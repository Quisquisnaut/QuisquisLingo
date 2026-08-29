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
