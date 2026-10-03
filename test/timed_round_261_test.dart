import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/progress_service.dart';
import 'package:quisquislingo_app/services/round_type_presentation.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/services/timed_round_rules.dart';
import 'package:quisquislingo_app/services/xp_calculator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

final _stamp = DateTime.utc(2026, 10, 3);

Exercise _question(String id) => Exercise.canonical(
  id: id,
  updatedAt: _stamp,
  primitive: ExercisePrimitive.select,
  promptElements: [
    PromptElement(type: 'text', role: 'question', text: 'Question $id'),
  ],
  items: [
    ExerciseItem(
      id: '${id}_right',
      content: [PromptElement(type: 'text', text: 'Right $id')],
    ),
    ExerciseItem(
      id: '${id}_wrong',
      content: [PromptElement(type: 'text', text: 'Wrong $id')],
    ),
  ],
  canonicalEvaluation: CanonicalEvaluation(
    mode: EvaluationMode.exactItem,
    correctItemIds: ['${id}_right'],
  ),
);

Course _course(LearningRound round) => Course(
  courseId: 'timed-course',
  title: 'Timed course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  lessons: [
    Lesson(lessonId: 'lesson', title: 'Lesson', rounds: [round]),
  ],
);

LearningRound _round({
  List<int> limits = const [30],
  bool intro = false,
  int questionCount = 2,
  PublicationState state = PublicationState.published,
}) => LearningRound(
  id: 'timed-round',
  title: 'Sprint',
  updatedAt: _stamp,
  publicationState: state,
  roundType: RoundType.timed,
  timedLimitsSeconds: limits,
  exercises: [
    if (intro)
      Exercise.beforeYouStart(
        id: 'intro',
        updatedAt: _stamp,
        text: 'Ready for the sprint?',
      ),
    for (var i = 1; i <= questionCount; i++) _question('q$i'),
  ],
);

Future<void> _waitFor(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 20));
  }
  expect(finder, findsWidgets);
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await ProfileService().addProfile('Timed learner');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => testSupportDirectory.path,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('xyz.luan/audioplayers.global'),
          (_) async => null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('xyz.luan/audioplayers'),
          (_) async => null,
        );
  });

  test('Timed limits, icon, persistence and central XP rules', () async {
    final round = _round(limits: const [60, 30, 90]);
    expect(LearningRound.fromJson(round.toJson()).timedLimitsSeconds, [
      60,
      30,
      90,
    ]);
    expect(RoundTypePresentation.icon(RoundType.timed), Icons.timer_outlined);
    expect(TimedRoundRules.activeLimit(round, {}), 60);
    expect(TimedRoundRules.activeLimit(round, {60}), 30);
    expect(TimedRoundRules.activeLimit(round, {60, 30, 90}), 90);
    expect(TimedRoundRules.validLimits([30, 600]), isTrue);
    expect(TimedRoundRules.validLimits([30, 30]), isFalse);
    expect(TimedRoundRules.validLimits([29]), isFalse);
    expect(TimedRoundRules.validLimits([601]), isFalse);
    final withDefaults = Course.fromJson({
      ..._course(round).toJson(),
      'defaultTimedLimitsSeconds': [90, 60],
    });
    expect(Course.fromJson(withDefaults.toJson()).defaultTimedLimitsSeconds, [
      90,
      60,
    ]);
    final calculator = const XpCalculator();
    final complete = calculator.calculateRoundAward(
      const RoundXpAwardContext(
        completed: true,
        errorsThisAttempt: 0,
        firstPassCorrect: 2,
        wasCompletedAtStart: false,
        newlyEarnedLaurel: false,
        evaluableExerciseCount: 2,
        firstOnTimeCompletion: true,
      ),
    );
    expect(complete.correctAnswerXp, 10);
    expect(complete.onTimeBonusXp, 10);
    expect(complete.totalXp, 25); // Includes the ordinary Perfect bonus.
    final timeout = calculator.calculateTimedTimeoutAward(
      firstPassCorrect: 2,
      wasCompletedAtStart: false,
    );
    expect(timeout.totalXp, 10);
    expect(timeout.onTimeBonusXp, 0);
    final progress = ProgressService();
    expect(
      await progress.claimTimedLimit(round.id, 60, courseId: 'timed-course'),
      isTrue,
    );
    expect(
      await progress.claimTimedLimit(round.id, 60, courseId: 'timed-course'),
      isFalse,
    );
    expect(
      await progress.getCompletedTimedLimits(
        round.id,
        courseId: 'timed-course',
      ),
      {60},
    );
  });

  test('invalid Timed content remains Draft but Audit blocks publication', () {
    final invalid = _round(
      limits: const [0, 0],
      questionCount: 0,
      state: PublicationState.draft,
    );
    final issues = CourseAuditService()
        .auditRound(_course(invalid), invalid.id)
        .issues;
    expect(
      issues.map((issue) => issue.code),
      contains('ROUND_TYPE_TIMED_LIMIT_INVALID'),
    );
    expect(
      issues.map((issue) => issue.code),
      contains('ROUND_TYPE_TIMED_NO_PLAYABLE'),
    );
    expect(invalid.publicationState, PublicationState.draft);
  });

  testWidgets('New Round offers Timed and requires a selected limit', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 1900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final course = _course(_round());
    Course? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: LessonRoundsScreen(
          course: Course.fromJson({
            ...course.toJson(),
            'lessons': [
              {...course.lessons.first.toJson(), 'rounds': <Object>[]},
            ],
          }),
          lesson: Lesson(lessonId: 'lesson', title: 'Lesson', rounds: const []),
          onCourseChanged: (value) => changed = value,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rounds-new-round')));
    await tester.pumpAndSettle();
    final timed = find.byKey(const Key('new-round-type-timed'));
    await tester.ensureVisible(timed);
    expect(
      tester
          .widget<Icon>(find.descendant(of: timed, matching: find.byType(Icon)))
          .icon,
      Icons.timer_outlined,
    );
    await tester.tap(timed);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, 'Sprint');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('timed-limit-picker')), findsOneWidget);
    await tester.tap(find.byKey(const Key('timed-limit-30')));
    await tester.pumpAndSettle();
    expect(changed!.lessons.first.rounds.single.timedLimitsSeconds, [30]);
  });

  testWidgets('Lesson Options authors ordered Course default Timed limits', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 1900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final course = _course(_round());
    await SettingsService().setCourseEditorLocked(course.courseId, false);
    await SettingsService().markAudioOrphanCheckRun(
      CourseService.codeForCourse(course),
    );
    await tester.pumpWidget(
      MaterialApp(home: CourseEditorScreen(course: course, userCourse: true)),
    );
    await tester.pumpAndSettle();
    final options = find.byKey(const Key('course-lesson-options'));
    await tester.ensureVisible(options);
    await tester.tap(options);
    await tester.pumpAndSettle();
    final add = find.byKey(const Key('default-timed-limit-add'));
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('timed-limit-60')));
    await tester.pumpAndSettle();
    expect(find.text('Stage 1 · 1 min'), findsOneWidget);
    await tester.ensureVisible(add);
    await tester.tap(add);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('timed-limit-60')));
    await tester.pumpAndSettle();
    expect(find.text('Each Timed limit must be different.'), findsOneWidget);
    expect(find.byKey(const Key('default-timed-limit-1')), findsNothing);
  });

  testWidgets('New Timed Round copies Course defaults without asking again', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 1900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final source = _course(_round());
    final course = Course.fromJson({
      ...source.toJson(),
      'defaultTimedLimitsSeconds': [90, 60],
      'lessons': [
        {...source.lessons.first.toJson(), 'rounds': <Object>[]},
      ],
    });
    Course? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: LessonRoundsScreen(
          course: course,
          lesson: course.lessons.first,
          onCourseChanged: (value) => changed = value,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rounds-new-round')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('new-round-type-timed')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, 'Sprint');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('timed-limit-picker')), findsNothing);
    expect(changed!.lessons.first.rounds.single.timedLimitsSeconds, [90, 60]);
    expect(course.defaultTimedLimitsSeconds, [90, 60]);
  });

  testWidgets(
    'countdown waits for play; timeout locks input and keeps answer XP',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var now = DateTime.utc(2026, 10, 3, 12);
      final round = _round(intro: true);
      final course = _course(round);
      await tester.pumpWidget(
        MaterialApp(
          home: RoundScreen(
            course: course,
            lesson: course.lessons.first,
            round: round,
            ttsLanguage: 'it-IT',
            roundIndex: 0,
            timedClock: () => now,
          ),
        ),
      );
      await _waitFor(
        tester,
        find.byKey(const Key('before-you-start-continue')),
      );
      now = now.add(const Duration(minutes: 5));
      await tester.pump(const Duration(seconds: 1));
      expect(find.byKey(const Key('timed-timeout')), findsNothing);
      await tester.tap(find.byKey(const Key('before-you-start-continue')));
      await tester.pump();
      expect(find.text('Time left: 0:30'), findsOneWidget);
      await tester.tap(find.textContaining('Right q').first);
      await tester.pump();
      await tester.tap(find.text('Continue'));
      await tester.pump();
      now = now.add(const Duration(seconds: 31));
      await tester.pump(const Duration(milliseconds: 300));
      await _waitFor(tester, find.byKey(const Key('timed-timeout-xp')));
      expect(find.text('Correct-answer XP kept: 5'), findsOneWidget);
      expect(
        await ProgressService().getCompletedRounds(courseId: course.courseId),
        isEmpty,
      );
      await tester.tap(find.byKey(const Key('timed-retry')));
      await _waitFor(
        tester,
        find.byKey(const Key('before-you-start-continue')),
      );
      expect(find.byKey(const Key('timed-timeout')), findsNothing);
    },
  );

  testWidgets(
    'on-time completion adds and displays a persisted once-per-limit bonus',
    (tester) async {
      tester.view.physicalSize = const Size(1000, 1700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var now = DateTime.utc(2026, 10, 3, 12);
      final round = _round(limits: const [30, 60], questionCount: 1);
      final course = _course(round);
      await tester.pumpWidget(
        MaterialApp(
          home: RoundScreen(
            course: course,
            lesson: course.lessons.first,
            round: round,
            ttsLanguage: 'it-IT',
            roundIndex: 0,
            timedClock: () => now,
          ),
        ),
      );
      await _waitFor(tester, find.byKey(const Key('timed-countdown')));
      await tester.tap(find.text('Right q1'));
      await tester.pump();
      now = now.add(const Duration(seconds: 31));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byKey(const Key('timed-timeout')), findsNothing);
      await tester.tap(find.text('Finish round'));
      await _waitFor(
        tester,
        find.byKey(const Key('round-completed-on-time-bonus')),
      );
      expect(find.text('On Time bonus: +10 XP'), findsOneWidget);
      int summaryTotal() {
        final line = tester.widget<Text>(find.textContaining('Total: ')).data!;
        return int.parse(
          RegExp(r'Total: (\d+) XP').firstMatch(line)!.group(1)!,
        );
      }

      final courseCode = CourseService.codeForCourse(course);
      final firstTotal = summaryTotal();
      expect(await ProgressService().getXp(courseCode: courseCode), firstTotal);
      expect(
        await ProgressService().getCompletedRounds(courseId: course.courseId),
        contains(round.id),
      );
      expect(
        await ProgressService().getCompletedTimedLimits(
          round.id,
          courseId: course.courseId,
        ),
        {30},
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          home: RoundScreen(
            course: course,
            lesson: course.lessons.first,
            round: round,
            ttsLanguage: 'it-IT',
            roundIndex: 0,
            timedClock: () => now,
          ),
        ),
      );
      await _waitFor(tester, find.byKey(const Key('timed-countdown')));
      expect(find.text('Time left: 1:00'), findsOneWidget);
      await tester.tap(find.text('Right q1'));
      await tester.pump();
      await tester.tap(find.text('Finish round'));
      await _waitFor(
        tester,
        find.byKey(const Key('round-completed-on-time-bonus')),
      );
      final secondTotal = summaryTotal();
      expect(
        await ProgressService().getXp(courseCode: courseCode),
        firstTotal + secondTotal,
      );
      expect(
        await ProgressService().getCompletedTimedLimits(
          round.id,
          courseId: course.courseId,
        ),
        {30, 60},
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          home: RoundScreen(
            course: course,
            lesson: course.lessons.first,
            round: round,
            ttsLanguage: 'it-IT',
            roundIndex: 0,
            timedClock: () => now,
          ),
        ),
      );
      await _waitFor(tester, find.byKey(const Key('timed-countdown')));
      expect(find.text('Time left: 1:00'), findsOneWidget);
      await tester.tap(find.text('Right q1'));
      await tester.pump();
      await tester.tap(find.text('Finish round'));
      await _waitFor(tester, find.byType(AlertDialog));
      expect(
        find.byKey(const Key('round-completed-on-time-bonus')),
        findsNothing,
      );
      expect(
        await ProgressService().getXp(courseCode: courseCode),
        firstTotal + secondTotal + summaryTotal(),
      );
    },
  );
}
