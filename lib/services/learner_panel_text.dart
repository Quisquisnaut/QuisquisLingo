import '../localization/learner_panel/learner_panel_catalogs.dart';
import '../localization/learner_panel/learner_panel_en.dart';
import '../models/course_models.dart';
import 'exercise_copy_service.dart';

/// The learner panel's buttons and messages (Build 260 Revision 1): Check,
/// Continue, the feedback, the end-of-Round summary, Before you start, the
/// Duel and the Review page, in the Course's instruction language
/// ([ExerciseCopyService.instructionLanguage]), as the exercise lines.
///
/// QQL's own interface stays English; messages about errors, audio set-up,
/// app versions and author previews are not learner panel text.
abstract final class LearnerPanelText {
  /// Each language's catalog over the English one, so a missing key falls
  /// back to English.
  static final Map<String, Map<String, String>> _merged = {
    for (final MapEntry(key: language, value: catalog)
        in learnerPanelCatalogs.entries)
      language: {...learnerPanelEn, ...catalog},
  };

  /// The text of [key] for [course], with each `{name}` replaced by
  /// [values]`[name]`.
  static String of(
    Course course,
    String key, [
    Map<String, Object> values = const {},
  ]) {
    final catalog =
        _merged[ExerciseCopyService.instructionLanguage(course)] ??
        _merged['en']!;
    var text = catalog[key] ?? learnerPanelEn[key]!;
    for (final MapEntry(:key, :value) in values.entries) {
      text = text.replaceAll('{$key}', '$value');
    }
    return text;
  }
}
