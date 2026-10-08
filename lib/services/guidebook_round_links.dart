import '../models/course_models.dart';

/// How a Lesson's Rounds follow its GuideBook (Build 266, GuideBook Modules;
/// pure Dart): a Round's focus module and supporting modules, and the
/// `sourceRefs` of its content, which name GuideBook entries.
abstract final class GuidebookRoundLinks {
  /// [rounds] after their Lesson's GuideBook changed from [before] to
  /// [after]: a Round loses its link to a module that is gone, and its
  /// content loses the `sourceRefs` that named a removed entry. A reference
  /// to anything that was never in the GuideBook is kept. A Round that
  /// changes nothing is the same object.
  static List<LearningRound> afterGuidebookSave(
    Guidebook before,
    Guidebook after,
    List<LearningRound> rounds,
  ) {
    final removed = before.ids.difference(after.ids);
    if (removed.isEmpty) return rounds;
    return [for (final round in rounds) _without(round, removed)];
  }

  static LearningRound _without(LearningRound round, Set<String> removed) {
    final focus = round.focusModuleId;
    final losesFocus = focus != null && removed.contains(focus);
    final supporting = [
      for (final id in round.supportingModuleIds)
        if (!removed.contains(id)) id,
    ];
    final losesSupporting =
        supporting.length != round.supportingModuleIds.length;
    final losesRefs = round.content.any(
      (content) => content.sourceRefs.any(removed.contains),
    );
    if (!losesFocus && !losesSupporting && !losesRefs) return round;
    final json = round.toJson();
    json.remove('focusModuleId');
    json.remove('supportingModuleIds');
    if (!losesFocus && focus != null) json['focusModuleId'] = focus;
    if (supporting.isNotEmpty) json['supportingModuleIds'] = supporting;
    json['content'] = [
      for (final content in round.content)
        if (content.sourceRefs.any(removed.contains))
          {
            ...content.toJson()..remove('sourceRefs'),
            if (content.sourceRefs.any((ref) => !removed.contains(ref)))
              'sourceRefs': [
                for (final ref in content.sourceRefs)
                  if (!removed.contains(ref)) ref,
              ],
          }
        else
          content.toJson(),
    ];
    return LearningRound.fromJson(json);
  }

  /// How many of [rounds] focus on [moduleId].
  static int focusCount(Iterable<LearningRound> rounds, String moduleId) =>
      rounds.where((round) => round.focusModuleId == moduleId).length;
}
