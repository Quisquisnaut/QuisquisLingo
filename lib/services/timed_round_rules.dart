import '../models/course_models.dart';

/// Authoring and progression rules shared by the editor, Audit and player.
abstract final class TimedRoundRules {
  static const minimumSeconds = 30;
  static const maximumSeconds = 600;
  static const presetSeconds = [30, 60, 90, 120, 180, 300];

  static bool validSeconds(int seconds) =>
      seconds >= minimumSeconds && seconds <= maximumSeconds;

  static bool validLimits(List<int> limits) =>
      limits.isNotEmpty &&
      limits.every(validSeconds) &&
      limits.toSet().length == limits.length;

  static int? activeLimit(LearningRound round, Set<int> completed) {
    for (final seconds in round.timedLimitsSeconds) {
      if (!completed.contains(seconds)) return seconds;
    }
    return round.timedLimitsSeconds.lastOrNull;
  }

  static String label(int seconds) =>
      seconds % 60 == 0 ? '${seconds ~/ 60} min' : '$seconds sec';
}
