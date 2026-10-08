import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/course_service.dart';

/// The former Korean demo, removed from the bundle in Build 256 Revision 5
/// at the owner's request and kept as a test fixture: the Home, navigation,
/// entry-animation and discovery tests were written around its nine regular
/// Lessons, sections and Duels, which no remaining demo has. Call it at the
/// start of a `setUp`; the registration is undone with the test.
void registerKoreanFixture() {
  CourseService.debugExtraAssets['KO'] = 'test/fixtures/v12/korean_en.json';
  CourseService.debugAssetReader = (path) => File(path).readAsString();
  addTearDown(() {
    CourseService.debugExtraAssets.remove('KO');
    CourseService.debugAssetReader = null;
  });
}
