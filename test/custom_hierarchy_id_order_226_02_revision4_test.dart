import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/editor_display_preferences.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      EditorDisplayPreferences.showInternalIdsKey: true,
    });
    EditorDisplayPreferences.resetForTesting();
  });

  for (final width in [320.0, 430.0]) {
    for (final level in _EntryLevel.values) {
      testWidgets(
        'custom ${level.name} keeps both actionable lines above its passive ID at $width px',
        (tester) async {
          await tester.binding.setSurfaceSize(Size(width, 1100));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final course = _customCourse();
          expect(course.originType, CourseOriginType.custom);
          expect(
            CourseAuditService()
                .auditCourse(course)
                .issues
                .where(
                  (issue) =>
                      issue.severity == AuditSeverity.error ||
                      issue.severity == AuditSeverity.warning,
                ),
            isEmpty,
          );
          final lesson = course.lessons.single;
          final round = lesson.rounds.single;
          final (screen, id, destination) = switch (level) {
            _EntryLevel.lesson => (
              LessonManagementScreen(course: course, initiallyLocked: false),
              lesson.lessonId,
              LessonEditorScreen,
            ),
            _EntryLevel.round => (
              LessonRoundsScreen(course: course, lesson: lesson),
              round.id,
              RoundEditorScreen,
            ),
            _EntryLevel.exercise => (
              RoundEditorScreen(
                course: course,
                lesson: lesson,
                round: round,
                roundIndex: 0,
              ),
              round.exercises.first.id,
              ExerciseEditorScreen,
            ),
          };
          await tester.pumpWidget(MaterialApp(home: screen));
          await tester.pumpAndSettle();
          expect(
            find.byTooltip('Internal IDs shown. Tap to hide'),
            findsOneWidget,
          );

          final card = find.byKey(
            ValueKey('${level.name}-status-indicator-$id'),
          );
          final entry = find.descendant(
            of: card,
            matching: find.byType(ListTile),
          );
          final idLine = find.descendant(
            of: card,
            matching: find.byKey(ValueKey('editor-internal-id-$id')),
          );
          await tester.ensureVisible(entry);
          await tester.ensureVisible(idLine);
          await tester.pumpAndSettle();
          _expectPassiveIdLast(tester, entry, idLine, width);

          await tester.tap(idLine);
          await tester.pumpAndSettle();
          expect(
            entry,
            findsOneWidget,
            reason: 'Selecting an ID must not navigate.',
          );
          expect(find.byType(destination), findsNothing);

          final title = tester.widget<ListTile>(entry).title!;
          await tester.tap(find.byWidget(title));
          await tester.pumpAndSettle();
          expect(
            find.byType(destination),
            findsOneWidget,
            reason: 'The first line must retain the existing edit navigation.',
          );
          expect(tester.takeException(), isNull);
          await tester.pageBack();
          await tester.pumpAndSettle();

          await tester.ensureVisible(entry);
          await tester.ensureVisible(idLine);
          await tester.pumpAndSettle();
          _expectPassiveIdLast(tester, entry, idLine, width);
          final subtitle = tester.widget<ListTile>(entry).subtitle!;
          await tester.tap(find.byWidget(subtitle));
          await tester.pumpAndSettle();
          expect(
            find.byType(destination),
            findsOneWidget,
            reason: 'The second line must retain the same edit navigation.',
          );
          expect(tester.takeException(), isNull);
          await tester.pageBack();
          await tester.pumpAndSettle();
          expect(
            find.byTooltip('Internal IDs shown. Tap to hide'),
            findsOneWidget,
          );
          _expectPassiveIdLast(tester, entry, idLine, width);
        },
      );
    }
  }
}

void _expectPassiveIdLast(
  WidgetTester tester,
  Finder entry,
  Finder idLine,
  double width,
) {
  expect(entry, findsOneWidget);
  expect(idLine, findsOneWidget);
  final tile = tester.widget<ListTile>(entry);
  expect(tile.onTap, isNotNull);
  final title = find.byWidget(tile.title!);
  final subtitle = find.byWidget(tile.subtitle!);
  final titleRect = tester.getRect(title);
  final subtitleRect = tester.getRect(subtitle);
  final idRect = tester.getRect(idLine);

  expect(subtitleRect.top, greaterThanOrEqualTo(titleRect.bottom));
  expect(idRect.top, greaterThanOrEqualTo(subtitleRect.bottom));
  expect(idRect.top, greaterThanOrEqualTo(tester.getRect(entry).bottom));
  expect(idRect.left, greaterThanOrEqualTo(0));
  expect(idRect.right, lessThanOrEqualTo(width));
  expect(titleRect.overlaps(idRect), isFalse);
  expect(subtitleRect.overlaps(idRect), isFalse);
  expect(
    find.ancestor(of: idLine, matching: find.byType(ListTile)),
    findsNothing,
  );
  expect(tester.widget<SelectableText>(idLine).onTap, isNull);
  expect(tester.takeException(), isNull);
}

enum _EntryLevel { lesson, round, exercise }

Course _customCourse() {
  final updatedAt = DateTime.utc(2026, 9, 6);
  return Course(
    courseId: 'custom-id-order-course',
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Custom course',
    ttsLanguage: 'it-IT',
    lessons: [
      Lesson(
        lessonId: 'custom-lesson-with-a-long-stable-internal-identifier',
        updatedAt: updatedAt,
        title: 'A long Lesson title that wraps on narrow screens',
        guidebook: Guidebook(
          content: [
            LearningContent.textual(
              id: 'guidebook-overview',
              kind: 'explanation',
              role: 'overview',
              text: 'Reviewed overview.',
            ),
          ],
        ),
        rounds: [
          LearningRound(
            id: 'custom-round-with-a-long-stable-internal-identifier',
            updatedAt: updatedAt,
            title: 'A long Round title that wraps on narrow screens',
            exercises: [
              for (var index = 0; index < 3; index++)
                Exercise(
                  id: 'custom-exercise-with-a-long-stable-internal-identifier-$index',
                  updatedAt: updatedAt,
                  type: 'choice',
                  prompt: 'A long Exercise prompt that wraps on narrow screens',
                  question: 'Choose a greeting for situation $index.',
                  answers: const ['hello', 'goodbye'],
                  correct: 0,
                  tts: null,
                  accepted: const [],
                  tokens: const [],
                  orderAnswer: const [],
                  pairs: const [],
                  hint: '',
                  icons: const [],
                ),
            ],
          ),
        ],
      ),
    ],
  );
}
