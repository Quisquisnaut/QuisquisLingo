import 'package:flutter/material.dart';
import '../models/course_draft_status.dart';
import '../models/course_models.dart';
import '../services/course_editor_service.dart';
import '../services/course_library_service.dart';
import '../services/course_service.dart';
import '../services/publication_service.dart';

const availableCoursesHelp =
    '''If your library has no courses available for study, Home keeps Settings and, when activated for your profile, Course Manager. Course Library lets you add courses again. No course flag is shown until a playable course is selected.

Courses are stored once on this device and can be added to each learner's personal library independently.

Bundled Courses are supplied with QQL. Publisher Courses are installed publisher releases. My Custom Courses were created by your profile; Other Custom Courses were created by another profile. Adding a Custom Course does not grant editing rights.

Courses are sorted alphabetically within each section. Bold titles identify Bundled Courses in black (white on black in dark mode), Publisher Courses in purple and Custom Courses in orange. Maintainer shows the local profile responsible for a Custom Course, or the publisher for Bundled and Publisher Courses. A profile not present on this device is identified by its profile ID.

Add to my courses includes the course in your Course Selector and Course Manager. Added · Remove lets you remove it here, with the same confirmation and optional progress reset. By default the page hides Courses that are unpublished, require Publisher verification, or still contain Draft authoring content. Show unavailable or Draft Courses displays them with blue outlined labels: Draft, Unpublished and Verification required. Showing them does not make them playable or verified. Only published courses are available for study. Publisher Courses also require verified signatures; draft or unverified courses remain subject to their existing restrictions.

Remove from my courses, in the Selector or Manager, removes the course only from your library. Progress is kept by default for when you add it again. You may explicitly reset your course progress during removal. Other learners and the shared file are unaffected. Even when Reset my progress is selected, all earned XP (including Weekly XP), total and per-language study days, streak and version backups are kept. XP earned from this course is not subtracted. Reset clears only your completed Rounds/Lessons, Perfect results, won Duels, read Guidebooks and recent Round entries for this course.

Only an admin can remove a Publisher Course from the device, through its Course Manager menu. This is blocked while another profile includes the course in its library. Physical removal preserves learner progress and version backups for later reinstallation.''';

class AvailableCoursesScreen extends StatefulWidget {
  final CourseEditorService? editorService;
  const AvailableCoursesScreen({super.key, this.editorService});
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
      courses.sort((a, b) {
        final title = a.title.toLowerCase().compareTo(b.title.toLowerCase());
        return title != 0 ? title : a.courseId.compareTo(b.courseId);
      });
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

  List<Course> get _shownCourses => [
    for (final course in _courses!)
      if (_showUnavailable || !_isUnavailableOrDraft(course)) course,
  ];

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
              MergeSemantics(
                child: InkWell(
                  onTap: () =>
                      setState(() => _showUnavailable = !_showUnavailable),
                  child: Row(
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
              for (final (index, label) in [
                'Bundled Courses',
                'Publisher Courses',
                'My Custom Courses',
                'Other Custom Courses',
              ].indexed) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (!_shownCourses.any((c) => _section(c) == index))
                  const Text('No courses in this section.'),
                for (final course in _shownCourses.where(
                  (c) => _section(c) == index,
                ))
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 480;
                      return ListTile(
                        key: ValueKey('device-course-${course.courseId}'),
                        title: Text(
                          course.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: switch (course.originType) {
                              CourseOriginType.bundledOfficial =>
                                Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black,
                              CourseOriginType.externalOfficial =>
                                Colors.purple,
                              CourseOriginType.custom => Colors.orange,
                            },
                            backgroundColor:
                                course.originType ==
                                        CourseOriginType.bundledOfficial &&
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                ? Colors.black
                                : null,
                          ),
                        ),
                        subtitle: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${course.sourceLanguage} → ${course.targetLanguage}\nMaintainer: ${_maintainer(course)}',
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
                                    if (PublicationService.requiresPublisherVerification(
                                      course,
                                    ))
                                      const _BlockingStatusBadge(
                                        'Verification required',
                                      ),
                                  ],
                                ),
                              ),
                            if (compact)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: _membershipButton(course),
                              ),
                          ],
                        ),
                        trailing: compact ? null : _membershipButton(course),
                      );
                    },
                  ),
              ],
            ],
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
