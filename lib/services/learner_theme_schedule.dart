import 'dart:ui';

/// Resolves the learner Day/Night theme from local device wall-clock time.
abstract final class LearnerThemeSchedule {
  static const int lightStartHour = 7;
  static const int darkStartHour = 19;

  static Brightness brightnessAt(DateTime localTime) =>
      localTime.hour >= lightStartHour && localTime.hour < darkStartHour
      ? Brightness.light
      : Brightness.dark;

  static DateTime nextBoundaryAfter(DateTime localTime) {
    final lightBoundary = DateTime(
      localTime.year,
      localTime.month,
      localTime.day,
      lightStartHour,
    );
    if (localTime.isBefore(lightBoundary)) return lightBoundary;

    final darkBoundary = DateTime(
      localTime.year,
      localTime.month,
      localTime.day,
      darkStartHour,
    );
    if (localTime.isBefore(darkBoundary)) return darkBoundary;

    return DateTime(
      localTime.year,
      localTime.month,
      localTime.day + 1,
      lightStartHour,
    );
  }
}
