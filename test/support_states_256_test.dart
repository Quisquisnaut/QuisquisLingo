import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/round_screen.dart';
import 'package:quisquislingo_app/services/canonical_exercise_draft.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/course_library_operations.dart';
import 'package:quisquislingo_app/services/duel_eligibility_service.dart';
import 'package:quisquislingo_app/services/exercise_draft_builder.dart';
import 'package:quisquislingo_app/services/profile_service.dart';
import 'package:quisquislingo_app/services/progress_service.dart';
import 'package:quisquislingo_app/services/round_flow_authoring.dart';
import 'package:quisquislingo_app/services/round_playability_service.dart';
import 'package:quisquislingo_app/services/tts_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_directories.dart';

/// Build 256 Revision 6 (plan A.6): the support states at runtime. An
/// exercise this version cannot play is computed, never stored; a practice
/// Round skips it before the audio filter, counts it in the completion
/// dialog and withholds the Laurel; a Story shows a card in its place and
/// ends unrecorded when it is the last step; the Duel never asks it; the
/// Audit reports it as information and warns when a Round or Story cannot
/// be completed; the import review counts it.
final _stamp = DateTime.utc(2026, 9, 28, 22);

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

Exercise _select(
  String id,
  String question, {
  Map<OptionKey, OptionValue> options = const {},
}) => Exercise.canonical(
  id: id,
  primitive: ExercisePrimitive.select,
  options: PrimitiveOptions(options),
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

/// A legal Select this version cannot play: one choice checked only on
/// completion (the runtime table plays a single choice checked at once).
Exercise _laterSelect(String id, String question) => _select(
  id,
  question,
  options: {
    OptionKey.evaluationTiming: const EnumOptionValue(
      EvaluationTiming.onCompletion,
    ),
  },
);

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
    lineMode: 'text',
  ),
).candidate!;

Exercise _cover(String id) => ExerciseDraftBuilder.build(
  ExerciseDraftValues(
    original: _blank(id),
    type: 'story_cover',
    publicationState: PublicationState.published,
    prompt: 'A morning in Turin',
  ),
).candidate!;

LearningRound _round(
  List<Exercise> exercises, {
  bool story = false,
  ContentFlow? flow,
  String id = 'round_one',
}) {
  final content = [
    for (final exercise in exercises) LearningContent.fromExercise(exercise),
  ];
  return LearningRound(
    id: id,
    title: 'Al bar',
    updatedAt: _stamp,
    content: content,
    flow:
        flow ??
        (story
            ? RoundFlowAuthoring.linearFor(
                content,
                presentation: FlowPresentation.scroll,
                title: 'Al bar',
                log: FlowLog.all,
                readAloud: FlowReadAloud.manual,
              )
            : null),
  );
}

Course _course(LearningRound round) => Course(
  courseId: 'support-states-course',
  title: 'Support states course',
  learningLanguage: 'Italian',
  interfaceLanguage: 'English',
  sourceLanguage: 'English',
  targetLanguage: 'Italian',
  ttsLanguage: 'it-IT',
  storyNarrator: const StorySpeaker(
    name: 'Narrator',
    language: TextLanguage.source,
  ),
  lessons: [
    Lesson(lessonId: 'lesson', title: 'Lesson', rounds: [round]),
  ],
);

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
    (call) async {
      if (call.method == 'create') {
        final arguments = call.arguments as Map<Object?, Object?>;
        messenger.setMockMessageHandler(
          'xyz.luan/audioplayers/events/${arguments['playerId']}',
          (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null),
        );
      }
      return null;
    },
  );
  messenger.setMockMessageHandler(
    'xyz.luan/audioplayers.global/events',
    (_) async => const StandardMethodCodec().encodeSuccessEnvelope(null),
  );
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

Future<void> _tap(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<Course> _pump(
  WidgetTester tester,
  LearningRound round, {
  bool preview = false,
}) async {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final course = _course(round);
  await tester.pumpWidget(
    MaterialApp(
      home: RoundScreen(
        course: course,
        lesson: course.lessons.single,
        round: round,
        ttsLanguage: course.ttsLanguage,
        roundIndex: 0,
        previewMode: preview,
        ttsCacheService: _Speech(),
      ),
    ),
  );
  return course;
}

void main() {
  group('support states', () {
    test('runtime support is computed from the registry, never stored', () {
      expect(
        _select('q1', 'Q').runtimeSupport.state,
        ExerciseSupportState.executable,
      );
      expect(_select('q1', 'Q').isExecutable, isTrue);
      final later = _laterSelect('q2', 'Q');
      expect(
        later.runtimeSupport.state,
        ExerciseSupportState.readableButNotExecutable,
      );
      expect(later.isExecutable, isFalse);
      expect(later.runtimeSupport.reason, contains('cannot play'));
      expect(later.toJson().containsKey('runtimeSupport'), isFalse);
      // A blank Speak is legal (its required options filled) and waits for
      // a later version.
      final speak = CanonicalExerciseDraft.blankExercise(
        ExercisePrimitive.speak,
        id: 'sp',
        updatedAt: _stamp,
      );
      expect(
        speak.runtimeSupport.state,
        ExerciseSupportState.readableButNotExecutable,
      );
      // An illegal pairing is invalid, not "not executable".
      final invalid = Exercise.canonical(
        id: 'bad',
        primitive: ExercisePrimitive.select,
        canonicalEvaluation: const CanonicalEvaluation(
          mode: EvaluationMode.exactText,
        ),
        updatedAt: _stamp,
      );
      expect(invalid.runtimeSupport.state, ExerciseSupportState.invalid);
    });

    test('the playability service drops what this version cannot play', () {
      final service = RoundPlayabilityService();
      final round = _round([_select('q1', 'Q1'), _laterSelect('q2', 'Q2')]);
      expect(service.playableExerciseIndices(round), [0]);
      expect(service.playableExerciseIndices(round, keepNotExecutable: true), [
        0,
        1,
      ]);
      expect(service.notExecutableIndices(round), [1]);
      final onlyLater = _round([_laterSelect('q2', 'Q2')], id: 'later');
      expect(service.playableExerciseIndices(onlyLater), isEmpty);
      expect(
        service.laurelEligibleRoundIds(_course(onlyLater)),
        isEmpty,
        reason: 'no scored exercise this version plays',
      );
      expect(service.laurelEligibleRoundIds(_course(round)), {'round_one'});
    });

    test('the Duel never asks an exercise this version cannot play', () {
      expect(DuelEligibilityService.isEligible(_select('q1', 'Q')), isTrue);
      expect(
        DuelEligibilityService.isEligible(_laterSelect('q2', 'Q')),
        isFalse,
      );
    });

    test('the Audit reports it as information, nothing blocks', () {
      final issues = CourseAuditService().auditExercise(
        _laterSelect('q2', 'Q'),
      );
      expect(
        issues.where((issue) => issue.severity == AuditSeverity.error),
        isEmpty,
      );
      final info = issues.where(
        (issue) => issue.code == 'EXERCISE_NOT_EXECUTABLE',
      );
      expect(info, hasLength(1));
      expect(info.single.severity, AuditSeverity.info);
      expect(info.single.message, contains('cannot play'));
      expect(
        CourseAuditService()
            .auditExercise(_select('q1', 'Q'))
            .where((issue) => issue.code == 'EXERCISE_NOT_EXECUTABLE'),
        isEmpty,
      );
    });

    test('the Audit warns when learners cannot complete a Round or Story', () {
      String? reason(LearningRound round) =>
          CourseAuditService.notCompletableReason(round);
      Iterable<CourseAuditIssue> warnings(LearningRound round) =>
          CourseAuditService()
              .auditCourse(_course(round))
              .issues
              .where((issue) => issue.code == 'ROUND_NOT_COMPLETABLE');

      // A practice Round with something to play: no warning.
      final mixed = _round([_select('q1', 'Q1'), _laterSelect('q2', 'Q2')]);
      expect(reason(mixed), isNull);
      expect(warnings(mixed), isEmpty);

      // Every exercise waits for a later version.
      final later = _round([_laterSelect('q2', 'Q2')]);
      expect(reason(later), contains('cannot complete'));
      final issue = warnings(later).single;
      expect(issue.severity, AuditSeverity.warning);
      expect(issue.roundId, 'round_one');

      // A Story with the unplayable step in the middle plays on; one that
      // ends on it ends unrecorded.
      final middle = _round([
        _cover('c1'),
        _line('n1', 'Anna walks into the café.'),
        _laterSelect('q2', 'Q2'),
        _select('q1', 'Q1'),
      ], story: true);
      expect(reason(middle), isNull);
      final ending = _round([
        _cover('c1'),
        _line('n1', 'Anna walks into the café.'),
        _laterSelect('q2', 'Q2'),
      ], story: true);
      expect(reason(ending), contains('ends on a step'));
      expect(warnings(ending), hasLength(1));

      // A branching flow cannot start in this version (plan A.7).
      final branching = _round(
        [_select('q1', 'Q1'), _select('q2', 'Q2'), _select('q3', 'Q3')],
        flow: ContentFlow(
          startNodeId: 'n1',
          nodes: const [
            FlowNode(
              id: 'n1',
              kind: FlowNodeKind.exercise,
              contentId: 'q1',
              transitions: [
                FlowTransition(
                  trigger: FlowTrigger.onCorrect,
                  targetNodeId: 'n2',
                ),
                FlowTransition.next('n3'),
              ],
            ),
            FlowNode(id: 'n2', kind: FlowNodeKind.exercise, contentId: 'q2'),
            FlowNode(id: 'n3', kind: FlowNodeKind.exercise, contentId: 'q3'),
          ],
        ),
      );
      expect(reason(branching), contains('branches'));
      expect(warnings(branching), hasLength(1));
    });

    test('the import report counts them', () {
      final course = _course(_round([_select('q1', 'Q1')]));
      expect(
        CourseLibraryReports.imported(course, 0),
        'Imported “Support states course”.',
      );
      expect(
        CourseLibraryReports.imported(course, 1, notExecutable: 2),
        'Imported “Support states course” with 1 Course Audit warning. Review Course Audit. 2 exercises cannot be played by this version of QuisquisLingo and are kept unchanged.',
      );
      expect(
        CourseLibraryReports.notExecutableNote(1),
        ' 1 exercise cannot be played by this version of QuisquisLingo and is kept unchanged.',
      );
      expect(CourseLibraryReports.notExecutableNote(0), '');
    });
  });

  group('the Round screen', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
      await ProfileService().addProfile('Support learner');
      _platforms();
      keepCrashLogUnavailable();
    });

    testWidgets(
      'a practice Round skips the exercise, counts it and withholds the Laurel',
      (tester) async {
        final round = _round([_select('q1', 'Q1'), _laterSelect('q2', 'Q2')]);
        final course = await _pump(tester, round);
        await _until(tester, find.text('Right q1'));
        expect(find.text('Q2'), findsNothing);
        await _tap(tester, find.widgetWithText(FilledButton, 'Right q1'));
        await _tap(tester, find.widgetWithText(FilledButton, 'Finish round'));
        await _until(
          tester,
          find.byKey(const Key('round-completed-version-skipped')),
        );
        expect(
          find.text(
            '1 exercise this version of QuisquisLingo cannot play were skipped.',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('Correct answers: 1/1'), findsOneWidget);
        final progress = ProgressService();
        expect(
          await progress.getCompletedRounds(courseId: course.courseId),
          contains('round_one'),
        );
        expect(
          await progress.getPerfectRounds(courseId: course.courseId),
          isEmpty,
          reason: 'something was skipped',
        );
        expect(
          await progress.getTtsSkippedPerfectRounds(courseId: course.courseId),
          contains('round_one'),
        );
      },
    );

    testWidgets('a Round of such exercises alone says why it is empty', (
      tester,
    ) async {
      await _pump(tester, _round([_laterSelect('q2', 'Q2')]));
      await _until(
        tester,
        find.text(
          'This version of QuisquisLingo cannot play the exercises of this round yet.',
        ),
      );
      expect(
        find.text(
          'They are kept in the Course unchanged; a later version of QuisquisLingo will play them.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('a Story shows a card in its place and plays on', (
      tester,
    ) async {
      final round = _round([
        _cover('c1'),
        _line('n1', 'Anna walks into the café.'),
        _laterSelect('q2', 'Q2'),
        _select('q1', 'Q1'),
      ], story: true);
      await _pump(tester, round);
      await _until(tester, find.byKey(const Key('story-cover-continue')));
      await _tap(tester, find.byKey(const Key('story-cover-continue')));
      await _until(tester, find.byKey(const Key('story-line-continue')));
      await _tap(tester, find.byKey(const Key('story-line-continue')));

      // The card: the prompt read-only, one sentence, no heading, no
      // instruction, no answer buttons.
      await _until(tester, find.byKey(const Key('not-executable-card')));
      expect(find.text('Q2'), findsOneWidget);
      expect(find.text('Not playable in this version'), findsOneWidget);
      expect(find.byKey(const Key('exercise-heading')), findsNothing);
      expect(find.byKey(const Key('exercise-instruction')), findsNothing);
      expect(find.text('Right q2'), findsNothing);
      await _tap(tester, find.byKey(const Key('not-executable-continue')));
      expect(find.text('Not playable in this version.'), findsOneWidget);
      // The card's own Continue is spent; the bottom bar's moves on.
      await tester.tap(find.widgetWithText(FilledButton, 'Continue').last);
      await tester.pumpAndSettle();

      // The next step plays as usual and the Story completes; the log
      // (Everything) kept the card.
      await _until(tester, find.text('Right q1'));
      expect(find.text('Not playable in this version'), findsOneWidget);
      await _tap(tester, find.widgetWithText(FilledButton, 'Right q1'));
      await _tap(tester, find.widgetWithText(FilledButton, 'Finish story'));
      await _until(
        tester,
        find.byKey(const Key('round-completed-version-skipped')),
      );
      expect(
        find.text(
          '1 exercise this version of QuisquisLingo cannot play appeared as cards.',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('Correct answers: 1/1'), findsOneWidget);
    });

    testWidgets('a Story ending on such a step ends unrecorded', (
      tester,
    ) async {
      final round = _round([
        _cover('c1'),
        _line('n1', 'Anna walks into the café.'),
        _laterSelect('q2', 'Q2'),
      ], story: true);
      final course = await _pump(tester, round);
      await _until(tester, find.byKey(const Key('story-cover-continue')));
      await _tap(tester, find.byKey(const Key('story-cover-continue')));
      await _until(tester, find.byKey(const Key('story-line-continue')));
      await _tap(tester, find.byKey(const Key('story-line-continue')));
      await _until(tester, find.byKey(const Key('not-executable-card')));
      await _tap(tester, find.byKey(const Key('not-executable-continue')));
      await _tap(tester, find.widgetWithText(FilledButton, 'Leave story'));
      await _until(tester, find.byKey(const Key('story-ends-unplayable')));
      await _tap(tester, find.widgetWithText(FilledButton, 'OK'));
      expect(find.byType(RoundScreen), findsNothing);
      expect(
        await ProgressService().getCompletedRounds(courseId: course.courseId),
        isEmpty,
      );
    });

    testWidgets('the editor Preview shows the card in a practice Round too', (
      tester,
    ) async {
      final round = _round([_laterSelect('q2', 'Q2'), _select('q1', 'Q1')]);
      await _pump(tester, round, preview: true);
      await _until(tester, find.byType(FilledButton));
      // Both are in the Preview; the card comes with its own Continue.
      final card = find.byKey(const Key('not-executable-card'));
      if (card.evaluate().isEmpty) {
        await _tap(tester, find.widgetWithText(FilledButton, 'Right q1'));
        await _tap(tester, find.widgetWithText(FilledButton, 'Continue'));
        await _until(tester, card);
      }
      expect(card, findsOneWidget);
    });
  });
}
