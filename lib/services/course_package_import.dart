import '../models/course_models.dart';
import 'course_editor_service.dart';
import 'course_package_service.dart';

/// One Course package import, from the read package until the attempt ends.
///
/// The attempt owns the package's staged media. The screen picks the file,
/// shows the Audit, dialogs and results, and chooses one action here. Each
/// action installs through [CourseEditorService], which writes the package's
/// media into the destination Course's own folder and confirms the Course
/// under that Course's lock, keeping media whenever a stored Course may use
/// them. Every action, and [close], discards the staged media as soon as the
/// attempt ends — before a new Copy or Fork opens in its Editor.
class CoursePackageImport {
  CoursePackageImport(this._package, {required CourseEditorService editor})
    : _editor = editor;

  final CoursePackage _package;
  final CourseEditorService _editor;
  bool _started = false;
  Future<void>? _closed;

  Course get course => _package.course;

  /// True when the ZIP's files sat in one folder matching the ZIP's name.
  bool get hadMatchingFolderWrapper => _package.hadMatchingFolderWrapper;

  /// A new custom Course, or Replace / update of the same custom identity.
  Future<void> installCustomCourse() => _run(
    () => _editor.installImportedCustomCourse(course, package: _package),
  );

  Future<CourseConfirmationResult> copyAsNewCourse({required String title}) =>
      _run(
        () => _editor.createCopyAsNewCourse(
          source: course,
          title: title,
          package: _package,
        ),
      );

  Future<CourseConfirmationResult> fork() =>
      _run(() => _editor.createFork(source: course, package: _package));

  Future<OfficialCourseUpdateResult> installPublisherCourse({
    required bool confirmUnverifiedAssociation,
  }) => _run(
    () => _editor.installExternalOfficialUpdate(
      course,
      package: _package,
      confirmUnverifiedAssociation: confirmUnverifiedAssociation,
    ),
  );

  /// Ends the attempt without installing. Safe to call more than once.
  Future<void> close() => _closed ??= _package.discard();

  Future<T> _run<T>(Future<T> Function() install) async {
    if (_started || _closed != null) {
      throw StateError('This Course package import has already ended.');
    }
    _started = true;
    try {
      return await install();
    } finally {
      await close();
    }
  }
}
