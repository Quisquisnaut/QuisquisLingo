import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../services/course_library_categories.dart';
import '../services/course_library_filter.dart';
import '../services/course_library_presentation.dart';

enum CourseLibrarySectionSurface { allCourses, courseStudio }

typedef CourseLibrarySectionRowBuilder =
    Widget Function(Course course, bool compact, bool favorites);

/// Shared Courses section, with its own page-session Expanded / Compact state.
class CourseLibrarySection extends StatefulWidget {
  const CourseLibrarySection({
    super.key,
    required this.category,
    required this.surface,
    required this.courses,
    required this.activeProfileId,
    required this.favoriteIds,
    required this.showUnavailable,
    required this.search,
    required this.sort,
    required this.maintainerOf,
    required this.rowBuilder,
    this.draftCourseIds,
    this.compact,
    this.onCompactChanged,
  }) : assert((compact == null) == (onCompactChanged == null));

  final CourseLibraryCategory category;
  final CourseLibrarySectionSurface surface;
  final Iterable<Course> courses;
  final String? activeProfileId;
  final Set<String> favoriteIds;
  final bool showUnavailable;
  final String search;
  final CourseLibrarySort sort;
  final String Function(Course) maintainerOf;
  final CourseLibrarySectionRowBuilder rowBuilder;
  final Set<String>? draftCourseIds;
  final bool? compact;
  final ValueChanged<bool>? onCompactChanged;

  @override
  State<CourseLibrarySection> createState() => _CourseLibrarySectionState();
}

class _CourseLibrarySectionState extends State<CourseLibrarySection> {
  bool _compact = false;

  bool get _isCompact => widget.compact ?? _compact;

  void _toggleCompact() {
    final next = !_isCompact;
    if (widget.onCompactChanged case final changed?) {
      changed(next);
    } else {
      setState(() => _compact = next);
    }
  }

  bool get _favorites => widget.category == CourseLibraryCategory.favorites;
  bool get _allCourses =>
      widget.surface == CourseLibrarySectionSurface.allCourses;

  Color _color(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    if (_favorites) {
      if (_allCourses) {
        return dark ? Colors.amber.shade200 : Colors.amber.shade800;
      }
      return dark ? Colors.amber.shade300 : Colors.amber.shade700;
    }
    return switch (widget.category) {
      CourseLibraryCategory.bundled => Theme.of(context).colorScheme.onSurface,
      CourseLibraryCategory.publisher => Colors.purple,
      CourseLibraryCategory.myLocal => Colors.orange,
      CourseLibraryCategory.otherLocal =>
        dark ? const Color(0xFFBDBDBD) : const Color(0xFF686868),
      CourseLibraryCategory.favorites => throw StateError('Handled above'),
    };
  }

  String _emptyMessage(CourseLibrarySelection selection) {
    if (selection.all.isEmpty && _favorites) return 'No Favorites yet.';
    if (_allCourses) {
      if (selection.all.isEmpty) return 'No courses in this section.';
      if (widget.search.trim().isNotEmpty) {
        return 'No matching Courses in this section.';
      }
      return 'No Courses are shown in this section. Turn on Show unavailable to see them.';
    }
    if (selection.all.isNotEmpty && widget.search.trim().isNotEmpty) {
      return 'No matching Courses in this section.';
    }
    return 'No courses in this section.';
  }

  @override
  Widget build(BuildContext context) {
    final selection = CourseLibraryFilter.select(
      courses: widget.courses,
      category: widget.category,
      activeProfileId: widget.activeProfileId,
      favoriteIds: widget.favoriteIds,
      showUnavailable: widget.showUnavailable,
      search: widget.search,
      sort: widget.sort,
      maintainerOf: widget.maintainerOf,
      draftCourseIds: widget.draftCourseIds,
    );
    final color = _color(context);
    final count = selection.shown.length == selection.all.length
        ? '${selection.all.length}'
        : '${selection.shown.length} of ${selection.all.length} shown';
    final sectionId = widget.category.sectionId;
    final keyPrefix = _allCourses ? 'course-section' : 'manager-section';
    final toggle = TextButton.icon(
      key: ValueKey('$keyPrefix-view-$sectionId'),
      onPressed: _toggleCompact,
      icon: Icon(_isCompact ? Icons.view_headline : Icons.view_agenda_outlined),
      label: Text(_isCompact ? 'Compact' : 'Expanded'),
    );
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: color.withValues(
            alpha:
                _allCourses &&
                    _favorites &&
                    Theme.of(context).brightness == Brightness.dark
                ? 0.20
                : 0.12,
          ),
          padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
          child: Row(
            children: [
              Expanded(
                child: _allCourses
                    ? Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            widget.category.label,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            ' · $count',
                            key: ValueKey('$keyPrefix-count-$sectionId'),
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      )
                    : Text(
                        '${widget.category.label} · $count',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
              ),
              if (_allCourses)
                Tooltip(
                  message: _isCompact
                      ? 'Show full details'
                      : 'Show fewer details',
                  child: toggle,
                )
              else
                toggle,
            ],
          ),
        ),
        if (selection.shown.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(_emptyMessage(selection)),
          ),
        for (final course in selection.shown)
          widget.rowBuilder(course, _isCompact, _favorites),
      ],
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: color, width: 2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _allCourses
              ? Material(type: MaterialType.transparency, child: content)
              : content,
        ),
      ),
    );
  }
}
