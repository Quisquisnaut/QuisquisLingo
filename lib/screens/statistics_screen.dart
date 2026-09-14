import 'package:flutter/material.dart';

import '../models/world_flag_entity.dart';
import '../services/learning_activity_service.dart';
import '../services/learning_language_identity.dart';
import '../services/world_flag_repository.dart';
import '../widgets/flag_art.dart';
import '../widgets/world_flag_art.dart';

class StatisticsScreen extends StatefulWidget {
  final LearningActivityService? learningActivityService;
  final WorldFlagRepository? worldFlagRepository;

  const StatisticsScreen({
    super.key,
    this.learningActivityService,
    this.worldFlagRepository,
  });

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late final LearningActivityService _activity;
  late final Future<WorldFlagManifest> _worldFlagManifest;
  LearnerStatistics? _statistics;

  @override
  void initState() {
    super.initState();
    _activity =
        widget.learningActivityService ??
        LearningActivityService(now: DateTime.now);
    _worldFlagManifest = (widget.worldFlagRepository ?? WorldFlagRepository())
        .loadManifest();
    _load();
  }

  Future<void> _load() async {
    final statistics = await _activity.getStatistics();
    if (!mounted) return;
    setState(() => _statistics = statistics);
  }

  @override
  Widget build(BuildContext context) {
    final statistics = _statistics;
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: statistics == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                ListTile(
                  key: const Key('statistics-total-study-days'),
                  leading: const Icon(Icons.calendar_month_outlined),
                  title: const Text('Total Study Days'),
                  trailing: Text(
                    '${statistics.totalStudyDays}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Divider(),
                if (statistics.languages.isEmpty)
                  const ListTile(
                    title: Text('No language statistics yet.'),
                    subtitle: Text(
                      'Complete a Round to record the first Study Day.',
                    ),
                  )
                else
                  for (final language in statistics.languages)
                    _LanguageStatisticsTile(
                      statistics: language,
                      worldFlagManifest: _worldFlagManifest,
                    ),
              ],
            ),
    );
  }
}

class _LanguageStatisticsTile extends StatelessWidget {
  final LanguageLearningStatistics statistics;
  final Future<WorldFlagManifest> worldFlagManifest;

  const _LanguageStatisticsTile({
    required this.statistics,
    required this.worldFlagManifest,
  });

  @override
  Widget build(BuildContext context) {
    final name = LearningLanguageIdentity.displayName(statistics.languageId);
    return Semantics(
      label: '$name language statistics',
      child: ListTile(
        key: ValueKey('statistics-language-${statistics.languageId}'),
        isThreeLine: true,
        leading: _LanguageStatisticsFlag(
          languageId: statistics.languageId,
          languageName: name,
          worldFlagManifest: worldFlagManifest,
        ),
        title: Text(name),
        subtitle: Text(
          '${statistics.languageId}\n'
          'Study Days ${statistics.studyDays} · '
          'Current Streak ${statistics.currentStreak} · '
          'Max Streak ${statistics.maxStreak}',
        ),
      ),
    );
  }
}

class _LanguageStatisticsFlag extends StatelessWidget {
  final String languageId;
  final String languageName;
  final Future<WorldFlagManifest> worldFlagManifest;

  const _LanguageStatisticsFlag({
    required this.languageId,
    required this.languageName,
    required this.worldFlagManifest,
  });

  @override
  Widget build(BuildContext context) => FutureBuilder<WorldFlagManifest>(
    future: worldFlagManifest,
    builder: (context, snapshot) {
      final suggestions = snapshot.hasData
          ? WorldFlagRepository.suggestForLanguage(
              snapshot.data!,
              languageTag: languageId,
              languageName: languageName,
            )
          : const <WorldFlagEntity>[];
      if (suggestions.isNotEmpty) {
        return SizedBox(
          width: 44,
          height: 31,
          child: WorldFlagArt(
            key: ValueKey('statistics-world-flag-$languageId'),
            entity: suggestions.first,
            semanticsLabel: '$languageName flag',
          ),
        );
      }
      return FlagBadge(LearningLanguageIdentity.flagCode(languageId));
    },
  );
}
