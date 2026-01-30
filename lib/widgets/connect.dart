import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:oppo/device_changes.dart';
import 'package:oppo/oppo.dart' as oppo;
import 'package:oppo/widgets/discovery.dart';
import 'package:oppo/widgets/home.dart';

class FakeConnect extends StatelessWidget {
  const FakeConnect({super.key});

  @override
  Widget build(BuildContext context) {
    return Connect(
      device: oppo.FakeDevice('Fake device', InternetAddress('1.2.3.4'), 123),
    );
  }
}

class Connect extends StatefulWidget {
  final oppo.Device device;

  const Connect({required this.device, super.key});

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
        if (snapshot.connectionState == .done) {
          if (snapshot.hasError) {
            return const ConnectionError();
          }
          return ChangeNotifierProvider<DeviceChanges>(
            create: (_) => DeviceChanges(widget.device, context),
            // The child Widget depends on [DeviceChanges] being fully set up
            // ahead of time.
            lazy: false,
            child: const HomePage(),
          );
        } else {
          return const Scaffold(body: Center(child: Text('Connecting...')));
        }
      },
    );
  }
}

class ConnectionError extends StatelessWidget {
  const ConnectionError({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: .center,
            children: [
              const Text('Error connecting to device.'),
              TextButton(
                onPressed: () => Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const ScanForDevices()),
                  (Route<dynamic> route) => false,
                ),
                child: const Text('Scan for players'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
