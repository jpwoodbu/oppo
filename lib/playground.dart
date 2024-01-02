import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'oppo.dart' as oppo;
import 'device_changes.dart';

class Playground extends StatelessWidget {
  const Playground({super.key});

  @override
  Widget build(BuildContext context) {
    return _consumer(context);
  }

  Widget _consumer(BuildContext context) {
    return Consumer<DeviceChanges>(
      builder: (context, deviceChanges, _) =>
          _playground(context, deviceChanges.device),
    );
  }

  Widget _playground(BuildContext context, oppo.Device device) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('playback status'),
          Text(device.playbackStatus.toString())
        ],
      ),
    );
  }
}
