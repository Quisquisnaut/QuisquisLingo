import '../models/course_models.dart';
import 'profile_service.dart';
import 'team_service.dart';

class CourseAccessCapabilities {
  final bool canEditOriginal;
  final bool canCopyAsNewCourse;
  final bool canFork;
  final bool canDelete;
  final bool hasOperationalAccess;
  final bool canTransferMaintainership;
  final bool canAssignTeam;
  final String? editDeniedReason;

  const CourseAccessCapabilities({
    required this.canEditOriginal,
    required this.canCopyAsNewCourse,
    required this.canFork,
    required this.canDelete,
    required this.hasOperationalAccess,
    required this.canTransferMaintainership,
    required this.canAssignTeam,
    this.editDeniedReason,
  });

  bool get readOnly => !canEditOriginal;

  /// Lets an Original Course Creator finish the one unconfirmed creation
  /// transaction after selecting a different initial Course Maintainer.
  CourseAccessCapabilities copyForUnconfirmedCreator() =>
      CourseAccessCapabilities(
        canEditOriginal: true,
        canCopyAsNewCourse: false,
        canFork: false,
        canDelete: false,
        hasOperationalAccess: true,
        canTransferMaintainership: canTransferMaintainership,
        canAssignTeam: canAssignTeam,
      );

  String get effectiveEditDeniedReason =>
      editDeniedReason ??
      'You do not have permission to edit this Course. Only its Maintainer or a member of its assigned Team can edit it.';
}

/// One authoritative Maintainer/assigned-Team-versus-license authorization
/// policy.
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
        canCopyAsNewCourse: false,
        canFork:
            profileId != null &&
            course.derivativeWorksPolicy == DerivativeWorksPolicy.allowed,
        canDelete: false,
        hasOperationalAccess: false,
        canTransferMaintainership: false,
        canAssignTeam: false,
        editDeniedReason:
            'Official courses are read-only. Their original content cannot be edited.',
      );
    }
    final isMaintainer =
        profileId != null && course.maintainer?.profileId == profileId;
    final isAssignedTeamMember =
        profileId != null &&
        course.assignedTeamId != null &&
        memberTeamIds.contains(course.assignedTeamId);
    final inside = isMaintainer || isAssignedTeamMember;
    return CourseAccessCapabilities(
      canEditOriginal: inside,
      canCopyAsNewCourse: inside,
      canFork:
          !inside &&
          profileId != null &&
          course.derivativeWorksPolicy == DerivativeWorksPolicy.allowed,
      canDelete: inside,
      hasOperationalAccess: inside,
      canTransferMaintainership: isMaintainer,
      canAssignTeam: isMaintainer,
      editDeniedReason: inside
          ? null
          : 'You do not have permission to edit this Course. Only its Maintainer or a member of its assigned Team can edit it.',
    );
  }
}
