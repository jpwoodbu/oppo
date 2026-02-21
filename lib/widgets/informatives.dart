import 'package:flutter/material.dart';

class InfoSection {
  final String title;
  final String body;

  const InfoSection(this.title, this.body);
}

class InformationPage extends StatelessWidget {
  final String title;
  final List<InfoSection> sections;

  const InformationPage({
    super.key,
    required this.title,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        minimum: const .symmetric(horizontal: 15.0),
        // Since we're using a scrollable widget, it's OK for the content to be
        // visible in the "unsafe" area at the bottom edge of the screen. And I
        // like the to-the-edge look.
        bottom: false,
        child: ListView.separated(
          itemBuilder: (context, index) =>
              _Item(title: sections[index].title, body: sections[index].body),
          separatorBuilder: (context, index) => const Divider(),
          itemCount: sections.length,
        ),
      ),
    );
  }
}

class _Item extends StatelessWidget {
  final String title;
  final String body;

  const _Item({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Padding(
          padding: const .only(bottom: 8.0),
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        Text(body),
      ],
    );
  }
}
