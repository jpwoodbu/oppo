import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../oppo.dart' as oppo;
import '../preferences.dart';
import 'connect.dart';
import 'util.dart';

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
          if (isApple(context)) {
            showCupertinoDialog(
                context: context,
                builder: (BuildContext context) => const ManuallyConnect());
          } else {
            showDialog(
                context: context,
                builder: (BuildContext context) => const ManuallyConnect());
          }
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
                              ? Text(
                                  'Last used',
                                  style: Theme.of(context).textTheme.bodySmall,
                                )
                              : null,
                          onTap: () => _connect(context, e),
                          onLongPress: () async {
                            final result = await showDialog<oppo.OppoID?>(
                              context: context,
                              builder: (BuildContext context) =>
                                  AlertDialog.adaptive(
                                title: const Text('Remove device'),
                                content: const Text(
                                    'Remove device from list of discovered devices?'),
                                actions: [
                                  isApple(context)
                                      ? CupertinoDialogAction(
                                          onPressed: () =>
                                              Navigator.pop(context, null),
                                          child: const Text('Cancel'))
                                      : TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, null),
                                          child: const Text('Cancel'),
                                        ),
                                  isApple(context)
                                      ? CupertinoDialogAction(
                                          onPressed: () =>
                                              Navigator.pop(context, e),
                                          isDestructiveAction: true,
                                          child: const Text('Remove'))
                                      : TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, e),
                                          child: const Text('Remove'),
                                        ),
                                ],
                              ),
                            );
                            if (result != null) {
                              // If the device to remove is the one saved as the
                              // last device, clear it.
                              if (e.address.address == lastDeviceAddress) {
                                await clearLastDevice();
                              }
                              setState(() {
                                ids.remove(e);
                              });
                            }
                          },
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
}

void _connect(BuildContext context, oppo.OppoID id) {
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

class ManuallyConnect extends StatefulWidget {
  const ManuallyConnect({super.key});

  @override
  State<ManuallyConnect> createState() => _ManuallyConnectState();
}

class _ManuallyConnectState extends State<ManuallyConnect> {
  late TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog.adaptive(
      title: const Text('Manually connect'),
      content: isApple(context)
          ? CupertinoTextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              // This is a workaround for the text being dark on dark when using
              // a dark theme (the only theme this app uses).
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              placeholder: 'Enter an IPv4 address',
              suffix: _errorText == null
                  ? null
                  : Text(
                      _errorText!,
                      style: const TextStyle(color: Colors.red),
                    ),
            )
          : TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter an IPv4 address',
                errorText: _errorText,
              ),
            ),
      actions: [
        isApple(context)
            ? CupertinoDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              )
            : TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
        isApple(context)
            ? CupertinoDialogAction(
                onPressed: () {
                  oppo.OppoID? id;
                  final address = _controller.text;
                  try {
                    id = oppo.OppoID(
                        InternetAddress(
                          address,
                          type: InternetAddressType.IPv4,
                        ),
                        23,
                        'Manually added');
                  } catch (e) {
                    setState(() {
                      _errorText = 'Invalid address';
                    });
                  }
                  if (id != null) _connect(context, id);
                },
                child: const Text('Connect'),
              )
            : TextButton(
                onPressed: () {
                  oppo.OppoID? id;
                  final address = _controller.text;
                  try {
                    id = oppo.OppoID(
                        InternetAddress(
                          address,
                          type: InternetAddressType.IPv4,
                        ),
                        23,
                        'Manually added');
                  } catch (e) {
                    setState(() {
                      _errorText = 'Invalid address';
                    });
                  }
                  if (id != null) _connect(context, id);
                },
                child: const Text('Connect'),
              ),
      ],
    );
  }
}
