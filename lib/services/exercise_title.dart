import '../models/course_models.dart';
import '../models/exercise_authoring.dart';
import 'preset_recipes.dart';

/// The learner title of an exercise (Build 261 Revision 3, owner decisions
/// of 2 October 2026): the name of the preset that represents it, without
/// "(to target)" / "(to source)". The preset is recognized from the
/// exercise's canonical content as the Course Editor recognizes it
/// ([PresetRecipes.recognize]), never read from the stored preset ID, so a
/// title follows what the exercise is. Null when no preset represents it;
/// the learner then sees the title of its kind.
///
/// This is the one place where a preset reaches what learners see: a
/// title, never behaviour, grading or the Audit.
abstract final class ExerciseTitle {
  static final Expando<Object> _presets = Expando('exercise title');
  static const Object _none = Object();

  /// The preset that represents [exercise], recognized once.
  static String? _presetOf(Exercise exercise) {
    final cached = _presets[exercise];
    if (cached != null) return identical(cached, _none) ? null : '$cached';
    String? presetId;
    try {
      presetId = PresetRecipes.recognize(exercise);
    } on Object {
      presetId = null;
    }
    _presets[exercise] = presetId ?? _none;
    return presetId;
  }

  /// The catalog slug of [exercise]'s title (`title.<slug>`), or null. In a
  /// Course in the same language ([sameLanguage], Build 275 Revision 1) a
  /// translation preset is named as there
  /// ([ExercisePresetRegistry.sameLanguageNames]): Pick the word, Type the
  /// meaning.
  static String? slugFor(Exercise exercise, {bool sameLanguage = false}) {
    final presetId = _presetOf(exercise);
    if (presetId == null) return null;
    final name =
        (sameLanguage
            ? ExercisePresetRegistry.sameLanguageNames[presetId]
            : null) ??
        ExercisePresetRegistry.byId(presetId)?.name;
    return name == null ? null : slugOfName(name);
  }

  /// `Pick the translation (to target)` → `pick_the_translation`.
  static String slugOfName(String presetName) => presetName
      .replaceAll(RegExp(r'\s*\(to (target|source)\)$'), '')
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}
