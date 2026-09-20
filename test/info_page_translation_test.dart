import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/screens/info_screen.dart';
import 'package:quisquislingo_app/screens/info_screen_content.dart';
import 'package:quisquislingo_app/widgets/help_language_toggle.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('App Info translation', () {
    test('both languages carry the same sections in the same order', () {
      final english = infoSections(HelpLanguage.english);
      final italian = infoSections(HelpLanguage.italian);

      // A section added to one language and forgotten in the other would show
      // the reader a page that silently loses content when they switch.
      expect(italian, hasLength(english.length));
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

    test('the credits button is labelled in both languages', () {
      expect(
        infoCreditsButtonLabel(HelpLanguage.english),
        'App and image credits',
      );
      expect(
        infoCreditsButtonLabel(HelpLanguage.italian),
        'Crediti dell’app e delle immagini',
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

    testWidgets('the toggle swaps the page between English and Italian', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: InfoScreen()));
      await tester.pumpAndSettle();

      // Opens in English, offering Italian.
      expect(find.text('Choosing and opening courses'), findsOneWidget);
      expect(find.text('Scegliere e aprire i corsi'), findsNothing);
      expect(find.text('Italiano'), findsOneWidget);

      await tester.tap(find.byKey(const Key('app-info-language-toggle')));
      await tester.pumpAndSettle();

      // Now Italian, and the same control offers the way back.
      expect(find.text('Scegliere e aprire i corsi'), findsOneWidget);
      expect(find.text('Choosing and opening courses'), findsNothing);
      expect(find.text('English'), findsOneWidget);

      await tester.tap(find.byKey(const Key('app-info-language-toggle')));
      await tester.pumpAndSettle();

      expect(find.text('Choosing and opening courses'), findsOneWidget);
      expect(find.text('Italiano'), findsOneWidget);
    });

    testWidgets('Italian keeps on-screen names in English', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: InfoScreen()));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('app-info-language-toggle')));
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
        'Course Manager',
        'Editor Help',
        'Week XP',
      ]) {
        expect(italian, contains(label), reason: '$label was translated away');
      }
    });
  });
}
