import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';

void main() {
  testWidgets(
    'generated Round can be edited before it is added to the Course',
    (tester) async {
      final exercise = Exercise(
        id: 'generated-exercise',
        publicationState: PublicationState.draft,
        type: 'choice',
        prompt: 'Generated prompt',
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
      final generated = LearningRound(
        id: 'generated-round',
        publicationState: PublicationState.draft,
        title: 'Generated draft',
        content: [LearningContent.fromExercise(exercise)],
      );
      final storedLesson = Lesson(
        lessonId: 'lesson',
        title: 'Lesson',
        rounds: const [],
      );
      final course = Course(
        courseId: 'generated-round-route',
        originType: CourseOriginType.custom,
        learningLanguage: 'Italian',
        interfaceLanguage: 'English',
        sourceLanguage: 'English',
        targetLanguage: 'Italian',
        title: 'Course',
        ttsLanguage: 'it-IT',
        lessons: [storedLesson],
      );
      final draftLesson = Lesson.fromJson({
        ...storedLesson.toJson(),
        'rounds': [generated.toJson()],
      });
      LearningRound? returned;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: FilledButton(
                onPressed: () async {
                  returned = await Navigator.of(context).push<LearningRound>(
                    MaterialPageRoute(
                      builder: (_) => RoundEditorScreen(
                        course: course,
                        lesson: draftLesson,
                        round: generated,
                        roundIndex: 0,
                        clock: () => DateTime.utc(2026, 9, 22, 12),
                      ),
                    ),
                  );
                },
                child: const Text('Open generated Round'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open generated Round'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Generated draft'), findsWidgets);

      expect(find.byKey(const Key('round-rename-action')), findsNothing);

      await tester.tap(find.byKey(const Key('round-save-draft')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(returned, isNotNull);
      expect(returned!.id, generated.id);
      expect(returned!.publicationState, PublicationState.draft);
      expect(returned!.title, 'Generated draft');
      expect(
        returned!.content.single.toJson(),
        generated.content.single.toJson(),
      );
      expect(course.lessons.single.rounds, isEmpty);
    },
  );

  testWidgets('Round editor opens duplicate Content for Audit repair', (
    tester,
  ) async {
    final exercise = Exercise(
      id: 'duplicate-content',
      type: 'choice',
      prompt: 'Prompt',
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
      title: 'Round with duplicate Content',
      content: [
        const LearningContent(
          id: 'duplicate-content',
          kind: 'text',
          role: 'lesson_intro',
          text: 'Introduction',
        ),
        LearningContent.fromExercise(exercise),
      ],
    );
    final lesson = Lesson(lessonId: 'lesson', title: 'Lesson', rounds: [round]);
    final course = Course(
      courseId: 'duplicate-content-route',
      originType: CourseOriginType.custom,
      learningLanguage: 'Italian',
      interfaceLanguage: 'English',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      title: 'Course',
      ttsLanguage: 'it-IT',
      lessons: [lesson],
    );
    expect(
      CourseAuditService()
          .auditCourse(course)
          .issues
          .any((issue) => issue.message == 'Duplicate ID: duplicate-content'),
      isTrue,
    );

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

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('round-audit-action')), findsNothing);
    expect(
      find.byKey(const ValueKey('exercise-actions-duplicate-content')),
      findsOneWidget,
    );
  });

  testWidgets('Lesson and Round editors open duplicate IDs for Audit repair', (
    tester,
  ) async {
    final first = Lesson(
      lessonId: 'duplicate-lesson',
      title: 'First',
      rounds: [
        LearningRound(
          id: 'first-round',
          title: 'First Round',
          content: const [],
        ),
      ],
    );
    final second = Lesson(
      lessonId: 'duplicate-lesson',
      title: 'Second',
      rounds: [
        LearningRound(
          id: 'second-round',
          title: 'Second Round',
          content: const [],
        ),
      ],
    );
    Course makeCourse(List<Lesson> lessons) => Course(
      courseId: 'duplicate-hierarchy-route',
      originType: CourseOriginType.custom,
      learningLanguage: 'Italian',
      interfaceLanguage: 'English',
      sourceLanguage: 'English',
      targetLanguage: 'Italian',
      title: 'Course',
      ttsLanguage: 'it-IT',
      lessons: lessons,
    );
    final duplicateLessons = makeCourse([first, second]);
    expect(
      CourseAuditService()
          .auditCourse(duplicateLessons)
          .issues
          .any((issue) => issue.message == 'Duplicate ID: duplicate-lesson'),
      isTrue,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LessonEditorScreen(course: duplicateLessons, lesson: first),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('lesson-rounds-navigation')), findsOneWidget);

    final firstRound = LearningRound(
      id: 'duplicate-round',
      title: 'First Round',
      content: const [],
    );
    final secondRound = LearningRound(
      id: 'duplicate-round',
      title: 'Second Round',
      content: const [],
    );
    final roundLesson = Lesson(
      lessonId: 'lesson',
      title: 'Lesson',
      rounds: [firstRound, secondRound],
    );
    final duplicateRounds = makeCourse([roundLesson]);
    expect(
      CourseAuditService()
          .auditCourse(duplicateRounds)
          .issues
          .any((issue) => issue.message == 'Duplicate ID: duplicate-round'),
      isTrue,
    );

    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        home: RoundEditorScreen(
          course: duplicateRounds,
          lesson: roundLesson,
          round: firstRound,
          roundIndex: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('round-audit-action')), findsNothing);
  });
}
