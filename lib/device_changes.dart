import 'package:logging/logging.dart';
import 'package:flutter/material.dart';

import 'oppo.dart';

final _log = Logger('DeviceChanges');

class DeviceChanges with ChangeNotifier {
  final Device device;
  final BuildContext context;

  DeviceChanges(this.device, this.context) {
    startListener();
  }

  void startListener() {
    device.stream().listen(
      (event) {
        device.parseEvent(event);
        notifyListeners();
      },
      onDone: () =>_snackBar('Socket done.'),
      onError: (e) {
        _snackBar('Socket error: $e\n', logLevel: Level.SEVERE);
        _log.severe(e);
        reconnect();
      },
    );
    _log.info('Listener started.');
  }

  void reconnect() async {
    _snackBar('Reconnecting...');
    await device.close();
    // Don't attempt to reconnect more than once per second to avoid storming
    // the network.
    await Future.delayed(Duration(seconds: 1), device.connect);
    _snackBar('Reconnected.');
    startListener();
  }

  void _snackBar(String message, {logLevel = Level.INFO}) {
    _log.log(logLevel, message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
