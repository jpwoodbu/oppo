import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import 'package:oppo/oppo.dart' as oppo;
import 'package:oppo/widgets/util.dart';

final _log = Logger('track_info');

class TrackMetadata extends StatelessWidget {
  /// [oppo.Device] is passed rather than looked up via context. This widget is
  /// called by showDialog() which doesn't share its context with its widget
  /// builder. Therefore, we can't lookup a reference to [oppo.Device] using the
  /// provided context.
  final oppo.Device device;
  const TrackMetadata({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    final errorStyle = TextStyle(color: errorColor);
    final dialogAction = TextButton(
      onPressed: () => Navigator.pop(context),
      child: const Text('Close'),
    );
    final content = FutureBuilder(
      future: device.getMusicLocalId3Info(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          _log.warning('Error fetching track metadata: ${snapshot.error}');
          return Column(
            crossAxisAlignment: .start,
            children: [
              Text(
                'Error fetching track metadata.',
                style: errorStyle,
              ),
              Text(
                'Track info may not be available in this context through the '
                'API.',
                style: errorStyle,
              ),
            ],
          );
        }
        if (snapshot.hasData) {
          final id3Info = snapshot.data!;
          if (id3Info.isEmpty) {
            return const Text('Metadata not available.');
          }
          return Column(
            crossAxisAlignment: .start,
            children: [
              if (id3Info.artist.isNotEmpty) Text(id3Info.artist),
              if (id3Info.album.isNotEmpty) Text(id3Info.album),
              if (id3Info.title.isNotEmpty) Text(id3Info.title),
              if (id3Info.year.isNotEmpty) Text(id3Info.year),
            ],
          );
        }
        return const Center(child: CircularProgressIndicator.adaptive());
      },
    );

    if (isApple(context)) {
      return CupertinoAlertDialog(
        content: content,
        actions: [CupertinoDialogAction(child: dialogAction)],
      );
    } else {
      return SimpleDialog(
        contentPadding: dialogPadding,
        children: [
          content,
          Align(
            alignment: Alignment.centerRight,
            child: dialogAction,
          ),
        ],
      );
    }
  }
}
