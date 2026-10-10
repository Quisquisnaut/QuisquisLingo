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
import 'custom_course_transfer_service.dart';
import 'import/image_validator.dart';
import 'import/json_limits.dart';
import 'import/mp3_validator.dart';

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

  // Course Model clean cuts: `Course Backups v9` holds v9/v10 Courses and
  // Build 255's manifests in the same Backups folder hold v11 Courses. Both
  // stay untouched and unread; Version History names a v11 manifest as
  // unreadable (Build 256 Revision 1), so an old backup cannot block it.
  static const backupFormat = 'QuisquisLingo Course Backup v12';
  static const earlierBackupFormat = 'QuisquisLingo Course Backup v11';

  /// Build 270 Revision 9 (owner decision of 10 October 2026): the folder,
  /// beside a Course's backups, holding each picture and recording once for
  /// all its saved versions. Earlier backups keep their own `…_assets`
  /// folders, which stay as they are.
  static const sharedMediaFolderName = 'QQL_media';

  /// Build 270 Revision 3: a manifest holds one Course (at most 10 MB) with
  /// its indented copy and a few fields; anything larger is not a backup.
  static const maxManifestBytes = 16 * 1024 * 1024;

  /// An asset's place beside its manifest: one folder and one file, neither
  /// starting with a dot (Build 270 Revision 3: `../x.png` was accepted and
  /// read from the folder above).
  static final RegExp _assetPath = RegExp(
    r'^[A-Za-z0-9_-][A-Za-z0-9._-]*/[A-Za-z0-9_-][A-Za-z0-9._-]*$',
  );

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
      final target = Directory('${root.path}${Platform.pathSeparator}$wanted');
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

  static bool officialContentChecksumMatches(Course course) =>
      CourseChecksums.officialMatches(course);

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

  /// Whether [file] exists and holds the bytes of [digest]; false when it
  /// cannot be read.
  static Future<bool> _holds(File file, String digest) async {
    try {
      return await file.exists() &&
          sha256.convert(await file.readAsBytes()).toString() == digest;
    } on FileSystemException {
      return false;
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
        '${directory.path}${Platform.pathSeparator}$sharedMediaFolderName',
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
        // Kept once: an earlier version already holds the same bytes. A file
        // this installation may not read or replace (Android keeps a file
        // with the installation that wrote it) goes to a folder of this
        // version's own, as before Build 270 Revision 9.
        var folder = assetsDirectory;
        var copy = target;
        if (!await _holds(target, digest)) {
          try {
            await _write(target, bytes);
          } on FileSystemException {
            folder = Directory(
              '${directory.path}${Platform.pathSeparator}${manifest.uri.pathSegments.last.replaceAll('.json', '')}_assets',
            );
            await folder.create(recursive: true);
            copy = File('${folder.path}${Platform.pathSeparator}$backupName');
            await _write(copy, bytes);
          }
          if (!await _holds(copy, digest)) {
            throw StateError(
              'A course-owned backup asset could not be verified.',
            );
          }
        }
        assetRecords.add({
          'reference': reference,
          'backupRelativePath':
              '${folder.path.substring(directory.path.length + 1)}/$backupName',
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
    // Build 270 Revision 3: the Backups folder is one people can reach, so a
    // backup is read with the limits of a Course import.
    if (await manifestFile.length() > maxManifestBytes) {
      throw const FormatException(
        'The course backup is larger than a Course can be.',
      );
    }
    final decoded = JsonLimits.imports.decode(
      utf8.decode(await manifestFile.readAsBytes(), allowMalformed: true),
      what: 'Course backup',
      invalidMessage: 'The selected file is not a supported course backup.',
    );
    if (decoded is Map && decoded['format'] == earlierBackupFormat) {
      // Build 256 Revision 1: Build 255's v11 backups stay in the same
      // folder, unread; Version History names them as unreadable.
      throw const FormatException(
        'This is a Course Backup of Course Model v11 (format 11), which this version of QuisquisLingo cannot read. The file was preserved; convert it with tools/convert_course_to_v12.dart if you need it.',
      );
    }
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
    CourseShapeLimits.check(courseJson);
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
            !_assetPath.hasMatch(relative)) {
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

  /// The readable backups of [courseId] beyond the newest [keep], oldest
  /// last (Build 270 Revision 9). Files QQL cannot read are never counted,
  /// so they are never offered for deletion.
  Future<List<CourseBackupRecord>> olderThanNewest(
    String courseId,
    int keep,
  ) async {
    final records = await listBackups(courseId, skipped: <String>[]);
    return records.length <= keep ? const [] : records.sublist(keep);
  }

  /// Deletes [records] (backups of [courseId] the learner agreed to delete,
  /// Build 270 Revision 9): each manifest and the media folder of its own
  /// that earlier builds wrote beside it, then the shared media no backup
  /// left names ([removeOrphanMedia]). Returns how many backups went.
  Future<int> deleteBackups(
    String courseId,
    List<CourseBackupRecord> records,
  ) async {
    final directory = await courseBackupDirectory(courseId);
    var deleted = 0;
    for (final record in records) {
      final manifest = record.manifestFile;
      _requireChildPath(directory, manifest);
      final name = manifest.uri.pathSegments.last;
      final own = Directory(
        '${directory.path}${Platform.pathSeparator}'
        '${name.substring(0, name.length - '.json'.length)}_assets',
      );
      if (await manifest.exists()) await manifest.delete();
      if (await own.exists()) await own.delete(recursive: true);
      deleted++;
    }
    await removeOrphanMedia(directory);
    return deleted;
  }

  /// Removes the files of [directory]'s shared media folder that no backup
  /// manifest there names any more (Build 270 Revision 9, owner decision:
  /// only after older backups are deleted, the one time QQL leaves media
  /// unused; files left by a manifest deleted by hand or a backup that
  /// failed halfway go too). Nothing is removed when a manifest cannot be
  /// read: its media might be among them. Never throws: the backups the
  /// learner deleted stay deleted.
  Future<int> removeOrphanMedia(Directory directory) async {
    try {
      final shared = Directory(
        '${directory.path}${Platform.pathSeparator}$sharedMediaFolderName',
      );
      if (!await shared.exists()) return 0;
      final named = <String>{};
      await for (final entity in directory.list(followLinks: false)) {
        if (entity is! File || !entity.path.toLowerCase().endsWith('.json')) {
          continue;
        }
        if (await entity.length() > maxManifestBytes) return 0;
        final decoded = jsonDecode(await entity.readAsString());
        if (decoded is! Map) return 0;
        final assets = decoded['assets'];
        if (assets is List) {
          for (final asset in assets.whereType<Map>()) {
            final relative = asset['backupRelativePath'];
            if (relative is String &&
                relative.startsWith('$sharedMediaFolderName/')) {
              named.add(relative.substring(sharedMediaFolderName.length + 1));
            }
          }
        }
      }
      var removed = 0;
      await for (final entity in shared.list(followLinks: false)) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        if (named.contains(name)) continue;
        await entity.delete();
        removed++;
      }
      return removed;
    } catch (_) {
      return 0;
    }
  }

  /// Puts every media file [record] saved back into its Course's folder, so a
  /// restored version shows its images and plays its recordings. Each copy is
  /// verified against its reference. Recorded gaps have nothing to restore.
  Future<void> reinstateMedia(CourseBackupRecord record) async {
    // Build 270 Revision 3: what a restore brings back passes the checks of
    // a Course import (a backup can be put in the Backups folder by hand).
    await CustomCourseTransferService.validateEmbeddedContent(record.course);
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
      final bytes = await source.readAsBytes();
      final cover = reference == record.course.coverImage;
      if (CourseMediaStore.isAudioReference(reference)) {
        await Mp3Validator.validate(bytes);
      } else {
        await ImageValidator.validate(
          bytes,
          cover ? ImageProfile.courseCover : ImageProfile.exerciseImage,
        );
      }
      final stored = await _media.addBytes(
        record.course.courseId,
        bytes,
        CourseMediaStore.extensionOf(reference),
        cover: cover,
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
            !officialContentChecksumMatches(source)) {
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
