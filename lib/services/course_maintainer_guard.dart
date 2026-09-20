import '../models/course_models.dart';
import 'course_file_store.dart';

/// Protects custom-Course authorization when a learner profile is deleted.
abstract final class CourseMaintainerGuard {
  /// Asynchronous because custom Courses are stored one file per Course; the
  /// previous synchronous form read a single SharedPreferences value.
  static Future<void> ensureProfileDoesNotMaintainCourses(
    String learnerProfileId, {
    CourseFileStore? store,
  }) async {
    final stored = await (store ?? CourseFileStore()).readAll(
      CourseStoreKind.custom,
    );
    for (final entry in stored.entries) {
      final record = entry.value;
      if (record is! Map || record['course'] is! Map) {
        throw FormatException('Stored custom Course ${entry.key} is invalid.');
      }
      final course = Course.fromJson(
        Map<String, dynamic>.from(record['course'] as Map),
      );
      if (course.originType == CourseOriginType.custom &&
          course.maintainer?.profileId == learnerProfileId) {
        throw StateError(
          'This profile maintains ${course.title}. Change the Course Maintainer or delete the Course before deleting the profile.',
        );
      }
    }
  }
}
