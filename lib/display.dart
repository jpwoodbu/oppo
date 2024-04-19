import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'device_changes.dart';
import 'oppo.dart' as oppo;

const String _noInformation = '--';

// TODO - To keep the display height fixed, always show something for each
// field.

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
                Title(device: device),
                Chapter(device: device),
              ]),
              PaddedRow(children: [
                AudioType(device: device),
                Muted(device: device),
              ]),
              PaddedRow(children: [
                AudioTrack(device: device),
                Subtitles(device: device),
              ]),
              PaddedRow(children: [
                ContentResolution(device: device),
                OutputResolution(device: device),
              ]),
            ],
          ),
        );
      },
    );
  }
}

class Title extends StatelessWidget {
  const Title({super.key, required this.device});

  final oppo.Device device;

  @override
  Widget build(BuildContext context) {
    if (device.position == null || device.position!.title == 0) {
      return const Text('Title: $_noInformation');
    }
    switch (device.discType) {
      case oppo.DiscType.cd || oppo.DiscType.dvdAudio || oppo.DiscType.sacd:
        return Text('Track: ${device.position!.title}');
      default:
        return Text('Title: ${device.position!.title}');
    }
  }
}

class Chapter extends StatelessWidget {
  const Chapter({super.key, required this.device});
  final oppo.Device device;

  @override
  Widget build(BuildContext context) {
    if (device.position == null || device.position!.chapter == 0) {
      return const Text('Chapter: $_noInformation');
    }
    switch (device.discType) {
      case oppo.DiscType.cd || oppo.DiscType.dvdAudio || oppo.DiscType.sacd:
        return const SizedBox();
      default:
        return Text('Chapter: ${device.position!.chapter}');
    }
  }
}

class AudioTrack extends StatelessWidget {
  const AudioTrack({super.key, required this.device});
  final oppo.Device device;

  @override
  Widget build(BuildContext context) {
    if (device.currentAudioTrack == null || device.currentAudioTrack == 0) {
      return const Text('Audio: $_noInformation');
    }
    final language = device.audioLanguage == 'UNK' ? '' : device.audioLanguage;
    return Text('Audio: ${device.currentAudioTrack}/'
        '${device.availableAudioTracks} ${language ?? ""}');
  }
}

class AudioType extends StatelessWidget {
  const AudioType({super.key, required this.device});
  final oppo.Device device;

  @override
  Widget build(BuildContext context) {
    if (device.audioType == oppo.AudioType.unknown) {
      return const Text('Audio stream: $_noInformation');
    }
    final channels = device.channels == '0.0' ? '' : device.channels;
    return Text('${device.audioType.displayName} '
        '${channels ?? ""} '
        '${device.audioExtraInfo ?? ""}');
  }
}

class Muted extends StatelessWidget {
  const Muted({super.key, required this.device});
  final oppo.Device device;

  @override
  Widget build(BuildContext context) {
    if (device.muted ?? false) {
      return const Text('Muted');
    }
    return SizedBox();
  }
}

class Subtitles extends StatelessWidget {
  const Subtitles({super.key, required this.device});
  final oppo.Device device;

  @override
  Widget build(BuildContext context) {
    if (device.currentSubtitleTrack == null) {
      return const Text('Subtitles: $_noInformation');
    }
    return Text('Subtitles: ${device.currentSubtitleTrack}/'
        '${device.availableSubtitleTracks} ${device.subtitleLanguage}');
  }
}

class ContentResolution extends StatelessWidget {
  const ContentResolution({super.key, required this.device});
  final oppo.Device device;

  @override
  Widget build(BuildContext context) {
    if (device.contentResolution == null) {
      return const Text('In: $_noInformation');
    }
    final aspectRatio = device.aspectRatioSetting == null
        ? ''
        : device.aspectRatioSetting!.ratio.displayName;
    return Text('In: ${device.contentResolution!.displayName} $aspectRatio');
  }
}

class OutputResolution extends StatelessWidget {
  const OutputResolution({super.key, required this.device});
  final oppo.Device device;

  @override
  Widget build(BuildContext context) {
    if (device.outputResolution == null) {
      return const Text('Out: $_noInformation');
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
