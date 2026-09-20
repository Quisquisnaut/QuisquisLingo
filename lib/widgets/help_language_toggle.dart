import 'package:flutter/material.dart';

/// The languages a translated Help or Info page can be shown in.
///
/// QuisquisLingo's interface itself stays in English. These pages are
/// translated on their own, so on-screen names such as Course Selector or
/// Save as draft are always quoted in English inside the Italian text: the
/// reader has to find them on an English screen.
enum HelpLanguage {
  english,
  italian;

  HelpLanguage get other => this == HelpLanguage.english
      ? HelpLanguage.italian
      : HelpLanguage.english;

  /// The name of [other], written in [other]'s own language, because it
  /// labels a control that takes the reader there.
  String get otherLabel =>
      this == HelpLanguage.english ? 'Italiano' : 'English';

  String get otherTooltip => this == HelpLanguage.english
      ? 'Leggi questa pagina in italiano'
      : 'Read this page in English';
}

/// Switches a Help or Info page between English and Italian.
///
/// Deliberately page-local: the choice lasts as long as the page is open and
/// is not stored, so it adds no preference key and nothing to reset.
class HelpLanguageToggle extends StatelessWidget {
  const HelpLanguageToggle({
    super.key,
    required this.language,
    required this.onChanged,
  });

  final HelpLanguage language;
  final ValueChanged<HelpLanguage> onChanged;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: language.otherTooltip,
    child: TextButton.icon(
      onPressed: () => onChanged(language.other),
      icon: const Icon(Icons.translate),
      label: Text(language.otherLabel),
      style: TextButton.styleFrom(
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
    ),
  );
}
