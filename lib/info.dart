import 'package:flutter/material.dart';

const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 20.0);

const String knownIssuesHeader =
    "Oppo hasn't sold Blu-ray players in the US since 2018. Firmware updates stopped soon thereafter. Unsurprisingly, there are some quirks with using their network control API, including incomplete functionality and stability issues.";

const String knownIssue1 =
    "1. Only a single IP remote can be connected to the player at a time.";
const String knownIssue2 =
    "2. The API always returns an error when trying to turn off HDR.";
const String knownIssue3 =
    "3. The API severely truncates track metadata. If you see a trailing asterisk on metadata fields, it has been truncated by the player.";
const String knownIssue4 =
    "4. The API does not provide a way to directly select a directory item. Due to this and the truncation mentioned above, this app does not implement a directory/file viewer.";
const String knownIssue5 =
    "5. The API often returns \"unknown\" for the audio type even when the OSD will display it.";

class KnownIssues extends StatelessWidget {
  const KnownIssues({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Known issues'),
        ),
        body: Padding(
          padding: padding,
          child: ListView(
            children: [
              Text(knownIssuesHeader),
              const Divider(),
              Text(knownIssue1),
              const Divider(),
              Text(knownIssue2),
              const Divider(),
              Text(knownIssue3),
              const Divider(),
              Text(knownIssue4),
              const Divider(),
              Text(knownIssue5),
            ],
          ),
        ),
      ),
    );
  }
}
