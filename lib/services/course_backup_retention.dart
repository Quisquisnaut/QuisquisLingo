import 'package:shared_preferences/shared_preferences.dart';

/// How many backups of a custom Course this device keeps when the learner
/// agrees to delete older ones (Build 270 Revision 9, owner decisions of 10
/// October 2026). One device-level key per Course ID, set in Course Info and
/// never written into the Course file; no key means every backup is kept
/// and nothing is ever asked. Nothing is deleted without a confirmation:
/// after a save that leaves more backups than this number, QQL asks.
/// Removed when the Course is deleted, by the custom-course reset and by
/// Wipe everything.
class CourseBackupRetention {
  static const keyPrefix = 'qql_course_backups_keep_';

  /// The numbers Course Info offers; any other stored value is ignored.
  static const choices = [5, 10, 20, 50];

  static String keyForCourseId(String courseId) =>
      '$keyPrefix${Uri.encodeComponent(courseId.trim())}';

  /// How many backups [courseId] keeps, or null to keep them all.
  Future<int?> keepFor(String courseId) async {
    final value = (await SharedPreferences.getInstance()).get(
      keyForCourseId(courseId),
    );
    return value is int && choices.contains(value) ? value : null;
  }

  /// Sets how many backups [courseId] keeps; null keeps them all.
  Future<void> setKeep(String courseId, int? keep) async {
    final preferences = await SharedPreferences.getInstance();
    if (keep == null) {
      await preferences.remove(keyForCourseId(courseId));
      return;
    }
    if (!choices.contains(keep)) {
      throw ArgumentError.value(keep, 'keep', 'Not one of $choices.');
    }
    await preferences.setInt(keyForCourseId(courseId), keep);
  }

  Future<void> forget(String courseId) async {
    await (await SharedPreferences.getInstance()).remove(
      keyForCourseId(courseId),
    );
  }
}
