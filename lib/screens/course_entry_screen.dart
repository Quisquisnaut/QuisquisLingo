import 'package:flutter/material.dart';
import '../services/alpha_lifecycle_service.dart';
import '../widgets/alpha_expired_view.dart';
import '../models/course_models.dart';
import '../services/course_service.dart';
import '../services/settings_service.dart';
import '../widgets/flag_art.dart';
import 'chapters_screen.dart';
import 'chapter_screen.dart';

/// Short language-specific transition shown after tapping Go to course.
///
/// It uses the same flag painter as the course pages so the animation remains
/// recognizable without adding video assets or fixed-size layouts.
class CourseEntryScreen extends StatefulWidget {
  final Course course;
  final bool resumeChapter;
  const CourseEntryScreen({super.key, required this.course, this.resumeChapter = false});

  @override
  State<CourseEntryScreen> createState() => _CourseEntryScreenState();
}

class _CourseEntryScreenState extends State<CourseEntryScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _animationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 760),
    );
    _start();
  }

  Future<void> _start() async {
    if(AlphaLifecycleService.isExpired())return;
    _animationsEnabled = await SettingsService().areAnimationsEnabled();
    if (!mounted) return;
    if (_animationsEnabled) _controller.forward();
    setState(() {});
    await Future<void>.delayed(_animationsEnabled ? const Duration(milliseconds: 820) : Duration.zero);
    if (!mounted) return;
    if (widget.resumeChapter && widget.course.chapters.isNotEmpty) {
      final savedChapterId = await SettingsService().getLastVisitedChapterId(widget.course.courseId);
      var selectedIndex = widget.course.chapters.indexWhere((chapter) => chapter.id == savedChapterId);
      if (selectedIndex < 0) selectedIndex = 0;
      final selectedChapter = widget.course.chapters[selectedIndex];
      await SettingsService().setLastVisitedChapterId(widget.course.courseId, selectedChapter.id);
      if (!mounted) return;
      final returnToChapterList = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => ChapterScreen(
        course: widget.course,
        chapter: selectedChapter,
        nextChapter: selectedIndex + 1 < widget.course.chapters.length
            ? widget.course.chapters[selectedIndex + 1]
            : null,
        ttsLanguage: widget.course.ttsLanguage,
        returnToChapterListOnExit: true,
      )));
      if (!mounted) return;
      if (returnToChapterList == true) {
        await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChaptersScreen(course: widget.course)));
      }
    } else {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChaptersScreen(course: widget.course)));
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if(AlphaLifecycleService.isExpired())return const AlphaExpiredView();
    final code = CourseService.codeForCourse(widget.course);
    final reducedMotion = !_animationsEnabled || (MediaQuery.maybeOf(context)?.disableAnimations ?? false);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          CourseFlagBackdrop(course: widget.course, fallbackCode: code, opacity: .94),
          ColoredBox(color: Colors.white.withValues(alpha: .14)),
          Center(
            child: reducedMotion
                ? _CourseMark(course: widget.course, code: code)
                : FadeTransition(
                    opacity: CurvedAnimation(parent: _controller, curve: Curves.easeIn),
                    child: ScaleTransition(
                      scale: Tween<double>(begin: .78, end: 1.0).animate(
                        CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
                      ),
                      child: _CourseMark(course: widget.course, code: code),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CourseMark extends StatelessWidget {
  final Course course;
  final String code;
  const _CourseMark({required this.course, required this.code});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 28),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .74),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CourseFlagBadge(course: course, fallbackCode: code, width: 76, height: 52),
            const SizedBox(height: 12),
            Text(
              course.targetLanguage,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            Text(
              '${course.sourceLanguage} → ${course.targetLanguage}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
}
