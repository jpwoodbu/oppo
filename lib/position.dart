import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'device_changes.dart';
import 'oppo.dart' as oppo;

const _iconSize = 20.0;

class Position extends StatefulWidget {
  final oppo.Device _device;
  const Position(this._device, {super.key});

  @override
  State<Position> createState() => _PositionState();
}

class _PositionState extends State<Position> {
  static const _scrubPadding = 2.0;

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceChanges>(
      builder: (_, __, ___) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _playbackStatusIcon(context),
            _clock(context),
            SizedBox(width: _iconSize, height: _iconSize),
          ],
        );
      },
    );
  }

  Widget _clock(BuildContext context) {
    final p = widget._device.position;
    final style = Theme.of(context).textTheme.bodySmall;
    if (p == null) {
      return SizedBox(height: _iconSize, width: _iconSize);
    }
    return Row(
      children: [
        _rewind(context),
        Text('${p.timeInformation.displayName}: ${p.clock}', style: style),
        _fastForward(context),
      ],
    );
  }

  Widget _rewind(BuildContext context) {
    switch (widget._device.playbackStatus) {
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
        return Padding(
          padding: const EdgeInsets.only(right: _scrubPadding),
          child: PositionIcon(icon: Icons.fast_rewind),
        );
      default:
        return Padding(
          padding: const EdgeInsets.only(right: _scrubPadding),
          child: SizedBox(height: _iconSize, width: _iconSize),
        );
    }
  }

  Widget _fastForward(BuildContext context) {
    switch (widget._device.playbackStatus) {
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
        return Padding(
          padding: const EdgeInsets.only(left: _scrubPadding),
          child: PositionIcon(icon: Icons.fast_forward),
        );
      default:
        return Padding(
          padding: const EdgeInsets.only(left: _scrubPadding),
          child: SizedBox(height: _iconSize, width: _iconSize),
        );
    }
  }

  Widget _playbackStatusIcon(BuildContext context) {
    final noIcon = SizedBox(width: _iconSize, height: _iconSize);
    switch (widget._device.playbackStatus) {
      case oppo.PlaybackStatus.noDisc:
        return PositionIcon(icon: Icons.disc_full);
      case oppo.PlaybackStatus.loadingDisc:
        return PositionIcon(icon: Icons.downloading);
      case oppo.PlaybackStatus.openTray:
        return Icon(Icons.eject,
            size: _iconSize, color: Theme.of(context).colorScheme.tertiary);
      case oppo.PlaybackStatus.closingTray:
        return PositionIcon(icon: Icons.eject);
      case oppo.PlaybackStatus.playbackStarted:
        return PositionIcon(icon: Icons.play_arrow);
      case oppo.PlaybackStatus.playbackPaused:
        return PositionIcon(icon: Icons.pause);
      case oppo.PlaybackStatus.playbackStopped:
        return PositionIcon(icon: Icons.stop);
      case oppo.PlaybackStatus.homeMenu:
        return PositionIcon(icon: Icons.home);
      case oppo.PlaybackStatus.mediaCenter:
        return PositionIcon(icon: Icons.folder_open);
      case oppo.PlaybackStatus.screenSaver:
        return PositionIcon(icon: Icons.animation);
      case oppo.PlaybackStatus.discMenu:
        return PositionIcon(icon: Icons.menu_book);
      case oppo.PlaybackStatus.dlna:
        return PositionIcon(icon: Icons.cast);
      default:
        return noIcon;
    }
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
