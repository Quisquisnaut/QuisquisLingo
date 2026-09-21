import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart' show getCrc32;
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/exercise_image_metadata.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/exercise_image_metadata_service.dart';
import 'package:quisquislingo_app/services/exercise_image_service.dart';
import 'package:quisquislingo_app/services/file_dialog_service.dart';
import 'package:quisquislingo_app/services/import/image_validator.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_file_dialog_backend.dart';
import 'support/forged_png.dart';

const _adminId = '11111111-1111-4111-8111-111111111111';
const _learnerId = '22222222-2222-4222-8222-222222222222';

Uint8List _asset(String name) =>
    File('assets/exercise_images/$name').readAsBytesSync();

Uint8List _png() => File('assets/lesson_icons/home.png').readAsBytesSync();

/// A PNG chunk with a correct CRC.
List<int> _chunk(String type, List<int> data) {
  final body = [...ascii.encode(type), ...data];
  final length = ByteData(4)..setUint32(0, data.length);
  final crc = ByteData(4)..setUint32(0, getCrc32(body));
  return [...length.buffer.asUint8List(), ...body, ...crc.buffer.asUint8List()];
}

/// [png] with [chunk] inserted right after IHDR.
Uint8List _withChunk(Uint8List png, List<int> chunk) =>
    Uint8List.fromList([...png.sublist(0, 33), ...chunk, ...png.sublist(33)]);

Matcher _refused(String text) => throwsA(
  isA<ImageValidationException>().having(
    (e) => e.message,
    'message',
    contains(text),
  ),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('structure (no decode)', () {
    const any = ImageProfile(maxBytes: 4 * 1024 * 1024);

    test('bundled images and the example bank all pass', () {
      for (final file in Directory(
        'assets/exercise_images',
      ).listSync().whereType<File>()) {
        if (!file.path.endsWith('.webp') && !file.path.endsWith('.png')) {
          continue;
        }
        expect(
          () => ImageValidator.inspect(file.readAsBytesSync(), any),
          returnsNormally,
          reason: file.path,
        );
      }
    });

    test('text or a program under an image name is not an image', () {
      expect(
        () => ImageValidator.inspect(
          Uint8List.fromList(utf8.encode('just some text')),
          any,
        ),
        _refused('Choose a readable PNG, JPEG or WEBP image.'),
      );
      expect(
        () => ImageValidator.inspect(
          Uint8List.fromList([0x4d, 0x5a, 0x90, 0x00, ...List.filled(60, 0)]),
          any,
        ),
        _refused('Choose a readable PNG, JPEG or WEBP image.'),
      );
    });

    test('empty, truncated and tampered images are refused', () {
      expect(
        () => ImageValidator.inspect(Uint8List(0), any),
        _refused('empty'),
      );
      final png = _png();
      expect(
        () => ImageValidator.inspect(png.sublist(0, png.length - 10), any),
        _refused('damaged'),
      );
      final flipped = Uint8List.fromList(png)..[png.length - 20] ^= 0xff;
      expect(() => ImageValidator.inspect(flipped, any), _refused('damaged'));
      final webp = _asset('apple.webp');
      expect(
        () => ImageValidator.inspect(webp.sublist(0, webp.length - 7), any),
        _refused('damaged'),
      );
    });

    testWidgets('huge declared dimensions are refused from the header', (
      tester,
    ) async {
      await tester.runAsync(() async {
        final bomb = await pngDeclaringDimensions(width: 30000, height: 30000);
        expect(bomb.length, lessThan(50 * 1024));
        expect(
          () => ImageValidator.inspect(bomb, ImageProfile.exerciseImage),
          _refused('4096 × 4096'),
        );
        final wide = await pngDeclaringDimensions(width: 4097, height: 16);
        expect(() => ImageValidator.inspect(wide, any), _refused('4096'));
      });
    });

    test('animation is refused: APNG and animated WebP', () {
      expect(
        () => ImageValidator.inspect(
          _withChunk(_png(), _chunk('acTL', List.filled(8, 0))),
          any,
        ),
        _refused('Animated images are not supported'),
      );
      final vp8x = [
        ...ascii.encode('VP8X'),
        10,
        0,
        0,
        0,
        2,
        0,
        0,
        0,
        7,
        0,
        0,
        7,
        0,
        0,
      ];
      final body = [...ascii.encode('WEBP'), ...vp8x];
      final size = ByteData(4)..setUint32(0, body.length, Endian.little);
      expect(
        () => ImageValidator.inspect(
          Uint8List.fromList([
            ...ascii.encode('RIFF'),
            ...size.buffer.asUint8List(),
            ...body,
          ]),
          any,
        ),
        _refused('Animated images are not supported'),
      );
    });

    test('oversized metadata and colour profiles are refused', () {
      final text = _withChunk(
        _png(),
        _chunk('tEXt', List.filled(ImageValidator.maxMetadataBytes + 1, 0x41)),
      );
      expect(
        () => ImageValidator.inspect(text, ImageProfile.lessonIcon),
        _refused('too much embedded metadata'),
      );
      final icc = _withChunk(
        _png(),
        _chunk('iCCP', List.filled(ImageValidator.maxProfileBytes + 1, 0)),
      );
      expect(
        () => ImageValidator.inspect(icc, ImageProfile.lessonIcon),
        _refused('oversized colour profile'),
      );
    });

    test('a JPEG whose frame declares zero height is refused', () {
      final jpeg = Uint8List.fromList([
        0xff, 0xd8, //
        0xff, 0xc0, 0x00, 0x0b, 0x08, 0x00, 0x00, 0x00, 0x10, 0x01, 1, 0x11, 0,
        0xff, 0xda, 0x00, 0x08, 0x01, 0x01, 0x00, 0x00, 0x3f, 0x00,
        0x00, //
        0xff, 0xd9,
      ]);
      expect(() => ImageValidator.inspect(jpeg, any), _refused('damaged'));
    });

    test('a profile may exclude formats', () {
      expect(
        () => ImageValidator.inspect(
          _asset('apple.webp'),
          ImageProfile.courseFlag,
        ),
        _refused('PNG or JPEG'),
      );
    });
  });

  group('import routes', () {
    late Directory support;
    late FakeFileDialogBackend backend;
    late ExerciseImageService images;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        ProfileService.profilesKey: [
          const LearnerProfile(
            learnerProfileId: _adminId,
            displayName: 'Admin',
          ).encode(),
          const LearnerProfile(
            learnerProfileId: _learnerId,
            displayName: 'Learner',
          ).encode(),
        ],
        ProfileService.adminProfileIdsKey: [_adminId],
      });
      support = await Directory.systemTemp.createTemp('qql_tranche2_');
      backend = FakeFileDialogBackend();
      images = ExerciseImageService(
        fileDialogs: FileDialogService(
          backend: backend,
          stager: testImportStager(),
        ),
        supportDirectory: () async => support,
      );
    });

    tearDown(() async {
      if (await support.exists()) await support.delete(recursive: true);
    });

    Directory shared() =>
        Directory('${support.path}${Platform.pathSeparator}exercise_images');

    testWidgets('content wins over the name: a WebP named .png is a WebP', (
      tester,
    ) async {
      await tester.runAsync(() async {
        backend.onOpen = () async =>
            FileDialogResult.opened('photo.png', _asset('apple.webp'));
        final picked = (await images.readImageFromDialog()).picked!;
        expect(picked.image.format, ImageFormat.webp);
        final media = CourseMediaStore(supportDirectory: () async => support);
        final reference = await media.addValidated('course-x', picked.image);
        expect(reference, endsWith('.webp'));
      });
    });

    testWidgets('an Admin adds an image under a name QQL generates', (
      tester,
    ) async {
      await tester.runAsync(() async {
        backend.onOpen = () async =>
            FileDialogResult.opened('My Cat.png', _png());
        final picked = (await images.readImageFromDialog()).picked!;
        final record = await images.addToSharedLibrary(
          actorProfileId: _adminId,
          picked: picked,
          metadata: ExerciseImageMetadataService(),
        );
        expect(record.label, 'My Cat');
        final stored = File(record.assetPath);
        expect(stored.parent.path, shared().path);
        expect(
          stored.uri.pathSegments.last,
          matches(RegExp(r'^image_local_\d+\.png$')),
        );
        expect(await stored.readAsBytes(), _png());
        expect(
          (await ExerciseImageMetadataService().metadataFor(
            record.id,
          )).assetPath,
          stored.path,
        );
      });
    });

    testWidgets('a non-Admin writes nothing', (tester) async {
      await tester.runAsync(() async {
        backend.onOpen = () async => FileDialogResult.opened('cat.png', _png());
        final picked = (await images.readImageFromDialog()).picked!;
        await expectLater(
          images.addToSharedLibrary(
            actorProfileId: _learnerId,
            picked: picked,
            metadata: ExerciseImageMetadataService(),
          ),
          throwsStateError,
        );
        expect(shared().existsSync(), isFalse);
      });
    });

    testWidgets('a failed record leaves no file behind', (tester) async {
      await tester.runAsync(() async {
        backend.onOpen = () async => FileDialogResult.opened('cat.png', _png());
        final picked = (await images.readImageFromDialog()).picked!;
        await expectLater(
          images.addToSharedLibrary(
            actorProfileId: _adminId,
            picked: picked,
            metadata: _FailingCatalog(),
          ),
          throwsA(isA<FormatException>()),
        );
        expect(shared().listSync(), isEmpty);
      });
    });
  });
}

class _FailingCatalog extends ExerciseImageMetadataService {
  @override
  Future<void> addLocalRecord({
    required String actorProfileId,
    required ExerciseImageMetadata record,
  }) async => throw const FormatException('The catalog could not be saved.');
}
