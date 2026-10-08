import 'dart:io';

import 'package:quisquislingo_app/services/custom_course_transfer_service.dart';
import 'package:quisquislingo_app/services/learner_backup_service.dart';
import 'package:quisquislingo_app/services/storage/file_system_storage.dart';
import 'package:quisquislingo_app/services/storage/qql_storage.dart';

/// The desktop folder [role] resolves to in the test file system: below the
/// documents directory that `flutter_test_config.dart` gives every test.
/// Created, so tests can put files there.
Future<Directory> quickFolder(QqlStorageRole role) async {
  final directory = await FileSystemStorageBackend().directoryFor(role);
  await directory.create(recursive: true);
  return directory;
}

/// Where tests put the files Course Quick Import and Course Merge read.
/// Only meaningful for the file-system folders tests use.
extension CourseTransferTestPaths on CustomCourseTransferService {
  Future<String> importFilePath() async => (await importFolder()).locationOf(
    CustomCourseTransferService.importJsonName,
  );

  Future<String> importPackagePath() async => (await importFolder())
      .locationOf(CustomCourseTransferService.importPackageName);

  Future<String> mergeFilePath() async => (await mergeFolder()).locationOf(
    CustomCourseTransferService.mergeJsonName,
  );

  Future<String> mergePackagePath() async => (await mergeFolder())
      .locationOf(CustomCourseTransferService.mergePackageName);
}

/// Where tests put the file Import my data reads.
extension LearnerBackupTestPaths on LearnerBackupService {
  Future<String> importFilePath() async => (await importFolder()).locationOf(
    LearnerBackupService.importFileName,
  );
}
