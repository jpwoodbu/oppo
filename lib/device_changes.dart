import 'dart:async';

import 'package:logging/logging.dart';
import 'package:flutter/material.dart';

import 'oppo.dart';

final _log = Logger('DeviceChanges');

class DeviceChanges with ChangeNotifier {
  final Device device;
  final BuildContext _context;
  late StreamSubscription<String> _subscription;
  var _connected = true;
  late final AppLifecycleListener _lifecycleListener;
  AppLifecycleState _state = AppLifecycleState.detached;

  DeviceChanges(this.device, this._context) {
    _subscription = _startListener();
    _lifecycleListener = AppLifecycleListener(
      onStateChange: (value) {
        _state = value;
        _log.info('State change: $value');
      },
      onRestart: _reconnect,
    );
  }

  @override
  void dispose() {
    _subscription.cancel();
    _lifecycleListener.dispose();
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
        _connected = false;
      },
      onError: (e) {
        _log.severe(e);
        _connected = false;
        // Reconnection attempts have been observed (somehow) when the app is
        // paused. They, of course, fail.
        if (_state != AppLifecycleState.paused) {
          _reconnect();
        }
      },
      cancelOnError: true,
    );
    _log.fine('Device changes listener started.');
    return subscription;
  }

  void _reconnect() async {
    _log.info('_reconnect called. _connected is $_connected');
    if (_connected) return;
    _log.info('Trying to reconnect.');
    await device.close();
    try {
        await device.connect();
    } catch (e) {
      _log.severe('Reconnect error: $e');
      _snackBar('Failed to reconnect.');
      _routeToScanner();
      return;
    }
    _connected = true;
    _log.info('Reconnected.');
    _subscription = _startListener();
    await device.fetchState();
  }

  void _routeToScanner() {
    Navigator.pushNamedAndRemoveUntil(_context, '/scan', (route) => false);
  }

  void _snackBar(String message) {
    ScaffoldMessenger.of(_context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
