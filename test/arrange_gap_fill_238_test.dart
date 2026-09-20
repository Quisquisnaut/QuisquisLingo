import 'support/test_directories.dart';
// QQL Build 238 Phase 1: focused tests for the gap-fill extension of the
// existing Arrange primitive (inline gaps, word/phrase tiles, distractors,
// tile removal, tile move-between-gaps and an optional audio prompt).
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A two-gap Arrange exercise: "I ___ ___ school." with a verb gap and a
/// preposition gap, an unused distractor tile, and an optional audio prompt.
Exercise _gapFillExercise({String? tts}) => Exercise.v2(
  id: 'arrange-gap-fill',
  updatedAt: DateTime.utc(2026, 9, 17),
  editorTemplate: 'word_order',
  promptElements: [if (tts != null) PromptElement(type: 'audio', text: tts)],
  interaction: const ExerciseInteraction(
    kind: 'arrange',
    items: [
      ExerciseItem(
        id: 'tile_go',
        content: [PromptElement(type: 'text', text: 'go')],
      ),
      ExerciseItem(
        id: 'tile_goes',
        content: [PromptElement(type: 'text', text: 'goes')],
      ),
      ExerciseItem(
        id: 'tile_to',
        content: [PromptElement(type: 'text', text: 'to')],
      ),
      ExerciseItem(
        id: 'tile_from',
        content: [PromptElement(type: 'text', text: 'from')],
      ),
    ],
    layout: [
      PromptElement(type: 'text', text: 'I'),
      PromptElement(type: 'gap', text: 'verb_gap'),
      PromptElement(type: 'gap', text: 'prep_gap'),
      PromptElement(type: 'text', text: 'school.'),
    ],
  ),
  evaluation: const ExerciseEvaluation(
    kind: 'gap_items',
    gapAssignments: {'verb_gap': 'tile_go', 'prep_gap': 'tile_to'},
  ),
);

/// An unmodified legacy whole-sentence Arrange exercise (no gaps), built the
/// same way existing Build 213-237 content is authored.
Exercise _legacyWordOrderExercise() => Exercise(
  id: 'legacy-word-order',
  updatedAt: DateTime.utc(2026, 9, 17),
  type: 'word_order',
  prompt: 'Build the sentence.',
  question: '',
  answers: const [],
  correct: null,
  tts: null,
  accepted: const [],
  tokens: const ['Io', 'studio', 'oggi'],
  orderAnswer: const ['Io', 'studio'],
  pairs: const [],
  hint: '',
  icons: const [],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('model', () {
    test('gap layout and gap assignments round-trip through JSON', () {
      final exercise = _gapFillExercise(tts: 'I go to school.');
      final json = exercise.toJson();
      final restored = Exercise.fromV2Json(
        json,
        contentId: exercise.id,
        editorTemplate: exercise.editorTemplate,
        publicationState: exercise.publicationState,
      );
      expect(restored.hasArrangeGaps, isTrue);
      expect(
        restored.arrangeLayout.map((e) => '${e.type}:${e.text}'),
        exercise.arrangeLayout.map((e) => '${e.type}:${e.text}'),
      );
      expect(restored.arrangeGapAssignments, exercise.arrangeGapAssignments);
      expect(restored.tts, 'I go to school.');
    });

    test('legacy whole-sentence Arrange exercises have no gaps', () {
      final exercise = _legacyWordOrderExercise();
      expect(exercise.hasArrangeGaps, isFalse);
      expect(exercise.arrangeLayout, isEmpty);
      expect(exercise.arrangeGapAssignments, isEmpty);
      // Existing whole-sentence evaluation is untouched.
      expect(exercise.orderAnswer, ['Io', 'studio']);
    });
  });

  group('audit', () {
    test('a valid gap-fill Arrange exercise has no issues', () {
      final issues = CourseAuditService().auditExercise(_gapFillExercise());
      expect(issues, isEmpty);
    });

    test('a gap without an assignment is flagged', () {
      final exercise = Exercise.v2(
        id: 'bad-gap',
        updatedAt: DateTime.utc(2026, 9, 17),
        editorTemplate: 'word_order',
        promptElements: const [],
        interaction: const ExerciseInteraction(
          kind: 'arrange',
          items: [
            ExerciseItem(
              id: 'tile_go',
              content: [PromptElement(type: 'text', text: 'go')],
            ),
          ],
          layout: [
            PromptElement(type: 'text', text: 'I'),
            PromptElement(type: 'gap', text: 'verb_gap'),
          ],
        ),
        evaluation: const ExerciseEvaluation(kind: 'gap_items'),
      );
      final issues = CourseAuditService().auditExercise(exercise);
      expect(issues, isNotEmpty);
    });

    test('more than 2 unused distractor tiles is flagged', () {
      final exercise = Exercise.v2(
        id: 'too-many-distractors',
        updatedAt: DateTime.utc(2026, 9, 17),
        editorTemplate: 'word_order',
        promptElements: const [],
        interaction: const ExerciseInteraction(
          kind: 'arrange',
          items: [
            ExerciseItem(
              id: 'tile_go',
              content: [PromptElement(type: 'text', text: 'go')],
            ),
            ExerciseItem(
              id: 'tile_a',
              content: [PromptElement(type: 'text', text: 'a')],
            ),
            ExerciseItem(
              id: 'tile_b',
              content: [PromptElement(type: 'text', text: 'b')],
            ),
            ExerciseItem(
              id: 'tile_c',
              content: [PromptElement(type: 'text', text: 'c')],
            ),
          ],
          layout: [
            PromptElement(type: 'text', text: 'I'),
            PromptElement(type: 'gap', text: 'verb_gap'),
          ],
        ),
        evaluation: const ExerciseEvaluation(
          kind: 'gap_items',
          gapAssignments: {'verb_gap': 'tile_go'},
        ),
      );
      final issues = CourseAuditService().auditExercise(exercise);
      expect(
        issues.any((issue) => issue.message.contains('distractor')),
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
      await ProfileService().addProfile('Arrange Gap Learner');
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
    });

    Future<void> pumpGapExercise(WidgetTester tester, Exercise exercise) async {
      final round = LearningRound(
        id: 'round-${exercise.id}',
        updatedAt: DateTime.utc(2026, 9, 17),
        title: '',
        exercises: [exercise],
      );
      final lesson = Lesson(
        lessonId: 'lesson-${exercise.id}',
        updatedAt: DateTime.utc(2026, 9, 17),
        title: 'Arrange gaps',
        rounds: [round],
      );
      final course = Course(
        courseId: 'arrange-gap-course',
        learningLanguage: 'English',
        interfaceLanguage: 'English',
        sourceLanguage: 'English',
        targetLanguage: 'English',
        title: 'Arrange gaps',
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
            .byKey(const Key('exercise-renderer-word_order'))
            .evaluate()
            .isNotEmpty) {
          break;
        }
      }
    }

    testWidgets('filling every gap correctly enables Check and marks correct', (
      tester,
    ) async {
      await pumpGapExercise(tester, _gapFillExercise());
      final check = find.widgetWithText(FilledButton, 'Check');
      expect(tester.widget<FilledButton>(check).onPressed, isNull);

      await tester.tap(find.byKey(const Key('arrange-tile-tile_go')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('arrange-tile-tile_to')));
      await tester.pump();

      expect(tester.widget<FilledButton>(check).onPressed, isNotNull);
      await tester.tap(check);
      await tester.pump();
      expect(find.text('Correct'), findsOneWidget);
    });

    testWidgets('a wrong tile in a gap marks the answer incorrect', (
      tester,
    ) async {
      await pumpGapExercise(tester, _gapFillExercise());
      await tester.tap(find.byKey(const Key('arrange-tile-tile_goes')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('arrange-tile-tile_from')));
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Check'));
      await tester.pump();
      expect(find.text('Incorrect'), findsOneWidget);
    });

    testWidgets(
      'removing a placed tile before submission returns it to the bank',
      (tester) async {
        await pumpGapExercise(tester, _gapFillExercise());
        await tester.tap(find.byKey(const Key('arrange-tile-tile_go')));
        await tester.pump();
        expect(find.byKey(const Key('arrange-tile-tile_go')), findsNothing);

        await tester.tap(find.byKey(const Key('gap-remove-verb_gap')));
        await tester.pump();
        expect(find.byKey(const Key('arrange-tile-tile_go')), findsOneWidget);
        expect(
          tester
              .widget<FilledButton>(find.widgetWithText(FilledButton, 'Check'))
              .onPressed,
          isNull,
        );
      },
    );

    testWidgets('moving a tile from one gap to another swaps their contents', (
      tester,
    ) async {
      await pumpGapExercise(tester, _gapFillExercise());
      // Fill both gaps: verb_gap=go, prep_gap=to.
      await tester.tap(find.byKey(const Key('arrange-tile-tile_go')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('arrange-tile-tile_to')));
      await tester.pump();

      // Arm the verb_gap (tap its label), then tap prep_gap to swap.
      await tester.tap(find.byKey(const Key('gap-slot-verb_gap')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('gap-slot-prep_gap')));
      await tester.pump();

      // After swapping, verb_gap now holds "to" and prep_gap holds "go",
      // which no longer matches the required assignments.
      await tester.tap(find.widgetWithText(FilledButton, 'Check'));
      await tester.pump();
      expect(find.text('Incorrect'), findsOneWidget);
    });

    testWidgets('an audio prompt shows a manual Play audio button', (
      tester,
    ) async {
      await pumpGapExercise(tester, _gapFillExercise(tts: 'I go to school.'));
      expect(find.widgetWithText(FilledButton, 'Play audio'), findsOneWidget);
    });

    testWidgets('no audio prompt renders no Play audio button', (tester) async {
      await pumpGapExercise(tester, _gapFillExercise());
      expect(find.widgetWithText(FilledButton, 'Play audio'), findsNothing);
    });
  });
}
