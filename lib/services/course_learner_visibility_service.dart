import 'package:shared_preferences/shared_preferences.dart';

import '../models/course_models.dart';
import 'course_library_service.dart';
import 'course_service.dart';
import 'learner_status_events.dart';
import 'profile_service.dart';
import 'settings_service.dart';

/// A learner's Hide in Learner preference, applied to Personal Library Courses.
/// Hiding changes neither Personal Library membership nor shared Course data.
class CourseLearnerVisibilityService {
  CourseLearnerVisibilityService({
    ProfileService? profiles,
    SettingsService? settings,
    CourseLibraryService? library,
  }) : _profiles = profiles ?? ProfileService(),
       _settings = settings ?? SettingsService(),
       _library = library ?? CourseLibraryService(profileService: profiles);

  static const keyPrefix = 'course_hidden_';

  final ProfileService _profiles;
  final SettingsService _settings;
  final CourseLibraryService _library;

  static String _suffix(String courseId) =>
      '$keyPrefix${Uri.encodeComponent(courseId.trim())}';

  /// A missing flag, or no active learner profile, means the Course is shown.
  Future<bool> isHidden(String courseId, {String? profileId}) async {
    final id = profileId ?? await _profiles.getActiveProfileId();
    if (id == null) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_profiles.keyForProfileId(id, _suffix(courseId))) ??
        false;
  }

  /// Reads the supplied Course IDs in one preferences snapshot.
  Future<Set<String>> hiddenCourseIds(
    Iterable<String> courseIds, {
    String? profileId,
  }) async {
    final id = profileId ?? await _profiles.getActiveProfileId();
    if (id == null) return const <String>{};
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final courseId in courseIds.map((value) => value.trim()).toSet())
        if (courseId.isNotEmpty &&
            (prefs.getBool(_profiles.keyForProfileId(id, _suffix(courseId))) ??
                false))
          courseId,
    };
  }

  /// Hides or unhides [course] for the active learner. The current Course may
  /// not be hidden; callers may pass its live ID when it has not yet been saved
  /// as the selected reference in [SettingsService].
  Future<void> setHidden(
    Course course,
    bool hidden, {
    String? activeCourseId,
  }) async {
    final profileId = await _profiles.getActiveProfileId();
    if (profileId == null) throw StateError('No active learner profile');
    if (hidden) {
      if (!await _library.contains(course, profileId: profileId)) {
        throw StateError('Add it to your courses first.');
      }
      final active = activeCourseId?.trim();
      final isCurrent = active != null
          ? active == course.courseId
          : await _isSelectedCourse(course);
      if (isCurrent) {
        throw StateError("You're studying this Course.");
      }
    }
    final prefs = await SharedPreferences.getInstance();
    final key = _profiles.keyForProfileId(profileId, _suffix(course.courseId));
    final saved = hidden
        ? await prefs.setBool(key, true)
        : await prefs.remove(key);
    if (!saved) throw StateError('Could not save Course visibility.');
    LearnerStatusEvents.publish(LearnerStatusInvalidation.courseMetadata);
  }

  Future<bool> _isSelectedCourse(Course course) async {
    final selected = await _settings.getLastSelectedCourseCode();
    if (selected == null) return false;
    final reference = course.originType == CourseOriginType.bundledOfficial
        ? CourseService.bundledCodeForCourse(course)
        : 'custom:${course.courseId}';
    return selected == reference;
  }
}
