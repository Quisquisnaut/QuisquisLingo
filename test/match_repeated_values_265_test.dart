import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/tts_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 265 Revision 4 (owner decision of 6 October 2026): a Match may
/// repeat a value (Ciao = Hi, Ciao = Bye). Two identical rows or sounds
/// are interchangeable, so either matching is right; giving both the same
/// answer is still wrong. Match and Listen and match alike.
const _created = '2026-10-06T00:00:00.000Z';
const _profile = '00000000-0000-4000-8000-000000002654';

const _pairs = [
  ['Ciao', 'Hi'],
  ['Ciao', 'Bye'],
  ['Acqua', 'Water'],
];

Exercise _match() => Exercise(
  id: 'match_repeat',
  type: 'matching',
  prompt: 'Match the words.',
  question: '',
  answers: const [],
  correct: null,
  tts: null,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: _pairs,
  hint: '',
  icons: const [],
);

Exercise _audioMatch() => Exercise(
  id: 'audio_match_repeat',
  type: 'audio_match',
  prompt: '',
  question: 'Match the sounds',
  answers: const ['Hi', 'Bye', 'Water'],
  correct: null,
  tts: null,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: _pairs,
  hint: '',
  icons: const [],
);

Course _course(Lesson lesson) => Course(
  courseId: 'match-repeat-course',
  originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
    profileId: _profile,
    displayName: 'Author',
  ),
  originalCreatedAtUtc: _created,
  maintainer: const CourseMaintainer(_profile),
  lastVersionEditorProfileId: _profile,
  lastVersionEditorDisplayName: 'Author',
  modifiedAtUtc: _created,
  title: 'Repeated values',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  lessons: [lesson],
);

class _Speech extends TtsCacheService {
  final spoken = <String>[];

  @override
  Future<bool> speak({
    required String text,
    required String language,
    String? learningLanguage,
    String? targetLanguage,
    double rate = 0.5,
    bool applyLearnerSettings = true,
    String? voicePreference,
  }) async {
    spoken.add(text);
    return true;
  }

  @override
  Future<void> stop() async {}
}

void _platforms() {
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
}

Future<void> _until(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  for (var attempt = 0; ; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(
      attempt < 100 ? const Duration(milliseconds: 25) : Duration.zero,
    );
    if (finder.evaluate().isNotEmpty) return;
    if (DateTime.now().isAfter(deadline)) break;
  }
  fail('Timed out waiting for $finder');
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<_Speech> _show(WidgetTester tester, Exercise exercise) async {
  tester.view.physicalSize = const Size(1200, 1800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final round = LearningRound(
    id: 'round_${exercise.id}',
    title: 'Repeated values',
    exercises: [exercise],
  );
  final lesson = Lesson(lessonId: 'lesson', title: 'Saluti', rounds: [round]);
  final course = _course(lesson);
  final speech = _Speech();
  await tester.pumpWidget(
    MaterialApp(
      home: RoundScreen(
        key: ValueKey(exercise.id),
        course: course,
        lesson: lesson,
        round: round,
        ttsLanguage: course.ttsLanguage,
        roundIndex: 0,
        previewMode: true,
        ttsCacheService: speech,
      ),
    ),
  );
  await _until(
    tester,
    find.byKey(Key('exercise-renderer-${exercise.primitive.serialized}')),
  );
  return speech;
}

/// Chooses [answers] for the rows showing [left], in screen order.
Future<void> _chooseForRows(
  WidgetTester tester,
  String left,
  List<String> answers,
) async {
  final rows = find.ancestor(
    of: find.text(left),
    matching: find.byType(LayoutBuilder),
  );
  for (var i = 0; i < answers.length; i++) {
    await _tap(
      tester,
      find.descendant(
        of: rows.at(i),
        matching: find.byType(DropdownButtonFormField<String>),
      ),
    );
    await _tap(tester, find.text(answers[i]).last);
  }
}

/// Chooses [answers] for the sound cards in screen order.
Future<void> _chooseForSounds(WidgetTester tester, List<String> answers) async {
  final cards = find.ancestor(
    of: find.byTooltip('Play sound'),
    matching: find.byType(Card),
  );
  for (var i = 0; i < answers.length; i++) {
    await _tap(
      tester,
      find.descendant(
        of: cards.at(i),
        matching: find.widgetWithText(ChoiceChip, answers[i]),
      ),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    _platforms();
    keepCrashLogUnavailable();
  });

  group('Match with a repeated value', () {
    for (final order in [
      ['Hi', 'Bye'],
      ['Bye', 'Hi'],
    ]) {
      testWidgets('either matching of the two Ciao rows is right: $order', (
        tester,
      ) async {
        await _show(tester, _match());
        expect(find.text('Ciao'), findsNWidgets(2));
        await _chooseForRows(tester, 'Ciao', order);
        await _chooseForRows(tester, 'Acqua', ['Water']);
        await _tap(tester, find.widgetWithText(FilledButton, 'Check'));
        expect(find.text('Correct'), findsOneWidget);
      });
    }

    testWidgets('the same answer for both Ciao rows is wrong', (tester) async {
      await _show(tester, _match());
      await _chooseForRows(tester, 'Ciao', ['Hi', 'Hi']);
      await _chooseForRows(tester, 'Acqua', ['Water']);
      await _tap(tester, find.widgetWithText(FilledButton, 'Check'));
      expect(find.text('Incorrect'), findsOneWidget);
    });
  });

  group('Listen and match with a repeated sound', () {
    testWidgets('either matching of the two identical sounds is right', (
      tester,
    ) async {
      for (final order in [
        ['Hi', 'Bye'],
        ['Bye', 'Hi'],
      ]) {
        final speech = await _show(tester, _audioMatch());
        // The cards are shuffled: each card's Play button says its sound.
        final plays = find.byTooltip('Play sound');
        expect(plays, findsNWidgets(3));
        final answers = <String>[];
        var ciao = 0;
        for (var i = 0; i < 3; i++) {
          await _tap(tester, plays.at(i));
          final sound = speech.spoken.last;
          answers.add(sound == 'Acqua' ? 'Water' : order[ciao++]);
        }
        expect(ciao, 2);
        await _chooseForSounds(tester, answers);
        await _tap(tester, find.widgetWithText(FilledButton, 'Check matches'));
        expect(find.text('Correct'), findsOneWidget, reason: '$order');
        await tester.pumpWidget(const SizedBox());
      }
    });
  });
}
