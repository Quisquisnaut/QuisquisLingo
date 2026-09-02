import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all bundled sample courses use the direct Lesson model', () async {
    for (final asset in CourseService.courseAssets.values) {
      final raw = await rootBundle.loadString(asset);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final course = Course.fromJson(json);
      expect(course.formatVersion, Course.currentFormatVersion, reason: asset);
      expect(course.temporarySample, isTrue, reason: asset);
      expect(course.lessons, isNotEmpty, reason: asset);
      expect(
        course.lessons.every(
          (lesson) => lesson.duel.id == '${lesson.lessonId}_duel',
        ),
        isTrue,
        reason: asset,
      );
      expect(course.contentRevision, isNotEmpty, reason: asset);
      expect(course.updateSummary, isNotEmpty, reason: asset);
    }
  });

  test('course update notice is tracked per learner and revision', () async {
    SharedPreferences.setMockInitialValues({});
    final profiles = ProfileService();
    await profiles.addProfile('A');
    final settings = SettingsService();
    expect(await settings.shouldShowCourseUpdate('IT', 'rev1'), isTrue);
    await settings.markCourseUpdateSeen('IT', 'rev1');
    expect(await settings.shouldShowCourseUpdate('IT', 'rev1'), isFalse);
    expect(await settings.shouldShowCourseUpdate('IT', 'rev2'), isTrue);
    await profiles.addProfile('B');
    expect(await settings.shouldShowCourseUpdate('IT', 'rev1'), isTrue);
  });
}
