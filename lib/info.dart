import 'package:flutter/material.dart';

const EdgeInsets padding = EdgeInsets.all(20.0);

String help1 = '''
Placeholder.
'''.trim();

String ki1 = '''
1. The API doesn't allow turning off HDR.

2. The API severely truncates track metadata. If you see a trailing asterisk on metadata fields, it has been truncated by the player.
'''.trim();

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
              Text(ki1),
            ],
          ),
        ),
      ),
    );
  }
}
