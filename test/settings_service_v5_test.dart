import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('last Lesson remains isolated by learner and Course', () async {
    final profiles = ProfileService();
    final settings = SettingsService();
    await profiles.addProfile('Alice');

    await settings.setLastVisitedLessonId('course_a', 'lesson_a2');
    await settings.setLastVisitedLessonId('course_b', 'lesson_b3');
    expect(await settings.getLastVisitedLessonId('course_a'), 'lesson_a2');
    expect(await settings.getLastVisitedLessonId('course_b'), 'lesson_b3');

    await profiles.addProfile('Bob');
    expect(await settings.getLastVisitedLessonId('course_a'), isNull);
    await settings.setLastVisitedLessonId('course_a', 'lesson_a1');

    await profiles.setActiveProfile('Alice');
    expect(await settings.getLastVisitedLessonId('course_a'), 'lesson_a2');
    expect(await settings.getLastVisitedLessonId('course_b'), 'lesson_b3');

    final prefs = await SharedPreferences.getInstance();
    final aliceId = (await profiles.getProfileRecords())
        .singleWhere((profile) => profile.displayName == 'Alice')
        .learnerProfileId;
    final alicePrefix = ProfileService.prefixForProfileId(aliceId);
    expect(prefs.getString('${alicePrefix}last_lesson_course_a'), 'lesson_a2');
    expect(prefs.getKeys().where((key) => key.contains('last_topic')), isEmpty);
    expect(
      prefs.getKeys().where((key) => key.contains('last_chapter')),
      isEmpty,
    );
  });

  test(
    'last active course remains isolated through switching logout and restart',
    () async {
      final profiles = ProfileService();
      final settings = SettingsService();

      await profiles.addProfile('Learner A');
      final learnerAId = (await profiles.getActiveProfileId())!;
      await settings.setLastSelectedCourseCode('IT');
      await profiles.addProfile('Learner B');
      final learnerBId = (await profiles.getActiveProfileId())!;
      await settings.setLastSelectedCourseCode('DE');

      expect(await settings.getLastSelectedCourseCode(), 'DE');
      await profiles.setActiveProfile('Learner A');
      expect(await settings.getLastSelectedCourseCode(), 'IT');
      await settings.setLastSelectedCourseCode('ES');

      await profiles.setActiveProfile('Learner B');
      expect(await settings.getLastSelectedCourseCode(), 'DE');
      await profiles.setActiveProfile('Learner A');
      expect(await settings.getLastSelectedCourseCode(), 'ES');

      await profiles.clearActiveProfile();
      expect(await settings.getLastSelectedCourseCode(), isNull);
      await profiles.setActiveProfile('Learner B');
      expect(await SettingsService().getLastSelectedCourseCode(), 'DE');
      await profiles.setActiveProfile('Learner A');
      expect(await SettingsService().getLastSelectedCourseCode(), 'ES');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('last_selected_course_code'), isNull);
      expect(
        prefs.getString(
          profiles.keyForProfileId(learnerAId, 'last_selected_course_code'),
        ),
        'ES',
      );
      expect(
        prefs.getString(
          profiles.keyForProfileId(learnerBId, 'last_selected_course_code'),
        ),
        'DE',
      );
    },
  );

  test(
    'recent courses keep current-first device history for the selector',
    () async {
      final settings = SettingsService();
      for (final ref in ['IT', 'DE', 'custom:one', 'ES', 'FI']) {
        await settings.setLastSelectedCourseCode(ref);
      }
      expect(await settings.getRecentCourseRefs(), [
        'FI',
        'ES',
        'custom:one',
        'DE',
      ]);

      await settings.setLastSelectedCourseCode('custom:one');
      expect(await settings.getRecentCourseRefs(), [
        'custom:one',
        'FI',
        'ES',
        'DE',
      ]);
    },
  );

  test('IDDQD remains isolated by opaque learner ID and Course ID', () async {
    final profiles = ProfileService();
    final settings = SettingsService();
    await profiles.addProfile('Alice');
    final aliceId = (await profiles.getActiveProfileId())!;

    await settings.setIddqdModeEnabled('course_a', true);
    expect(await settings.isIddqdModeEnabled('course_a'), isTrue);
    expect(await settings.isIddqdModeEnabled('course_b'), isFalse);

    await profiles.addProfile('Bob');
    expect(await settings.isIddqdModeEnabled('course_a'), isFalse);
    await settings.setIddqdModeEnabled('course_b', true);

    await profiles.setActiveProfile('Alice');
    expect(await settings.isIddqdModeEnabled('course_a'), isTrue);
    expect(await settings.isIddqdModeEnabled('course_b'), isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getBool(profiles.keyForProfileId(aliceId, 'iddqd_course_a')),
      isTrue,
    );
  });
}
