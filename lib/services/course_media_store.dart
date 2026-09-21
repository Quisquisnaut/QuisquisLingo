import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import '../models/course_models.dart';
import 'course_image_usage.dart';

/// The one home of a Course's own images and recordings.
///
/// A Course names such a file by content, never by path: `media:<sha256>.<ext>`
/// with the lowercase SHA-256 of the bytes. Every device keeps the file in
/// `<AppSupport>/quisquislingo_course_media/<course folder>/<sha256>.<ext>`, so
/// the Course JSON is identical everywhere and a signature over it also pins
/// the media bytes. Each Course has its own folder: Fork, Copy as New Course
/// and Merge copy the files they need, and deleting a Course deletes its
/// folder. Bundled `assets/` media and embedded `data:` images are not stored
/// here.
class CourseMediaStore {
  CourseMediaStore({Future<Directory> Function()? supportDirectory})
    : _supportDirectory = supportDirectory ?? getApplicationSupportDirectory;

  final Future<Directory> Function() _supportDirectory;

  static const rootDirectoryName = 'quisquislingo_course_media';
  static const audioExtensions = {'mp3'};
  static const imageExtensions = {'png', 'jpg', 'jpeg', 'webp'};
  static const maxAudioBytes = 50 * 1024 * 1024;
  static const maxImageBytes = 50 * 1024;

  static final RegExp referencePattern = RegExp(
    r'^media:([0-9a-f]{64})\.(mp3|png|jpg|jpeg|webp)$',
  );
  static final RegExp _fileNamePattern = RegExp(
    r'^[0-9a-f]{64}\.(mp3|png|jpg|jpeg|webp)$',
  );

  static bool isReference(String value) => referencePattern.hasMatch(value);

  static bool isAudioReference(String value) =>
      isReference(value) && audioExtensions.contains(extensionOf(value));

  static bool isImageReference(String value) =>
      isReference(value) && imageExtensions.contains(extensionOf(value));

  static String extensionOf(String reference) =>
      reference.substring(reference.lastIndexOf('.') + 1);

  static String digestOf(String reference) =>
      referencePattern.firstMatch(reference)!.group(1)!;

  /// The stored file name of [reference]: `<sha256>.<ext>`.
  static String fileNameOf(String reference) =>
      reference.substring('media:'.length);

  static String referenceFor(List<int> bytes, String extension) {
    final ext = extension.toLowerCase();
    if (!audioExtensions.contains(ext) && !imageExtensions.contains(ext)) {
      throw FormatException('Unsupported course media type: .$extension');
    }
    return 'media:${sha256.convert(bytes)}.$ext';
  }

  /// The folder name used for a Course, stable across devices.
  static String folderNameFor(String courseId) {
    final value = courseId.trim();
    if (value.isEmpty) {
      throw ArgumentError.value(courseId, 'courseId', 'Course ID is required');
    }
    return 'course_${sha256.convert(utf8.encode(value))}';
  }

  /// Every `media:` reference [course] keeps: Audio Library clips, the images
  /// [CourseImageUsage] finds in its Lessons and cover, and the unused images
  /// in its own image library.
  static Set<String> referencesOf(Course course) => {
    for (final clip in course.audioLibrary)
      if (isReference(clip.filePath)) clip.filePath,
    for (final use in CourseImageUsage.uses(course))
      if (isReference(use.asset)) use.asset,
    for (final entry in course.imageLibrary) entry.asset,
  };

  Future<Directory> rootDirectory() async => Directory(
    '${(await _supportDirectory()).path}${Platform.pathSeparator}'
    '$rootDirectoryName',
  );

  Future<Directory> courseDirectory(
    String courseId, {
    bool create = false,
  }) async {
    final directory = Directory(
      '${(await rootDirectory()).path}${Platform.pathSeparator}'
      '${folderNameFor(courseId)}',
    );
    if (create) await directory.create(recursive: true);
    return directory;
  }

  /// Where [reference] lives for [courseId], whether or not it exists.
  Future<File> fileFor(String courseId, String reference) async {
    if (!isReference(reference)) {
      throw FormatException('Not a course media reference: $reference');
    }
    return File(
      '${(await courseDirectory(courseId)).path}${Platform.pathSeparator}'
      '${fileNameOf(reference)}',
    );
  }

  /// The stored file, or null when [reference] is not a `media:` reference or
  /// its file is missing.
  Future<File?> existingFile(String courseId, String reference) async {
    if (!isReference(reference)) return null;
    final file = await fileFor(courseId, reference);
    return await file.exists() ? file : null;
  }

  /// Stores [bytes] for [courseId] and returns their reference. Storing the
  /// same bytes twice keeps one file. The written file is read back and its
  /// digest checked before the reference is returned.
  Future<String> addBytes(
    String courseId,
    Uint8List bytes,
    String extension,
  ) async {
    final reference = referenceFor(bytes, extension);
    final limit = isAudioReference(reference) ? maxAudioBytes : maxImageBytes;
    if (bytes.isEmpty || bytes.length > limit) {
      throw FormatException(
        isAudioReference(reference)
            ? 'MP3 files larger than 50 MB are not accepted.'
            : 'Exercise images must be 1 byte to 50 KB.',
      );
    }
    await courseDirectory(courseId, create: true);
    final target = await fileFor(courseId, reference);
    if (await target.exists() && await _matches(target, reference)) {
      return reference;
    }
    final temporary = File('${target.path}.tmp');
    try {
      await temporary.writeAsBytes(bytes, flush: true);
      await temporary.rename(target.path);
    } catch (_) {
      try {
        if (await temporary.exists()) await temporary.delete();
      } catch (_) {}
      rethrow;
    }
    if (!await _matches(target, reference)) {
      throw StateError('Course media could not be verified after writing.');
    }
    return reference;
  }

  /// Copies [source] into [courseId]'s folder; the extension comes from its
  /// name.
  Future<String> addFile(String courseId, File source) async {
    final name = source.uri.pathSegments.isEmpty
        ? ''
        : source.uri.pathSegments.last;
    final dot = name.lastIndexOf('.');
    if (dot < 0) throw const FormatException('The file has no extension.');
    return addBytes(
      courseId,
      await source.readAsBytes(),
      name.substring(dot + 1),
    );
  }

  /// Copies each of [references] present for [fromCourseId] into
  /// [toCourseId]'s folder and returns those that were missing at the source.
  Future<Set<String>> copyReferences(
    String fromCourseId,
    String toCourseId,
    Iterable<String> references,
  ) async {
    final missing = <String>{};
    for (final reference in references.toSet()) {
      if (!isReference(reference)) continue;
      final source = await existingFile(fromCourseId, reference);
      if (source == null) {
        if (await existingFile(toCourseId, reference) == null) {
          missing.add(reference);
        }
        continue;
      }
      await addBytes(
        toCourseId,
        await source.readAsBytes(),
        extensionOf(reference),
      );
    }
    return missing;
  }

  /// Deletes the stored files of [courseId] that [keep] does not name, and the
  /// folder once it is empty. Only regular files named like course media are
  /// touched. Returns how many files were deleted; never throws.
  Future<int> deleteUnreferenced(String courseId, Set<String> keep) async {
    var deleted = 0;
    try {
      final directory = await courseDirectory(courseId);
      if (!await directory.exists()) return 0;
      final keepNames = keep.where(isReference).map(fileNameOf).toSet();
      await for (final entity in directory.list(followLinks: false)) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        final stale =
            (_fileNamePattern.hasMatch(name) && !keepNames.contains(name)) ||
            name.endsWith('.tmp');
        if (!stale) continue;
        try {
          await entity.delete();
          deleted++;
        } catch (_) {}
      }
      try {
        // Succeeds only when the folder is now empty.
        await directory.delete();
      } catch (_) {}
    } catch (_) {}
    return deleted;
  }

  /// Deletes the stored file of [reference] for [courseId], if present. The
  /// caller must know that no saved or edited version of the Course still
  /// uses it. Returns whether a file was deleted; never throws.
  Future<bool> deleteStored(String courseId, String reference) async {
    try {
      final file = await existingFile(courseId, reference);
      if (file == null) return false;
      await file.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Deletes every stored file of [courseId]; never throws.
  Future<void> deleteCourse(String courseId) async {
    try {
      final directory = await courseDirectory(courseId);
      if (await directory.exists()) await directory.delete(recursive: true);
    } catch (_) {}
  }

  static Future<bool> _matches(File file, String reference) async {
    try {
      return sha256.convert(await file.readAsBytes()).toString() ==
          digestOf(reference);
    } catch (_) {
      return false;
    }
  }
}
