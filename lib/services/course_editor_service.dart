import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course_models.dart';
import 'learner_status_events.dart';

/// Local, offline Course Model v3 authoring storage.
///
/// Bundled samples are immutable assets. Local edits to a bundled course are a
/// complete formatVersion 3 override. User-created courses are stored as
/// independent Course Model v3 projects keyed by stable courseId.
class CourseEditorService {
  // Keep these QuisquisLingo key names stable across future Course Model upgrades.
  static const _storageKey = 'quisquislingo_course_editor_overrides_v2_100';
  static const _userCoursesKey = 'quisquislingo_user_courses_v2_100';
  static const _corruptBackupKey =
      'quisquislingo_course_editor_corrupt_backup_100';
  static const _maxBytes = 8 * 1024 * 1024;

  String _normalizeCode(String value) {
    final v = value.trim().toUpperCase();
    switch (v) {
      case 'ITALIAN':
      case 'IT':
        return 'IT';
      case 'GERMAN':
      case 'DE':
        return 'DE';
      case 'SPANISH':
      case 'ES':
        return 'ES';
      case 'ENGLISH':
      case 'EN':
        return 'EN';
      case 'WELSH':
      case 'CY':
        return 'CY';
      case 'DUTCH':
      case 'NL':
        return 'NL';
      case 'PORTUGUESE':
      case 'PT':
        return 'PT';
      case 'FINNISH':
      case 'FI':
        return 'FI';
      default:
        return v;
    }
  }

  Future<Map<String, dynamic>> _loadKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.trim().isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : <String, dynamic>{};
    } catch (_) {
      await prefs.setString(_corruptBackupKey, raw);
      await prefs.remove(key);
      return <String, dynamic>{};
    }
  }

  Future<void> _saveKey(String key, Map<String, dynamic> data) async {
    final encoded = jsonEncode(data);
    if (utf8.encode(encoded).length > _maxBytes)
      throw StateError(
        'Local course authoring data exceed the 8 MB safety limit. Export or simplify courses before saving more content.',
      );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, encoded);
  }

  /// Applies only a valid v3 override to a bundled v3 course.
  Future<Map<String, dynamic>> applyToCourse(
    String languageCode,
    Map<String, dynamic> base,
  ) async {
    final all = await _loadKey(_storageKey);
    final entry = all[_normalizeCode(languageCode)];
    if (entry is Map && entry['course'] is Map) {
      try {
        final candidate = Map<String, dynamic>.from(
          jsonDecode(jsonEncode(entry['course'])) as Map,
        );
        Course.fromJson(candidate);
        return candidate;
      } catch (_) {
        /* keep bundled sample usable */
      }
    }
    return base;
  }

  Future<void> saveCourse({
    required String languageCode,
    required Course course,
  }) async {
    if (course.courseId.startsWith('user_')) {
      await saveUserCourse(course);
      return;
    }
    final json = course.toJson();
    Course.fromJson(Map<String, dynamic>.from(json));
    final all = await _loadKey(_storageKey);
    all[_normalizeCode(languageCode)] = {
      'savedAt': DateTime.now().toIso8601String(),
      'course': json,
    };
    await _saveKey(_storageKey, all);
    LearnerStatusEvents.publish(LearnerStatusInvalidation.courseMetadata);
  }

  Future<void> saveUserCourse(Course course) async {
    final json = course.toJson();
    Course.fromJson(Map<String, dynamic>.from(json));
    final all = await _loadKey(_userCoursesKey);
    all[course.courseId] = {
      'savedAt': DateTime.now().toIso8601String(),
      'course': json,
    };
    await _saveKey(_userCoursesKey, all);
    LearnerStatusEvents.publish(LearnerStatusInvalidation.courseMetadata);
  }

  Future<List<Course>> listUserCourses() async {
    final all = await _loadKey(_userCoursesKey);
    final out = <Course>[];
    for (final entry in all.values) {
      if (entry is Map && entry['course'] is Map) {
        try {
          out.add(
            Course.fromJson(Map<String, dynamic>.from(entry['course'] as Map)),
          );
        } catch (_) {}
      }
    }
    out.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    return out;
  }

  Future<void> deleteUserCourse(String courseId) async {
    final all = await _loadKey(_userCoursesKey);
    all.remove(courseId);
    await _saveKey(_userCoursesKey, all);
    LearnerStatusEvents.publish(LearnerStatusInvalidation.courseMetadata);
  }

  Future<void> resetCourse(String languageCode) async {
    final all = await _loadKey(_storageKey);
    all.remove(_normalizeCode(languageCode));
    await _saveKey(_storageKey, all);
    LearnerStatusEvents.publish(LearnerStatusInvalidation.courseMetadata);
  }

  Future<String> exportCourseEdits(String languageCode) async {
    final all = await _loadKey(_storageKey);
    final code = _normalizeCode(languageCode);
    return const JsonEncoder.withIndent('  ').convert({
      'format': 'QuisquisLingo Course Model v3 local override',
      'language': code,
      'override': all[code] ?? <String, dynamic>{},
    });
  }

  Future<String> exportUserCourse(Course course) async =>
      const JsonEncoder.withIndent('  ').convert(course.toJson());
  Future<void> copyCourseEdits(String languageCode) async => Clipboard.setData(
    ClipboardData(text: await exportCourseEdits(languageCode)),
  );
}
