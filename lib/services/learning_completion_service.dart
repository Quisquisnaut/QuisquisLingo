import 'progress_service.dart';
import 'xp_calculator.dart';

class LearningCompletionRequest {
  final String roundId;
  final String courseId;
  final String courseCode;

  /// Reads screen-owned attempt state at the same await boundaries used before
  /// extraction, preserving the existing unguarded completion race behavior.
  final LearningCompletionAttemptFacts Function() readAttemptFacts;

  const LearningCompletionRequest({
    required this.roundId,
    required this.courseId,
    required this.courseCode,
    required this.readAttemptFacts,
  });
}

class LearningCompletionAttemptFacts {
  final int errorsThisAttempt;
  final int firstPassCorrect;
  final bool wasCompletedAtStart;
  final bool ttsWasSkipped;

  const LearningCompletionAttemptFacts({
    required this.errorsThisAttempt,
    required this.firstPassCorrect,
    required this.wasCompletedAtStart,
    required this.ttsWasSkipped,
  });
}

class LearningCompletionResult {
  final RoundXpResult roundXp;
  final int weeklyXpBefore;
  final int weeklyXpAfter;
  final int weeklyXpTarget;
  final bool newlyEarnedLaurel;

  const LearningCompletionResult({
    required this.roundXp,
    required this.weeklyXpBefore,
    required this.weeklyXpAfter,
    required this.weeklyXpTarget,
    required this.newlyEarnedLaurel,
  });

  int get awardedXp => roundXp.totalXp;

  bool get crossedWeeklyXpTarget =>
      weeklyXpBefore < weeklyXpTarget && weeklyXpAfter >= weeklyXpTarget;
}

/// The narrow progress/accounting boundary used by [LearningCompletionService].
abstract interface class LearningCompletionProgress {
  Future<void> completeRound(
    String id, {
    required String courseId,
    required String courseCode,
  });

  Future<void> recordRecentRound(
    String courseId,
    String roundId, {
    required int errors,
  });

  Future<bool> markPerfectRound(String roundId, {required String courseId});

  Future<void> markTtsSkippedPerfectRound(
    String roundId, {
    required String courseId,
  });

  Future<int> getWeeklyXp();

  Future<void> addXp(
    int amount, {
    required String courseCode,
    required String courseId,
  });

  Future<void> registerLearningActivity({required String courseCode});

  Future<bool> isWeeklyGoalCelebrated();

  Future<void> markWeeklyGoalCelebrated();
}

class LearningCompletionService {
  final LearningCompletionProgress _progress;
  final XpCalculator _xpCalculator;

  LearningCompletionService({
    ProgressService? progressService,
    XpCalculator xpCalculator = const XpCalculator(),
  }) : _progress = _ProgressServiceLearningCompletionProgress(
         progressService ?? ProgressService(),
       ),
       _xpCalculator = xpCalculator;

  LearningCompletionService.withProgress(
    this._progress, {
    XpCalculator xpCalculator = const XpCalculator(),
  }) : _xpCalculator = xpCalculator;

  Future<LearningCompletionResult> completeRound(
    LearningCompletionRequest request, {
    required Future<void> Function() onNewLaurel,
    required Future<int> Function() getWeeklyXpTarget,
  }) async {
    await _progress.completeRound(
      request.roundId,
      courseId: request.courseId,
      courseCode: request.courseCode,
    );
    // These staged reads deliberately do not collapse attempt state into one
    // earlier snapshot; RoundScreen remains the authority for mutable facts.
    final recentRoundFacts = request.readAttemptFacts();
    await _progress.recordRecentRound(
      request.courseId,
      request.roundId,
      errors: recentRoundFacts.errorsThisAttempt,
    );

    final perfectFacts = request.readAttemptFacts();
    var newlyEarnedLaurel = false;
    if (perfectFacts.errorsThisAttempt == 0 && !perfectFacts.ttsWasSkipped) {
      // A perfect result is permanent once earned, regardless of how the round
      // is entered (course path or Review) or of later imperfect attempts.
      newlyEarnedLaurel = await _progress.markPerfectRound(
        request.roundId,
        courseId: request.courseId,
      );
      // RoundScreen supplies its sound/settings work here so the existing
      // laurel-persisted -> sound -> XP ordering remains intact.
      if (newlyEarnedLaurel) await onNewLaurel();
    } else if (perfectFacts.errorsThisAttempt == 0 &&
        perfectFacts.ttsWasSkipped) {
      // Zero errors among presented exercises gets a separate mark when any
      // TTS exercise was skipped. A later full zero-error attempt can still
      // replace this with the permanent laurel crown.
      await _progress.markTtsSkippedPerfectRound(
        request.roundId,
        courseId: request.courseId,
      );
    }

    final scoringFacts = request.readAttemptFacts();
    final roundXp = _xpCalculator.calculateRoundAward(
      RoundXpAwardContext(
        completed: true,
        errorsThisAttempt: scoringFacts.errorsThisAttempt,
        firstPassCorrect: scoringFacts.firstPassCorrect,
        wasCompletedAtStart: scoringFacts.wasCompletedAtStart,
        newlyEarnedLaurel: newlyEarnedLaurel,
      ),
    );
    final weeklyXpBefore = await _progress.getWeeklyXp();
    await _progress.addXp(
      roundXp.totalXp,
      courseCode: request.courseCode,
      courseId: request.courseId,
    );
    final weeklyXpAfter = await _progress.getWeeklyXp();
    // Keep this read before the explicit second activity registration, matching
    // the current RoundScreen partial-failure and clock-dependent ordering.
    final weeklyXpTarget = await getWeeklyXpTarget();
    await _progress.registerLearningActivity(courseCode: request.courseCode);

    return LearningCompletionResult(
      roundXp: roundXp,
      weeklyXpBefore: weeklyXpBefore,
      weeklyXpAfter: weeklyXpAfter,
      weeklyXpTarget: weeklyXpTarget,
      newlyEarnedLaurel: newlyEarnedLaurel,
    );
  }

  /// Claims the current week's celebration only when RoundScreen has decided
  /// that its mounted lifecycle permits the claim.
  Future<bool> claimWeeklyGoalCelebration() async {
    if (await _progress.isWeeklyGoalCelebrated()) return false;
    await _progress.markWeeklyGoalCelebrated();
    return true;
  }
}

class _ProgressServiceLearningCompletionProgress
    implements LearningCompletionProgress {
  final ProgressService _progress;

  const _ProgressServiceLearningCompletionProgress(this._progress);

  @override
  Future<void> completeRound(
    String id, {
    required String courseId,
    required String courseCode,
  }) => _progress.completeRound(id, courseId: courseId, courseCode: courseCode);

  @override
  Future<void> recordRecentRound(
    String courseId,
    String roundId, {
    required int errors,
  }) => _progress.recordRecentRound(courseId, roundId, errors: errors);

  @override
  Future<bool> markPerfectRound(String roundId, {required String courseId}) =>
      _progress.markPerfectRound(roundId, courseId: courseId);

  @override
  Future<void> markTtsSkippedPerfectRound(
    String roundId, {
    required String courseId,
  }) => _progress.markTtsSkippedPerfectRound(roundId, courseId: courseId);

  @override
  Future<int> getWeeklyXp() => _progress.getWeeklyXp();

  @override
  Future<void> addXp(
    int amount, {
    required String courseCode,
    required String courseId,
  }) => _progress.addXp(amount, courseCode: courseCode, courseId: courseId);

  @override
  Future<void> registerLearningActivity({required String courseCode}) =>
      _progress.registerLearningActivity(courseCode: courseCode);

  @override
  Future<bool> isWeeklyGoalCelebrated() => _progress.isWeeklyGoalCelebrated();

  @override
  Future<void> markWeeklyGoalCelebrated() =>
      _progress.markWeeklyGoalCelebrated();
}
