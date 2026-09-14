import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/screens/statistics_screen.dart';
import 'package:quisquislingo_app/services/learning_activity_service.dart';
import 'package:quisquislingo_app/services/world_flag_repository.dart';
import 'package:quisquislingo_app/widgets/flag_art.dart';
import 'package:quisquislingo_app/widgets/world_flag_art.dart';

void main() {
  testWidgets('Neapolitan statistics use the language-related World Flag', (
    tester,
  ) async {
    final worldFlags = WorldFlagRepository();
    final manifest = (await tester.runAsync(worldFlags.loadManifest))!;
    expect(
      WorldFlagRepository.suggestForLanguage(
        manifest,
        languageTag: 'nap',
      ).first.id,
      'neapolitan',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: StatisticsScreen(
          learningActivityService: _FixedStatisticsService(
            const LearnerStatistics(
              totalStudyDays: 1,
              languages: [
                LanguageLearningStatistics(
                  languageId: 'nap',
                  studyDays: 1,
                  currentStreak: 1,
                  maxStreak: 1,
                ),
              ],
            ),
          ),
          worldFlagRepository: worldFlags,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    final art = tester.widget<WorldFlagArt>(find.byType(WorldFlagArt));
    expect(art.entity.id, 'neapolitan');
    expect(find.byType(FlagBadge), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _FixedStatisticsService extends LearningActivityService {
  final LearnerStatistics result;

  _FixedStatisticsService(this.result)
    : super(now: () => DateTime(2026, 9, 13));

  @override
  Future<LearnerStatistics> getStatistics() async => result;
}
