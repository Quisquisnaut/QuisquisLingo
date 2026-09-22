import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_access_policy.dart';
import 'package:quisquislingo_app/services/course_authoring_session.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_hierarchy_update_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';

const _profileId = '12345678-1234-4234-9234-123456789abc';
final _confirmedAt = DateTime.utc(2026, 9, 22, 10, 30);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('staging changes only the working Course and makes Audit stale', () {
    final original = _course('Original');
    final session = _session(original, _RecordingEditorService());
    session.setEditorMode(CourseEditorMode.edit);
    final firstAudit = session.runAudit();
    expect(session.auditOutdated, isFalse);
    expect(session.lastAudit, same(firstAudit));

    session.stageCourse(_withTitle(session.workingCourse, 'Edited'));

    expect(session.workingCourse.title, 'Edited');
    expect(session.originalCourse.title, 'Original');
    expect(session.hasChanges, isTrue);
    expect(session.auditOutdated, isTrue);
    expect(session.lastAudit, same(firstAudit));
  });

  test('typed hierarchy update uses the current working Course once', () {
    final original = _course('Original');
    final session = _session(original, _RecordingEditorService());
    session.setEditorMode(CourseEditorMode.edit);
    session.stageCourse(_withTitle(session.workingCourse, 'Edited'));

    session.applyHierarchyUpdate(
      ReplaceLessons([
        Lesson(lessonId: 'new-lesson', title: 'New Lesson', rounds: const []),
      ]),
    );

    expect(session.workingCourse.title, 'Edited');
    expect(session.workingCourse.lessons.single.lessonId, 'new-lesson');
    expect(session.originalCourse.lessons, isEmpty);
    expect(session.hasChanges, isTrue);
  });

  test('read-only access cannot activate Edit or stage a Course', () {
    final original = _course('Original');
    final session = CourseAuthoringSession(
      course: original,
      access: _access(false),
      editorService: _RecordingEditorService(),
    );

    expect(
      session.setEditorMode(CourseEditorMode.edit),
      CourseEditorMode.viewOnly,
    );
    expect(session.canModify, isFalse);
    expect(
      () => session.stageCourse(_withTitle(original, 'Forbidden')),
      throwsStateError,
    );
    expect(session.workingCourse.title, 'Original');
  });

  test('a rejected stage does not mark governance or Audit stale', () {
    final session = _session(_course('Original'), _RecordingEditorService());
    session.setEditorMode(CourseEditorMode.edit);
    session.runAudit();
    final differentIdentity = Course.fromJson({
      ...session.workingCourse.toJson(),
      'courseId': 'different-course',
    });

    expect(
      () => session.stageCourse(differentIdentity, governanceChanged: true),
      throwsArgumentError,
    );
    expect(session.governanceChangedInEditMode, isFalse);
    expect(session.workingCourse.title, 'Original');
    expect(session.auditOutdated, isFalse);
  });

  test(
    'cancel restores original and clears governance and pending notes',
    () async {
      final service = _RecordingEditorService()..fail = true;
      final session = _session(_course('Original'), service);
      session.setEditorMode(CourseEditorMode.edit);
      session.stageCourse(
        _withTitle(session.workingCourse, 'Edited'),
        governanceChanged: true,
      );
      await expectLater(
        session.confirm(languageCode: 'IT', versionNotes: 'Pending'),
        throwsStateError,
      );
      expect(session.governanceChangedInEditMode, isTrue);
      expect(session.pendingVersionNotes, 'Pending');

      session.cancel();

      expect(session.workingCourse.title, 'Original');
      expect(session.hasChanges, isFalse);
      expect(session.governanceChangedInEditMode, isFalse);
      expect(session.pendingVersionNotes, isEmpty);
      expect(session.auditOutdated, isTrue);
    },
  );

  test(
    'history loads content while retaining active version and becomes stale',
    () {
      final session = _session(
        _course('Current', version: '6'),
        _RecordingEditorService(),
      );
      session.setEditorMode(CourseEditorMode.edit);
      session.runAudit();

      session.loadHistoricalCourse(_course('Historical', version: '3'));

      expect(session.workingCourse.title, 'Historical');
      expect(session.workingCourse.courseVersion, '6');
      expect(session.workingCourse.restoredFromVersion, 3);
      expect(session.originalCourse.title, 'Current');
      expect(session.auditOutdated, isTrue);
    },
  );

  test('history loading leaves permission decisions to the UI', () {
    final session = _session(
      _course('Current', version: '6'),
      _RecordingEditorService(),
    );

    session.loadHistoricalCourse(_course('Historical', version: '3'));

    expect(session.workingCourse.title, 'Historical');
    expect(session.workingCourse.courseVersion, '6');
  });

  test('failed confirmation retains the working copy and its notes', () async {
    final service = _RecordingEditorService()..fail = true;
    final session = _session(_course('Original'), service);
    session.setEditorMode(CourseEditorMode.edit);
    session.stageCourse(_withTitle(session.workingCourse, 'Edited'));

    await expectLater(
      session.confirm(languageCode: 'IT', versionNotes: 'Keep these notes'),
      throwsStateError,
    );

    expect(service.calls, 1);
    expect(session.workingCourse.title, 'Edited');
    expect(session.originalCourse.title, 'Original');
    expect(session.hasChanges, isTrue);
    expect(session.pendingVersionNotes, 'Keep these notes');
  });

  test(
    'confirmation forwards one complete transaction then resets session',
    () async {
      final service = _RecordingEditorService();
      final session = _session(_course('Original'), service, isNewCourse: true);
      session.setEditorMode(CourseEditorMode.edit);
      session.stageCourse(
        _withTitle(session.workingCourse, 'Edited'),
        governanceChanged: true,
      );
      final result = await session.confirm(
        languageCode: 'IT',
        versionNotes: 'First version',
      );

      expect(service.calls, 1);
      expect(service.original?.title, 'Original');
      expect(service.working?.title, 'Edited');
      expect(service.languageCode, 'IT');
      expect(service.versionNotes, 'First version');
      expect(service.isNewCourse, isTrue);
      expect(service.governanceChanged, isTrue);
      expect(service.committedAt, _confirmedAt);
      expect(result.course.title, 'Confirmed');
      expect(session.originalCourse.title, 'Confirmed');
      expect(session.workingCourse.title, 'Confirmed');
      expect(session.hasChanges, isFalse);
      expect(session.governanceChangedInEditMode, isFalse);
      expect(session.pendingVersionNotes, isEmpty);
    },
  );

  test('a new Course can confirm before the Edit setting has loaded', () async {
    final service = _RecordingEditorService();
    final session = _session(_course('New'), service, isNewCourse: true);

    final result = await session.confirm(languageCode: 'IT', versionNotes: '');

    expect(result.course.title, 'Confirmed');
    expect(service.calls, 1);
  });
}

CourseAuthoringSession _session(
  Course course,
  _RecordingEditorService service, {
  bool isNewCourse = false,
}) => CourseAuthoringSession(
  course: course,
  access: _access(true),
  editorService: service,
  isNewCourse: isNewCourse,
  clock: () => _confirmedAt,
);

CourseAccessCapabilities _access(bool canEdit) => CourseAccessCapabilities(
  canEditOriginal: canEdit,
  canCopyAsNewCourse: canEdit,
  canFork: !canEdit,
  canDelete: canEdit,
  hasOperationalAccess: canEdit,
  canTransferMaintainership: canEdit,
  canAssignTeam: canEdit,
);

Course _course(String title, {String version = '6'}) => Course(
  courseId: 'qql-245-session',
  originalCourseCreator: CourseProvenanceIdentity.qqlUser(
    profileId: _profileId,
    displayName: 'Original creator',
  ),
  maintainer: const CourseMaintainer(_profileId),
  originType: CourseOriginType.custom,
  originalCreatedAtUtc: '2026-09-01T00:00:00.000Z',
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: title,
  ttsLanguage: 'it-IT',
  courseVersion: version,
  lessons: const [],
);

Course _withTitle(Course course, String title) =>
    Course.fromJson({...course.toJson(), 'title': title});

class _RecordingEditorService extends CourseEditorService {
  bool fail = false;
  int calls = 0;
  Course? original;
  Course? working;
  String? languageCode;
  String? versionNotes;
  bool? isNewCourse;
  bool? governanceChanged;
  DateTime? committedAt;

  @override
  Future<CourseConfirmationResult> confirmCourseTransaction({
    required Course originalCourse,
    required Course workingCourse,
    required String languageCode,
    required String versionNotes,
    bool isNewCourse = false,
    bool governanceChangesMadeInEditMode = false,
    DateTime? committedAt,
  }) async {
    calls += 1;
    original = originalCourse;
    working = workingCourse;
    this.languageCode = languageCode;
    this.versionNotes = versionNotes;
    this.isNewCourse = isNewCourse;
    governanceChanged = governanceChangesMadeInEditMode;
    this.committedAt = committedAt;
    if (fail) throw StateError('simulated persistence failure');
    return CourseConfirmationResult(
      course: _withTitle(workingCourse, 'Confirmed'),
      backupPath: null,
      hadPreviousVersion: !isNewCourse,
    );
  }
}
