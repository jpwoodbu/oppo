import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:oppo/device_changes.dart';
import 'package:oppo/widgets/util.dart';

const _iconSize = 20.0;
const _scrubPadding = 2.0;

class Position extends StatelessWidget {
  const Position({super.key});

  @override
  Widget build(BuildContext context) {
    final device = context.watch<DeviceChanges>().device;
    return Semantics(
      label: 'playback position, e.g. elapsed track time',
      child: device.powered ?? false
          ? const Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                PlaybackStatusIcon(),
                ClockRow(),
                SizedBox(width: _iconSize, height: _iconSize),
              ],
            )
          : const SizedBox(),
    );
  }
}

class PositionIcon extends StatelessWidget {
  const PositionIcon({super.key, required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Icon(icon, size: _iconSize);
  }
}

class ClockRow extends StatelessWidget {
  const ClockRow({super.key});

  @override
  Widget build(BuildContext context) {
    return const Row(children: [Rewind(), Clock(), FastForward()]);
  }
}

class Clock extends StatefulWidget {
  const Clock({super.key});

  @override
  State<Clock> createState() => _ClockState();
}

class _ClockState extends State<Clock> {
  bool _largeMode = false;

  @override
  Widget build(BuildContext context) {
    final p = context.select((DeviceChanges d) => d.device.position);
    if (p == null) {
      return const SizedBox(height: _iconSize, width: _iconSize);
    }

    final textTheme = Theme.of(context).textTheme;
    final style = _largeMode ? textTheme.bodyLarge : textTheme.bodySmall;
    return GestureDetector(
      onLongPress: () {
        addHaptic(() {
          setState(() {
            _largeMode = !_largeMode;
          });
        });
      },
      // Hide the time information type (e.g. elapsed vs. remaining time) on
      // very small screens and in large mode. At 346 logical pixels there's not
      // room for all the widgets on a single row. We're using MediaQuery here
      // instead of LayoutBuilder because this widget is wrapped in a Row which
      // has an infinite max width.
      child: !_largeMode && MediaQuery.sizeOf(context).width > 346.0
          ? Text('${p.timeInformation.displayName}: ${p.clock}', style: style)
          : Text(p.clock, style: style),
    );
  }
}

class Rewind extends StatelessWidget {
  const Rewind({super.key});

  @override
  Widget build(BuildContext context) {
    final playbackStatus = context.select(
      (DeviceChanges d) => d.device.playbackStatus,
    );
    switch (playbackStatus) {
      case .reverseFrameByFrame ||
          .fastReverse1 ||
          .fastReverse2 ||
          .fastReverse3 ||
          .fastReverse4 ||
          .fastReverse5 ||
          .slowReverseHalf ||
          .slowReverseQuarter ||
          .slowReverseEighth ||
          .slowReverseSixteenth ||
          .slowReverseThirtySecond:
        return const Padding(
          padding: .only(right: _scrubPadding),
          child: PositionIcon(icon: Icons.fast_rewind),
        );
      default:
        return const Padding(
          padding: .only(right: _scrubPadding),
          child: SizedBox(height: _iconSize, width: _iconSize),
        );
    }
  }
}

class FastForward extends StatelessWidget {
  const FastForward({super.key});

  @override
  Widget build(BuildContext context) {
    final playbackStatus = context.select(
      (DeviceChanges d) => d.device.playbackStatus,
    );
    switch (playbackStatus) {
      case .forwardFrameByFrame ||
          .fastForward1 ||
          .fastForward2 ||
          .fastForward3 ||
          .fastForward4 ||
          .fastForward5 ||
          .slowForwardHalf ||
          .slowForwardQuarter ||
          .slowForwardEighth ||
          .slowForwardSixteenth ||
          .slowForwardThirtySecond:
        return const Padding(
          padding: .only(left: _scrubPadding),
          child: PositionIcon(icon: Icons.fast_forward),
        );
      default:
        return const Padding(
          padding: .only(left: _scrubPadding),
          child: SizedBox(height: _iconSize, width: _iconSize),
        );
    }
  }
}

class PlaybackStatusIcon extends StatelessWidget {
  const PlaybackStatusIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final playbackStatus = context.select(
      (DeviceChanges d) => d.device.playbackStatus,
    );
    const noIcon = SizedBox(width: _iconSize, height: _iconSize);
    switch (playbackStatus) {
      case .noDisc:
        return const PositionIcon(icon: Icons.disc_full);
      case .loadingDisc:
        return const PositionIcon(icon: Icons.downloading);
      case .openTray:
        return Icon(
          Icons.eject,
          size: _iconSize,
          color: Theme.of(context).colorScheme.tertiary,
        );
      case .closingTray:
        return const PositionIcon(icon: Icons.eject);
      case .playbackStarted:
        return const PositionIcon(icon: Icons.play_arrow);
      case .playbackPaused:
        return const PositionIcon(icon: Icons.pause);
      case .playbackStopped:
        return const PositionIcon(icon: Icons.stop);
      case .homeMenu:
        return const PositionIcon(icon: Icons.home);
      case .mediaCenter:
        return const PositionIcon(icon: Icons.folder_open);
      case .screenSaver:
        return const PositionIcon(icon: Icons.animation);
      case .discMenu:
        return const PositionIcon(icon: Icons.menu_book);
      case .dlna:
        return const PositionIcon(icon: Icons.cast);
      default:
        return noIcon;
    }
  }
}
