import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/screens/course_projects_screen.dart';

/// Build 248 Revision 2: export moved out of the Course Editor, where it ran on
/// the unconfirmed working copy, into one Course Export screen reached from the
/// Course Manager menu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the Export screen offers both routes and names the Course', (
    tester,
  ) async {
    var exported = 0;
    var savedTo = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: CourseExportScreen(
          courseTitle: 'Everyday Italian',
          onExport: () async => exported++,
          onSaveTo: () async => savedTo++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Course Export'), findsOneWidget);
    expect(find.byKey(const Key('export-course-title')), findsOneWidget);
    expect(find.text('Everyday Italian'), findsOneWidget);
    expect(find.byKey(const Key('cloud-folder-help')), findsOneWidget);
    expect(
      find.textContaining('not included until they are confirmed'),
      findsOneWidget,
      reason: 'The screen states that the export uses the stored Course.',
    );

    await tester.tap(find.byKey(const Key('export-course-zip-primary')));
    await tester.pumpAndSettle();
    expect(exported, 1);
    expect(savedTo, 0);

    await tester.tap(find.byKey(const Key('save-course-zip-to')));
    await tester.pumpAndSettle();
    expect(exported, 1);
    expect(savedTo, 1);
  });

  testWidgets('Save as… is hidden where the system dialog is unavailable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CourseExportScreen(
          courseTitle: 'Everyday Italian',
          onExport: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('export-course-zip-primary')), findsOneWidget);
    expect(find.byKey(const Key('save-course-zip-to')), findsNothing);
    expect(find.byKey(const Key('cloud-folder-help')), findsNothing);
  });
}
