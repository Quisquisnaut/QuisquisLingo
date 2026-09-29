import 'dart:io';

import 'package:quisquislingo_app/models/canonical/capability_description.dart';

/// Developer tool (Build 256 Revision 6, plan A.13): writes the capability
/// registry's machine-readable description.
///
///     dart run tools/export_capabilities.dart [OUTPUT]
///
/// OUTPUT defaults to `docs/capabilities_v12.json`, relative to the current
/// directory (the repository root). The file is the one source the Python
/// tools read (`tools/qql_capabilities.py`); `test/capability_description_256_test.dart`
/// fails when the committed file no longer matches the registry, so run
/// this after any registry change and commit the result.
Future<void> main(List<String> args) async {
  if (args.length > 1 || args.any((arg) => arg.startsWith('-'))) {
    stderr.writeln('Usage: dart run tools/export_capabilities.dart [OUTPUT]');
    exitCode = 2;
    return;
  }
  final output = File(
    args.isEmpty ? 'docs/capabilities_v12.json' : args.single,
  );
  await output.parent.create(recursive: true);
  await output.writeAsString(capabilityDescriptionJson(), flush: true);
  stdout.writeln('Wrote ${output.path}');
}
