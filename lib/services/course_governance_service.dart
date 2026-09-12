import '../models/course_models.dart';
import 'profile_service.dart';
import 'team_service.dart';

/// Applies Course ownership and Team-assignment rules to an Editor working copy.
///
/// Ownership authorization always uses stable local profile IDs. Team
/// membership and leadership never confer ownership-transfer powers.
class CourseGovernanceService {
  CourseGovernanceService({
    ProfileService? profileService,
    TeamService? teamService,
  }) : _profiles = profileService ?? ProfileService(),
       _teams =
           teamService ??
           TeamService(profileService: profileService ?? ProfileService());

  static const teamAssignmentWarning =
      'The Course remains owned by its individual Course Owner. The Team '
      'receives management access under QQL Team permissions. Team membership '
      'and Team Leaders may change over time, so future Members or Leaders may '
      'participate in managing this Course. The Course Owner can revoke the '
      'assignment. QQL Team and ownership rules govern permissions inside QQL; '
      'they do not by themselves determine copyright ownership, contractual '
      'rights, or external organizational authority.';

  final ProfileService _profiles;
  final TeamService _teams;

  Future<Course> transferOwnership({
    required Course course,
    required String actorProfileId,
    required String newOwnerProfileId,
    required bool editMode,
  }) async {
    _requireOwnerInEdit(
      course: course,
      actorProfileId: actorProfileId,
      editMode: editMode,
    );
    if (await _profiles.getProfileById(newOwnerProfileId) == null) {
      throw StateError('The new Course Owner must be an existing local user.');
    }
    return Course.fromJson({
      ...course.toJson(),
      'ownership': CourseOwnership.individual(newOwnerProfileId).toJson(),
    });
  }

  Future<Course> assignTeam({
    required Course course,
    required String actorProfileId,
    required String? teamId,
    required bool editMode,
    bool assignmentConfirmed = false,
  }) async {
    _requireOwnerInEdit(
      course: course,
      actorProfileId: actorProfileId,
      editMode: editMode,
    );
    final normalizedTeamId = teamId?.trim();
    final assigning = normalizedTeamId != null && normalizedTeamId.isNotEmpty;
    if (assigning) {
      if (!assignmentConfirmed && normalizedTeamId != course.assignedTeamId) {
        throw StateError(
          'Confirm the Team-assignment warning before assigning this Course.',
        );
      }
      if (await _teams.teamById(normalizedTeamId) == null) {
        throw StateError('The selected Team is unavailable.');
      }
    }
    final json = Map<String, dynamic>.from(course.toJson());
    if (assigning) {
      json['assignedTeamId'] = normalizedTeamId;
    } else {
      json.remove('assignedTeamId');
    }
    return Course.fromJson(json);
  }

  static void _requireOwnerInEdit({
    required Course course,
    required String actorProfileId,
    required bool editMode,
  }) {
    if (!editMode) {
      throw StateError(
        'Course ownership and Team assignment can change only in Edit mode.',
      );
    }
    if (course.originType != CourseOriginType.custom ||
        course.ownership?.id != actorProfileId) {
      throw StateError(
        'Only the current individual Course Owner can change ownership or Team assignment.',
      );
    }
  }
}
