import 'support/test_directories.dart';
// QQL Build 238 Phase 2: focused tests for the linked-gap extension of the
// existing Select primitive. Tapping an option always fills the first
// remaining empty gap in layout order (or an explicitly armed gap),
// regardless of whether that option is actually correct for that gap —
// placement never depends on correctness, only correctness at Check time
// does. The same option is never consumed, so it can be tapped again to
// fill a later gap that also needs it.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A two-gap linked Select exercise: "___ she happy? ___ he late?" where a
/// single "Was" option is the required answer for both gaps, plus an unused
/// distractor option.
Exercise _linkedGapExercise() => Exercise.v2(
  id: 'select-gap-fill',
  updatedAt: DateTime.utc(2026, 9, 18),
  editorTemplate: 'choice',
  promptElements: const [],
  interaction: const ExerciseInteraction(
    kind: 'select',
    items: [
      ExerciseItem(
        id: 'item_was',
        content: [PromptElement(type: 'text', text: 'Was')],
      ),
      ExerciseItem(
        id: 'item_were',
        content: [PromptElement(type: 'text', text: 'Were')],
      ),
      ExerciseItem(
        id: 'item_perhaps',
        content: [PromptElement(type: 'text', text: 'Perhaps')],
      ),
    ],
    layout: [
      PromptElement(type: 'gap', text: 'gap_1'),
      PromptElement(type: 'text', text: 'she happy?'),
      PromptElement(type: 'gap', text: 'gap_2'),
      PromptElement(type: 'text', text: 'he late?'),
    ],
  ),
  evaluation: const ExerciseEvaluation(
    kind: 'selected_items',
    gapAssignments: {'gap_1': 'item_was', 'gap_2': 'item_was'},
  ),
);

/// A single-gap Select exercise: "Un ___" with one correct option ("gatto")
/// and two distractors ("cane", "passero") that are not the answer to any
/// gap — matching a common "fill in the blank" authoring shape.
Exercise _singleGapExercise() => Exercise.v2(
  id: 'select-gap-single',
  updatedAt: DateTime.utc(2026, 9, 18),
  editorTemplate: 'choice',
  promptElements: const [],
  interaction: const ExerciseInteraction(
    kind: 'select',
    items: [
      ExerciseItem(
        id: 'item_gatto',
        content: [PromptElement(type: 'text', text: 'gatto')],
      ),
      ExerciseItem(
        id: 'item_cane',
        content: [PromptElement(type: 'text', text: 'cane')],
      ),
      ExerciseItem(
        id: 'item_passero',
        content: [PromptElement(type: 'text', text: 'passero')],
      ),
    ],
    layout: [PromptElement(type: 'gap', text: 'gap_1')],
  ),
  evaluation: const ExerciseEvaluation(
    kind: 'selected_items',
    gapAssignments: {'gap_1': 'item_gatto'},
  ),
);

/// A two-gap Select exercise with two *different* correct answers: "I ___
/// going ___ London" requiring "am" then "to", plus an unused distractor.
/// Used to verify that filling both gaps with the right words but in the
/// wrong order is marked incorrect.
Exercise _twoAnswerGapExercise() => Exercise.v2(
  id: 'select-gap-two-answers',
  updatedAt: DateTime.utc(2026, 9, 18),
  editorTemplate: 'choice',
  promptElements: const [],
  interaction: const ExerciseInteraction(
    kind: 'select',
    items: [
      ExerciseItem(
        id: 'item_am',
        content: [PromptElement(type: 'text', text: 'am')],
      ),
      ExerciseItem(
        id: 'item_to',
        content: [PromptElement(type: 'text', text: 'to')],
      ),
      ExerciseItem(
        id: 'item_is',
        content: [PromptElement(type: 'text', text: 'is')],
      ),
    ],
    layout: [
      PromptElement(type: 'text', text: 'I'),
      PromptElement(type: 'gap', text: 'gap_1'),
      PromptElement(type: 'text', text: 'going'),
      PromptElement(type: 'gap', text: 'gap_2'),
      PromptElement(type: 'text', text: 'London'),
    ],
  ),
  evaluation: const ExerciseEvaluation(
    kind: 'selected_items',
    gapAssignments: {'gap_1': 'item_am', 'gap_2': 'item_to'},
  ),
);

/// An unmodified legacy single-select Choice exercise (no gaps).
Exercise _legacyChoiceExercise() => Exercise(
  id: 'legacy-choice',
  updatedAt: DateTime.utc(2026, 9, 18),
  type: 'choice',
  prompt: 'Good morning',
  question: '',
  answers: const ['Buongiorno', 'Buonanotte'],
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
    test('gap layout and gap assignments round-trip through JSON', () {
      final exercise = _linkedGapExercise();
      final json = exercise.toJson();
      final restored = Exercise.fromV2Json(
        json,
        contentId: exercise.id,
        editorTemplate: exercise.editorTemplate,
        publicationState: exercise.publicationState,
      );
      expect(restored.hasSelectGaps, isTrue);
      expect(
        restored.arrangeLayout.map((e) => '${e.type}:${e.text}'),
        exercise.arrangeLayout.map((e) => '${e.type}:${e.text}'),
      );
      expect(restored.arrangeGapAssignments, exercise.arrangeGapAssignments);
      // Both gaps require the same linked option.
      expect(restored.arrangeGapAssignments.values.toSet(), {'item_was'});
    });

    test('legacy single-select Choice exercises have no gaps', () {
      final exercise = _legacyChoiceExercise();
      expect(exercise.hasSelectGaps, isFalse);
      expect(exercise.arrangeLayout, isEmpty);
    });
  });

  group('audit', () {
    test('a valid linked-gap Select exercise has no issues', () {
      final issues = CourseAuditService().auditExercise(_linkedGapExercise());
      expect(issues, isEmpty);
    });

    test('a gap without an assignment is flagged', () {
      final exercise = Exercise.v2(
        id: 'bad-gap',
        updatedAt: DateTime.utc(2026, 9, 18),
        editorTemplate: 'choice',
        promptElements: const [],
        interaction: const ExerciseInteraction(
          kind: 'select',
          items: [
            ExerciseItem(
              id: 'item_was',
              content: [PromptElement(type: 'text', text: 'Was')],
            ),
          ],
          layout: [
            PromptElement(type: 'gap', text: 'gap_1'),
            PromptElement(type: 'text', text: 'she happy?'),
          ],
        ),
        evaluation: const ExerciseEvaluation(kind: 'selected_items'),
      );
      final issues = CourseAuditService().auditExercise(exercise);
      expect(issues, isNotEmpty);
    });

    test('more than 2 unused distractor options is flagged', () {
      final exercise = Exercise.v2(
        id: 'too-many-distractors',
        updatedAt: DateTime.utc(2026, 9, 18),
        editorTemplate: 'choice',
        promptElements: const [],
        interaction: const ExerciseInteraction(
          kind: 'select',
          items: [
            ExerciseItem(
              id: 'item_was',
              content: [PromptElement(type: 'text', text: 'Was')],
            ),
            ExerciseItem(
              id: 'item_a',
              content: [PromptElement(type: 'text', text: 'a')],
            ),
            ExerciseItem(
              id: 'item_b',
              content: [PromptElement(type: 'text', text: 'b')],
            ),
            ExerciseItem(
              id: 'item_c',
              content: [PromptElement(type: 'text', text: 'c')],
            ),
          ],
          layout: [
            PromptElement(type: 'gap', text: 'gap_1'),
            PromptElement(type: 'text', text: 'she happy?'),
          ],
        ),
        evaluation: const ExerciseEvaluation(
          kind: 'selected_items',
          gapAssignments: {'gap_1': 'item_was'},
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
      await ProfileService().addProfile('Select Gap Learner');
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
        title: 'Select gaps',
        rounds: [round],
      );
      final course = Course(
        courseId: 'select-gap-course',
        learningLanguage: 'English',
        interfaceLanguage: 'English',
        sourceLanguage: 'English',
        targetLanguage: 'English',
        title: 'Select gaps',
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
      'tapping the same correct option twice fills both gaps in order and marks Correct',
      (tester) async {
        await pumpExercise(tester, _linkedGapExercise());
        final check = find.widgetWithText(FilledButton, 'Check');
        expect(tester.widget<FilledButton>(check).onPressed, isNull);

        // First tap fills only the first empty gap.
        await tester.tap(find.byKey(const Key('select-gap-option-item_was')));
        await tester.pump();
        expect(tester.widget<FilledButton>(check).onPressed, isNull);

        // Second tap of the same (never-consumed) option fills the next
        // remaining empty gap.
        await tester.tap(find.byKey(const Key('select-gap-option-item_was')));
        await tester.pump();

        expect(tester.widget<FilledButton>(check).onPressed, isNotNull);
        await tester.tap(check);
        await tester.pump();
        expect(find.text('Correct'), findsOneWidget);
      },
    );

    testWidgets(
      'selecting one wrong option fills only the first empty gap, leaving Check disabled',
      (tester) async {
        await pumpExercise(tester, _linkedGapExercise());
        await tester.tap(find.byKey(const Key('select-gap-option-item_were')));
        await tester.pump();
        // "Were" is not required by any gap, so it falls back to filling
        // only the first empty gap; the second gap is still blank. "Were"
        // now shows both as the (still-selected) option chip and inside
        // gap_1's slot.
        expect(
          find.descendant(
            of: find.byKey(const Key('select-gap-slot-gap_1')),
            matching: find.text('Were'),
          ),
          findsOneWidget,
        );
        final check = find.widgetWithText(FilledButton, 'Check');
        expect(tester.widget<FilledButton>(check).onPressed, isNull);
      },
    );

    testWidgets(
      'selecting two different wrong options fills both gaps and marks Incorrect',
      (tester) async {
        await pumpExercise(tester, _linkedGapExercise());
        await tester.tap(find.byKey(const Key('select-gap-option-item_were')));
        await tester.pump();
        await tester.tap(
          find.byKey(const Key('select-gap-option-item_perhaps')),
        );
        await tester.pump();
        final check = find.widgetWithText(FilledButton, 'Check');
        expect(tester.widget<FilledButton>(check).onPressed, isNotNull);
        await tester.tap(check);
        await tester.pump();
        expect(find.text('Incorrect'), findsOneWidget);
      },
    );

    testWidgets(
      'removing a placed option via the gap remove control empties it again',
      (tester) async {
        await pumpExercise(tester, _linkedGapExercise());
        await tester.tap(find.byKey(const Key('select-gap-option-item_was')));
        await tester.pump();
        await tester.tap(find.byKey(const Key('select-gap-option-item_was')));
        await tester.pump();
        final check = find.widgetWithText(FilledButton, 'Check');
        expect(tester.widget<FilledButton>(check).onPressed, isNotNull);

        await tester.tap(find.byKey(const Key('select-gap-remove-gap_1')));
        await tester.pump();
        expect(tester.widget<FilledButton>(check).onPressed, isNull);
      },
    );

    testWidgets('arming a specific gap lets an option fill it out of order', (
      tester,
    ) async {
      await pumpExercise(tester, _twoAnswerGapExercise());
      // Arm gap_2 first, then tap "am": it fills gap_2, not the
      // otherwise-first gap_1.
      await tester.tap(find.byKey(const Key('select-gap-slot-gap_2')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('select-gap-option-item_am')));
      await tester.pump();
      expect(
        find.descendant(
          of: find.byKey(const Key('select-gap-slot-gap_2')),
          matching: find.text('am'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('select-gap-slot-gap_1')),
          matching: find.text('___'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('the right options in the wrong gaps are marked Incorrect', (
      tester,
    ) async {
      await pumpExercise(tester, _twoAnswerGapExercise());
      // "to" goes into gap_1 (needs "am"); "am" goes into gap_2 (needs
      // "to") — both gaps end up filled but swapped.
      await tester.tap(find.byKey(const Key('select-gap-option-item_to')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('select-gap-option-item_am')));
      await tester.pump();
      final check = find.widgetWithText(FilledButton, 'Check');
      expect(tester.widget<FilledButton>(check).onPressed, isNotNull);
      await tester.tap(check);
      await tester.pump();
      expect(find.text('Incorrect'), findsOneWidget);
    });

    testWidgets('the right options in the right gaps are marked Correct', (
      tester,
    ) async {
      await pumpExercise(tester, _twoAnswerGapExercise());
      await tester.tap(find.byKey(const Key('select-gap-option-item_am')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('select-gap-option-item_to')));
      await tester.pump();
      final check = find.widgetWithText(FilledButton, 'Check');
      await tester.tap(check);
      await tester.pump();
      expect(find.text('Correct'), findsOneWidget);
    });

    testWidgets(
      'a single-gap exercise: picking a distractor fills the blank and marks Incorrect',
      (tester) async {
        await pumpExercise(tester, _singleGapExercise());
        final check = find.widgetWithText(FilledButton, 'Check');
        expect(tester.widget<FilledButton>(check).onPressed, isNull);

        await tester.tap(find.byKey(const Key('select-gap-option-item_cane')));
        await tester.pump();
        expect(
          find.descendant(
            of: find.byKey(const Key('select-gap-slot-gap_1')),
            matching: find.text('cane'),
          ),
          findsOneWidget,
        );
        expect(tester.widget<FilledButton>(check).onPressed, isNotNull);

        await tester.tap(check);
        await tester.pump();
        expect(find.text('Incorrect'), findsOneWidget);
      },
    );

    testWidgets(
      'a single-gap exercise: picking the correct option fills the blank and marks Correct',
      (tester) async {
        await pumpExercise(tester, _singleGapExercise());
        await tester.tap(find.byKey(const Key('select-gap-option-item_gatto')));
        await tester.pump();
        final check = find.widgetWithText(FilledButton, 'Check');
        expect(tester.widget<FilledButton>(check).onPressed, isNotNull);
        await tester.tap(check);
        await tester.pump();
        expect(find.text('Correct'), findsOneWidget);
      },
    );

    testWidgets(
      'a single-gap exercise: removing a placed distractor re-empties the blank',
      (tester) async {
        await pumpExercise(tester, _singleGapExercise());
        await tester.tap(find.byKey(const Key('select-gap-option-item_cane')));
        await tester.pump();
        final check = find.widgetWithText(FilledButton, 'Check');
        expect(tester.widget<FilledButton>(check).onPressed, isNotNull);

        await tester.tap(find.byKey(const Key('select-gap-remove-gap_1')));
        await tester.pump();
        expect(tester.widget<FilledButton>(check).onPressed, isNull);
      },
    );
  });
}
