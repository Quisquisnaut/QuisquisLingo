import '../models/course_models.dart';
import 'audio_exercise_availability_service.dart';

class DuelCandidate {
  final LearningRound round;
  final Exercise exercise;

  const DuelCandidate({required this.round, required this.exercise});
}

class DuelEligibilityResult {
  final List<DuelCandidate> candidates;
  final int requiredCount;
  final int structuralEligibleCount;

  const DuelEligibilityResult({
    required this.candidates,
    required this.requiredCount,
    required this.structuralEligibleCount,
  });

  int get eligibleCount => candidates.length;
  bool get isAvailable => eligibleCount >= requiredCount;
  bool get isStructurallyAvailable => structuralEligibleCount >= requiredCount;
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

  DuelEligibilityResult evaluate(Lesson lesson) {
    final candidates = <DuelCandidate>[];
    final seen = <String>{};

    if (!lesson.publicationState.isPublished) {
      return const DuelEligibilityResult(
        candidates: [],
        requiredCount: requiredQuestionCount,
        structuralEligibleCount: 0,
      );
    }

    for (final round in lesson.rounds) {
      if (!round.publicationState.isPublished) continue;
      for (final exercise in round.exercises) {
        if (!exercise.publicationState.isPublished) continue;
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
      structuralEligibleCount: candidates.length,
    );
  }

  /// Applies the learner's audio settings and runtime audio availability to
  /// the canonical structural candidate pool.
  ///
  /// Home and Duel entry must both use this result so displayed availability
  /// cannot disagree with the exercises that are actually playable.
  Future<DuelEligibilityResult> evaluateEffective(
    Course course,
    Lesson lesson, {
    required bool audioExercisesEnabled,
    required bool ttsEnabled,
    AudioExerciseAvailabilityService? audioAvailability,
  }) async {
    final structural = evaluate(lesson);
    final availability =
        audioAvailability ?? AudioExerciseAvailabilityService();
    final candidates = <DuelCandidate>[];

    for (final candidate in structural.candidates) {
      final exercise = candidate.exercise;
      if (!availability.isAudioExercise(exercise)) {
        candidates.add(candidate);
        continue;
      }
      if (audioExercisesEnabled &&
          await availability.isAvailable(
            course,
            exercise,
            ttsEnabled: ttsEnabled,
          )) {
        candidates.add(candidate);
      }
    }

    return DuelEligibilityResult(
      candidates: List.unmodifiable(candidates),
      requiredCount: requiredQuestionCount,
      structuralEligibleCount: structural.eligibleCount,
    );
  }
}
