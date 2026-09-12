import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/course_models.dart';
import 'course_editor_storage.dart';

/// Protects custom-Course authorization when a learner profile is deleted.
abstract final class CourseMaintainerGuard {
  static void ensureProfileDoesNotMaintainCourses(
    SharedPreferences preferences,
    String learnerProfileId,
  ) {
    final raw = preferences.getString(CourseEditorStorage.userCoursesKey);
    if (raw == null || raw.trim().isEmpty) return;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException(
        'Stored Course Model v9 authoring data are invalid or unsupported.',
      );
    }
    for (final entry in decoded.entries) {
      final record = entry.value;
      if (record is! Map || record['course'] is! Map) {
        throw FormatException('Stored custom Course ${entry.key} is invalid.');
      }
      final course = Course.fromJson(
        Map<String, dynamic>.from(record['course'] as Map),
      );
      if (course.originType == CourseOriginType.custom &&
          course.maintainer?.profileId == learnerProfileId) {
        throw StateError(
          'This profile maintains ${course.title}. Change the Course Maintainer or delete the Course before deleting the profile.',
        );
      }
    }
  }
}
