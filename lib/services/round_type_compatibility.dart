import '../models/course_models.dart';
import '../models/exercise_authoring.dart';
import '../models/exercise_features.dart';

enum RoundTypeIssue {
  audioRequired,
  readingRequired,
  flashcardOnly,
  evaluatableOnly,
  timedEvaluatableOnly,
  timedRequiresAudio,
  speakUnavailable,
}

/// The same canonical capability rules drive authoring and publication.
/// Presets are only suggestions; an edited exercise is checked again.
abstract final class RoundTypeCompatibility {
  static const _audioKinds = {
    LearnerExerciseKind.selectListen,
    LearnerExerciseKind.selectListenPassage,
    LearnerExerciseKind.inputListenWrite,
    LearnerExerciseKind.inputListenGaps,
    LearnerExerciseKind.matchAudio,
  };
  static const _readingKinds = {
    LearnerExerciseKind.selectRead,
    LearnerExerciseKind.selectContext,
  };

  static bool canOfferPreset(RoundType type, ExercisePreset preset) {
    return switch (type) {
      RoundType.listening => preset.audioEssentialCandidate,
      RoundType.reading => preset.readingEssentialCandidate,
      RoundType.flashcard => preset.flashcardCandidate,
      RoundType.test => preset.evaluatableCandidate,
      RoundType.timed =>
        preset.evaluatableCandidate && !preset.audioEssentialCandidate,
      RoundType.speak => false,
      _ => true,
    };
  }

  static bool audioEssential(Exercise exercise) {
    final features = ExerciseFeatures(exercise);
    if (!features.requiresAudio || !_audioKinds.contains(features.kind)) {
      return false;
    }
    if (features.kind == LearnerExerciseKind.matchAudio) {
      // A written label on the sound side supplies a second answer path.
      final soundItems = exercise.items
          .where((item) => item.content.any((e) => e.isAudio))
          .toList();
      return soundItems.isNotEmpty &&
          soundItems.every(
            (item) =>
                !item.content.any((e) => e.isText && e.text.trim().isNotEmpty),
          );
    }
    final spoken = features.automaticAudio?.text.trim().toLowerCase() ?? '';
    if (spoken.isEmpty || features.automaticAudio?.isRequired != true) {
      return false;
    }
    final visible = features.prompt
        .where((e) => e.isText)
        .map((e) => e.text.trim().toLowerCase());
    return !visible.any(
      (text) => text.isNotEmpty && (text == spoken || text.contains(spoken)),
    );
  }

  static bool readingEssential(Exercise exercise) {
    final features = ExerciseFeatures(exercise);
    if (!_readingKinds.contains(features.kind) ||
        features.questionText.trim().isEmpty) {
      return false;
    }
    final passage = [
      features.passageText,
      features.contextText,
      features.situationText,
      ...features.dialogueTurns.map((e) => e.text),
    ].where((text) => text.trim().isNotEmpty).join(' ').toLowerCase();
    if (passage.isEmpty) return false;
    final correct = exercise.items.where(
      (item) => exercise.canonicalEvaluation.correctItemIds.contains(item.id),
    );
    // A verbatim answer in the reading material can be copied without comprehension.
    return correct.isNotEmpty &&
        correct.every((item) {
          final answer = item.value.trim().toLowerCase();
          return answer.isNotEmpty && !passage.contains(answer);
        });
  }

  static bool flashcardCompatible(Exercise exercise) {
    final features = ExerciseFeatures(exercise);
    return exercise.primitive == ExercisePrimitive.presentation &&
        features.kind == LearnerExerciseKind.presentation &&
        features.textOf('term').trim().isNotEmpty &&
        features.textOf('meaning').trim().isNotEmpty;
  }

  static bool evaluatable(Exercise exercise) =>
      exercise.isExecutable &&
      exercise.primitive != ExercisePrimitive.presentation &&
      exercise.canonicalEvaluation.mode != EvaluationMode.none &&
      exercise.canonicalEvaluation.mode != EvaluationMode.manual;

  static List<RoundTypeIssue> issuesForExercise(
    RoundType type,
    Exercise exercise, {
    bool required = true,
  }) => switch (type) {
    RoundType.listening when required && !audioEssential(exercise) => const [
      RoundTypeIssue.audioRequired,
    ],
    RoundType.reading when required && !readingEssential(exercise) => const [
      RoundTypeIssue.readingRequired,
    ],
    RoundType.flashcard when !flashcardCompatible(exercise) => const [
      RoundTypeIssue.flashcardOnly,
    ],
    RoundType.test when !evaluatable(exercise) => const [
      RoundTypeIssue.evaluatableOnly,
    ],
    RoundType.timed when !evaluatable(exercise) => const [
      RoundTypeIssue.timedEvaluatableOnly,
    ],
    RoundType.timed when ExerciseFeatures(exercise).requiresAudio => const [
      RoundTypeIssue.timedRequiresAudio,
    ],
    RoundType.speak => const [RoundTypeIssue.speakUnavailable],
    _ => const [],
  };

  static String message(RoundTypeIssue issue) => switch (issue) {
    RoundTypeIssue.audioRequired =>
      'This required exercise does not structurally require audio.',
    RoundTypeIssue.readingRequired =>
      'This required exercise does not structurally require reading.',
    RoundTypeIssue.flashcardOnly =>
      'A FlashCard Round accepts only canonical Flashcards.',
    RoundTypeIssue.evaluatableOnly =>
      'A Test accepts only evaluatable exercises.',
    RoundTypeIssue.timedEvaluatableOnly =>
      'A Timed Round accepts only playable, automatically evaluatable exercises.',
    RoundTypeIssue.timedRequiresAudio =>
      'A Timed exercise cannot require audio, which may be disabled during play.',
    RoundTypeIssue.speakUnavailable =>
      'Speak Rounds are not playable in this version.',
  };
}
