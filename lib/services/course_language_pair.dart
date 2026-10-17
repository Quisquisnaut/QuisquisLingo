import '../models/course_models.dart';
import 'exercise_search_service.dart';

/// The two kinds of Course (Build 275, owner decisions of 16 October 2026):
/// a language taught through another language, or in the same language.
enum CourseKind {
  /// Learners read instructions and translations in a language they
  /// already speak: Italian for English speakers.
  otherLanguage,

  /// Everything is in the language being learned: English explained in
  /// English. The second side of a word holds its meaning.
  sameLanguage,
}

/// Whether a Course teaches its language in that same language. Screens,
/// services and catalogs ask this owner; never test "same-language"
/// anywhere else.
///
/// Build 275 Revision 2 (owner decision of 17 October 2026): the creator
/// decides. The kind chosen when the Course is made is stored
/// ([Course.sameLanguage]) and never changes, like the languages; nothing
/// is derived from the language tags. In the same language has one
/// Language field, so both sides are one language (a variant may be named
/// in Language variant); Through another language takes any two
/// languages, two variants of one language too (English (UK) and English
/// (US): it translates between them), but not one language twice.
abstract final class CourseLanguagePair {
  static bool isSameLanguage(Course course) => course.sameLanguage;

  static CourseKind kindOf(Course course) => isSameLanguage(course)
      ? CourseKind.sameLanguage
      : CourseKind.otherLanguage;

  /// Whether two languages as a form holds them (each a name and a tag,
  /// '' for none) are one language written twice: the same name and the
  /// same tag, capitals and accents ignored. Through another language
  /// refuses them; any difference of name or tag is accepted.
  static bool identicalChoices({
    required String learningName,
    required String learningTag,
    required String baseName,
    required String baseTag,
  }) {
    final name = _plain(learningName);
    return name.isNotEmpty &&
        name == _plain(baseName) &&
        _tag(learningTag) == _tag(baseTag);
  }

  /// A same-language Course is read by Build 275 Revision 2 and later
  /// (`CourseMinimumBuild`): an earlier build would drop the field on its
  /// first save and show translations.
  static const minimumAppBuild = 275002;

  /// [course] with its `minimumAppBuild` raised to [minimumAppBuild] when
  /// it is in the same language, never lowered.
  static Course withMinimumAppBuild(Course course) {
    if (!course.sameLanguage) return course;
    final current = course.minimumAppBuild;
    if (current != null && current >= minimumAppBuild) return course;
    return Course.fromJson({
      ...course.toJson(),
      'minimumAppBuild': minimumAppBuild,
    });
  }

  static String _plain(String name) =>
      ExerciseSearchService.normalize(name.trim());

  static String _tag(String tag) =>
      tag.trim().toLowerCase().replaceAll('_', '-');
}
