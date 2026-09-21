import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/course_draft_status.dart';
import '../models/course_models.dart';
import '../services/course_editor_service.dart';
import '../services/course_library_presentation.dart';
import '../services/course_library_service.dart';
import '../services/course_media_store.dart';
import '../services/course_service.dart';
import '../services/publication_service.dart';
import '../widgets/course_artwork.dart';

/// The QQL Course web site. None exists yet, so Find Courses on the web stays
/// hidden until this is set.
const Uri? courseLibraryWebSite = null;

const availableCoursesHelp = '''Courses on this device

Course Library shows all Courses installed or stored on this QQL device, not only the Courses in your personal library. Each learner chooses independently which of them to include in their personal Course library.

Courses do not have to be created on this device. You can import a Course made elsewhere. For example, a friend can send you a Course they created, or a publisher may distribute or sell you a Publisher Course to install. QQL only imports the Course package; it does not sell or license Courses itself.

If your library has no courses available for study, Home keeps Settings and, when activated for your profile, Course Manager. Course Library lets you add courses again. No course flag is shown until a playable course is selected.

Categories

Bundled Courses: supplied with QuisquisLingo.
Publisher Courses: installed Publisher releases.
My Local Courses: Custom Courses created by your profile.
Other Local Courses: Custom Courses created by another profile or imported from somebody else.

Each category has its own section, and its header shows how many Courses it holds. Bold titles identify Bundled Courses in black (white on black in dark mode), Publisher Courses in purple and Custom Courses in orange.

Course details

Each row shows the Course cover, or the Course flag when there is no cover, followed by the languages, Version, Last edited date, Maintainer and, when the author declared it, Duration. Bundled and Publisher Courses show their release version; Custom Courses show their Course version. Maintainer shows the local profile responsible for a Custom Course, or the publisher for Bundled and Publisher Courses. A profile not present on this device is identified by its profile ID.

Availability

By default the page hides Courses that are unpublished, require Publisher verification, or still contain Draft authoring content; a section header then shows how many are shown and how many are hidden. Use Show unavailable or Draft Courses to display them with blue outlined labels: Draft, Unpublished and Verification required. Showing them does not make them playable or verified. Only published courses are available for study. Publisher Courses also require verified signatures.

Sorting and compact view

Sort by orders the Courses inside each section by Title, Language, Maintainer, Most recent or Duration. The sections themselves never change order. Most recent shows the latest edit first; Duration shows the shortest Course first and Courses without a declared duration last. Each section's Expanded / Compact button shows or hides version, date, maintainer and duration for that section only. These choices last while the page is open.

Personal library

Add to my courses adds an installed Course to your personal Course Selector and Course Manager. It does not copy the Course or give you editing rights. Removing it from your courses does not remove it from the device. Added · Remove lets you remove it here, with the same confirmation and optional progress reset.

Remove from my courses, in the Selector or Manager, removes the course only from your library. Progress is kept by default for when you add it again. You may explicitly reset your course progress during removal. Other learners and the shared file are unaffected. Even when Reset my progress is selected, all earned XP (including Weekly XP), total and per-language study days, streak and version backups are kept. XP earned from this course is not subtracted. Reset clears only your completed Rounds/Lessons, Perfect results, won Duels, read Guidebooks and recent Round entries for this course.

Importing

Courses may be transferred as QQL Course packages. Imported Custom Courses keep their ownership and provenance rules. Publisher Courses remain subject to Publisher verification.

Removing a Publisher Course from the device

Only an admin can remove a Publisher Course from the device, through its Course Manager menu. This is blocked while another profile includes the course in its library. Physical removal preserves learner progress and version backups for later reinstallation.''';

class AvailableCoursesScreen extends StatefulWidget {
  final CourseEditorService? editorService;

  /// The QQL Course web site; its section is shown only when this is set.
  final Uri? courseWebSite;

  /// Opens [courseWebSite]; tests replace the external launcher.
  final Future<bool> Function(Uri site)? launchWebSite;

  /// Where Course covers are read from; tests use a temporary folder.
  final CourseMediaStore? mediaStore;
  const AvailableCoursesScreen({
    super.key,
    this.editorService,
    this.mediaStore,
    this.courseWebSite = courseLibraryWebSite,
    this.launchWebSite,
  });
  @override
  State<AvailableCoursesScreen> createState() => _AvailableCoursesScreenState();
}

class _AvailableCoursesScreenState extends State<AvailableCoursesScreen> {
  final _library = CourseLibraryService();
  List<Course>? _courses;
  Set<String> _added = {};
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
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final courses = <Course>[
        for (final code in CourseService.courseAssets.keys)
          await CourseService().loadCourse(code),
        ...await (widget.editorService ?? CourseEditorService())
            .listUserCourses(),
      ];
      final added = (await _library.included(
        courses,
      )).map((c) => c.courseId).toSet();
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
        _profileId = profileId;
        _profileNames = profileNames;
        _error = null;
      });
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
      if (await removeFromMyCourses(context, course)) await _load();
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
    _ => Colors.orange.shade800,
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

  Widget _sectionBand(BuildContext context, int index, String label) {
    final all = _courses!.where((c) => _section(c) == index).toList();
    final shown = CourseLibraryPresentation.sorted(
      all.where((c) => _showUnavailable || !_isUnavailableOrDraft(c)),
      _sort,
      maintainerOf: _maintainer,
    );
    final hidden = all.length - shown.length;
    final color = _sectionColor(context, index);
    return _Band(
      key: ValueKey('course-section-$index'),
      color: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: color.withValues(alpha: 0.12),
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
                        hidden == 0
                            ? ' · ${all.length}'
                            : ' · ${shown.length} shown · $hidden hidden',
                        key: ValueKey('course-section-count-$index'),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                Tooltip(
                  message: _compact[index]
                      ? 'Show full details'
                      : 'Show fewer details',
                  child: TextButton.icon(
                    key: ValueKey('course-section-view-$index'),
                    icon: Icon(
                      _compact[index]
                          ? Icons.view_headline
                          : Icons.view_agenda_outlined,
                    ),
                    label: Text(_compact[index] ? 'Compact' : 'Expanded'),
                    onPressed: () =>
                        setState(() => _compact[index] = !_compact[index]),
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
                    ? 'No courses in this section.'
                    : '${all.length == 1 ? 'The Course here is' : 'All ${all.length} Courses here are'} unavailable or Draft. Turn on Show unavailable or Draft Courses to see ${all.length == 1 ? 'it' : 'them'}.',
              ),
            ),
          for (final course in shown)
            _courseRow(course, compact: _compact[index]),
        ],
      ),
    );
  }

  TextStyle _titleStyle(BuildContext context, Course course) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return TextStyle(
      fontWeight: FontWeight.bold,
      color: switch (course.originType) {
        CourseOriginType.bundledOfficial => dark ? Colors.white : Colors.black,
        CourseOriginType.externalOfficial => Colors.purple,
        CourseOriginType.custom => Colors.orange,
      },
      backgroundColor:
          course.originType == CourseOriginType.bundledOfficial && dark
          ? Colors.black
          : null,
    );
  }

  String _lastEdited(BuildContext context, Course course) {
    final instant = CourseLibraryPresentation.lastEdited(course);
    return instant == null
        ? 'Unknown'
        : MaterialLocalizations.of(context).formatShortDate(instant.toLocal());
  }

  /// Compact rows keep the title, languages, status labels and action.
  Widget _courseRow(Course course, {required bool compact}) => LayoutBuilder(
    builder: (context, constraints) {
      final narrow = constraints.maxWidth < 480;
      final version = CourseLibraryPresentation.version(course);
      final duration = CourseLibraryPresentation.duration(course);
      final details = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course.title,
            key: ValueKey('device-course-title-${course.courseId}'),
            style: _titleStyle(context, course),
          ),
          const SizedBox(height: 2),
          DefaultTextStyle.merge(
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${course.sourceLanguage} → ${course.targetLanguage}'),
                if (!compact) ...[
                  if (version != null) Text('Version: $version'),
                  Text('Last edited: ${_lastEdited(context, course)}'),
                  Text('Maintainer: ${_maintainer(course)}'),
                  if (duration != null) Text('Duration: $duration'),
                ],
              ],
            ),
          ),
          if (_isUnavailableOrDraft(course))
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (_hasAuthoredDraft(course))
                    const _BlockingStatusBadge('Draft'),
                  if (_isUnpublished(course))
                    const _BlockingStatusBadge('Unpublished'),
                  if (PublicationService.requiresPublisherVerification(course))
                    const _BlockingStatusBadge('Verification required'),
                ],
              ),
            ),
          if (narrow)
            Align(
              alignment: Alignment.centerLeft,
              child: _membershipButton(course),
            ),
        ],
      );
      return DecoratedBox(
        key: ValueKey('device-course-${course.courseId}'),
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerColor),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CourseArtwork(
                course: course,
                size: compact ? 40 : 64,
                mediaStore: widget.mediaStore,
              ),
              const SizedBox(width: 16),
              Expanded(child: details),
              if (!narrow)
                Align(
                  alignment: Alignment.bottomRight,
                  child: _membershipButton(course),
                ),
            ],
          ),
        ),
      );
    },
  );

  @override
  Widget build(BuildContext context) => Scaffold(
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
    body: _error != null
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
            padding: const EdgeInsets.all(16),
            children: [
              if (widget.courseWebSite case final site?) _webSiteBand(site),
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
                            const Flexible(
                              child: Text('Show unavailable or Draft Courses'),
                            ),
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
              for (final (index, label) in _sectionLabels.indexed)
                _sectionBand(context, index, label),
            ],
          ),
  );
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

class _BlockingStatusBadge extends StatelessWidget {
  final String label;
  const _BlockingStatusBadge(this.label);

  @override
  Widget build(BuildContext context) {
    final blue = Theme.of(context).brightness == Brightness.dark
        ? Colors.blue.shade300
        : Colors.blue.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: blue),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: blue,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
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
                'Remove “${course.title}” from your Course Selector and Course Manager? The shared course and other profiles are unaffected. You can add it again from Course Library.',
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
