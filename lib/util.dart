import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const double borderRadius = 4.0;

dynamic addHaptic(Function function) {
  HapticFeedback.lightImpact();
  return function();
}

class IconVertical extends StatelessWidget {
  final String label;
  final Icon icon;
  const IconVertical({super.key, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        icon,
      ],
    );
  }
}
