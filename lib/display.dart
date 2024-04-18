import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'device_changes.dart';
import 'oppo.dart' as oppo;

class Display extends StatelessWidget {
  final oppo.Device device;
  const Display(this.device, {super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DeviceChanges>(
      builder: (_, __, ___) {
        return DefaultTextStyle.merge(
          style: Theme.of(context).textTheme.bodySmall,
          child: Column(
            children: [
              PaddedRow(children: [
                _title(context),
                _chapter(context),
              ]),
              PaddedRow(children: [
                _audioType(context),
                _muted(context),
              ]),
              PaddedRow(children: [
                _audioTrack(context),
                _subtitles(context),
              ]),
              PaddedRow(children: [
                _contentResolution(context),
                _outputResolution(context),
              ]),
            ],
          ),
        );
      },
    );
  }

  Widget _title(BuildContext context) {
    if (device.position == null || device.position!.title == 0) {
      return SizedBox();
    }
    switch (device.discType) {
      case oppo.DiscType.cd || oppo.DiscType.dvdAudio || oppo.DiscType.sacd:
        return Text('Track: ${device.position!.title}');
      default:
        return Text('Title: ${device.position!.title}');
    }
  }

  Widget _chapter(BuildContext context) {
    if (device.position == null || device.position!.chapter == 0) {
      return const SizedBox();
    }
    switch (device.discType) {
      case oppo.DiscType.cd || oppo.DiscType.dvdAudio || oppo.DiscType.sacd:
        return const SizedBox();
      default:
        return Text('Chapter: ${device.position!.chapter}');
    }
  }

  Widget _audioTrack(BuildContext context) {
    if (device.currentAudioTrack == null || device.currentAudioTrack == 0) {
      return const SizedBox();
    }
    final language = device.audioLanguage == 'UNK' ? '' : device.audioLanguage;
    return Text('Audio: ${device.currentAudioTrack}/'
        '${device.availableAudioTracks} ${language ?? ""}');
  }

  Widget _audioType(BuildContext context) {
    if (device.audioType == oppo.AudioType.unknown) {
      return const SizedBox();
    }
    final channels = device.channels == '0.0' ? '' : device.channels;
    return Text('${device.audioType.displayName} '
        '${channels ?? ""} '
        '${device.audioExtraInfo ?? ""}');
  }

  Widget _muted(BuildContext context) {
    if (device.muted ?? false) {
      return const Text('Muted');
    }
    return SizedBox();
  }

  Widget _subtitles(BuildContext context) {
    if (device.currentSubtitleTrack == null) {
      return const SizedBox();
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
}

class PaddedRow extends StatelessWidget {
  const PaddedRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    const alignment = MainAxisAlignment.spaceBetween;
    const padding = EdgeInsets.symmetric(vertical: 1.0);
    return Padding(
      padding: padding,
      child: Row(
        mainAxisAlignment: alignment,
        children: children,
      ),
    );
  }
}
