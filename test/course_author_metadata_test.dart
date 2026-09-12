import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

Course _metadataCourse() => Course(
  courseId: 'course_metadata',
  originalCourseCreator: CourseProvenanceIdentity.qqlUser(
    profileId: '11111111-1111-4111-8111-111111111111',
    displayName: 'Original Course Creator',
  ),
  maintainer: const CourseMaintainer('11111111-1111-4111-8111-111111111111'),
  originalCreatedAtUtc: '2026-09-12T08:00:00.000Z',
  lastVersionEditorProfileId: '11111111-1111-4111-8111-111111111111',
  lastVersionEditorDisplayName: 'Original Course Creator',
  modifiedAtUtc: '2026-09-12T08:00:00.000Z',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Metadata course',
  ttsLanguage: 'it-IT',
  temporarySample: true,
  buyACoffeeUrl: 'https://example.com/support',
  authors: const [
    CourseAuthor(name: 'A', roles: ['Author']),
  ],
  rightsHolders: const [
    CourseRightsHolder(
      type: CourseRightsHolderType.person,
      name: 'Rights Holder',
    ),
  ],
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

  test('Course Model v9 author metadata requires structured roles', () {
    expect(
      () => CourseAuthor.fromJson({'name': 'A', 'role': 'Author'}),
      throwsFormatException,
    );
    expect(
      () => CourseAuthor.fromJson({'name': 'A', 'roles': const []}),
      throwsFormatException,
    );
    final author = CourseAuthor(
      name: 'A',
      roles: const ['Author', 'Team Leader', 'Custom role'],
    );
    final json = author.toJson();
    expect(json['roles'], ['Author', 'Team Leader', 'Custom role']);
    expect(json.containsKey('role'), isFalse);
  });

  test('course metadata and Lesson Guidebook round-trip independently', () {
    final course = _metadataCourse();
    final json = course.toJson();
    final decoded = Course.fromJson(json);
    expect(decoded.temporarySample, isTrue);
    expect(decoded.buyACoffeeUrl, 'https://example.com/support');
    expect(decoded.authors.single.roles, ['Author']);
    expect(decoded.rightsHolders.single.name, 'Rights Holder');
    expect(decoded.rightsHolders.single.type, CourseRightsHolderType.person);
    expect(decoded.lessons.single.guidebook.overview, 'Learner text');
    expect(decoded.lessons.single.duel.id, 'd1');
    expect(json.containsKey('chapters'), isFalse);
  });

  test('v9 serialized Courses require canonical root version metadata', () {
    final json = _metadataCourse().toJson();
    for (final field in [
      'originalCreatedAtUtc',
      'lastVersionEditorProfileId',
      'lastVersionEditorDisplayName',
      'modifiedAtUtc',
    ]) {
      final missing = Map<String, dynamic>.from(json)..remove(field);
      expect(
        () => Course.fromJson(missing),
        throwsFormatException,
        reason: 'missing $field must be rejected',
      );
    }
  });

  test('non-forked custom Course lineage must begin with a QQL user', () {
    final json = _metadataCourse().toJson();
    expect(
      () => Course.fromJson({
        ...json,
        'originalCourseCreator': const CourseProvenanceIdentity.publisher(
          publisherId: 'example.publisher',
          displayName: 'Example Publisher',
        ).toJson(),
      }),
      throwsFormatException,
    );
  });

  test('v9 serialized Authors must be a list of structured objects', () {
    final json = _metadataCourse().toJson();
    expect(
      () => Course.fromJson({...json, 'authors': 'A'}),
      throwsFormatException,
    );
    expect(
      () => Course.fromJson({
        ...json,
        'authors': [
          {
            'name': 'A',
            'roles': ['Author'],
          },
          'not an author object',
        ],
      }),
      throwsFormatException,
    );
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

  test('Course Editor uses v9 storage and leaves v8 untouched', () async {
    final course = _metadataCourse();
    final v8Value = jsonEncode({
      course.courseId: {'savedAt': '2026-08-28', 'course': course.toJson()},
    });
    SharedPreferences.setMockInitialValues({
      'quisquislingo_user_courses_v8_233030': v8Value,
    });

    final profiles = ProfileService();
    await profiles.createProfile(
      'Owner',
      learnerProfileId: '11111111-1111-4111-8111-111111111111',
    );
    final service = CourseEditorService(profileService: profiles);
    expect(await service.listUserCourses(), isEmpty);

    await service.saveUserCourse(course);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('quisquislingo_user_courses_v9_233030'), isNotNull);
    expect(prefs.getString('quisquislingo_user_courses_v8_233030'), v8Value);
    expect(prefs.getString('quisquislingo_user_courses_v5_223'), isNull);
    expect(prefs.getString('quisquislingo_user_courses_v4_215'), isNull);
  });
}
