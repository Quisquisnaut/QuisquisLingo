import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _icon = CourseLessonIconAsset(
  assetId: 'custom_a',
  base64Png: base64Encode(
    File('assets/lesson_icons/home.png').readAsBytesSync(),
  ),
);

Course _course({String? firstLessonIcon, String? secondLessonIcon}) =>
    Course.fromJson({
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
            themeIconAsset: firstLessonIcon,
            rounds: const [],
          ),
          Lesson(
            lessonId: 'two',
            publicationState: PublicationState.draft,
            title: 'Second',
            themeIconAsset: secondLessonIcon,
            rounds: const [],
          ),
        ],
      ).toJson(),
      'lessonIconAssets': [_icon.toJson()],
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> openEditorSheet(
    WidgetTester tester,
    Course course,
    void Function(List<CourseLessonIconAsset>) onAssets,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1100));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: LessonEditorScreen(
          course: course,
          lesson: course.lessons.first,
          onLessonIconAssetsChanged: onAssets,
        ),
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

  final deleteButton = find.byKey(
    const ValueKey('delete-custom-lesson-icon-custom_a'),
  );

  testWidgets(
    'an unused custom icon can be deleted; kept only when the Lesson is saved',
    (tester) async {
      List<CourseLessonIconAsset>? saved;
      await openEditorSheet(tester, _course(), (assets) => saved = assets);
      expect(
        find.byKey(const ValueKey('custom-lesson-icon-custom_a')),
        findsOneWidget,
      );

      await tester.tap(deleteButton);
      await tester.pumpAndSettle();
      expect(find.text('Delete custom icon?'), findsOneWidget);
      await tester.tap(
        find.byKey(const Key('confirm-delete-custom-lesson-icon')),
      );
      await tester.pumpAndSettle();

      // The sheet reopens without the icon; nothing is handed back until Save.
      expect(find.text('No custom icons imported.'), findsOneWidget);
      expect(saved, isNull);

      await tester.tapAt(const Offset(10, 10)); // close the sheet
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('save-lesson-draft')));
      await tester.pumpAndSettle();
      expect(saved, isEmpty);
    },
  );

  testWidgets('cancelling the confirmation keeps the icon', (tester) async {
    await openEditorSheet(tester, _course(), (_) {});
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('custom-lesson-icon-custom_a')),
      findsOneWidget,
    );
  });

  testWidgets('an icon this Lesson uses cannot be deleted', (tester) async {
    List<CourseLessonIconAsset>? saved;
    await openEditorSheet(
      tester,
      _course(firstLessonIcon: _icon.reference),
      (assets) => saved = assets,
    );
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();

    expect(find.text('Delete custom icon?'), findsNothing);
    expect(find.textContaining('still used by this Lesson'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('custom-lesson-icon-custom_a')),
      findsOneWidget,
    );
    expect(saved, isNull);
  });

  testWidgets(
    'an icon another Lesson uses cannot be deleted and names that Lesson',
    (tester) async {
      await openEditorSheet(
        tester,
        _course(secondLessonIcon: _icon.reference),
        (_) {},
      );
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      expect(find.text('Delete custom icon?'), findsNothing);
      expect(find.textContaining('still used by Second'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('custom-lesson-icon-custom_a')),
        findsOneWidget,
      );
    },
  );
}
