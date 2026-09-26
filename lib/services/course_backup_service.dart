import 'course_checksums.dart';
import 'publisher_verification_service.dart';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/course_models.dart';
import 'course_media_store.dart';
import 'storage/course_storage_names.dart';
import 'storage/qql_storage.dart';

class CourseBackupRecord {
  final File manifestFile;
  final Course course;
  final String checksum;
  final DateTime backedUpAtUtc;
  final String reason;
  final List<Map<String, String>> assets;

  const CourseBackupRecord({
    required this.manifestFile,
    required this.course,
    required this.checksum,
    required this.backedUpAtUtc,
    required this.reason,
    required this.assets,
  });

  int? get displayedVersion =>
      course.originType.isOfficial ? null : int.tryParse(course.courseVersion);
}

/// Durable, course-scoped backups for final Course Editor transactions.
///
/// Backups live in the public Backups folder beside Import and Export on
/// every system, `QuisquisLingo/Backups/Courses` ([QqlStorage.courseBackupsDirectory]),
/// one folder per Course named `QQL_bkp_<pair>_<id>` (see
/// [CourseStorageNames]). A manifest contains the complete v11 course plus
/// SHA-256 integrity data; the Course's own media (every `media:` image and
/// recording it uses) is copied alongside it, so a version restores even
/// after the confirmed change removed a file from the Course folder.
class CourseBackupService {
  CourseBackupService({
    Future<Directory> Function()? backupsDirectoryProvider,
    Future<void> Function(File file, List<int> bytes)? fileWriter,
    Future<bool> Function(Uri uri)? uriLauncher,
    PublisherVerificationService? publisherVerification,
    CourseMediaStore? mediaStore,
  }) : _backupsDirectoryProvider =
           backupsDirectoryProvider ??
           (() => QqlStorage().courseBackupsDirectory()),
       _fileWriter = fileWriter,
       _uriLauncher = uriLauncher,
       _media = mediaStore ?? CourseMediaStore(),
       _publisherVerification =
           publisherVerification ?? PublisherVerificationService();

  final CourseMediaStore _media;

  final PublisherVerificationService _publisherVerification;

  // v11 clean cut: `Course Backups v9` holds v9/v10 Courses and is left
  // untouched and unread, so an old backup cannot block Version History.
  static const backupFormat = 'QuisquisLingo Course Backup v11';

  /// Build 255 Revision 5 moved the backups here from QQL's private storage
  /// (`QQL_CourseBackups`, and `qql_course_backups_v11` before Revision 4),
  /// and Revision 3 had moved them there from
  /// `Documents/QuisquisLingo/Exports/Course Backups v11`; the earlier
  /// folders are left untouched and no longer read.
  final Future<Directory> Function() _backupsDirectoryProvider;
  final Future<void> Function(File file, List<int> bytes)? _fileWriter;
  final Future<bool> Function(Uri uri)? _uriLauncher;

  /// The Course Backups folder, `QuisquisLingo/Backups/Courses`.
  Future<Directory> backupRoot({bool create = false}) async {
    final directory = await _backupsDirectoryProvider();
    if (create) await directory.create(recursive: true);
    return directory;
  }

  static String sanitizedCourseId(String courseId) =>
      CourseStorageNames.sanitizedId(courseId);

  /// The backup folder of [courseId], found by the ID at the end of its name
  /// whatever its language pair. A folder that does not exist yet is named
  /// with [pair], which creating one requires.
  Future<Directory> courseBackupDirectory(
    String courseId, {
    bool create = false,
    String? pair,
  }) async {
    final root = await backupRoot(create: create);
    final existing = await _existingFolder(root, courseId);
    if (existing == null && create && pair == null) {
      throw ArgumentError.value(
        pair,
        'pair',
        'A new backup folder needs the Course language pair',
      );
    }
    const unknown = CourseStorageNames.unknownLanguage;
    final directory =
        existing ??
        Directory(
          '${root.path}${Platform.pathSeparator}'
          '${CourseStorageNames.backupFolderName(courseId, pair ?? '${unknown}_$unknown')}',
        );
    final rootPath = root.absolute.path;
    final childPath = directory.absolute.path;
    if (!childPath.startsWith('$rootPath${Platform.pathSeparator}')) {
      throw const FormatException('Unsafe Course Backup path.');
    }
    if (create) await directory.create(recursive: true);
    return directory;
  }

  static Future<Directory?> _existingFolder(
    Directory root,
    String courseId,
  ) async {
    if (!await root.exists()) return null;
    final idPart = CourseStorageNames.idPart(courseId);
    await for (final entity in root.list(followLinks: false)) {
      if (entity is! Directory) continue;
      final name = entity.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
      final found = CourseStorageNames.idPartOfBackupFolder(name);
      if (found == null) continue;
      final same = Platform.isWindows
          ? found.toLowerCase() == idPart.toLowerCase()
          : found == idPart;
      if (same) return entity;
    }
    return null;
  }

  /// Renames the backup folder of [course] to its current language pair, so
  /// it keeps matching the Course's other names after its languages change.
  /// Saved versions keep their own names, which record the languages they
  /// had. A folder that cannot be renamed keeps its name and is still found.
  Future<void> alignFolder(Course course) async {
    try {
      final root = await backupRoot();
      final existing = await _existingFolder(root, course.courseId);
      if (existing == null) return;
      final wanted = CourseStorageNames.backupFolderName(
        course.courseId,
        CourseStorageNames.pairOfCourse(course),
      );
      final current = existing.uri.pathSegments.lastWhere((s) => s.isNotEmpty);
      if (current == wanted) return;
      final target = Directory(
        '${root.path}${Platform.pathSeparator}$wanted',
      );
      if (await target.exists()) return;
      await existing.rename(target.path);
    } catch (_) {
      // Only a name: the folder is still found by the Course ID.
    }
  }

  static String courseChecksum(Course course) => CourseChecksums.whole(course);

  static String _nameOf(FileSystemEntity entity) =>
      entity.path.split(RegExp(r'[\\/]')).lastWhere((part) => part.isNotEmpty);

  static String officialContentChecksum(Course course) =>
      CourseChecksums.official(course);

  static String _filenameStamp(DateTime value) => value
      .toUtc()
      .toIso8601String()
      .replaceAll(':', '')
      .replaceAll('-', '')
      .replaceAll('.', '');

  static String _normalizedAbsolutePath(FileSystemEntity entity) {
    final normalized = entity.absolute.uri.normalizePath().toFilePath();
    return Platform.isWindows ? normalized.toLowerCase() : normalized;
  }

  static void _requireChildPath(Directory directory, FileSystemEntity child) {
    final parentPath = _normalizedAbsolutePath(
      directory,
    ).replaceFirst(RegExp(r'[\\/]+$'), '');
    final childPath = _normalizedAbsolutePath(child);
    if (!childPath.startsWith('$parentPath${Platform.pathSeparator}')) {
      throw const FormatException('Unsafe Course Backup manifest path.');
    }
  }

  Future<void> _write(File file, List<int> bytes) async {
    final writer = _fileWriter;
    if (writer != null) {
      await writer(file, bytes);
    } else {
      await file.writeAsBytes(bytes, flush: true);
    }
  }

  Future<CourseBackupRecord> createBackup(
    Course course, {
    required DateTime backedUpAt,
    required String reason,
  }) async {
    final when = backedUpAt.toUtc();
    final pair = CourseStorageNames.pairOfCourse(course);
    final directory = await courseBackupDirectory(
      course.courseId,
      create: true,
      pair: pair,
    );
    final version = course.originType.isOfficial
        ? course.officialCourseVersion
        : (course.courseVersion.trim().isEmpty ? '0' : course.courseVersion);
    final base = CourseStorageNames.backupVersionName(
      course.courseId,
      pair,
      version: version,
      stamp: _filenameStamp(when),
    );
    var manifest = File('${directory.path}${Platform.pathSeparator}$base.json');
    _requireChildPath(directory, manifest);
    var suffix = 2;
    while (await manifest.exists()) {
      manifest = File(
        '${directory.path}${Platform.pathSeparator}${base}_$suffix.json',
      );
      _requireChildPath(directory, manifest);
      suffix += 1;
    }

    final assetRecords = <Map<String, String>>[];
    final references = CourseMediaStore.referencesOf(course).toList()..sort();
    if (references.isNotEmpty) {
      final assetsDirectory = Directory(
        '${directory.path}${Platform.pathSeparator}${manifest.uri.pathSegments.last.replaceAll('.json', '')}_assets',
      );
      await assetsDirectory.create(recursive: true);
      for (final reference in references) {
        final source = await _media.existingFile(course.courseId, reference);
        if (source == null) {
          // A file that is already gone cannot be lost by the change this
          // backup precedes, so refusing to back anything up would protect
          // nothing while making the Course permanently unsaveable: the
          // pre-change backup reads the persisted Course, so even the edit
          // that removes the broken reference could never be confirmed.
          // Record the gap instead; `loadBackup` accepts it and restore has
          // nothing to put back.
          assetRecords.add({'reference': reference, 'missing': 'true'});
          continue;
        }
        final bytes = await source.readAsBytes();
        final digest = sha256.convert(bytes).toString();
        if (digest != CourseMediaStore.digestOf(reference)) {
          throw StateError(
            'Course media ${CourseMediaStore.fileNameOf(reference)} does not match its reference.',
          );
        }
        final backupName = CourseMediaStore.fileNameOf(reference);
        final target = File(
          '${assetsDirectory.path}${Platform.pathSeparator}$backupName',
        );
        await _write(target, bytes);
        if (sha256.convert(await target.readAsBytes()).toString() != digest) {
          throw StateError(
            'A course-owned backup asset could not be verified.',
          );
        }
        assetRecords.add({
          'reference': reference,
          'backupRelativePath':
              '${assetsDirectory.path.substring(directory.path.length + 1)}/$backupName',
          'sha256': digest,
        });
      }
    }

    final checksum = courseChecksum(course);
    final payload = <String, dynamic>{
      'format': backupFormat,
      'courseId': course.courseId,
      'originType': course.originType.name,
      'backedUpAtUtc': when.toIso8601String(),
      'reason': reason,
      'courseChecksumSha256': checksum,
      'courseVersion': course.courseVersion,
      'officialCourseVersion': course.officialCourseVersion,
      'publisherId': course.publisherId,
      'versionNotes': course.originType.isOfficial
          ? course.officialReleaseNotes
          : course.versionNotes,
      if (course.restoredFromVersion != null)
        'restoredFromVersion': course.restoredFromVersion,
      'assets': assetRecords,
      'course': course.toJson(),
    };
    await _write(
      manifest,
      utf8.encode(const JsonEncoder.withIndent('  ').convert(payload)),
    );
    return loadBackup(manifest, expectedCourseId: course.courseId);
  }

  Future<CourseBackupRecord> loadBackup(
    File manifestFile, {
    required String expectedCourseId,
  }) async {
    final directory = await courseBackupDirectory(expectedCourseId);
    _requireChildPath(directory, manifestFile);
    if (!await manifestFile.exists()) {
      throw const FormatException('The selected course backup is missing.');
    }
    final decoded = jsonDecode(await manifestFile.readAsString());
    if (decoded is! Map || decoded['format'] != backupFormat) {
      throw const FormatException(
        'The selected file is not a supported course backup.',
      );
    }
    final manifest = Map<String, dynamic>.from(decoded);
    if (manifest['courseId'] != expectedCourseId) {
      throw const FormatException(
        'The selected backup belongs to a different course.',
      );
    }
    final courseJson = manifest['course'];
    if (courseJson is! Map) {
      throw const FormatException(
        'The course backup has no canonical course content.',
      );
    }
    final course = Course.fromJson(Map<String, dynamic>.from(courseJson));
    if (course.courseId != expectedCourseId) {
      throw const FormatException(
        'The backup course identity does not match its manifest.',
      );
    }
    final checksum = manifest['courseChecksumSha256'];
    if (checksum is! String || checksum != courseChecksum(course)) {
      throw const FormatException('The course backup integrity check failed.');
    }
    final backedUpAt = DateTime.tryParse('${manifest['backedUpAtUtc']}');
    if (backedUpAt == null || !backedUpAt.isUtc) {
      throw const FormatException('The course backup timestamp is invalid.');
    }
    final assets = <Map<String, String>>[];
    final rawAssets = manifest['assets'];
    if (rawAssets is List) {
      for (final raw in rawAssets.whereType<Map>()) {
        final record = raw.map((key, value) => MapEntry('$key', '$value'));
        // A recorded gap: the file was already missing when the backup was
        // taken, so there is nothing to validate and nothing to remap. It
        // must declare neither a path nor a checksum, so this cannot be used
        // to smuggle an unvalidated asset past the checks below.
        if (record['missing'] == 'true' &&
            record['backupRelativePath'] == null &&
            record['sha256'] == null) {
          assets.add(record);
          continue;
        }
        final relative = record['backupRelativePath'];
        final expected = record['sha256'];
        final reference = record['reference'];
        if (relative == null ||
            expected == null ||
            reference == null ||
            !CourseMediaStore.isReference(reference) ||
            CourseMediaStore.digestOf(reference) != expected ||
            !RegExp(r'^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$').hasMatch(relative)) {
          throw const FormatException(
            'The course backup asset path is unsafe.',
          );
        }
        final asset = File(
          '${manifestFile.parent.path}${Platform.pathSeparator}${relative.replaceAll('/', Platform.pathSeparator)}',
        );
        if (!await asset.exists() ||
            sha256.convert(await asset.readAsBytes()).toString() != expected) {
          throw const FormatException(
            'A course backup asset failed integrity validation.',
          );
        }
        assets.add(record);
      }
    }
    // Course media references are content-addressed, so the Course needs no
    // path remapping; [reinstateMedia] puts the files back on restore.
    return CourseBackupRecord(
      manifestFile: manifestFile,
      course: await _publisherVerification.assessStored(course),
      checksum: checksum,
      backedUpAtUtc: backedUpAt,
      reason: '${manifest['reason'] ?? ''}',
      assets: assets,
    );
  }

  /// Puts every media file [record] saved back into its Course's folder, so a
  /// restored version shows its images and plays its recordings. Each copy is
  /// verified against its reference. Recorded gaps have nothing to restore.
  Future<void> reinstateMedia(CourseBackupRecord record) async {
    for (final asset in record.assets) {
      final relative = asset['backupRelativePath'];
      final reference = asset['reference'];
      if (relative == null || reference == null) continue;
      if (await _media.existingFile(record.course.courseId, reference) !=
          null) {
        continue;
      }
      final source = File(
        '${record.manifestFile.parent.path}${Platform.pathSeparator}${relative.replaceAll('/', Platform.pathSeparator)}',
      );
      final stored = await _media.addBytes(
        record.course.courseId,
        await source.readAsBytes(),
        CourseMediaStore.extensionOf(reference),
      );
      if (stored != reference) {
        throw StateError('Restored course media does not match its reference.');
      }
    }
  }

  /// The verified backups of [courseId], newest first. A file in its folder
  /// that is not a readable backup of this Course stops the listing with a
  /// [FormatException] naming it, unless [skipped] is given: people can reach
  /// the Backups folder, so Version History lists what it can read and adds
  /// every other file's name to [skipped], leaving the file unchanged.
  Future<List<CourseBackupRecord>> listBackups(
    String courseId, {
    List<String>? skipped,
  }) async {
    final directory = await courseBackupDirectory(courseId);
    if (!await directory.exists()) return const [];
    final records = <CourseBackupRecord>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File || !entity.path.toLowerCase().endsWith('.json')) {
        continue;
      }
      try {
        records.add(await loadBackup(entity, expectedCourseId: courseId));
      } catch (error) {
        if (skipped != null) {
          skipped.add(_nameOf(entity));
          continue;
        }
        throw FormatException(
          'Course Backup history contains an unreadable entry at ${entity.path}. The file was preserved. $error',
        );
      }
    }
    records.sort((a, b) => b.backedUpAtUtc.compareTo(a.backedUpAtUtc));
    return records;
  }

  /// History preserves publisher sources; authenticity is re-evaluated on read.
  /// [skipped] works as for [listBackups].
  Future<List<CourseBackupRecord>> listOfficialBackups(
    String courseId, {
    List<String>? skipped,
  }) async {
    final directory = await courseBackupDirectory(courseId);
    if (!await directory.exists()) return const [];
    final records = <CourseBackupRecord>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File || !entity.path.toLowerCase().endsWith('.json')) {
        continue;
      }
      try {
        final record = await loadBackup(entity, expectedCourseId: courseId);
        final source = record.course;
        if (!source.originType.isOfficial ||
            officialContentChecksum(source) != source.officialChecksum) {
          throw const FormatException(
            'Official history source integrity is invalid.',
          );
        }
        records.add(record);
      } catch (error) {
        if (skipped != null) {
          skipped.add(_nameOf(entity));
          continue;
        }
        throw FormatException(
          'Official Course history contains an unreadable entry at ${entity.path}. The file was preserved. $error',
        );
      }
    }
    records.sort((a, b) => b.backedUpAtUtc.compareTo(a.backedUpAtUtc));
    return records;
  }

  Future<bool> openBackupFolder(Course course) async {
    final directory = await courseBackupDirectory(
      course.courseId,
      create: true,
      pair: CourseStorageNames.pairOfCourse(course),
    );
    final uri = Uri.directory(
      directory.absolute.path,
      windows: Platform.isWindows,
    );
    return _uriLauncher?.call(uri) ?? launchUrl(uri);
  }
}
