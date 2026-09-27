/// Content flows: how the content and exercise nodes of a Round, Story or
/// other learning activity are ordered or branched (Course Model v12).
///
/// A Story is not a primitive. It is a flow whose nodes point at the Round's
/// Content entries: content nodes show material (dialogue, narration, a
/// Presentation exercise) and exercise nodes run a scored primitive. Linear
/// flows chain nodes with `next`; branching uses `onCorrect`, `onIncorrect`,
/// `onChoice` and `conditional` transitions, which this model represents and
/// checks structurally so later builds can play them without changing the
/// serialized shape. A node with no applicable transition ends the flow.
library;

/// What a node does when the flow reaches it.
enum FlowNodeKind {
  /// Shows the referenced Content (textual material or a Presentation).
  content('content'),

  /// Runs the referenced Content's exercise and records its outcome.
  exercise('exercise');

  const FlowNodeKind(this.serialized);
  final String serialized;

  static FlowNodeKind? tryParse(Object? value) {
    if (value is! String) return null;
    for (final kind in values) {
      if (kind.serialized == value) return kind;
    }
    return null;
  }
}

/// When a transition is taken.
enum FlowTrigger {
  /// Unconditionally, after the node completes. At most one per node.
  next('next'),

  /// After an exercise node whose answer was correct.
  onCorrect('onCorrect'),

  /// After an exercise node whose answer was incorrect.
  onIncorrect('onIncorrect'),

  /// After an exercise node in which the learner chose [FlowTransition.choiceItemId].
  onChoice('onChoice'),

  /// When [FlowTransition.condition] holds.
  conditional('conditional');

  const FlowTrigger(this.serialized);
  final String serialized;

  static FlowTrigger? tryParse(Object? value) {
    if (value is! String) return null;
    for (final trigger in values) {
      if (trigger.serialized == value) return trigger;
    }
    return null;
  }
}

/// What a conditional transition tests. Every kind refers to an earlier
/// node's recorded outcome, so a condition never needs learner state outside
/// the flow.
enum FlowConditionKind {
  answeredCorrectly('answeredCorrectly'),
  answeredIncorrectly('answeredIncorrectly'),
  chose('chose'),
  visited('visited');

  const FlowConditionKind(this.serialized);
  final String serialized;

  static FlowConditionKind? tryParse(Object? value) {
    if (value is! String) return null;
    for (final kind in values) {
      if (kind.serialized == value) return kind;
    }
    return null;
  }
}

String _requiredFlowString(Map<String, dynamic> j, String key, String where) {
  final v = j[key];
  if (v is! String || v.trim().isEmpty) {
    throw FormatException('Missing or invalid $where.$key');
  }
  return v.trim();
}

void _refuseUnknownFlowKeys(
  Map<String, dynamic> j,
  Set<String> known,
  String where,
) {
  final unknown = j.keys.where((key) => !known.contains(key)).toList();
  if (unknown.isNotEmpty) {
    throw FormatException(
      '$where contains unsupported fields: ${unknown.join(', ')}.',
    );
  }
}

final class FlowCondition {
  const FlowCondition({required this.kind, required this.nodeId, this.itemId});

  final FlowConditionKind kind;

  /// The node whose outcome is tested.
  final String nodeId;

  /// For [FlowConditionKind.chose]: the item the learner must have chosen.
  final String? itemId;

  Map<String, dynamic> toJson() => {
    'kind': kind.serialized,
    'nodeId': nodeId,
    if (itemId != null) 'itemId': itemId,
  };

  factory FlowCondition.fromJson(Map<String, dynamic> j) {
    _refuseUnknownFlowKeys(j, const {'kind', 'nodeId', 'itemId'}, 'condition');
    final kind = FlowConditionKind.tryParse(j['kind']);
    if (kind == null) {
      throw FormatException('condition.kind “${j['kind']}” is not supported.');
    }
    final itemId = j['itemId'];
    if (j.containsKey('itemId') && itemId is! String) {
      throw const FormatException('condition.itemId must be a string.');
    }
    return FlowCondition(
      kind: kind,
      nodeId: _requiredFlowString(j, 'nodeId', 'condition'),
      itemId: itemId as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FlowCondition &&
      other.kind == kind &&
      other.nodeId == nodeId &&
      other.itemId == itemId;

  @override
  int get hashCode => Object.hash(kind, nodeId, itemId);
}

final class FlowTransition {
  const FlowTransition({
    required this.trigger,
    required this.targetNodeId,
    this.choiceItemId,
    this.condition,
  });

  const FlowTransition.next(String targetNodeId)
    : this(trigger: FlowTrigger.next, targetNodeId: targetNodeId);

  final FlowTrigger trigger;
  final String targetNodeId;

  /// For [FlowTrigger.onChoice]: the chosen item that takes this transition.
  final String? choiceItemId;

  /// For [FlowTrigger.conditional].
  final FlowCondition? condition;

  Map<String, dynamic> toJson() => {
    'trigger': trigger.serialized,
    'target': targetNodeId,
    if (choiceItemId != null) 'choiceItemId': choiceItemId,
    if (condition != null) 'condition': condition!.toJson(),
  };

  factory FlowTransition.fromJson(Map<String, dynamic> j) {
    _refuseUnknownFlowKeys(j, const {
      'trigger',
      'target',
      'choiceItemId',
      'condition',
    }, 'transition');
    final trigger = FlowTrigger.tryParse(j['trigger']);
    if (trigger == null) {
      throw FormatException(
        'transition.trigger “${j['trigger']}” must be next, onCorrect, onIncorrect, onChoice or conditional.',
      );
    }
    final choiceItemId = j['choiceItemId'];
    if (j.containsKey('choiceItemId') && choiceItemId is! String) {
      throw const FormatException('transition.choiceItemId must be a string.');
    }
    final condition = j['condition'];
    if (j.containsKey('condition') && condition is! Map) {
      throw const FormatException('transition.condition must be an object.');
    }
    return FlowTransition(
      trigger: trigger,
      targetNodeId: _requiredFlowString(j, 'target', 'transition'),
      choiceItemId: choiceItemId as String?,
      condition: condition is Map
          ? FlowCondition.fromJson(Map<String, dynamic>.from(condition))
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FlowTransition &&
      other.trigger == trigger &&
      other.targetNodeId == targetNodeId &&
      other.choiceItemId == choiceItemId &&
      other.condition == condition;

  @override
  int get hashCode =>
      Object.hash(trigger, targetNodeId, choiceItemId, condition);
}

final class FlowNode {
  const FlowNode({
    required this.id,
    required this.kind,
    required this.contentId,
    this.transitions = const [],
  });

  final String id;
  final FlowNodeKind kind;

  /// The Round Content entry this node shows or runs.
  final String contentId;
  final List<FlowTransition> transitions;

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.serialized,
    'contentId': contentId,
    if (transitions.isNotEmpty)
      'transitions': transitions.map((t) => t.toJson()).toList(),
  };

  factory FlowNode.fromJson(Map<String, dynamic> j) {
    _refuseUnknownFlowKeys(j, const {
      'id',
      'kind',
      'contentId',
      'transitions',
    }, 'flow node');
    final kind = FlowNodeKind.tryParse(j['kind']);
    if (kind == null) {
      throw FormatException(
        'flow node kind “${j['kind']}” must be content or exercise.',
      );
    }
    final rawTransitions = j['transitions'];
    if (j.containsKey('transitions') && rawTransitions is! List) {
      throw const FormatException('flow node transitions must be a list.');
    }
    return FlowNode(
      id: _requiredFlowString(j, 'id', 'flow node'),
      kind: kind,
      contentId: _requiredFlowString(j, 'contentId', 'flow node'),
      transitions: [
        if (rawTransitions is List)
          for (final transition in rawTransitions)
            if (transition is Map)
              FlowTransition.fromJson(Map<String, dynamic>.from(transition))
            else
              throw const FormatException(
                'flow node transitions must contain objects.',
              ),
      ],
    );
  }

  FlowNode copyWith({List<FlowTransition>? transitions}) => FlowNode(
    id: id,
    kind: kind,
    contentId: contentId,
    transitions: transitions ?? this.transitions,
  );

  /// The unconditional successor, if any.
  String? get nextNodeId => transitions
      .where((transition) => transition.trigger == FlowTrigger.next)
      .map((transition) => transition.targetNodeId)
      .firstOrNull;

  bool get hasBranching =>
      transitions.any((transition) => transition.trigger != FlowTrigger.next);
}

enum FlowStructureIssueCode {
  emptyFlow,
  blankNodeId,
  duplicateNodeId,
  blankContentId,
  startNodeMissing,
  targetNodeUnknown,
  duplicateNext,
  contentNodeBranches,
  choiceWithoutItem,
  choiceItemOnOtherTrigger,
  conditionalWithoutCondition,
  conditionOnOtherTrigger,
  conditionNodeUnknown,
  nextSelfLoop,
  unreachableNode,
}

final class FlowStructureIssue {
  const FlowStructureIssue({
    required this.code,
    required this.message,
    this.nodeId,
  });

  final FlowStructureIssueCode code;
  final String? nodeId;
  final String message;

  @override
  String toString() =>
      'FlowStructureIssue(${code.name}${nodeId == null ? '' : ', $nodeId'}: $message)';
}

/// How a Story is shown to the learner (Build 256 Revision 3 follow-up).
enum FlowPresentation {
  /// One item per page, as a practice Round shows its exercises.
  step('step'),

  /// Finished items stay on the page, the next one appears below and the
  /// page scrolls to it; one item is active at a time.
  scroll('scroll');

  const FlowPresentation(this.serialized);
  final String serialized;

  static FlowPresentation? tryParse(Object? value) {
    for (final presentation in values) {
      if (presentation.serialized == value) return presentation;
    }
    return null;
  }
}

final class ContentFlow {
  ContentFlow({
    required this.startNodeId,
    required List<FlowNode> nodes,
    this.presentation = FlowPresentation.step,
  }) : nodes = List.unmodifiable(nodes);

  /// A flow that visits [nodes] in order with `next` transitions. Nodes are
  /// given without transitions; the last one ends the flow.
  factory ContentFlow.linear(
    List<FlowNode> nodes, {
    FlowPresentation presentation = FlowPresentation.step,
  }) {
    if (nodes.isEmpty) {
      return ContentFlow(
        startNodeId: '',
        nodes: const [],
        presentation: presentation,
      );
    }
    return ContentFlow(
      startNodeId: nodes.first.id,
      presentation: presentation,
      nodes: [
        for (var i = 0; i < nodes.length; i++)
          nodes[i].copyWith(
            transitions: i + 1 < nodes.length
                ? [FlowTransition.next(nodes[i + 1].id)]
                : const [],
          ),
      ],
    );
  }

  final String startNodeId;
  final List<FlowNode> nodes;

  /// Omitted in JSON when it is the default, [FlowPresentation.step].
  final FlowPresentation presentation;

  Map<String, dynamic> toJson() => {
    'start': startNodeId,
    'nodes': nodes.map((node) => node.toJson()).toList(),
    if (presentation != FlowPresentation.step)
      'presentation': presentation.serialized,
  };

  /// Parses the structure only; [check] reports semantic problems such as
  /// unknown targets so a Course stays readable and the Audit can name them.
  factory ContentFlow.fromJson(Map<String, dynamic> j) {
    _refuseUnknownFlowKeys(j, const {'start', 'nodes', 'presentation'}, 'flow');
    final rawNodes = j['nodes'];
    if (rawNodes is! List) {
      throw const FormatException('flow.nodes must be a list.');
    }
    final presentation = j.containsKey('presentation')
        ? FlowPresentation.tryParse(j['presentation'])
        : FlowPresentation.step;
    if (presentation == null) {
      throw FormatException(
        'flow.presentation “${j['presentation']}” must be step or scroll.',
      );
    }
    return ContentFlow(
      startNodeId: _requiredFlowString(j, 'start', 'flow'),
      presentation: presentation,
      nodes: [
        for (final node in rawNodes)
          if (node is Map)
            FlowNode.fromJson(Map<String, dynamic>.from(node))
          else
            throw const FormatException('flow.nodes must contain objects.'),
      ],
    );
  }

  FlowNode? nodeById(String id) {
    for (final node in nodes) {
      if (node.id == id) return node;
    }
    return null;
  }

  /// The IDs reachable from the start by following any transition.
  Set<String> reachableNodeIds() {
    final reachable = <String>{};
    final pending = <String>[startNodeId];
    while (pending.isNotEmpty) {
      final id = pending.removeLast();
      if (!reachable.add(id)) continue;
      final node = nodeById(id);
      if (node == null) continue;
      for (final transition in node.transitions) {
        pending.add(transition.targetNodeId);
      }
    }
    return reachable;
  }

  /// Structural problems, independent of what the referenced Content holds.
  List<FlowStructureIssue> check() {
    final issues = <FlowStructureIssue>[];
    void add(FlowStructureIssueCode code, String message, [String? nodeId]) =>
        issues.add(
          FlowStructureIssue(code: code, message: message, nodeId: nodeId),
        );

    if (nodes.isEmpty) {
      add(FlowStructureIssueCode.emptyFlow, 'The flow has no nodes.');
      return issues;
    }
    final ids = <String>{};
    for (final node in nodes) {
      if (node.id.trim().isEmpty) {
        add(FlowStructureIssueCode.blankNodeId, 'A node has no ID.');
      } else if (!ids.add(node.id)) {
        add(
          FlowStructureIssueCode.duplicateNodeId,
          'Node ID “${node.id}” is used more than once.',
          node.id,
        );
      }
      if (node.contentId.trim().isEmpty) {
        add(
          FlowStructureIssueCode.blankContentId,
          'Node “${node.id}” names no Content.',
          node.id,
        );
      }
    }
    if (!ids.contains(startNodeId)) {
      add(
        FlowStructureIssueCode.startNodeMissing,
        'The start node “$startNodeId” does not exist.',
      );
    }
    for (final node in nodes) {
      var nextCount = 0;
      for (final transition in node.transitions) {
        if (!ids.contains(transition.targetNodeId)) {
          add(
            FlowStructureIssueCode.targetNodeUnknown,
            'Node “${node.id}” leads to the unknown node “${transition.targetNodeId}”.',
            node.id,
          );
        }
        switch (transition.trigger) {
          case FlowTrigger.next:
            nextCount++;
            if (transition.targetNodeId == node.id) {
              add(
                FlowStructureIssueCode.nextSelfLoop,
                'Node “${node.id}” leads unconditionally to itself.',
                node.id,
              );
            }
          case FlowTrigger.onCorrect:
          case FlowTrigger.onIncorrect:
            if (node.kind != FlowNodeKind.exercise) {
              add(
                FlowStructureIssueCode.contentNodeBranches,
                'Content node “${node.id}” cannot branch on ${transition.trigger.serialized}; only an exercise node has an answer.',
                node.id,
              );
            }
          case FlowTrigger.onChoice:
            if (node.kind != FlowNodeKind.exercise) {
              add(
                FlowStructureIssueCode.contentNodeBranches,
                'Content node “${node.id}” cannot branch on a choice; only an exercise node has one.',
                node.id,
              );
            }
            if ((transition.choiceItemId ?? '').trim().isEmpty) {
              add(
                FlowStructureIssueCode.choiceWithoutItem,
                'An onChoice transition of node “${node.id}” names no chosen item.',
                node.id,
              );
            }
          case FlowTrigger.conditional:
            final condition = transition.condition;
            if (condition == null) {
              add(
                FlowStructureIssueCode.conditionalWithoutCondition,
                'A conditional transition of node “${node.id}” has no condition.',
                node.id,
              );
            } else if (!ids.contains(condition.nodeId)) {
              add(
                FlowStructureIssueCode.conditionNodeUnknown,
                'A condition of node “${node.id}” refers to the unknown node “${condition.nodeId}”.',
                node.id,
              );
            }
        }
        if (transition.trigger != FlowTrigger.onChoice &&
            transition.choiceItemId != null) {
          add(
            FlowStructureIssueCode.choiceItemOnOtherTrigger,
            'A ${transition.trigger.serialized} transition of node “${node.id}” names a chosen item, which only onChoice uses.',
            node.id,
          );
        }
        if (transition.trigger != FlowTrigger.conditional &&
            transition.condition != null) {
          add(
            FlowStructureIssueCode.conditionOnOtherTrigger,
            'A ${transition.trigger.serialized} transition of node “${node.id}” carries a condition, which only conditional uses.',
            node.id,
          );
        }
      }
      if (nextCount > 1) {
        add(
          FlowStructureIssueCode.duplicateNext,
          'Node “${node.id}” has ${nextCount.toString()} unconditional next transitions; at most one is allowed.',
          node.id,
        );
      }
    }
    if (ids.contains(startNodeId)) {
      final reachable = reachableNodeIds();
      for (final node in nodes) {
        if (!reachable.contains(node.id)) {
          add(
            FlowStructureIssueCode.unreachableNode,
            'Node “${node.id}” cannot be reached from the start.',
            node.id,
          );
        }
      }
    }
    return issues;
  }

  bool get isValid => check().isEmpty;

  /// True when any node has a transition other than `next`.
  bool get hasBranching => nodes.any((node) => node.hasBranching);

  /// A valid flow that visits every node exactly once along `next`
  /// transitions from the start and ends at a node without transitions.
  bool get isLinear => linearNodeIds() != null;

  /// The visiting order of a linear flow, or null when the flow is not linear
  /// (branching, cycles, several transitions on a node, structural issues).
  List<String>? linearNodeIds() {
    if (!isValid || hasBranching) return null;
    final order = <String>[];
    final seen = <String>{};
    var current = nodeById(startNodeId);
    while (current != null) {
      if (!seen.add(current.id)) return null;
      order.add(current.id);
      if (current.transitions.length > 1) return null;
      final next = current.nextNodeId;
      current = next == null ? null : nodeById(next);
    }
    return order.length == nodes.length ? order : null;
  }
}
