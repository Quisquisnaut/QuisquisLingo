import '../models/course_models.dart';

/// Course Library orderings, applied inside each section only.
enum CourseLibrarySort {
  title('Title'),
  language('Language'),
  maintainer('Maintainer'),
  mostRecent('Most recent'),
  duration('Duration');

  const CourseLibrarySort(this.label);
  final String label;
}

/// Read-only display values for Course Library rows. Nothing here is stored.
abstract final class CourseLibraryPresentation {
  /// The one text comparison policy: trimmed and case-insensitive.
  static int compareText(String a, String b) =>
      a.trim().toLowerCase().compareTo(b.trim().toLowerCase());

  /// [courses] in [sort] order. Every ordering ends with title, then
  /// courseId, so equal keys never swap between rebuilds.
  static List<Course> sorted(
    Iterable<Course> courses,
    CourseLibrarySort sort, {
    required String Function(Course course) maintainerOf,
  }) {
    int nullsLast<T extends Comparable<Object>>(T? a, T? b, bool descending) {
      if (a == null || b == null) return a == null ? (b == null ? 0 : 1) : -1;
      return descending ? b.compareTo(a) : a.compareTo(b);
    }

    int primary(Course a, Course b) => switch (sort) {
      CourseLibrarySort.title => 0,
      CourseLibrarySort.language =>
        compareText(a.targetLanguage, b.targetLanguage) != 0
            ? compareText(a.targetLanguage, b.targetLanguage)
            : compareText(a.sourceLanguage, b.sourceLanguage),
      CourseLibrarySort.maintainer => compareText(
        maintainerOf(a),
        maintainerOf(b),
      ),
      CourseLibrarySort.mostRecent => nullsLast(
        lastEdited(a),
        lastEdited(b),
        true,
      ),
      CourseLibrarySort.duration => nullsLast(
        a.estimatedStudyHours,
        b.estimatedStudyHours,
        false,
      ),
    };

    return [...courses]..sort((a, b) {
      final byKey = primary(a, b);
      if (byKey != 0) return byKey;
      final byTitle = compareText(a.title, b.title);
      return byTitle != 0 ? byTitle : a.courseId.compareTo(b.courseId);
    });
  }

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
