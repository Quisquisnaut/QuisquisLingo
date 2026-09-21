import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import '../models/course_models.dart';
import 'course_media_store.dart';
import 'import/bounded_zip_reader.dart';
import 'import/image_validator.dart';
import 'import/import_stager.dart';
import 'import/media_file_kind.dart';
import 'import/mp3_validator.dart';

/// A fully checked package. Reading one never writes to course storage.
///
/// A package read from a ZIP keeps each media file in QQL's private staging
/// folder, not in memory; [discard] removes those copies (startup cleanup
/// removes any that are left behind). A package built in memory (a media-free
/// JSON Course, or a Copy/Fork) holds its few bytes directly.
class CoursePackage {
  CoursePackage(
    this.course,
    this.courseJson,
    Map<String, Uint8List> media, {
    CourseMediaStore? mediaStore,
  }) : _memory = Map.unmodifiable(media),
       _staged = const {},
       _mediaStore = mediaStore ?? CourseMediaStore();

  CoursePackage._staged(
    this.course,
    this.courseJson,
    Map<String, File> staged, {
    required CourseMediaStore mediaStore,
  }) : _memory = const {},
       _staged = Map.unmodifiable(staged),
       _mediaStore = mediaStore;

  final Course course;
  final Uint8List courseJson;
  final Map<String, Uint8List> _memory;
  final Map<String, File> _staged;
  final CourseMediaStore _mediaStore;

  /// The media references this package carries (exactly those the Course
  /// uses).
  Set<String> get mediaReferences => {..._memory.keys, ..._staged.keys};

  /// One medium's bytes, read when needed.
  Future<Uint8List> mediaBytes(String reference) async {
    final inMemory = _memory[reference];
    if (inMemory != null) return inMemory;
    final file = _staged[reference];
    if (file == null) {
      throw FormatException('Course media $reference is not in the package. Export the Course package again with this file included.');
    }
    return file.readAsBytes();
  }

  /// Removes the staged media copies; never throws.
  Future<void> discard() async {
    for (final file in _staged.values) {
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }
  }

  /// Materializes only the media this Course uses, after the caller has
  /// accepted it, one file at a time. Newly created files are rolled back if
  /// [save] fails.
  Future<T> withInstalledMedia<T>(
    String targetCourseId,
    Future<T> Function() save, {
    CourseMediaStore? mediaStore,
    bool keepOnSuccess = true,
  }) async {
    final store = mediaStore ?? _mediaStore;
    final created = <String>[];
    var succeeded = false;
    try {
      for (final reference in mediaReferences) {
        final bytes = await mediaBytes(reference);
        if (sha256.convert(bytes).toString() !=
            CourseMediaStore.digestOf(reference)) {
          throw FormatException(
          'Course media $reference has the wrong SHA-256. Replace it with the original file and export the package again.',
          );
        }
        final existing = await store.existingFile(targetCourseId, reference);
        if (existing != null) {
          if (sha256.convert(await existing.readAsBytes()).toString() !=
              CourseMediaStore.digestOf(reference)) {
            throw FormatException(
              'Existing Course media ${CourseMediaStore.fileNameOf(reference)} '
              'is damaged; the Course was not changed. Restore the original file and retry.',
            );
          }
          continue;
        }
        await store.addBytes(
          targetCourseId,
          bytes,
          CourseMediaStore.extensionOf(reference),
        );
        created.add(reference);
      }
      final result = await save();
      succeeded = true;
      return result;
    } finally {
      if (!succeeded || !keepOnSuccess) {
        for (final reference in created) {
          final file = await store.fileFor(targetCourseId, reference);
          if (await file.exists()) await file.delete();
        }
        final directory = await store.courseDirectory(targetCourseId);
        if (await directory.exists() &&
            (await directory.list(followLinks: false).isEmpty)) {
          await directory.delete();
        }
      }
    }
  }
}

class CoursePackageService {
  CoursePackageService({
    CourseMediaStore? mediaStore,
    ImportStager? stager,
    this.sizeLimit = maxPackageBytes,
  }) : assert(sizeLimit > 0 && sizeLimit <= maxPackageBytes),
       _media = mediaStore ?? CourseMediaStore(),
       _stager = stager ?? ImportStager();

  final CourseMediaStore _media;
  final ImportStager _stager;
  final int sizeLimit;

  static const int maxPackageBytes = 300 * 1024 * 1024;
  static const int maxCourseJsonBytes = 10 * 1024 * 1024;
  static const int maxCoverBytes = 100 * 1024;
  static const int maxManifestBytes = 1024 * 1024;

  /// Archive entries (files and folders) a package may list.
  static const int maxPackageEntries = 20000;
  static const String manifestName = 'qql-course-package.json';
  static const String courseName = 'course.json';
  static final RegExp _mediaName = RegExp(
    r'^media/([0-9a-f]{64})\.(mp3|png|jpg|jpeg|webp)$',
  );

  /// Uses the supplied Course serialization unchanged as `course.json`.
  Future<Uint8List> build(
    Course course,
    Uint8List courseJson, {
    Map<String, Uint8List>? suppliedMedia,
  }) async {
    if (courseJson.length > maxCourseJsonBytes) {
      throw const FormatException(
        'Course JSON exceeds the 10 MB safety limit. Remove unnecessary content before exporting.',
      );
    }
    final sharedSources = _sharedImageSources(course);
    final manifestBytes = Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'packageFormat': 1,
          if (sharedSources.isNotEmpty) 'sharedImageSources': sharedSources,
        }),
      ),
    );
    if (manifestBytes.length > maxManifestBytes) {
      throw const FormatException('Course package manifest is too large. Remove unnecessary metadata and export again.');
    }
    final archive = Archive()
      ..addFile(ArchiveFile.bytes(manifestName, manifestBytes))
      ..addFile(ArchiveFile.bytes(courseName, courseJson));
    var total = courseJson.length + manifestBytes.length;
    final references = CourseMediaStore.referencesOf(course).toList()..sort();
    for (final reference in references) {
      final file = suppliedMedia == null
          ? await _media.existingFile(course.courseId, reference)
          : null;
      final bytes = suppliedMedia == null
          ? (file == null ? null : await file.readAsBytes())
          : suppliedMedia[reference];
      if (bytes == null) {
        throw FormatException(
          'Course media ${CourseMediaStore.fileNameOf(reference)} is missing '
          'from ${suppliedMedia == null ? (await _media.courseDirectory(course.courseId)).path : 'the supplied media folder'}; used in '
          '${_usage(course, reference)}. Restore the original file to the Course and export again.',
        );
      }
      _checkMedia(reference, bytes);
      total += bytes.length;
      if (total > sizeLimit) {
        throw const FormatException('Course package exceeds the 300 MB limit. Remove or shrink media and export again.');
      }
      archive.addFile(
        ArchiveFile.bytes(
          'media/${CourseMediaStore.fileNameOf(reference)}',
          bytes,
        ),
      );
    }
    final zip = Uint8List.fromList(ZipEncoder().encode(archive));
    if (zip.length > sizeLimit) {
      throw const FormatException('Course package exceeds the 300 MB limit. Remove or shrink media and export again.');
    }
    return zip;
  }

  /// Checks structure, compressed and expanded sizes, content digests and the
  /// Course itself before returning anything that can be installed.
  Future<CoursePackage> parse(
    Uint8List zip,
    Future<Course> Function(Uint8List bytes, String fileName) validateCourse,
  ) async {
    if (zip.length > sizeLimit) {
      throw const FormatException('Course package exceeds the 300 MB limit. Remove or shrink media and export again.');
    }
    _checkArchiveKind(zip);
    return _parse(InputMemoryStream(zip), validateCourse);
  }

  /// [parse] reading the ZIP from [zip] on disk, a piece at a time, so the
  /// whole archive is never held in memory.
  Future<CoursePackage> parseFile(
    File zip,
    Future<Course> Function(Uint8List bytes, String fileName) validateCourse,
  ) async {
    if (await zip.length() > sizeLimit) {
      throw const FormatException('Course package exceeds the 300 MB limit. Remove or shrink media and export again.');
    }
    final source = await zip.open();
    try {
      _checkArchiveKind(await source.read(4096));
    } finally {
      await source.close();
    }
    final input = InputFileStream(zip.path);
    try {
      return await _parse(input, validateCourse);
    } finally {
      await input.close();
    }
  }

  static void _checkArchiveKind(Uint8List bytes) {
    final kind = unexpectedMediaKind(bytes);
    if (kind != null && kind != 'ZIP archive') {
      throw FormatException(
        'This file is a $kind, not a Course package ZIP. Export the Course '
        'package again and select that ZIP.',
      );
    }
  }

  Future<CoursePackage> _parse(
    InputStream input,
    Future<Course> Function(Uint8List bytes, String fileName) validateCourse,
  ) async {
    final zipReader = BoundedZipReader.open(
      input,
      label: 'Course package',
      maxEntries: maxPackageEntries,
      maxTotalBytes: sizeLimit,
    );
    final entries = <String, BoundedZipEntry>{};
    for (final entry in zipReader.entries) {
      final name = entry.name;
      if (name != manifestName &&
          name != courseName &&
          !_mediaName.hasMatch(name)) {
        throw FormatException(
          'Unsafe or unexpected Course package entry: $name. Export a fresh package containing only its manifest, course.json and referenced media.',
        );
      }
      entries[name] = entry;
    }
    final manifest = entries[manifestName];
    final courseEntry = entries[courseName];
    if (manifest == null || courseEntry == null) {
      throw const FormatException(
        'This ZIP is not a Course package: manifest or course.json is missing. Use Export Course package to create a complete ZIP and retry.',
      );
    }
    if (manifest.size > maxManifestBytes ||
        courseEntry.size > maxCourseJsonBytes) {
      throw const FormatException(
        'Course package manifest or JSON is too large. Remove unnecessary Course content and export again.',
      );
    }
    late final Map<String, dynamic> manifestData;
    try {
      final decoded = jsonDecode(utf8.decode(zipReader.read(manifest)));
      if (decoded is! Map ||
          decoded['packageFormat'] != 1 ||
          decoded.keys.any(
            (key) => key != 'packageFormat' && key != 'sharedImageSources',
          )) {
        throw const FormatException('Unsupported Course package format. Export the Course with this QQL version and try again.');
      }
      manifestData = Map<String, dynamic>.from(decoded);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Invalid Course package manifest. Export a fresh Course package instead of editing the ZIP by hand.');
    }
    final courseJson = zipReader.read(courseEntry);
    final course = await validateCourse(courseJson, courseName);
    final expectedSources = _sharedImageSources(course);
    final actualSources = manifestData['sharedImageSources'];
    if (expectedSources.isEmpty) {
      if (actualSources != null) {
        throw const FormatException(
          'Course package shared image metadata does not match the Course. Export a fresh package with its images.',
        );
      }
    } else if (actualSources is! List ||
        jsonEncode(_normalizedManifestSources(actualSources)) !=
            jsonEncode(expectedSources)) {
      throw const FormatException(
        'Course package shared image metadata does not match the Course. Export a fresh package with its images.',
      );
    }
    final references = CourseMediaStore.referencesOf(course);
    for (final reference in references) {
      if (!entries.containsKey(
        'media/${CourseMediaStore.fileNameOf(reference)}',
      )) {
        throw FormatException(
          'Course package is missing ${CourseMediaStore.fileNameOf(reference)} '
          'used in ${_usage(course, reference)}. Export the Course again with its media.',
        );
      }
    }
    // Media the Course does not use is never read. Each used file is read,
    // checked and written to staging before the next one is read.
    final staged = <String, File>{};
    try {
      for (final reference in references) {
        final value = zipReader.read(
          entries['media/${CourseMediaStore.fileNameOf(reference)}']!,
        );
        _checkMedia(reference, value);
        _checkImportedImage(reference, value);
        if (CourseMediaStore.isAudioReference(reference)) {
          try {
            await Mp3Validator.validate(value);
          } on Mp3ValidationException catch (error) {
            throw FormatException(
              '${CourseMediaStore.fileNameOf(reference)}: ${error.message}',
            );
          }
        }
        if (reference == course.coverImage) {
          await _checkCover(course.coverImage, value);
        }
        staged[reference] = await _stager.stageBytes(value);
      }
    } catch (_) {
      for (final file in staged.values) {
        try {
          await file.delete();
        } catch (_) {}
      }
      rethrow;
    }
    return CoursePackage._staged(
      course,
      courseJson,
      staged,
      mediaStore: _media,
    );
  }

  /// An imported image medium must be a valid image of the type its name
  /// says. Applied when a package is read, never when one is written.
  static void _checkImportedImage(String reference, Uint8List bytes) {
    if (!CourseMediaStore.isImageReference(reference)) return;
    try {
      final facts = ImageValidator.inspect(
        bytes,
        const ImageProfile(maxBytes: CourseMediaStore.maxImageBytes),
      );
      final extension = CourseMediaStore.extensionOf(reference);
      if (facts.format.extension != extension &&
          !(facts.format == ImageFormat.jpeg && extension == 'jpeg')) {
        throw const ImageValidationException(
          'The file is not the image type its name says. Export the picture in that format and make a new Course package.',
        );
      }
    } on ImageValidationException catch (error) {
      throw FormatException(
        '${CourseMediaStore.fileNameOf(reference)}: ${error.message}',
      );
    }
  }

  static void _checkMedia(String reference, Uint8List bytes) {
    final max = CourseMediaStore.isAudioReference(reference)
        ? CourseMediaStore.maxAudioBytes
        : CourseMediaStore.maxImageBytes;
    if (bytes.isEmpty || bytes.length > max) {
      throw FormatException(
        '${CourseMediaStore.fileNameOf(reference)} is empty or exceeds its Course media size limit. Replace it with a smaller valid file and export again.',
      );
    }
    if (sha256.convert(bytes).toString() !=
        CourseMediaStore.digestOf(reference)) {
      throw FormatException(
        '${CourseMediaStore.fileNameOf(reference)} does not match its SHA-256 name. Restore the original media file and export again.',
      );
    }
  }

  @visibleForTesting
  static Future<void> checkCoverForTest(String reference, Uint8List bytes) =>
      _checkCover(reference, bytes);

  static Future<void> _checkCover(String reference, Uint8List bytes) async {
    if (!CourseMediaStore.isImageReference(reference) ||
        bytes.length > maxCoverBytes) {
      throw const FormatException(
        'Course cover must be PNG, JPEG or WebP and small enough to import. Export a smaller still picture and retry.',
      );
    }
    final ext = CourseMediaStore.extensionOf(reference);
    final png =
        bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4e &&
        bytes[3] == 0x47;
    final jpeg =
        bytes.length >= 3 &&
        bytes[0] == 0xff &&
        bytes[1] == 0xd8 &&
        bytes[2] == 0xff;
    final webp =
        bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46 &&
        bytes[3] == 0x46 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50;
    if (!((ext == 'png' && png) ||
        ((ext == 'jpg' || ext == 'jpeg') && jpeg) ||
        (ext == 'webp' && webp))) {
      throw const FormatException(
        'Course cover file format does not match its name. Export the picture in the named format and retry.',
      );
    }
    // Read the declared dimensions from the header first. Decoding before
    // this check let a 100 KB file that claims 30,000 × 30,000 pixels
    // allocate gigabytes; only a genuine 512 × 512 cover is ever rasterized.
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      if (descriptor.width != 512 || descriptor.height != 512) {
        throw const FormatException(
          'Course cover must be exactly 512 × 512 pixels. Resize it to a square of that size and retry.',
        );
      }
      ImageValidator.inspect(bytes, ImageProfile.courseCover);
      codec = await descriptor.instantiateCodec();
      final frame = await codec.getNextFrame();
      frame.image.dispose();
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Course cover image could not be decoded. Export a fresh PNG, JPEG or WebP image and retry.');
    } finally {
      codec?.dispose();
      descriptor?.dispose();
      buffer?.dispose();
    }
  }

  static String _usage(Course course, String reference) {
    if (course.coverImage == reference) return 'the Course cover';
    for (final clip in course.audioLibrary) {
      if (clip.filePath == reference) {
        return 'Audio Library recording ${clip.id}';
      }
    }
    for (final lesson in course.lessons) {
      if (jsonEncode(lesson.toJson()).contains(reference)) {
        return 'Lesson ${lesson.title}';
      }
    }
    return 'Course ${course.title}';
  }

  static List<Map<String, dynamic>> _sharedImageSources(Course course) {
    final entries = <String, Map<String, dynamic>>{};
    for (final lesson in course.lessons) {
      for (final round in lesson.rounds) {
        for (final exercise in round.exercises) {
          for (final element in exercise.promptElements) {
            final source = element.sharedImageSource;
            if (source == null) continue;
            final entry = <String, dynamic>{
              'media': element.asset,
              'sha256': CourseMediaStore.digestOf(element.asset),
              ...source.toJson(),
            };
            entries[jsonEncode(entry)] = entry;
          }
        }
      }
    }
    final sorted = entries.keys.toList()..sort();
    return [for (final key in sorted) entries[key]!];
  }

  static List<Map<String, dynamic>> _normalizedManifestSources(
    List<dynamic> raw,
  ) {
    final entries = <String, Map<String, dynamic>>{};
    for (final item in raw) {
      if (item is! Map) {
        throw const FormatException(
          'Invalid shared image metadata in Course package. Export a fresh package with its images.',
        );
      }
      final Map<String, dynamic> data;
      try {
        data = Map<String, dynamic>.from(item);
      } catch (_) {
        throw const FormatException(
          'Invalid shared image metadata in Course package. Export a fresh package with its images.',
        );
      }
      final media = data.remove('media');
      final digest = data.remove('sha256');
      if (media is! String ||
          !CourseMediaStore.isImageReference(media) ||
          digest != CourseMediaStore.digestOf(media)) {
        throw const FormatException(
          'Invalid shared image identity in Course package. Export a fresh package with its images.',
        );
      }
      final source = SharedImageSource.fromJson(data);
      final entry = <String, dynamic>{
        'media': media,
        'sha256': digest,
        ...source.toJson(),
      };
      final key = jsonEncode(entry);
      if (entries.containsKey(key)) {
        throw const FormatException(
          'Duplicate shared image metadata in Course package. Remove duplicate entries and export again.',
        );
      }
      entries[key] = entry;
    }
    final sorted = entries.keys.toList()..sort();
    return [for (final key in sorted) entries[key]!];
  }
}
