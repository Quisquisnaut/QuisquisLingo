import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('release artifacts use QuisquisLingo filesystem naming', () {
    final packagingScript = File(
      'tools/package_windows_release.ps1',
    ).readAsStringSync();
    final androidPackagingScript = File(
      'tools/package_android_debug.ps1',
    ).readAsStringSync();
    final agentInstructions = File('AGENTS.md').readAsStringSync();
    final roadmap = File('docs/ROADMAP.md').readAsStringSync();

    expect(
      packagingScript,
      contains('\$packageName = "quisquislingo_windows_beta_\${buildNumber}"'),
    );
    expect(
      androidPackagingScript,
      contains(
        '\$packageName = "quisquislingo_android_debug_beta_\${buildNumber}"',
      ),
    );
    expect(androidPackagingScript, contains('flutter build apk --debug --no-pub'));
    expect(androidPackagingScript, contains('matXpack'));
    expect(
      agentInstructions,
      contains(
        'Windows release/package: `quisquislingo_windows_beta_<buildnumber>`',
      ),
    );
    expect(
      agentInstructions,
      contains(
        'source folder/archive: `quisquislingo_beta_<buildnumber>_source`',
      ),
    );
    expect(
      roadmap,
      contains(
        'Windows release package uses `quisquislingo_windows_beta_<buildnumber>`',
      ),
    );
    expect(
      roadmap,
      contains('Source package uses `quisquislingo_beta_<buildnumber>_source`'),
    );
  });
}
