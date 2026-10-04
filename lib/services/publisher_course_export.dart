import '../models/course_draft_status.dart';
import '../models/course_models.dart';
import 'course_audit_service.dart';
import 'course_checksums.dart';
import 'trusted_publishers.dart';

/// The publisher a Course is exported for: the publisher ID and name the
/// QQL owner gave it when approving its signing key
/// (`docs/PUBLISHER_SIGNING_GUIDE.md` §§3–6), typed by the author. Any
/// publisher can be named; the app that imports the Course decides whether
/// it trusts the publisher's key.
class PublisherIdentity {
  const PublisherIdentity({
    required this.publisherId,
    required this.publisherName,
  });

  final String publisherId;
  final String publisherName;
}

/// Export as Publisher Course (Build 262 Revision 2,
/// `docs/PUBLISHER_COURSES_PLAN.md` 4.3): a custom Course its Maintainer or
/// assigned Team may publish, turned into an unsigned Publisher Course
/// (`externalOfficial`), the file `tools/sign_course.dart` starts from
/// (`docs/PUBLISHER_SIGNING_GUIDE.md` §7).
///
/// Every ID is kept, so a later export of the same Course is an update of
/// the same Publisher Course; its official version is the Course version,
/// which rises at every confirmed save (owner decision of 3 October 2026).
/// The stored Course is never changed. The publisher is any the author
/// names (owner decision of 4 October 2026), not a list of the app's.
abstract final class PublisherCourseExport {
  /// The distribution channel of an exported Publisher Course.
  static const distributionChannel = 'publisher';

  /// The reason given to a profile that neither maintains the Course nor
  /// belongs to its assigned Team.
  static const noAccessReason =
      'Only the Maintainer or assigned Team can publish this Course.';

  static final _publisherIdPattern = RegExp(r'^[A-Za-z0-9._-]+$');

  /// What is wrong with a typed publisher ID; null when it is usable or
  /// still empty.
  static String? publisherIdProblem(String publisherId) {
    final id = publisherId.trim();
    if (id.isEmpty || _publisherIdPattern.hasMatch(id)) return null;
    return 'A publisher ID has no spaces: only letters, digits, dots, '
        'hyphens and underscores.';
  }

  /// [publisherId] and [publisherName] as a [PublisherIdentity], trimmed;
  /// null while either is empty or the ID is not usable.
  static PublisherIdentity? identity(String publisherId, String publisherName) {
    final id = publisherId.trim();
    final name = publisherName.trim();
    if (id.isEmpty || name.isEmpty || publisherIdProblem(id) != null) {
      return null;
    }
    return PublisherIdentity(publisherId: id, publisherName: name);
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

  /// A warning, never a refusal, comparing [publisher] with the publishers
  /// [registry] (by default this app's) accepts at installation (owner
  /// request of 4 October 2026): an ID it does not know, an ID whose keys
  /// are all revoked, or a name other than the approved one, each of which
  /// would make the import fail. It names only the publisher the author
  /// typed; null when the Course would be accepted.
  static String? trustWarning(
    PublisherIdentity publisher, [
    TrustedPublishers? registry,
  ]) {
    final keys = (registry ?? TrustedPublishers.application()).keys
        .where((key) => key.publisherId == publisher.publisherId)
        .toList();
    if (keys.isEmpty) {
      return 'This version of QuisquisLingo does not accept this publisher '
          'yet: the Course can be exported and signed, but not installed '
          'until a version of the app has its signing key.';
    }
    final active = keys.where((key) => !key.revoked).toList();
    if (active.isEmpty) {
      return "QuisquisLingo has revoked this publisher's signing key: the "
          'Course cannot be installed until the publisher has a new approved '
          'key.';
    }
    if (active.any((key) => key.publisherName == publisher.publisherName)) {
      return null;
    }
    return 'This version of QuisquisLingo knows this publisher as '
        '“${active.first.publisherName}”: write the name exactly so, or the '
        'Course will be refused at installation.';
  }

  /// [course] as an unsigned Publisher Course of [publisher], released
  /// [now]. Throws [ArgumentError] when [refusals] would refuse it for a
  /// reason of its own (access is the caller's) or [identity] would not
  /// accept the publisher.
  static Course build(
    Course course,
    PublisherIdentity publisher, {
    required DateTime now,
  }) {
    if (course.originType != CourseOriginType.custom ||
        course.forkProvenance != null ||
        course.mergeProvenance != null ||
        course.courseVersion.isEmpty) {
      throw ArgumentError('This Course cannot become a Publisher Course.');
    }
    final checked = identity(publisher.publisherId, publisher.publisherName);
    if (checked == null) {
      throw ArgumentError('Name the publisher with a usable ID and name.');
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
      'publisherId': checked.publisherId,
      'publisherName': checked.publisherName,
      'originalCourseCreator': CourseProvenanceIdentity.publisher(
        publisherId: checked.publisherId,
        displayName: checked.publisherName,
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
