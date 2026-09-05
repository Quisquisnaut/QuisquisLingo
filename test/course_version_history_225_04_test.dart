import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_version_history_screen.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory documents;
  late CourseBackupService backups;
  late _HistoryBackupService displayBackups;

  setUp(() async {
    documents = await Directory.systemTemp.createTemp('qql_history_22504_');
    backups = CourseBackupService(
      documentsDirectoryProvider: () async => documents,
      uriLauncher: (_) async => false,
    );
    await backups.createBackup(
      _course(version: '1', title: 'First', notes: 'first notes'),
      backedUpAt: DateTime.utc(2026, 9, 4, 12),
      reason: 'test history',
    );
    await backups.createBackup(
      _course(version: '2', title: 'Second', notes: 'second\nnotes'),
      backedUpAt: DateTime.utc(2026, 9, 4, 13),
      reason: 'test history',
    );
    displayBackups = _HistoryBackupService(
      documents,
      await backups.listBackups('history-course'),
    );
  });

  tearDown(() async {
    if (await documents.exists()) await documents.delete(recursive: true);
  });

  testWidgets(
    'history shows resolved path and immutable versions newest first',
    (tester) async {
      CourseHistorySelection? selection;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => FilledButton(
              onPressed: () async => selection = await Navigator.of(context)
                  .push<CourseHistorySelection>(
                    MaterialPageRoute(
                      builder: (_) => CourseVersionHistoryScreen(
                        course: _course(
                          version: '3',
                          title: 'Current',
                          notes: 'current notes',
                        ),
                        backupService: displayBackups,
                      ),
                    ),
                  ),
              child: const Text('Open history'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open history'));
      await tester.pumpAndSettle();

      final folder = await backups.courseBackupDirectory('history-course');
      expect(
        find.text('Course Backups: ${folder.absolute.path}'),
        findsOneWidget,
      );
      expect(find.text('Course version: 3'), findsOneWidget);
      expect(find.text('Course version: 2'), findsOneWidget);
      expect(find.text('second\nnotes'), findsOneWidget);
      expect(
        displayBackups.records.map((record) => record.course.courseVersion),
        ['2', '1'],
      );

      await tester.tap(find.text('Open backup folder'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'The backup folder could not be opened. The backups remain available.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Restore this version').first);
      await tester.pumpAndSettle();
      expect(selection, isNotNull);
      expect(selection!.separateCustomCopy, isFalse);
      expect(selection!.course.courseVersion, '2');
      expect(selection!.course.title, 'Second');
    },
  );
}

class _HistoryBackupService extends CourseBackupService {
  _HistoryBackupService(this.documents, this.records)
    : super(documentsDirectoryProvider: () async => documents);

  final Directory documents;
  final List<CourseBackupRecord> records;

  @override
  Future<List<CourseBackupRecord>> listBackups(String courseId) async =>
      records;

  @override
  Future<bool> openBackupFolder(String courseId) async => false;
}

Course _course({
  required String version,
  required String title,
  required String notes,
}) => Course(
  courseId: 'history-course',
  originType: CourseOriginType.custom,
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: title,
  ttsLanguage: 'it-IT',
  version: '1',
  courseVersion: version,
  lastModifiedByProfileId: 'profile-id',
  lastModifiedByUsername: 'Historical Author',
  lastModifiedAtUtc: '2026-09-04T13:00:00.000Z',
  versionNotes: notes,
  lessons: const [],
);
