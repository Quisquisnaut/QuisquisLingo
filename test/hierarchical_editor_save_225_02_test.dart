import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'course_editor_locked_user_hierarchy': false,
    });
  });

  for (final publication in PublicationState.values) {
    testWidgets(
      '${publication.name} Exercise save persists through Round and Lesson without repeated warnings',
      (tester) async {
        var persisted = _course();
        final service = CourseEditorService();
        await _open(
          tester,
          LessonEditorScreen(
            course: persisted,
            lesson: persisted.lessons.single,
            clock: () => DateTime.utc(2026, 9, 4, 14),
            onPersistLesson: (lesson) async {
              persisted = _replaceLesson(persisted, lesson);
              await service.saveUserCourse(persisted);
            },
          ),
        );

        await _openNestedExercise(tester);
        await tester.enterText(
          _field('Prompt / instruction'),
          'Saved child prompt',
        );
        await tester.scrollUntilVisible(
          find.byKey(
            Key(
              publication.isPublished
                  ? 'exercise-publish'
                  : 'exercise-save-draft',
            ),
          ),
          350,
          scrollable: _editorScroll(),
        );
        await tester.tap(
          find.byKey(
            Key(
              publication.isPublished
                  ? 'exercise-publish'
                  : 'exercise-save-draft',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(RoundEditorScreen), findsOneWidget);

        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('Unsaved changes'), findsNothing);
        expect(find.byType(LessonRoundsScreen), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('Unsaved changes'), findsNothing);
        expect(find.byType(LessonEditorScreen), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('Unsaved changes'), findsNothing);
        expect(find.byType(LessonEditorScreen), findsNothing);

        final reloaded = (await service.listUserCourses()).single;
        final exercise = reloaded.lessons.single.rounds.single.exercises.single;
        expect(exercise.prompt, 'Saved child prompt');
        expect(exercise.publicationState, publication);
        expect(exercise.updatedAt, DateTime.utc(2026, 9, 4, 14));
      },
    );
  }

  testWidgets('child save retains an independent Round title edit as dirty', (
    tester,
  ) async {
    final course = _course();
    LearningRound? persistedRound;
    await _open(
      tester,
      RoundEditorScreen(
        course: course,
        lesson: course.lessons.single,
        round: course.lessons.single.rounds.single,
        roundIndex: 0,
        clock: () => DateTime.utc(2026, 9, 4, 15),
        onPersistRound: (round) async => persistedRound = round,
      ),
    );

    await tester.tap(find.byTooltip('Rename round'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Title'), 'Independent title');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await _openExerciseFromRound(tester);
    await tester.enterText(_field('Prompt / instruction'), 'Saved child only');
    await tester.scrollUntilVisible(
      find.byKey(const Key('exercise-save-draft')),
      350,
      scrollable: _editorScroll(),
    );
    await tester.tap(find.byKey(const Key('exercise-save-draft')));
    await tester.pumpAndSettle();

    expect(persistedRound?.title, 'Original title');
    expect(persistedRound?.exercises.single.prompt, 'Saved child only');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsOneWidget);
    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();
    expect(find.byType(RoundEditorScreen), findsOneWidget);
  });

  testWidgets(
    'persistence failure keeps the Exercise and all ancestors dirty',
    (tester) async {
      final course = _course();
      await _open(
        tester,
        LessonEditorScreen(
          course: course,
          lesson: course.lessons.single,
          onPersistLesson: (_) async => throw StateError('disk full'),
        ),
      );
      await _openNestedExercise(tester);
      await tester.enterText(_field('Prompt / instruction'), 'Not persisted');
      await tester.scrollUntilVisible(
        find.byKey(const Key('exercise-save-draft')),
        350,
        scrollable: _editorScroll(),
      );
      await tester.tap(find.byKey(const Key('exercise-save-draft')));
      await tester.pumpAndSettle();

      expect(find.textContaining('Exercise was not saved:'), findsOneWidget);
      expect(find.byType(ExerciseEditorScreen), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Unsaved changes'), findsOneWidget);
      await tester.tap(find.text('Leave without saving'));
      await tester.pumpAndSettle();
      expect(find.byType(RoundEditorScreen), findsOneWidget);
    },
  );

  testWidgets('confirmed discard removes only edits made after a child save', (
    tester,
  ) async {
    final course = _course();
    LearningRound? persistedRound;
    await _open(
      tester,
      RoundEditorScreen(
        course: course,
        lesson: course.lessons.single,
        round: course.lessons.single.rounds.single,
        roundIndex: 0,
        onPersistRound: (round) async => persistedRound = round,
      ),
    );
    await _openExerciseFromRound(tester);
    await tester.enterText(_field('Prompt / instruction'), 'Persisted prompt');
    await tester.scrollUntilVisible(
      find.byKey(const Key('exercise-save-draft')),
      350,
      scrollable: _editorScroll(),
    );
    await tester.tap(find.byKey(const Key('exercise-save-draft')));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Rename round'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Title'), 'Discard this title');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsOneWidget);
    await tester.tap(find.text('Leave without saving'));
    await tester.pumpAndSettle();

    expect(find.byType(RoundEditorScreen), findsNothing);
    expect(persistedRound?.title, 'Original title');
    expect(persistedRound?.exercises.single.prompt, 'Persisted prompt');
  });
}

Future<void> _openNestedExercise(WidgetTester tester) async {
  final rounds = find.byKey(const Key('lesson-rounds-navigation'));
  await tester.scrollUntilVisible(
    rounds,
    300,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(rounds);
  await tester.pumpAndSettle();
  expect(find.byType(LessonRoundsScreen), findsOneWidget);
  await tester.tap(find.byKey(const ValueKey('round')));
  await tester.pumpAndSettle();
  await _openExerciseFromRound(tester);
}

Future<void> _openExerciseFromRound(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('exercise-actions-exercise')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Edit').last);
  await tester.pumpAndSettle();
  expect(find.byType(ExerciseEditorScreen), findsOneWidget);
}

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Finder _editorScroll() => find
    .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
    .first;

Future<void> _open(WidgetTester tester, Widget child) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 1400);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => FilledButton(
          onPressed: () => Navigator.of(
            context,
          ).push(MaterialPageRoute<void>(builder: (_) => child)),
          child: const Text('Open'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

Course _replaceLesson(Course course, Lesson lesson) => Course.fromJson({
  ...course.toJson(),
  'lessons': [lesson.toJson()],
});

Course _course() {
  final timestamp = DateTime.utc(2026, 9, 4, 10);
  final round = LearningRound(
    id: 'round',
    publicationState: PublicationState.draft,
    updatedAt: timestamp,
    title: 'Original title',
    exercises: [_choice(timestamp)],
  );
  final lesson = Lesson(
    lessonId: 'lesson',
    publicationState: PublicationState.draft,
    updatedAt: timestamp,
    title: 'Lesson',
    rounds: [round],
  );
  return Course(
    courseId: 'user_hierarchy',
    publicationState: PublicationState.draft,
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Hierarchy',
    ttsLanguage: 'it-IT',
    version: '1',
    lessons: [lesson],
  );
}

Exercise _choice(DateTime timestamp) => Exercise(
  id: 'exercise',
  publicationState: PublicationState.draft,
  updatedAt: timestamp,
  type: 'choice',
  prompt: 'Original prompt',
  question: 'Which answer is correct?',
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
