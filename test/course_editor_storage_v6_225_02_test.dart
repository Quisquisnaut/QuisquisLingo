import 'dart:io';
import 'package:quisquislingo_app/services/course_file_store.dart';

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
        'quisquislingo_user_courses_v8_233030': legacy,
        'quisquislingo_user_courses_v9_233030': legacy,
      });
      final service = CourseEditorService();

      expect(await service.listUserCourses(), isEmpty);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('quisquislingo_user_courses_v5_223'), legacy);
      expect(prefs.getString('quisquislingo_user_courses_v6_225'), legacy);
      expect(prefs.getString('quisquislingo_user_courses_v7_2291'), legacy);
      expect(prefs.getString('quisquislingo_user_courses_v8_233030'), legacy);
      expect(prefs.getString('quisquislingo_user_courses_v9_233030'), legacy);
    },
  );

  test(
    'unsupported stored course is reported clearly without deletion',
    () async {
      final legacyCourse = _course().toJson()..['formatVersion'] = 5;
      final store = CourseFileStore();
      await store.write(CourseStoreKind.custom, 'legacy-course', {
        'savedAt': '2026-09-04T12:00:00.000Z',
        'course': legacyCourse,
      });
      final directory = await store.directoryFor(CourseStoreKind.custom);
      final file = (await directory.list().toList()).single as File;
      final stored = await file.readAsBytes();
      final service = CourseEditorService();

      // Build 243 Revision 1: the unreadable Course is skipped and reported;
      // it no longer hides the readable ones.
      expect(await service.listUserCourses(), isEmpty);
      expect(
        service.unreadableCourseFiles.single.reason,
        allOf(contains('preserved'), contains('unsupported course format')),
      );
      expect(await file.readAsBytes(), stored);
    },
  );

  test('corrupt v8 storage is ignored and left physically unchanged', () async {
    const corrupt = '[not an object]';
    SharedPreferences.setMockInitialValues({
      'quisquislingo_user_courses_v8_233030': corrupt,
    });
    final service = CourseEditorService();

    expect(await service.listUserCourses(), isEmpty);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('quisquislingo_user_courses_v8_233030'), corrupt);
    expect(
      prefs.getString('quisquislingo_course_editor_corrupt_backup_v9_233030'),
      isNull,
    );
  });

  test(
    'corrupt course file is preserved in place and never silently emptied',
    () async {
      const corrupt = '[not an object]';
      final directory = await CourseFileStore().directoryFor(
        CourseStoreKind.custom,
        create: true,
      );
      final file = File('${directory.path}/broken.json');
      await file.writeAsString(corrupt);
      final service = CourseEditorService();

      // Build 243 Revision 1: reported by name instead of failing the list.
      expect(await service.listUserCourses(), isEmpty);
      expect(
        service.unreadableCourseFiles.single.reason,
        allOf(contains('preserved'), contains('not loaded')),
      );
      expect(await file.readAsString(), corrupt);
      expect((await directory.list().toList()).length, 1);
    },
  );

  test('v9 local save/reload preserves canonical timestamp bytes', () async {
    SharedPreferences.setMockInitialValues({});
    final profiles = ProfileService();
    await profiles.createProfile(
      'Maintainer',
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
    courseId: 'user_storage_v9',
    originalCourseCreator: CourseProvenanceIdentity.qqlUser(
      profileId: '11111111-1111-4111-8111-111111111111',
      displayName: 'Original Course Creator',
    ),
    maintainer: const CourseMaintainer('11111111-1111-4111-8111-111111111111'),
    originalCreatedAtUtc: '2026-09-04T12:00:00.000Z',
    publicationState: PublicationState.draft,
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Stored v9',
    ttsLanguage: 'it-IT',
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
