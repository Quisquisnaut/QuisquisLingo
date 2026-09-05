import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _profileId = '12345678-1234-4234-9234-123456789abc';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documents;
  late CourseBackupService backups;
  late CourseEditorService service;
  late Course course;

  setUp(() async {
    documents = await Directory.systemTemp.createTemp('qql_ui_22504_');
    backups = _MemoryBackupService(documents);
    SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [
        const LearnerProfile(
          learnerProfileId: _profileId,
          displayName: 'UI Author',
        ).encode(),
      ],
      ProfileService.activeProfileIdKey: _profileId,
      'course_editor_locked_TRANSACTION_UI_COURSE': false,
    });
    service = CourseEditorService(
      backupService: backups,
      clock: () => DateTime.utc(2026, 9, 4, 17),
    );
    course = _course();
    await service.saveUserCourse(course);
  });

  tearDown(() async {
    if (await documents.exists()) await documents.delete(recursive: true);
  });

  testWidgets(
    'real Course Lesson Round Exercise route stages Draft and confirms once',
    (tester) async {
      await _openEditor(tester, course, service);

      final topList = tester.widget<ListView>(
        find
            .descendant(
              of: find.byType(CourseEditorScreen),
              matching: find.byType(ListView),
            )
            .first,
      );
      final children =
          (topList.childrenDelegate as SliverChildListDelegate).children;
      expect(
        (children.first as ListTile).key,
        const Key('course-editor-lessons-navigation'),
      );

      await _openExercise(tester);
      await tester.enterText(
        _field('Prompt / instruction'),
        'Working-copy prompt',
      );
      await tester.scrollUntilVisible(
        find.byKey(const Key('exercise-save-draft')),
        350,
        scrollable: _editorScroll(),
      );
      await tester.tap(find.byKey(const Key('exercise-save-draft')));
      await _settle(tester);
      expect(find.byType(RoundEditorScreen), findsOneWidget);
      expect(
        find.byKey(const Key('course-transaction-confirmation')),
        findsNothing,
      );

      await _nestedBack(tester, LessonRoundsScreen);
      await _nestedBack(tester, LessonEditorScreen);
      await _nestedBack(tester, LessonManagementScreen);
      await _nestedBack(tester, CourseEditorScreen);

      final beforeConfirm = (await service.listUserCourses()).single;
      expect(
        beforeConfirm.lessons.single.rounds.single.exercises.first.prompt,
        'Original prompt',
      );
      expect(await backups.listBackups(course.courseId), isEmpty);

      await tester.tap(find.byType(BackButton).last);
      await _settle(tester);
      expect(
        find.byKey(const Key('course-transaction-confirmation')),
        findsOneWidget,
      );
      expect(find.text('Confirm course changes'), findsOneWidget);
      expect(find.text('Cancel course changes'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.enterText(
        find.byKey(const Key('course-version-notes')),
        'Draft flow\nkeeps line breaks',
      );
      await tester.tap(find.byKey(const Key('confirm-course-changes')));
      await _settle(tester, frames: 24);
      expect(find.byType(CourseEditorScreen), findsNothing);

      final reloaded = (await service.listUserCourses()).single;
      expect(reloaded.courseVersion, '2');
      expect(reloaded.lastModifiedByProfileId, _profileId);
      expect(reloaded.lastModifiedByUsername, 'UI Author');
      expect(reloaded.versionNotes, 'Draft flow\nkeeps line breaks');
      expect(
        reloaded.lessons.single.rounds.single.exercises.first.prompt,
        'Working-copy prompt',
      );
      expect(
        reloaded.lessons.single.rounds.single.exercises.first.publicationState,
        PublicationState.draft,
      );
      expect(await backups.listBackups(course.courseId), hasLength(1));
    },
  );

  testWidgets('Cancel discards Course Info and creates no version or backup', (
    tester,
  ) async {
    await _openEditor(tester, course, service);
    await tester.tap(find.text('Course info'));
    await _settle(tester);
    await tester.enterText(_field('Course name'), 'Cancelled title');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await _settle(tester);
    expect(find.byType(CourseEditorScreen), findsOneWidget);
    expect(find.text('Cancelled title'), findsWidgets);

    await tester.tap(find.byType(BackButton).last);
    await _settle(tester);
    expect(
      find.byKey(const Key('course-transaction-confirmation')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('course-version-notes')),
      'discard this',
    );
    await tester.tap(find.byKey(const Key('cancel-course-changes')));
    await _settle(tester);

    final reloaded = (await service.listUserCourses()).single;
    expect(reloaded.title, 'Transaction UI');
    expect(reloaded.courseVersion, '1');
    expect(reloaded.versionNotes, isEmpty);
    expect(await backups.listBackups(course.courseId), isEmpty);
  });

  testWidgets(
    'Back from Exercise discards only its unstaged form edit without dialog',
    (tester) async {
      await _openEditor(tester, course, service);
      await _openExercise(tester);
      await tester.enterText(_field('Prompt / instruction'), 'Unstaged prompt');
      await tester.tap(find.byType(BackButton).last);
      await _settle(tester);
      expect(find.byType(RoundEditorScreen), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      await tester.tap(find.byKey(const ValueKey('exercise-actions-exercise')));
      await _settle(tester);
      await tester.tap(find.text('Edit').last);
      await _settle(tester);
      expect(
        tester
            .widget<TextField>(_field('Prompt / instruction'))
            .controller!
            .text,
        'Original prompt',
      );
    },
  );

  testWidgets('real Exercise Save stages published content and confirms once', (
    tester,
  ) async {
    await _openEditor(tester, course, service);
    await _openExercise(tester);
    await tester.enterText(
      _field('Prompt / instruction'),
      'Published working-copy prompt',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('exercise-save')),
      350,
      scrollable: _editorScroll(),
    );
    await tester.tap(find.byKey(const Key('exercise-save')));
    await _settle(tester);
    expect(find.byType(RoundEditorScreen), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    await _nestedBack(tester, LessonRoundsScreen);
    await _nestedBack(tester, LessonEditorScreen);
    await _nestedBack(tester, LessonManagementScreen);
    await _nestedBack(tester, CourseEditorScreen);
    expect(find.byType(AlertDialog), findsNothing);

    await tester.tap(find.byType(BackButton).last);
    await _settle(tester);
    expect(
      find.byKey(const Key('course-transaction-confirmation')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('confirm-course-changes')));
    await _settle(tester, frames: 24);

    final reloaded = (await service.listUserCourses()).single;
    final exercise = reloaded.lessons.single.rounds.single.exercises.single;
    expect(exercise.prompt, 'Published working-copy prompt');
    expect(exercise.publicationState, PublicationState.published);
    expect(reloaded.courseVersion, '2');
    expect(await backups.listBackups(course.courseId), hasLength(1));
  });

  testWidgets('restoring Course Info to the original value exits cleanly', (
    tester,
  ) async {
    await _openEditor(tester, course, service);
    await tester.tap(find.text('Course info'));
    await _settle(tester);
    await tester.enterText(_field('Course name'), 'Temporary title');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await _settle(tester);
    await tester.tap(find.text('Course info'));
    await _settle(tester);
    await tester.enterText(_field('Course name'), course.title);
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await _settle(tester);

    await tester.tap(find.byType(BackButton).last);
    await _settle(tester);
    expect(find.byType(CourseEditorScreen), findsNothing);
    expect(
      find.byKey(const Key('course-transaction-confirmation')),
      findsNothing,
    );
    expect((await service.listUserCourses()).single.courseVersion, '1');
    expect(await backups.listBackups(course.courseId), isEmpty);
  });

  testWidgets('failed final persistence keeps working copy and version notes', (
    tester,
  ) async {
    final failing = _FailingCourseEditorService(backups);
    await _openEditor(tester, course, failing);
    await tester.tap(find.text('Course info'));
    await _settle(tester);
    await tester.enterText(_field('Course name'), 'Still editable');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await _settle(tester);

    await tester.tap(find.byType(BackButton).last);
    await _settle(tester);
    await tester.enterText(
      find.byKey(const Key('course-version-notes')),
      'keep these notes',
    );
    await tester.tap(find.byKey(const Key('confirm-course-changes')));
    await _settle(tester);
    expect(find.byType(CourseEditorScreen), findsOneWidget);
    expect(find.textContaining('original course is unchanged'), findsOneWidget);

    await tester.tap(find.byType(BackButton).last);
    await _settle(tester);
    final notes = tester.widget<TextFormField>(
      find.byKey(const Key('course-version-notes')),
    );
    expect(notes.initialValue, 'keep these notes');
    await tester.tap(find.byKey(const Key('cancel-course-changes')));
    await _settle(tester);
    final live = (await service.listUserCourses()).single;
    expect(live.title, course.title);
    expect(live.courseVersion, '1');
  });

  testWidgets('no-change top-level exit has no dialog, backup or version', (
    tester,
  ) async {
    await _openEditor(tester, course, service);
    await tester.tap(find.byType(BackButton).last);
    await _settle(tester);
    expect(find.byType(CourseEditorScreen), findsNothing);
    expect(
      find.byKey(const Key('course-transaction-confirmation')),
      findsNothing,
    );
    expect((await service.listUserCourses()).single.courseVersion, '1');
    expect(await backups.listBackups(course.courseId), isEmpty);
  });

  testWidgets(
    'mixed real-screen mutations stage once, audit the working copy and persist once',
    (tester) async {
      final mixed = _mixedCourse();
      await service.saveUserCourse(mixed);
      await _openEditor(tester, mixed, service);

      await tester.tap(find.text('Course info'));
      await _settle(tester);
      await tester.enterText(_field('Course name'), 'Mixed transaction');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await _settle(tester);
      expect(
        find.byKey(const Key('course-transaction-confirmation')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const Key('course-editor-lessons-navigation')),
      );
      await _settle(tester);
      await tester.tap(find.widgetWithText(FloatingActionButton, 'New lesson'));
      await _settle(tester);
      await tester.enterText(find.byType(TextField), 'Created lesson');
      await tester.tap(find.widgetWithText(FilledButton, 'Create'));
      await _settle(tester);

      await tester.tap(find.byKey(const ValueKey('lesson-actions-lesson')));
      await _settle(tester);
      await tester.tap(find.text('Rename'));
      await _settle(tester);
      await tester.enterText(find.byType(TextField), 'Renamed lesson');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await _settle(tester);

      await tester.tap(find.byKey(const ValueKey('lesson-actions-lesson_b')));
      await _settle(tester);
      await tester.tap(find.text('Delete'));
      await _settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await _settle(tester);
      final lessonList = tester.widget<ReorderableListView>(
        find.byKey(const Key('lesson-management-list')),
      );
      lessonList.onReorderItem!(1, 0);
      await _settle(tester);
      expect(
        find.byKey(const Key('course-transaction-confirmation')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('lesson')));
      await _settle(tester);
      await tester.tap(find.text('Lesson Guidebook'));
      await _settle(tester);
      await tester.enterText(_field('Overview'), 'Working-copy guidebook');
      await tester.enterText(
        _field('Vocabulary'),
        'uno = one\ndue = two\ntre = three\nquattro = four',
      );
      await tester.tap(find.text('Save Guidebook'));
      await _settle(tester);
      expect(find.byType(LessonEditorScreen), findsOneWidget);

      await tester.tap(find.byKey(const Key('guidebook-round-generator')));
      await _settle(tester);
      await tester.enterText(
        find.byKey(const Key('generator-round-count')),
        '1',
      );
      await tester.enterText(
        find.byKey(const Key('generator-exercise-count')),
        '3',
      );
      await tester.tap(find.byKey(const Key('generator-review-plan')));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('generator-generate')));
      await _settle(tester);
      expect(find.textContaining('Automatic audit: 0 errors'), findsOneWidget);
      await tester.tap(find.byKey(const Key('generator-approve')));
      await _settle(tester);
      expect(find.byType(LessonEditorScreen), findsOneWidget);
      expect(
        find.byKey(const Key('course-transaction-confirmation')),
        findsNothing,
      );

      await tester.tap(find.byKey(const Key('lesson-rounds-navigation')));
      await _settle(tester);
      await tester.tap(find.widgetWithText(FloatingActionButton, 'New round'));
      await _settle(tester);
      await tester.enterText(find.byType(TextFormField), 'Created round');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await _settle(tester);

      await tester.tap(find.byKey(const ValueKey('round-actions-round')));
      await _settle(tester);
      await tester.tap(find.text('Rename'));
      await _settle(tester);
      await tester.enterText(find.byType(TextFormField), 'Renamed round');
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await _settle(tester);

      await tester.tap(find.byKey(const ValueKey('round-actions-round_b')));
      await _settle(tester);
      await tester.tap(find.text('Delete'));
      await _settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await _settle(tester);
      final roundList = tester.widget<ReorderableListView>(
        find.byKey(const Key('lesson-rounds-list')),
      );
      roundList.onReorderItem!(1, 0);
      await _settle(tester);
      expect(
        find.byKey(const Key('course-transaction-confirmation')),
        findsNothing,
      );

      await tester.tap(find.byKey(const ValueKey('round')));
      await _settle(tester);
      await tester.tap(find.byKey(const ValueKey('exercise-actions-exercise')));
      await _settle(tester);
      await tester.tap(find.text('Edit').last);
      await _settle(tester);
      await tester.enterText(_field('Prompt / instruction'), 'Mixed edit');
      await tester.scrollUntilVisible(
        find.byKey(const Key('exercise-save')),
        350,
        scrollable: _editorScroll(),
      );
      await tester.tap(find.byKey(const Key('exercise-save')));
      await _settle(tester);

      await tester.tap(
        find.byKey(const ValueKey('exercise-actions-exercise_b')),
      );
      await _settle(tester);
      await tester.tap(find.text('Delete exercise'));
      await _settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await _settle(tester);

      await tester.tap(find.byKey(const Key('new-exercise')));
      await _settle(tester);
      await tester.enterText(_field('Prompt / instruction'), 'Created draft');
      await tester.enterText(_field('Question'), 'Choose.');
      await tester.enterText(_field('Answers'), 'Yes\nNo');
      await tester.enterText(_field('Correct answer number'), '1');
      await tester.scrollUntilVisible(
        find.byKey(const Key('exercise-save-draft')),
        350,
        scrollable: _editorScroll(),
      );
      await tester.tap(find.byKey(const Key('exercise-save-draft')));
      await _settle(tester);
      final exerciseList = tester.widget<ReorderableListView>(
        find.byType(ReorderableListView),
      );
      exerciseList.onReorderItem!(1, 0);
      await _settle(tester);
      await tester.tap(find.byKey(const Key('round-save-draft')));
      await _settle(tester);

      await _nestedBack(tester, LessonEditorScreen);
      await _nestedBack(tester, LessonManagementScreen);
      await _nestedBack(tester, CourseEditorScreen);

      await tester.tap(find.text('Run audit'));
      await _settle(tester);
      final audit = tester.widget<CourseAuditScreen>(
        find.byType(CourseAuditScreen),
      );
      expect(audit.course.title, 'Mixed transaction');
      await tester.tap(find.byType(BackButton).last);
      await _settle(tester);
      expect(
        find.byKey(const Key('course-transaction-confirmation')),
        findsNothing,
      );

      await tester.tap(find.byType(BackButton).last);
      await _settle(tester);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(
        find.byKey(const Key('course-transaction-confirmation')),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const Key('course-version-notes')),
        'mixed transaction note',
      );
      await tester.tap(find.byKey(const Key('confirm-course-changes')));
      await _settle(tester, frames: 24);

      final reloaded = (await service.listUserCourses()).single;
      expect(reloaded.courseVersion, '2');
      expect(reloaded.title, 'Mixed transaction');
      expect(reloaded.versionNotes, 'mixed transaction note');
      expect(
        reloaded.lessons.any((item) => item.lessonId == 'lesson_b'),
        isFalse,
      );
      final editedLesson = reloaded.lessons.singleWhere(
        (item) => item.lessonId == 'lesson',
      );
      expect(editedLesson.title, 'Renamed lesson');
      expect(editedLesson.guidebook.overview, 'Working-copy guidebook');
      expect(editedLesson.rounds.any((item) => item.id == 'round_b'), isFalse);
      expect(editedLesson.rounds, hasLength(3));
      final editedRound = editedLesson.rounds.singleWhere(
        (item) => item.id == 'round',
      );
      expect(editedRound.title, 'Renamed round');
      expect(
        editedRound.exercises.any((item) => item.id == 'exercise_b'),
        isFalse,
      );
      expect(
        editedRound.exercises.any((item) => item.prompt == 'Mixed edit'),
        isTrue,
      );
      expect(
        editedRound.exercises.any(
          (item) =>
              item.prompt == 'Created draft' &&
              item.publicationState == PublicationState.draft,
        ),
        isTrue,
      );
      expect(await backups.listBackups(mixed.courseId), hasLength(1));
    },
  );

  testWidgets(
    'Restore official version changes only the working copy until top-level choice',
    (tester) async {
      final official = (await tester.runAsync(
        () => CourseService().loadBundledCourse('IT'),
      ))!;
      final localResult = await service.confirmCourseTransaction(
        originalCourse: official,
        workingCourse: Course.fromJson({
          ...official.toJson(),
          'title': 'Local official title',
          'temporarySample': false,
        }),
        languageCode: 'IT',
        versionNotes: 'local official work',
      );
      expect(localResult.course.localCourseVersion, 1);
      expect(await backups.listBackups(official.courseId), hasLength(1));

      await _openEditor(
        tester,
        localResult.course,
        service,
        courseService: _StubCourseService(official),
      );
      await tester.tap(find.byType(PopupMenuButton<String>).first);
      await _settle(tester);
      await tester.tap(find.text('Restore official version'));
      await _settle(tester, frames: 24);

      expect(find.text('Local official title'), findsNothing);
      expect(find.text(official.title), findsWidgets);
      expect(
        find.byKey(const Key('course-transaction-confirmation')),
        findsNothing,
      );
      final stillPersisted = Course.fromJson(
        await service.applyToCourse('IT', official.toJson()),
      );
      expect(stillPersisted.title, 'Local official title');
      expect(stillPersisted.localCourseVersion, 1);

      await tester.tap(find.byType(BackButton).last);
      await _settle(tester);
      expect(
        find.byKey(const Key('course-transaction-confirmation')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const Key('cancel-course-changes')));
      await _settle(tester);
      final afterCancel = Course.fromJson(
        await service.applyToCourse('IT', official.toJson()),
      );
      expect(afterCancel.title, 'Local official title');
      expect(afterCancel.localCourseVersion, 1);
      expect(await backups.listBackups(official.courseId), hasLength(1));
    },
  );

  testWidgets('Cancel discards a mixed multi-level working copy', (
    tester,
  ) async {
    final mixed = _mixedCourse();
    await service.saveUserCourse(mixed);
    await _openEditor(tester, mixed, service);

    await tester.tap(find.text('Course info'));
    await _settle(tester);
    await tester.enterText(_field('Course name'), 'Cancel mixed title');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await _settle(tester);

    await tester.tap(find.byKey(const Key('course-editor-lessons-navigation')));
    await _settle(tester);
    await tester.tap(find.widgetWithText(FloatingActionButton, 'New lesson'));
    await _settle(tester);
    await tester.enterText(find.byType(TextField), 'Cancelled lesson');
    await tester.tap(find.widgetWithText(FilledButton, 'Create'));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('lesson')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('lesson-rounds-navigation')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('round-actions-round')));
    await _settle(tester);
    await tester.tap(find.text('Rename'));
    await _settle(tester);
    await tester.enterText(find.byType(TextFormField), 'Cancelled round');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('round')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('exercise-actions-exercise')));
    await _settle(tester);
    await tester.tap(find.text('Edit').last);
    await _settle(tester);
    await tester.enterText(
      _field('Prompt / instruction'),
      'Cancelled exercise',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('exercise-save-draft')),
      350,
      scrollable: _editorScroll(),
    );
    await tester.tap(find.byKey(const Key('exercise-save-draft')));
    await _settle(tester);

    await _nestedBack(tester, LessonRoundsScreen);
    await _nestedBack(tester, LessonEditorScreen);
    await _nestedBack(tester, LessonManagementScreen);
    await _nestedBack(tester, CourseEditorScreen);
    await tester.tap(find.byType(BackButton).last);
    await _settle(tester);
    expect(
      find.byKey(const Key('course-transaction-confirmation')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('course-version-notes')),
      'notes must also be cancelled',
    );
    await tester.tap(find.byKey(const Key('cancel-course-changes')));
    await _settle(tester);

    final reloaded = (await service.listUserCourses()).single;
    expect(reloaded.toJson(), mixed.toJson());
    expect(await backups.listBackups(mixed.courseId), isEmpty);
  });
}

Future<void> _openEditor(
  WidgetTester tester,
  Course course,
  CourseEditorService service, {
  CourseService? courseService,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 1500);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => FilledButton(
          onPressed: () => Navigator.of(context).push<CourseConfirmationResult>(
            MaterialPageRoute(
              builder: (_) => CourseEditorScreen(
                course: course,
                userCourse: true,
                editorService: service,
                courseService: courseService,
                clock: () => DateTime.utc(2026, 9, 4, 17),
              ),
            ),
          ),
          child: const Text('Open Editor'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open Editor'));
  await _settle(tester);
}

Future<void> _openExercise(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('course-editor-lessons-navigation')));
  await _settle(tester);
  await tester.tap(find.byKey(const ValueKey('lesson')));
  await _settle(tester);

  final lessonList = tester.widget<ListView>(
    find
        .descendant(
          of: find.byType(LessonEditorScreen),
          matching: find.byType(ListView),
        )
        .first,
  );
  final lessonChildren =
      (lessonList.childrenDelegate as SliverChildListDelegate).children;
  expect(
    (lessonChildren.first as ListTile).key,
    const Key('lesson-rounds-navigation'),
  );

  await tester.tap(find.byKey(const Key('lesson-rounds-navigation')));
  await _settle(tester);
  await tester.tap(find.byKey(const ValueKey('round')));
  await _settle(tester);
  await tester.tap(find.byKey(const ValueKey('exercise-actions-exercise')));
  await _settle(tester);
  await tester.tap(find.text('Edit').last);
  await _settle(tester);
  expect(find.byType(ExerciseEditorScreen), findsOneWidget);
}

Future<void> _nestedBack(WidgetTester tester, Type expected) async {
  await tester.tap(find.byType(BackButton).last);
  await _settle(tester);
  expect(
    find.byKey(const Key('course-transaction-confirmation')),
    findsNothing,
  );
  expect(find.byType(expected), findsOneWidget);
}

Future<void> _settle(WidgetTester tester, {int frames = 12}) async {
  for (var frame = 0; frame < frames; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Finder _editorScroll() => find
    .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
    .first;

Course _course() => Course(
  courseId: 'transaction_ui_course',
  originType: CourseOriginType.custom,
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Transaction UI',
  ttsLanguage: 'it-IT',
  version: '1',
  courseVersion: '1',
  lessons: [
    Lesson(
      lessonId: 'lesson',
      publicationState: PublicationState.draft,
      updatedAt: DateTime.utc(2026, 9, 4, 10),
      title: 'Lesson',
      rounds: [
        LearningRound(
          id: 'round',
          publicationState: PublicationState.draft,
          updatedAt: DateTime.utc(2026, 9, 4, 10),
          title: 'Round',
          exercises: [
            Exercise(
              id: 'exercise',
              publicationState: PublicationState.draft,
              updatedAt: DateTime.utc(2026, 9, 4, 10),
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
            ),
          ],
        ),
      ],
    ),
  ],
);

Course _mixedCourse() {
  final base = _course();
  final secondExercise = Exercise(
    id: 'exercise_b',
    publicationState: PublicationState.draft,
    updatedAt: DateTime.utc(2026, 9, 4, 10),
    type: 'choice',
    prompt: 'Second prompt',
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
  final firstRound = LearningRound.fromJson({
    ...base.lessons.single.rounds.single.toJson(),
    'content': [
      ...base.lessons.single.rounds.single.content.map((item) => item.toJson()),
      LearningContent.fromExercise(secondExercise).toJson(),
    ],
  });
  final secondRound = LearningRound.fromJson({
    ...firstRound.toJson(),
    'id': 'round_b',
    'title': 'Second round',
    'content': firstRound.content
        .map(
          (item) => {
            ...item.toJson(),
            'id': '${item.id}_round_b',
            if (item.exercise != null)
              'exercise': {
                ...item.exercise!.toJson(),
                'id': '${item.exercise!.id}_round_b',
              },
          },
        )
        .toList(),
  });
  final firstLesson = Lesson.fromJson({
    ...base.lessons.single.toJson(),
    'rounds': [firstRound.toJson(), secondRound.toJson()],
  });
  final secondLesson = Lesson.fromJson({
    ...firstLesson.toJson(),
    'lessonId': 'lesson_b',
    'title': 'Second lesson',
    'rounds': const [],
    'duel': {'id': 'duel_b', 'title': 'Second duel'},
  });
  return Course.fromJson({
    ...base.toJson(),
    'lessons': [firstLesson.toJson(), secondLesson.toJson()],
  });
}

class _MemoryBackupService extends CourseBackupService {
  _MemoryBackupService(Directory documents)
    : super(documentsDirectoryProvider: () async => documents);

  final List<CourseBackupRecord> records = [];

  @override
  Future<CourseBackupRecord> createBackup(
    Course course, {
    required DateTime backedUpAt,
    required String reason,
  }) async {
    final record = CourseBackupRecord(
      manifestFile: File('memory/${course.courseId}_${records.length}.json'),
      course: Course.fromJson(course.toJson()),
      checksum: CourseBackupService.courseChecksum(course),
      backedUpAtUtc: backedUpAt.toUtc(),
      reason: reason,
      assets: const [],
    );
    records.add(record);
    return record;
  }

  @override
  Future<List<CourseBackupRecord>> listBackups(String courseId) async =>
      records.where((record) => record.course.courseId == courseId).toList();
}

class _FailingCourseEditorService extends CourseEditorService {
  _FailingCourseEditorService(CourseBackupService backups)
    : super(backupService: backups);

  @override
  Future<CourseConfirmationResult> confirmCourseTransaction({
    required Course originalCourse,
    required Course workingCourse,
    required String languageCode,
    required String versionNotes,
    bool isNewCourse = false,
    DateTime? committedAt,
  }) async {
    throw StateError('simulated persistence failure');
  }
}

class _StubCourseService extends CourseService {
  _StubCourseService(this.official);

  final Course official;

  @override
  Future<Course> loadBundledCourse(String languageCode) async => official;
}
