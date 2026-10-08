import '../models/course_models.dart';
import '../models/exercise_features.dart';

/// The difficulty level of an exercise (Build 260 Revision 5, owner
/// decision of 1 October 2026): what the learner has to do, from reading to
/// writing. It is computed from the exercise's canonical data, like
/// executability, never stored, and never read from a preset ID.
enum DifficultyLevel {
  /// A card to read: a Flashcard, a Note card, a Page.
  read(0, 'Read'),

  /// Recognize a meaning: pick or pair a source-language text or a picture.
  recognizeMeaning(1, 'Recognize the meaning'),

  /// Recognize the target language: pick, pair or sort target-language
  /// forms.
  recognizeTarget(2, 'Recognize the language'),

  /// Build with blocks: put blocks in order or place them into slots.
  build(3, 'Build with blocks'),

  /// Write: type the answer.
  write(4, 'Write');

  const DifficultyLevel(this.value, this.label);

  /// 0 to 4.
  final int value;

  /// The level's name in the editor (QQL's own interface, English).
  final String label;
}

abstract final class ExerciseDifficulty {
  /// The level of [exercise]; null for what a learner does not answer or
  /// study: a Before you start card, a Story cover, a Dialogue line, and a
  /// primitive this version does not play.
  static DifficultyLevel? of(Exercise exercise) {
    final f = ExerciseFeatures(exercise);
    switch (f.kind) {
      case LearnerExerciseKind.roundIntro:
      case LearnerExerciseKind.storyCover:
      case LearnerExerciseKind.dialogueLine:
      case LearnerExerciseKind.other:
        return null;
      case LearnerExerciseKind.presentation:
      case LearnerExerciseKind.page:
        return DifficultyLevel.read;
      case LearnerExerciseKind.matchTranslation:
      case LearnerExerciseKind.matchAudio:
        return DifficultyLevel.recognizeMeaning;
      case LearnerExerciseKind.match:
        // Pictures paired with words name a meaning; two sides of the
        // target language (opposites, plurals) test the language.
        return f.hasImageItems
            ? DifficultyLevel.recognizeMeaning
            : DifficultyLevel.recognizeTarget;
      case LearnerExerciseKind.assignGroups:
        return DifficultyLevel.recognizeTarget;
      case LearnerExerciseKind.assignSlots:
      case LearnerExerciseKind.assignGaps:
        return DifficultyLevel.build;
      case LearnerExerciseKind.arrangeSentence:
      case LearnerExerciseKind.arrangeLines:
      case LearnerExerciseKind.arrangeTranslation:
      case LearnerExerciseKind.arrangeWord:
      case LearnerExerciseKind.arrangePictureName:
        return DifficultyLevel.build;
      case LearnerExerciseKind.inputComplete:
      case LearnerExerciseKind.inputTranslation:
      case LearnerExerciseKind.inputListenWrite:
      case LearnerExerciseKind.inputListenGaps:
      case LearnerExerciseKind.inputMissingWord:
      case LearnerExerciseKind.inputPictureName:
        return DifficultyLevel.write;
      case LearnerExerciseKind.select:
      case LearnerExerciseKind.selectComplete:
      case LearnerExerciseKind.selectCompleteAll:
      case LearnerExerciseKind.selectImage:
      case LearnerExerciseKind.selectPicture:
      case LearnerExerciseKind.selectCharacter:
      case LearnerExerciseKind.selectListen:
      case LearnerExerciseKind.selectListenPassage:
      case LearnerExerciseKind.selectRead:
      case LearnerExerciseKind.selectDialogue:
      case LearnerExerciseKind.selectContext:
      case LearnerExerciseKind.selectTranslation:
        // Picking a meaning (a source-language answer or a picture) is
        // easier than picking a target-language form.
        return f.itemLanguage == TextLanguage.source ||
                f.hasImageItems ||
                f.hasIconItems
            ? DifficultyLevel.recognizeMeaning
            : DifficultyLevel.recognizeTarget;
    }
  }

  /// The average level of [round]'s exercises that are answered (levels 1
  /// to 4), rounded to one decimal; null when it has none.
  static double? averageOf(LearningRound round) {
    final levels = [
      for (final exercise in round.exercises)
        if ((of(exercise)?.value ?? 0) > 0) of(exercise)!.value,
    ];
    if (levels.isEmpty) return null;
    final average = levels.reduce((a, b) => a + b) / levels.length;
    return (average * 10).round() / 10;
  }
}
