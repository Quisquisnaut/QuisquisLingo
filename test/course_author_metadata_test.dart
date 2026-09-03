import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Course _metadataCourse() => Course(
  courseId: 'course_metadata',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Metadata course',
  ttsLanguage: 'it-IT',
  version: '1.0.0',
  temporarySample: true,
  buyACoffeeUrl: 'https://example.com/support',
  lessons: [
    Lesson(
      lessonId: 't1',
      title: 'Lesson',
      guidebook: Guidebook(
        content: const [
          LearningContent(
            id: 'g1',
            kind: 'explanation',
            required: false,
            role: 'overview',
            text: 'Learner text',
          ),
        ],
      ),
      rounds: const [],
      duel: Duel(id: 'd1', title: 'Duel'),
    ),
  ],
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('course author reads legacy role and writes multi-role metadata', () {
    final legacy = CourseAuthor.fromJson({
      'name': 'A',
      'role': 'Course Creator',
    });
    expect(legacy.roles, ['Course Creator']);
    final author = CourseAuthor(
      name: 'A',
      roles: const ['Course Creator', 'Team Leader', 'Custom role'],
    );
    final json = author.toJson();
    expect(json['roles'], ['Course Creator', 'Team Leader', 'Custom role']);
    expect(json['role'], 'Course Creator, Team Leader, Custom role');
  });

  test('course metadata and Lesson Guidebook round-trip independently', () {
    final course = _metadataCourse();
    final json = course.toJson();
    final decoded = Course.fromJson(json);
    expect(decoded.temporarySample, isTrue);
    expect(decoded.buyACoffeeUrl, 'https://example.com/support');
    expect(decoded.lessons.single.guidebook.overview, 'Learner text');
    expect(decoded.lessons.single.duel.id, 'd1');
    expect(json.containsKey('chapters'), isFalse);
  });

  test('Buy a Coffee uses only a trimmed optional HTTPS URL', () {
    final base = _metadataCourse().toJson();
    expect(
      Course.fromJson({
        ...base,
        'buyACoffeeUrl': '  https://example.com/coffee  ',
      }).buyACoffeeUrl,
      'https://example.com/coffee',
    );
    final absent = Course.fromJson({...base}..remove('buyACoffeeUrl'));
    expect(absent.buyACoffeeUrl, isEmpty);
    expect(absent.toJson().containsKey('buyACoffeeUrl'), isFalse);
    expect(
      () => Course.fromJson({...base, 'buyACoffeeUrl': 'http://example.com'}),
      throwsFormatException,
    );
    expect(
      () => Course.fromJson({...base, 'buyACoffeeUrl': 4}),
      throwsFormatException,
    );
    expect(
      () => Course.fromJson({...base, 'supportUrl': 'https://example.com'}),
      throwsFormatException,
    );
  });

  test('Course Editor uses a clean v5 storage namespace', () async {
    final course = _metadataCourse();
    final legacyValue = jsonEncode({
      course.courseId: {'savedAt': '2026-08-28', 'course': course.toJson()},
    });
    SharedPreferences.setMockInitialValues({
      'quisquislingo_user_courses_v2_100': legacyValue,
    });

    final service = CourseEditorService();
    expect(await service.listUserCourses(), isEmpty);

    await service.saveUserCourse(course);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('quisquislingo_user_courses_v5_223'), isNotNull);
    expect(prefs.getString('quisquislingo_user_courses_v4_215'), isNull);
    expect(prefs.getString('quisquislingo_user_courses_v2_100'), legacyValue);
  });
}
