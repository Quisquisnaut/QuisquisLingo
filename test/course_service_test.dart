import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Build 262 Revision 0 bundles two demos', () {
    expect(CourseService.courseAssets, {
      'IT': 'assets/courses/exercise_laboratory_en_it.json',
      'EN_IT': 'assets/courses/english_from_italian_it_en.json',
    });
    expect(CourseService.hasCourse('ko'), isFalse);
    expect(CourseService.sourceLabels['EN_IT'], 'Italian');
    expect(CourseService.targetLabels['EN_IT'], 'English');
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
    ]) {
      expect(CourseService.hasCourse(code), isFalse, reason: code);
      expect(CourseService.targetLabels.containsKey(code), isFalse);
      expect(CourseService.sourceLabels.containsKey(code), isFalse);
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

      expect(first, CourseService.courseAssets.keys);
      expect(second, first);
      expect(first, ['IT', 'EN_IT']);
      expect(
        preferences.getStringList(CourseService.bundledCourseIndexStorageKey),
        first,
      );
      expect(preferences.getString('custom-course-sentinel'), 'preserved');
      expect(preferences.getString('learner-progress-sentinel'), 'preserved');
    },
  );
}
