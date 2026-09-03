import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
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
    await ProfileService().addProfile('Responsive Learner');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async =>
              throw PlatformException(code: 'test_storage_unavailable'),
        );
  });

  for (final width in [320.0, 375.0, 430.0, 1100.0]) {
    testWidgets(
      '224 editor and learner flows fit at ${width.toInt()} logical px',
      (tester) async {
        tester.view.physicalSize = Size(width, 760);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final course = _course();
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey('course-editor-$width'),
            home: CourseEditorScreen(course: course, userCourse: true),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.ensureVisible(
          find.byKey(const Key('course-editor-lessons-navigation')),
        );
        await tester.tap(
          find.byKey(const Key('course-editor-lessons-navigation')),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('lesson-management-lock')), findsOneWidget);
        await tester.tap(
          find.byKey(const ValueKey('lesson-actions-responsive_lesson')),
        );
        await tester.pumpAndSettle();
        expect(find.text('Duplicate'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey('translation-editor-$width'),
            home: ExerciseEditorScreen(
              exercise: _translation(),
              title: 'Type the translation',
              isNew: false,
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView), const Offset(0, -420));
        await tester.pumpAndSettle();
        expect(find.text('Accepted translations'), findsOneWidget);
        await tester.tap(find.byKey(const Key('type-translation-answer-help')));
        await tester.pumpAndSettle();
        expect(
          find.text('Type the translation · answer syntax'),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        final authorLesson = course.lessons.single;
        final authorRound = authorLesson.rounds.single;
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey('wizard-$width'),
            home: ExerciseCreationWizardScreen(
              course: course,
              lesson: authorLesson,
              round: authorRound,
              roundIndex: 0,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('wizard-setup')), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey('generator-$width'),
            home: GuidebookRoundGeneratorScreen(
              course: course,
              lesson: authorLesson,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('guidebook-generator-configure')),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const Key('generator-review-plan')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const Key('guidebook-generator-plan')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);

        final exercise = _contextual();
        final round = LearningRound(
          id: 'responsive_round',
          title: 'Context',
          exercises: [exercise],
        );
        final lesson = Lesson(
          lessonId: 'responsive_lesson',
          title: 'Responsive',
          rounds: [round],
        );
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey('context-round-$width'),
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
        for (var frame = 0; frame < 100; frame++) {
          await tester.pump(const Duration(milliseconds: 50));
          if (find
              .byKey(const Key('contextual-comprehension-dialogue'))
              .evaluate()
              .isNotEmpty) {
            break;
          }
        }
        expect(
          find.byKey(const Key('contextual-comprehension-dialogue')),
          findsOneWidget,
        );
        expect(find.text('What does Jane mean?'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Course _course() {
  final round = LearningRound(
    id: 'responsive_authoring_round',
    title: 'Round',
    exercises: [_translation()],
  );
  final lesson = Lesson(
    lessonId: 'responsive_lesson',
    title: 'Responsive Lesson',
    rounds: [round],
    guidebook: Guidebook(
      vocabulary: const ['casa = house', 'pane = bread', 'acqua = water'],
      examples: const ['La casa è grande.', 'Il pane è fresco.', 'Bevo acqua.'],
    ),
  );
  return Course(
    courseId: 'responsive_224',
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Responsive Course',
    ttsLanguage: 'it-IT',
    version: '1',
    lessons: [lesson],
  );
}

Exercise _translation() => Exercise(
  id: 'translation_stable',
  type: 'type_translation',
  prompt: 'I would like a cappuccino.',
  question: '',
  answers: const [],
  correct: null,
  tts: null,
  accepted: const ['Vorrei un cappuccino.'],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);

Exercise _contextual() => Exercise.v2(
  id: 'context_stable',
  editorTemplate: 'contextual_comprehension',
  promptElements: const [
    PromptElement(
      role: 'dialogue_turn',
      type: 'text',
      speaker: 'Jane',
      text: 'I thought Jim was coming with us.',
    ),
    PromptElement(
      role: 'dialogue_turn',
      type: 'text',
      speaker: 'Jim',
      text: 'I changed my mind.',
    ),
    PromptElement(
      role: 'dialogue_turn',
      type: 'text',
      speaker: 'Jane',
      text: 'That is just great.',
    ),
    PromptElement(role: 'question', type: 'text', text: 'What does Jane mean?'),
  ],
  interaction: const ExerciseInteraction(
    kind: 'select',
    items: [
      ExerciseItem(
        id: 'sarcastic',
        content: [PromptElement(type: 'text', text: 'She is annoyed.')],
      ),
      ExerciseItem(
        id: 'happy',
        content: [PromptElement(type: 'text', text: 'She is delighted.')],
      ),
    ],
  ),
  evaluation: const ExerciseEvaluation(
    kind: 'selected_items',
    correctItemIds: ['sarcastic'],
  ),
);
