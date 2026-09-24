import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/localization/help/help_destinations.dart';
import 'package:quisquislingo_app/localization/help/help_text.dart';
import 'package:quisquislingo_app/localization/locale_service.dart';
import 'package:quisquislingo_app/screens/audit_codes_screen.dart';
import 'package:quisquislingo_app/screens/info_screen.dart';
import 'package:quisquislingo_app/screens/qql_guide_screen.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'one registry covers every standalone Help route and localizes titles',
    () {
      expect(
        QqlGuideHelpDestinations.all.map((destination) => destination.id),
        [
          'all-courses',
          'audit-codes',
          'course-library',
          'course-studio',
          'debug',
          'device-administration',
          'editor',
          'exercise',
          'exercise-primitives',
          'json-structure',
          'publisher-signing',
          'course-model',
        ],
      );
      expect(
        QqlGuideHelpDestinations.all
            .map((destination) => destination.id)
            .toSet(),
        hasLength(QqlGuideHelpDestinations.all.length),
      );

      final audit = QqlGuideHelpDestinations.all.singleWhere(
        (destination) => destination.id == 'audit-codes',
      );
      expect(audit.englishOnly, isTrue);
      expect(audit.titleFor(AppLocale.italian), auditCodesPageTitle);
      expect(audit.titleFor(AppLocale.spanish), auditCodesPageTitle);
      expect(
        QqlGuideHelpDestinations.all
            .singleWhere((destination) => destination.id == 'all-courses')
            .titleFor(AppLocale.english),
        isNot(
          QqlGuideHelpDestinations.all
              .singleWhere((destination) => destination.id == 'course-library')
              .titleFor(AppLocale.english),
        ),
      );

      for (final locale in AppLocale.values) {
        final destinations = QqlGuideHelpDestinations.sortedFor(locale);
        expect(destinations, hasLength(QqlGuideHelpDestinations.all.length));
        final titles = destinations.map(
          (destination) => destination.titleFor(locale),
        );
        expect(titles.every((title) => title.isNotEmpty), isTrue);
        final expectedTitles = titles.toList()
          ..sort(
            (left, right) => left.toLowerCase().compareTo(right.toLowerCase()),
          );
        expect(titles, expectedTitles);
        for (final destination in destinations) {
          if (destination.titleKey case final String key) {
            expect(destination.titleFor(locale), helpText.lookup(locale, key));
          }
        }
      }
    },
  );

  testWidgets('Guide keeps fixed entries first and opens every Help route', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1100, 2600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await ProfileService().addProfile('Guide Learner');
    final prefs = await SharedPreferences.getInstance();
    final profileId = (await ProfileService().getActiveProfileId())!;
    final localeKey = ProfileService().keyForProfileId(profileId, 'locale');

    await tester.pumpWidget(const MaterialApp(home: QqlGuideScreen()));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(AppBar, 'QQL Guide'), findsOneWidget);
    expect(prefs.containsKey(localeKey), isFalse);
    expect(_tileTitles(tester), [
      'Help Language',
      'App Info',
      ...QqlGuideHelpDestinations.sortedFor(
        AppLocale.english,
      ).map((destination) => destination.titleFor(AppLocale.english)),
    ]);
    expect(
      find.text('Help and Course Info language for this learner.'),
      findsOneWidget,
    );
    expect(
      find.text('Learning rules, metrics and app behavior.'),
      findsOneWidget,
    );
    expect(find.text('English only'), findsOneWidget);

    await tester.tap(find.byKey(const Key('qql-guide-app-info')));
    await tester.pumpAndSettle();
    expect(find.byType(InfoScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    for (final destination in QqlGuideHelpDestinations.all) {
      final link = find.byKey(Key('qql-guide-help-${destination.id}'));
      await tester.ensureVisible(link);
      await tester.tap(link);
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text(destination.titleFor(AppLocale.english)),
        ),
        findsOneWidget,
        reason: destination.id,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
    }
    expect(prefs.containsKey(localeKey), isFalse);

    for (final locale in [AppLocale.italian, AppLocale.spanish]) {
      await tester.tap(find.byKey(const Key('qql-guide-language-selector')));
      await tester.pumpAndSettle();
      await tester.tap(find.text(locale.id).last);
      await tester.pumpAndSettle();
      expect(await LocaleService().read(), locale);
      expect(_tileTitles(tester), [
        'Help Language',
        'App Info',
        ...QqlGuideHelpDestinations.sortedFor(
          locale,
        ).map((destination) => destination.titleFor(locale)),
      ]);
      final editor = QqlGuideHelpDestinations.all.singleWhere(
        (destination) => destination.id == 'editor',
      );
      await tester.tap(find.byKey(const Key('qql-guide-help-editor')));
      await tester.pumpAndSettle();
      expect(
        find.widgetWithText(AppBar, editor.titleFor(locale)),
        findsOneWidget,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('qql-guide-help-audit-codes')));
      await tester.pumpAndSettle();
      expect(find.byType(AuditCodesScreen), findsOneWidget);
      expect(find.widgetWithText(AppBar, auditCodesPageTitle), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(await LocaleService().read(), locale);
      expect(prefs.getString(localeKey), locale.id);
    }
  });
}

List<String> _tileTitles(WidgetTester tester) => tester
    .widgetList<ListTile>(find.byType(ListTile))
    .map((tile) => tile.title)
    .whereType<Text>()
    .map((title) => title.data!)
    .toList();
