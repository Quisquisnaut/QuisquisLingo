import 'package:shared_preferences/shared_preferences.dart';

/// Every Publisher Course ID installed on this device (Build 270 Revision 8,
/// owner decision of 10 October 2026), kept after the Course is removed.
///
/// A custom Course can never take one of these IDs: it would replace the
/// signed Course in the learner's library and inherit the progress kept
/// under its ID. Device-level, never in Course files; Wipe everything
/// removes it with the other settings.
class PublisherCourseIds {
  static const key = 'qql_publisher_course_ids_v1';

  Future<Set<String>> all() async =>
      ((await SharedPreferences.getInstance()).getStringList(key) ?? const [])
          .toSet();

  Future<bool> contains(String courseId) async =>
      (await all()).contains(courseId.trim());

  Future<void> remember(String courseId) async {
    final prefs = await SharedPreferences.getInstance();
    final ids = (prefs.getStringList(key) ?? const <String>[]).toSet();
    if (!ids.add(courseId.trim())) return;
    if (!await prefs.setStringList(key, ids.toList()..sort())) {
      throw StateError('Could not remember the Publisher Course ID.');
    }
  }
}
