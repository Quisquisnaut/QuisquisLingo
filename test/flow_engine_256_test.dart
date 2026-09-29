import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/flow_engine.dart';

/// Build 256 Revision 6: the stand-alone flow engine (plan A.7). It names
/// the next node from the node just finished and what happened there:
/// onChoice, onCorrect, onIncorrect and conditional transitions in declared
/// order, `next` as the fallback, the end when nothing applies. Not wired
/// to playback: linear Stories play directly and branching ones wait.
FlowNode _exercise(String id, [List<FlowTransition> transitions = const []]) =>
    FlowNode(
      id: id,
      kind: FlowNodeKind.exercise,
      contentId: 'content_$id',
      transitions: transitions,
    );

FlowNode _content(String id, [List<FlowTransition> transitions = const []]) =>
    FlowNode(
      id: id,
      kind: FlowNodeKind.content,
      contentId: 'content_$id',
      transitions: transitions,
    );

FlowTransition _on(FlowTrigger trigger, String target, {String? item}) =>
    FlowTransition(trigger: trigger, targetNodeId: target, choiceItemId: item);

FlowTransition _when(
  FlowConditionKind kind,
  String nodeId,
  String target, {
  String? item,
}) => FlowTransition(
  trigger: FlowTrigger.conditional,
  targetNodeId: target,
  condition: FlowCondition(kind: kind, nodeId: nodeId, itemId: item),
);

ContentFlow _flow(List<FlowNode> nodes) =>
    ContentFlow(startNodeId: nodes.first.id, nodes: nodes);

List<String> _walk(
  ContentFlow flow,
  FlowOutcome Function(FlowNode node, FlowState state) outcomeFor, {
  int maxSteps = 1000,
}) => FlowEngine(flow).walk(outcomeFor: outcomeFor, maxSteps: maxSteps).path;

void main() {
  test('a linear flow walks in its authored order', () {
    final flow = ContentFlow.linear([
      _content('c1'),
      _exercise('e1'),
      _exercise('e2'),
    ]);
    expect(flow.check(), isEmpty);
    expect(
      _walk(flow, (_, _) => const FlowOutcome.seen()),
      flow.linearNodeIds(),
    );
    expect(_walk(flow, (_, _) => const FlowOutcome.seen()), ['c1', 'e1', 'e2']);
  });

  test(
    'onCorrect and onIncorrect branch on the answer, next is the fallback',
    () {
      final flow = _flow([
        _exercise('q', [
          _on(FlowTrigger.onIncorrect, 'help'),
          FlowTransition.next('end'),
        ]),
        _content('help', [FlowTransition.next('end')]),
        _content('end'),
      ]);
      expect(flow.check(), isEmpty);
      expect(flow.isLinear, isFalse);
      expect(
        _walk(
          flow,
          (node, _) => node.id == 'q'
              ? const FlowOutcome.incorrect()
              : const FlowOutcome.seen(),
        ),
        ['q', 'help', 'end'],
      );
      expect(
        _walk(
          flow,
          (node, _) => node.id == 'q'
              ? const FlowOutcome.correct()
              : const FlowOutcome.seen(),
        ),
        ['q', 'end'],
      );
      // A card in place of the question (seen, no answer) takes the fallback.
      expect(_walk(flow, (_, _) => const FlowOutcome.seen()), ['q', 'end']);
    },
  );

  test('onChoice follows the chosen item; an unlisted choice takes next', () {
    final flow = _flow([
      _exercise('fork', [
        _on(FlowTrigger.onChoice, 'left', item: 'a'),
        _on(FlowTrigger.onChoice, 'right', item: 'b'),
        FlowTransition.next('both'),
      ]),
      _content('left', [FlowTransition.next('both')]),
      _content('right', [FlowTransition.next('both')]),
      _content('both'),
    ]);
    expect(flow.check(), isEmpty);
    List<String> chose(String item) => _walk(
      flow,
      (node, _) => node.id == 'fork'
          ? FlowOutcome.chose(item)
          : const FlowOutcome.seen(),
    );
    expect(chose('a'), ['fork', 'left', 'both']);
    expect(chose('b'), ['fork', 'right', 'both']);
    expect(chose('c'), ['fork', 'both']);
  });

  test(
    'conditions read the outcomes recorded so far, the current node included',
    () {
      final flow = _flow([
        _exercise('q1', [FlowTransition.next('q2')]),
        _exercise('q2', [
          _when(FlowConditionKind.answeredCorrectly, 'q1', 'praise'),
          _when(FlowConditionKind.answeredIncorrectly, 'q1', 'help'),
          FlowTransition.next('end'),
        ]),
        _content('praise', [FlowTransition.next('end')]),
        _content('help', [FlowTransition.next('end')]),
        _content('end'),
      ]);
      expect(flow.check(), isEmpty);
      List<String> after(FlowOutcome q1) => _walk(
        flow,
        (node, _) => node.id == 'q1' ? q1 : const FlowOutcome.seen(),
      );
      expect(after(const FlowOutcome.correct()), ['q1', 'q2', 'praise', 'end']);
      expect(after(const FlowOutcome.incorrect()), ['q1', 'q2', 'help', 'end']);
      expect(after(const FlowOutcome.seen()), ['q1', 'q2', 'end']);

      final chosen = _flow([
        _exercise('pick', [FlowTransition.next('later')]),
        _content('later', [
          _when(FlowConditionKind.chose, 'pick', 'tea', item: 'tea'),
          _when(FlowConditionKind.visited, 'pick', 'visited'),
        ]),
        _content('tea'),
        _content('visited'),
      ]);
      expect(chosen.check(), isEmpty);
      expect(
        _walk(
          chosen,
          (node, _) => node.id == 'pick'
              ? const FlowOutcome.chose('tea')
              : const FlowOutcome.seen(),
        ),
        ['pick', 'later', 'tea'],
      );
      expect(
        _walk(
          chosen,
          (node, _) => node.id == 'pick'
              ? const FlowOutcome.chose('coffee')
              : const FlowOutcome.seen(),
        ),
        ['pick', 'later', 'visited'],
      );

      // The node's own outcome is visible to its conditions.
      final self = _flow([
        _exercise('q', [
          _when(FlowConditionKind.answeredCorrectly, 'q', 'yes'),
          FlowTransition.next('no'),
        ]),
        _content('yes'),
        _content('no'),
      ]);
      expect(self.check(), isEmpty);
      expect(
        _walk(
          self,
          (node, _) => node.id == 'q'
              ? const FlowOutcome.correct()
              : const FlowOutcome.seen(),
        ),
        ['q', 'yes'],
      );
    },
  );

  test('transitions resolve in declared order; next wins only as fallback', () {
    final flow = _flow([
      _exercise('q', [
        FlowTransition.next('plain'),
        _when(FlowConditionKind.visited, 'q', 'visited'),
        _on(FlowTrigger.onCorrect, 'correct'),
      ]),
      _content('plain'),
      _content('visited'),
      _content('correct'),
    ]);
    expect(flow.check(), isEmpty);
    // Correct: the visited condition is declared first and holds.
    expect(
      _walk(
        flow,
        (node, _) => node.id == 'q'
            ? const FlowOutcome.correct()
            : const FlowOutcome.seen(),
      ),
      ['q', 'visited'],
    );
    final reordered = _flow([
      _exercise('q', [
        _on(FlowTrigger.onCorrect, 'correct'),
        _when(FlowConditionKind.visited, 'q', 'visited'),
        FlowTransition.next('plain'),
      ]),
      _content('plain'),
      _content('visited'),
      _content('correct'),
    ]);
    expect(
      _walk(
        reordered,
        (node, _) => node.id == 'q'
            ? const FlowOutcome.correct()
            : const FlowOutcome.seen(),
      ),
      ['q', 'correct'],
    );
  });

  test('the flow ends when nothing applies or a target is unknown', () {
    final engine = FlowEngine(
      _flow([
        _exercise('q', [_on(FlowTrigger.onCorrect, 'gone')]),
      ]),
    );
    expect(
      engine.nextAfter(
        'q',
        const FlowOutcome.correct(),
        const FlowState.initial(),
      ),
      isNull,
      reason: 'unknown target',
    );
    expect(
      engine.nextAfter(
        'q',
        const FlowOutcome.incorrect(),
        const FlowState.initial(),
      ),
      isNull,
      reason: 'no applicable transition',
    );
    expect(
      engine.nextAfter(
        'missing',
        const FlowOutcome.seen(),
        const FlowState.initial(),
      ),
      isNull,
    );
    expect(
      FlowEngine(
        ContentFlow(startNodeId: 'nowhere', nodes: [_content('c')]),
      ).walk(outcomeFor: (_, _) => const FlowOutcome.seen()).path,
      isEmpty,
    );
  });

  test('a retry loop repeats until the answer is right and is bounded', () {
    final flow = _flow([
      _exercise('q', [
        _on(FlowTrigger.onIncorrect, 'q'),
        FlowTransition.next('end'),
      ]),
      _content('end'),
    ]);
    var attempts = 0;
    expect(
      _walk(flow, (node, state) {
        if (node.id != 'q') return const FlowOutcome.seen();
        attempts++;
        return attempts < 3
            ? const FlowOutcome.incorrect()
            : const FlowOutcome.correct();
      }),
      ['q', 'q', 'q', 'end'],
    );
    expect(
      () => _walk(
        flow,
        (node, _) => node.id == 'q'
            ? const FlowOutcome.incorrect()
            : const FlowOutcome.seen(),
        maxSteps: 5,
      ),
      throwsStateError,
    );
  });

  test('the state records visits and outcomes immutably', () {
    const initial = FlowState.initial();
    final one = initial.record('a', const FlowOutcome.chose('x'));
    final two = one.record('b', const FlowOutcome.incorrect());
    expect(initial.visited, isEmpty);
    expect(one.visited, ['a']);
    expect(two.visited, ['a', 'b']);
    expect(two.chose('a', 'x'), isTrue);
    expect(two.chose('a', 'y'), isFalse);
    expect(two.chose('a', null), isTrue);
    expect(two.answeredIncorrectly('b'), isTrue);
    expect(two.answeredCorrectly('b'), isFalse);
    expect(two.hasVisited('c'), isFalse);
    expect(() => two.visited.add('c'), throwsUnsupportedError);
  });
}
