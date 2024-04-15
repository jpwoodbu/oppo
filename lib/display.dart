import 'package:flutter/material.dart';

import 'oppo.dart' as oppo;

class Display extends StatelessWidget {
  final oppo.Device device;
  const Display(this.device, {super.key});

  @override
  Widget build(BuildContext context) {
    return _buildSplitRows(context);
  }

  Widget _buildColumn(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
    if (device.muted ?? false) {
      return const Text('Muted');
    }
    if (device.volume == null) {
      return SizedBox();
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

  Widget _buildSplitRows(BuildContext context) {
    const alignment = MainAxisAlignment.spaceBetween;
    const padding = EdgeInsets.symmetric(vertical: 1.0);
    return DefaultTextStyle.merge(
      style: Theme.of(context).textTheme.bodySmall,
      child: Column(
        children: [
          Padding(
            padding: padding,
            child: Row(
              mainAxisAlignment: alignment,
              children: [
                _title(context),
                _chapter(context),
              ],
            ),
          ),
          Padding(
            padding: padding,
            child: Row(
              mainAxisAlignment: alignment,
              children: [
                _audioType(context),
                _volume(context),
              ],
            ),
          ),
          Padding(
            padding: padding,
            child: Row(
              mainAxisAlignment: alignment,
              children: [
                _audioTrack(context),
                _subtitles(context),
              ],
            ),
          ),
          Padding(
            padding: padding,
            child: Row(
              mainAxisAlignment: alignment,
              children: [
                _contentResolution(context),
                _outputResolution(context),
              ],
            ),
          ),
          Padding(
            padding: padding,
            child: Row(
              mainAxisAlignment: alignment,
              children: [_discType(context)],
            ),
          ),
        ],
      ),
    );
  }
}
