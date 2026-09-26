import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';

import 'course_backup_service.dart';
import 'storage/course_storage_names.dart';

/// Which authoring store a Course belongs to.
enum CourseStoreKind {
  custom('Custom'),
  externalOfficial('Publisher');

  const CourseStoreKind(this.directoryName);
  final String directoryName;
}

/// Seam for forcing a write failure in tests, mirroring the preference writer
/// the SharedPreferences store used before.
typedef CourseStoreFileWriter =
    Future<void> Function(File target, String contents);

/// One exact on-disk Course record and its opaque compare-and-swap token.
class CourseStoredRecord {
  const CourseStoredRecord(this.entry, this.token);

  final Object? entry;
  final String token;
}

class _CourseLockOwner {
  bool active = true;
}

/// One file per Course, replacing the single SharedPreferences blob.
///
/// The previous store kept every custom Course inside one string under one
/// preference key. That made a save cost the whole corpus, capped all authoring
/// data at 8 MB combined, and let a single unreadable Course hide every other
/// one. This store is a clean cut: the old key is neither read nor migrated,
/// and nothing here ever touches it.
///
/// Writes go to a temporary file and are renamed into place, which is atomic on
/// both Windows and POSIX, then read back and verified. A Course file that
/// cannot be read is left on disk untouched and reported by name. [readAll]
/// refuses the whole store in that case, for callers that must see every Course
/// (unused-media cleanup, profile deletion); [readReadable] returns the others
/// and lists the skipped files, for listing and saving.
class CourseFileStore {
  CourseFileStore({
    Future<Directory> Function()? supportDirectory,
    CourseStoreFileWriter? fileWriter,
  }) : _supportDirectory = supportDirectory ?? getApplicationSupportDirectory,
       _fileWriter = fileWriter;

  /// Build 255 Revision 4 renamed the store and its files (a clean cut). The
  /// earlier `qql_courses_v2` tree (Course Model v11) and `qql_courses_v1`
  /// tree (v9/v10) are left on disk untouched and are never read; a one-off
  /// tool moves the owner's earlier Courses.
  static const rootDirectoryName = 'QQL_Courses';

  /// Per Course, replacing the old 8 MB cap on all courses combined. It matches
  /// the import limit, so anything importable is storable.
  static const int maxCourseBytes = 10 * 1024 * 1024;

  final Future<Directory> Function() _supportDirectory;
  final CourseStoreFileWriter? _fileWriter;

  static final Object _heldLocksZoneKey = Object();
  static final Map<String, Future<void>> _lockTails = {};
  static int _nextTemporaryId = 0;

  /// Serializes mutations of one Course across store instances and both kinds.
  /// The canonical file name is used so IDs that sanitize to the same path
  /// cannot enter independent critical sections.
  Future<T> withCourseLock<T>(
    String courseId,
    Future<T> Function() action,
  ) async {
    final support = await _supportDirectory();
    String rootPath;
    try {
      rootPath = await support.resolveSymbolicLinks();
    } on FileSystemException {
      rootPath = support.absolute.path;
    }
    final pathKey = Platform.isWindows ? rootPath.toLowerCase() : rootPath;
    final fileName = CourseBackupService.sanitizedCourseId(courseId);
    final fileKey = Platform.isWindows ? fileName.toLowerCase() : fileName;
    final key = '$pathKey\u0000$fileKey';
    final held =
        Zone.current[_heldLocksZoneKey] as Map<String, _CourseLockOwner>?;
    if (held?[key]?.active ?? false) return action();

    final prior = _lockTails[key];
    final released = Completer<void>();
    final tail = released.future;
    final owner = _CourseLockOwner();
    _lockTails[key] = tail;
    try {
      if (prior != null) await prior;
      return await runZoned(
        action,
        zoneValues: {
          _heldLocksZoneKey: {...?held, key: owner},
        },
      );
    } finally {
      owner.active = false;
      if (identical(_lockTails[key], tail)) _lockTails.remove(key);
      released.complete();
    }
  }

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

  /// The file [entry] is stored in: `QQL_<pair>_<id>.json`, with the
  /// language pair of the Course the entry holds (`course` for a custom
  /// Course, `source` for a Publisher Course).
  File _targetFor(Directory directory, String courseId, Object? entry) => File(
    '${directory.path}${Platform.pathSeparator}'
    '${CourseStorageNames.courseFileName(courseId, _pairOf(entry))}',
  );

  static String _pairOf(Object? entry) {
    if (entry is Map) {
      final course = entry['course'] ?? entry['source'];
      if (course is Map) return CourseStorageNames.pairOfJson(course);
    }
    const unknown = CourseStorageNames.unknownLanguage;
    return '${unknown}_$unknown';
  }

  static bool _sameIdPart(String? a, String b) {
    if (a == null) return false;
    return Platform.isWindows ? a.toLowerCase() == b.toLowerCase() : a == b;
  }

  static bool _samePath(File a, File b) => Platform.isWindows
      ? a.absolute.path.toLowerCase() == b.absolute.path.toLowerCase()
      : a.absolute.path == b.absolute.path;

  /// The one file holding [courseId], with its record, or null. A file is
  /// found by the ID inside it, because its name is lossy and carries a
  /// language pair that can change. A file named for this ID that cannot be
  /// read, one claiming the ID without an entry, and a second file claiming
  /// it are refused rather than silently chosen or replaced. A readable file
  /// holding another Course is not this one; the writes below never replace
  /// it, because they refuse a name that is taken.
  Future<({File file, Map<String, dynamic> record, List<int> bytes})?>
  _findUnlocked(Directory directory, String courseId) async {
    final idPart = CourseStorageNames.idPart(courseId);
    ({File file, Map<String, dynamic> record, List<int> bytes})? found;
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File || !entity.path.toLowerCase().endsWith('.json')) {
        continue;
      }
      final named = _sameIdPart(
        CourseStorageNames.idPartOfCourseFile(_name(entity)),
        idPart,
      );
      final ({Map<String, dynamic> record, List<int> bytes}) read;
      try {
        read = await _readRecord(entity);
      } on FormatException {
        if (named) rethrow;
        continue;
      }
      final id = read.record['courseId'];
      if (id == courseId) {
        if (!read.record.containsKey('entry')) {
          throw FormatException(
            'Stored Course record ${_name(entity)} has no entry. '
            'The file was preserved.',
          );
        }
        if (found != null) {
          throw FormatException(
            'Two stored Course records both claim the Course ID $courseId. '
            'Both files were preserved.',
          );
        }
        found = (file: entity, record: read.record, bytes: read.bytes);
      }
    }
    return found;
  }

  /// Moves [found] to [target] when the Course's language pair changed, so the
  /// write that follows replaces it in place. Refuses when [target] is taken
  /// by another file, which is never replaced.
  Future<void> _renameTo(File found, File target) async {
    if (_samePath(found, target)) return;
    await _refuseTaken(target);
    await found.rename(target.path);
  }

  /// Refuses [target] when another file has its name already: one holding
  /// another Course, which is never replaced.
  static Future<void> _refuseTaken(File target) async {
    if (await target.exists()) {
      throw FormatException(
        'The stored file ${_name(target)} already holds another Course, so '
        'it was kept and nothing was saved. Move that file out of '
        '${target.parent.path} to save this Course.',
      );
    }
  }

  /// Every stored record for [kind], keyed by the Course ID held inside each
  /// file rather than by its file name, because the file name is sanitized and
  /// therefore lossy.
  ///
  /// Strict: throws, naming the file, when any file cannot be read. Callers
  /// that act on the absence of a Course (deleting media no Course uses,
  /// allowing a profile to be deleted) must not mistake an unreadable Course
  /// for a missing one.
  Future<Map<String, dynamic>> readAll(CourseStoreKind kind) async {
    final snapshot = await readReadable(kind);
    if (snapshot.skipped.isNotEmpty) {
      throw FormatException(snapshot.skipped.first.reason);
    }
    return snapshot.records;
  }

  /// The readable records for [kind] and the files that were skipped. [write]
  /// refuses to replace a file that cannot be read or that holds another
  /// Course ID, so a skipped file is never lost by saving.
  ///
  /// When two files claim the same Course ID, both are skipped, because
  /// neither can be trusted over the other.
  Future<CourseStoreSnapshot> readReadable(CourseStoreKind kind) async {
    final directory = await directoryFor(kind);
    if (!await directory.exists()) {
      // Mutable: callers add Courses to this map before saving it.
      return CourseStoreSnapshot(<String, dynamic>{}, const []);
    }
    final files =
        (await directory.list(followLinks: false).toList())
            .whereType<File>()
            .where((file) => file.path.toLowerCase().endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    final out = <String, dynamic>{};
    final fileById = <String, String>{};
    final duplicateIds = <String>{};
    final skipped = <SkippedCourseFile>[];
    for (final file in files) {
      final Map<String, dynamic> record;
      try {
        record = await _decode(file);
      } on FormatException catch (error) {
        skipped.add(SkippedCourseFile(_name(file), error.message));
        continue;
      }
      final courseId = record['courseId'];
      if (courseId is! String || courseId.trim().isEmpty) {
        skipped.add(
          SkippedCourseFile(
            _name(file),
            'Stored Course record ${_name(file)} has no Course ID. '
            'The file was preserved and was not loaded.',
          ),
        );
        continue;
      }
      if (fileById.containsKey(courseId)) {
        duplicateIds.add(courseId);
        skipped.add(
          SkippedCourseFile(
            _name(file),
            'Two stored Course records both claim the Course ID $courseId.',
          ),
        );
        continue;
      }
      fileById[courseId] = _name(file);
      out[courseId] = record['entry'];
    }
    for (final courseId in duplicateIds) {
      out.remove(courseId);
      skipped.add(
        SkippedCourseFile(
          fileById[courseId]!,
          'Two stored Course records both claim the Course ID $courseId.',
        ),
      );
    }
    return CourseStoreSnapshot(out, skipped);
  }

  Future<({Map<String, dynamic> record, List<int> bytes})> _readRecord(
    File file,
  ) async {
    List<int> bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (error) {
      throw FormatException(
        'Stored Course record ${_name(file)} could not be read. '
        'The file was preserved and was not loaded. $error',
      );
    }
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map) {
        throw const FormatException(
          'A stored Course record must be an object.',
        );
      }
      return (record: Map<String, dynamic>.from(decoded), bytes: bytes);
    } catch (error) {
      throw FormatException(
        'Stored Course record ${_name(file)} is invalid or unsupported. '
        'The file was preserved and was not loaded. $error',
      );
    }
  }

  Future<Map<String, dynamic>> _decode(File file) async =>
      (await _readRecord(file)).record;

  static String _name(File file) =>
      file.path.split(RegExp(r'[\\/]')).where((part) => part.isNotEmpty).last;

  /// Reads only the requested Course record. A duplicate ID or a canonical
  /// file owned by another ID is refused instead of silently choosing one.
  Future<CourseStoredRecord?> snapshot(CourseStoreKind kind, String courseId) =>
      withCourseLock(courseId, () => _snapshotUnlocked(kind, courseId));

  Future<CourseStoredRecord?> _snapshotUnlocked(
    CourseStoreKind kind,
    String courseId,
  ) async {
    final directory = await directoryFor(kind);
    if (!await directory.exists()) return null;
    final found = await _findUnlocked(directory, courseId);
    if (found == null) return null;
    return CourseStoredRecord(
      found.record['entry'],
      sha256.convert(found.bytes).toString(),
    );
  }

  /// Creates only when no file or duplicate record claims this Course ID.
  Future<void> createIfAbsent(
    CourseStoreKind kind,
    String courseId,
    Object? entry,
  ) => withCourseLock(courseId, () async {
    if (await _snapshotUnlocked(kind, courseId) != null) {
      throw StateError('Stored Course $courseId already exists.');
    }
    final directory = await directoryFor(kind, create: true);
    final target = _targetFor(directory, courseId, entry);
    await _refuseTaken(target);
    await _writeEncoded(target, _encode(courseId, entry), requireAbsent: true);
  });

  /// Replaces one record only when it still has the caller's exact token.
  Future<void> replaceIfUnchanged(
    CourseStoreKind kind,
    String courseId,
    Object? entry, {
    required String expectedToken,
  }) => withCourseLock(courseId, () async {
    final directory = await directoryFor(kind);
    final found = await directory.exists()
        ? await _findUnlocked(directory, courseId)
        : null;
    if (found == null ||
        sha256.convert(found.bytes).toString() != expectedToken) {
      throw StateError('Stored Course $courseId changed before replacement.');
    }
    final encoded = _encode(courseId, entry);
    final target = _targetFor(directory, courseId, entry);
    // A changed language pair renames the file first, so the replacement
    // below stays atomic and never leaves two files claiming the Course.
    await _renameTo(found.file, target);
    await _writeEncoded(target, encoded, expectedToken: expectedToken);
  });

  /// Removes one record only when it still has the caller's exact token.
  Future<void> removeIfUnchanged(
    CourseStoreKind kind,
    String courseId, {
    required String expectedToken,
  }) => withCourseLock(courseId, () async {
    final directory = await directoryFor(kind);
    final found = await directory.exists()
        ? await _findUnlocked(directory, courseId)
        : null;
    if (found == null ||
        sha256.convert(found.bytes).toString() != expectedToken) {
      throw StateError('Stored Course $courseId changed before removal.');
    }
    final latest = await _readRecord(found.file);
    if (sha256.convert(latest.bytes).toString() != expectedToken) {
      throw StateError('Stored Course $courseId changed before removal.');
    }
    await found.file.delete();
  });

  /// Whether a file named for [courseId] is stored, readable or not.
  Future<bool> contains(CourseStoreKind kind, String courseId) async {
    final directory = await directoryFor(kind);
    if (!await directory.exists()) return false;
    final idPart = CourseStorageNames.idPart(courseId);
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is File &&
          _sameIdPart(
            CourseStorageNames.idPartOfCourseFile(_name(entity)),
            idPart,
          )) {
        return true;
      }
    }
    return false;
  }

  /// Writes one Course record, leaving every other Course untouched.
  Future<void> write(
    CourseStoreKind kind,
    String courseId,
    Object? entry,
  ) => withCourseLock(courseId, () async {
    final encoded = _encode(courseId, entry);
    final directory = await directoryFor(kind, create: true);
    final target = _targetFor(directory, courseId, entry);
    // Never replace a file that the listing skipped: it may be the only copy
    // of a Course, and its owner has to recover it by hand.
    final ({File file, Map<String, dynamic> record, List<int> bytes})? found;
    try {
      found = await _findUnlocked(directory, courseId);
    } on FormatException {
      throw FormatException(
        'A stored file for this Course cannot be read as this Course, so it '
        'was kept and nothing was saved. Move that file out of '
        '${directory.path} to save this Course.',
      );
    }
    if (found != null) {
      await _renameTo(found.file, target);
    } else {
      await _refuseTaken(target);
    }
    await _writeEncoded(target, encoded);
  });

  String _encode(String courseId, Object? entry) {
    final encoded = jsonEncode({'courseId': courseId, 'entry': entry});
    if (utf8.encode(encoded).length > maxCourseBytes) {
      throw StateError(
        'This Course exceeds the 10 MB storage safety limit. Export or simplify it before saving more content.',
      );
    }
    return encoded;
  }

  Future<void> _writeEncoded(
    File target,
    String encoded, {
    String? expectedToken,
    bool requireAbsent = false,
  }) async {
    final temporary = File(
      '${target.path}.$pid.${DateTime.now().microsecondsSinceEpoch}.'
      '${_nextTemporaryId++}.tmp',
    );
    try {
      final writer = _fileWriter;
      if (writer == null) {
        await temporary.writeAsString(encoded, flush: true);
      } else {
        await writer(temporary, encoded);
      }
      if (!await temporary.exists() ||
          await temporary.readAsString() != encoded) {
        throw StateError(
          'The staged Course file for ${_name(target)} was incomplete.',
        );
      }
      if (requireAbsent && await target.exists()) {
        throw StateError(
          'Stored Course ${_name(target)} appeared during creation.',
        );
      }
      if (expectedToken != null) {
        if (!await target.exists()) {
          throw StateError(
            'Stored Course ${_name(target)} disappeared before replacement.',
          );
        }
        final current = await _readRecord(target);
        if (sha256.convert(current.bytes).toString() != expectedToken) {
          throw StateError(
            'Stored Course ${_name(target)} changed before replacement.',
          );
        }
      }
      await temporary.rename(target.path);
    } catch (error) {
      try {
        if (await temporary.exists()) await temporary.delete();
      } catch (_) {}
      rethrow;
    }
    if (await target.readAsString() != encoded) {
      throw StateError(
        'Verified Course storage write failed for ${_name(target)}.',
      );
    }
  }

  Future<void> remove(CourseStoreKind kind, String courseId) =>
      withCourseLock(courseId, () async {
        final directory = await directoryFor(kind);
        if (!await directory.exists()) return;
        final found = await _findUnlocked(directory, courseId);
        if (found != null) await found.file.delete();
      });
}

/// The readable part of one store, plus every file that was skipped.
class CourseStoreSnapshot {
  const CourseStoreSnapshot(this.records, this.skipped);

  /// Stored records keyed by Course ID, as [CourseFileStore.readAll] returns.
  final Map<String, dynamic> records;
  final List<SkippedCourseFile> skipped;
}

/// A stored Course file that could not be loaded. It stays on disk untouched.
class SkippedCourseFile {
  const SkippedCourseFile(this.fileName, this.reason);

  final String fileName;
  final String reason;
}
