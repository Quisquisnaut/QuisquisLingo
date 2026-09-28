import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/course_flag_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/course_learner_visibility_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/services/world_flag_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'Build 255 Revision 7: every bundled Course flag can be drawn',
    () async {
      // An explicit flag QQL cannot draw shows the neutral flag, never the
      // automatic one: Edge Case said "GB" until Revision 7.
      final courses = CourseService();
      final worldFlags = WorldFlagRepository();
      for (final code in CourseService.courseAssets.keys) {
        final course = await courses.loadBundledCourse(code);
        final flag = CourseFlagService.resolve(course, fallbackCode: code);
        switch (flag.kind) {
          case ResolvedCourseFlagKind.builtIn:
            expect(
              CourseFlagService.renderableBuiltInCodes,
              contains(flag.identifier),
              reason: course.title,
            );
          case ResolvedCourseFlagKind.worldFlag:
            expect(
              await worldFlags.findById(flag.identifier),
              isNotNull,
              reason: course.title,
            );
          case ResolvedCourseFlagKind.customImage ||
              ResolvedCourseFlagKind.neutral:
            fail('${course.title} has no drawable flag.');
        }
      }
      final edge = await courses.loadBundledCourse('EN_EDGE');
      expect(edge.flagCode, 'EN');
    },
  );

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
    final other = await service.loadBundledCourse('PMS');
    final visibility = CourseLearnerVisibilityService();
    await expectLater(visibility.setHidden(edge, true), throwsStateError);
    await visibility.setHidden(other, true);
    expect(await visibility.isHidden(other.courseId), isTrue);
    expect(await visibility.isHidden(edge.courseId), isFalse);
    expect(await SettingsService().getLastSelectedCourseCode(), 'EN_EDGE');
  });
}
