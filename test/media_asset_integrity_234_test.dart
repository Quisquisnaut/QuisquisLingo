import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/exercise_image_metadata_service.dart';

import 'support/bundled_image_catalog.dart';

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

  List<String> bundledImagePaths() {
    final catalog =
        jsonDecode(
              File(
                ExerciseImageMetadataService.bundledCatalogAsset,
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    expect(catalog['schemaVersion'], 1);
    final records = (catalog['records'] as List).cast<Map<String, dynamic>>();
    expect(records, hasLength(bundledImageCount));
    return records.map((entry) => entry['assetPath'] as String).toList();
  }

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

  test('QQL 234 audited-clean images remain in the expanded bank', () {
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
    final filenames = bundledImagePaths()
        .map((assetPath) => File(assetPath).uri.pathSegments.last)
        .toSet();

    // Five of the 19 retained originally clean images received padding-only
    // normalization. Later image-bank additions do not change that history.
    expect(auditedClean, hasLength(19));
    expect(paddingOnly, hasLength(5));
    expect(auditedClean.containsAll(paddingOnly), isTrue);
    expect(filenames.containsAll(auditedClean), isTrue);
  });

  test(
    'every exercise image is 256 square; illustrations use transparency',
    () async {
      // Character pictures may be opaque (owner decision of 5 October 2026).
      final characters = {
        for (final record in readBundledImageRecords())
          if (isCharacterImageCategory(record['category'] as String))
            record['assetPath'] as String,
      };
      for (final assetPath in bundledImagePaths()) {
        // The flags are the World Flags' SVG drawings (Build 264).
        if (assetPath.startsWith(worldFlagFolder)) continue;
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
        var usesTransparency = false;
        for (var alphaOffset = 3; alphaOffset < rgba.length; alphaOffset += 4) {
          if (rgba[alphaOffset] < 255) {
            usesTransparency = true;
            break;
          }
        }
        if (!characters.contains(assetPath)) {
          expect(usesTransparency, isTrue, reason: assetPath);
        }

        image.dispose();
        codec.dispose();
        descriptor.dispose();
        buffer.dispose();
      }
    },
  );

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
