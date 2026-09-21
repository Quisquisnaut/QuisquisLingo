import '../models/exercise_image_metadata.dart';
import 'course_media_store.dart';
import 'image_library_rules.dart';

/// English details for the full-size image preview only. All facts come from
/// existing records or a read of the stored image; this never validates or
/// changes an already stored image.
String imagePreviewTooltip({
  required ExerciseImageMetadata item,
  int? byteLength,
  int? width,
  int? height,
  String? format,
  DateTime? addedAt,
  String? bankName,
  bool missing = false,
  bool alsoStoredInCourse = false,
}) {
  if (missing) return 'File missing';

  final name = CourseMediaStore.isImageReference(item.assetPath)
      ? 'Course file (named by content)'
      : isBundledImage(item)
      ? _baseName(item.assetPath)
      : item.provenance?.sourceName ?? _baseName(item.assetPath);
  final date = addedAt ?? stampedAddedDate(item);
  final bankId = imageBankIdOf(item);
  final credit = item.attribution;
  return [
    'File: $name',
    'Size: ${_size(byteLength)}',
    'Dimensions: ${width == null || height == null ? 'Unknown' : '$width × $height pixels'}',
    'Format: ${format ?? item.provenance?.detectedFormat?.toUpperCase() ?? 'Unknown'}',
    if (isBundledImage(item))
      'Included with QQL'
    else
      'Added: ${date == null ? 'Unknown' : _date(date)}',
    if (bankId != null) 'Bank: ${bankName ?? bankId}',
    if (credit != null) ...[
      'Author: ${credit.author}',
      'License: ${credit.license}',
      if (credit.title.isNotEmpty) 'Work: ${credit.title}',
      if (credit.source.isNotEmpty) 'Source: ${credit.source}',
    ],
    if (alsoStoredInCourse) 'Also stored in this Course',
  ].join('\n');
}

String _baseName(String path) => path.replaceAll('\\', '/').split('/').last;

String _size(int? bytes) {
  if (bytes == null) return 'Unknown';
  if (bytes < 1024) return 'about $bytes bytes';
  if (bytes < 1024 * 1024) {
    return 'about ${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return 'about ${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _date(DateTime value) {
  final local = value.toLocal();
  return '${local.year.toString().padLeft(4, '0')}-'
      '${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}
