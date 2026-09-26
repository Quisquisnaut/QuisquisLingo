import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/storage/course_storage_names.dart';

import '../tools/move_private_storage_255.dart';

const _profileId = '12345678-1234-4234-9234-123456789abc';
const _courseId = 'course_abc';

/// Build 255 Revisions 4 and 5: the one-off tool moves what an earlier
/// version stored to where QQL keeps it now (Course Backups to the public
/// Backups folder), so the app finds it again, and never overwrites or
/// deletes anything.
void main() {
  final sep = Platform.pathSeparator;
  late Directory support;
  late Directory documents;
  late Directory staging;

  setUp(() async {
    support = await Directory.systemTemp.createTemp('qql_move_support_');
    documents = await Directory.systemTemp.createTemp('qql_move_documents_');
    staging = await Directory.systemTemp.createTemp('qql_move_staging_');
  });

  tearDown(() async {
    for (final directory in [support, documents, staging]) {
      if (await directory.exists()) await directory.delete(recursive: true);
    }
  });

  String path(Directory root, String relative) =>
      '${root.path}$sep${relative.replaceAll('/', sep)}';

  Future<File> put(Directory root, String relative, Object contents) async {
    final file = File(path(root, relative));
    await file.parent.create(recursive: true);
    if (contents is String) {
      await file.writeAsString(contents);
    } else {
      await file.writeAsBytes(contents as List<int>);
    }
    return file;
  }

  String record(String courseId, String key, Map<String, Object?> course) =>
      jsonEncode({
        'courseId': courseId,
        'entry': {'savedAt': '2026-09-20T10:00:00.000Z', key: course},
      });

  /// Lays out what Revision 3 stored: a Course with a recording, its media
  /// folder and a backup in private storage, a backup a desktop kept in
  /// Documents before Revision 3, a backup in Revision 4's private folder, a
  /// Publisher Course and a few files the tool must leave alone. The media
  /// and backups are made by the app's own services, then put under the
  /// earlier names.
  Future<String> earlierLayout() async {
    final media = CourseMediaStore(supportDirectory: () async => staging);
    final reference = await media.addBytes(
      _courseId,
      Uint8List.fromList(const [1, 2, 3, 4]),
      'mp3',
    );
    final course = _course([
      CourseAudioClip(id: 'a', text: 'uno', filePath: reference),
    ]);
    final backups = CourseBackupService(
      backupsDirectoryProvider: () async => staging,
      mediaStore: media,
    );
    final first = await backups.createBackup(
      course,
      backedUpAt: DateTime.utc(2026, 9, 20, 10),
      reason: 'Pre-change Course Editor transaction backup',
    );
    final second = await backups.createBackup(
      course,
      backedUpAt: DateTime.utc(2026, 9, 19, 9),
      reason: 'Pre-change Course Editor transaction backup',
    );
    final third = await backups.createBackup(
      course,
      backedUpAt: DateTime.utc(2026, 9, 26, 12),
      reason: 'Pre-change Course Editor transaction backup',
    );
    final hash = CourseStorageNames.hashOf(_courseId);

    await put(
      support,
      'qql_courses_v2/custom/course_abc.json',
      record(_courseId, 'course', course.toJson()),
    );
    await Directory(
      path(support, 'quisquislingo_course_media'),
    ).create(recursive: true);
    await (await media.courseDirectory(_courseId)).rename(
      path(support, 'quisquislingo_course_media/course_$hash'),
    );
    // Revision 3's private backup folder, with the first version's manifest
    // named the earlier way; its assets folder keeps its name.
    await Directory(path(support, 'qql_course_backups_v11')).create();
    final r3Folder = await first.manifestFile.parent.rename(
      path(support, 'qql_course_backups_v11/course_abc'),
    );
    await File(
      '${r3Folder.path}$sep${first.manifestFile.uri.pathSegments.last}',
    ).rename('${r3Folder.path}${sep}course_abc_course_2_20260920T100000Z.json');
    // The second version where a desktop kept backups before Revision 3.
    final documentsFolder = Directory(
      path(documents, 'QuisquisLingo/Exports/Course Backups v11/course_abc'),
    );
    await documentsFolder.create(recursive: true);
    final secondName = second.manifestFile.uri.pathSegments.last;
    final secondBase = secondName.substring(
      0,
      secondName.length - '.json'.length,
    );
    await File(
      '${r3Folder.path}$sep$secondName',
    ).rename('${documentsFolder.path}$sep$secondName');
    await Directory(
      '${r3Folder.path}$sep${secondBase}_assets',
    ).rename('${documentsFolder.path}$sep${secondBase}_assets');
    // The third version in Revision 4's private folder.
    final r4Folder = Directory(
      path(support, 'QQL_CourseBackups/QQL_bkp_EN_IT_abc'),
    );
    await r4Folder.create(recursive: true);
    final thirdName = third.manifestFile.uri.pathSegments.last;
    final thirdBase = thirdName.substring(0, thirdName.length - '.json'.length);
    await File(
      '${r3Folder.path}$sep$thirdName',
    ).rename('${r4Folder.path}$sep$thirdName');
    await Directory(
      '${r3Folder.path}$sep${thirdBase}_assets',
    ).rename('${r4Folder.path}$sep${thirdBase}_assets');

    await put(
      support,
      'qql_courses_v2/external_official/pub.one.json',
      record('pub.one', 'source', const {
        'sourceLanguage': 'Italian',
        'targetLanguage': 'Neapolitan',
        'targetLanguageTag': 'nap',
      }),
    );
    await put(support, 'qql_courses_v2/custom/broken.json', 'not a course');
    await put(
      support,
      'quisquislingo_course_media/course_${CourseStorageNames.hashOf('gone')}/'
      '${'0' * 64}.png',
      const [9, 9],
    );
    return reference;
  }

  Map<String, List<int>> snapshot(Directory root) => {
    for (final entity in root.listSync(recursive: true))
      if (entity is File) entity.path: entity.readAsBytesSync(),
  };

  test('moves Courses, their media and backups where the app finds them', () async {
    final reference = await earlierLayout();

    final report = await movePrivateStorage(
      support: support,
      documents: documents,
    );

    final hash = CourseStorageNames.hashOf(_courseId);
    expect(
      File(path(support, 'QQL_Courses/Custom/QQL_EN_IT_abc.json')).existsSync(),
      isTrue,
    );
    expect(
      File(
        path(support, 'QQL_Courses/Publisher/QQL_IT_NAP_pub.one.json'),
      ).existsSync(),
      isTrue,
    );
    expect(
      Directory(path(support, 'QQL_CourseMedia/QQL_EN_IT_$hash')).existsSync(),
      isTrue,
    );
    // No stored Course names this media folder, so it keeps the neutral name.
    expect(
      Directory(
        path(
          support,
          'QQL_CourseMedia/QQL_${CourseStorageNames.hashOf('gone')}',
        ),
      ).existsSync(),
      isTrue,
    );
    expect(
      Directory(
        path(documents, 'QuisquisLingo/Backups/Courses/QQL_bkp_EN_IT_abc'),
      ).existsSync(),
      isTrue,
    );

    // The app's own stores read what was moved.
    final store = CourseFileStore(supportDirectory: () async => support);
    final custom = await store.readReadable(CourseStoreKind.custom);
    expect(custom.records.keys, [_courseId]);
    expect(custom.skipped, isEmpty);
    expect(
      (await store.readReadable(CourseStoreKind.externalOfficial)).records.keys,
      ['pub.one'],
    );
    final media = CourseMediaStore(supportDirectory: () async => support);
    expect(await media.existingFile(_courseId, reference), isNotNull);
    final backups = CourseBackupService(
      backupsDirectoryProvider: () async =>
          Directory(path(documents, 'QuisquisLingo/Backups/Courses')),
      mediaStore: media,
    );
    final history = await backups.listBackups(_courseId);
    expect(history, hasLength(3));
    // The saved version keeps the name its manifest was written under.
    expect(
      history.map((r) => r.manifestFile.uri.pathSegments.last),
      contains('course_abc_course_2_20260920T100000Z.json'),
    );
    for (final version in history) {
      await backups.reinstateMedia(version);
    }

    // The unreadable file stays where it was, and nothing was deleted.
    expect(
      File(path(support, 'qql_courses_v2/custom/broken.json')).existsSync(),
      isTrue,
    );
    expect(
      report.lines.where((line) => line.startsWith('Left in place')),
      [contains('broken.json')],
    );
    expect(report.kept, 1);
    expect(report.copied, 0);
    expect(report.moved, greaterThanOrEqualTo(8));
  });

  test('without a Documents folder, backups stay where they are', () async {
    await earlierLayout();

    final report = await movePrivateStorage(support: support);

    expect(
      File(path(support, 'qql_courses_v2/custom/course_abc.json')).existsSync(),
      isFalse,
    );
    expect(
      Directory(path(support, 'qql_course_backups_v11/course_abc')).existsSync(),
      isTrue,
    );
    expect(
      Directory(path(support, 'QQL_CourseBackups/QQL_bkp_EN_IT_abc')).existsSync(),
      isTrue,
    );
    expect(
      report.lines.where((line) => line.contains('pass --documents')),
      hasLength(2),
    );
  });

  test('a dry run changes nothing', () async {
    await earlierLayout();
    final before = {...snapshot(support), ...snapshot(documents)};

    final report = await movePrivateStorage(
      support: support,
      documents: documents,
      dryRun: true,
    );

    expect({...snapshot(support), ...snapshot(documents)}, before);
    expect(Directory(path(support, 'QQL_Courses')).existsSync(), isFalse);
    expect(report.moved, greaterThanOrEqualTo(6));
    expect(report.summary, contains('Nothing was changed'));
  });

  test('never overwrites a Course or a file already under the new names', () async {
    await earlierLayout();
    // The same Course is already stored under the new names, with another
    // pair, and the recording is already in its new media folder.
    final present = await put(
      support,
      'QQL_Courses/Custom/QQL_EN_FR_abc.json',
      record(_courseId, 'course', const {
        'sourceLanguage': 'English',
        'targetLanguage': 'French',
      }),
    );
    final presentBytes = present.readAsBytesSync();
    final hash = CourseStorageNames.hashOf(_courseId);
    final mediaName = Directory(
      path(support, 'quisquislingo_course_media/course_$hash'),
    ).listSync().single.uri.pathSegments.last;
    final taken = await put(
      support,
      'QQL_CourseMedia/QQL_EN_FR_$hash/$mediaName',
      const [7, 7, 7],
    );

    final report = await movePrivateStorage(
      support: support,
      documents: documents,
    );

    expect(present.readAsBytesSync(), presentBytes);
    expect(taken.readAsBytesSync(), const [7, 7, 7]);
    expect(
      File(path(support, 'qql_courses_v2/custom/course_abc.json')).existsSync(),
      isTrue,
    );
    expect(
      File(
        path(support, 'quisquislingo_course_media/course_$hash/$mediaName'),
      ).existsSync(),
      isTrue,
    );
    // The stored Course's pair (EN_FR) names its backup folder.
    expect(
      Directory(
        path(documents, 'QuisquisLingo/Backups/Courses/QQL_bkp_EN_FR_abc'),
      ).existsSync(),
      isTrue,
    );
    expect(
      report.lines.where((line) => line.startsWith('Left in place')),
      containsAll([
        contains('course_abc.json'),
        contains(mediaName),
        contains('broken.json'),
      ]),
    );
    expect(
      (await CourseFileStore(
        supportDirectory: () async => support,
      ).readReadable(CourseStoreKind.custom)).skipped,
      isEmpty,
    );
  });

  test('options: Windows defaults, and --support elsewhere', () {
    final windows = MoveStorageOptions.parse(
      const ['--dry-run'],
      environment: const {
        'APPDATA': r'C:\Users\A\AppData\Roaming',
        'USERPROFILE': r'C:\Users\A',
      },
      windows: true,
    );
    expect(
      windows.support,
      r'C:\Users\A\AppData\Roaming\QuisquisLingo\quisquislingo_app',
    );
    expect(windows.documents, r'C:\Users\A\Documents');
    expect(windows.dryRun, isTrue);

    final linux = MoveStorageOptions.parse(
      const ['--support', '/data/qql', '--documents', '/home/a/Documents'],
      environment: const {},
      windows: false,
    );
    expect(linux.support, '/data/qql');
    expect(linux.documents, '/home/a/Documents');
    expect(linux.dryRun, isFalse);

    expect(
      () => MoveStorageOptions.parse(
        const [],
        environment: const {},
        windows: false,
      ),
      throwsFormatException,
    );
    expect(
      () => MoveStorageOptions.parse(
        const ['--unknown'],
        environment: const {},
        windows: true,
      ),
      throwsFormatException,
    );
  });
}

Course _course(List<CourseAudioClip> clips) => Course(
  courseId: _courseId,
  originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
    profileId: _profileId,
    displayName: 'Original Creator',
  ),
  maintainer: const CourseMaintainer(_profileId),
  originalCreatedAtUtc: '2026-09-01T09:00:00.000Z',
  lastVersionEditorProfileId: _profileId,
  lastVersionEditorDisplayName: 'Last Editor',
  modifiedAtUtc: '2026-09-20T11:00:00.000Z',
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Moved Course',
  ttsLanguage: 'it-IT',
  courseVersion: '2',
  audioMode: 'recorded',
  audioLibrary: clips,
  lessons: const [],
);
