import 'dart:io';

import 'package:flutter/services.dart';
import 'package:quisquislingo_app/services/course_service.dart';

/// The Exercise Laboratory as a bundled test Course. Build 272 Revision 17
/// took it out of the app at the owner's request: no Course comes with the
/// app, people import the Laboratory from
/// `demo_courses/exercise_laboratory_en_it.json` (a custom Course with its
/// own identity), and its file stays in the app only as the source of the
/// preset forms' Fill with an example.
///
/// The tests written while it was bundled still need a bundled Course with
/// every preset, so `test/flutter_test_config.dart` registers it for every
/// test, under the code it had. A test of the app as it ships, with no
/// Course, calls [unregisterLaboratoryFixture] first.
const laboratoryFixtureCode = 'IT';

/// The Laboratory's bundled identity, reserved in CourseEditorService.
const laboratoryCourseId = 'course_50d68435-d2c2-4b63-9a0b-b23161357f1d';

/// The Course to import, beside the app's file.
const laboratoryImportPath = 'demo_courses/exercise_laboratory_en_it.json';

/// Registers the Laboratory as the bundled Course `IT`.
void registerLaboratoryFixture() {
  CourseService.debugExtraAssets[laboratoryFixtureCode] =
      CourseService.laboratoryAsset;
  CourseService.debugExtraCourseIds.add(laboratoryCourseId);
}

/// The app as it ships: no bundled Course. The next test gets the
/// Laboratory back from the test configuration.
void unregisterLaboratoryFixture() {
  CourseService.debugExtraAssets.remove(laboratoryFixtureCode);
  CourseService.debugExtraCourseIds.remove(laboratoryCourseId);
}

/// The reader the fixture Courses share: the Laboratory comes from the
/// app's assets, as it did while it was bundled; a fixture file from disk.
Future<String> readFixtureCourse(String path) =>
    path == CourseService.laboratoryAsset
    ? rootBundle.loadString(path)
    : File(path).readAsString();
