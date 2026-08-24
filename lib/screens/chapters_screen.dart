import 'package:flutter/material.dart';
import '../models/course_models.dart';
import '../services/progress_service.dart';
import '../services/unlock_service.dart';
import '../services/course_service.dart';
import '../services/settings_service.dart';
import '../services/crash_log_service.dart';
import 'chapter_screen.dart';

class ChaptersScreen extends StatefulWidget {
  final Course course;
  const ChaptersScreen({super.key, required this.course});
  @override
  State<ChaptersScreen> createState() => _ChaptersScreenState();
}

class _ChaptersScreenState extends State<ChaptersScreen> {
  final _progress = ProgressService();
  final _unlock = UnlockService();
  final _settings = SettingsService();
  Set<String> _completed = {};
  Set<String> _duels = {};
  bool _iddqdMode = false;

  @override
  void initState() {
    super.initState();
    _reload();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _showCourseUpdateIfNeeded(),
    );
  }

  Future<void> _showCourseUpdateIfNeeded() async {
    final code = CourseService.codeForCourse(widget.course);
    if (!await _settings.shouldShowCourseUpdate(
      code,
      widget.course.contentRevision,
    )) {
      return;
    }
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Course updated'),
        content: Text(
          widget.course.updateSummary.trim().isEmpty
              ? 'This course has been updated since your last visit. Chapters, Topics, Rounds or exercises may have changed.'
              : widget.course.updateSummary,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK, got it'),
          ),
        ],
      ),
    );
    await _settings.markCourseUpdateSeen(code, widget.course.contentRevision);
  }

  Future<void> _reload() async {
    final completed = await _progress.getCompletedTopics(
      courseId: widget.course.courseId,
    );
    final duels = await _progress.getWonDuels(courseId: widget.course.courseId);
    final iddqdMode = await _settings.isIddqdModeEnabled(
      widget.course.courseId,
    );
    if (!mounted) return;
    setState(() {
      _completed = completed;
      _duels = duels;
      _iddqdMode = iddqdMode;
    });
  }

  Future<void> _showGuidebookAvailabilityNoticeIfNeeded() async {
    if (await _progress.hasSeenGuidebookAvailabilityNotice()) return;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Topic Guidebooks'),
        content: const Text(
          'Every learning Topic includes its own Guidebook with explanations and reference material. '
          'Open a Topic and use OPEN TOPIC GUIDEBOOK whenever you want its reference material.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
    await _progress.markGuidebookAvailabilityNoticeSeen();
  }

  Future<void> _open(int index) async {
    final chapters = widget.course.chapters;
    final chapter = chapters[index];

    // The first Chapter visit explains Topic Guidebooks, but never diverts the learner
    // away from the Chapter topics. Guidebooks are opened only on explicit tap from a Topic.
    await CrashLogService.instance.recordDebugEvent(
      'Chapters: opening Chapter ${chapter.id}',
    );
    await _settings.setLastVisitedChapterId(widget.course.courseId, chapter.id);
    await _showGuidebookAvailabilityNoticeIfNeeded();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChapterScreen(
          course: widget.course,
          chapter: chapter,
          nextChapter: index + 1 < chapters.length ? chapters[index + 1] : null,
          ttsLanguage: widget.course.ttsLanguage,
          returnToChapterListOnExit: false,
        ),
      ),
    );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.course.title),
            if (widget.course.authors.isNotEmpty ||
                widget.course.author.trim().isNotEmpty)
              Text(
                'Course by ${widget.course.authors.isNotEmpty ? widget.course.authors.map((a) => a.name).join(', ') : widget.course.author.trim()}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
          ],
        ),
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF7D6), Color(0xFFEAF5D7), Color(0xFFFFE6CF)],
          ),
        ),
        child: SafeArea(
          top: false,
          child: widget.course.chapters.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.menu_book_outlined, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          '${widget.course.targetLanguage} course in preparation',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'This course is currently empty. Course creators can add Chapters, Topics, Rounds and exercises in Course Editor.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                  itemCount: widget.course.chapters.length,
                  itemBuilder: (context, index) {
                    final chapter = widget.course.chapters[index];
                    final genuinelyUnlocked = _unlock.isChapterUnlocked(
                      chapterIndex: index,
                      course: widget.course,
                      completedTopics: _completed,
                      wonDuels: _duels,
                    );
                    final unlocked = genuinelyUnlocked || _iddqdMode;
                    final learningTopics = chapter.learningTopics;
                    final done = learningTopics
                        .where((t) => _completed.contains(t.id))
                        .length;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      color: const Color(0xEEFFFFFF),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: unlocked ? () => _open(index) : null,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                child: Icon(
                                  genuinelyUnlocked
                                      ? Icons.eco
                                      : Icons.lock_outline,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Chapter ${index + 1}: ${chapter.title}',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$done/${learningTopics.length} topics completed',
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.chevron_right),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
