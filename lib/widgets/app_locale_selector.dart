import 'package:flutter/material.dart';

import '../localization/locale_service.dart';

/// The same persisted Locale control used by Settings, Help and Course Info.
class AppLocaleSelector extends StatelessWidget {
  const AppLocaleSelector({super.key, required this.locale});

  final AppLocale locale;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Locale',
    child: DropdownButtonHideUnderline(
      child: DropdownButton<AppLocale>(
        value: locale,
        items: [
          for (final option in AppLocale.values)
            DropdownMenuItem(value: option, child: Text(option.id)),
        ],
        onChanged: (option) async {
          if (option == null || option == locale) return;
          try {
            await LocaleService().write(option);
          } catch (_) {
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not save Locale.')),
            );
          }
        },
      ),
    ),
  );
}
