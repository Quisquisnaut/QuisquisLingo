import '../models/course_models.dart';
import 'course_file_store.dart';
import 'stored_course_reader.dart';

/// A custom Course a learner maintains, as an admin is told before deleting
/// that learner (Build 271 Revision 2 follow-up).
class MaintainedCourse {
  const MaintainedCourse({
    required this.courseId,
    required this.title,
    required this.shownName,
    required this.private,
    required this.hasTeam,
    required this.unopenable,
  });

  final String courseId;

  /// Its title, or its ID when it has none.
  final String title;

  /// How the refusal names it.
  final String shownName;

  /// A Private course: without its Maintainer only its Team sees it.
  final bool private;

  /// Whether a Team is assigned, whose members can still edit it.
  final bool hasTeam;

  /// A stored Course this version cannot open.
  final bool unopenable;
}

/// Protects custom-Course authorization when a learner profile is deleted.
abstract final class CourseMaintainerGuard {
  /// What ends every refusal of this guard: where an admin can go on
  /// (owner rule of 11 October 2026: a refusal is not a dead end for the
  /// admin).
  static const adminWayOut =
      'An admin can delete the profile anyway in Advanced (Admin) › '
      'Inventory, after a warning.';

  /// The custom Courses [learnerProfileId] maintains, those this version
  /// cannot open included (by the Maintainer their JSON names). Throws a
  /// [FormatException] when a stored file cannot be read at all, so that
  /// nobody can tell.
  static Future<List<MaintainedCourse>> maintainedBy(
    String learnerProfileId, {
    CourseFileStore? store,
  }) async {
    final stored = await (store ?? CourseFileStore()).readAll(
      CourseStoreKind.custom,
    );
    final maintained = <MaintainedCourse>[];
    for (final entry in stored.entries) {
      final read = StoredCourseReader.open(entry.key, entry.value);
      final course = read.course;
      if (course != null) {
        if (course.originType == CourseOriginType.custom &&
            course.maintainer?.profileId == learnerProfileId) {
          maintained.add(
            MaintainedCourse(
              courseId: course.courseId,
              title: course.title.trim().isEmpty
                  ? course.courseId
                  : course.title,
              shownName: course.title,
              private: course.temporarySample,
              hasTeam: course.assignedTeamId != null,
              unopenable: false,
            ),
          );
        }
        continue;
      }
      final unopenable = read.unopenable!;
      if (unopenable.maintainerProfileId == learnerProfileId) {
        maintained.add(
          MaintainedCourse(
            courseId: unopenable.courseId,
            title: unopenable.title ?? unopenable.courseId,
            shownName: unopenable.shownName,
            private: unopenable.private,
            hasTeam: unopenable.assignedTeamId != null,
            unopenable: true,
          ),
        );
      }
    }
    return maintained;
  }

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
    final List<MaintainedCourse> maintained;
    try {
      maintained = await maintainedBy(learnerProfileId, store: store);
    } on FormatException catch (error) {
      throw StateError(
        'A stored Course file cannot be read, so QQL cannot tell whether this '
        'profile maintains it: ${error.message} An admin can remove the file '
        'in Advanced (Admin) › Inventory.',
      );
    }
    if (maintained.isEmpty) return;
    final first = maintained.first;
    if (first.unopenable) {
      throw StateError(
        'This profile maintains ${first.shownName}, which this version '
        'cannot open. Remove it in Advanced (Admin) › Inventory, or import '
        'it again with the same Course ID, before deleting the profile. '
        '$adminWayOut',
      );
    }
    throw StateError(
      'This profile maintains ${first.shownName}. Change the Course Maintainer or '
      'delete the Course before deleting the profile. $adminWayOut',
    );
  }
}
