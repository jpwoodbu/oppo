import 'package:flutter/material.dart';

import 'oppo.dart' as oppo;

class Display extends StatelessWidget {
  final oppo.Device device;
  const Display(this.device, {super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _playbackStatusIcon(context),
        Text('${device.audioType?.displayName ?? "audio type"} '
            '${device.channels ?? "channels"}'),
        Text('Audio Track: ${device.currentAudioTrack}/'
            '${device.availableAudioTracks} ${device.audioLanguage}'),
        if (device.muted ?? false) const Text('Muted'),
        if (device.volume != null) Text('Volume: ${device.volume}'),
        Text('Disc type: ${device.discType.displayName}'),
        // TODO - Probably should remove this. It doesn't get set unless the
        // input source is changed, which is probably going to be rare.
        if (device.inputSourceName != null)
          Text('Input: ${device.inputSourceName}'),
        Text('Content: ${device.contentResolution?.displayName}'),
        Text('Ouput: ${device.outputResolution?.displayName}'),
        if (device.threeDimensional) const Text('3D'),
        Text('Subtitle Track: ${device.currentSubtitleTrack}/'
            '${device.availableSubtitleTracks} ${device.subtitleLanguage}'),
        Text('Apect ratio: ${device.aspectRatioSetting?.ratio.displayName}'),
        Text('Mode: ${device.aspectRatioSetting?.mode.displayName}'),
        Text('Playback: ${device.aspectRatioSetting?.playback.displayName}'),
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
        return Icon(Icons.folder_open);
      case oppo.PlaybackStatus.screenSaver:
        return Icon(Icons.animation);
      case oppo.PlaybackStatus.discMenu:
        return Icon(Icons.album);
      case oppo.PlaybackStatus.dlna:
        return Icon(Icons.cast);
      default:
        return Icon(null);
    }
  }
}
