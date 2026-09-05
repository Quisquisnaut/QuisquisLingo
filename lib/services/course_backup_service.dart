import 'dart:convert';
import 'dart:io';
import 'dart:collection';

import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/course_models.dart';

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
/// Backups live outside application storage under the existing resolved
/// Documents/QuisquisLingo/Exports tree. A manifest contains the complete v6
/// course plus SHA-256 integrity data; local course-owned file assets are
/// copied alongside it when they exist.
class CourseBackupService {
  CourseBackupService({
    Future<Directory> Function()? documentsDirectoryProvider,
    Future<void> Function(File file, List<int> bytes)? fileWriter,
    Future<bool> Function(Uri uri)? uriLauncher,
  }) : _documentsDirectoryProvider =
           documentsDirectoryProvider ?? getApplicationDocumentsDirectory,
       _fileWriter = fileWriter,
       _uriLauncher = uriLauncher;

  static const backupFormat = 'QuisquisLingo Course Backup v1';
  final Future<Directory> Function() _documentsDirectoryProvider;
  final Future<void> Function(File file, List<int> bytes)? _fileWriter;
  final Future<bool> Function(Uri uri)? _uriLauncher;

  Future<Directory> backupRoot({bool create = false}) async {
    final documents = await _documentsDirectoryProvider();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}QuisquisLingo'
      '${Platform.pathSeparator}Exports${Platform.pathSeparator}Course Backups',
    );
    if (create) await directory.create(recursive: true);
    return directory;
  }

  static String sanitizedCourseId(String courseId) {
    final clean = courseId
        .trim()
        .replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_')
        .replaceAll(RegExp(r'^\.+|\.+$'), '');
    if (clean.isEmpty || clean == '.' || clean == '..') {
      throw const FormatException('Course ID cannot form a safe backup path.');
    }
    return clean;
  }

  Future<Directory> courseBackupDirectory(
    String courseId, {
    bool create = false,
  }) async {
    final root = await backupRoot(create: create);
    final directory = Directory(
      '${root.path}${Platform.pathSeparator}${sanitizedCourseId(courseId)}',
    );
    final rootPath = root.absolute.path;
    final childPath = directory.absolute.path;
    if (!childPath.startsWith('$rootPath${Platform.pathSeparator}')) {
      throw const FormatException('Unsafe Course Backup path.');
    }
    if (create) await directory.create(recursive: true);
    return directory;
  }

  static String courseChecksum(Course course) =>
      sha256.convert(utf8.encode(_canonicalJson(course.toJson()))).toString();

  /// Publisher checksum of the immutable official payload. The digest and
  /// authenticity metadata are separate from the authenticated content.
  static String officialContentChecksum(Course course) {
    final value = Map<String, dynamic>.from(course.toJson())
      ..remove('officialChecksum')
      ..remove('publisherVerificationStatus')
      ..remove('publisherSignature');
    return sha256.convert(utf8.encode(_canonicalJson(value))).toString();
  }

  static String _canonicalJson(Object? value) =>
      jsonEncode(_canonicalValue(value));

  static SplayTreeMap<String, Object?> _canonicalMap(Map value) {
    final output = SplayTreeMap<String, Object?>();
    for (final entry in value.entries) {
      output[entry.key.toString()] = _canonicalValue(entry.value);
    }
    return output;
  }

  static Object? _canonicalValue(Object? value) => switch (value) {
    Map() => _canonicalMap(value),
    List() => value.map(_canonicalValue).toList(growable: false),
    _ => value,
  };

  static String _filenameStamp(DateTime value) => value
      .toUtc()
      .toIso8601String()
      .replaceAll(':', '')
      .replaceAll('-', '')
      .replaceAll('.', '');

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
    final directory = await courseBackupDirectory(
      course.courseId,
      create: true,
    );
    final version = course.originType.isOfficial
        ? 'official_${sanitizedCourseId(course.officialCourseVersion)}'
        : 'course_${course.courseVersion.trim().isEmpty ? '0' : course.courseVersion.trim()}';
    final base =
        '${sanitizedCourseId(course.courseId)}_${version}_${_filenameStamp(when)}';
    var manifest = File('${directory.path}${Platform.pathSeparator}$base.json');
    var suffix = 2;
    while (await manifest.exists()) {
      manifest = File(
        '${directory.path}${Platform.pathSeparator}${base}_$suffix.json',
      );
      suffix += 1;
    }

    final assetRecords = <Map<String, String>>[];
    final localPaths = <String>{
      for (final clip in course.audioLibrary)
        if (clip.filePath.trim().isNotEmpty &&
            !clip.filePath.startsWith('assets/'))
          clip.filePath,
    };
    if (localPaths.isNotEmpty) {
      final assetsDirectory = Directory(
        '${directory.path}${Platform.pathSeparator}${manifest.uri.pathSegments.last.replaceAll('.json', '')}_assets',
      );
      await assetsDirectory.create(recursive: true);
      var index = 0;
      for (final sourcePath in localPaths) {
        final source = File(sourcePath);
        if (!await source.exists()) {
          throw StateError(
            'Course-owned backup asset is missing: ${source.absolute.path}',
          );
        }
        final bytes = await source.readAsBytes();
        final sourceName = source.uri.pathSegments.isEmpty
            ? 'asset_$index'
            : source.uri.pathSegments.last;
        final safeName = sourceName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
        final backupName = '${index}_${safeName.isEmpty ? 'asset' : safeName}';
        final target = File(
          '${assetsDirectory.path}${Platform.pathSeparator}$backupName',
        );
        await _write(target, bytes);
        final targetBytes = await target.readAsBytes();
        if (sha256.convert(targetBytes) != sha256.convert(bytes)) {
          throw StateError(
            'A course-owned backup asset could not be verified.',
          );
        }
        assetRecords.add({
          'originalPath': source.absolute.path,
          'backupRelativePath':
              '${assetsDirectory.path.substring(directory.path.length + 1)}/$backupName',
          'sha256': sha256.convert(bytes).toString(),
        });
        index += 1;
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
      'authorProfileId': course.originType.isOfficial
          ? course.publisherId
          : course.lastModifiedByProfileId,
      'authorUsername': course.originType.isOfficial
          ? course.publisherName
          : course.lastModifiedByUsername,
      'versionCreatedAtUtc': course.originType.isOfficial
          ? course.officialReleaseDateUtc
          : course.lastModifiedAtUtc,
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
    final restoredAssetPaths = <String, String>{};
    final rawAssets = manifest['assets'];
    if (rawAssets is List) {
      for (final raw in rawAssets.whereType<Map>()) {
        final record = raw.map((key, value) => MapEntry('$key', '$value'));
        final relative = record['backupRelativePath'];
        final expected = record['sha256'];
        if (relative == null ||
            expected == null ||
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
        final originalPath = record['originalPath'];
        if (originalPath != null) {
          restoredAssetPaths[originalPath] = asset.absolute.path;
        }
      }
    }
    // Only custom restore remaps paths. Publisher payloads and their official
    // checksums must remain exact when history is inspected or exported.
    final restoredCourse =
        course.originType.isOfficial || restoredAssetPaths.isEmpty
        ? course
        : Course.fromJson({
            ...course.toJson(),
            'audioLibrary': course.audioLibrary
                .map(
                  (clip) => {
                    ...clip.toJson(),
                    'filePath':
                        restoredAssetPaths[clip.filePath] ?? clip.filePath,
                  },
                )
                .toList(),
          });
    return CourseBackupRecord(
      manifestFile: manifestFile,
      course: restoredCourse,
      checksum: checksum,
      backedUpAtUtc: backedUpAt,
      reason: '${manifest['reason'] ?? ''}',
      assets: assets,
    );
  }

  Future<List<CourseBackupRecord>> listBackups(String courseId) async {
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
        throw FormatException(
          'Course Backup history contains an unreadable entry at ${entity.path}. The file was preserved. $error',
        );
      }
    }
    records.sort((a, b) => b.backedUpAtUtc.compareTo(a.backedUpAtUtc));
    return records;
  }

  /// Official history contains publisher sources only. Build 225 local-variant
  /// manifests are left on disk, without loading or adapting their content.
  Future<List<CourseBackupRecord>> listOfficialBackups(String courseId) async {
    final directory = await courseBackupDirectory(courseId);
    if (!await directory.exists()) return const [];
    final records = <CourseBackupRecord>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File || !entity.path.toLowerCase().endsWith('.json')) {
        continue;
      }
      try {
        final decoded = jsonDecode(await entity.readAsString());
        final payload = decoded is Map ? decoded['course'] : null;
        if (payload is Map &&
            const {
              'baseCourseId',
              'basePublisherId',
              'baseOfficialCourseVersion',
              'baseOfficialChecksum',
              'localCourseVersion',
              'localAuthorProfileId',
              'localAuthorUsername',
              'localModifiedAtUtc',
              'localVersionNotes',
            }.any(payload.containsKey)) {
          continue;
        }
        if (payload is! Map) {
          throw const FormatException(
            'Official history has no course payload.',
          );
        }
        final source = Course.fromJson(Map<String, dynamic>.from(payload));
        if (!source.originType.isOfficial ||
            officialContentChecksum(source) != source.officialChecksum) {
          throw const FormatException(
            'Official history source integrity is invalid.',
          );
        }
        records.add(await loadBackup(entity, expectedCourseId: courseId));
      } catch (error) {
        throw FormatException(
          'Official Course history contains an unreadable entry at ${entity.path}. The file was preserved. $error',
        );
      }
    }
    records.sort((a, b) => b.backedUpAtUtc.compareTo(a.backedUpAtUtc));
    return records;
  }

  Future<bool> openBackupFolder(String courseId) async {
    final directory = await courseBackupDirectory(courseId, create: true);
    final uri = Uri.directory(
      directory.absolute.path,
      windows: Platform.isWindows,
    );
    return _uriLauncher?.call(uri) ?? launchUrl(uri);
  }
}
