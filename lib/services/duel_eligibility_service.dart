import '../models/course_models.dart';
import '../models/exercise_features.dart';
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

  const DuelEligibilityService();

  /// Whether the Duel can ask [exercise]: a Select with one answer among
  /// items shown as choices (not inline gaps), graded as exactly one item,
  /// with at least two items and one correct item that exists. Decided
  /// from canonical data only (Build 256, plan A.10): Contextual
  /// comprehension and Recognize characters qualify, a multiple-answer
  /// Choose does not.
  static bool isEligible(Exercise exercise) {
    if (exercise.primitive != ExercisePrimitive.select) return false;
    // An exercise this version cannot play never reaches the Duel (Build
    // 256 Revision 6, plan A.6).
    if (!exercise.isExecutable) return false;
    final features = ExerciseFeatures(exercise);
    if (features.multipleSelection || features.hasInlineTargets) return false;
    final evaluation = exercise.canonicalEvaluation;
    if (evaluation.mode != EvaluationMode.exactItem) return false;
    if (exercise.items.length < 2 || evaluation.correctItemIds.length != 1) {
      return false;
    }
    final correct = evaluation.correctItemIds.single;
    return exercise.items.any((item) => item.id == correct);
  }

  /// [includeDrafts] counts Draft Lessons, Rounds and exercises too: the
  /// Course preview from the Course Editor (Build 261 Revision 2).
  DuelEligibilityResult evaluate(Lesson lesson, {bool includeDrafts = false}) {
    final candidates = <DuelCandidate>[];
    final seen = <String>{};

    if (!includeDrafts && !lesson.publicationState.isPublished) {
      return const DuelEligibilityResult(
        candidates: [],
        requiredCount: requiredQuestionCount,
        structuralEligibleCount: 0,
      );
    }

    for (final round in lesson.rounds) {
      if (!includeDrafts && !round.publicationState.isPublished) continue;
      // Build 256 Revision 5: a Story's exercises depend on its dialogue
      // and never enter the Duel pool (owner decision). A sequence is a
      // plain Round played in order, so its exercises do (Revision 7, third
      // follow-up); a flow that branches is not a sequence.
      if (round.isStory || (round.flow != null && !round.flow!.isLinear)) {
        continue;
      }
      for (final exercise in round.exercises) {
        if (!includeDrafts && !exercise.publicationState.isPublished) {
          continue;
        }
        if (!isEligible(exercise)) continue;
        final features = ExerciseFeatures(exercise);
        final correct = exercise.canonicalEvaluation.correctItemIds.single;
        final correctText = exercise.items
            .where((item) => item.id == correct)
            .map((item) => item.value)
            .first;
        final duplicateKey = [
          exercise.id,
          features.kind.name,
          for (final element in exercise.promptElements)
            element.text.trim().toLowerCase(),
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
    bool includeDrafts = false,
  }) async {
    final structural = evaluate(lesson, includeDrafts: includeDrafts);
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
