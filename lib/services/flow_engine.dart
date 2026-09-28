/// A stand-alone engine for content flows (Build 256 Revision 6, plan A.7
/// and Part D): given a flow, the node just finished and what happened
/// there, it names the next node.
///
/// Transitions resolve in the order they are declared on the node: the
/// first `onChoice`, `onCorrect`, `onIncorrect` or `conditional` transition
/// that applies wins; `next` is the fallback wherever it stands; when
/// nothing applies the flow ends. A condition sees the outcome of the node
/// it hangs on (the node is recorded before its transitions are read). The
/// engine assumes a structurally valid flow (`ContentFlow.check()`); an
/// unknown target ends the flow rather than failing.
///
/// The learner runtime plays linear flows directly and does not use the
/// engine yet: a Story whose flow branches counts as "cannot run yet" at
/// Round level, and Adventures, which would play through it, are parked.
library;

import '../models/canonical/content_flow.dart';

enum FlowOutcomeKind { seen, correct, incorrect, chose }

/// What happened at a node: a content node or a card was seen, an exercise
/// was answered correctly or incorrectly, or the learner chose an item.
final class FlowOutcome {
  const FlowOutcome.seen() : kind = FlowOutcomeKind.seen, itemId = null;
  const FlowOutcome.correct() : kind = FlowOutcomeKind.correct, itemId = null;
  const FlowOutcome.incorrect()
    : kind = FlowOutcomeKind.incorrect,
      itemId = null;
  const FlowOutcome.chose(String this.itemId) : kind = FlowOutcomeKind.chose;

  final FlowOutcomeKind kind;
  final String? itemId;

  @override
  String toString() =>
      'FlowOutcome.${kind.name}${itemId == null ? '' : '($itemId)'}';
}

/// What a walk has done so far: the nodes visited in order and the last
/// outcome recorded at each. Immutable; [record] returns the next state.
final class FlowState {
  const FlowState._(this.visited, this.outcomes);
  const FlowState.initial() : this._(const [], const {});

  final List<String> visited;
  final Map<String, FlowOutcome> outcomes;

  FlowState record(String nodeId, FlowOutcome outcome) => FlowState._(
    List.unmodifiable([...visited, nodeId]),
    Map.unmodifiable({...outcomes, nodeId: outcome}),
  );

  bool hasVisited(String nodeId) => visited.contains(nodeId);

  bool answeredCorrectly(String nodeId) =>
      outcomes[nodeId]?.kind == FlowOutcomeKind.correct;

  bool answeredIncorrectly(String nodeId) =>
      outcomes[nodeId]?.kind == FlowOutcomeKind.incorrect;

  /// True when the learner chose [itemId] at [nodeId]; with no item, any
  /// choice there counts.
  bool chose(String nodeId, String? itemId) {
    final outcome = outcomes[nodeId];
    return outcome != null &&
        outcome.kind == FlowOutcomeKind.chose &&
        (itemId == null || outcome.itemId == itemId);
  }

  bool holds(FlowCondition condition) => switch (condition.kind) {
    FlowConditionKind.answeredCorrectly => answeredCorrectly(condition.nodeId),
    FlowConditionKind.answeredIncorrectly => answeredIncorrectly(
      condition.nodeId,
    ),
    FlowConditionKind.chose => chose(condition.nodeId, condition.itemId),
    FlowConditionKind.visited => hasVisited(condition.nodeId),
  };
}

/// The result of [FlowEngine.walk]: the nodes in the order they were
/// visited and the final state.
final class FlowWalk {
  const FlowWalk({required this.path, required this.state});
  final List<String> path;
  final FlowState state;
}

final class FlowEngine {
  const FlowEngine(this.flow);

  final ContentFlow flow;

  /// Where a walk starts, or null when the start node does not exist.
  String? get startNodeId => flow.nodeById(flow.startNodeId)?.id;

  /// The node after [nodeId] given [outcome] there and [state], the walk
  /// before this node; null when the flow ends. The node's own outcome is
  /// recorded before its conditions are read.
  String? nextAfter(String nodeId, FlowOutcome outcome, FlowState state) {
    final node = flow.nodeById(nodeId);
    if (node == null) return null;
    final after = state.record(nodeId, outcome);
    String? fallback;
    for (final transition in node.transitions) {
      if (transition.trigger == FlowTrigger.next) {
        fallback ??= transition.targetNodeId;
        continue;
      }
      final applies = switch (transition.trigger) {
        FlowTrigger.next => false,
        FlowTrigger.onCorrect => outcome.kind == FlowOutcomeKind.correct,
        FlowTrigger.onIncorrect => outcome.kind == FlowOutcomeKind.incorrect,
        FlowTrigger.onChoice =>
          outcome.kind == FlowOutcomeKind.chose &&
              transition.choiceItemId == outcome.itemId,
        FlowTrigger.conditional =>
          transition.condition != null && after.holds(transition.condition!),
      };
      if (applies) return _existing(transition.targetNodeId);
    }
    return fallback == null ? null : _existing(fallback);
  }

  String? _existing(String id) => flow.nodeById(id)?.id;

  /// Walks the flow from the start, asking [outcomeFor] what happens at
  /// each node, until the flow ends. A retry loop is legal, so a walk that
  /// never ends is the caller's mistake: beyond [maxSteps] nodes a
  /// [StateError] is thrown.
  FlowWalk walk({
    required FlowOutcome Function(FlowNode node, FlowState state) outcomeFor,
    int maxSteps = 1000,
  }) {
    var state = const FlowState.initial();
    final path = <String>[];
    var current = startNodeId;
    while (current != null) {
      if (path.length >= maxSteps) {
        throw StateError('The flow did not end within $maxSteps steps.');
      }
      final node = flow.nodeById(current)!;
      final outcome = outcomeFor(node, state);
      path.add(current);
      final next = nextAfter(current, outcome, state);
      state = state.record(current, outcome);
      current = next;
    }
    return FlowWalk(path: path, state: state);
  }
}
