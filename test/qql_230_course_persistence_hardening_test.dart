import 'support/publisher_fixtures.dart';
import 'support/pump_file_io.dart';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_projects_screen.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
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
      publisherVerification: fixtureVerifier(
        'publisher.qql230',
        'QQL 230 Publisher',
      ),
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
      publisherVerification: fixtureVerifier(
        'publisher.qql230',
        'QQL 230 Publisher',
      ),
      backupService: backups,
      clock: () => _when,
    );

    await expectLater(
      service.installImportedCustomCourse(
        _customCourse(courseId: 'sample_it_en_it', title: 'Collision'),
      ),
      throwsFormatException,
    );

    expect(await CourseFileStore().readAll(CourseStoreKind.custom), isEmpty);
  });

  test('custom import cannot take an external official identity', () async {
    final service = CourseEditorService(
      publisherVerification: fixtureVerifier(
        'publisher.qql230',
        'QQL 230 Publisher',
      ),
      backupService: backups,
      clock: () => _when,
    );
    final official = _externalOfficialCourse();
    await service.installExternalOfficialUpdate(await signFixture(official));

    await expectLater(
      service.installImportedCustomCourse(
        _customCourse(courseId: official.courseId, title: 'Collision'),
      ),
      throwsFormatException,
    );

    expect(await CourseFileStore().readAll(CourseStoreKind.custom), isEmpty);
    expect(
      (await service.listUserCourses()).single.originType.isOfficial,
      isTrue,
    );
  });

  test(
    'new custom import leaves no course after a partial file write fails',
    () async {
      final service = CourseEditorService(
        publisherVerification: fixtureVerifier(
          'publisher.qql230',
          'QQL 230 Publisher',
        ),
        backupService: backups,
        clock: () => _when,
        courseStore: CourseFileStore(
          supportDirectory: () async => documents,
          fileWriter: (file, contents) async {
            await file.writeAsString(
              contents.substring(0, contents.length ~/ 2),
            );
            throw FileSystemException('disk full');
          },
        ),
      );
      final course = _customCourse(title: 'Never partially installed');

      await expectLater(
        service.installImportedCustomCourse(course),
        throwsA(isA<FileSystemException>()),
      );

      expect(await service.listUserCourses(), isEmpty);
      final directory = await CourseFileStore(
        supportDirectory: () async => documents,
      ).directoryFor(CourseStoreKind.custom);
      expect(await directory.list().toList(), isEmpty);
      expect(await backups.listBackups(course.courseId), isEmpty);
    },
  );

  test(
    'same-ID custom import backs up and advances the persisted version once',
    () async {
      final service = CourseEditorService(
        publisherVerification: fixtureVerifier(
          'publisher.qql230',
          'QQL 230 Publisher',
        ),
        backupService: backups,
        clock: () => _when,
      );
      final original = _customCourse(
        title: 'Original',
        courseVersion: '7',
        forkProvenance: _forkProvenance('licensed-parent'),
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
      expect(stored.forkProvenance!.sourceCourseId, 'licensed-parent');
      expect(stored.forkProvenance!.sourceCourseVersion, '3');
      expect(stored.versionNotes, 'Imported replacement');
      final history = await backups.listBackups(original.courseId);
      expect(history, hasLength(1));
      expect(history.single.course.title, 'Original');
      expect(history.single.course.courseVersion, '7');
    },
  );

  test('same-ID custom import cannot rewrite maintainer or lineage', () async {
    final service = CourseEditorService(
      publisherVerification: fixtureVerifier(
        'publisher.qql230',
        'QQL 230 Publisher',
      ),
      backupService: backups,
      clock: () => _when,
    );
    final original = _customCourse(
      title: 'Original',
      courseVersion: '4',
      forkProvenance: _forkProvenance('licensed-parent'),
    );
    await service.installImportedCustomCourse(original);

    final invalidReplacements = [
      Course.fromJson({
        ...original.toJson(),
        'originalCourseCreator': const CourseProvenanceIdentity.qqlUser(
          profileId: _otherProfileId,
          displayName: 'Replacement creator',
        ).toJson(),
        'maintainer': const CourseMaintainer(_otherProfileId).toJson(),
      }),
      Course.fromJson({
        ...original.toJson(),
        'forkProvenance': _forkProvenance('different-parent').toJson(),
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
    'same-ID replacement preserves exact file bytes after write failure',
    () async {
      final store = CourseFileStore(supportDirectory: () async => documents);
      final seed = CourseEditorService(
        publisherVerification: fixtureVerifier(
          'publisher.qql230',
          'QQL 230 Publisher',
        ),
        courseStore: store,
        backupService: backups,
        clock: () => _when,
      );
      final original = _customCourse(title: 'Keep me', courseVersion: '5');
      await seed.installImportedCustomCourse(original);
      final directory = await store.directoryFor(CourseStoreKind.custom);
      final file = (await directory.list().toList()).single as File;
      final before = await file.readAsBytes();
      final failing = CourseEditorService(
        publisherVerification: fixtureVerifier(
          'publisher.qql230',
          'QQL 230 Publisher',
        ),
        backupService: backups,
        clock: () => _when.add(const Duration(hours: 1)),
        courseStore: CourseFileStore(
          supportDirectory: () async => documents,
          fileWriter: (file, contents) async {
            await file.writeAsString(
              contents.substring(0, contents.length ~/ 2),
            );
            throw FileSystemException('disk full');
          },
        ),
      );

      await expectLater(
        failing.installImportedCustomCourse(
          Course.fromJson({...original.toJson(), 'title': 'Do not retain'}),
        ),
        throwsA(isA<FileSystemException>()),
      );

      expect(await file.readAsBytes(), before);
      expect((await directory.list().toList()).map((entry) => entry.path), [
        file.path,
      ]);
      final stored = (await seed.listUserCourses()).single;
      expect(stored.title, 'Keep me');
      expect(stored.courseVersion, '5');
      final history = await backups.listBackups(original.courseId);
      expect(history, hasLength(1));
      expect(history.single.course.toJson(), original.toJson());
    },
  );

  test('custom Course rejects backup-path version values', () {
    final versions = <String>[
      '/../../escaped',
      r'\..\..\escaped',
      r'C:\outside\backup',
    ];

    for (final version in versions) {
      expect(
        () => _customCourse(title: 'Unsafe version', courseVersion: version),
        throwsFormatException,
      );
    }
  });

  testWidgets('Course Manager surfaces corrupt storage instead of spinning', (
    tester,
  ) async {
    await tester.runAsync(() async {
      final directory = await CourseFileStore().directoryFor(
        CourseStoreKind.custom,
        create: true,
      );
      await File('${directory.path}/broken.json').writeAsString('not-json');
    });

    await tester.pumpWidget(
      MaterialApp(
        home: CourseProjectsScreen(
          currentCourse: _customCourse(title: 'Current course'),
        ),
      ),
    );
    await tester.pumpUntilFileIoState(
      () => find
          .byKey(const Key('course-manager-load-error'))
          .evaluate()
          .isNotEmpty,
    );

    expect(find.byKey(const Key('course-manager-load-error')), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('was preserved'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Retry'), findsOneWidget);
  });
}

Course _customCourse({
  String courseId = 'qql-230-custom-course',
  required String title,
  String courseVersion = '1',
  CourseForkProvenance? forkProvenance,
}) => Course(
  courseId: courseId,
  originalCourseCreator: CourseProvenanceIdentity.qqlUser(
    profileId: _profileId,
    displayName: 'Original Course Creator',
  ),
  maintainer: const CourseMaintainer(_profileId),
  originType: CourseOriginType.custom,
  publicationState: PublicationState.draft,
  originalCreatedAtUtc: '2026-09-01T09:00:00.000Z',
  lastVersionEditorProfileId: _profileId,
  lastVersionEditorDisplayName: 'QQL Author',
  modifiedAtUtc: '2026-09-01T09:00:00.000Z',
  forkProvenance: forkProvenance,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: title,
  ttsLanguage: 'it-IT',
  courseVersion: courseVersion,
  lessons: const [],
);

CourseForkProvenance _forkProvenance(String sourceCourseId) =>
    CourseForkProvenance(
      sourceCourseId: sourceCourseId,
      sourceCourseTitle: 'Licensed source',
      sourceCourseVersion: '3',
      sourceOriginType: CourseOriginType.custom,
      sourceAuthors: const [
        CourseAuthor(name: 'Source author', roles: ['Author']),
      ],
      forkCreatedByProfileId: _profileId,
      forkCreatedByDisplayName: 'QQL Author',
      forkCreatedAtUtc: '2026-09-01T09:00:00.000Z',
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
    lessons: const [],
  );
  return Course.fromJson({
    ...provisional.toJson(),
    'officialChecksum': CourseBackupService.officialContentChecksum(
      provisional,
    ),
  });
}
