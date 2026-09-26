import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/course_package_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _profileId = '12345678-1234-4234-9234-123456789abc';
final _when = DateTime.utc(2026, 9, 22, 12);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory support;
  late _FailingCourseStore store;
  late _FailingMediaStore media;
  late CourseEditorService editor;

  setUp(() async {
    support = await Directory.systemTemp.createTemp('qql_246_merge_');
    SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [
        const LearnerProfile(
          learnerProfileId: _profileId,
          displayName: 'Merge Author',
        ).encode(),
      ],
      ProfileService.activeProfileIdKey: _profileId,
    });
    store = _FailingCourseStore(support);
    media = _FailingMediaStore(support);
    editor = CourseEditorService(
      courseStore: store,
      mediaStore: media,
      backupService: CourseBackupService(
        backupsDirectoryProvider: () async => support,
        mediaStore: media,
      ),
      clock: () => _when,
    );
  });

  tearDown(() async {
    if (await support.exists()) await support.delete(recursive: true);
  });

  test(
    'a committed Merge keeps both media files when storage throws late',
    () async {
      final leftRef = await media.addBytes(
        'left',
        Uint8List.fromList([1, 2]),
        'png',
      );
      final rightRef = await media.addBytes(
        'right',
        Uint8List.fromList([3, 4]),
        'png',
      );
      final left = _course('left', coverImage: leftRef);
      final right = _course('right', image: rightRef);
      final merged = _course('merged', coverImage: leftRef, image: rightRef);
      store.throwAfterCreate = true;

      await expectLater(
        editor.confirmMergedCourse(left: left, right: right, merged: merged),
        throwsA(isA<StateError>()),
      );

      final saved = (await editor.listUserCourses()).single;
      expect(saved.courseId, 'merged');
      expect(saved.coverImage, leftRef);
      expect(saved.imageLibrary.single.asset, rightRef);
      expect(await media.existingFile('merged', leftRef), isNotNull);
      expect(await media.existingFile('merged', rightRef), isNotNull);
    },
  );

  test(
    'a partial Merge copy removes only media this attempt created',
    () async {
      final leftRef = await media.addBytes(
        'left',
        Uint8List.fromList([5, 6]),
        'png',
      );
      final rightRef = await media.addBytes(
        'right',
        Uint8List.fromList([7, 8]),
        'png',
      );
      final sentinel = await media.addBytes(
        'merged',
        Uint8List.fromList([9, 10]),
        'png',
      );
      final left = _course('left', coverImage: leftRef);
      final right = _course('right', image: rightRef);
      final merged = _course('merged', coverImage: leftRef, image: rightRef);
      media.throwAfterFirstCopy = true;

      await expectLater(
        editor.confirmMergedCourse(left: left, right: right, merged: merged),
        throwsA(isA<StateError>()),
      );

      expect(await editor.listUserCourses(), isEmpty);
      expect(await media.existingFile('merged', leftRef), isNull);
      expect(await media.existingFile('merged', rightRef), isNull);
      expect(await media.existingFile('merged', sentinel), isNotNull);
      expect(await media.existingFile('left', leftRef), isNotNull);
      expect(await media.existingFile('right', rightRef), isNotNull);
    },
  );

  test(
    'a rejected Course create removes copies but preserves prior destination media',
    () async {
      final leftRef = await media.addBytes(
        'left',
        Uint8List.fromList([20, 21]),
        'png',
      );
      final rightRef = await media.addBytes(
        'right',
        Uint8List.fromList([22, 23]),
        'png',
      );
      final sentinel = await media.addBytes(
        'merged',
        Uint8List.fromList([24, 25]),
        'png',
      );
      final left = _course('left', coverImage: leftRef);
      final right = _course('right', image: rightRef);
      final merged = _course('merged', coverImage: leftRef, image: rightRef);
      store.throwBeforeCreate = true;

      await expectLater(
        editor.confirmMergedCourse(left: left, right: right, merged: merged),
        throwsA(isA<StateError>()),
      );

      expect(await editor.listUserCourses(), isEmpty);
      expect(await media.existingFile('merged', leftRef), isNull);
      expect(await media.existingFile('merged', rightRef), isNull);
      expect(await media.existingFile('merged', sentinel), isNotNull);
      expect(await media.existingFile('left', leftRef), isNotNull);
      expect(await media.existingFile('right', rightRef), isNotNull);
    },
  );

  test(
    'Merge copies temporary right-package media before the package removes it',
    () async {
      final leftRef = await media.addBytes(
        'left',
        Uint8List.fromList([11, 12]),
        'png',
      );
      final rightBytes = Uint8List.fromList([13, 14]);
      final rightRef = CourseMediaStore.referenceFor(rightBytes, 'png');
      final left = _course('left', coverImage: leftRef);
      final right = _course('right', image: rightRef);
      final merged = _course('merged', coverImage: leftRef, image: rightRef);
      final package = CoursePackage(right, Uint8List(0), {
        rightRef: rightBytes,
      }, mediaStore: media);

      final saved = await package.withInstalledMedia(
        right.courseId,
        () => editor.confirmMergedCourse(
          left: left,
          right: right,
          merged: merged,
        ),
        keepOnSuccess: false,
      );

      expect(saved.course.courseId, 'merged');
      expect(saved.course.courseVersion, '1');
      expect(saved.hadPreviousVersion, isFalse);
      expect(await media.existingFile('right', rightRef), isNull);
      expect(await media.existingFile('merged', leftRef), isNotNull);
      expect(await media.existingFile('merged', rightRef), isNotNull);
      expect((await editor.listUserCourses()).single.courseId, 'merged');
    },
  );

  test(
    'Merge rejection leaves an existing destination Course and media intact',
    () async {
      final sentinel = await media.addBytes(
        'merged',
        Uint8List.fromList([15]),
        'png',
      );
      final existing = _course('merged', coverImage: sentinel);
      await editor.saveUserCourse(existing);
      final leftRef = await media.addBytes(
        'left',
        Uint8List.fromList([16]),
        'png',
      );
      final left = _course('left', coverImage: leftRef);
      final right = _course('right');
      final merged = _course('merged', coverImage: leftRef);

      await expectLater(
        editor.confirmMergedCourse(left: left, right: right, merged: merged),
        throwsA(isA<StateError>()),
      );

      expect((await editor.listUserCourses()).single.coverImage, sentinel);
      expect(await media.existingFile('merged', sentinel), isNotNull);
      expect(await media.existingFile('merged', leftRef), isNull);
    },
  );

  test(
    'a late cleanup error leaves the saved Merge and media intact',
    () async {
      final leftRef = await media.addBytes(
        'left',
        Uint8List.fromList([17]),
        'png',
      );
      final left = _course('left', coverImage: leftRef);
      final right = _course('right');
      final merged = _course('merged', coverImage: leftRef);
      media.throwDuringCleanup = true;

      await expectLater(
        editor.confirmMergedCourse(left: left, right: right, merged: merged),
        throwsA(isA<StateError>()),
      );

      expect((await editor.listUserCourses()).single.courseId, 'merged');
      expect(await media.existingFile('merged', leftRef), isNotNull);
    },
  );

  test(
    'an unreadable recovery check conservatively retains copied media',
    () async {
      final leftRef = await media.addBytes(
        'left',
        Uint8List.fromList([18]),
        'png',
      );
      final left = _course('left', coverImage: leftRef);
      final right = _course('right');
      final merged = _course('merged', coverImage: leftRef);
      store.throwAfterCreate = true;
      store.throwDuringRecoveryRead = true;

      await expectLater(
        editor.confirmMergedCourse(left: left, right: right, merged: merged),
        throwsA(isA<StateError>()),
      );

      expect((await editor.listUserCourses()).single.courseId, 'merged');
      expect(await media.existingFile('merged', leftRef), isNotNull);
    },
  );

  test(
    'Merge preserves existing acceptance of media absent from both sources',
    () async {
      final absent = CourseMediaStore.referenceFor([19], 'png');
      final left = _course('left');
      final right = _course('right');
      final merged = _course('merged', coverImage: absent);

      final saved = await editor.confirmMergedCourse(
        left: left,
        right: right,
        merged: merged,
      );

      expect(saved.course.coverImage, absent);
      expect(await media.existingFile('merged', absent), isNull);
    },
  );
}

Course _course(String id, {String coverImage = '', String? image}) => Course(
  courseId: id,
  originType: CourseOriginType.custom,
  originalCourseCreator: CourseProvenanceIdentity.qqlUser(
    profileId: _profileId,
    displayName: 'Merge Author',
  ),
  maintainer: const CourseMaintainer(_profileId),
  originalCreatedAtUtc: _when.toIso8601String(),
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Course $id',
  ttsLanguage: 'it-IT',
  coverImage: coverImage,
  imageLibrary: image == null
      ? const []
      : [CourseImageLibraryEntry(asset: image)],
  lessons: [
    Lesson(
      lessonId: 'lesson-$id',
      publicationState: PublicationState.draft,
      title: 'Lesson $id',
      rounds: const [],
    ),
  ],
);

class _FailingCourseStore extends CourseFileStore {
  _FailingCourseStore(Directory support)
    : super(supportDirectory: () async => support);

  bool throwAfterCreate = false;
  bool throwBeforeCreate = false;
  bool throwDuringRecoveryRead = false;
  bool _created = false;

  @override
  Future<CourseStoredRecord?> snapshot(CourseStoreKind kind, String courseId) {
    if (throwDuringRecoveryRead &&
        _created &&
        kind == CourseStoreKind.custom &&
        courseId == 'merged') {
      throw StateError('simulated unreadable recovery record');
    }
    return super.snapshot(kind, courseId);
  }

  @override
  Future<void> createIfAbsent(
    CourseStoreKind kind,
    String courseId,
    Object? entry,
  ) async {
    if (throwBeforeCreate && kind == CourseStoreKind.custom) {
      throw StateError('simulated rejection before Course creation');
    }
    await super.createIfAbsent(kind, courseId, entry);
    _created = true;
    if (throwAfterCreate && kind == CourseStoreKind.custom) {
      throw StateError('simulated error after Course creation');
    }
  }
}

class _FailingMediaStore extends CourseMediaStore {
  _FailingMediaStore(Directory support)
    : super(supportDirectory: () async => support);

  bool throwAfterFirstCopy = false;
  bool throwDuringCleanup = false;

  @override
  Future<int> deleteUnreferenced(String courseId, Set<String> keep) {
    if (throwDuringCleanup) {
      throw StateError('simulated cleanup error after Course save');
    }
    return super.deleteUnreferenced(courseId, keep);
  }

  @override
  Future<Set<String>> copyReferences(
    String fromCourseId,
    String toCourseId,
    Iterable<String> references,
  ) async {
    if (!throwAfterFirstCopy) {
      return super.copyReferences(fromCourseId, toCourseId, references);
    }
    final first = references.first;
    await super.copyReferences(fromCourseId, toCourseId, [first]);
    throw StateError('simulated error after first media copy');
  }
}
