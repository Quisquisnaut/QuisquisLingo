import 'dart:async';

enum LearnerStatusInvalidation {
  xp,
  activity,
  laurels,
  weeklyGoal,
  activeCourse,
  courseMetadata,
  activeProfile,
}

/// Process-local invalidations. Values remain authoritative in their services.
class LearnerStatusEvents {
  static final StreamController<LearnerStatusInvalidation> _events =
      StreamController<LearnerStatusInvalidation>.broadcast(sync: true);

  static Stream<LearnerStatusInvalidation> get stream => _events.stream;

  static void publish(LearnerStatusInvalidation invalidation) {
    _events.add(invalidation);
  }
}
