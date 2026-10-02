import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/duel_screen.dart';
import 'package:quisquislingo_app/screens/guidebook_screen.dart';
import 'package:quisquislingo_app/screens/home_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/course_service.dart';
import 'package:quisquislingo_app/services/duel_eligibility_service.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/pump_file_io.dart';

/// Build 261 Revision 2 (owner decisions of 1 October 2026): the Course
/// preview from the Course Editor.
const _alice = '11111111-1111-4111-8111-111111112612';

/// QQL Demo: English from Italian with its Lesson, GuideBook and second
/// Round turned into Drafts, as an author may hold them.
Course _draftCourse(Course course) {
  final json = course.toJson();
  final lesson = (json['lessons'] as List).first as Map<String, dynamic>;
  lesson['publicationState'] = 'draft';
  final guidebook = lesson['guidebook'] as Map<String, dynamic>;
  guidebook['publicationState'] = 'draft';
  ((lesson['rounds'] as List)[1] as Map<String, dynamic>)['publicationState'] =
      'draft';
  return Course.fromJson(json);
}

Future<Map<String, Object?>> _preferences() async {
  final prefs = await SharedPreferences.getInstance();
  return {for (final key in prefs.getKeys()) key: prefs.get(key)};
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Course english;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
    await ProfileService().createProfile(
      'Alice',
      learnerProfileId: _alice,
      generateScreenNameSuffix: false,
    );
    await ProfileService().setActiveProfileById(_alice);
    english = await CourseService().loadCourse('EN_IT');
  });

  test('the preview Duel counts Draft content', () {
    final lesson = _draftCourse(english).lessons.first;
    const service = DuelEligibilityService();
    expect(service.evaluate(lesson).eligibleCount, 0);
    expect(
      service.evaluate(lesson, includeDrafts: true).eligibleCount,
      greaterThan(0),
    );
  });

  testWidgets('the preview shows Drafts on a clean slate and writes nothing', (
    tester,
  ) async {
    final course = _draftCourse(english);
    final before = await tester.runAsync(_preferences);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => openCoursePreview(context, course),
                child: const Text('Open preview'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open preview'));
    // The Course's flag is read from files, as on the learner page.
    await tester.pumpUntilFileIoState(
      () => find.byKey(const Key('course-preview-page')).evaluate().isNotEmpty,
    );

    expect(find.byKey(const Key('course-preview-page')), findsOneWidget);
    expect(find.text(course.title), findsOneWidget);
    final lesson = course.lessons.first;
    // Every Lesson open, nothing completed.
    expect(
      find.byKey(ValueKey('unified-lesson-locked-${lesson.lessonId}')),
      findsNothing,
    );
    expect(find.text('Practice'), findsNothing);
    expect(find.text('Perfect'), findsNothing);
    // The Draft Round is on the path.
    final draftRound = lesson.rounds[1];
    expect(draftRound.publicationState, PublicationState.draft);
    expect(
      find.byKey(ValueKey('unified-round-${draftRound.id}')),
      findsOneWidget,
    );

    // Selector, Profile, Review and Settings are not available.
    for (final key in ['course-preview-profile', 'course-preview-review']) {
      expect(
        tester.widget<TextButton>(find.byKey(Key(key))).onPressed,
        isNull,
        reason: key,
      );
    }
    expect(
      tester
          .widget<IconButton>(find.byKey(const Key('course-preview-settings')))
          .onPressed,
      isNull,
    );
    expect(
      find.byKey(const Key('unified-topbar-course-selector')),
      findsNothing,
    );

    // The Draft GuideBook opens with its Draft content.
    await tester.tap(find.byKey(const Key('unified-guidebook-node')).first);
    await tester.pumpUntilFileIoState(
      () => find.byType(GuidebookScreen).evaluate().isNotEmpty,
    );
    expect(
      tester
          .widget<GuidebookScreen>(find.byType(GuidebookScreen))
          .includeDraftContent,
      isTrue,
    );
    await tester.pageBack();
    await tester.pumpUntilFileIoState(
      () => find.byType(GuidebookScreen).evaluate().isEmpty,
    );

    // A Round plays in Preview.
    await tester.tap(find.byKey(ValueKey('unified-round-${draftRound.id}')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final round = tester.widget<RoundScreen>(find.byType(RoundScreen));
    expect(round.previewMode, isTrue);
    expect(round.round.id, draftRound.id);
    // The Round keeps loading in fake time; close its route directly.
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    await tester.tap(find.byKey(const Key('course-preview-exit')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('course-preview-page')), findsNothing);
    expect(find.text('Open preview'), findsOneWidget);
    expect(await tester.runAsync(_preferences), before);
  });

  testWidgets('a Duel opened from the preview is marked PREVIEW', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DuelScreen(
          course: english,
          lesson: english.lessons.first,
          ttsLanguage: 'en-GB',
          previewMode: true,
        ),
      ),
    );
    await tester.pump();
    expect(find.textContaining('PREVIEW · '), findsOneWidget);
  });

  testWidgets('the Course Editor flag opens the preview and comes back', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: CourseEditorScreen(course: english)),
    );
    await tester.pumpUntilFileIoState(
      () => find.byKey(const Key('course-preview-flag')).evaluate().isNotEmpty,
    );
    await tester.tap(find.byKey(const Key('course-preview-flag')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<CoursePreviewScreen>(find.byType(CoursePreviewScreen))
          .course
          .courseId,
      english.courseId,
    );
    await tester.tap(find.byKey(const Key('course-preview-exit')));
    await tester.pumpAndSettle();
    expect(find.byType(CoursePreviewScreen), findsNothing);
    expect(find.byType(CourseEditorScreen), findsOneWidget);
  });

  testWidgets('the Round editor shows the flag left of its title', (
    tester,
  ) async {
    final lesson = english.lessons.first;
    await tester.pumpWidget(
      MaterialApp(
        home: RoundEditorScreen(
          course: english,
          lesson: lesson,
          round: lesson.rounds[1],
          roundIndex: 1,
          readOnly: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final flag = find.byKey(const Key('course-preview-flag'));
    expect(
      find.descendant(of: find.byType(AppBar), matching: flag),
      findsOneWidget,
    );
    await tester.tap(flag);
    await tester.pumpAndSettle();
    expect(find.byType(CoursePreviewScreen), findsOneWidget);
    await tester.tap(find.byKey(const Key('course-preview-exit')));
    await tester.pumpAndSettle();
    expect(find.byType(RoundEditorScreen), findsOneWidget);
  });

  testWidgets('from an exercise form the preview leaves out unsaved edits', (
    tester,
  ) async {
    final lesson = english.lessons.first;
    final round = lesson.rounds[1];
    final exercise = round.exercises.first;
    await tester.pumpWidget(
      MaterialApp(
        home: ExerciseEditorScreen(
          exercise: exercise,
          title: 'Exercise',
          isNew: false,
          course: english,
          lesson: lesson,
          round: round,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'An unsaved edit');
    await tester.pump();
    await tester.tap(find.byKey(const Key('course-preview-flag')));
    await tester.pumpAndSettle();
    final previewed = tester
        .widget<CoursePreviewScreen>(find.byType(CoursePreviewScreen))
        .course
        .lessons
        .first
        .rounds[1]
        .exercises
        .firstWhere((item) => item.id == exercise.id);
    expect(previewed.semanticallyEquals(exercise), isTrue);
    await tester.tap(find.byKey(const Key('course-preview-exit')));
    await tester.pumpAndSettle();
    expect(find.text('An unsaved edit'), findsOneWidget);
  });
}
