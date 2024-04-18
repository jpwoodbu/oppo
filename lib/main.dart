import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'controls.dart';
import 'display.dart';
import 'device_changes.dart';
import 'info.dart';
import 'number_pad.dart';
import 'oppo.dart' as oppo;
import 'position.dart';
import 'util.dart';

final _log = Logger('main');

void main() {
  Logger.root.level = kDebugMode ? Level.INFO : Level.INFO;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  runApp(const MyApp());
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
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: const EdgeInsets.fromLTRB(5.0, 20.0, 5.0, 20.0),
          ),
        ),
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
        body: ListView(
          padding: const EdgeInsets.all(25.0),
          children: [
            Text('Device selection',
                style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 25.0),
            LinearProgressIndicator(),
            SizedBox(height: 25.0),
            Column(
              children: _devices(context, broadcasts),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _devices(
      BuildContext context, Set<oppo.OppoBroadcast> broadcasts) {
    if (broadcasts.isEmpty) {
      return [
        const Text('Scanning for players...'),
        TextButton(
          onPressed: () => _connect(
              _discover,
              oppo.OppoBroadcast(
                  InternetAddress('192.168.86.59'), 23, 'Name unknown')),
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
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error connecting to device.'),
                    TextButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Discovery()),
                            (Route<dynamic> route) => false);
                      },
                      child: const Text('Scan for players'),
                    ),
                  ],
                ),
              ),
            );
          }
          return ChangeNotifierProvider<DeviceChanges>(
            create: (_) => DeviceChanges(widget.device, context),
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
  final oppo.Device device;
  HomePage(this.device, {super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // It's important that the "engage" Future is stateful so we don't try to
  // run it on every widget rebuild or hot reload.
  late Future<void> _engage;
  late oppo.Device device;

  @override
  void initState() {
    super.initState();
    _engage = widget.device.engage();
    // Just a convenience.
    device = widget.device;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _engage,
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Scaffold(
              body: Center(
                child: Column(
                  children: [
                    Text('Error while waiting on device to power up.'),
                    TextButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => Discovery()),
                            (Route<dynamic> route) => false);
                      },
                      child: const Text('Scan for players'),
                    ),
                  ],
                ),
              ),
            );
          }
          return _build(context);
        } else {
          return const Scaffold(
            body: Center(
              child: Text('Powering on and setting up communication...'),
            ),
          );
        }
      },
    );
  }

  Widget _build(BuildContext context) {
    Image appIcon = const Image(
      image: AssetImage('assets/hdpi_app_icon.png'),
    );
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: device.powered ?? false ? Position(device) : null,
          centerTitle: true,
          titleSpacing: 0.0,
          actions: [
            if (device.powered ?? false)
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
              SizedBox(
                height: 75.0,
                child: DrawerHeader(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Row(children: [
                      appIcon,
                      SizedBox(width: 8.0),
                      Text('Oppo Remote'),
                    ]),
                  ),
                ),
              ),
              if (device.powered ?? false)
                ListTile(
                  leading: Icon(Icons.refresh),
                  title: const Text('Refresh player info'),
                  onTap: () {
                    addHaptic(device.fetchState);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Refreshing player info...')));
                  },
                ),
              // TODO - Maybe change this to a control button that opens an
              // AlertDialog for confirmation.
              ListTile(
                leading: Icon(Icons.power_settings_new),
                title: const Text('Power off'),
                onTap: () {
                  addHaptic(device.powerOff);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Waiting for power off signal...')));
                },
              ),
              // TODO - Maybe change this to a control button that opens an
              // AlertDialog for confirmation.
              if (device.powered ?? false)
                ListTile(
                  leading: Icon(Icons.eject),
                  title: const Text('Tray open/close'),
                  onTap: () => addHaptic(device.trayToggle),
                ),
              ListTile(
                leading: Icon(Icons.sensors),
                title: const Text('Scan for players'),
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => Discovery()),
                    (Route<dynamic> route) => false,
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.help),
                title: const Text('Help'),
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (context) => Help())),
              ),
              ListTile(
                leading: Icon(Icons.bug_report),
                title: const Text('Known issues'),
                onTap: () => Navigator.push(context,
                    MaterialPageRoute(builder: (context) => KnownIssues())),
              ),
              ListTile(
                leading: Icon(Icons.article),
                title: const Text('Licenses'),
                onTap: () =>
                    showLicensePage(context: context, applicationIcon: appIcon),
              ),
            ],
          ),
        ),
        // TODO - BROKEN; Without a Consumer above, this doesn't get re-eval'd
        // when the device powers off.
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
              onPressed: () {
                addHaptic(device.powerOn);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Waiting for power on signal...')));
              },
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
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: ListView(
        children: [
          Display(device),
          SizedBox(height: 4.0),
          HomeRow(device),
          Arrows(device),
          PlayControls(device),
          PositionControls(device),
          BottomGrid(device),
          Divider(),
          ExtraControls(device),
        ],
      ),
    );
  }
}
