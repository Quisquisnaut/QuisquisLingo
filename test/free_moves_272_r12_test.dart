import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/screens/course_export_screen.dart';
import 'package:quisquislingo_app/screens/course_import_screen.dart';
import 'package:quisquislingo_app/screens/course_merge_screen.dart';
import 'package:quisquislingo_app/screens/course_projects_screen.dart'
    as course_studio;
import 'package:quisquislingo_app/services/storage/qql_storage.dart';
import 'package:quisquislingo_app/widgets/course_package_notes.dart';
import 'package:quisquislingo_app/widgets/primitive_editor_rows.dart';

/// Build 272 Revision 12: the Course Import, Export and Merge pages and the
/// canonical editor's rows have files of their own.
void main() {
  test('the three pages are still reachable from the Course Studio file', () {
    expect(course_studio.CourseImportScreen, CourseImportScreen);
    expect(course_studio.CourseExportScreen, CourseExportScreen);
    expect(course_studio.CourseMergeScreen, CourseMergeScreen);
  });

  test('the names of a folder and of a file are the storage layout\'s', () {
    final layout = QqlStorageLayout.current;
    for (final role in [
      QqlStorageRole.courseImports,
      QqlStorageRole.courseExports,
      QqlStorageRole.mergeImports,
    ]) {
      expect(courseFolderLabel(role), layout.folderLabel(role));
      expect(
        courseFileLabel(role, 'import.zip'),
        layout.fileLabel(role, 'import.zip'),
      );
    }
  });

  testWidgets('the notice of a ZIP with its files in a folder of its name', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showMatchingZipFolderWarning(context),
              child: const Text('show'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('show'));
    await tester.pump();
    expect(
      find.text(
        'Accepted a matching ZIP folder. Course package files normally belong at the ZIP root.',
      ),
      findsOneWidget,
    );
    expect(
      tester.widget<SnackBar>(find.byType(SnackBar)).duration,
      const Duration(seconds: 10),
    );
  });

  test('a menu entry of the canonical editor is one line, cut when the menu '
      'is narrow', () {
    final text = menuText('exactAssignments');
    expect(text.data, 'exactAssignments');
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
  });
}
