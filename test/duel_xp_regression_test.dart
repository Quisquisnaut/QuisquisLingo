import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/duel_screen.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await ProfileService().addProfile('Duel XP Learner');
  });

  testWidgets('Duel UI and persistence use 50 XP first then 10 XP', (
    tester,
  ) async {
    final fixture = _duelFixture();
    await _pumpLauncher(tester, fixture);

    await _openAndWinDuel(tester);
    expect(find.textContaining('Duel won: +50 XP'), findsOneWidget);

    final progress = ProgressService();
    expect(await progress.getXp(courseCode: 'IT'), 50);
    expect(await progress.getWeeklyXp(), 50);
    expect(await progress.getWonDuels(courseId: fixture.course.courseId), {
      fixture.topic.duel.id,
    });
    expect(
      await progress.getCompletedTopics(courseId: fixture.course.courseId),
      isEmpty,
    );
    await _closeDuelResult(tester);

    await _openAndWinDuel(tester);
    expect(find.textContaining('Duel won: +10 XP'), findsOneWidget);
    expect(await progress.getXp(courseCode: 'IT'), 60);
    expect(await progress.getWeeklyXp(), 60);
    await _closeDuelResult(tester);
  });

  testWidgets('final Lesson Duel win uses final-only wording', (tester) async {
    final fixture = _duelFixture(topicIsFinal: true);
    await _pumpLauncher(tester, fixture);

    await _openAndWinDuel(tester);

    expect(find.text('Duel Won!'), findsOneWidget);
    expect(find.text('Duel won: +50 XP'), findsOneWidget);
    expect(find.textContaining('next Lesson'), findsNothing);
    final progress = ProgressService();
    expect(await progress.getXp(courseCode: 'IT'), 50);
    expect(await progress.getWonDuels(courseId: fixture.course.courseId), {
      fixture.topic.duel.id,
    });
  });

  testWidgets('Duel keeps four lives and loses after four wrong answers', (
    tester,
  ) async {
    final fixture = _duelFixture();
    await _pumpLauncher(tester, fixture);
    await tester.tap(find.text('Open Duel'));
    await tester.pump();
    await _pumpFrames(tester);

    for (var wrongAnswer = 0; wrongAnswer < 4; wrongAnswer++) {
      final wrong = find.byWidgetPredicate(
        (widget) => widget is Text && (widget.data ?? '').startsWith('Wrong '),
      );
      expect(wrong, findsOneWidget);
      await tester.tap(wrong);
      await _pumpFrames(tester, count: 2);
      expect(find.byIcon(Icons.person), findsNWidgets(3 - wrongAnswer));
      await tester.tap(find.text(wrongAnswer == 3 ? 'Finish duel' : 'Next'));
      await _pumpFrames(tester, count: 2);
    }

    expect(find.text('Duel lost'), findsOneWidget);
    expect(find.textContaining('lost all four lives'), findsOneWidget);
    final progress = ProgressService();
    expect(await progress.getXp(courseCode: 'IT'), 0);
    expect(
      await progress.getWonDuels(courseId: fixture.course.courseId),
      isEmpty,
    );
  });
}

class _DuelFixture {
  final Course course;
  final Topic topic;

  const _DuelFixture({required this.course, required this.topic});
}

_DuelFixture _duelFixture({bool topicIsFinal = false}) {
  final round = LearningRound(
    id: 'duel_source_round',
    title: 'Duel Source Round',
    exercises: [
      for (var index = 0; index < 25; index++)
        Exercise(
          id: 'duel_exercise_$index',
          type: 'choice',
          prompt: 'Duel prompt $index',
          question: 'Duel question $index',
          answers: ['Correct $index', 'Wrong $index'],
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
  final topic = Topic(
    id: 'duel_source_topic',
    title: 'Duel Source Topic',
    rounds: [round],
  );
  final followingTopic = Topic(
    id: 'following_topic',
    title: 'Following Topic',
    rounds: const [],
  );
  final course = Course(
    courseId: 'duel_xp_course',
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Duel XP Course',
    ttsLanguage: 'it-IT',
    version: '1.0.0',
    topics: topicIsFinal ? [topic] : [topic, followingTopic],
  );
  return _DuelFixture(course: course, topic: topic);
}

Future<void> _pumpLauncher(WidgetTester tester, _DuelFixture fixture) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: FilledButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => DuelScreen(
                  course: fixture.course,
                  topic: fixture.topic,
                  ttsLanguage: fixture.course.ttsLanguage,
                ),
              ),
            ),
            child: const Text('Open Duel'),
          ),
        ),
      ),
    ),
  );
}

Future<void> _openAndWinDuel(WidgetTester tester) async {
  await tester.tap(find.text('Open Duel'));
  await tester.pump();
  await _pumpFrames(tester);

  for (var index = 0; index < 25; index++) {
    final correct = find.byWidgetPredicate(
      (widget) => widget is Text && (widget.data ?? '').startsWith('Correct '),
    );
    expect(correct, findsOneWidget);
    await tester.tap(correct);
    await _pumpFrames(tester, count: 2);
    await tester.tap(find.text(index == 24 ? 'Finish duel' : 'Next'));
    await _pumpFrames(tester, count: 2);
  }
  await _pumpFrames(tester);
}

Future<void> _closeDuelResult(WidgetTester tester) async {
  await tester.tap(find.text('Back to course'));
  await _pumpFrames(tester);
}

Future<void> _pumpFrames(WidgetTester tester, {int count = 10}) async {
  for (var frame = 0; frame < count; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}
