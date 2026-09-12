import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'legacy storage namespace remains untouched and is not migrated',
    () async {
      const legacy = '{"legacy":"preserve me"}';
      SharedPreferences.setMockInitialValues({
        'quisquislingo_user_courses_v5_223': legacy,
        'quisquislingo_user_courses_v6_225': legacy,
        'quisquislingo_user_courses_v7_2291': legacy,
      });
      final service = CourseEditorService();

      expect(await service.listUserCourses(), isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('quisquislingo_user_courses_v5_223'), legacy);
      expect(prefs.getString('quisquislingo_user_courses_v6_225'), legacy);
      expect(prefs.getString('quisquislingo_user_courses_v7_2291'), legacy);
      expect(prefs.getString('quisquislingo_user_courses_v8_233030'), isNull);
    },
  );

  test(
    'unsupported course in v8 storage fails clearly without deletion',
    () async {
      final legacyCourse = _course().toJson()..['formatVersion'] = 5;
      final stored = jsonEncode({
        'legacy-course': {
          'savedAt': '2026-09-04T12:00:00.000Z',
          'course': legacyCourse,
        },
      });
      SharedPreferences.setMockInitialValues({
        'quisquislingo_user_courses_v8_233030': stored,
      });
      final service = CourseEditorService();

      await expectLater(
        service.listUserCourses(),
        throwsA(
          isA<FormatException>()
              .having(
                (error) => error.message,
                'message',
                contains('preserved'),
              )
              .having(
                (error) => error.message,
                'message',
                contains('unsupported course format'),
              ),
        ),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('quisquislingo_user_courses_v8_233030'), stored);
    },
  );

  test(
    'corrupt v8 storage is copied aside and never silently emptied',
    () async {
      const corrupt = '[not an object]';
      SharedPreferences.setMockInitialValues({
        'quisquislingo_user_courses_v8_233030': corrupt,
      });
      final service = CourseEditorService();

      await expectLater(
        service.listUserCourses(),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            allOf(contains('preserved'), contains('not loaded')),
          ),
        ),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('quisquislingo_user_courses_v8_233030'), corrupt);
      expect(
        prefs.getString('quisquislingo_course_editor_corrupt_backup_v8_233030'),
        corrupt,
      );
    },
  );

  test('v8 local save/reload preserves canonical timestamp bytes', () async {
    SharedPreferences.setMockInitialValues({});
    final profiles = ProfileService();
    await profiles.createProfile(
      'Owner',
      learnerProfileId: '11111111-1111-4111-8111-111111111111',
    );
    final service = CourseEditorService(profileService: profiles);
    final original = _course();

    await service.saveUserCourse(original);
    final reloaded = (await service.listUserCourses()).single;
    expect(reloaded.toJson(), original.toJson());
    expect(
      reloaded.lessons.single.rounds.single.exercises.single.updatedAt,
      DateTime.utc(2026, 9, 4, 12, 3),
    );
  });
}

Course _course() {
  final exercise = Exercise(
    id: 'stored-exercise',
    updatedAt: DateTime.utc(2026, 9, 4, 12, 3),
    type: 'choice',
    prompt: 'Choose.',
    question: 'Which?',
    answers: const ['One', 'Two'],
    correct: 0,
    tts: null,
    accepted: const [],
    tokens: const [],
    orderAnswer: const [],
    pairs: const [],
    hint: '',
    icons: const [],
  );
  return Course(
    courseId: 'user_storage_v6',
    creatorProfileId: '11111111-1111-4111-8111-111111111111',
    ownership: const CourseOwnership.individual(
      '11111111-1111-4111-8111-111111111111',
    ),
    publicationState: PublicationState.draft,
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Stored v6',
    ttsLanguage: 'it-IT',
    version: '1',
    lessons: [
      Lesson(
        lessonId: 'stored-lesson',
        updatedAt: DateTime.utc(2026, 9, 4, 12, 1),
        title: 'Stored',
        rounds: [
          LearningRound(
            id: 'stored-round',
            updatedAt: DateTime.utc(2026, 9, 4, 12, 2),
            title: '',
            exercises: [exercise],
          ),
        ],
      ),
    ],
  );
}
