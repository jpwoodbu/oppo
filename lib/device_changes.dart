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
      onDone: () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Socket done.')),
        );
      },
      onError: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Socket error: $e\n')),
        );
        _log.severe(e);
        reconnect();
      },
    );
    _log.info('Listener started.');
  }

  void reconnect() async {
    _log.info('Reconnecting...');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reconnecting...')),
    );
    await device.close();
    // Don't attempt to reconnect more than once per second to avoid storming
    // the network.
    await Future.delayed(Duration(seconds: 1), device.connect);
    _showConnected();
    startListener();
  }

  /// This function is pulled out so that [context] can be fetched from a scope
  /// outside of an async gap. Putting this code in-line in [reconnect]
  /// generates a warning.
  void _showConnected() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reconnected.')),
    );
  }
}
