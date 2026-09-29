import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/screens/course_editor_screen.dart';
import 'package:quisquislingo_app/services/authoring_duplication_service.dart';
import 'package:quisquislingo_app/services/canonical_exercise_draft.dart';
import 'package:quisquislingo_app/services/course_authoring_transfer_service.dart';
import 'package:quisquislingo_app/services/round_flow_authoring.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Build 256 Session 4: a Story (a Round with a flow) survives every
/// authoring rebuild. Before this, the Round editor, Move/Copy, rename,
/// GuideBook references and duplication rebuilt Rounds without `flow`, so
/// editing a Story silently made it a practice Round (plan A.7).
Exercise _select(String id, String question) {
  final draft = CanonicalExerciseDraft.blank(ExercisePrimitive.select, id: id);
  draft.prompt.add(PromptElement(type: 'text', text: question));
  draft.items.addAll([
    ExerciseItem(
      id: '${id}_item_0',
      content: const [PromptElement(type: 'text', text: 'sì')],
    ),
    ExerciseItem(
      id: '${id}_item_1',
      content: const [PromptElement(type: 'text', text: 'no')],
    ),
  ]);
  draft.evaluation = CanonicalEvaluation(
    mode: EvaluationMode.exactItem,
    correctItemIds: ['${id}_item_0'],
  );
  return draft.toExercise(
    publicationState: PublicationState.published,
    updatedAt: DateTime.utc(2026, 9, 27),
  );
}

List<LearningContent> _content(List<Exercise> exercises) => [
  for (final exercise in exercises) LearningContent.fromExercise(exercise),
];

Course _laboratory() => Course.fromJson(
  jsonDecode(
        File(
          'assets/courses/exercise_laboratory_en_it.json',
        ).readAsStringSync(),
      )
      as Map<String, dynamic>,
);

/// The Laboratory with its first Round turned into a linear Story, copied
/// as a custom Course (Copy as New Course gives every Round fresh IDs and
/// must carry the Story's flow across them; Move/Copy refuse official
/// Courses).
Course _laboratoryWithStory() {
  final json = _laboratory().toJson();
  final lessons = json['lessons'] as List;
  final lesson = lessons.first as Map<String, dynamic>;
  final rounds = lesson['rounds'] as List;
  final round = rounds.first as Map<String, dynamic>;
  final parsed = LearningRound.fromJson(round);
  round['flow'] = RoundFlowAuthoring.linearFor(parsed.content).toJson();
  final source = Course.fromJson(json);
  const profileId = '11111111-1111-4111-8111-111111111111';
  final copy =
      AuthoringDuplicationService(
        ids: _FixedIds(),
        clock: () => DateTime.utc(2026, 9, 27),
      ).forkOfficialCourse(
        source,
        provenance: CourseForkProvenance(
          sourceCourseId: source.courseId,
          sourceCourseTitle: source.title,
          sourceCourseVersion: source.officialCourseVersion,
          sourceOriginType: source.originType,
          sourcePublisherId: source.publisherId,
          sourcePublisherName: source.publisherName,
          sourceOfficialChecksum: source.officialChecksum,
          sourceAuthors: source.authors,
          forkCreatedByProfileId: profileId,
          forkCreatedByDisplayName: 'Story tester',
          forkCreatedAtUtc: '2026-09-27T00:00:00.000Z',
        ),
        maintainer: const CourseMaintainer(profileId),
      );
  final story = copy.lessons.first.rounds.first;
  if (story.flow?.linearNodeIds()?.join(',') !=
      story.content.map((content) => content.id).join(',')) {
    throw StateError('The licensed Fork did not carry the Story flow.');
  }
  return copy;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'sound_effects_enabled': false});
  });

  group('RoundFlowAuthoring', () {
    test('a linear flow follows the content order', () {
      final content = _content([_select('a', 'A?'), _select('b', 'B?')]);
      final flow = RoundFlowAuthoring.linearFor(content);
      expect(flow.isLinear, isTrue);
      expect(flow.linearNodeIds(), ['a', 'b']);
      expect(flow.nodes.map((node) => node.contentId), ['a', 'b']);
      expect(flow.nodes.map((node) => node.kind), [
        FlowNodeKind.exercise,
        FlowNodeKind.exercise,
      ]);
    });

    test('forContent keeps none, regenerates linear, keeps branching', () {
      final a = _select('a', 'A?');
      final b = _select('b', 'B?');
      final c = _select('c', 'C?');
      expect(RoundFlowAuthoring.forContent(null, _content([a, b])), isNull);
      final linear = RoundFlowAuthoring.linearFor(_content([a, b]));
      final reordered = RoundFlowAuthoring.forContent(
        linear,
        _content([b, c, a]),
      );
      expect(reordered!.linearNodeIds(), ['b', 'c', 'a']);
      final branching = ContentFlow(
        startNodeId: 'a',
        nodes: const [
          FlowNode(
            id: 'a',
            kind: FlowNodeKind.exercise,
            contentId: 'a',
            transitions: [
              FlowTransition(trigger: FlowTrigger.onCorrect, targetNodeId: 'b'),
              FlowTransition(
                trigger: FlowTrigger.onIncorrect,
                targetNodeId: 'c',
              ),
            ],
          ),
          FlowNode(id: 'b', kind: FlowNodeKind.exercise, contentId: 'b'),
          FlowNode(id: 'c', kind: FlowNodeKind.exercise, contentId: 'c'),
        ],
      );
      expect(branching.isLinear, isFalse);
      expect(
        identical(
          RoundFlowAuthoring.forContent(branching, _content([b, a])),
          branching,
        ),
        isTrue,
      );
    });

    test(
      'remapped renames nodes, content, targets, choices and conditions',
      () {
        final flow = ContentFlow(
          startNodeId: 'a',
          nodes: const [
            FlowNode(
              id: 'a',
              kind: FlowNodeKind.exercise,
              contentId: 'a',
              transitions: [
                FlowTransition(
                  trigger: FlowTrigger.onChoice,
                  targetNodeId: 'b',
                  choiceItemId: 'a_item_0',
                ),
                FlowTransition(
                  trigger: FlowTrigger.conditional,
                  targetNodeId: 'c',
                  condition: FlowCondition(
                    kind: FlowConditionKind.answeredCorrectly,
                    nodeId: 'a',
                  ),
                ),
              ],
            ),
            FlowNode(id: 'b', kind: FlowNodeKind.exercise, contentId: 'b'),
            FlowNode(id: 'c', kind: FlowNodeKind.content, contentId: 'c'),
          ],
        );
        final remapped = RoundFlowAuthoring.remapped(flow, {
          'a': 'x',
          'b': 'y',
          'a_item_0': 'x_item_0',
        })!;
        expect(remapped.startNodeId, 'x');
        expect(remapped.nodes.map((node) => node.id), ['x', 'y', 'c']);
        expect(remapped.nodes.map((node) => node.contentId), ['x', 'y', 'c']);
        final transitions = remapped.nodes.first.transitions;
        expect(transitions[0].targetNodeId, 'y');
        expect(transitions[0].choiceItemId, 'x_item_0');
        expect(transitions[1].targetNodeId, 'c');
        expect(transitions[1].condition!.nodeId, 'x');
        expect(jsonEncode(remapped.toJson()), isNot(jsonEncode(flow.toJson())));
      },
    );
  });

  test('duplicating a Story keeps a flow over the copied content IDs', () {
    final source = LearningRound(
      id: 'round_story',
      updatedAt: DateTime.utc(2026, 9, 27),
      title: 'Story',
      content: _content([_select('a', 'A?'), _select('b', 'B?')]),
      flow: RoundFlowAuthoring.linearFor(
        _content([_select('a', 'A?'), _select('b', 'B?')]),
      ),
    );
    final copy = AuthoringDuplicationService(
      ids: _FixedIds(),
    ).duplicateRound(source);
    expect(copy.id, isNot('round_story'));
    expect(copy.flow, isNotNull);
    expect(copy.flow!.isLinear, isTrue);
    expect(
      copy.flow!.linearNodeIds(),
      copy.content.map((content) => content.id).toList(),
    );
    expect(copy.content.map((c) => c.id), isNot(contains('a')));
  });

  test('copying an exercise into a Story extends its linear flow', () {
    final course = _laboratoryWithStory();
    final lesson = course.lessons.first;
    final story = lesson.rounds.first;
    final donor = lesson.rounds[1];
    final exerciseId = donor.exercises.first.id;
    final updated = CourseAuthoringTransferService().copyExercise(
      course,
      sourceLessonId: lesson.lessonId,
      sourceRoundId: donor.id,
      exerciseId: exerciseId,
      destinationLessonId: lesson.lessonId,
      destinationRoundId: story.id,
    );
    final updatedStory = updated.lessons.first.rounds.first;
    expect(updatedStory.content.length, story.content.length + 1);
    expect(updatedStory.flow, isNotNull);
    expect(
      updatedStory.flow!.linearNodeIds(),
      updatedStory.content.map((content) => content.id).toList(),
    );
    // The donor stays a practice Round.
    expect(updated.lessons.first.rounds[1].flow, isNull);
  });

  testWidgets('the Round editor keeps a Story and offers the Story switch', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final course = _laboratoryWithStory();
    final lesson = course.lessons.first;
    final story = lesson.rounds.first;
    Course? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: RoundEditorScreen(
          course: course,
          lesson: lesson,
          round: story,
          roundIndex: 0,
          onCourseChanged: (value) => changed = value,
          clock: () => DateTime.utc(2026, 9, 27, 12),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final switchFinder = find.byKey(const Key('round-story-switch'));
    expect(switchFinder, findsOneWidget);
    expect(tester.widget<SwitchListTile>(switchFinder).value, isTrue);
    expect(find.textContaining('play in this order'), findsOneWidget);
    // Saving the Round (as draft: the fork's content is Draft, so a
    // published save would fail the Audit) rebuilds it and keeps the flow.
    await tester.tap(find.byKey(const Key('round-save-draft')));
    await tester.pumpAndSettle();
    expect(changed, isNotNull);
    final saved = changed!.lessons.first.rounds.first;
    expect(saved.flow, isNotNull);
    expect(
      saved.flow!.linearNodeIds(),
      saved.content.map((content) => content.id).toList(),
    );
  });

  testWidgets('the Story switch turns a practice Round into a linear Story', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final course = _laboratory();
    final lesson = course.lessons.first;
    final round = lesson.rounds.first;
    expect(round.flow, isNull);
    Course? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: RoundEditorScreen(
          course: course,
          lesson: lesson,
          round: round,
          roundIndex: 0,
          onCourseChanged: (value) => changed = value,
          clock: () => DateTime.utc(2026, 9, 27, 12),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('round-story-switch')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<SwitchListTile>(find.byKey(const Key('round-story-switch')))
          .value,
      isTrue,
    );
    expect(changed, isNotNull);
    final saved = changed!.lessons.first.rounds.first;
    expect(saved.flow, isNotNull);
    expect(
      saved.flow!.linearNodeIds(),
      saved.content.map((content) => content.id).toList(),
    );
    // And off again: a practice Round.
    await tester.tap(find.byKey(const Key('round-story-switch')));
    await tester.pumpAndSettle();
    expect(changed!.lessons.first.rounds.first.flow, isNull);
  });
}

class _FixedIds implements AuthoringIdGenerator {
  var _n = 0;
  @override
  String next(String kind) => 'copy_${kind}_${_n++}';
}
