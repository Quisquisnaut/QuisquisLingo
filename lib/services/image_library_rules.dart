import '../models/exercise_image_metadata.dart';

// The Image Library's rules, apart from how the screen draws them: search,
// sorting, the added date, and the badges and wording of each image. Plain
// functions, so they are tested directly.

String normalizeImageSearchText(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll('_', ' ')
    .replaceAll(RegExp(r'\s+'), ' ');

bool matchesImageSearch(ExerciseImageMetadata asset, String normalizedQuery) {
  if (normalizedQuery.isEmpty) return true;
  return <String>[
    asset.label,
    ...asset.tags,
    ...asset.localWords,
    asset.id,
    asset.category,
  ].any((value) => normalizeImageSearchText(value).contains(normalizedQuery));
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
