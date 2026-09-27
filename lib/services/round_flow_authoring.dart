import '../models/course_models.dart';

/// How authoring keeps a Round's content `flow` (Build 256 Session 4).
///
/// A Story is a Round with a flow (plan A.7). The editor, Move/Copy and
/// duplication rebuild Rounds from their content; every rebuild must carry
/// the flow, otherwise a Story silently becomes a practice Round. A linear
/// flow follows the content order, so it is regenerated from the edited
/// content; a branching flow is authored outside QQL's forms and is kept
/// exactly as it is (the Audit names any target it no longer finds).
abstract final class RoundFlowAuthoring {
  /// The linear flow that plays [content] in authored order. Node IDs are
  /// the content IDs, which are unique within a Round.
  static ContentFlow linearFor(List<LearningContent> content) =>
      ContentFlow.linear([
        for (final entry in content)
          FlowNode(
            id: entry.id,
            kind: entry.exercise != null
                ? FlowNodeKind.exercise
                : FlowNodeKind.content,
            contentId: entry.id,
          ),
      ]);

  /// The flow a Round keeps after its content became [content]: none stays
  /// none, a linear flow follows the new order, a branching flow is kept.
  static ContentFlow? forContent(
    ContentFlow? previous,
    List<LearningContent> content,
  ) {
    if (previous == null) return null;
    if (previous.isLinear) return linearFor(content);
    return previous;
  }

  /// The same flow with every content reference (and the node IDs that
  /// equal a content ID) renamed through [remap], for copies that give the
  /// content fresh IDs. Transitions name nodes, so they are renamed with
  /// their nodes.
  static ContentFlow? remapped(ContentFlow? flow, Map<String, String> remap) {
    if (flow == null) return null;
    String node(String id) => remap[id] ?? id;
    return ContentFlow(
      startNodeId: node(flow.startNodeId),
      nodes: [
        for (final entry in flow.nodes)
          FlowNode(
            id: node(entry.id),
            kind: entry.kind,
            contentId: remap[entry.contentId] ?? entry.contentId,
            transitions: [
              for (final transition in entry.transitions)
                FlowTransition(
                  trigger: transition.trigger,
                  targetNodeId: node(transition.targetNodeId),
                  choiceItemId: transition.choiceItemId == null
                      ? null
                      : remap[transition.choiceItemId] ??
                            transition.choiceItemId,
                  condition: transition.condition == null
                      ? null
                      : FlowCondition(
                          kind: transition.condition!.kind,
                          nodeId: node(transition.condition!.nodeId),
                          itemId: transition.condition!.itemId == null
                              ? null
                              : remap[transition.condition!.itemId] ??
                                    transition.condition!.itemId,
                        ),
                ),
            ],
          ),
      ],
    );
  }
}
