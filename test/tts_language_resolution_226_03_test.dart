import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/tts_cache_service.dart';
import 'package:quisquislingo_app/services/tts_language_resolver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final value in ['it', 'it_IT', 'IT-it', 'it-IT', ' Italian ']) {
    test('$value resolves only to compatible installed Italian', () {
      final resolved = TtsLanguageResolver.resolve(requestedLanguage: value);
      expect(
        TtsLanguageResolver.selectInstalledLocale(resolved, ['en-US', 'it-IT']),
        'it-IT',
      );
    });
  }

  test('exact locale is preferred and unrelated voices never substitute', () {
    expect(
      TtsLanguageResolver.selectInstalledLocale('it-IT', ['it-CH', 'it-IT']),
      'it-IT',
    );
    expect(TtsLanguageResolver.selectInstalledLocale('en', ['it-IT']), isNull);
    expect(TtsLanguageResolver.selectInstalledLocale('it', ['ita-IT']), isNull);
    expect(
      TtsLanguageResolver.selectInstalledLocale('en-GB', ['en-US', 'en-GB']),
      'en-GB',
    );
  });

  test(
    'custom und metadata and bundled Italian resolve identically without mutation',
    () {
      final bundledJson =
          jsonDecode(File('assets/courses/italian_en.json').readAsStringSync())
              as Map<String, dynamic>;
      final bundled = Course.fromJson(bundledJson);
      final customJson = <String, dynamic>{
        ...bundledJson,
        'ttsLanguage': 'und',
        'title': 'My course',
        'originType': 'custom',
      };
      final custom = Course.fromJson(customJson);
      final before = jsonEncode(custom.toJson());
      String? voice(Course course) => TtsLanguageResolver.selectInstalledLocale(
        TtsLanguageResolver.resolve(
          requestedLanguage: course.ttsLanguage,
          learningLanguage: course.learningLanguage,
          targetLanguage: course.targetLanguage,
        ),
        ['it-IT'],
      );
      expect(voice(custom), voice(bundled));
      expect(voice(custom), 'it-IT');
      expect(jsonEncode(custom.toJson()), before);
      expect(custom.ttsLanguage, 'und');
    },
  );

  test('unknown or conflicting fallback metadata is not a missing voice', () {
    for (final value in ['', 'und', 'und-US', 'mul', 'not a locale']) {
      expect(
        () => TtsLanguageResolver.resolve(requestedLanguage: value),
        throwsFormatException,
      );
    }
    expect(
      () => TtsLanguageResolver.resolve(
        requestedLanguage: 'und',
        learningLanguage: 'Italian',
        targetLanguage: 'English',
      ),
      throwsFormatException,
    );
    expect(
      TtsLanguageResolver.resolve(
        requestedLanguage: 'en-US',
        learningLanguage: 'Italian',
      ),
      'en-US',
    );
    expect(
      TtsLanguageResolver.resolve(
        requestedLanguage: 'und',
        targetLanguage: 'Korean',
      ),
      'ko',
    );
  });

  test(
    'missing metadata reports the course problem before requesting any voice',
    () async {
      SharedPreferences.setMockInitialValues({});
      final service = TtsCacheService();
      expect(await service.speak(text: 'Hello', language: 'und'), isFalse);
      expect(
        service.lastFailureDescription,
        contains('course speech language metadata'),
      );
      expect(service.lastFailureDescription, isNot(contains('installed')));
      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString('quisquislingo_diagnostic_log'),
        contains('requested=und'),
      );
    },
  );

  test(
    'speech service forwards canonical metadata and refreshes voice enumeration after absence',
    () async {
      SharedPreferences.setMockInitialValues({});
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      const channel = MethodChannel('flutter_tts');
      final calls = <MethodCall>[];
      var installed = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            if (call.method == 'getLanguages') return installed;
            if (call.method == 'setLanguage') {
              return installed.contains(call.arguments) ? 1 : 0;
            }
            return 1;
          });
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });
      final service = TtsCacheService();
      expect(
        await service.speak(
          text: 'Buongiorno',
          language: 'und',
          learningLanguage: 'Italian',
          targetLanguage: 'Italian',
        ),
        isFalse,
      );
      installed = ['en-US', 'it-IT'];
      expect(
        await service.speak(
          text: 'Buongiorno',
          language: 'und',
          learningLanguage: 'Italian',
          targetLanguage: 'Italian',
        ),
        isTrue,
      );
      expect(
        calls.where((call) => call.method == 'getLanguages'),
        hasLength(2),
      );
      expect(
        calls.where((call) => call.method == 'setLanguage').last.arguments,
        'it-IT',
      );
      expect(
        calls.where((call) => call.method == 'speak').last.arguments,
        'Buongiorno',
      );
    },
  );
}
