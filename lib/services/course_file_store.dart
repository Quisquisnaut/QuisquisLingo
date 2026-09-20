import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'course_backup_service.dart';

/// Which authoring store a Course belongs to.
enum CourseStoreKind {
  custom('custom'),
  externalOfficial('external_official');

  const CourseStoreKind(this.directoryName);
  final String directoryName;
}

/// Seam for forcing a write failure in tests, mirroring the preference writer
/// the SharedPreferences store used before.
typedef CourseStoreFileWriter =
    Future<void> Function(File target, String contents);

/// One file per Course, replacing the single SharedPreferences blob.
///
/// The previous store kept every custom Course inside one string under one
/// preference key. That made a save cost the whole corpus, capped all authoring
/// data at 8 MB combined, and let a single unreadable Course hide every other
/// one. This store is a clean cut: the old key is neither read nor migrated,
/// and nothing here ever touches it.
///
/// Writes go to a temporary file and are renamed into place, which is atomic on
/// both Windows and POSIX, then read back and verified. A Course that cannot be
/// parsed is left on disk untouched and reported by name, so the others still
/// load.
class CourseFileStore {
  CourseFileStore({
    Future<Directory> Function()? supportDirectory,
    CourseStoreFileWriter? fileWriter,
  }) : _supportDirectory = supportDirectory ?? getApplicationSupportDirectory,
       _fileWriter = fileWriter;

  /// Versioned so a later storage change can be another clean cut.
  static const rootDirectoryName = 'qql_courses_v1';

  /// Per Course, replacing the old 8 MB cap on all courses combined. It matches
  /// the import limit, so anything importable is storable.
  static const int maxCourseBytes = 10 * 1024 * 1024;

  final Future<Directory> Function() _supportDirectory;
  final CourseStoreFileWriter? _fileWriter;

  Future<Directory> directoryFor(
    CourseStoreKind kind, {
    bool create = false,
  }) async {
    final root = await _supportDirectory();
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}$rootDirectoryName'
      '${Platform.pathSeparator}${kind.directoryName}',
    );
    if (create) await directory.create(recursive: true);
    return directory;
  }

  /// The root both kinds live under, for reset and inventory.
  Future<Directory> rootDirectory() async {
    final root = await _supportDirectory();
    return Directory('${root.path}${Platform.pathSeparator}$rootDirectoryName');
  }

  File _fileFor(Directory directory, String courseId) => File(
    '${directory.path}${Platform.pathSeparator}'
    '${CourseBackupService.sanitizedCourseId(courseId)}.json',
  );

  /// Every stored record for [kind], keyed by the Course ID held inside each
  /// file rather than by its file name, because the file name is sanitized and
  /// therefore lossy.
  Future<Map<String, dynamic>> readAll(CourseStoreKind kind) async {
    final directory = await directoryFor(kind);
    if (!await directory.exists()) return <String, dynamic>{};
    final files =
        (await directory.list(followLinks: false).toList())
            .whereType<File>()
            .where((file) => file.path.toLowerCase().endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    final out = <String, dynamic>{};
    for (final file in files) {
      final record = await _decode(file);
      final courseId = record['courseId'];
      if (courseId is! String || courseId.trim().isEmpty) {
        throw FormatException(
          'Stored Course record ${_name(file)} has no Course ID. '
          'The file was preserved and was not loaded.',
        );
      }
      if (out.containsKey(courseId)) {
        throw FormatException(
          'Two stored Course records both claim the Course ID $courseId.',
        );
      }
      out[courseId] = record['entry'];
    }
    return out;
  }

  Future<Map<String, dynamic>> _decode(File file) async {
    String raw;
    try {
      raw = await file.readAsString();
    } catch (error) {
      throw FormatException(
        'Stored Course record ${_name(file)} could not be read. '
        'The file was preserved and was not loaded. $error',
      );
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException(
          'A stored Course record must be an object.',
        );
      }
      return Map<String, dynamic>.from(decoded);
    } catch (error) {
      throw FormatException(
        'Stored Course record ${_name(file)} is invalid or unsupported. '
        'The file was preserved and was not loaded. $error',
      );
    }
  }

  static String _name(File file) =>
      file.path.split(RegExp(r'[\\/]')).where((part) => part.isNotEmpty).last;

  Future<bool> contains(CourseStoreKind kind, String courseId) async {
    final directory = await directoryFor(kind);
    if (!await directory.exists()) return false;
    return _fileFor(directory, courseId).exists();
  }

  /// Writes one Course record, leaving every other Course untouched.
  Future<void> write(
    CourseStoreKind kind,
    String courseId,
    Object? entry,
  ) async {
    final encoded = jsonEncode({'courseId': courseId, 'entry': entry});
    if (utf8.encode(encoded).length > maxCourseBytes) {
      throw StateError(
        'This Course exceeds the 10 MB storage safety limit. Export or simplify it before saving more content.',
      );
    }
    final directory = await directoryFor(kind, create: true);
    final target = _fileFor(directory, courseId);
    final temporary = File('${target.path}.tmp');
    try {
      final writer = _fileWriter;
      if (writer == null) {
        await temporary.writeAsString(encoded, flush: true);
      } else {
        await writer(temporary, encoded);
      }
      await temporary.rename(target.path);
    } catch (error) {
      try {
        if (await temporary.exists()) await temporary.delete();
      } catch (_) {}
      rethrow;
    }
    if (await target.readAsString() != encoded) {
      throw StateError('Verified Course storage write failed for $courseId.');
    }
  }

  Future<void> remove(CourseStoreKind kind, String courseId) async {
    final directory = await directoryFor(kind);
    if (!await directory.exists()) return;
    final target = _fileFor(directory, courseId);
    if (await target.exists()) await target.delete();
  }
}
