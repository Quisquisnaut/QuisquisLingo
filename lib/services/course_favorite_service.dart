import 'package:shared_preferences/shared_preferences.dart';

import 'learner_status_events.dart';
import 'profile_service.dart';

/// A learner's Favorite shortcuts. This preference never changes Personal
/// Library membership or the shared Course.
class CourseFavoriteService {
  CourseFavoriteService({ProfileService? profiles})
    : _profiles = profiles ?? ProfileService();

  static const keyPrefix = 'course_favorite_';

  final ProfileService _profiles;

  static String _suffix(String courseId) =>
      '$keyPrefix${Uri.encodeComponent(courseId.trim())}';

  /// A missing flag, or no active learner profile, means not a Favorite.
  Future<bool> isFavorite(String courseId, {String? profileId}) async {
    final id = profileId ?? await _profiles.getActiveProfileId();
    if (id == null || courseId.trim().isEmpty) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_profiles.keyForProfileId(id, _suffix(courseId))) ??
        false;
  }

  /// Reads the supplied Course IDs in one preferences snapshot.
  Future<Set<String>> favoriteCourseIds(
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

  /// Favorites can include Courses outside this learner's Personal Library.
  Future<void> setFavorite(String courseId, bool favorite) async {
    if (courseId.trim().isEmpty) throw ArgumentError('Course ID is required.');
    final profileId = await _profiles.getActiveProfileId();
    if (profileId == null) throw StateError('No active learner profile');
    final prefs = await SharedPreferences.getInstance();
    final key = _profiles.keyForProfileId(profileId, _suffix(courseId));
    final saved = favorite
        ? await prefs.setBool(key, true)
        : await prefs.remove(key);
    if (!saved) throw StateError('Could not save Course Favorite.');
    LearnerStatusEvents.publish(LearnerStatusInvalidation.courseMetadata);
  }
}
