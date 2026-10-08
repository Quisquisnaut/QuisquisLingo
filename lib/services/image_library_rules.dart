import '../models/exercise_image_metadata.dart';
import '../models/image_categories.dart';

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
  final wanted = imageTagKey(tag);
  if (wanted.isEmpty) return false;
  final namesakeCategory = _categoryNameKey(asset.category);
  if (namesakeCategory != null && namesakeCategory == wanted) return true;
  return <String>[
    asset.label,
    ...asset.tags,
    ...asset.localWords,
  ].any((value) => imageTagKey(value) == wanted);
}

/// Whether [asset] shows in [category]: its own category, or a tag or Local
/// word naming that category (Build 264 Revision 10: the pictures tagged
/// "restaurant" show in Restaurant too, so a picture can show in several
/// categories while it keeps one).
bool belongsToImageCategory(ExerciseImageMetadata asset, String category) {
  if (asset.category == category) return true;
  final name = _categoryNameKey(category);
  if (name == null) return false;
  return <String>[
    ...asset.tags,
    ...asset.localWords,
  ].any((value) => imageTagKey(value) == name);
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
bool matchesImageSearch(ExerciseImageMetadata asset, String normalizedQuery) {
  if (normalizedQuery.isEmpty) return true;
  final group = imageCategoryGroupOf(asset.category);
  if (group != null && _namesGroup(group, normalizedQuery)) return true;
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

/// Whether [normalizedQuery] is the whole name of [group], "&" or "and".
bool _namesGroup(String group, String normalizedQuery) {
  String spelled(String text) => text.replaceAll('&', 'and');
  final name = normalizeImageSearchText(imageCategoryLabel(group));
  return spelled(normalizedQuery) == spelled(name);
}

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
