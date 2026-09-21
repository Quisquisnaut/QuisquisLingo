import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/bounded_archive_entry.dart';
import 'package:quisquislingo_app/services/course_flag_service.dart';
import 'package:quisquislingo_app/services/course_package_service.dart';
import 'package:quisquislingo_app/services/image_bank_service.dart';
import 'package:quisquislingo_app/services/import/bounded_zip_reader.dart';
import 'package:quisquislingo_app/services/lesson_icon_service.dart';
import 'package:quisquislingo_app/services/portable_exercise_image.dart';

import 'support/forged_png.dart';

Matcher _formatError(String text) => throwsA(
  isA<FormatException>().having((e) => e.message, 'message', contains(text)),
);

/// Sets every declared uncompressed size, local and central, to [size].
Uint8List _declareSizes(Uint8List zip, int size) {
  final bytes = Uint8List.fromList(zip);
  final view = ByteData.sublistView(bytes);
  for (var i = 0; i + 30 < bytes.length; i++) {
    final signature = view.getUint32(i, Endian.little);
    if (signature == 0x02014b50) {
      view.setUint32(i + 24, size, Endian.little);
    } else if (signature == 0x04034b50) {
      view.setUint32(i + 22, size, Endian.little);
    }
  }
  return bytes;
}

Uint8List _bank(List<ArchiveFile> extra, {String filename = 'a.png'}) {
  final archive = Archive()
    ..addFile(
      ArchiveFile.bytes(
        'image_bank_manifest.json',
        utf8.encode(
          jsonEncode([
            {'id': 'a', 'primary_term': 'A', 'filename': filename},
          ]),
        ),
      ),
    )
    ..addFile(ArchiveFile.bytes('a.png', [1, 2, 3]));
  for (final file in extra) {
    archive.addFile(file);
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

Future<void> _expectBankError(Uint8List zip, String text) async {
  final dir = await Directory.systemTemp.createTemp('qql_tranche0_bank_');
  addTearDown(() => dir.delete(recursive: true));
  final file = File('${dir.path}${Platform.pathSeparator}bank.zip');
  await file.writeAsBytes(zip, flush: true);
  await expectLater(ImageBankService().importBankZip(file), _formatError(text));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('bounded archive entry', () {
    test('output never grows past its limit', () {
      final output = LimitedOutputStream(5, overflowMessage: 'too big');
      output.writeBytes([1, 2, 3]);
      expect(() => output.writeBytes([4, 5, 6]), _formatError('too big'));
      expect(output.length, 3);
      expect(() => output.writeByte(9), returnsNormally);
      expect(() => output.writeBytes([1, 2]), _formatError('too big'));
      expect(output.length, lessThanOrEqualTo(5));
    });

    test('an entry that understates its size stops at the claim', () {
      final payload = List<int>.filled(1 << 20, 65);
      final zip = _declareSizes(
        Uint8List.fromList(
          ZipEncoder().encode(
            Archive()..addFile(ArchiveFile.bytes('big.bin', payload)),
          ),
        ),
        100,
      );
      // Revision 14: the shared BoundedZipReader does the bounded read.
      final reader = BoundedZipReader.open(
        InputMemoryStream(zip),
        label: 'Test ZIP',
        maxEntries: 10,
        maxTotalBytes: 1 << 21,
      );
      expect(
        () => reader.read(reader.entries.single),
        _formatError('expands beyond its declared size'),
      );
    });
  });

  group('Image Bank ZIP pre-scan', () {
    test('rejects a total declared size above 50 MB, referenced or not', () {
      // An unreferenced entry is never read, but its declared size still
      // counts: the archive as a whole must stay within 50 MB.
      final zip = _declareSizes(
        _bank([ArchiveFile.bytes('unreferenced.bin', List.filled(64, 0))]),
        ImageBankService.maxInflatedArchiveBytes ~/ 3 + 1,
      );
      return _expectBankError(zip, 'expands beyond its 50 MB limit');
    });

    test('rejects a symbolic-link entry before decoding', () {
      final link = ArchiveFile.bytes('link.png', utf8.encode('/etc/passwd'))
        ..mode = 0xa1ff;
      return _expectBankError(_bank([link]), 'link or special file');
    });

    test('rejects too many entries before decoding', () {
      final extra = [
        for (var i = 0; i < ImageBankService.maxArchiveEntries; i++)
          ArchiveFile.bytes('x$i.bin', const [0]),
      ];
      return _expectBankError(_bank(extra), 'too many entries');
    });

    test('rejects bytes that are not a ZIP', () {
      return _expectBankError(
        Uint8List.fromList(utf8.encode('not a zip at all')),
        'not a readable Image Bank ZIP',
      );
    });

    test('limits stay as decided', () {
      expect(ImageBankService.maxInflatedArchiveBytes, 50 * 1024 * 1024);
    });
  });

  testWidgets('a Course cover declaring 30,000 × 30,000 is refused '
      'from its header', (tester) async {
    await tester.runAsync(() async {
      final bytes = await pngDeclaringDimensions(width: 30000, height: 30000);
      await expectLater(
        CoursePackageService.checkCoverForTest('media:${'a' * 64}.png', bytes),
        _formatError('exactly 512 × 512'),
      );
    });
  });

  testWidgets('Lesson icons and custom flags stop at 4096 pixels', (
    tester,
  ) async {
    await tester.runAsync(() async {
      expect(LessonIconService.maxSourceDimension, 4096);
      expect(CourseFlagService.maxSourceDimension, 4096);
      await expectLater(
        LessonIconService().prepareIcon(
          await pngDeclaringDimensions(width: 4097, height: 64),
          assetId: 'too_wide',
        ),
        _formatError('at most 4096 pixels'),
      );
      await expectLater(
        CourseFlagService().prepareFlag(
          await pngDeclaringDimensions(width: 4097, height: 64),
        ),
        _formatError('at most 4096 pixels'),
      );
    });
  });

  group('animated images are refused on import', () {
    testWidgets('APNG', (tester) async {
      await tester.runAsync(() async {
        final png = await pngDeclaringDimensions(width: 8, height: 8);
        // Insert an acTL chunk right after IHDR (signature 8 + IHDR 25).
        // A well-formed acTL chunk: length 8, type, 8 zero bytes, CRC.
        final body = [...ascii.encode('acTL'), ...List.filled(8, 0)];
        final crc = ByteData(4)..setUint32(0, getCrc32(body));
        final acTL = [0, 0, 0, 8, ...body, ...crc.buffer.asUint8List()];
        final apng = Uint8List.fromList([
          ...png.sublist(0, 33),
          ...acTL,
          ...png.sublist(33),
        ]);
        await expectLater(
          PortableExerciseImageService.fromBytes(apng),
          _formatError('Animated images are not supported'),
        );
      });
    });

    test('animated WebP (VP8X animation flag or ANIM chunk)', () async {
      Uint8List webp(List<int> chunks) {
        final body = [...ascii.encode('WEBP'), ...chunks];
        return Uint8List.fromList([
          ...ascii.encode('RIFF'),
          ...(ByteData(
            4,
          )..setUint32(0, body.length, Endian.little)).buffer.asUint8List(),
          ...body,
        ]);
      }

      List<int> chunk(String type, List<int> payload) => [
        ...ascii.encode(type),
        ...(ByteData(
          4,
        )..setUint32(0, payload.length, Endian.little)).buffer.asUint8List(),
        ...payload,
        if (payload.length.isOdd) 0,
      ];

      await expectLater(
        PortableExerciseImageService.fromBytes(
          webp(chunk('VP8X', [2, 0, 0, 0, 7, 0, 0, 7, 0, 0])),
        ),
        _formatError('Animated images are not supported'),
      );
      await expectLater(
        PortableExerciseImageService.fromBytes(
          webp([
            ...chunk('VP8X', [0, 0, 0, 0, 7, 0, 0, 7, 0, 0]),
            ...chunk('ANIM', List.filled(6, 0)),
          ]),
        ),
        _formatError('Animated images are not supported'),
      );
    });
  });
}
