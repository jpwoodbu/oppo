import 'package:flutter/material.dart';

import 'oppo.dart' as oppo;

class Position extends StatelessWidget {
  final oppo.Device device;
  static const iconSize = 20.0;
  const Position(this.device, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _playbackStatusIcon(context),
        _clock(context),
        SizedBox(width: 20.0),
      ],
    );
  }

  Widget _clock(BuildContext context) {
    final p = device.position;
    final style = Theme.of(context).textTheme.bodySmall;
    if (p == null) {
      return SizedBox();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        _rewind(context),
        Text('${p.timeInformation.displayName}: ${p.clock}', style: style),
        _fastForward(context),
      ],
    );
  }

  Widget _rewind(BuildContext context) {
    switch (device.playbackStatus) {
      case oppo.PlaybackStatus.reverseFrameByFrame ||
            oppo.PlaybackStatus.fastReverse1 ||
            oppo.PlaybackStatus.fastReverse2 ||
            oppo.PlaybackStatus.fastReverse3 ||
            oppo.PlaybackStatus.fastReverse4 ||
            oppo.PlaybackStatus.fastReverse5:
        return Padding(
          padding: const EdgeInsets.only(right: 1.0),
          child: Icon(Icons.fast_rewind, size: iconSize),
        );
      default:
        return SizedBox();
    }
  }

  Widget _fastForward(BuildContext context) {
    switch (device.playbackStatus) {
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
          padding: const EdgeInsets.only(left: 1.0),
          child: Icon(Icons.fast_forward, size: iconSize),
        );
      default:
        return SizedBox();
    }
  }

  Widget _playbackStatusIcon(BuildContext context) {
    switch (device.playbackStatus) {
      case oppo.PlaybackStatus.noDisc:
        return Icon(Icons.disc_full, size: iconSize);
      case oppo.PlaybackStatus.loadingDisc:
        return Icon(Icons.downloading);
      case oppo.PlaybackStatus.openTray:
        return Icon(Icons.eject, color: Theme.of(context).highlightColor);
      case oppo.PlaybackStatus.closingTray:
        return Icon(Icons.eject);
      case oppo.PlaybackStatus.playbackStarted:
        return Icon(Icons.play_arrow);
      case oppo.PlaybackStatus.playbackPaused:
        return Icon(Icons.pause);
      case oppo.PlaybackStatus.playbackStopped:
        return Icon(Icons.stop);
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
        return SizedBox();
      case oppo.PlaybackStatus.reverseFrameByFrame ||
            oppo.PlaybackStatus.fastReverse1 ||
            oppo.PlaybackStatus.fastReverse2 ||
            oppo.PlaybackStatus.fastReverse3 ||
            oppo.PlaybackStatus.fastReverse4 ||
            oppo.PlaybackStatus.fastReverse5:
        return SizedBox();
      case oppo.PlaybackStatus.homeMenu:
        return Icon(Icons.home, size: iconSize);
      case oppo.PlaybackStatus.mediaCenter:
        // TODO - I'm not sure what the media center context is. Once I know, I
        // can probably pick a better icon.
        return Icon(Icons.folder_open);
      case oppo.PlaybackStatus.screenSaver:
        return Icon(Icons.animation);
      case oppo.PlaybackStatus.discMenu:
        return Icon(Icons.album);
      case oppo.PlaybackStatus.dlna:
        return Icon(Icons.cast);
      default:
        return SizedBox(width: iconSize);
    }
  }
}
