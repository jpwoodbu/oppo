import 'package:flutter/material.dart';

import 'oppo.dart' as oppo;

class Position extends StatelessWidget {
  final oppo.Device _device;
  static const _iconSize = 20.0;
  static const _scrubPadding = 2.0;
  const Position(this._device, {super.key});

  @override
  Widget build(BuildContext context) {
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
    final p = _device.position;
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
    switch (_device.playbackStatus) {
      case oppo.PlaybackStatus.reverseFrameByFrame ||
            oppo.PlaybackStatus.fastReverse1 ||
            oppo.PlaybackStatus.fastReverse2 ||
            oppo.PlaybackStatus.fastReverse3 ||
            oppo.PlaybackStatus.fastReverse4 ||
            oppo.PlaybackStatus.fastReverse5:
        return Padding(
          padding: const EdgeInsets.only(right: _scrubPadding),
          child: Icon(Icons.fast_rewind, size: _iconSize),
        );
      default:
        return Padding(
          padding: const EdgeInsets.only(right: _scrubPadding),
          child: SizedBox(height: _iconSize, width: _iconSize),
        );
    }
  }

  Widget _fastForward(BuildContext context) {
    switch (_device.playbackStatus) {
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
          child: Icon(Icons.fast_forward, size: _iconSize),
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
    switch (_device.playbackStatus) {
      case oppo.PlaybackStatus.noDisc:
        return Icon(Icons.disc_full, size: _iconSize);
      case oppo.PlaybackStatus.loadingDisc:
        return Icon(Icons.downloading, size: _iconSize);
      case oppo.PlaybackStatus.openTray:
        return Icon(Icons.eject,
            size: _iconSize, color: Theme.of(context).highlightColor);
      case oppo.PlaybackStatus.closingTray:
        return Icon(Icons.eject, size: _iconSize);
      case oppo.PlaybackStatus.playbackStarted:
        return Icon(Icons.play_arrow, size: _iconSize);
      case oppo.PlaybackStatus.playbackPaused:
        return Icon(Icons.pause, size: _iconSize);
      case oppo.PlaybackStatus.playbackStopped:
        return Icon(Icons.stop, size: _iconSize);
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
        return Icon(Icons.home, size: _iconSize);
      case oppo.PlaybackStatus.mediaCenter:
        return Icon(Icons.folder_open, size: _iconSize);
      case oppo.PlaybackStatus.screenSaver:
        return Icon(Icons.animation, size: _iconSize);
      case oppo.PlaybackStatus.discMenu:
        return Icon(Icons.album, size: _iconSize);
      case oppo.PlaybackStatus.dlna:
        return Icon(Icons.cast, size: _iconSize);
      default:
        return noIcon;
    }
  }
}
