import '../models/course_models.dart';
import 'profile_service.dart';
import 'team_service.dart';

class CourseAccessCapabilities {
  final bool canEditOriginal;
  final bool canDuplicate;
  final bool canFork;
  final bool canDelete;
  final bool isInsideOwnershipBoundary;

  const CourseAccessCapabilities({
    required this.canEditOriginal,
    required this.canDuplicate,
    required this.canFork,
    required this.canDelete,
    required this.isInsideOwnershipBoundary,
  });

  bool get readOnly => !canEditOriginal;
}

/// One authoritative Owner/Team-versus-license authorization policy.
class CourseAccessPolicy {
  CourseAccessPolicy({ProfileService? profileService, TeamService? teamService})
    : _profiles = profileService ?? ProfileService(),
      _teams = teamService ?? TeamService(profileService: profileService);

  final ProfileService _profiles;
  final TeamService _teams;

  Future<CourseAccessCapabilities> forCurrentProfile(Course course) async {
    final profileId = await _profiles.getActiveProfileId();
    final teamIds = profileId == null
        ? const <String>{}
        : (await _teams.teamsForProfile(
            profileId,
          )).map((team) => team.teamId).toSet();
    return evaluate(course, profileId: profileId, memberTeamIds: teamIds);
  }

  static CourseAccessCapabilities evaluate(
    Course course, {
    required String? profileId,
    Set<String> memberTeamIds = const {},
  }) {
    if (course.originType.isOfficial) {
      return CourseAccessCapabilities(
        canEditOriginal: false,
        canDuplicate: false,
        canFork:
            profileId != null &&
            course.derivativeWorksPolicy == DerivativeWorksPolicy.allowed,
        canDelete: false,
        isInsideOwnershipBoundary: false,
      );
    }
    final owner = course.ownership;
    final inside =
        profileId != null &&
        owner != null &&
        (owner.type == CourseOwnerType.individual
            ? owner.id == profileId
            : memberTeamIds.contains(owner.id));
    return CourseAccessCapabilities(
      canEditOriginal: inside,
      canDuplicate: inside,
      canFork:
          !inside &&
          profileId != null &&
          course.derivativeWorksPolicy == DerivativeWorksPolicy.allowed,
      canDelete: inside,
      isInsideOwnershipBoundary: inside,
    );
  }
}
