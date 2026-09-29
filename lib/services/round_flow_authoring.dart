import '../models/course_models.dart';

/// How authoring keeps a Round's content `flow` (Build 256 Session 4).
///
/// A Story is a Round with a flow (plan A.7). The editor, Move/Copy and
/// duplication rebuild Rounds from their content; every rebuild must carry
/// the flow, otherwise a Story silently becomes a practice Round. A linear
/// flow follows the content order, so it is regenerated from the edited
/// content; a branching flow is authored outside QQL's forms and is kept
/// exactly as it is (the Audit names any target it no longer finds). The
/// Story options (title, scroll log, read-aloud; Build 256 Revision 5) and
/// each exercise node's audio dependence travel with every rebuild.
abstract final class RoundFlowAuthoring {
  /// The linear flow that plays [content] in authored order. Node IDs are
  /// the content IDs, which are unique within a Round; the exercises whose
  /// content ID is in [requiresAudio] need the Story's audio.
  static ContentFlow linearFor(
    List<LearningContent> content, {
    FlowPresentation presentation = FlowPresentation.step,
    String title = '',
    FlowLog log = FlowLog.all,
    FlowReadAloud readAloud = FlowReadAloud.automatic,
    Set<String> requiresAudio = const {},
  }) => ContentFlow.linear(
    [
      for (final entry in content)
        FlowNode(
          id: entry.id,
          kind: entry.exercise != null
              ? FlowNodeKind.exercise
              : FlowNodeKind.content,
          contentId: entry.id,
          // A presentation (a dialogue line, a cover) is never skipped, so
          // only a scorable exercise can depend on the Story's audio.
          requiresAudio: _scorable(entry) && requiresAudio.contains(entry.id),
        ),
    ],
    presentation: presentation,
    title: title,
    log: log,
    readAloud: readAloud,
  );

  /// The flow a Round keeps after its content became [content]: none stays
  /// none, a linear flow follows the new order (keeping its presentation),
  /// a branching flow is kept.
  static ContentFlow? forContent(
    ContentFlow? previous,
    List<LearningContent> content,
  ) {
    if (previous == null) return null;
    if (previous.isLinear) {
      return linearFor(
        content,
        presentation: previous.presentation,
        title: previous.title,
        log: previous.log,
        readAloud: previous.readAloud,
        requiresAudio: previous.audioDependentContentIds,
      );
    }
    return previous;
  }

  /// The same flow shown the other way (step by step or scrolling).
  static ContentFlow withPresentation(
    ContentFlow flow,
    FlowPresentation presentation,
  ) => flow.copyWith(presentation: presentation);

  /// The same flow with other Story options (Build 256 Revision 5).
  static ContentFlow withStoryOptions(
    ContentFlow flow, {
    String? title,
    FlowLog? log,
    FlowReadAloud? readAloud,
  }) => flow.copyWith(title: title, log: log, readAloud: readAloud);

  /// The same flow with the node of [entry] marked as needing the Story's
  /// audio, or not (Build 256 Revision 5). A presentation is never skipped,
  /// so the flow is returned unchanged for one.
  static ContentFlow withAudioDependence(
    ContentFlow flow,
    LearningContent entry, {
    required bool requiresAudio,
  }) => !_scorable(entry)
      ? flow
      : flow.copyWith(
          nodes: [
            for (final node in flow.nodes)
              node.contentId == entry.id && node.kind == FlowNodeKind.exercise
                  ? node.copyWith(requiresAudio: requiresAudio)
                  : node,
          ],
        );

  static bool _scorable(LearningContent entry) =>
      entry.exercise != null &&
      entry.exercise!.primitive != ExercisePrimitive.presentation;

  /// The same flow with every content reference (and the node IDs that
  /// equal a content ID) renamed through [remap], for copies that give the
  /// content fresh IDs. Transitions name nodes, so they are renamed with
  /// their nodes.
  static ContentFlow? remapped(ContentFlow? flow, Map<String, String> remap) {
    if (flow == null) return null;
    String node(String id) => remap[id] ?? id;
    return ContentFlow(
      startNodeId: node(flow.startNodeId),
      presentation: flow.presentation,
      title: flow.title,
      log: flow.log,
      readAloud: flow.readAloud,
      nodes: [
        for (final entry in flow.nodes)
          FlowNode(
            id: node(entry.id),
            kind: entry.kind,
            contentId: remap[entry.contentId] ?? entry.contentId,
            requiresAudio: entry.requiresAudio,
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
