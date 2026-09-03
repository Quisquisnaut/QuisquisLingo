import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';

void main() {
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
  courseId: 'course',
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

Exercise _choice() => Exercise(
  id: 'exercise',
  publicationState: PublicationState.draft,
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
