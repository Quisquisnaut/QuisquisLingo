import 'settings_service.dart';

/// Owns Course Editor preferences that are written immediately on this device.
///
/// These settings are separate from the Course authoring working copy and its
/// final confirmation. SettingsService retains the persisted keys and values.
class CourseEditorDeviceState {
  CourseEditorDeviceState({SettingsService? settings})
    : _settings = settings ?? SettingsService();

  final SettingsService _settings;

  Future<CourseEditorMode> openingMode(
    String courseId, {
    required bool canEditOriginal,
  }) async {
    final remembered = await _settings.hasCourseEditorMode(courseId);
    final mode = await _settings.getCourseEditorMode(courseId);
    // The first opening keeps the learner's opening mode for this Course, so
    // changing that default later leaves Courses already opened alone
    // (Build 261 Revision 1, owner decision of 1 October 2026).
    if (!remembered) await _settings.setCourseEditorMode(courseId, mode);
    if (!canEditOriginal && mode == CourseEditorMode.edit) {
      return CourseEditorMode.viewOnly;
    }
    return mode;
  }

  Future<void> setMode(String courseId, CourseEditorMode mode) =>
      _settings.setCourseEditorMode(courseId, mode);

  Future<bool> hasSeenViewOnlyNotice(String courseId) =>
      _settings.hasSeenCourseEditorViewNotice(courseId);

  Future<void> markViewOnlyNoticeSeen(String courseId) =>
      _settings.markCourseEditorViewNoticeSeen(courseId);

  /// Runs the opening maintenance check when its per-code date is due.
  /// The date is recorded after [check] returns, including when no orphans are
  /// found or the author keeps them. Manual Audit does not call this method.
  Future<void> runAutomaticOrphanCheck({
    required String courseCode,
    required bool canEditOriginal,
    required CourseEditorMode mode,
    required Future<void> Function() check,
  }) async {
    if (canEditOriginal &&
        mode == CourseEditorMode.edit &&
        await _settings.isAudioOrphanCheckDue(courseCode)) {
      await check();
      await _settings.markAudioOrphanCheckRun(courseCode);
    }
  }
}
