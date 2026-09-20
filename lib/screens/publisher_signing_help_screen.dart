import 'package:flutter/material.dart';

import 'publisher_signing_help_content.dart';

class PublisherSigningHelpScreen extends StatelessWidget {
  const PublisherSigningHelpScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text(publisherSigningGuideTitle)),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final (index, section) in publisherSigningGuideSections.indexed)
          Card(
            child: index == 0
                ? Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          section.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        _GuideBody(section.body),
                      ],
                    ),
                  )
                : ExpansionTile(
                    key: PageStorageKey('publisher-guide-$index'),
                    title: Text(section.title),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [_GuideBody(section.body)],
                  ),
          ),
      ],
    ),
  );
}

class _GuideBody extends StatelessWidget {
  const _GuideBody(this.body);

  final String body;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (index, paragraph) in body.split('\n\n').indexed)
        Padding(
          padding: const EdgeInsets.only(top: 12),
          child: SelectableText(
            paragraph,
            // Keep text scroll offsets separate from the parent tile's
            // persisted expanded/collapsed boolean.
            key: PageStorageKey('publisher-paragraph-$index'),
            style:
                (paragraph.startsWith('openssl ') ||
                    paragraph.startsWith('dart ') ||
                    paragraph.startsWith('flutter '))
                ? const TextStyle(fontFamily: 'monospace')
                : null,
          ),
        ),
    ],
  );
}
