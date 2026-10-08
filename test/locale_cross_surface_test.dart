import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/localization/locale_service.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_info_screen.dart';
import 'package:quisquislingo_app/screens/editor_help_screen.dart';
import 'package:quisquislingo_app/screens/qql_guide_screen.dart';
import 'package:quisquislingo_app/screens/settings_screen.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/widgets/app_locale_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Guide Help and Course Info share one persisted Locale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await ProfileService().addProfile('Alice');
    await tester.pumpWidget(
      MaterialApp(
        home: SettingsScreen(course: null, onManageLearners: (_) async {}),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('settings-qql-guide')));
    await tester.pumpAndSettle();
    expect(find.byType(QqlGuideScreen), findsOneWidget);
    await _select(tester, 'qql-guide-language-selector', 'IT');
    await tester.ensureVisible(find.byKey(const Key('qql-guide-help-editor')));
    await tester.tap(find.byKey(const Key('qql-guide-help-editor')));
    await tester.pumpAndSettle();
    expect(find.byType(EditorHelpScreen), findsOneWidget);
    expect(
      tester
          .widget<AppLocaleSelector>(
            find.byKey(const Key('editor-help-language-toggle')),
          )
          .locale,
      AppLocale.italian,
    );

    await _select(tester, 'editor-help-language-toggle', 'ES');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<AppLocaleSelector>(
            find.byKey(const Key('qql-guide-language-selector')),
          )
          .locale,
      AppLocale.spanish,
    );

    unawaited(
      Navigator.of(tester.element(find.byType(QqlGuideScreen))).push<void>(
        MaterialPageRoute(builder: (_) => CourseInfoScreen(course: _course)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Lenguas'), findsOneWidget);
    await _select(tester, 'course-info-locale-selector', 'EN');
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<AppLocaleSelector>(
            find.byKey(const Key('qql-guide-language-selector')),
          )
          .locale,
      AppLocale.english,
    );
    expect(await LocaleService().read(), AppLocale.english);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.byKey(const Key('settings-locale-selector')), findsNothing);
    expect(find.text('Help Language'), findsNothing);
    expect(find.text('App Info'), findsNothing);
    await tester.tap(find.byKey(const Key('settings-qql-guide')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<AppLocaleSelector>(
            find.byKey(const Key('qql-guide-language-selector')),
          )
          .locale,
      AppLocale.english,
    );
  });
}

Future<void> _select(WidgetTester tester, String key, String id) async {
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
  await tester.tap(find.text(id).last);
  await tester.pumpAndSettle();
}

final _course = Course(
  courseId: 'shared-locale-course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Shared Locale Course',
  ttsLanguage: 'it-IT',
  lessons: const [],
);
