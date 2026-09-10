import '../models/course_models.dart';
import 'tts_language_resolver.dart';

class ResolvedCourseLanguage {
  final String name;
  final String? code;

  const ResolvedCourseLanguage({required this.name, required this.code});

  String get displayLabel {
    final normalizedName = name.trim();
    final normalizedCode = code?.trim() ?? '';
    if (normalizedName.isEmpty && normalizedCode.isEmpty) {
      return 'Not specified';
    }
    if (normalizedCode.isEmpty) return normalizedName;
    if (normalizedName.isEmpty) return normalizedCode;
    return '$normalizedName ($normalizedCode)';
  }
}

/// Resolves a Course's language identities without depending on its origin.
///
/// Explicit BCP-47 language tags retain their complete stored variant. When a
/// stored tag is absent or malformed, the established language-name mapping is
/// used without inventing a regional subtag.
abstract final class CourseLanguageResolver {
  static ResolvedCourseLanguage learning(Course course) =>
      ResolvedCourseLanguage(
        name: _firstDisplayName([
          course.targetLanguage,
          course.learningLanguage,
        ]),
        code: _learningCode(course),
      );

  static ResolvedCourseLanguage base(Course course) => ResolvedCourseLanguage(
    name: _firstDisplayName([course.sourceLanguage, course.interfaceLanguage]),
    code: _firstCode([
      course.sourceLanguageTag,
      course.sourceLanguage,
      course.interfaceLanguage,
    ]),
  );

  static String? codeFromMetadata(Iterable<String?> candidates) =>
      _firstCode(candidates);

  static String? _learningCode(Course course) {
    final explicitTag = TtsLanguageResolver.normalize(course.targetLanguageTag);
    if (explicitTag != null) return explicitTag;

    final learning = TtsLanguageResolver.normalize(course.learningLanguage);
    final target = TtsLanguageResolver.normalize(course.targetLanguage);
    final languageIdentity = learning ?? target;
    final speech = TtsLanguageResolver.normalize(course.ttsLanguage);
    if (speech != null &&
        (languageIdentity == null ||
            _baseCode(speech) == _baseCode(languageIdentity))) {
      return speech;
    }
    return languageIdentity;
  }

  static String _baseCode(String code) => code.split('-').first;

  static String _firstDisplayName(Iterable<String> candidates) {
    for (final candidate in candidates) {
      final value = candidate.trim();
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static String? _firstCode(Iterable<String?> candidates) {
    for (final candidate in candidates) {
      final normalized = TtsLanguageResolver.normalize(candidate);
      if (normalized != null) return normalized;
    }
    return null;
  }
}
