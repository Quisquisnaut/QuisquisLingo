import 'dart:convert';
import 'course_flag_service.dart';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../models/course_models.dart';
import 'file_dialog_service.dart';

/// The exact bytes and base file name a course export produces, shared by the
/// fixed-folder Export and the dialog-based Save to…
class CourseExportPayload {
  const CourseExportPayload(this.bytes, this.baseName);

  final Uint8List bytes;

  /// File name without extension, e.g. `quisquislingo_my_course`.
  final String baseName;

  String get fileName => '$baseName.json';
}

class CustomCourseTransferService {
  CustomCourseTransferService({
    Future<Directory> Function()? directory,
    Future<Directory> Function()? importDirectory,
    Future<Directory> Function()? mergeDirectory,
    FileDialogService? fileDialogs,
  }) : _directory = directory,
       _importDirectory = importDirectory ?? directory,
       _mergeDirectory = mergeDirectory ?? directory,
       _fileDialogs = fileDialogs ?? FileDialogService();

  static const int maxJsonBytes = 10 * 1024 * 1024;

  // Memory guard for the dialog path only. Files above maxJsonBytes but below
  // this reach the ordinary validator, so they get the standard size message.
  static const int _dialogReadCap = 64 * 1024 * 1024;
  final FileDialogService _fileDialogs;

  /// False when the system dialog is unsupported; hide Save to… / Open from….
  bool get fileDialogsAvailable => _fileDialogs.isAvailable;
  final Future<Directory> Function()? _directory;
  final Future<Directory> Function()? _importDirectory;
  final Future<Directory> Function()? _mergeDirectory;

  Future<Directory> transferDirectory() async {
    final testDirectory = _directory;
    if (testDirectory != null) {
      final directory = await testDirectory();
      await directory.create(recursive: true);
      return directory;
    }
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      '${documents.path}${Platform.pathSeparator}QuisquisLingo${Platform.pathSeparator}Exports',
    );
    await directory.create(recursive: true);
    return directory;
  }

  Future<String> importFilePath() async {
    final directory = await importDirectory();
    return '${directory.path}${Platform.pathSeparator}import.json';
  }

  Future<Directory> importDirectory() async {
    final injected = _importDirectory;
    final directory = injected != null
        ? await injected()
        : Directory(
            '${(await getApplicationDocumentsDirectory()).path}${Platform.pathSeparator}QuisquisLingo${Platform.pathSeparator}Imports',
          );
    await directory.create(recursive: true);
    return directory;
  }

  Future<String> mergeFilePath() async {
    final directory = await mergeDirectory();
    return '${directory.path}${Platform.pathSeparator}merge.json';
  }

  Future<Directory> mergeDirectory() async {
    final injected = _mergeDirectory;
    final directory = injected != null
        ? await injected()
        : Directory(
            '${(await getApplicationDocumentsDirectory()).path}${Platform.pathSeparator}QuisquisLingo${Platform.pathSeparator}Merges',
          );
    await directory.create(recursive: true);
    return directory;
  }

  Future<Course> importCourse() async =>
      _readCourse(await importFilePath(), 'import.json');

  Future<Course> mergeCourse() async =>
      _readCourse(await mergeFilePath(), 'merge.json');

  Future<Course> _readCourse(String path, String fileName) async {
    final file = File(path);
    if (!await file.exists()) {
      throw FormatException(
        'No $fileName found. Copy the course file to $path, then try again.',
      );
    }
    if (await file.length() > maxJsonBytes) {
      throw const FormatException(
        'Course JSON exceeds the 10 MB safety limit.',
      );
    }

    return courseFromBytes(await file.readAsBytes(), fileName);
  }

  /// The one authoritative course-file validator. Both the fixed-folder
  /// import and Open from… end here.
  Future<Course> courseFromBytes(Uint8List bytes, String fileName) async {
    if (bytes.length > maxJsonBytes) {
      throw const FormatException(
        'Course JSON exceeds the 10 MB safety limit.',
      );
    }
    String raw;
    try {
      raw = utf8.decode(bytes);
    } catch (_) {
      throw FormatException('$fileName must be valid UTF-8 text.');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throw FormatException('$fileName is not valid JSON.');
    }
    if (decoded is! Map) {
      throw const FormatException('Course JSON root must be an object.');
    }

    final course = Course.fromJson(Map<String, dynamic>.from(decoded));
    await CourseFlagService().validateWorldFlag(course);

    if (course.flagImageBase64.length > 1024 * 1024) {
      throw const FormatException(
        'Embedded custom flag data exceed the 1 MB safety limit.',
      );
    }
    if (course.flagImageBase64.isNotEmpty) {
      try {
        base64Decode(course.flagImageBase64);
      } catch (_) {
        throw const FormatException(
          'Embedded custom flag data are not valid Base64.',
        );
      }
    }
    return course;
  }

  /// Builds the export bytes and base name. Shared by [exportCourse] and
  /// [exportCourseTo], so both write identical data.
  CourseExportPayload buildCourseExport(Course course) {
    final payload = const JsonEncoder.withIndent('  ').convert(course.toJson());
    final bytes = Uint8List.fromList(utf8.encode(payload));
    if (bytes.length > maxJsonBytes) {
      throw const FormatException(
        'Course JSON exceeds the 10 MB export safety limit.',
      );
    }
    final safe = course.title
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return CourseExportPayload(
      bytes,
      'quisquislingo_${safe.isEmpty ? 'custom_course' : safe}',
    );
  }

  /// Save to…: the same export as [exportCourse], written wherever the user
  /// chooses in the system dialog. Additional to, not a replacement for, the
  /// fixed Exports folder.
  Future<FileDialogResult> exportCourseTo(Course course) {
    final payload = buildCourseExport(course);
    return _fileDialogs.saveBytes(
      bytes: payload.bytes,
      suggestedName: payload.fileName,
      extensions: const ['json'],
      artifact: 'course',
    );
  }

  /// Open from…: lets the user pick a course file in the system dialog. The
  /// outcome carries the validated [Course] only when the file passed the same
  /// validation as an ordinary import.
  Future<({FileDialogResult dialog, Course? course})>
  importCourseFromDialog() => _courseFromDialog('course');

  /// Merge From…: the same pick-and-validate as [importCourseFromDialog], for
  /// the second Course of a merge instead of `Merges/merge.json`.
  Future<({FileDialogResult dialog, Course? course})> mergeCourseFromDialog() =>
      _courseFromDialog('course-merge');

  Future<({FileDialogResult dialog, Course? course})> _courseFromDialog(
    String artifact,
  ) async {
    final result = await _fileDialogs.openBytes(
      extensions: const ['json'],
      maxBytes: _dialogReadCap,
      artifact: artifact,
    );
    if (result.outcome != FileDialogOutcome.opened) {
      return (dialog: result, course: null);
    }
    final course = await courseFromBytes(result.bytes!, result.displayName!);
    return (dialog: result, course: course);
  }

  Future<String> exportCourse(Course course) async {
    final export = buildCourseExport(course);
    final bytes = export.bytes;
    final baseName = export.baseName;

    // Keep course exports independent from desktop file-picker/portal support.
    // They always go to one predictable per-user folder. (Save to… is a
    // separate, additional route: see exportCourseTo.)
    final exportDirectory = await transferDirectory();

    var output = File(
      '${exportDirectory.path}${Platform.pathSeparator}$baseName.json',
    );
    var suffix = 2;
    while (await output.exists()) {
      output = File(
        '${exportDirectory.path}${Platform.pathSeparator}${baseName}_$suffix.json',
      );
      suffix += 1;
    }

    await output.writeAsBytes(bytes, flush: true);
    return output.path;
  }
}
