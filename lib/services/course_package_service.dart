import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';

import '../models/course_models.dart';
import 'course_media_store.dart';

/// A fully checked package. Reading one never writes to course storage.
class CoursePackage {
  CoursePackage(
    this.course,
    this.courseJson,
    this.media, {
    CourseMediaStore? mediaStore,
  }) : _mediaStore = mediaStore ?? CourseMediaStore();

  final Course course;
  final Uint8List courseJson;
  final Map<String, Uint8List> media;
  final CourseMediaStore _mediaStore;

  /// Materializes only the media this Course uses, after the caller has
  /// accepted it. Newly created files are rolled back if [save] fails.
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
      for (final entry in media.entries) {
        if (sha256.convert(entry.value).toString() !=
            CourseMediaStore.digestOf(entry.key)) {
          throw FormatException(
            'Course media ${entry.key} has the wrong SHA-256.',
          );
        }
        final existing = await store.existingFile(targetCourseId, entry.key);
        if (existing != null) {
          if (sha256.convert(await existing.readAsBytes()).toString() !=
              CourseMediaStore.digestOf(entry.key)) {
            throw FormatException(
              'Existing Course media ${CourseMediaStore.fileNameOf(entry.key)} '
              'is damaged; the Course was not changed.',
            );
          }
          continue;
        }
        await store.addBytes(
          targetCourseId,
          entry.value,
          CourseMediaStore.extensionOf(entry.key),
        );
        created.add(entry.key);
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
    this.sizeLimit = maxPackageBytes,
  }) : assert(sizeLimit > 0 && sizeLimit <= maxPackageBytes),
       _media = mediaStore ?? CourseMediaStore();

  final CourseMediaStore _media;
  final int sizeLimit;

  static const int maxPackageBytes = 300 * 1024 * 1024;
  static const int maxCourseJsonBytes = 10 * 1024 * 1024;
  static const int maxCoverBytes = 100 * 1024;
  static const int maxManifestBytes = 1024 * 1024;
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
        'Course JSON exceeds the 10 MB safety limit.',
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
      throw const FormatException('Course package manifest is too large.');
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
          '${_usage(course, reference)}.',
        );
      }
      _checkMedia(reference, bytes);
      total += bytes.length;
      if (total > sizeLimit) {
        throw const FormatException('Course package exceeds the 300 MB limit.');
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
      throw const FormatException('Course package exceeds the 300 MB limit.');
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
      throw const FormatException('Course package exceeds the 300 MB limit.');
    }
    // Read the central directory before ZipDecoder, which eagerly expands
    // symlink contents. Reject oversized and unsafe entries first.
    final directory = ZipDirectory();
    try {
      directory.read(InputMemoryStream(zip));
    } catch (_) {
      throw const FormatException('This is not a readable Course package ZIP.');
    }
    final names = <String>{};
    var expanded = 0;
    for (final header in directory.fileHeaders) {
      final name = header.filename;
      if (!names.add(name)) {
        throw FormatException('Duplicate Course package entry: $name');
      }
      final mode = header.externalFileAttributes >> 16;
      if ((mode & 0xf000) == 0xa000 ||
          (name != manifestName &&
              name != courseName &&
              !_mediaName.hasMatch(name))) {
        throw FormatException(
          'Unsafe or unexpected Course package entry: $name',
        );
      }
      expanded += header.uncompressedSize;
      if (header.uncompressedSize < 0 || expanded > sizeLimit) {
        throw const FormatException(
          'Expanded Course package exceeds the 300 MB limit.',
        );
      }
    }
    final ZipDecoder decoder = ZipDecoder();
    final Archive archive;
    try {
      archive = decoder.decodeBytes(zip);
    } catch (_) {
      throw const FormatException('This is not a readable Course package ZIP.');
    }
    final entries = <String, ArchiveFile>{};
    for (final entry in archive.files) {
      final name = entry.name;
      if (!entry.isFile ||
          entry.isSymbolicLink ||
          (entry.mode & 0xf000) == 0xa000 ||
          (name != manifestName &&
              name != courseName &&
              !_mediaName.hasMatch(name))) {
        throw FormatException(
          'Unsafe or unexpected Course package entry: $name',
        );
      }
      entries[name] = entry;
    }
    final manifest = entries[manifestName];
    final courseEntry = entries[courseName];
    if (manifest == null || courseEntry == null) {
      throw const FormatException(
        'This ZIP is not a Course package: manifest or course.json is missing.',
      );
    }
    if (manifest.size > maxManifestBytes ||
        courseEntry.size > maxCourseJsonBytes) {
      throw const FormatException(
        'Course package manifest or JSON is too large.',
      );
    }
    late final Map<String, dynamic> manifestData;
    try {
      final decoded = jsonDecode(utf8.decode(_bytes(manifest)));
      if (decoded is! Map ||
          decoded['packageFormat'] != 1 ||
          decoded.keys.any(
            (key) => key != 'packageFormat' && key != 'sharedImageSources',
          )) {
        throw const FormatException('Unsupported Course package format.');
      }
      manifestData = Map<String, dynamic>.from(decoded);
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Invalid Course package manifest.');
    }
    final courseJson = _bytes(courseEntry);
    final media = <String, Uint8List>{};
    for (final entry in entries.entries) {
      if (!_mediaName.hasMatch(entry.key)) continue;
      final reference = 'media:${entry.key.substring('media/'.length)}';
      final value = _bytes(entry.value);
      _checkMedia(reference, value);
      media[reference] = value;
    }
    final course = await validateCourse(courseJson, courseName);
    final expectedSources = _sharedImageSources(course);
    final actualSources = manifestData['sharedImageSources'];
    if (expectedSources.isEmpty) {
      if (actualSources != null) {
        throw const FormatException(
          'Course package shared image metadata does not match the Course.',
        );
      }
    } else if (actualSources is! List ||
        jsonEncode(_normalizedManifestSources(actualSources)) !=
            jsonEncode(expectedSources)) {
      throw const FormatException(
        'Course package shared image metadata does not match the Course.',
      );
    }
    final references = CourseMediaStore.referencesOf(course);
    for (final reference in references) {
      if (!media.containsKey(reference)) {
        throw FormatException(
          'Course package is missing ${CourseMediaStore.fileNameOf(reference)} '
          'used in ${_usage(course, reference)}.',
        );
      }
    }
    if (course.coverImage.isNotEmpty) {
      await _checkCover(course.coverImage, media[course.coverImage]!);
    }
    media.removeWhere((reference, _) => !references.contains(reference));
    return CoursePackage(course, courseJson, media, mediaStore: _media);
  }

  static Uint8List _bytes(ArchiveFile entry) {
    try {
      final output = _LimitedOutputStream(entry.size);
      entry.decompress(output);
      final bytes = output.getBytes();
      if (bytes.length != entry.size) {
        throw const FormatException('Course package entry could not be read.');
      }
      return bytes;
    } on FormatException {
      rethrow;
    } catch (_) {
      throw FormatException('Course package entry ${entry.name} is damaged.');
    }
  }

  static void _checkMedia(String reference, Uint8List bytes) {
    final max = CourseMediaStore.isAudioReference(reference)
        ? CourseMediaStore.maxAudioBytes
        : CourseMediaStore.maxImageBytes;
    if (bytes.isEmpty || bytes.length > max) {
      throw FormatException(
        '${CourseMediaStore.fileNameOf(reference)} exceeds its Course media size limit.',
      );
    }
    if (sha256.convert(bytes).toString() !=
        CourseMediaStore.digestOf(reference)) {
      throw FormatException(
        '${CourseMediaStore.fileNameOf(reference)} does not match its SHA-256 name.',
      );
    }
  }

  static Future<void> _checkCover(String reference, Uint8List bytes) async {
    if (!CourseMediaStore.isImageReference(reference) ||
        bytes.length > maxCoverBytes) {
      throw const FormatException(
        'Course cover must be PNG, JPEG or WEBP and at most 100 KB.',
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
        'Course cover file format does not match its name.',
      );
    }
    ui.Codec? codec;
    try {
      codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;
      final valid = image.width == 512 && image.height == 512;
      image.dispose();
      if (!valid) {
        throw const FormatException(
          'Course cover must be exactly 512 × 512 pixels.',
        );
      }
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Course cover image could not be decoded.');
    } finally {
      codec?.dispose();
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
          'Invalid shared image metadata in Course package.',
        );
      }
      final Map<String, dynamic> data;
      try {
        data = Map<String, dynamic>.from(item);
      } catch (_) {
        throw const FormatException(
          'Invalid shared image metadata in Course package.',
        );
      }
      final media = data.remove('media');
      final digest = data.remove('sha256');
      if (media is! String ||
          !CourseMediaStore.isImageReference(media) ||
          digest != CourseMediaStore.digestOf(media)) {
        throw const FormatException(
          'Invalid shared image identity in Course package.',
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
          'Duplicate shared image metadata in Course package.',
        );
      }
      entries[key] = entry;
    }
    final sorted = entries.keys.toList()..sort();
    return [for (final key in sorted) entries[key]!];
  }
}

class _LimitedOutputStream extends OutputStream {
  _LimitedOutputStream(this.limit)
    : _output = OutputMemoryStream(size: limit),
      super(byteOrder: ByteOrder.littleEndian);

  final int limit;
  final OutputMemoryStream _output;

  @override
  int get length => _output.length;

  void _check(int additional) {
    if (additional < 0 || length + additional > limit) {
      throw const FormatException(
        'Course package entry expands beyond its declared size.',
      );
    }
  }

  @override
  void writeByte(int value) {
    _check(1);
    _output.writeByte(value);
  }

  @override
  void writeBytes(List<int> bytes, {int? length}) {
    _check(length ?? bytes.length);
    _output.writeBytes(bytes, length: length);
  }

  @override
  void writeStream(InputStream stream) {
    _check(stream.length);
    _output.writeStream(stream);
  }

  @override
  void clear() => _output.clear();

  @override
  void flush() => _output.flush();

  @override
  Uint8List subset(int start, [int? end]) => _output.subset(start, end);
}
