import 'package:flutter/material.dart';

import '../localization/help/help_destinations.dart';
import '../localization/locale_builder.dart';
import '../widgets/app_locale_selector.dart';
import 'info_screen.dart';

/// Settings entry point for the shared Help language and standalone guides.
class QqlGuideScreen extends StatelessWidget {
  const QqlGuideScreen({super.key});

  @override
  Widget build(BuildContext context) => LocaleBuilder(
    builder: (context, locale) => Scaffold(
      appBar: AppBar(title: const Text('QQL Guide')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          ListTile(
            key: const Key('qql-guide-language'),
            title: const Text('Help Language'),
            subtitle: const Text(
              'Help and Course Info language for this learner.',
            ),
            trailing: AppLocaleSelector(
              key: const Key('qql-guide-language-selector'),
              locale: locale,
            ),
          ),
          ListTile(
            key: const Key('qql-guide-app-info'),
            leading: const Icon(Icons.help_outline),
            title: const Text('App Info'),
            subtitle: const Text('Learning rules, metrics and app behavior.'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const InfoScreen())),
          ),
          const Divider(),
          for (final destination in QqlGuideHelpDestinations.sortedFor(locale))
            ListTile(
              key: Key('qql-guide-help-${destination.id}'),
              title: Text(destination.titleFor(locale)),
              subtitle: destination.englishOnly
                  ? const Text('English only')
                  : null,
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: destination.build)),
            ),
        ],
      ),
    ),
  );
}
