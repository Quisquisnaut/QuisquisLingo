import 'dart:convert';
import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart';
import '../models/course_models.dart';
import 'app_errors.dart';
import 'diagnostic_log_service.dart';
import 'course_editor_service.dart';

/// Loads bundled courses and overlays local author edits.
///
/// There is intentionally no language fallback: asking for an unavailable
/// course must fail rather than silently opening Italian or another course.
class CourseService {
  final DiagnosticLogService _log = DiagnosticLogService();
  final CourseEditorService _editor = CourseEditorService();

  static const Map<String, String> courseAssets = {
    'IT': 'assets/courses/italian_en.json',
    'DE': 'assets/courses/german_en.json',
    'ES': 'assets/courses/spanish_en.json',
    'EN': 'assets/courses/english_es.json',
    'CY': 'assets/courses/welsh_en.json',
    'NL': 'assets/courses/dutch_en.json',
    'PT': 'assets/courses/portuguese_en.json',
    'FI': 'assets/courses/finnish_en.json',
    'KO': 'assets/courses/korean_en.json',
  };

  static const Map<String, String> targetLabels = {
    'IT': 'Italian',
    'DE': 'German',
    'ES': 'Spanish',
    'EN': 'English',
    'CY': 'Welsh',
    'NL': 'Dutch',
    'PT': 'Portuguese',
    'FI': 'Finnish',
    'KO': 'Korean',
  };

  static const Map<String, String> sourceLabels = {
    'IT': 'English',
    'DE': 'English',
    'ES': 'English',
    'EN': 'Spanish',
    'CY': 'English',
    'NL': 'English',
    'PT': 'English',
    'FI': 'English',
    'KO': 'English',
  };

  Future<Course> loadItalianCourse() => loadCourse('IT');
  Future<Course> loadGermanCourse() => loadCourse('DE');
  Future<Course> loadSpanishCourse() => loadCourse('ES');
  Future<Course> loadEnglishCourse() => loadCourse('EN');
  Future<Course> loadKoreanCourse() => loadCourse('KO');

  static bool hasCourse(String languageCode) =>
      courseAssets.containsKey(languageCode.trim().toUpperCase());

  static String codeForCourse(Course course) {
    final language = course.targetLanguage.trim().toLowerCase();
    if (language == 'italian') return 'IT';
    if (language == 'german') return 'DE';
    if (language == 'spanish') return 'ES';
    if (language == 'english') return 'EN';
    if (language == 'welsh') return 'CY';
    if (language == 'dutch') return 'NL';
    if (language == 'portuguese') return 'PT';
    if (language == 'finnish') return 'FI';
    if (language == 'korean') return 'KO';
    final raw = course.targetLanguage.trim().toUpperCase();
    return raw.length >= 2 ? raw.substring(0, 2) : raw;
  }

  Future<Course> loadCourse(String languageCode) async {
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
        final decoded = Map<String, dynamic>.from(decodedValue);
        final withLocalEdits = await _editor.applyToCourse(
          normalizedCode,
          decoded,
        );
        return Course.fromJson(withLocalEdits);
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
