import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/localization/locale_service.dart';
import 'package:quisquislingo_app/screens/available_courses_screen.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Course Library Help uses the shared persistent Locale', (
    tester,
  ) async {
    await ProfileService().addProfile('Library learner');

    await tester.pumpWidget(
      const MaterialApp(
        home: CourseLibraryHelpScreen(
          source: CourseLibraryHelpSource.allCourses,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('All Courses — Help'), findsOneWidget);
    expect(
      tester
          .widget<SelectableText>(
            find.byKey(const Key('all-courses-help-text')),
          )
          .data,
      contains('Courses on this device'),
    );
    expect(availableCoursesHelpFor(AppLocale.english), availableCoursesHelp);

    await tester.tap(find.byKey(const Key('all-courses-help-locale-selector')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ES').last);
    await tester.pumpAndSettle();

    expect(await LocaleService().read(), AppLocale.spanish);
    expect(find.text('All Courses — Ayuda'), findsOneWidget);
    expect(
      tester
          .widget<SelectableText>(
            find.byKey(const Key('all-courses-help-text')),
          )
          .data,
      contains('Cursos de este dispositivo'),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(
      const MaterialApp(
        home: CourseLibraryHelpScreen(
          source: CourseLibraryHelpSource.courseLibrary,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Course Library — Ayuda'), findsOneWidget);
    expect(
      tester
          .widget<SelectableText>(
            find.byKey(const Key('all-courses-help-text')),
          )
          .data,
      contains('Cursos de este dispositivo'),
    );
  });
}
