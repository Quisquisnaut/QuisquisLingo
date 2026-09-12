import '../models/course_models.dart';
import 'profile_service.dart';
import 'team_service.dart';

class ResolvedUserIdentity {
  final String profileId;
  final String label;

  const ResolvedUserIdentity({required this.profileId, required this.label});
}

class ResolvedCourseGovernance {
  final String maintainerLabel;
  final String originalCreatorLabel;
  final String? maintainerProfileId;
  final String? originalCreatorProfileId;
  final String? assignedTeamLabel;
  final String? assignedTeamId;
  final List<ResolvedUserIdentity> teamLeaders;
  final List<ResolvedUserIdentity> teamMembers;

  const ResolvedCourseGovernance({
    required this.maintainerLabel,
    required this.originalCreatorLabel,
    required this.maintainerProfileId,
    required this.originalCreatorProfileId,
    required this.assignedTeamLabel,
    required this.assignedTeamId,
    required this.teamLeaders,
    required this.teamMembers,
  });
}

/// Resolves live QQL identities and assigned-Team names for presentation.
///
/// Course JSON stores stable identities and immutable fallback provenance;
/// authorization remains in [CourseAccessPolicy], not this resolver.
class CourseGovernanceResolver {
  final ProfileService _profiles;
  final TeamService _teams;

  CourseGovernanceResolver({
    ProfileService? profileService,
    TeamService? teamService,
  }) : _profiles = profileService ?? ProfileService(),
       _teams =
           teamService ??
           TeamService(profileService: profileService ?? ProfileService());

  Future<ResolvedCourseGovernance> resolve(Course course) async {
    if (course.originType.isOfficial) {
      return ResolvedCourseGovernance(
        maintainerLabel: 'Not applicable',
        originalCreatorLabel: course.originalCourseCreator.displayName,
        maintainerProfileId: null,
        originalCreatorProfileId: null,
        assignedTeamLabel: null,
        assignedTeamId: null,
        teamLeaders: const [],
        teamMembers: const [],
      );
    }

    final maintainer = course.maintainer == null
        ? null
        : await _profiles.getProfileById(course.maintainer!.profileId);
    final originalCreator =
        course.originalCourseCreator.type ==
            CourseProvenanceIdentityType.qqlUser
        ? await _profiles.getProfileById(course.originalCourseCreator.id)
        : null;
    final assignedTeamId = course.assignedTeamId;
    final assignedTeam = assignedTeamId == null
        ? null
        : await _teams.teamById(assignedTeamId);

    Future<ResolvedUserIdentity> resolveUser(String profileId) async {
      final profile = await _profiles.getProfileById(profileId);
      return ResolvedUserIdentity(
        profileId: profileId,
        label: profile?.presentationName ?? 'Unavailable local profile',
      );
    }

    return ResolvedCourseGovernance(
      maintainerLabel:
          maintainer?.presentationName ?? 'Unavailable local profile',
      originalCreatorLabel:
          originalCreator?.presentationName ??
          course.originalCourseCreator.displayName,
      maintainerProfileId: course.maintainer?.profileId,
      originalCreatorProfileId:
          course.originalCourseCreator.type ==
              CourseProvenanceIdentityType.qqlUser
          ? course.originalCourseCreator.id
          : null,
      assignedTeamLabel: assignedTeamId == null
          ? null
          : assignedTeam?.displayName ?? 'Unavailable Team',
      assignedTeamId: assignedTeamId,
      teamLeaders: assignedTeam == null
          ? const []
          : [
              for (final profileId in assignedTeam.leadProfileIds)
                await resolveUser(profileId),
            ],
      teamMembers: assignedTeam == null
          ? const []
          : [
              for (final profileId in assignedTeam.memberProfileIds)
                if (!assignedTeam.hasLead(profileId))
                  await resolveUser(profileId),
            ],
    );
  }
}
