import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_library_categories.dart';
import 'package:quisquislingo_app/services/course_library_filter.dart';
import 'package:quisquislingo_app/services/course_library_presentation.dart';
import 'package:quisquislingo_app/widgets/course_library_section.dart';

Course _course(
  String id,
  String title, {
  String creator = 'bob',
  String source = 'English',
  String target = 'Italian',
  bool published = true,
}) => Course(
  courseId: id,
  originalCourseCreator: CourseProvenanceIdentity.qqlUser(
    profileId: creator,
    displayName: creator,
  ),
  publicationState: published
      ? PublicationState.published
      : PublicationState.draft,
  learningLanguage: target,
  interfaceLanguage: source,
  sourceLanguage: source,
  targetLanguage: target,
  title: title,
  ttsLanguage: 'it-IT',
  lessons: const [],
);

List<String> _ids(Iterable<Course> courses) => [
  for (final course in courses) course.courseId,
];

void main() {
  test(
    'Favorites remain in their own category and both views filter alike',
    () {
      final own = _course('own', 'Own Course', creator: 'alice');
      final other = _course('other', 'Other Course', target: 'French');
      final draft = _course('draft', 'Italian Draft', published: false);
      final courses = [other, draft, own];

      CourseLibrarySelection select(
        CourseLibraryCategory category, {
        required bool showUnavailable,
        required String search,
      }) => CourseLibraryFilter.select(
        courses: courses,
        category: category,
        activeProfileId: 'alice',
        favoriteIds: const {'own', 'draft'},
        showUnavailable: showUnavailable,
        search: search,
        sort: CourseLibrarySort.title,
        maintainerOf: (course) => course.originalCourseCreator.displayName,
      );

      expect(
        _ids(
          select(
            CourseLibraryCategory.favorites,
            showUnavailable: true,
            search: '',
          ).shown,
        ),
        ['draft', 'own'],
      );
      expect(
        _ids(
          select(
            CourseLibraryCategory.myLocal,
            showUnavailable: true,
            search: '',
          ).shown,
        ),
        ['own'],
      );
      expect(
        _ids(
          select(
            CourseLibraryCategory.otherLocal,
            showUnavailable: true,
            search: '',
          ).shown,
        ),
        ['draft', 'other'],
      );
      final filtered = select(
        CourseLibraryCategory.favorites,
        showUnavailable: false,
        search: ' iTaLiAn ',
      );
      expect(_ids(filtered.all), ['draft', 'own']);
      expect(_ids(filtered.shown), ['own']);
    },
  );

  testWidgets('each Course section keeps its own Expanded or Compact state', (
    tester,
  ) async {
    final own = _course('own', 'Own Course', creator: 'alice');
    final other = _course('other', 'Other Course');
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              for (final category in [
                CourseLibraryCategory.myLocal,
                CourseLibraryCategory.otherLocal,
              ])
                CourseLibrarySection(
                  key: ValueKey('course-section-${category.sectionId}'),
                  category: category,
                  surface: CourseLibrarySectionSurface.allCourses,
                  courses: [own, other],
                  activeProfileId: 'alice',
                  favoriteIds: const {},
                  showUnavailable: true,
                  search: '',
                  sort: CourseLibrarySort.title,
                  maintainerOf: (_) => 'Maintainer',
                  rowBuilder: (course, compact, _) => Text(
                    '${course.title}: ${compact ? 'Compact' : 'Expanded'}',
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('course-section-view-2')));
    await tester.pump();
    expect(find.text('Own Course: Compact'), findsOneWidget);
    expect(find.text('Other Course: Expanded'), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(const Key('course-section-count-2'))).data,
      ' · 1',
    );
  });
}
