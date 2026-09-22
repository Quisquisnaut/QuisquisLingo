import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/course_authoring_media.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/recorded_audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_file_io.dart';
import 'support/synthetic_mp3.dart';

/// Build 248: who owns an imported recording's file between the moment
/// `RecordedAudioService` writes it into the Course's media folder and the
/// single top-level Course confirmation.
///
/// Every test drives the real Course Editor and Audio Library screens against
/// a real Course store and a real [CourseMediaStore] in this test's own
/// temporary support and Documents folders (installed by
/// `flutter_test_config.dart`), so the assertions are about files on disk.
const _profileId = '12345678-1234-4234-9234-123456789abc';
const _courseId = 'audio_media_course';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('cancelling the session removes the recordings it imported', (
    tester,
  ) async {
    final service = _service();
    final stored = _course();
    await tester.runAsync(() => service.saveUserCourse(stored));
    await _putImportFiles(tester, {
      'a.mp3': syntheticMp3(seed: 1),
      'b.mp3': syntheticMp3(seed: 2),
    });

    await _openEditor(tester, service, stored);
    await _openAudioLibrary(tester);
    await _importFromFolder(tester, expectedClips: 2);
    expect(await _storedMp3s(tester), hasLength(2));

    await _saveAudioLibrary(tester);
    await _leaveEditor(tester, confirm: false);

    expect(
      await _storedMp3s(tester),
      isEmpty,
      reason:
          'A cancelled session must not leave the recordings it copied behind.',
    );
  });

  testWidgets(
    'leaving the Audio Library without Save removes only that session’s recordings',
    (tester) async {
      final service = _service();
      final kept = syntheticMp3(seed: 7);
      final keptReference = CourseMediaStore.referenceFor(kept, 'mp3');
      final leftover = syntheticMp3(seed: 8);
      final leftoverReference = CourseMediaStore.referenceFor(leftover, 'mp3');
      final stored = _course(
        clips: [
          CourseAudioClip(
            id: 'clip-kept',
            text: 'ciao',
            filePath: keptReference,
          ),
        ],
      );
      await tester.runAsync(() async {
        await service.saveUserCourse(stored);
        // One file the stored Course uses, and one already-unreferenced file
        // left by an earlier session. Neither belongs to the session below.
        await CourseMediaStore().addBytes(_courseId, kept, 'mp3');
        await CourseMediaStore().addBytes(_courseId, leftover, 'mp3');
      });
      await _putImportFiles(tester, {'new.mp3': syntheticMp3(seed: 9)});

      await _openEditor(tester, service, stored);
      await _openAudioLibrary(tester);
      await _importFromFolder(tester, expectedClips: 1);
      expect(await _storedMp3s(tester), hasLength(3));

      // Back out instead of Save: the draft never receives the clip, so the
      // Editor is not dirty and leaves without asking.
      await tester.pageBack();
      await _settle(tester);
      await _leaveEditor(tester, confirm: false, expectDialog: false);

      expect(
        await _storedMp3s(tester),
        unorderedEquals([
          CourseMediaStore.fileNameOf(keptReference),
          CourseMediaStore.fileNameOf(leftoverReference),
        ]),
        reason:
            'Only the recording this session copied may go; files that were '
            'already in the folder are not this session’s to remove.',
      );
    },
  );

  testWidgets('a partial batch write leaves no unreferenced recording', (
    tester,
  ) async {
    final service = _service();
    final stored = _course();
    final blocked = syntheticMp3(seed: 5);
    await tester.runAsync(() async {
      await service.saveUserCourse(stored);
      // A real injected storage failure: the third recording's target name is
      // taken by a directory, so its rename fails after the first two have
      // already been written.
      final directory = await CourseMediaStore().courseDirectory(
        _courseId,
        create: true,
      );
      await Directory(
        '${directory.path}${Platform.pathSeparator}'
        '${CourseMediaStore.fileNameOf(CourseMediaStore.referenceFor(blocked, 'mp3'))}',
      ).create(recursive: true);
    });
    await _putImportFiles(tester, {
      'a.mp3': syntheticMp3(seed: 3),
      'b.mp3': syntheticMp3(seed: 4),
      'c.mp3': blocked,
    });

    await _openEditor(tester, service, stored);
    await _openAudioLibrary(tester);
    await tester.tap(find.text('Import MP3'));
    await tester.pumpUntilFileIoState(
      () => find.byType(SnackBar).evaluate().isNotEmpty,
    );
    // The batch threw, so no clip reached the draft, but two files were stored.
    expect(find.text('Unassigned MP3'), findsNothing);
    expect(await _storedMp3s(tester), hasLength(2));

    await tester.pageBack();
    await _settle(tester);
    await _leaveEditor(tester, confirm: false, expectDialog: false);

    expect(
      await _storedMp3s(tester),
      isEmpty,
      reason:
          'A batch that failed part way through must not leave stored files '
          'that no clip refers to.',
    );
  });

  testWidgets('an unreadable stored Course retains the recordings', (
    tester,
  ) async {
    final service = _service();
    final stored = _course();
    await tester.runAsync(() => service.saveUserCourse(stored));
    await _putImportFiles(tester, {'a.mp3': syntheticMp3(seed: 11)});

    await _openEditor(tester, service, stored);
    await _openAudioLibrary(tester);
    await _importFromFolder(tester, expectedClips: 1);
    await _saveAudioLibrary(tester);
    final imported = await _storedMp3s(tester);
    expect(imported, hasLength(1));

    // The persisted record can no longer be read, so nothing can prove the
    // saved Course does not use these files.
    await tester.runAsync(_corruptStoredCourse);
    await _leaveEditor(tester, confirm: false);

    expect(
      await _storedMp3s(tester),
      imported,
      reason:
          'A failed read cannot prove that saving failed; the media stay for '
          'recovery.',
    );
  });

  testWidgets('a confirmed Course keeps every imported recording', (
    tester,
  ) async {
    final service = _service();
    final stored = _course();
    await tester.runAsync(() => service.saveUserCourse(stored));
    await _putImportFiles(tester, {
      'a.mp3': syntheticMp3(seed: 21),
      'b.mp3': syntheticMp3(seed: 22),
    });

    await _openEditor(tester, service, stored);
    await _openAudioLibrary(tester);
    await _importFromFolder(tester, expectedClips: 2);
    await _saveAudioLibrary(tester);
    await _leaveEditor(tester, confirm: true);

    final confirmed = ((await tester.runAsync(service.listUserCourses))!).single;
    expect(confirmed.audioLibrary, hasLength(2));
    expect(
      await _storedMp3s(tester),
      unorderedEquals([
        for (final clip in confirmed.audioLibrary)
          CourseMediaStore.fileNameOf(clip.filePath),
      ]),
      reason: 'A confirmed Course keeps exactly the files it uses.',
    );
  });

  group('the media lifetime owner', () {
    late Directory support;
    late CourseMediaStore media;

    setUp(() async {
      support = await Directory.systemTemp.createTemp('qql_248_owner_');
      media = CourseMediaStore(supportDirectory: () async => support);
    });
    tearDown(() async {
      if (await support.exists()) await support.delete(recursive: true);
    });

    test('a Course that was never stored loses what the session created', () async {
      final owner = CourseAuthoringMedia(
        courseId: _courseId,
        persistedReferences: () async => null,
        mediaStore: media,
      );
      await owner.ready;
      await media.addBytes(_courseId, syntheticMp3(seed: 31), 'mp3');

      expect(await owner.discardUnconfirmedMedia(), 1);
      expect(await media.storedReferences(_courseId), isEmpty);
    });

    test('pictures added while editing are left in place', () async {
      final owner = CourseAuthoringMedia(
        courseId: _courseId,
        persistedReferences: () async => null,
        mediaStore: media,
      );
      await owner.ready;
      final picture = await media.addBytes(
        _courseId,
        Uint8List.fromList(const [0x89, 0x50, 0x4e, 0x47, 1, 2, 3]),
        'png',
      );
      await media.addBytes(_courseId, syntheticMp3(seed: 32), 'mp3');

      expect(
        await owner.discardUnconfirmedMedia(),
        1,
        reason: 'Build 248 owns recordings only; pictures are a later build.',
      );
      expect(await media.storedReferences(_courseId), {picture});
    });

    test('an unreadable folder removes nothing', () async {
      final owner = CourseAuthoringMedia(
        courseId: _courseId,
        persistedReferences: () async => null,
        mediaStore: _UnreadableMediaStore(support),
      );
      await owner.ready;

      expect(await owner.discardUnconfirmedMedia(), 0);
    });

    test('the sweep runs once', () async {
      final owner = CourseAuthoringMedia(
        courseId: _courseId,
        persistedReferences: () async => null,
        mediaStore: media,
      );
      await owner.ready;
      await media.addBytes(_courseId, syntheticMp3(seed: 33), 'mp3');

      expect(await owner.discardUnconfirmedMedia(), 1);
      await media.addBytes(_courseId, syntheticMp3(seed: 34), 'mp3');
      expect(
        await owner.discardUnconfirmedMedia(),
        1,
        reason: 'The second call reports the first result without re-running.',
      );
      expect(await media.storedReferences(_courseId), hasLength(1));
    });
  });
}

/// A store whose folder cannot be listed, so nothing can be proven about it.
class _UnreadableMediaStore extends CourseMediaStore {
  _UnreadableMediaStore(Directory support)
    : super(supportDirectory: () async => support);

  @override
  Future<Set<String>> storedReferences(String courseId) async =>
      throw const FileSystemException('The Course media folder is unreadable.');
}

/// The Audio Library builds a preview player as soon as it opens.
void _mockAudio() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers.global'),
    (_) async => null,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers'),
    (call) async {
      if (call.method == 'create') {
        final arguments = call.arguments as Map<Object?, Object?>;
        messenger.setMockMessageHandler(
          'xyz.luan/audioplayers/events/${arguments['playerId']}',
          (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null),
        );
      }
      return null;
    },
  );
  messenger.setMockMessageHandler(
    'xyz.luan/audioplayers.global/events',
    (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null),
  );
}

CourseEditorService _service() {
  _mockAudio();
  SharedPreferences.setMockInitialValues({
    ProfileService.profilesKey: [
      const LearnerProfile(
        learnerProfileId: _profileId,
        displayName: 'Audio Author',
      ).encode(),
    ],
    ProfileService.activeProfileIdKey: _profileId,
    'course_editor_locked_${_courseId.toUpperCase()}': false,
  });
  return CourseEditorService(clock: () => DateTime.utc(2026, 9, 22, 12));
}

Course _course({List<CourseAudioClip> clips = const []}) {
  final exercise = Exercise(
    id: 'exercise',
    publicationState: PublicationState.draft,
    updatedAt: DateTime.utc(2026, 9, 22, 10),
    type: 'choice',
    prompt: 'Original prompt',
    question: 'Choose one.',
    answers: const ['One', 'Two'],
    correct: 0,
    tts: null,
    accepted: const [],
    tokens: const [],
    orderAnswer: const [],
    pairs: const [],
    hint: '',
    icons: const [],
  );
  return Course(
    courseId: _courseId,
    originType: CourseOriginType.custom,
    originalCourseCreator: CourseProvenanceIdentity.qqlUser(
      profileId: _profileId,
      displayName: 'Audio Author',
    ),
    maintainer: const CourseMaintainer(_profileId),
    originalCreatedAtUtc: '2026-09-22T09:00:00.000Z',
    publicationState: PublicationState.draft,
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Audio Media Course',
    ttsLanguage: 'it-IT',
    courseVersion: '1',
    audioMode: 'recorded',
    audioLibrary: clips,
    lessons: [
      Lesson(
        lessonId: 'lesson',
        publicationState: PublicationState.draft,
        updatedAt: DateTime.utc(2026, 9, 22, 10),
        title: 'Lesson',
        rounds: [
          LearningRound(
            id: 'round',
            publicationState: PublicationState.draft,
            updatedAt: DateTime.utc(2026, 9, 22, 10),
            title: 'Round',
            exercises: [exercise],
          ),
        ],
      ),
    ],
  );
}

/// The Course's own stored recordings, by file name.
Future<List<String>> _storedMp3s(WidgetTester tester) async =>
    (await tester.runAsync(() async {
      final directory = await CourseMediaStore().courseDirectory(_courseId);
      if (!await directory.exists()) return <String>[];
      final names = <String>[];
      await for (final entity in directory.list(followLinks: false)) {
        if (entity is File && entity.path.toLowerCase().endsWith('.mp3')) {
          names.add(entity.uri.pathSegments.last);
        }
      }
      names.sort();
      return names;
    }))!;

Future<void> _putImportFiles(
  WidgetTester tester,
  Map<String, List<int>> files,
) async {
  await tester.runAsync(() async {
    final directory = await RecordedAudioService().fixedImportDirectory();
    for (final entry in files.entries) {
      await File(
        '${directory.path}${Platform.pathSeparator}${entry.key}',
      ).writeAsBytes(entry.value, flush: true);
    }
  });
}

Future<void> _corruptStoredCourse() async {
  final directory = await CourseFileStore().directoryFor(
    CourseStoreKind.custom,
  );
  await File(
    '${directory.path}${Platform.pathSeparator}'
    '${CourseBackupService.sanitizedCourseId(_courseId)}.json',
  ).writeAsString('{ this is not a Course record', flush: true);
}

Future<void> _openEditor(
  WidgetTester tester,
  CourseEditorService service,
  Course course,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(1200, 1800);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => FilledButton(
          onPressed: () => Navigator.of(context).push<CourseConfirmationResult>(
            MaterialPageRoute(
              builder: (_) => CourseEditorScreen(
                course: course,
                userCourse: true,
                editorService: service,
                clock: () => DateTime.utc(2026, 9, 22, 12),
              ),
            ),
          ),
          child: const Text('Open Course'),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open Course'));
  await tester.pumpUntilFileIoState(
    () => find.text('Audio Library').evaluate().isNotEmpty,
  );
}

Future<void> _openAudioLibrary(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    find.text('Audio Library'),
    300,
    scrollable: find
        .descendant(of: find.byType(ListView), matching: find.byType(Scrollable))
        .first,
  );
  await tester.tap(find.text('Audio Library'));
  await tester.pumpUntilFileIoState(
    () => find.text('Import MP3').evaluate().isNotEmpty,
  );
}

Future<void> _importFromFolder(
  WidgetTester tester, {
  required int expectedClips,
}) async {
  await tester.tap(find.text('Import MP3'));
  await tester.pumpUntilFileIoState(
    () => find.text('Unassigned MP3').evaluate().length == expectedClips,
  );
}

Future<void> _saveAudioLibrary(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(TextButton, 'Save'));
  await tester.pumpUntilFileIoState(
    () => find.text('Import MP3').evaluate().isEmpty,
  );
}

Future<void> _leaveEditor(
  WidgetTester tester, {
  required bool confirm,
  bool expectDialog = true,
}) async {
  await tester.tap(find.byType(BackButton).last);
  await _settle(tester);
  if (expectDialog) {
    expect(
      find.byKey(const Key('course-transaction-confirmation')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(
        confirm
            ? const Key('confirm-course-changes')
            : const Key('cancel-course-changes'),
      ),
    );
  }
  await tester.pumpUntilFileIoState(
    () => find.byType(CourseEditorScreen).evaluate().isEmpty,
  );
}

Future<void> _settle(WidgetTester tester) async {
  for (var frame = 0; frame < 12; frame++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
