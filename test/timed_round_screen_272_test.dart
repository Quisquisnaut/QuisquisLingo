import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 272 Revision 7: what a Timed Round's clock does on the Round screen,
/// written before the clock got its owner (`TimedRoundClock`) and unchanged
/// by it.
final _stamp = DateTime.utc(2026, 10, 12);

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

LearningRound _round({List<int> limits = const [30], int questions = 2}) =>
    LearningRound(
      id: 'timed-round',
      title: 'Sprint',
      updatedAt: _stamp,
      roundType: RoundType.timed,
      timedLimitsSeconds: limits,
      exercises: [for (var i = 1; i <= questions; i++) _question('q$i')],
    );

Course _course(LearningRound round) => Course(
  courseId: 'timed-clock-course',
  title: 'Timed clock course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  lessons: [
    Lesson(lessonId: 'lesson', title: 'Lesson', rounds: [round]),
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
  late DateTime now;

  setUp(() async {
    now = DateTime.utc(2026, 10, 12, 12);
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await ProfileService().addProfile('Clock learner');
    // The Round writes debug events to the Crash Log; a real file write
    // left unfinished at the end of one test would hold the next one's.
    keepCrashLogUnavailable();
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (_) async => testSupportDirectory.path,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (_) async => null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (_) async => null,
    );
  });

  Future<Course> open(
    WidgetTester tester,
    LearningRound round, {
    bool preview = false,
  }) async {
    tester.view.physicalSize = const Size(1000, 1700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final course = _course(round);
    await tester.pumpWidget(
      MaterialApp(
        home: RoundScreen(
          course: course,
          lesson: course.lessons.first,
          round: round,
          ttsLanguage: 'it-IT',
          roundIndex: 0,
          previewMode: preview,
          timedClock: () => now,
        ),
      ),
    );
    await _waitFor(tester, find.byKey(const Key('timed-countdown')));
    return course;
  }

  String clock(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('timed-countdown'))).data!;

  testWidgets('the clock shows the whole limit, then every started second '
      'until it ends', (tester) async {
    await open(tester, _round(limits: const [90]));
    expect(clock(tester), 'Time left: 1:30');
    now = now.add(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 250));
    expect(clock(tester), 'Time left: 1:30');
    now = now.add(const Duration(milliseconds: 1000));
    await tester.pump(const Duration(milliseconds: 250));
    expect(clock(tester), 'Time left: 1:29');
    now = now.add(const Duration(seconds: 29));
    await tester.pump(const Duration(milliseconds: 250));
    expect(clock(tester), 'Time left: 1:00');
    now = now.add(const Duration(milliseconds: 800));
    await tester.pump(const Duration(milliseconds: 250));
    expect(clock(tester), 'Time left: 0:59');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the time is up when the device clock passes the deadline, at '
      'the next refresh', (tester) async {
    await open(tester, _round());
    now = now.add(const Duration(seconds: 30));
    expect(find.byKey(const Key('timed-timeout')), findsNothing);
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byKey(const Key('timed-timeout')), findsOneWidget);
    await _waitFor(tester, find.byKey(const Key('timed-timeout-xp')));
    expect(find.text('Correct-answer XP kept: 0'), findsOneWidget);
  });

  testWidgets('the time is also up after the limit of waiting, whatever the '
      'device clock says', (tester) async {
    await open(tester, _round());
    await tester.pump(const Duration(seconds: 29));
    expect(find.byKey(const Key('timed-timeout')), findsNothing);
    // The device clock did not move: the seconds shown did not either.
    expect(clock(tester), 'Time left: 0:30');
    await tester.pump(const Duration(seconds: 1));
    expect(find.byKey(const Key('timed-timeout')), findsOneWidget);
    await _waitFor(tester, find.byKey(const Key('timed-timeout-xp')));
  });

  testWidgets('an answer given after the deadline is not taken: the time is '
      'up', (tester) async {
    final course = await open(tester, _round());
    now = now.add(const Duration(seconds: 31));
    // A Round shows its exercises in a new order each time: either question.
    await tester.tap(find.textContaining('Right q').first);
    await tester.pump();
    expect(find.byKey(const Key('timed-timeout')), findsOneWidget);
    await _waitFor(tester, find.byKey(const Key('timed-timeout-xp')));
    expect(find.text('Correct-answer XP kept: 0'), findsOneWidget);
    expect(
      await ProgressService().getXp(
        courseCode: CourseService.codeForCourse(course),
      ),
      0,
    );
  });

  testWidgets('the last answer in time stops the clock where it is', (
    tester,
  ) async {
    await open(tester, _round(questions: 1));
    now = now.add(const Duration(milliseconds: 4200));
    await tester.pump(const Duration(milliseconds: 250));
    expect(clock(tester), 'Time left: 0:26');
    await tester.tap(find.text('Right q1'));
    await tester.pump();
    now = now.add(const Duration(minutes: 2));
    await tester.pump(const Duration(seconds: 40));
    expect(find.byKey(const Key('timed-timeout')), findsNothing);
    expect(clock(tester), 'Time left: 0:26');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a last answer that leaves mistakes to repeat does not stop the '
      'clock; the time running out closes the mistakes notice', (tester) async {
    await open(tester, _round());
    final first = find.textContaining('Wrong q').first;
    await tester.tap(first);
    await tester.pump();
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.tap(find.textContaining('Right q').first);
    await tester.pump();
    now = now.add(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 250));
    expect(clock(tester), 'Time left: 0:28');
    await tester.tap(find.text('Review mistakes'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byType(AlertDialog), findsOneWidget);
    now = now.add(const Duration(seconds: 30));
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byKey(const Key('timed-timeout')), findsOneWidget);
    await _waitFor(tester, find.byKey(const Key('timed-timeout-xp')));
    expect(find.text('Correct-answer XP kept: 5'), findsOneWidget);
  });

  testWidgets('in the Preview the time runs out the same way and nothing is '
      'kept', (tester) async {
    final course = await open(tester, _round(), preview: true);
    await tester.tap(find.textContaining('Right q').first);
    await tester.pump();
    now = now.add(const Duration(seconds: 31));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.byKey(const Key('timed-timeout')), findsOneWidget);
    await _waitFor(tester, find.byKey(const Key('timed-timeout-xp')));
    expect(find.text('Correct-answer XP kept: 0'), findsOneWidget);
    expect(
      await ProgressService().getXp(
        courseCode: CourseService.codeForCourse(course),
      ),
      0,
    );
  });
}
