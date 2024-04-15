import 'package:flutter/material.dart';

import 'oppo.dart' as oppo;

class Display extends StatelessWidget {
  final oppo.Device device;
  const Display(this.device, {super.key});

  @override
  Widget build(BuildContext context) {
    return _buildTable(context);
  }

  Widget _buildColumn(BuildContext context) {
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

  Widget _discType(BuildContext context) {
    if (device.discType == oppo.DiscType.unknown) {
      return SizedBox();
    }
    return Text(device.discType.displayName);
  }

  Widget _title(BuildContext context) {
    if (device.position == null) {
      return SizedBox();
    }
    return Text('Title: ${device.position!.title}');
  }

  Widget _chapter(BuildContext context) {
    if (device.position == null) {
      return SizedBox();
    }
    return Text('Chapter: ${device.position!.chapter}');
  }

  Widget _audioTrack(BuildContext context) {
    if (device.currentAudioTrack == null) {
      return SizedBox();
    }
    final language = device.audioLanguage == 'UNK' ? '' : device.audioLanguage;
    return Text('Audio: ${device.currentAudioTrack}/'
        '${device.availableAudioTracks} $language');
  }

  Widget _audioType(BuildContext context) {
    if (device.audioType == null) {
      return SizedBox();
    }
    final channels = device.channels == '0.0' ? '' : device.channels;
    return Text('${device.audioType!.displayName} $channels');
  }

  Widget _volume(BuildContext context) {
    if (device.volume == null) {
      return SizedBox();
    }
    if (device.muted ?? false) {
      return Icon(Icons.volume_mute);
    }
    return Text('Vol: ${device.volume}');
  }

  Widget _subtitles(BuildContext context) {
    if (device.currentAudioTrack == null) {
      return SizedBox();
    }
    return Text('Subtitles: ${device.currentSubtitleTrack}/'
        '${device.availableSubtitleTracks} ${device.subtitleLanguage}');
  }

  Widget _contentResolution(BuildContext context) {
    if (device.contentResolution == null) {
      return SizedBox();
    }
    final aspectRatio = device.aspectRatioSetting == null
        ? ''
        : device.aspectRatioSetting!.ratio.displayName;
    return Text('In: ${device.contentResolution!.displayName} $aspectRatio');
  }

  Widget _outputResolution(BuildContext context) {
    if (device.outputResolution == null) {
      return SizedBox();
    }
    return Text('Out: ${device.outputResolution!.displayName}');
  }

  Widget _tableCellPadder(Widget w) {
    return Padding(padding: const EdgeInsets.all(2.0), child: w);
  }

  Widget _buildTable(BuildContext context) {
    return Table(
      children: [
        TableRow(
          children: [
            _title(context),
            _chapter(context),
            _discType(context),
          ].map(_tableCellPadder).toList(),
        ),
        TableRow(
          children: [
            _audioTrack(context),
            _audioType(context),
            // When not playing anything, this is the only visible Widget in
            // this table and that's a bad look.
            _volume(context),
          ].map(_tableCellPadder).toList(),
        ),
        TableRow(
          children: [
            _subtitles(context),
            _contentResolution(context),
            _outputResolution(context),
          ].map(_tableCellPadder).toList(),
        ),
      ],
    );
  }
}
