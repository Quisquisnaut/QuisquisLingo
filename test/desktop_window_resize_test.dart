import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('desktop hosts preserve resizing with only the safe minimum size', () {
    final windowSetup = File(
      'lib/services/window_setup_io.dart',
    ).readAsStringSync();
    final macWindow = File(
      'macos/Runner/MainFlutterWindow.swift',
    ).readAsStringSync();

    expect(
      windowSetup,
      contains('windowManager.setMinimumSize(const Size(320, 600))'),
    );
    expect(windowSetup, isNot(contains('setMaximumSize')));
    expect(windowSetup, isNot(contains('setResizable(false)')));
    expect(
      macWindow,
      contains('self.contentMinSize = NSSize(width: 320, height: 600)'),
    );
    expect(macWindow, isNot(contains('styleMask.remove(.resizable)')));
    expect(macWindow, isNot(contains('maxSize')));
  });
}
