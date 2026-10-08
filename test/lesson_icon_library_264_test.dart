import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/lesson_icon_catalog.dart';
import 'package:quisquislingo_app/services/lesson_icon_pictures.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/bundled_image_catalog.dart';

// Build 264 Revision 8 (owner decision of 5 October 2026): a Lesson icon may
// be a QQL picture of the image library; a Course that uses one needs this
// build.

const _picture = 'assets/exercise_images/bread.webp';

Course _course(Lesson lesson, {int? minimumAppBuild}) => Course(
  courseId: 'course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  title: 'Course',
  ttsLanguage: 'it-IT',
  lessons: [lesson],
  minimumAppBuild: minimumAppBuild,
);

Lesson _lesson({String? icon}) => Lesson(
  lessonId: 'lesson',
  title: 'Lesson',
  rounds: const [],
  themeIconAsset: icon,
);

Map<String, dynamic> _lessonJson(String icon) => {
  ..._lesson().toJson(),
  'themeIconAsset': icon,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every QQL WebP of the library qualifies, no flag does', () {
    final paths = [
      for (final record in readBundledImageRecords())
        record['assetPath'] as String,
    ];
    expect(
      paths.where((p) => p.endsWith('.webp')),
      everyElement(predicate<String>(LessonIconCatalog.isLibraryPicture)),
    );
    expect(
      paths.where((p) => p.endsWith('.svg')),
      everyElement(
        predicate<String>((p) => !LessonIconCatalog.isLibraryPicture(p)),
      ),
    );
    expect(paths, contains(_picture));
  });

  test('a Lesson reads and writes a library picture as its icon', () {
    final lesson = Lesson.fromJson(_lessonJson(_picture));
    expect(lesson.themeIconAsset, _picture);
    expect(Lesson.fromJson(lesson.toJson()).themeIconAsset, _picture);
    for (final refused in [
      'assets/world_flags/flags/italy.svg',
      'assets/exercise_images/Bread.WEBP',
      'assets/exercise_images/../lesson_icons/home.png',
      'media:0123.webp',
    ]) {
      expect(
        () => Lesson.fromJson(_lessonJson(refused)),
        throwsFormatException,
        reason: refused,
      );
    }
  });

  test('the Audit accepts a library picture as a Lesson icon', () {
    final result = CourseAuditService().auditCourse(
      _course(_lesson(icon: _picture)),
    );
    expect(
      result.issues.where((issue) => issue.code == 'LESSON_THEME_ICON_INVALID'),
      isEmpty,
    );
  });

  test('a Course with a library icon records this build', () {
    final plain = _course(_lesson(icon: 'assets/lesson_icons/home.png'));
    expect(LessonIconPictures.withMinimumAppBuild(plain).minimumAppBuild, null);

    final raised = LessonIconPictures.withMinimumAppBuild(
      _course(_lesson(icon: _picture), minimumAppBuild: 258000),
    );
    expect(
      raised.minimumAppBuild,
      LessonIconCatalog.libraryPictureMinimumAppBuild,
    );

    // A Course already at this build keeps its record (a later one cannot
    // be built here: the app refuses a Course that needs a newer build).
    final same = _course(
      _lesson(icon: _picture),
      minimumAppBuild: LessonIconCatalog.libraryPictureMinimumAppBuild,
    );
    expect(
      identical(LessonIconPictures.withMinimumAppBuild(same), same),
      isTrue,
    );
  });

  test('the sixteen new icons join the fourteen, and need this build', () {
    expect(LessonIconCatalog.options, hasLength(30));
    expect(LessonIconCatalog.addedInBuild264, hasLength(16));
    expect(
      LessonIconCatalog.addedInBuild264,
      everyElement(predicate<String>(LessonIconCatalog.isApproved)),
    );
    final course = _course(_lesson(icon: 'assets/lesson_icons/music.png'));
    expect(
      LessonIconPictures.withMinimumAppBuild(course).minimumAppBuild,
      LessonIconCatalog.libraryPictureMinimumAppBuild,
    );
  });

  testWidgets('Choose from the image library sets the Lesson icon', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final lesson = _lesson();
    await tester.pumpWidget(
      MaterialApp(
        home: LessonEditorScreen(course: _course(lesson), lesson: lesson),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('lesson-theme-icon-field')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('lesson-theme-icon-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lesson-icon-from-library')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('exercise-image-search')),
      'bread',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('exercise-image-bread')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use image'));
    await tester.pumpAndSettle();

    final field = find.byKey(const Key('lesson-theme-icon-field'));
    expect(
      find.descendant(
        of: field,
        matching: find.text('Picture from the image library'),
      ),
      findsOneWidget,
    );
    final preview = tester.widget<Image>(
      find.byKey(const Key('lesson-theme-icon-preview')),
    );
    expect((preview.image as AssetImage).assetName, _picture);
  });

  testWidgets('a lesson icon chosen in the library is the preinstalled icon', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final lesson = _lesson();
    await tester.pumpWidget(
      MaterialApp(
        home: LessonEditorScreen(course: _course(lesson), lesson: lesson),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('lesson-theme-icon-field')),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const Key('lesson-theme-icon-field')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('lesson-icon-from-library')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('exercise-image-search')),
      'lesson_icon_music',
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('exercise-image-lesson_icon_music')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Use image'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byKey(const Key('lesson-theme-icon-field')),
        matching: find.text('Music'),
      ),
      findsOneWidget,
    );
  });
}
