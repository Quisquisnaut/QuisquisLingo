import 'package:flutter/material.dart';
import '../localization/help/help_text.dart';
import '../localization/locale_builder.dart';
import '../widgets/app_locale_selector.dart';
import '../widgets/enlarged_image_dialog.dart';
import '../widgets/help_language_toggle.dart';
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
            _InfoSection(
              key: ValueKey('app-info-section-${section.id}'),
              title: section.title,
              body: section.body,
              children: [
                if (section.id == 'pathColours')
                  _PathColoursPicture(locale: locale),
              ],
            ),
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
  final List<Widget> children;
  const _InfoSection({
    super.key,
    required this.title,
    required this.body,
    this.children = const [],
  });

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
          ...children,
        ],
      ),
    ),
  );
}

/// The owner's picture of the eight Lesson colours (Build 261 Revision 8).
/// It keeps its proportions while it loads; a tap opens it enlarged, where
/// it zooms with a pinch, since on a phone the inline picture is small.
class _PathColoursPicture extends StatelessWidget {
  final HelpLanguage locale;
  const _PathColoursPicture({required this.locale});

  @override
  Widget build(BuildContext context) {
    final label = helpText.lookup(locale, 'appInfo.pathColours.picture');
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Tooltip(
        message: helpText.lookup(locale, 'appInfo.pathColours.enlarge'),
        child: InkWell(
          key: const Key('app-info-path-colours-enlarge'),
          borderRadius: BorderRadius.circular(8),
          onTap: () => showEnlargedImage(
            context,
            dialogKey: const Key('app-info-path-colours-dialog'),
            closeKey: const Key('app-info-path-colours-close'),
            title: helpText.lookup(locale, 'appInfo.pathColours.title'),
            aspectRatio: appInfoPathColoursAspectRatio,
            closeTooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            builder: (_, width) => InteractiveViewer(
              maxScale: 4,
              child: Image.asset(
                appInfoPathColoursPicture,
                width: width,
                fit: BoxFit.contain,
                semanticLabel: label,
              ),
            ),
          ),
          child: AspectRatio(
            aspectRatio: appInfoPathColoursAspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                appInfoPathColoursPicture,
                key: const Key('app-info-path-colours-picture'),
                semanticLabel: label,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
