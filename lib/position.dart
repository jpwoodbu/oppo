import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'device_changes.dart';
import 'oppo.dart' as oppo;

const _iconSize = 20.0;
const _scrubPadding = 2.0;

class Position extends StatefulWidget {
  const Position({super.key});

  @override
  State<Position> createState() => _PositionState();
}

class _PositionState extends State<Position> {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'playback position, e.g. elapsed track time',
      child: Consumer<DeviceChanges>(
        builder: (_, deviceChanges, ___) {
          final device = deviceChanges.device;
          if (device.powered ?? false) {
            return const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                PlaybackStatusIcon(),
                Clock(),
                SizedBox(width: _iconSize, height: _iconSize),
              ],
            );
          } else {
            return const SizedBox();
          }
        },
      ),
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

class Clock extends StatelessWidget {
  const Clock({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceChanges>(
      builder: (_, deviceChanges, ___) {
        final p = deviceChanges.device.position;
        if (p == null) {
          return const SizedBox(height: _iconSize, width: _iconSize);
        }
        return Row(
          children: [
            const Rewind(),
            Text('${p.timeInformation.displayName}: ${p.clock}',
                style: Theme.of(context).textTheme.bodySmall),
            const FastForward(),
          ],
        );
      },
    );
  }
}

class Rewind extends StatelessWidget {
  const Rewind({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<DeviceChanges, oppo.PlaybackStatus?>(
      selector: (_, deviceChanges) => deviceChanges.device.playbackStatus,
      builder: (_, playbackStatus, __) {
        switch (playbackStatus) {
          case oppo.PlaybackStatus.reverseFrameByFrame ||
                oppo.PlaybackStatus.fastReverse1 ||
                oppo.PlaybackStatus.fastReverse2 ||
                oppo.PlaybackStatus.fastReverse3 ||
                oppo.PlaybackStatus.fastReverse4 ||
                oppo.PlaybackStatus.fastReverse5 ||
                oppo.PlaybackStatus.slowReverseHalf ||
                oppo.PlaybackStatus.slowReverseQuarter ||
                oppo.PlaybackStatus.slowReverseEighth ||
                oppo.PlaybackStatus.slowReverseSixteenth ||
                oppo.PlaybackStatus.slowReverseThirtySecond:
            return const Padding(
              padding: EdgeInsets.only(right: _scrubPadding),
              child: PositionIcon(icon: Icons.fast_rewind),
            );
          default:
            return const Padding(
              padding: EdgeInsets.only(right: _scrubPadding),
              child: SizedBox(height: _iconSize, width: _iconSize),
            );
        }
      },
    );
  }
}

class FastForward extends StatelessWidget {
  const FastForward({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<DeviceChanges, oppo.PlaybackStatus?>(
      selector: (_, deviceChanges) => deviceChanges.device.playbackStatus,
      builder: (_, playbackStatus, __) {
        switch (playbackStatus) {
          case oppo.PlaybackStatus.forwardFrameByFrame ||
                oppo.PlaybackStatus.fastForward1 ||
                oppo.PlaybackStatus.fastForward2 ||
                oppo.PlaybackStatus.fastForward3 ||
                oppo.PlaybackStatus.fastForward4 ||
                oppo.PlaybackStatus.fastForward5 ||
                oppo.PlaybackStatus.slowForwardHalf ||
                oppo.PlaybackStatus.slowForwardQuarter ||
                oppo.PlaybackStatus.slowForwardEighth ||
                oppo.PlaybackStatus.slowForwardSixteenth ||
                oppo.PlaybackStatus.slowForwardThirtySecond:
            return const Padding(
              padding: EdgeInsets.only(left: _scrubPadding),
              child: PositionIcon(icon: Icons.fast_forward),
            );
          default:
            return const Padding(
              padding: EdgeInsets.only(left: _scrubPadding),
              child: SizedBox(height: _iconSize, width: _iconSize),
            );
        }
      },
    );
  }
}

class PlaybackStatusIcon extends StatelessWidget {
  const PlaybackStatusIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<DeviceChanges, oppo.PlaybackStatus?>(
      selector: (_, deviceChanges) => deviceChanges.device.playbackStatus,
      builder: (_, playbackStatus, __) {
        const noIcon = SizedBox(width: _iconSize, height: _iconSize);
        switch (playbackStatus) {
          case oppo.PlaybackStatus.noDisc:
            return const PositionIcon(icon: Icons.disc_full);
          case oppo.PlaybackStatus.loadingDisc:
            return const PositionIcon(icon: Icons.downloading);
          case oppo.PlaybackStatus.openTray:
            return Icon(Icons.eject,
                size: _iconSize, color: Theme.of(context).colorScheme.tertiary);
          case oppo.PlaybackStatus.closingTray:
            return const PositionIcon(icon: Icons.eject);
          case oppo.PlaybackStatus.playbackStarted:
            return const PositionIcon(icon: Icons.play_arrow);
          case oppo.PlaybackStatus.playbackPaused:
            return const PositionIcon(icon: Icons.pause);
          case oppo.PlaybackStatus.playbackStopped:
            return const PositionIcon(icon: Icons.stop);
          case oppo.PlaybackStatus.homeMenu:
            return const PositionIcon(icon: Icons.home);
          case oppo.PlaybackStatus.mediaCenter:
            return const PositionIcon(icon: Icons.folder_open);
          case oppo.PlaybackStatus.screenSaver:
            return const PositionIcon(icon: Icons.animation);
          case oppo.PlaybackStatus.discMenu:
            return const PositionIcon(icon: Icons.menu_book);
          case oppo.PlaybackStatus.dlna:
            return const PositionIcon(icon: Icons.cast);
          default:
            return noIcon;
        }
      },
    );
  }
}
