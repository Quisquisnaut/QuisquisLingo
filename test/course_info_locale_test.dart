import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/localization/locale_service.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_info_screen.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Course Info selector changes localized labels and persists ES', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(900, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await ProfileService().addProfile('Alice');
    await tester.pumpWidget(
      MaterialApp(home: CourseInfoScreen(course: _course)),
    );
    await tester.pumpAndSettle();

    final selector = find.byKey(const Key('course-info-locale-selector'));
    expect(selector, findsOneWidget);
    expect(find.text('Languages'), findsOneWidget);
    await tester.tap(selector);
    await tester.pumpAndSettle();
    await tester.tap(find.text('ES').last);
    await tester.pumpAndSettle();

    expect(find.text('Lenguas'), findsOneWidget);
    expect(find.text('Course Info'), findsOneWidget);
    expect(find.textContaining('septiembre'), findsWidgets);
    expect(await LocaleService().read(), AppLocale.spanish);
  });
}

final _course = Course(
  courseId: 'locale-course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Localized Course',
  ttsLanguage: 'it-IT',
  originalCreatedAtUtc: '2026-09-10T12:00:00Z',
  modifiedAtUtc: '2026-09-10T12:00:00Z',
  lessons: const [],
);
