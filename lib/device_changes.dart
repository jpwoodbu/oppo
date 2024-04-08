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
    );
    _log.info('Listener started.');
  }

  void reconnect() async {
    _log.info('Reconnecting.');
    await device.close();
    await device.connect();
    startListener();
  }
}
