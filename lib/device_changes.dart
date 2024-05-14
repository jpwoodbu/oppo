import 'dart:async';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:flutter/material.dart';
import 'package:retry/retry.dart';

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
    try {
      final r = RetryOptions(maxAttempts: 3);
      await r.retry(
        device.connect,
        retryIf: (e) => e is SocketException || e is TimeoutException,
        onRetry: (_) => _snackBar('Reconnecting...'),
      );
    } catch (e) {
      _snackBar('Failed to reconnect.');
      _log.severe('Reconnect error: $e');
      _routeToScanner();
      return;
    }
    _log.info('Reconnected.');
    _subscription = _startListener();
    await device.fetchState();
  }

  void _routeToScanner() {
    Navigator.pushNamedAndRemoveUntil(_context, '/scan', (route) => false);
  }

  void _snackBar(String message) {
    _log.warning(message);
    ScaffoldMessenger.of(_context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
