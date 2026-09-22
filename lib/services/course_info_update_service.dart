import '../models/course_models.dart';
import 'course_governance_service.dart';

/// Values accepted by the Course Info dialog after its field validation.
typedef CourseInfoChange = ({
  String title,
  List<CourseAuthor> authors,
  List<CourseRightsHolder> rightsHolders,
  List<CourseMediaAttribution> mediaAttributions,
  String license,
  DerivativeWorksPolicy derivativePolicy,
  String variant,
  String startLevel,
  String targetLevel,
  String description,
  String buyACoffeeUrl,
  int? estimatedStudyHours,
  int? minimumAge,
  List<String> keywords,
  CoursePublisherContact? publisherContact,
  int? minimumAppBuild,
  String flagCode,
  String flagImageBase64,
  String worldFlagId,
  String maintainerProfileId,
  String? assignedTeamId,
});

typedef CourseInfoUpdateResult = ({Course course, bool governanceChanged});

/// Applies a validated Course Info edit to an Editor working copy.
///
/// The caller stages [CourseInfoUpdateResult.course] in its existing Course
/// transaction. This operation does not persist a Course or create a version.
class CourseInfoUpdateService {
  CourseInfoUpdateService({CourseGovernanceService? governanceService})
    : _governanceService = governanceService ?? CourseGovernanceService();

  final CourseGovernanceService _governanceService;

  Future<CourseInfoUpdateResult> apply(
    Course currentCourse,
    CourseInfoChange change,
    String? actorProfileId,
  ) async {
    var governedCourse = currentCourse;
    if (governedCourse.assignedTeamId != change.assignedTeamId) {
      if (actorProfileId == null) {
        throw StateError('An active profile is required to assign a Team.');
      }
      governedCourse = await _governanceService.assignTeam(
        course: governedCourse,
        actorProfileId: actorProfileId,
        teamId: change.assignedTeamId,
        editMode: true,
        assignmentConfirmed: true,
      );
    }
    if (governedCourse.maintainer!.profileId != change.maintainerProfileId) {
      if (actorProfileId == null) {
        throw StateError(
          'An active profile is required to transfer the Course Maintainer.',
        );
      }
      governedCourse = await _governanceService.transferMaintainer(
        course: governedCourse,
        actorProfileId: actorProfileId,
        newMaintainerProfileId: change.maintainerProfileId,
        editMode: true,
      );
    }
    final governanceChanged =
        currentCourse.maintainer!.profileId !=
            governedCourse.maintainer!.profileId ||
        currentCourse.assignedTeamId != governedCourse.assignedTeamId;
    final descriptive = <String, Object?>{
      'estimatedStudyHours': change.estimatedStudyHours,
      'minimumAge': change.minimumAge,
      'keywords': change.keywords.isEmpty ? null : change.keywords,
      'publisherContact': change.publisherContact?.toJson(),
      'minimumAppBuild': change.minimumAppBuild,
    };
    final updated = Course.fromJson({
      // Cleared optional fields are omitted, never stored as null.
      ...governedCourse.toJson()
        ..removeWhere((key, _) => descriptive.containsKey(key)),
      for (final entry in descriptive.entries)
        if (entry.value != null) entry.key: entry.value,
      'title': change.title,
      'authors': change.authors.map((author) => author.toJson()).toList(),
      'rightsHolders': change.rightsHolders
          .map((holder) => holder.toJson())
          .toList(),
      'mediaAttributions': change.mediaAttributions
          .map((credit) => credit.toJson())
          .toList(),
      'license': change.license,
      'derivativeWorksPolicy': change.derivativePolicy.name,
      'languageVariant': change.variant,
      'startLevel': change.startLevel,
      'targetLevel': change.targetLevel,
      'courseDescription': change.description,
      'buyACoffeeUrl': change.buyACoffeeUrl,
      'flagCode': change.flagCode,
      'flagImageBase64': change.flagImageBase64,
      'worldFlagId': change.worldFlagId,
    });
    return (course: updated, governanceChanged: governanceChanged);
  }
}
