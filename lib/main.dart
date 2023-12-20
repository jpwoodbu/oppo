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

  Widget _page(BuildContext context, Set<oppo.OppoBroadcast> devices) {
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Center(
            child: Column(
              children: _devices(context, devices),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _devices(BuildContext context, Set<oppo.OppoBroadcast> devices) {
    if (devices.isEmpty) {
      return [const Text('Scanning for Oppo UDP-20X players...')];
    } else {
      return devices
          .map(
            (e) => Card(
              child: SizedBox(
                width: 300,
                height: 75,
                child: ListTile(
                  leading: const Icon(Icons.album),
                  title: Text(e.name),
                  subtitle: Text(e.address.address),
                  onTap: () {
                    _discover.close();
                    final device = oppo.Device(e.name, e.address, e.port);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => HomePage(device)),
                      (Route<dynamic> route) => false,
                    );
                  },
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

class HomePage extends StatelessWidget {
  final oppo.Device device;

  const HomePage(this.device, {super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
        future: device.connect(),
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (snapshot.hasError) {
              return const Text('Error connecting to device.');
            }
            return ChangeNotifierProvider(
              create: (context) => DeviceChanges(device),
              child: _consumer(context),
            );
          } else {
            return const Text('Connecting...');
          }
        });
  }

  Widget _consumer(BuildContext context) {
    return Consumer<DeviceChanges>(
      builder: (context, deviceChanges, _) =>
          _page(context, deviceChanges.device),
    );
  }

  Widget _page(BuildContext context, oppo.Device device) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: const Center(child: Text('Oppo Remote'))),
        body: Column(
          children: [
            ElevatedButton(onPressed: device.queryPowerStatus, child: const Text('query power')),
            ElevatedButton(onPressed: device.queryFirmwareVersion, child: const Text('query firmware')),
            ElevatedButton(onPressed: device.powerOn, child: const Text('power on')),
            Text(device.name),
            Text(device.firmwareVersion ?? 'unknown'),
            Text(device.powered?.toString() ?? 'pending'),
          ],
        ),
      ),
    );
  }
}
