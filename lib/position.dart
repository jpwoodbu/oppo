import 'package:flutter/material.dart';

import 'oppo.dart' as oppo;

class Position extends StatefulWidget {
  final oppo.Device _device;
  const Position(this._device, {super.key});

  @override
  State<Position> createState() => _PositionState();
}

class _PositionState extends State<Position> {
  static const _iconSize = 20.0;
  static const _scrubPadding = 2.0;
  late Color _iconColor;

  @override
  Widget build(BuildContext context) {
    // TODO - Create a local icon factory to set their size and color.
    _iconColor = Theme.of(context).colorScheme.onPrimaryContainer;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _playbackStatusIcon(context),
        _clock(context),
        SizedBox(width: _iconSize, height: _iconSize),
      ],
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
            oppo.PlaybackStatus.fastReverse5:
        return Padding(
          padding: const EdgeInsets.only(right: _scrubPadding),
          child: Icon(Icons.fast_rewind, size: _iconSize, color: _iconColor),
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
            oppo.PlaybackStatus.slowForwardThirtySecond ||
            oppo.PlaybackStatus.fastForwardHalf ||
            oppo.PlaybackStatus.fastForwardQuarter ||
            oppo.PlaybackStatus.fastForwardEighth ||
            oppo.PlaybackStatus.fastForwardSixteenth ||
            oppo.PlaybackStatus.fastForwardThirtySecond:
        return Padding(
          padding: const EdgeInsets.only(left: _scrubPadding),
          child: Icon(Icons.fast_forward, size: _iconSize, color: _iconColor),
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
        return Icon(Icons.disc_full, size: _iconSize, color: _iconColor);
      case oppo.PlaybackStatus.loadingDisc:
        return Icon(Icons.downloading, size: _iconSize, color: _iconColor);
      case oppo.PlaybackStatus.openTray:
        return Icon(Icons.eject,
            size: _iconSize, color: Theme.of(context).colorScheme.tertiary);
      case oppo.PlaybackStatus.closingTray:
        return Icon(Icons.eject, size: _iconSize, color: _iconColor);
      case oppo.PlaybackStatus.playbackStarted:
        return Icon(Icons.play_arrow, size: _iconSize, color: _iconColor);
      case oppo.PlaybackStatus.playbackPaused:
        return Icon(Icons.pause, size: _iconSize, color: _iconColor);
      case oppo.PlaybackStatus.playbackStopped:
        return Icon(Icons.stop, size: _iconSize, color: _iconColor);
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
            oppo.PlaybackStatus.slowForwardThirtySecond ||
            oppo.PlaybackStatus.fastForwardHalf ||
            oppo.PlaybackStatus.fastForwardQuarter ||
            oppo.PlaybackStatus.fastForwardEighth ||
            oppo.PlaybackStatus.fastForwardSixteenth ||
            oppo.PlaybackStatus.fastForwardThirtySecond:
        return noIcon;
      case oppo.PlaybackStatus.reverseFrameByFrame ||
            oppo.PlaybackStatus.fastReverse1 ||
            oppo.PlaybackStatus.fastReverse2 ||
            oppo.PlaybackStatus.fastReverse3 ||
            oppo.PlaybackStatus.fastReverse4 ||
            oppo.PlaybackStatus.fastReverse5:
        return noIcon;
      case oppo.PlaybackStatus.homeMenu:
        return Icon(Icons.home, size: _iconSize, color: _iconColor);
      case oppo.PlaybackStatus.mediaCenter:
        return Icon(Icons.folder_open, size: _iconSize, color: _iconColor);
      case oppo.PlaybackStatus.screenSaver:
        return Icon(Icons.animation, size: _iconSize, color: _iconColor);
      case oppo.PlaybackStatus.discMenu:
        return Icon(Icons.album, size: _iconSize, color: _iconColor);
      case oppo.PlaybackStatus.dlna:
        return Icon(Icons.cast, size: _iconSize, color: _iconColor);
      default:
        return noIcon;
    }
  }
}
