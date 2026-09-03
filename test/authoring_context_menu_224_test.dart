import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Lesson menu exposes all actions and duplicates after source', (
    tester,
  ) async {
    final fixture = _fixture();
    final results = <Course?>[];
    await _openLessons(tester, fixture, results);

    await tester.tap(find.byKey(const ValueKey('lesson-actions-lesson_a')));
    await tester.pumpAndSettle();
    for (final label in const [
      'Edit',
      'Rename',
      'Delete',
      'Duplicate',
      'Preview',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Renamed Lesson');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Lesson 1: Renamed Lesson'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('lesson-actions-lesson_a')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();
    expect(find.text('Lesson 1: Renamed Lesson'), findsOneWidget);
    expect(find.text('Lesson 2: Renamed Lesson'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    final renamed = results.single!.lessons[0];
    final copy = results.single!.lessons[1];
    expect(renamed.lessonId, fixture.lesson.lessonId);
    expect(renamed.title, 'Renamed Lesson');
    expect(renamed.rounds.single.id, fixture.round.id);
    expect(renamed.sectionName, fixture.lesson.sectionName);
    expect(copy.lessonId, isNot(fixture.lesson.lessonId));
    expect(copy.rounds.single.id, isNot(fixture.round.id));
    expect(copy.rounds.single.exercises.single.id, isNot(fixture.exercise.id));
    expect(fixture.lesson.lessonId, 'lesson_a');
  });

  testWidgets('Round menu exposes all actions and duplicates after source', (
    tester,
  ) async {
    final fixture = _fixture();
    final results = <List<LearningRound>?>[];
    await _openRounds(tester, fixture, results);

    await tester.tap(find.byKey(const ValueKey('round-actions-round_a')));
    await tester.pumpAndSettle();
    for (final label in const [
      'Edit',
      'Rename',
      'Delete',
      'Duplicate',
      'Preview',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), '');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();
    expect(find.text('Round 1'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('round-actions-round_a')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();
    expect(find.text('Round 1'), findsOneWidget);
    expect(find.text('Round 2'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    final renamed = results.single![0];
    final copy = results.single![1];
    expect(renamed.id, fixture.round.id);
    expect(renamed.title, isEmpty);
    expect(renamed.exercises.single.id, fixture.exercise.id);
    expect(copy.id, isNot(fixture.round.id));
    expect(copy.exercises.single.id, isNot(fixture.exercise.id));
    expect(fixture.round.id, 'round_a');
  });

  testWidgets('Exercise menu keeps Edit and creates an independent duplicate', (
    tester,
  ) async {
    final fixture = _fixture();
    final results = <LearningRound?>[];
    await _openRoundEditor(tester, fixture, results);

    await tester.tap(find.byKey(const ValueKey('exercise-actions-exercise_a')));
    await tester.pumpAndSettle();
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Duplicate'), findsOneWidget);
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('round-publish')));
    await tester.pumpAndSettle();
    final copy = results.single!.exercises[1];
    expect(results.single!.exercises, hasLength(2));
    expect(copy.id, isNot(fixture.exercise.id));
    expect(
      copy.interaction.items.map((item) => item.id).toSet(),
      isNot(
        equals(
          fixture.exercise.interaction.items.map((item) => item.id).toSet(),
        ),
      ),
    );
    expect(
      copy.evaluation.correctItemIds.single,
      copy.interaction.items.first.id,
    );
    expect(fixture.exercise.evaluation.correctItemIds.single, 'answer_a');
  });
}

Future<void> _openLessons(
  WidgetTester tester,
  _Fixture fixture,
  List<Course?> results,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: FilledButton(
            onPressed: () async => results.add(
              await Navigator.of(context).push<Course>(
                MaterialPageRoute(
                  builder: (_) => LessonManagementScreen(
                    course: fixture.course,
                    userCourse: true,
                    initiallyLocked: false,
                  ),
                ),
              ),
            ),
            child: const Text('Open Lessons'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open Lessons'));
  await tester.pumpAndSettle();
}

Future<void> _openRounds(
  WidgetTester tester,
  _Fixture fixture,
  List<List<LearningRound>?> results,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: FilledButton(
            onPressed: () async => results.add(
              await Navigator.of(context).push<List<LearningRound>>(
                MaterialPageRoute(
                  builder: (_) => LessonRoundsScreen(
                    course: fixture.course,
                    lesson: fixture.lesson,
                  ),
                ),
              ),
            ),
            child: const Text('Open Rounds'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open Rounds'));
  await tester.pumpAndSettle();
}

Future<void> _openRoundEditor(
  WidgetTester tester,
  _Fixture fixture,
  List<LearningRound?> results,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: FilledButton(
            onPressed: () async => results.add(
              await Navigator.of(context).push<LearningRound>(
                MaterialPageRoute(
                  builder: (_) => RoundEditorScreen(
                    course: fixture.course,
                    lesson: fixture.lesson,
                    round: fixture.round,
                    roundIndex: 0,
                  ),
                ),
              ),
            ),
            child: const Text('Open Round'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open Round'));
  await tester.pumpAndSettle();
}

class _Fixture {
  const _Fixture(this.course, this.lesson, this.round, this.exercise);
  final Course course;
  final Lesson lesson;
  final LearningRound round;
  final Exercise exercise;
}

_Fixture _fixture() {
  final exercise = Exercise.v2(
    id: 'exercise_a',
    editorTemplate: 'choice',
    promptElements: const [PromptElement(type: 'text', text: 'Choose A')],
    interaction: const ExerciseInteraction(
      kind: 'select',
      items: [
        ExerciseItem(
          id: 'answer_a',
          content: [PromptElement(type: 'text', text: 'A')],
        ),
        ExerciseItem(
          id: 'answer_b',
          content: [PromptElement(type: 'text', text: 'B')],
        ),
      ],
    ),
    evaluation: const ExerciseEvaluation(
      kind: 'selected_items',
      correctItemIds: ['answer_a'],
    ),
  );
  final round = LearningRound(
    id: 'round_a',
    title: 'Round A',
    exercises: [exercise],
  );
  final lesson = Lesson(
    lessonId: 'lesson_a',
    title: 'Lesson A',
    rounds: [round],
  );
  final course = Course(
    courseId: 'course_a',
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Course',
    ttsLanguage: 'it-IT',
    version: '1',
    lessons: [lesson],
  );
  return _Fixture(course, lesson, round, exercise);
}
