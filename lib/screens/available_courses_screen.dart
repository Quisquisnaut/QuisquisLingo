import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../localization/help/help_structure.dart';
import '../localization/help/help_text.dart';
import '../localization/locale_builder.dart';
import '../localization/locale_service.dart';
import '../models/course_draft_status.dart';
import '../models/course_models.dart';
import '../services/course_library_categories.dart';
import '../services/course_editor_service.dart';
import '../services/course_favorite_service.dart';
import '../services/course_file_store.dart';
import '../services/course_learner_visibility_service.dart';
import '../services/course_library_presentation.dart';
import '../services/course_library_service.dart';
import '../services/course_media_store.dart';
import '../services/course_service.dart';
import '../services/progress_service.dart';
import '../widgets/app_locale_selector.dart';
import '../widgets/course_library_row.dart';
import '../widgets/course_library_section.dart';
import 'course_info_screen.dart';

/// The QQL Course web site. None exists yet, so Find Courses on the web stays
/// hidden until this is set.
const Uri? courseLibraryWebSite = null;

/// The English Help text remains readable for existing callers and tests.
String get availableCoursesHelp => availableCoursesHelpFor(AppLocale.english);

/// A missing translated leaf falls back to English without changing Locale.
String availableCoursesHelpFor(AppLocale locale) {
  String text(String key) => helpText.lookup(locale, 'allCoursesHelp.$key');
  return [
    text('title'),
    for (var paragraph = 1; paragraph <= 3; paragraph++)
      text('intro$paragraph'),
    for (final section in allCoursesHelpSectionIds)
      "${text('$section.title')}\n\n${text('$section.body')}",
  ].join('\n\n');
}

/// The same full Help page opens from All Courses and Course Library.
enum CourseLibraryHelpSource { allCourses, courseLibrary }

class CourseLibraryHelpScreen extends StatelessWidget {
  const CourseLibraryHelpScreen({super.key, required this.source});

  final CourseLibraryHelpSource source;

  @override
  Widget build(BuildContext context) => LocaleBuilder(
    builder: (context, locale) => Scaffold(
      appBar: AppBar(
        title: Text(
          helpText.lookup(
            locale,
            source == CourseLibraryHelpSource.allCourses
                ? 'allCoursesHelp.allCoursesPageTitle'
                : 'allCoursesHelp.courseLibraryPageTitle',
          ),
        ),
        actions: [
          AppLocaleSelector(
            key: const Key('all-courses-help-locale-selector'),
            locale: locale,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: SelectableText(
          availableCoursesHelpFor(locale),
          key: const Key('all-courses-help-text'),
        ),
      ),
    ),
  );
}

class AvailableCoursesScreen extends StatefulWidget {
  final CourseEditorService? editorService;
  final Course? currentCourse;

  /// The QQL Course web site; its section is shown only when this is set.
  final Uri? courseWebSite;

  /// Opens [courseWebSite]; tests replace the external launcher.
  final Future<bool> Function(Uri site)? launchWebSite;

  /// Where Course covers are read from; tests use a temporary folder.
  final CourseMediaStore? mediaStore;
  final bool embedded;
  final bool? showUnavailable;
  final CourseLibrarySort? sort;
  final String search;
  final int refreshToken;
  final String? highlightCourseId;
  final VoidCallback? onLibraryChanged;
  const AvailableCoursesScreen({
    super.key,
    this.editorService,
    this.currentCourse,
    this.mediaStore,
    this.courseWebSite = courseLibraryWebSite,
    this.launchWebSite,
    this.embedded = false,
    this.showUnavailable,
    this.sort,
    this.search = '',
    this.refreshToken = 0,
    this.highlightCourseId,
    this.onLibraryChanged,
  });
  @override
  State<AvailableCoursesScreen> createState() => _AvailableCoursesScreenState();
}

class _AvailableCoursesScreenState extends State<AvailableCoursesScreen> {
  final _library = CourseLibraryService();
  final _favorites = CourseFavoriteService();
  final _visibility = CourseLearnerVisibilityService();
  final _scrollController = ScrollController();
  final _highlightKey = GlobalKey();
  List<Course>? _courses;
  Set<String> _added = {};
  Set<String> _hidden = {};
  Set<String> _favoriteIds = {};
  List<SkippedCourseFile> _unreadable = const [];
  String? _profileId;
  String? _error;
  Map<String, String> _profileNames = {};
  Set<String> _hasDraft = {};
  bool _busy = false;

  /// Page-session presentation filter; never changes any Course state.
  bool _showUnavailable = false;

  /// Page-session ordering, applied inside each section.
  CourseLibrarySort _sort = CourseLibrarySort.title;
  final _compactSections = <CourseLibraryCategory, bool>{};

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AvailableCoursesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshToken != widget.refreshToken) {
      _load();
    } else if (oldWidget.highlightCourseId != widget.highlightCourseId) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusHighlighted());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _focusHighlighted() async {
    if (!mounted ||
        !_scrollController.hasClients ||
        widget.highlightCourseId == null) {
      return;
    }
    for (var step = 0; step < 80 && mounted; step++) {
      final target = _highlightKey.currentContext;
      if (target != null) {
        if (!target.mounted) return;
        await Scrollable.ensureVisible(
          target,
          duration: const Duration(milliseconds: 250),
          alignment: 0.25,
        );
        return;
      }
      final position = _scrollController.position;
      if (position.pixels >= position.maxScrollExtent) return;
      _scrollController.jumpTo(
        (position.pixels + position.viewportDimension * 0.6).clamp(
          0.0,
          position.maxScrollExtent,
        ),
      );
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  Future<void> _load() async {
    try {
      final editor = widget.editorService ?? CourseEditorService();
      final courses = <Course>[
        for (final code in CourseService.courseAssets.keys)
          await CourseService().loadCourse(code),
        ...await editor.listUserCourses(),
      ];
      final added = (await _library.included(
        courses,
      )).map((c) => c.courseId).toSet();
      final hidden = await _visibility.hiddenCourseIds(
        courses.map((course) => course.courseId),
      );
      final favoriteIds = await _favorites.favoriteCourseIds(
        courses.map((course) => course.courseId),
      );
      final profileId = await _library.profiles.getActiveProfileId();
      final profileNames = {
        for (final profile in await _library.profiles.getProfileRecords())
          profile.learnerProfileId: profile.displayName,
      };
      final hasDraft = {
        for (final course in courses)
          if (CourseDraftStatus.courseHasDraft(course)) course.courseId,
      };
      if (!mounted) return;
      setState(() {
        _courses = courses;
        _hasDraft = hasDraft;
        _added = added;
        _hidden = hidden;
        _favoriteIds = favoriteIds;
        _unreadable = editor.unreadableCourseFiles;
        _profileId = profileId;
        _profileNames = profileNames;
        _error = null;
      });
      if (widget.highlightCourseId != null) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _focusHighlighted(),
        );
      }
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    }
  }

  Future<void> _add(Course course) async {
    setState(() => _busy = true);
    try {
      await _library.add(course);
      await _load();
      widget.onLibraryChanged?.call();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _maintainer(Course course) {
    if (course.originType.isOfficial) return course.publisherName;
    final id = course.maintainer?.profileId;
    if (id == null) return 'Not specified';
    return _profileNames[id] ?? 'Profile not on this device ($id)';
  }

  Future<void> _remove(Course course) async {
    setState(() => _busy = true);
    try {
      if (await removeFromMyCourses(context, course)) {
        await _load();
        widget.onLibraryChanged?.call();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _membershipButton(Course course) => _added.contains(course.courseId)
      ? TextButton(
          key: ValueKey('remove-course-${course.courseId}'),
          onPressed: _busy || _profileId == null ? null : () => _remove(course),
          child: const Text('Added · Remove'),
        )
      : TextButton(
          key: ValueKey('add-course-${course.courseId}'),
          onPressed: _busy || _profileId == null ? null : () => _add(course),
          child: const Text('Add to my courses'),
        );

  Future<void> _toggleHidden(Course course) async {
    try {
      await _visibility.setHidden(
        course,
        !_hidden.contains(course.courseId),
        activeCourseId: widget.currentCourse?.courseId,
      );
      await _load();
      widget.onLibraryChanged?.call();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
          ),
        );
      }
    }
  }

  Future<void> _toggleFavorite(Course course) async {
    try {
      await _favorites.setFavorite(
        course.courseId,
        !_favoriteIds.contains(course.courseId),
      );
      await _load();
      widget.onLibraryChanged?.call();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceFirst('Bad state: ', '')),
          ),
        );
      }
    }
  }

  Future<void> _resetProgress(Course course) async {
    final name = course.title.trim().isEmpty
        ? course.targetLanguage
        : course.title;
    final first = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Reset $name progress?'),
        content: const Text(
          'This resets Review history, round results, laurel crowns and Duel progress for this course only. Language XP, streak, study days and Status are kept because they are shared by courses in that language.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (first != true || !mounted) return;
    final second = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Final confirmation'),
        content: Text(
          'Reset all your progress for $name? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset course progress'),
          ),
        ],
      ),
    );
    if (second != true) return;
    try {
      await ProgressService().resetCourse(course.courseId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$name progress reset.')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not reset $name progress: $error')),
        );
      }
    }
  }

  PopupMenuEntry<String> _courseActionItem(
    String action,
    String title, {
    String? unavailableReason,
  }) => PopupMenuItem<String>(
    value: action,
    enabled: unavailableReason == null,
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      enabled: unavailableReason == null,
      title: Text(title),
      subtitle: unavailableReason == null ? null : Text(unavailableReason),
    ),
  );

  Widget _courseActions(Course course) {
    final member = _added.contains(course.courseId);
    final hidden = _hidden.contains(course.courseId);
    final active = widget.currentCourse?.courseId == course.courseId;
    final reason = !member
        ? 'Add it to your courses first'
        : active && !hidden
        ? "You're studying this Course"
        : null;
    return PopupMenuButton<String>(
      key: ValueKey('all-course-actions-${course.courseId}'),
      tooltip: 'Course actions',
      icon: const Icon(Icons.more_vert),
      onSelected: (action) {
        switch (action) {
          case 'info':
            Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => CourseInfoScreen(course: course),
              ),
            );
          case 'favorite':
            _toggleFavorite(course);
          case 'visibility':
            _toggleHidden(course);
          case 'reset':
            _resetProgress(course);
        }
      },
      itemBuilder: (_) => [
        _courseActionItem('info', 'Course Info'),
        _courseActionItem(
          'favorite',
          _favoriteIds.contains(course.courseId)
              ? 'Remove from Favorites'
              : 'Favorite',
        ),
        _courseActionItem(
          'visibility',
          hidden ? 'Unhide in Learner' : 'Hide in Learner',
          unavailableReason: reason,
        ),
        _courseActionItem(
          'reset',
          'Reset course progress',
          unavailableReason: member ? null : 'Add it to your courses first',
        ),
      ],
    );
  }

  Widget _webSiteBand(Uri site) => _Band(
    key: const Key('course-library-web-band'),
    color: Theme.of(context).colorScheme.primary,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              key: const Key('find-courses-on-the-web'),
              icon: const Icon(Icons.public),
              label: const Text('Find Courses on the web'),
              onPressed: () => _openWebSite(site),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Free and paid Courses from QuisquisLingo and publishers. Downloaded Courses are imported as QQL Course packages.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    ),
  );

  Future<void> _openWebSite(Uri site) async {
    var opened = false;
    try {
      opened = await (widget.launchWebSite ?? _launchExternal)(site);
    } catch (_) {}
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('The Course web site could not be opened.'),
        ),
      );
    }
  }

  static Future<bool> _launchExternal(Uri site) =>
      launchUrl(site, mode: LaunchMode.externalApplication);

  Widget _unreadableCoursesCard() {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      key: const Key('all-courses-unreadable-courses'),
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _unreadable.length == 1
                  ? '1 stored Course could not be read'
                  : '${_unreadable.length} stored Courses could not be read',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: scheme.onErrorContainer,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'The other Courses are listed normally. These files were kept untouched and are not shown. Saving a Course over one of them is refused until the file is moved away.',
              style: TextStyle(color: scheme.onErrorContainer),
            ),
            for (final file in _unreadable)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: SelectableText('${file.fileName}: ${file.reason}'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _courseSection(CourseLibraryCategory category) => CourseLibrarySection(
    key: ValueKey('course-section-${category.sectionId}'),
    category: category,
    surface: CourseLibrarySectionSurface.allCourses,
    courses: _courses!,
    activeProfileId: _profileId,
    favoriteIds: _favoriteIds,
    showUnavailable: widget.showUnavailable ?? _showUnavailable,
    search: widget.search,
    sort: widget.sort ?? _sort,
    maintainerOf: _maintainer,
    draftCourseIds: _hasDraft,
    compact: _compactSections[category] ?? false,
    onCompactChanged: (value) =>
        setState(() => _compactSections[category] = value),
    rowBuilder: (course, compact, favorites) =>
        _courseRow(course, compact: compact, favorites: favorites),
  );

  /// Compact rows keep the title, languages, status labels and action.
  Widget _courseRow(
    Course course, {
    required bool compact,
    bool favorites = false,
  }) {
    final row = CourseLibraryRow(
      key: ValueKey(
        '${favorites ? 'favorite' : 'device'}-course-${course.courseId}',
      ),
      course: course,
      compact: compact,
      maintainer: _maintainer(course),
      mediaStore: widget.mediaStore,
      hiddenInLearner: _hidden.contains(course.courseId),
      supplementalAction: _membershipButton(course),
      trailing: _courseActions(course),
    );
    if (favorites || course.courseId != widget.highlightCourseId) return row;
    return DecoratedBox(
      key: _highlightKey,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary,
          width: 2,
        ),
      ),
      child: row,
    );
  }

  Widget _body(BuildContext context) => _error != null
      ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ],
          ),
        )
      : _courses == null
      ? const Center(child: CircularProgressIndicator())
      : ListView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          children: [
            if (_unreadable.isNotEmpty) _unreadableCoursesCard(),
            if (widget.courseWebSite case final site?) _webSiteBand(site),
            if (!widget.embedded)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Wrap(
                  spacing: 24,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    MergeSemantics(
                      child: InkWell(
                        onTap: () => setState(
                          () => _showUnavailable = !_showUnavailable,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Switch(
                              key: const Key('show-unavailable-courses'),
                              value: _showUnavailable,
                              onChanged: (value) =>
                                  setState(() => _showUnavailable = value),
                            ),
                            const SizedBox(width: 8),
                            const Flexible(child: Text('Show unavailable')),
                          ],
                        ),
                      ),
                    ),
                    Wrap(
                      spacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('Sort by'),
                        DropdownButton<CourseLibrarySort>(
                          key: const Key('course-library-sort'),
                          value: _sort,
                          onChanged: (value) {
                            if (value != null) setState(() => _sort = value);
                          },
                          items: [
                            for (final sort in CourseLibrarySort.values)
                              DropdownMenuItem(
                                value: sort,
                                child: Text(sort.label),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (widget.embedded)
              _courseSection(CourseLibraryCategory.favorites),
            for (final category in CourseLibraryCategories.standard)
              _courseSection(category),
          ],
        );

  @override
  Widget build(BuildContext context) {
    if (widget.embedded) return _body(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Course Library'),
        actions: [
          IconButton(
            tooltip: 'Help',
            icon: const Icon(Icons.help_outline),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => const CourseLibraryHelpScreen(
                  source: CourseLibraryHelpSource.courseLibrary,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _body(context),
    );
  }
}

/// One visually separate page section: coloured border, rounded corners and
/// space below.
class _Band extends StatelessWidget {
  final Color color;
  final Widget child;
  const _Band({super.key, required this.color, required this.child});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(type: MaterialType.transparency, child: child),
      ),
    ),
  );
}

/// Shared confirmation for personal removal from Selector, Manager and device list.
Future<bool> removeFromMyCourses(BuildContext context, Course course) async {
  var reset = false;
  final choice = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, update) => AlertDialog(
        title: const Text('Remove from my courses?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Remove “${course.title}” from your Course Selector and Course Studio? The shared course and other profiles are unaffected. You can add it again from Course Library.',
              ),
              CheckboxListTile(
                value: reset,
                onChanged: (value) => update(() => reset = value ?? false),
                title: const Text('Reset my progress for this course'),
                subtitle: const Text(
                  'Even with reset selected, all XP (including Weekly XP), total and per-language study days, streak and version backups are kept. XP earned from this course is not subtracted.',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remove from my courses'),
          ),
        ],
      ),
    ),
  );
  if (choice != true || !context.mounted) return false;
  if (reset) {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm progress reset'),
        content: const Text(
          'Reset your completed Rounds/Lessons, Perfect results, won Duels, read Guidebooks and recent Round entries for this course, then remove it from your courses? All XP (including Weekly XP), total and per-language study days and streak are kept. Other courses and profiles are unaffected. The progress reset cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reset and remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
  }
  try {
    await CourseLibraryService().remove(course, resetProgress: reset);
    return true;
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('$error')));
    }
    return false;
  }
}
