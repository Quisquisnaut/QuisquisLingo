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

/// Build 256 Revision 5, third follow-up: in a Story the Round editor offers
/// Add step instead of New exercise, New canonical and Exercise Wizard. The
/// title block is offered once and goes first, a Dialogue line comes from
/// the short form New Story uses, an exercise from the Story presets;
/// Duplicate is greyed out for the title block; the Story options count the
/// steps and no longer say that lines are never skipped.
const _profileId = '12345678-1234-4234-9234-123456789abc';
final _stamp = DateTime.utc(2026, 9, 28, 21);

Exercise _blank(String id) => Exercise.canonical(
  id: id,
  publicationState: PublicationState.draft,
  primitive: ExercisePrimitive.presentation,
  canonicalEvaluation: CanonicalEvaluation.none,
  updatedAt: _stamp,
);

Exercise _cover(String id, String titleLine) => ExerciseDraftBuilder.build(
  ExerciseDraftValues(
    original: _blank(id),
    type: 'story_cover',
    publicationState: PublicationState.published,
    prompt: titleLine,
  ),
).candidate!;

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

List<Exercise> _full() => [
  _cover('c1', 'Una mattina'),
  _line('n1', 'Anna walks into the café.'),
  _line('a1', 'Un caffè, per favore.', speakerId: 'character_anna'),
  _select('q1', 'What did Anna order?'),
];

LearningRound _round(List<Exercise> exercises, {bool story = true}) {
  final content = [
    for (final exercise in exercises) LearningContent.fromExercise(exercise),
  ];
  return LearningRound(
    id: 'round_one',
    title: 'Al bar',
    updatedAt: _stamp,
    content: content,
    flow: story
        ? RoundFlowAuthoring.linearFor(
            content,
            presentation: FlowPresentation.scroll,
            title: 'Al bar',
            log: FlowLog.dialogue,
            readAloud: FlowReadAloud.automatic,
          )
        : null,
  );
}

Course _course(LearningRound round) => Course(
  courseId: 'story_add_step_256',
  originalCourseCreator: CourseProvenanceIdentity.qqlUser(
    profileId: _profileId,
    displayName: 'Original Course Creator',
  ),
  maintainer: const CourseMaintainer(_profileId),
  title: 'Add step course',
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
  ],
  lessons: [
    Lesson(
      lessonId: 'lesson_one',
      title: 'Lesson one',
      updatedAt: _stamp,
      rounds: [round],
    ),
  ],
);

LearningRound _roundOf(Course course) => course.lessons.first.rounds.first;

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

Future<void> _pumpEditor(
  WidgetTester tester,
  Course course, {
  ValueChanged<Course>? onChanged,
}) async {
  // A fresh editor each time: the same widget type at the same place would
  // keep the previous State (and its flow).
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    MaterialApp(
      home: RoundEditorScreen(
        course: course,
        lesson: course.lessons.first,
        round: _roundOf(course),
        roundIndex: 0,
        onCourseChanged: onChanged,
        clock: () => _stamp,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _steps(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('round-story-steps'))).data!;

ListTile _titleChoice(WidgetTester tester) => tester.widget<ListTile>(
  find.descendant(
    of: find.byKey(const Key('story-step-title')),
    matching: find.byType(ListTile),
  ),
);

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

  testWidgets('a Story offers Add step instead of the three exercise buttons', (
    tester,
  ) async {
    _bigWindow(tester);
    await _pumpEditor(tester, _course(_round(_full())));
    expect(find.byKey(const Key('round-add-step')), findsOneWidget);
    expect(find.byKey(const Key('new-exercise')), findsNothing);
    expect(find.byKey(const Key('new-canonical-exercise')), findsNothing);
    expect(find.byKey(const Key('exercise-creation-wizard')), findsNothing);
    expect(find.textContaining('Lines are never skipped'), findsNothing);
    expect(find.textContaining('Needs the Story\'s audio'), findsOneWidget);
    expect(
      _steps(tester),
      'Title block: 1 · Dialogue lines: 2 · Exercises: 1.',
    );

    // A practice Round keeps the three buttons and has no steps.
    await _pumpEditor(tester, _course(_round(_full(), story: false)));
    expect(find.byKey(const Key('round-add-step')), findsNothing);
    expect(find.byKey(const Key('new-exercise')), findsOneWidget);
    expect(find.byKey(const Key('new-canonical-exercise')), findsOneWidget);
    expect(find.byKey(const Key('exercise-creation-wizard')), findsOneWidget);
    expect(find.byKey(const Key('round-story-steps')), findsNothing);
  });

  testWidgets(
    'the title block is offered once; a line is added at the end through the short form',
    (tester) async {
      _bigWindow(tester);
      Course? changed;
      await _pumpEditor(
        tester,
        _course(_round(_full())),
        onChanged: (course) => changed = course,
      );
      await _tap(tester, find.byKey(const Key('round-add-step')));
      expect(find.text('Add a step to the Story'), findsOneWidget);
      expect(_titleChoice(tester).enabled, isFalse);
      await _tap(tester, find.byKey(const Key('story-step-line')));
      expect(find.text('Add line'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('story-line-text')), 'Ciao!');
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const Key('story-line-save')));

      final round = _roundOf(changed!);
      expect(round.exercises, hasLength(5));
      final added = round.exercises.last;
      expect(ExerciseFeatures(added).kind, LearnerExerciseKind.dialogueLine);
      expect(ExerciseFeatures(added).lineText, 'Ciao!');
      expect(added.publicationState, PublicationState.published);
      expect(round.flow!.isLinear, isTrue);
      expect(round.displayTitle(0), 'Story: Al bar');
      expect(
        _steps(tester),
        'Title block: 1 · Dialogue lines: 3 · Exercises: 1.',
      );
    },
  );

  testWidgets(
    'a Story without a title block gets one first through the cover form',
    (tester) async {
      _bigWindow(tester);
      Course? changed;
      await _pumpEditor(
        tester,
        _course(
          _round([
            _line('n1', 'Anna walks into the café.'),
            _select('q1', 'What did Anna order?'),
          ]),
        ),
        onChanged: (course) => changed = course,
      );
      expect(
        _steps(tester),
        'No title block yet: add it with Add step · Dialogue lines: 1 · Exercises: 1.',
      );
      await _tap(tester, find.byKey(const Key('round-add-step')));
      expect(_titleChoice(tester).enabled, isTrue);
      await _tap(tester, find.byKey(const Key('story-step-title')));
      expect(find.byType(ExerciseEditorScreen), findsOneWidget);
      expect(find.text('New title block'), findsOneWidget);
      await tester.enterText(
        find.byKey(const ValueKey('exercise-field-prompt')),
        'Una mattina a Torino',
      );
      await tester.pumpAndSettle();
      await _tap(tester, find.byKey(const Key('exercise-save')));
      expect(find.byType(ExerciseEditorScreen), findsNothing);

      final round = _roundOf(changed!);
      expect(round.exercises, hasLength(3));
      final cover = round.exercises.first;
      expect(ExerciseFeatures(cover).kind, LearnerExerciseKind.storyCover);
      expect(ExerciseFeatures(cover).coverTitle, 'Una mattina a Torino');
      expect(round.exercises[1].id, 'n1');
      expect(
        _steps(tester),
        'Title block: 1 · Dialogue lines: 1 · Exercises: 1.',
      );

      // Offered once.
      await _tap(tester, find.byKey(const Key('round-add-step')));
      expect(_titleChoice(tester).enabled, isFalse);
    },
  );

  testWidgets('Add step offers the Story presets for an exercise', (
    tester,
  ) async {
    _bigWindow(tester);
    Course? changed;
    await _pumpEditor(
      tester,
      _course(_round(_full())),
      onChanged: (course) => changed = course,
    );
    await _tap(tester, find.byKey(const Key('round-add-step')));
    await _tap(tester, find.byKey(const Key('story-step-exercise')));
    expect(find.text('Add an exercise to the Story'), findsOneWidget);
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

    final round = _roundOf(changed!);
    expect(round.exercises, hasLength(5));
    expect(round.exercises.last.editorTemplate, 'choice_target');
    expect(round.exercises.last.publicationState, PublicationState.draft);
    expect(
      _steps(tester),
      'Title block: 1 · Dialogue lines: 2 · Exercises: 2.',
    );
  });

  testWidgets('Duplicate is greyed out for the title block only', (
    tester,
  ) async {
    _bigWindow(tester);
    await _pumpEditor(tester, _course(_round(_full())));
    PopupMenuItem<String> duplicate() => tester.widget<PopupMenuItem<String>>(
      find.widgetWithText(PopupMenuItem<String>, 'Duplicate'),
    );
    await _tap(tester, find.byKey(const ValueKey('exercise-actions-c1')));
    expect(duplicate().enabled, isFalse);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    await _tap(tester, find.byKey(const ValueKey('exercise-actions-n1')));
    expect(duplicate().enabled, isTrue);
  });
}
