import '../models/course_models.dart';
import 'profile_service.dart';
import 'team_service.dart';

class ResolvedCourseOwnership {
  final String ownerLabel;
  final String creatorLabel;
  final String? ownerId;
  final CourseOwnerType? ownerType;

  const ResolvedCourseOwnership({
    required this.ownerLabel,
    required this.creatorLabel,
    required this.ownerId,
    required this.ownerType,
  });
}

/// Resolves live Owner/Creator names from authoritative Profile and Team data.
/// Course JSON retains only stable ownership identity and never caches a Team
/// display name.
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
      );
    }

    final ownership = course.ownership;
    var ownerLabel = 'Unsupported custom course (Owner missing)';
    if (ownership?.type == CourseOwnerType.team) {
      final team = await _teams.teamById(ownership!.id);
      ownerLabel = team == null
          ? 'Unavailable Team'
          : '${team.displayName} (Team)';
    } else if (ownership?.type == CourseOwnerType.individual) {
      final profile = await _profiles.getProfileById(ownership!.id);
      ownerLabel = profile == null
          ? 'Unavailable local profile'
          : profile.displayName;
    }

    final creator = await _profiles.getProfileById(course.creatorProfileId);
    return ResolvedCourseOwnership(
      ownerLabel: ownerLabel,
      creatorLabel: creator == null
          ? 'Unavailable local profile'
          : creator.displayName,
      ownerId: ownership?.id,
      ownerType: ownership?.type,
    );
  }
}
