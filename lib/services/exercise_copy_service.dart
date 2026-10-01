import '../localization/exercise_copy/exercise_copy_catalogs.dart';
import '../localization/exercise_copy/exercise_copy_en.dart';
import '../models/course_models.dart';
import '../models/exercise_features.dart';
import 'language_catalog.dart';

/// Learner-facing exercise labels and instructions, keyed by the
/// [LearnerExerciseKind] derived from canonical data (Build 256).
///
/// These strings are derived from the course source language, so authoring
/// data cannot accidentally show a target-language instruction to learners.
class ExerciseCopyService {
  const ExerciseCopyService._();

  /// The instruction language: the Course's base language when QQL has a
  /// catalog for it (Build 260 Revision 0: its tag, else the language its
  /// name or interface language names), otherwise English.
  static String _languageCode(Course course) {
    final tag = LanguageCatalog.tagFor(
      tag: course.sourceLanguageTag,
      name: course.sourceLanguage,
      fallbackName: course.interfaceLanguage,
    );
    final primary = tag?.split('-').first.toLowerCase();
    return exerciseCopyCatalogs.containsKey(primary) ? primary! : 'en';
  }

  /// Each instruction language's catalog over the English one, so a missing
  /// key falls back to English.
  static final Map<String, Map<String, String>> _merged = {
    for (final MapEntry(key: language, value: catalog)
        in exerciseCopyCatalogs.entries)
      language: {...exerciseCopyEn, ...catalog},
  };

  static Map<String, String> _copy(Course course) =>
      _merged[_languageCode(course)]!;

  /// The learner heading for an exercise of [kind].
  static String typeLabel(Course course, LearnerExerciseKind kind) {
    final c = _copy(course);
    return c['type.${kind.name}'] ?? c['type.default']!;
  }

  /// The learner instruction for an exercise of [kind]. Without an
  /// exercise, a translation line names the target language.
  static String instruction(Course course, LearnerExerciseKind kind) {
    final c = _copy(course);
    return _withLanguage(
      course,
      c['instruction.${kind.name}'] ?? c['instruction.default']!,
    );
  }

  /// [text] with `{language}` replaced by the name of the language a
  /// translation is written in: the base language when the text to
  /// translate is in the target language, else the learning language
  /// (Build 259 Revision 7), named in the instruction language
  /// ([languageName]).
  static String _withLanguage(
    Course course,
    String text, [
    ExerciseFeatures? features,
  ]) {
    if (!text.contains('{language}')) return text;
    final intoSource = features?.promptLanguage == TextLanguage.target;
    return text.replaceAll(
      '{language}',
      languageName(course, intoSource: intoSource),
    );
  }

  /// The name of the Course's base language ([intoSource]) or learning
  /// language inside a line in its instruction language (Build 260
  /// Revision 0, owner decisions of 1 October 2026): the Course's own name
  /// for learners of the learning language, else QQL's name for that
  /// language in the instruction language, else its English name, else the
  /// name the Course writes.
  static String languageName(Course course, {required bool intoSource}) {
    if (!intoSource) {
      final own = course.targetLanguageNameForLearners.trim();
      if (own.isNotEmpty) return own;
    }
    final written = (intoSource ? course.sourceLanguage : course.targetLanguage)
        .trim();
    final fallback =
        (intoSource ? course.interfaceLanguage : course.learningLanguage)
            .trim();
    final tag = LanguageCatalog.tagFor(
      tag: intoSource ? course.sourceLanguageTag : course.targetLanguageTag,
      name: written,
      fallbackName: fallback,
    );
    if (tag != null) {
      final local = LanguageCatalog.nameIn(_languageCode(course), tag);
      if (local != null) return local;
      final entry = LanguageCatalog.byTag(tag);
      if (entry != null) return entry.englishName;
    }
    return written.isNotEmpty ? written : fallback;
  }

  /// The instruction [variant] (a key such as `selectListenHeard`), else
  /// [kind]'s. The Exercise editor quotes a variant for the presets whose
  /// exercises always get it (Build 259 Revision 3).
  static String instructionVariant(
    Course course,
    String variant,
    LearnerExerciseKind kind,
  ) => _copy(course)['instruction.$variant'] ?? instruction(course, kind);

  /// The instruction for [exercise]: its kind's, or the "opposites" variant
  /// when the exercise's own text says so. Both come from canonical data;
  /// nothing here reads a preset (Build 256, plan A.3).
  static String instructionForExercise(Course course, Exercise exercise) {
    final features = ExerciseFeatures(exercise);
    final kind = features.kind;
    final prompt = [
      features.primaryText,
      features.questionText,
      features.clueText,
      features.passageText,
      features.situationText,
      features.contextText,
    ].join(' ').toLowerCase();
    final c = _copy(course);
    if (kind == LearnerExerciseKind.dialogueLine) {
      // The instruction follows the line's mode and whether its text waits
      // for the audio (owner review, 28 September 2026).
      final variant = features.lineMode == 'text'
          ? 'dialogueLineText'
          : features.lineMode == 'audio'
          ? 'dialogueLineAudio'
          : features.textReveal == TextReveal.afterAudio
          ? 'dialogueLineAfterAudio'
          : 'dialogueLine';
      return c['instruction.$variant'] ?? instruction(course, kind);
    }
    // Typed gaps (Build 259 Revision 3, owner decision of 30 September
    // 2026): letters inside words, one word, or several words.
    if (kind == LearnerExerciseKind.inputComplete) {
      final targets = features.gapFieldTargets;
      final inWord = features.gapsInWord;
      final variant =
          targets.isNotEmpty &&
              targets.every((target) => inWord[target.id] ?? false)
          ? 'inputCompleteLetters'
          : targets.length <= 1
          ? 'inputCompleteOne'
          : null;
      if (variant != null) {
        return c['instruction.$variant'] ?? instruction(course, kind);
      }
    }
    // Listening (Build 259 Revision 3): a question is answered; without one
    // the learner picks the sentence heard, or its meaning among
    // source-language answers. Picture answers and gaps keep their line.
    if (kind == LearnerExerciseKind.selectListen ||
        kind == LearnerExerciseKind.selectListenPassage) {
      final variant = features.questionText.isNotEmpty
          ? 'selectListenQuestion'
          : kind == LearnerExerciseKind.selectListen &&
                !features.hasInlineTargets &&
                !features.hasImageItems &&
                !features.hasIconItems
          ? (features.itemLanguage == TextLanguage.source
                ? 'selectListenMeaning'
                : 'selectListenHeard')
          : null;
      if (variant != null) {
        return c['instruction.$variant'] ?? instruction(course, kind);
      }
    }
    // Spelling without a picture (Build 259 Revision 4): heard, or from a
    // clue.
    if (kind == LearnerExerciseKind.arrangeWord &&
        features.illustrationImages.isEmpty) {
      final variant = features.automaticAudio != null
          ? 'arrangeWordHeard'
          : 'arrangeWordClue';
      return c['instruction.$variant'] ?? instruction(course, kind);
    }
    // Words picked for the gaps of a sentence (Build 259 Revision 4).
    if (kind == LearnerExerciseKind.arrangeSentence &&
        features.hasInlineTargets) {
      return c['instruction.arrangeGaps'] ?? instruction(course, kind);
    }
    if (prompt.contains('opposite') ||
        prompt.contains('contrari') ||
        prompt.contains('gegens') ||
        prompt.contains('opuestos') ||
        prompt.contains('opostos') ||
        prompt.contains('tegenstell') ||
        prompt.contains('vastakoht') ||
        prompt.contains('croes')) {
      // A Match keeps its generic line (owner decision, 29 September 2026):
      // Match by meaning takes opposites, synonyms and more, and an authored
      // instruction is drawn in the line's place anyway.
      if (kind == LearnerExerciseKind.select) {
        return c['instruction.select_opposite'] ?? instruction(course, kind);
      }
    }
    // Type and Build the translation name the language of the answer.
    return _withLanguage(
      course,
      c['instruction.${kind.name}'] ?? c['instruction.default']!,
      features,
    );
  }

  /// Old demo courses sometimes stored a generic instruction in `prompt`.
  /// The Round screen now renders the localized instruction separately, so
  /// suppress only these exact legacy instruction strings to avoid duplicates.
  static bool isLegacyInstruction(String prompt) {
    final value = prompt.trim();
    if (value.isEmpty) return false;
    return _legacyInstructions.contains(value);
  }

  /// Keeps authored content intact while localizing the instruction prefix in
  /// old Spanish-source demo exercises that used English `Translate:` text.
  static String displayPrompt(Course course, String prompt) {
    final value = prompt.trim();
    if (_languageCode(course) == 'es' && value.startsWith('Translate:')) {
      return 'Traduce:${value.substring('Translate:'.length)}';
    }
    return prompt;
  }

  static const _legacyInstructions = <String>{
    'Choose the correct translation.',
    'Build the target-language word shown in the image.',
    'Build the word shown in the image.',
    'Match each translation.',
    'Match each sound to the word.',
    'Match the opposites.',
    'Abbina i contrari.',
    'Ordne die Gegensätze zu.',
    'Relaciona los contrarios.',
    'Associe os opostos.',
    'Koppel de tegenstellingen.',
    'Yhdistä vastakohdat.',
    'Parwch y geiriau croes.',
  };
}
