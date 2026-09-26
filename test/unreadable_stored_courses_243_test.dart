import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_projects_screen.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/storage/course_storage_names.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_file_io.dart';

const _profileId = '41111111-1111-4111-8111-111111111111';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<File> writeRaw(String name, String contents) async {
    final directory = await CourseFileStore().directoryFor(
      CourseStoreKind.custom,
      create: true,
    );
    final file = File('${directory.path}${Platform.pathSeparator}$name');
    await file.writeAsString(contents);
    return file;
  }

  Future<void> storeCourse(Course course, {String? fileName}) async {
    final entry = {
      'courseId': course.courseId,
      'entry': {
        'savedAt': '2026-09-21T09:00:00.000Z',
        'course': course.toJson(),
      },
    };
    if (fileName == null) {
      await CourseFileStore().write(
        CourseStoreKind.custom,
        course.courseId,
        entry['entry'],
      );
    } else {
      await writeRaw(fileName, jsonEncode(entry));
    }
  }

  group('CourseFileStore', () {
    test(
      'readReadable lists readable Courses and names skipped files',
      () async {
        await storeCourse(_course('good'));
        await writeRaw('broken.json', '{ not json');
        await writeRaw('no-id.json', jsonEncode({'entry': {}}));
        final snapshot = await CourseFileStore().readReadable(
          CourseStoreKind.custom,
        );
        expect(snapshot.records.keys, ['good']);
        expect(
          snapshot.skipped.map((file) => file.fileName),
          unorderedEquals(['broken.json', 'no-id.json']),
        );
        expect(
          snapshot.skipped.every((file) => file.reason.contains('preserved')),
          isTrue,
        );
      },
    );

    test('two files claiming one Course ID are both skipped', () async {
      await storeCourse(_course('twin'));
      await storeCourse(_course('twin'), fileName: 'twin-copy.json');
      await storeCourse(_course('other'));
      final snapshot = await CourseFileStore().readReadable(
        CourseStoreKind.custom,
      );
      expect(snapshot.records.keys, ['other']);
      expect(snapshot.skipped, hasLength(2));
    });

    test('readAll stays strict for callers that must see everything', () async {
      await storeCourse(_course('good'));
      await writeRaw('broken.json', '{ not json');
      await expectLater(
        CourseFileStore().readAll(CourseStoreKind.custom),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('broken.json'),
          ),
        ),
      );
    });

    test('write never replaces an unreadable or foreign file', () async {
      final store = CourseFileStore();
      // Named as the store names this Course (an entry without languages).
      final broken = await writeRaw(
        'QQL_UNKNOWN_UNKNOWN_victim.json',
        '{ not json',
      );
      await expectLater(
        store.write(CourseStoreKind.custom, 'victim', {'v': 1}),
        throwsA(isA<FormatException>()),
      );
      expect(await broken.readAsString(), '{ not json');

      final foreign = await writeRaw(
        'QQL_UNKNOWN_UNKNOWN_claimed.json',
        jsonEncode({'courseId': 'someone-else', 'entry': {}}),
      );
      final before = await foreign.readAsString();
      await expectLater(
        store.write(CourseStoreKind.custom, 'claimed', {'v': 1}),
        throwsA(isA<FormatException>()),
      );
      expect(await foreign.readAsString(), before);

      await store.write(CourseStoreKind.custom, 'fine', {'v': 1});
      await store.write(CourseStoreKind.custom, 'fine', {'v': 2});
      expect(
        (await store.readReadable(CourseStoreKind.custom)).records['fine'],
        {'v': 2},
      );
    });
  });

  group('CourseEditorService', () {
    test('an unreadable Course no longer hides the readable ones', () async {
      await storeCourse(_course('good'));
      final broken = await writeRaw('broken.json', '{ not json');
      // Readable JSON, but not a Course this build accepts.
      await storeCourse(_course('old-format'), fileName: 'old-format.json');
      final oldFile = File(
        '${(await CourseFileStore().directoryFor(CourseStoreKind.custom)).path}'
        '${Platform.pathSeparator}old-format.json',
      );
      final oldJson = jsonDecode(await oldFile.readAsString()) as Map;
      ((oldJson['entry'] as Map)['course'] as Map)['formatVersion'] = 9;
      await oldFile.writeAsString(jsonEncode(oldJson));
      final oldBytes = await oldFile.readAsString();

      final service = CourseEditorService();
      final courses = await service.listUserCourses();
      expect(courses.map((course) => course.courseId), ['good']);
      expect(
        service.unreadableCourseFiles.map((file) => file.fileName),
        unorderedEquals(['broken.json', 'old-format']),
      );
      expect(await broken.readAsString(), '{ not json');
      expect(await oldFile.readAsString(), oldBytes);
    });

    test('importing over an unreadable file is refused and keeps it', () async {
      await ProfileService().createProfile(
        'Owner',
        learnerProfileId: _profileId,
      );
      await ProfileService().setActiveProfileById(_profileId);
      final broken = await writeRaw(
        CourseStorageNames.courseFileName(
          'victim',
          CourseStorageNames.pairOfCourse(_course('victim')),
        ),
        '{ not json',
      );
      await expectLater(
        CourseEditorService().installImportedCustomCourse(_course('victim')),
        throwsA(isA<FormatException>()),
      );
      expect(await broken.readAsString(), '{ not json');

      await CourseEditorService().installImportedCustomCourse(
        _course('another'),
      );
      expect(
        (await CourseEditorService().listUserCourses()).map((c) => c.courseId),
        ['another'],
      );
    });
  });

  testWidgets('Course Manager lists readable Courses and names skipped files', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await storeCourse(_course('good', title: 'Readable course'));
      await writeRaw('broken.json', '{ not json');
    });
    await tester.pumpWidget(
      const MaterialApp(home: CourseProjectsScreen(currentCourse: null)),
    );
    await tester.pumpUntilFileIoState(
      () => find
          .byKey(const Key('course-manager-unreadable-courses'))
          .evaluate()
          .isNotEmpty,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('course-manager-load-error')), findsNothing);
    expect(find.text('1 stored Course could not be read'), findsOneWidget);
    expect(find.textContaining('broken.json'), findsOneWidget);
    // The readable Course is listed by the service (tested above); here the
    // page must load instead of showing the whole-store error.
    expect(find.text('Course Studio'), findsOneWidget);
  });
}

Course _course(String id, {String title = 'Stored course'}) => Course(
  courseId: id,
  originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
    profileId: _profileId,
    displayName: 'Owner',
  ),
  maintainer: const CourseMaintainer(_profileId),
  originalCreatedAtUtc: '2026-09-01T09:00:00.000Z',
  modifiedAtUtc: '2026-09-01T09:00:00.000Z',
  lastVersionEditorProfileId: _profileId,
  lastVersionEditorDisplayName: 'Owner',
  publicationState: PublicationState.published,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: title,
  ttsLanguage: 'it-IT',
  courseVersion: '1',
  lessons: [
    Lesson(
      lessonId: '$id-lesson',
      publicationState: PublicationState.published,
      updatedAt: DateTime.utc(2026, 9, 1),
      title: 'Lesson',
      rounds: const [],
    ),
  ],
);
