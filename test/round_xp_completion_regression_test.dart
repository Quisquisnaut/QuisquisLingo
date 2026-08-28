import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const learner = 'Round Characterization Learner';
  const courseId = 'characterization_course';
  const courseCode = 'IT';

  setUp(() async {
    _installDesktopPluginMocks();
    SharedPreferences.setMockInitialValues({
      'sound_effects_enabled': false,
      'weekly_xp_target': 1000,
    });
    await ProfileService().addProfile(learner);
  });

  testWidgets(
    'imperfect first completion records progress and awards only first-pass-correct XP',
    (tester) async {
      final fixture = _roundFixture(exerciseCount: 2);
      final routeResults = <bool?>[];
      await _openRound(tester, fixture, routeResults: routeResults);

      await _answerChoice(tester, correctly: false);
      await _tapAndPump(tester, 'Next');
      await _answerChoice(tester, correctly: true);
      await _tapAndPump(tester, 'Review mistakes');
      await _tapAndPump(tester, 'Continue');
      await _answerChoice(tester, correctly: true);
      await _tapAndPump(tester, 'Finish round');

      final progress = ProgressService();
      expect(routeResults, [true]);
      expect(await progress.getCompletedRounds(courseId: courseId), {
        fixture.round.id,
      });
      expect(await progress.getPerfectRounds(courseId: courseId), isEmpty);
      expect(
        await progress.getTtsSkippedPerfectRounds(courseId: courseId),
        isEmpty,
      );
      expect(await progress.getXp(courseCode: courseCode), 5);
      expect(await progress.getWeeklyXp(), 5);
      final recent = await progress.getRecentRounds(courseId: courseId);
      expect(recent, hasLength(1));
      expect(recent.single.roundId, fixture.round.id);
      expect(recent.single.errors, 1);
    },
  );

  testWidgets(
    'perfect first completion records a laurel and all three XP components',
    (tester) async {
      final fixture = _roundFixture(exerciseCount: 2);
      final routeResults = <bool?>[];
      await _openRound(tester, fixture, routeResults: routeResults);

      final progress = ProgressService();
      await _answerChoice(tester, correctly: true);
      await _tapAndPump(tester, 'Next');
      await _answerChoice(tester, correctly: true);
      final finish = find.text('Finish round');
      await tester.ensureVisible(finish);
      await tester.tap(finish);
      await _pumpFrames(tester);

      expect(find.text('Correct answers: 10 XP'), findsOneWidget);
      expect(find.text('Perfect bonus: +5 XP'), findsOneWidget);
      expect(find.text('First Laurel: +25 XP'), findsOneWidget);
      expect(find.text('Total: 40 XP'), findsOneWidget);
      expect(await progress.getXp(courseCode: courseCode), 40);
      expect(await progress.getWeeklyXp(), 40);

      await _tapAndPump(tester, 'Continue');
      expect(routeResults, [true]);
      expect(await progress.getCompletedRounds(courseId: courseId), {
        fixture.round.id,
      });
      expect(await progress.getPerfectRounds(courseId: courseId), {
        fixture.round.id,
      });
      expect(await progress.getStreak(courseCode: courseCode), 1);
      expect(await progress.getDaysStudied(courseCode: courseCode), 1);
      final recent = await progress.getRecentRounds(courseId: courseId);
      expect(recent.single.errors, 0);
    },
  );

  testWidgets('perfect repeat awards repeat XP and a first Laurel', (
    tester,
  ) async {
    final fixture = _roundFixture(exerciseCount: 2);
    final progress = ProgressService();
    await progress.completeRound(
      fixture.round.id,
      courseId: courseId,
      courseCode: courseCode,
    );
    final routeResults = <bool?>[];
    await _openRound(tester, fixture, routeResults: routeResults);

    await _completePerfectRound(tester, exerciseCount: 2);

    expect(routeResults, [true]);
    expect(await progress.getPerfectRounds(courseId: courseId), {
      fixture.round.id,
    });
    expect(await progress.getXp(courseCode: courseCode), 34);
    expect(await progress.getWeeklyXp(), 34);
    final recent = await progress.getRecentRounds(courseId: courseId);
    expect(recent.single.errors, 0);
  });

  testWidgets(
    'a perfect presented subset records the TTS-skipped mark without a laurel',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('skip_tts_exercises', true);
      final fixture = _roundFixture(exerciseCount: 1, includeTtsExercise: true);
      final routeResults = <bool?>[];
      await _openRound(tester, fixture, routeResults: routeResults);

      await _completePerfectRound(tester, exerciseCount: 1);

      final progress = ProgressService();
      expect(routeResults, [true]);
      expect(await progress.getPerfectRounds(courseId: courseId), isEmpty);
      expect(await progress.getTtsSkippedPerfectRounds(courseId: courseId), {
        fixture.round.id,
      });
      expect(await progress.getXp(courseCode: courseCode), 10);
      expect(await progress.getWeeklyXp(), 10);
    },
  );

  testWidgets('preview completion writes no learner progress or XP', (
    tester,
  ) async {
    final fixture = _roundFixture(exerciseCount: 1);
    final routeResults = <bool?>[];
    await _openRound(
      tester,
      fixture,
      routeResults: routeResults,
      previewMode: true,
    );

    await _answerChoice(tester, correctly: true);
    await _tapAndPump(tester, 'Finish round');
    expect(find.text('Preview complete'), findsOneWidget);
    await _tapAndPump(tester, 'Close');

    final progress = ProgressService();
    expect(routeResults, [null]);
    expect(await progress.getCompletedRounds(courseId: courseId), isEmpty);
    expect(await progress.getPerfectRounds(courseId: courseId), isEmpty);
    expect(await progress.getRecentRounds(courseId: courseId), isEmpty);
    expect(await progress.getXp(courseCode: courseCode), 0);
    expect(await progress.getWeeklyXp(), 0);
    expect(await progress.getStreak(courseCode: courseCode), 0);
    expect(await progress.getDaysStudied(courseCode: courseCode), 0);
  });

  testWidgets('abandoning a Round before completion awards no XP', (
    tester,
  ) async {
    final fixture = _roundFixture(exerciseCount: 2);
    final routeResults = <bool?>[];
    await _openRound(tester, fixture, routeResults: routeResults);

    await _answerChoice(tester, correctly: true);
    await tester.pageBack();
    await _pumpFrames(tester);

    final progress = ProgressService();
    expect(routeResults, [null]);
    expect(await progress.getCompletedRounds(courseId: courseId), isEmpty);
    expect(await progress.getPerfectRounds(courseId: courseId), isEmpty);
    expect(await progress.getXp(courseCode: courseCode), 0);
    expect(await progress.getWeeklyXp(), 0);
  });

  testWidgets(
    'Flashcards add no base XP and do not block perfect or Laurel bonuses',
    (tester) async {
      final fixture = _roundFixture(exerciseCount: 8, flashcardCount: 2);
      final routeResults = <bool?>[];
      await _openRound(
        tester,
        fixture,
        routeResults: routeResults,
        waitForChoice: false,
      );

      await _completeMixedPerfectRound(tester, itemCount: 10);

      final progress = ProgressService();
      expect(routeResults, [true]);
      expect(await progress.getPerfectRounds(courseId: courseId), {
        fixture.round.id,
      });
      expect(await progress.getXp(courseCode: courseCode), 70);
      expect(await progress.getWeeklyXp(), 70);

      await _openRound(
        tester,
        fixture,
        routeResults: routeResults,
        waitForChoice: false,
      );
      await _completeMixedPerfectRound(tester, itemCount: 10);

      expect(routeResults, [true, true]);
      expect(await progress.getXp(courseCode: courseCode), 91);
      expect(await progress.getWeeklyXp(), 91);
    },
  );

  testWidgets(
    'a dynamically skipped TTS-only round receives only the perfect bonus',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('tts_enabled', false);
      final fixture = _roundFixture(exerciseCount: 0, includeTtsExercise: true);
      final routeResults = <bool?>[];
      await _openRound(
        tester,
        fixture,
        routeResults: routeResults,
        waitForChoice: false,
      );
      await _pumpUntilText(tester, 'Round completed');
      expect(find.text('Perfect bonus: +5 XP'), findsOneWidget);
      expect(find.text('Total: 5 XP'), findsOneWidget);
      await _tapAndPump(tester, 'Continue');
      await _pumpUntil(tester, () => routeResults.isNotEmpty);

      final progress = ProgressService();
      expect(routeResults, [true]);
      expect(await progress.getCompletedRounds(courseId: courseId), {
        fixture.round.id,
      });
      expect(await progress.getPerfectRounds(courseId: courseId), isEmpty);
      expect(await progress.getTtsSkippedPerfectRounds(courseId: courseId), {
        fixture.round.id,
      });
      expect(await progress.getXp(courseCode: courseCode), 5);
      expect(await progress.getWeeklyXp(), 5);
      expect(await progress.getStreak(courseCode: courseCode), 1);
      expect(await progress.getDaysStudied(courseCode: courseCode), 1);

      final recent = await progress.getRecentRounds(courseId: courseId);
      expect(recent, hasLength(1));
      expect(recent.single.roundId, fixture.round.id);
      expect(recent.single.errors, 0);

      const prefix = 'learner_Round%20Characterization%20Learner_';
      expect(prefs.getInt('${prefix}xp_IT'), 5);
      expect(prefs.getInt('${prefix}week_xp'), 5);
      expect(jsonDecode(prefs.getString('${prefix}week_xp_by_course')!), {
        courseId: 5,
      });
    },
  );

  testWidgets(
    'weekly goal state and completion persist before dialog and celebrate once',
    (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('weekly_xp_target', 10);
      final fixture = _roundFixture(exerciseCount: 2);
      final routeResults = <bool?>[];
      await _openRound(tester, fixture, routeResults: routeResults);

      await _completePerfectRound(tester, exerciseCount: 2);
      expect(find.text('Weekly goal reached!'), findsOneWidget);

      final progress = ProgressService();
      expect(routeResults, isEmpty);
      expect(await progress.getCompletedRounds(courseId: courseId), {
        fixture.round.id,
      });
      expect(await progress.getPerfectRounds(courseId: courseId), {
        fixture.round.id,
      });
      expect(await progress.getXp(courseCode: courseCode), 40);
      expect(await progress.getWeeklyXp(), 40);
      expect(await progress.getStreak(courseCode: courseCode), 1);
      expect(await progress.getDaysStudied(courseCode: courseCode), 1);
      expect(await progress.isWeeklyGoalCelebrated(), isTrue);
      final recent = await progress.getRecentRounds(courseId: courseId);
      expect(recent.single.roundId, fixture.round.id);
      expect(recent.single.errors, 0);

      await _tapAndPump(tester, 'Continue');
      expect(routeResults, [true]);

      await _openRound(tester, fixture, routeResults: routeResults);
      await _completePerfectRound(tester, exerciseCount: 2);

      expect(find.text('Weekly goal reached!'), findsNothing);
      expect(routeResults, [true, true]);
      expect(await progress.getWeeklyXp(), 49);
      expect(await progress.isWeeklyGoalCelebrated(), isTrue);
    },
  );

  testWidgets('imperfect repeat keeps first-pass-correct scoring', (
    tester,
  ) async {
    final fixture = _roundFixture(exerciseCount: 2);
    final progress = ProgressService();
    await progress.completeRound(
      fixture.round.id,
      courseId: courseId,
      courseCode: courseCode,
    );
    final routeResults = <bool?>[];
    await _openRound(tester, fixture, routeResults: routeResults);

    await _answerChoice(tester, correctly: false);
    await _tapAndPump(tester, 'Next');
    await _answerChoice(tester, correctly: true);
    await _tapAndPump(tester, 'Review mistakes');
    await _tapAndPump(tester, 'Continue');
    await _answerChoice(tester, correctly: true);
    await _tapAndPump(tester, 'Finish round');

    expect(routeResults, [true]);
    expect(await progress.getXp(courseCode: courseCode), 2);
    expect(await progress.getWeeklyXp(), 2);
    expect(await progress.getPerfectRounds(courseId: courseId), isEmpty);
    final recent = await progress.getRecentRounds(courseId: courseId);
    expect(recent.single.errors, 1);
  });

  testWidgets('six-exercise repeat displays and persists exactly 10 XP', (
    tester,
  ) async {
    final fixture = _roundFixture(exerciseCount: 6);
    final progress = ProgressService();
    await progress.completeRound(
      fixture.round.id,
      courseId: courseId,
      courseCode: courseCode,
    );
    final routeResults = <bool?>[];
    await _openRound(tester, fixture, routeResults: routeResults);

    await _answerChoice(tester, correctly: false);
    await _tapAndPump(tester, 'Next');
    for (var index = 1; index < 6; index++) {
      await _answerChoice(tester, correctly: true);
      if (index < 5) await _tapAndPump(tester, 'Next');
    }

    expect(
      find.text('Perfect completion awards up to 15 XP (repeat cap).'),
      findsNothing,
    );
    await _tapAndPump(tester, 'Review mistakes');
    await _tapAndPump(tester, 'Continue');
    await _answerChoice(tester, correctly: true);
    final finish = find.text('Finish round');
    await tester.ensureVisible(finish);
    await tester.tap(finish);
    await _pumpFrames(tester);

    expect(find.text('Correct answers: 10 XP'), findsOneWidget);
    expect(find.text('Perfect bonus: +5 XP'), findsNothing);
    expect(find.text('First Laurel: +25 XP'), findsNothing);
    expect(find.text('Total: 10 XP'), findsOneWidget);
    expect(await progress.getXp(courseCode: courseCode), 10);
    expect(await progress.getWeeklyXp(), 10);

    await _tapAndPump(tester, 'Continue');

    expect(routeResults, [true]);
  });

  testWidgets('course reset restores perfect first-completion XP eligibility', (
    tester,
  ) async {
    final fixture = _roundFixture(exerciseCount: 2);
    final progress = ProgressService();
    await progress.completeRound(
      fixture.round.id,
      courseId: courseId,
      courseCode: courseCode,
    );
    await progress.markPerfectRound(fixture.round.id, courseId: courseId);
    await progress.addXp(10, courseCode: courseCode, courseId: courseId);
    await progress.resetCourse(courseId);
    expect(await progress.getCompletedRounds(courseId: courseId), isEmpty);
    expect(await progress.getPerfectRounds(courseId: courseId), isEmpty);

    final routeResults = <bool?>[];
    await _openRound(tester, fixture, routeResults: routeResults);
    await _completePerfectRound(tester, exerciseCount: 2);

    expect(routeResults, [true]);
    expect(await progress.getCompletedRounds(courseId: courseId), {
      fixture.round.id,
    });
    expect(await progress.getPerfectRounds(courseId: courseId), {
      fixture.round.id,
    });
    expect(await progress.getXp(courseCode: courseCode), 50);
    expect(await progress.getWeeklyXp(), 50);
  });
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

class _RoundFixture {
  final Course course;
  final Chapter chapter;
  final Topic topic;
  final LearningRound round;

  const _RoundFixture({
    required this.course,
    required this.chapter,
    required this.topic,
    required this.round,
  });
}

_RoundFixture _roundFixture({
  required int exerciseCount,
  int flashcardCount = 0,
  bool includeTtsExercise = false,
}) {
  final exercises = <Exercise>[
    for (var index = 0; index < exerciseCount; index++)
      _choiceExercise('choice_${index + 1}'),
    for (var index = 0; index < flashcardCount; index++)
      _flashcardExercise('flashcard_${index + 1}'),
    if (includeTtsExercise) _listeningExercise('listening_1'),
  ];
  final round = LearningRound(
    id: 'round_characterization',
    title: 'Characterization Round',
    exercises: exercises,
  );
  final topic = Topic(
    id: 'topic_characterization',
    title: 'Characterization Topic',
    rounds: [round],
    guidebook: Guidebook.empty(),
  );
  final chapter = Chapter(
    id: 'chapter_characterization',
    title: 'Characterization Chapter',
    requiredTopics: 1,
    topics: [topic],
  );
  final course = Course(
    courseId: 'characterization_course',
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Characterization Course',
    ttsLanguage: 'it-IT',
    version: '1.0.0',
    chapters: [chapter],
  );
  return _RoundFixture(
    course: course,
    chapter: chapter,
    topic: topic,
    round: round,
  );
}

Exercise _choiceExercise(String id) => Exercise(
  id: id,
  type: 'choice',
  prompt: 'Choose the characterized answer.',
  question: '',
  answers: const ['Correct characterization', 'Wrong characterization'],
  correct: 0,
  tts: null,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);

Exercise _listeningExercise(String id) => Exercise(
  id: id,
  type: 'listening_choice',
  prompt: '',
  question: 'What do you hear?',
  answers: const ['casa', 'pane'],
  correct: 0,
  tts: 'casa',
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);

Exercise _flashcardExercise(String id) => Exercise(
  id: id,
  type: 'flashcard',
  prompt: 'Informational card',
  question: '',
  answers: const ['Word', 'Meaning'],
  correct: null,
  tts: null,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);

Future<void> _openRound(
  WidgetTester tester,
  _RoundFixture fixture, {
  required List<bool?> routeResults,
  bool previewMode = false,
  bool waitForChoice = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () async {
                routeResults.add(
                  await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => RoundScreen(
                        course: fixture.course,
                        chapter: fixture.chapter,
                        topic: fixture.topic,
                        round: fixture.round,
                        ttsLanguage: fixture.course.ttsLanguage,
                        roundIndex: 0,
                        previewMode: previewMode,
                      ),
                    ),
                  ),
                );
              },
              child: const Text('Open round'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open round'));
  await tester.pump();
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 250)),
  );
  if (!waitForChoice) return;
  await _pumpUntilText(tester, 'Correct characterization');
  expect(find.byType(RoundScreen), findsOneWidget);
  expect(find.text('Correct characterization'), findsOneWidget);
}

Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() condition, {
  int maxFrames = 100,
}) async {
  for (var frame = 0; frame < maxFrames; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (condition()) return;
  }
  fail('Timed out waiting for the expected completion state.');
}

Future<void> _answerChoice(
  WidgetTester tester, {
  required bool correctly,
}) async {
  final label = correctly
      ? 'Correct characterization'
      : 'Wrong characterization';
  final finder = find.text(label);
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await _pumpFrames(tester, count: 3);
}

Future<void> _completePerfectRound(
  WidgetTester tester, {
  required int exerciseCount,
}) async {
  for (var index = 0; index < exerciseCount; index++) {
    await _answerChoice(tester, correctly: true);
    await _tapAndPump(
      tester,
      index + 1 == exerciseCount ? 'Finish round' : 'Next',
    );
  }
}

Future<void> _completeMixedPerfectRound(
  WidgetTester tester, {
  required int itemCount,
}) async {
  for (var index = 0; index < itemCount; index++) {
    await _pumpUntil(
      tester,
      () =>
          find.text('Got it').evaluate().isNotEmpty ||
          find.text('Correct characterization').evaluate().isNotEmpty,
    );
    if (find.text('Got it').evaluate().isNotEmpty) {
      await _tapAndPump(tester, 'Got it');
    } else {
      await _answerChoice(tester, correctly: true);
    }
    await _tapAndPump(tester, index + 1 == itemCount ? 'Finish round' : 'Next');
  }
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
