import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

import 'controls.dart';
import 'device_changes.dart';
import 'number_pad.dart';
import 'oppo.dart' as oppo;
import 'position.dart';
import 'util.dart';

final _log = Logger('main');

void main() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
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
              borderRadius: BorderRadius.circular(4.0),
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
        const Text('No devices found so far...'),
        TextButton(
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
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onRestart: () {
        _log.info('onRestart');
      },
    );
    _connect =
        Future.delayed(const Duration(seconds: 1), widget.device.connect);
  }

  @override
  void dispose() async {
    super.dispose();
    _listener.dispose();
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
    Image appIcon = const Image(
      image: AssetImage('assets/hdpi_app_icon.png'),
    );
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Position(device),
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
                  leading: Icon(Icons.power_settings_new),
                  title: const Text('Power off'),
                  onTap: () {
                    addHaptic(device.powerOff);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Waiting for power off signal...')));
                  },
                ),
              if (device.powered ?? false)
                ListTile(
                  leading: Icon(Icons.route),
                  title: const Text('Input'),
                  onTap: () => addHaptic(device.inputMenu),
                ),
              if (device.powered ?? false)
                ListTile(
                  leading: Icon(Icons.eject),
                  title: const Text('Tray open/close'),
                  onTap: () => addHaptic(device.trayToggle),
                ),
              ListTile(
                leading: Icon(Icons.redo),
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
                leading: Icon(Icons.info),
                title: const Text('Licenses'),
                onTap: () =>
                    showLicensePage(context: context, applicationIcon: appIcon),
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
