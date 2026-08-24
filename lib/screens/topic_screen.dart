import 'dart:io';
import 'package:flutter/material.dart';
import '../models/course_models.dart';
import '../services/progress_service.dart';
import '../services/course_service.dart';
import '../widgets/flag_art.dart';
import '../widgets/topic_decoration.dart';
import 'round_screen.dart';
import 'guidebook_screen.dart';

class TopicScreen extends StatefulWidget {
  final Course course;
  final Chapter chapter;
  final Topic topic;
  final String ttsLanguage;

  const TopicScreen({
    super.key,
    required this.course,
    required this.chapter,
    required this.topic,
    required this.ttsLanguage,
  });

  @override
  State<TopicScreen> createState() => _TopicScreenState();
}

class _TopicScreenState extends State<TopicScreen> {
  final _progress = ProgressService();
  Set<String> _completedRounds = {};
  Set<String> _perfectRounds = {};
  Set<String> _ttsSkippedPerfectRounds = {};

  @override
  void initState() {
    super.initState();
    _reloadRounds();
  }

  Future<void> _reloadRounds() async {
    final done = await _progress.getCompletedRounds(
      courseId: widget.course.courseId,
    );
    final perfect = await _progress.getPerfectRounds(
      courseId: widget.course.courseId,
    );
    final skipped = await _progress.getTtsSkippedPerfectRounds(
      courseId: widget.course.courseId,
    );
    if (mounted) {
      setState(() {
        _completedRounds = done;
        _perfectRounds = perfect;
        _ttsSkippedPerfectRounds = skipped;
      });
    }
  }

  Future<void> _openRound(LearningRound round) async {
    final roundIndex = widget.topic.rounds.indexOf(round);
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RoundScreen(
          course: widget.course,
          chapter: widget.chapter,
          topic: widget.topic,
          round: round,
          roundIndex: roundIndex,
          ttsLanguage: widget.ttsLanguage,
        ),
      ),
    );

    if (completed == true) await _reloadRounds();

    // Completed rounds are stored for the entire course. Count only this
    // Topic's round IDs when deciding whether the Topic itself is complete.
    final completedInTopic = widget.topic.rounds
        .where((round) => _completedRounds.contains(round.id))
        .length;
    if (widget.topic.rounds.isNotEmpty &&
        completedInTopic == widget.topic.rounds.length) {
      await _progress.completeTopic(
        widget.topic.id,
        courseId: widget.course.courseId,
        courseCode: CourseService.codeForCourse(widget.course),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 8),
            content: Text('Topic completed. +25 XP'),
          ),
        );
      }
    }
  }

  String _roundStatus(String roundId) {
    if (_perfectRounds.contains(roundId)) {
      return 'Perfect round · Laurel earned';
    }
    if (_ttsSkippedPerfectRounds.contains(roundId)) {
      return 'Zero errors · TTS exercises skipped';
    }
    if (_completedRounds.contains(roundId)) return 'Completed with errors';
    return 'Not completed';
  }

  IconData _roundIcon(String roundId) {
    if (_perfectRounds.contains(roundId)) {
      return Icons.workspace_premium_outlined;
    }
    if (_ttsSkippedPerfectRounds.contains(roundId)) return Icons.eco_outlined;
    if (_completedRounds.contains(roundId)) return Icons.check_circle_outline;
    return Icons.play_circle_outline;
  }

  @override
  Widget build(BuildContext context) {
    final code = CourseService.codeForCourse(widget.course);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.topic.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          CourseFlagBackdrop(
            course: widget.course,
            fallbackCode: code,
            opacity: .78,
          ),
          ColoredBox(color: Colors.white.withValues(alpha: .20)),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              Builder(
                builder: (context) {
                  final completedInTopic = widget.topic.rounds
                      .where((round) => _completedRounds.contains(round.id))
                      .length;
                  final totalRounds = widget.topic.rounds.length;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$completedInTopic/$totalRounds rounds completed',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        LinearProgressIndicator(
                          value: totalRounds == 0
                              ? 0
                              : completedInTopic / totalRounds,
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    final chapterIndex = widget.course.chapters.indexWhere(
                      (chapter) => chapter.id == widget.chapter.id,
                    );
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GuidebookScreen(
                          chapter: widget.chapter,
                          topic: widget.topic,
                          chapterNumber: chapterIndex < 0
                              ? 1
                              : chapterIndex + 1,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Text('OPEN TOPIC GUIDEBOOK'),
                ),
              ),
              const SizedBox(height: 14),
              if (widget.topic.imageAsset.isNotEmpty) ...[
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 170,
                      maxWidth: 260,
                    ),
                    child: widget.topic.imageAsset.startsWith('assets/')
                        ? Image.asset(
                            widget.topic.imageAsset,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Card(
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: Text('Topic image asset is missing.'),
                              ),
                            ),
                          )
                        : (File(widget.topic.imageAsset).existsSync()
                              ? Image.file(
                                  File(widget.topic.imageAsset),
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) => const Card(
                                    child: Padding(
                                      padding: EdgeInsets.all(12),
                                      child: Text(
                                        'Topic image asset is unreadable.',
                                      ),
                                    ),
                                  ),
                                )
                              : const Card(
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Icon(Icons.broken_image_outlined),
                                        Text('Topic image asset is missing.'),
                                      ],
                                    ),
                                  ),
                                )),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              for (final round in widget.topic.rounds)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Card(
                    color: Colors.white.withValues(alpha: .70),
                    child: ListTile(
                      leading: Icon(_roundIcon(round.id)),
                      title: Text(
                        round.title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_roundStatus(round.id)),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: _completedRounds.contains(round.id) ? 1 : 0,
                          ),
                        ],
                      ),
                      onTap: () => _openRound(round),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              TopicDecoration(variant: widget.topic.id.hashCode),
            ],
          ),
        ],
      ),
    );
  }
}
