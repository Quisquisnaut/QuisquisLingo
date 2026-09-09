import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/official_course_inspection_screen.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_service.dart';
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
    testWidgets(
      'official hierarchy puts passive IDs below both actionable lines at $width px',
      (tester) async {
        await tester.binding.setSurfaceSize(Size(width, 1100));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final course = _officialCourse();
        await tester.pumpWidget(
          MaterialApp(
            home: OfficialCourseInspectionScreen(
              course: course,
              courseService: _BundledSource(course),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byTooltip('Internal IDs shown. Tap to hide'),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(const Key('course-editor-lessons-navigation')),
        );
        await tester.pumpAndSettle();

        await _checkEntryAndFollowBothLines(
          tester,
          entryKey: 'lesson-entry-lesson',
          id: 'lesson',
          destinationText: 'Preview Lesson',
        );
        await _checkEntryAndFollowBothLines(
          tester,
          entryKey: 'official-round-round',
          id: 'round',
          destinationText: 'Preview Round',
        );
        await _checkEntryAndFollowBothLines(
          tester,
          entryKey: 'official-exercise-exercise',
          id: 'exercise',
          destinationText: 'Exercise inspection',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}

Future<void> _checkEntryAndFollowBothLines(
  WidgetTester tester, {
  required String entryKey,
  required String id,
  required String destinationText,
}) async {
  final entry = find.byKey(ValueKey(entryKey));
  final idLine = find.byKey(ValueKey('editor-internal-id-$id'));
  await tester.ensureVisible(entry);
  await tester.ensureVisible(idLine);
  await tester.pumpAndSettle();

  final tile = tester.widget<ListTile>(entry);
  final firstLine = find.byWidget(tile.title!);
  final secondLine = find.byWidget(tile.subtitle!);
  expect(tile.onTap, isNotNull);
  expect(
    tester.getRect(secondLine).top,
    greaterThanOrEqualTo(tester.getRect(firstLine).bottom),
  );
  expect(
    tester.getRect(idLine).top,
    greaterThanOrEqualTo(tester.getRect(secondLine).bottom),
  );
  expect(
    tester.getRect(idLine).top,
    greaterThanOrEqualTo(tester.getRect(entry).bottom),
  );
  expect(
    find.ancestor(of: idLine, matching: find.byType(ListTile)),
    findsNothing,
  );
  expect(tester.widget<SelectableText>(idLine).onTap, isNull);
  expect(tester.takeException(), isNull);

  await tester.tap(idLine);
  await tester.pumpAndSettle();
  expect(entry, findsOneWidget, reason: 'Selecting an ID must not navigate.');

  final currentTile = tester.widget<ListTile>(entry);
  await tester.tap(find.byWidget(currentTile.title!));
  await tester.pumpAndSettle();
  expect(find.text(destinationText), findsOneWidget);
  await tester.pageBack();
  await tester.pumpAndSettle();

  await tester.ensureVisible(entry);
  await tester.pumpAndSettle();
  final returnedTile = tester.widget<ListTile>(entry);
  await tester.tap(find.byWidget(returnedTile.subtitle!));
  await tester.pumpAndSettle();
  expect(find.text(destinationText), findsOneWidget);
}

class _BundledSource extends CourseService {
  _BundledSource(this.course);
  final Course course;

  @override
  Future<Course> loadBundledCourse(String languageCode) async => course;
}

Course _officialCourse() {
  final updatedAt = DateTime.utc(2026, 9, 1);
  final course = Course(
    courseId: 'official-id-order',
    originType: CourseOriginType.bundledOfficial,
    publisherId: 'publisher',
    publisherName: 'Publisher',
    officialCourseVersion: '1',
    officialReleaseDateUtc: updatedAt.toIso8601String(),
    officialChecksum: '0' * 64,
    distributionChannel: 'app',
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    title: 'Official course',
    ttsLanguage: 'it-IT',
    version: '1',
    lessons: [
      Lesson(
        lessonId: 'lesson',
        updatedAt: updatedAt,
        title: 'A long Lesson title that wraps on narrow screens',
        rounds: [
          LearningRound(
            id: 'round',
            updatedAt: updatedAt,
            title: 'A long Round title that wraps on narrow screens',
            exercises: [
              Exercise(
                id: 'exercise',
                updatedAt: updatedAt,
                type: 'choice',
                prompt: 'A long Exercise prompt that wraps on narrow screens',
                question: 'Choose one.',
                answers: const ['One', 'Two'],
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
  return Course.fromJson({
    ...course.toJson(),
    'officialChecksum': CourseBackupService.officialContentChecksum(course),
  });
}
