import '../models/course_models.dart';

class DuelCandidate {
  final LearningRound round;
  final Exercise exercise;

  const DuelCandidate({required this.round, required this.exercise});
}

class DuelEligibilityResult {
  final List<DuelCandidate> candidates;
  final int requiredCount;

  const DuelEligibilityResult({
    required this.candidates,
    required this.requiredCount,
  });

  int get eligibleCount => candidates.length;
  bool get isAvailable => eligibleCount >= requiredCount;
}

class DuelEligibilityService {
  static const int requiredQuestionCount = 25;
  static const Set<String> supportedExerciseTypes = {
    'choice',
    'gap_choice',
    'dialogue_response',
    'icon_choice',
    'listening_choice',
    'listening_comprehension',
    'reading_comprehension',
  };

  const DuelEligibilityService();

  DuelEligibilityResult evaluate(Topic topic) {
    final candidates = <DuelCandidate>[];
    final seen = <String>{};

    for (final round in topic.rounds) {
      for (final exercise in round.exercises) {
        final answers = exercise.answers;
        final correct = exercise.correct;
        final validCorrect =
            correct != null && correct >= 0 && correct < answers.length;
        if (!supportedExerciseTypes.contains(exercise.type) ||
            answers.length < 2 ||
            !validCorrect) {
          continue;
        }

        final correctText = answers[correct];
        final duplicateKey = [
          exercise.id,
          exercise.type,
          exercise.prompt.trim().toLowerCase(),
          exercise.question.trim().toLowerCase(),
          (exercise.tts ?? '').trim().toLowerCase(),
          correctText.trim().toLowerCase(),
        ].join('|');
        if (!seen.add(duplicateKey)) continue;
        candidates.add(DuelCandidate(round: round, exercise: exercise));
      }
    }

    return DuelEligibilityResult(
      candidates: List.unmodifiable(candidates),
      requiredCount: requiredQuestionCount,
    );
  }
}
