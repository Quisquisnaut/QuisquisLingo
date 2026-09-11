import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/course_models.dart';
import 'course_editor_storage.dart';

/// Protects custom-course authorization when a learner profile is deleted.
abstract final class CourseOwnershipGuard {
  static void ensureProfileDoesNotOwnCourses(
    SharedPreferences preferences,
    String learnerProfileId,
  ) {
    final raw = preferences.getString(CourseEditorStorage.userCoursesKey);
    if (raw == null || raw.trim().isEmpty) return;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException(
        'Stored Course Model v7 authoring data are invalid or unsupported.',
      );
    }
    for (final entry in decoded.entries) {
      final record = entry.value;
      if (record is! Map || record['course'] is! Map) {
        throw FormatException('Stored custom course ${entry.key} is invalid.');
      }
      final course = Course.fromJson(
        Map<String, dynamic>.from(record['course'] as Map),
      );
      final ownership = course.ownership;
      if (course.originType == CourseOriginType.custom &&
          ownership?.type == CourseOwnerType.individual &&
          ownership?.id == learnerProfileId) {
        throw StateError(
          'This profile owns ${course.title}. Change the Course Owner or delete the course before deleting the profile.',
        );
      }
    }
  }
}
