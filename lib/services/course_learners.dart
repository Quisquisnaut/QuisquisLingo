import 'package:shared_preferences/shared_preferences.dart';

import '../models/course_models.dart';
import 'course_library_service.dart';
import 'profile_service.dart';
import 'progress_service.dart';

/// The learners on this device a Course matters to (Build 271 Revision 1
/// follow-up, owner decisions of 11 October 2026).
class CourseLearners {
  const CourseLearners({required this.inCourses, required this.keptProgress});

  /// Learners whose Course list shows the Course: they added it, or have
  /// progress on it and never removed it.
  final List<LearnerProfile> inCourses;

  /// Learners who removed the Course from their courses and kept their
  /// progress on it.
  final List<LearnerProfile> keptProgress;
}

/// Who has a Course in their courses, who still has progress on it, and the
/// reset of everyone's progress that the Inventory's Delete offers.
class CourseLearnersService {
  CourseLearnersService({
    ProfileService? profiles,
    CourseLibraryService? library,
    ProgressService? progress,
  }) : _profiles = profiles ?? ProfileService(),
       _progress = progress ?? ProgressService() {
    _library = library ?? CourseLibraryService(profileService: _profiles);
  }

  final ProfileService _profiles;
  final ProgressService _progress;
  late final CourseLibraryService _library;

  /// The learners of [courseId]. With [course], membership follows
  /// [CourseLibraryService.contains] (a Private course is in nobody else's
  /// courses). Without it, for a stored Course this version cannot open, a
  /// learner has the Course when they added it, or have progress on it and
  /// did not remove it.
  Future<CourseLearners> of(String courseId, {Course? course}) async {
    final prefs = await SharedPreferences.getInstance();
    final inCourses = <LearnerProfile>[];
    final keptProgress = <LearnerProfile>[];
    for (final profile in await _profiles.getProfileRecords()) {
      final id = profile.learnerProfileId;
      final hasProgress = await _progress.hasCourseProgress(id, courseId);
      final bool has;
      if (course != null) {
        has = await _library.contains(course, profileId: id);
      } else {
        final explicit = prefs.getBool(
          _profiles.keyForProfileId(
            id,
            '${CourseLibraryService.keyPrefix}'
            '${Uri.encodeComponent(courseId)}',
          ),
        );
        has = explicit ?? hasProgress;
      }
      if (has) {
        inCourses.add(profile);
      } else if (hasProgress) {
        keptProgress.add(profile);
      }
    }
    return CourseLearners(
      inCourses: List.unmodifiable(inCourses),
      keptProgress: List.unmodifiable(keptProgress),
    );
  }

  /// The Courses learners still have progress on although they are not
  /// among [onDevice] (Build 271 Revision 1 second follow-up): Course ID to
  /// the learners, in the order of the profiles. Deleting a Course keeps
  /// its learners' progress unless the admin resets it, and then it can no
  /// longer be reset where the Course was listed.
  Future<Map<String, List<LearnerProfile>>> leftProgress({
    required Set<String> onDevice,
  }) async {
    final left = <String, List<LearnerProfile>>{};
    for (final profile in await _profiles.getProfileRecords()) {
      final ids = await _progress.courseIdsWithProgress(
        profile.learnerProfileId,
      );
      for (final id in ids) {
        if (onDevice.contains(id)) continue;
        left.putIfAbsent(id, () => []).add(profile);
      }
    }
    return left;
  }

  /// Resets every learner's progress on [courseId], also of the learners
  /// who removed it from their courses. XP, Weekly XP, study days and
  /// streaks stay, as for [ProgressService.resetCourse].
  Future<void> resetEveryone(String courseId) async {
    for (final profile in await _profiles.getProfileRecords()) {
      await _progress.resetCourseForProfile(profile.learnerProfileId, courseId);
    }
  }
}
