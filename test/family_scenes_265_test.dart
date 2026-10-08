import 'package:flutter_test/flutter_test.dart';

import 'support/bundled_image_catalog.dart';

// Build 265 Revision 11 (owner decisions of 7 October 2026): family members
// as small scenes, the person named ringed in yellow beside the relative
// that defines them, as Grandfather and Grandmother have a portrait beside
// their family-tree picture; Man and Woman in other colours; Friends
// (women).

const _relatives = [
  'father',
  'mother',
  'son',
  'daughter',
  'child',
  'brother',
  'sister',
  'uncle',
  'aunt',
];

void main() {
  final records = readBundledImageRecords();
  final byId = {for (final r in records) r['id'] as String: r};
  String capitalized(String word) =>
      '${word[0].toUpperCase()}${word.substring(1)}';

  test('each relative has a scene and keeps its family-tree picture', () {
    for (final who in _relatives) {
      final scene = byId['people_family_$who'];
      expect(scene, isNotNull, reason: who);
      expect(scene!['label'], capitalized(who));
      expect(scene['assetPath'], 'assets/exercise_images/family_$who.webp');
      expect((scene['tags'] as List).length, greaterThanOrEqualTo(5));
      final tree = byId['family_relatives_rel_$who']!;
      expect(tree['label'], '${capitalized(who)} (family tree)');
      expect(tree['assetPath'], 'assets/exercise_images/rel_$who.webp');
      expect(
        (tree['tags'] as List).cast<String>().map(imageWordKey),
        contains('family tree'),
      );
    }
  });

  test('Man and Woman have numbered colour variants', () {
    for (final (id, label, tag) in [
      ('people_family_man_2', 'Man 2', 'adult man'),
      ('people_family_man_3', 'Man 3', 'adult man'),
      ('people_family_woman_2', 'Woman 2', 'adult woman'),
      ('people_family_woman_3', 'Woman 3', 'adult woman'),
    ]) {
      final record = byId[id];
      expect(record, isNotNull, reason: id);
      expect(record!['label'], label);
      expect(
        (record['tags'] as List).cast<String>().map(imageWordKey),
        contains(tag),
      );
    }
  });

  test('Friends (women) stands beside the mixed Friends', () {
    final women = byId['relationships_friends_women']!;
    expect(women['label'], 'Friends (women)');
    expect(
      (women['tags'] as List).cast<String>().map(imageWordKey),
      contains('female friends'),
    );
    expect(byId['relationships_friends']!['label'], 'Friends');
  });
}
