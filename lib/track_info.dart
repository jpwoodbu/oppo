import 'package:flutter/material.dart';

import 'oppo.dart' as oppo;
import 'util.dart';

class _FetchInfoResponse {
  final String album;
  final String name;
  final String performer;

  const _FetchInfoResponse(this.album, this.name, this.performer);
}

// TODO - Is this worth keeping? All the fields are normally truncated.
class TrackInfo extends StatelessWidget {
  final oppo.Device device;
  const TrackInfo({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _fetchInfo(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text('Error fetching track info');
        }
        if (snapshot.hasData) {
          return SimpleDialog(
            contentPadding: dialogPadding,
            title: const Text('Track info'),
            children: [
              InfoRow(header: 'Performer', value: snapshot.data!.performer),
              InfoRow(header: 'Album', value: snapshot.data!.album),
              InfoRow(header: 'Track', value: snapshot.data!.name),
              Align(
                heightFactor: 1.2,
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          );
        }
        return CircularProgressIndicator();
      },
    );
  }

  Future<_FetchInfoResponse> _fetchInfo() async {
    final album = await device.queryTrackAlbum();
    final name = await device.queryTrackName();
    final performer = await device.queryTrackPerformer();
    return _FetchInfoResponse(album, name, performer);
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
