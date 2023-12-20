import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';

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
  // late Future<oppo.Device> _device;
  // late final AppLifecycleListener _listener;
  // oppo.Device? device;
  late oppo.Discover discover;

  @override
  void initState() {
    super.initState();
    discover = oppo.Discover();

    /*
    _listener = AppLifecycleListener(
      onExitRequested: () async {
        if (device != null) {
          _log.info('Disconnecting from Oppo.');
          await device?.close();
        }
        return AppExitResponse.exit;
      }
    );
    */
  }

  @override
  void dispose() async {
    super.dispose();
    // _listener.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => DiscoveryChanges(discover),
      child: const ChooseDevicePage(),
    );
  }
}

class ChooseDevicePage extends StatelessWidget {
  const ChooseDevicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DiscoveryChanges>(
      builder: (context, discoveryChanges, _) =>
          _build(context, discoveryChanges.devices),
    );
  }

  Widget _build(BuildContext context, Set<oppo.OppoBroadcast> devices) {
    return Scaffold(
      appBar: AppBar(title: const Center(child: Text('Oppo Remote'))),
      body: Column(children: devices.map((e) => Text(e.name)).toList()),
    );
  }
}
