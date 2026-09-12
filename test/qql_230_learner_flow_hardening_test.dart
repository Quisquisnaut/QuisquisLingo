import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/duel_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/progress_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    _installDesktopPluginMocks();
    SharedPreferences.setMockInitialValues({});
    await ProfileService().addProfile('QQL 230 learner');
    await SettingsService().setSoundEffectsEnabled(false);
  });

  testWidgets(
    'Round intro cannot continue before asynchronous initialization is ready',
    (tester) async {
      final settings = _DeferredAudioSettings();
      final fixture = _roundFixture(includeIntro: true);

      await tester.pumpWidget(
        MaterialApp(
          home: RoundScreen(
            course: fixture.course,
            lesson: fixture.lesson,
            round: fixture.round,
            roundIndex: 0,
            ttsLanguage: 'it-IT',
            settingsService: settings,
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Continue to Round'), findsNothing);
      expect(tester.takeException(), isNull);

      settings.complete(audioExercisesEnabled: false);
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 250)),
      );
      await _pumpUntil(tester, find.text('Continue to Round'));
      await tester.tap(find.text('Continue to Round'));
      await tester.pump();

      expect(find.text('Correct'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('rapid Round finish invokes completion only once', (
    tester,
  ) async {
    final fixture = _roundFixture();
    await _pumpRound(tester, fixture);

    await tester.tap(find.widgetWithText(FilledButton, 'Correct'));
    await tester.pump();
    final finish = find.widgetWithText(FilledButton, 'Finish round');
    await tester.ensureVisible(finish);
    final onPressed = tester.widget<FilledButton>(finish).onPressed!;

    onPressed();
    onPressed();
    await _pumpUntil(tester, find.text('Round completed'));

    final progress = ProgressService();
    expect(await progress.getXp(courseCode: 'IT'), 35);
    expect(await progress.getWeeklyXp(), 35);
    expect(
      await progress.getCompletedRounds(courseId: fixture.course.courseId),
      {fixture.round.id},
    );
    expect(
      await progress.getRecentRounds(courseId: fixture.course.courseId),
      hasLength(1),
    );
    expect(find.text('Round completed'), findsOneWidget);
  });

  testWidgets('rapid Duel finish records one victory and one XP award', (
    tester,
  ) async {
    final fixture = _duelFixture();
    await tester.pumpWidget(
      MaterialApp(
        home: DuelScreen(
          course: fixture.course,
          lesson: fixture.lesson,
          ttsLanguage: 'it-IT',
        ),
      ),
    );
    await _pumpUntil(tester, find.text('Question 1/25 · 4 lives'));

    for (var index = 0; index < 25; index++) {
      await tester.tap(find.widgetWithText(FilledButton, 'Correct'));
      await tester.pump();
      if (index < 24) {
        await tester.tap(find.widgetWithText(FilledButton, 'Next'));
        await tester.pump();
      }
    }

    final finish = find.widgetWithText(FilledButton, 'Finish duel');
    await tester.ensureVisible(finish);
    final onPressed = tester.widget<FilledButton>(finish).onPressed!;
    onPressed();
    onPressed();
    await _pumpUntil(tester, find.text('Final Duel completed!'));

    final progress = ProgressService();
    expect(await progress.getXp(courseCode: 'IT'), 50);
    expect(await progress.getWeeklyXp(), 50);
    expect(await progress.getWonDuels(courseId: fixture.course.courseId), {
      fixture.lesson.duel.id,
    });
    expect(find.text('Final Duel completed!'), findsOneWidget);
  });

  testWidgets('Duel initialization failure reaches a bounded safe state', (
    tester,
  ) async {
    final fixture = _duelFixture();
    await tester.pumpWidget(
      MaterialApp(
        home: DuelScreen(
          course: fixture.course,
          lesson: fixture.lesson,
          ttsLanguage: 'it-IT',
          settingsService: _FailingAudioSettings(),
        ),
      ),
    );
    await _pumpUntil(tester, find.textContaining('could not be opened safely'));

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
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

class _DeferredAudioSettings extends SettingsService {
  final Completer<bool> _audioExercisesEnabled = Completer<bool>();

  void complete({required bool audioExercisesEnabled}) {
    _audioExercisesEnabled.complete(audioExercisesEnabled);
  }

  @override
  Future<bool> areAudioExercisesEnabled() => _audioExercisesEnabled.future;
}

class _FailingAudioSettings extends SettingsService {
  @override
  Future<bool> areAudioExercisesEnabled() async {
    throw StateError('simulated settings failure');
  }
}

class _LearnerFixture {
  final Course course;
  final Lesson lesson;
  final LearningRound round;

  const _LearnerFixture({
    required this.course,
    required this.lesson,
    required this.round,
  });
}

_LearnerFixture _roundFixture({bool includeIntro = false}) {
  final round = LearningRound(
    id: 'qql_230_round',
    title: 'QQL 230 Round',
    content: [
      if (includeIntro)
        LearningContent.textual(
          id: 'qql_230_intro',
          kind: 'text',
          role: 'lesson_intro',
          text: 'Prepare before starting.',
        ),
      LearningContent.fromExercise(_choiceExercise('qql_230_exercise')),
    ],
  );
  final lesson = Lesson(
    lessonId: 'qql_230_lesson',
    title: 'QQL 230 Lesson',
    rounds: [round],
  );
  return _LearnerFixture(
    course: _course('qql_230_round_course', lesson),
    lesson: lesson,
    round: round,
  );
}

_LearnerFixture _duelFixture() {
  final round = LearningRound(
    id: 'qql_230_duel_round',
    title: 'QQL 230 Duel Round',
    exercises: [
      for (var index = 0; index < 25; index++)
        _choiceExercise('qql_230_duel_exercise_$index'),
    ],
  );
  final lesson = Lesson(
    lessonId: 'qql_230_duel_lesson',
    title: 'QQL 230 Duel Lesson',
    rounds: [round],
  );
  return _LearnerFixture(
    course: _course('qql_230_duel_course', lesson),
    lesson: lesson,
    round: round,
  );
}

Course _course(String courseId, Lesson lesson) => Course(
  courseId: courseId,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'QQL 230 Course',
  ttsLanguage: 'it-IT',
  lessons: [lesson],
);

Exercise _choiceExercise(String id) => Exercise(
  id: id,
  type: 'choice',
  prompt: 'Choose the correct answer.',
  question: '',
  answers: const ['Correct', 'Wrong'],
  correct: 0,
  tts: null,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);

Future<void> _pumpRound(WidgetTester tester, _LearnerFixture fixture) async {
  await tester.pumpWidget(
    MaterialApp(
      home: RoundScreen(
        course: fixture.course,
        lesson: fixture.lesson,
        round: fixture.round,
        roundIndex: 0,
        ttsLanguage: 'it-IT',
      ),
    ),
  );
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 250)),
  );
  await _pumpUntil(tester, find.text('Correct'));
}

Future<void> _pumpUntil(
  WidgetTester tester,
  Finder finder, {
  int maxFrames = 120,
}) async {
  for (var frame = 0; frame < maxFrames; frame++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out waiting for the expected widget.');
}
