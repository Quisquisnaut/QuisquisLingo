import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 256 Revision 5, Stage 4: the Story Wizard. A → B → C → builder,
/// at least one line, an exercise step returns to the builder, Finish
/// creates the Story Round through the Lesson editor's session, Cancel
/// creates nothing.
const _profileId = '12345678-1234-4234-9234-123456789abc';
final _stamp = DateTime.utc(2026, 9, 28, 9);

Course _course({bool useGuidebook = false}) => Course.fromJson({
  ...Course(
    courseId: 'story_wizard_256',
    originalCourseCreator: CourseProvenanceIdentity.qqlUser(
      profileId: _profileId,
      displayName: 'Original Course Creator',
    ),
    maintainer: const CourseMaintainer(_profileId),
    title: 'Story wizard course',
    learningLanguage: 'Italian',
    interfaceLanguage: 'English',
    sourceLanguage: 'English',
    targetLanguage: 'Italian',
    ttsLanguage: 'it-IT',
    storyCharacters: const [
      StorySpeaker(
        id: 'character_bob',
        name: 'Bob',
        language: TextLanguage.target,
      ),
    ],
    lessons: [
      Lesson(
        lessonId: 'lesson_one',
        title: 'Lesson one',
        updatedAt: _stamp,
        rounds: const [],
      ),
    ],
  ).toJson(),
  'useGuidebook': useGuidebook,
});

void _bigWindow(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _pumpLessonEditor(
  WidgetTester tester,
  Course course,
  ValueChanged<Course> onChanged,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: LessonEditorScreen(
        course: course,
        lesson: course.lessons.first,
        onCourseChanged: onChanged,
        clock: () => _stamp,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [
        const LearnerProfile(
          learnerProfileId: _profileId,
          displayName: 'Story author',
        ).encode(),
      ],
      ProfileService.activeProfileIdKey: _profileId,
      'sound_effects_enabled': false,
    });
    keepCrashLogUnavailable();
  });

  testWidgets('the Story Wizard needs no GuideBook', (tester) async {
    _bigWindow(tester);
    await _pumpLessonEditor(tester, _course(), (_) {});
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('lesson-round-wizard')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('lesson-story-wizard')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets(
    'A → B → C → builder: lines and an exercise make a Story Round with its speakers',
    (tester) async {
      _bigWindow(tester);
      Course? changed;
      await _pumpLessonEditor(tester, _course(), (value) => changed = value);
      await _tap(tester, find.byKey(const Key('lesson-story-wizard')));
      expect(find.byKey(const Key('story-wizard-step-story')), findsOneWidget);

      // A: the title is required; read-aloud on request.
      FilledButton next() => tester.widget<FilledButton>(
        find.byKey(const Key('story-wizard-next')),
      );
      expect(next().onPressed, isNull);
      await tester.enterText(
        find.byKey(const Key('story-wizard-title')),
        'Al bar',
      );
      await tester.pumpAndSettle();
      expect(next().onPressed, isNotNull);
      await _tap(tester, find.text('On request'));
      await _tap(tester, find.byKey(const Key('story-wizard-next')));

      // B: the narrator, prefilled from the Course, renamed here.
      expect(
        find.byKey(const Key('story-wizard-step-narrator')),
        findsOneWidget,
      );
      expect(find.text('Narrator (unnamed)'), findsOneWidget);
      await _tap(tester, find.byKey(const Key('story-wizard-edit-narrator')));
      await tester.enterText(
        find.byKey(const Key('story-speaker-name')),
        'The storyteller',
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const Key('story-speaker-save')));
      expect(find.text('Narrator: The storyteller'), findsOneWidget);
      await _tap(tester, find.byKey(const Key('story-wizard-next')));

      // C: the Course's characters, plus Anna with the cat avatar.
      expect(
        find.byKey(const Key('story-wizard-step-characters')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('story-wizard-character-character_bob')),
        findsOneWidget,
      );
      await _tap(tester, find.byKey(const Key('story-wizard-add-character')));
      await tester.enterText(
        find.byKey(const Key('story-speaker-name')),
        'Anna',
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const ValueKey('story-avatar-cat')));
      await _tap(tester, find.byKey(const Key('story-speaker-save')));
      expect(find.widgetWithText(ListTile, 'Anna'), findsOneWidget);
      await _tap(tester, find.byKey(const Key('story-wizard-next')));

      // The builder: Finish needs a line.
      expect(
        find.byKey(const Key('story-wizard-step-builder')),
        findsOneWidget,
      );
      FilledButton finish() => tester.widget<FilledButton>(
        find.byKey(const Key('story-wizard-finish')),
      );
      expect(finish().onPressed, isNull);
      await _tap(tester, find.byKey(const Key('story-wizard-add-line')));
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('story-line-save')))
            .onPressed,
        isNull,
      );
      await _tap(tester, find.byKey(const Key('story-line-speaker')));
      await _tap(tester, find.text('Anna').last);
      await tester.enterText(
        find.byKey(const Key('story-line-text')),
        'Buongiorno!',
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const Key('story-line-save')));
      expect(find.text('Buongiorno!'), findsOneWidget);
      expect(finish().onPressed, isNotNull);

      // A narrator line before it, moved to the top.
      await _tap(tester, find.byKey(const Key('story-wizard-add-line')));
      await tester.enterText(
        find.byKey(const Key('story-line-text')),
        'Anna walks into the café.',
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const Key('story-line-save')));
      await _tap(tester, find.byKey(const ValueKey('story-wizard-up-1')));

      // An exercise step: only the allowed presets, the normal form on top,
      // Save as draft returns to the builder.
      await _tap(tester, find.byKey(const Key('story-wizard-add-exercise')));
      expect(
        find.byKey(const ValueKey('story-wizard-preset-true_false')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('story-wizard-preset-flashcard')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('story-wizard-preset-dialogue_line')),
        findsNothing,
      );
      await _tap(
        tester,
        find.byKey(const ValueKey('story-wizard-preset-choice_target')),
      );
      expect(find.byType(ExerciseEditorScreen), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('exercise-field-question')),
        'What does Anna order?',
      );
      await tester.enterText(
        find.byKey(const ValueKey('exercise-field-answers')),
        'A coffee\nA tea',
      );
      await tester.enterText(
        find.byKey(const ValueKey('exercise-field-correct')),
        '1',
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const Key('exercise-save-draft')));
      expect(find.byType(ExerciseEditorScreen), findsNothing);
      expect(
        find.byKey(const Key('story-wizard-step-builder')),
        findsOneWidget,
      );
      expect(find.text('Choose the answer (to target)'), findsOneWidget);
      await _tap(tester, find.byType(CheckboxListTile));

      await _tap(tester, find.byKey(const Key('story-wizard-finish')));
      expect(find.byType(LessonEditorScreen), findsOneWidget);
      final lesson = changed!.lessons.first;
      expect(lesson.rounds, hasLength(1));
      final round = lesson.rounds.single;
      expect(round.title, 'Story: Al bar');
      expect(round.visualType, 'story');
      expect(round.publicationState, PublicationState.draft);
      final flow = round.flow!;
      expect(flow.isLinear, isTrue);
      expect(flow.presentation, FlowPresentation.scroll);
      expect(flow.log, FlowLog.dialogue);
      expect(flow.readAloud, FlowReadAloud.manual);
      expect(flow.title, 'Al bar');
      final kinds = [
        for (final content in round.content)
          ExerciseFeatures(content.exercise!).kind,
      ];
      expect(kinds, [
        LearnerExerciseKind.storyCover,
        LearnerExerciseKind.dialogueLine,
        LearnerExerciseKind.dialogueLine,
        LearnerExerciseKind.select,
      ]);
      expect(
        ExerciseFeatures(round.content[1].exercise!).lineText,
        'Anna walks into the café.',
      );
      final anna = round.content[2].exercise!;
      expect(ExerciseFeatures(anna).lineText, 'Buongiorno!');
      final exercise = round.content.last.exercise!;
      expect(exercise.publicationState, PublicationState.draft);
      expect(flow.audioDependentContentIds, {exercise.id});
      expect(flow.linearNodeIds(), [
        for (final content in round.content) content.id,
      ]);
      // The speakers reached the Course: the narrator renamed, Anna added
      // beside Bob, and the line names her.
      expect(changed!.narrator.name, 'The storyteller');
      expect(changed!.storyCharacters.map((c) => c.name), ['Bob', 'Anna']);
      final annaId = changed!.storyCharacters.last.id;
      expect(changed!.storyCharacters.last.avatar, 'assets/avatars/cat.png');
      expect(ExerciseFeatures(anna).speakerId, annaId);
    },
  );

  testWidgets('Cancel creates nothing', (tester) async {
    _bigWindow(tester);
    Course? changed;
    final course = _course();
    await _pumpLessonEditor(tester, course, (value) => changed = value);
    await _tap(tester, find.byKey(const Key('lesson-story-wizard')));
    await tester.enterText(
      find.byKey(const Key('story-wizard-title')),
      'Never told',
    );
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const Key('story-wizard-next')));
    await _tap(tester, find.byKey(const Key('story-wizard-edit-narrator')));
    await tester.enterText(
      find.byKey(const Key('story-speaker-name')),
      'Nobody',
    );
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const Key('story-speaker-save')));
    await _tap(tester, find.byKey(const Key('story-wizard-cancel')));
    expect(find.byType(LessonEditorScreen), findsOneWidget);
    expect(changed, isNull);
  });
}
