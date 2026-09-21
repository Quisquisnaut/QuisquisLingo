import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/file_dialog_service.dart';
import 'package:quisquislingo_app/services/import/import_result.dart';
import 'package:quisquislingo_app/services/import/mp3_validator.dart';
import 'package:quisquislingo_app/services/import/selected_external_file.dart';
import 'package:quisquislingo_app/services/recorded_audio_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_file_dialog_backend.dart';
import 'support/synthetic_mp3.dart';

/// One MPEG-1 Layer III frame with the given header bytes 2 and 3.
Uint8List _frame(int byte2, {int length = 417}) =>
    Uint8List(length)..setAll(0, [0xff, 0xfb, byte2, 0x00]);

Uint8List _join(List<List<int>> parts) =>
    Uint8List.fromList([for (final part in parts) ...part]);

Matcher _refused([Pattern? message]) => throwsA(
  isA<Mp3ValidationException>().having(
    (error) => error.message,
    'message',
    message == null ? anything : contains(message),
  ),
);

/// Build 243 Revision 13 (Tranche 3): every MP3 route passes one structural
/// check. These are the adversarial cases from the import hardening plan.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Mp3Validator accepts', () {
    test('constant bit rate frames, with duration from the frames', () {
      final facts = Mp3Validator.inspect(syntheticMp3());
      expect(facts.frames, 8);
      expect(facts.durationMs, 8 * 1152 * 1000 ~/ 44100);
      expect(facts.metadataBytes, 0);
    });

    test('variable bit rate', () {
      // 128 kbps (417 bytes) and 160 kbps (522 bytes) frames mixed.
      final bytes = _join([
        for (var i = 0; i < 6; i++)
          i.isEven ? _frame(0x90) : _frame(0xa0, length: 522),
      ]);
      expect(Mp3Validator.inspect(bytes).frames, 6);
    });

    test('an ID3v2 text tag, and ID3v1 and APEv2 trailers', () {
      final title = id3v23Frame('TIT2', [0, ...'Ciao'.codeUnits]);
      final ape = Uint8List(32)
        ..setAll(0, 'APETAGEX'.codeUnits)
        ..buffer.asByteData().setUint32(12, 32, Endian.little);
      final id3v1 = Uint8List(128)..setAll(0, 'TAG'.codeUnits);
      final bytes = _join([syntheticMp3(id3: title), ape, id3v1]);
      final facts = Mp3Validator.inspect(bytes);
      expect(facts.frames, 8);
      expect(facts.metadataBytes, 10 + title.length + 32 + 128);
    });

    test('the bundled sample recordings', () {
      final samples = Directory('assets/audio')
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => file.path.endsWith('.mp3'))
          .toList();
      expect(samples, isNotEmpty);
      for (final sample in samples) {
        expect(
          Mp3Validator.inspect(sample.readAsBytesSync()).frames,
          greaterThanOrEqualTo(Mp3Validator.minFrames),
          reason: sample.path,
        );
      }
    });

    test('validate runs the same check off the UI isolate', () async {
      expect((await Mp3Validator.validate(syntheticMp3())).frames, 8);
      await expectLater(
        Mp3Validator.validate(Uint8List.fromList([1, 2, 3])),
        _refused('not a valid MP3'),
      );
    });
  });

  group('Mp3Validator refuses', () {
    test('an empty file and a file over 50 MB', () {
      expect(() => Mp3Validator.inspect(Uint8List(0)), _refused('empty'));
      expect(
        () => Mp3Validator.inspect(Uint8List(Mp3Validator.maxBytes + 1)),
        _refused('50 MB'),
      );
    });

    test('a ZIP renamed to .mp3', () {
      final zip = ZipEncoder().encode(
        Archive()..addFile(ArchiveFile.bytes('a.txt', utf8.encode('hi'))),
      );
      expect(
        () => Mp3Validator.inspect(Uint8List.fromList(zip)),
        _refused('not a valid MP3'),
      );
    });

    test('a web page saved as .mp3 is named as such', () {
      // Like a download site's "your download is starting" page.
      const start =
          '<!DOCTYPE html><html><head><meta charset="UTF-8"> '
          '<title>File Examples | Download redirect...</title></head><body>';
      const end = '</body></html>\n\n';
      final redirect = Uint8List.fromList(
        utf8.encode(start + 'x' * (1273 - start.length - end.length) + end),
      );
      expect(redirect.length, 1273);
      expect(
        () => Mp3Validator.inspect(redirect),
        _refused('it is a website’s download page'),
      );
      final page = Uint8List.fromList(
        utf8.encode('\u{feff}  <html><body>Not found</body></html>'),
      );
      expect(
        () => Mp3Validator.inspect(page),
        _refused('it is a web page, probably saved by mistake'),
      );
    });

    test('an image renamed to .mp3', () {
      expect(
        () => Mp3Validator.inspect(
          File('assets/exercise_images/apple.webp').readAsBytesSync(),
        ),
        _refused('not a valid MP3'),
      );
    });

    test('an ID3 header with no audio', () {
      expect(() => Mp3Validator.inspect(id3v2Tag(const [])), _refused());
    });

    test('a corrupt synchsafe size and a tag larger than the file', () {
      final corrupt = syntheticMp3(id3: const [])..[6] = 0x80;
      expect(() => Mp3Validator.inspect(corrupt), _refused());
      final overlong = syntheticMp3(id3: const [])..[8] = 0x7f;
      expect(() => Mp3Validator.inspect(overlong), _refused());
    });

    test('a damaged ID3 frame', () {
      final frame = id3v23Frame('TIT2', [0, 1, 2])..[0] = 0x3f; // '?'
      expect(() => Mp3Validator.inspect(syntheticMp3(id3: frame)), _refused());
    });

    test('more than 2 MB of metadata', () {
      final comment = id3v23Frame('TXXX', Uint8List(2 * 1024 * 1024));
      expect(
        () => Mp3Validator.inspect(syntheticMp3(id3: comment)),
        throwsA(isA<Mp3MetadataTooLargeException>()),
      );
    });

    test('embedded artwork', () {
      final artwork = id3v23Frame('APIC', [0, ...'image/png'.codeUnits, 0]);
      expect(
        () => Mp3Validator.inspect(syntheticMp3(id3: artwork)),
        _refused('artwork'),
      );
    });

    test('a truncated last frame and trailing junk', () {
      final whole = syntheticMp3();
      expect(
        () => Mp3Validator.inspect(whole.sublist(0, whole.length - 100)),
        _refused(),
      );
      expect(
        () => Mp3Validator.inspect(_join([whole, utf8.encode('junk')])),
        _refused(),
      );
    });

    test('a single fake sync marker, or fewer than four frames', () {
      final fake = _join([
        _frame(0x90),
        utf8.encode('not audio, just text after a sync marker'),
      ]);
      expect(() => Mp3Validator.inspect(fake), _refused());
      expect(() => Mp3Validator.inspect(syntheticMp3(frames: 3)), _refused());
    });

    test('a bad bit rate, a reserved sample rate or another layer', () {
      for (final bad in [
        _join([for (var i = 0; i < 6; i++) _frame(0xf0)]), // bit rate 15
        _join([for (var i = 0; i < 6; i++) _frame(0x00)]), // free format
        _join([for (var i = 0; i < 6; i++) _frame(0x9c)]), // sample rate 3
        _join([
          for (var i = 0; i < 6; i++)
            Uint8List(417)..setAll(0, [0xff, 0xfd, 0x90, 0x00]), // Layer II
        ]),
      ]) {
        expect(() => Mp3Validator.inspect(bad), _refused());
      }
    });

    test('a sample rate change between frames', () {
      // 128 kbps at 48 kHz is 384 bytes.
      final mixed = _join([
        for (var i = 0; i < 4; i++) _frame(0x90),
        _frame(0x94, length: 384),
      ]);
      expect(() => Mp3Validator.inspect(mixed), _refused());
    });
  });

  group('MP3 routes', () {
    late Directory temp;
    late FakeFileDialogBackend backend;
    late RecordedAudioService audio;
    late CourseMediaStore media;

    setUp(() async {
      temp = await Directory.systemTemp.createTemp('qql_mp3_tranche3_');
      backend = FakeFileDialogBackend();
      final dialogs = FileDialogService(
        backend: backend,
        stager: testImportStager(),
      );
      audio = RecordedAudioService(
        fileDialogs: dialogs,
        supportDirectory: () async => temp,
      );
      media = CourseMediaStore(supportDirectory: () async => temp);
    });
    tearDown(() async {
      try {
        await temp.delete(recursive: true);
      } catch (_) {}
    });

    Future<List<File>> stored() async {
      final folder = await media.courseDirectory('course-a');
      if (!await folder.exists()) return const [];
      return folder.listSync().whereType<File>().toList();
    }

    test('Open from… with several files reports each one', () async {
      final existing = syntheticMp3(seed: 3);
      backend.onOpenMany = [
        MemorySelectedFile('uno.mp3', syntheticMp3(seed: 1)),
        MemorySelectedFile('due.mp3', syntheticMp3(seed: 2)),
        MemorySelectedFile('uno again.mp3', syntheticMp3(seed: 1)),
        MemorySelectedFile('already.mp3', existing),
        MemorySelectedFile(
          'photo.mp3',
          File('assets/exercise_images/apple.webp').readAsBytesSync(),
        ),
        MemorySelectedFile(
          'cover.mp3',
          syntheticMp3(id3: id3v23Frame('APIC', const [0, 0, 0])),
        ),
        MemorySelectedFile(
          'tags.mp3',
          syntheticMp3(id3: id3v23Frame('TXXX', Uint8List(2 * 1024 * 1024))),
        ),
        MemorySelectedFile('voice.wav', syntheticMp3(seed: 4)),
      ];
      final picked = await audio.importMp3sFromDialog(
        'course-a',
        existingReferences: {CourseMediaStore.referenceFor(existing, 'mp3')},
      );
      expect(picked.dialog.outcome, FileDialogOutcome.opened);
      expect(
        {
          for (final result in picked.results)
            result.displayName: result.outcome,
        },
        {
          'uno.mp3': ImportItemOutcome.imported,
          'due.mp3': ImportItemOutcome.imported,
          'uno again.mp3': ImportItemOutcome.duplicateSkipped,
          'already.mp3': ImportItemOutcome.duplicateSkipped,
          'photo.mp3': ImportItemOutcome.malformed,
          'cover.mp3': ImportItemOutcome.malformed,
          'tags.mp3': ImportItemOutcome.metadataTooLarge,
          'voice.wav': ImportItemOutcome.invalidType,
        },
      );
      expect(picked.clips, hasLength(2));
      expect(picked.clips.map((clip) => clip.id).toSet(), hasLength(2));
      expect(picked.clips.map((clip) => clip.filePath), [
        CourseMediaStore.referenceFor(syntheticMp3(seed: 1), 'mp3'),
        CourseMediaStore.referenceFor(syntheticMp3(seed: 2), 'mp3'),
      ]);
      expect(await stored(), hasLength(2));
    });

    test('a cancelled Open from… stores nothing', () async {
      final picked = await audio.importMp3sFromDialog('course-a');
      expect(picked.dialog.outcome, FileDialogOutcome.cancelled);
      expect(picked.results, isEmpty);
      expect(await stored(), isEmpty);
    });

    test('a single Open from… refuses a file that is not an MP3', () async {
      backend.onOpen = () async =>
          FileDialogResult.opened('fake.mp3', Uint8List.fromList([1, 2, 3]));
      await expectLater(
        audio.importMp3FromDialog('course-a'),
        throwsA(isA<Mp3ValidationException>()),
      );
      expect(await stored(), isEmpty);
    });

    test('the fixed folder stores nothing when one file is bad', () async {
      final folder = await audio.fixedImportDirectory();
      final files = [
        File('${folder.path}${Platform.pathSeparator}good.mp3'),
        File('${folder.path}${Platform.pathSeparator}bad.mp3'),
      ];
      addTearDown(() async {
        for (final file in files) {
          if (await file.exists()) await file.delete();
        }
      });
      await files[0].writeAsBytes(syntheticMp3(seed: 5));
      await files[1].writeAsBytes(utf8.encode('not audio'));
      await expectLater(
        audio.importMp3Files('course-a'),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            startsWith('bad.mp3: '),
          ),
        ),
      );
      expect(await stored(), isEmpty);

      await files[1].delete();
      final clips = await audio.importMp3Files('course-a');
      expect(clips, hasLength(1));
      // Already in the Course: skipped the second time.
      expect(
        await audio.importMp3Files(
          'course-a',
          existingReferences: {clips.single.filePath},
        ),
        isEmpty,
      );
    });
  });
}
