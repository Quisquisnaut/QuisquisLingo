import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_audit_service.dart';
import 'package:quisquislingo_app/services/round_playability_service.dart';

import 'support/canonical_course_256.dart';

/// Build 256 Revision 7 (plan Part D, session 6): the negative cases in one
/// place. What the parser refuses (unknown primitives, unknown or
/// inapplicable options, illegal values, unknown evaluation keys, the v11
/// shapes, an older format), what the Audit blocks (illegal combinations
/// and evaluation modes, a missing required option, broken item, target and
/// layout references, impossible selection limits) and what a malformed
/// flow reports.
Map<String, dynamic> _select({
  Map<String, Object?> options = const {},
  Map<String, Object?>? evaluation,
  List<Map<String, Object?>>? items,
  List<Map<String, Object?>>? layout,
  List<Map<String, Object?>>? targets,
}) => {
  'updatedAt': '2026-09-28T23:00:00.000Z',
  'primitive': 'select',
  if (options.isNotEmpty) 'options': options,
  'prompt': [
    {'role': 'question', 'type': 'text', 'text': 'Which is a cat?'},
  ],
  'items':
      items ??
      [
        {
          'id': 'a',
          'content': [
            {'role': 'primary', 'type': 'text', 'text': 'gatto'},
          ],
        },
        {
          'id': 'b',
          'content': [
            {'role': 'primary', 'type': 'text', 'text': 'cane'},
          ],
        },
      ],
  if (targets != null) 'targets': targets,
  if (layout != null) 'layout': layout,
  'evaluation':
      evaluation ??
      {
        'mode': 'exactItem',
        'correctItemIds': ['a'],
      },
};

Exercise _parse(Map<String, dynamic> json) => Exercise.fromJson(
  json,
  contentId: 'ex',
  publicationState: PublicationState.published,
);

Iterable<String> _errorCodes(Exercise exercise) => CourseAuditService()
    .auditExercise(exercise)
    .where((issue) => issue.severity == AuditSeverity.error)
    .map((issue) => issue.code);

void main() {
  group('the parser refuses', () {
    test('an unknown primitive', () {
      expect(
        () => _parse({..._select(), 'primitive': 'hotspot'}),
        throwsFormatException,
      );
    });

    test('an unknown option, an inapplicable one and an illegal value', () {
      expect(
        () => _parse(_select(options: {'colour': 'red'})),
        throwsFormatException,
      );
      expect(
        () => _parse(_select(options: {'inputMode': 'text'})),
        throwsFormatException,
      );
      expect(
        () => _parse(_select(options: {'selectionMode': 'triple'})),
        throwsFormatException,
      );
    });

    test('an unknown evaluation key and an unknown mode', () {
      expect(
        () => _parse(
          _select(
            evaluation: {
              'mode': 'exactItem',
              'correctItemIds': ['a'],
              'score': 3,
            },
          ),
        ),
        throwsFormatException,
      );
      expect(
        () => _parse(_select(evaluation: {'mode': 'bestGuess'})),
        throwsFormatException,
      );
    });

    test('the v11 shapes', () {
      expect(
        () => _parse({
          ..._select(),
          'interaction': {'kind': 'select'},
        }),
        throwsFormatException,
      );
      expect(
        () => _parse({..._select(), 'editorTemplate': 'choice'}),
        throwsFormatException,
      );
    });

    test('an older Course format, naming the converter', () {
      final json = canonicalCourse256().toJson();
      json['formatVersion'] = 11;
      expect(
        () => Course.fromJson(json),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('convert_course_to_v12'),
          ),
        ),
      );
    });

    test('a flow with an unknown trigger or node kind', () {
      expect(
        () => ContentFlow.fromJson({
          'start': 'n1',
          'nodes': [
            {
              'id': 'n1',
              'kind': 'exercise',
              'contentId': 'c1',
              'transitions': [
                {'trigger': 'onMood', 'target': 'n1'},
              ],
            },
          ],
        }),
        throwsFormatException,
      );
      expect(
        () => ContentFlow.fromJson({
          'start': 'n1',
          'nodes': [
            {'id': 'n1', 'kind': 'scene', 'contentId': 'c1'},
          ],
        }),
        throwsFormatException,
      );
    });
  });

  group('the Audit blocks', () {
    test('an illegal combination and an illegal evaluation mode', () {
      final combination = Exercise.canonical(
        id: 'combo',
        primitive: ExercisePrimitive.input,
        options: PrimitiveOptions({
          OptionKey.cardinality: const EnumOptionValue(Cardinality.multiple),
          OptionKey.layout: const EnumOptionValue(LayoutValue.field),
        }),
        promptElements: const [PromptElement(type: 'text', text: 'Type it')],
        canonicalEvaluation: const CanonicalEvaluation(
          mode: EvaluationMode.acceptedTexts,
          answers: ['x'],
        ),
      );
      expect(
        _errorCodes(combination),
        contains('EXERCISE_COMBINATION_ILLEGAL'),
      );
      final mode = Exercise.canonical(
        id: 'mode',
        primitive: ExercisePrimitive.select,
        promptElements: const [PromptElement(type: 'text', text: 'Choose')],
        canonicalEvaluation: const CanonicalEvaluation(
          mode: EvaluationMode.exactText,
          answers: ['x'],
        ),
      );
      expect(_errorCodes(mode), contains('EXERCISE_EVALUATION_MODE_INVALID'));
      expect(mode.runtimeSupport.state, ExerciseSupportState.invalid);
    });

    test('a missing required option', () {
      final assign = Exercise.canonical(
        id: 'assign',
        primitive: ExercisePrimitive.assign,
        promptElements: const [PromptElement(type: 'text', text: 'Sort')],
        items: const [
          ExerciseItem(
            id: 'i',
            content: [PromptElement(type: 'text', text: 'gatto')],
          ),
        ],
        targets: const [ExerciseTarget(id: 't')],
        layout: const [LayoutElement.target('t')],
        canonicalEvaluation: const CanonicalEvaluation(
          mode: EvaluationMode.exactAssignments,
          assignments: [
            TargetAssignment(targetId: 't', itemIds: ['i']),
          ],
        ),
      );
      expect(_errorCodes(assign), contains('EXERCISE_OPTION_INVALID'));
    });

    test('broken item, target and layout references', () {
      final item = _parse(
        _select(
          evaluation: {
            'mode': 'exactItem',
            'correctItemIds': ['zz'],
          },
        ),
      );
      expect(_errorCodes(item), contains('EXERCISE_ITEM_REFERENCE'));
      final layout = _parse(
        _select(
          options: {'layout': 'inline'},
          targets: [
            {'id': 'g1'},
          ],
          layout: [
            {'type': 'text', 'text': 'Il'},
            {'type': 'target', 'targetId': 'nowhere'},
          ],
        ),
      );
      expect(_errorCodes(layout), contains('EXERCISE_TARGET_REFERENCE'));
    });

    test('impossible selection limits', () {
      final limits = _parse(
        _select(
          options: {
            'selectionMode': 'multiple',
            'evaluationTiming': 'explicit',
            'maximumSelections': 1,
          },
          items: [
            for (final value in ['gatto', 'cane', 'casa'])
              {
                'id': value,
                'content': [
                  {'role': 'primary', 'type': 'text', 'text': value},
                ],
              },
          ],
          evaluation: {
            'mode': 'exactSet',
            'correctItemIds': ['gatto', 'cane'],
          },
        ),
      );
      expect(_errorCodes(limits), contains('EXERCISE_SELECTION_LIMITS'));
    });
  });

  group('a malformed flow', () {
    FlowNode node(
      String id,
      List<FlowTransition> transitions, {
      FlowNodeKind kind = FlowNodeKind.exercise,
    }) => FlowNode(
      id: id,
      kind: kind,
      contentId: 'c_$id',
      transitions: transitions,
    );

    test('reports its structural problems and never plays', () {
      final unknownTarget = ContentFlow(
        startNodeId: 'a',
        nodes: [
          node('a', const [FlowTransition.next('gone')]),
        ],
      );
      expect(
        unknownTarget.check().map((issue) => issue.code),
        contains(FlowStructureIssueCode.targetNodeUnknown),
      );
      final twoNexts = ContentFlow(
        startNodeId: 'a',
        nodes: [
          node('a', const [FlowTransition.next('b'), FlowTransition.next('c')]),
          node('b', const []),
          node('c', const []),
        ],
      );
      expect(
        twoNexts.check().map((issue) => issue.code),
        contains(FlowStructureIssueCode.duplicateNext),
      );
      final contentBranches = ContentFlow(
        startNodeId: 'a',
        nodes: [
          node('a', const [
            FlowTransition(trigger: FlowTrigger.onCorrect, targetNodeId: 'b'),
          ], kind: FlowNodeKind.content),
          node('b', const []),
        ],
      );
      expect(
        contentBranches.check().map((issue) => issue.code),
        contains(FlowStructureIssueCode.contentNodeBranches),
      );
      final unreachable = ContentFlow(
        startNodeId: 'a',
        nodes: [node('a', const []), node('b', const [])],
      );
      expect(
        unreachable.check().map((issue) => issue.code),
        contains(FlowStructureIssueCode.unreachableNode),
      );
      for (final flow in [
        unknownTarget,
        twoNexts,
        contentBranches,
        unreachable,
      ]) {
        expect(flow.isLinear, isFalse);
      }
      // A Round carrying such a flow has nothing playable and is reported.
      final round = LearningRound(
        id: 'r',
        title: 'Broken',
        updatedAt: DateTime.utc(2026, 9, 28),
        content: [LearningContent.fromExercise(_parse(_select()))],
        flow: unreachable,
      );
      expect(RoundPlayabilityService().playableExerciseIndices(round), isEmpty);
      expect(
        CourseAuditService.notCompletableReason(round),
        contains('not a straight sequence'),
      );
    });
  });
}
