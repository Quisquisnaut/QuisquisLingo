import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_projects_screen.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _profileId = '12345678-1234-4234-9234-123456789abc';
const _otherProfileId = '87654321-4321-4234-9234-cba987654321';
final _when = DateTime.utc(2026, 9, 11, 12);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documents;
  late CourseBackupService backups;

  setUp(() async {
    documents = await Directory.systemTemp.createTemp('qql_230_course_');
    backups = CourseBackupService(
      documentsDirectoryProvider: () async => documents,
    );
    SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [
        const LearnerProfile(
          learnerProfileId: _profileId,
          displayName: 'QQL Author',
        ).encode(),
      ],
      ProfileService.activeProfileIdKey: _profileId,
    });
  });

  tearDown(() async {
    if (await documents.exists()) await documents.delete(recursive: true);
  });

  test('custom import cannot take a bundled official identity', () async {
    final service = CourseEditorService(
      backupService: backups,
      clock: () => _when,
    );

    await expectLater(
      service.installImportedCustomCourse(
        _customCourse(courseId: 'sample_it_en_it', title: 'Collision'),
      ),
      throwsFormatException,
    );

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString(CourseEditorService.userCoursesStorageKey),
      isNull,
    );
  });

  test('custom import cannot take an external official identity', () async {
    final service = CourseEditorService(
      backupService: backups,
      clock: () => _when,
    );
    final official = _externalOfficialCourse();
    await service.installExternalOfficialUpdate(official);

    await expectLater(
      service.installImportedCustomCourse(
        _customCourse(courseId: official.courseId, title: 'Collision'),
      ),
      throwsFormatException,
    );

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString(CourseEditorService.userCoursesStorageKey),
      isNull,
    );
    expect(
      (await service.listUserCourses()).single.originType.isOfficial,
      isTrue,
    );
  });

  test('new custom import rolls back a failed verified write', () async {
    final service = CourseEditorService(
      backupService: backups,
      clock: () => _when,
      preferenceWriter: (preferences, key, value) async {
        await preferences.setString(key, value);
        return false;
      },
    );
    final course = _customCourse(title: 'Never partially installed');

    await expectLater(
      service.installImportedCustomCourse(course),
      throwsStateError,
    );

    final preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getString(CourseEditorService.userCoursesStorageKey),
      isNull,
    );
    expect(await backups.listBackups(course.courseId), isEmpty);
  });

  test(
    'same-ID custom import backs up and advances the persisted version once',
    () async {
      final service = CourseEditorService(
        backupService: backups,
        clock: () => _when,
      );
      final original = _customCourse(
        title: 'Original',
        courseVersion: '7',
        parentCourseId: 'licensed-parent',
        derivedFromVersion: '3',
      );
      await service.installImportedCustomCourse(original);
      final imported = Course.fromJson({
        ...original.toJson(),
        'title': 'Imported update',
        'courseVersion': '999',
        'versionNotes': 'Imported replacement',
      });

      await service.installImportedCustomCourse(imported);

      final stored = (await service.listUserCourses()).single;
      expect(stored.title, 'Imported update');
      expect(stored.courseVersion, '8');
      expect(stored.parentCourseId, 'licensed-parent');
      expect(stored.derivedFromVersion, '3');
      expect(stored.versionNotes, 'Imported replacement');
      final history = await backups.listBackups(original.courseId);
      expect(history, hasLength(1));
      expect(history.single.course.title, 'Original');
      expect(history.single.course.courseVersion, '7');
    },
  );

  test('same-ID custom import cannot rewrite ownership or lineage', () async {
    final service = CourseEditorService(
      backupService: backups,
      clock: () => _when,
    );
    final original = _customCourse(
      title: 'Original',
      courseVersion: '4',
      parentCourseId: 'licensed-parent',
      derivedFromVersion: '3',
    );
    await service.installImportedCustomCourse(original);

    final invalidReplacements = [
      Course.fromJson({
        ...original.toJson(),
        'creatorProfileId': _otherProfileId,
        'ownership': const CourseOwnership.individual(_otherProfileId).toJson(),
      }),
      Course.fromJson({
        ...original.toJson(),
        'parentCourseId': 'different-parent',
      }),
    ];
    for (final replacement in invalidReplacements) {
      await expectLater(
        service.installImportedCustomCourse(replacement),
        throwsFormatException,
      );
    }

    final stored = (await service.listUserCourses()).single;
    expect(stored.toJson(), original.toJson());
    expect(await backups.listBackups(original.courseId), isEmpty);
  });

  test(
    'same-ID replacement restores exact storage after write failure',
    () async {
      final seed = CourseEditorService(
        backupService: backups,
        clock: () => _when,
      );
      final original = _customCourse(title: 'Keep me', courseVersion: '5');
      await seed.installImportedCustomCourse(original);
      final preferences = await SharedPreferences.getInstance();
      final before = preferences.getString(
        CourseEditorService.userCoursesStorageKey,
      );
      final failing = CourseEditorService(
        backupService: backups,
        clock: () => _when.add(const Duration(hours: 1)),
        preferenceWriter: (preferences, key, value) async {
          await preferences.setString(key, value);
          return false;
        },
      );

      await expectLater(
        failing.installImportedCustomCourse(
          Course.fromJson({...original.toJson(), 'title': 'Do not retain'}),
        ),
        throwsStateError,
      );

      expect(
        preferences.getString(CourseEditorService.userCoursesStorageKey),
        before,
      );
      final stored = (await seed.listUserCourses()).single;
      expect(stored.title, 'Keep me');
      expect(stored.courseVersion, '5');
      final history = await backups.listBackups(original.courseId);
      expect(history, hasLength(1));
      expect(history.single.course.toJson(), original.toJson());
    },
  );

  test('custom backup version cannot escape its course directory', () async {
    final versions = <String>[
      '/../../escaped',
      r'\..\..\escaped',
      r'C:\outside\backup',
    ];

    for (var index = 0; index < versions.length; index++) {
      final course = _customCourse(
        title: 'Unsafe version $index',
        courseVersion: versions[index],
      );
      final record = await backups.createBackup(
        course,
        backedUpAt: _when.add(Duration(seconds: index)),
        reason: 'path containment',
      );
      final expectedDirectory = await backups.courseBackupDirectory(
        course.courseId,
      );

      expect(
        record.manifestFile.parent.absolute.path.toLowerCase(),
        expectedDirectory.absolute.path.toLowerCase(),
      );
      expect(record.manifestFile.uri.pathSegments.last, isNot(contains('/')));
      expect(record.manifestFile.uri.pathSegments.last, isNot(contains(r'\')));
    }
  });

  testWidgets('Course Manager surfaces corrupt storage instead of spinning', (
    tester,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      CourseEditorService.userCoursesStorageKey,
      'not-json',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CourseProjectsScreen(
          currentCourse: _customCourse(title: 'Current course'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('course-manager-load-error')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('were preserved'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);
  });
}

Course _customCourse({
  String courseId = 'qql-230-custom-course',
  required String title,
  String courseVersion = '1',
  String? parentCourseId,
  String? derivedFromVersion,
}) => Course(
  courseId: courseId,
  creatorProfileId: _profileId,
  ownership: const CourseOwnership.individual(_profileId),
  originType: CourseOriginType.custom,
  publicationState: PublicationState.draft,
  parentCourseId: parentCourseId,
  derivedFromVersion: derivedFromVersion,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: title,
  ttsLanguage: 'it-IT',
  version: '1',
  courseVersion: courseVersion,
  lessons: const [],
);

Course _externalOfficialCourse() {
  final provisional = Course(
    courseId: 'qql-230-external-official',
    originType: CourseOriginType.externalOfficial,
    publisherId: 'publisher.qql230',
    publisherName: 'QQL 230 Publisher',
    officialCourseVersion: '1',
    officialReleaseDateUtc: _when.toIso8601String(),
    officialChecksum: List.filled(64, '0').join(),
    distributionChannel: 'file-import',
    publisherVerificationStatus: PublisherVerificationStatus.verified,
    publicationState: PublicationState.published,
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'External official',
    ttsLanguage: 'it-IT',
    version: '1',
    lessons: const [],
  );
  return Course.fromJson({
    ...provisional.toJson(),
    'officialChecksum': CourseBackupService.officialContentChecksum(
      provisional,
    ),
  });
}
