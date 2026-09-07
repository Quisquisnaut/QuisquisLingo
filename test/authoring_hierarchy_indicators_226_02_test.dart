import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/course_projects_screen.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_authoring_transfer_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets(
    'Draft and Audit status propagate from Exercise through Course links',
    (tester) async {
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
        draft: true,
        auditConcern: true,
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
        draft: true,
        auditConcern: true,
      );
      _expectIndicator(
        tester,
        ValueKey('lesson-status-indicator-${goodLesson.lessonId}'),
        draft: false,
        auditConcern: false,
      );
      final cleanAudit = CourseAuditService().auditLesson(
        course,
        goodLesson.lessonId,
      );
      expect(
        cleanAudit.issues.any(
          (issue) => issue.severity == AuditSeverity.warning,
        ),
        isFalse,
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
        draft: true,
        auditConcern: true,
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
        ValueKey('round-status-indicator-${badRound.id}'),
        draft: true,
        auditConcern: true,
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
        ValueKey('round-status-indicator-${goodRound.id}'),
        draft: false,
        auditConcern: false,
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
        draft: true,
        auditConcern: true,
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
        draft: false,
        auditConcern: false,
      );
      expect(tester.takeException(), isNull);
    },
  );

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
    final roundIndicator = ValueKey('round-status-indicator-${round.id}');
    _expectIndicator(tester, roundIndicator, draft: true, auditConcern: true);

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
    _expectIndicator(tester, roundIndicator, draft: false, auditConcern: false);
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
        draft: false,
        auditConcern: false,
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
        draft: false,
        auditConcern: false,
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
        draft: false,
        auditConcern: false,
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
        ValueKey('round-status-indicator-${round.id}'),
        draft: false,
        auditConcern: false,
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
      draft: false,
      auditConcern: false,
    );
    _expectIndicator(
      tester,
      ValueKey('lesson-status-indicator-${destinationLesson.lessonId}'),
      draft: true,
      auditConcern: true,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('red, green, and blue Draft states follow Audit severity', (
    tester,
  ) async {
    _viewport(tester);

    Future<void> check(
      LearningRound round, {
      required bool auditConcern,
      required bool draft,
    }) async {
      final course = _statusCourse([round]);
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          home: LessonRoundsScreen(
            course: course,
            lesson: course.lessons.single,
          ),
        ),
      );
      await tester.pumpAndSettle();
      _expectIndicator(
        tester,
        ValueKey('round-status-indicator-${round.id}'),
        draft: draft,
        auditConcern: auditConcern,
      );
    }

    await check(
      LearningRound(
        id: 'error-only',
        title: 'Error only',
        exercises: [_choice('error', correct: 9)],
      ),
      auditConcern: true,
      draft: false,
    );
    await check(
      _exerciseRound('warning-only', count: 11),
      auditConcern: true,
      draft: false,
    );
    await check(
      LearningRound(
        id: 'info-only',
        title: 'Info only',
        exercises: [_choice('info', correct: 0)],
      ),
      auditConcern: false,
      draft: false,
    );
    await check(_cleanRound('no-findings'), auditConcern: false, draft: false);
    await check(
      _cleanRound('draft-only', draftFirst: true),
      auditConcern: false,
      draft: true,
    );
    await check(
      LearningRound(
        id: 'draft-error',
        title: 'Draft Error',
        exercises: [_choice('draft-error-exercise', draft: true, correct: 9)],
      ),
      auditConcern: true,
      draft: true,
    );
    await check(
      _exerciseRound('draft-warning', count: 11, draftFirst: true),
      auditConcern: true,
      draft: true,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('clean sibling stays green while its Lesson ancestor is red', (
    tester,
  ) async {
    _viewport(tester);
    final bad = LearningRound(
      id: 'bad-sibling',
      title: 'Bad sibling',
      exercises: [_choice('bad-sibling-exercise', correct: 9)],
    );
    final clean = _cleanRound('clean-sibling');
    final course = _statusCourse([bad, clean]);

    await tester.pumpWidget(
      MaterialApp(
        home: LessonRoundsScreen(course: course, lesson: course.lessons.single),
      ),
    );
    await tester.pumpAndSettle();
    _expectIndicator(
      tester,
      const ValueKey('round-status-indicator-bad-sibling'),
      draft: false,
      auditConcern: true,
    );
    _expectIndicator(
      tester,
      const ValueKey('round-status-indicator-clean-sibling'),
      draft: false,
      auditConcern: false,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LessonManagementScreen(course: course, initiallyLocked: false),
      ),
    );
    await tester.pumpAndSettle();
    _expectIndicator(
      tester,
      const ValueKey('lesson-status-indicator-status-lesson'),
      draft: false,
      auditConcern: true,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Warning-only status is red through every ancestor', (
    tester,
  ) async {
    _viewport(tester);
    final warningRound = _exerciseRound('warning-branch', count: 11);
    final course = _statusCourse([warningRound]);
    final lesson = course.lessons.single;
    final audit = CourseAuditService().auditRound(course, warningRound.id);
    expect(
      audit.issues.where((issue) => issue.severity == AuditSeverity.error),
      isEmpty,
    );
    expect(
      audit.issues.any((issue) => issue.severity == AuditSeverity.warning),
      isTrue,
    );

    await tester.pumpWidget(
      MaterialApp(home: CourseEditorScreen(course: course, userCourse: true)),
    );
    await tester.pumpAndSettle();
    _expectIndicator(
      tester,
      const Key('course-lessons-status-indicator'),
      draft: false,
      auditConcern: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LessonManagementScreen(course: course, initiallyLocked: false),
      ),
    );
    await tester.pumpAndSettle();
    _expectIndicator(
      tester,
      const ValueKey('lesson-status-indicator-status-lesson'),
      draft: false,
      auditConcern: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LessonEditorScreen(course: course, lesson: lesson),
      ),
    );
    await tester.pumpAndSettle();
    _expectIndicator(
      tester,
      const Key('lesson-rounds-status-indicator'),
      draft: false,
      auditConcern: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LessonRoundsScreen(course: course, lesson: lesson),
      ),
    );
    await tester.pumpAndSettle();
    _expectIndicator(
      tester,
      const ValueKey('round-status-indicator-warning-branch'),
      draft: false,
      auditConcern: true,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty Round uses canonical Error then turns green when filled', (
    tester,
  ) async {
    _viewport(tester);
    final empty = LearningRound(id: 'empty-round', title: 'Empty');
    var course = _statusCourse([empty]);
    expect(
      CourseAuditService()
          .auditRound(course, empty.id)
          .issues
          .singleWhere((issue) => issue.code == 'ROUND_CONTENT_EMPTY')
          .severity,
      AuditSeverity.error,
    );

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
      draft: false,
      auditConcern: true,
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
      const ValueKey('lesson-status-indicator-status-lesson'),
      draft: false,
      auditConcern: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        home: LessonEditorScreen(course: course, lesson: course.lessons.single),
      ),
    );
    await tester.pumpAndSettle();
    _expectIndicator(
      tester,
      const Key('lesson-rounds-status-indicator'),
      draft: false,
      auditConcern: true,
    );

    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        home: LessonRoundsScreen(course: course, lesson: course.lessons.single),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('0 Exercises'), findsOneWidget);
    expect(find.text('0 Draft Exercises'), findsNothing);
    _expectIndicator(
      tester,
      const ValueKey('round-status-indicator-empty-round'),
      draft: false,
      auditConcern: true,
    );

    final filled = _cleanRound('empty-round');
    course = _statusCourse([filled]);
    expect(CourseAuditService().auditRound(course, filled.id).issues, isEmpty);
    await tester.pumpWidget(
      MaterialApp(
        key: UniqueKey(),
        home: LessonRoundsScreen(course: course, lesson: course.lessons.single),
      ),
    );
    await tester.pumpAndSettle();
    _expectIndicator(
      tester,
      const ValueKey('round-status-indicator-empty-round'),
      draft: false,
      auditConcern: false,
    );

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
      draft: false,
      auditConcern: false,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'empty Lesson uses canonical Warning, remains navigable, then turns green',
    (tester) async {
      _viewport(tester);
      var course = _statusCourse(const []);
      final emptyLesson = course.lessons.single;
      final emptyAudit = CourseAuditService().auditLesson(
        course,
        emptyLesson.lessonId,
      );
      expect(
        emptyAudit.issues
            .singleWhere((issue) => issue.code == 'LESSON_ROUNDS_EMPTY')
            .severity,
        AuditSeverity.warning,
      );
      expect(
        emptyAudit.issues
            .singleWhere((issue) => issue.code == 'LESSON_ROUND_GUIDANCE')
            .severity,
        AuditSeverity.info,
      );

      await tester.pumpWidget(
        MaterialApp(home: CourseProjectsScreen(currentCourse: course)),
      );
      await tester.pumpAndSettle();
      _expectIndicator(
        tester,
        const ValueKey('course-manager-status-status-course'),
        draft: false,
        auditConcern: true,
      );

      await tester.pumpWidget(
        MaterialApp(home: CourseEditorScreen(course: course, userCourse: true)),
      );
      await tester.pumpAndSettle();
      _expectIndicator(
        tester,
        const Key('course-lessons-status-indicator'),
        draft: false,
        auditConcern: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LessonManagementScreen(course: course, initiallyLocked: false),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('0 Rounds'), findsOneWidget);
      _expectIndicator(
        tester,
        const ValueKey('lesson-status-indicator-status-lesson'),
        draft: false,
        auditConcern: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LessonEditorScreen(course: course, lesson: emptyLesson),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('0 Rounds'), findsOneWidget);
      _expectIndicator(
        tester,
        const Key('lesson-rounds-status-indicator'),
        draft: false,
        auditConcern: true,
      );
      await tester.tap(find.byKey(const Key('lesson-rounds-navigation')));
      await tester.pumpAndSettle();
      expect(find.byType(LessonRoundsScreen), findsOneWidget);

      course = _statusCourse([_cleanRound('first-round')]);
      expect(
        CourseAuditService()
            .auditLesson(course, course.lessons.single.lessonId)
            .issues
            .where(
              (issue) =>
                  issue.severity == AuditSeverity.error ||
                  issue.severity == AuditSeverity.warning,
            ),
        isEmpty,
      );
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          home: LessonEditorScreen(
            course: course,
            lesson: course.lessons.single,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('1 Round'), findsOneWidget);
      _expectIndicator(
        tester,
        const Key('lesson-rounds-status-indicator'),
        draft: false,
        auditConcern: false,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'creating the first Round through the UI refreshes every open ancestor',
    (tester) async {
      _viewport(tester);
      final course = _statusCourse(const []);
      await tester.pumpWidget(
        MaterialApp(home: CourseEditorScreen(course: course, userCourse: true)),
      );
      await tester.pumpAndSettle();
      _expectIndicator(
        tester,
        const Key('course-lessons-status-indicator'),
        draft: false,
        auditConcern: true,
      );

      await tester.tap(
        find.byKey(const Key('course-editor-lessons-navigation')),
      );
      await tester.pumpAndSettle();
      expect(find.byType(LessonManagementScreen), findsOneWidget);
      expect(find.text('0 Rounds'), findsOneWidget);
      _expectIndicator(
        tester,
        const ValueKey('lesson-status-indicator-status-lesson'),
        draft: false,
        auditConcern: true,
      );
      await tester.tap(find.byKey(const Key('lesson-management-lock')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lesson 1: Status lesson'));
      await tester.pumpAndSettle();
      expect(find.byType(LessonEditorScreen), findsOneWidget);
      expect(find.text('0 Rounds'), findsOneWidget);
      expect(find.text('Draft · hidden from learner delivery'), findsNothing);
      _expectIndicator(
        tester,
        const Key('lesson-rounds-status-indicator'),
        draft: false,
        auditConcern: true,
      );

      await tester.tap(find.byKey(const Key('lesson-rounds-navigation')));
      await tester.pumpAndSettle();
      expect(find.byType(LessonRoundsScreen), findsOneWidget);
      expect(find.text('New round'), findsOneWidget);
      expect(find.byKey(const Key('round-draft-indicator')), findsNothing);
      await tester.tap(find.text('New round'));
      await tester.pumpAndSettle();
      final titleField = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(TextFormField),
      );
      await tester.enterText(titleField, 'First valid Round');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();
      expect(find.text('1 Exercise'), findsOneWidget);
      final createdRoundIndicator = find.byWidgetPredicate(
        (widget) =>
            widget.key is ValueKey<String> &&
            (widget.key! as ValueKey<String>).value.startsWith(
              'round-status-indicator-custom_round_',
            ),
      );
      expect(createdRoundIndicator, findsOneWidget);
      final createdCard = tester.widget<Card>(
        find.descendant(of: createdRoundIndicator, matching: find.byType(Card)),
      );
      expect(
        (createdCard.shape! as RoundedRectangleBorder).side.color,
        const Color(0xFF00A83B),
      );

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(LessonEditorScreen), findsOneWidget);
      expect(find.text('1 Round'), findsOneWidget);
      _expectIndicator(
        tester,
        const Key('lesson-rounds-status-indicator'),
        draft: true,
        auditConcern: false,
      );

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(LessonManagementScreen), findsOneWidget);
      expect(find.text('1 Round'), findsOneWidget);
      _expectIndicator(
        tester,
        const ValueKey('lesson-status-indicator-status-lesson'),
        draft: true,
        auditConcern: false,
      );

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(CourseEditorScreen), findsOneWidget);
      _expectIndicator(
        tester,
        const Key('course-lessons-status-indicator'),
        draft: true,
        auditConcern: false,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'accepted Exercise saves refresh the canonical Audit through every open ancestor',
    (tester) async {
      _viewport(tester);
      final course = _liveAuditCourse();
      final lesson = course.lessons.single;
      final round = lesson.rounds.single;
      final lessonAudit = CourseAuditService().auditLesson(
        course,
        lesson.lessonId,
      );
      expect(
        lessonAudit.issues.where(
          (issue) =>
              issue.severity == AuditSeverity.error ||
              issue.severity == AuditSeverity.warning,
        ),
        isEmpty,
      );
      expect(
        lessonAudit.issues.any(
          (issue) => issue.code == 'LESSON_ROUND_GUIDANCE',
        ),
        isTrue,
      );

      await tester.pumpWidget(
        MaterialApp(home: CourseEditorScreen(course: course, userCourse: true)),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const Key('course-editor-lessons-navigation')),
      );
      await tester.pumpAndSettle();
      final lock = tester.widget<IconButton>(
        find.byKey(const Key('lesson-management-lock')),
      );
      if (lock.isSelected == true) {
        await tester.tap(find.byKey(const Key('lesson-management-lock')));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('Lesson 1: Live Audit Lesson'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('lesson-rounds-navigation')));
      await tester.pumpAndSettle();
      await tester.tap(_hierarchyTile(round.id));
      await tester.pumpAndSettle();

      for (final exercise in round.exercises) {
        await tester.tap(_hierarchyTile(exercise.id));
        await tester.pumpAndSettle();
        await _savePublishedExercise(tester);
      }

      for (final exercise in round.exercises) {
        _expectIndicator(
          tester,
          ValueKey('exercise-status-indicator-${exercise.id}'),
          draft: false,
          auditConcern: false,
        );
      }
      _expectIndicator(
        tester,
        const ValueKey('round-status-indicator-live-audit-round'),
        draft: false,
        auditConcern: false,
        skipOffstage: false,
      );
      _expectIndicator(
        tester,
        const Key('lesson-rounds-status-indicator'),
        draft: false,
        auditConcern: false,
        skipOffstage: false,
      );
      _expectIndicator(
        tester,
        const ValueKey('lesson-status-indicator-live-audit-lesson'),
        draft: false,
        auditConcern: false,
        skipOffstage: false,
      );
      _expectIndicator(
        tester,
        const Key('course-lessons-status-indicator'),
        draft: false,
        auditConcern: false,
        skipOffstage: false,
      );

      await tester.tap(_hierarchyTile('live-audit-exercise-1'));
      await tester.pumpAndSettle();
      await tester.enterText(_field('Hint (optional)'), 'La ___ casa è qui 1.');
      await _savePublishedExercise(tester, warningCode: 'HINT_REPEATS_PROMPT');

      _expectIndicator(
        tester,
        const ValueKey('exercise-status-indicator-live-audit-exercise-1'),
        draft: false,
        auditConcern: true,
      );
      _expectIndicator(
        tester,
        const ValueKey('round-status-indicator-live-audit-round'),
        draft: false,
        auditConcern: true,
        skipOffstage: false,
      );
      _expectIndicator(
        tester,
        const Key('lesson-rounds-status-indicator'),
        draft: false,
        auditConcern: true,
        skipOffstage: false,
      );
      _expectIndicator(
        tester,
        const ValueKey('lesson-status-indicator-live-audit-lesson'),
        draft: false,
        auditConcern: true,
        skipOffstage: false,
      );
      _expectIndicator(
        tester,
        const Key('course-lessons-status-indicator'),
        draft: false,
        auditConcern: true,
        skipOffstage: false,
      );

      await tester.tap(_hierarchyTile('live-audit-exercise-1'));
      await tester.pumpAndSettle();
      await tester.enterText(
        _field('Hint (optional)'),
        'Think about the possessive adjective.',
      );
      await _savePublishedExercise(tester);

      _expectIndicator(
        tester,
        const ValueKey('exercise-status-indicator-live-audit-exercise-1'),
        draft: false,
        auditConcern: false,
      );
      _expectIndicator(
        tester,
        const ValueKey('round-status-indicator-live-audit-round'),
        draft: false,
        auditConcern: false,
        skipOffstage: false,
      );
      _expectIndicator(
        tester,
        const Key('lesson-rounds-status-indicator'),
        draft: false,
        auditConcern: false,
        skipOffstage: false,
      );
      _expectIndicator(
        tester,
        const ValueKey('lesson-status-indicator-live-audit-lesson'),
        draft: false,
        auditConcern: false,
        skipOffstage: false,
      );
      _expectIndicator(
        tester,
        const Key('course-lessons-status-indicator'),
        draft: false,
        auditConcern: false,
        skipOffstage: false,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

Finder _hierarchyTile(String id) => find.descendant(
  of: find.byKey(ValueKey(id)),
  matching: find.byType(ListTile),
);

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Future<void> _savePublishedExercise(
  WidgetTester tester, {
  String? warningCode,
}) async {
  final save = find.byKey(const Key('exercise-save'));
  await tester.scrollUntilVisible(
    save,
    350,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(save);
  await tester.pumpAndSettle();
  if (warningCode != null) {
    expect(find.textContaining(warningCode), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Use anyway'));
    await tester.pumpAndSettle();
  }
  expect(find.byType(RoundEditorScreen), findsOneWidget);
}

void _expectIndicator(
  WidgetTester tester,
  Key key, {
  required bool draft,
  required bool auditConcern,
  bool skipOffstage = true,
}) {
  final status = find.byWidgetPredicate(
    (widget) => widget is AuthoringStatusCard && widget.indicatorKey == key,
    skipOffstage: skipOffstage,
  );
  expect(status, findsOneWidget);
  final statusWidget = tester.widget<AuthoringStatusCard>(status);
  expect(statusWidget.hasAuditConcern, auditConcern);
  expect(statusWidget.hasDraft, draft);
  if (skipOffstage) {
    final finder = find.byKey(key);
    final card = tester.widget<Card>(
      find.descendant(of: finder, matching: find.byType(Card)).first,
    );
    final side = (card.shape! as RoundedRectangleBorder).side;
    expect(
      side.color,
      auditConcern ? const Color(0xFFC90000) : const Color(0xFF00A83B),
      reason: '$key Audit border',
    );
  }
  expect(
    find.byKey(_draftIndicatorKey(key), skipOffstage: skipOffstage),
    draft ? findsOneWidget : findsNothing,
    reason: '$key Draft indicator',
  );
}

Key _draftIndicatorKey(Key statusKey) {
  final value = (statusKey as ValueKey).value as String;
  if (value.startsWith('course-manager-status-')) {
    return ValueKey(
      value.replaceFirst('course-manager-status-', 'course-manager-draft-'),
    );
  }
  if (value == 'course-lessons-status-indicator') {
    return const ValueKey('course-lessons-draft-indicator');
  }
  if (value == 'lesson-rounds-status-indicator') {
    return const ValueKey('lesson-rounds-draft-indicator');
  }
  if (value.startsWith('lesson-status-indicator-')) {
    return ValueKey(
      value.replaceFirst('lesson-status-indicator-', 'lesson-draft-indicator-'),
    );
  }
  if (value.startsWith('round-status-indicator-')) {
    return ValueKey(
      value.replaceFirst('round-status-indicator-', 'round-draft-indicator-'),
    );
  }
  return ValueKey(
    value.replaceFirst(
      'exercise-status-indicator-',
      'exercise-draft-indicator-',
    ),
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
      guidebook: _guidebook('bad-guidebook'),
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
      guidebook: _guidebook('good-guidebook'),
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

Course _statusCourse(List<LearningRound> rounds) => Course(
  courseId: 'status-course',
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Status course',
  ttsLanguage: 'it-IT',
  version: '1',
  courseVersion: '3',
  lessons: [
    Lesson(
      lessonId: 'status-lesson',
      title: 'Status lesson',
      guidebook: _guidebook('status-guidebook'),
      rounds: rounds,
    ),
  ],
);

LearningRound _exerciseRound(
  String id, {
  required int count,
  bool draftFirst = false,
}) => LearningRound(
  id: id,
  title: id,
  exercises: [
    for (var index = 0; index < count; index++)
      _choice(
        '$id-exercise-$index',
        draft: draftFirst && index == 0,
        correct: 0,
      ),
  ],
);

LearningRound _cleanRound(String id, {bool draftFirst = false}) =>
    LearningRound(
      id: id,
      title: id,
      content: [
        LearningContent.textual(
          id: '$id-intro',
          kind: 'text',
          role: 'lesson_intro',
          text: 'A short introduction.',
        ),
        for (var index = 0; index < 8; index++)
          LearningContent.fromExercise(
            _choice(
              '$id-exercise-$index',
              draft: draftFirst && index == 0,
              correct: 0,
            ),
          ),
      ],
    );

Guidebook _guidebook(String id) => Guidebook(
  content: [
    LearningContent.textual(
      id: id,
      kind: 'explanation',
      role: 'overview',
      text: 'Reviewed overview.',
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
      question: 'How are you in exercise $id?',
      answers: const ['well', 'badly'],
      correct: correct,
      tts: null,
      accepted: const [],
      tokens: const [],
      orderAnswer: const [],
      pairs: const [],
      hint: '',
      icons: const [],
    );

Course _liveAuditCourse() => Course(
  courseId: 'live-audit-course',
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Live Audit Course',
  ttsLanguage: 'it-IT',
  version: '1',
  courseVersion: '1',
  lessons: [
    Lesson(
      lessonId: 'live-audit-lesson',
      title: 'Live Audit Lesson',
      guidebook: _guidebook('live-audit-guidebook'),
      rounds: [
        LearningRound(
          id: 'live-audit-round',
          title: 'Live Audit Round',
          content: [
            LearningContent.textual(
              id: 'live-audit-intro',
              kind: 'text',
              role: 'lesson_intro',
              text: 'A short introduction.',
            ),
            for (var index = 1; index <= 3; index++)
              LearningContent.fromExercise(_gapChoice(index)),
          ],
        ),
      ],
    ),
  ],
);

Exercise _gapChoice(int index) => Exercise(
  id: 'live-audit-exercise-$index',
  publicationState: PublicationState.published,
  updatedAt: DateTime.utc(2026, 9, 6),
  type: 'gap_choice',
  prompt: 'Complete sentence $index.',
  question: 'La ___ casa è qui $index.',
  answers: const ['mia', 'tua'],
  correct: 0,
  tts: null,
  accepted: const [],
  tokens: const [],
  orderAnswer: const [],
  pairs: const [],
  hint: 'Choose the matching possessive adjective.',
  icons: const [],
);
