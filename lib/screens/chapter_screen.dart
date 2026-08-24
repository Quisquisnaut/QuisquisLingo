import 'package:flutter/material.dart';
import '../models/course_models.dart';
import '../services/progress_service.dart';
import '../services/course_service.dart';
import '../services/settings_service.dart';
import 'topic_screen.dart';
import 'duel_screen.dart';
import '../widgets/flag_art.dart';

class ChapterScreen extends StatefulWidget {
  final Course course;
  final Chapter chapter;
  final Chapter? nextChapter;
  final String ttsLanguage;
  final bool returnToChapterListOnExit;

  const ChapterScreen({
    super.key,
    required this.course,
    required this.chapter,
    required this.nextChapter,
    required this.ttsLanguage,
    this.returnToChapterListOnExit = false,
  });

  @override
  State<ChapterScreen> createState() => _ChapterScreenState();
}

class _ChapterScreenState extends State<ChapterScreen> {
  final _progress = ProgressService();
  final _settings = SettingsService();
  Set<String> _completedTopics = {};
  Set<String> _completedRounds = {};
  Set<String> _wonDuels = {};

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final completed = await _progress.getCompletedTopics(
      courseId: widget.course.courseId,
    );
    final completedRounds = await _progress.getCompletedRounds(
      courseId: widget.course.courseId,
    );
    final duels = await _progress.getWonDuels(courseId: widget.course.courseId);
    if (!mounted) return;
    setState(() {
      _completedTopics = completed;
      _completedRounds = completedRounds;
      _wonDuels = duels;
    });
  }

  Future<void> _openTopic(Topic topic) async {
    await _settings.setLastVisitedTopicId(widget.course.courseId, topic.id);
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TopicScreen(
          course: widget.course,
          chapter: widget.chapter,
          topic: topic,
          ttsLanguage: widget.ttsLanguage,
        ),
      ),
    );
    await _reload();
  }

  Future<void> _openDuel() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DuelScreen(
          course: widget.course,
          chapter: widget.chapter,
          ttsLanguage: widget.ttsLanguage,
        ),
      ),
    );
    await _reload();
  }

  void _handleBack() {
    Navigator.of(context).pop(widget.returnToChapterListOnExit);
  }

  @override
  Widget build(BuildContext context) {
    final learningTopics = widget.chapter.learningTopics;
    final done = learningTopics
        .where((t) => _completedTopics.contains(t.id))
        .length;
    final duelWon = _wonDuels.contains(widget.chapter.duel.id);
    final total = learningTopics.length;

    final chapterIndex = widget.course.chapters.indexWhere(
      (c) => c.id == widget.chapter.id,
    );
    final chapterNumber = chapterIndex >= 0 ? chapterIndex + 1 : 1;

    return PopScope(
      canPop: !widget.returnToChapterListOnExit,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && widget.returnToChapterListOnExit) {
          _handleBack();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(onPressed: _handleBack),
          toolbarHeight: 68,
          title: Text(
            'Chapter $chapterNumber: ${widget.chapter.title}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          backgroundColor: Colors.transparent,
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CourseFlagBackdrop(
                  course: widget.course,
                  fallbackCode: CourseService.codeForCourse(widget.course),
                  opacity: .90,
                ),
              ),
            ),
            const Positioned.fill(
              child: IgnorePointer(child: ColoredBox(color: Color(0x16FFFDF7))),
            ),
            ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
              children: [
                if (widget.chapter.temporarySample)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      label: Text(
                        'TEMPORARY SAMPLE',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                Text(
                  '$done/$total topics completed',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: total == 0 ? 0 : done / total),
                const SizedBox(height: 12),
                const _FreedomCard(),
                const SizedBox(height: 22),
                _TopicTree(
                  topics: learningTopics,
                  completedTopics: _completedTopics,
                  completedRounds: _completedRounds,
                  onTap: _openTopic,
                ),
                const SizedBox(height: 24),
                if (widget.nextChapter != null)
                  _DuelGate(
                    duelWon: duelWon,
                    nextTitle: widget.nextChapter!.title,
                    onTap: _openDuel,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FreedomCard extends StatelessWidget {
  const _FreedomCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.alt_route),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jump freely around the tree',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TopicTree extends StatelessWidget {
  final List<Topic> topics;
  final Set<String> completedTopics;
  final Set<String> completedRounds;
  final ValueChanged<Topic> onTap;

  const _TopicTree({
    required this.topics,
    required this.completedTopics,
    required this.completedRounds,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(topics.length, (index) {
        final topic = topics[index];
        final complete = completedTopics.contains(topic.id);
        final completedRoundCount = topic.rounds
            .where((round) => completedRounds.contains(round.id))
            .length;
        final left = index.isEven;
        return Column(
          children: [
            if (index > 0)
              Container(width: 3, height: 22, color: const Color(0x664F622D)),
            Align(
              alignment: left ? Alignment.centerLeft : Alignment.centerRight,
              child: FractionallySizedBox(
                widthFactor: 0.72,
                child: Card(
                  color: Colors.white.withValues(alpha: .55),
                  surfaceTintColor: Colors.transparent,
                  elevation: 0,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => onTap(topic),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          CircleAvatar(
                            backgroundColor: const Color(0x184F622D),
                            child: Icon(complete ? Icons.check : Icons.eco),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  topic.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  '$completedRoundCount/${topic.rounds.length} rounds completed',
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _DuelGate extends StatelessWidget {
  final bool duelWon;
  final String nextTitle;
  final VoidCallback onTap;

  const _DuelGate({
    required this.duelWon,
    required this.nextTitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white.withValues(alpha: .32),
      surfaceTintColor: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Icon(
                duelWon ? Icons.lock_open : Icons.sports_martial_arts,
                size: 34,
              ),
              const SizedBox(height: 8),
              Text(
                'Language Duel',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                duelWon
                    ? 'Duel won. $nextTitle is unlocked.'
                    : 'Win the duel to test out to next chapter',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onTap,
                child: Text(duelWon ? 'Play again' : 'Start Duel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
