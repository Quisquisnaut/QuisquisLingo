import '../models/course_models.dart';
import 'course_access_policy.dart';

/// Private courses (Build 259 Revision 8, owner decisions of 1 October 2026).
///
/// A custom Course whose `temporarySample` flag is on is a **Private course**:
/// QQL shows it only to its Course Maintainer and the members of its assigned
/// Team, the people who can edit it. Admins are no exception. The JSON key
/// keeps its earlier name (owner decision: the flag stays, its display name
/// changes); official Courses are never private, whatever the flag says.
/// Export keeps the flag; Fork and Copy as New Course start non-private.
class CoursePrivacy {
  CoursePrivacy({CourseAccessPolicy? accessPolicy})
    : _access = accessPolicy ?? CourseAccessPolicy();

  final CourseAccessPolicy _access;

  static bool isPrivate(Course course) =>
      course.originType == CourseOriginType.custom && course.temporarySample;

  /// Whether the active profile may see [course] in QQL.
  Future<bool> isVisible(Course course) async =>
      !isPrivate(course) ||
      (await _access.forCurrentProfile(course)).hasOperationalAccess;

  /// Whether the profile [profileId] may see [course] in QQL.
  Future<bool> isVisibleTo(Course course, String? profileId) async =>
      !isPrivate(course) ||
      (await _access.forProfile(course, profileId)).hasOperationalAccess;

  /// [courses] without the Private courses the active profile may not see.
  Future<List<Course>> visible(Iterable<Course> courses) async => [
    for (final course in courses)
      if (await isVisible(course)) course,
  ];
}
