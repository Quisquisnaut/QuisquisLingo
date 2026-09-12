import '../models/course_models.dart';
import 'profile_service.dart';
import 'team_service.dart';

class ResolvedUserIdentity {
  final String profileId;
  final String label;

  const ResolvedUserIdentity({required this.profileId, required this.label});
}

class ResolvedCourseOwnership {
  final String ownerLabel;
  final String creatorLabel;
  final String? ownerId;
  final CourseOwnerType? ownerType;
  final String? assignedTeamLabel;
  final String? assignedTeamId;
  final List<ResolvedUserIdentity> teamLeaders;
  final List<ResolvedUserIdentity> teamMembers;

  const ResolvedCourseOwnership({
    required this.ownerLabel,
    required this.creatorLabel,
    required this.ownerId,
    required this.ownerType,
    required this.assignedTeamLabel,
    required this.assignedTeamId,
    required this.teamLeaders,
    required this.teamMembers,
  });
}

/// Resolves live Owner, Creator and assigned-Team names from authoritative
/// Profile and Team data. Course JSON retains only stable identities and never
/// caches presentation names or Team membership.
class CourseOwnerResolver {
  final ProfileService _profiles;
  final TeamService _teams;

  CourseOwnerResolver({
    ProfileService? profileService,
    TeamService? teamService,
  }) : _profiles = profileService ?? ProfileService(),
       _teams =
           teamService ??
           TeamService(profileService: profileService ?? ProfileService());

  Future<ResolvedCourseOwnership> resolve(Course course) async {
    if (course.originType.isOfficial) {
      final publisher = course.publisherName.trim();
      final label = publisher.isEmpty ? 'Official publisher' : publisher;
      return ResolvedCourseOwnership(
        ownerLabel: label,
        creatorLabel: label,
        ownerId: course.publisherId.trim().isEmpty ? null : course.publisherId,
        ownerType: null,
        assignedTeamLabel: null,
        assignedTeamId: null,
        teamLeaders: const [],
        teamMembers: const [],
      );
    }

    final ownership = course.ownership;
    final owner = ownership == null
        ? null
        : await _profiles.getProfileById(ownership.id);
    final creator = await _profiles.getProfileById(course.creatorProfileId);
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

    return ResolvedCourseOwnership(
      ownerLabel: owner?.presentationName ?? 'Unavailable local profile',
      creatorLabel: creator?.presentationName ?? 'Unavailable local profile',
      ownerId: ownership?.id,
      ownerType: ownership?.type,
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
