import 'dart:io';

class OppoBroadcast {
  InternetAddress address;
  String name;

  OppoBroadcast(this.address, this.name);
}

Stream<OppoBroadcast> discover() async* {
  // Setup a listening socket for broadcast UDP port 7624.
  // Their docs say the broadcast is addressed to 239.255.255.251, but wireshark
  // is showing their addressed to 255.255.255.255. Packets are sent by a
  // powered on Oppo UDP-203 every 10s. I actually saw it send out a pair of
  // identical packets every 10s.
}

OppoBroadcast _parseBroadcast(data) {

}
