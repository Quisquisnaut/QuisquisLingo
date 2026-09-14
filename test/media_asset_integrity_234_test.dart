import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Map<String, String> lockedAudioHashes() {
    final decoded =
        jsonDecode(File('tools/media_asset_hashes.json').readAsStringSync())
            as Map<String, dynamic>;
    return Map<String, String>.from(decoded['audioSha256'] as Map);
  }

  Uint8List bytesFromBundle(ByteData data) =>
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

  test('all 19 existing audio assets are exact, hash-locked files', () {
    final expected = lockedAudioHashes();
    final actualFiles = Directory('assets/audio')
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (file) =>
              file.path.toLowerCase().endsWith('.mp3') ||
              file.path.toLowerCase().endsWith('.wav'),
        )
        .toList();
    final actual = <String, File>{
      for (final file in actualFiles) file.path.replaceAll('\\', '/'): file,
    };

    expect(expected, hasLength(19));
    expect(actual.keys.toSet(), expected.keys.toSet());
    expect(actual.keys.any((path) => path.contains('/nap_sample/')), isFalse);
    for (final entry in expected.entries) {
      expect(
        sha256.convert(actual[entry.key]!.readAsBytesSync()).toString(),
        entry.value,
        reason: entry.key,
      );
    }
  });

  test(
    'all locked audio is visible through the Flutter asset bundle',
    () async {
      for (final entry in lockedAudioHashes().entries) {
        final data = await rootBundle.load(entry.key);
        expect(
          sha256.convert(bytesFromBundle(data)).toString(),
          entry.value,
          reason: entry.key,
        );
      }
    },
  );

  test('QQL 234 image replacement scope remains explicit', () {
    const auditedClean = {
      'apple.webp',
      'backpack.webp',
      'book.webp',
      'boy.webp',
      'bread.webp',
      'car.webp',
      'cat.webp',
      'chair.webp',
      'coffee.webp',
      'eye.webp',
      'grandfather.webp',
      'hat.webp',
      'hospital.webp',
      'house.webp',
      'train.webp',
      'tree.webp',
      'wallet.webp',
      'water.webp',
      'woman.webp',
    };
    const paddingOnly = {
      'boy.webp',
      'eye.webp',
      'grandfather.webp',
      'hat.webp',
      'hospital.webp',
    };
    final manifest =
        jsonDecode(
              File('assets/exercise_images/manifest.json').readAsStringSync(),
            )
            as List<dynamic>;
    final filenames = manifest
        .map(
          (entry) => File(
            (entry as Map<String, dynamic>)['assetPath'] as String,
          ).uri.pathSegments.last,
        )
        .toSet();

    // The 92 non-clean audit entries are semantic replacements. Five of the
    // 19 retained originally clean images receive padding-only normalization.
    expect(filenames, hasLength(111));
    expect(auditedClean, hasLength(19));
    expect(filenames.difference(auditedClean), hasLength(92));
    expect(paddingOnly, hasLength(5));
    expect(auditedClean.containsAll(paddingOnly), isTrue);
    expect(filenames.containsAll(paddingOnly), isTrue);
  });

  test('every exercise image has a fully transparent outer border', () async {
    final manifest =
        jsonDecode(
              File('assets/exercise_images/manifest.json').readAsStringSync(),
            )
            as List<dynamic>;

    for (final rawEntry in manifest) {
      final entry = Map<String, dynamic>.from(rawEntry as Map);
      final assetPath = entry['assetPath'] as String;
      final buffer = await ui.ImmutableBuffer.fromUint8List(
        File(assetPath).readAsBytesSync(),
      );
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final codec = await descriptor.instantiateCodec();
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final byteData = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );

      expect(image.width, 256, reason: assetPath);
      expect(image.height, 256, reason: assetPath);
      expect(byteData, isNotNull, reason: assetPath);
      final rgba = bytesFromBundle(byteData!);
      final nonTransparentBorderPixels = <(int, int)>[];
      for (var x = 0; x < image.width; x++) {
        if (rgba[(x * 4) + 3] != 0) {
          nonTransparentBorderPixels.add((x, 0));
        }
        final bottomOffset = (((image.height - 1) * image.width + x) * 4) + 3;
        if (rgba[bottomOffset] != 0) {
          nonTransparentBorderPixels.add((x, image.height - 1));
        }
      }
      for (var y = 1; y < image.height - 1; y++) {
        final leftOffset = (y * image.width * 4) + 3;
        if (rgba[leftOffset] != 0) {
          nonTransparentBorderPixels.add((0, y));
        }
        final rightOffset = ((y * image.width + image.width - 1) * 4) + 3;
        if (rgba[rightOffset] != 0) {
          nonTransparentBorderPixels.add((image.width - 1, y));
        }
      }
      expect(nonTransparentBorderPixels, isEmpty, reason: assetPath);

      image.dispose();
      codec.dispose();
      descriptor.dispose();
      buffer.dispose();
    }
  });

  test(
    'canonical startup logo is bundle-visible and the olive is gone',
    () async {
      const logoPath = 'assets/branding/quisquislingo_logo.png';
      final data = await rootBundle.load(logoPath);
      final buffer = await ui.ImmutableBuffer.fromUint8List(
        bytesFromBundle(data),
      );
      final descriptor = await ui.ImageDescriptor.encoded(buffer);

      expect(descriptor.width, greaterThan(0));
      expect(descriptor.height, greaterThan(0));
      expect(File('assets/olive_tree.png').existsSync(), isFalse);

      descriptor.dispose();
      buffer.dispose();
    },
  );
}
