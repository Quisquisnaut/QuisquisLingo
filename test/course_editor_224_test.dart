import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/editor_help_screen.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
          (_) async =>
              throw PlatformException(code: 'test_storage_unavailable'),
        );
  });

  testWidgets('main Course Editor uses a compact Lessons navigation row', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CourseEditorScreen(course: _course(), userCourse: true),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('course-editor-lessons-navigation')),
      findsOneWidget,
    );
    expect(find.text('2 Lessons'), findsOneWidget);
    expect(find.text('Lesson 1: First Lesson'), findsNothing);
    expect(find.text('Lock'), findsNothing);
  });

  testWidgets('Lessons subpage puts Lock first and preserves Lesson IDs', (
    tester,
  ) async {
    final course = _course();
    await tester.pumpWidget(
      MaterialApp(home: CourseEditorScreen(course: course, userCourse: true)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('course-editor-lessons-navigation')));
    await tester.pumpAndSettle();

    expect(find.byType(LessonManagementScreen), findsOneWidget);
    expect(find.byKey(const Key('lesson-management-lock')), findsOneWidget);
    expect(find.byKey(const Key('lesson-management-list')), findsOneWidget);
    expect(find.text('Lesson 1: First Lesson'), findsOneWidget);
    expect(find.byKey(const ValueKey('stable_lesson_one')), findsOneWidget);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lesson 1: First Lesson'));
    await tester.pumpAndSettle();
    expect(find.byType(LessonEditorScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('course-editor-lessons-navigation')),
      findsOneWidget,
    );
  });

  testWidgets('Lesson creation preserves draft Course metadata', (
    tester,
  ) async {
    final course = _course();
    await CourseEditorService().saveUserCourse(course);
    final routeResults = <Course?>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () async {
                routeResults.add(
                  await Navigator.of(context).push<Course>(
                    MaterialPageRoute(
                      builder: (_) => LessonManagementScreen(
                        course: course,
                        userCourse: true,
                        initiallyLocked: false,
                      ),
                    ),
                  ),
                );
              },
              child: const Text('Open Lessons'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Lessons'));
    await tester.pumpAndSettle();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FloatingActionButton, 'New lesson'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Third Lesson');
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await tester.pumpAndSettle();

    expect(find.text('Lesson 3: Third Lesson'), findsOneWidget);
    final saved = (await CourseEditorService().listUserCourses()).single;
    expect(saved.title, 'Draft Course Metadata');
    expect(saved.courseDescription, 'Unsaved-looking draft metadata');
    expect(
      saved.lessons.map((lesson) => lesson.lessonId),
      containsAll(['stable_lesson_one', 'stable_lesson_two']),
    );
    expect(saved.lessons, hasLength(2));

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(routeResults, hasLength(1));
    final draft = routeResults.single!;
    expect(draft.title, 'Draft Course Metadata');
    expect(draft.courseDescription, 'Unsaved-looking draft metadata');
    expect(draft.lessons.last.title, 'Third Lesson');
    expect(draft.lessons.take(2).map((lesson) => lesson.lessonId), [
      'stable_lesson_one',
      'stable_lesson_two',
    ]);
  });

  testWidgets('preset picker is grouped, searchable and links to Help', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ExerciseEditorScreen(
          exercise: _blankExercise(),
          title: 'New exercise',
          isNew: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('exercise-preset-selector')));
    await tester.pumpAndSettle();
    expect(find.text('Multiple choice'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('exercise-preset-search')),
      'translation',
    );
    await tester.pump();
    expect(find.text('Translation'), findsOneWidget);
    expect(find.text('Type the translation'), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('exercise-preset-search')),
      'contextual',
    );
    await tester.pump();
    expect(find.text('Contextual comprehension'), findsOneWidget);
    await tester.tap(find.text('Contextual comprehension'));
    await tester.pumpAndSettle();
    expect(find.text('Context mode'), findsOneWidget);

    await tester.tap(find.text('Exercise Help'));
    await tester.pumpAndSettle();
    expect(find.byType(ExerciseHelpScreen), findsOneWidget);
  });

  testWidgets('Course Editor and Lessons subpage do not overflow at 320 px', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: CourseEditorScreen(course: _course(), userCourse: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(
      find.byKey(const Key('course-editor-lessons-navigation')),
    );
    await tester.tap(find.byKey(const Key('course-editor-lessons-navigation')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

Course _course() => Course(
  courseId: 'course_editor_224',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Draft Course Metadata',
  ttsLanguage: 'it-IT',
  version: '1',
  courseDescription: 'Unsaved-looking draft metadata',
  lessons: [
    Lesson(
      lessonId: 'stable_lesson_one',
      title: 'First Lesson',
      rounds: const [],
    ),
    Lesson(
      lessonId: 'stable_lesson_two',
      title: 'Second Lesson',
      rounds: const [],
    ),
  ],
);

Exercise _blankExercise() => Exercise(
  id: 'stable_new_exercise',
  type: 'choice',
  prompt: '',
  question: '',
  answers: const [],
  correct: null,
  tts: null,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: '',
  icons: const [],
);
