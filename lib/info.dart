import 'package:flutter/material.dart';

const EdgeInsets padding = EdgeInsets.symmetric(horizontal: 20.0);

String help1 = '''
'''.trim();

const String knownIssuesHeader = "Oppo hasn't sold these players since 2018. They stopped developing the firmware soon thereafter. Unsurprisingly, there are some quirks with using their IP control API, including missing features and stability issues.";

const String knownIssue1 = "1. Only a single IP remote can be connected to the player at a time.";
const String knownIssue2 = "2. The API docs don't include how to turn off HDR.";
const String knownIssue3 = "3. The API severely truncates track metadata. If you see a trailing asterisk on metadata fields, it has been truncated by the player.";
const String knownIssue4 = "4. The API does not provide a way to directly select a directory item. Due to this and the truncation of directory items, this app does not include a directory viewer.";

class Help extends StatelessWidget {
  const Help({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(),
        body: Padding(
          padding: padding,
          child: ListView(
            children: [
              Text(help1),
            ],
          ),
        ),
      ),
    );
  }
}

class KnownIssues extends StatelessWidget {
  const KnownIssues({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(),
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
            ],
          ),
        ),
      ),
    );
  }
}
