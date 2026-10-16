import '../models/course_models.dart';
import 'course_language_resolver.dart';
import 'exercise_search_service.dart';
import 'language_catalog.dart';

/// The two kinds of Course (Build 275, owner decisions of 16 October 2026):
/// a language taught through another language, or in the same language.
/// The kind is derived from the Course's two languages and never stored.
enum CourseKind {
  /// Learners read instructions and translations in a language they
  /// already speak: Italian for English speakers.
  otherLanguage,

  /// Everything is in the language being learned: English explained in
  /// English. The second side of a word holds its meaning.
  sameLanguage,
}

/// Whether a Course teaches its language in that same language (Build 275
/// Revision 0). Screens, services and catalogs ask this owner; never test
/// "same-language" anywhere else.
///
/// The two sides are resolved as everywhere else: the language learned by
/// [CourseLanguageResolver.learning], the learners' by
/// [CourseLanguageResolver.base]. They are the same language when their
/// primary language subtags are equal and neither their regions nor their
/// scripts are both present and different: `es` and `es`, `en` and `en-US`
/// are; `en-GB` and `en-US`, `sr-Latn` and `sr-Cyrl`, `en` and `it` are not
/// (a Course between two variants translates between them: lift →
/// elevator). A side without a code takes the tag of the listed language
/// its name names ([LanguageCatalog], as Course Info's Add the language
/// tags from the list does), so an earlier Course written "Français" and
/// "French" is one language; a language typed by hand and not in the list
/// is compared by its name, capitals and accents ignored. A Course's
/// languages never change once it is created, and Course Info refuses a tag
/// that would change its kind, so its kind never changes either.
abstract final class CourseLanguagePair {
  static bool isSameLanguage(Course course) => sameLanguages(
    CourseLanguageResolver.learning(course),
    CourseLanguageResolver.base(course),
  );

  static CourseKind kindOf(Course course) => isSameLanguage(course)
      ? CourseKind.sameLanguage
      : CourseKind.otherLanguage;

  /// Whether two languages as a form holds them (each an English name and
  /// a tag, '' for none) are one language, resolved as a new Course's
  /// languages are: the tag first, else the name.
  static bool sameChoices({
    required String learningName,
    required String learningTag,
    required String baseName,
    required String baseTag,
  }) => sameLanguages(
    ResolvedCourseLanguage(
      name: learningName,
      code: CourseLanguageResolver.codeFromMetadata([
        learningTag,
        learningName,
      ]),
    ),
    ResolvedCourseLanguage(
      name: baseName,
      code: CourseLanguageResolver.codeFromMetadata([baseTag, baseName]),
    ),
  );

  static bool sameLanguages(
    ResolvedCourseLanguage learning,
    ResolvedCourseLanguage base,
  ) {
    final learningCode = learning.code ?? _listedTag(learning.name);
    final baseCode = base.code ?? _listedTag(base.name);
    if (learningCode != null && baseCode != null) {
      return sameTags(learningCode, baseCode);
    }
    final learningName = _plain(learning.name);
    return learningName.isNotEmpty && learningName == _plain(base.name);
  }

  /// Whether two language tags name one language (see the class).
  static bool sameTags(String a, String b) {
    final first = _Subtags.of(a);
    final second = _Subtags.of(b);
    if (first.language.isEmpty || first.language != second.language) {
      return false;
    }
    bool differ(String? x, String? y) => x != null && y != null && x != y;
    return !differ(first.script, second.script) &&
        !differ(first.region, second.region);
  }

  static String? _listedTag(String name) => LanguageCatalog.resolve(name)?.tag;

  static String _plain(String name) =>
      ExerciseSearchService.normalize(name.trim());
}

/// A tag's primary language, script (four letters) and region (two letters
/// or three digits), in small letters.
class _Subtags {
  const _Subtags(this.language, this.script, this.region);

  factory _Subtags.of(String tag) {
    final parts = tag.trim().toLowerCase().replaceAll('_', '-').split('-');
    String? script;
    String? region;
    for (final part in parts.skip(1)) {
      if (script == null &&
          region == null &&
          RegExp(r'^[a-z]{4}$').hasMatch(part)) {
        script = part;
      } else if (region == null &&
          RegExp(r'^(?:[a-z]{2}|[0-9]{3})$').hasMatch(part)) {
        region = part;
      }
    }
    return _Subtags(parts.first, script, region);
  }

  final String language;
  final String? script;
  final String? region;
}
