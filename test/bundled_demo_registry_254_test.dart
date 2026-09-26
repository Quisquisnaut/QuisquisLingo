import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/course_learner_visibility_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('Build 254 replaces the three requested bundled demos', () {
    expect(
      CourseService.courseAssets['IT'],
      'assets/courses/exercise_laboratory_en_it.json',
    );
    expect(CourseService.hasCourse('FI'), isFalse);
    expect(CourseService.hasCourse('NL'), isFalse);
    expect(
      CourseService.courseAssets['PMS'],
      'assets/courses/piedmontais_en.json',
    );
    expect(
      CourseService.courseAssets['EN_EDGE'],
      'assets/courses/edge_case_it_en.json',
    );
    // Build 255 Revision 6 removed the Spanish-to-English demo.
    expect(CourseService.hasCourse('EN'), isFalse);
  });

  test(
    'the Edge Course keeps its own selection reference and shares English',
    () async {
      final service = CourseService();
      final italianToEnglish = await service.loadBundledCourse('EN_EDGE');
      expect(CourseService.bundledCodeForCourse(italianToEnglish), 'EN_EDGE');
      expect(CourseService.codeForCourse(italianToEnglish), 'EN');
      expect(italianToEnglish.sourceLanguage, 'Italian');
      final piedmontese = await service.loadBundledCourse('PMS');
      expect(CourseService.codeForCourse(piedmontese), 'PMS');
      expect(piedmontese.sourceLanguage, 'English');
    },
  );

  test('current Edge Course protection does not hide another bundle', () async {
    await ProfileService().addProfile('Demo learner');
    await SettingsService().setLastSelectedCourseCode('EN_EDGE');
    final service = CourseService();
    final edge = await service.loadBundledCourse('EN_EDGE');
    final other = await service.loadBundledCourse('KO');
    final visibility = CourseLearnerVisibilityService();
    await expectLater(visibility.setHidden(edge, true), throwsStateError);
    await visibility.setHidden(other, true);
    expect(await visibility.isHidden(other.courseId), isTrue);
    expect(await visibility.isHidden(edge.courseId), isFalse);
    expect(await SettingsService().getLastSelectedCourseCode(), 'EN_EDGE');
  });
}
