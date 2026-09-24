import 'package:flutter/material.dart';

import '../localization/help/help_structure.dart';
import '../localization/help/help_text.dart';
import '../localization/locale_builder.dart';
import '../widgets/app_locale_selector.dart';

class PublisherSigningHelpScreen extends StatelessWidget {
  const PublisherSigningHelpScreen({super.key});

  @override
  Widget build(BuildContext context) => LocaleBuilder(
    builder: (context, locale) => Scaffold(
      appBar: AppBar(
        title: Text(helpText.lookup(locale, 'publisherSigningHelp.title')),
        actions: [
          AppLocaleSelector(
            key: const Key('publisher-signing-help-locale-selector'),
            locale: locale,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final (index, sectionId)
              in publisherSigningHelpSectionIds.indexed)
            Card(
              child: index == 0
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            helpText.lookup(
                              locale,
                              'publisherSigningHelp.$sectionId.title',
                            ),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          _GuideBody(
                            helpText.lookup(
                              locale,
                              'publisherSigningHelp.$sectionId.body',
                            ),
                          ),
                        ],
                      ),
                    )
                  : ExpansionTile(
                      key: PageStorageKey('publisher-guide-$index'),
                      title: Text(
                        helpText.lookup(
                          locale,
                          'publisherSigningHelp.$sectionId.title',
                        ),
                      ),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _GuideBody(
                          helpText.lookup(
                            locale,
                            'publisherSigningHelp.$sectionId.body',
                          ),
                        ),
                      ],
                    ),
            ),
        ],
      ),
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
