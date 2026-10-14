import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/app_errors.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/laboratory_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Build 272 Revision 17: no Course comes with the app', () {
    expect(CourseService.courseAssets, isEmpty);
    expect(CourseService.hasCourse('ko'), isFalse);
    // The Laboratory is a bundled Course only while a test registers it.
    expect(CourseService.hasCourse('IT'), isTrue);
    unregisterLaboratoryFixture();
    expect(CourseService.bundledAssets, isEmpty);
    expect(CourseService.bundledCourseIds, isEmpty);
    expect(CourseService.hasCourse('IT'), isFalse);
    expect(
      () => CourseService().loadBundledCourse('IT'),
      throwsA(isA<AppException>()),
    );
  });

  test('removed demos are unavailable', () {
    for (final code in [
      'DE',
      'ES',
      'EN',
      'CY',
      'PT',
      'NAP',
      'NL',
      'FI',
      'KO',
      'EN_EDGE',
      'PMS',
      'PMS_MIX',
      'EN_IT',
    ]) {
      expect(CourseService.hasCourse(code), isFalse, reason: code);
    }
  });

  test('unknown language is not silently mapped to Italian', () {
    expect(CourseService.hasCourse('ZZ'), isFalse);
  });

  test(
    'startup reconciliation adds missing bundled courses once without touching other state',
    () async {
      const existingCodes = ['IT', 'DE', 'ES', 'EN', 'CY', 'NL', 'PT', 'FI'];
      SharedPreferences.setMockInitialValues({
        CourseService.bundledCourseIndexStorageKey: existingCodes,
        'custom-course-sentinel': 'preserved',
        'learner-progress-sentinel': 'preserved',
      });
      final service = CourseService();

      final first = await service.reconcileAvailableBundledCourseCodes();
      final second = await service.reconcileAvailableBundledCourseCodes();
      final preferences = await SharedPreferences.getInstance();

      expect(first, CourseService.bundledAssets.keys);
      expect(second, first);
      expect(first, ['IT']);
      expect(
        preferences.getStringList(CourseService.bundledCourseIndexStorageKey),
        first,
      );
      expect(preferences.getString('custom-course-sentinel'), 'preserved');
      expect(preferences.getString('learner-progress-sentinel'), 'preserved');
    },
  );
}
