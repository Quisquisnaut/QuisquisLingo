import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/review_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const learner = 'Lesson Characterization Learner';
  const courseId = 'lesson_characterization_course';
  const courseCode = 'IT';

  setUp(() async {
    _installDesktopPluginMocks();
    SharedPreferences.setMockInitialValues({
      'sound_effects_enabled': false,
      'weekly_xp_target': 1000,
    });
    await ProfileService().addProfile(learner);
  });

  testWidgets('completing a non-final round does not complete its lesson', (
    tester,
  ) async {
    final fixture = _lessonFixture();
    await _openLesson(tester, fixture, expectedCompleted: 0);

    await _completeRoundFromLesson(tester, fixture.firstRound);
    await _pumpUntilText(tester, '1/2 rounds completed');

    final progress = ProgressService();
    expect(await progress.getCompletedLessons(courseId: courseId), isEmpty);
    expect(await progress.getXp(courseCode: courseCode), 35);
    expect(await progress.getWeeklyXp(), 35);
    expect(find.text('Lesson completed: +25 XP'), findsNothing);
  });

  testWidgets(
    'final Round popup includes Lesson XP and returning shows no notice',
    (tester) async {
      final fixture = _lessonFixture();
      final progress = ProgressService();
      await _completeForSetup(progress, fixture.firstRound);
      await _openLesson(tester, fixture, expectedCompleted: 1);

      await _completeRoundFromLesson(
        tester,
        fixture.finalRound,
        closeCompletionDialog: false,
      );

      expect(find.text('Correct answers: 1/1 — 5 XP'), findsOneWidget);
      expect(find.text('Perfect bonus: +5 XP'), findsOneWidget);
      expect(find.text('First Laurel: +25 XP'), findsOneWidget);
      expect(find.text('Lesson completed: +25 XP'), findsOneWidget);
      expect(find.text('Total: 60 XP'), findsOneWidget);

      expect(await progress.getCompletedLessons(courseId: courseId), {
        fixture.lesson.lessonId,
      });
      expect(await progress.getXp(courseCode: courseCode), 60);
      expect(await progress.getWeeklyXp(), 60);
      await _tapAndPump(tester, 'Continue');
      await _pumpUntilText(tester, '2/2 rounds completed');
      expect(find.text('Lesson completed: +25 XP'), findsNothing);
    },
  );

  testWidgets('unrelated completed rounds do not count toward this lesson', (
    tester,
  ) async {
    final fixture = _lessonFixture();
    final progress = ProgressService();
    await _completeForSetup(progress, fixture.unrelatedRound);
    await _openLesson(tester, fixture, expectedCompleted: 0);

    await _completeRoundFromLesson(tester, fixture.firstRound);
    await _pumpUntilText(tester, '1/2 rounds completed');

    expect(await progress.getCompletedRounds(courseId: courseId), {
      fixture.unrelatedRound.id,
      fixture.firstRound.id,
    });
    expect(await progress.getCompletedLessons(courseId: courseId), isEmpty);
    expect(await progress.getXp(courseCode: courseCode), 35);
    expect(find.text('Lesson completed: +25 XP'), findsNothing);
  });

  testWidgets(
    'combined Round and Lesson XP crosses the weekly threshold once',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('weekly_xp_target', 50);
      final fixture = _lessonFixture();
      final progress = ProgressService();
      await _completeForSetup(progress, fixture.firstRound);
      await _openLesson(tester, fixture, expectedCompleted: 1);

      await _completeRoundFromLesson(
        tester,
        fixture.finalRound,
        closeCompletionDialog: false,
      );
      expect(find.text('Total: 60 XP'), findsOneWidget);
      await _tapAndPump(tester, 'Continue');
      await _pumpUntilText(tester, 'Weekly goal reached!');

      expect(await progress.getWeeklyXp(), 60);
      expect(await progress.isWeeklyGoalCelebrated(), isTrue);
      await _tapAndPump(tester, 'Continue');
      await _pumpUntilText(tester, '2/2 rounds completed');
      expect(find.text('Lesson completed: +25 XP'), findsNothing);
    },
  );

  testWidgets('replaying a round cannot award completed Lesson XP again', (
    tester,
  ) async {
    final fixture = _lessonFixture();
    final progress = ProgressService();
    await _completeForSetup(progress, fixture.firstRound);
    await _completeForSetup(progress, fixture.finalRound);
    await progress.completeLesson(
      fixture.lesson.lessonId,
      courseId: courseId,
      courseCode: courseCode,
    );
    await _openLesson(tester, fixture, expectedCompleted: 2);

    await _completeRoundFromLesson(tester, fixture.firstRound);
    await _pumpUntilText(tester, '2/2 rounds completed');

    expect(await progress.getCompletedLessons(courseId: courseId), {
      fixture.lesson.lessonId,
    });
    expect(await progress.getXp(courseCode: courseCode), 57);
    expect(await progress.getWeeklyXp(), 57);
    expect(find.text('Lesson completed: +25 XP'), findsNothing);
  });

  testWidgets('backing out of a round cannot award completed Lesson XP again', (
    tester,
  ) async {
    final fixture = _lessonFixture();
    final progress = ProgressService();
    await _completeForSetup(progress, fixture.firstRound);
    await _completeForSetup(progress, fixture.finalRound);
    await progress.completeLesson(
      fixture.lesson.lessonId,
      courseId: courseId,
      courseCode: courseCode,
    );
    await _openLesson(tester, fixture, expectedCompleted: 2);

    await tester.tap(find.text(fixture.firstRound.title));
    await tester.pump();
    await _pumpUntilText(tester, 'Correct ${fixture.firstRound.id}');
    await tester.pageBack();
    await _pumpUntilText(tester, '2/2 rounds completed');

    expect(await progress.getCompletedLessons(courseId: courseId), {
      fixture.lesson.lessonId,
    });
    expect(await progress.getXp(courseCode: courseCode), 25);
    expect(await progress.getWeeklyXp(), 25);
    expect(find.text('Lesson completed: +25 XP'), findsNothing);
    expect(await progress.getRecentRounds(courseId: courseId), isEmpty);
  });

  testWidgets(
    'Review perfect replay updates round state without lesson completion XP',
    (tester) async {
      final fixture = _lessonFixture();
      final progress = ProgressService();
      await _completeForSetup(progress, fixture.firstRound);
      await progress.recordRecentRound(
        courseId,
        fixture.lesson.lessonId,
        fixture.firstRound.id,
        errors: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ReviewScreen(course: fixture.course, courseCode: courseCode),
        ),
      );
      await _pumpUntilText(tester, fixture.firstRound.title);
      expect(find.textContaining('1 error in latest attempt'), findsOneWidget);

      await tester.tap(find.text(fixture.firstRound.title));
      await tester.pump();
      await _pumpUntilText(tester, 'Correct ${fixture.firstRound.id}');
      await _answerPerfectChoice(tester, fixture.firstRound);
      await _tapAndPump(tester, 'Finish round');
      await _pumpUntilText(
        tester,
        'Lesson 1: Characterization Lesson · '
        '0 errors in latest attempt',
      );

      expect(await progress.getPerfectRounds(courseId: courseId), {
        fixture.firstRound.id,
      });
      final recent = await progress.getRecentRounds(courseId: courseId);
      expect(recent, hasLength(1));
      expect(recent.single.roundId, fixture.firstRound.id);
      expect(recent.single.errors, 0);
      expect(await progress.getCompletedLessons(courseId: courseId), isEmpty);
      expect(await progress.getXp(courseCode: courseCode), 32);
      expect(await progress.getWeeklyXp(), 32);
    },
  );
}

void _installDesktopPluginMocks() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (_) async => throw PlatformException(
      code: 'test_storage_unavailable',
      message: 'Persistent crash logging is unavailable in widget tests.',
    ),
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers.global'),
    (_) async => null,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers'),
    (call) async {
      if (call.method == 'create') {
        final arguments = call.arguments as Map<Object?, Object?>;
        final playerId = arguments['playerId'] as String;
        _installEventChannelMock(
          messenger,
          'xyz.luan/audioplayers/events/$playerId',
        );
      }
      return null;
    },
  );
  _installEventChannelMock(messenger, 'xyz.luan/audioplayers.global/events');
}

void _installEventChannelMock(
  TestDefaultBinaryMessenger messenger,
  String channel,
) {
  messenger.setMockMessageHandler(channel, (message) async {
    return const StandardMethodCodec().encodeSuccessEnvelope(null);
  });
}

class _LessonFixture {
  final Course course;
  final Lesson lesson;
  final LearningRound firstRound;
  final LearningRound finalRound;
  final LearningRound unrelatedRound;

  const _LessonFixture({
    required this.course,
    required this.lesson,
    required this.firstRound,
    required this.finalRound,
    required this.unrelatedRound,
  });
}

_LessonFixture _lessonFixture() {
  final firstRound = _round('lesson_round_1', 'First Lesson Round');
  final finalRound = _round('lesson_round_2', 'Final Lesson Round');
  final unrelatedRound = _round('unrelated_round', 'Unrelated Round');
  final lesson = Lesson(
    lessonId: 'lesson_characterization',
    title: 'Characterization Lesson',
    rounds: [firstRound, finalRound],
  );
  final unrelatedLesson = Lesson(
    lessonId: 'unrelated_lesson',
    title: 'Unrelated Lesson',
    rounds: [unrelatedRound],
  );
  final course = Course(
    courseId: 'lesson_characterization_course',
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Lesson Characterization Course',
    ttsLanguage: 'it-IT',
    version: '1.0.0',
    lessons: [lesson, unrelatedLesson],
  );
  return _LessonFixture(
    course: course,
    lesson: lesson,
    firstRound: firstRound,
    finalRound: finalRound,
    unrelatedRound: unrelatedRound,
  );
}

LearningRound _round(String id, String title) => LearningRound(
  id: id,
  title: title,
  exercises: [
    Exercise(
      id: '${id}_choice',
      type: 'choice',
      prompt: 'Choose the characterized answer.',
      question: '',
      answers: ['Correct $id', 'Wrong $id'],
      correct: 0,
      tts: null,
      accepted: const [],
      tokens: const [],
      orderAnswer: const [],
      pairs: const [],
      hint: '',
      icons: const [],
    ),
  ],
);

class _LessonRoundLauncher extends StatefulWidget {
  final _LessonFixture fixture;

  const _LessonRoundLauncher({required this.fixture});

  @override
  State<_LessonRoundLauncher> createState() => _LessonRoundLauncherState();
}

class _LessonRoundLauncherState extends State<_LessonRoundLauncher> {
  final _progress = ProgressService();
  int _completed = 0;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final completed = await _progress.getCompletedRounds(
      courseId: widget.fixture.course.courseId,
    );
    if (!mounted) return;
    setState(() {
      _completed = widget.fixture.lesson.rounds
          .where((round) => completed.contains(round.id))
          .length;
    });
  }

  Future<void> _open(LearningRound round) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RoundScreen(
          course: widget.fixture.course,
          lesson: widget.fixture.lesson,
          round: round,
          ttsLanguage: widget.fixture.course.ttsLanguage,
          roundIndex: widget.fixture.lesson.rounds.indexOf(round),
          completeLessonOnFinish: true,
        ),
      ),
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.fixture.lesson.title)),
    body: Column(
      children: [
        Text(
          '$_completed/${widget.fixture.lesson.rounds.length} rounds completed',
        ),
        for (final round in widget.fixture.lesson.rounds)
          FilledButton(onPressed: () => _open(round), child: Text(round.title)),
      ],
    ),
  );
}

Future<void> _completeForSetup(ProgressService progress, LearningRound round) =>
    progress.completeRound(
      round.id,
      courseId: 'lesson_characterization_course',
      courseCode: 'IT',
    );

Future<void> _openLesson(
  WidgetTester tester,
  _LessonFixture fixture, {
  required int expectedCompleted,
}) async {
  await tester.pumpWidget(
    MaterialApp(home: _LessonRoundLauncher(fixture: fixture)),
  );
  await _pumpUntilText(tester, '$expectedCompleted/2 rounds completed');
}

Future<void> _completeRoundFromLesson(
  WidgetTester tester,
  LearningRound round, {
  bool closeCompletionDialog = true,
}) async {
  await tester.tap(find.text(round.title));
  await tester.pump();
  await _pumpUntilText(tester, 'Correct ${round.id}');
  await _answerPerfectChoice(tester, round);
  if (closeCompletionDialog) {
    await _tapAndPump(tester, 'Finish round');
  } else {
    final finish = find.text('Finish round');
    await tester.ensureVisible(finish);
    await tester.tap(finish);
    await _pumpUntilText(tester, 'Round completed');
  }
}

Future<void> _answerPerfectChoice(
  WidgetTester tester,
  LearningRound round,
) async {
  final finder = find.text('Correct ${round.id}');
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await _pumpFrames(tester, count: 3);
}

Future<void> _tapAndPump(WidgetTester tester, String label) async {
  final finder = find.text(label);
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await _pumpFrames(tester);
  if (label == 'Finish round' &&
      find.text('Round completed').evaluate().isNotEmpty) {
    await tester.tap(find.text('Continue'));
    await _pumpFrames(tester);
  }
}

Future<void> _pumpFrames(WidgetTester tester, {int count = 12}) async {
  for (var frame = 0; frame < count; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> _pumpUntilText(
  WidgetTester tester,
  String text, {
  int maxFrames = 100,
}) async {
  final finder = find.text(text);
  for (var frame = 0; frame < maxFrames; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  final visibleText = tester
      .widgetList<Text>(find.byType(Text))
      .map((widget) => widget.data)
      .whereType<String>()
      .join(' | ');
  fail('Timed out waiting for "$text". Visible text: $visibleText');
}
