import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  List<Widget> _devices(
      BuildContext context, Set<oppo.OppoBroadcast> broadcasts) {
    if (broadcasts.isEmpty) {
      return [
        const Text('Scanning for Oppo UDP-20X players...'),
        ElevatedButton(
          onPressed: () => _connect(
              _discover,
              oppo.OppoBroadcast(
                  InternetAddress('192.168.86.149'), 23, 'My OPPO')),
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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DiscoveryChanges(_discover),
      child: _consumer(context),
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
  bool createdProvider = false;

  @override
  Widget build(BuildContext context) {
    _log.fine('Rebuilding FutureBuilder.');
    return FutureBuilder<void>(
        future: widget.device.connect(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return const Text('Error connecting to device.');
            }
            return ChangeNotifierProvider(
              create: (_) {
                _log.info('Creating change notifier provider.');
                final deviceChanges = DeviceChanges(widget.device);
                createdProvider = true;
                return deviceChanges;
              },
              child: const HomePage(),
            );
          } else {
            return const Text('Connecting...');
          }
        });
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceChanges>(
      builder: (context, deviceChanges, _) =>
          _build(context, deviceChanges.device),
    );
  }

  Widget _build(BuildContext context, oppo.Device device) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Center(child: Text('Oppo Remote'))),
        body: device.powered ?? false
            ? _buttons(context, device)
            : _notPoweredOn(context, device),
      ),
    );
  }

  Widget _notPoweredOn(BuildContext context, oppo.Device device) {
    return ElevatedButton(
        onPressed: device.powerOn, child: const Text('power on'));
  }

  Widget _buttons(BuildContext context, oppo.Device device) {
    return Column(
      children: [
        ElevatedButton(
            onPressed: device.queryPowerStatus,
            child: const Text('query power')),
        ElevatedButton(
            onPressed: device.queryFirmwareVersion,
            child: const Text('query firmware')),
        ElevatedButton(
            onPressed: device.powerOn, child: const Text('power on')),
        ElevatedButton(
            onPressed: device.powerOff, child: const Text('power off')),
        ElevatedButton(onPressed: device.mute, child: const Text('mute')),
        const SizedBox(height: 10),
        Text(device.name),
        Text(device.firmwareVersion ?? 'pending'),
        Text(device.powered?.toString() ?? 'pending'),
      ],
    );
  }
}
