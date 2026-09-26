import 'support/test_directories.dart';
// QQL Build 238 Phase 2: focused tests for the multiple-selection extension
// of the existing Select primitive (multi-select mode, required-selection
// count, and set-based exact-match correctness).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A 4-option multi-select Choice exercise: exactly 2 correct answers,
/// required selections defaulting to that same count.
Exercise _multiSelectExercise({int minSelections = 2}) => Exercise.v2(
  id: 'select-multi',
  updatedAt: DateTime.utc(2026, 9, 18),
  editorTemplate: 'choice',
  promptElements: const [
    PromptElement(role: 'primary', type: 'text', text: 'Choose the fruits.'),
  ],
  interaction: ExerciseInteraction(
    kind: 'select',
    minSelections: minSelections,
    maxSelections: 4,
    items: const [
      ExerciseItem(
        id: 'item_0',
        content: [PromptElement(type: 'text', text: 'Apple')],
      ),
      ExerciseItem(
        id: 'item_1',
        content: [PromptElement(type: 'text', text: 'Carrot')],
      ),
      ExerciseItem(
        id: 'item_2',
        content: [PromptElement(type: 'text', text: 'Banana')],
      ),
      ExerciseItem(
        id: 'item_3',
        content: [PromptElement(type: 'text', text: 'Potato')],
      ),
    ],
  ),
  evaluation: const ExerciseEvaluation(
    kind: 'selected_items',
    correctItemIds: ['item_0', 'item_2'],
  ),
);

/// An unmodified legacy single-select Choice exercise (no multi-select), the
/// same way existing Build 213-237 content is authored.
Exercise _legacyChoiceExercise() => Exercise(
  id: 'legacy-choice',
  updatedAt: DateTime.utc(2026, 9, 18),
  type: 'choice',
  prompt: 'Good morning',
  question: '',
  answers: const ['Buongiorno', 'Buonanotte', 'Ciao'],
  correct: 0,
  tts: null,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('model', () {
    test('multi-select fields round-trip through JSON', () {
      final exercise = _multiSelectExercise();
      final json = exercise.toJson();
      final restored = Exercise.fromV2Json(
        json,
        contentId: exercise.id,
        editorTemplate: exercise.editorTemplate,
        publicationState: exercise.publicationState,
      );
      expect(restored.isMultiSelect, isTrue);
      expect(restored.requiredSelectionCount, 2);
      expect(restored.maxSelectionCount, 4);
      expect(restored.correctItemIdSet, {'item_0', 'item_2'});
    });

    test('legacy single-select Choice exercises are unaffected', () {
      final exercise = _legacyChoiceExercise();
      expect(exercise.isMultiSelect, isFalse);
      expect(exercise.maxSelectionCount, 1);
      expect(exercise.correctItemIdSet, hasLength(1));
      expect(exercise.correct, 0);
    });
  });

  group('audit', () {
    test('a valid multi-select Choice exercise has no issues', () {
      final issues = CourseAuditService().auditExercise(_multiSelectExercise());
      expect(issues, isEmpty);
    });

    test('a multi-select exercise with no correct answers is flagged', () {
      final exercise = Exercise.v2(
        id: 'no-correct',
        updatedAt: DateTime.utc(2026, 9, 18),
        editorTemplate: 'choice',
        promptElements: const [
          PromptElement(role: 'primary', type: 'text', text: 'Pick some.'),
        ],
        interaction: const ExerciseInteraction(
          kind: 'select',
          minSelections: 1,
          maxSelections: 2,
          items: [
            ExerciseItem(
              id: 'item_0',
              content: [PromptElement(type: 'text', text: 'A')],
            ),
            ExerciseItem(
              id: 'item_1',
              content: [PromptElement(type: 'text', text: 'B')],
            ),
          ],
        ),
        evaluation: const ExerciseEvaluation(kind: 'selected_items'),
      );
      final issues = CourseAuditService().auditExercise(exercise);
      expect(issues, isNotEmpty);
    });

    test('a required-selection count outside range is flagged', () {
      final exercise = _multiSelectExercise(minSelections: 9);
      final issues = CourseAuditService().auditExercise(exercise);
      expect(
        issues.any((issue) => issue.message.contains('Required selections')),
        isTrue,
      );
    });
  });

  group('learner UI', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'sound_effects_enabled': false,
        'weekly_xp_target': 1000,
      });
      await ProfileService().addProfile('Select Multi Learner');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async {
              if (call.method == 'getApplicationSupportDirectory') {
                return testSupportDirectory.path;
              }
              throw PlatformException(code: 'test-storage');
            },
          );
      keepCrashLogUnavailable();
    });

    Future<void> pumpExercise(WidgetTester tester, Exercise exercise) async {
      final round = LearningRound(
        id: 'round-${exercise.id}',
        updatedAt: DateTime.utc(2026, 9, 18),
        title: '',
        exercises: [exercise],
      );
      final lesson = Lesson(
        lessonId: 'lesson-${exercise.id}',
        updatedAt: DateTime.utc(2026, 9, 18),
        title: 'Select multi',
        rounds: [round],
      );
      final course = Course(
        courseId: 'select-multi-course',
        learningLanguage: 'English',
        interfaceLanguage: 'English',
        sourceLanguage: 'English',
        targetLanguage: 'English',
        title: 'Select multi',
        ttsLanguage: 'en-US',
        lessons: [lesson],
      );
      await tester.pumpWidget(
        MaterialApp(
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
            .byKey(const Key('exercise-renderer-choice'))
            .evaluate()
            .isNotEmpty) {
          break;
        }
      }
    }

    testWidgets(
      'Check stays disabled until the required selection count is reached',
      (tester) async {
        // Options are shuffled for display, so select by their text rather
        // than by a fixed pre-shuffle index.
        await pumpExercise(tester, _multiSelectExercise());
        final check = find.widgetWithText(FilledButton, 'Check');
        expect(tester.widget<FilledButton>(check).onPressed, isNull);

        await tester.tap(find.text('Apple'));
        await tester.pump();
        expect(tester.widget<FilledButton>(check).onPressed, isNull);

        await tester.tap(find.text('Banana'));
        await tester.pump();
        expect(tester.widget<FilledButton>(check).onPressed, isNotNull);
      },
    );

    testWidgets('selecting exactly the correct set marks the answer correct', (
      tester,
    ) async {
      await pumpExercise(tester, _multiSelectExercise());
      await tester.tap(find.text('Apple'));
      await tester.pump();
      await tester.tap(find.text('Banana'));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Check'));
      await tester.pump();
      expect(find.text('Correct'), findsOneWidget);
    });

    testWidgets(
      'selecting a correct option plus an extra wrong option marks the answer incorrect',
      (tester) async {
        await pumpExercise(tester, _multiSelectExercise());
        await tester.tap(find.text('Apple'));
        await tester.pump();
        await tester.tap(find.text('Banana'));
        await tester.pump();
        await tester.tap(find.text('Carrot'));
        await tester.pump();
        await tester.tap(find.widgetWithText(FilledButton, 'Check'));
        await tester.pump();
        expect(find.text('Incorrect'), findsOneWidget);
      },
    );

    testWidgets('a legacy single-select Choice exercise answers immediately', (
      tester,
    ) async {
      await pumpExercise(tester, _legacyChoiceExercise());
      expect(find.widgetWithText(FilledButton, 'Check'), findsNothing);
      await tester.tap(find.text('Buongiorno'));
      await tester.pump();
      expect(find.text('Correct'), findsOneWidget);
    });
  });
}
