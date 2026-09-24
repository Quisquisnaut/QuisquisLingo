import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/courses_screen.dart';
import 'package:quisquislingo_app/services/course_editor_service.dart';
import 'package:quisquislingo_app/services/course_library_service.dart';
import 'package:quisquislingo_app/services/course_media_store.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/settings_service.dart';
import 'package:quisquislingo_app/widgets/course_artwork.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_file_io.dart';

const _learnerId = '11111111-1111-4111-8111-111111111111';

class _DeviceCourses extends CourseEditorService {
  _DeviceCourses(this.course);

  final Course course;

  @override
  Future<List<Course>> listUserCourses() async => [course];
}

Course _course(String id, {String cover = ''}) => Course(
  courseId: id,
  originType: CourseOriginType.custom,
  courseVersion: '1',
  publicationState: PublicationState.published,
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Preview $id',
  ttsLanguage: 'it-IT',
  flagCode: 'IT',
  coverImage: cover,
  lessons: const [],
);

Future<void> _pumpCourses(
  WidgetTester tester,
  Course course, {
  Size size = const Size(900, 1400),
}) async {
  await CourseLibraryService().add(course);
  await SettingsService().setCourseEditorUnlocked(true);
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(home: CoursesScreen(editorService: _DeviceCourses(course))),
  );
  await tester.pumpUntilFileIoState(
    () => find.byKey(const Key('courses-tab-manager')).evaluate().isNotEmpty,
  );
}

Future<void> _showRow(WidgetTester tester, String rowKey) async {
  await tester.scrollUntilVisible(
    find.byKey(ValueKey(rowKey)),
    300,
    scrollable: find.byType(Scrollable).first,
  );
}

Finder _inPreview(String id, Finder matching) => find.descendant(
  of: find.byKey(ValueKey('course-artwork-preview-$id')),
  matching: matching,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await ProfileService().createProfile(
      'Alice',
      learnerProfileId: _learnerId,
      generateScreenNameSuffix: false,
    );
    await ProfileService().setActiveProfileById(_learnerId);
  });

  testWidgets('All Courses opens an uncropped, enlarged cover and closes it', (
    tester,
  ) async {
    const id = 'preview_cover';
    final bytes = await tester.runAsync(
      () => File('test/fixtures/import/valid_cover.png').readAsBytes(),
    );
    final cover = (await tester.runAsync(
      () => CourseMediaStore().addBytes(id, bytes!, 'png'),
    ))!;
    await _pumpCourses(tester, _course(id, cover: cover));
    await _showRow(tester, 'device-course-$id');

    final row = find.byKey(ValueKey('device-course-$id'));
    final opener = find.descendant(
      of: row,
      matching: find.byKey(ValueKey('course-artwork-open-$id')),
    );
    await tester.tap(opener);
    await tester.pumpAndSettle();

    final preview = find.byKey(ValueKey('course-artwork-preview-$id'));
    expect(preview, findsOneWidget);
    await tester.pumpUntilFileIoState(
      () => _inPreview(id, find.byType(Image)).evaluate().isNotEmpty,
    );
    final image = tester.widget<Image>(_inPreview(id, find.byType(Image)));
    expect(image.fit, BoxFit.contain);
    expect(
      tester.getSize(_inPreview(id, find.byType(CourseArtwork))).width,
      greaterThan(64),
    );

    await tester.tap(find.byKey(const Key('course-artwork-preview-close')));
    await tester.pumpAndSettle();
    expect(preview, findsNothing);
    expect(row, findsOneWidget);
  });

  testWidgets(
    'Course Studio artwork opens flag preview without opening Editor',
    (tester) async {
      const id = 'preview_flag';
      await _pumpCourses(tester, _course(id));
      await tester.tap(find.byKey(const Key('courses-tab-manager')));
      await tester.pumpUntilFileIoState(
        () => find.byKey(const Key('manager-section-0')).evaluate().isNotEmpty,
      );
      await _showRow(tester, 'manager-course-$id');

      final row = find.byKey(ValueKey('manager-course-$id'));
      await tester.tap(
        find.descendant(
          of: row,
          matching: find.byKey(ValueKey('course-artwork-open-$id')),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(ValueKey('course-artwork-preview-$id')),
        findsOneWidget,
      );
      expect(
        _inPreview(id, find.byKey(ValueKey('course-artwork-flag-$id'))),
        findsOneWidget,
      );
      expect(find.byType(CourseEditorScreen), findsNothing);

      await tester.tap(find.byKey(const Key('course-artwork-preview-close')));
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('course-artwork-preview-$id')), findsNothing);
      expect(row, findsOneWidget);
      expect(find.byType(CourseEditorScreen), findsNothing);
    },
  );

  testWidgets('missing cover previews its flag within a phone viewport', (
    tester,
  ) async {
    const id = 'preview_missing';
    final course = _course(id, cover: 'media:${'a' * 64}.png');
    await _pumpCourses(tester, course, size: const Size(320, 640));
    await _showRow(tester, 'device-course-$id');
    await tester.ensureVisible(
      find.byKey(ValueKey('course-artwork-open-$id')).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('course-artwork-open-$id')).first);
    await tester.pumpUntilFileIoState(
      () => _inPreview(
        id,
        find.byKey(ValueKey('course-artwork-flag-$id')),
      ).evaluate().isNotEmpty,
    );

    final dialog = find.byKey(ValueKey('course-artwork-preview-$id'));
    final bounds = tester.getRect(dialog);
    expect(bounds.left, greaterThanOrEqualTo(0));
    expect(bounds.top, greaterThanOrEqualTo(0));
    expect(bounds.right, lessThanOrEqualTo(320));
    expect(bounds.bottom, lessThanOrEqualTo(640));
    expect(tester.takeException(), isNull);
  });
}
