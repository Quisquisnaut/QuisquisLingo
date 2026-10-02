part of 'home_screen.dart';

/// The learner page on the Course Editor's working copy (Build 261 Revision
/// 2, owner decisions of 1 October 2026).
///
/// It shows [course] as it is, Draft content included, on a clean slate:
/// no Round completed, no Laurel, every Lesson open. Rounds, Stories, the
/// GuideBook and the Duel open in their Preview modes, which record nothing;
/// the Course Selector, Profile, Review and Settings are not available. The
/// screen reads and writes no learner state, so the stored current Course is
/// unchanged, and "Preview · Exit" pops back to the editor screen that opened
/// it with the session's changes still pending.
class CoursePreviewScreen extends StatelessWidget {
  const CoursePreviewScreen({super.key, required this.course});

  final Course course;

  static const _unavailable = 'Not available in the Course preview.';

  String get _ttsLanguage => CourseLanguageResolver.learning(course).code ?? '';

  Future<void> _openGuidebook(
    BuildContext context,
    Lesson lesson,
    int lessonIndex,
  ) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => GuidebookScreen(
        course: course,
        lesson: lesson,
        lessonIndex: lessonIndex,
        includeDraftContent: true,
      ),
    ),
  );

  Future<void> _openRound(
    BuildContext context,
    Lesson lesson,
    LearningRound round,
  ) => Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => RoundScreen(
        course: course,
        lesson: lesson,
        round: round,
        ttsLanguage: _ttsLanguage,
        roundIndex: lesson.rounds.indexOf(round),
        previewMode: true,
      ),
    ),
  );

  Future<void> _openDuel(BuildContext context, Lesson lesson) =>
      Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => DuelScreen(
            course: course,
            lesson: lesson,
            ttsLanguage: _ttsLanguage,
            previewMode: true,
          ),
        ),
      );

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    final artwork = Course.coverImagePattern.hasMatch(course.coverImage)
        ? CourseArtwork(course: course, size: 40)
        : CourseFlagBadge(
            course: course,
            fallbackCode: CourseService.codeForCourse(course),
            width: 40,
            height: 28,
          );
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 8, 4),
      child: Row(
        children: [
          Tooltip(
            message: 'Course Selector: $_unavailable',
            child: Opacity(
              key: const Key('course-preview-selector'),
              opacity: .6,
              child: artwork,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              course.title,
              key: const Key('course-preview-title'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ActionChip(
            key: const Key('course-preview-exit'),
            avatar: const Icon(Icons.visibility_outlined, size: 18),
            label: const Text('Preview · Exit'),
            tooltip: 'Back to the Course Editor',
            onPressed: () => Navigator.of(context).pop(),
          ),
          IconButton(
            key: const Key('course-preview-settings'),
            tooltip: 'Settings: $_unavailable',
            onPressed: null,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
    child: Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        Tooltip(
          message: 'Profile: $_unavailable',
          child: TextButton.icon(
            key: const Key('course-preview-profile'),
            onPressed: null,
            icon: const Icon(Icons.person_outline),
            label: const Text('Profile'),
          ),
        ),
        Tooltip(
          message: 'Review: $_unavailable',
          child: TextButton.icon(
            key: const Key('course-preview-review'),
            onPressed: null,
            icon: const Icon(Icons.history_outlined),
            label: const Text('Review'),
          ),
        ),
        TextButton.icon(
          key: const Key('course-preview-course-info'),
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => CourseInfoScreen(course: course)),
          ),
          icon: const Icon(Icons.info_outline),
          label: const Text('Course Info'),
        ),
      ],
    ),
  );

  Widget _lesson(BuildContext context, int lessonIndex) {
    final lesson = course.lessons[lessonIndex];
    return _LessonSection(
      key: ValueKey('course-preview-lesson-${lesson.lessonId}'),
      visibilityKey: GlobalObjectKey(lesson),
      lesson: lesson,
      course: course,
      courseId: course.courseId,
      lessonIndex: lessonIndex,
      mascotPositionOffset: learnerMascotPositionOffsetForLesson(
        course.lessons,
        lessonIndex,
      ),
      roundPositionOffset: learnerRoundPositionOffsetForLesson(
        course.lessons,
        lessonIndex,
      ),
      showBoundary: lessonIndex > 0,
      showSectionHeader: learnerShowsSectionHeader(course.lessons, lessonIndex),
      unlocked: true,
      hasAccess: true,
      isExpanded: true,
      iddqdAccessMode: null,
      previewOnly: false,
      includeDrafts: true,
      completedRounds: const {},
      perfectRounds: const {},
      ttsSkippedPerfectRounds: const {},
      roundAudioAvailability: const {},
      duelEligibility: const DuelEligibilityService().evaluate(
        lesson,
        includeDrafts: true,
      ),
      onOpenGuidebook: () => _openGuidebook(context, lesson, lessonIndex),
      onOpenRound: (round) => _openRound(context, lesson, round),
      onOpenDuel: () => _openDuel(context, lesson),
      onExpand: null,
      onLockedTap: null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = _usesDarkLearnerAppearance(context);
    return Theme(
      data: _unifiedLearnerTheme(context),
      child: Builder(
        builder: (context) => Scaffold(
          key: const Key('course-preview-page'),
          backgroundColor: dark
              ? _learnerDarkPageBackground
              : _learnerLightPageBackground,
          body: SafeArea(
            child: Column(
              children: [
                _header(context),
                Expanded(
                  child: ListView.builder(
                    key: const Key('course-preview-scroll'),
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                    itemCount: course.lessons.isEmpty
                        ? 1
                        : course.lessons.length,
                    itemBuilder: (context, index) => course.lessons.isEmpty
                        ? const _EmptyCourseCard()
                        : _lesson(context, index),
                  ),
                ),
                _bottomBar(context),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens [CoursePreviewScreen] on [course]. The preview only reads it, so
/// the editor's working copy is untouched when it closes.
Future<void> openCoursePreview(BuildContext context, Course course) =>
    Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => CoursePreviewScreen(course: course)),
    );
