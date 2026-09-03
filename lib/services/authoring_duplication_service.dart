import '../models/course_models.dart';

abstract interface class AuthoringIdGenerator {
  String next(String kind);
}

class TimestampAuthoringIdGenerator implements AuthoringIdGenerator {
  TimestampAuthoringIdGenerator({int? seed})
    : _seed = seed ?? DateTime.now().microsecondsSinceEpoch;

  final int _seed;
  int _sequence = 0;

  @override
  String next(String kind) => 'custom_${kind}_${_seed}_${_sequence++}';
}

/// Creates independent authoring copies and remaps every owned identity.
///
/// Asset paths and references outside the duplicated subtree remain shared.
class AuthoringDuplicationService {
  AuthoringDuplicationService({AuthoringIdGenerator? ids})
    : _ids = ids ?? TimestampAuthoringIdGenerator();

  final AuthoringIdGenerator _ids;

  Exercise duplicateExercise(Exercise source) {
    final remap = <String, String>{source.id: _ids.next('exercise')};
    _allocateExerciseItems(source, remap);
    return _copyExercise(source, remap);
  }

  LearningRound duplicateRound(LearningRound source) {
    final remap = <String, String>{source.id: _ids.next('round')};
    for (final content in source.content) {
      _allocateContent(content, remap);
    }
    return _copyRound(source, remap);
  }

  Lesson duplicateLesson(Lesson source) {
    final remap = <String, String>{
      source.lessonId: _ids.next('lesson'),
      source.duel.id: _ids.next('duel'),
    };
    for (final content in source.guidebook.content) {
      _allocateContent(content, remap);
    }
    for (final round in source.rounds) {
      remap.putIfAbsent(round.id, () => _ids.next('round'));
      for (final content in round.content) {
        _allocateContent(content, remap);
      }
    }
    return Lesson(
      lessonId: remap[source.lessonId]!,
      title: source.title,
      rounds: [for (final round in source.rounds) _copyRound(round, remap)],
      section: source.section,
      sectionName: source.sectionName,
      themeIconAsset: source.themeIconAsset,
      guidebook: Guidebook(
        content: [
          for (final content in source.guidebook.content)
            _copyContent(content, remap),
        ],
      ),
      duel: Duel(id: remap[source.duel.id]!, title: source.duel.title),
    );
  }

  void _allocateContent(LearningContent content, Map<String, String> remap) {
    remap.putIfAbsent(content.id, () => _ids.next('content'));
    final exercise = content.exercise;
    if (exercise != null) {
      remap.putIfAbsent(
        exercise.id,
        () => exercise.id == content.id
            ? remap[content.id]!
            : _ids.next('exercise'),
      );
      _allocateExerciseItems(exercise, remap);
    }
  }

  void _allocateExerciseItems(Exercise exercise, Map<String, String> remap) {
    for (final item in exercise.interaction.items) {
      remap.putIfAbsent(item.id, () => _ids.next('item'));
    }
  }

  LearningRound _copyRound(LearningRound source, Map<String, String> remap) =>
      LearningRound(
        id: remap[source.id]!,
        title: source.title,
        visualType: source.visualType,
        content: [
          for (final content in source.content) _copyContent(content, remap),
        ],
      );

  LearningContent _copyContent(
    LearningContent source,
    Map<String, String> remap,
  ) => LearningContent(
    id: remap[source.id]!,
    kind: source.kind,
    required: source.required,
    editorTemplate: source.editorTemplate,
    role: source.role,
    exercise: source.exercise == null
        ? null
        : _copyExercise(source.exercise!, remap),
    presentation: source.presentation == null
        ? null
        : Presentation(
            content: [
              for (final element in source.presentation!.content)
                _copyPrompt(element),
            ],
            actions: [...source.presentation!.actions],
          ),
    text: source.text,
    sourceRefs: [
      for (final reference in source.sourceRefs) remap[reference] ?? reference,
    ],
  );

  Exercise _copyExercise(Exercise source, Map<String, String> remap) {
    String mapped(String id) => remap[id] ?? id;
    return Exercise.v2(
      id: mapped(source.id),
      editorTemplate: source.editorTemplate,
      promptElements: [
        for (final element in source.promptElements) _copyPrompt(element),
      ],
      interaction: ExerciseInteraction(
        kind: source.interaction.kind,
        inputType: source.interaction.inputType,
        minSelections: source.interaction.minSelections,
        maxSelections: source.interaction.maxSelections,
        items: [
          for (final item in source.interaction.items)
            ExerciseItem(
              id: mapped(item.id),
              content: [
                for (final element in item.content) _copyPrompt(element),
              ],
            ),
        ],
      ),
      evaluation: ExerciseEvaluation(
        kind: source.evaluation.kind,
        correctItemIds: source.evaluation.correctItemIds.map(mapped).toList(),
        accepted: [...source.evaluation.accepted],
        correctOrder: source.evaluation.correctOrder.map(mapped).toList(),
        pairs: [
          for (final pair in source.evaluation.pairs)
            [for (final id in pair) mapped(id)],
        ],
        normalization: {...source.evaluation.normalization},
      ),
      hint: source.hint,
      feedback: {...source.feedback},
      missingWords: [...source.missingWords],
    );
  }

  PromptElement _copyPrompt(PromptElement source) => PromptElement(
    role: source.role,
    type: source.type,
    text: source.text,
    asset: source.asset,
    speaker: source.speaker,
  );
}
