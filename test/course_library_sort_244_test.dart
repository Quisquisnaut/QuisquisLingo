import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/available_courses_screen.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_library_presentation.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_file_io.dart';

Course _course(
  String id,
  String title, {
  String source = 'English',
  String target = 'Italian',
  String modified = '2026-01-01T00:00:00.000Z',
  int? hours,
}) => Course(
  courseId: id,
  modifiedAtUtc: modified,
  estimatedStudyHours: hours,
  learningLanguage: target,
  interfaceLanguage: source,
  sourceLanguage: source,
  targetLanguage: target,
  title: title,
  ttsLanguage: 'it-IT',
  lessons: const [],
);

List<String> _ids(List<Course> courses) => [
  for (final c in courses) c.courseId,
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  List<Course> sort(
    List<Course> courses,
    CourseLibrarySort by, [
    Map<String, String> maintainers = const {},
  ]) => CourseLibraryPresentation.sorted(
    courses,
    by,
    maintainerOf: (c) => maintainers[c.courseId] ?? '',
  );

  test('Title: case-insensitive A to Z, then courseId', () {
    final courses = [
      _course('c', 'beta'),
      _course('b', 'Alpha'),
      _course('a', 'alpha'),
      _course('d', '  Gamma'),
    ];
    expect(_ids(sort(courses, CourseLibrarySort.title)), ['a', 'b', 'c', 'd']);
  });

  test('Language: target, then source, then title', () {
    final courses = [
      _course('it-en', 'Z', source: 'English', target: 'Italian'),
      _course('fr-it', 'A', source: 'Italian', target: 'French'),
      _course('it-de', 'B', source: 'German', target: 'Italian'),
      _course('it-en2', 'A', source: 'english', target: 'italian'),
    ];
    expect(_ids(sort(courses, CourseLibrarySort.language)), [
      'fr-it',
      'it-en2',
      'it-en',
      'it-de',
    ]);
  });

  test('Maintainer: A to Z, then title', () {
    final courses = [_course('1', 'B'), _course('2', 'A'), _course('3', 'C')];
    expect(
      _ids(
        sort(courses, CourseLibrarySort.maintainer, {
          '1': 'bob',
          '2': 'Bob',
          '3': 'Alice',
        }),
      ),
      ['3', '2', '1'],
    );
  });

  test('Most recent: newest first, then title', () {
    final courses = [
      _course('old', 'A', modified: '2025-05-01T00:00:00.000Z'),
      _course('new', 'Z', modified: '2026-09-20T00:00:00.000Z'),
      _course('tie', 'B', modified: '2025-05-01T00:00:00.000Z'),
    ];
    expect(_ids(sort(courses, CourseLibrarySort.mostRecent)), [
      'new',
      'old',
      'tie',
    ]);
  });

  test('Duration: shortest first, unknown last', () {
    final courses = [
      _course('none', 'A'),
      _course('long', 'B', hours: 40),
      _course('short', 'C', hours: 1),
      _course('none2', 'B'),
      _course('mid', 'D', hours: 12),
    ];
    expect(_ids(sort(courses, CourseLibrarySort.duration)), [
      'short',
      'mid',
      'long',
      'none',
      'none2',
    ]);
  });

  test('sorting is stable across repeated calls and input orders', () {
    final courses = [
      _course('b', 'Same', hours: 2),
      _course('a', 'Same', hours: 2),
      _course('c', 'Same'),
    ];
    for (final by in CourseLibrarySort.values) {
      final once = _ids(sort(courses, by));
      expect(_ids(sort(courses.reversed.toList(), by)), once, reason: '$by');
    }
  });

  testWidgets('Sort by reorders inside a section and never moves Courses', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await tester.runAsync(() async {
      await ProfileService().createProfile(
        'Alice',
        learnerProfileId: '11111111-1111-4111-8111-111111111111',
        generateScreenNameSuffix: false,
      );
      await ProfileService().setActiveProfileById(
        '11111111-1111-4111-8111-111111111111',
      );
    });
    await tester.binding.setSurfaceSize(const Size(800, 8000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final local = [
      _course('user_a', 'A long one', hours: 30),
      _course('user_b', 'B unknown'),
      _course('user_c', 'C short', hours: 2),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: AvailableCoursesScreen(editorService: _DeviceCourses(local)),
      ),
    );
    await tester.pumpUntilFileIoState(
      () => find.text('Bundled Courses').evaluate().isNotEmpty,
    );

    List<String> titlesIn(int section) => [
      for (final text in tester.widgetList<Text>(
        find.descendant(
          of: find.byKey(ValueKey('course-section-$section')),
          matching: find.byWidgetPredicate(
            (w) =>
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>).value.startsWith(
                  'device-course-title-',
                ),
          ),
        ),
      ))
        text.data!,
    ];

    final bundledBefore = titlesIn(0).toSet();
    expect(titlesIn(3), ['A long one', 'B unknown', 'C short']);

    await tester.tap(find.byKey(const Key('course-library-sort')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duration').last);
    await tester.pumpAndSettle();

    expect(titlesIn(3), ['C short', 'A long one', 'B unknown']);
    expect(titlesIn(0).toSet(), bundledBefore);
    for (final section in [1, 2]) {
      expect(titlesIn(section), isEmpty);
    }
  });
}

class _DeviceCourses extends CourseEditorService {
  final List<Course> courses;
  _DeviceCourses(this.courses);
  @override
  Future<List<Course>> listUserCourses() async => courses;
}
