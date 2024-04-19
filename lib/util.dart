import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const double borderRadius = 4.0;
const dialogPadding = EdgeInsets.all(12.0);


dynamic addHaptic(Function function) {
  HapticFeedback.lightImpact();
  return function();
}

class VerticalIcon extends StatelessWidget {
  final String label;
  final Icon icon;
  final bool small;
  const VerticalIcon(
      {super.key, required this.label, required this.icon, this.small = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textScaler: TextScaler.linear(small ? 0.8 : 1.0),
        ),
        icon,
      ],
    );
  }
}
