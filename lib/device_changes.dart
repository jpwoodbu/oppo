import 'package:logging/logging.dart';
import 'package:flutter/material.dart';

import 'oppo.dart';

final _log = Logger('DeviceChanges');

class DeviceChanges with ChangeNotifier {
  final Device device;

  DeviceChanges(this.device) {
    device.stream().listen((message) {
      device.parseMessage(message);
      notifyListeners();
    });
    _log.fine('ChangeNotifier started.');
  }
}
