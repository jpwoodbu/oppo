import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

import '../oppo.dart' as oppo;
import 'util.dart';

final _log = Logger('track_info');

class TrackMetadata extends StatelessWidget {
  final oppo.Device device;
  const TrackMetadata({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    final errorStyle = TextStyle(color: errorColor);
    return SimpleDialog(
      contentPadding: dialogPadding,
      children: [
        FutureBuilder(
          future: device.getMusicLocalId3Info(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              _log.warning('Error fetching track metadata: ${snapshot.error}');
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (id3Info.artist.isNotEmpty) Text(id3Info.artist),
                  if (id3Info.album.isNotEmpty) Text(id3Info.album),
                  if (id3Info.title.isNotEmpty) Text(id3Info.title),
                  if (id3Info.year.isNotEmpty) Text(id3Info.year),
                ],
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ),
      ],
    );
  }
}
