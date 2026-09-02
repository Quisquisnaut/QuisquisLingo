import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/learning_completion_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MutableClock {
  _MutableClock(this.value);

  DateTime value;

  DateTime call() => value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'perfect first completion preserves sequential persistence and accounting order',
    () async {
      final events = <String>[];
      final progress = _FakeLearningCompletionProgress(
        events: events,
        weeklyXpValues: [90, 135],
        newlyEarnedLaurel: true,
      );
      final service = LearningCompletionService.withProgress(progress);

      final result = await service.completeRound(
        _request(
          errorsThisAttempt: 0,
          firstPassCorrect: 3,
          wasCompletedAtStart: false,
          ttsWasSkipped: false,
          factEvents: events,
        ),
        onNewLaurel: () => _event(events, 'newLaurel'),
        getWeeklyXpTarget: () => _valueEvent(events, 'weeklyTarget', 100),
      );

      expect(events, [
        'completeRound:start',
        'completeRound:completedRoundPersisted',
        'activity:first',
        'completeRound:end',
        'attemptFacts:recent',
        'recentRound:start',
        'recentRound:end',
        'attemptFacts:perfect',
        'perfectRound:start',
        'perfectRound:end',
        'newLaurel:start',
        'newLaurel:end',
        'attemptFacts:scoring',
        'weeklyXp:1:start',
        'weeklyXp:1:end',
        'addXp:45:start',
        'addXp:45:end',
        'weeklyXp:2:start',
        'weeklyXp:2:end',
        'weeklyTarget:start',
        'weeklyTarget:end',
        'activity:second:start',
        'activity:second:end',
      ]);
      expect(progress.completedRoundId, 'round_1');
      expect(progress.completedCourseId, 'course_1');
      expect(progress.completedCourseCode, 'IT');
      expect(progress.recentCourseId, 'course_1');
      expect(progress.recentLessonId, 'lesson_1');
      expect(progress.recentRoundId, 'round_1');
      expect(progress.recentRoundErrors, 0);
      expect(progress.perfectCourseId, 'course_1');
      expect(progress.perfectRoundId, 'round_1');
      expect(progress.addedXp, 45);
      expect(progress.addedCourseId, 'course_1');
      expect(progress.addedCourseCode, 'IT');
      expect(progress.activityCourseCode, 'IT');
      expect(progress.effectiveActivityRegistrations, 2);
      expect(result.roundXp.correctAnswerXp, 15);
      expect(result.roundXp.perfectBonusXp, 5);
      expect(result.roundXp.laurelBonusXp, 25);
      expect(result.awardedXp, 45);
      expect(result.weeklyXpBefore, 90);
      expect(result.weeklyXpAfter, 135);
      expect(result.weeklyXpTarget, 100);
      expect(result.newlyEarnedLaurel, isTrue);
      expect(result.crossedWeeklyXpTarget, isTrue);
    },
  );

  test(
    'first Lesson completion is included in the same awarded total',
    () async {
      final events = <String>[];
      final progress = _FakeLearningCompletionProgress(
        events: events,
        weeklyXpValues: [10, 70],
        newlyEarnedLaurel: true,
        lessonCompletionAward: 25,
      );
      final service = LearningCompletionService.withProgress(progress);

      final result = await service.completeRound(
        LearningCompletionRequest(
          roundId: 'round_1',
          lessonId: 'lesson_1',
          courseId: 'course_1',
          courseCode: 'IT',
          completedLessonId: 'lesson_1',
          readAttemptFacts: () => const LearningCompletionAttemptFacts(
            errorsThisAttempt: 0,
            firstPassCorrect: 1,
            evaluableExerciseCount: 1,
            wasCompletedAtStart: false,
            ttsWasSkipped: false,
          ),
        ),
        onNewLaurel: () async {},
        getWeeklyXpTarget: () async => 1000,
      );

      expect(progress.completedLessonId, 'lesson_1');
      expect(result.roundXp.totalXp, 35);
      expect(result.lessonCompletionXp, 25);
      expect(result.awardedXp, 60);
      expect(result.weeklyXpAfter - result.weeklyXpBefore, 60);
      expect(result.firstPassCorrect, 1);
      expect(result.evaluableExerciseCount, 1);
    },
  );

  test(
    'attempt facts are read lazily at the original await boundaries',
    () async {
      final events = <String>[];
      final progress = _FakeLearningCompletionProgress(
        events: events,
        weeklyXpValues: [40, 50],
      );
      final service = LearningCompletionService.withProgress(progress);
      final stagedFacts = [
        const LearningCompletionAttemptFacts(
          errorsThisAttempt: 0,
          firstPassCorrect: 0,
          wasCompletedAtStart: false,
          ttsWasSkipped: false,
        ),
        const LearningCompletionAttemptFacts(
          errorsThisAttempt: 1,
          firstPassCorrect: 2,
          wasCompletedAtStart: false,
          ttsWasSkipped: false,
        ),
        const LearningCompletionAttemptFacts(
          errorsThisAttempt: 1,
          firstPassCorrect: 2,
          wasCompletedAtStart: false,
          ttsWasSkipped: false,
        ),
      ];
      var factsRead = 0;

      final result = await service.completeRound(
        LearningCompletionRequest(
          roundId: 'round_1',
          lessonId: 'lesson_1',
          courseId: 'course_1',
          courseCode: 'IT',
          readAttemptFacts: () {
            events.add('attemptFacts:${factsRead + 1}');
            return stagedFacts[factsRead++];
          },
        ),
        onNewLaurel: () async {},
        getWeeklyXpTarget: () async => 100,
      );

      expect(
        events.indexOf('attemptFacts:1'),
        greaterThan(events.indexOf('completeRound:end')),
      );
      expect(
        events.indexOf('attemptFacts:2'),
        greaterThan(events.indexOf('recentRound:end')),
      );
      expect(
        events.indexOf('attemptFacts:3'),
        greaterThan(events.indexOf('attemptFacts:2')),
      );
      expect(progress.recentRoundErrors, 0);
      expect(progress.perfectRoundCalls, 0);
      expect(progress.ttsSkippedPerfectRoundCalls, 0);
      expect(progress.addedXp, 10);
      expect(result.awardedXp, 10);
      expect(factsRead, 3);
    },
  );

  test(
    'perfect repeat uses repeat answer XP plus the repeatable perfect bonus',
    () async {
      final progress = _FakeLearningCompletionProgress(
        events: <String>[],
        weeklyXpValues: [20, 31],
        newlyEarnedLaurel: false,
      );
      final service = LearningCompletionService.withProgress(progress);
      var laurelCallbackCalled = false;

      final result = await service.completeRound(
        _request(
          errorsThisAttempt: 0,
          firstPassCorrect: 3,
          wasCompletedAtStart: true,
          ttsWasSkipped: false,
        ),
        onNewLaurel: () async => laurelCallbackCalled = true,
        getWeeklyXpTarget: () async => 100,
      );

      expect(result.roundXp.correctAnswerXp, 6);
      expect(result.roundXp.perfectBonusXp, 5);
      expect(result.roundXp.laurelBonusXp, 0);
      expect(result.awardedXp, 11);
      expect(progress.addedXp, 11);
      expect(progress.perfectRoundCalls, 1);
      expect(progress.ttsSkippedPerfectRoundCalls, 0);
      expect(laurelCallbackCalled, isFalse);
    },
  );

  test('reload cannot re-award an already persisted Laurel bonus', () async {
    await ProfileService().addProfile('Reloaded Laurel Learner');
    final progress = ProgressService();
    await progress.completeRound(
      'round_1',
      courseId: 'course_1',
      courseCode: 'IT',
    );
    await progress.markPerfectRound('round_1', courseId: 'course_1');

    final reloaded = LearningCompletionService(
      progressService: ProgressService(),
    );
    final result = await reloaded.completeRound(
      _request(
        errorsThisAttempt: 0,
        firstPassCorrect: 1,
        wasCompletedAtStart: true,
        ttsWasSkipped: false,
      ),
      onNewLaurel: () async {},
      getWeeklyXpTarget: () async => 100,
    );

    expect(result.roundXp.correctAnswerXp, 2);
    expect(result.roundXp.perfectBonusXp, 5);
    expect(result.roundXp.laurelBonusXp, 0);
    expect(result.awardedXp, 7);
    expect(await ProgressService().getWeeklyXp(), 7);
  });

  test('imperfect repeat keeps first-pass-correct scoring', () async {
    final progress = _FakeLearningCompletionProgress(
      events: <String>[],
      weeklyXpValues: [12, 16],
    );
    final service = LearningCompletionService.withProgress(progress);

    final result = await service.completeRound(
      _request(
        errorsThisAttempt: 2,
        firstPassCorrect: 2,
        wasCompletedAtStart: true,
        ttsWasSkipped: false,
      ),
      onNewLaurel: () async {},
      getWeeklyXpTarget: () async => 100,
    );

    expect(result.awardedXp, 4);
    expect(progress.addedXp, 4);
    expect(progress.perfectRoundCalls, 0);
    expect(progress.ttsSkippedPerfectRoundCalls, 0);
  });

  test(
    'TTS-skipped zero-error completion persists provisional state and adds the perfect bonus',
    () async {
      final events = <String>[];
      final progress = _FakeLearningCompletionProgress(
        events: events,
        weeklyXpValues: [0, 5],
      );
      final service = LearningCompletionService.withProgress(progress);
      var laurelCallbackCalled = false;

      final result = await service.completeRound(
        _request(
          errorsThisAttempt: 0,
          firstPassCorrect: 0,
          wasCompletedAtStart: false,
          ttsWasSkipped: true,
        ),
        onNewLaurel: () async => laurelCallbackCalled = true,
        getWeeklyXpTarget: () => _valueEvent(events, 'weeklyTarget', 100),
      );

      expect(
        events.indexOf('ttsSkippedPerfectRound:start'),
        greaterThan(events.indexOf('recentRound:end')),
      );
      expect(
        events.indexOf('ttsSkippedPerfectRound:end'),
        lessThan(events.indexOf('weeklyXp:1:start')),
      );
      expect(events.where((event) => event == 'addXp:5:start'), hasLength(1));
      expect(progress.addedXp, 5);
      expect(progress.addXpCalls, 1);
      expect(progress.perfectRoundCalls, 0);
      expect(progress.ttsSkippedPerfectRoundCalls, 1);
      expect(progress.ttsSkippedPerfectCourseId, 'course_1');
      expect(progress.ttsSkippedPerfectRoundId, 'round_1');
      expect(progress.effectiveActivityRegistrations, 2);
      expect(laurelCallbackCalled, isFalse);
      expect(result.roundXp.correctAnswerXp, 0);
      expect(result.roundXp.perfectBonusXp, 5);
      expect(result.awardedXp, 5);
      expect(result.newlyEarnedLaurel, isFalse);
    },
  );

  test(
    'new-laurel callback failure stops before XP and later activity',
    () async {
      final events = <String>[];
      final progress = _FakeLearningCompletionProgress(
        events: events,
        weeklyXpValues: [0, 5],
        newlyEarnedLaurel: true,
      );
      final service = LearningCompletionService.withProgress(progress);

      await expectLater(
        service.completeRound(
          _request(
            errorsThisAttempt: 0,
            firstPassCorrect: 1,
            wasCompletedAtStart: false,
            ttsWasSkipped: false,
          ),
          onNewLaurel: () async {
            events.add('newLaurel:start');
            throw StateError('sound failed');
          },
          getWeeklyXpTarget: () async => 100,
        ),
        throwsStateError,
      );

      expect(events, [
        'completeRound:start',
        'completeRound:completedRoundPersisted',
        'activity:first',
        'completeRound:end',
        'recentRound:start',
        'recentRound:end',
        'perfectRound:start',
        'perfectRound:end',
        'newLaurel:start',
      ]);
      expect(progress.addXpCalls, 0);
      expect(progress.effectiveActivityRegistrations, 1);
    },
  );

  test(
    'six-exercise repeat and completed Lesson add only the authoritative 10 XP',
    () async {
      final clock = _MutableClock(DateTime(2026, 8, 28, 12));
      final profiles = ProfileService();
      await profiles.addProfile('Repeat Lesson Learner');
      final progress = ProgressService(now: clock.call);
      final service = LearningCompletionService(progressService: progress);
      await progress.addXp(85, courseCode: 'IT', courseId: 'course_1');
      await progress.completeLesson(
        'lesson_1',
        courseId: 'course_1',
        courseCode: 'IT',
      );
      // Preserve the observed starting point while retaining the authoritative
      // already-completed Lesson state.
      final prefs = await SharedPreferences.getInstance();
      final prefix = ProfileService.prefixForProfileId(
        (await profiles.getActiveProfileId())!,
      );
      await prefs.setInt('${prefix}xp_IT', 85);
      await prefs.setInt('${prefix}week_xp', 85);
      await prefs.setString('${prefix}week_xp_by_course', '{"course_1":85}');

      final result = await service.completeRound(
        _request(
          errorsThisAttempt: 1,
          firstPassCorrect: 5,
          wasCompletedAtStart: true,
          ttsWasSkipped: false,
        ),
        onNewLaurel: () async {},
        getWeeklyXpTarget: () async => 1000,
      );
      expect(result.awardedXp, 10);
      expect(result.weeklyXpBefore, 85);
      expect(result.weeklyXpAfter, 95);

      final lessonAward = await progress.completeLesson(
        'lesson_1',
        courseId: 'course_1',
        courseCode: 'IT',
      );
      expect(lessonAward, 0);
      expect(await progress.getXp(courseCode: 'IT'), 95);
      expect(await progress.getWeeklyXp(), 95);
    },
  );

  test(
    'real Round completion preserves two activity dates when its duplicate registrations cross midnight',
    () async {
      final clock = _MutableClock(DateTime(2026, 8, 25, 23, 59));
      final profiles = ProfileService();
      await profiles.addProfile('Midnight Learner');
      final progress = ProgressService(now: clock.call);
      final service = LearningCompletionService(progressService: progress);

      await service.completeRound(
        _request(
          errorsThisAttempt: 1,
          firstPassCorrect: 1,
          wasCompletedAtStart: false,
          ttsWasSkipped: false,
        ),
        onNewLaurel: () async {},
        getWeeklyXpTarget: () async {
          clock.value = DateTime(2026, 8, 26);
          return 100;
        },
      );

      final prefs = await SharedPreferences.getInstance();
      final prefix = ProfileService.prefixForProfileId(
        (await profiles.getActiveProfileId())!,
      );
      expect(await progress.getStreak(courseCode: 'IT'), 2);
      expect(await progress.getDaysStudied(courseCode: 'IT'), 2);
      expect(prefs.getInt('${prefix}streak_IT'), 2);
      expect(
        prefs.getString('${prefix}last_active_IT'),
        '2026-08-26T00:00:00.000',
      );
      expect(prefs.getStringList('${prefix}study_days_IT'), [
        '2026-08-25',
        '2026-08-26',
      ]);
      expect(prefs.getStringList('${prefix}study_days_all'), [
        '2026-08-25',
        '2026-08-26',
      ]);
    },
  );

  test(
    'weekly celebration is claimed only when not already celebrated',
    () async {
      final events = <String>[];
      final progress = _FakeLearningCompletionProgress(
        events: events,
        weeklyXpValues: const [],
      );
      final service = LearningCompletionService.withProgress(progress);

      expect(await service.claimWeeklyGoalCelebration(), isTrue);
      expect(events, [
        'weeklyCelebrated:start',
        'weeklyCelebrated:end',
        'markWeeklyCelebrated:start',
        'markWeeklyCelebrated:end',
      ]);

      events.clear();
      expect(await service.claimWeeklyGoalCelebration(), isFalse);
      expect(events, ['weeklyCelebrated:start', 'weeklyCelebrated:end']);
    },
  );
}

LearningCompletionRequest _request({
  required int errorsThisAttempt,
  required int firstPassCorrect,
  required bool wasCompletedAtStart,
  required bool ttsWasSkipped,
  List<String>? factEvents,
}) {
  final facts = LearningCompletionAttemptFacts(
    errorsThisAttempt: errorsThisAttempt,
    firstPassCorrect: firstPassCorrect,
    wasCompletedAtStart: wasCompletedAtStart,
    ttsWasSkipped: ttsWasSkipped,
  );
  const readStages = ['recent', 'perfect', 'scoring'];
  var readIndex = 0;
  return LearningCompletionRequest(
    roundId: 'round_1',
    lessonId: 'lesson_1',
    courseId: 'course_1',
    courseCode: 'IT',
    readAttemptFacts: () {
      factEvents?.add('attemptFacts:${readStages[readIndex]}');
      readIndex++;
      return facts;
    },
  );
}

Future<void> _event(List<String> events, String name) async {
  events.add('$name:start');
  await Future<void>.delayed(Duration.zero);
  events.add('$name:end');
}

Future<T> _valueEvent<T>(List<String> events, String name, T value) async {
  await _event(events, name);
  return value;
}

class _FakeLearningCompletionProgress implements LearningCompletionProgress {
  final List<String> events;
  final List<int> weeklyXpValues;
  final bool newlyEarnedLaurel;
  final int lessonCompletionAward;

  String? completedRoundId;
  String? completedCourseId;
  String? completedCourseCode;
  String? recentCourseId;
  String? recentLessonId;
  String? recentRoundId;
  int? recentRoundErrors;
  String? perfectCourseId;
  String? perfectRoundId;
  String? ttsSkippedPerfectCourseId;
  String? ttsSkippedPerfectRoundId;
  int? addedXp;
  String? addedCourseId;
  String? addedCourseCode;
  String? activityCourseCode;
  String? completedLessonId;
  int addXpCalls = 0;
  int perfectRoundCalls = 0;
  int ttsSkippedPerfectRoundCalls = 0;
  int effectiveActivityRegistrations = 0;
  int _weeklyXpReadIndex = 0;
  bool _weeklyGoalCelebrated = false;

  _FakeLearningCompletionProgress({
    required this.events,
    required this.weeklyXpValues,
    this.newlyEarnedLaurel = false,
    this.lessonCompletionAward = 0,
  });

  @override
  Future<void> completeRound(
    String id, {
    required String courseId,
    required String courseCode,
  }) async {
    events.add('completeRound:start');
    await Future<void>.delayed(Duration.zero);
    completedRoundId = id;
    completedCourseId = courseId;
    completedCourseCode = courseCode;
    events.add('completeRound:completedRoundPersisted');
    await Future<void>.delayed(Duration.zero);
    effectiveActivityRegistrations++;
    events.add('activity:first');
    await Future<void>.delayed(Duration.zero);
    events.add('completeRound:end');
  }

  @override
  Future<void> recordRecentRound(
    String courseId,
    String lessonId,
    String roundId, {
    required int errors,
  }) async {
    recentCourseId = courseId;
    recentLessonId = lessonId;
    recentRoundId = roundId;
    recentRoundErrors = errors;
    await _event(events, 'recentRound');
  }

  @override
  Future<bool> markPerfectRound(
    String roundId, {
    required String courseId,
  }) async {
    perfectRoundCalls++;
    perfectCourseId = courseId;
    perfectRoundId = roundId;
    return _valueEvent(events, 'perfectRound', newlyEarnedLaurel);
  }

  @override
  Future<void> markTtsSkippedPerfectRound(
    String roundId, {
    required String courseId,
  }) async {
    ttsSkippedPerfectRoundCalls++;
    ttsSkippedPerfectCourseId = courseId;
    ttsSkippedPerfectRoundId = roundId;
    await _event(events, 'ttsSkippedPerfectRound');
  }

  @override
  Future<int> getWeeklyXp() {
    final readNumber = _weeklyXpReadIndex + 1;
    final value = weeklyXpValues[_weeklyXpReadIndex++];
    return _valueEvent(events, 'weeklyXp:$readNumber', value);
  }

  @override
  Future<void> addXp(
    int amount, {
    required String courseCode,
    required String courseId,
  }) async {
    addXpCalls++;
    addedXp = amount;
    addedCourseId = courseId;
    addedCourseCode = courseCode;
    await _event(events, 'addXp:$amount');
  }

  @override
  Future<void> registerLearningActivity({required String courseCode}) async {
    effectiveActivityRegistrations++;
    activityCourseCode = courseCode;
    await _event(events, 'activity:second');
  }

  @override
  Future<int> completeLesson(
    String id, {
    required String courseId,
    required String courseCode,
  }) async {
    completedLessonId = id;
    await _event(events, 'completeLesson');
    return lessonCompletionAward;
  }

  @override
  Future<bool> isWeeklyGoalCelebrated() =>
      _valueEvent(events, 'weeklyCelebrated', _weeklyGoalCelebrated);

  @override
  Future<void> markWeeklyGoalCelebrated() async {
    await _event(events, 'markWeeklyCelebrated');
    _weeklyGoalCelebrated = true;
  }
}
