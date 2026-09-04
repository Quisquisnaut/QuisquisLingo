import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('bundled course registry includes Spanish', () {
    expect(CourseService.hasCourse('ES'), isTrue);
    expect(CourseService.hasCourse('es'), isTrue);
    expect(CourseService.courseAssets['ES'], 'assets/courses/spanish_en.json');
  });

  test('bundled course registry includes English from Spanish', () {
    expect(CourseService.hasCourse('EN'), isTrue);
    expect(CourseService.courseAssets['EN'], 'assets/courses/english_es.json');
  });

  test('empty authoring course shells are registered explicitly', () {
    expect(CourseService.hasCourse('NL'), isTrue);
    expect(CourseService.hasCourse('CY'), isTrue);
    expect(CourseService.hasCourse('PT'), isTrue);
    expect(CourseService.hasCourse('FI'), isTrue);
    expect(CourseService.courseAssets['FI'], 'assets/courses/finnish_en.json');
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
      expect(first, hasLength(9));
      expect(first.where((code) => code == 'KO'), hasLength(1));
      expect(
        preferences.getStringList(CourseService.bundledCourseIndexStorageKey),
        first,
      );
      expect(preferences.getString('custom-course-sentinel'), 'preserved');
      expect(preferences.getString('learner-progress-sentinel'), 'preserved');
    },
  );
}
