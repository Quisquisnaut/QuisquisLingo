import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';

void main() {
  testWidgets(
    'nested Exercise save preserves hierarchy metadata and Round route results',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1200, 1500);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final original = _course();
      final originalLesson = original.lessons.single;
      final originalContent = originalLesson.rounds.single.content.single;
      Course? changedCourse;
      LearningRound? returnedRound;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                returnedRound = await Navigator.of(context).push<LearningRound>(
                  MaterialPageRoute(
                    builder: (_) => RoundEditorScreen(
                      course: original,
                      lesson: originalLesson,
                      round: originalLesson.rounds.single,
                      roundIndex: 0,
                      clock: () => DateTime.utc(2026, 9, 22, 12),
                      onCourseChanged: (course) => changedCourse = course,
                    ),
                  ),
                );
              },
              child: const Text('Open Round'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Round'));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('exercise-actions-exercise')));
      await _settle(tester);
      await tester.tap(find.text('Edit').last);
      await _settle(tester);
      expect(find.byType(ExerciseEditorScreen), findsOneWidget);

      await tester.enterText(_field('Prompt / instruction'), 'Edited prompt');
      await tester.scrollUntilVisible(
        find.byKey(const Key('exercise-save-draft')),
        350,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.byKey(const Key('exercise-save-draft')));
      await _settle(tester);

      expect(find.byType(ExerciseEditorScreen), findsNothing);
      expect(find.byType(RoundEditorScreen), findsOneWidget);
      expect(returnedRound, isNull);
      expect(changedCourse, isNotNull);
      final changedLesson = changedCourse!.lessons.single;
      expect(
        changedLesson.guidebook.toJson(),
        originalLesson.guidebook.toJson(),
      );
      expect(changedLesson.themeIconAsset, originalLesson.themeIconAsset);
      final changedContent = changedLesson.rounds.single.content.single;
      expect(changedContent.required, originalContent.required);
      expect(changedContent.role, originalContent.role);
      expect(changedContent.sourceRefs, originalContent.sourceRefs);
      expect(changedContent.exercise!.prompt, 'Edited prompt');

      await tester.tap(find.byType(BackButton).last);
      await _settle(tester);
      expect(find.byType(RoundEditorScreen), findsNothing);
      expect(returnedRound, isNotNull);
      final returnedContent = returnedRound!.content.single;
      expect(returnedContent.required, originalContent.required);
      expect(returnedContent.role, originalContent.role);
      expect(returnedContent.sourceRefs, originalContent.sourceRefs);
      expect(returnedContent.exercise!.prompt, 'Edited prompt');
    },
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var frame = 0; frame < 12; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Course _course() {
  final exercise = Exercise(
    id: 'exercise',
    publicationState: PublicationState.draft,
    updatedAt: DateTime.utc(2026, 9, 22, 10),
    type: 'choice',
    prompt: 'Original prompt',
    question: 'Choose one.',
    answers: const ['One', 'Two'],
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
    id: 'round',
    publicationState: PublicationState.draft,
    updatedAt: DateTime.utc(2026, 9, 22, 10),
    title: 'Round',
    content: [
      LearningContent(
        id: exercise.id,
        publicationState: exercise.publicationState,
        kind: 'exercise',
        required: false,
        role: 'practice',
        sourceRefs: const ['guide_source'],
        exercise: exercise,
      ),
    ],
  );
  return Course(
    courseId: 'hierarchy_route_245',
    originType: CourseOriginType.custom,
    publicationState: PublicationState.draft,
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Hierarchy route',
    ttsLanguage: 'it-IT',
    lessons: [
      Lesson(
        lessonId: 'lesson',
        publicationState: PublicationState.draft,
        updatedAt: DateTime.utc(2026, 9, 22, 10),
        title: 'Lesson',
        themeIconAsset: 'assets/lesson_icons/work.png',
        guidebook: Guidebook(
          content: [
            LearningContent.textual(
              id: 'guide_source',
              kind: 'explanation',
              role: 'overview',
              text: 'GuideBook source stays untouched',
            ),
          ],
        ),
        rounds: [round],
      ),
    ],
  );
}
