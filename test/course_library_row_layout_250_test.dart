import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/available_courses_screen.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_favorite_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_file_io.dart';

const _alice = '11111111-1111-4111-8111-111111111111';
const _id = 'layout_course';

class _DeviceCourses extends CourseEditorService {
  _DeviceCourses(this.course);
  final Course course;

  @override
  Future<List<Course>> listUserCourses() async => [course];
}

Course _course() => Course(
  courseId: _id,
  originType: CourseOriginType.custom,
  courseVersion: '12',
  publicationState: PublicationState.published,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'A long Course title that wraps across several lines on a phone',
  ttsLanguage: 'it-IT',
  lessons: const [],
);

Finder _inRow(Finder row, Finder matching) =>
    find.descendant(of: row, matching: matching);

Future<void> _pumpCourses(
  WidgetTester tester, {
  required Size size,
  bool favorite = false,
  Brightness brightness = Brightness.light,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  if (favorite) await CourseFavoriteService().setFavorite(_id, true);
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData(brightness: brightness),
      home: AvailableCoursesScreen(
        embedded: true,
        showUnavailable: true,
        editorService: _DeviceCourses(_course()),
      ),
    ),
  );
  await tester.pumpUntilFileIoState(
    () => find.byKey(const Key('device-course-$_id')).evaluate().isNotEmpty,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await ProfileService().createProfile(
      'Alice',
      learnerProfileId: _alice,
      generateScreenNameSuffix: false,
    );
    await ProfileService().setActiveProfileById(_alice);
  });

  testWidgets('phone row reserves its right edge for the menu', (tester) async {
    await _pumpCourses(tester, size: const Size(320, 8000));
    final row = find.byKey(const Key('device-course-$_id'));
    final title = _inRow(
      row,
      find.byKey(const Key('device-course-title-$_id')),
    );
    final menu = _inRow(row, find.byKey(const Key('all-course-actions-$_id')));
    final membership = _inRow(row, find.byKey(const Key('add-course-$_id')));
    final details = _inRow(row, find.textContaining('Maintainer:'));

    expect(menu, findsOneWidget);
    expect(membership, findsOneWidget);
    expect(
      tester.getRect(menu).left,
      greaterThanOrEqualTo(tester.getRect(title).right),
    );
    expect(
      tester.getRect(menu).right,
      lessThanOrEqualTo(tester.getRect(row).right),
    );
    expect(tester.getRect(menu).top, lessThan(tester.getRect(title).bottom));
    expect(
      tester.getRect(membership).top,
      greaterThan(tester.getRect(details).bottom),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('wide row keeps membership beside the right-edge menu', (
    tester,
  ) async {
    await _pumpCourses(tester, size: const Size(900, 3000));
    final row = find.byKey(const Key('device-course-$_id'));
    final menu = _inRow(row, find.byKey(const Key('all-course-actions-$_id')));
    final membership = _inRow(row, find.byKey(const Key('add-course-$_id')));

    expect(
      tester.getRect(membership).right,
      lessThanOrEqualTo(tester.getRect(menu).left),
    );
    expect(
      (tester.getRect(membership).center.dy - tester.getRect(menu).center.dy)
          .abs(),
      lessThan(12),
    );
    expect(
      tester.getRect(menu).right,
      lessThanOrEqualTo(tester.getRect(row).right),
    );
    expect(tester.takeException(), isNull);
  });

  for (final brightness in Brightness.values) {
    testWidgets(
      'Favorites uses a soft amber header and normal row ink in $brightness',
      (tester) async {
        await _pumpCourses(
          tester,
          size: const Size(900, 3000),
          favorite: true,
          brightness: brightness,
        );
        final section = find.byKey(const Key('course-section-favorites'));
        final row = _inRow(
          section,
          find.byKey(const Key('favorite-course-$_id')),
        );
        final header = tester.widget<Container>(
          find.descendant(of: section, matching: find.byType(Container)).first,
        );
        final borderBox = tester.widget<DecoratedBox>(
          find
              .descendant(of: section, matching: find.byType(DecoratedBox))
              .first,
        );
        final headerColor = header.color!;
        final borderColor =
            ((borderBox.decoration as BoxDecoration).border! as Border)
                .top
                .color;
        final title = tester.widget<Text>(
          _inRow(row, find.byKey(const Key('device-course-title-$_id'))),
        );
        final details = _inRow(row, find.text('English → Italian'));
        final theme = Theme.of(tester.element(row));

        expect(headerColor.a, greaterThan(0));
        expect(headerColor.a, lessThan(0.3));
        expect(headerColor.r, greaterThan(headerColor.b));
        expect(headerColor.g, greaterThan(headerColor.b));
        expect(borderColor.r, greaterThan(borderColor.b));
        expect(borderColor.g, greaterThan(borderColor.b));
        expect(title.style!.color, Colors.orange);
        expect(
          DefaultTextStyle.of(tester.element(details)).style.color,
          theme.colorScheme.onSurfaceVariant,
        );
        expect(
          _inRow(row, find.byKey(const Key('all-course-actions-$_id'))),
          findsOneWidget,
        );
        expect(theme.brightness, brightness);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
