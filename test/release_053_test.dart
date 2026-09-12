import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_service.dart';

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
    }
  });
}
