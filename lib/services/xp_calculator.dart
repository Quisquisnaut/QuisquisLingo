class RoundXpAwardContext {
  final bool completed;
  final int errorsThisAttempt;
  final int firstPassCorrect;
  final bool wasCompletedAtStart;
  final bool newlyEarnedLaurel;
  final bool firstOnTimeCompletion;

  /// How many evaluable exercises the attempt presented; null when the
  /// caller does not state it. Zero means a Round of cards, covers or lines
  /// only, which awards nothing (owner decision, 28 September 2026).
  final int? evaluableExerciseCount;

  /// The sum of the difficulty levels (`ExerciseDifficulty`, 0 to 4) of the
  /// exercises answered correctly at the first attempt; zero when the
  /// caller does not state it (Build 260 Revision 6).
  final int firstPassDifficulty;

  const RoundXpAwardContext({
    required this.completed,
    required this.errorsThisAttempt,
    required this.firstPassCorrect,
    required this.wasCompletedAtStart,
    required this.newlyEarnedLaurel,
    this.firstOnTimeCompletion = false,
    this.evaluableExerciseCount,
    this.firstPassDifficulty = 0,
  });
}

class RoundXpResult {
  final int correctAnswerXp;
  final int perfectBonusXp;
  final int laurelBonusXp;
  final int onTimeBonusXp;

  /// 1 XP per difficulty level of each exercise answered correctly at the
  /// first attempt, on a Round's first completion only (Build 260 Revision
  /// 6, owner decision of 1 October 2026).
  final int difficultyBonusXp;

  const RoundXpResult({
    required this.correctAnswerXp,
    required this.perfectBonusXp,
    required this.laurelBonusXp,
    this.onTimeBonusXp = 0,
    this.difficultyBonusXp = 0,
  });

  int get totalXp =>
      correctAnswerXp +
      perfectBonusXp +
      laurelBonusXp +
      difficultyBonusXp +
      onTimeBonusXp;
}

/// Pure XP reward calculations.
///
/// Callers remain responsible for resolving progress state and for persisting
/// the returned amount through XpService.
class XpCalculator {
  static const int _firstCompletionCorrectAnswerXp = 5;
  static const int _repeatCorrectAnswerXp = 2;
  static const int _perfectCompletionXp = 5;
  static const int _firstLaurelXp = 25;
  static const int _difficultyBonusXpPerLevel = 1;
  static const int _firstOnTimeCompletionXp = 10;
  static const int _lessonCompletionXp = 25;
  static const int _firstDuelWinXp = 50;
  static const int _repeatDuelWinXp = 10;

  const XpCalculator();

  RoundXpResult calculateRoundAward(RoundXpAwardContext context) {
    // A Round without an evaluable exercise is completed for progression
    // but scores nothing: no answer XP, no perfect bonus, no Laurel.
    if (!context.completed || context.evaluableExerciseCount == 0) {
      return const RoundXpResult(
        correctAnswerXp: 0,
        perfectBonusXp: 0,
        laurelBonusXp: 0,
      );
    }
    final xpPerCorrectAnswer = context.wasCompletedAtStart
        ? _repeatCorrectAnswerXp
        : _firstCompletionCorrectAnswerXp;
    return RoundXpResult(
      correctAnswerXp: context.firstPassCorrect * xpPerCorrectAnswer,
      perfectBonusXp: context.errorsThisAttempt == 0 ? _perfectCompletionXp : 0,
      laurelBonusXp: context.newlyEarnedLaurel ? _firstLaurelXp : 0,
      onTimeBonusXp: context.firstOnTimeCompletion
          ? _firstOnTimeCompletionXp
          : 0,
      // Repeats and Review earn no Difficulty bonus.
      difficultyBonusXp: context.wasCompletedAtStart
          ? 0
          : context.firstPassDifficulty * _difficultyBonusXpPerLevel,
    );
  }

  /// A Timed attempt that expires keeps correct-answer XP without granting
  /// completion, difficulty, Perfect, Laurel or On Time bonuses.
  RoundXpResult calculateTimedTimeoutAward({
    required int firstPassCorrect,
    required bool wasCompletedAtStart,
  }) => RoundXpResult(
    correctAnswerXp:
        firstPassCorrect *
        (wasCompletedAtStart
            ? _repeatCorrectAnswerXp
            : _firstCompletionCorrectAnswerXp),
    perfectBonusXp: 0,
    laurelBonusXp: 0,
  );

  int calculateLessonCompletionAward({required bool isFirstCompletion}) =>
      isFirstCompletion ? _lessonCompletionXp : 0;

  int calculateDuelWinAward({required bool wasPreviouslyWon}) =>
      wasPreviouslyWon ? _repeatDuelWinXp : _firstDuelWinXp;
}
