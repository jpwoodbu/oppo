import 'dart:async';

import 'package:logging/logging.dart';
import 'package:flutter/material.dart';

import 'oppo.dart';

final _log = Logger('DeviceChanges');

class DeviceChanges with ChangeNotifier {
  final Device device;
  final BuildContext _context;
  late StreamSubscription<String> _subscription;

  DeviceChanges(this.device, this._context) {
    _subscription = _startListener();
  }

  @override
  void dispose() {
    _subscription.cancel();
    _log.fine('Device changes listener stopped.');
    super.dispose();
  }

  StreamSubscription<String> _startListener() {
    final subscription = device.stream().listen(
      (event) {
        device.parseEvent(event);
        notifyListeners();
      },
      onDone: () {
        _log.info('disconnected.');
        _reconnect();
      },
      onError: (e) {
        _log.severe(e);
        _reconnect();
      },
      cancelOnError: true,
    );
    _log.fine('Device changes listener started.');
    return subscription;
  }

  void _reconnect() async {
    await device.close();
    // Don't attempt to reconnect more than once per second to avoid storming
    // the network.
    try {
      await Future.delayed(Duration(seconds: 1), device.connect);
    } catch (e) {
      _snackBar('Reconnect error: $e\n', logLevel: Level.SEVERE);
      _routeToScanner();
      return;
    }
    _snackBar('Reconnected.');
    _subscription = _startListener();
    await device.fetchState();
  }

  void _snackBar(String message, {logLevel = Level.INFO}) {
    _log.log(logLevel, message);
    ScaffoldMessenger.of(_context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _routeToScanner() {
    Navigator.pushNamedAndRemoveUntil(_context, '/scan', (route) => false);
  }
}
