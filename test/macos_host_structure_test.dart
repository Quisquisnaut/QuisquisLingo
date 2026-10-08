import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('macOS compatibility scaffold is present', () {
    expect(File('macos/Runner/AppDelegate.swift').existsSync(), isTrue);
    expect(File('macos/Runner/MainFlutterWindow.swift').existsSync(), isTrue);
    expect(File('macos/Runner/DebugProfile.entitlements').existsSync(), isTrue);
    expect(File('macos/Runner/Release.entitlements').existsSync(), isTrue);
    expect(File('tools/prepare_macos.sh').existsSync(), isTrue);
    expect(File('docs/PLATFORM_COMPATIBILITY.md').existsSync(), isTrue);
  });
}
