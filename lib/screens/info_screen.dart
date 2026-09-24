import 'package:flutter/material.dart';
import '../localization/help/help_text.dart';
import '../localization/locale_builder.dart';
import '../widgets/app_locale_selector.dart';
import 'credits_screen.dart';
import 'info_screen_content.dart';

/// Human-readable explanation of learning metrics and game rules.
class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) => LocaleBuilder(
    builder: (context, locale) => Scaffold(
      appBar: AppBar(
        title: Text(helpText.lookup(locale, 'appInfo.title')),
        actions: [
          AppLocaleSelector(
            key: const Key('app-info-language-toggle'),
            locale: locale,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
        children: [
          Semantics(
            image: true,
            label: 'QuisquisLingo logo',
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Image.asset(
                'assets/branding/quisquislingo_logo.png',
                key: const Key('app-info-full-logo'),
                width: double.infinity,
                height: 96,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ),
          for (final section in infoSections(locale))
            _InfoSection(title: section.title, body: section.body),
          OutlinedButton.icon(
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CreditsScreen())),
            icon: const Icon(Icons.attribution_outlined),
            label: Text(infoCreditsButtonLabel(locale)),
          ),
        ],
      ),
    ),
  );
}

class _InfoSection extends StatelessWidget {
  final String title;
  final String body;
  const _InfoSection({required this.title, required this.body});

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(body),
        ],
      ),
    ),
  );
}
