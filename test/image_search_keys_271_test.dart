import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/exercise_image_metadata.dart';
import 'package:quisquislingo_app/models/image_categories.dart';
import 'package:quisquislingo_app/services/image_library_rules.dart';

import 'support/bundled_image_catalog.dart';

ExerciseImageMetadata _fromRecord(Map<String, dynamic> record) =>
    ExerciseImageMetadata(
      id: record['id'] as String,
      label: record['label'] as String,
      category: record['category'] as String,
      tags: [for (final tag in record['tags'] as List) tag as String],
      assetPath: record['assetPath'] as String,
      origin: 'bundled',
    );

// The rules as they were written before Build 271 Revision 3, word for
// word: every text of every picture worked out again for each question.

String? _categoryNameKeyBefore(String category) {
  if (category == 'other' ||
      category == characterCategoryGroup ||
      isCharacterCategory(category)) {
    return null;
  }
  return imageTagKey(category);
}

bool _carriedBefore(ExerciseImageMetadata asset, String tag) {
  final wanted = imageTagKey(tag);
  if (wanted.isEmpty) return false;
  final namesakeCategory = _categoryNameKeyBefore(asset.category);
  if (namesakeCategory != null && namesakeCategory == wanted) return true;
  return <String>[
    asset.label,
    ...asset.tags,
    ...asset.localWords,
  ].any((value) => imageTagKey(value) == wanted);
}

bool _belongedBefore(ExerciseImageMetadata asset, String category) {
  if (asset.category == category) return true;
  final name = _categoryNameKeyBefore(category);
  if (name == null) return false;
  return <String>[
    ...asset.tags,
    ...asset.localWords,
  ].any((value) => imageTagKey(value) == name);
}

bool _namedGroupBefore(String group, String normalizedQuery) {
  String spelled(String text) => text.replaceAll('&', 'and');
  final name = normalizeImageSearchText(imageCategoryLabel(group));
  return spelled(normalizedQuery) == spelled(name);
}

bool _matchedBefore(ExerciseImageMetadata asset, String normalizedQuery) {
  if (normalizedQuery.isEmpty) return true;
  final group = imageCategoryGroupOf(asset.category);
  if (group != null && _namedGroupBefore(group, normalizedQuery)) return true;
  final wanted = imageTagKey(normalizedQuery);
  return <String>[
    asset.label,
    ...asset.tags,
    ...asset.localWords,
    asset.id,
    asset.category,
  ].any((value) {
    final text = normalizeImageSearchText(value);
    return text.contains(normalizedQuery) || imageTagKey(text).contains(wanted);
  });
}

// Build 271 Revision 3 follow-up: what the image library compares of each
// picture is worked out once. The answers must be the ones the rules gave.
void main() {
  final assets = [
    for (final record in readBundledImageRecords()) _fromRecord(record),
    // Pictures with Local words, as an Admin adds them.
    for (final record in readBundledImageRecords().take(40))
      _fromRecord(record).copyWith(localWords: const ['Micio', 'restaurants']),
  ];

  test('the search finds what it found, for every QQL picture', () {
    expect(assets.length, bundledImageCount + 40);
    const typed = [
      'cat',
      'cats',
      'Dog',
      'dogs ',
      'food & drink',
      'Food and Drink',
      'food',
      'a',
      'é',
      'apple pie',
      'latin',
      'flags',
      'no-picture-has-this',
      'berries',
      'glasses',
      'news',
      'woman 2',
      'lesson icon',
      'micio',
      'restaurant',
      'char_block',
      '_',
      '   ',
      '',
    ];
    var found = 0;
    for (final text in typed) {
      final query = normalizeImageSearchText(text);
      for (final asset in assets) {
        final now = matchesImageSearch(asset, query);
        if (now) found++;
        if (now != _matchedBefore(asset, query)) {
          fail('"$text" and ${asset.id}: $now, before ${!now}');
        }
      }
    }
    expect(found, greaterThan(1000));
  });

  test('a tag opens what it opened, for every QQL picture', () {
    final tags = <String>{
      '',
      'cat',
      'Cats',
      'restaurant',
      'Restaurants',
      'people',
      'food',
      'friend',
      'micio',
      'no picture has this',
      // Real names and tags, one picture in fifty.
      for (var index = 0; index < bundledImageCount; index += 50) ...[
        assets[index].label,
        ...assets[index].tags.take(2),
      ],
    };
    var found = 0;
    for (final tag in tags) {
      for (final asset in assets) {
        final now = carriesImageTag(asset, tag);
        if (now) found++;
        if (now != _carriedBefore(asset, tag)) {
          fail('"$tag" and ${asset.id}: $now, before ${!now}');
        }
      }
    }
    expect(found, greaterThan(100));
  });

  test('a category shows what it showed, for every QQL picture', () {
    final categories = [
      ...imageCategories,
      ...imageCategoryGroups.keys,
      characterCategoryGroup,
      'no-such-category',
    ];
    var found = 0;
    for (final category in categories) {
      for (final asset in assets) {
        final now = belongsToImageCategory(asset, category);
        if (now) found++;
        if (now != _belongedBefore(asset, category)) {
          fail('$category and ${asset.id}: $now, before ${!now}');
        }
      }
    }
    expect(found, greaterThan(bundledImageCount - 1));
  });

  test('the keys of a picture are worked out once and belong to its '
      'record', () {
    final picture = assets.first;
    final keys = ImageSearchKeys.of(picture);
    expect(identical(ImageSearchKeys.of(picture), keys), isTrue);
    expect(keys.texts.first, normalizeImageSearchText(picture.label));
    expect(keys.singulars, [for (final text in keys.texts) imageTagKey(text)]);

    // A changed picture is a new record with keys of its own.
    final changed = picture.copyWith(localWords: const ['Zebras']);
    expect(matchesImageSearch(changed, 'zebra'), isTrue);
    expect(carriesImageTag(changed, 'zebra'), isTrue);
    expect(
      matchesImageSearch(picture, 'zebra'),
      _matchedBefore(picture, 'zebra'),
    );
    expect(identical(ImageSearchKeys.of(changed), keys), isFalse);
  });
}
