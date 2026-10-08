import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/primitive_editor_screen.dart';
import 'package:quisquislingo_app/services/canonical_exercise_draft.dart';
import 'package:quisquislingo_app/services/canonical_exercise_samples.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Build 261 Revision 5 (owner review of 2 October 2026): reading answers
/// that do not copy the text and the Audit's READING_ANSWER_IN_TEXT; the
/// English course's ordinary Rounds without titles; Fill with an example in
/// the canonical editor.
final _stamp = DateTime.utc(2026, 10, 2, 12);

PromptElement _text(String value, String role, {TextLanguage? language}) =>
    PromptElement(type: 'text', text: value, role: role, language: language);

Exercise _select(String id, List<PromptElement> prompt, List<String> options) =>
    Exercise.canonical(
      id: id,
      updatedAt: _stamp,
      primitive: ExercisePrimitive.select,
      promptElements: prompt,
      items: [
        for (var i = 0; i < options.length; i++)
          ExerciseItem(id: '${id}_$i', content: [_text(options[i], 'primary')]),
      ],
      canonicalEvaluation: CanonicalEvaluation(
        mode: EvaluationMode.exactItem,
        correctItemIds: ['${id}_0'],
      ),
    );

List<String> _codes(Exercise exercise) => [
  for (final issue in CourseAuditService().auditExercise(exercise)) issue.code,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('reading answers', () {
    test('a reading answer copied from the text is a Warning', () {
      final copied = _select(
        'tom',
        [
          _text('Anna meets Tom in the morning.', 'context'),
          _text('Good morning, Anna! How are you?', 'dialogue_turn'),
          _text('What does Tom ask?', 'question'),
        ],
        ['How are you?', 'Good night!'],
      );
      expect(_codes(copied), contains('READING_ANSWER_IN_TEXT'));

      final reworded = _select(
        'tom2',
        [
          _text('Anna meets Tom in the morning.', 'context'),
          _text('Good morning, Anna! How are you?', 'dialogue_turn'),
          _text('What does Tom want to know?', 'question'),
        ],
        ['If Anna is well', 'Where Anna lives'],
      );
      expect(_codes(reworded), isNot(contains('READING_ANSWER_IN_TEXT')));
    });

    test('listening is not concerned', () {
      final listening = Exercise.canonical(
        id: 'listen',
        updatedAt: _stamp,
        primitive: ExercisePrimitive.select,
        promptElements: [
          PromptElement(
            type: 'audio',
            text: 'I have a cat and a dog.',
            role: 'passage',
          ),
          _text('Which animal comes first?', 'question'),
        ],
        items: [
          ExerciseItem(id: 'l_0', content: [_text('a cat', 'primary')]),
          ExerciseItem(id: 'l_1', content: [_text('a horse', 'primary')]),
        ],
        canonicalEvaluation: const CanonicalEvaluation(
          mode: EvaluationMode.exactItem,
          correctItemIds: ['l_0'],
        ),
      );
      expect(_codes(listening), isNot(contains('READING_ANSWER_IN_TEXT')));
    });

    test('no bundled Course copies a reading answer from its text', () async {
      for (final code in CourseService.courseAssets.keys) {
        final course = await CourseService().loadCourse(code);
        final codes = CourseAuditService()
            .auditCourse(course)
            .issues
            .map((issue) => issue.code);
        expect(codes, isNot(contains('READING_ANSWER_IN_TEXT')), reason: code);
      }
    });
  });

  test('the English course\'s ordinary Rounds have no title', () async {
    final course = await CourseService().loadCourse('EN_IT');
    final rounds = course.lessons.single.rounds;
    expect([
      for (final round in rounds)
        if (!round.isStory) round.title,
    ], everyElement(isEmpty));
    expect(
      [
        for (final round in rounds)
          if (round.isStory) round.displayTitle(0),
      ],
      ['Story: Al bar', 'Story: Alla stazione'],
    );
  });

  group('Fill with an example', () {
    test('every primitive has a legal example without Audit errors', () {
      for (final primitive in ExercisePrimitive.values) {
        final sample = CanonicalExerciseSamples.forPrimitive(
          primitive,
          id: 'sample_${primitive.name}',
          updatedAt: _stamp,
        );
        expect(sample.primitive, primitive);
        final draft = CanonicalExerciseDraft.fromExercise(sample);
        expect(draft.violations, isEmpty, reason: primitive.name);
        final errors = [
          for (final issue in CourseAuditService().auditExercise(sample))
            if (issue.severity == AuditSeverity.error) issue.code,
        ];
        expect(errors, isEmpty, reason: primitive.name);
        final playable = const {
          ExercisePrimitive.select,
          ExercisePrimitive.input,
          ExercisePrimitive.arrange,
          ExercisePrimitive.match,
          ExercisePrimitive.assign,
          ExercisePrimitive.presentation,
        }.contains(primitive);
        expect(sample.isExecutable, playable, reason: primitive.name);
      }
    });

    Future<void> pumpNew(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1000, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: PrimitiveEditorScreen(
            exercise: CanonicalExerciseDraft.blankExercise(
              ExercisePrimitive.select,
              id: 'new_one',
              updatedAt: _stamp,
            ),
            title: 'New Exercise',
            isNew: true,
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a blank new exercise fills at once', (tester) async {
      await pumpNew(tester);
      expect(find.text('Which animal barks?'), findsNothing);
      await tester.tap(find.byKey(const Key('primitive-fill-example')));
      await tester.pumpAndSettle();
      expect(find.text('Which animal barks?'), findsOneWidget);
      expect(find.text('the dog'), findsOneWidget);
    });

    testWidgets('a form with content asks before replacing it', (tester) async {
      await pumpNew(tester);
      await tester.tap(find.byKey(const Key('primitive-fill-example')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('primitive-fill-example')));
      await tester.pumpAndSettle();
      expect(find.text('Replace with an example?'), findsOneWidget);
      await tester.tap(find.byKey(const Key('primitive-fill-example-confirm')));
      await tester.pumpAndSettle();
      expect(find.text('Which animal barks?'), findsOneWidget);
    });

    testWidgets('an existing exercise offers no example', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PrimitiveEditorScreen(
            exercise: CanonicalExerciseSamples.forPrimitive(
              ExercisePrimitive.select,
              id: 'stored',
              updatedAt: _stamp,
            ),
            title: 'Exercise',
            isNew: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('primitive-fill-example')), findsNothing);
    });
  });
}
