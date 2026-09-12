import '../models/course_models.dart';
import 'profile_service.dart';
import 'team_service.dart';

/// Applies Course Maintainer and Team-assignment rules to an Editor working
/// copy.
///
/// Maintainer authorization always uses stable local profile IDs. Team
/// membership and leadership never confer Maintainer-transfer powers.
class CourseGovernanceService {
  CourseGovernanceService({
    ProfileService? profileService,
    TeamService? teamService,
  }) : _profiles = profileService ?? ProfileService(),
       _teams =
           teamService ??
           TeamService(profileService: profileService ?? ProfileService());

  static const teamAssignmentWarning =
      'The Course remains maintained by its individual Course Maintainer. The Team '
      'receives management access under QQL Team permissions. Team membership '
      'and Team Leaders may change over time, so future Members or Leaders may '
      'participate in managing this Course. The Course Maintainer can revoke the '
      'assignment. QQL Team and Course rules govern permissions inside QQL; '
      'they do not by themselves determine copyright ownership, contractual '
      'rights, or external organizational authority.';

  final ProfileService _profiles;
  final TeamService _teams;

  Future<Course> transferMaintainer({
    required Course course,
    required String actorProfileId,
    required String newMaintainerProfileId,
    required bool editMode,
  }) async {
    _requireMaintainerInEdit(
      course: course,
      actorProfileId: actorProfileId,
      editMode: editMode,
    );
    if (await _profiles.getProfileById(newMaintainerProfileId) == null) {
      throw StateError(
        'The new Course Maintainer must be an existing local user.',
      );
    }
    return Course.fromJson({
      ...course.toJson(),
      'maintainer': CourseMaintainer(newMaintainerProfileId).toJson(),
    });
  }

  Future<Course> assignTeam({
    required Course course,
    required String actorProfileId,
    required String? teamId,
    required bool editMode,
    bool assignmentConfirmed = false,
  }) async {
    _requireMaintainerInEdit(
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

  static void _requireMaintainerInEdit({
    required Course course,
    required String actorProfileId,
    required bool editMode,
  }) {
    if (!editMode) {
      throw StateError(
        'Course Maintainer and Team assignment can change only in Edit mode.',
      );
    }
    if (course.originType != CourseOriginType.custom ||
        course.maintainer?.profileId != actorProfileId) {
      throw StateError(
        'Only the current Course Maintainer can change the Maintainer or Team assignment.',
      );
    }
  }
}
