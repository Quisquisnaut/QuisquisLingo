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
    'Unlock Course Manager for this profile to edit Courses and use Course operations. Tap Version in Settings ten times to unlock it.';

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

  void _openHelp() {
    if (_tab == CoursesTab.manager) {
      Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => const CourseManagerHelpScreen()),
      );
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('All Courses — Help')),
          body: const SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: SelectableText(availableCoursesHelp),
          ),
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
        child: InkWell(
          key: Key(
            tab == CoursesTab.allCourses
                ? 'courses-tab-all'
                : 'courses-tab-manager',
          ),
          onTap: () => _select(tab),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: selected ? scheme.primary : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
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
          if (allSelected)
            IconButton(
              key: const Key('courses-search'),
              tooltip: 'Search Courses',
              onPressed: () => setState(() {
                _searchOpen = !_searchOpen;
                if (!_searchOpen) _search = '';
              }),
              icon: const Icon(Icons.search),
            )
          else
            IconButton(
              key: const Key('create-course-icon-action'),
              tooltip: 'Create new course',
              onPressed: _newCourse,
              icon: const Icon(Icons.add),
            ),
          IconButton(
            key: const Key('courses-help'),
            tooltip: 'Help',
            onPressed: _openHelp,
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          if (allSelected && _searchOpen)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: TextField(
                key: const Key('courses-search-field'),
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search title or language',
                ),
                onChanged: (value) => setState(() => _search = value),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 24,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      key: const Key('show-unavailable-courses'),
                      value: _showUnavailable,
                      onChanged: (value) =>
                          setState(() => _showUnavailable = value),
                    ),
                    const Flexible(child: Text('Show unavailable Courses')),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Sort by'),
                    const SizedBox(width: 8),
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
          Row(
            children: [
              _tabButton(CoursesTab.allCourses, 'ALL COURSES'),
              _tabButton(CoursesTab.manager, 'COURSE MANAGER'),
            ],
          ),
          Expanded(
            child: IndexedStack(
              index: allSelected ? 0 : 1,
              children: [
                AvailableCoursesScreen(
                  editorService: widget.editorService,
                  currentCourse: widget.currentCourse,
                  mediaStore: widget.mediaStore,
                  courseWebSite: widget.courseWebSite,
                  embedded: true,
                  showUnavailable: _showUnavailable,
                  sort: _sort,
                  search: _search,
                  refreshToken: _refreshToken,
                  highlightCourseId: _highlightCourseId,
                  onLibraryChanged: () => setState(() => _refreshToken++),
                ),
                CourseProjectsScreen(
                  key: _managerKey,
                  currentCourse: widget.currentCourse,
                  initialCourseIdToOpen: _managerUnlocked!
                      ? widget.initialCourseIdToOpen
                      : null,
                  editorService: widget.editorService,
                  transferService: widget.transferService,
                  mediaStore: widget.mediaStore,
                  embedded: true,
                  sort: _sort,
                  showUnavailable: _showUnavailable,
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
