import 'package:flutter/material.dart';

import 'oppo.dart' as oppo;

import 'package:logging/logging.dart';

final _log = Logger('display');

class Display extends StatelessWidget {
  final oppo.Device device;
  const Display(this.device, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            _playbackStatusIcon(context),
            SizedBox(width: 8.0),
            Text(device.audioType?.displayName ?? ''),
            SizedBox(width: 8.0),
            Text(device.channels ?? ''),
          ],
        ),
        Text('Track: ${device.currentTrack}/${device.availableTracks}'),
        Text('Language: ${device.audioLanguage}'),
      ],
    );
  }

  Icon _playbackStatusIcon(BuildContext context) {
    switch (device.playbackStatus) {
      case oppo.PlaybackStatus.noDisc:
        return Icon(Icons.disc_full);
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
        return Icon(Icons.fast_forward);
      case oppo.PlaybackStatus.reverseFrameByFrame ||
            oppo.PlaybackStatus.fastReverse1 ||
            oppo.PlaybackStatus.fastReverse2 ||
            oppo.PlaybackStatus.fastReverse3 ||
            oppo.PlaybackStatus.fastReverse4 ||
            oppo.PlaybackStatus.fastReverse5:
        return Icon(Icons.fast_rewind);
      case oppo.PlaybackStatus.homeMenu:
        return Icon(Icons.home);
      case oppo.PlaybackStatus.mediaCenter:
        // TODO - I'm not sure what the media center context is. Once I know, I
        // can probably pick a better icon.
        return Icon(Icons.newspaper);
      case oppo.PlaybackStatus.screenSaver:
        return Icon(Icons.animation);
      case oppo.PlaybackStatus.discMenu:
        return Icon(Icons.album);
      case oppo.PlaybackStatus.dlna:
        return Icon(Icons.cast);
      default:
        _log.warning('Unknown playback status: ${device.playbackStatus}');
        return Icon(Icons.question_mark);
    }
  }
}
