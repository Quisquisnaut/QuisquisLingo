import 'package:shared_preferences/shared_preferences.dart';

import 'course_library_categories.dart';
import 'profile_service.dart';

/// How a Courses section shows its Courses. Minimal shows only the section's
/// heading with how many of its Courses are shown and how many it holds.
enum CourseLibraryView {
  expanded('Expanded', 'expanded'),
  compact('Compact', 'compact'),
  minimal('Minimal', 'minimal');

  const CourseLibraryView(this.label, this.storageValue);

  final String label;
  final String storageValue;

  /// The section button cycles Expanded → Compact → Minimal → Expanded.
  CourseLibraryView get next => switch (this) {
    CourseLibraryView.expanded => CourseLibraryView.compact,
    CourseLibraryView.compact => CourseLibraryView.minimal,
    CourseLibraryView.minimal => CourseLibraryView.expanded,
  };

  static CourseLibraryView fromStorage(Object? value) =>
      CourseLibraryView.values.firstWhere(
        (view) => view.storageValue == value,
        orElse: () => CourseLibraryView.expanded,
      );
}

/// Each learner's Courses section views, per tab and category (Build 255
/// Revision 6; before, the views lasted only while the page was open). A
/// missing value, or no active learner, means Expanded. This is a learner
/// setting: it never changes a Course or Personal Library membership.
class CourseLibraryViewService {
  CourseLibraryViewService({ProfileService? profiles})
    : _profiles = profiles ?? ProfileService();

  static const keyPrefix = 'course_library_view_';

  final ProfileService _profiles;

  /// Stable storage names; the enum names may change.
  static String _categoryName(CourseLibraryCategory category) =>
      switch (category) {
        CourseLibraryCategory.favorites => 'favorites',
        CourseLibraryCategory.bundled => 'bundled',
        CourseLibraryCategory.publisher => 'publisher',
        CourseLibraryCategory.myLocal => 'my_local',
        CourseLibraryCategory.otherLocal => 'other_local',
      };

  /// The learner-scoped key suffix for [tab] (`all_courses` or
  /// `course_studio`) and [category].
  static String suffix(String tab, CourseLibraryCategory category) =>
      '$keyPrefix${tab}_${_categoryName(category)}';

  /// Every category's view in [tab], read in one preferences snapshot.
  Future<Map<CourseLibraryCategory, CourseLibraryView>> views(
    String tab, {
    String? profileId,
  }) async {
    final id = profileId ?? await _profiles.getActiveProfileId();
    if (id == null) return const {};
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final category in CourseLibraryCategory.values)
        category: CourseLibraryView.fromStorage(
          prefs.get(_profiles.keyForProfileId(id, suffix(tab, category))),
        ),
    };
  }

  /// Saves [view] for the active learner. Without one the choice lasts only
  /// while the page is open, as before.
  Future<void> setView(
    String tab,
    CourseLibraryCategory category,
    CourseLibraryView view,
  ) async {
    final id = await _profiles.getActiveProfileId();
    if (id == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _profiles.keyForProfileId(id, suffix(tab, category)),
      view.storageValue,
    );
  }
}
