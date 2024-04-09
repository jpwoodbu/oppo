import 'package:flutter/material.dart';

import 'oppo.dart' as oppo;

class Position extends StatelessWidget {
  final oppo.Device device;
  const Position(this.device, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = device.position;
    final style = Theme.of(context).textTheme.bodySmall;
    if (p == null) {
      return SizedBox();
    }
    final bool displayExtras =
        p.timeInformation == oppo.TimeInformation.titleElapsedTime;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (displayExtras) Text('T: ${p.title}', style: style),
        if (displayExtras) Text('C: ${p.chapter}', style: style),
        Text('${p.timeInformation.displayName}: ${p.clock}', style: style),
      ],
    );
  }
}