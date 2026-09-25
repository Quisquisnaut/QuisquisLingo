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
  static const Map<String, String> courseAssets = {
    'IT': 'assets/courses/exercise_laboratory_en_it.json',
    'DE': 'assets/courses/german_en.json',
    'ES': 'assets/courses/spanish_en.json',
    'EN': 'assets/courses/english_es.json',
    'CY': 'assets/courses/welsh_en.json',
    'PT': 'assets/courses/portuguese_en.json',
    'KO': 'assets/courses/korean_en.json',
    'NAP': 'assets/courses/neapolitan_it.json',
    'EN_EDGE': 'assets/courses/edge_case_it_en.json',
    'PMS': 'assets/courses/piedmontais_en.json',
  };

  static const bundledCourseIndexStorageKey =
      'quisquislingo_bundled_course_codes_v9_233030';

  static const Map<String, String> targetLabels = {
    'IT': 'Italian',
    'DE': 'German',
    'ES': 'Spanish',
    'EN': 'English',
    'CY': 'Welsh',
    'PT': 'Portuguese',
    'KO': 'Korean',
    'NAP': 'Neapolitan',
    'EN_EDGE': 'English',
    'PMS': 'Piedmontais',
  };

  static const Map<String, String> sourceLabels = {
    'IT': 'English',
    'DE': 'English',
    'ES': 'English',
    'EN': 'Spanish',
    'CY': 'English',
    'PT': 'English',
    'KO': 'English',
    'NAP': 'Italian',
    'EN_EDGE': 'Italian',
    'PMS': 'English',
  };

  Future<Course> loadItalianCourse() => loadCourse('IT');
  Future<Course> loadGermanCourse() => loadCourse('DE');
  Future<Course> loadSpanishCourse() => loadCourse('ES');
  Future<Course> loadEnglishCourse() => loadCourse('EN');
  Future<Course> loadKoreanCourse() => loadCourse('KO');
  Future<Course> loadNeapolitanCourse() => loadCourse('NAP');

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
