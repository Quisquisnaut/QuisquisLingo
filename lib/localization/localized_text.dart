import 'locale_service.dart';

/// A language-neutral lookup over keyed text catalogs.
///
/// Each keyed value resolves on its own. A key containing several paragraphs
/// falls back as one value; other keys on the page keep their translations.
/// Catalogs for other UI areas can use this class later.
class LocalizedText {
  const LocalizedText({
    required this.english,
    required this.italian,
    required this.spanish,
  });

  final Map<String, String> english;
  final Map<String, String> italian;
  final Map<String, String> spanish;

  String lookup(
    AppLocale locale,
    String key, {
    Map<String, String> values = const {},
  }) {
    final selected = switch (locale) {
      AppLocale.english => english,
      AppLocale.italian => italian,
      AppLocale.spanish => spanish,
    };
    final translation = selected[key];
    final source = translation != null && translation.isNotEmpty
        ? translation
        : english[key];
    if (source == null || source.isEmpty) {
      throw StateError('Missing English localization key: $key');
    }
    return source.replaceAllMapped(
      RegExp(r'\{([a-zA-Z][a-zA-Z0-9_]*)\}'),
      (match) => values[match.group(1)] ?? match.group(0)!,
    );
  }
}
