import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/course_merge_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/recorded_audio_service.dart';
import 'package:quisquislingo_app/widgets/course_media_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_file_io.dart';

const _profileId = '12345678-1234-4234-9234-123456789abc';
const _otherProfileId = '22222222-2222-4222-8222-222222222222';
final _when = DateTime.utc(2026, 9, 21, 12);

/// Build 243 Revision 2: a Course names its own images and recordings by
/// content (`media:<sha256>.<ext>`) and keeps them in its own folder.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
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

  Uint8List bytes(List<int> values) => Uint8List.fromList(values);

  group('CourseMediaStore', () {
    test('references are content addresses with a known extension', () {
      final reference = CourseMediaStore.referenceFor(const [1, 2, 3], 'MP3');
      expect(reference, matches(RegExp(r'^media:[0-9a-f]{64}\.mp3$')));
      expect(CourseMediaStore.isAudioReference(reference), isTrue);
      expect(CourseMediaStore.isImageReference(reference), isFalse);
      expect(
        () => CourseMediaStore.referenceFor(const [1], 'gif'),
        throwsFormatException,
      );
      expect(CourseMediaStore.isReference('C:/x.mp3'), isFalse);
      expect(CourseMediaStore.isReference('media:${'A' * 64}.mp3'), isFalse);
    });

    test('storing is verified, deduplicated and size limited', () async {
      final store = CourseMediaStore();
      final first = await store.addBytes('c', bytes([1, 2, 3]), 'mp3');
      final second = await store.addBytes('c', bytes([1, 2, 3]), 'mp3');
      expect(second, first);
      final folder = await store.courseDirectory('c');
      expect(folder.listSync(), hasLength(1));
      expect(
        folder.path,
        endsWith(CourseMediaStore.folderNameFor('c')),
        reason: 'one folder per Course, derived from its ID',
      );
      await expectLater(
        store.addBytes(
          'c',
          Uint8List(CourseMediaStore.maxImageBytes + 1),
          'png',
        ),
        throwsFormatException,
      );
      await expectLater(
        store.addBytes('c', Uint8List(0), 'mp3'),
        throwsFormatException,
      );
    });

    test('a damaged stored file is replaced by the verified bytes', () async {
      final store = CourseMediaStore();
      final reference = await store.addBytes('c', bytes([5, 5]), 'png');
      final file = (await store.existingFile('c', reference))!;
      await file.writeAsBytes(const [0]);
      await store.addBytes('c', bytes([5, 5]), 'png');
      expect(await file.readAsBytes(), const [5, 5]);
    });

    test('copying moves only what exists and reports the rest', () async {
      final store = CourseMediaStore();
      final present = await store.addBytes('from', bytes([1]), 'mp3');
      final absent = CourseMediaStore.referenceFor(const [2], 'mp3');
      final missing = await store.copyReferences('from', 'to', {
        present,
        absent,
      });
      expect(missing, {absent});
      expect(await store.existingFile('to', present), isNotNull);
      expect(await store.existingFile('from', present), isNotNull);
    });

    test('cleanup keeps what the Course uses and removes the rest', () async {
      final store = CourseMediaStore();
      final keep = await store.addBytes('c', bytes([1]), 'mp3');
      final drop = await store.addBytes('c', bytes([2]), 'png');
      final folder = await store.courseDirectory('c');
      final stray = File('${folder.path}${Platform.pathSeparator}notes.txt')
        ..writeAsStringSync('not course media');
      File(
        '${folder.path}${Platform.pathSeparator}x.mp3.tmp',
      ).writeAsStringSync('interrupted');

      final deleted = await store.deleteUnreferenced('c', {keep});
      expect(deleted, 2);
      expect(await store.existingFile('c', keep), isNotNull);
      expect(await store.existingFile('c', drop), isNull);
      expect(
        stray.existsSync(),
        isTrue,
        reason: 'only media files are touched',
      );

      stray.deleteSync();
      await store.deleteUnreferenced('c', const {});
      expect(folder.existsSync(), isFalse, reason: 'an empty folder goes too');
    });

    test('referencesOf finds recordings, exercise images and the cover', () {
      final audio = CourseMediaStore.referenceFor(const [1], 'mp3');
      final image = CourseMediaStore.referenceFor(const [2], 'webp');
      final cover = CourseMediaStore.referenceFor(const [3], 'png');
      final course = _course(
        'refs',
        clips: {'a': audio, 'bundled': 'assets/audio/it_sample/x.mp3'},
        image: image,
        coverImage: cover,
      );
      expect(CourseMediaStore.referencesOf(course), {audio, image, cover});
    });
  });

  group('Course Model v11 media rule', () {
    test('device paths are refused; media, assets and data are accepted', () {
      Map<String, dynamic> withAudio(String path) => {
        ..._course('rule').toJson(),
        'audioLibrary': [
          {'id': 'a', 'text': 'ciao', 'filePath': path},
        ],
      };
      Map<String, dynamic> withImage(String asset) =>
          _course('rule', image: asset).toJson();

      for (final path in ['C:/voice.mp3', '/home/me/voice.mp3', 'voice.mp3']) {
        expect(
          () => Course.fromJson(withAudio(path)),
          throwsFormatException,
          reason: path,
        );
      }
      expect(
        () => Course.fromJson(withAudio('media:${'a' * 64}.png')),
        throwsFormatException,
        reason: 'a recording must be an MP3',
      );
      for (final asset in [
        r'C:\pictures\cat.png',
        '/tmp/cat.png',
        'media:${'a' * 64}.mp3',
      ]) {
        expect(
          () => Course.fromJson(withImage(asset)),
          throwsFormatException,
          reason: asset,
        );
      }
      expect(
        Course.fromJson(withAudio('media:${'a' * 64}.mp3')).audioLibrary,
        hasLength(1),
      );
      for (final asset in [
        'media:${'b' * 64}.jpeg',
        'assets/exercise_images/apple.webp',
        'data:image/png;base64,AAAA',
      ]) {
        expect(
          Course.fromJson(
            withImage(asset),
          ).lessons.single.rounds.single.exercises.single.imageAsset,
          asset,
        );
      }
    });
  });

  group('CourseEditorService', () {
    test('a confirmed save removes media the Course no longer uses', () async {
      final service = CourseEditorService(clock: () => _when);
      final store = service.mediaStore;
      final kept = await store.addBytes('course-a', bytes([1]), 'mp3');
      final dropped = await store.addBytes('course-a', bytes([2]), 'mp3');
      final unsaved = await store.addBytes('course-a', bytes([3]), 'png');
      final created = await _create(
        service,
        _course('a', clips: {'kept': kept, 'dropped': dropped}),
      );
      expect(
        await store.existingFile('course-a', unsaved),
        isNull,
        reason: 'added while editing, never saved',
      );

      await service.confirmCourseTransaction(
        originalCourse: created,
        workingCourse: Course.fromJson({
          ...created.toJson(),
          'audioLibrary': [created.audioLibrary.first.toJson()],
        }),
        languageCode: 'ZZ',
        versionNotes: '',
      );

      expect(await store.existingFile('course-a', kept), isNotNull);
      expect(await store.existingFile('course-a', dropped), isNull);
      // The pre-change backup keeps a copy, so the old version restores.
      final record = (await service.backupService.listBackups(
        'course-a',
      )).single;
      await service.backupService.reinstateMedia(record);
      expect(await store.existingFile('course-a', dropped), isNotNull);
    });

    test('deleting a Course deletes its media folder', () async {
      final service = CourseEditorService(clock: () => _when);
      final reference = await service.mediaStore.addBytes(
        'course-a',
        bytes([1]),
        'mp3',
      );
      await _create(service, _course('a', clips: {'clip': reference}));
      await service.deleteUserCourse('course-a');
      expect(
        (await service.mediaStore.courseDirectory('course-a')).existsSync(),
        isFalse,
      );
    });

    test('Copy as New Course and Fork copy the media they use', () async {
      final service = CourseEditorService(clock: () => _when);
      final store = service.mediaStore;
      final clip = await store.addBytes('course-a', bytes([1]), 'mp3');
      final image = await store.addBytes('course-a', bytes([2]), 'png');
      final source = await _create(
        service,
        _course('a', clips: {'clip': clip}, image: image),
      );
      final copy = (await service.createCopyAsNewCourse(
        source: source,
        title: 'Copy',
      )).course;

      // Fork is for outsiders: another person's Course that allows it.
      final outsiderClip = await store.addBytes('course-o', bytes([1]), 'mp3');
      final outsiderImage = await store.addBytes('course-o', bytes([2]), 'png');
      final outsiders = _course(
        'o',
        clips: {'clip': outsiderClip},
        image: outsiderImage,
        maintainerId: _otherProfileId,
        derivative: DerivativeWorksPolicy.allowed,
      );
      await CourseFileStore().write(
        CourseStoreKind.custom,
        outsiders.courseId,
        {'savedAt': _when.toIso8601String(), 'course': outsiders.toJson()},
      );
      final fork = (await service.createFork(source: outsiders)).course;

      for (final created in [copy, fork]) {
        expect(created.courseId, isNot(source.courseId));
        expect(await store.existingFile(created.courseId, clip), isNotNull);
        expect(await store.existingFile(created.courseId, image), isNotNull);
      }
      expect(await store.existingFile(source.courseId, clip), isNotNull);

      // Folders are independent: deleting the source leaves the copies intact.
      await service.deleteUserCourse(source.courseId);
      expect(await store.existingFile(copy.courseId, clip), isNotNull);
    });

    test('a merge copies media from both source Courses', () async {
      final store = CourseMediaStore();
      final leftImage = await store.addBytes('course-l', bytes([1]), 'png');
      final rightImage = await store.addBytes('course-r', bytes([2]), 'png');
      final left = _course('l', image: leftImage);
      final right = _course('r', image: rightImage);
      final merged = Course.fromJson({
        ...left.toJson(),
        'courseId': 'course-merged',
        'lessons': [
          ...left.lessons,
          ...right.lessons,
        ].map((lesson) => lesson.toJson()).toList(),
      });

      final missing = await CourseMergeService(
        mediaStore: store,
      ).copyMedia(left: left, right: right, merged: merged);

      expect(missing, isEmpty);
      expect(await store.existingFile('course-merged', leftImage), isNotNull);
      expect(await store.existingFile('course-merged', rightImage), isNotNull);
    });
  });

  test(
    'imported recordings are course media and play from the folder',
    () async {
      final service = RecordedAudioService();
      final imports = await service.fixedImportDirectory();
      File(
        '${imports.path}${Platform.pathSeparator}ciao.mp3',
      ).writeAsBytesSync(const [1, 2, 3]);

      final clips = await service.importMp3Files('course-a');
      final reference = clips.single.filePath;
      expect(reference, CourseMediaStore.referenceFor(const [1, 2, 3], 'mp3'));
      expect(
        await service.resolveSourceForClip(clips.single, courseId: 'course-a'),
        isNotNull,
      );
      expect(
        await service.resolveSourceForClip(clips.single, courseId: 'other'),
        isNull,
        reason: 'each Course resolves only its own folder',
      );
    },
  );

  testWidgets('CourseMediaImage shows a stored image and marks a missing one', (
    tester,
  ) async {
    final png = File('assets/lesson_icons/home.png').readAsBytesSync();
    expect(png.length, lessThanOrEqualTo(CourseMediaStore.maxImageBytes));
    late String present;
    await tester.runAsync(() async {
      present = await CourseMediaStore().addBytes(
        'course-a',
        Uint8List.fromList(png),
        'png',
      );
    });
    final absent = CourseMediaStore.referenceFor(const [7], 'png');
    Future<void> show(String asset, bool Function() shown) async {
      await tester.pumpWidget(
        MaterialApp(
          home: CourseMediaImage(
            key: ValueKey(asset),
            courseId: 'course-a',
            asset: asset,
            missing: const Text('missing'),
          ),
        ),
      );
      await tester.pumpUntilFileIoState(shown);
    }

    bool missingShown() => find.text('missing').evaluate().isNotEmpty;
    await show(absent, missingShown);
    await show('C:/device/path.png', missingShown);
    await show(present, () => find.byType(Image).evaluate().isNotEmpty);
    expect(find.text('missing'), findsNothing);
  });
}

Future<Course> _create(CourseEditorService service, Course course) async =>
    (await service.confirmCourseTransaction(
      originalCourse: course,
      workingCourse: course,
      languageCode: 'ZZ',
      versionNotes: '',
      isNewCourse: true,
    )).course;

Course _course(
  String id, {
  Map<String, String> clips = const {},
  String? image,
  String coverImage = '',
  String maintainerId = _profileId,
  DerivativeWorksPolicy derivative = DerivativeWorksPolicy.unspecified,
}) => Course(
  courseId: 'course-$id',
  originalCourseCreator: CourseProvenanceIdentity.qqlUser(
    profileId: maintainerId,
    displayName: 'Author',
  ),
  maintainer: CourseMaintainer(maintainerId),
  lastVersionEditorProfileId: maintainerId,
  lastVersionEditorDisplayName: 'Author',
  modifiedAtUtc: _when.toIso8601String(),
  originType: CourseOriginType.custom,
  originalCreatedAtUtc: _when.toIso8601String(),
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Course $id',
  ttsLanguage: 'it-IT',
  derivativeWorksPolicy: derivative,
  coverImage: coverImage,
  audioLibrary: [
    for (final entry in clips.entries)
      CourseAudioClip(id: entry.key, text: '', filePath: entry.value),
  ],
  lessons: [
    Lesson(
      lessonId: 'lesson-$id',
      publicationState: PublicationState.draft,
      updatedAt: _when,
      title: 'Lesson $id',
      rounds: [
        LearningRound(
          id: 'round-$id',
          publicationState: PublicationState.draft,
          updatedAt: _when,
          title: '',
          exercises: [
            Exercise.v2(
              id: 'exercise-$id',
              publicationState: PublicationState.draft,
              updatedAt: _when,
              editorTemplate: 'translate_to_target',
              promptElements: [
                const PromptElement(type: 'text', text: 'Say hello'),
                if (image != null)
                  PromptElement(role: 'clue', type: 'image', asset: image),
              ],
              interaction: const ExerciseInteraction(kind: 'input'),
              evaluation: const ExerciseEvaluation(
                kind: 'text_match',
                accepted: ['ciao'],
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
