import 'dart:convert';
import 'dart:io';

import 'package:quisquislingo_app/services/storage/course_storage_names.dart';

/// Developer tool, run once with QQL closed.
///
/// Build 255 Revision 4 renamed QQL's private folders and gave every
/// per-Course name the Course's language pair (docs/255_STORAGE_PLAN.md). The
/// app reads only the new names, so this tool moves what an earlier version
/// stored:
///
/// - each stored Course from `qql_courses_v2/custom` and
///   `qql_courses_v2/external_official` to
///   `QQL_Courses/Custom` or `QQL_Courses/Publisher` as `QQL_<pair>_<ID>.json`;
/// - each Course media folder from `quisquislingo_course_media/course_<hash>`
///   to `QQL_CourseMedia/QQL_<pair>_<hash>`, or `QQL_<hash>` when no stored
///   Course names it;
/// - each Course's backups from `qql_course_backups_v11/<ID>` and, as a
///   desktop kept them before Revision 3,
///   `Documents/QuisquisLingo/Exports/Course Backups v11/<ID>`, to
///   `QQL_CourseBackups/QQL_bkp_<pair>_<ID>`. The saved versions keep their
///   names, which their manifests refer to.
///
/// It never overwrites or deletes. A file whose new place is taken, a file it
/// cannot read and a Course already stored under the new names stay where
/// they are and are reported. A file on another drive is copied and the
/// earlier copy stays. Shared images and Image Banks are not moved: their
/// records hold full paths, and they keep working where they are.
Future<void> main(List<String> args) async {
  try {
    final options = MoveStorageOptions.parse(
      args,
      environment: Platform.environment,
      windows: Platform.isWindows,
    );
    stdout.writeln('QQL private storage: ${options.support}');
    if (options.documents != null) {
      stdout.writeln('Documents: ${options.documents}');
    }
    final report = await movePrivateStorage(
      support: Directory(options.support),
      documents: options.documents == null
          ? null
          : Directory(options.documents!),
      dryRun: options.dryRun,
    );
    report.lines.forEach(stdout.writeln);
    stdout.writeln(report.summary);
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = 1;
  }
}

class MoveStorageOptions {
  MoveStorageOptions(this.support, this.documents, this.dryRun);

  final String support;
  final String? documents;
  final bool dryRun;

  static const usage =
      'Usage: dart run tools/move_private_storage_255.dart '
      '[--support DIR] [--documents DIR] [--dry-run]\n'
      'Close QQL first. On Windows --support defaults to '
      r'%APPDATA%\QuisquisLingo\quisquislingo_app and --documents to '
      r'%USERPROFILE%\Documents; on other systems pass --support.';

  static MoveStorageOptions parse(
    List<String> args, {
    required Map<String, String> environment,
    required bool windows,
  }) {
    String? support;
    String? documents;
    var dryRun = false;
    for (var i = 0; i < args.length; i++) {
      switch (args[i]) {
        case '--support':
          if (i + 1 >= args.length) throw const FormatException(usage);
          support = args[++i];
        case '--documents':
          if (i + 1 >= args.length) throw const FormatException(usage);
          documents = args[++i];
        case '--dry-run':
          dryRun = true;
        default:
          throw const FormatException(usage);
      }
    }
    if (windows) {
      final appData = environment['APPDATA'];
      final profile = environment['USERPROFILE'];
      if (support == null && appData != null) {
        support = '$appData\\QuisquisLingo\\quisquislingo_app';
      }
      if (documents == null && profile != null) {
        documents = '$profile\\Documents';
      }
    }
    if (support == null) throw const FormatException(usage);
    return MoveStorageOptions(support, documents, dryRun);
  }
}

/// What [movePrivateStorage] did, or would do in a dry run.
class PrivateStorageMoveReport {
  PrivateStorageMoveReport({required this.dryRun});

  final bool dryRun;
  final List<String> lines = [];

  /// Files moved (or that would be moved), copied, and left in place.
  int moved = 0;
  int copied = 0;
  int kept = 0;

  String get summary => dryRun
      ? 'Dry run: $moved files would be moved and $kept would stay where '
            'they are. Nothing was changed.'
      : 'Moved $moved files, copied $copied and left $kept where they were. '
            'The earlier folders stay; delete them yourself once QQL shows '
            'your Courses, their media and Version History.';
}

/// Moves the Courses, Course media and Course Backups an earlier version
/// stored in [support] (and, for backups made before Revision 3, in
/// [documents]) to Revision 4's names. See the library comment.
Future<PrivateStorageMoveReport> movePrivateStorage({
  required Directory support,
  Directory? documents,
  bool dryRun = false,
}) async {
  final report = PrivateStorageMoveReport(dryRun: dryRun);
  final mover = _Mover(report, dryRun, [
    support.path,
    if (documents != null) documents.path,
  ]);
  // Course ID → language pair, and ID hash → Course ID, for media and backups.
  final pairs = <String, String>{};
  final ids = <String, String>{};
  void remember(String id, String pair) {
    pairs.putIfAbsent(id, () => pair);
    ids.putIfAbsent(CourseStorageNames.hashOf(id), () => id);
  }

  // ---- Stored Courses. One already stored under the new names stays put,
  // because two files claiming one Course would make the store refuse both.
  const kinds = [('custom', 'Custom'), ('external_official', 'Publisher')];
  final coursesRoot = _join(support.path, ['QQL_Courses']);
  final stored = <String, Set<String>>{};
  for (final (_, current) in kinds) {
    final present = stored[current] = <String>{};
    for (final file in await _jsonFiles(_join(coursesRoot, [current]))) {
      final record = await _readObject(file);
      final id = record?['courseId'];
      if (id is String && id.trim().isNotEmpty) {
        present.add(id);
        remember(id, _pairOfRecord(record!));
      }
    }
  }
  for (final (earlier, current) in kinds) {
    final source = _join(support.path, ['qql_courses_v2', earlier]);
    for (final file in await _jsonFiles(source)) {
      final record = await _readObject(file);
      final id = record?['courseId'];
      if (id is! String || id.trim().isEmpty) {
        mover.keep(file.path, 'it cannot be read as a stored Course');
        continue;
      }
      final pair = _pairOfRecord(record!);
      remember(id, pair);
      if (!stored[current]!.add(id)) {
        mover.keep(file.path, 'the Course $id is already stored');
        continue;
      }
      final String name;
      try {
        name = CourseStorageNames.courseFileName(id, pair);
      } on FormatException {
        mover.keep(file.path, 'the Course ID $id cannot name a file');
        continue;
      }
      await mover.moveFile(file, File(_join(coursesRoot, [current, name])));
    }
  }

  // ---- Course media: content-named files, so a file already in the new
  // folder is the same file.
  final mediaRoot = _join(support.path, ['QQL_CourseMedia']);
  final earlierMedia = _join(support.path, ['quisquislingo_course_media']);
  for (final folder in await _folders(earlierMedia)) {
    final hash = RegExp(
      r'^course_([0-9a-f]{64})$',
    ).firstMatch(_nameOf(folder))?.group(1);
    if (hash == null) {
      mover.keep(folder, 'it is not a Course media folder');
      continue;
    }
    final id = ids[hash];
    final target =
        await _mediaFolderFor(mediaRoot, hash) ??
        _join(mediaRoot, [
          CourseStorageNames.mediaFolderNameOfHash(
            hash,
            pair: id == null ? null : pairs[id],
          ),
        ]);
    await mover.moveContents(folder, target);
  }

  // ---- Course Backups, from the private folder of Revision 3 and the
  // Documents folder a desktop used before.
  final backupRoot = _join(support.path, ['QQL_CourseBackups']);
  final backupSources = [
    _join(support.path, ['qql_course_backups_v11']),
    if (documents != null)
      _join(documents.path, [
        'QuisquisLingo',
        'Exports',
        'Course Backups v11',
      ]),
  ];
  for (final source in backupSources) {
    for (final folder in await _folders(source)) {
      String? id;
      Map<Object?, Object?>? newest;
      var newestAt = '';
      for (final manifest in await _jsonFiles(folder)) {
        final decoded = await _readObject(manifest);
        final courseId = decoded?['courseId'];
        if (courseId is! String || courseId.trim().isEmpty) continue;
        id ??= courseId;
        final at = decoded!['backedUpAtUtc'];
        final course = decoded['course'];
        if (courseId == id &&
            at is String &&
            course is Map &&
            at.compareTo(newestAt) > 0) {
          newestAt = at;
          newest = course;
        }
      }
      // The earlier folder was named by the sanitized Course ID.
      id ??= _nameOf(folder);
      final pair =
          pairs[id] ??
          (newest == null
              ? _unknownPair
              : CourseStorageNames.pairOfJson(newest));
      final String name;
      try {
        name = CourseStorageNames.backupFolderName(id, pair);
      } on FormatException {
        mover.keep(folder, 'the Course ID $id cannot name a folder');
        continue;
      }
      final target =
          await _backupFolderFor(backupRoot, CourseStorageNames.idPart(id)) ??
          _join(backupRoot, [name]);
      await mover.moveContents(folder, target);
    }
  }
  return report;
}

const _unknownPair =
    '${CourseStorageNames.unknownLanguage}_${CourseStorageNames.unknownLanguage}';

/// The pair of a stored record: `course` for a custom Course, `source` for a
/// Publisher Course.
String _pairOfRecord(Map<String, dynamic> record) {
  final entry = record['entry'];
  if (entry is Map) {
    final course = entry['course'] ?? entry['source'];
    if (course is Map) return CourseStorageNames.pairOfJson(course);
  }
  return _unknownPair;
}

class _Mover {
  _Mover(this.report, this.dryRun, this.roots);

  final PrivateStorageMoveReport report;
  final bool dryRun;
  final List<String> roots;

  String _shown(String path) {
    for (final root in roots) {
      if (path.startsWith(root) && path.length > root.length) {
        return path.substring(root.length + 1);
      }
    }
    return path;
  }

  void keep(String path, String reason) {
    report.kept++;
    report.lines.add('Left in place: ${_shown(path)} ($reason).');
  }

  Future<void> moveFile(File file, File target) async {
    if (await _move(file, target)) {
      report.lines.add(
        '${dryRun ? 'Would move' : 'Moved'}: ${_shown(file.path)} → '
        '${_shown(target.path)}',
      );
    }
  }

  /// Moves every file below [folder] to the same place below [target].
  Future<void> moveContents(String folder, String target) async {
    final before = report.moved + report.copied;
    await for (final entity in Directory(
      folder,
    ).list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final relative = entity.path.substring(folder.length + 1);
      await _move(
        entity,
        File('$target${Platform.pathSeparator}$relative'),
        quiet: true,
      );
    }
    final count = report.moved + report.copied - before;
    if (count > 0) {
      report.lines.add(
        '${dryRun ? 'Would move' : 'Moved'} $count '
        '${count == 1 ? 'file' : 'files'}: ${_shown(folder)} → '
        '${_shown(target)}',
      );
    }
  }

  /// True when [file] was moved or copied to [target], which must be free.
  Future<bool> _move(File file, File target, {bool quiet = false}) async {
    if (await target.exists()) {
      keep(file.path, '${_shown(target.path)} already exists');
      return false;
    }
    if (dryRun) {
      report.moved++;
      return true;
    }
    await target.parent.create(recursive: true);
    try {
      await file.rename(target.path);
      report.moved++;
      return true;
    } on FileSystemException {
      // Another drive: copy, check, and leave the earlier file.
    }
    try {
      await file.copy(target.path);
      if (!_sameBytes(await file.readAsBytes(), await target.readAsBytes())) {
        await target.delete();
        keep(file.path, 'the copy could not be checked');
        return false;
      }
      report.copied++;
      if (!quiet) {
        report.lines.add(
          'Copied (the earlier file stays): ${_shown(file.path)}',
        );
      }
      return true;
    } on FileSystemException catch (error) {
      keep(file.path, 'it could not be moved: ${error.message}');
      return false;
    }
  }

  static bool _sameBytes(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

String _join(String root, List<String> parts) =>
    [root, ...parts].join(Platform.pathSeparator);

String _nameOf(String path) =>
    path.split(RegExp(r'[\\/]')).lastWhere((part) => part.isNotEmpty);

Future<List<File>> _jsonFiles(String folder) async {
  final directory = Directory(folder);
  if (!await directory.exists()) return const [];
  return [
    await for (final entity in directory.list(followLinks: false))
      if (entity is File && entity.path.toLowerCase().endsWith('.json')) entity,
  ]..sort((a, b) => a.path.compareTo(b.path));
}

Future<List<String>> _folders(String folder) async {
  final directory = Directory(folder);
  if (!await directory.exists()) return const [];
  return [
    await for (final entity in directory.list(followLinks: false))
      if (entity is Directory) entity.path,
  ]..sort();
}

Future<Map<String, dynamic>?> _readObject(File file) async {
  try {
    final decoded = jsonDecode(await file.readAsString());
    return decoded is Map ? Map<String, dynamic>.from(decoded) : null;
  } catch (_) {
    return null;
  }
}

/// A media folder already made for [hash] under the new names, preferring
/// one with a language pair.
Future<String?> _mediaFolderFor(String root, String hash) async {
  String? neutral;
  for (final folder in await _folders(root)) {
    final name = _nameOf(folder);
    if (CourseStorageNames.hashOfMediaFolder(name) != hash) continue;
    if (name != CourseStorageNames.mediaFolderNameOfHash(hash)) return folder;
    neutral = folder;
  }
  return neutral;
}

/// A backup folder already made for [idPart] under the new names.
Future<String?> _backupFolderFor(String root, String idPart) async {
  for (final folder in await _folders(root)) {
    final found = CourseStorageNames.idPartOfBackupFolder(_nameOf(folder));
    if (found == null) continue;
    if (Platform.isWindows
        ? found.toLowerCase() == idPart.toLowerCase()
        : found == idPart) {
      return folder;
    }
  }
  return null;
}
