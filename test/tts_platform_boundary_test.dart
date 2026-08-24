import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_flutter_tts_windows/quisquislingo_flutter_tts_windows.dart';

void main() {
  test('Windows flutter_tts implementation is an intentional no-op', () {
    expect(QuisquisLingoFlutterTtsWindows.registerWith, returnsNormally);

    final source = File(
      'packages/quisquislingo_flutter_tts_windows/lib/'
      'quisquislingo_flutter_tts_windows.dart',
    ).readAsStringSync();
    expect(
      source,
      contains(RegExp(r'static\s+void\s+registerWith\(\)\s*\{\s*\}')),
    );
  });

  test('Flutter selects the local implementation only on Windows', () {
    final metadata =
        jsonDecode(File('.flutter-plugins-dependencies').readAsStringSync())
            as Map<String, dynamic>;
    final plugins = metadata['plugins'] as Map<String, dynamic>;

    Set<String> pluginNames(String platform) =>
        (plugins[platform] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map((plugin) => plugin['name'] as String)
            .toSet();

    final windows = pluginNames('windows');
    expect(windows, contains('quisquislingo_flutter_tts_windows'));
    expect(windows, isNot(contains('flutter_tts')));
    expect(pluginNames('linux'), isNot(contains('flutter_tts')));

    for (final platform in ['android', 'ios', 'macos', 'web']) {
      expect(
        pluginNames(platform),
        contains('flutter_tts'),
        reason: 'flutter_tts must remain selected on $platform',
      );
    }
  });

  test('generated Windows native plugin files exclude only flutter_tts', () {
    final registrant = File(
      'windows/flutter/generated_plugin_registrant.cc',
    ).readAsStringSync();
    final generatedCmake = File(
      'windows/flutter/generated_plugins.cmake',
    ).readAsStringSync();

    expect(registrant, isNot(contains('flutter_tts')));
    expect(
      registrant,
      isNot(contains('FlutterTtsPluginRegisterWithRegistrar')),
    );
    expect(registrant, isNot(contains('startup_diagnostics')));
    expect(registrant, isNot(contains('NATIVE_PLUGIN_')));
    expect(generatedCmake, isNot(contains('flutter_tts')));

    for (final plugin in [
      'AudioplayersWindowsPluginRegisterWithRegistrar',
      'ScreenRetrieverWindowsPluginCApiRegisterWithRegistrar',
      'UrlLauncherWindowsRegisterWithRegistrar',
      'WindowManagerPluginRegisterWithRegistrar',
    ]) {
      expect(registrant, contains(plugin));
    }

    for (final plugin in [
      'audioplayers_windows',
      'screen_retriever_windows',
      'url_launcher_windows',
      'window_manager',
    ]) {
      expect(generatedCmake, contains(plugin));
    }
  });
}
