import 'package:shared_preferences/shared_preferences.dart';
import '../models/course_models.dart';
import 'profile_service.dart';
import 'progress_service.dart';
import 'learner_status_events.dart';

/// Personal membership never changes a shared course or authoring permission.
class CourseLibraryService {
  static const keyPrefix = 'course_library_member_';
  static String creatorProfileId(Course course) =>
      course.forkProvenance?.forkCreatedByProfileId ??
      course.originalCourseCreator.id;
  final ProfileService profiles;
  CourseLibraryService({ProfileService? profileService})
    : profiles = profileService ?? ProfileService();

  Future<bool> contains(Course course, {String? profileId}) async {
    final id = profileId ?? await profiles.getActiveProfileId();
    if (id == null) return true;
    final prefs = await SharedPreferences.getInstance();
    final explicit = prefs.getBool(
      profiles.keyForProfileId(
        id,
        '$keyPrefix${Uri.encodeComponent(course.courseId)}',
      ),
    );
    if (explicit != null) return explicit;
    if (course.originType == CourseOriginType.bundledOfficial ||
        creatorProfileId(course) == id ||
        course.maintainer?.profileId == id) {
      return true;
    }
    // Preserve access for learners who used a course before personal libraries.
    final prefix = ProfileService.prefixForProfileId(id);
    final suffix = '_course_${Uri.encodeComponent(course.courseId)}';
    final previouslyUsed = prefs.getKeys().any(
      (key) => key.startsWith('${prefix}v4_') && key.endsWith(suffix),
    );
    if (previouslyUsed) {
      // Remember the pre-library association before a later progress reset.
      if (!await prefs.setBool(
        profiles.keyForProfileId(
          id,
          '$keyPrefix${Uri.encodeComponent(course.courseId)}',
        ),
        true,
      )) {
        throw StateError('Could not preserve course membership.');
      }
    }
    return previouslyUsed;
  }

  Future<List<Course>> included(Iterable<Course> courses) async {
    final result = <Course>[];
    for (final course in courses) {
      if (await contains(course)) result.add(course);
    }
    return result;
  }

  Future<void> add(Course course) => _set(course, true);

  Future<void> remove(Course course, {bool resetProgress = false}) async {
    if (await profiles.getActiveProfileId() == null) {
      throw StateError('No active learner profile');
    }
    if (resetProgress) await ProgressService().resetCourse(course.courseId);
    await _set(course, false);
  }

  Future<void> _set(Course course, bool value) async {
    final key = await profiles.key(
      '$keyPrefix${Uri.encodeComponent(course.courseId)}',
    );
    if (!await (await SharedPreferences.getInstance()).setBool(key, value)) {
      throw StateError('Could not save course membership.');
    }
    LearnerStatusEvents.publish(LearnerStatusInvalidation.courseMetadata);
  }
}
