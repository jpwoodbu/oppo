import 'package:logging/logging.dart';
import 'package:flutter/material.dart';

import 'oppo.dart';

final _log = Logger('DeviceChanges');

class DeviceChanges with ChangeNotifier {
  final Device device;

  DeviceChanges(this.device) {
    startListener();
  }

  void startListener() {
    device.stream().listen(
      (event) {
        device.parseEvent(event);
        notifyListeners();
      },
      onDone: reconnect,
      onError: (e) {
        _log.severe(e);
        reconnect();
      },
    );
    _log.info('Listener started.');
  }

  void reconnect() async {
    _log.info('Reconnecting.');
    await device.close();
    // Don't attempt to reconnect more than once per second to avoid storming
    // the network.
    await Future.delayed(Duration(seconds: 1), device.connect);
    startListener();
  }
}
