class RoundXpAwardContext {
  final int errorsThisAttempt;
  final int firstPassCorrect;
  final int repeatCapExerciseCount;
  final bool wasCompletedAtStart;

  const RoundXpAwardContext({
    required this.errorsThisAttempt,
    required this.firstPassCorrect,
    required this.repeatCapExerciseCount,
    required this.wasCompletedAtStart,
  });
}

/// Pure XP reward calculations.
///
/// Callers remain responsible for resolving progress state and for persisting
/// the returned amount through XpService.
class XpCalculator {
  static const int _xpPerFirstPassCorrectExercise = 5;
  static const int _topicCompletionXp = 25;
  static const int _duelWinXp = 50;

  const XpCalculator();

  int calculateRoundAward(RoundXpAwardContext context) {
    final fullRoundXp =
        context.repeatCapExerciseCount * _xpPerFirstPassCorrectExercise;
    return context.errorsThisAttempt == 0 && context.wasCompletedAtStart
        ? fullRoundXp ~/ 2
        : context.firstPassCorrect * _xpPerFirstPassCorrectExercise;
  }

  int calculatePerfectRoundPotential({
    required int exerciseCount,
    required bool wasCompletedAtStart,
  }) {
    final fullRoundXp = exerciseCount * _xpPerFirstPassCorrectExercise;
    return wasCompletedAtStart ? fullRoundXp ~/ 2 : fullRoundXp;
  }

  int calculateTopicCompletionAward() => _topicCompletionXp;

  int calculateDuelWinAward() => _duelWinXp;
}
