import 'package:flutter/material.dart';
import '../services/alpha_lifecycle_service.dart';
import '../widgets/alpha_expired_view.dart';
import '../models/course_models.dart';
import '../services/progress_service.dart';
import 'round_screen.dart';
import '../widgets/learner_shell.dart';

class ReviewScreen extends StatefulWidget {
  final Course course;
  final String courseCode;

  const ReviewScreen({
    super.key,
    required this.course,
    required this.courseCode,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  final _progress = ProgressService();
  List<RecentRoundEntry> _recent = [];
  Set<String> _perfect = {};
  Set<String> _ttsSkippedPerfect = {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final entries = await _progress.getRecentRounds(
      courseId: widget.course.courseId,
      limit: 50,
    );
    final perfect = await _progress.getPerfectRounds(
      courseId: widget.course.courseId,
    );
    final skipped = await _progress.getTtsSkippedPerfectRounds(
      courseId: widget.course.courseId,
    );
    if (mounted) {
      setState(() {
        _recent = entries;
        _perfect = perfect;
        _ttsSkippedPerfect = skipped;
      });
    }
  }

  _RoundLocation? _findRound(String lessonId, String roundId) {
    final lessonIndex = widget.course.lessons.indexWhere(
      (lesson) => lesson.lessonId == lessonId,
    );
    if (lessonIndex < 0) return null;
    final lesson = widget.course.lessons[lessonIndex];
    for (var i = 0; i < lesson.rounds.length; i++) {
      final round = lesson.rounds[i];
      if (round.id == roundId) {
        return _RoundLocation(
          lessonIndex: lessonIndex,
          lesson: lesson,
          round: round,
          roundIndex: i,
        );
      }
    }
    return null;
  }

  Future<void> _open(_RoundLocation location) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RoundScreen(
          course: widget.course,
          lesson: location.lesson,
          round: location.round,
          roundIndex: location.roundIndex,
          ttsLanguage: widget.course.ttsLanguage,
        ),
      ),
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    if (AlphaLifecycleService.isExpired()) return const AlphaExpiredView();
    final resolved = <(_RoundLocation, RecentRoundEntry)>[];
    for (final entry in _recent) {
      final location = _findRound(entry.lessonId, entry.roundId);
      if (location != null) resolved.add((location, entry));
    }

    return LearnerStatusPage(
      child: Scaffold(
        appBar: LearnerStatusAppBar(
          appBar: AppBar(title: const Text('Review')),
        ),
        body: resolved.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Text(
                    'Complete some rounds first. Up to 50 recent rounds will appear here, with the rounds where you made more errors prioritized.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                itemCount: resolved.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final location = resolved[index].$1;
                  final entry = resolved[index].$2;
                  return Card(
                    child: ListTile(
                      leading: _perfect.contains(location.round.id)
                          ? const CircleAvatar(
                              child: Icon(Icons.workspace_premium_outlined),
                            )
                          : _ttsSkippedPerfect.contains(location.round.id)
                          ? const CircleAvatar(child: Icon(Icons.eco_outlined))
                          : CircleAvatar(child: Text('${entry.errors}')),
                      title: Text(
                        location.round.displayTitle(location.roundIndex),
                      ),
                      subtitle: Text(
                        'Lesson ${location.lessonIndex + 1}: ${location.lesson.title} · ${entry.errors} ${entry.errors == 1 ? 'error' : 'errors'} in latest attempt',
                      ),
                      trailing: const Icon(Icons.replay_outlined),
                      onTap: () => _open(location),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _RoundLocation {
  final int lessonIndex;
  final Lesson lesson;
  final LearningRound round;
  final int roundIndex;

  const _RoundLocation({
    required this.lessonIndex,
    required this.lesson,
    required this.round,
    required this.roundIndex,
  });
}
