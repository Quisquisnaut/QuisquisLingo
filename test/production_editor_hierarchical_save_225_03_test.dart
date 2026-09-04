import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'course_editor_locked_SAMPLE_IT_EN_IT': false,
      'course_editor_locked_USER_HIERARCHY_METADATA': false,
    });
  });

  testWidgets(
    'production Course to Exercise route persists a Draft child without parent prompts',
    (tester) async {
      final service = CourseEditorService();
      final course = (await tester.runAsync(
        () => CourseService().loadCourse('IT'),
      ))!;
      final lesson = course.lessons.first;
      final round = lesson.rounds.first;
      final exercise = round.exercises.first;

      await _openCourseEditor(
        tester,
        course,
        service,
        expectSampleNotice: true,
      );
      await _openExercise(tester, lesson, round, exercise);
      await tester.enterText(
        _field('Prompt / instruction'),
        'Persisted through the complete production route',
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('exercise-save-draft')),
        350,
        scrollable: _editorScroll(),
      );
      await tester.tap(find.byKey(const Key('exercise-save-draft')));
      await _settle(tester);
      expect(find.text('Move Exercise to Draft?'), findsOneWidget);
      await tester.tap(find.text('Move to Draft'));
      await _settle(tester);
      expect(find.byType(RoundEditorScreen), findsOneWidget);

      await _backWithoutUnsavedDialog(tester);
      expect(find.byType(LessonRoundsScreen), findsOneWidget);
      await _backWithoutUnsavedDialog(tester);
      expect(find.byType(LessonEditorScreen), findsOneWidget);
      await _backWithoutUnsavedDialog(tester);
      expect(find.byType(LessonManagementScreen), findsOneWidget);
      await _backWithoutUnsavedDialog(tester);
      expect(find.byType(CourseEditorScreen), findsOneWidget);
      await _backWithoutUnsavedDialog(tester);
      expect(find.byType(CourseEditorScreen), findsNothing);

      final reloaded = (await tester.runAsync(
        () => CourseService().loadCourse('IT'),
      ))!;
      final saved = reloaded.lessons
          .singleWhere((candidate) => candidate.lessonId == lesson.lessonId)
          .rounds
          .singleWhere((candidate) => candidate.id == round.id)
          .exercises
          .singleWhere((candidate) => candidate.id == exercise.id);
      expect(saved.prompt, 'Persisted through the complete production route');
      expect(saved.publicationState, PublicationState.draft);
    },
  );

  for (final publication in PublicationState.values) {
    testWidgets(
      '${publication.name} Exercise save persists through the production route without parent prompts',
      (tester) async {
        final service = CourseEditorService();
        final course = _metadataCourse();
        await tester.runAsync(() => service.saveUserCourse(course));
        final lesson = course.lessons.single;
        final round = lesson.rounds.single;
        final exercise = round.exercises.first;
        final prompt = '${publication.name} persisted prompt';

        await _openCourseEditor(tester, course, service, userCourse: true);
        await _openExercise(tester, lesson, round, exercise);
        await tester.enterText(_field('Prompt / instruction'), prompt);
        await _saveExercise(tester, publication);
        expect(find.byType(RoundEditorScreen), findsOneWidget);

        await _backWithoutUnsavedDialog(tester);
        expect(find.byType(LessonRoundsScreen), findsOneWidget);
        await _backWithoutUnsavedDialog(tester);
        expect(find.byType(LessonEditorScreen), findsOneWidget);
        await _backWithoutUnsavedDialog(tester);
        expect(find.byType(LessonManagementScreen), findsOneWidget);
        await _backWithoutUnsavedDialog(tester);
        expect(find.byType(CourseEditorScreen), findsOneWidget);
        await _backWithoutUnsavedDialog(tester);
        expect(find.byType(CourseEditorScreen), findsNothing);

        final reloaded = (await service.listUserCourses()).single;
        final savedRound = reloaded.lessons.single.rounds.single;
        final saved = savedRound.exercises.singleWhere(
          (candidate) => candidate.id == exercise.id,
        );
        expect(saved.prompt, prompt);
        expect(saved.publicationState, publication);
        expect(savedRound.content.first.sourceRefs, ['guidebook-source']);
        expect(savedRound.content.last.sourceRefs, ['second-guidebook-source']);
      },
    );
  }

  testWidgets(
    'independent Round edit after Exercise save still warns and discards only that edit',
    (tester) async {
      final service = CourseEditorService();
      final course = _metadataCourse();
      await tester.runAsync(() => service.saveUserCourse(course));
      final lesson = course.lessons.single;
      final round = lesson.rounds.single;
      final exercise = round.exercises.first;

      await _openCourseEditor(tester, course, service, userCourse: true);
      await _openExercise(tester, lesson, round, exercise);
      await tester.enterText(_field('Prompt / instruction'), 'Saved child');
      await _saveExercise(tester, PublicationState.draft);

      await tester.tap(find.byTooltip('Rename round'));
      await _settle(tester);
      await tester.enterText(_field('Title'), 'Unsaved Round title');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await _settle(tester);
      await tester.tap(find.byType(BackButton).last);
      await _settle(tester);
      expect(find.text('Unsaved changes'), findsOneWidget);
      await tester.tap(find.text('Stay'));
      await _settle(tester);
      expect(find.byType(RoundEditorScreen), findsOneWidget);
      expect(find.text('Unsaved Round title'), findsOneWidget);

      await tester.tap(find.byType(BackButton).last);
      await _settle(tester);
      await tester.tap(find.text('Leave without saving'));
      await _settle(tester);
      expect(find.byType(LessonRoundsScreen), findsOneWidget);

      final reloaded = (await service.listUserCourses()).single;
      final savedRound = reloaded.lessons.single.rounds.single;
      expect(savedRound.title, 'Metadata round');
      expect(savedRound.exercises.first.prompt, 'Saved child');
    },
  );

  testWidgets(
    'independent Lesson edit after Exercise save still warns and discards only that edit',
    (tester) async {
      final service = CourseEditorService();
      final course = _metadataCourse();
      await tester.runAsync(() => service.saveUserCourse(course));
      final lesson = course.lessons.single;
      final round = lesson.rounds.single;
      final exercise = round.exercises.first;

      await _openCourseEditor(tester, course, service, userCourse: true);
      await _openExercise(tester, lesson, round, exercise);
      await tester.enterText(_field('Prompt / instruction'), 'Saved child');
      await _saveExercise(tester, PublicationState.draft);
      await _backWithoutUnsavedDialog(tester);
      await _backWithoutUnsavedDialog(tester);
      expect(find.byType(LessonEditorScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Rename lesson'));
      await _settle(tester);
      await tester.enterText(_field('Title'), 'Unsaved Lesson title');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await _settle(tester);
      await tester.tap(find.byType(BackButton).last);
      await _settle(tester);
      expect(find.text('Unsaved changes'), findsOneWidget);
      await tester.tap(find.text('Stay'));
      await _settle(tester);
      expect(find.byType(LessonEditorScreen), findsOneWidget);
      expect(find.text('Unsaved Lesson title'), findsWidgets);

      await tester.tap(find.byType(BackButton).last);
      await _settle(tester);
      await tester.tap(find.text('Leave without saving'));
      await _settle(tester);
      expect(find.byType(LessonManagementScreen), findsOneWidget);

      final reloaded = (await service.listUserCourses()).single;
      expect(reloaded.lessons.single.title, 'Metadata lesson');
      expect(
        reloaded.lessons.single.rounds.single.exercises.first.prompt,
        'Saved child',
      );
    },
  );

  testWidgets(
    'failed Exercise persistence remains dirty and Cancel preserves the edit',
    (tester) async {
      final storage = CourseEditorService();
      final course = _metadataCourse();
      await tester.runAsync(() => storage.saveUserCourse(course));
      final failing = _FailingCourseEditorService();
      final lesson = course.lessons.single;
      final round = lesson.rounds.single;
      final exercise = round.exercises.first;

      await _openCourseEditor(tester, course, failing, userCourse: true);
      await _openExercise(tester, lesson, round, exercise);
      await tester.enterText(
        _field('Prompt / instruction'),
        'Unsaved after failure',
      );
      await _saveExercise(tester, PublicationState.draft);
      expect(find.byType(ExerciseEditorScreen), findsOneWidget);
      expect(find.textContaining('Exercise was not saved:'), findsOneWidget);

      await tester.tap(find.byType(BackButton).last);
      await _settle(tester);
      expect(find.text('Unsaved changes'), findsOneWidget);
      await tester.tap(find.text('Stay'));
      await _settle(tester);
      expect(
        tester
            .widget<TextField>(_field('Prompt / instruction'))
            .controller!
            .text,
        'Unsaved after failure',
      );

      await tester.tap(find.byType(BackButton).last);
      await _settle(tester);
      await tester.tap(find.text('Leave without saving'));
      await _settle(tester);
      expect(find.byType(RoundEditorScreen), findsOneWidget);
      final reloaded = (await storage.listUserCourses()).single;
      expect(
        reloaded.lessons.single.rounds.single.exercises.first.prompt,
        'Original prompt',
      );
    },
  );
}

Future<void> _openCourseEditor(
  WidgetTester tester,
  Course course,
  CourseEditorService service, {
  bool userCourse = false,
  bool expectSampleNotice = false,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 1400);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => FilledButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CourseEditorScreen(
                course: course,
                userCourse: userCourse,
                editorService: service,
                clock: () => DateTime.utc(2026, 9, 4, 16),
              ),
            ),
          ),
          child: const Text('Open editor'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open editor'));
  await _settle(tester);
  if (expectSampleNotice) {
    expect(find.text('Temporary sample content'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await _settle(tester);
  }
}

Future<void> _openExercise(
  WidgetTester tester,
  Lesson lesson,
  LearningRound round,
  Exercise exercise,
) async {
  await tester.tap(find.byKey(const Key('course-editor-lessons-navigation')));
  await _settle(tester);
  expect(find.byType(LessonManagementScreen), findsOneWidget);
  await tester.tap(find.byKey(ValueKey(lesson.lessonId)));
  await _settle(tester);
  expect(find.byType(LessonEditorScreen), findsOneWidget);
  await tester.scrollUntilVisible(
    find.byKey(const Key('lesson-rounds-navigation')),
    300,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(find.byKey(const Key('lesson-rounds-navigation')));
  await _settle(tester);
  expect(find.byType(LessonRoundsScreen), findsOneWidget);
  await tester.tap(find.byKey(ValueKey(round.id)));
  await _settle(tester);
  expect(find.byType(RoundEditorScreen), findsOneWidget);
  await tester.tap(find.byKey(ValueKey('exercise-actions-${exercise.id}')));
  await _settle(tester);
  await tester.tap(find.text('Edit').last);
  await _settle(tester);
  expect(find.byType(ExerciseEditorScreen), findsOneWidget);
}

Future<void> _backWithoutUnsavedDialog(WidgetTester tester) async {
  await tester.tap(find.byType(BackButton).last);
  await _settle(tester);
  expect(find.text('Unsaved changes'), findsNothing);
}

Future<void> _saveExercise(
  WidgetTester tester,
  PublicationState publication,
) async {
  final key = publication.isPublished
      ? const Key('exercise-publish')
      : const Key('exercise-save-draft');
  await tester.scrollUntilVisible(
    find.byKey(key),
    350,
    scrollable: _editorScroll(),
  );
  await tester.tap(find.byKey(key));
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var frame = 0; frame < 12; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Finder _editorScroll() => find
    .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
    .first;

Course _metadataCourse() {
  final updatedAt = DateTime.utc(2026, 9, 4, 10);
  final exercise = Exercise(
    id: 'metadata-exercise',
    publicationState: PublicationState.draft,
    updatedAt: updatedAt,
    type: 'choice',
    prompt: 'Original prompt',
    question: 'Choose the answer.',
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
  final untouchedExercise = Exercise(
    id: 'metadata-exercise-untouched',
    publicationState: PublicationState.draft,
    updatedAt: updatedAt,
    type: 'choice',
    prompt: 'Untouched prompt',
    question: 'Choose another answer.',
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
  final round = LearningRound(
    id: 'metadata-round',
    publicationState: PublicationState.draft,
    updatedAt: updatedAt,
    title: 'Metadata round',
    content: [
      LearningContent(
        id: exercise.id,
        publicationState: exercise.publicationState,
        kind: 'exercise',
        required: false,
        editorTemplate: exercise.editorTemplate,
        exercise: exercise,
        sourceRefs: const ['guidebook-source'],
      ),
      LearningContent(
        id: untouchedExercise.id,
        publicationState: untouchedExercise.publicationState,
        kind: 'exercise',
        required: false,
        editorTemplate: untouchedExercise.editorTemplate,
        exercise: untouchedExercise,
        sourceRefs: const ['second-guidebook-source'],
      ),
    ],
  );
  return Course(
    courseId: 'user_hierarchy_metadata',
    publicationState: PublicationState.draft,
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Hierarchy metadata',
    ttsLanguage: 'it-IT',
    version: '1',
    lessons: [
      Lesson(
        lessonId: 'metadata-lesson',
        publicationState: PublicationState.draft,
        updatedAt: updatedAt,
        title: 'Metadata lesson',
        rounds: [round],
      ),
    ],
  );
}

class _FailingCourseEditorService extends CourseEditorService {
  @override
  Future<void> saveUserCourse(Course course) async {
    throw StateError('simulated storage failure');
  }
}
