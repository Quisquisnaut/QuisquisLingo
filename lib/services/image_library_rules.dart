import 'package:characters/characters.dart';

import '../models/exercise_image_metadata.dart';
import '../models/image_categories.dart';
import 'word_lookup/word_lookup_text.dart';

// The Image Library's rules, apart from how the screen draws them: search,
// sorting, the added date, and the badges and wording of each image. Plain
// functions, so they are tested directly.

String normalizeImageSearchText(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll('_', ' ')
    .replaceAll(RegExp(r'\s+'), ' ');

/// Tags as an Admin types them, one per comma.
List<String> splitImageTags(String text) => [
  for (final tag in text.split(','))
    if (tag.trim().isNotEmpty) tag.trim(),
];

/// Whether every tag only repeats the picture's name (capitals and spaces
/// ignored). The search reads the name already, so such a picture would
/// gain from a tag of its own; QQL's pictures never look like this, an
/// Admin's may, and is only told so (Build 264 Revision 2).
bool tagsOnlyRepeatName(String label, List<String> tags) {
  final name = normalizeImageSearchText(label);
  return tags.every((tag) => normalizeImageSearchText(tag) == name);
}

bool hasOnlyNameTags(ExerciseImageMetadata item) =>
    tagsOnlyRepeatName(item.label, item.tags);

/// Whether [asset] carries [tag] as a whole: one of its tags or Local words,
/// or its name (QQL names are never repeated as tags), capitals and spaces
/// ignored. A tap on a tag in a picture's card filters by this, not by the
/// search's "contains" (owner decision, Build 264 Revision 5: "cat" must
/// not find School or Catalonia).
///
/// Since Build 264 Revision 10 (owner decisions of 6 October 2026) a tag and
/// the category of the same name are one: the tag "restaurant" also finds the
/// pictures of the category Restaurant; and singular and plural count as one
/// ([imageTagKey]).
bool carriesImageTag(ExerciseImageMetadata asset, String tag) {
  final wanted = _keyOf(tag);
  if (wanted.isEmpty) return false;
  final keys = ImageSearchKeys.of(asset);
  if (keys.categoryName != null && keys.categoryName == wanted) return true;
  return keys.words.contains(wanted);
}

/// What the library compares of one picture, worked out once for each
/// picture record (Build 271 Revision 3). Before, every keystroke of a
/// search, and every rebuild of the library, wrote the name, the tags, the
/// Local words, the ID and the category of every picture in small letters
/// and in the singular again: tens of thousands of texts for QQL's own
/// pictures. A record never changes (a changed picture is a new record), so
/// its keys are kept with it.
class ImageSearchKeys {
  ImageSearchKeys._(ExerciseImageMetadata asset)
    : texts = List.unmodifiable([
        for (final value in [
          asset.label,
          ...asset.tags,
          ...asset.localWords,
          asset.id,
          asset.category,
        ])
          normalizeImageSearchText(value),
      ]),
      words = {
        for (final value in [asset.label, ...asset.tags, ...asset.localWords])
          imageTagKey(value),
      },
      tags = {
        for (final value in [...asset.tags, ...asset.localWords])
          imageTagKey(value),
      },
      categoryName = _categoryNameKey(asset.category),
      nameWords = imageSearchWords(asset.label),
      tagWords = List.unmodifiable([
        for (final value in [...asset.tags, ...asset.localWords])
          imageSearchWords(value),
      ]),
      categoryWords = List.unmodifiable([
        imageSearchWords(asset.category),
        imageSearchWords(imageSubcategoryLabel(asset.category)),
      ]) {
    singulars = List.unmodifiable([
      for (final text in texts) imageTagKey(text),
    ]);
  }

  static final _byAsset = Expando<ImageSearchKeys>();

  static ImageSearchKeys of(ExerciseImageMetadata asset) =>
      _byAsset[asset] ??= ImageSearchKeys._(asset);

  /// The name, the tags, the Local words, the ID and the category as
  /// [normalizeImageSearchText] writes them.
  final List<String> texts;

  /// [texts] with every word in its singular ([imageTagKey]).
  late final List<String> singulars;

  /// [imageTagKey] of the name, the tags and the Local words.
  final Set<String> words;

  /// [imageTagKey] of the tags and the Local words.
  final Set<String> tags;

  /// The key of the picture's own category's name, when the name is a word
  /// to tag with.
  final String? categoryName;

  /// The words of the name ([imageSearchWords]; Build 274 Revision 4).
  final List<String> nameWords;

  /// The words of each tag and each Local word.
  final List<List<String>> tagWords;

  /// The words of the category's ID and of its name on its chip ("latin"
  /// for the Latin characters).
  final List<List<String>> categoryWords;
}

/// [imageTagKey] of the word asked for last: a filter asks for the same word
/// once for each picture.
String _keyOf(String value) {
  if (value != _lastValue) {
    _lastValue = value;
    _lastKey = imageTagKey(value);
  }
  return _lastKey;
}

String? _lastValue;
String _lastKey = '';

/// The key of each category's name, worked out once.
final _categoryNameKeys = <String, String?>{};

/// Whether [asset] shows in [category]: its own category, or a tag or Local
/// word naming that category (Build 264 Revision 10: the pictures tagged
/// "restaurant" show in Restaurant too, so a picture can show in several
/// categories while it keeps one).
bool belongsToImageCategory(ExerciseImageMetadata asset, String category) {
  if (asset.category == category) return true;
  final name = _categoryNameKeys.putIfAbsent(
    category,
    () => _categoryNameKey(category),
  );
  if (name == null) return false;
  return ImageSearchKeys.of(asset).tags.contains(name);
}

/// The key of a category's name, or null for categories whose name is not
/// a word to tag with: the characters (scripts, not topics) and Other.
String? _categoryNameKey(String category) {
  if (category == 'other' ||
      category == characterCategoryGroup ||
      isCharacterCategory(category)) {
    return null;
  }
  return imageTagKey(category);
}

/// How the library compares words (Build 264 Revision 10): capitals and
/// spaces ignored as in [normalizeImageSearchText], and every word in its
/// singular, so "cats" and "cat", "boxes" and "box", "berries" and "berry"
/// are one. A plain English rule, not a dictionary: "glasses" is "glass".
String imageTagKey(String value) =>
    normalizeImageSearchText(value).split(' ').map(_singular).join(' ');

/// Plurals that are words of their own, kept as they are.
const _notPlurals = {'news', 'goods'};

String _singular(String word) {
  if (_notPlurals.contains(word)) return word;
  if (word.length > 4 && word.endsWith('ies')) {
    return '${word.substring(0, word.length - 3)}y';
  }
  for (final ending in const ['sses', 'shes', 'ches', 'xes', 'zes']) {
    if (word.endsWith(ending)) return word.substring(0, word.length - 2);
  }
  if (word.length > 3 &&
      word.endsWith('s') &&
      !word.endsWith('ss') &&
      !word.endsWith('us') &&
      !word.endsWith('is')) {
    return word.substring(0, word.length - 1);
  }
  return word;
}

/// The search: [normalizedQuery] anywhere in a name, tag, Local word, ID or
/// category; singular and plural count as one (Build 264 Revision 10), so
/// "dogs" finds the dogs. The whole name of a category group finds the
/// group's pictures (Build 265 Revision 9): "food & drink" or "food and
/// drink", while "food" alone keeps finding what it found before.
///
/// [strict] (Build 274 Revision 4, Strict search): only whole words
/// ([ImageSearchMatch.isWhole]), so "man" does not find Woman.
bool matchesImageSearch(
  ExerciseImageMetadata asset,
  String normalizedQuery, {
  bool strict = false,
}) {
  if (!strict) return _containsImageSearch(asset, normalizedQuery);
  return imageSearchMatch(asset, normalizedQuery)?.isWhole ?? false;
}

/// How a picture matches a search, best first (Build 274 Revision 4, the
/// owner's point 8 of 13 October 2026). The library shows the parts in this
/// order and the chosen sort orders the pictures inside each part.
enum ImageSearchMatch {
  /// The name is the term: "Man" for "man", "Cat" for "cats".
  name,

  /// The term is a whole word, or whole words in a row, of the name:
  /// "Man 2", "Tennis player (man)".
  nameWord,

  /// The term is a whole word of a tag or a Local word, or names the
  /// picture's whole category or category group.
  tagWord,

  /// The term is only inside a longer word, a single word of the
  /// category, or only in the ID: Woman and Businesswoman for "man", the
  /// food_drinks pictures for "food".
  inside;

  /// Whether the term is a whole word where it is found: what Strict
  /// search keeps.
  bool get isWhole => this != inside;
}

/// How [asset] matches [normalizedQuery], or null when the search does not
/// find it. It finds exactly what [matchesImageSearch] finds, and only says
/// where: the order never adds or hides a picture. An empty search is
/// [ImageSearchMatch.name] for every picture, so the sort alone orders them.
ImageSearchMatch? imageSearchMatch(
  ExerciseImageMetadata asset,
  String normalizedQuery,
) {
  if (normalizedQuery.isEmpty) return ImageSearchMatch.name;
  if (!_containsImageSearch(asset, normalizedQuery)) return null;
  final keys = ImageSearchKeys.of(asset);
  // Whole texts first, so a symbol (no word in it: "€", "+", "?") is the
  // name or a tag it is.
  final whole = _keyOf(normalizedQuery);
  if (keys.singulars.first == whole) return ImageSearchMatch.name;
  final wanted = _queryWordsOf(normalizedQuery);
  if (wanted.isNotEmpty) {
    if (_sameWords(keys.nameWords, wanted)) return ImageSearchMatch.name;
    if (_holdsWords(keys.nameWords, wanted)) return ImageSearchMatch.nameWord;
  }
  if (keys.tags.contains(whole)) return ImageSearchMatch.tagWord;
  if (wanted.isNotEmpty) {
    for (final words in keys.tagWords) {
      if (_holdsWords(words, wanted)) return ImageSearchMatch.tagWord;
    }
    // The whole category, as its ID or its chip names it.
    for (final words in keys.categoryWords) {
      if (_sameWords(words, wanted)) return ImageSearchMatch.tagWord;
    }
  }
  final group = imageCategoryGroupOf(asset.category);
  if (group != null && _namesGroup(group, normalizedQuery)) {
    return ImageSearchMatch.tagWord;
  }
  return ImageSearchMatch.inside;
}

/// The words of [text] as the search compares them: small letters, split
/// at anything that is not a letter, a mark or a digit (so "(man)" and
/// "ice-cream" are words too), each in its singular ([imageTagKey]); in a
/// script written without spaces each character is a word, as Word Lookup
/// reads them ([WordLookupText.isSpacelessCharacter]).
List<String> imageSearchWords(String text) {
  final words = <String>[];
  for (final piece in normalizeImageSearchText(
    text,
  ).split(_notWordCharacters)) {
    if (piece.isEmpty) continue;
    final run = StringBuffer();
    void close() {
      if (run.isEmpty) return;
      words.add(_singular(run.toString()));
      run.clear();
    }

    for (final cluster in piece.characters) {
      if (WordLookupText.isSpacelessCharacter(cluster)) {
        close();
        words.add(cluster);
      } else {
        run.write(cluster);
      }
    }
    close();
  }
  return List.unmodifiable(words);
}

final _notWordCharacters = RegExp(r'[^\p{L}\p{M}\p{N}]+', unicode: true);

/// [imageSearchWords] of the search asked for last.
List<String> _queryWordsOf(String normalizedQuery) {
  if (normalizedQuery != _lastQuery) {
    _lastQuery = normalizedQuery;
    _lastQueryWords = imageSearchWords(normalizedQuery);
  }
  return _lastQueryWords;
}

String? _lastQuery;
List<String> _lastQueryWords = const [];

bool _sameWords(List<String> words, List<String> wanted) {
  if (words.length != wanted.length) return false;
  for (var i = 0; i < words.length; i++) {
    if (words[i] != wanted[i]) return false;
  }
  return true;
}

/// Whether [wanted] is in [words], whole words in a row.
bool _holdsWords(List<String> words, List<String> wanted) {
  for (var start = 0; start + wanted.length <= words.length; start++) {
    var all = true;
    for (var i = 0; i < wanted.length; i++) {
      if (words[start + i] != wanted[i]) {
        all = false;
        break;
      }
    }
    if (all) return true;
  }
  return false;
}

bool _containsImageSearch(ExerciseImageMetadata asset, String normalizedQuery) {
  if (normalizedQuery.isEmpty) return true;
  final group = imageCategoryGroupOf(asset.category);
  if (group != null && _namesGroup(group, normalizedQuery)) return true;
  final wanted = _keyOf(normalizedQuery);
  final keys = ImageSearchKeys.of(asset);
  for (var index = 0; index < keys.texts.length; index++) {
    if (keys.texts[index].contains(normalizedQuery) ||
        keys.singulars[index].contains(wanted)) {
      return true;
    }
  }
  return false;
}

/// Whether [normalizedQuery] is the whole name of [group], "&" or "and".
bool _namesGroup(String group, String normalizedQuery) {
  final name = _groupNames.putIfAbsent(
    group,
    () => _spelled(normalizeImageSearchText(imageCategoryLabel(group))),
  );
  return _spelled(normalizedQuery) == name;
}

String _spelled(String text) => text.replaceAll('&', 'and');

/// Each group's name as a search writes it, worked out once.
final _groupNames = <String, String>{};

enum ImageSort {
  name('Name (A–Z)'),
  newest('Newest added'),
  oldest('Oldest added'),
  largest('Largest file'),
  smallest('Smallest file');

  const ImageSort(this.label);
  final String label;
}

// Since Build 243 Revision 16 an imported image records when it was imported
// (provenance). Older ones get a date from values QQL itself generated: the
// microsecond stamp in a single import's ID, the stamp in its Image Bank ID, or
// when the file was written into the Course folder. Bundled images have no
// date and count as the oldest.
final _localIdStamp = RegExp(r'^local_(\d+)$');
final _bankOriginStamp = RegExp(r'^bank:bank_(\d+)$');

DateTime? stampedAddedDate(ExerciseImageMetadata item) {
  final recorded = item.provenance?.importedAtUtc;
  if (recorded != null) return recorded;
  final match =
      _localIdStamp.firstMatch(item.id) ??
      _bankOriginStamp.firstMatch(item.origin);
  final micros = match == null ? null : int.tryParse(match.group(1)!);
  return micros == null
      ? null
      : DateTime.fromMicrosecondsSinceEpoch(micros, isUtc: true);
}

String? imageBankIdOf(ExerciseImageMetadata item) {
  if (!item.origin.startsWith('bank:')) return null;
  final id = item.origin.substring('bank:'.length).trim();
  return id.isEmpty ? null : id;
}

bool isBundledImage(ExerciseImageMetadata item) =>
    item.origin == 'bundled' || item.assetPath.startsWith('assets/');

/// Badge labels in display order; the badge filter offers the same labels.
const imageBadgeOrder = ['IN USE', 'QQL', 'DEVICE', 'COURSE'];

const imageBadgeMeanings = {
  'QQL': 'App bundled; supplied by QQL on every device.',
  'DEVICE': 'Admin-added on this device; copied into the Course ZIP when used.',
  'COURSE': 'These bytes are stored in this Course.',
  'IN USE': 'This image is used by this Course.',
};

/// [inCourse]: a device image whose Course copy is listed as this same tile.
List<String> imageBadgesOf(
  ExerciseImageMetadata item, {
  bool used = false,
  bool inCourse = false,
}) => [
  if (used) 'IN USE',
  ...switch (item.origin) {
    // Listed on its own only when the device original is gone.
    'course' || 'course-device' => const ['COURSE'],
    _ => [isBundledImage(item) ? 'QQL' : 'DEVICE', if (inCourse) 'COURSE'],
  },
];

/// The tile's tag line: `Tags: …` and `Local: …` on one line, each only
/// when present, in lowercase; null when the image has neither.
String? imageTileTags(ExerciseImageMetadata item) {
  final parts = [
    if (item.tags.isNotEmpty) 'Tags: ${item.tags.join(', ').toLowerCase()}',
    if (item.localWords.isNotEmpty)
      'Local: ${item.localWords.join(', ').toLowerCase()}',
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

String imageSourceCode(List<String> badges) => badges.join(' · ');

String imageSourceExplanation(
  ExerciseImageMetadata item,
) => switch (item.origin) {
  'course-device' =>
    'Originally Admin-added; these bytes are stored in this Course.',
  'course' => 'These bytes are stored in this Course.',
  _ =>
    isBundledImage(item)
        ? 'App bundled; supplied by QQL on every device.'
        : 'Admin-added on this device; copied into the Course ZIP when used.',
};

/// Orders two images for [sort]; ties fall back to the name. [addedAt] and
/// [fileBytes] are keyed by image ID; missing values sort as described below.
int compareImages(
  ExerciseImageMetadata left,
  ExerciseImageMetadata right, {
  required ImageSort sort,
  required Map<String, DateTime> addedAt,
  required Map<String, int> fileBytes,
}) {
  int byName() => left.label.toLowerCase().compareTo(right.label.toLowerCase());
  final oldest = DateTime.fromMicrosecondsSinceEpoch(0, isUtc: true);
  int byDate() =>
      (addedAt[left.id] ?? oldest).compareTo(addedAt[right.id] ?? oldest);
  // An unmeasured file (missing, or sizes still loading) sorts last.
  int bySize(bool largestFirst) {
    final a = fileBytes[left.id];
    final b = fileBytes[right.id];
    if (a == null || b == null) return a == null ? (b == null ? 0 : 1) : -1;
    return largestFirst ? b.compareTo(a) : a.compareTo(b);
  }

  final primary = switch (sort) {
    ImageSort.name => 0,
    ImageSort.newest => -byDate(),
    ImageSort.oldest => byDate(),
    ImageSort.largest => bySize(true),
    ImageSort.smallest => bySize(false),
  };
  return primary != 0 ? primary : byName();
}

/// Shows a Course copy of a Shared Image Library image once: when the device
/// original is still on this device, the copy is removed from [owned] and the
/// original carries a COURSE badge. A record whose file [isMissing] does not
/// hide a working Course copy.
///
/// [ownedSources] maps each Course image's ID to the Shared Image Library ID
/// it was copied from, or null. Returns the IDs of device images that absorbed
/// their Course copy.
Set<String> mergeCourseCopies({
  required List<ExerciseImageMetadata> records,
  required List<ExerciseImageMetadata> owned,
  required Map<String, String?> ownedSources,
  required bool Function(ExerciseImageMetadata) isMissing,
}) {
  final deviceIds = {
    for (final record in records)
      if (!isBundledImage(record) && !isMissing(record)) record.id,
  };
  final copied = <String>{};
  owned.removeWhere((item) {
    final sourceId = ownedSources[item.id];
    if (sourceId == null || !deviceIds.contains(sourceId)) return false;
    copied.add(sourceId);
    return true;
  });
  return copied;
}
