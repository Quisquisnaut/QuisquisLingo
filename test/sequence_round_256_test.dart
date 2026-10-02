import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/duel_eligibility_service.dart';
import 'package:quisquislingo_app/services/exercise_draft_builder.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/round_flow_authoring.dart';
import 'package:quisquislingo_app/services/tts_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 256 Revision 7, third follow-up (owner decisions, 29 September
/// 2026): a Round made with New Round and played as a sequence is a plain
/// Round played in order, not a Story. A Story is what New Story makes (the
/// `story` visual type). A sequence has an optional title, the plain
/// Round's buttons, the label "Sequence: <title>" (else the Round's name)
/// in every list, the learner's path and the Round screen, the Audit's
/// Round rules, and its exercises join the Duel; playback stays ordered,
/// without a mistake review.
const _profileId = '12345678-1234-4234-9234-123456789abc';
final _stamp = DateTime.utc(2026, 9, 29, 9);

Exercise _blank(String id) => Exercise.canonical(
  id: id,
  publicationState: PublicationState.draft,
  primitive: ExercisePrimitive.presentation,
  canonicalEvaluation: CanonicalEvaluation.none,
  updatedAt: _stamp,
);

Exercise _line(String id, String text) => ExerciseDraftBuilder.build(
  ExerciseDraftValues(
    original: _blank(id),
    type: 'dialogue_line',
    publicationState: PublicationState.published,
    prompt: text,
  ),
).candidate!;

Exercise _select(String id, String question) => Exercise.canonical(
  id: id,
  primitive: ExercisePrimitive.select,
  promptElements: [PromptElement(type: 'text', text: question)],
  items: [
    ExerciseItem(
      id: '${id}_a',
      content: [PromptElement(type: 'text', text: 'Right $id')],
    ),
    ExerciseItem(
      id: '${id}_b',
      content: [PromptElement(type: 'text', text: 'Wrong $id')],
    ),
  ],
  canonicalEvaluation: CanonicalEvaluation(
    mode: EvaluationMode.exactItem,
    correctItemIds: ['${id}_a'],
  ),
  updatedAt: _stamp,
);

LearningRound _round(
  String id,
  List<Exercise> exercises, {
  String title = 'Numbers',
  String visualType = 'generic',
  ContentFlow? Function(List<LearningContent>)? flow,
}) {
  final content = [
    for (final exercise in exercises) LearningContent.fromExercise(exercise),
  ];
  return LearningRound(
    id: id,
    title: title,
    updatedAt: _stamp,
    visualType: visualType,
    content: content,
    flow: flow?.call(content),
  );
}

Course _course(List<LearningRound> rounds) => Course(
  courseId: 'sequence_round_256',
  originalCourseCreator: CourseProvenanceIdentity.qqlUser(
    profileId: _profileId,
    displayName: 'Original Course Creator',
  ),
  maintainer: const CourseMaintainer(_profileId),
  title: 'Sequence course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  lessons: [
    Lesson(
      lessonId: 'lesson_one',
      title: 'Lesson one',
      updatedAt: _stamp,
      rounds: rounds,
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

Future<void> _until(WidgetTester tester, Finder finder) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  for (var attempt = 0; ; attempt++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(
      attempt < 100 ? const Duration(milliseconds: 25) : Duration.zero,
    );
    if (finder.evaluate().isNotEmpty) return;
    if (DateTime.now().isAfter(deadline)) break;
  }
  fail('Timed out waiting for $finder');
}

class _Speech extends TtsCacheService {
  @override
  Future<bool> speak({
    required String text,
    required String language,
    String? learningLanguage,
    String? targetLanguage,
    double rate = 0.5,
    bool applyLearnerSettings = true,
    String? voicePreference,
  }) async => true;

  @override
  Future<void> stop() async {}
}

void _platforms() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (_) async => testSupportDirectory.path,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers.global'),
    (_) async => null,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers'),
    (_) async => null,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      ProfileService.profilesKey: [
        const LearnerProfile(
          learnerProfileId: _profileId,
          displayName: 'Sequence author',
        ).encode(),
      ],
      ProfileService.activeProfileIdKey: _profileId,
      'sound_effects_enabled': false,
    });
    keepCrashLogUnavailable();
    _platforms();
  });

  test('a flow makes a Story only with the story visual type', () {
    final exercises = [_select('q1', 'One?')];
    final practice = _round('practice', exercises);
    final sequence = _round(
      'sequence',
      exercises,
      flow: RoundFlowAuthoring.linearFor,
    );
    final story = _round(
      'story',
      exercises,
      visualType: LearningRound.storyVisualType,
      flow: (content) => RoundFlowAuthoring.linearFor(content, title: 'Bar'),
    );
    expect((practice.isStory, practice.isSequence), (false, false));
    expect((sequence.isStory, sequence.isSequence), (false, true));
    expect((story.isStory, story.isSequence), (true, false));
    expect(practice.displayTitle(0), 'Numbers');
    expect(sequence.displayTitle(0), 'Sequence: Numbers');
    expect(story.displayTitle(0), 'Story: Bar');
    expect(
      _round(
        'untitled',
        exercises,
        title: '',
        flow: RoundFlowAuthoring.linearFor,
      ).displayTitle(3),
      'Sequence: Round 4',
    );
  });

  group('Round editor', () {
    testWidgets(
      'Play as a sequence on a New Round: optional title, plain Round buttons, Sequence label',
      (tester) async {
        _bigWindow(tester);
        final course = _course([
          _round('round_one', [_select('q1', 'One?'), _select('q2', 'Two?')]),
        ]);
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
        await _tap(tester, find.byKey(const Key('round-story-switch')));

        // A plain Round played in order: one exercise per page, every
        // finished item kept when it scrolls, no title of its own yet.
        final flow = _roundOf(changed!).flow!;
        expect(flow.presentation, FlowPresentation.step);
        expect(flow.log, FlowLog.all);
        expect(flow.readAloud, FlowReadAloud.automatic);
        expect(flow.title, isEmpty);
        expect(_roundOf(changed!).isSequence, isTrue);
        expect(_roundOf(changed!).displayTitle(0), 'Sequence: Numbers');
        expect(find.text('Sequence: Numbers'), findsOneWidget);

        expect(find.text('Optional sequence title'), findsOneWidget);
        expect(find.text('Story title'), findsNothing);
        expect(
          tester
              .widget<TextField>(find.byKey(const Key('round-story-title')))
              .controller!
              .text,
          isEmpty,
        );
        expect(find.textContaining('Needs the sequence\'s audio'), findsOne);
        expect(find.textContaining('Story'), findsNothing);
        expect(find.byKey(const Key('round-story-steps')), findsNothing);
        expect(find.byKey(const Key('round-add-step')), findsNothing);
        for (final key in ['new-exercise', 'exercise-creation-wizard']) {
          expect(find.byKey(Key(key)), findsOneWidget, reason: key);
        }

        await tester.enterText(
          find.byKey(const Key('round-story-title')),
          'Counting',
        );
        await tester.pumpAndSettle();
        expect(_roundOf(changed!).flow!.title, 'Counting');
        expect(_roundOf(changed!).title, 'Numbers');
        expect(_roundOf(changed!).displayTitle(0), 'Sequence: Counting');

        await _tap(tester, find.byKey(const ValueKey('exercise-actions-q1')));
        expect(find.text('Needs the sequence\'s audio'), findsOneWidget);
        final duplicate = tester.widget<PopupMenuItem<String>>(
          find.widgetWithText(PopupMenuItem<String>, 'Duplicate'),
        );
        expect(duplicate.enabled, isTrue);
        await tester.tapAt(const Offset(4, 4));
        await tester.pumpAndSettle();

        await _tap(tester, find.byKey(const Key('round-story-switch')));
        expect(_roundOf(changed!).flow, isNull);
        expect(_roundOf(changed!).displayTitle(0), 'Numbers');
      },
    );

    testWidgets('a Story keeps its Story options and Add Step', (tester) async {
      _bigWindow(tester);
      final course = _course([
        _round('round_one', [
          _line('l1', 'Ciao.'),
          _select('q1', 'One?'),
        ], visualType: LearningRound.storyVisualType),
      ]);
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
      await _tap(tester, find.byKey(const Key('round-story-switch')));
      expect(_roundOf(changed!).isStory, isTrue);
      expect(_roundOf(changed!).flow!.presentation, FlowPresentation.scroll);
      expect(_roundOf(changed!).displayTitle(0), 'Story: Numbers');
      expect(find.text('Story title'), findsOneWidget);
      expect(find.byKey(const Key('round-story-steps')), findsOneWidget);
      expect(find.byKey(const Key('round-add-step')), findsOneWidget);
      expect(find.byKey(const Key('new-exercise')), findsNothing);
    });
  });

  test('the Audit gives a sequence the Round rules', () {
    LearningRound sequence(String id, List<Exercise> exercises) =>
        _round(id, exercises, flow: RoundFlowAuthoring.linearFor);
    final course = _course([
      sequence('plain_sequence', [_select('q1', 'One?')]),
      sequence('sequence_with_line', [_line('l1', 'Ciao.')]),
      _round(
        'untitled_story',
        [_select('q2', 'Two?')],
        visualType: LearningRound.storyVisualType,
        flow: RoundFlowAuthoring.linearFor,
      ),
    ]);
    final issues = CourseAuditService().auditCourse(course).issues;
    Set<String> codes(String roundId) => {
      for (final issue in issues)
        if (issue.roundId == roundId) issue.code,
    };
    for (final id in ['plain_sequence', 'sequence_with_line']) {
      expect(codes(id), isNot(contains('STORY_TITLE_MISSING')), reason: id);
      expect(codes(id), isNot(contains('STORY_WITHOUT_DIALOGUE')), reason: id);
    }
    expect(
      codes('sequence_with_line'),
      contains('DIALOGUE_LINE_OUTSIDE_STORY'),
    );
    expect(
      codes('untitled_story'),
      containsAll(['STORY_TITLE_MISSING', 'STORY_WITHOUT_DIALOGUE']),
    );
    expect(
      issues
          .where((issue) => issue.roundId == 'plain_sequence')
          .every((issue) => issue.location.contains('Sequence: Numbers')),
      isTrue,
    );
  });

  test('a sequence\'s exercises join the Duel pool; a Story\'s do not', () {
    final lesson = Lesson(
      lessonId: 'lesson',
      title: 'Lesson',
      rounds: [
        _round('sequence', [
          _select('s1', 'One?'),
          _select('s2', 'Two?'),
        ], flow: RoundFlowAuthoring.linearFor),
        _round(
          'story',
          [_select('t1', 'Three?')],
          visualType: LearningRound.storyVisualType,
          flow: RoundFlowAuthoring.linearFor,
        ),
        _round('practice', [_select('p1', 'Four?')]),
      ],
    );
    final result = const DuelEligibilityService().evaluate(lesson);
    expect(result.candidates.map((c) => c.exercise.id), ['s1', 's2', 'p1']);
  });

  testWidgets('the Round screen calls a sequence a Sequence', (tester) async {
    _bigWindow(tester);
    final round = _round(
      'sequence',
      [_select('e1', 'Question 1'), _select('e2', 'Question 2')],
      flow: (content) => RoundFlowAuthoring.linearFor(
        content,
        presentation: FlowPresentation.scroll,
      ),
    );
    final course = _course([round]);
    await tester.pumpWidget(
      MaterialApp(
        home: RoundScreen(
          course: course,
          lesson: course.lessons.single,
          round: round,
          ttsLanguage: course.ttsLanguage,
          roundIndex: 0,
          previewMode: true,
          ttsCacheService: _Speech(),
        ),
      ),
    );
    await _until(tester, find.text('Question 1'));
    expect(find.text('Sequence: Numbers'), findsOneWidget);
    expect(find.text('Sequence · 2 steps'), findsOneWidget);
    // In order, without a mistake review: a wrong answer moves on.
    await _tap(tester, find.widgetWithText(FilledButton, 'Wrong e1'));
    await _tap(tester, find.widgetWithText(FilledButton, 'Continue'));
    await _tap(tester, find.widgetWithText(FilledButton, 'Right e2'));
    expect(find.widgetWithText(FilledButton, 'Finish sequence'), findsOne);
    expect(find.textContaining('Story'), findsNothing);
  });
}
