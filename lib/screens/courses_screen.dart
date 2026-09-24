import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../services/course_editor_service.dart';
import '../services/course_library_presentation.dart';
import '../services/course_media_store.dart';
import '../services/custom_course_transfer_service.dart';
import '../services/settings_service.dart';
import '../widgets/course_library_row.dart';
import 'available_courses_screen.dart';
import 'course_projects_screen.dart';
import 'editor_help_screen.dart';

enum CoursesTab { allCourses, manager }

const courseManagerUnlockMessage =
    'Unlock Course Studio for this profile to edit Courses and use Course operations. Tap Version in Settings ten times to unlock it.';

/// All Courses data and learner actions inside the shared Courses frame.
class AllCoursesTab extends StatelessWidget {
  const AllCoursesTab({
    super.key,
    this.editorService,
    this.currentCourse,
    this.mediaStore,
    this.courseWebSite,
    required this.showUnavailable,
    required this.sort,
    required this.search,
    required this.refreshToken,
    this.highlightCourseId,
    this.onLibraryChanged,
  });

  final CourseEditorService? editorService;
  final Course? currentCourse;
  final CourseMediaStore? mediaStore;
  final Uri? courseWebSite;
  final bool showUnavailable;
  final CourseLibrarySort sort;
  final String search;
  final int refreshToken;
  final String? highlightCourseId;
  final VoidCallback? onLibraryChanged;

  @override
  Widget build(BuildContext context) => AvailableCoursesScreen(
    editorService: editorService,
    currentCourse: currentCourse,
    mediaStore: mediaStore,
    courseWebSite: courseWebSite,
    embedded: true,
    showUnavailable: showUnavailable,
    sort: sort,
    search: search,
    refreshToken: refreshToken,
    highlightCourseId: highlightCourseId,
    onLibraryChanged: onLibraryChanged,
  );
}

/// Course Studio data and authoring actions inside the shared Courses frame.
class CourseStudioTab extends StatelessWidget {
  const CourseStudioTab({
    super.key,
    required this.screenKey,
    required this.currentCourse,
    this.initialCourseIdToOpen,
    this.editorService,
    this.transferService,
    this.mediaStore,
    required this.sort,
    required this.showUnavailable,
    required this.search,
    required this.refreshToken,
  });

  final GlobalKey<CourseProjectsScreenState> screenKey;
  final Course? currentCourse;
  final String? initialCourseIdToOpen;
  final CourseEditorService? editorService;
  final CustomCourseTransferService? transferService;
  final CourseMediaStore? mediaStore;
  final CourseLibrarySort sort;
  final bool showUnavailable;
  final String search;
  final int refreshToken;

  @override
  Widget build(BuildContext context) => CourseProjectsScreen(
    key: screenKey,
    currentCourse: currentCourse,
    initialCourseIdToOpen: initialCourseIdToOpen,
    editorService: editorService,
    transferService: transferService,
    mediaStore: mediaStore,
    embedded: true,
    sort: sort,
    showUnavailable: showUnavailable,
    search: search,
    refreshToken: refreshToken,
  );
}

/// One Courses screen with shared view controls and two Course libraries.
class CoursesScreen extends StatefulWidget {
  const CoursesScreen({
    super.key,
    this.initialTab = CoursesTab.allCourses,
    this.currentCourse,
    this.initialCourseIdToOpen,
    this.editorService,
    this.transferService,
    this.mediaStore,
    this.courseWebSite = courseLibraryWebSite,
  });

  final CoursesTab initialTab;
  final Course? currentCourse;
  final String? initialCourseIdToOpen;
  final CourseEditorService? editorService;
  final CustomCourseTransferService? transferService;
  final CourseMediaStore? mediaStore;
  final Uri? courseWebSite;

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  final _managerKey = GlobalKey<CourseProjectsScreenState>();
  bool? _managerUnlocked;
  late CoursesTab _tab = widget.initialTab;
  bool _showUnavailable = true;
  CourseLibrarySort _sort = CourseLibrarySort.title;
  bool _searchOpen = false;
  String _search = '';
  int _refreshToken = 0;
  String? _highlightCourseId;

  @override
  void initState() {
    super.initState();
    _loadUnlock();
  }

  Future<void> _loadUnlock() async {
    final unlocked = await SettingsService().isCourseEditorUnlocked();
    if (!mounted) return;
    setState(() {
      _managerUnlocked = unlocked;
      if (!unlocked) _tab = CoursesTab.allCourses;
    });
    if (!unlocked && widget.initialTab == CoursesTab.manager) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _explainLock());
    }
  }

  void _explainLock() {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text(courseManagerUnlockMessage)));
  }

  void _select(CoursesTab tab) {
    if (tab == CoursesTab.manager && _managerUnlocked != true) {
      _explainLock();
      return;
    }
    setState(() {
      _tab = tab;
      _refreshToken++;
    });
  }

  Future<void> _openImport() async {
    final imported = await Navigator.of(context).push<Course>(
      MaterialPageRoute(
        builder: (_) => CourseProjectsScreen(
          currentCourse: widget.currentCourse,
          importOnly: true,
          editorService: widget.editorService,
          transferService: widget.transferService,
        ),
      ),
    );
    if (mounted) {
      setState(() {
        _refreshToken++;
        if (imported != null) {
          _tab = CoursesTab.allCourses;
          if (CourseLibraryRow.isUnavailable(imported)) {
            _showUnavailable = true;
          }
          _searchOpen = false;
          _search = '';
          _highlightCourseId = imported.courseId;
        }
      });
    }
  }

  Future<void> _newCourse() async {
    await _managerKey.currentState?.createCourse();
    if (mounted) setState(() => _refreshToken++);
  }

  void _openHelp(CoursesTab tab) {
    if (tab == CoursesTab.manager) {
      Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => const CourseManagerHelpScreen()),
      );
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => const CourseLibraryHelpScreen(
          source: CourseLibraryHelpSource.allCourses,
        ),
      ),
    );
  }

  Widget _tabButton(CoursesTab tab, String label) {
    final selected = _tab == tab;
    final locked = tab == CoursesTab.manager && _managerUnlocked != true;
    final scheme = Theme.of(context).colorScheme;
    final color = locked
        ? Theme.of(context).disabledColor
        : selected
        ? scheme.primary
        : scheme.onSurfaceVariant;
    return Expanded(
      child: KeyedSubtree(
        key: selected
            ? Key(
                tab == CoursesTab.allCourses
                    ? 'courses-tab-all-selected'
                    : 'courses-tab-manager-selected',
              )
            : null,
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? scheme.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  key: Key(
                    tab == CoursesTab.allCourses
                        ? 'courses-tab-all'
                        : 'courses-tab-manager',
                  ),
                  onTap: () => _select(tab),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 2,
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: color,
                        fontWeight: selected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                key: Key(
                  tab == CoursesTab.allCourses
                      ? 'all-courses-help'
                      : 'course-manager-help',
                ),
                tooltip: tab == CoursesTab.allCourses
                    ? 'All Courses Help'
                    : 'Course Studio Help',
                onPressed: () => _openHelp(tab),
                icon: const Icon(Icons.help_outline),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_managerUnlocked == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final allSelected = _tab == CoursesTab.allCourses;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courses'),
        actions: [
          IconButton(
            key: const Key('courses-import'),
            tooltip: 'Course Import',
            onPressed: _openImport,
            icon: const Icon(Icons.file_open_outlined),
          ),
          IconButton(
            key: const Key('courses-search'),
            tooltip: 'Search Courses',
            onPressed: () => setState(() {
              _searchOpen = !_searchOpen;
              if (!_searchOpen) _search = '';
            }),
            icon: const Icon(Icons.search),
          ),
          if (!allSelected)
            IconButton(
              key: const Key('create-course-icon-action'),
              tooltip: 'Create new course',
              onPressed: _newCourse,
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sort by'),
                      DropdownButton<CourseLibrarySort>(
                        key: const Key('course-library-sort'),
                        value: _sort,
                        isExpanded: true,
                        onChanged: (value) {
                          if (value != null) setState(() => _sort = value);
                        },
                        items: [
                          for (final sort in CourseLibrarySort.values)
                            DropdownMenuItem(
                              value: sort,
                              child: Text(
                                sort.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                        ],
                      ),
                      if (_searchOpen) ...[
                        const SizedBox(height: 8),
                        TextField(
                          key: const Key('courses-search-field'),
                          autofocus: true,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Search',
                          ),
                          onChanged: (value) => setState(() => _search = value),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Show unavailable'),
                      Switch(
                        key: const Key('show-unavailable-courses'),
                        value: _showUnavailable,
                        onChanged: (value) =>
                            setState(() => _showUnavailable = value),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              _tabButton(CoursesTab.allCourses, 'ALL COURSES'),
              _tabButton(CoursesTab.manager, 'COURSE STUDIO'),
            ],
          ),
          Expanded(
            child: IndexedStack(
              index: allSelected ? 0 : 1,
              children: [
                AllCoursesTab(
                  editorService: widget.editorService,
                  currentCourse: widget.currentCourse,
                  mediaStore: widget.mediaStore,
                  courseWebSite: widget.courseWebSite,
                  showUnavailable: _showUnavailable,
                  sort: _sort,
                  search: _search,
                  refreshToken: _refreshToken,
                  highlightCourseId: _highlightCourseId,
                  onLibraryChanged: () => setState(() => _refreshToken++),
                ),
                CourseStudioTab(
                  screenKey: _managerKey,
                  currentCourse: widget.currentCourse,
                  initialCourseIdToOpen: _managerUnlocked!
                      ? widget.initialCourseIdToOpen
                      : null,
                  editorService: widget.editorService,
                  transferService: widget.transferService,
                  mediaStore: widget.mediaStore,
                  sort: _sort,
                  showUnavailable: _showUnavailable,
                  search: _search,
                  refreshToken: _refreshToken,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
