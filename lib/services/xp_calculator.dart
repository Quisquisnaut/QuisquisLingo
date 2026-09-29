class RoundXpAwardContext {
  final bool completed;
  final int errorsThisAttempt;
  final int firstPassCorrect;
  final bool wasCompletedAtStart;
  final bool newlyEarnedLaurel;

  /// How many evaluable exercises the attempt presented; null when the
  /// caller does not state it. Zero means a Round of cards, covers or lines
  /// only, which awards nothing (owner decision, 28 September 2026).
  final int? evaluableExerciseCount;

  const RoundXpAwardContext({
    required this.completed,
    required this.errorsThisAttempt,
    required this.firstPassCorrect,
    required this.wasCompletedAtStart,
    required this.newlyEarnedLaurel,
    this.evaluableExerciseCount,
  });
}

class RoundXpResult {
  final int correctAnswerXp;
  final int perfectBonusXp;
  final int laurelBonusXp;

  const RoundXpResult({
    required this.correctAnswerXp,
    required this.perfectBonusXp,
    required this.laurelBonusXp,
  });

  int get totalXp => correctAnswerXp + perfectBonusXp + laurelBonusXp;
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
    );
  }

  int calculateLessonCompletionAward({required bool isFirstCompletion}) =>
      isFirstCompletion ? _lessonCompletionXp : 0;

  int calculateDuelWinAward({required bool wasPreviouslyWon}) =>
      wasPreviouslyWon ? _repeatDuelWinXp : _firstDuelWinXp;
}
