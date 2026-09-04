import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course_models.dart';
import 'learner_status_events.dart';

/// Local, offline Course Model v6 authoring storage.
///
/// Bundled samples are immutable assets. Local edits to a bundled course are a
/// complete formatVersion 6 override. User-created courses are stored as
/// independent Course Model v6 projects keyed by stable courseId.
class CourseEditorService {
  // Clean-cut v6 storage intentionally leaves earlier keys untouched.
  static const _storageKey = 'quisquislingo_course_editor_overrides_v6_225';
  static const _userCoursesKey = 'quisquislingo_user_courses_v6_225';
  static const _corruptBackupKey =
      'quisquislingo_course_editor_corrupt_backup_v6_225';
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
      case 'KOREAN':
      case 'KO':
      case 'KR':
        return 'KO';
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
      if (decoded is! Map) {
        throw const FormatException('Stored authoring root must be an object.');
      }
      return Map<String, dynamic>.from(decoded);
    } catch (error) {
      await prefs.setString(_corruptBackupKey, raw);
      throw FormatException(
        'Stored Course Model v6 authoring data are invalid or unsupported. '
        'The original data were preserved and were not loaded. $error',
      );
    }
  }

  Future<void> _saveKey(String key, Map<String, dynamic> data) async {
    final encoded = jsonEncode(data);
    if (utf8.encode(encoded).length > _maxBytes) {
      throw StateError(
        'Local course authoring data exceed the 8 MB safety limit. Export or simplify courses before saving more content.',
      );
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, encoded);
  }

  /// Applies only a valid v6 override to a bundled v6 course.
  Future<Map<String, dynamic>> applyToCourse(
    String languageCode,
    Map<String, dynamic> base,
  ) async {
    final all = await _loadKey(_storageKey);
    final entry = all[_normalizeCode(languageCode)];
    if (entry != null) {
      if (entry is! Map || entry['course'] is! Map) {
        throw const FormatException(
          'The stored course override is invalid or unsupported. It was preserved and was not loaded.',
        );
      }
      try {
        final candidate = Map<String, dynamic>.from(
          jsonDecode(jsonEncode(entry['course'])) as Map,
        );
        Course.fromJson(candidate);
        return candidate;
      } on FormatException catch (error) {
        throw FormatException(
          'The stored course override uses invalid or unsupported Course Model v6 data. It was preserved and was not loaded. $error',
        );
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
    for (final mapEntry in all.entries) {
      final entry = mapEntry.value;
      if (entry is! Map || entry['course'] is! Map) {
        throw FormatException(
          'Stored custom course ${mapEntry.key} is invalid or unsupported. '
          'It was preserved and was not loaded.',
        );
      }
      try {
        out.add(
          Course.fromJson(Map<String, dynamic>.from(entry['course'] as Map)),
        );
      } on FormatException catch (error) {
        throw FormatException(
          'Stored custom course ${mapEntry.key} uses an unsupported course '
          'format. It was preserved and was not loaded. $error',
        );
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
      'format': 'QuisquisLingo Course Model v6 local override',
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
