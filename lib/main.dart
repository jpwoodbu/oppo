import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:logging_flutter/logging_flutter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'controls.dart';
import 'display.dart';
import 'device_changes.dart';
import 'info.dart';
import 'number_pad.dart';
import 'oppo.dart' as oppo;
import 'position.dart';
import 'track_info.dart';
import 'util.dart';

final _log = Logger('main');

void main() {
  Logger.root.level = kDebugMode ? Level.ALL : Level.INFO;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  // Set up in-app log viewing.
  Flogger.init(
    config: const FloggerConfig(
      printClassName: true,
      printMethodName: true,
      showDateTime: true,
      showDebugLogs: true,
    ),
  );
  Flogger.registerListener(
    (record) => LogConsole.add(
      OutputEvent(record.level, [record.printable()]),
      bufferSize: 1000,
    ),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: Colors.blue,
      brightness: Brightness.dark,
    );
    return MaterialApp(
      title: 'Oppo Remote',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colorScheme,
        // This is a workaround for
        // https://github.com/flutter/flutter/issues/148849. When upgrading
        // Flutter from 3.19.6, the backgrounds of dialogs were too dark and had
        // low contrast with the dimmed background. Note that the default
        // background color for dialogs is supposed to be surfaceContainerHigh,
        // but I preferred surfaceContainer when testing this workaround.
        dialogTheme: DialogTheme(
          backgroundColor: colorScheme.surfaceContainer,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            padding: const EdgeInsets.fromLTRB(5.0, 20.0, 5.0, 20.0),
          ),
        ),
      ),
      initialRoute: '/scan',
      routes: {
        '/scan': (context) => const Discovery(),
      },
    );
  }
}

class DiscoveryChanges with ChangeNotifier {
  final oppo.Discover discover;
  late Stream<oppo.OppoID> _stream;
  Set<oppo.OppoID> devices = {};

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
  final String _settingLastDeviceName = 'lastDeviceName';
  final String _settingLastDeviceAddress = 'lastDeviceAddress';
  final String _settingLastDevicePort = 'lastDevicePort';
  late oppo.Discover _discover;
  final Future<SharedPreferences> _preferences =
      SharedPreferences.getInstance();

  @override
  void initState() {
    super.initState();
    _discover = oppo.Discover();
  }

  @override
  void dispose() {
    super.dispose();
    _discover.close();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DiscoveryChanges(_discover),
      child: Consumer<DiscoveryChanges>(
        builder: (context, discoveryChanges, _) => SafeArea(
          child: Scaffold(
            body: Semantics(
              label: 'list of discovered devices with '
                  'option to enter demo mode',
              child: ListView(
                padding: const EdgeInsets.all(25.0),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Device discovery',
                          style: Theme.of(context).textTheme.titleMedium),
                      TextButton(
                        onPressed: () => _connect(
                            oppo.OppoID(
                              InternetAddress('1.2.3.4'),
                              123,
                              'Fake device',
                            ),
                            useFake: true),
                        child: const Text('Demo mode'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 25.0),
                  const LinearProgressIndicator(),
                  const SizedBox(height: 25.0),
                  _devices(discoveryChanges.devices),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _devices(Set<oppo.OppoID> ids) {
    String? lastDeviceAddress;
    return FutureBuilder(
      future: _preferences,
      builder: (_, AsyncSnapshot<SharedPreferences> snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          lastDeviceAddress =
              snapshot.data!.getString(_settingLastDeviceAddress);
          final lastDeviceName =
              snapshot.data!.getString(_settingLastDeviceName);
          final lastDevicePort = snapshot.data!.getInt(_settingLastDevicePort);
          if (lastDeviceAddress != null &&
              lastDeviceName != null &&
              lastDevicePort != null) {
            ids.add(
              oppo.OppoID(
                InternetAddress(lastDeviceAddress!),
                lastDevicePort,
                lastDeviceName,
              ),
            );
          }
        }
        if (ids.isEmpty) {
          return const Column(children: []);
        }
        return Column(
          children: ids
              .map(
                (e) => Semantics(
                  label: 'discovered device',
                  child: Card(
                    child: ListTile(
                      leading: const Icon(Icons.album),
                      title: Text(e.name),
                      subtitle: Text(e.address.address),
                      trailing: e.address.address == lastDeviceAddress
                          ? Text('Last connected',
                              style: Theme.of(context).textTheme.bodySmall)
                          : null,
                      onTap: () => _connect(e),
                    ),
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  void _connect(oppo.OppoID id, {bool useFake = false}) {
    final device = useFake
        ? oppo.FakeDevice(id.name, id.address, id.port)
        : oppo.Device(id.name, id.address, id.port);
    if (!useFake) _saveLastDevice(id);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => Connect(device)),
      (Route<dynamic> route) => false,
    );
  }

  void _saveLastDevice(oppo.OppoID id) async {
    final p = await SharedPreferences.getInstance();
    await p.setString(_settingLastDeviceName, id.name);
    await p.setString(_settingLastDeviceAddress, id.address.address);
    await p.setInt(_settingLastDevicePort, id.port);
    _log.info('Saved last device: ${id.address.address}');
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
                    const Text('Error connecting to device.'),
                    TextButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Discovery()),
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
            // TODO - See about using read/watch to minimize how many widgets
            // get rebuilt with each device change.
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
  const HomePage(this.device, {super.key});

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
      // Show the waiting message for at least 1s while we perform the
      // background work.
      future:
          Future.wait([Future.delayed(const Duration(seconds: 1)), _engage]),
      builder: (BuildContext context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return SafeArea(
              child: Scaffold(
                body: Center(
                  child: Column(
                    children: [
                      const Text('Error while waiting on device to power up.'),
                      TextButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const Discovery()),
                              (Route<dynamic> route) => false);
                        },
                        child: const Text('Scan for players'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return _build();
        } else {
          return const SafeArea(
            child: Scaffold(
              body: Center(
                child: Text('Powering on and setting up communication...'),
              ),
            ),
          );
        }
      },
    );
  }

  Widget _build() {
    Image appIcon = const Image(
      image: AssetImage('assets/hdpi_app_icon.png'),
      height: 72.0,
      width: 72.0,
    );
    final smallText = Theme.of(context).textTheme.bodySmall;
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Position(),
          centerTitle: true,
          titleSpacing: 0.0,
          actions: [
            PoweredProvider(
              builder: (_, powered, __) {
                return powered ?? false
                    ? IconButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) =>
                                NumberPad(device),
                          );
                        },
                        icon: const Icon(
                          Icons.dialpad,
                          semanticLabel: 'open number pad',
                        ),
                      )
                    : const SizedBox();
              },
            ),
          ],
        ),
        drawer: PoweredProvider(
          builder: (_, powered, __) => NavigationDrawer(
            children: [
              DrawerHeader(
                child: Row(
                  children: [
                    appIcon,
                    const SizedBox(width: 8.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Oppo Remote'),
                        Text(device.name, style: smallText),
                        Text('Firmware: ${device.firmwareVersion ?? 'unknown'}',
                            style: smallText),
                      ],
                    ),
                  ],
                ),
              ),
              if (powered ?? false)
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('Fetch track metadata'),
                  onTap: () {
                    Navigator.pop(context);
                    showDialog(
                      context: context,
                      builder: (_) => TrackMetadata(device: device),
                    );
                  },
                ),
              ListTile(
                leading: const Icon(Icons.sensors),
                title: const Text('Scan for players'),
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const Discovery()),
                    (Route<dynamic> route) => false,
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.bug_report),
                title: const Text('Known issues'),
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const KnownIssues())),
              ),
              ListTile(
                leading: const Icon(Icons.feedback),
                title: const Text('Debug logs'),
                onTap: () => LogConsole.open(context),
              ),
              ListTile(
                leading: const Icon(Icons.article),
                title: const Text('Licenses'),
                onTap: () =>
                    showLicensePage(context: context, applicationIcon: appIcon),
              ),
            ],
          ),
        ),
        body: PoweredProvider(
          builder: (_, powered, __) =>
              powered ?? false ? Buttons(device) : NotPoweredOn(device),
        ),
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
            const Text('Power on to use the remote.'),
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
    return Semantics(
      label: 'scrollable area with information display and '
          'remote control buttons',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: ListView(
          children: [
            Display(device),
            const SizedBox(height: 4.0),
            const Divider(),
            HomeRow(device),
            Arrows(device),
            PlayControls(device),
            PositionControls(device),
            BottomGrid(device),
            const Divider(),
            ExtraControls(device),
            const SizedBox(height: 4.0),
          ],
        ),
      ),
    );
  }
}

class PoweredProvider extends StatelessWidget {
  final ValueWidgetBuilder builder;
  const PoweredProvider({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return Selector<DeviceChanges, bool?>(
        selector: (_, deviceChanges) => deviceChanges.device.powered,
        builder: builder);
  }
}
