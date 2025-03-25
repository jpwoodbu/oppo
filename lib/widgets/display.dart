import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:oppo/device_changes.dart';
import 'package:oppo/oppo.dart' as oppo;

const String _kNoInformation = '--';

class Display extends StatefulWidget {
  const Display({super.key});

  @override
  State<Display> createState() => _DisplayState();
}

class _DisplayState extends State<Display> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return DefaultTextStyle.merge(
      style: Theme.of(context).textTheme.bodySmall,
      child: Semantics(
        label: 'display of player information',
        child: const Column(
          children: [
            PaddedRow(children: [
              Title(),
              Chapter(),
            ]),
            PaddedRow(children: [
              AudioType(),
              Muted(),
            ]),
            PaddedRow(children: [
              AudioTrack(),
              Subtitles(),
            ]),
            PaddedRow(children: [
              ContentResolution(),
              OutputResolution(),
            ]),
          ],
        ),
      ),
    );
  }
}

class Title extends StatelessWidget {
  const Title({super.key});

  @override
  Widget build(BuildContext context) {
    final position = context.select((DeviceChanges d) => d.device.position);
    final discType = context.select((DeviceChanges d) => d.device.discType);
    if (position == null || position.title == 0) {
      return const Text('Title: $_kNoInformation');
    }
    switch (discType) {
      case oppo.DiscType.cd || oppo.DiscType.dvdAudio || oppo.DiscType.sacd:
        return Text('Track: ${position.title}');
      default:
        return Text('Title: ${position.title}');
    }
  }
}

class Chapter extends StatelessWidget {
  const Chapter({super.key});

  @override
  Widget build(BuildContext context) {
    final position = context.select((DeviceChanges d) => d.device.position);
    final discType = context.select((DeviceChanges d) => d.device.discType);
    if (position == null || position.chapter == 0) {
      return const Text('Chapter: $_kNoInformation');
    }
    switch (discType) {
      case oppo.DiscType.cd || oppo.DiscType.dvdAudio || oppo.DiscType.sacd:
        return const SizedBox();
      default:
        return Text('Chapter: ${position.chapter}');
    }
  }
}

class AudioTrack extends StatelessWidget {
  const AudioTrack({super.key});

  @override
  Widget build(BuildContext context) {
    final currentAudioTrack =
        context.select((DeviceChanges d) => d.device.currentAudioTrack);
    final availableAudioTracks =
        context.select((DeviceChanges d) => d.device.availableAudioTracks);
    final audioLanguage =
        context.select((DeviceChanges d) => d.device.audioLanguage);
    if (currentAudioTrack == null || currentAudioTrack == 0) {
      return const Text('Audio: $_kNoInformation');
    }
    final language = audioLanguage == 'UNK' ? '' : audioLanguage;
    return Text('Audio: $currentAudioTrack/'
        '$availableAudioTracks ${language ?? ""}');
  }
}

class AudioType extends StatelessWidget {
  const AudioType({super.key});

  @override
  Widget build(BuildContext context) {
    final audioType = context.select((DeviceChanges d) => d.device.audioType);
    final audioExtraInfo =
        context.select((DeviceChanges d) => d.device.audioExtraInfo);
    final rawChannels = context.select((DeviceChanges d) => d.device.channels);
    final channels = rawChannels == '0.0' ? '' : rawChannels;
    if (audioType == oppo.AudioType.unknown) {
      return const Text('Audio stream: $_kNoInformation');
    }
    return Text('${audioType.displayName} '
        '${channels ?? ""} '
        '${audioExtraInfo ?? ""}');
  }
}

class Muted extends StatelessWidget {
  const Muted({super.key});

  @override
  Widget build(BuildContext context) {
    final muted = context.select((DeviceChanges d) => d.device.muted);
    if (muted ?? false) {
      return const Text('Muted');
    }
    return const SizedBox();
  }
}

class Subtitles extends StatelessWidget {
  const Subtitles({super.key});

  @override
  Widget build(BuildContext context) {
    final currentSubtitleTrack =
        context.select((DeviceChanges d) => d.device.currentSubtitleTrack);
    final availableSubtitleTracks =
        context.select((DeviceChanges d) => d.device.availableSubtitleTracks);
    final subtitleLanguage =
        context.select((DeviceChanges d) => d.device.subtitleLanguage);
    if (currentSubtitleTrack == null) {
      return const Text('Subtitles: $_kNoInformation');
    }
    return Text('Subtitles: $currentSubtitleTrack/'
        '$availableSubtitleTracks $subtitleLanguage');
  }
}

class ContentResolution extends StatelessWidget {
  const ContentResolution({super.key});

  @override
  Widget build(BuildContext context) {
    final contentResolution =
        context.select((DeviceChanges d) => d.device.contentResolution);
    final aspectRatioSetting =
        context.select((DeviceChanges d) => d.device.aspectRatioSetting);
    if (contentResolution == null) {
      return const Text('In: $_kNoInformation');
    }
    final aspectRatio =
        aspectRatioSetting == null ? '' : aspectRatioSetting.ratio.displayName;
    return Text('In: ${contentResolution.displayName} $aspectRatio');
  }
}

class OutputResolution extends StatelessWidget {
  const OutputResolution({super.key});

  @override
  Widget build(BuildContext context) {
    final outputResolution =
        context.select((DeviceChanges d) => d.device.outputResolution);
    if (outputResolution == null) {
      return const Text('Out: $_kNoInformation');
    }
    return Text('Out: ${outputResolution.displayName}');
  }
}

class PaddedRow extends StatelessWidget {
  const PaddedRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    const alignment = MainAxisAlignment.spaceBetween;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.0),
      child: Row(
        mainAxisAlignment: alignment,
        children: children,
      ),
    );
  }
}
