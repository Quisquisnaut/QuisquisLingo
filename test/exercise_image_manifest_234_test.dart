import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/exercise_image_metadata_service.dart';

import 'support/bundled_image_catalog.dart';

void main() {
  List<Map<String, dynamic>> readRecords() {
    final document =
        jsonDecode(
              File(
                ExerciseImageMetadataService.bundledCatalogAsset,
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    expect(document['schemaVersion'], 1);
    return (document['records'] as List)
        .map((entry) => Map<String, dynamic>.from(entry as Map))
        .toList();
  }

  test('canonical exercise-image taxonomy is complete and collision-free', () {
    final entries = readRecords();

    expect(entries, hasLength(bundledImageCount));
    expect(
      entries.map((entry) => (entry['id'] as String).toLowerCase()).toSet(),
      hasLength(entries.length),
    );
    expect(
      entries
          .map((entry) => (entry['assetPath'] as String).toLowerCase())
          .toSet(),
      hasLength(entries.length),
    );
    expect(entries.any((entry) => entry['id'] == 'bicycle'), isFalse);

    for (final entry in entries) {
      final tags = (entry['tags'] as List<dynamic>).cast<String>();
      expect(tags, isNotEmpty, reason: '${entry['id']}');
      expect(tags, tags.map((tag) => tag.trim()).toList());
      expect(tags.toSet(), hasLength(tags.length), reason: '${entry['id']}');
      expect(
        File(entry['assetPath'] as String).existsSync(),
        isTrue,
        reason: '${entry['id']}',
      );
      expect(entry['origin'], 'bundled');
    }

    final man = entries.singleWhere(
      (entry) => entry['id'] == 'people_family_man',
    );
    expect(man['label'], 'Man');
    expect(man['assetPath'], 'assets/exercise_images/man.webp');
    // Build 265 Revision 5: no "friend" (it made a single man the answer to
    // "friends"); the picture Friends carries it. Revision 7 appends two.
    expect(man['tags'], [
      'adult man',
      'male',
      'adult',
      'grown man',
      'gentleman',
    ]);

    final jump = entries.singleWhere((entry) => entry['id'] == 'actions_jump');
    // Build 265 Revision 6: named Jump, no longer "Saltare".
    expect(jump['label'], 'Jump');
    expect(jump['assetPath'], 'assets/exercise_images/jump.webp');
    // Build 265 Revision 5 appends tags and keeps the earlier ones first;
    // Revision 6 drops "jump", now the name.
    expect(jump['tags'], ['jumping', 'leap', 'hop', 'jump for joy', 'jump up']);
  });

  test('runtime image metadata code does not read obsolete sources', () {
    final runtimeSources = [
      File(
        'lib/services/exercise_image_metadata_service.dart',
      ).readAsStringSync(),
      File('lib/screens/flat_image_library_screen.dart').readAsStringSync(),
    ].join('\n');

    expect(runtimeSources, isNot(contains('manifest.json')));
    expect(runtimeSources, isNot(contains('image_bank_manifest.json')));
    expect(runtimeSources, isNot(contains('manifest_external.json')));
    expect(runtimeSources, isNot(contains('custom_image_bank_v1')));
    expect(runtimeSources, isNot(contains('imported_image_banks_v1')));
    expect(runtimeSources, contains('metadata_v2.json'));
  });
}
