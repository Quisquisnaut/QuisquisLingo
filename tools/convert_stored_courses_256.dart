import 'dart:convert';
import 'dart:io';

import 'package:quisquislingo_app/services/course_model_v12_converter.dart';

/// Developer tool, run once with QQL closed (Build 256 Revision 1).
///
/// Build 256 reads Course Model v12 only, from the private folder
/// `QQL_Courses_v12`. This tool converts every custom Course that Build 255
/// stored in `QQL_Courses/Custom` and writes it to `QQL_Courses_v12/Custom`
/// under the same file name, with the same record shape
/// (`{courseId, entry: {course, …}}`). Course media (`QQL_CourseMedia`) are
/// keyed by Course ID and need no move; Course Backups stay in the Backups
/// folder, where Version History names the v11 versions as unreadable.
///
/// It never overwrites or deletes: a file whose new place is taken, a file
/// it cannot read or convert, and every Publisher Course (whose signature
/// conversion would strip; re-import the signed package instead) stay where
/// they are and are reported.
///
///     dart run tools/convert_stored_courses_256.dart [--support DIR] [--dry-run]
///
/// On Windows `--support` defaults to `%APPDATA%\QuisquisLingo\quisquislingo_app`;
/// on other systems pass it.
Future<void> main(List<String> args) async {
  try {
    final options = ConvertStoredOptions.parse(
      args,
      environment: Platform.environment,
      windows: Platform.isWindows,
    );
    stdout.writeln('QQL private storage: ${options.support}');
    final report = await convertStoredCourses(
      support: Directory(options.support),
      dryRun: options.dryRun,
    );
    report.lines.forEach(stdout.writeln);
    stdout.writeln(report.summary);
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = 1;
  }
}

class ConvertStoredOptions {
  ConvertStoredOptions(this.support, this.dryRun);

  final String support;
  final bool dryRun;

  static const usage =
      'Usage: dart run tools/convert_stored_courses_256.dart '
      '[--support DIR] [--dry-run]\n'
      'Close QQL first. On Windows --support defaults to '
      r'%APPDATA%\QuisquisLingo\quisquislingo_app; on other systems pass it.';

  static ConvertStoredOptions parse(
    List<String> args, {
    required Map<String, String> environment,
    required bool windows,
  }) {
    String? support;
    var dryRun = false;
    for (var i = 0; i < args.length; i++) {
      switch (args[i]) {
        case '--support':
          if (i + 1 >= args.length) throw const FormatException(usage);
          support = args[++i];
        case '--dry-run':
          dryRun = true;
        default:
          throw const FormatException(usage);
      }
    }
    if (windows && support == null) {
      final appData = environment['APPDATA'];
      if (appData != null) {
        support = '$appData\\QuisquisLingo\\quisquislingo_app';
      }
    }
    if (support == null) throw const FormatException(usage);
    return ConvertStoredOptions(support, dryRun);
  }
}

/// What [convertStoredCourses] did, or would do in a dry run.
class StoredCourseConversionReport {
  StoredCourseConversionReport({required this.dryRun});

  final bool dryRun;
  final List<String> lines = [];
  int converted = 0;
  int kept = 0;

  String get summary =>
      '${dryRun ? 'Would convert' : 'Converted'} $converted Course(s); '
      '$kept file(s) left where they were.';
}

const earlierRoot = 'QQL_Courses';
const currentRoot = 'QQL_Courses_v12';

Future<StoredCourseConversionReport> convertStoredCourses({
  required Directory support,
  bool dryRun = false,
}) async {
  final sep = Platform.pathSeparator;
  final report = StoredCourseConversionReport(dryRun: dryRun);
  for (final kind in const ['Custom', 'Publisher']) {
    final source = Directory('${support.path}$sep$earlierRoot$sep$kind');
    if (!await source.exists()) continue;
    final files =
        (await source.list(followLinks: false).toList())
            .whereType<File>()
            .where((file) => file.path.toLowerCase().endsWith('.json'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    for (final file in files) {
      final name = file.uri.pathSegments.last;
      final where = '$earlierRoot/$kind/$name';
      if (kind == 'Publisher') {
        report.kept++;
        report.lines.add(
          '$where: kept. A Publisher Course cannot be converted without '
          'losing its signature; import the Publisher\'s signed package '
          'into this version instead.',
        );
        continue;
      }
      final Map<String, dynamic> record;
      try {
        final decoded = jsonDecode(await file.readAsString());
        if (decoded is! Map ||
            decoded['courseId'] is! String ||
            decoded['entry'] is! Map ||
            (decoded['entry'] as Map)['course'] is! Map) {
          throw const FormatException('not a stored custom Course record');
        }
        record = Map<String, dynamic>.from(decoded);
      } catch (error) {
        report.kept++;
        report.lines.add('$where: kept, it cannot be read ($error).');
        continue;
      }
      final entry = Map<String, dynamic>.from(record['entry'] as Map);
      final CourseConversionResult result;
      try {
        result = convertCourseJsonToV12(
          Map<String, dynamic>.from(entry['course'] as Map),
        );
      } on FormatException catch (error) {
        report.kept++;
        report.lines.add(
          '$where: kept, it cannot be converted: ${error.message}',
        );
        continue;
      }
      final target = File('${support.path}$sep$currentRoot$sep$kind$sep$name');
      if (await target.exists()) {
        report.kept++;
        report.lines.add(
          '$where: kept, $currentRoot/$kind/$name already exists.',
        );
        continue;
      }
      final converted = jsonEncode({
        'courseId': record['courseId'],
        'entry': {...entry, 'course': result.json},
      });
      if (!dryRun) {
        await target.parent.create(recursive: true);
        await target.writeAsString(converted, flush: true);
      }
      report.converted++;
      report.lines.add(
        '$where: ${dryRun ? 'would convert' : 'converted'} to '
        '$currentRoot/$kind/$name'
        '${result.notes.isEmpty ? '' : ' (${result.notes.join(' ')})'}',
      );
    }
  }
  return report;
}
