import 'package:flutter/material.dart';

import '../services/course_import_check.dart';
import '../services/storage/qql_storage.dart';

// Small texts the Course Import, Export and Merge pages and Course Studio
// share (Build 272 Revision 12; before, private helpers of the Course
// Studio file).

/// The name an author reads for a folder of QuisquisLingo.
String courseFolderLabel(QqlStorageRole role) =>
    QqlStorageLayout.current.folderLabel(role);

/// The name an author reads for a file in a folder of QuisquisLingo.
String courseFileLabel(QqlStorageRole role, String name) =>
    QqlStorageLayout.current.fileLabel(role, name);

/// Says that a Course package held its files inside one folder named
/// after the ZIP: accepted, with this notice.
void showMatchingZipFolderWarning(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      duration: Duration(seconds: 10),
      content: Text(CourseImportCheck.matchingZipFolderText),
    ),
  );
}
