import 'dart:convert';
import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course_models.dart';
import 'app_errors.dart';
import 'diagnostic_log_service.dart';
import 'course_backup_service.dart';
import 'learning_language_identity.dart';
import 'course_language_resolver.dart';

/// Loads immutable bundled official courses.
///
/// There is intentionally no language fallback: asking for an unavailable
/// course must fail rather than silently opening Italian or another course.
class CourseService {
  final DiagnosticLogService _log = DiagnosticLogService();
  // Build 255 Revision 6 removed the German, Spanish, English-from-Spanish,
  // Welsh, Portuguese and Neapolitan demos. Their Course IDs stay reserved in
  // CourseEditorService, as the demos removed in Build 254 do.
  static const Map<String, String> courseAssets = {
    'IT': 'assets/courses/exercise_laboratory_en_it.json',
    'KO': 'assets/courses/korean_en.json',
    'EN_EDGE': 'assets/courses/edge_case_it_en.json',
    'PMS': 'assets/courses/piedmontais_en.json',
  };

  static const bundledCourseIndexStorageKey =
      'quisquislingo_bundled_course_codes_v9_233030';

  static const Map<String, String> targetLabels = {
    'IT': 'Italian',
    'KO': 'Korean',
    'EN_EDGE': 'English',
    'PMS': 'Piedmontese',
  };

  static const Map<String, String> sourceLabels = {
    'IT': 'English',
    'KO': 'English',
    'EN_EDGE': 'Italian',
    'PMS': 'English',
  };

  Future<Course> loadItalianCourse() => loadCourse('IT');
  Future<Course> loadKoreanCourse() => loadCourse('KO');

  /// Reconciles the device-local discovery index with the authoritative
  /// bundled registry. This is normal startup initialization: it does not
  /// inspect or modify custom courses, learner progress, or earlier schemas.
  Future<List<String>> reconcileAvailableBundledCourseCodes() async {
    final current = List<String>.unmodifiable(courseAssets.keys);
    final preferences = await SharedPreferences.getInstance();
    final stored = preferences.getStringList(bundledCourseIndexStorageKey);
    if (stored == null || !_sameCodes(stored, current)) {
      await preferences.setStringList(bundledCourseIndexStorageKey, current);
    }
    return current;
  }

  static bool _sameCodes(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  static bool hasCourse(String languageCode) =>
      courseAssets.containsKey(languageCode.trim().toUpperCase());

  /// Bundled selection and source lookup use a distinct reference when more
  /// than one bundled Course teaches the same language. Language-scoped XP,
  /// streaks and flags continue to use [codeForCourse].
  static String bundledCodeForCourse(Course course) =>
      _additionalBundledCodes[course.courseId] ?? codeForCourse(course);

  static const _additionalBundledCodes = {
    'course_6f6a1fa3-b834-4936-b324-92fb57f73502': 'EN_EDGE',
  };

  static String codeForCourse(Course course) {
    final resolved = CourseLanguageResolver.learning(course).code;
    if (resolved != null) {
      final canonical = LearningLanguageIdentity.storageId(resolved);
      if (_isLanguageCode(canonical)) return canonical;
    }
    for (final candidate in [
      course.learningLanguage,
      course.targetLanguageTag,
      course.targetLanguage,
    ]) {
      final canonical = LearningLanguageIdentity.storageId(candidate);
      if (_isLanguageCode(canonical)) return canonical;
    }
    final raw = course.targetLanguage.trim().toUpperCase();
    return raw.length >= 2 ? raw.substring(0, 2) : raw;
  }

  static bool _isLanguageCode(String value) =>
      RegExp(r'^[A-Z]{2,3}$').hasMatch(value);

  Future<Course> loadCourse(String languageCode) =>
      loadBundledCourse(languageCode);

  /// Loads the immutable bundled source without applying a local override.
  Future<Course> loadBundledCourse(String languageCode) async {
    final normalizedCode = languageCode.trim().toUpperCase();
    final asset = courseAssets[normalizedCode];
    if (asset == null) throw AppException(AppErrorCode.courseFileMissing);
    try {
      final raw = await rootBundle.loadString(asset);
      try {
        final decodedValue = jsonDecode(raw);
        if (decodedValue is! Map) {
          throw const FormatException('Course root must be an object.');
        }
        final course = Course.fromJson(Map<String, dynamic>.from(decodedValue));
        if (course.originType != CourseOriginType.bundledOfficial ||
            course.publisherId != 'org.quisquislingo' ||
            course.publisherVerificationStatus !=
                PublisherVerificationStatus.verified ||
            CourseBackupService.officialContentChecksum(course) !=
                course.officialChecksum) {
          throw const FormatException(
            'Bundled official course provenance or checksum is invalid.',
          );
        }
        return course;
      } catch (e, st) {
        await _log.log(
          AppErrorCode.invalidCourseData,
          context: asset,
          exception: e,
          stackTrace: st,
        );
        throw AppException(
          AppErrorCode.invalidCourseData,
          cause: e,
          stackTrace: st,
        );
      }
    } on FlutterError catch (e, st) {
      await _log.log(
        AppErrorCode.courseFileMissing,
        context: asset,
        exception: e,
        stackTrace: st,
      );
      throw AppException(
        AppErrorCode.courseFileMissing,
        cause: e,
        stackTrace: st,
      );
    }
  }
}
