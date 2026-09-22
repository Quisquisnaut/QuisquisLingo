import '../models/course_models.dart';
import 'course_access_policy.dart';
import 'course_audit_service.dart';
import 'course_editor_service.dart';
import 'course_editor_transaction.dart';
import 'provisional_publication_service.dart';
import 'settings_service.dart';

/// Coordinates one Course Editor working copy and its final confirmation.
///
/// The transaction remains the sole owner of the original and working Course.
/// UI mode persistence and confirmation dialogs stay with the screen.
class CourseAuthoringSession {
  CourseAuthoringSession({
    required Course course,
    required CourseAccessCapabilities access,
    required CourseEditorService editorService,
    bool isNewCourse = false,
    DateTime Function()? clock,
  }) : _access = access,
       _editorService = editorService,
       _isNewCourse = isNewCourse,
       _clock = clock ?? DateTime.now,
       _transaction = CourseEditorTransaction(
         course,
         isNewCourse: isNewCourse,
         allowReadOnlyOfficial: access.readOnly,
       );

  final CourseAccessCapabilities _access;
  final CourseEditorService _editorService;
  final bool _isNewCourse;
  final DateTime Function() _clock;
  final CourseEditorTransaction _transaction;

  CourseEditorMode _editorMode = CourseEditorMode.viewOnly;
  CourseAuditResult? _lastAudit;
  bool _auditOutdated = true;
  bool _governanceChangedInEditMode = false;
  String _pendingVersionNotes = '';

  Course get originalCourse => _transaction.originalCourse;
  Course get workingCourse => _transaction.workingCourse;
  bool get hasChanges => _transaction.hasChanges;
  bool get canModify =>
      _access.canEditOriginal && _editorMode == CourseEditorMode.edit;
  CourseEditorMode get editorMode => _editorMode;
  CourseAuditResult? get lastAudit => _lastAudit;
  bool get auditOutdated => _auditOutdated;
  bool get governanceChangedInEditMode => _governanceChangedInEditMode;
  String get pendingVersionNotes => _pendingVersionNotes;

  /// Applies a mode selected in the UI or loaded from device settings.
  /// Stored Edit cannot grant permission that Course access has denied.
  CourseEditorMode setEditorMode(CourseEditorMode mode) {
    _editorMode = mode == CourseEditorMode.edit && !_access.canEditOriginal
        ? CourseEditorMode.viewOnly
        : mode;
    return _editorMode;
  }

  /// Stages a Course-level or nested-editor result as one working-copy update.
  void stageCourse(Course value, {bool governanceChanged = false}) {
    if (!canModify) {
      throw StateError('The Course Editor is not in Edit.');
    }
    final reconciled = const ProvisionalPublicationService().reconcile(
      value,
      updatedAt: _clock(),
      previous: workingCourse,
    );
    _transaction.replaceWorkingCourse(reconciled);
    if (governanceChanged) _governanceChangedInEditMode = true;
    _auditOutdated = true;
  }

  void markAuditOutdated() => _auditOutdated = true;

  CourseAuditResult runAudit() {
    final result = CourseAuditService().auditCourse(workingCourse);
    _lastAudit = result;
    _auditOutdated = false;
    return result;
  }

  void loadHistoricalCourse(Course historical) {
    _transaction.loadHistoricalCourse(historical);
    _auditOutdated = true;
  }

  void cancel() {
    _transaction.cancel();
    _pendingVersionNotes = '';
    _governanceChangedInEditMode = false;
    _auditOutdated = true;
  }

  Future<CourseConfirmationResult> confirm({
    required String languageCode,
    required String versionNotes,
  }) async {
    _pendingVersionNotes = versionNotes;
    final result = await _editorService.confirmCourseTransaction(
      originalCourse: originalCourse,
      workingCourse: workingCourse,
      languageCode: languageCode,
      versionNotes: versionNotes,
      isNewCourse: _isNewCourse,
      governanceChangesMadeInEditMode: _governanceChangedInEditMode,
      committedAt: _clock(),
    );
    _transaction.markConfirmed(result.course);
    _pendingVersionNotes = '';
    _governanceChangedInEditMode = false;
    _auditOutdated = true;
    return result;
  }
}
