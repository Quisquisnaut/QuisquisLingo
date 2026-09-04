import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'sound_effects_enabled': false,
      'weekly_xp_target': 1000,
    });
    await ProfileService().addProfile('Renderer 225.02');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async => throw PlatformException(code: 'test-storage'),
        );
  });

  for (final brightness in [Brightness.light, Brightness.dark]) {
    for (final width in [320.0, 375.0, 430.0, 1100.0]) {
      testWidgets(
        'all required exercise renderers fit in ${brightness.name} at ${width.toInt()} px',
        (tester) async {
          tester.view.physicalSize = Size(width, 780);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          for (final exercise in _renderers()) {
            await _pumpRound(tester, exercise, brightness: brightness);
            expect(
              find.byType(RoundScreen),
              findsOneWidget,
              reason: exercise.type,
            );
            expect(tester.takeException(), isNull, reason: exercise.type);
          }
        },
      );
    }
  }

  for (final correct in [true, false]) {
    testWidgets(
      'Dark mode Build translation ${correct ? 'correct' : 'incorrect'} feedback shows every answer',
      (tester) async {
        tester.view.physicalSize = const Size(320, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final exercise = _buildTranslation();
        await _pumpRound(tester, exercise, brightness: Brightness.dark);

        await tester.tap(find.text('Come'));
        await tester.pump();
        await tester.tap(find.text(correct ? 'va' : 'te'));
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Check'));
        await tester.pump();

        expect(find.text(correct ? 'Correct' : 'Incorrect'), findsOneWidget);
        expect(
          find.byKey(const Key('exercise-feedback-surface')),
          findsOneWidget,
        );
        expect(
          find.byWidgetPredicate(
            (widget) =>
                widget is Semantics &&
                widget.properties.label == '3 correct translations',
          ),
          findsOneWidget,
        );
        for (final answer in [
          '• Come stai?',
          '• Come va?',
          '• Come te la passi?',
        ]) {
          expect(find.text(answer), findsOneWidget);
        }
        final context = tester.element(
          find.byKey(const Key('exercise-feedback-surface')),
        );
        expect(Theme.of(context).brightness, Brightness.dark);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('Dark text input focus and disabled controls remain renderable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await _pumpRound(
      tester,
      _exercise('listening_spelling'),
      brightness: Brightness.dark,
    );

    final input = find.byType(TextField);
    expect(input, findsOneWidget);
    await tester.tap(input);
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Check'))
          .onPressed,
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpRound(
  WidgetTester tester,
  Exercise exercise, {
  required Brightness brightness,
}) async {
  final round = LearningRound(
    id: 'round-${exercise.id}',
    updatedAt: DateTime.utc(2026, 9, 4),
    title: '',
    exercises: [exercise],
  );
  final lesson = Lesson(
    lessonId: 'lesson-${exercise.id}',
    updatedAt: DateTime.utc(2026, 9, 4),
    title: 'Renderer',
    rounds: [round],
  );
  final course = Course(
    courseId: 'renderer-course',
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Renderer',
    ttsLanguage: 'it-IT',
    version: '1',
    lessons: [lesson],
  );
  final scheme = ColorScheme.fromSeed(
    seedColor: Colors.teal,
    brightness: brightness,
  );
  final normalDebugPrint = debugPrint;
  debugPrint = (message, {wrapWidth}) {};
  try {
    await tester.pumpWidget(
      MaterialApp(
        key: ValueKey('${exercise.id}-${brightness.name}'),
        theme: ThemeData(useMaterial3: true, colorScheme: scheme),
        home: RoundScreen(
          course: course,
          lesson: lesson,
          round: round,
          ttsLanguage: course.ttsLanguage,
          roundIndex: 0,
          previewMode: true,
        ),
      ),
    );
    for (var frame = 0; frame < 80; frame++) {
      await tester.pump(const Duration(milliseconds: 25));
      if (find
          .byKey(Key('exercise-renderer-${exercise.type}'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
    }
  } finally {
    debugPrint = normalDebugPrint;
  }
  expect(find.byKey(Key('exercise-renderer-${exercise.type}')), findsOneWidget);
}

List<Exercise> _renderers() => [
  _exercise('choice'),
  _exercise('icon_choice'),
  _exercise('gap_choice'),
  _exercise('dialogue_response'),
  _exercise('listening_choice'),
  _exercise('listening_comprehension'),
  _exercise('listening_spelling'),
  _exercise('missing_word'),
  _exercise('word_order'),
  _buildTranslation(),
  _exercise('matching'),
  _exercise('reading_comprehension'),
];

Exercise _exercise(String type) => switch (type) {
  'choice' => _base(type, prompt: 'Choose.', question: 'Which greeting?'),
  'icon_choice' => _base(
    type,
    prompt: 'Choose the image.',
    question: 'Which one is the apple?',
    icons: const ['apple', 'book'],
  ),
  'gap_choice' => _base(
    type,
    prompt: 'Complete the sentence.',
    question: 'Io ___ italiano.',
  ),
  'dialogue_response' => _base(
    type,
    prompt: 'The teacher says hello.',
    question: 'How do you reply?',
  ),
  'listening_choice' => _base(
    type,
    prompt: '',
    question: 'Which word do you hear?',
    tts: 'ciao',
  ),
  'listening_comprehension' => _base(
    type,
    prompt: '',
    question: 'Which expression was used?',
    tts: 'Oggi ascoltiamo insieme questa breve frase.',
  ),
  'listening_spelling' => _base(
    type,
    prompt: '',
    question: 'Type what you hear.',
    answers: const [],
    correct: null,
    accepted: const ['ciao'],
    tts: 'ciao',
  ),
  'missing_word' => _base(
    type,
    prompt: 'Una casa.',
    question: 'Complete the missing word.',
    answers: const [],
    correct: null,
    accepted: const ['casa'],
    missingWords: const ['casa'],
    tts: 'Una casa.',
  ),
  'word_order' => _base(
    type,
    prompt: 'Build the sentence.',
    question: '',
    answers: const [],
    correct: null,
    tokens: const ['Io', 'studio'],
    orderAnswer: const ['Io', 'studio'],
  ),
  'matching' => _base(
    type,
    prompt: 'Match the words.',
    question: '',
    answers: const [],
    correct: null,
    pairs: const [
      ['casa', 'house'],
      ['libro', 'book'],
      ['acqua', 'water'],
    ],
  ),
  'reading_comprehension' => _base(
    type,
    prompt: 'Oggi studio con Maria.',
    question: 'Who studies with me?',
    answers: const ['Maria', 'Luca'],
  ),
  _ => throw ArgumentError(type),
};

Exercise _base(
  String type, {
  required String prompt,
  required String question,
  List<String> answers = const ['Correct', 'Wrong'],
  int? correct = 0,
  String? tts,
  List<String> accepted = const [],
  List<String> tokens = const [],
  List<String> orderAnswer = const [],
  List<List<String>> pairs = const [],
  List<String> icons = const [],
  List<String> missingWords = const [],
}) => Exercise(
  id: 'render-$type',
  updatedAt: DateTime.utc(2026, 9, 4),
  type: type,
  prompt: prompt,
  question: question,
  answers: answers,
  correct: correct,
  tts: tts,
  accepted: accepted,
  tokens: tokens,
  orderAnswer: orderAnswer,
  pairs: pairs,
  hint: type == 'choice' ? 'A useful contextual hint.' : '',
  icons: icons,
  missingWords: missingWords,
);

Exercise _buildTranslation() => Exercise(
  id: 'render-build-translation',
  updatedAt: DateTime.utc(2026, 9, 4),
  type: 'build_translation',
  prompt: 'How are you?',
  question: '',
  answers: const [],
  correct: null,
  tts: null,
  accepted: const [],
  tokens: const ['Come', 'stai', 'va', 'te', 'la', 'passi'],
  orderAnswer: const [],
  correctTranslations: const ['Come stai?', 'Come va?', 'Come te la passi?'],
  pairs: const [],
  hint: '',
  icons: const [],
);
