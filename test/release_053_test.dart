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

  test('all bundled sample courses have at most three sample chapters', () async {
    for (final asset in CourseService.courseAssets.values) {
      final raw = await rootBundle.loadString(asset);
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final course = Course.fromJson(json);
      expect(course.chapters.length, lessThanOrEqualTo(3), reason: asset);
      expect(course.chapters.every((c) => c.temporarySample), isTrue, reason: asset);
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
