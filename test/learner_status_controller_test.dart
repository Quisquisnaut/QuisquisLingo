import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/controllers/learner_status_controller.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/learner_status_events.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/progress_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/services/xp_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Profiles extends ProfileService {
  String? active = 'Alice';

  @override
  Future<String?> getActiveProfile() async => active;
}

class _Settings extends SettingsService {
  String? selected = 'IT';
  int goal = 1000;

  @override
  Future<String?> getLastSelectedCourseCode() async => selected;

  @override
  Future<int> getWeeklyXpTarget() async => goal;
}

class _Courses extends CourseService {
  Course? bundled;

  @override
  Future<Course> loadCourse(String languageCode) async => bundled!;
}

class _Editor extends CourseEditorService {
  List<Course> courses = [];

  @override
  Future<List<Course>> listUserCourses() async => courses;
}

class _Progress extends ProgressService {
  _Progress(this.profiles) : super(now: () => DateTime(2026, 8, 27, 12));

  final _Profiles profiles;
  final Map<String, int> weeklyByProfile = {'Alice': 1250, 'Bob': 75};
  final Map<String, int> streakByProfile = {'Alice': 14, 'Bob': 3};
  final Map<String, Set<String>> laurelsByCourse = {
    'bundled_it': {'round_1', 'round_2'},
  };
  int weeklyReads = 0;

  @override
  Future<int> getWeeklyXp() async {
    weeklyReads++;
    return weeklyByProfile[profiles.active] ?? 0;
  }

  @override
  Future<int> getStreak({required String courseCode}) async =>
      streakByProfile[profiles.active] ?? 0;

  @override
  Future<Set<String>> getPerfectRounds({required String courseId}) async =>
      laurelsByCourse[courseId] ?? <String>{};
}

class _DelayedProfiles extends _Profiles {
  final List<Completer<String?>> reads = [];

  @override
  Future<String?> getActiveProfile() {
    final completer = Completer<String?>();
    reads.add(completer);
    return completer.future;
  }
}

class _FakeTimer implements Timer {
  _FakeTimer(this.callback);

  final void Function() callback;
  bool _active = true;

  void fire() {
    if (_active) callback();
  }

  @override
  void cancel() => _active = false;

  @override
  bool get isActive => _active;

  @override
  int get tick => 0;
}

class _MutableClock {
  _MutableClock(this.value);

  DateTime value;

  DateTime call() => value;
}

Course _course({
  String id = 'bundled_it',
  String title = 'Italian Complete',
  String target = 'Italian',
  String flagCode = '',
  String flagImageBase64 = '',
}) => Course(
  courseId: id,
  learningLanguage: target,
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: target,
  title: title,
  ttsLanguage: 'it-IT',
  version: '1',
  flagCode: flagCode,
  flagImageBase64: flagImageBase64,
  topics: const [],
);

Future<void> _flush() => Future<void>.delayed(Duration.zero);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _Profiles profiles;
  late _Settings settings;
  late _Courses courses;
  late _Editor editor;
  late _Progress progress;
  late StreamController<LearnerStatusInvalidation> events;
  late List<_FakeTimer> timers;

  LearnerStatusController createController() => LearnerStatusController(
    profileService: profiles,
    settingsService: settings,
    courseService: courses,
    courseEditorService: editor,
    progressService: progress,
    invalidations: events.stream,
    now: () => DateTime(2026, 8, 27, 12),
    timerFactory: (_, callback) {
      final timer = _FakeTimer(callback);
      timers.add(timer);
      return timer;
    },
    observeLifecycle: false,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    profiles = _Profiles();
    settings = _Settings();
    courses = _Courses()..bundled = _course();
    editor = _Editor();
    progress = _Progress(profiles);
    events = StreamController<LearnerStatusInvalidation>.broadcast(sync: true);
    timers = [];
  });

  tearDown(() => events.close());

  test(
    'initial bundled state uses loaded Course.title and authoritative data',
    () async {
      final controller = createController();
      await controller.refresh();

      expect(controller.state.course?.title, 'Italian Complete');
      expect(controller.state.weeklyXp, 1250);
      expect(controller.state.weeklyXpGoal, 1000);
      expect(controller.state.streak, 14);
      expect(controller.state.laurels, 2);
      expect(controller.state.activeProfile, 'Alice');
      controller.dispose();
    },
  );

  test(
    'locally edited bundled title is reread after metadata invalidation',
    () async {
      final controller = createController();
      await controller.refresh();
      courses.bundled = _course(title: 'Edited bundled title');

      events.add(LearnerStatusInvalidation.courseMetadata);
      await _flush();

      expect(controller.state.course?.title, 'Edited bundled title');
      controller.dispose();
    },
  );

  test(
    'custom/imported title and flag metadata come from the Course',
    () async {
      settings.selected = 'custom:imported_course';
      editor.courses = [
        _course(
          id: 'imported_course',
          title: 'A very personal course',
          target: 'Esperanto',
          flagCode: 'FI',
          flagImageBase64: 'aW1wb3J0ZWQ=',
        ),
      ];
      final controller = createController();
      await controller.refresh();

      expect(controller.state.course?.title, 'A very personal course');
      expect(controller.state.course?.flagCode, 'FI');
      expect(controller.state.course?.flagImageBase64, 'aW1wb3J0ZWQ=');
      controller.dispose();
    },
  );

  test(
    'deleting the active custom course clears course, flag, and streak',
    () async {
      settings.selected = 'custom:active_custom';
      editor.courses = [_course(id: 'active_custom', flagCode: 'DE')];
      final controller = createController();
      await controller.refresh();
      editor.courses = [];

      events.add(LearnerStatusInvalidation.courseMetadata);
      await _flush();

      expect(controller.state.course, isNull);
      expect(controller.state.courseCode, isNull);
      expect(controller.state.streak, isNull);
      expect(controller.state.laurels, isNull);
      expect(controller.state.weeklyXp, 1250);
      controller.dispose();
    },
  );

  test(
    'profile, XP, activity, goal, and course invalidations reread state',
    () async {
      final controller = createController();
      await controller.refresh();

      profiles.active = 'Bob';
      settings.goal = 2000;
      courses.bundled = _course(title: 'New title', flagCode: 'DE');
      for (final event in LearnerStatusInvalidation.values) {
        events.add(event);
      }
      await _flush();

      expect(controller.state.activeProfile, 'Bob');
      expect(controller.state.weeklyXp, 75);
      expect(controller.state.weeklyXpGoal, 2000);
      expect(controller.state.streak, 3);
      expect(controller.state.laurels, 2);
      expect(controller.state.course?.title, 'New title');
      expect(controller.state.course?.flagCode, 'DE');
      controller.dispose();
    },
  );

  test(
    'Laurel invalidation rereads the course-owned authoritative count',
    () async {
      final controller = createController();
      await controller.refresh();
      progress.laurelsByCourse['bundled_it'] = {
        'round_1',
        'round_2',
        'round_3',
      };

      events.add(LearnerStatusInvalidation.laurels);
      await _flush();

      expect(controller.state.laurels, 3);
      controller.dispose();
    },
  );

  test(
    'an older asynchronous refresh cannot overwrite a newer refresh',
    () async {
      final delayed = _DelayedProfiles();
      profiles = delayed;
      progress = _Progress(profiles);
      final controller = createController();
      await _flush();
      expect(delayed.reads, hasLength(1));

      final newer = controller.refresh();
      expect(delayed.reads, hasLength(2));
      delayed.reads[1].complete('Bob');
      await newer;
      delayed.reads[0].complete('Alice');
      await _flush();

      expect(controller.state.activeProfile, 'Bob');
      controller.dispose();
    },
  );

  test('day boundary and resume reread authoritative values', () async {
    final controller = createController();
    await controller.refresh();
    progress.weeklyByProfile['Alice'] = 0;
    progress.streakByProfile['Alice'] = 0;

    timers.single.fire();
    await _flush();
    expect(controller.state.weeklyXp, 0);
    expect(controller.state.streak, 0);

    progress.weeklyByProfile['Alice'] = 20;
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await _flush();
    expect(controller.state.weeklyXp, 20);
    controller.dispose();
  });

  test('dispose cancels timer and invalidation subscription', () async {
    final controller = createController();
    await controller.refresh();
    final reads = progress.weeklyReads;
    final timer = timers.single;

    controller.dispose();
    events.add(LearnerStatusInvalidation.xp);
    timer.fire();
    await _flush();

    expect(timer.isActive, isFalse);
    expect(progress.weeklyReads, reads);
  });

  test(
    'missing persisted weekly goal uses the existing 1000 default',
    () async {
      final actualSettings = SettingsService();
      final controller = LearnerStatusController(
        profileService: profiles,
        settingsService: actualSettings,
        courseService: courses,
        courseEditorService: editor,
        progressService: progress,
        invalidations: events.stream,
        timerFactory: (_, callback) => _FakeTimer(callback),
        observeLifecycle: false,
      );
      await controller.refresh();

      expect(controller.state.weeklyXpGoal, 1000);
      controller.dispose();
    },
  );

  test(
    'Sunday boundary delegates rollover to XpService while mounted',
    () async {
      final clock = _MutableClock(DateTime(2026, 8, 22, 23, 59));
      SharedPreferences.setMockInitialValues({
        'learner_profiles': ['Tester'],
        'active_learner': 'Tester',
        'last_selected_course_code': 'IT',
      });
      final xp = XpService(now: clock.call);
      await xp.addXp(25, courseCode: 'IT', courseId: 'course_it');
      final boundaryTimers = <_FakeTimer>[];
      final controller = LearnerStatusController(
        courseService: courses,
        courseEditorService: editor,
        progressService: ProgressService(now: clock.call),
        now: clock.call,
        timerFactory: (_, callback) {
          final timer = _FakeTimer(callback);
          boundaryTimers.add(timer);
          return timer;
        },
        invalidations: events.stream,
        observeLifecycle: false,
      );
      await controller.refresh();
      expect(controller.state.weeklyXp, 25);

      clock.value = DateTime(2026, 8, 23);
      boundaryTimers.single.fire();
      await _flush();

      expect(controller.state.weeklyXp, 0);
      expect(await XpService(now: clock.call).getLastWeekXp(), 25);
      controller.dispose();
    },
  );

  test(
    'controller recreation rereads persisted course/profile/XP/goal/streak',
    () async {
      final clock = _MutableClock(DateTime(2026, 8, 27, 12));
      SharedPreferences.setMockInitialValues({
        'learner_profiles': ['Persisted'],
        'active_learner': 'Persisted',
        'last_selected_course_code': 'IT',
        'weekly_xp_target': 2000,
      });
      final actualProgress = ProgressService(now: clock.call);
      await actualProgress.addXp(125, courseCode: 'IT', courseId: 'course_it');
      await actualProgress.registerLearningActivity(courseCode: 'IT');
      await actualProgress.markPerfectRound('round_1', courseId: 'bundled_it');

      LearnerStatusController buildController() => LearnerStatusController(
        courseService: courses,
        courseEditorService: editor,
        progressService: ProgressService(now: clock.call),
        now: clock.call,
        timerFactory: (_, callback) => _FakeTimer(callback),
        invalidations: events.stream,
        observeLifecycle: false,
      );

      final first = buildController();
      await first.refresh();
      expect(first.state.activeProfile, 'Persisted');
      expect(first.state.course?.title, 'Italian Complete');
      expect(first.state.weeklyXp, 125);
      expect(first.state.weeklyXpGoal, 2000);
      expect(first.state.streak, 1);
      expect(first.state.laurels, 1);
      first.dispose();

      final recreated = buildController();
      await recreated.refresh();
      expect(recreated.state.activeProfile, 'Persisted');
      expect(recreated.state.course?.title, 'Italian Complete');
      expect(recreated.state.weeklyXp, 125);
      expect(recreated.state.weeklyXpGoal, 2000);
      expect(recreated.state.streak, 1);
      expect(recreated.state.laurels, 1);
      recreated.dispose();
    },
  );
}
