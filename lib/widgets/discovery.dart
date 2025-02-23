import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../oppo.dart' as oppo;
import '../preferences.dart';
import 'connect.dart';

class DiscoveryChanges with ChangeNotifier {
  final oppo.Discover discover;
  late Stream<oppo.OppoID> _stream;
  final Set<oppo.OppoID> devices = {};

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

class ScanForDevices extends StatelessWidget {
  const ScanForDevices({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.input),
        onPressed: () {
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog.adaptive(
                  title: const Text('Manually connect'),
                  content: const TextField(
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    decoration:
                        InputDecoration(hintText: 'Enter an IPv4 address'),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text('Connect'),
                    ),
                  ],
                );
              });
        },
      ),
      body: SafeArea(
        child: Semantics(
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
                    onPressed: () => Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (_) => const FakeConnect()),
                        (Route<dynamic> route) => false),
                    child: const Text('Demo mode'),
                  ),
                ],
              ),
              const SizedBox(height: 25.0),
              const LinearProgressIndicator(),
              const SizedBox(height: 25.0),
              const Devices(),
            ],
          ),
        ),
      ),
    );
  }
}

class Devices extends StatefulWidget {
  const Devices({super.key});

  @override
  State<Devices> createState() => _DevicesState();
}

class _DevicesState extends State<Devices> {
  late oppo.Discover _discover;
  final Future<SharedPreferences> _sharedPreferences =
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
      create: (_) => DiscoveryChanges(_discover),
      builder: (context, _) {
        final ids = context.watch<DiscoveryChanges>().devices;
        return FutureBuilder(
          future: _sharedPreferences,
          builder: (_, AsyncSnapshot<SharedPreferences> snapshot) {
            // [lastDeviceAddress] is also used in the [Column] below to
            // conditionally mark a device as being the one we connected to
            // last.
            String? lastDeviceAddress;
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              final p = Preferences(snapshot.data!);
              lastDeviceAddress = p.lastDeviceAddress;
              if (lastDeviceAddress != null &&
                  p.lastDeviceName != null &&
                  p.lastDevicePort != null) {
                ids.add(
                  oppo.OppoID(
                    InternetAddress(lastDeviceAddress),
                    p.lastDevicePort!,
                    p.lastDeviceName!,
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
      },
    );
  }

  void _connect(oppo.OppoID id) {
    // [saveLastDevice] is an async func but making [_connect] async, causes a
    // warning when passing [context] to Navigator below.
    saveLastDevice(id);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => Connect(
          device: oppo.Device(id.name, id.address, id.port),
        ),
      ),
      (Route<dynamic> route) => false,
    );
  }
}
