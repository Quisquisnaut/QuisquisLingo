import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/exercise_image_metadata_service.dart';
import 'package:quisquislingo_app/services/lesson_icon_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/bundled_image_catalog.dart';

// The rules of the QQL image catalog (owner decisions of 5 October 2026,
// Build 264 Revision 0). `tools/validate_images.py` checks the same rules and,
// with Python's Unicode names, that every character picture is the character
// its name gives; since Revision 4 it also refuses a picture whose outer edge
// is mostly near-white (lost on a white page; `tools/outline_light_edges.py`
// draws the grey edge).

/// What the RIFF header of a WebP file says, without decoding it.
({int width, int height, bool animated, int bitstreams}) _webpInfo(
  Uint8List bytes,
) {
  String fourCc(int offset) =>
      String.fromCharCodes(bytes.sublist(offset, offset + 4));
  if (bytes.length < 20 || fourCc(0) != 'RIFF' || fourCc(8) != 'WEBP') {
    throw const FormatException('not a RIFF WebP');
  }
  final data = ByteData.sublistView(bytes);
  if (data.getUint32(4, Endian.little) + 8 != bytes.length) {
    throw const FormatException('the RIFF size does not match the file');
  }
  int? width;
  int? height;
  var animated = false;
  var bitstreams = 0;
  var offset = 12;
  while (offset + 8 <= bytes.length) {
    final id = fourCc(offset);
    final size = data.getUint32(offset + 4, Endian.little);
    final start = offset + 8;
    if (start + size > bytes.length) {
      throw FormatException('truncated $id chunk');
    }
    switch (id) {
      case 'VP8X':
        animated = bytes[start] & 0x02 != 0;
        width =
            (bytes[start + 4] |
                bytes[start + 5] << 8 |
                bytes[start + 6] << 16) +
            1;
        height =
            (bytes[start + 7] |
                bytes[start + 8] << 8 |
                bytes[start + 9] << 16) +
            1;
      case 'VP8 ':
        bitstreams++;
        width ??= data.getUint16(start + 6, Endian.little) & 0x3fff;
        height ??= data.getUint16(start + 8, Endian.little) & 0x3fff;
      case 'VP8L':
        bitstreams++;
        final bits = data.getUint32(start + 1, Endian.little);
        width ??= (bits & 0x3fff) + 1;
        height ??= ((bits >> 14) & 0x3fff) + 1;
      case 'ANIM' || 'ANMF':
        animated = true;
    }
    offset = start + size + (size & 1);
  }
  if (offset != bytes.length || width == null || height == null) {
    throw const FormatException('malformed WebP chunks');
  }
  return (
    width: width,
    height: height,
    animated: animated,
    bitstreams: bitstreams,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final records = readBundledImageRecords();

  test('QQL ships the pinned number of images, each with its own file', () {
    expect(records, hasLength(bundledImageCount));
    final declared = {
      for (final r in records)
        if (!(r['assetPath'] as String).startsWith(worldFlagFolder) &&
            !(r['assetPath'] as String).startsWith(lessonIconFolder))
          r['assetPath'] as String,
    };
    final files = {
      for (final file in Directory(
        'assets/exercise_images',
      ).listSync().whereType<File>())
        if (file.path.toLowerCase().endsWith('.webp'))
          'assets/exercise_images/${file.uri.pathSegments.last}',
    };
    expect(declared.difference(files), isEmpty, reason: 'records without file');
    expect(files.difference(declared), isEmpty, reason: 'files without record');
  });

  test('IDs and file paths are unique', () {
    for (final field in ['id', 'assetPath']) {
      final values = records.map((r) => (r[field] as String).toLowerCase());
      expect(values.toSet(), hasLength(records.length), reason: field);
    }
  });

  test('every image is a QQL image in a QQL category', () {
    for (final record in records) {
      expect(
        ExerciseImageMetadataService.categories,
        contains(record['category']),
        reason: '${record['id']}',
      );
      expect(record['origin'], 'bundled', reason: '${record['id']}');
    }
  });

  test('names are filled in and unique within their category', () {
    final seen = <String, String>{};
    for (final record in records) {
      final label = record['label'] as String;
      expect(label.trim(), isNotEmpty, reason: '${record['id']}');
      expect(label, label.trim(), reason: '${record['id']}');
      // Exact text: A and a are two letters.
      final key = '${record['category']}|$label';
      expect(
        seen[key],
        isNull,
        reason: '${record['id']} has the name of ${seen[key]}',
      );
      seen[key] = record['id'] as String;
    }
  });

  test('every image has tags, none repeated and none equal to its name', () {
    for (final record in records) {
      final id = record['id'];
      final tags = (record['tags'] as List).cast<String>();
      expect(tags, isNotEmpty, reason: '$id');
      final keys = tags.map(imageWordKey).toList();
      expect(keys, isNot(contains('')), reason: '$id');
      expect(tags, tags.map((tag) => tag.trim()).toList(), reason: '$id');
      expect(keys.toSet(), hasLength(keys.length), reason: '$id: $tags');
      expect(
        keys,
        isNot(contains(imageWordKey(record['label'] as String))),
        reason: '$id repeats its name among $tags',
      );
    }
  });

  // Build 265 Revision 8 (owner, 7 October 2026), also checked by
  // tools/validate_images.py: enough tags to be found, never more than 32
  // or a tag over 80 characters. Character pictures have no minimum; Image
  // Banks an Admin imports keep their own rule (at least one tag).
  test('every picture outside the characters has 5 to 32 tags', () {
    for (final record in records) {
      final id = record['id'];
      final tags = (record['tags'] as List).cast<String>();
      if (!isCharacterImageCategory(record['category'] as String)) {
        expect(tags.length, greaterThanOrEqualTo(5), reason: '$id: $tags');
      }
      expect(tags.length, lessThanOrEqualTo(32), reason: '$id');
      for (final tag in tags) {
        expect(tag.length, lessThanOrEqualTo(80), reason: '$id: $tag');
      }
    }
  });

  test('a character named by its code point is that character', () {
    final codePoint = RegExp(r'_([0-9a-f]{4,5})$');
    var checked = 0;
    for (final record in records) {
      final match = codePoint.firstMatch(record['id'] as String);
      final label = record['label'] as String;
      if (match == null || label.runes.length != 1) continue;
      checked++;
      expect(
        label.runes.single,
        int.parse(match.group(1)!, radix: 16),
        reason: '${record['id']} is named "$label"',
      );
    }
    expect(checked, greaterThan(0));
  });

  test('the flags are the World Flags, one record each, with their credit', () {
    final manifest =
        jsonDecode(File('assets/world_flags/manifest.json').readAsStringSync())
            as Map<String, dynamic>;
    final entities = (manifest['entities'] as List)
        .cast<Map<String, dynamic>>();
    final flags = records.where((r) => r['category'] == 'flags').toList();
    expect(
      flags.map((r) => r['assetPath']).toList()..sort(),
      entities.map((e) => e['assetPath']).toList()..sort(),
    );
    final byPath = {for (final e in entities) e['assetPath']: e};
    for (final flag in flags) {
      final entity = byPath[flag['assetPath']]!;
      expect(flag['label'], entity['displayNameEn'], reason: '${flag['id']}');
      final credit = flag['attribution'] as Map<String, dynamic>;
      if (entity['artworkAuthor'] != null) {
        expect(credit['author'], entity['artworkAuthor']);
        expect(credit['license'], entity['artworkLicense']);
      } else {
        expect(credit['license'], 'MIT', reason: '${flag['id']}');
      }
    }
    // No other picture points into the World Flags.
    expect(
      records.where(
        (r) =>
            (r['assetPath'] as String).startsWith(worldFlagFolder) &&
            r['category'] != 'flags',
      ),
      isEmpty,
    );
  });

  test('the lesson icons are the Lesson icons, one record each', () {
    final icons = records.where((r) => r['category'] == 'lesson_icons');
    expect(
      icons.map((r) => r['assetPath']).toList()..sort(),
      LessonIconCatalog.options.map((o) => o.assetPath).toList()..sort(),
    );
    // No other picture points into the Lesson icons.
    expect(
      records.where(
        (r) =>
            (r['assetPath'] as String).startsWith(lessonIconFolder) &&
            r['category'] != 'lesson_icons',
      ),
      isEmpty,
    );
  });

  test('every image is a single-frame 256 × 256 WebP of at most 50 KB', () {
    for (final record in records) {
      final path = record['assetPath'] as String;
      // The flags are SVG drawings and the Lesson icons PNG files, each
      // checked by their own tests and validators.
      if (path.startsWith(worldFlagFolder)) continue;
      if (path.startsWith(lessonIconFolder)) continue;
      final bytes = File(path).readAsBytesSync();
      expect(bytes.length, lessThanOrEqualTo(50 * 1024), reason: path);
      final info = _webpInfo(bytes);
      expect(info.animated, isFalse, reason: path);
      // One picture, lossy or lossless.
      expect(info.bitstreams, 1, reason: path);
      expect((info.width, info.height), (256, 256), reason: path);
    }
  });

  testWidgets('the catalog opens inside a widget test, without an isolate', (
    tester,
  ) async {
    // AssetBundle.loadString hands a file of 50 KB or more to another
    // isolate, which never finishes under a widget test's clock: the whole
    // suite once stopped here. The service decodes the catalog itself.
    SharedPreferences.setMockInitialValues({});
    Object? outcome;
    ExerciseImageMetadataService().loadCatalog().then<void>(
      (catalog) => outcome = catalog,
      onError: (Object error) => outcome = error,
    );
    for (var pump = 0; pump < 10 && outcome == null; pump++) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(outcome, isA<List<Object>>());
    expect(outcome as List<Object>, hasLength(bundledImageCount));
  });
}
