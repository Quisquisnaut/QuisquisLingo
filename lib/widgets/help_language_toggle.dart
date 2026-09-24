import 'package:flutter/material.dart';

import '../localization/locale_service.dart';

// Kept as a source-compatible alias while Help callers move to LocaleService.
typedef HelpLanguage = AppLocale;

/// Compatibility control for older callers. New pages use AppLocaleSelector.
class HelpLanguageToggle extends StatelessWidget {
  const HelpLanguageToggle({
    super.key,
    required this.language,
    required this.onChanged,
  });

  final HelpLanguage language;
  final ValueChanged<HelpLanguage> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonHideUnderline(
    child: DropdownButton<HelpLanguage>(
      value: language,
      items: [
        for (final option in HelpLanguage.values)
          DropdownMenuItem(value: option, child: Text(option.id)),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    ),
  );
}
