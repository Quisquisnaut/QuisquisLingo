import 'package:flutter/material.dart';
import '../widgets/help_language_toggle.dart';
import 'credits_screen.dart';
import 'info_screen_content.dart';

/// Human-readable explanation of learning metrics and game rules.
///
/// Available in English and Italian. The chosen language lasts as long as the
/// page is open; it is not stored, so it adds no preference key.
class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  HelpLanguage _language = HelpLanguage.english;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Info'),
      actions: [
        HelpLanguageToggle(
          key: const Key('app-info-language-toggle'),
          language: _language,
          onChanged: (value) => setState(() => _language = value),
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
        for (final section in infoSections(_language))
          _InfoSection(title: section.title, body: section.body),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CreditsScreen())),
          icon: const Icon(Icons.attribution_outlined),
          label: Text(infoCreditsButtonLabel(_language)),
        ),
      ],
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
