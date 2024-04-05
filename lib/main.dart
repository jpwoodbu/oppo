import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'device_changes.dart';
import 'oppo.dart' as oppo;
import 'playground.dart';

final _log = Logger('main');

void main() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  runApp(const MyApp());
}

dynamic addHaptic(Function function) {
  HapticFeedback.lightImpact();
  return function();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Oppo Remote',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue,
      ),
      home: const Discovery(),
    );
  }
}

class DiscoveryChanges with ChangeNotifier {
  final oppo.Discover discover;
  late Stream<oppo.OppoBroadcast> _stream;
  Set<oppo.OppoBroadcast> devices = {};

  DiscoveryChanges(this.discover) {
    _stream = discover.listen();
    _handleBroadcasts();
  }

  Future<void> _handleBroadcasts() async {
    await for (final broadcast in _stream) {
      devices.add(broadcast);
      notifyListeners();
    }
  }
}

class Discovery extends StatefulWidget {
  const Discovery({super.key});

  @override
  State<Discovery> createState() => _DiscoveryState();
}

class _DiscoveryState extends State<Discovery> {
  late oppo.Discover _discover;

  @override
  void initState() {
    super.initState();
    _discover = oppo.Discover();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DiscoveryChanges(_discover),
      child: _consumer(context),
    );
  }

  Widget _consumer(BuildContext context) {
    return Consumer<DiscoveryChanges>(
      builder: (context, discoveryChanges, _) =>
          _page(context, discoveryChanges.devices),
    );
  }

  Widget _page(BuildContext context, Set<oppo.OppoBroadcast> broadcasts) {
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Center(
            child: Column(
              children: _devices(context, broadcasts),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _devices(
      BuildContext context, Set<oppo.OppoBroadcast> broadcasts) {
    if (broadcasts.isEmpty) {
      return [
        const Text('Scanning for Oppo UDP-20X players...'),
        ElevatedButton(
          onPressed: () => _connect(
              _discover,
              oppo.OppoBroadcast(
                  InternetAddress('192.168.86.149'), 23, 'Name unknown')),
          child: const Text('Just connect to mine.'),
        ),
      ];
    } else {
      return broadcasts
          .map(
            (e) => Card(
              child: SizedBox(
                width: 300,
                height: 75,
                child: ListTile(
                  leading: const Icon(Icons.album),
                  title: Text(e.name),
                  subtitle: Text(e.address.address),
                  onTap: () => _connect(_discover, e),
                ),
              ),
            ),
          )
          .toList();
    }
  }

  void _connect(oppo.Discover discover, oppo.OppoBroadcast broadcast) {
    discover.close();
    final device =
        oppo.Device(broadcast.name, broadcast.address, broadcast.port);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => Connect(device)),
      (Route<dynamic> route) => false,
    );
  }
}

class Connect extends StatefulWidget {
  final oppo.Device device;
  const Connect(this.device, {super.key});

  @override
  State<Connect> createState() => _ConnectState();
}

class _ConnectState extends State<Connect> {
  // It's important that the "connect" Future is stateful so we don't try to
  // reconnect on hot reload.
  late Future<void> _connect;

  @override
  void initState() {
    super.initState();
    _connect =
        Future.delayed(const Duration(seconds: 1), widget.device.connect);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _connect,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return const Scaffold(
                body: Center(child: Text('Error connecting to device.')));
          }
          return ChangeNotifierProvider<DeviceChanges>(
            create: (_) => DeviceChanges(widget.device),
            // The child Widget depends on [DeviceChanges] being fully set up
            // ahead of time.
            lazy: false,
            child: HomePage(widget.device),
          );
        } else {
          return const Scaffold(body: Center(child: Text('Connecting...')));
        }
      },
    );
  }
}

class HomePage extends StatefulWidget {
  late final oppo.Device device;
  HomePage(this.device, {super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // It's important that the "engage" Future is stateful so we don't try to
  // run it on every widget rebuild or hot reload.
  late Future<void> _engage;
  int currentPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _engage = widget.device.engage();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceChanges>(
      builder: (context, deviceChanges, _) =>
          _futureBuilder(context, _engage, deviceChanges.device),
    );
  }

  Widget _futureBuilder(
      BuildContext context, Future future, oppo.Device device) {
    return FutureBuilder<void>(
      future: future,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return const Scaffold(
                body: Center(
                    child: Text('Error while waiting on device to power up.')));
          }
          return _build(context, device);
        } else {
          return const Scaffold(
              body: Center(
            child: Text('Powering on and setting up communication...'),
          ));
        }
      },
    );
  }

  Widget _build(BuildContext context, oppo.Device device) {
    return SafeArea(
      child: Scaffold(
        body: device.powered ?? false
            ? IndexedStack(
                index: currentPageIndex,
                // TODO - maybe these children should be full widget classes
                // instead of functions. That may give them some optimizations
                // like only being rebuilt lazily.
                children: [
                  _buttons(context, device),
                  _numberPad(context, device),
                  _otherControls(context, device),
                  _fileViewer(context, device),
                  Playground(),
                ],
              )
            : _notPoweredOn(context, device),
        bottomNavigationBar: device.powered ?? false
            ? NavigationBar(
                destinations: [
                  NavigationDestination(
                    icon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.numbers),
                    label: 'Pad',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.miscellaneous_services),
                    label: 'Other',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.folder),
                    label: 'Files',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.play_arrow),
                    label: 'Playground',
                  ),
                ],
                selectedIndex: currentPageIndex,
                onDestinationSelected: (int index) {
                  setState(() => currentPageIndex = index);
                },
              )
            : null,
      ),
    );
  }
}

Widget _notPoweredOn(BuildContext context, oppo.Device device) {
  return Padding(
    padding: const EdgeInsets.all(15.0),
    child: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('The player must be powered on to use this remote.'),
          const SizedBox(height: 10.0),
          const Text('Click below to power it on.'),
          const SizedBox(height: 10.0),
          IconButton(
            // TODO - turn this into a stateful widget show a progress indicator
            // can be displayed after the power button is clicked.
            onPressed: () => addHaptic(device.powerOn),
            icon: const Icon(
              Icons.power_settings_new,
              color: Colors.amber,
              semanticLabel: 'Toggle power',
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buttons(BuildContext context, oppo.Device device) {
  return Padding(
    padding: const EdgeInsets.all(15.0),
    child: ListView(
      children: [
        _nameRow(context, device),
        _position(context, device),
        _homeRow(context, device),
        _arrows(context, device),
        _playControls(context, device),
        _positionControls(context, device),
      ],
    ),
  );
}

Widget _position(BuildContext context, oppo.Device device) {
  final p = device.position;
  if (p == null) return Text('No position data.');
  return Text('Title: ${p.title}\nChapter: ${p.chapter}\n'
      '${p.timeInformation.displayName}: ${p.clock}');
}

Widget _nameRow(BuildContext context, oppo.Device device) {
  return Row(
    mainAxisSize: MainAxisSize.max,
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        device.name,
      ),
      IconButton(
        // This widget is only displayed when the power is on so we explicitly
        // call the power off function here.
        onPressed: () => addHaptic(device.powerOff),
        icon: const Icon(
          Icons.power_settings_new,
          color: Colors.blue,
          semanticLabel: 'Toggle power',
        ),
      )
    ],
  );
}

Widget _homeRow(BuildContext context, oppo.Device device) {
  return Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      IconButton(
        onPressed: () => addHaptic(device.home),
        icon: const Icon(
          Icons.home,
          semanticLabel: 'home',
        ),
      ),
      ElevatedButton.icon(
        onPressed: () => addHaptic(device.goto),
        icon: Icon(Icons.arrow_downward),
        label: Text('Goto'),
      ),
      ElevatedButton.icon(
        onPressed: () => addHaptic(device.clear),
        icon: Icon(Icons.clear),
        label: Text('Clear'),
      ),
      IconButton(
        onPressed: () => addHaptic(device.osd),
        icon: const Icon(
          Icons.info,
          semanticLabel: 'info',
        ),
      ),
      IconButton(
        onPressed: () => addHaptic(device.infoDetailed),
        icon: const Icon(
          Icons.query_stats,
          semanticLabel: 'detailed info',
        ),
      ),
    ],
  );
}

Widget _arrows(BuildContext context, oppo.Device device) {
  const iconSize = 100.0;
  final table = Table(
    defaultColumnWidth: const IntrinsicColumnWidth(),
    children: <TableRow>[
      TableRow(
        children: [
          TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: ElevatedButton(
              onPressed: () => addHaptic(device.topMenu),
              child: const Text('Top'),
            ),
          ),
          IconButton(
              onPressed: () => addHaptic(device.arrowUp),
              icon: Icon(
                Icons.keyboard_arrow_up,
                size: iconSize,
                semanticLabel: 'up',
              )),
          TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: ElevatedButton(
              onPressed: () => addHaptic(device.popupMenu),
              child: const Text('Pop-up'),
            ),
          ),
        ],
      ),
      TableRow(
        children: [
          IconButton(
              onPressed: () => addHaptic(device.arrowLeft),
              icon: Icon(
                Icons.keyboard_arrow_left,
                size: iconSize,
                semanticLabel: 'left',
              )),
          IconButton(
              onPressed: () => addHaptic(device.enter),
              icon: Icon(
                Icons.circle_outlined,
                size: iconSize,
                semanticLabel: 'enter',
              )),
          IconButton(
              onPressed: () => addHaptic(device.arrowRight),
              icon: Icon(
                Icons.keyboard_arrow_right,
                size: iconSize,
                semanticLabel: 'right',
              )),
        ],
      ),
      TableRow(
        children: [
          TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: ElevatedButton(
              onPressed: () => addHaptic(device.option),
              child: const Text('Option'),
            ),
          ),
          IconButton(
              onPressed: () => addHaptic(device.arrowDown),
              icon: Icon(
                Icons.keyboard_arrow_down,
                size: iconSize,
                semanticLabel: 'down',
              )),
          TableCell(
            verticalAlignment: TableCellVerticalAlignment.middle,
            child: IconButton(
                onPressed: () => addHaptic(device.returnToPrevious),
                icon: Icon(
                  Icons.arrow_back,
                  size: iconSize / 3,
                  semanticLabel: 'return to previous',
                )),
          ),
        ],
      ),
    ],
  );

  return table;
  /*
  return Expanded(
    child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints boxConstraints) {
      return table;
    }),
  );
  */
}

Widget _playControls(BuildContext context, oppo.Device device) {
  const iconSize = 85.0;
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      IconButton(
          onPressed: () => addHaptic(device.stop),
          icon: Icon(
            Icons.stop_circle,
            size: iconSize,
            semanticLabel: 'stop',
          )),
      IconButton(
          onPressed: () => addHaptic(device.play),
          icon: Icon(
            Icons.play_arrow,
            size: iconSize,
            semanticLabel: 'play',
          )),
      IconButton(
          onPressed: () => addHaptic(device.pause),
          icon: Icon(
            Icons.pause,
            size: iconSize,
            semanticLabel: 'pause',
          )),
    ],
  );
}

Widget _positionControls(BuildContext context, oppo.Device device) {
  const iconSize = 65.0;
  return Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      IconButton(
          onPressed: () => addHaptic(device.previous),
          icon: Icon(
            Icons.skip_previous,
            size: iconSize,
            semanticLabel: 'previous',
          )),
      IconButton(
          onPressed: () => addHaptic(device.reverse),
          icon: Icon(
            Icons.fast_rewind,
            size: iconSize,
            semanticLabel: 'scan reverse',
          )),
      IconButton(
          onPressed: () => addHaptic(device.forward),
          icon: Icon(
            Icons.fast_forward,
            size: iconSize,
            semanticLabel: 'scan forward',
          )),
      IconButton(
          onPressed: () => addHaptic(device.next),
          icon: Icon(
            Icons.skip_next,
            size: iconSize,
            semanticLabel: 'next',
          )),
    ],
  );
}

Widget _numberPad(BuildContext context, oppo.Device device) {
  Widget number(Function onPressed, String label) {
    final padding = EdgeInsets.all(8.0);
    return Padding(
      padding: padding,
      child: ElevatedButton(
        onPressed: () => addHaptic(onPressed),
        child: Container(
          padding: padding,
          child: Text(label, style: Theme.of(context).textTheme.headlineLarge),
        ),
      ),
    );
  }

  return Center(
    child: Table(
      defaultColumnWidth: IntrinsicColumnWidth(),
      children: [
        TableRow(
          children: [
            number(device.number1, '1'),
            number(device.number2, '2'),
            number(device.number2, '3'),
          ],
        ),
        TableRow(
          children: [
            number(device.number4, '4'),
            number(device.number5, '5'),
            number(device.number6, '6'),
          ],
        ),
        TableRow(
          children: [
            number(device.number7, '7'),
            number(device.number8, '8'),
            number(device.number9, '9'),
          ],
        ),
        TableRow(
          children: [
            SizedBox(),
            number(device.number0, '0'),
            SizedBox(),
          ],
        ),
      ],
    ),
  );
}

Widget _otherControls(BuildContext context, oppo.Device device) {
  Widget colorButton(Function onPressed, Color color) {
    return FilledButton(
      onPressed: () => addHaptic(onPressed),
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(color),
      ),
      child: SizedBox(height: 30.0, width: 60.0),
    );
  }

  return Padding(
    padding: const EdgeInsets.all(15.0),
    child: ListView(
      children: [
        Wrap(
          alignment: WrapAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: device.inputMenu,
              icon: Icon(Icons.route),
              label: Text('Input'),
            ),
            ElevatedButton.icon(
              onPressed: device.trayToggle,
              icon: Icon(Icons.eject),
              label: Text('Open'),
            ),
          ],
        ),
        Wrap(
          alignment: WrapAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: device.pureAudio,
              icon: Icon(Icons.graphic_eq),
              label: Text('Pure audio'),
            ),
            ElevatedButton.icon(
              onPressed: device.volumeDown,
              icon: Icon(Icons.volume_down),
              label: Text('Volume -'),
            ),
            ElevatedButton.icon(
              onPressed: device.volumeUp,
              icon: Icon(Icons.volume_up),
              label: Text('Volume +'),
            ),
            ElevatedButton.icon(
              onPressed: device.mute,
              icon: Icon(Icons.volume_mute),
              label: Text('Mute'),
            ),
          ],
        ),
        Wrap(
          alignment: WrapAlignment.spaceEvenly,
          children: [
            colorButton(device.red, Colors.red),
            colorButton(device.green, Colors.green),
            colorButton(device.blue, Colors.blue),
            colorButton(device.yellow, Colors.yellow),
          ],
        ),
        Wrap(
          alignment: WrapAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: device.audio,
              icon: Icon(Icons.audiotrack),
              label: Text('Audio'),
            ),
            ElevatedButton.icon(
              onPressed: device.subtitle,
              icon: Icon(Icons.subtitles),
              label: Text('Subtitle'),
            ),
            ElevatedButton.icon(
              onPressed: device.zoom,
              icon: Icon(Icons.zoom_in),
              label: Text('Zoom'),
            ),
            ElevatedButton.icon(
              onPressed: device.dim,
              icon: Icon(Icons.light_mode),
              label: Text('Dimmer'),
            ),
          ],
        ),
        Wrap(
          alignment: WrapAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: device.setUp,
              icon: Icon(Icons.settings),
              label: Text('Setup'),
            ),
            ElevatedButton.icon(
              onPressed: device.repeatAB,
              icon: Icon(Icons.undo),
              label: Text('AB Replay'),
            ),
            ElevatedButton.icon(
              onPressed: device.repeat,
              icon: Icon(Icons.repeat),
              label: Text('Repeat'),
            ),
            ElevatedButton.icon(
              onPressed: device.pictureAdjustmentMenu,
              icon: Icon(Icons.apps),
              label: Text('Pic'),
            ),
          ],
        ),
        Wrap(
          alignment: WrapAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: device.outputResolutionCycle,
              icon: Icon(Icons.aspect_ratio),
              label: Text('Resolution'),
            ),
            ElevatedButton.icon(
              onPressed: device.hdrMenu,
              icon: Icon(Icons.hdr_strong),
              label: Text('HDR'),
            ),
          ],
        ),
      ],
    ),
  );
}

Widget _fileViewer(BuildContext context, oppo.Device device) {
  return Placeholder();
}
