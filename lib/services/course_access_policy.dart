import '../models/course_models.dart';
import 'profile_service.dart';
import 'team_service.dart';

class CourseAccessCapabilities {
  final bool canEditOriginal;
  final bool canDuplicate;
  final bool canFork;
  final bool canDelete;
  final bool isInsideOwnershipBoundary;
  final bool canTransferOwnership;
  final bool canAssignTeam;
  final String? editDeniedReason;

  const CourseAccessCapabilities({
    required this.canEditOriginal,
    required this.canDuplicate,
    required this.canFork,
    required this.canDelete,
    required this.isInsideOwnershipBoundary,
    required this.canTransferOwnership,
    required this.canAssignTeam,
    this.editDeniedReason,
  });

  bool get readOnly => !canEditOriginal;

  /// Lets a Course Creator finish the one unconfirmed creation transaction
  /// after selecting a different individual as the initial Owner.
  CourseAccessCapabilities copyForUnconfirmedCreator() =>
      CourseAccessCapabilities(
        canEditOriginal: true,
        canDuplicate: false,
        canFork: false,
        canDelete: false,
        isInsideOwnershipBoundary: true,
        canTransferOwnership: canTransferOwnership,
        canAssignTeam: canAssignTeam,
      );

  String get effectiveEditDeniedReason =>
      editDeniedReason ??
      'You do not have permission to edit this course. Only its Owner or a member of its assigned Team can edit the original.';
}

/// One authoritative Owner/assigned-Team-versus-license authorization policy.
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
        canTransferOwnership: false,
        canAssignTeam: false,
        editDeniedReason:
            'Official courses are read-only. Their original content cannot be edited.',
      );
    }
    final isOwner = profileId != null && course.ownership?.id == profileId;
    final isAssignedTeamMember =
        profileId != null &&
        course.assignedTeamId != null &&
        memberTeamIds.contains(course.assignedTeamId);
    final inside = isOwner || isAssignedTeamMember;
    return CourseAccessCapabilities(
      canEditOriginal: inside,
      canDuplicate: inside,
      canFork:
          !inside &&
          profileId != null &&
          course.derivativeWorksPolicy == DerivativeWorksPolicy.allowed,
      canDelete: inside,
      isInsideOwnershipBoundary: inside,
      canTransferOwnership: isOwner,
      canAssignTeam: isOwner,
      editDeniedReason: inside
          ? null
          : 'You do not have permission to edit this course. Only its individual Owner or a member of its assigned Team can edit the original.',
    );
  }
}
