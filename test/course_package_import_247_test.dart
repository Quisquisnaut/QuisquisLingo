import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/course_package_import.dart';
import 'package:quisquislingo_app/services/course_package_service.dart';
import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/import/import_stager.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/trusted_publishers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/publisher_fixtures.dart';
import 'support/synthetic_mp3.dart';
import 'support/unique_png.dart';

const _authorId = '12345678-1234-4234-9234-123456789abc';
const _otherId = '22222222-2222-4222-8222-222222222222';
final _when = DateTime.utc(2026, 9, 22, 12);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory support;
  late _FailingCourseStore store;
  late _RecordingMediaStore media;
  late CourseEditorService editor;
  late CoursePackageService packages;
  var zipCount = 0;

  setUp(() async {
    support = await Directory.systemTemp.createTemp('qql_247_import_');
    SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [
        const LearnerProfile(
          learnerProfileId: _authorId,
          displayName: 'Import Author',
        ).encode(),
      ],
      ProfileService.activeProfileIdKey: _authorId,
    });
    store = _FailingCourseStore(support);
    media = _RecordingMediaStore(support);
    editor = CourseEditorService(
      courseStore: store,
      mediaStore: media,
      backupService: CourseBackupService(
        documentsDirectoryProvider: () async => support,
        mediaStore: media,
      ),
      clock: () => _when,
    );
    packages = CoursePackageService(
      mediaStore: media,
      stager: ImportStager(supportDirectory: () async => support),
    );
  });

  tearDown(() async {
    if (await support.exists()) await support.delete(recursive: true);
  });

  /// A package read from a real ZIP on disk, so its media wait in staging.
  Future<CoursePackage> zipPackage(
    Course course,
    Map<String, Uint8List> files,
  ) async {
    final json = Uint8List.fromList(utf8.encode(jsonEncode(course.toJson())));
    final zip = await packages.build(course, json, suppliedMedia: files);
    final file = File('${support.path}/package_${zipCount++}.zip');
    await file.writeAsBytes(zip, flush: true);
    return packages.parseFile(
      file,
      (bytes, _) async => Course.fromJson(
        Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map),
      ),
    );
  }

  Future<List<String>> stagedFiles() async {
    final directory = Directory(
      '${support.path}/${ImportStager.stagingDirectoryName}',
    );
    if (!await directory.exists()) return const [];
    return [
      await for (final entity in directory.list(recursive: true))
        if (entity is File) entity.path,
    ];
  }

  Future<Set<String>> storedIds() async => {
    for (final course in await editor.listUserCourses()) course.courseId,
  };

  Future<bool> hasMedia(String courseId, String reference) async =>
      await media.existingFile(courseId, reference) != null;

  // The routes CourseProjectsScreen takes, through one import attempt each.

  Future<void> installCustom(CoursePackage package) =>
      CoursePackageImport(package, editor: editor).installCustomCourse();

  Future<CourseConfirmationResult> copyAsNew(
    CoursePackage package,
    String title,
  ) => CoursePackageImport(
    package,
    editor: editor,
  ).copyAsNewCourse(title: title);

  Future<CourseConfirmationResult> fork(CoursePackage package) =>
      CoursePackageImport(package, editor: editor).fork();

  group('new custom Course', () {
    test('installs media in its own folder and leaves no staging', () async {
      final a = uniquePng(1);
      final b = uniquePng(2);
      final refA = CourseMediaStore.referenceFor(a, 'png');
      final refB = CourseMediaStore.referenceFor(b, 'png');
      final package = await zipPackage(_course('new', images: [refA, refB]), {
        refA: a,
        refB: b,
      });
      expect(await stagedFiles(), hasLength(2));

      await installCustom(package);

      expect(await storedIds(), {'new'});
      expect(await hasMedia('new', refA), isTrue);
      expect(await hasMedia('new', refB), isTrue);
      expect(await stagedFiles(), isEmpty);
    });

    test('writes no media while another operation holds the Course', () async {
      final a = uniquePng(3);
      final refA = CourseMediaStore.referenceFor(a, 'png');
      final package = await zipPackage(_course('held', images: [refA]), {
        refA: a,
      });
      final entered = Completer<void>();
      final release = Completer<void>();
      final holder = store.withCourseLock('held', () async {
        entered.complete();
        await release.future;
      });
      await entered.future;

      final importing = installCustom(package);
      final writtenWhileHeld = await _eventually(() => hasMedia('held', refA));
      release.complete();
      await holder;
      await importing;

      expect(
        writtenWhileHeld,
        isFalse,
        reason: 'media must be installed inside the Course lock',
      );
      expect(await storedIds(), {'held'});
      expect(await hasMedia('held', refA), isTrue);
    });

    test('a partial media write removes only files it created', () async {
      final sentinel = await media.addBytes('partial', uniquePng(4), 'png');
      final a = uniquePng(5);
      final b = uniquePng(6);
      final refA = CourseMediaStore.referenceFor(a, 'png');
      final refB = CourseMediaStore.referenceFor(b, 'png');
      final package = await zipPackage(
        _course('partial', images: [refA, refB]),
        {refA: a, refB: b},
      );
      media.writes.clear();
      media.failSecondWriteFor = 'partial';

      await expectLater(installCustom(package), throwsA(isA<StateError>()));

      expect(await storedIds(), isEmpty);
      expect(await hasMedia('partial', refA), isFalse);
      expect(await hasMedia('partial', refB), isFalse);
      expect(await hasMedia('partial', sentinel), isTrue);
      expect(await stagedFiles(), isEmpty);
    });

    test('a save rejected before commit removes created media', () async {
      final a = uniquePng(7);
      final refA = CourseMediaStore.referenceFor(a, 'png');
      final package = await zipPackage(_course('rejected', images: [refA]), {
        refA: a,
      });
      store.throwBeforeCreate = true;

      await expectLater(installCustom(package), throwsA(isA<StateError>()));

      expect(await storedIds(), isEmpty);
      expect(await hasMedia('rejected', refA), isFalse);
      expect(await stagedFiles(), isEmpty);
    });

    test('a post-commit error keeps the imported Course media', () async {
      final a = uniquePng(8);
      final refA = CourseMediaStore.referenceFor(a, 'png');
      final package = await zipPackage(_course('late', images: [refA]), {
        refA: a,
      });
      store.throwAfterCreate = true;

      await expectLater(installCustom(package), throwsA(isA<StateError>()));

      expect(await storedIds(), {'late'});
      expect(await hasMedia('late', refA), isTrue);
      expect(await stagedFiles(), isEmpty);
    });

    test('an unreadable recovery check keeps created media', () async {
      final a = uniquePng(9);
      final refA = CourseMediaStore.referenceFor(a, 'png');
      final package = await zipPackage(_course('unknown', images: [refA]), {
        refA: a,
      });
      store.throwAfterCreate = true;
      store.throwDuringRecoveryRead = true;

      await expectLater(installCustom(package), throwsA(isA<StateError>()));

      store.throwDuringRecoveryRead = false;
      expect(await storedIds(), {'unknown'});
      expect(await hasMedia('unknown', refA), isTrue);
    });
  });

  group('Replace / update', () {
    test(
      'keeps new media and removes media only the old version used',
      () async {
        final shared = uniquePng(10);
        final oldOnly = uniquePng(11);
        final added = uniquePng(12);
        final refShared = await media.addBytes('same', shared, 'png');
        final refOld = await media.addBytes('same', oldOnly, 'png');
        final refAdded = CourseMediaStore.referenceFor(added, 'png');
        await editor.installImportedCustomCourse(
          _course('same', images: [refShared, refOld]),
        );
        final package = await zipPackage(
          _course('same', title: 'Updated', images: [refShared, refAdded]),
          {refShared: shared, refAdded: added},
        );

        await installCustom(package);

        final stored = (await editor.listUserCourses()).single;
        expect(stored.title, 'Updated');
        expect(await hasMedia('same', refShared), isTrue);
        expect(await hasMedia('same', refAdded), isTrue);
        expect(await hasMedia('same', refOld), isFalse);
        expect(await stagedFiles(), isEmpty);
      },
    );

    test(
      'a Replace rejected before commit removes only the media it created',
      () async {
        final shared = uniquePng(13);
        final added = uniquePng(14);
        final refShared = await media.addBytes('same', shared, 'png');
        final refAdded = CourseMediaStore.referenceFor(added, 'png');
        await editor.installImportedCustomCourse(
          _course('same', images: [refShared]),
        );
        final package = await zipPackage(
          _course('same', title: 'Updated', images: [refShared, refAdded]),
          {refShared: shared, refAdded: added},
        );
        store.throwBeforeReplace = true;

        await expectLater(installCustom(package), throwsA(isA<StateError>()));

        final stored = (await editor.listUserCourses()).single;
        expect(stored.title, 'Imported Course');
        expect(await hasMedia('same', refShared), isTrue);
        // The stored Course is still the previous version, which never used
        // the file this attempt added.
        expect(await hasMedia('same', refAdded), isFalse);
        expect(await stagedFiles(), isEmpty);
      },
    );

    test(
      'a Replace that commits before an error keeps its new media',
      () async {
        final shared = uniquePng(15);
        final added = uniquePng(16);
        final refShared = await media.addBytes('same', shared, 'png');
        final refAdded = CourseMediaStore.referenceFor(added, 'png');
        await editor.installImportedCustomCourse(
          _course('same', images: [refShared]),
        );
        final package = await zipPackage(
          _course('same', title: 'Updated', images: [refShared, refAdded]),
          {refShared: shared, refAdded: added},
        );
        store.throwAfterReplace = true;

        await expectLater(installCustom(package), throwsA(isA<StateError>()));

        expect((await editor.listUserCourses()).single.title, 'Updated');
        expect(await hasMedia('same', refShared), isTrue);
        expect(await hasMedia('same', refAdded), isTrue);
      },
    );
  });

  group('Copy as New Course and Fork from an import', () {
    Future<({String sentinel, String refNew, CoursePackage package})> sameId({
      required String maintainer,
      DerivativeWorksPolicy policy = DerivativeWorksPolicy.unspecified,
    }) async {
      final sentinel = await media.addBytes('same', uniquePng(20), 'png');
      await editor.installImportedCustomCourse(
        _course(
          'same',
          images: [sentinel],
          maintainer: maintainer,
          policy: policy,
        ),
      );
      final fresh = uniquePng(21);
      final refNew = CourseMediaStore.referenceFor(fresh, 'png');
      final package = await zipPackage(
        _course(
          'same',
          title: 'Incoming',
          images: [refNew],
          maintainer: maintainer,
          policy: policy,
        ),
        {refNew: fresh},
      );
      media.writes.clear();
      return (sentinel: sentinel, refNew: refNew, package: package);
    }

    test('Copy never writes into the same-ID Course folder', () async {
      final item = await sameId(maintainer: _authorId);

      final created = await copyAsNew(item.package, 'Incoming (copy)');

      final copyId = created.course.courseId;
      expect(copyId, isNot('same'));
      expect(await hasMedia(copyId, item.refNew), isTrue);
      expect(await hasMedia('same', item.refNew), isFalse);
      expect(await hasMedia('same', item.sentinel), isTrue);
      expect(await storedIds(), {'same', copyId});
      expect(await stagedFiles(), isEmpty);
      expect(
        media.writes.where((write) => write.startsWith('same|')),
        isEmpty,
        reason: 'package media belong only to the new Course',
      );
    });

    test('Fork never writes into the same-ID Course folder', () async {
      final item = await sameId(
        maintainer: _otherId,
        policy: DerivativeWorksPolicy.allowed,
      );

      final created = await fork(item.package);

      final forkId = created.course.courseId;
      expect(created.course.forkProvenance?.sourceCourseId, 'same');
      expect(await hasMedia(forkId, item.refNew), isTrue);
      expect(await hasMedia('same', item.refNew), isFalse);
      expect(await hasMedia('same', item.sentinel), isTrue);
      expect(await stagedFiles(), isEmpty);
      expect(
        media.writes.where((write) => write.startsWith('same|')),
        isEmpty,
        reason: 'package media belong only to the new Course',
      );
    });

    test(
      'a rejected Copy leaves no new files and the same-ID Course intact',
      () async {
        final item = await sameId(maintainer: _authorId);
        store.throwBeforeCreate = true;

        await expectLater(
          copyAsNew(item.package, 'Incoming (copy)'),
          throwsA(isA<StateError>()),
        );

        expect(await storedIds(), {'same'});
        expect(await hasMedia('same', item.sentinel), isTrue);
        expect(await hasMedia('same', item.refNew), isFalse);
        final folders = await (await media.rootDirectory())
            .list()
            .where((entity) => entity is Directory)
            .length;
        expect(folders, 1, reason: 'only the same-ID Course folder remains');
        expect(await stagedFiles(), isEmpty);
      },
    );
  });

  group('import attempt', () {
    test('installs once, then refuses another action', () async {
      final a = uniquePng(50);
      final refA = CourseMediaStore.referenceFor(a, 'png');
      final attempt = CoursePackageImport(
        await zipPackage(_course('once', images: [refA]), {refA: a}),
        editor: editor,
      );

      await attempt.installCustomCourse();
      await expectLater(
        attempt.copyAsNewCourse(title: 'Again'),
        throwsA(isA<StateError>()),
      );
      await attempt.close();

      expect(await storedIds(), {'once'});
      expect(await stagedFiles(), isEmpty);
    });

    test('close ends the attempt without writing anything', () async {
      final a = uniquePng(51);
      final refA = CourseMediaStore.referenceFor(a, 'png');
      final attempt = CoursePackageImport(
        await zipPackage(_course('closed', images: [refA]), {refA: a}),
        editor: editor,
      );
      media.writes.clear();

      await attempt.close();
      await attempt.close();
      await expectLater(
        attempt.installCustomCourse(),
        throwsA(isA<StateError>()),
      );

      expect(await stagedFiles(), isEmpty);
      expect(await storedIds(), isEmpty);
      expect(media.writes, isEmpty);
    });

    test('a package for another Course is refused before any write', () async {
      final a = uniquePng(52);
      final refA = CourseMediaStore.referenceFor(a, 'png');
      final package = await zipPackage(_course('packaged', images: [refA]), {
        refA: a,
      });
      media.writes.clear();

      await expectLater(
        editor.installImportedCustomCourse(
          _course('packaged', title: 'Changed', images: [refA]),
          package: package,
        ),
        throwsFormatException,
      );
      await package.discard();

      expect(await storedIds(), isEmpty);
      expect(media.writes, isEmpty);
    });

    test(
      'a Publisher Course installs its media and leaves no staging',
      () async {
        final verifier = fixtureVerifier(
          TrustedPublishers.dummy.publisherId,
          TrustedPublishers.dummy.publisherName,
        );
        final publisherEditor = CourseEditorService(
          courseStore: store,
          mediaStore: media,
          backupService: CourseBackupService(
            documentsDirectoryProvider: () async => support,
            publisherVerification: verifier,
            mediaStore: media,
          ),
          publisherVerification: verifier,
          clock: () => _when,
        );
        final base = Course.fromJson(
          Map<String, dynamic>.from(
            jsonDecode(
                  File(
                    'test/fixtures/publishers/dummy-signed-v1.json',
                  ).readAsStringSync(),
                )
                as Map,
          ),
        );
        final recording = syntheticMp3(seed: 3);
        final reference = CourseMediaStore.referenceFor(recording, 'mp3');
        final signed = await signFixture(
          Course.fromJson({
            ...base.toJson(),
            'audioMode': 'recorded',
            'audioLibrary': [
              {'id': 'clip', 'text': 'ciao', 'filePath': reference},
            ],
          }),
        );
        final zip = await packages.build(
          signed,
          Uint8List.fromList(utf8.encode(jsonEncode(signed.toJson()))),
          suppliedMedia: {reference: recording},
        );
        final package = await packages.parse(
          zip,
          CustomCourseTransferService(
            publisherVerification: verifier,
          ).courseFromBytes,
        );
        expect(await stagedFiles(), hasLength(1));

        final result = await CoursePackageImport(
          package,
          editor: publisherEditor,
        ).installPublisherCourse(confirmUnverifiedAssociation: false);

        expect(result.officialCourse.audioLibrary.single.filePath, reference);
        expect(await hasMedia(signed.courseId, reference), isTrue);
        expect(await stagedFiles(), isEmpty);
      },
    );
  });

  test(
    'known limit: the manifest lists shared-image provenance only for Exercise prompt images',
    () async {
      const source = {
        'id': 'bank-cat-01',
        'label': 'Cat',
        'category': 'animals',
        'tags': ['cat'],
        'origin': 'bank:animals',
      };
      final images = {
        for (var seed = 30; seed < 36; seed++) seed: uniquePng(seed),
      };
      final refs = {
        for (final entry in images.entries)
          entry.key: CourseMediaStore.referenceFor(entry.value, 'png'),
      };
      Map<String, dynamic> image(int seed, [String role = 'primary']) => {
        'role': role,
        'type': 'image',
        'asset': refs[seed],
        'sharedImageSource': source,
      };
      final raw =
          jsonDecode(
                await File(
                  'demo_courses/italian_demo_2_pick_the_translation.json',
                ).readAsString(),
              )
              as Map<String, dynamic>;
      final lesson = (raw['lessons'] as List).first as Map;
      final round = (lesson['rounds'] as List).first as Map;
      final content = round['content'] as List;
      final exercise = (content.first as Map)['exercise'] as Map;
      (exercise['prompt'] as List)[1] = image(30, 'clue');
      final interaction = exercise['interaction'] as Map;
      ((interaction['items'] as List).first['content'] as List).add(image(31));
      interaction['layout'] = [image(32)];
      Map<String, dynamic> flashcard(String id, int seed) => {
        'id': id,
        'publicationState': 'published',
        'kind': 'presentation',
        'required': true,
        'editorTemplate': 'flashcard',
        'presentation': {
          'content': [
            {'role': 'term', 'type': 'text', 'text': 'Gatto'},
            image(seed, 'image'),
          ],
          'completion': {
            'actions': ['understood', 'review_later'],
          },
        },
      };
      content.add(flashcard('manifest-round-flashcard', 33));
      (lesson['guidebook'] as Map)['content'] = [
        flashcard('manifest-guidebook-flashcard', 34),
      ];
      raw['imageLibrary'] = [
        {'asset': refs[35], 'sharedImageSource': source},
      ];
      final course = Course.fromJson(raw);
      expect(
        CourseMediaStore.referencesOf(course),
        containsAll(refs.values),
        reason: 'every image is Course media',
      );

      final zip = await packages.build(
        course,
        Uint8List.fromList(utf8.encode(jsonEncode(course.toJson()))),
        suppliedMedia: {
          for (final entry in images.entries) refs[entry.key]!: entry.value,
        },
      );
      final manifest =
          jsonDecode(
                utf8.decode(
                  ZipDecoder()
                          .decodeBytes(zip)
                          .files
                          .singleWhere(
                            (file) =>
                                file.name == CoursePackageService.manifestName,
                          )
                          .content
                      as List<int>,
                ),
              )
              as Map<String, dynamic>;
      final listed = {
        for (final entry in manifest['sharedImageSources'] as List)
          (entry as Map)['media'],
      };
      // Only the prompt image is listed. Answer item, layout, presentation,
      // GuideBook and Course image library provenance is absent here.
      expect(listed, {refs[30]});

      // Nothing is lost: course.json carries every source, and the package
      // still imports because export and import build the list the same way.
      final imported = await packages.parse(
        zip,
        (bytes, _) async => Course.fromJson(
          Map<String, dynamic>.from(jsonDecode(utf8.decode(bytes)) as Map),
        ),
      );
      expect(imported.course.toJson(), course.toJson());
      expect(
        imported.course.imageLibrary.single.sharedImageSource?.id,
        'bank-cat-01',
      );
      await imported.discard();
    },
  );
}

/// Polls [condition] for a short bounded period; never waits indefinitely.
Future<bool> _eventually(Future<bool> Function() condition) async {
  final deadline = DateTime.now().add(const Duration(milliseconds: 500));
  while (DateTime.now().isBefore(deadline)) {
    if (await condition()) return true;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  return condition();
}

Course _course(
  String id, {
  String title = 'Imported Course',
  List<String> images = const [],
  String maintainer = _authorId,
  DerivativeWorksPolicy policy = DerivativeWorksPolicy.unspecified,
}) => Course(
  courseId: id,
  originType: CourseOriginType.custom,
  originalCourseCreator: CourseProvenanceIdentity.qqlUser(
    profileId: maintainer,
    displayName: 'Original Author',
  ),
  maintainer: CourseMaintainer(maintainer),
  originalCreatedAtUtc: '2026-09-20T09:00:00.000Z',
  courseVersion: '1',
  publicationState: PublicationState.draft,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: title,
  ttsLanguage: 'it-IT',
  derivativeWorksPolicy: policy,
  imageLibrary: [
    for (final image in images) CourseImageLibraryEntry(asset: image),
  ],
  lessons: [
    Lesson(
      lessonId: 'lesson-$id',
      publicationState: PublicationState.draft,
      title: 'Lesson',
      rounds: const [],
    ),
  ],
);

class _FailingCourseStore extends CourseFileStore {
  _FailingCourseStore(Directory support)
    : super(supportDirectory: () async => support);

  bool throwBeforeCreate = false;
  bool throwAfterCreate = false;
  bool throwBeforeReplace = false;
  bool throwAfterReplace = false;
  bool throwDuringRecoveryRead = false;
  bool _failed = false;

  @override
  Future<CourseStoredRecord?> snapshot(CourseStoreKind kind, String courseId) {
    if (throwDuringRecoveryRead && _failed && kind == CourseStoreKind.custom) {
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
      _failed = true;
      throw StateError('simulated rejection before Course creation');
    }
    await super.createIfAbsent(kind, courseId, entry);
    if (throwAfterCreate && kind == CourseStoreKind.custom) {
      _failed = true;
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
    if (throwBeforeReplace && kind == CourseStoreKind.custom) {
      _failed = true;
      throw StateError('simulated rejection before Course replacement');
    }
    await super.replaceIfUnchanged(
      kind,
      courseId,
      entry,
      expectedToken: expectedToken,
    );
    if (throwAfterReplace && kind == CourseStoreKind.custom) {
      _failed = true;
      throw StateError('simulated error after Course replacement');
    }
  }
}

/// Records every media write as `courseId|reference`.
class _RecordingMediaStore extends CourseMediaStore {
  _RecordingMediaStore(Directory support)
    : super(supportDirectory: () async => support);

  final writes = <String>[];
  String? failSecondWriteFor;

  @override
  Future<String> addBytes(
    String courseId,
    Uint8List bytes,
    String extension,
  ) async {
    if (failSecondWriteFor == courseId &&
        writes.any((write) => write.startsWith('$courseId|'))) {
      throw StateError('simulated media write failure');
    }
    final reference = await super.addBytes(courseId, bytes, extension);
    writes.add('$courseId|$reference');
    return reference;
  }
}
