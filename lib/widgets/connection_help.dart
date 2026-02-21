import 'package:flutter/material.dart';

import 'package:oppo/widgets/informatives.dart';

const List<InfoSection> _sections = [
  InfoSection('Same network',
      'This device must be connected to the same network as the Oppo Blu-ray player.'),
  InfoSection('No VPN',
      "Make sure you don't have a VPN activated on this device while using this app."),
  InfoSection('Standby mode',
      'Try turning on the Oppo Blu-ray player before trying to connect to it with this app. When first plugged into power, the player may be in "standby" mode but won\'t be on the network until after its first boot up. Once on the network, if it\'s turned off from the IR remote or an app, it should remain on the network.'),
  InfoSection('Enable IP control',
      'In the Oppo settings, go to Setup > Network Setup > IP Control, and set it to "On".'),
  InfoSection('WiFi settings',
      'Check your WiFi router settings to ensure client isolation is disabled. This setting might be called something different on your WiFi router, but any setting that prevents the WiFi clients from talking to each other will break this app.'),
];

class ConnectionHelp extends StatelessWidget {
  const ConnectionHelp({super.key});

  @override
  Widget build(BuildContext context) {
    return const InformationPage(
        title: 'Troubleshooting tips', sections: _sections);
  }
}
