import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/models/exercise_features.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/exercise_draft_builder.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/round_flow_authoring.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 256 Revision 5, Stage 3: the Dialogue line and Story cover forms,
/// the Round editor's Story options (title, presentation, log, read-aloud,
/// audio dependence), the Course editor's Story characters section and the
/// speaker dialog.
const _profileId = '12345678-1234-4234-9234-123456789abc';
final _stamp = DateTime.utc(2026, 9, 28);

Exercise _blank(String id) => Exercise.canonical(
  id: id,
  publicationState: PublicationState.draft,
  primitive: ExercisePrimitive.presentation,
  canonicalEvaluation: CanonicalEvaluation.none,
  updatedAt: _stamp,
);

Exercise _line(String id, String text, {String speakerId = ''}) =>
    ExerciseDraftBuilder.build(
      ExerciseDraftValues(
        original: _blank(id),
        type: 'dialogue_line',
        publicationState: PublicationState.published,
        prompt: text,
        speakerId: speakerId,
      ),
    ).candidate!;

Exercise _emptyFor(String preset) => ExerciseDraftBuilder.build(
  ExerciseDraftValues(
    original: _blank('new'),
    type: preset,
    publicationState: PublicationState.draft,
  ),
).candidate!;

Exercise _select(String id, String question) => Exercise.canonical(
  id: id,
  primitive: ExercisePrimitive.select,
  promptElements: [PromptElement(type: 'text', text: question)],
  items: [
    ExerciseItem(
      id: '${id}_a',
      content: [PromptElement(type: 'text', text: 'Right')],
    ),
    ExerciseItem(
      id: '${id}_b',
      content: [PromptElement(type: 'text', text: 'Wrong')],
    ),
  ],
  canonicalEvaluation: CanonicalEvaluation(
    mode: EvaluationMode.exactItem,
    correctItemIds: ['${id}_a'],
  ),
  updatedAt: _stamp,
);

LearningRound _round({ContentFlow? flow, String title = 'Round one'}) {
  final content = [
    for (final exercise in [
      _line('n1', 'Anna walks into the café.'),
      _line('a1', 'Un caffè, per favore.', speakerId: 'character_anna'),
      _select('q1', 'What did Anna order?'),
    ])
      LearningContent.fromExercise(exercise),
  ];
  return LearningRound(
    id: 'round_one',
    title: title,
    updatedAt: _stamp,
    content: content,
    flow: flow,
  );
}

Course _course({LearningRound? round}) => Course(
  courseId: 'story_editor_256',
  originalCourseCreator: CourseProvenanceIdentity.qqlUser(
    profileId: _profileId,
    displayName: 'Original Course Creator',
  ),
  maintainer: const CourseMaintainer(_profileId),
  title: 'Story editor course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  storyNarrator: const StorySpeaker(
    name: 'Narrator',
    language: TextLanguage.source,
  ),
  storyCharacters: const [
    StorySpeaker(
      id: 'character_anna',
      name: 'Anna',
      avatar: 'assets/avatars/cat.png',
      language: TextLanguage.target,
      voice: StoryVoice.female,
    ),
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
      rounds: [round ?? _round()],
    ),
  ],
);

void _bigWindow(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _choose(WidgetTester tester, String fieldKey, String label) async {
  final field = find.descendant(
    of: find.byKey(ValueKey('exercise-choice-$fieldKey')),
    matching: find.byType(DropdownButtonFormField<String>),
  );
  await tester.ensureVisible(field);
  await tester.tap(field);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

LearningRound _roundOf(Course course) => course.lessons.first.rounds.first;

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

  group('Dialogue line form', () {
    testWidgets('offers the speakers of the Course and saves the line', (
      tester,
    ) async {
      _bigWindow(tester);
      Exercise? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: _emptyFor('dialogue_line'),
            title: 'New exercise',
            isNew: true,
            course: _course(),
            onExerciseSaved: (exercise) => saved = exercise,
            clock: () => _stamp,
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final key in [
        'exercise-choice-speaker',
        'exercise-field-prompt',
        'exercise-choice-lineMode',
        'exercise-choice-readAloud',
        'exercise-choice-textReveal',
        'exercise-choice-language',
      ]) {
        expect(find.byKey(ValueKey(key)), findsOneWidget, reason: key);
      }
      // Every control has the field Help of its own key.
      for (final key in ['speaker', 'lineMode', 'readAloud', 'textReveal']) {
        expect(
          find.byKey(ValueKey('exercise-field-help-$key')),
          findsOneWidget,
          reason: key,
        );
      }
      await _choose(tester, 'speaker', 'Anna');
      await tester.enterText(
        find.byKey(const ValueKey('exercise-field-prompt')),
        'Buongiorno!',
      );
      await tester.pumpAndSettle();
      await _choose(tester, 'textReveal', 'After listening');
      await _choose(tester, 'readAloud', 'On request');
      await tester.ensureVisible(find.byKey(const Key('exercise-save-draft')));
      await tester.tap(find.byKey(const Key('exercise-save-draft')));
      await tester.pumpAndSettle();
      final features = ExerciseFeatures(saved!);
      expect(saved!.primitive, ExercisePrimitive.presentation);
      expect(saved!.editorTemplate, 'dialogue_line');
      expect(features.kind, LearnerExerciseKind.dialogueLine);
      expect(features.speakerId, 'character_anna');
      expect(features.lineText, 'Buongiorno!');
      expect(features.lineMode, 'both');
      expect(features.lineReadAloud, 'manual');
      expect(features.textReveal, TextReveal.afterAudio);
    });

    testWidgets('an audio-only line has no Show text choice', (tester) async {
      _bigWindow(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: _emptyFor('dialogue_line'),
            title: 'New exercise',
            isNew: true,
            course: _course(),
            clock: () => _stamp,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await _choose(tester, 'lineMode', 'Audio only');
      expect(
        find.byKey(const ValueKey('exercise-choice-textReveal')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('exercise-choice-readAloud')),
        findsOneWidget,
      );
      await _choose(tester, 'lineMode', 'Text only');
      expect(
        find.byKey(const ValueKey('exercise-choice-readAloud')),
        findsNothing,
      );
    });

    testWidgets('a stored line reopens with its speaker and choices', (
      tester,
    ) async {
      _bigWindow(tester);
      final line = ExerciseDraftBuilder.build(
        ExerciseDraftValues(
          original: _blank('a1'),
          type: 'dialogue_line',
          publicationState: PublicationState.published,
          prompt: 'Grazie.',
          speakerId: 'character_anna',
          lineMode: 'audio',
          lineReadAloud: 'automatic',
          lineLanguage: 'source',
        ),
      ).candidate!;
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: line,
            title: 'Edit exercise',
            isNew: false,
            course: _course(),
            clock: () => _stamp,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('exercise-choice-speaker-character_anna')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('exercise-choice-lineMode-audio')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('exercise-choice-readAloud-automatic')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('exercise-choice-language-source')),
        findsOneWidget,
      );
      expect(find.text('Grazie.'), findsOneWidget);
    });

    testWidgets('the Story cover form has a title line and the picture', (
      tester,
    ) async {
      _bigWindow(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: ExerciseEditorScreen(
            exercise: _emptyFor('story_cover'),
            title: 'New exercise',
            isNew: true,
            course: _course(),
            clock: () => _stamp,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Title line'), findsOneWidget);
      expect(find.text('Choose flat image'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('exercise-choice-speaker')),
        findsNothing,
      );
    });
  });

  group('Round editor Story options', () {
    testWidgets(
      'Story on writes scroll, dialogue log and automatic read-aloud; the title names the Round',
      (tester) async {
        _bigWindow(tester);
        final course = _course();
        Course? changed;
        await tester.pumpWidget(
          MaterialApp(
            home: RoundEditorScreen(
              course: course,
              lesson: course.lessons.first,
              round: _roundOf(course),
              roundIndex: 0,
              onCourseChanged: (value) => changed = value,
              clock: () => _stamp,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('round-story-title')), findsNothing);
        expect(find.byKey(const Key('round-story-log')), findsNothing);
        await tester.tap(find.byKey(const Key('round-story-switch')));
        await tester.pumpAndSettle();
        var flow = _roundOf(changed!).flow!;
        expect(flow.presentation, FlowPresentation.scroll);
        expect(flow.log, FlowLog.dialogue);
        expect(flow.readAloud, FlowReadAloud.automatic);
        expect(flow.title, '');
        expect(find.byKey(const Key('round-story-title')), findsOneWidget);
        expect(find.byKey(const Key('round-story-log')), findsOneWidget);
        expect(find.byKey(const Key('round-story-read-aloud')), findsOneWidget);

        await tester.enterText(
          find.byKey(const Key('round-story-title')),
          'Al bar',
        );
        await tester.pumpAndSettle();
        flow = _roundOf(changed!).flow!;
        expect(flow.title, 'Al bar');
        expect(_roundOf(changed!).title, 'Story: Al bar');
        expect(find.text('Story: Al bar'), findsOneWidget);

        await tester.tap(find.text('On request'));
        await tester.pumpAndSettle();
        expect(_roundOf(changed!).flow!.readAloud, FlowReadAloud.manual);
        await tester.tap(find.text('Everything'));
        await tester.pumpAndSettle();
        expect(_roundOf(changed!).flow!.log, FlowLog.all);

        // Step by step has no scroll log to filter.
        await tester.tap(find.text('Step by step'));
        await tester.pumpAndSettle();
        expect(_roundOf(changed!).flow!.presentation, FlowPresentation.step);
        expect(find.byKey(const Key('round-story-log')), findsNothing);

        // Story off: the Round keeps its name without the prefix.
        await tester.tap(find.byKey(const Key('round-story-switch')));
        await tester.pumpAndSettle();
        expect(_roundOf(changed!).flow, isNull);
        expect(_roundOf(changed!).title, 'Al bar');
      },
    );

    testWidgets('an exercise, not a line, can need the Story\'s audio', (
      tester,
    ) async {
      _bigWindow(tester);
      final round = _round(title: 'Story: Al bar');
      final story = LearningRound(
        id: round.id,
        title: round.title,
        updatedAt: round.updatedAt,
        content: round.content,
        flow: RoundFlowAuthoring.linearFor(
          round.content,
          presentation: FlowPresentation.scroll,
          title: 'Al bar',
          log: FlowLog.dialogue,
        ),
      );
      final course = _course(round: story);
      Course? changed;
      await tester.pumpWidget(
        MaterialApp(
          home: RoundEditorScreen(
            course: course,
            lesson: course.lessons.first,
            round: story,
            roundIndex: 0,
            onCourseChanged: (value) => changed = value,
            clock: () => _stamp,
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The stored title is shown as it is.
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('round-story-title')))
            .controller!
            .text,
        'Al bar',
      );
      await tester.tap(find.byKey(const ValueKey('exercise-actions-a1')));
      await tester.pumpAndSettle();
      expect(find.text('Needs the Story\'s audio'), findsNothing);
      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('exercise-actions-q1')));
      await tester.pumpAndSettle();
      final item = tester.widget<CheckedPopupMenuItem<String>>(
        find.byType(CheckedPopupMenuItem<String>),
      );
      expect(item.checked, isFalse);
      await tester.tap(find.text('Needs the Story\'s audio'));
      await tester.pumpAndSettle();
      expect(_roundOf(changed!).flow!.audioDependentContentIds, {'q1'});
      await tester.tap(find.byKey(const ValueKey('exercise-actions-q1')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CheckedPopupMenuItem<String>>(
              find.byType(CheckedPopupMenuItem<String>),
            )
            .checked,
        isTrue,
      );
      await tester.tap(find.text('Needs the Story\'s audio'));
      await tester.pumpAndSettle();
      expect(_roundOf(changed!).flow!.audioDependentContentIds, isEmpty);
    });
  });

  group('Course editor Story characters', () {
    Future<void> expand(WidgetTester tester) async {
      // The Course Editor opens Locked; Edit unlocks the characters' controls.
      await tester.tap(find.byKey(const Key('course-editor-lock')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();
      final tile = find.byKey(const Key('course-story-characters'));
      await tester.scrollUntilVisible(
        tile,
        200,
        scrollable: find
            .descendant(
              of: find.byType(CourseEditorScreen),
              matching: find.byType(Scrollable),
            )
            .first,
        maxScrolls: 20,
      );
      await tester.pumpAndSettle();
      await tester.tap(tile);
      await tester.pumpAndSettle();
    }

    testWidgets('lists the narrator and the characters', (tester) async {
      _bigWindow(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: CourseEditorScreen(course: _course(), userCourse: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Story characters'), findsOneWidget);
      expect(find.byKey(const Key('story-narrator')), findsNothing);
      await expand(tester);
      expect(find.byKey(const Key('story-narrator')), findsOneWidget);
      expect(find.text('Narrator: Narrator'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('story-character-character_anna')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('story-character-character_bob')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('story-character-add')), findsOneWidget);
    });

    testWidgets(
      'a character that lines still name is not removed; an unused one is',
      (tester) async {
        _bigWindow(tester);
        await tester.pumpWidget(
          MaterialApp(
            home: CourseEditorScreen(course: _course(), userCourse: true),
          ),
        );
        await tester.pumpAndSettle();
        await expand(tester);
        await tester.tap(
          find.byKey(const ValueKey('story-character-remove-character_anna')),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('story-character-in-use')), findsOneWidget);
        expect(
          find.textContaining('1 Dialogue line of this Course'),
          findsOneWidget,
        );
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('story-character-character_anna')),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(const ValueKey('story-character-remove-character_bob')),
        );
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('story-character-character_bob')),
          findsNothing,
        );
        expect(find.textContaining('1 character'), findsOneWidget);
      },
    );

    testWidgets('Add character needs a name and takes a bundled avatar', (
      tester,
    ) async {
      _bigWindow(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: CourseEditorScreen(course: _course(), userCourse: true),
        ),
      );
      await tester.pumpAndSettle();
      await expand(tester);
      await tester.tap(find.byKey(const Key('story-character-add')));
      await tester.pumpAndSettle();
      expect(find.text('New character'), findsOneWidget);
      FilledButton save() => tester.widget<FilledButton>(
        find.byKey(const Key('story-speaker-save')),
      );
      expect(save().onPressed, isNull);
      await tester.enterText(
        find.byKey(const Key('story-speaker-name')),
        'Carla',
      );
      await tester.pumpAndSettle();
      expect(save().onPressed, isNotNull);
      await tester.tap(find.byKey(const ValueKey('story-avatar-dog')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('story-speaker-save')));
      await tester.pumpAndSettle();
      expect(find.text('New character'), findsNothing);
      expect(find.widgetWithText(ListTile, 'Carla'), findsOneWidget);
      expect(find.textContaining('3 characters'), findsOneWidget);
    });

    testWidgets('the narrator is renamed through the same dialog', (
      tester,
    ) async {
      _bigWindow(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: CourseEditorScreen(course: _course(), userCourse: true),
        ),
      );
      await tester.pumpAndSettle();
      await expand(tester);
      await tester.tap(find.byKey(const Key('story-narrator')));
      await tester.pumpAndSettle();
      expect(find.text('Narrator'), findsWidgets);
      await tester.enterText(
        find.byKey(const Key('story-speaker-name')),
        'The storyteller',
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('story-speaker-save')));
      await tester.pumpAndSettle();
      expect(find.text('Narrator: The storyteller'), findsOneWidget);
    });
  });
}
