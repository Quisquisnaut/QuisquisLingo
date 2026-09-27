import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/canonical/canonical.dart';

FlowNode content(String id, [String? contentId]) => FlowNode(
  id: id,
  kind: FlowNodeKind.content,
  contentId: contentId ?? 'c_$id',
);

FlowNode exercise(String id, [List<FlowTransition> transitions = const []]) =>
    FlowNode(
      id: id,
      kind: FlowNodeKind.exercise,
      contentId: 'c_$id',
      transitions: transitions,
    );

List<FlowStructureIssueCode> codes(ContentFlow flow) =>
    flow.check().map((issue) => issue.code).toList();

void main() {
  test('a linear Story chains content and exercise nodes with next', () {
    final flow = ContentFlow.linear([
      content('dialogue1'),
      content('dialogue2'),
      exercise('question'),
      content('narration'),
      exercise('typed'),
      content('ending'),
    ]);
    expect(flow.startNodeId, 'dialogue1');
    expect(flow.isValid, isTrue);
    expect(flow.hasBranching, isFalse);
    expect(flow.isLinear, isTrue);
    expect(flow.linearNodeIds(), [
      'dialogue1',
      'dialogue2',
      'question',
      'narration',
      'typed',
      'ending',
    ]);
    expect(flow.nodeById('ending')!.transitions, isEmpty);
    expect(flow.nodeById('question')!.nextNodeId, 'narration');
    expect(flow.reachableNodeIds(), hasLength(6));
    expect(
      ContentFlow.linear(const []).check().single.code,
      FlowStructureIssueCode.emptyFlow,
    );
  });

  test('trigger, node-kind and condition identifiers parse strictly', () {
    expect(FlowTrigger.tryParse('onChoice'), FlowTrigger.onChoice);
    expect(FlowTrigger.tryParse('onchoice'), isNull);
    expect(FlowNodeKind.tryParse('exercise'), FlowNodeKind.exercise);
    expect(FlowNodeKind.tryParse('Exercise'), isNull);
    expect(FlowConditionKind.tryParse('visited'), FlowConditionKind.visited);
    expect(FlowConditionKind.tryParse(null), isNull);
    expect(FlowTrigger.values.map((trigger) => trigger.serialized), [
      'next',
      'onCorrect',
      'onIncorrect',
      'onChoice',
      'conditional',
    ]);
  });

  test('branching on correctness is valid, not linear', () {
    final flow = ContentFlow(
      startNodeId: 'a',
      nodes: [
        exercise('a', const [
          FlowTransition(trigger: FlowTrigger.onCorrect, targetNodeId: 'b'),
          FlowTransition(
            trigger: FlowTrigger.onIncorrect,
            targetNodeId: 'hint',
          ),
        ]),
        content('hint').copyWith(transitions: const [FlowTransition.next('a')]),
        content('b'),
      ],
    );
    expect(flow.check(), isEmpty);
    expect(flow.hasBranching, isTrue);
    expect(flow.isLinear, isFalse);
    expect(flow.linearNodeIds(), isNull);
  });

  test('a choice branch names the chosen item per transition', () {
    final flow = ContentFlow(
      startNodeId: 'ask',
      nodes: [
        exercise('ask', const [
          FlowTransition(
            trigger: FlowTrigger.onChoice,
            targetNodeId: 'branchA',
            choiceItemId: 'item_a',
          ),
          FlowTransition(
            trigger: FlowTrigger.onChoice,
            targetNodeId: 'branchB',
            choiceItemId: 'item_b',
          ),
        ]),
        content('branchA'),
        content('branchB'),
      ],
    );
    expect(flow.check(), isEmpty);
    expect(flow.hasBranching, isTrue);
  });

  test('a conditional transition refers to an earlier node', () {
    final flow = ContentFlow(
      startNodeId: 'q1',
      nodes: [
        exercise('q1', const [FlowTransition.next('q2')]),
        exercise('q2', const [
          FlowTransition(
            trigger: FlowTrigger.conditional,
            targetNodeId: 'bonus',
            condition: FlowCondition(
              kind: FlowConditionKind.answeredCorrectly,
              nodeId: 'q1',
            ),
          ),
          FlowTransition.next('end'),
        ]),
        content(
          'bonus',
        ).copyWith(transitions: const [FlowTransition.next('end')]),
        content('end'),
      ],
    );
    expect(flow.check(), isEmpty);
    expect(flow.isLinear, isFalse);
  });

  test('structural issues are reported with their codes', () {
    expect(codes(ContentFlow(startNodeId: 'missing', nodes: [content('a')])), [
      FlowStructureIssueCode.startNodeMissing,
    ]);
    expect(
      codes(ContentFlow(startNodeId: 'a', nodes: [content('a'), content('a')])),
      contains(FlowStructureIssueCode.duplicateNodeId),
    );
    expect(
      codes(ContentFlow(startNodeId: '', nodes: [content('', 'x')])),
      contains(FlowStructureIssueCode.blankNodeId),
    );
    expect(codes(ContentFlow(startNodeId: 'a', nodes: [content('a', '')])), [
      FlowStructureIssueCode.blankContentId,
    ]);
    expect(
      codes(
        ContentFlow(
          startNodeId: 'a',
          nodes: [
            content(
              'a',
            ).copyWith(transitions: const [FlowTransition.next('zz')]),
          ],
        ),
      ),
      [FlowStructureIssueCode.targetNodeUnknown],
    );
    expect(
      codes(
        ContentFlow(
          startNodeId: 'a',
          nodes: [
            content('a').copyWith(
              transitions: const [
                FlowTransition(
                  trigger: FlowTrigger.onCorrect,
                  targetNodeId: 'b',
                ),
              ],
            ),
            content('b'),
          ],
        ),
      ),
      [FlowStructureIssueCode.contentNodeBranches],
    );
    expect(
      codes(
        ContentFlow(
          startNodeId: 'a',
          nodes: [
            content('a').copyWith(
              transitions: const [
                FlowTransition.next('b'),
                FlowTransition.next('c'),
              ],
            ),
            content('b'),
            content('c'),
          ],
        ),
      ),
      [FlowStructureIssueCode.duplicateNext],
    );
    expect(
      codes(
        ContentFlow(
          startNodeId: 'a',
          nodes: [
            exercise('a', const [
              FlowTransition(trigger: FlowTrigger.onChoice, targetNodeId: 'b'),
            ]),
            content('b'),
          ],
        ),
      ),
      [FlowStructureIssueCode.choiceWithoutItem],
    );
    expect(
      codes(
        ContentFlow(
          startNodeId: 'a',
          nodes: [
            exercise('a', const [
              FlowTransition(
                trigger: FlowTrigger.conditional,
                targetNodeId: 'b',
              ),
            ]),
            content('b'),
          ],
        ),
      ),
      [FlowStructureIssueCode.conditionalWithoutCondition],
    );
    expect(
      codes(
        ContentFlow(
          startNodeId: 'a',
          nodes: [
            exercise('a', const [
              FlowTransition(
                trigger: FlowTrigger.conditional,
                targetNodeId: 'b',
                condition: FlowCondition(
                  kind: FlowConditionKind.visited,
                  nodeId: 'nowhere',
                ),
              ),
            ]),
            content('b'),
          ],
        ),
      ),
      [FlowStructureIssueCode.conditionNodeUnknown],
    );
    expect(
      codes(
        ContentFlow(
          startNodeId: 'a',
          nodes: [
            exercise('a', const [
              FlowTransition.next('b'),
              FlowTransition(
                trigger: FlowTrigger.onCorrect,
                targetNodeId: 'b',
                choiceItemId: 'item',
              ),
              FlowTransition(
                trigger: FlowTrigger.onIncorrect,
                targetNodeId: 'b',
                condition: FlowCondition(
                  kind: FlowConditionKind.visited,
                  nodeId: 'a',
                ),
              ),
            ]),
            content('b'),
          ],
        ),
      ),
      [
        FlowStructureIssueCode.choiceItemOnOtherTrigger,
        FlowStructureIssueCode.conditionOnOtherTrigger,
      ],
    );
    expect(
      codes(
        ContentFlow(
          startNodeId: 'a',
          nodes: [
            content(
              'a',
            ).copyWith(transitions: const [FlowTransition.next('a')]),
          ],
        ),
      ),
      [FlowStructureIssueCode.nextSelfLoop],
    );
    expect(
      codes(
        ContentFlow(startNodeId: 'a', nodes: [content('a'), content('orphan')]),
      ),
      [FlowStructureIssueCode.unreachableNode],
    );
  });

  test('a cycle through next is valid but not linear', () {
    final flow = ContentFlow(
      startNodeId: 'a',
      nodes: [
        content('a').copyWith(transitions: const [FlowTransition.next('b')]),
        content('b').copyWith(transitions: const [FlowTransition.next('a')]),
      ],
    );
    expect(flow.check(), isEmpty);
    expect(flow.isLinear, isFalse);
    expect(flow.linearNodeIds(), isNull);
  });
}
