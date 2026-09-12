import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/course_projects_screen.dart';
import 'package:quisquislingo_app/services/course_authoring_transfer_service.dart';
import 'package:quisquislingo_app/services/editor_display_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    EditorDisplayPreferences.resetForTesting();
  });

  testWidgets('Editor Help and direct ID controls cover every editor level', (
    tester,
  ) async {
    await _wide(tester);
    final course = _course();
    final lesson = course.lessons.first;
    final round = lesson.rounds.first;
    final exercise = round.exercises.first;
    final pages = <Widget>[
      CourseProjectsScreen(currentCourse: course),
      CourseEditorScreen(course: course, userCourse: true),
      LessonManagementScreen(course: course, initiallyLocked: false),
      LessonEditorScreen(course: course, lesson: lesson),
      LessonRoundsScreen(course: course, lesson: lesson),
      RoundEditorScreen(
        course: course,
        lesson: lesson,
        round: round,
        roundIndex: 0,
      ),
      ExerciseEditorScreen(
        exercise: exercise,
        title: 'Edit Exercise',
        isNew: false,
        course: course,
        lesson: lesson,
        round: round,
      ),
    ];
    for (final page in pages) {
      await tester.pumpWidget(MaterialApp(home: page));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Editor Help'), findsOneWidget, reason: '$page');
      expect(
        find.byTooltip('Internal IDs hidden. Tap to show'),
        findsOneWidget,
        reason: '$page',
      );
    }
  });

  testWidgets(
    'ID toggle is immediate, global, persistent and exposes full IDs',
    (tester) async {
      await _wide(tester);
      final course = _course(duplicateLessonTitles: true);
      await tester.pumpWidget(
        MaterialApp(
          home: LessonManagementScreen(course: course, initiallyLocked: false),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Lesson ID:'), findsNothing);
      await tester.tap(find.byKey(const Key('editor-internal-ids-toggle')));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Internal IDs shown. Tap to hide'), findsOneWidget);
      expect(find.text('Lesson ID: lesson-one'), findsOneWidget);
      expect(find.text('Lesson ID: lesson-two'), findsOneWidget);
      expect(find.byTooltip('lesson-one'), findsOneWidget);
      expect(find.byTooltip('lesson-two'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: LessonRoundsScreen(
            course: course,
            lesson: course.lessons.first,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Round ID: round-one'), findsOneWidget);

      EditorDisplayPreferences.resetForTesting();
      await tester.pumpWidget(
        MaterialApp(
          home: RoundEditorScreen(
            course: course,
            lesson: course.lessons.first,
            round: course.lessons.first.rounds.first,
            roundIndex: 0,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Internal IDs shown. Tap to hide'), findsOneWidget);
      expect(find.text('Exercise ID: exercise-one'), findsOneWidget);
      expect(find.text('Exercise ID: exercise-two'), findsOneWidget);
      await tester.tap(find.byKey(const Key('editor-internal-ids-toggle')));
      await tester.pumpAndSettle();
      expect(
        find.byTooltip('Internal IDs hidden. Tap to show'),
        findsOneWidget,
      );
      expect(find.textContaining('Exercise ID:'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('opening Help preserves unsaved Exercise input', (tester) async {
    await _wide(tester);
    final course = _course();
    final lesson = course.lessons.first;
    final round = lesson.rounds.first;
    await tester.pumpWidget(
      MaterialApp(
        home: ExerciseEditorScreen(
          exercise: round.exercises.first,
          title: 'Edit Exercise',
          isNew: false,
          course: course,
          lesson: lesson,
          round: round,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final prompt = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Prompt / instruction',
    );
    await tester.enterText(prompt, 'Unsaved prompt survives Help');
    await tester.tap(find.byKey(const Key('editor-help-action')));
    await tester.pumpAndSettle();
    expect(find.text('Editor Help'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(prompt).controller!.text,
      'Unsaved prompt survives Help',
    );
  });

  testWidgets(
    'new Exercise exposes its assigned ID before it has a list index',
    (tester) async {
      await _wide(tester);
      SharedPreferences.setMockInitialValues({
        EditorDisplayPreferences.showInternalIdsKey: true,
      });
      EditorDisplayPreferences.resetForTesting();
      final course = _course();
      final lesson = course.lessons.first;
      final round = lesson.rounds.first;
      final exercise = _exercise('new-exercise-id');
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: exercise,
            title: 'New Exercise',
            isNew: true,
            course: course,
            lesson: lesson,
            round: round,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Exercise ID: new-exercise-id'), findsOneWidget);
    },
  );

  testWidgets('Rename preserves the displayed Round ID', (tester) async {
    await _wide(tester);
    SharedPreferences.setMockInitialValues({
      EditorDisplayPreferences.showInternalIdsKey: true,
    });
    EditorDisplayPreferences.resetForTesting();
    final course = _course();
    final lesson = course.lessons.first;
    final round = lesson.rounds.first;
    await tester.pumpWidget(
      MaterialApp(
        home: RoundEditorScreen(
          course: course,
          lesson: lesson,
          round: round,
          roundIndex: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Round ID: round-one'), findsOneWidget);
    await tester.tap(find.byKey(const Key('round-rename-action')));
    await tester.pumpAndSettle();
    final titleField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Title, or Enter to skip',
    );
    await tester.enterText(titleField, 'Renamed Round');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Save'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Renamed Round'),
      ),
      findsOneWidget,
    );
    expect(find.text('Round ID: round-one'), findsOneWidget);
  });

  testWidgets('Move preserves and Copy replaces displayed Exercise IDs', (
    tester,
  ) async {
    await _wide(tester);
    SharedPreferences.setMockInitialValues({
      EditorDisplayPreferences.showInternalIdsKey: true,
    });
    EditorDisplayPreferences.resetForTesting();
    final service = CourseAuthoringTransferService(
      clock: () => DateTime.utc(2026, 9, 6, 12),
    );
    final original = _course();
    final moved = service.moveExercise(
      original,
      sourceLessonId: 'lesson-one',
      sourceRoundId: 'round-one',
      exerciseId: 'exercise-one',
      destinationLessonId: 'lesson-one',
      destinationRoundId: 'round-two',
    );
    final movedLesson = moved.lessons.first;
    final movedRound = movedLesson.rounds[1];
    await tester.pumpWidget(
      MaterialApp(
        home: RoundEditorScreen(
          course: moved,
          lesson: movedLesson,
          round: movedRound,
          roundIndex: 1,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Exercise ID: exercise-one'), findsOneWidget);

    final copied = service.copyExercise(
      moved,
      sourceLessonId: 'lesson-one',
      sourceRoundId: 'round-two',
      exerciseId: 'exercise-one',
      destinationLessonId: 'lesson-one',
      destinationRoundId: 'round-one',
    );
    final copiedLesson = copied.lessons.first;
    final copiedRound = copiedLesson.rounds.first;
    final copiedId = copiedRound.exercises.last.id;
    expect(copiedId, isNot('exercise-one'));
    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        home: RoundEditorScreen(
          course: copied,
          lesson: copiedLesson,
          round: copiedRound,
          roundIndex: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Exercise ID: $copiedId'), findsOneWidget);
    expect(find.text('Exercise ID: exercise-two'), findsOneWidget);
  });

  testWidgets('internal ID presentation remains safe at 320 px', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    SharedPreferences.setMockInitialValues({
      EditorDisplayPreferences.showInternalIdsKey: true,
    });
    EditorDisplayPreferences.resetForTesting();
    final course = _course(longIds: true);
    await tester.pumpWidget(
      MaterialApp(
        home: LessonManagementScreen(course: course, initiallyLocked: false),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Lesson ID:'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _wide(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1200, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Exercise _exercise(String id) => Exercise(
  id: id,
  type: 'choice',
  publicationState: PublicationState.published,
  updatedAt: DateTime.utc(2026, 9, 6),
  prompt: 'Translate this greeting',
  question: 'Choose the greeting.',
  answers: const ['Ciao', 'Casa'],
  correct: 0,
  tts: null,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);

Course _course({bool duplicateLessonTitles = false, bool longIds = false}) {
  final firstId = longIds
      ? 'lesson-${List.filled(180, 'x').join()}'
      : 'lesson-one';
  final first = Lesson(
    lessonId: firstId,
    title: 'Same title',
    rounds: [
      LearningRound(
        id: 'round-one',
        title: 'Round',
        exercises: [_exercise('exercise-one'), _exercise('exercise-two')],
      ),
      LearningRound(id: 'round-two', title: 'Other Round', exercises: const []),
    ],
  );
  return Course(
    courseId: 'diagnostics-course',
    publicationState: PublicationState.draft,
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Diagnostics course',
    ttsLanguage: 'it-IT',
    courseVersion: '1',
    lessons: [
      first,
      Lesson(
        lessonId: 'lesson-two',
        title: duplicateLessonTitles ? 'Same title' : 'Second title',
        rounds: const [],
      ),
    ],
  );
}
