import 'course_service.dart';

/// Resolves speech metadata without inferring language from a course title,
/// origin, filename, or a machine's default voice. No course data is rewritten.
class TtsLanguageResolver {
  static String? normalize(String? value) {
    final text = (value ?? '').trim().replaceAll('_', '-').toLowerCase();
    if (text.isEmpty ||
        const {'und', 'mul', 'mis', 'zxx'}.contains(text.split('-').first)) {
      return null;
    }
    for (final entry in CourseService.targetLabels.entries) {
      if (entry.value.toLowerCase() == text) return entry.key.toLowerCase();
    }
    if (!RegExp(r'^[a-z]{2,3}(?:-[a-z0-9]{2,8})*$').hasMatch(text)) {
      return null;
    }
    final parts = text.split('-');
    return [
      parts.first,
      for (final part in parts.skip(1))
        if (part.length == 2)
          part.toUpperCase()
        else if (part.length == 4)
          '${part[0].toUpperCase()}${part.substring(1)}'
        else
          part,
    ].join('-');
  }

  static String resolve({
    required String requestedLanguage,
    String? learningLanguage,
    String? targetLanguage,
  }) {
    final explicit = normalize(requestedLanguage);
    if (explicit != null) return explicit;
    final learning = normalize(learningLanguage);
    final target = normalize(targetLanguage);
    if (learning != null &&
        target != null &&
        learning.split('-').first != target.split('-').first) {
      throw const FormatException(
        'Conflicting course learning/target language metadata.',
      );
    }
    final fallback = learning ?? target;
    if (fallback == null) {
      throw const FormatException(
        'Missing or unrecognized course speech language metadata.',
      );
    }
    return fallback;
  }

  /// An exact locale wins; otherwise only the same complete language subtag
  /// can match. Installed enumeration order breaks ties deterministically.
  static String? selectInstalledLocale(
    String requested,
    Iterable<String> installed,
  ) {
    final wanted = normalize(requested);
    if (wanted == null) return null;
    final locales = installed.toList();
    for (final locale in locales) {
      if (normalize(locale) == wanted) return locale;
    }
    final base = wanted.split('-').first;
    for (final locale in locales) {
      if (normalize(locale)?.split('-').first == base) return locale;
    }
    return null;
  }
}
