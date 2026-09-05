import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_authoring_transfer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Draft and Error coexist from Exercise through Course links', (
    tester,
  ) async {
    _viewport(tester);
    final course = _course();
    final badLesson = course.lessons.first;
    final goodLesson = course.lessons.last;
    final badRound = badLesson.rounds.first;
    final goodRound = goodLesson.rounds.first;
    final badExercise = badRound.exercises.first;
    final goodExercise = goodRound.exercises.first;

    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        home: CourseEditorScreen(course: course, userCourse: true),
      ),
    );
    await tester.pumpAndSettle();
    _expectIndicator(
      tester,
      const Key('course-lessons-status-indicator'),
      orange: true,
      pink: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        home: LessonManagementScreen(course: course, initiallyLocked: false),
      ),
    );
    await tester.pumpAndSettle();
    _expectIndicator(
      tester,
      ValueKey('lesson-status-indicator-${badLesson.lessonId}'),
      orange: true,
      pink: true,
    );
    _expectIndicator(
      tester,
      ValueKey('lesson-status-indicator-${goodLesson.lessonId}'),
      orange: false,
      pink: false,
    );
    final cleanAudit = CourseAuditService().auditLesson(
      course,
      goodLesson.lessonId,
    );
    expect(
      cleanAudit.issues.any((issue) => issue.severity == AuditSeverity.warning),
      isTrue,
    );
    expect(
      cleanAudit.issues.any((issue) => issue.severity == AuditSeverity.error),
      isFalse,
    );

    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        home: LessonEditorScreen(course: course, lesson: badLesson),
      ),
    );
    await tester.pumpAndSettle();
    _expectIndicator(
      tester,
      const Key('lesson-rounds-status-indicator'),
      orange: true,
      pink: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        home: LessonRoundsScreen(course: course, lesson: badLesson),
      ),
    );
    await tester.pumpAndSettle();
    _expectIndicator(
      tester,
      ValueKey('round-draft-indicator-${badRound.id}'),
      orange: true,
      pink: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        home: LessonRoundsScreen(course: course, lesson: goodLesson),
      ),
    );
    await tester.pumpAndSettle();
    _expectIndicator(
      tester,
      ValueKey('round-draft-indicator-${goodRound.id}'),
      orange: false,
      pink: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        home: RoundEditorScreen(
          course: course,
          lesson: badLesson,
          round: badRound,
          roundIndex: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();
    _expectIndicator(
      tester,
      ValueKey('exercise-status-indicator-${badExercise.id}'),
      orange: true,
      pink: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        home: RoundEditorScreen(
          course: course,
          lesson: goodLesson,
          round: goodRound,
          roundIndex: 0,
        ),
      ),
    );
    await tester.pumpAndSettle();
    _expectIndicator(
      tester,
      ValueKey('exercise-status-indicator-${goodExercise.id}'),
      orange: false,
      pink: false,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('deleting the last Draft Error clears the live Round indicator', (
    tester,
  ) async {
    _viewport(tester);
    final course = _course();
    final lesson = course.lessons.first;
    final round = lesson.rounds.first;
    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        home: LessonRoundsScreen(course: course, lesson: lesson),
      ),
    );
    await tester.pumpAndSettle();
    final roundIndicator = ValueKey('round-draft-indicator-${round.id}');
    _expectIndicator(tester, roundIndicator, orange: true, pink: true);

    await tester.tap(
      find.descendant(
        of: find.byKey(ValueKey(round.id)),
        matching: find.byType(ListTile),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(ValueKey('exercise-actions-${round.exercises.first.id}')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete exercise'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        ValueKey('exercise-status-indicator-${round.exercises.first.id}'),
      ),
      findsNothing,
    );

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    _expectIndicator(tester, roundIndicator, orange: false, pink: false);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'correcting the last Draft Error clears every inherited indicator',
    (tester) async {
      _viewport(tester);
      final corrected = _course(badDraft: false, badCorrect: 0);
      final lesson = corrected.lessons.first;
      final round = lesson.rounds.first;

      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          home: CourseEditorScreen(course: corrected, userCourse: true),
        ),
      );
      await tester.pumpAndSettle();
      _expectIndicator(
        tester,
        const Key('course-lessons-status-indicator'),
        orange: false,
        pink: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          home: LessonManagementScreen(
            course: corrected,
            initiallyLocked: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      _expectIndicator(
        tester,
        ValueKey('lesson-status-indicator-${lesson.lessonId}'),
        orange: false,
        pink: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          home: LessonEditorScreen(course: corrected, lesson: lesson),
        ),
      );
      await tester.pumpAndSettle();
      _expectIndicator(
        tester,
        const Key('lesson-rounds-status-indicator'),
        orange: false,
        pink: false,
      );

      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          home: LessonRoundsScreen(course: corrected, lesson: lesson),
        ),
      );
      await tester.pumpAndSettle();
      _expectIndicator(
        tester,
        ValueKey('round-draft-indicator-${round.id}'),
        orange: false,
        pink: false,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('moving the last Draft Error transfers the live indicators', (
    tester,
  ) async {
    _viewport(tester);
    final source = _course();
    final moved =
        CourseAuthoringTransferService(
          clock: () => DateTime.utc(2026, 9, 5),
        ).moveExercise(
          source,
          sourceLessonId: 'bad-lesson',
          sourceRoundId: 'bad-round',
          exerciseId: 'bad-exercise',
          destinationLessonId: 'good-lesson',
          destinationRoundId: 'good-round',
        );
    final sourceLesson = moved.lessons.first;
    final destinationLesson = moved.lessons.last;

    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        home: LessonManagementScreen(course: moved, initiallyLocked: false),
      ),
    );
    await tester.pumpAndSettle();
    _expectIndicator(
      tester,
      ValueKey('lesson-status-indicator-${sourceLesson.lessonId}'),
      orange: false,
      pink: false,
    );
    _expectIndicator(
      tester,
      ValueKey('lesson-status-indicator-${destinationLesson.lessonId}'),
      orange: true,
      pink: true,
    );
    expect(tester.takeException(), isNull);
  });
}

void _expectIndicator(
  WidgetTester tester,
  Key key, {
  required bool orange,
  required bool pink,
}) {
  final finder = find.byKey(key);
  expect(finder, findsOneWidget);
  final decoration =
      tester.widget<Container>(finder).decoration! as BoxDecoration;
  final border = decoration.border as Border?;
  expect(border?.top.color == Colors.orange, orange, reason: '$key orange');
  final card = tester.widget<Card>(
    find.descendant(of: finder, matching: find.byType(Card)).first,
  );
  final side = (card.shape! as RoundedRectangleBorder).side;
  expect(
    side.style != BorderStyle.none && side.color == Colors.pinkAccent,
    pink,
    reason: '$key pink',
  );
}

void _viewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Course _course({bool badDraft = true, int badCorrect = 9}) => Course(
  courseId: 'indicator-course',
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Indicator course',
  ttsLanguage: 'it-IT',
  version: '1',
  courseVersion: '3',
  lessons: [
    Lesson(
      lessonId: 'bad-lesson',
      title: 'Needs work',
      rounds: [
        LearningRound(
          id: 'bad-round',
          title: 'Draft error',
          exercises: [
            _choice('bad-exercise', draft: badDraft, correct: badCorrect),
            _choice('good-alongside', correct: 0),
          ],
        ),
      ],
    ),
    Lesson(
      lessonId: 'good-lesson',
      title: 'Review guidance only',
      rounds: [
        LearningRound(
          id: 'good-round',
          title: 'Good',
          exercises: [_choice('good-exercise', correct: 0)],
        ),
      ],
    ),
  ],
);

Exercise _choice(String id, {bool draft = false, required int correct}) =>
    Exercise(
      id: id,
      publicationState: draft
          ? PublicationState.draft
          : PublicationState.published,
      updatedAt: DateTime.utc(2026, 9, 5),
      type: 'choice',
      prompt: 'Choose the greeting.',
      question: 'How are you?',
      answers: const ['Bene', 'Male'],
      correct: correct,
      tts: null,
      accepted: const [],
      tokens: const [],
      orderAnswer: const [],
      pairs: const [],
      hint: '',
      icons: const [],
    );
