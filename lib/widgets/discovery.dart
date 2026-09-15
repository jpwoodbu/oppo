import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import 'package:oppo/oppo.dart' as oppo;
import 'package:oppo/preferences.dart';
import 'package:oppo/widgets/connect.dart';
import 'package:oppo/widgets/connection_help.dart';
import 'package:oppo/widgets/util.dart';

class DiscoveryChanges with ChangeNotifier {
  final Set<oppo.OppoID> devices = {};
  final Stream<oppo.OppoID> _stream;

  DiscoveryChanges(this._stream) {
    _stream.listen((oppo.OppoID broadcast) {
      devices.add(broadcast);
      notifyListeners();
    });
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
              builder: (BuildContext context) => const ManuallyConnect(),
            );
          } else {
            showDialog(
              context: context,
              builder: (BuildContext context) => const ManuallyConnect(),
            );
          }
        },
      ),
      body: SafeArea(
        child: Semantics(
          label:
              'list of discovered devices with '
              'option to enter demo mode',
          child: ListView(
            padding: const .all(25.0),
            children: [
              // On very narrow screens, wrapping is necessary.
              Wrap(
                alignment: .spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Device discovery',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      IconButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ConnectionHelp(),
                          ),
                        ),
                        icon: const Icon(Icons.help),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const FakeConnect()),
                      (Route<dynamic> route) => false,
                    ),
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
      create: (_) => DiscoveryChanges(_discover.stream()),
      builder: (context, _) {
        final ids = context.watch<DiscoveryChanges>().devices;
        final p = context.watch<Preferences>();
        final lastDeviceAddress = p.lastDeviceAddress;
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
                              'last device',
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
                                  'Remove device from list of discovered devices?',
                                ),
                                actions: [
                                  isApple(context)
                                      ? CupertinoDialogAction(
                                          onPressed: () =>
                                              Navigator.pop(context, null),
                                          child: const Text('Cancel'),
                                        )
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
                                          child: const Text('Remove'),
                                        )
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
  }
}

void _connect(BuildContext context, oppo.OppoID id) {
  // [saveLastDevice] is an async func but making [_connect] async, causes a
  // warning when passing [context] to Navigator below.
  saveLastDevice(id).ignore();
  Navigator.pushAndRemoveUntil(
    context,
    MaterialPageRoute(
      builder: (_) =>
          Connect(device: oppo.Device(id.name, id.address, id.port)),
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
  final _controller = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hintText = 'Enter an IPv4 address';
    return AlertDialog.adaptive(
      title: const Text('Manually connect'),
      content: isApple(context)
          ? Column(
              children: [
                if (_errorText != null)
                  Text(_errorText!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12.0),
                CupertinoTextField(
                  controller: _controller,
                  autofocus: true,
                  keyboardType: const .numberWithOptions(decimal: true),
                  placeholder: hintText,
                ),
              ],
            )
          : TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: .number,
              decoration: InputDecoration(
                hintText: hintText,
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
                onPressed: () => _onPressedConnect(),
                child: const Text('Connect'),
              )
            : TextButton(
                onPressed: () => _onPressedConnect(),
                child: const Text('Connect'),
              ),
      ],
    );
  }

  void _onPressedConnect() {
    oppo.OppoID? id;
    final address = _controller.text;
    try {
      id = oppo.OppoID(
        InternetAddress(address, type: InternetAddressType.IPv4),
        23,
        'Manually added',
      );
    } catch (e) {
      setState(() {
        _errorText = 'Invalid address';
      });
    }
    if (id != null) _connect(context, id);
  }
}
