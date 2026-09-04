import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../models/course_models.dart';

class CustomCourseTransferService {
  CustomCourseTransferService({Future<Directory> Function()? directory})
    : _directory = directory;

  static const int maxJsonBytes = 10 * 1024 * 1024;
  final Future<Directory> Function()? _directory;

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
    final directory = await transferDirectory();
    return '${directory.path}${Platform.pathSeparator}import.json';
  }

  Future<Course> importCourse() async {
    final path = await importFilePath();
    final file = File(path);
    if (!await file.exists()) {
      throw FormatException(
        'No import.json found. Copy the course file to $path, then press Import course JSON again.',
      );
    }
    if (await file.length() > maxJsonBytes) {
      throw const FormatException(
        'Course JSON exceeds the 10 MB safety limit.',
      );
    }

    final Uint8List bytes = await file.readAsBytes();
    String raw;
    try {
      raw = utf8.decode(bytes);
    } catch (_) {
      throw const FormatException('import.json must be valid UTF-8 text.');
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      throw const FormatException('import.json is not valid JSON.');
    }
    if (decoded is! Map) {
      throw const FormatException('Course JSON root must be an object.');
    }

    final course = Course.fromJson(Map<String, dynamic>.from(decoded));

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

  Future<String> exportCourse(Course course) async {
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
    final baseName = 'quisquislingo_${safe.isEmpty ? 'custom_course' : safe}';

    // Keep course exports independent from desktop file-picker/portal support.
    // They always go to one predictable per-user folder.
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
