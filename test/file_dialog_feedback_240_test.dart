import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/screens/course_projects_screen.dart';
import 'package:quisquislingo_app/services/file_dialog_service.dart';
import 'package:quisquislingo_app/widgets/file_dialog_feedback.dart';

Future<void> _show(
  WidgetTester tester,
  FileDialogResult result, {
  bool saving = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showFileDialogFeedback(
              context,
              result,
              saving: saving,
              savedMessage: 'Saved it as x.json.',
              fallbackHint: exportFallbackHint,
            ),
            child: const Text('go'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('go'));
  await tester.pump();
}

void main() {
  testWidgets('cancel shows nothing', (tester) async {
    await _show(tester, const FileDialogResult.cancelled());
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('saved shows the success message', (tester) async {
    await _show(tester, const FileDialogResult.saved('x.json'));
    expect(find.text('Saved it as x.json.'), findsOneWidget);
  });

  testWidgets('a failed save explains the fixed-folder fallback', (
    tester,
  ) async {
    await _show(tester, const FileDialogResult.failed('boom'));
    expect(
      find.textContaining('Couldn’t save to that location.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Documents/QuisquisLingo/Exports'),
      findsOneWidget,
    );
    expect(find.textContaining('Export instead'), findsOneWidget);
  });

  testWidgets('a failed open explains the fixed-folder Import route', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showFileDialogFeedback(
                context,
                const FileDialogResult.failed('boom'),
                saving: false,
                fallbackHint: courseImportFallbackHint,
              ),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    expect(find.textContaining('Couldn’t open that file.'), findsOneWidget);
    expect(find.textContaining('Imports/import.zip'), findsOneWidget);
    expect(
      find.textContaining('media-free JSON to import.json'),
      findsOneWidget,
    );
  });

  testWidgets('unavailable says so and still points at the default route', (
    tester,
  ) async {
    await _show(tester, const FileDialogResult.unavailable());
    expect(find.textContaining('not available here'), findsOneWidget);
    expect(find.textContaining('Export instead'), findsOneWidget);
  });

  test('cloud help says QQL does not sign in and explains each platform', () {
    for (final os in ['android', 'windows', 'macos', 'linux', 'fuchsia']) {
      final text = cloudFolderHelpText(operatingSystem: os);
      expect(
        text,
        contains('only if this device already shows them'),
        reason: os,
      );
      expect(text, contains('QQL does not sign in'), reason: os);
    }
    expect(
      cloudFolderHelpText(operatingSystem: 'android'),
      contains('Google Drive'),
    );
    expect(
      cloudFolderHelpText(operatingSystem: 'windows'),
      contains('Drive for desktop'),
    );
    expect(
      cloudFolderHelpText(operatingSystem: 'linux'),
      contains('Online Accounts'),
    );
  });

  testWidgets('the Import screen shows the cloud help beside Open from…', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CourseImportScreen(
          onImport: () async {},
          onOpenFrom: () async {},
        ),
      ),
    );
    expect(find.byKey(const Key('cloud-folder-help')), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(home: CourseImportScreen(onImport: () async {})),
    );
    expect(find.byKey(const Key('cloud-folder-help')), findsNothing);
  });

  testWidgets('Open from… is offered only when a system dialog exists', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: CourseImportScreen(onImport: () async {})),
    );
    expect(find.byKey(const Key('import-course-json-primary')), findsOneWidget);
    expect(find.byKey(const Key('open-course-json-from')), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: CourseImportScreen(
          onImport: () async {},
          onOpenFrom: () async {},
        ),
      ),
    );
    expect(find.byKey(const Key('import-course-json-primary')), findsOneWidget);
    expect(find.byKey(const Key('open-course-json-from')), findsOneWidget);
  });
}
