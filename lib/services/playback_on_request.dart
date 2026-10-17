import '../models/course_models.dart';
import '../models/exercise_features.dart';
import 'correct_answer_text.dart';
import 'translation_choice_service.dart';

/// What a learner may hear on request, never by itself (Build 274
/// Revision 2, the owner's points 4 and 6 of 13 October 2026). QQL speech
/// concerns the target language. Nothing is asked of the author and Course
/// files do not change: every text is worked out from the exercise as it is.
///
/// The Round screen draws a speaker for each text while the learner's audio
/// is on, and the Audio Library counts them among the texts a Course speaks
/// ([texts], through `CourseAudioUsage.spokenTexts`).
///
/// Build 275 Revision 3 (owner decision of 17 October 2026): in a Course in
/// the same language ([sameLanguage], `CourseLanguagePair.isSameLanguage`)
/// a meaning is the language being learned too, so text marked as the
/// source language is heard like target-language text.
abstract final class PlaybackOnRequest {
  /// The target-language sentence beside the text the learner reads: Pick
  /// the translation's question, or the sentence Build the translation and
  /// Type the translation ask to translate into the source language. Null
  /// when that text is not in the target language, and when the prompt
  /// shown is an Instruction or context (the page draws it as its
  /// instruction line, in the learners' language).
  static String? promptText(ExerciseFeatures f, {bool sameLanguage = false}) {
    if (f.isTranslationChoice) {
      if (f.questionLanguage == TextLanguage.target) {
        return TranslationChoice.spokenTextFor(f, answered: false);
      }
      // A meaning in a same-language Course.
      if (_heard(f.questionLanguage, sameLanguage)) {
        final text = f.questionText.trim();
        return text.isEmpty ? null : text;
      }
      return null;
    }
    if (!_buildsOrTypesATranslation(f) ||
        !_heard(f.promptLanguage, sameLanguage) ||
        f.authoredInstruction.isNotEmpty) {
      return null;
    }
    final text = f.displayedPrompt.trim();
    return text.isEmpty ? null : text;
  }

  /// The target-language answer the learner may hear once they have
  /// answered: Pick the translation's right answer, or the first answer
  /// Build the translation and Type the translation into the target
  /// language accept (the plan's choice: the correct answer line may show
  /// another accepted answer, the one closest to what was typed). Null
  /// before an answer and when the answer is in the source language, except
  /// in a same-language Course (a meaning; Build 275 Revision 3).
  static String? answerText(
    Exercise ex,
    ExerciseFeatures f, {
    required bool answered,
    bool sameLanguage = false,
  }) {
    if (!answered) return null;
    if (f.isTranslationChoice) {
      if (f.itemLanguage == TextLanguage.target) {
        return TranslationChoice.spokenTextFor(f, answered: true);
      }
      // The right meaning in a same-language Course.
      if (_heard(f.itemLanguage, sameLanguage)) {
        final correct = f.evaluation.correctItemIds.firstOrNull;
        final text = f.items
            .where((item) => item.id == correct)
            .map((item) => item.text.trim())
            .firstOrNull;
        return text == null || text.isEmpty ? null : text;
      }
      return null;
    }
    if (!_buildsOrTypesATranslation(f) ||
        !_heard(f.answerLanguage, sameLanguage)) {
      return null;
    }
    if (f.kind == LearnerExerciseKind.inputTranslation) {
      // The first answer the exercise accepts: a verbatim answer first,
      // else the first answer an answer expression accepts, its optional
      // words written as the correct answer line writes a variant.
      final literal = f.literalAnswers
          .map((answer) => answer.trim())
          .where((answer) => answer.isNotEmpty)
          .firstOrNull;
      if (literal != null) return literal;
      final expression = f.acceptedAnswers
          .map((answer) => answer.trim())
          .where((answer) => answer.isNotEmpty)
          .firstOrNull;
      if (expression == null) return null;
      final text = CorrectAnswerText.variantOf(expression).trim();
      return text.isEmpty ? null : text;
    }
    final order = ex.canonicalEvaluation.correctOrders.firstOrNull;
    if (order == null) return null;
    final text = CorrectAnswerText.orderText(ex, f, order).trim();
    return text.isEmpty ? null : text;
  }

  /// The word of an option the learner may hear: the word under a named
  /// icon in Select the image (owner decision of 15 October 2026: a word
  /// that states no language counts as the target language), or a word of
  /// Match pictures to words. Null for a word marked as the source language
  /// outside a same-language Course, and for a picture option, which shows
  /// no word (Build 263 Revision 0).
  /// Only where the Round screen draws a speaker: the picture grid of a
  /// single-answer Select, and the menus of a Match whose left items show
  /// pictures.
  static String? optionWord(
    ExerciseFeatures f,
    ExerciseItem item, {
    bool sameLanguage = false,
  }) {
    final word = item.label.trim();
    if (word.isEmpty ||
        (!sameLanguage && _wordLanguage(item) == TextLanguage.source)) {
      return null;
    }
    if (f.kind == LearnerExerciseKind.selectImage) {
      // Several answers, or answers that fill gaps, are drawn without the
      // picture grid.
      if (f.multipleSelection || f.hasInlineTargets) return null;
      final iconKey =
          item.content
              .where((element) => element.isText && element.role == 'icon')
              .map((element) => element.text)
              .firstOrNull ??
          '';
      final namedIcon = item.image.isEmpty && !iconKey.startsWith('assets/');
      return namedIcon ? word : null;
    }
    // The sides as the Round screen pairs them: an item without a side is
    // left when it opens a relation.
    if (f.primitive == ExercisePrimitive.match &&
        f.leftItems.any((left) => left.image.isNotEmpty) &&
        f.rightItems.any((right) => right.id == item.id)) {
      return word;
    }
    return null;
  }

  /// Every text [ex] lets the learner hear on request.
  static List<String> texts(Exercise ex, {bool sameLanguage = false}) {
    final f = ExerciseFeatures(ex);
    return [
      ?promptText(f, sameLanguage: sameLanguage),
      ?answerText(ex, f, answered: true, sameLanguage: sameLanguage),
      for (final item in f.items)
        ?optionWord(f, item, sameLanguage: sameLanguage),
    ];
  }

  /// Whether text in [language] may be heard: the target language, and in
  /// a same-language Course the source side too (its meanings).
  static bool _heard(TextLanguage? language, bool sameLanguage) =>
      language == TextLanguage.target ||
      (sameLanguage && language == TextLanguage.source);

  static bool _buildsOrTypesATranslation(ExerciseFeatures f) =>
      f.kind == LearnerExerciseKind.inputTranslation ||
      f.kind == LearnerExerciseKind.arrangeTranslation;

  /// The language an item's word states, if any (not its icon key).
  static TextLanguage? _wordLanguage(ExerciseItem item) => item.content
      .where((element) => element.isText && element.role != 'icon')
      .map((element) => element.language)
      .firstOrNull;
}
