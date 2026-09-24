import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/localization/locale_builder.dart';
import 'package:quisquislingo_app/localization/locale_service.dart';
import 'package:quisquislingo_app/localization/localized_text.dart';
import 'package:quisquislingo_app/screens/settings_screen.dart';
import 'package:quisquislingo_app/screens/qql_guide_screen.dart';
import 'package:quisquislingo_app/services/learner_backup_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/widgets/app_locale_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Locale persists per learner and reads do not create a key', () async {
    final profiles = ProfileService();
    final locale = LocaleService();
    await profiles.addProfile('Alice');
    final aliceId = (await profiles.getActiveProfileId())!;
    final aliceKey = profiles.keyForProfileId(aliceId, 'locale');
    final prefs = await SharedPreferences.getInstance();

    expect(await locale.read(), AppLocale.english);
    expect(prefs.containsKey(aliceKey), isFalse);
    await locale.write(AppLocale.italian);
    expect(prefs.getString(aliceKey), 'IT');

    await profiles.addProfile('Bob');
    final bobId = (await profiles.getActiveProfileId())!;
    final bobKey = profiles.keyForProfileId(bobId, 'locale');
    expect(await locale.read(), AppLocale.english);
    expect(prefs.containsKey(bobKey), isFalse);
    await locale.write(AppLocale.spanish);
    expect(prefs.getString(bobKey), 'ES');

    await profiles.setActiveProfile('Alice');
    expect(await LocaleService().read(), AppLocale.italian);
    await profiles.setActiveProfile('Bob');
    expect(await LocaleService().read(), AppLocale.spanish);
  });

  test(
    'invalid Locale falls back to English without changing storage',
    () async {
      final profiles = ProfileService();
      await profiles.addProfile('Alice');
      final key = profiles.keyForProfileId(
        (await profiles.getActiveProfileId())!,
        'locale',
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, 'FR');

      expect(await LocaleService().read(), AppLocale.english);
      expect(prefs.getString(key), 'FR');
    },
  );

  test('learner backup carries Locale and old backups restore EN', () async {
    await ProfileService().addProfile('Alice');
    await LocaleService().write(AppLocale.italian);
    final backup = LearnerBackupService();
    final exported = await backup.exportActiveProfile();
    expect((exported['data'] as Map<String, dynamic>)['locale'], 'IT');

    final restored = backup.decodeDocument(utf8.encode(jsonEncode(exported)));
    await backup.importAsSeparateCopy(restored, displayName: 'Alice Copy');
    expect(await LocaleService().read(), AppLocale.italian);

    final oldBackup = Map<String, dynamic>.from(exported);
    oldBackup['data'] = Map<String, dynamic>.from(
      exported['data'] as Map<String, dynamic>,
    )..remove('locale');
    final oldDocument = backup.decodeDocument(
      utf8.encode(jsonEncode(oldBackup)),
    );
    await backup.importAsSeparateCopy(
      oldDocument,
      displayName: 'Old Backup Copy',
    );
    expect(await LocaleService().read(), AppLocale.english);
  });

  test('missing leaf falls back to English without a Locale write', () async {
    final profiles = ProfileService();
    await profiles.addProfile('Alice');
    final locale = LocaleService();
    await locale.write(AppLocale.spanish);
    final key = profiles.keyForProfileId(
      (await profiles.getActiveProfileId())!,
      'locale',
    );
    final prefs = await SharedPreferences.getInstance();

    const text = LocalizedText(
      english: {'sample.title': 'Title', 'sample.body': 'English body'},
      italian: {'sample.title': 'Titolo', 'sample.body': 'Testo italiano'},
      spanish: {'sample.title': 'Título'},
    );
    expect(text.lookup(await locale.read(), 'sample.title'), 'Título');
    expect(text.lookup(await locale.read(), 'sample.body'), 'English body');
    expect(prefs.getString(key), 'ES');
  });

  test('lookup inserts dynamic values once and leaves their text verbatim', () {
    const text = LocalizedText(
      english: {'example': '{value} {unit}'},
      italian: {'example': '{value} {unit}'},
      spanish: {'example': '{value} {unit}'},
    );
    expect(
      text.lookup(
        AppLocale.spanish,
        'example',
        values: {'value': 'literal {unit}', 'unit': 'hours'},
      ),
      'literal {unit} hours',
    );
  });

  testWidgets('mounted Locale readers follow changes and profile switches', (
    tester,
  ) async {
    final profiles = ProfileService();
    await profiles.addProfile('Alice');
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            LocaleBuilder(builder: (_, locale) => Text('first:${locale.id}')),
            LocaleBuilder(builder: (_, locale) => Text('second:${locale.id}')),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('first:EN'), findsOneWidget);
    expect(find.text('second:EN'), findsOneWidget);

    await LocaleService().write(AppLocale.italian);
    await tester.pumpAndSettle();
    expect(find.text('first:IT'), findsOneWidget);
    expect(find.text('second:IT'), findsOneWidget);

    await profiles.addProfile('Bob');
    await tester.pumpAndSettle();
    expect(find.text('first:EN'), findsOneWidget);
    expect(find.text('second:EN'), findsOneWidget);
  });

  testWidgets('selector offers EN IT ES and writes the shared preference', (
    tester,
  ) async {
    final profiles = ProfileService();
    await profiles.addProfile('Alice');
    final key = profiles.keyForProfileId(
      (await profiles.getActiveProfileId())!,
      'locale',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LocaleBuilder(
            builder: (_, locale) => AppLocaleSelector(
              key: const Key('test-locale-selector'),
              locale: locale,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.containsKey(key), isFalse);

    await tester.tap(find.byKey(const Key('test-locale-selector')));
    await tester.pumpAndSettle();
    for (final id in ['EN', 'IT', 'ES']) {
      expect(find.text(id), findsWidgets);
    }
    await tester.tap(find.text('ES').last);
    await tester.pumpAndSettle();
    expect(prefs.getString(key), 'ES');
    expect(find.text('ES'), findsOneWidget);
  });

  testWidgets('QQL Guide exposes the shared per-user Help Language', (
    tester,
  ) async {
    final profiles = ProfileService();
    await profiles.addProfile('Alice');
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(course: null, onManageLearners: (_) async {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('settings-locale-selector')), findsNothing);
    await tester.tap(find.byKey(const Key('settings-qql-guide')));
    await tester.pumpAndSettle();
    expect(find.byType(QqlGuideScreen), findsOneWidget);
    final selector = find.byKey(const Key('qql-guide-language-selector'));
    expect(selector, findsOneWidget);
    expect(find.widgetWithText(ListTile, 'Help Language'), findsOneWidget);
    await tester.tap(selector);
    await tester.pumpAndSettle();
    await tester.tap(find.text('IT').last);
    await tester.pumpAndSettle();
    expect(await LocaleService().read(), AppLocale.italian);
  });
}
