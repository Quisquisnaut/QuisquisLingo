import '../models/course_draft_status.dart';
import '../models/course_models.dart';
import 'course_audit_service.dart';
import 'course_checksums.dart';
import 'trusted_publishers.dart';

/// Export as Publisher Course (Build 262 Revision 2,
/// `docs/PUBLISHER_COURSES_PLAN.md` 4.3): a custom Course its Maintainer or
/// assigned Team may publish, turned into an unsigned Publisher Course
/// (`externalOfficial`), the file `tools/sign_course.dart` starts from
/// (`docs/PUBLISHER_SIGNING_GUIDE.md` §7).
///
/// Every ID is kept, so a later export of the same Course is an update of
/// the same Publisher Course; its official version is the Course version,
/// which rises at every confirmed save (owner decision of 3 October 2026).
/// The stored Course is never changed.
abstract final class PublisherCourseExport {
  /// The distribution channel of an exported Publisher Course.
  static const distributionChannel = 'publisher';

  /// The reason given to a profile that neither maintains the Course nor
  /// belongs to its assigned Team.
  static const noAccessReason =
      'Only the Maintainer or assigned Team can publish this Course.';

  /// The publishers a Course can be exported for, one per publisher: the
  /// active keys of [registry] (by default the app's) and QuisquisLingo
  /// Courses, whose key may still be pending.
  static List<TrustedPublisherKey> publishers([TrustedPublishers? registry]) {
    final byId = <String, TrustedPublisherKey>{};
    for (final key in [
      ...(registry ?? TrustedPublishers.application()).keys,
      TrustedPublishers.quisquisLingoCourses,
    ]) {
      if (key.revoked) continue;
      byId.putIfAbsent(key.publisherId, () => key);
    }
    return List.unmodifiable(byId.values);
  }

  /// Why [course] cannot be exported as a Publisher Course; empty when it
  /// can. [hasOperationalAccess] is the active profile's access (Maintainer
  /// or assigned-Team member).
  static List<String> refusals(
    Course course, {
    required bool hasOperationalAccess,
    CourseAuditResult? audit,
  }) {
    if (course.originType != CourseOriginType.custom) {
      return const ['Only a custom Course can become a Publisher Course.'];
    }
    final errors = (audit ?? CourseAuditService().auditCourse(course)).count(
      AuditSeverity.error,
    );
    return [
      if (!hasOperationalAccess) noAccessReason,
      if (course.forkProvenance != null)
        'A Fork keeps the lineage of its source Course, which a Publisher '
            'Course cannot carry.',
      if (course.mergeProvenance != null)
        'A merged Course keeps the lineage of its sources, which a Publisher '
            'Course cannot carry.',
      if (course.courseVersion.isEmpty)
        'The Course has no Course version yet: confirm it once in the Course '
            'Editor.',
      if (course.publicationState != PublicationState.published)
        'The Course is not published: use Publish under Course delivery '
            'status in the Course Editor.',
      if (CourseDraftStatus.courseHasDraft(course))
        'The Course still has Draft content: publish or remove it in the '
            'Course Editor.',
      if (course.license.trim().isEmpty)
        'The Course states no License: set it in Course Info Editor.',
      if (errors > 0)
        'The Audit finds $errors ${errors == 1 ? 'error' : 'errors'}.',
    ];
  }

  /// [course] as an unsigned Publisher Course of [publisher], released
  /// [now]. Throws [ArgumentError] when [refusals] would refuse it for a
  /// reason of its own (access is the caller's).
  static Course build(
    Course course,
    TrustedPublisherKey publisher, {
    required DateTime now,
  }) {
    if (course.originType != CourseOriginType.custom ||
        course.forkProvenance != null ||
        course.mergeProvenance != null ||
        course.courseVersion.isEmpty) {
      throw ArgumentError('This Course cannot become a Publisher Course.');
    }
    final json = course.toJson()
      ..remove('maintainer')
      ..remove('assignedTeamId')
      ..remove('courseVersion')
      ..remove('versionNotes')
      ..remove('restoredFromVersion')
      ..remove('lastVersionEditorProfileId')
      ..remove('lastVersionEditorDisplayName');
    final unsigned = Course.fromJson({
      ...json,
      'originType': CourseOriginType.externalOfficial.name,
      'publisherId': publisher.publisherId,
      'publisherName': publisher.publisherName,
      'originalCourseCreator': CourseProvenanceIdentity.publisher(
        publisherId: publisher.publisherId,
        displayName: publisher.publisherName,
      ).toJson(),
      'officialCourseVersion': course.courseVersion,
      'officialReleaseDateUtc': now.toUtc().toIso8601String(),
      if (course.versionNotes.isNotEmpty)
        'officialReleaseNotes': course.versionNotes,
      'distributionChannel': distributionChannel,
      'publisherVerificationStatus':
          PublisherVerificationStatus.unverified.name,
      'temporarySample': false,
      // Replaced below by the checksum of the Course itself.
      'officialChecksum': '0' * 64,
    });
    return Course.fromJson({
      ...unsigned.toJson(),
      'officialChecksum': CourseChecksums.official(unsigned),
    });
  }
}
