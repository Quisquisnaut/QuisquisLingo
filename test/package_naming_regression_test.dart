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
      contains('\$packageName = "quisquislingo_windows_alpha_\${buildNumber}"'),
    );
    expect(
      agentInstructions,
      contains(
        'Windows release/package: `quisquislingo_windows_alpha_<buildnumber>`',
      ),
    );
    expect(
      agentInstructions,
      contains(
        'source folder/archive: `quisquislingo_alpha_<buildnumber>_source`',
      ),
    );
    expect(
      roadmap,
      contains(
        'Windows release package uses `quisquislingo_windows_alpha_<buildnumber>`',
      ),
    );
    expect(
      roadmap,
      contains(
        'Source package uses `quisquislingo_alpha_<buildnumber>_source`',
      ),
    );
  });
}
