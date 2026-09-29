import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_model_v12_converter.dart';

/// Developer tool: converts a Course Model v11 file to v12 (Build 256).
///
///     dart run tools/convert_course_to_v12.dart INPUT OUTPUT [--overwrite]
///
/// INPUT is a Course JSON file or a Course package ZIP (Quick Export or Save
/// as… from Build 255). A ZIP keeps its media and gets a manifest regenerated
/// from the converted Course. The input is never modified; OUTPUT must not
/// exist unless `--overwrite` is given. Everything the mapping could not
/// carry over exactly is printed. A Publisher Course loses its signature and
/// must be signed again with tools/sign_course.dart.
///
/// The application itself never converts: it reads v12 only and refuses
/// v11 files. Files older than v11 (v9, v10) must first be brought to v11
/// with Build 255's tools/convert_course_to_v11.dart, which lives in the
/// repository history and is no longer part of the tree.
Future<void> main(List<String> args) async {
  try {
    final options = _Options.parse(args);
    final output = File(options.output);
    if (!options.overwrite && await output.exists()) {
      throw FormatException(
        '${options.output} already exists. Pass --overwrite to replace it.',
      );
    }
    final bytes = await File(options.input).readAsBytes();
    final List<String> notes;
    if (_isZip(bytes)) {
      notes = await _convertPackage(bytes, output);
    } else {
      notes = await _convertJson(bytes, output);
    }
    stdout.writeln('Converted ${options.input} to v12: ${options.output}');
    for (final note in notes) {
      stdout.writeln('  note: $note');
    }
  } on FormatException catch (error) {
    // ArchiveException is a FormatException: an unreadable ZIP ends here too.
    stderr.writeln(error.message);
    exitCode = 1;
  }
}

bool _isZip(Uint8List bytes) =>
    bytes.length >= 4 &&
    bytes[0] == 0x50 &&
    bytes[1] == 0x4b &&
    (bytes[2] == 0x03 || bytes[2] == 0x05 || bytes[2] == 0x07);

Future<List<String>> _convertJson(Uint8List bytes, File output) async {
  final raw = utf8.decode(bytes);
  final result = _convertRaw(raw);
  // Keep the source layout: pretty-printed stays pretty, compact stays
  // compact, and a trailing newline is preserved.
  final pretty = raw.trimLeft().startsWith(RegExp(r'\{\s*\n'));
  final encoded = pretty
      ? const JsonEncoder.withIndent('  ').convert(result.json)
      : jsonEncode(result.json);
  final newline = raw.endsWith('\n') ? '\n' : '';
  await output.writeAsString('$encoded$newline', flush: true);
  return result.notes;
}

CourseConversionResult _convertRaw(String raw) {
  final decoded = jsonDecode(raw);
  if (decoded is! Map) {
    throw const FormatException('Course JSON root must be an object.');
  }
  return convertCourseJsonToV12(Map<String, dynamic>.from(decoded));
}

/// A Course package: `qql-course-package.json`, `course.json` and the
/// referenced media. This is a developer tool working on the developer's own
/// files, so it reads the archive with the plain decoder; the application's
/// import path keeps its bounded reader.
Future<List<String>> _convertPackage(Uint8List bytes, File output) async {
  const manifestName = 'qql-course-package.json';
  const courseName = 'course.json';
  final archive = ZipDecoder().decodeBytes(bytes, verify: true);
  // A package keeps its manifest and course.json at the root and its media
  // under `media/`; Build 246 also accepts one enclosing folder named like
  // the ZIP. The output is always written at the root.
  ArchiveFile? courseEntry;
  var wrapper = '';
  for (final entry in archive.files) {
    if (!entry.isFile) continue;
    final name = entry.name.replaceAll('\\', '/');
    if (name == courseName || name.endsWith('/$courseName')) {
      courseEntry = entry;
      wrapper = name.substring(0, name.length - courseName.length);
      break;
    }
  }
  if (courseEntry == null) {
    throw const FormatException(
      'This ZIP is not a Course package: course.json is missing.',
    );
  }
  final others = <({String name, ArchiveFile entry})>[];
  for (final entry in archive.files) {
    if (!entry.isFile || identical(entry, courseEntry)) continue;
    final name = entry.name.replaceAll('\\', '/');
    if (!name.startsWith(wrapper)) {
      throw FormatException(
        'Unexpected Course package entry outside its folder: ${entry.name}',
      );
    }
    final relative = name.substring(wrapper.length);
    if (relative == manifestName) continue;
    others.add((name: relative, entry: entry));
  }
  final result = _convertRaw(utf8.decode(courseEntry.content as List<int>));
  final course = Course.fromJson(result.json);
  final courseBytes = utf8.encode(jsonEncode(result.json));
  // The same manifest `CoursePackageService.build` writes: the key is absent
  // when there is no shared-image provenance.
  final sources = _sharedImageSources(course);
  final manifestBytes = utf8.encode(
    jsonEncode({
      'packageFormat': 1,
      if (sources.isNotEmpty) 'sharedImageSources': sources,
    }),
  );
  final out = Archive()
    ..addFile(
      ArchiveFile.bytes(manifestName, Uint8List.fromList(manifestBytes)),
    )
    ..addFile(ArchiveFile.bytes(courseName, Uint8List.fromList(courseBytes)));
  for (final other in others) {
    out.addFile(
      ArchiveFile.bytes(
        other.name,
        Uint8List.fromList(other.entry.content as List<int>),
      ),
    );
  }
  final encoded = ZipEncoder().encode(out);
  await output.writeAsBytes(encoded, flush: true);
  return result.notes;
}

/// The same entries `CoursePackageService` writes: every shared-image
/// provenance of an image element, once, in sorted order.
List<Map<String, dynamic>> _sharedImageSources(Course course) {
  final entries = <String, Map<String, dynamic>>{};
  for (final lesson in course.lessons) {
    for (final round in lesson.rounds) {
      for (final exercise in round.exercises) {
        for (final element in exercise.promptElements) {
          final source = element.sharedImageSource;
          if (source == null) continue;
          final entry = <String, dynamic>{
            'media': element.asset,
            'sha256': _digestOf(element.asset),
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

String _digestOf(String reference) {
  final match = RegExp(r'^media:([0-9a-f]{64})\.').firstMatch(reference);
  if (match == null) {
    throw FormatException('$reference is not a Course media reference.');
  }
  return match.group(1)!;
}

class _Options {
  const _Options({
    required this.input,
    required this.output,
    required this.overwrite,
  });

  final String input;
  final String output;
  final bool overwrite;

  static _Options parse(List<String> args) {
    final positional = <String>[];
    var overwrite = false;
    for (final arg in args) {
      if (arg == '--overwrite') {
        overwrite = true;
      } else if (arg.startsWith('--')) {
        throw FormatException('Unknown option $arg.');
      } else {
        positional.add(arg);
      }
    }
    if (positional.length != 2) {
      throw const FormatException(
        'Usage: dart run tools/convert_course_to_v12.dart INPUT OUTPUT [--overwrite]',
      );
    }
    return _Options(
      input: positional[0],
      output: positional[1],
      overwrite: overwrite,
    );
  }
}
