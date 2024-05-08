import 'package:flutter/material.dart';

import 'oppo.dart' as oppo;

class TrackMetadata extends StatelessWidget {
  final oppo.Device device;
  const TrackMetadata({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    final errorStyle = TextStyle(color: errorColor);
    return FutureBuilder(
      future: device.getMusicPlayInfo(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
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
          return Column(
            children: [
              if (id3Info.artist.isNotEmpty)
                InfoRow(header: 'Artist', value: id3Info.artist),
              if (id3Info.album.isNotEmpty)
                InfoRow(header: 'Album', value: id3Info.album),
              if (id3Info.title.isNotEmpty)
                InfoRow(header: 'Title', value: id3Info.title),
              if (id3Info.year.isNotEmpty)
                InfoRow(header: 'Year', value: id3Info.year),
            ],
          );
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }
}

class InfoRow extends StatelessWidget {
  final String header;
  final String value;
  const InfoRow({super.key, required this.header, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(header),
        Text(value),
      ],
    );
  }
}
