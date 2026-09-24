import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/course_draft_status.dart';
import '../models/course_models.dart';
import '../services/course_editor_service.dart';
import '../services/course_favorite_service.dart';
import '../services/course_file_store.dart';
import '../services/course_learner_visibility_service.dart';
import '../services/course_library_presentation.dart';
import '../services/course_library_service.dart';
import '../services/course_media_store.dart';
import '../services/course_service.dart';
import '../services/progress_service.dart';
import '../services/publication_service.dart';
import '../widgets/course_library_row.dart';
import 'course_info_screen.dart';

/// The QQL Course web site. None exists yet, so Find Courses on the web stays
/// hidden until this is set.
const Uri? courseLibraryWebSite = null;

const availableCoursesHelp = '''Courses on this device

All Courses shows every Course installed or stored on this QQL device, including Courses outside your personal library. Each learner chooses independently which of them to include.

Courses do not have to be created on this device. You can import a Course made elsewhere. For example, a friend can send you a Course they created, or a publisher may distribute or sell you a Publisher Course to install. QQL only imports the Course package; it does not sell or license Courses itself.

If your library has no courses available for study, Home keeps Settings and All Courses. Course Studio can be unlocked for your profile by tapping Version in Settings ten times. All Courses lets you add Courses again. No course flag is shown until a playable Course is selected.

Categories

Favorites: your shortcuts, also listed in their normal sections.
Bundled Courses: supplied with QuisquisLingo.
Publisher Courses: installed Publisher releases.
My Local Courses: Custom Courses created by your profile.
Other Local Courses: Custom Courses created by another profile or imported from somebody else.

Each category has its own section, and its header shows how many Courses it holds. Bold titles identify Bundled Courses in black (white on black in dark mode), Publisher Courses in purple and Custom Courses in orange.

Course details

Each row shows the Course cover, or the Course flag when there is no cover, followed by the languages, Version, Last edited date, Maintainer and, when the author declared it, Duration. Bundled and Publisher Courses show their release version; Custom Courses show their Course version. Maintainer shows the local profile responsible for a Custom Course, or the publisher for Bundled and Publisher Courses. A profile not present on this device is identified by its profile ID.

Availability

Show unavailable starts on, displaying unpublished Courses, Courses needing Publisher verification and Courses with Draft authoring content. Turn it off to filter those rows from both tabs. A filtered section says how many of its Courses are shown. Blue outlined labels identify Draft, Unpublished and Verification required. Showing them does not make them playable or verified. Only published Courses are available for study. Publisher Courses also require verified signatures.

Sorting and compact view

Sort by orders the Courses inside each section by Title, Language, Maintainer, Most recent or Duration. The sections themselves never change order. Most recent shows the latest edit first; Duration shows the shortest Course first and Courses without a declared duration last. Each section's Expanded / Compact button shows or hides version, date, maintainer and duration for that section only. Search filters titles and languages across all sections, including Favorites. These choices last while the page is open.

Personal library

Add to my courses adds an installed Course to your personal Course Selector and Course Studio. It does not copy the Course or give you editing rights. Removing it from your courses does not remove it from the device. Added · Remove lets you remove it here, with the same confirmation and optional progress reset.

Remove from my courses, in the Selector or Course Studio, removes the course only from your library. Progress is kept by default for when you add it again. You may explicitly reset your course progress during removal. Other learners and the shared file are unaffected. Even when Reset my progress is selected, all earned XP (including Weekly XP), total and per-language study days, streak and version backups are kept. XP earned from this course is not subtracted. Reset clears only your completed Rounds/Lessons, Perfect results, won Duels, read Guidebooks and recent Round entries for this course.

Courses in learner mode

Hide in Learner keeps a Course in your personal library and Course Studio but removes it from the learner Course Selector. Unhide in Learner restores it. The Course you are studying cannot be hidden until you switch Courses. Favorites are learner-specific shortcuts; favoriting never adds a Course to your personal library. All Courses keeps hidden Courses visible with a Hidden in Learner label so you can unhide them.

Importing

Courses may be transferred as QQL Course packages. Imported Custom Courses keep their ownership and provenance rules. Publisher Courses remain subject to Publisher verification.

Removing a Publisher Course from the device

Only an admin can remove a Publisher Course from the device, through its Course Studio menu. This is blocked while another profile includes the course in its library. Physical removal preserves learner progress and version backups for later reinstallation.''';

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

  /// Page-session Compact view, one flag per section; all start Expanded.
  final _compact = List<bool>.filled(_sectionLabels.length, false);
  bool _favoritesCompact = false;
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

  bool _isUnpublished(Course c) => !c.publicationState.isPublished;
  bool _hasAuthoredDraft(Course c) => _hasDraft.contains(c.courseId);

  /// Unpublished, awaiting Publisher verification, or containing Draft content.
  bool _isUnavailableOrDraft(Course c) =>
      _isUnpublished(c) ||
      PublicationService.requiresPublisherVerification(c) ||
      _hasAuthoredDraft(c);

  int _section(Course c) {
    if (c.originType == CourseOriginType.bundledOfficial) return 0;
    if (c.originType == CourseOriginType.externalOfficial) return 1;
    return CourseLibraryService.creatorProfileId(c) == _profileId ? 2 : 3;
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

  static const _sectionLabels = [
    'Bundled Courses',
    'Publisher Courses',
    'My Local Courses',
    'Other Local Courses',
  ];

  /// Border and header colour of each section, from its title colour.
  Color _sectionColor(BuildContext context, int index) => switch (index) {
    0 => Theme.of(context).colorScheme.onSurface,
    1 => Colors.purple,
    2 => Colors.orange,
    _ =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFFBDBDBD)
          : const Color(0xFF686868),
  };

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

  Widget _sectionBand(
    BuildContext context,
    int index,
    String label, {
    bool favorites = false,
  }) {
    final all = _courses!
        .where(
          (c) => favorites
              ? _favoriteIds.contains(c.courseId)
              : _section(c) == index,
        )
        .toList();
    final query = widget.search.trim().toLowerCase();
    final shown = CourseLibraryPresentation.sorted(
      all.where(
        (c) =>
            ((widget.showUnavailable ?? _showUnavailable) ||
                !_isUnavailableOrDraft(c)) &&
            (query.isEmpty ||
                c.title.toLowerCase().contains(query) ||
                c.sourceLanguage.toLowerCase().contains(query) ||
                c.targetLanguage.toLowerCase().contains(query)),
      ),
      widget.sort ?? _sort,
      maintainerOf: _maintainer,
    );
    final filtered = all.length - shown.length;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = favorites
        ? (dark ? Colors.amber.shade200 : Colors.amber.shade800)
        : _sectionColor(context, index);
    final compact = favorites ? _favoritesCompact : _compact[index];
    final sectionKey = favorites ? 'favorites' : '$index';
    return _Band(
      key: ValueKey('course-section-$sectionKey'),
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: color.withValues(alpha: favorites && dark ? 0.20 : 0.12),
            padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
            child: Row(
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        label,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        filtered == 0
                            ? ' · ${all.length}'
                            : ' · ${shown.length} of ${all.length} shown',
                        key: ValueKey('course-section-count-$sectionKey'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message: compact ? 'Show full details' : 'Show fewer details',
                  child: TextButton.icon(
                    key: ValueKey('course-section-view-$sectionKey'),
                    icon: Icon(
                      compact
                          ? Icons.view_headline
                          : Icons.view_agenda_outlined,
                    ),
                    label: Text(compact ? 'Compact' : 'Expanded'),
                    onPressed: () => setState(() {
                      if (favorites) {
                        _favoritesCompact = !_favoritesCompact;
                      } else {
                        _compact[index] = !_compact[index];
                      }
                    }),
                  ),
                ),
              ],
            ),
          ),
          if (shown.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                all.isEmpty
                    ? favorites
                          ? 'No Favorites yet.'
                          : 'No courses in this section.'
                    : widget.search.trim().isNotEmpty
                    ? 'No matching Courses in this section.'
                    : 'No Courses are shown in this section. Turn on Show unavailable to see them.',
              ),
            ),
          for (final course in shown)
            favorites
                ? _courseRow(course, compact: compact, favorites: true)
                : _courseRow(course, compact: compact),
        ],
      ),
    );
  }

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
              _sectionBand(context, -1, 'Favorites', favorites: true),
            for (final (index, label) in _sectionLabels.indexed)
              _sectionBand(context, index, label),
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
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Course Library — Help')),
                  body: const SingleChildScrollView(
                    padding: EdgeInsets.all(20),
                    child: SelectableText(availableCoursesHelp),
                  ),
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
