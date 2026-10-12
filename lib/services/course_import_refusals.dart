import '../models/course_models.dart';
import 'course_access_policy.dart';
import 'course_audit_service.dart';
import 'course_privacy.dart';
import 'profile_service.dart';

/// What every import of a Course package refuses, whatever asks for it
/// (Build 271 Revision 4). Before, only the import screen refused someone
/// else's Private course and a Course whose Audit has errors, so any other
/// caller of an install could bring them in.
abstract final class CourseImportRefusals {
  static String privateCourse(Course course) =>
      '“${course.title}” is a Private course: only its Course Maintainer and the members of its assigned Team can import it or use it in a Merge. Ask its Maintainer for a copy that is not private.';

  static String auditErrors(int errors) =>
      'Course Audit found $errors error${errors == 1 ? '' : 's'}. Fix these errors before importing the course.';

  /// Refuses someone else's Private course (Build 259 Revision 8, owner
  /// decision: it would stay hidden for this profile) with a
  /// [FormatException].
  static Future<void> checkPrivate(
    Course course, {
    ProfileService? profiles,
  }) async {
    if (CoursePrivacy.isPrivate(course) &&
        !await CoursePrivacy(
          accessPolicy: CourseAccessPolicy(profileService: profiles),
        ).isVisible(course)) {
      throw FormatException(privateCourse(course));
    }
  }

  /// Refuses with a [FormatException] what no import may bring in: someone
  /// else's Private course, and a Course whose Audit has errors.
  static Future<void> check(Course course, {ProfileService? profiles}) async {
    await checkPrivate(course, profiles: profiles);
    final errors = CourseAuditService()
        .auditCourse(course)
        .count(AuditSeverity.error);
    if (errors > 0) throw FormatException(auditErrors(errors));
  }
}
