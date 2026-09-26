import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_version_history_screen.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/storage/course_storage_names.dart';

import 'support/pump_file_io.dart';

const _profileId = '12345678-1234-4234-9234-123456789abc';

/// Build 255 Revision 5: Course Backups are in the public Backups folder,
/// which people can reach, so Version History lists the versions it can
/// read and names the other files instead of refusing the whole history.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory folder;
  late CourseBackupService backups;

  setUp(() async {
    folder = await Directory.systemTemp.createTemp('qql_255_r5_backups_');
    backups = CourseBackupService(backupsDirectoryProvider: () async => folder);
  });

  tearDown(() async {
    if (await folder.exists()) await folder.delete(recursive: true);
  });

  /// A backup of [course] and, beside it, a file that is not one.
  Future<File> backupAndForeignFile(Course course) async {
    await backups.createBackup(
      course,
      backedUpAt: DateTime.utc(2026, 9, 26, 10),
      reason: 'Pre-change Course Editor transaction backup',
    );
    final courseFolder = await backups.courseBackupDirectory(
      course.courseId,
      pair: CourseStorageNames.pairOfCourse(course),
    );
    final foreign = File(
      '${courseFolder.path}${Platform.pathSeparator}notes.json',
    );
    await foreign.writeAsString('{"not":"a backup"}');
    return foreign;
  }

  test('a file that is not a backup is named and left unchanged', () async {
    final course = _course();
    final foreign = await backupAndForeignFile(course);

    final skipped = <String>[];
    final history = await backups.listBackups(
      course.courseId,
      skipped: skipped,
    );
    expect(history, hasLength(1));
    expect(skipped, ['notes.json']);
    expect(await foreign.readAsString(), '{"not":"a backup"}');

    // Callers that must see every version still get the strict listing.
    await expectLater(
      backups.listBackups(course.courseId),
      throwsFormatException,
    );
  });

  testWidgets('Version History shows the readable version and names the '
      'skipped file', (tester) async {
    final course = _course();
    await tester.runAsync(() => backupAndForeignFile(course));

    await tester.pumpWidget(
      MaterialApp(
        home: CourseVersionHistoryScreen(
          course: course,
          backupService: backups,
        ),
      ),
    );
    await tester.pumpUntilFileIoState(
      () => find
          .byKey(const Key('course-history-skipped-files'))
          .evaluate()
          .isNotEmpty,
    );

    expect(find.textContaining('notes.json'), findsOneWidget);
    expect(find.text('Restore this version'), findsOneWidget);
  });
}

Course _course() => Course(
  courseId: 'course_backups_folder',
  originType: CourseOriginType.custom,
  originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
    profileId: _profileId,
    displayName: 'Author',
  ),
  maintainer: const CourseMaintainer(_profileId),
  originalCreatedAtUtc: '2026-09-26T09:00:00.000Z',
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Backups folder',
  ttsLanguage: 'it-IT',
  courseVersion: '2',
  lessons: const [],
);
