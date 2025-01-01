import 'package:flutter/material.dart';

const String knownIssuesHeader =
    "Oppo hasn't sold Blu-ray players in the US since 2018. Firmware updates stopped soon thereafter. Unsurprisingly, there are some quirks with using their network control API, including incomplete functionality and stability issues.";

const String knownIssue1 =
    "1. The documented API does not provide a way to directly select a directory item. This app does not implement a directory/file viewer, since without item selection, it wouldn't be sufficiently useful.";
const String knownIssue2 =
    "2. The player often returns \"unknown\" for the audio type even when the OSD will display it.";
const String knownIssue3 =
    "3. Only a single IP remote can be connected to the player at a time.";

class KnownIssues extends StatelessWidget {
  const KnownIssues({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Semantics(
        label: 'list of known issues',
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Known issues'),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ListView(
              children: const [
                Text(knownIssuesHeader),
                Divider(),
                Text(knownIssue1),
                Divider(),
                Text(knownIssue2),
                Divider(),
                Text(knownIssue3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
