import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release artifacts use QuisquisLingo filesystem naming', () {
    final packagingScript = File(
      'tools/package_windows_release.ps1',
    ).readAsStringSync();
    final agentInstructions = File('AGENTS.md').readAsStringSync();
    final roadmap = File('docs/ROADMAP.md').readAsStringSync();

    expect(
      packagingScript,
      contains('quisquislingo_alpha_\${buildNumber}_dev_windows_x64'),
    );
    expect(
      agentInstructions,
      contains('quisquislingo_alpha_<buildnumber>'),
    );
    expect(
      agentInstructions,
      contains('quisquislingo_alpha_<buildnumber>_source'),
    );
    expect(roadmap, contains('quisquislingo_alpha_<buildnumber>'));
    expect(roadmap, contains('quisquislingo_alpha_<buildnumber>_source'));
  });
}
