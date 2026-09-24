import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/course_models.dart';
import 'course_library_service.dart';
import 'profile_service.dart';
import 'team_service.dart';

/// Device-local evidence that a Custom Course arrived from another author.
///
/// The flag is deliberately separate from Course JSON and is never inferred
/// for Courses stored before this feature. It grants only the narrowly checked
/// import update path, not Course Editor or Course Manager authoring rights.
class CourseReceivedService {
  CourseReceivedService({
    ProfileService? profiles,
    TeamService? teams,
    CourseLibraryService? library,
  }) : _profiles = profiles ?? ProfileService(),
       _teams = teams ?? TeamService(profileService: profiles),
       _library = library ?? CourseLibraryService(profileService: profiles);

  static const keyPrefix = 'quisquislingo_received_custom_course_';

  static String keyForCourseId(String courseId) =>
      '$keyPrefix${Uri.encodeComponent(courseId.trim())}';

  final ProfileService _profiles;
  final TeamService _teams;
  final CourseLibraryService _library;

  Future<bool> isReceived(String courseId) async =>
      (await SharedPreferences.getInstance()).getBool(
        keyForCourseId(courseId),
      ) ==
      true;

  /// Records an import only while no profile on this device owns its authoring
  /// rights. Reinstalling a Course with a local owner removes any stale flag.
  Future<void> recordNewImport(Course course) async {
    if (course.originType != CourseOriginType.custom) return;
    if (await _hasLocalAuthor(course)) {
      await clear(course.courseId);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final key = keyForCourseId(course.courseId);
    if (!await prefs.setBool(key, true) || prefs.getBool(key) != true) {
      throw StateError('Could not record the received Custom Course.');
    }
  }

  Future<void> clear(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = keyForCourseId(courseId);
    if (prefs.containsKey(key) && !await prefs.remove(key)) {
      throw StateError('Could not clear the received Custom Course flag.');
    }
  }

  /// Checks the exceptional update path; ordinary Maintainer/Team replacement
  /// is decided by [CourseAccessPolicy] outside this service.
  Future<ReceivedCourseUpdateDecision> reviewUpdate({
    required Course existing,
    required Course incoming,
    String? profileId,
  }) async {
    if (existing.originType != CourseOriginType.custom ||
        incoming.originType != CourseOriginType.custom ||
        existing.courseId != incoming.courseId) {
      return const ReceivedCourseUpdateDecision.denied(
        'Only the same Custom Course can be updated.',
      );
    }
    if (!await isReceived(existing.courseId) ||
        await _hasLocalAuthor(existing)) {
      return const ReceivedCourseUpdateDecision.denied(
        'This Course is authored on this device. Only its Maintainer or assigned Team can replace it.',
      );
    }
    final actor = profileId ?? await _profiles.getActiveProfileId();
    if (actor == null || !await _library.contains(existing, profileId: actor)) {
      return const ReceivedCourseUpdateDecision.denied(
        'Add this Course to your Personal Library before updating it.',
      );
    }
    if (existing.maintainer?.profileId != incoming.maintainer?.profileId ||
        jsonEncode(existing.originalCourseCreator.toJson()) !=
            jsonEncode(incoming.originalCourseCreator.toJson())) {
      return const ReceivedCourseUpdateDecision.denied(
        'An update must name the same Maintainer and Original Course Creator.',
      );
    }
    if (existing.assignedTeamId != incoming.assignedTeamId) {
      return const ReceivedCourseUpdateDecision.denied(
        'An update must keep the installed Course assigned Team.',
      );
    }
    if (existing.originalCreatedAtUtc != incoming.originalCreatedAtUtc ||
        jsonEncode(existing.forkProvenance?.toJson()) !=
            jsonEncode(incoming.forkProvenance?.toJson()) ||
        jsonEncode(existing.mergeProvenance?.toJson()) !=
            jsonEncode(incoming.mergeProvenance?.toJson())) {
      return const ReceivedCourseUpdateDecision.denied(
        'An update must preserve original Course, Fork and Merge provenance.',
      );
    }
    final oldVersion = _positiveVersion(existing.courseVersion);
    final newVersion = _positiveVersion(incoming.courseVersion);
    if (oldVersion == null || newVersion == null || newVersion <= oldVersion) {
      return const ReceivedCourseUpdateDecision.denied(
        'An update must have a newer positive integer Course version.',
      );
    }
    return const ReceivedCourseUpdateDecision.allowed();
  }

  Future<bool> _hasLocalAuthor(Course course) async {
    final profiles = await _profiles.getProfileRecords();
    if (profiles.any(
      (profile) => profile.learnerProfileId == course.maintainer?.profileId,
    )) {
      return true;
    }
    final assignedTeamId = course.assignedTeamId;
    if (assignedTeamId == null) return false;
    final team = await _teams.teamById(assignedTeamId);
    return team != null &&
        profiles.any((profile) => team.hasMember(profile.learnerProfileId));
  }

  static BigInt? _positiveVersion(String value) {
    if (!RegExp(r'^[1-9][0-9]*$').hasMatch(value)) return null;
    final number = BigInt.tryParse(value);
    return number != null && number > BigInt.zero ? number : null;
  }
}

class ReceivedCourseUpdateDecision {
  const ReceivedCourseUpdateDecision.allowed()
    : allowed = true,
      unavailableReason = null;

  const ReceivedCourseUpdateDecision.denied(this.unavailableReason)
    : allowed = false;

  final bool allowed;
  final String? unavailableReason;
}
