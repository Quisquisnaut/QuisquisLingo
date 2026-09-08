import 'package:flutter/material.dart';

import '../services/learning_activity_service.dart';
import '../services/learning_language_identity.dart';
import '../widgets/flag_art.dart';

class StatisticsScreen extends StatefulWidget {
  final LearningActivityService? learningActivityService;

  const StatisticsScreen({super.key, this.learningActivityService});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  late final LearningActivityService _activity;
  LearnerStatistics? _statistics;

  @override
  void initState() {
    super.initState();
    _activity =
        widget.learningActivityService ??
        LearningActivityService(now: DateTime.now);
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
                    _LanguageStatisticsTile(statistics: language),
              ],
            ),
    );
  }
}

class _LanguageStatisticsTile extends StatelessWidget {
  final LanguageLearningStatistics statistics;

  const _LanguageStatisticsTile({required this.statistics});

  @override
  Widget build(BuildContext context) {
    final name = LearningLanguageIdentity.displayName(statistics.languageId);
    return Semantics(
      label: '$name language statistics',
      child: ListTile(
        key: ValueKey('statistics-language-${statistics.languageId}'),
        isThreeLine: true,
        leading: FlagBadge(
          LearningLanguageIdentity.flagCode(statistics.languageId),
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
