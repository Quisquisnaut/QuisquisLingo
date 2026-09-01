import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('last Topic remains isolated by learner and Course', () async {
    final profiles = ProfileService();
    final settings = SettingsService();
    await profiles.addProfile('Alice');

    await settings.setLastVisitedTopicId('course_a', 'topic_a2');
    await settings.setLastVisitedTopicId('course_b', 'topic_b3');
    expect(await settings.getLastVisitedTopicId('course_a'), 'topic_a2');
    expect(await settings.getLastVisitedTopicId('course_b'), 'topic_b3');

    await profiles.addProfile('Bob');
    expect(await settings.getLastVisitedTopicId('course_a'), isNull);
    await settings.setLastVisitedTopicId('course_a', 'topic_a1');

    await profiles.setActiveProfile('Alice');
    expect(await settings.getLastVisitedTopicId('course_a'), 'topic_a2');
    expect(await settings.getLastVisitedTopicId('course_b'), 'topic_b3');

    final prefs = await SharedPreferences.getInstance();
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
      await settings.setLastSelectedCourseCode('IT');
      await profiles.addProfile('Learner B');
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
        prefs.getString('learner_Learner%20A_last_selected_course_code'),
        'ES',
      );
      expect(
        prefs.getString('learner_Learner%20B_last_selected_course_code'),
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
}
