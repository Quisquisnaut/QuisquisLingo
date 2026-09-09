import 'settings_service.dart';

/// Pure learner-page presentation rules for Lesson expansion.
abstract final class LessonExpansionPolicy {
  static bool isExpanded({
    required LearnerLessonExpansionMode mode,
    required bool hasAccess,
    required bool isCompleted,
    required bool isCurrent,
  }) {
    if (!hasAccess) return false;
    return switch (mode) {
      LearnerLessonExpansionMode.expanded => true,
      LearnerLessonExpansionMode.collapseCompleted => !isCompleted,
      LearnerLessonExpansionMode.focused => isCurrent,
    };
  }
}
