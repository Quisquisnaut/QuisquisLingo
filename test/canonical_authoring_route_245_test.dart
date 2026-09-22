import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_file_io.dart';

const _profileId = '12345678-1234-4234-9234-123456789abc';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('nested edit is adopted once and confirmed once at Course exit', (
    tester,
  ) async {
    final documents = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('qql_245_route_'),
    ))!;
    addTearDown(() async {
      if (await documents.exists()) await documents.delete(recursive: true);
    });
    SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [
        const LearnerProfile(
          learnerProfileId: _profileId,
          displayName: 'Route Author',
        ).encode(),
      ],
      ProfileService.activeProfileIdKey: _profileId,
      'course_editor_locked_CANONICAL_ROUTE_COURSE': false,
    });
    final backups = _RecordingBackupService(documents);
    final service = CourseEditorService(
      backupService: backups,
      clock: () => DateTime.utc(2026, 9, 22, 12),
    );
    final original = _course();
    await tester.runAsync(() => service.saveUserCourse(original));
    var clockCalls = 0;
    DateTime clock() =>
        DateTime.utc(2026, 9, 22, 12).add(Duration(seconds: ++clockCalls));

    await _useViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () =>
                Navigator.of(context).push<CourseConfirmationResult>(
                  MaterialPageRoute(
                    builder: (_) => CourseEditorScreen(
                      course: original,
                      userCourse: true,
                      editorService: service,
                      clock: clock,
                    ),
                  ),
                ),
            child: const Text('Open Course'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Course'));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('course-editor-lessons-navigation')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('lesson')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('lesson-rounds-navigation')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('round')));
    await _settle(tester);
    await _openExercise(tester);
    await tester.enterText(_field('Prompt / instruction'), 'Canonical edit');
    await tester.scrollUntilVisible(
      find.byKey(const Key('exercise-save')),
      350,
      scrollable: _editorScroll(),
    );
    await tester.tap(find.byKey(const Key('exercise-save')));
    await _settle(tester);
    expect(find.byType(RoundEditorScreen), findsOneWidget);
    final callsAfterSave = clockCalls;
    expect(callsAfterSave, greaterThan(0));

    await _backTo(tester, LessonRoundsScreen);
    await _backTo(tester, LessonEditorScreen);
    await _backTo(tester, LessonManagementScreen);
    await _backTo(tester, CourseEditorScreen);
    // Back navigation has no new authoring intent. Child callbacks and route
    // results must not independently restamp the same edit.
    expect(clockCalls, callsAfterSave);
    final storedBeforeConfirm = ((await tester.runAsync(
      service.listUserCourses,
    ))!).single;
    expect(storedBeforeConfirm.toJson(), original.toJson());
    expect(backups.records, isEmpty);

    await tester.tap(find.byType(BackButton).last);
    await _settle(tester);
    expect(
      find.byKey(const Key('course-transaction-confirmation')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('course-version-notes')),
      'One canonical edit',
    );
    await tester.tap(find.byKey(const Key('confirm-course-changes')));
    await tester.pumpUntilFileIoState(
      () => find.byType(CourseEditorScreen).evaluate().isEmpty,
    );
    final storedAfterConfirm = ((await tester.runAsync(
      service.listUserCourses,
    ))!).single;
    expect(storedAfterConfirm.courseVersion, '2');
    expect(
      storedAfterConfirm.lessons.single.rounds.single.exercises.single.prompt,
      'Canonical edit',
    );
    expect(storedAfterConfirm.publicationState, PublicationState.draft);
    expect(
      storedAfterConfirm.lessons.single.publicationState,
      PublicationState.published,
    );
    expect(
      storedAfterConfirm.lessons.single.rounds.single.publicationState,
      PublicationState.published,
    );
    expect(
      storedAfterConfirm
          .lessons
          .single
          .rounds
          .single
          .exercises
          .single
          .publicationState,
      PublicationState.published,
    );
    expect(backups.records, hasLength(1));
    expect(backups.records.single.course.toJson(), original.toJson());
  });

  testWidgets('standalone Round callback and route result describe one edit', (
    tester,
  ) async {
    final original = _course();
    final changes = <Course>[];
    LearningRound? returned;
    var clockCalls = 0;
    DateTime clock() =>
        DateTime.utc(2026, 9, 22, 12).add(Duration(seconds: ++clockCalls));
    await _useViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              returned = await Navigator.of(context).push<LearningRound>(
                MaterialPageRoute(
                  builder: (_) => RoundEditorScreen(
                    course: original,
                    lesson: original.lessons.single,
                    round: original.lessons.single.rounds.single,
                    roundIndex: 0,
                    onCourseChanged: changes.add,
                    clock: clock,
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
    await _openExercise(tester);
    await tester.enterText(_field('Prompt / instruction'), 'Standalone edit');
    await tester.scrollUntilVisible(
      find.byKey(const Key('exercise-save-draft')),
      350,
      scrollable: _editorScroll(),
    );
    await tester.tap(find.byKey(const Key('exercise-save-draft')));
    await _settle(tester);
    expect(changes, hasLength(1));
    final callsAfterSave = clockCalls;
    expect(
      changes.single.lessons.single.rounds.single.exercises.single.prompt,
      'Standalone edit',
    );

    await tester.tap(find.byType(BackButton).last);
    await _settle(tester);
    expect(returned, isNotNull);
    expect(
      returned!.content.single.toJson(),
      changes.single.lessons.single.rounds.single.content.single.toJson(),
    );
    expect(changes, hasLength(1));
    expect(clockCalls, callsAfterSave);
  });

  testWidgets('Course Audit Exercise save stages once before final confirm', (
    tester,
  ) async {
    final documents = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('qql_245_audit_route_'),
    ))!;
    addTearDown(() async {
      if (await documents.exists()) await documents.delete(recursive: true);
    });
    SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [
        const LearnerProfile(
          learnerProfileId: _profileId,
          displayName: 'Route Author',
        ).encode(),
      ],
      ProfileService.activeProfileIdKey: _profileId,
      'course_editor_locked_CANONICAL_ROUTE_COURSE': false,
    });
    final backups = _RecordingBackupService(documents);
    final service = CourseEditorService(
      backupService: backups,
      clock: () => DateTime.utc(2026, 9, 22, 12),
    );
    final original = _course();
    await tester.runAsync(() => service.saveUserCourse(original));
    var clockCalls = 0;
    DateTime clock() =>
        DateTime.utc(2026, 9, 22, 12).add(Duration(seconds: ++clockCalls));
    final issue = CourseAuditService()
        .auditCourse(original)
        .issues
        .firstWhere(
          (candidate) =>
              candidate.roundId == 'round' &&
              candidate.exerciseId == 'exercise',
        );

    await _useViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () =>
                Navigator.of(context).push<CourseConfirmationResult>(
                  MaterialPageRoute(
                    builder: (_) => CourseEditorScreen(
                      course: original,
                      userCourse: true,
                      editorService: service,
                      clock: clock,
                    ),
                  ),
                ),
            child: const Text('Open Course'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Course'));
    await _settle(tester);
    await tester.tap(find.text('Run audit'));
    await _settle(tester);
    expect(find.byType(CourseAuditScreen), findsOneWidget);
    final issueTile = find.text(issue.message).first;
    await tester.ensureVisible(issueTile);
    await tester.tap(issueTile);
    await _settle(tester);
    expect(find.byType(ExerciseEditorScreen), findsOneWidget);

    await tester.enterText(_field('Prompt / instruction'), 'Audit route edit');
    await tester.scrollUntilVisible(
      find.byKey(const Key('exercise-save-draft')),
      350,
      scrollable: _editorScroll(),
    );
    final callsBeforeSave = clockCalls;
    await tester.tap(find.byKey(const Key('exercise-save-draft')));
    await _settle(tester);
    expect(find.byType(CourseEditorScreen), findsOneWidget);
    expect(clockCalls, callsBeforeSave + 1);
    expect(
      ((await tester.runAsync(service.listUserCourses))!).single.toJson(),
      original.toJson(),
    );

    await tester.tap(find.byType(BackButton).last);
    await _settle(tester);
    expect(
      find.byKey(const Key('course-transaction-confirmation')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('confirm-course-changes')));
    await tester.pumpUntilFileIoState(
      () => find.byType(CourseEditorScreen).evaluate().isEmpty,
    );
    final stored = ((await tester.runAsync(service.listUserCourses))!).single;
    expect(stored.courseVersion, '2');
    expect(
      stored.lessons.single.rounds.single.exercises.single.prompt,
      'Audit route edit',
    );
    expect(backups.records, hasLength(1));
  });

  testWidgets('Course-root Exercise copy reaches its destination once', (
    tester,
  ) async {
    final documents = (await tester.runAsync(
      () => Directory.systemTemp.createTemp('qql_245_transfer_route_'),
    ))!;
    addTearDown(() async {
      if (await documents.exists()) await documents.delete(recursive: true);
    });
    SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [
        const LearnerProfile(
          learnerProfileId: _profileId,
          displayName: 'Route Author',
        ).encode(),
      ],
      ProfileService.activeProfileIdKey: _profileId,
      'course_editor_locked_CANONICAL_ROUTE_COURSE': false,
    });
    final backups = _RecordingBackupService(documents);
    final service = CourseEditorService(
      backupService: backups,
      clock: () => DateTime.utc(2026, 9, 22, 12),
    );
    final original = _courseWithDestination();
    await tester.runAsync(() => service.saveUserCourse(original));
    var clockCalls = 0;
    DateTime clock() =>
        DateTime.utc(2026, 9, 22, 12).add(Duration(seconds: ++clockCalls));

    await _useViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () =>
                Navigator.of(context).push<CourseConfirmationResult>(
                  MaterialPageRoute(
                    builder: (_) => CourseEditorScreen(
                      course: original,
                      userCourse: true,
                      editorService: service,
                      clock: clock,
                    ),
                  ),
                ),
            child: const Text('Open Course'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Course'));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('course-editor-lessons-navigation')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('lesson')));
    await _settle(tester);
    await tester.tap(find.byKey(const Key('lesson-rounds-navigation')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('round')));
    await _settle(tester);
    await tester.tap(find.byKey(const ValueKey('exercise-actions-exercise')));
    await _settle(tester);
    await tester.tap(find.text('Copy to…').last);
    await _settle(tester);
    await tester.tap(find.byKey(const Key('transfer-destination-lesson')));
    await _settle(tester);
    await tester.tap(find.text('Lesson 1: Lesson').last);
    await _settle(tester);
    await tester.tap(
      find.byKey(const ValueKey('transfer-destination-round-lesson')),
    );
    await _settle(tester);
    await tester.tap(
      find.text(original.lessons.single.rounds.last.displayTitle(1)).last,
    );
    await _settle(tester);
    await tester.tap(find.byKey(const Key('confirm-authoring-transfer')));
    await _settle(tester);
    expect(find.byType(RoundEditorScreen), findsOneWidget);
    final callsAfterTransfer = clockCalls;
    expect(callsAfterTransfer, greaterThan(0));

    await _backTo(tester, LessonRoundsScreen);
    await _backTo(tester, LessonEditorScreen);
    await _backTo(tester, LessonManagementScreen);
    await _backTo(tester, CourseEditorScreen);
    expect(clockCalls, callsAfterTransfer);
    expect(
      ((await tester.runAsync(service.listUserCourses))!).single.toJson(),
      original.toJson(),
    );
    await tester.tap(find.byType(BackButton).last);
    await _settle(tester);
    await tester.tap(find.byKey(const Key('confirm-course-changes')));
    await tester.pumpUntilFileIoState(
      () => find.byType(CourseEditorScreen).evaluate().isEmpty,
    );
    final stored = ((await tester.runAsync(service.listUserCourses))!).single;
    final source = stored.lessons.single.rounds.first;
    final destination = stored.lessons.single.rounds.last;
    expect(source.exercises.single.id, 'exercise');
    expect(destination.exercises, hasLength(1));
    expect(destination.exercises.single.id, isNot('exercise'));
    expect(destination.exercises.single.prompt, 'Original prompt');
    expect(stored.courseVersion, '2');
    expect(backups.records, hasLength(1));
  });

  testWidgets('pending Lesson section survives a no-change Rounds visit', (
    tester,
  ) async {
    final original = _course();
    final changed = <Course>[];
    Lesson? returned;
    await _useViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              returned = await Navigator.of(context).push<Lesson>(
                MaterialPageRoute(
                  builder: (_) => LessonEditorScreen(
                    course: original,
                    lesson: original.lessons.single,
                    onCourseChanged: changed.add,
                    clock: () => DateTime.utc(2026, 9, 22, 12),
                  ),
                ),
              );
            },
            child: const Text('Open Lesson'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Lesson'));
    await _settle(tester);
    await tester.scrollUntilVisible(
      find.byWidgetPredicate(
        (widget) =>
            widget is DropdownButtonFormField<String> &&
            widget.decoration.labelText == 'Section',
      ),
      250,
      scrollable: find
          .descendant(
            of: find.byKey(const Key('lesson-metadata-controls')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Old section').last);
    await _settle(tester);
    await tester.tap(find.text('New section').last);
    await _settle(tester);
    expect(changed, isEmpty);

    await tester.tap(find.byKey(const Key('lesson-rounds-navigation')));
    await _settle(tester);
    expect(find.byType(LessonRoundsScreen), findsOneWidget);
    await tester.tap(find.byType(BackButton).last);
    await _settle(tester);
    expect(find.byType(LessonEditorScreen), findsOneWidget);
    expect(changed, isEmpty);
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byWidgetPredicate(
              (widget) =>
                  widget is DropdownButtonFormField<String> &&
                  widget.decoration.labelText == 'Section',
            ),
          )
          .initialValue,
      'name:New section',
    );
    await tester.tap(find.byKey(const Key('save-lesson-draft')));
    await _settle(tester);
    expect(changed, hasLength(1));
    expect(changed.single.lessons.single.sectionName, 'New section');
    expect(
      changed.single.lessons.single.rounds.single.toJson(),
      original.lessons.single.rounds.single.toJson(),
    );

    expect(returned, isNotNull);
    expect(returned!.sectionName, 'New section');
    expect(original.lessons.single.sectionName, 'Old section');
  });
}

Future<void> _openExercise(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('exercise-actions-exercise')));
  await _settle(tester);
  await tester.tap(find.text('Edit').last);
  await _settle(tester);
  expect(find.byType(ExerciseEditorScreen), findsOneWidget);
}

Future<void> _backTo(WidgetTester tester, Type expected) async {
  await tester.tap(find.byType(BackButton).last);
  await _settle(tester);
  expect(find.byType(expected), findsOneWidget);
}

Future<void> _settle(WidgetTester tester) async {
  for (var frame = 0; frame < 12; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _useViewport(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 1500);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
}

Finder _field(String label) => find.byWidgetPredicate(
  (widget) => widget is TextField && widget.decoration?.labelText == label,
);

Finder _editorScroll() => find
    .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
    .first;

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
    courseId: 'canonical_route_course',
    originType: CourseOriginType.custom,
    originalCourseCreator: CourseProvenanceIdentity.qqlUser(
      profileId: _profileId,
      displayName: 'Route Author',
    ),
    maintainer: const CourseMaintainer(_profileId),
    originalCreatedAtUtc: '2026-09-22T09:00:00.000Z',
    publicationState: PublicationState.draft,
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Canonical Route Course',
    ttsLanguage: 'it-IT',
    courseVersion: '1',
    sectionNames: const ['Old section', 'New section'],
    lessons: [
      Lesson(
        lessonId: 'lesson',
        publicationState: PublicationState.draft,
        updatedAt: DateTime.utc(2026, 9, 22, 10),
        title: 'Lesson',
        section: true,
        sectionName: 'Old section',
        guidebook: Guidebook(
          content: [
            LearningContent.textual(
              id: 'guide_source',
              kind: 'explanation',
              role: 'overview',
              text: 'Reference text',
            ),
          ],
        ),
        rounds: [round],
      ),
    ],
  );
}

Course _courseWithDestination() {
  final course = _course();
  final lesson = course.lessons.single;
  final destination = LearningRound(
    id: 'destination-round',
    publicationState: PublicationState.draft,
    updatedAt: DateTime.utc(2026, 9, 22, 10),
    title: 'Destination',
    content: const [],
  );
  return Course.fromJson({
    ...course.toJson(),
    'lessons': [
      {
        ...lesson.toJson(),
        'rounds': [
          for (final round in lesson.rounds) round.toJson(),
          destination.toJson(),
        ],
      },
    ],
  });
}

class _RecordingBackupService extends CourseBackupService {
  _RecordingBackupService(Directory documents)
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
