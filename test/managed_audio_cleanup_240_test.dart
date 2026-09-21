import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
import 'package:quisquislingo_app/services/managed_media_cleanup.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _profileId = '12345678-1234-4234-9234-123456789abc';
final _when = DateTime.utc(2026, 9, 19, 12);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late Directory documents;
  late Directory support;
  late CourseBackupService backups;
  late CourseEditorService service;
  late ManagedAudioCleanup cleanup;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('qql_240_cleanup_');
    documents = Directory('${root.path}${Platform.pathSeparator}documents')
      ..createSync();
    support = Directory('${root.path}${Platform.pathSeparator}support')
      ..createSync();
    backups = CourseBackupService(
      documentsDirectoryProvider: () async => documents,
    );
    cleanup = ManagedAudioCleanup(supportDirectory: () async => support);
    service = CourseEditorService(
      backupService: backups,
      audioCleanup: cleanup,
      clock: () => _when,
    );
    SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [
        const LearnerProfile(
          learnerProfileId: _profileId,
          displayName: 'Author',
        ).encode(),
      ],
      ProfileService.activeProfileIdKey: _profileId,
    });
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  File managed(String course, String name) {
    final file = File(
      '${support.path}${Platform.pathSeparator}quisquislingo_audio'
      '${Platform.pathSeparator}$course${Platform.pathSeparator}$name',
    );
    file.parent.createSync(recursive: true);
    file.writeAsBytesSync(Uint8List.fromList([1, 2, 3]));
    return file;
  }

  Future<Course> create(Course course) async =>
      (await service.confirmCourseTransaction(
        originalCourse: course,
        workingCourse: course,
        languageCode: 'ZZ',
        versionNotes: '',
        isNewCourse: true,
      )).course;

  Future<Course> confirmWithClips(Course persisted, List<String> keep) async =>
      (await service.confirmCourseTransaction(
        originalCourse: persisted,
        workingCourse: Course.fromJson({
          ...persisted.toJson(),
          'audioLibrary': [
            for (final clip in persisted.audioLibrary)
              if (keep.contains(clip.id)) clip.toJson(),
          ],
        }),
        languageCode: 'ZZ',
        versionNotes: '',
      )).course;

  group('after a confirmed Save', () {
    test(
      'a removed clip\'s file is deleted; the kept clip\'s file is not',
      () async {
        final gone = managed('course_a', 'gone.mp3');
        final kept = managed('course_a', 'kept.mp3');
        final saved = await create(
          _course('a', {'gone': gone.path, 'kept': kept.path}),
        );

        await confirmWithClips(saved, ['kept']);

        expect(gone.existsSync(), isFalse);
        expect(kept.existsSync(), isTrue);
      },
    );

    test(
      'a file another Course still uses is kept (Duplicate shares paths)',
      () async {
        final shared = managed('course_a', 'shared.mp3');
        final saved = await create(_course('a', {'shared': shared.path}));
        await create(_course('b', {'shared': shared.path}));

        await confirmWithClips(saved, []);

        expect(shared.existsSync(), isTrue);
      },
    );

    test(
      'nothing is deleted while a stored Course file is unreadable',
      () async {
        // Build 243 Revision 1: listing skips unreadable files, but the
        // cleanup must still refuse to guess what such a Course uses.
        final clip = managed('course_a', 'maybe-used.mp3');
        final saved = await create(_course('a', {'clip': clip.path}));
        final store = await CourseFileStore().directoryFor(
          CourseStoreKind.custom,
          create: true,
        );
        await File(
          '${store.path}${Platform.pathSeparator}broken.json',
        ).writeAsString('{ not json');

        await confirmWithClips(saved, []);

        expect(clip.existsSync(), isTrue);
      },
    );

    test('an unrelated change keeps every clip file', () async {
      final clip = managed('course_a', 'clip.mp3');
      final saved = await create(_course('a', {'clip': clip.path}));

      await confirmWithClips(saved, ['clip']);

      expect(clip.existsSync(), isTrue);
    });

    test(
      'bundled assets and files outside QQL\'s audio folder are never deleted',
      () async {
        final outside = File(
          '${documents.path}${Platform.pathSeparator}mine.mp3',
        )..writeAsBytesSync([9]);
        final saved = await create(
          _course('a', {'bundled': 'assets/audio/it_sample/x.mp3'}),
        );
        final withOutside = Course.fromJson({
          ...saved.toJson(),
          'audioLibrary': [
            ...saved.audioLibrary.map((clip) => clip.toJson()),
            {'id': 'outside', 'text': '', 'filePath': outside.path},
          ],
        });
        final second = (await service.confirmCourseTransaction(
          originalCourse: saved,
          workingCourse: withOutside,
          languageCode: 'ZZ',
          versionNotes: '',
        )).course;

        await confirmWithClips(second, []);

        expect(outside.existsSync(), isTrue);
      },
    );

    test(
      'the pre-change backup keeps its own copy, so the old version still restores',
      () async {
        final clip = managed('course_a', 'clip.mp3');
        final saved = await create(_course('a', {'clip': clip.path}));
        await confirmWithClips(saved, []);
        expect(clip.existsSync(), isFalse);

        final records = await backups.listBackups(saved.courseId);
        final restored = records.single.course.audioLibrary.single;
        expect(File(restored.filePath).existsSync(), isTrue);
      },
    );
  });

  group('when a Course is deleted', () {
    test(
      'its unshared files go, files shared with another Course stay, and the empty folder is removed',
      () async {
        final own = managed('course_a', 'own.mp3');
        final shared = managed('course_a', 'shared.mp3');
        await create(_course('a', {'own': own.path, 'shared': shared.path}));
        await create(_course('b', {'shared': shared.path}));

        await service.deleteUserCourse('course-a');

        expect(own.existsSync(), isFalse);
        expect(shared.existsSync(), isTrue);
        expect(shared.parent.existsSync(), isTrue);
      },
    );

    test('the folder disappears once its last file is deleted', () async {
      final only = managed('course_a', 'only.mp3');
      await create(_course('a', {'only': only.path}));

      await service.deleteUserCourse('course-a');

      expect(only.existsSync(), isFalse);
      expect(only.parent.existsSync(), isFalse);
    });
  });

  group('the cleanup itself', () {
    test('deletes nothing when the reference index is incomplete', () async {
      final file = managed('course_a', 'x.mp3');
      final deleted = await cleanup.deleteUnreferenced([
        file.path,
      ], MediaReferenceIndex.fromStoredJson(const [], isComplete: false));
      expect(deleted, 0);
      expect(file.existsSync(), isTrue);
    });

    test(
      'references ignore slash style and letter case, and skip embedded data',
      () {
        final index = MediaReferenceIndex.fromStoredJson([
          {
            'audioLibrary': [
              {'filePath': r'C:\Data\Audio\Clip.MP3'},
            ],
            'flagImageBase64': 'data:image/png;base64,${'A' * 2000}',
          },
        ]);
        expect(index.references('c:/data/audio/clip.mp3'), isTrue);
        expect(index.references('c:/data/audio/other.mp3'), isFalse);
      },
    );

    test('a path that climbs out of the audio folder is refused', () async {
      final outside = File('${root.path}${Platform.pathSeparator}keep.mp3')
        ..writeAsBytesSync([1]);
      final sneaky =
          '${support.path}${Platform.pathSeparator}quisquislingo_audio'
          '${Platform.pathSeparator}..${Platform.pathSeparator}..'
          '${Platform.pathSeparator}keep.mp3';
      final deleted = await cleanup.deleteUnreferenced([
        sneaky,
      ], MediaReferenceIndex.fromStoredJson(const []));
      expect(deleted, 0);
      expect(outside.existsSync(), isTrue);
    });
  });
}

Course _course(String id, Map<String, String> clips) => Course(
  courseId: 'course-$id',
  originalCourseCreator: const CourseProvenanceIdentity.qqlUser(
    profileId: _profileId,
    displayName: 'Original Course Creator',
  ),
  maintainer: const CourseMaintainer(_profileId),
  originType: CourseOriginType.custom,
  originalCreatedAtUtc: _when.toIso8601String(),
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Course $id',
  ttsLanguage: 'it-IT',
  audioLibrary: [
    for (final entry in clips.entries)
      CourseAudioClip(id: entry.key, text: '', filePath: entry.value),
  ],
  lessons: [
    Lesson(
      lessonId: 'lesson-$id',
      publicationState: PublicationState.draft,
      updatedAt: _when,
      title: 'Lesson',
      rounds: [
        LearningRound(
          id: 'round-$id',
          publicationState: PublicationState.draft,
          updatedAt: _when,
          title: '',
          exercises: [
            Exercise(
              id: 'exercise-$id',
              publicationState: PublicationState.draft,
              updatedAt: _when,
              type: 'build_translation',
              prompt: 'How are you?',
              question: '',
              answers: const [],
              correct: null,
              tts: null,
              accepted: const [],
              tokens: const ['Come', 'stai'],
              orderAnswer: const [],
              correctTranslations: const ['Come stai?'],
              pairs: const [],
              hint: '',
              icons: const [],
            ),
          ],
        ),
      ],
    ),
  ],
);
