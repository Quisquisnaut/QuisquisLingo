import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/course_service.dart';

/// The former bundled Edge Case demo. Build 259 Revision 5 took it out of
/// the bundle at the owner's request: people import it from
/// `demo_courses/edge_case_it_en.json`, a custom Course with its own
/// identity. The bundled official Course stays a test fixture, written by
/// `tools/generate_edge_case_demo_254.py`: the only bundled Course with
/// Draft content, the one sharing the English language code, and the one the
/// Selector and discovery tests switch to.
const edgeCaseFixturePath = 'test/fixtures/v12/edge_case_it_en.json';

/// The Course to import, beside the fixture.
const edgeCaseImportPath = 'demo_courses/edge_case_it_en.json';

/// Registers the fixture as the bundled Course `EN_EDGE`. Call it at the
/// start of a `setUp`; the registration is undone with the test.
void registerEdgeCaseFixture() {
  CourseService.debugExtraAssets['EN_EDGE'] = edgeCaseFixturePath;
  CourseService.debugAssetReader = (path) => File(path).readAsString();
  addTearDown(() {
    CourseService.debugExtraAssets.remove('EN_EDGE');
    CourseService.debugAssetReader = null;
  });
}
