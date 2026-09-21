import '../models/course_models.dart';

/// Read-only display values for Course Library rows. Nothing here is stored.
abstract final class CourseLibraryPresentation {
  /// `courseVersion` for Custom Courses, `officialCourseVersion` for Bundled
  /// and Publisher Courses; null when there is no meaningful value.
  static String? version(Course course) {
    final value =
        (course.originType.isOfficial
                ? course.officialCourseVersion
                : course.courseVersion)
            .trim();
    return value.isEmpty ? null : value;
  }

  /// The parsed `modifiedAtUtc` instant, or null when it is malformed.
  static DateTime? lastEdited(Course course) =>
      parseUtcInstant(course.modifiedAtUtc);

  /// The Course model refuses malformed timestamps, so null is defensive.
  static DateTime? parseUtcInstant(String value) =>
      DateTime.tryParse(value.trim())?.toUtc();

  /// `1 hour` / `N hours` from author metadata; null when not declared.
  static String? duration(Course course) =>
      switch (course.estimatedStudyHours) {
        null => null,
        1 => '1 hour',
        final hours => '$hours hours',
      };
}
