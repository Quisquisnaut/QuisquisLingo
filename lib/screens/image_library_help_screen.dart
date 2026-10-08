import 'package:flutter/material.dart';

import '../localization/help/help_structure.dart';
import '../localization/help/help_text.dart';
import '../localization/locale_builder.dart';
import '../widgets/app_locale_selector.dart';

/// Help for the image library (Shared Images and a Course's Image Library),
/// opened from its question mark (Build 264 Revision 10, owner request of 6
/// October 2026: the explanations no longer fill the top of the page).
class ImageLibraryHelpScreen extends StatelessWidget {
  const ImageLibraryHelpScreen({super.key});

  @override
  Widget build(BuildContext context) => LocaleBuilder(
    builder: (context, locale) => Scaffold(
      appBar: AppBar(
        title: Text(helpText.lookup(locale, 'imageLibraryHelp.title')),
        actions: [
          AppLocaleSelector(
            key: const Key('image-library-help-locale-selector'),
            locale: locale,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              key: const Key('image-library-help-list'),
              padding: const EdgeInsets.all(16),
              children: [
                for (final sectionId in imageLibraryHelpSectionIds)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          helpText.lookup(
                            locale,
                            'imageLibraryHelp.$sectionId.title',
                          ),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        for (
                          var index = 1;
                          index <= imageLibraryHelpParagraphs[sectionId]!;
                          index++
                        )
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              helpText.lookup(
                                locale,
                                'imageLibraryHelp.$sectionId.paragraph$index',
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
