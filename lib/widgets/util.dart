import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const applicationName = 'Oppo Remote';
// Apple is complaining about using other's intellectual property.
const appleApplicationName = 'Remote Control';
const double borderRadius = 4.0;
const dialogPadding = EdgeInsets.all(12.0);
const mainViewPadding = EdgeInsets.symmetric(horizontal: 4.0);

T addHaptic<T>(T Function() function) {
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
          style: Theme.of(context).textTheme.titleSmall,
          textScaler: TextScaler.linear(small ? 0.8 : 1.0),
          overflow: TextOverflow.ellipsis,
        ),
        // Set the default icon size to 24.0. That used to be the default before
        // it changed in Flutter 3.27. The new default is a tad small for this
        // use case.
        IconTheme.merge(data: const IconThemeData(size: 24.0), child: icon),
      ],
    );
  }
}

bool isApple(BuildContext context) {
  final p = Theme.of(context).platform;
  return p == TargetPlatform.iOS || p == TargetPlatform.macOS;
}
