import '../models/course_models.dart';
import '../models/exercise_features.dart';

/// Which side of a two-sided Flashcard faces the learner first.
enum FlashcardFront {
  /// The word or expression; its meaning is on the back.
  word,

  /// The meaning (the translation, and the picture of a Picture flashcard);
  /// the word and its read-aloud are on the back.
  meaning,
}

/// Two-sided Flashcards (Build 268 Revision 0, owner decisions of 9 October
/// 2026). A vocabulary card has a front and a back that the learner turns;
/// a card that ends with Continue (the Note card) stays one page. Nothing
/// is stored: the sides come from the card's canonical content and the
/// direction from where the Round is played.
abstract final class FlashcardSides {
  /// Whether [features] describe a card with two sides: a presentation
  /// reviewed with Got it / Review again (`understoodReview`) that has a
  /// word and a meaning to put behind it (a translation or a picture).
  static bool isTwoSided(ExerciseFeatures features) =>
      features.primitive == ExercisePrimitive.presentation &&
      features.kind == LearnerExerciseKind.presentation &&
      features.completionMode == CompletionMode.understoodReview &&
      features.textOf('term').trim().isNotEmpty &&
      (features.textOf('meaning').trim().isNotEmpty ||
          features.illustrationAsset.isNotEmpty);

  /// The side facing up first (owner's choice (b)): the word the first time
  /// through a Round, the meaning when a Round the learner has already
  /// completed is played again and in Review. The editor's Preview always
  /// shows the word first.
  static FlashcardFront frontFor({
    required bool roundCompleted,
    required bool review,
    required bool preview,
  }) {
    if (preview) return FlashcardFront.word;
    return roundCompleted || review
        ? FlashcardFront.meaning
        : FlashcardFront.word;
  }
}
