import '../models/course_models.dart';
import 'course_file_store.dart';
import 'stored_course_reader.dart';

/// Protects custom-Course authorization when a learner profile is deleted.
abstract final class CourseMaintainerGuard {
  /// Asynchronous because custom Courses are stored one file per Course; the
  /// previous synchronous form read a single SharedPreferences value.
  ///
  /// A stored file that cannot be read at all still refuses: QQL cannot tell
  /// whether this learner maintains it. A Course this version cannot open
  /// counts by the Maintainer its JSON names (Build 266 Revision 2: one such
  /// Course used to refuse every learner's deletion).
  static Future<void> ensureProfileDoesNotMaintainCourses(
    String learnerProfileId, {
    CourseFileStore? store,
  }) async {
    final Map<String, dynamic> stored;
    try {
      stored = await (store ?? CourseFileStore()).readAll(
        CourseStoreKind.custom,
      );
    } on FormatException catch (error) {
      throw StateError(
        'A stored Course file cannot be read, so QQL cannot tell whether this '
        'profile maintains it: ${error.message} An admin can remove the file '
        'in Advanced (Admin) › Inventory.',
      );
    }
    for (final entry in stored.entries) {
      final read = StoredCourseReader.open(entry.key, entry.value);
      final course = read.course;
      if (course != null) {
        if (course.originType == CourseOriginType.custom &&
            course.maintainer?.profileId == learnerProfileId) {
          throw StateError(
            'This profile maintains ${course.title}. Change the Course Maintainer or delete the Course before deleting the profile.',
          );
        }
        continue;
      }
      final unopenable = read.unopenable!;
      if (unopenable.maintainerProfileId == learnerProfileId) {
        throw StateError(
          'This profile maintains ${unopenable.shownName}, which this version '
          'cannot open. Remove it in Advanced (Admin) › Inventory, or import '
          'it again with the same Course ID, before deleting the profile.',
        );
      }
    }
  }
}
