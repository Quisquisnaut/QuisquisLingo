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
      'course_editor_locked_USER_COURSE': false,
      'audio_orphan_check_last_IT': DateTime(2026, 9, 3).toIso8601String(),
    });
  });

  testWidgets('Lesson dirty state uses the exact shared leave confirmation', (
    tester,
  ) async {
    await _open(
      tester,
      LessonEditorScreen(course: _course(), lesson: _course().lessons.single),
    );
    await tester.tap(find.byKey(const Key('lesson-title-control')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Changed title');
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsOneWidget);
    expect(
      find.text(
        'You have unsaved changes. Do you want to leave without saving?',
      ),
      findsOneWidget,
    );
    expect(find.text('Stay'), findsOneWidget);
    expect(find.text('Leave without saving'), findsOneWidget);
    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();
    expect(find.byType(LessonEditorScreen), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leave without saving'));
    await tester.pumpAndSettle();
    expect(find.byType(LessonEditorScreen), findsNothing);
  });

  testWidgets('untouched Lesson editor leaves without a warning', (
    tester,
  ) async {
    await _open(
      tester,
      LessonEditorScreen(course: _course(), lesson: _course().lessons.single),
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsNothing);
    expect(find.byType(LessonEditorScreen), findsNothing);
  });

  testWidgets('Exercise edits are protected by the shared guard', (
    tester,
  ) async {
    await _open(
      tester,
      ExerciseEditorScreen(
        exercise: _choice(),
        title: 'Edit exercise',
        isNew: false,
      ),
    );
    await tester.enterText(find.byType(TextField).first, 'Changed prompt');
    tester.testTextInput.hide();
    await tester.pump();
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsOneWidget);
    await tester.tap(find.text('Leave without saving'));
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseEditorScreen), findsNothing);
  });

  testWidgets('Course Save as Draft refreshes the persisted baseline', (
    tester,
  ) async {
    await _open(
      tester,
      CourseEditorScreen(course: _course(), userCourse: true),
    );
    await _markTemporarySample(tester);
    await tester.tap(find.byKey(const Key('course-save-draft')));
    await tester.pumpAndSettle();
    expect(find.text('Course saved as Draft.'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsNothing);
    expect(find.byType(CourseEditorScreen), findsNothing);
  });

  testWidgets('Course Publish refreshes the persisted baseline', (
    tester,
  ) async {
    await _open(
      tester,
      CourseEditorScreen(course: _course(), userCourse: true),
    );
    await _markTemporarySample(tester);
    await tester.tap(find.byKey(const Key('course-publish')));
    await tester.pumpAndSettle();
    expect(find.text('Course published.'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsNothing);
    expect(find.byType(CourseEditorScreen), findsNothing);
  });

  testWidgets('failed Course persistence leaves the Editor dirty', (
    tester,
  ) async {
    await _open(
      tester,
      CourseEditorScreen(
        course: _course(),
        userCourse: true,
        editorService: _FailingCourseEditorService(),
      ),
    );
    await _markTemporarySample(tester);
    await tester.tap(find.byKey(const Key('course-save-draft')));
    await tester.pumpAndSettle();
    expect(find.textContaining('Could not save Course:'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsOneWidget);
  });

  testWidgets('Lesson Save as Draft exits without an unsaved warning', (
    tester,
  ) async {
    await _open(
      tester,
      LessonEditorScreen(course: _course(), lesson: _course().lessons.single),
    );
    await tester.tap(find.byKey(const Key('lesson-title-control')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Saved title');
    await tester.tap(find.text('Save').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-lesson-draft')));
    await tester.pumpAndSettle();

    expect(find.text('Unsaved changes'), findsNothing);
    expect(find.byType(LessonEditorScreen), findsNothing);
  });

  testWidgets('Round Publish exits without an unsaved warning', (tester) async {
    final course = _roundCourse();
    await _open(
      tester,
      RoundEditorScreen(
        course: course,
        lesson: course.lessons.single,
        round: course.lessons.single.rounds.single,
        roundIndex: 0,
      ),
    );
    await tester.tap(find.byKey(const ValueKey('exercise-actions-exercise')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('round-publish')));
    await tester.pumpAndSettle();

    expect(find.text('Unsaved changes'), findsNothing);
    expect(find.byType(RoundEditorScreen), findsNothing);
  });

  testWidgets('failed Exercise publish keeps edits dirty', (tester) async {
    await _open(
      tester,
      ExerciseEditorScreen(
        exercise: _choice(),
        title: 'Edit exercise',
        isNew: false,
      ),
    );
    await tester.enterText(_field('Answers'), '');
    await tester.scrollUntilVisible(
      find.byKey(const Key('exercise-publish')),
      300,
      scrollable: _editorScroll(),
    );
    await tester.tap(find.byKey(const Key('exercise-publish')));
    await tester.pumpAndSettle();
    expect(find.text('Choose a valid correct answer number.'), findsOneWidget);

    tester.testTextInput.hide();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsOneWidget);
  });

  testWidgets('an edit made after an Exercise save is protected', (
    tester,
  ) async {
    Exercise? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              saved = await Navigator.of(context).push<Exercise>(
                MaterialPageRoute(
                  builder: (_) => ExerciseEditorScreen(
                    exercise: saved ?? _choice(),
                    title: 'Edit exercise',
                    isNew: false,
                  ),
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Prompt / instruction'), 'Saved prompt');
    await tester.scrollUntilVisible(
      find.byKey(const Key('exercise-save-draft')),
      300,
      scrollable: _editorScroll(),
    );
    await tester.tap(find.byKey(const Key('exercise-save-draft')));
    await tester.pumpAndSettle();
    expect(saved, isNotNull);

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.enterText(_field('Prompt / instruction'), 'Changed again');
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Unsaved changes'), findsOneWidget);
    expect(
      tester.widget<TextField>(_field('Prompt / instruction')).controller?.text,
      'Changed again',
    );
  });
}

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Finder _editorScroll() => find
    .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
    .first;

Future<void> _markTemporarySample(WidgetTester tester) async {
  await tester.tap(find.byType(PopupMenuButton<String>).first);
  await tester.pumpAndSettle();
  await tester.tap(find.text('Mark TEMPORARY SAMPLE'));
  await tester.pumpAndSettle();
}

Future<void> _open(WidgetTester tester, Widget child) async {
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

Course _course() => Course(
  courseId: 'user_course',
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Course',
  ttsLanguage: 'it-IT',
  version: '1',
  lessons: [
    Lesson(
      lessonId: 'lesson',
      publicationState: PublicationState.draft,
      title: 'Lesson',
      rounds: const [],
    ),
  ],
);

Course _roundCourse() {
  final round = LearningRound(
    id: 'round',
    publicationState: PublicationState.draft,
    title: 'Round',
    exercises: [_choice(publicationState: PublicationState.published)],
  );
  final lesson = Lesson(
    lessonId: 'lesson',
    publicationState: PublicationState.draft,
    title: 'Lesson',
    rounds: [round],
  );
  return Course(
    courseId: 'user_course',
    publicationState: PublicationState.draft,
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Course',
    ttsLanguage: 'it-IT',
    version: '1',
    lessons: [lesson],
  );
}

class _FailingCourseEditorService extends CourseEditorService {
  @override
  Future<void> saveUserCourse(Course course) async {
    throw StateError('test persistence failure');
  }
}

Exercise _choice({
  PublicationState publicationState = PublicationState.draft,
}) => Exercise(
  id: 'exercise',
  publicationState: publicationState,
  type: 'choice',
  prompt: 'Choose',
  question: 'Question',
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
