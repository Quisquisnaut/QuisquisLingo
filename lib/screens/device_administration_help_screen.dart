import 'package:flutter/material.dart';

import '../localization/help/help_structure.dart';
import '../localization/help/help_text.dart';
import '../localization/locale_builder.dart';
import '../widgets/app_locale_selector.dart';

/// Help for the Device Administration page.
class DeviceAdministrationHelpScreen extends StatelessWidget {
  const DeviceAdministrationHelpScreen({super.key});

  @override
  Widget build(BuildContext context) => LocaleBuilder(
    builder: (context, locale) => Scaffold(
      appBar: AppBar(
        title: Text(helpText.lookup(locale, 'deviceAdminHelp.title')),
        actions: [
          AppLocaleSelector(
            key: const Key('device-admin-help-locale-selector'),
            locale: locale,
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              key: const Key('admin-help-list'),
              padding: const EdgeInsets.all(16),
              children: [
                for (final sectionId in deviceAdminHelpSectionIds)
                  _Section(
                    title: helpText.lookup(
                      locale,
                      'deviceAdminHelp.$sectionId.title',
                    ),
                    paragraphs: [
                      for (
                        var index = 1;
                        index <=
                            deviceAdminHelpSectionShape[sectionId]!.paragraphs;
                        index++
                      )
                        helpText.lookup(
                          locale,
                          'deviceAdminHelp.$sectionId.paragraph$index',
                        ),
                    ],
                    bullets: [
                      for (
                        var index = 1;
                        index <=
                            deviceAdminHelpSectionShape[sectionId]!.bullets;
                        index++
                      )
                        helpText.lookup(
                          locale,
                          'deviceAdminHelp.$sectionId.bullet$index',
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _Section extends StatelessWidget {
  final String title;
  final List<String> paragraphs;
  final List<String> bullets;

  const _Section({
    required this.title,
    this.paragraphs = const [],
    this.bullets = const [],
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        for (final paragraph in paragraphs)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(paragraph),
          ),
        for (final bullet in bullets)
          Padding(
            padding: const EdgeInsets.only(left: 8, bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  '),
                Expanded(child: Text(bullet)),
              ],
            ),
          ),
      ],
    ),
  );
}
