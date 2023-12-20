import 'package:logging/logging.dart';
import 'package:flutter/material.dart';

import 'oppo.dart';

final _log = Logger('DeviceChanges');

class DeviceChanges with ChangeNotifier {
  final Device device;
  late Stream<String> _stream;

  DeviceChanges(this.device) {
    _stream = device.stream();
    _handleMessages();
    _log.info('Handling messages.');
  }

  Future<void> _handleMessages() async {
    await for (final message in _stream) {
      device.parseMessage(message);
      notifyListeners();
    }
  }
}