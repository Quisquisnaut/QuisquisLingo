import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/screens/statistics_screen.dart';
import 'package:quisquislingo_app/services/learning_activity_service.dart';
import 'package:quisquislingo_app/services/learning_language_identity.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/widgets/flag_art.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    '228.02 regional variants share canonical language statistics',
    () async {
      final profiles = ProfileService();
      await profiles.addProfile('Statistics Learner');
      var now = DateTime(2026, 9, 1, 10);
      final activity = LearningActivityService(now: () => now);

      await activity.registerLearningActivity(courseCode: 'en-US');
      now = DateTime(2026, 9, 2, 12);
      await activity.registerLearningActivity(courseCode: 'de');
      now = DateTime(2026, 9, 3, 9);
      await activity.registerLearningActivity(courseCode: 'en_GB');
      now = DateTime(2026, 9, 5, 18);
      await activity.registerLearningActivity(courseCode: 'English');

      final statistics = await activity.getStatistics();
      expect(statistics.totalStudyDays, 4);
      expect(statistics.languages.map((language) => language.languageId), [
        'en',
        'de',
      ]);
      final english = statistics.languages.first;
      expect(english.studyDays, 3);
      expect(english.currentStreak, 1);
      expect(english.maxStreak, 2);
      final german = statistics.languages.last;
      expect(german.studyDays, 1);
      expect(german.currentStreak, 0);
      expect(german.maxStreak, 1);

      final prefs = await SharedPreferences.getInstance();
      final prefix = ProfileService.prefixForProfileId(
        (await profiles.getActiveProfileId())!,
      );
      expect(prefs.getStringList('${prefix}study_days_EN'), [
        '2026-09-01',
        '2026-09-03',
        '2026-09-05',
      ]);
      expect(
        prefs.getKeys().where(
          (key) => key.contains('study_days_EN-US') || key.contains('EN-GB'),
        ),
        isEmpty,
      );
    },
  );

  test(
    '228.02 statistics remain isolated by opaque learner identity',
    () async {
      final profiles = ProfileService();
      var now = DateTime(2026, 9, 1, 10);
      await profiles.addProfile('First Learner');
      final first = LearningActivityService(now: () => now);
      await first.registerLearningActivity(courseCode: 'it');

      await profiles.addProfile('Second Learner');
      final second = LearningActivityService(now: () => now);
      expect((await second.getStatistics()).totalStudyDays, 0);
      await second.registerLearningActivity(courseCode: 'it-IT');
      now = DateTime(2026, 9, 2, 10);
      await second.registerLearningActivity(courseCode: 'it-CH');

      expect((await second.getStatistics()).totalStudyDays, 2);
      await profiles.setActiveProfile('First Learner');
      final restored = await first.getStatistics();
      expect(restored.totalStudyDays, 1);
      expect(restored.languages.single.studyDays, 1);
    },
  );

  test(
    '228.02 canonical language identity preserves QQL language families',
    () {
      expect(LearningLanguageIdentity.canonicalId('en-US'), 'en');
      expect(LearningLanguageIdentity.canonicalId('en_GB'), 'en');
      expect(LearningLanguageIdentity.canonicalId('English'), 'en');
      expect(LearningLanguageIdentity.canonicalId('Korean'), 'ko');
      expect(LearningLanguageIdentity.displayName('cy'), 'Welsh');
    },
  );

  testWidgets('228.02 Statistics page shows all required language fields', (
    tester,
  ) async {
    await ProfileService().addProfile('Statistics Learner');
    final activity = LearningActivityService(
      now: () => DateTime(2026, 9, 8, 12),
    );
    await activity.registerLearningActivity(courseCode: 'en-GB');

    await tester.pumpWidget(
      MaterialApp(home: StatisticsScreen(learningActivityService: activity)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Statistics'), findsOneWidget);
    expect(find.text('Total Study Days'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.textContaining('en\n'), findsOneWidget);
    expect(find.textContaining('Study Days 1'), findsOneWidget);
    expect(find.textContaining('Current Streak 1'), findsOneWidget);
    expect(find.textContaining('Max Streak 1'), findsOneWidget);
    final flag = tester.widget<FlagBadge>(find.byType(FlagBadge));
    expect(flag.code, 'EN');
  });
}
