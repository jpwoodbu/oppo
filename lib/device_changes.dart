import 'package:logging/logging.dart';
import 'package:flutter/material.dart';

import 'oppo.dart';

final _log = Logger('DeviceChanges');

class DeviceChanges with ChangeNotifier {
  final Device device;
  final BuildContext _context;

  DeviceChanges(this.device, this._context) {
    _startListener();
  }

  void _startListener() {
    device.stream().listen(
      (event) {
        device.parseEvent(event);
        notifyListeners();
      },
      onError: (e) {
        _log.severe(e);
        _reconnect();
      },
    );
    _log.info('Listener started.');
  }

  void _reconnect() async {
    await device.close();
    // Don't attempt to reconnect more than once per second to avoid storming
    // the network.
    try {
      await Future.delayed(Duration(seconds: 1), device.connect);
    } catch (e) {
      _snackBar('Reconnect error: $e\n', logLevel: Level.SEVERE);
      _log.severe(e);
      return;
    }
    _snackBar('Reconnected.');
    _startListener();
    await device.fetchState();
  }

  void _snackBar(String message, {logLevel = Level.INFO}) {
    _log.log(logLevel, message);
    ScaffoldMessenger.of(_context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
