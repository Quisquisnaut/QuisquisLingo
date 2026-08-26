import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/review_screen.dart';
import 'package:quisquislingo_app/screens/topic_screen.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const learner = 'Topic Characterization Learner';
  const courseId = 'topic_characterization_course';
  const courseCode = 'IT';

  setUp(() async {
    _installDesktopPluginMocks();
    SharedPreferences.setMockInitialValues({
      'sound_effects_enabled': false,
      'weekly_xp_target': 1000,
    });
    await ProfileService().addProfile(learner);
  });

  testWidgets('completing a non-final round does not complete its topic', (
    tester,
  ) async {
    final fixture = _topicFixture();
    await _openTopic(tester, fixture, expectedCompleted: 0);

    await _completeRoundFromTopic(tester, fixture.firstRound);
    await _pumpUntilText(tester, '1/2 rounds completed');

    final progress = ProgressService();
    expect(await progress.getCompletedTopics(courseId: courseId), isEmpty);
    expect(await progress.getXp(courseCode: courseCode), 5);
    expect(await progress.getWeeklyXp(), 5);
    expect(find.text('Topic completed. +25 XP'), findsNothing);
  });

  testWidgets('completing the final round awards topic XP and shows notice', (
    tester,
  ) async {
    final fixture = _topicFixture();
    final progress = ProgressService();
    await _completeForSetup(progress, fixture.firstRound);
    await _openTopic(tester, fixture, expectedCompleted: 1);

    await _completeRoundFromTopic(tester, fixture.finalRound);
    await _pumpUntilText(tester, 'Topic completed. +25 XP');

    expect(await progress.getCompletedTopics(courseId: courseId), {
      fixture.topic.id,
    });
    expect(await progress.getXp(courseCode: courseCode), 30);
    expect(await progress.getWeeklyXp(), 30);
    expect(find.text('2/2 rounds completed'), findsOneWidget);
    expect(find.text('Topic completed. +25 XP'), findsOneWidget);
  });

  testWidgets('unrelated completed rounds do not count toward this topic', (
    tester,
  ) async {
    final fixture = _topicFixture();
    final progress = ProgressService();
    await _completeForSetup(progress, fixture.unrelatedRound);
    await _openTopic(tester, fixture, expectedCompleted: 0);

    await _completeRoundFromTopic(tester, fixture.firstRound);
    await _pumpUntilText(tester, '1/2 rounds completed');

    expect(await progress.getCompletedRounds(courseId: courseId), {
      fixture.unrelatedRound.id,
      fixture.firstRound.id,
    });
    expect(await progress.getCompletedTopics(courseId: courseId), isEmpty);
    expect(await progress.getXp(courseCode: courseCode), 5);
    expect(find.text('Topic completed. +25 XP'), findsNothing);
  });

  testWidgets(
    'topic-only weekly threshold crossing does not mark or show celebration',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('weekly_xp_target', 20);
      final fixture = _topicFixture();
      final progress = ProgressService();
      await _completeForSetup(progress, fixture.firstRound);
      await _openTopic(tester, fixture, expectedCompleted: 1);

      await _completeRoundFromTopic(tester, fixture.finalRound);
      await _pumpUntilText(tester, 'Topic completed. +25 XP');

      expect(await progress.getWeeklyXp(), 30);
      expect(await progress.isWeeklyGoalCelebrated(), isFalse);
      expect(find.text('Weekly goal reached!'), findsNothing);
      expect(find.text('Topic completed. +25 XP'), findsOneWidget);
    },
  );

  testWidgets('replaying a round in a completed topic awards topic XP again', (
    tester,
  ) async {
    final fixture = _topicFixture();
    final progress = ProgressService();
    await _completeForSetup(progress, fixture.firstRound);
    await _completeForSetup(progress, fixture.finalRound);
    await progress.completeTopic(
      fixture.topic.id,
      courseId: courseId,
      courseCode: courseCode,
    );
    await _openTopic(tester, fixture, expectedCompleted: 2);

    await _completeRoundFromTopic(tester, fixture.firstRound);
    await _pumpUntilText(tester, 'Topic completed. +25 XP');

    expect(await progress.getCompletedTopics(courseId: courseId), {
      fixture.topic.id,
    });
    expect(await progress.getXp(courseCode: courseCode), 52);
    expect(await progress.getWeeklyXp(), 52);
    expect(find.text('Topic completed. +25 XP'), findsOneWidget);
  });

  testWidgets('backing out of a round can award completed topic XP again', (
    tester,
  ) async {
    final fixture = _topicFixture();
    final progress = ProgressService();
    await _completeForSetup(progress, fixture.firstRound);
    await _completeForSetup(progress, fixture.finalRound);
    await progress.completeTopic(
      fixture.topic.id,
      courseId: courseId,
      courseCode: courseCode,
    );
    await _openTopic(tester, fixture, expectedCompleted: 2);

    await tester.tap(find.text(fixture.firstRound.title));
    await tester.pump();
    await _pumpUntilText(tester, 'Correct ${fixture.firstRound.id}');
    await tester.pageBack();
    await _pumpUntilText(tester, 'Topic completed. +25 XP');

    expect(await progress.getCompletedTopics(courseId: courseId), {
      fixture.topic.id,
    });
    expect(await progress.getXp(courseCode: courseCode), 50);
    expect(await progress.getWeeklyXp(), 50);
    expect(await progress.getRecentRounds(courseId: courseId), isEmpty);
  });

  testWidgets(
    'Review perfect replay updates round state without topic completion XP',
    (tester) async {
      final fixture = _topicFixture();
      final progress = ProgressService();
      await _completeForSetup(progress, fixture.firstRound);
      await progress.recordRecentRound(
        courseId,
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
        'Chapter 1: Characterization Chapter · Characterization Topic · '
        '0 errors in latest attempt',
      );

      expect(await progress.getPerfectRounds(courseId: courseId), {
        fixture.firstRound.id,
      });
      final recent = await progress.getRecentRounds(courseId: courseId);
      expect(recent, hasLength(1));
      expect(recent.single.roundId, fixture.firstRound.id);
      expect(recent.single.errors, 0);
      expect(await progress.getCompletedTopics(courseId: courseId), isEmpty);
      expect(await progress.getXp(courseCode: courseCode), 2);
      expect(await progress.getWeeklyXp(), 2);
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

class _TopicFixture {
  final Course course;
  final Chapter chapter;
  final Topic topic;
  final LearningRound firstRound;
  final LearningRound finalRound;
  final LearningRound unrelatedRound;

  const _TopicFixture({
    required this.course,
    required this.chapter,
    required this.topic,
    required this.firstRound,
    required this.finalRound,
    required this.unrelatedRound,
  });
}

_TopicFixture _topicFixture() {
  final firstRound = _round('topic_round_1', 'First Topic Round');
  final finalRound = _round('topic_round_2', 'Final Topic Round');
  final unrelatedRound = _round('unrelated_round', 'Unrelated Round');
  final topic = Topic(
    id: 'topic_characterization',
    title: 'Characterization Topic',
    rounds: [firstRound, finalRound],
  );
  final unrelatedTopic = Topic(
    id: 'unrelated_topic',
    title: 'Unrelated Topic',
    rounds: [unrelatedRound],
  );
  final chapter = Chapter(
    id: 'chapter_characterization',
    title: 'Characterization Chapter',
    requiredTopics: 2,
    topics: [topic, unrelatedTopic],
  );
  final course = Course(
    courseId: 'topic_characterization_course',
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Topic Characterization Course',
    ttsLanguage: 'it-IT',
    version: '1.0.0',
    chapters: [chapter],
  );
  return _TopicFixture(
    course: course,
    chapter: chapter,
    topic: topic,
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

Future<void> _completeForSetup(ProgressService progress, LearningRound round) =>
    progress.completeRound(
      round.id,
      courseId: 'topic_characterization_course',
      courseCode: 'IT',
    );

Future<void> _openTopic(
  WidgetTester tester,
  _TopicFixture fixture, {
  required int expectedCompleted,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: TopicScreen(
        course: fixture.course,
        chapter: fixture.chapter,
        topic: fixture.topic,
        ttsLanguage: fixture.course.ttsLanguage,
      ),
    ),
  );
  await _pumpUntilText(tester, '$expectedCompleted/2 rounds completed');
}

Future<void> _completeRoundFromTopic(
  WidgetTester tester,
  LearningRound round,
) async {
  await tester.tap(find.text(round.title));
  await tester.pump();
  await _pumpUntilText(tester, 'Correct ${round.id}');
  await _answerPerfectChoice(tester, round);
  await _tapAndPump(tester, 'Finish round');
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
