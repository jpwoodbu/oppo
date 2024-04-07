import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'device_changes.dart';
import 'oppo.dart' as oppo;

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
        appBar: AppBar(
          actions: [
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) => PageControls(device),
                );
              },
              icon: Icon(Icons.swap_vert),
            ),
            IconButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) => NumberPad(device),
                );
              },
              icon: Icon(Icons.dialpad),
            ),
          ],
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(child: Text('Drawer header')),
              ListTile(
                leading: Icon(Icons.power_settings_new),
                title: const Text('Power off'),
                onTap: () => addHaptic(device.powerOff),
              ),
              ListTile(
                leading: Icon(Icons.route),
                title: const Text('Input'),
                onTap: () => addHaptic(device.inputMenu),
              ),
              ListTile(
                leading: Icon(Icons.eject),
                title: const Text('Tray open/close'),
                onTap: () => addHaptic(device.trayToggle),
              ),
            ],
          ),
        ),
        body: device.powered ?? false ? Buttons(device) : NotPoweredOn(device),
      ),
    );
  }
}

class NotPoweredOn extends StatelessWidget {
  final oppo.Device device;
  const NotPoweredOn(this.device, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Turn on player to use remote.'),
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
}

class Buttons extends StatelessWidget {
  final oppo.Device device;
  const Buttons(this.device, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: ListView(
        children: [
          HomeRow(device),
          Arrows(device),
          PlayControls(device),
          PositionControls(device),
          BottomGrid(device),
        ],
      ),
    );
  }
}

class Position extends StatelessWidget {
  final oppo.Device device;
  const Position(this.device, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = device.position;
    if (p == null) return Text('No position data.');
    return Text('Title: ${p.title}\nChapter: ${p.chapter}\n'
        '${p.timeInformation.displayName}: ${p.clock}');
  }
}

class NameRow extends StatelessWidget {
  final oppo.Device device;
  const NameRow(this.device, {super.key});

  @override
  Widget build(BuildContext context) {
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
}

class HomeRow extends StatelessWidget {
  final oppo.Device device;
  const HomeRow(this.device, {super.key});

  @override
  Widget build(BuildContext context) {
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
}

class Arrows extends StatelessWidget {
  final oppo.Device device;
  const Arrows(this.device, {super.key});

  @override
  Widget build(BuildContext context) {
    const iconSize = 100.0;
    return Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      children: <TableRow>[
        TableRow(
          children: [
            TableCell(
              verticalAlignment: TableCellVerticalAlignment.middle,
              child: ElevatedButton(
                onPressed: () => addHaptic(device.topMenu),
                child: IconVertical(icon: Icon(Icons.navigation), label: 'Top'),
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
                child: IconVertical(icon: Icon(Icons.article), label: 'Pop-up'),
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
                child:
                    IconVertical(icon: Icon(Icons.emergency), label: 'Option'),
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
              child: ElevatedButton(
                  onPressed: () => addHaptic(device.returnToPrevious),
                  child: IconVertical(
                    icon: Icon(Icons.arrow_back),
                    label: 'Return',
                  )),
            ),
          ],
        ),
      ],
    );
  }
}

class PlayControls extends StatelessWidget {
  final oppo.Device device;
  const PlayControls(this.device, {super.key});

  @override
  Widget build(BuildContext context) {
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
}

class PositionControls extends StatelessWidget {
  final oppo.Device device;
  const PositionControls(this.device, {super.key});

  @override
  Widget build(BuildContext context) {
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
}

class NumberButton extends StatelessWidget {
  final Function onPressed;
  final String label;
  const NumberButton({super.key, required this.onPressed, required this.label});

  @override
  Widget build(BuildContext context) {
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
}

class NumberPad extends StatelessWidget {
  final oppo.Device device;
  const NumberPad(this.device, {super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Table(
        defaultColumnWidth: IntrinsicColumnWidth(),
        children: [
          TableRow(
            children: [
              NumberButton(onPressed: device.number1, label: '1'),
              NumberButton(onPressed: device.number2, label: '2'),
              NumberButton(onPressed: device.number2, label: '3'),
            ],
          ),
          TableRow(
            children: [
              NumberButton(onPressed: device.number4, label: '4'),
              NumberButton(onPressed: device.number5, label: '5'),
              NumberButton(onPressed: device.number6, label: '6'),
            ],
          ),
          TableRow(
            children: [
              NumberButton(onPressed: device.number7, label: '7'),
              NumberButton(onPressed: device.number8, label: '8'),
              NumberButton(onPressed: device.number9, label: '9'),
            ],
          ),
          TableRow(
            children: [
              SizedBox(),
              NumberButton(onPressed: device.number0, label: '0'),
              SizedBox(),
            ],
          ),
        ],
      ),
    );
  }
}

class ColorButton extends StatelessWidget {
  final Function onPressed;
  final Color color;
  const ColorButton({super.key, required this.onPressed, required this.color});

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: () => addHaptic(onPressed),
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(color),
      ),
      child: SizedBox(height: 30.0, width: 12.0),
    );
  }
}

class IconVertical extends StatelessWidget {
  final String label;
  final Icon icon;
  const IconVertical({super.key, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        icon,
      ],
    );
  }
}

class BottomGrid extends StatelessWidget {
  final oppo.Device device;
  const BottomGrid(this.device, {super.key});

  @override
  Widget build(BuildContext context) {
    return Table(
      children: <TableRow>[
        TableRow(children: [
          TableCell(
              child: ColorButton(onPressed: () => addHaptic(device.red), color: Colors.red)),
          TableCell(
              child: ColorButton(onPressed: () => addHaptic(device.green), color: Colors.green)),
          TableCell(
              child: ColorButton(onPressed: () => addHaptic(device.blue), color: Colors.blue)),
          TableCell(
              child:
                  ColorButton(onPressed: () => addHaptic(device.yellow), color: Colors.yellow)),
        ]),
        TableRow(children: [
          TableCell(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.pureAudio),
              child: IconVertical(
                  icon: Icon(Icons.graphic_eq), label: 'Pure audio'),
            ),
          ),
          TableCell(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.volumeDown),
              child:
                  IconVertical(icon: Icon(Icons.volume_down), label: 'Vol -'),
            ),
          ),
          TableCell(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.volumeUp),
              child: IconVertical(icon: Icon(Icons.volume_up), label: 'Vol +'),
            ),
          ),
          TableCell(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.mute),
              child: IconVertical(icon: Icon(Icons.volume_mute), label: 'Mute'),
            ),
          ),
        ]),
        TableRow(
          children: [
            TableCell(
              child: ElevatedButton(
                onPressed: () => addHaptic(device.audio),
                child:
                    IconVertical(icon: Icon(Icons.audiotrack), label: 'Audio'),
              ),
            ),
            TableCell(
              child: ElevatedButton(
                onPressed: () => addHaptic(device.subtitle),
                child: IconVertical(
                    icon: Icon(Icons.subtitles), label: 'Subtitle'),
              ),
            ),
            TableCell(
              child: ElevatedButton(
                onPressed: () => addHaptic(device.zoom),
                child: IconVertical(icon: Icon(Icons.zoom_in), label: 'Zoom'),
              ),
            ),
            TableCell(
              child: ElevatedButton(
                onPressed: () => addHaptic(device.dim),
                child:
                    IconVertical(icon: Icon(Icons.light_mode), label: 'Dimmer'),
              ),
            ),
          ],
        ),
        TableRow(children: [
          TableCell(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.setup),
              child: IconVertical(icon: Icon(Icons.build), label: 'Setup'),
            ),
          ),
          TableCell(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.repeatAB),
              child: IconVertical(icon: Icon(Icons.undo), label: 'AB Replay'),
            ),
          ),
          TableCell(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.repeat),
              child: IconVertical(icon: Icon(Icons.repeat), label: 'Repeat'),
            ),
          ),
          TableCell(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.pictureAdjustmentMenu),
              child: IconVertical(icon: Icon(Icons.apps), label: 'Pic'),
            ),
          ),
        ]),
        TableRow(children: [
          TableCell(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.outputResolutionCycle),
              child: IconVertical(
                  icon: Icon(Icons.aspect_ratio), label: 'Resolution'),
            ),
          ),
          TableCell(child: SizedBox()),
          TableCell(child: SizedBox()),
          TableCell(
            child: ElevatedButton(
              onPressed: () => addHaptic(device.hdrMenu),
              child: IconVertical(icon: Icon(Icons.hdr_strong), label: 'HDR'),
            ),
          ),
        ]),
      ],
    );
  }
}

class PageControls extends StatelessWidget {
  final oppo.Device device;
  const PageControls(this.device, {super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
              onPressed: () => addHaptic(device.pageUp), icon: Icon(Icons.arrow_upward)),
          const Text('Page'),
          IconButton(
              onPressed: () => addHaptic(device.pageDown),
              icon: Icon(Icons.arrow_downward)),
        ],
      ),
    );
  }
}
