import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/lesson_icon_catalog.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _custom = CourseLessonIconAsset(
  assetId: 'custom_a',
  base64Png: base64Encode(
    File('assets/lesson_icons/home.png').readAsBytesSync(),
  ),
);

Course _course(String? themeIcon) => Course.fromJson({
  ...Course(
    courseId: 'course',
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Course',
    ttsLanguage: 'it-IT',
    lessons: [
      Lesson(
        lessonId: 'one',
        publicationState: PublicationState.draft,
        title: 'First',
        themeIconAsset: themeIcon,
        rounds: const [],
      ),
    ],
  ).toJson(),
  'lessonIconAssets': [_custom.toJson()],
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> openSheet(WidgetTester tester, String? themeIcon) async {
    await tester.binding.setSurfaceSize(const Size(900, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final course = _course(themeIcon);
    await tester.pumpWidget(
      MaterialApp(
        home: LessonEditorScreen(course: course, lesson: course.lessons.first),
      ),
    );
    await tester.pumpAndSettle();
    final field = find.byKey(const Key('lesson-theme-icon-field'));
    await tester.scrollUntilVisible(
      field,
      200,
      scrollable: find.byType(Scrollable).first,
      maxScrolls: 20,
    );
    await tester.tap(field);
    await tester.pumpAndSettle();
  }

  final toggle = find.byKey(const Key('lesson-theme-icon-preinstalled-toggle'));
  final grid = find.byKey(const Key('lesson-theme-icon-grid'));

  testWidgets('import is a small icon with a tooltip, not a text button', (
    tester,
  ) async {
    await openSheet(tester, null);
    final import = find.byKey(const Key('import-custom-lesson-icon'));
    expect(tester.widget(import), isA<IconButton>());
    expect(find.text('Import custom icon'), findsNothing);
    expect(find.byTooltip('Import custom icon'), findsOneWidget);
  });

  testWidgets('with no icon chosen the single Preinstalled entry is Numbers', (
    tester,
  ) async {
    await openSheet(tester, null);
    expect(grid, findsNothing);
    expect(
      find.descendant(of: toggle, matching: find.text('Numbers')),
      findsOneWidget,
    );
    expect(find.text('None'), findsNothing);
  });

  testWidgets('a chosen preinstalled icon is the only one shown until opened', (
    tester,
  ) async {
    final option = LessonIconCatalog.options.first;
    await openSheet(tester, option.assetPath);

    expect(grid, findsNothing);
    expect(
      find.descendant(of: toggle, matching: find.text(option.label)),
      findsOneWidget,
    );
    for (final other in LessonIconCatalog.options.skip(1)) {
      expect(
        find.byKey(ValueKey('lesson-theme-icon-option-${other.id}')),
        findsNothing,
      );
    }

    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(grid, findsOneWidget);
    expect(
      tester.widget<GridView>(grid).childrenDelegate.estimatedChildCount,
      LessonIconCatalog.options.length + 1,
    );
    expect(
      find.descendant(of: grid, matching: find.text('Numbers')),
      findsOneWidget,
    );
  });

  testWidgets(
    'with a custom icon chosen no preinstalled icon is shown as chosen',
    (tester) async {
      await openSheet(tester, _custom.reference);
      expect(grid, findsNothing);
      expect(
        find.descendant(of: toggle, matching: find.text('Preinstalled icons')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('custom-lesson-icon-custom_a')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'the collapsed sheet is much smaller than the old fixed 76% height',
    (tester) async {
      await openSheet(tester, null);
      final collapsed = tester.getSize(find.byType(BottomSheet)).height;
      expect(collapsed, lessThan(1100 * .5));

      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(BottomSheet)).height,
        greaterThan(collapsed),
      );
    },
  );

  testWidgets('choosing an icon from the opened list still selects it', (
    tester,
  ) async {
    await openSheet(tester, null);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    final option = LessonIconCatalog.options.first;
    await tester.tap(
      find.byKey(ValueKey('lesson-theme-icon-option-${option.id}')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('lesson-theme-icon-preview')), findsOneWidget);
  });
}
