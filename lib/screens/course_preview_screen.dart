part of 'home_screen.dart';

/// The learner page on the Course Editor's working copy (Build 261 Revision
/// 2, owner decisions of 1 October 2026).
///
/// It shows [course] as it is, Draft content included, on a clean slate:
/// no Round completed, no Laurel, every Lesson open. Rounds, Stories, the
/// GuideBook and the Duel open in their Preview modes, which record nothing.
/// The screen writes no learner state, so the stored current Course is
/// unchanged, and Exit pops back to the editor screen that opened it with the
/// session's changes still pending.
///
/// Revision 4 (owner decisions of 2 October 2026): a coloured PREVIEW bar
/// with Exit says where the learner is; only the controls that work are
/// shown (Course Info, Theme, Flag background); Theme and Flag background
/// start from the active learner's and change for this preview only.
class CoursePreviewScreen extends StatefulWidget {
  const CoursePreviewScreen({super.key, required this.course});

  final Course course;

  /// The PREVIEW bar's colour, the same in light and dark.
  static const barColor = Color(0xFFFFB300);

  @override
  State<CoursePreviewScreen> createState() => _CoursePreviewScreenState();
}

class _CoursePreviewScreenState extends State<CoursePreviewScreen> {
  /// Null until the learner's choice is known (the app's appearance).
  bool? _dark;
  var _flagBackground = LearnerFlagBackgroundMode.off;

  Course get course => widget.course;

  String get _code => CourseService.codeForCourse(course);

  String get _ttsLanguage => CourseLanguageResolver.learning(course).code ?? '';

  @override
  void initState() {
    super.initState();
    _loadFlagBackground();
  }

  /// Reads the active learner's Flag background for this Course; nothing is
  /// written back.
  Future<void> _loadFlagBackground() async {
    try {
      final mode = await ProfileService().getFlagBackgroundMode(
        course.courseId,
      );
      if (mounted) setState(() => _flagBackground = mode);
    } catch (_) {
      // The preview keeps Off when the learner's choice cannot be read.
    }
  }

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

  Widget _previewBar(BuildContext context) => Material(
    key: const Key('course-preview-bar'),
    color: CoursePreviewScreen.barColor,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 8, 6),
      child: Row(
        children: [
          const Icon(Icons.visibility_outlined, color: Colors.black87),
          const SizedBox(width: 10),
          Expanded(
            child: Text.rich(
              const TextSpan(
                children: [
                  TextSpan(
                    text: 'PREVIEW',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  TextSpan(
                    text: ' · As a learner sees it · nothing is recorded',
                  ),
                ],
              ),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.black87),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.icon(
            key: const Key('course-preview-exit'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: CoursePreviewScreen.barColor,
            ),
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            label: const Text('Exit'),
          ),
        ],
      ),
    ),
  );

  Widget _header(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
    child: Row(
      children: [
        Course.coverImagePattern.hasMatch(course.coverImage)
            ? CourseArtwork(course: course, size: 40)
            : CourseFlagBadge(
                course: course,
                fallbackCode: _code,
                width: 40,
                height: 28,
              ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            course.title,
            key: const Key('course-preview-title'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );

  Widget _roundButton({
    required Key key,
    required String tooltip,
    required IconData icon,
    required VoidCallback onPressed,
  }) => IconButton.filledTonal(
    key: key,
    tooltip: tooltip,
    onPressed: onPressed,
    icon: Icon(icon),
  );

  Widget _bottomBar(BuildContext context, bool dark) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
    child: Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 4,
      children: [
        TextButton.icon(
          key: const Key('course-preview-course-info'),
          onPressed: () => Navigator.of(context).push<void>(
            MaterialPageRoute(builder: (_) => CourseInfoScreen(course: course)),
          ),
          icon: const Icon(Icons.info_outline),
          label: const Text('Course Info'),
        ),
        _roundButton(
          key: const Key('course-preview-theme'),
          tooltip: dark ? 'Theme: Dark' : 'Theme: Light',
          icon: dark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
          onPressed: () => setState(() => _dark = !dark),
        ),
        _roundButton(
          key: const Key('course-preview-flag-background'),
          tooltip: 'Flag background: ${_flagBackground.label}',
          icon: switch (_flagBackground) {
            LearnerFlagBackgroundMode.small => Icons.flag_outlined,
            LearnerFlagBackgroundMode.off => Icons.hide_image_outlined,
            LearnerFlagBackgroundMode.extended => Icons.flag,
            LearnerFlagBackgroundMode.tinted =>
              Icons.format_color_fill_outlined,
            LearnerFlagBackgroundMode.softInspired => Icons.gradient_outlined,
          },
          onPressed: () =>
              setState(() => _flagBackground = _flagBackground.next),
        ),
      ],
    ),
  );

  /// The flag behind the page, drawn as on the learner page.
  List<Widget> _background(ThemeData theme, bool dark) =>
      switch (_flagBackground) {
        LearnerFlagBackgroundMode.small ||
        LearnerFlagBackgroundMode.extended => [
          CourseFlagBackdrop(
            key: const Key('course-preview-flag-backdrop'),
            course: course,
            fallbackCode: _code,
            opacity: 1,
            fit: _flagBackground == LearnerFlagBackgroundMode.extended
                ? BoxFit.cover
                : BoxFit.contain,
          ),
          ColoredBox(
            color: theme.colorScheme.surface.withValues(
              alpha: dark
                  ? learnerDarkFlagVeilOpacity
                  : learnerLightFlagVeilOpacity,
            ),
          ),
        ],
        LearnerFlagBackgroundMode.tinted ||
        LearnerFlagBackgroundMode.softInspired => [
          CourseFlagInspiredBackground(
            key: const Key('course-preview-flag-inspired'),
            course: course,
            fallbackCode: _code,
            brightness: dark ? Brightness.dark : Brightness.light,
            mode: _flagBackground,
          ),
        ],
        LearnerFlagBackgroundMode.off => const [],
      };

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

  /// The app's light theme, whatever the app shows now: the preview's Theme
  /// button may differ from the learner's.
  ThemeData _lightTheme(BuildContext context) =>
      context.findAncestorWidgetOfExactType<MaterialApp>()?.theme ??
      ThemeData.light(useMaterial3: true);

  @override
  Widget build(BuildContext context) {
    final dark = _dark ?? _usesDarkLearnerAppearance(context);
    final mode = dark ? LearnerThemeMode.dark : LearnerThemeMode.light;
    return LearnerThemeModeScope(
      mode: mode,
      child: Builder(
        builder: (scoped) {
          final theme = dark
              ? _unifiedLearnerTheme(scoped)
              : _lightTheme(scoped);
          return Theme(
            data: theme,
            child: Builder(
              builder: (context) => Scaffold(
                key: const Key('course-preview-page'),
                backgroundColor: dark
                    ? _learnerDarkPageBackground
                    : _learnerLightPageBackground,
                body: Stack(
                  fit: StackFit.expand,
                  children: [
                    ..._background(theme, dark),
                    SafeArea(
                      child: Column(
                        children: [
                          _previewBar(context),
                          _header(context),
                          Expanded(
                            child: LearnerPathHalo(
                              enabled:
                                  _flagBackground ==
                                      LearnerFlagBackgroundMode.small ||
                                  _flagBackground ==
                                      LearnerFlagBackgroundMode.extended,
                              child: ListView.builder(
                                key: const Key('course-preview-scroll'),
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  8,
                                  14,
                                  24,
                                ),
                                itemCount: course.lessons.isEmpty
                                    ? 1
                                    : course.lessons.length,
                                itemBuilder: (context, index) =>
                                    course.lessons.isEmpty
                                    ? const _EmptyCourseCard()
                                    : _lesson(context, index),
                              ),
                            ),
                          ),
                          _bottomBar(context, dark),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
