import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quisquislingo_app/localization/locale_service.dart';
import 'package:quisquislingo_app/screens/info_screen.dart';
import 'package:quisquislingo_app/screens/info_screen_content.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/widgets/help_language_toggle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('App Info translation', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('both languages carry the same sections in the same order', () {
      final english = infoSections(HelpLanguage.english);
      final italian = infoSections(HelpLanguage.italian);
      final spanish = infoSections(HelpLanguage.spanish);

      // A section added to one language and forgotten in the other would show
      // the reader a page that silently loses content when they switch.
      expect(italian, hasLength(english.length));
      expect(spanish, hasLength(english.length));
      expect(spanish[1].title, 'Elegir y abrir cursos');
      for (var index = 0; index < english.length; index++) {
        expect(
          italian[index].title.trim(),
          isNotEmpty,
          reason: 'Italian title missing at $index',
        );
        expect(
          italian[index].body.trim(),
          isNotEmpty,
          reason: 'Italian body missing at $index',
        );
      }

      // Every body is translated except Version and Build, whose body is the
      // version string itself and is deliberately identical in both languages.
      final untranslated = [
        for (var index = 0; index < english.length; index++)
          if (italian[index].body == english[index].body) english[index].title,
      ];
      expect(untranslated, ['Version and Build']);
    });

    test('the credits button keeps its canonical English label', () {
      expect(
        infoCreditsButtonLabel(HelpLanguage.english),
        'App and image credits',
      );
      expect(
        infoCreditsButtonLabel(HelpLanguage.italian),
        'App and image credits',
      );
    });

    test('streak keeps its on-screen English name in the Italian text', () {
      // Profile > Statistics shows Current Streak and Max Streak, so the
      // Italian prose uses the same word rather than translating it.
      final italian = infoSections(
        HelpLanguage.italian,
      ).map((section) => section.body).join('\n');
      expect(italian, contains('streak'));
      expect(italian, isNot(contains('serie')));
      expect(italian, isNot(contains('slancio')));
    });

    test('no bundled-course count is stated, because it changes', () {
      for (final language in HelpLanguage.values) {
        for (final section in infoSections(language)) {
          expect(
            section.body,
            isNot(contains('eleven bundled')),
            reason: '${language.name} states a course count',
          );
          expect(section.body, isNot(contains('undici corsi')));
        }
      }
    });

    testWidgets('the Locale dropdown persists ES and restores it on reopen', (
      tester,
    ) async {
      final profiles = ProfileService();
      await profiles.addProfile('Alice');
      final profileId = (await profiles.getActiveProfileId())!;
      final localeKey = profiles.keyForProfileId(profileId, 'locale');
      final prefs = await SharedPreferences.getInstance();
      await tester.pumpWidget(const MaterialApp(home: InfoScreen()));
      await tester.pumpAndSettle();

      expect(prefs.containsKey(localeKey), isFalse);
      expect(find.text('Choosing and opening courses'), findsOneWidget);
      await tester.tap(find.byKey(const Key('app-info-language-toggle')));
      await tester.pumpAndSettle();
      for (final id in ['EN', 'IT', 'ES']) {
        expect(find.text(id), findsWidgets);
      }
      await tester.tap(find.text('ES').last);
      await tester.pumpAndSettle();
      expect(find.text('Elegir y abrir cursos'), findsOneWidget);
      expect(prefs.getString(localeKey), 'ES');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(const MaterialApp(home: InfoScreen()));
      await tester.pumpAndSettle();
      expect(find.text('Elegir y abrir cursos'), findsOneWidget);
      expect(await LocaleService().read(), AppLocale.spanish);
    });

    testWidgets('Italian keeps on-screen names in English', (tester) async {
      await ProfileService().addProfile('Alice');
      await tester.pumpWidget(const MaterialApp(home: InfoScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('app-info-language-toggle')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('IT').last);
      await tester.pumpAndSettle();

      // The interface is English, so a reader following the Italian text has
      // to see the exact names that appear on screen.
      final italian = infoSections(
        HelpLanguage.italian,
      ).map((section) => section.body).join('\n');
      for (final label in const [
        'Course Selector',
        'Remove from my courses',
        'Profile > Statistics',
        'Settings > Audio Settings',
        'Course Studio',
        'Course Studio Help',
        'Editor Help',
        'Week XP',
      ]) {
        expect(italian, contains(label), reason: '$label was translated away');
      }
      expect(
        italian,
        isNot(
          contains(
            'Course Editor di un corso personalizzato offre Copy as New Course',
          ),
        ),
      );
    });
  });
}
