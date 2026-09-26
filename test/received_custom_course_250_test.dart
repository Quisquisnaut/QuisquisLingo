import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
import 'package:quisquislingo_app/services/course_library_service.dart';
import 'package:quisquislingo_app/services/course_library_operations.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/course_package_import.dart';
import 'package:quisquislingo_app/services/course_package_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/team_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/unique_png.dart';

const _alice = '11111111-1111-4111-8111-111111111111';
const _bob = '22222222-2222-4222-8222-222222222222';
const _friend = '33333333-3333-4333-8333-333333333333';
const _courseId = 'friend/course 1';
const _team = '44444444-4444-4444-8444-444444444444';
const _receivedKey = 'quisquislingo_received_custom_course_friend%2Fcourse%201';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;
  late CourseEditorService editor;
  late CourseBackupService backups;
  late _PostCommitFailureStore store;
  final profiles = ProfileService();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    root = await Directory.systemTemp.createTemp('qql_received_course_');
    await profiles.createProfile(
      'Alice',
      learnerProfileId: _alice,
      generateScreenNameSuffix: false,
    );
    await profiles.createProfile(
      'Bob',
      learnerProfileId: _bob,
      generateScreenNameSuffix: false,
    );
    await profiles.setActiveProfileById(_alice);
    final media = CourseMediaStore(supportDirectory: () async => root);
    backups = CourseBackupService(
      backupsDirectoryProvider: () async => root,
      mediaStore: media,
    );
    store = _PostCommitFailureStore(root);
    editor = CourseEditorService(
      courseStore: store,
      mediaStore: media,
      backupService: backups,
      clock: () => DateTime.utc(2026, 9, 23, 12),
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test(
    'import records a received Course only when no local profile owns it',
    () async {
      await editor.installImportedCustomCourse(_course(version: '2'));
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(_receivedKey), isTrue);
      expect(
        await CourseLibraryService().contains(_course(version: '2')),
        isTrue,
      );

      await profiles.createProfile(
        'Friend',
        learnerProfileId: _friend,
        generateScreenNameSuffix: false,
      );
      await editor.installImportedCustomCourse(
        _course(id: 'owned', version: '2'),
      );
      expect(
        prefs.containsKey('quisquislingo_received_custom_course_owned'),
        isFalse,
      );
    },
  );

  test(
    'a library member updates a received Course to the imported version',
    () async {
      await editor.installImportedCustomCourse(_course(version: '2'));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(
        'learner_${_alice}_v4_completed_course_$_courseId',
        true,
      );
      await profiles.setActiveProfileById(_bob);
      await CourseLibraryService().add(_course(version: '2'));

      await editor.installImportedCustomCourse(
        _course(version: '5', title: 'Friend Course Updated'),
      );

      final stored = (await editor.listUserCourses()).single;
      expect(stored.courseVersion, '5');
      expect(stored.title, 'Friend Course Updated');
      expect(
        (await backups.listBackups(_courseId)).single.course.courseVersion,
        '2',
      );
      expect(
        prefs.getBool('learner_${_alice}_v4_completed_course_$_courseId'),
        isTrue,
      );
      expect(prefs.getBool(_receivedKey), isTrue);
    },
  );

  test(
    'received update rejects an unavailable World Flag before writes',
    () async {
      await editor.installImportedCustomCourse(_course(version: '2'));

      await expectLater(
        editor.installImportedCustomCourse(
          _course(version: '3', worldFlagId: 'removed_world_flag'),
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('World Flag "removed_world_flag" is unavailable'),
          ),
        ),
      );
      expect((await editor.listUserCourses()).single.courseVersion, '2');
      expect(await backups.listBackups(_courseId), isEmpty);
    },
  );

  test(
    'a profile outside the personal library cannot update a received Course',
    () async {
      await editor.installImportedCustomCourse(_course(version: '2'));
      await profiles.setActiveProfileById(_bob);

      await expectLater(
        editor.installImportedCustomCourse(_course(version: '3')),
        throwsA(isA<StateError>()),
      );
      expect((await editor.listUserCourses()).single.courseVersion, '2');
    },
  );

  test(
    'received update requires unchanged identity and a newer positive version',
    () async {
      await editor.installImportedCustomCourse(_course(version: '2'));
      for (final candidate in [
        _course(version: '2'),
        _course(version: '1'),
        _course(version: ''),
        _course(version: '3', maintainer: _bob),
        _course(version: '3', creator: _bob),
        _course(version: '3', creatorDisplayName: 'Changed friend'),
        _course(version: '3', createdAt: '2026-09-21T09:00:00.000Z'),
        _course(version: '3', assignedTeamId: _team),
      ]) {
        await expectLater(
          editor.installImportedCustomCourse(candidate),
          throwsA(anything),
        );
        expect((await editor.listUserCourses()).single.courseVersion, '2');
      }
    },
  );

  test(
    'a later local Maintainer profile blocks the received update exception',
    () async {
      await editor.installImportedCustomCourse(_course(version: '2'));
      await profiles.createProfile(
        'Friend',
        learnerProfileId: _friend,
        generateScreenNameSuffix: false,
      );
      await profiles.setActiveProfileById(_alice);
      await expectLater(
        editor.installImportedCustomCourse(_course(version: '3')),
        throwsA(isA<StateError>()),
      );
    },
  );

  test('received update keeps the installed assigned Team', () async {
    await editor.installImportedCustomCourse(
      _course(version: '2', assignedTeamId: _team),
    );

    await expectLater(
      editor.installImportedCustomCourse(_course(version: '3')),
      throwsA(isA<StateError>()),
    );
    expect((await editor.listUserCourses()).single.courseVersion, '2');
    expect(await backups.listBackups(_courseId), isEmpty);
  });

  test(
    'a later local assigned Team blocks the received update exception',
    () async {
      await editor.installImportedCustomCourse(
        _course(version: '2', assignedTeamId: _team),
      );
      await TeamService(
        idGenerator: () => _team,
      ).createTeam(creatorProfileId: _alice, displayName: 'Local team');
      await profiles.setActiveProfileById(_bob);
      await CourseLibraryService().add(_course(version: '2'));

      await expectLater(
        editor.installImportedCustomCourse(
          _course(version: '3', assignedTeamId: _team),
        ),
        throwsA(isA<StateError>()),
      );
      expect((await editor.listUserCourses()).single.courseVersion, '2');
    },
  );

  test('local authoring and physical deletion clear a received flag', () async {
    await editor.installImportedCustomCourse(_course(version: '2'));
    final prefs = await SharedPreferences.getInstance();
    await profiles.createProfile(
      'Friend',
      learnerProfileId: _friend,
      generateScreenNameSuffix: false,
    );
    await editor.saveUserCourse(_course(version: '2', title: 'Locally edited'));
    expect(prefs.containsKey(_receivedKey), isFalse);

    await prefs.setBool(_receivedKey, true);
    await editor.deleteUserCourse(_courseId);
    expect(prefs.containsKey(_receivedKey), isFalse);
  });

  test(
    'a stored Course without a flag is never inferred as received',
    () async {
      final old = _course(version: '2');
      await store.write(CourseStoreKind.custom, _courseId, {
        'savedAt': '2026-09-22T00:00:00.000Z',
        'course': old.toJson(),
      });
      await CourseLibraryService().add(old);

      await expectLater(
        editor.installImportedCustomCourse(_course(version: '3')),
        throwsA(isA<StateError>()),
      );
      expect((await editor.listUserCourses()).single.courseVersion, '2');
    },
  );

  test(
    'import review offers received Update only to a library member',
    () async {
      await editor.installImportedCustomCourse(_course(version: '2'));
      final operations = CourseLibraryOperations(editor: editor);
      final incoming = _course(version: '3');
      final attempt = CoursePackageImport(
        CoursePackage(incoming, Uint8List(0), const {}),
        editor: editor,
      );
      await profiles.setActiveProfileById(_bob);
      final outside = await operations.reviewImport(
        attempt,
        await operations.load(importOnly: true),
      );
      expect(outside.choices, isNot(contains(CourseImportChoice.replace)));
      expect(outside.replaceUnavailableReason, contains('Personal Library'));

      await CourseLibraryService().add(incoming);
      final included = await operations.reviewImport(
        attempt,
        await operations.load(importOnly: true),
      );
      expect(included.choices, contains(CourseImportChoice.replace));
      expect(included.receivedUpdate, isTrue);
      expect(included.replaceUnavailableReason, isNull);
      await attempt.close();

      final changed = _course(
        version: '3',
        createdAt: '2026-09-21T09:00:00.000Z',
      );
      final changedAttempt = CoursePackageImport(
        CoursePackage(changed, Uint8List(0), const {}),
        editor: editor,
      );
      final changedReview = await operations.reviewImport(
        changedAttempt,
        await operations.load(importOnly: true),
      );
      expect(
        changedReview.choices,
        isNot(contains(CourseImportChoice.replace)),
      );
      expect(changedReview.replaceUnavailableReason, contains('provenance'));
      await changedAttempt.close();
    },
  );

  test(
    'package update keeps the new media and archives the previous version',
    () async {
      final oldImage = uniquePng(101);
      final newImage = uniquePng(102);
      final oldRef = CourseMediaStore.referenceFor(oldImage, 'png');
      final newRef = CourseMediaStore.referenceFor(newImage, 'png');

      Future<void> install(Course course, String reference, Uint8List bytes) {
        final package = CoursePackage(
          course,
          Uint8List.fromList(utf8.encode(jsonEncode(course.toJson()))),
          {reference: bytes},
        );
        return CoursePackageImport(
          package,
          editor: editor,
        ).installCustomCourse();
      }

      await install(_course(version: '2', images: [oldRef]), oldRef, oldImage);
      await install(_course(version: '5', images: [newRef]), newRef, newImage);

      expect((await editor.listUserCourses()).single.courseVersion, '5');
      expect(await editor.mediaStore.existingFile(_courseId, oldRef), isNull);
      expect(
        await editor.mediaStore.existingFile(_courseId, newRef),
        isNotNull,
      );
      expect(
        (await backups.listBackups(_courseId)).single.course.courseVersion,
        '2',
      );
    },
  );

  test(
    'a post-commit create failure keeps the received flag and package media',
    () async {
      final image = uniquePng(103);
      final reference = CourseMediaStore.referenceFor(image, 'png');
      final incoming = _course(version: '2', images: [reference]);
      final package = CoursePackage(incoming, Uint8List(0), {reference: image});
      store.failCreateAfterCommit = true;

      await expectLater(
        CoursePackageImport(package, editor: editor).installCustomCourse(),
        throwsA(isA<StateError>()),
      );

      final prefs = await SharedPreferences.getInstance();
      expect((await editor.listUserCourses()).single.courseVersion, '2');
      expect(prefs.getBool(_receivedKey), isTrue);
      expect(
        await editor.mediaStore.existingFile(_courseId, reference),
        isNotNull,
      );
      expect(await CourseLibraryService().contains(incoming), isTrue);
    },
  );

  test(
    'a pre-commit create failure removes the provisional received flag',
    () async {
      final image = uniquePng(106);
      final reference = CourseMediaStore.referenceFor(image, 'png');
      final incoming = _course(version: '2', images: [reference]);
      store.failCreateBeforeCommit = true;

      await expectLater(
        CoursePackageImport(
          CoursePackage(incoming, Uint8List(0), {reference: image}),
          editor: editor,
        ).installCustomCourse(),
        throwsA(isA<StateError>()),
      );

      final prefs = await SharedPreferences.getInstance();
      expect(await editor.listUserCourses(), isEmpty);
      expect(prefs.containsKey(_receivedKey), isFalse);
      expect(
        await editor.mediaStore.existingFile(_courseId, reference),
        isNull,
      );
    },
  );

  test(
    'a post-commit received update failure retains media for recovery',
    () async {
      final oldImage = uniquePng(104);
      final newImage = uniquePng(105);
      final oldRef = CourseMediaStore.referenceFor(oldImage, 'png');
      final newRef = CourseMediaStore.referenceFor(newImage, 'png');
      final old = _course(version: '2', images: [oldRef]);
      await CoursePackageImport(
        CoursePackage(old, Uint8List(0), {oldRef: oldImage}),
        editor: editor,
      ).installCustomCourse();
      final update = _course(version: '5', images: [newRef]);
      store.failReplaceAfterCommit = true;

      await expectLater(
        CoursePackageImport(
          CoursePackage(update, Uint8List(0), {newRef: newImage}),
          editor: editor,
        ).installCustomCourse(),
        throwsA(isA<StateError>()),
      );

      expect((await editor.listUserCourses()).single.courseVersion, '5');
      expect(
        await editor.mediaStore.existingFile(_courseId, newRef),
        isNotNull,
      );
      expect(
        (await backups.listBackups(_courseId)).single.course.courseVersion,
        '2',
      );
    },
  );
}

class _PostCommitFailureStore extends CourseFileStore {
  _PostCommitFailureStore(Directory support)
    : super(supportDirectory: () async => support);

  bool failCreateAfterCommit = false;
  bool failCreateBeforeCommit = false;
  bool failReplaceAfterCommit = false;

  @override
  Future<void> createIfAbsent(
    CourseStoreKind kind,
    String courseId,
    Object? entry,
  ) async {
    if (failCreateBeforeCommit) {
      throw StateError('simulated error before Course creation');
    }
    await super.createIfAbsent(kind, courseId, entry);
    if (failCreateAfterCommit) {
      throw StateError('simulated error after Course creation');
    }
  }

  @override
  Future<void> replaceIfUnchanged(
    CourseStoreKind kind,
    String courseId,
    Object? entry, {
    required String expectedToken,
  }) async {
    await super.replaceIfUnchanged(
      kind,
      courseId,
      entry,
      expectedToken: expectedToken,
    );
    if (failReplaceAfterCommit) {
      throw StateError('simulated error after Course replacement');
    }
  }
}

Course _course({
  String id = _courseId,
  required String version,
  String title = 'Friend Course',
  String maintainer = _friend,
  String creator = _friend,
  String creatorDisplayName = 'Friend',
  String createdAt = '2026-09-20T09:00:00.000Z',
  String? assignedTeamId,
  String worldFlagId = '',
  List<String> images = const [],
}) => Course(
  courseId: id,
  originType: CourseOriginType.custom,
  originalCourseCreator: CourseProvenanceIdentity.qqlUser(
    profileId: creator,
    displayName: creatorDisplayName,
  ),
  maintainer: CourseMaintainer(maintainer),
  assignedTeamId: assignedTeamId,
  originalCreatedAtUtc: createdAt,
  courseVersion: version,
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: title,
  ttsLanguage: 'it-IT',
  worldFlagId: worldFlagId,
  imageLibrary: [
    for (final image in images) CourseImageLibraryEntry(asset: image),
  ],
  lessons: const [],
);
