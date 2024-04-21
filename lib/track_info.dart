import 'package:flutter/material.dart';

import 'oppo.dart' as oppo;

class _Responses {
  final String album;
  final String name;
  final String performer;

  const _Responses(this.album, this.name, this.performer);
}

class TrackMetadata extends StatelessWidget {
  final oppo.Device device;
  const TrackMetadata({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    final errorStyle = TextStyle(color: errorColor);
    return FutureBuilder(
      future: _fetchInfo(),
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
          return Column(
            children: [
              InfoRow(header: 'Performer', value: snapshot.data!.performer),
              InfoRow(header: 'Album', value: snapshot.data!.album),
              InfoRow(header: 'Track', value: snapshot.data!.name),
            ],
          );
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }

  Future<_Responses> _fetchInfo() async {
    final album = await device.queryTrackAlbum();
    final name = await device.queryTrackName();
    final performer = await device.queryTrackPerformer();
    return _Responses(album, name, performer);
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
