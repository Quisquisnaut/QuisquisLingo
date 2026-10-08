import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'course_wizard.dart';

/// Where a paused Course Wizard stands (Build 267, owner decision of 6
/// October 2026: "Save for now" pauses creation and it can be resumed). One
/// device-level key per Course ID, like the publisher memory, never in the
/// Course file: a Course exported in the middle of the Wizard is continued by
/// hand on another device. Removed when the Wizard finishes, on Continue by
/// hand, when the Course is deleted, by the custom-course reset and by Wipe
/// everything.
class CourseWizardMemory {
  static const keyPrefix = 'qql_course_wizard_';

  static String keyForCourseId(String courseId) =>
      '$keyPrefix${Uri.encodeComponent(courseId.trim())}';

  /// The Course ID a key names, or the raw rest of the key when it is not
  /// URI-encoded.
  static String courseIdOfKey(String key) {
    final encoded = key.substring(keyPrefix.length);
    try {
      return Uri.decodeComponent(encoded);
    } on FormatException {
      return encoded;
    }
  }

  /// The paused Wizard of [courseId], or null when there is none or the
  /// stored value is not usable.
  Future<CourseWizardPause?> recall(String courseId) async {
    final raw = (await SharedPreferences.getInstance()).getString(
      keyForCourseId(courseId),
    );
    return raw == null ? null : CourseWizardPause.decode(raw);
  }

  /// Every usable paused Wizard, by Course ID.
  Future<Map<String, CourseWizardPause>> all() async {
    final preferences = await SharedPreferences.getInstance();
    return {
      for (final key in preferences.getKeys())
        if (key.startsWith(keyPrefix))
          if (_read(preferences, key) case final pause?)
            courseIdOfKey(key): pause,
    };
  }

  static CourseWizardPause? _read(SharedPreferences preferences, String key) {
    final raw = preferences.get(key);
    return raw is String ? CourseWizardPause.decode(raw) : null;
  }

  Future<void> remember(String courseId, CourseWizardPause pause) async {
    await (await SharedPreferences.getInstance()).setString(
      keyForCourseId(courseId),
      jsonEncode(pause.toJson()),
    );
  }

  Future<void> forget(String courseId) async {
    await (await SharedPreferences.getInstance()).remove(
      keyForCourseId(courseId),
    );
  }
}
