import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/course_models.dart';
import '../models/learner_status_state.dart';
import '../services/course_editor_service.dart';
import '../services/course_service.dart';
import '../services/learner_status_events.dart';
import '../services/profile_service.dart';
import '../services/progress_service.dart';
import '../services/round_playability_service.dart';
import '../services/settings_service.dart';

typedef LearnerStatusTimerFactory =
    Timer Function(Duration duration, void Function() callback);

/// Reactive projection of status values owned by existing domain services.
class LearnerStatusController extends ChangeNotifier
    with WidgetsBindingObserver {
  final CourseService _courses;
  final CourseEditorService _courseEditor;
  final ProfileService _profiles;
  final ProgressService _progress;
  final RoundPlayabilityService _roundPlayability;
  final SettingsService _settings;
  final DateTime Function() _now;
  final LearnerStatusTimerFactory _timerFactory;
  final Stream<LearnerStatusInvalidation> _invalidations;
  final bool _observeLifecycle;

  LearnerStatusState _state = const LearnerStatusState.loading();
  StreamSubscription<LearnerStatusInvalidation>? _subscription;
  Timer? _dayBoundaryTimer;
  int _generation = 0;
  bool _disposed = false;

  LearnerStatusController({
    CourseService? courseService,
    CourseEditorService? courseEditorService,
    ProfileService? profileService,
    ProgressService? progressService,
    RoundPlayabilityService? roundPlayabilityService,
    SettingsService? settingsService,
    DateTime Function()? now,
    LearnerStatusTimerFactory? timerFactory,
    Stream<LearnerStatusInvalidation>? invalidations,
    bool observeLifecycle = true,
  }) : _courses = courseService ?? CourseService(),
       _courseEditor = courseEditorService ?? CourseEditorService(),
       _profiles = profileService ?? ProfileService(),
       _progress = progressService ?? ProgressService(now: now),
       _roundPlayability = roundPlayabilityService ?? RoundPlayabilityService(),
       _settings = settingsService ?? SettingsService(),
       _now = now ?? DateTime.now,
       _timerFactory = timerFactory ?? Timer.new,
       _invalidations = invalidations ?? LearnerStatusEvents.stream,
       _observeLifecycle = observeLifecycle {
    _subscription = _invalidations.listen((_) => unawaited(refresh()));
    if (_observeLifecycle) WidgetsBinding.instance.addObserver(this);
    _scheduleDayBoundary();
    unawaited(refresh());
  }

  LearnerStatusState get state => _state;

  Future<Course?> _resolveActiveCourse() async {
    final saved = await _settings.getLastSelectedCourseCode();
    if (saved != null && saved.startsWith('custom:')) {
      final courseId = saved.substring('custom:'.length);
      final courses = await _courseEditor.listUserCourses();
      for (final course in courses) {
        if (course.courseId == courseId) return course;
      }
      return null;
    }

    final code = saved != null && CourseService.hasCourse(saved) ? saved : 'IT';
    try {
      return await _courses.loadCourse(code);
    } catch (_) {
      return null;
    }
  }

  Future<void> refresh() async {
    final generation = ++_generation;
    final profile = await _profiles.getActiveProfile();
    final course = await _resolveActiveCourse();
    final courseCode = course == null
        ? null
        : CourseService.codeForCourse(course);
    final weeklyXp = await _progress.getWeeklyXp();
    final weeklyGoal = await _settings.getWeeklyXpTarget();
    final streak = courseCode == null
        ? null
        : await _progress.getStreak(courseCode: courseCode);
    final eligibleRoundIds = course == null
        ? null
        : _roundPlayability.laurelEligibleRoundIds(course);
    final perfectRoundIds = course == null
        ? null
        : await _progress.getPerfectRounds(courseId: course.courseId);
    final laurels = eligibleRoundIds == null || perfectRoundIds == null
        ? null
        : perfectRoundIds.intersection(eligibleRoundIds).length;
    final laurelMaximum = eligibleRoundIds?.length;

    if (_disposed || generation != _generation) return;
    _state = LearnerStatusState(
      activeProfile: profile,
      course: course,
      courseCode: courseCode,
      weeklyXp: weeklyXp,
      weeklyXpGoal: weeklyGoal,
      streak: streak,
      laurels: laurels,
      laurelMaximum: laurelMaximum,
    );
    notifyListeners();
  }

  void _scheduleDayBoundary() {
    _dayBoundaryTimer?.cancel();
    final now = _now();
    final nextDay = DateTime(now.year, now.month, now.day + 1);
    var delay = nextDay.difference(now);
    if (delay <= Duration.zero) delay = const Duration(milliseconds: 1);
    _dayBoundaryTimer = _timerFactory(delay, () {
      unawaited(refresh());
      _scheduleDayBoundary();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    _scheduleDayBoundary();
    unawaited(refresh());
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    _dayBoundaryTimer?.cancel();
    _subscription?.cancel();
    if (_observeLifecycle) WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}
