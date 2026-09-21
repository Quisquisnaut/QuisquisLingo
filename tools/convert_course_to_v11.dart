import 'dart:convert';
import 'dart:io';

import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_checksums.dart';

/// Developer tool: converts a Course Model v9 or v10 JSON file to v11.
///
/// The application itself never converts: v9 and v10 are clean-cut. This tool
/// only changes `formatVersion` (a v10 merged Course is a v11 Course with
/// mergeProvenance) and, for official Courses, recomputes `officialChecksum`.
/// It stops, listing every location, when the Course refers to media outside
/// `assets/`: such a path belongs to the author's device and cannot be carried
/// over. A converted Publisher Course loses its signature and must be signed
/// again with tools/sign_course.dart.
Future<void> main(List<String> args) async {
  try {
    final options = _Options.parse(args);
    final raw = await File(options.input).readAsString();
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Course JSON root must be an object.');
    }
    final json = convertCourseJsonToV11(
      Map<String, dynamic>.from(decoded),
      officialVersion: options.officialVersion,
    );

    // Keep the source layout: pretty-printed stays pretty, compact stays
    // compact, and a trailing newline is preserved.
    final pretty = raw.trimLeft().startsWith(RegExp(r'\{\s*\n'));
    final encoded = pretty
        ? const JsonEncoder.withIndent('  ').convert(json)
        : jsonEncode(json);
    final newline = raw.endsWith('\n') ? '\n' : '';
    final output = File(options.output);
    if (!options.overwrite && await output.exists()) {
      throw FormatException(
        '${options.output} already exists. Pass --overwrite to replace it.',
      );
    }
    await output.writeAsString('$encoded$newline', flush: true);
    stdout.writeln('Converted ${options.input} to v11: ${options.output}');
    if (json['originType'] == CourseOriginType.externalOfficial.name) {
      stdout.writeln(
        'The Publisher signature was removed. Sign the result again with '
        'tools/sign_course.dart.',
      );
    }
  } on ExternalMediaReferences catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = 1;
  }
}

/// Thrown when a Course names media outside `assets/`.
class ExternalMediaReferences implements Exception {
  const ExternalMediaReferences(this.locations);

  final List<String> locations;

  @override
  String toString() => [
    'The Course refers to media outside assets/, which cannot be converted. '
        'Remove or replace these references first:',
    for (final location in locations) '  $location',
  ].join('\n');
}

/// Returns the v11 form of a v9 or v10 Course [json], preserving key order.
/// Throws [FormatException] for anything that is not a convertible Course and
/// [ExternalMediaReferences] when it names media outside `assets/`.
Map<String, dynamic> convertCourseJsonToV11(
  Map<String, dynamic> source, {
  String? officialVersion,
}) {
  final json = Map<String, dynamic>.from(source);
  final version = json['formatVersion'];
  if (version == Course.currentFormatVersion) {
    throw const FormatException('The Course is already v11.');
  }
  if (version != 9 && version != 10) {
    throw FormatException(
      'Only Course Model v9 or v10 can be converted, not $version.',
    );
  }

  final external = <String>[];
  _findExternalMedia(json, r'$', external);
  if (external.isNotEmpty) throw ExternalMediaReferences(external);

  json['formatVersion'] = Course.currentFormatVersion;
  final origin = json['originType'];
  final official =
      origin == CourseOriginType.bundledOfficial.name ||
      origin == CourseOriginType.externalOfficial.name;
  if (officialVersion != null) {
    if (!official) {
      throw const FormatException(
        '--official-version applies only to official Courses.',
      );
    }
    json['officialCourseVersion'] = officialVersion;
  }
  if (origin == CourseOriginType.externalOfficial.name) {
    json.remove('publisherSignature');
    json['publisherVerificationStatus'] =
        PublisherVerificationStatus.unverified.name;
  }
  if (official) {
    json['officialChecksum'] = CourseChecksums.official(Course.fromJson(json));
  }
  // Final proof that the result is a valid v11 Course.
  Course.fromJson(json);
  return json;
}

/// Media references live in `filePath` (Audio Library) and `asset` (prompt
/// and item image elements). Bundled `assets/` media and embedded `data:`
/// images travel with any Course.
void _findExternalMedia(Object? node, String location, List<String> out) {
  if (node is Map) {
    for (final entry in node.entries) {
      final key = entry.key.toString();
      final value = entry.value;
      final here = '$location.$key';
      if ((key == 'filePath' || key == 'asset') &&
          value is String &&
          value.trim().isNotEmpty &&
          !value.startsWith('assets/') &&
          !value.startsWith('data:')) {
        out.add('$here = $value');
      } else {
        _findExternalMedia(value, here, out);
      }
    }
  } else if (node is List) {
    for (var i = 0; i < node.length; i++) {
      _findExternalMedia(node[i], '$location[$i]', out);
    }
  }
}

class _Options {
  _Options(this.input, this.output, this.overwrite, this.officialVersion);

  final String input;
  final String output;
  final bool overwrite;
  final String? officialVersion;

  static const usage =
      'Usage: dart run tools/convert_course_to_v11.dart INPUT.json OUTPUT.json '
      '[--overwrite] [--official-version VERSION]';

  static _Options parse(List<String> args) {
    final positional = <String>[];
    var overwrite = false;
    String? officialVersion;
    for (var i = 0; i < args.length; i++) {
      switch (args[i]) {
        case '--overwrite':
          overwrite = true;
        case '--official-version':
          if (i + 1 >= args.length) throw const FormatException(usage);
          officialVersion = args[++i];
        default:
          positional.add(args[i]);
      }
    }
    if (positional.length != 2) throw const FormatException(usage);
    return _Options(positional[0], positional[1], overwrite, officialVersion);
  }
}
