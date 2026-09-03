import 'dart:math';

import '../models/course_models.dart';
import '../models/exercise_authoring.dart';
import 'authoring_duplication_service.dart';

class GuidebookGenerationException implements Exception {
  const GuidebookGenerationException(this.message);
  final String message;

  @override
  String toString() => message;
}

class GuidebookRoundPlan {
  const GuidebookRoundPlan({
    required this.index,
    required this.difficulty,
    required this.title,
    required this.presetIds,
  });

  final int index;
  final double difficulty;
  final String title;
  final List<String> presetIds;
}

class GuidebookGenerationPlan {
  const GuidebookGenerationPlan({
    required this.roundCount,
    required this.exercisesPerRound,
    required this.rounds,
  });

  final int roundCount;
  final int exercisesPerRound;
  final List<GuidebookRoundPlan> rounds;

  int get totalExercises => roundCount * exercisesPerRound;

  Map<String, int> get presetDistribution {
    final result = <String, int>{};
    for (final preset in rounds.expand((round) => round.presetIds)) {
      result[preset] = (result[preset] ?? 0) + 1;
    }
    return result;
  }
}

class GuidebookRoundGenerator {
  GuidebookRoundGenerator({int randomSeed = 0, AuthoringIdGenerator? draftIds})
    : _randomSeed = randomSeed,
      _draftIds = draftIds ?? TimestampAuthoringIdGenerator();

  static const int defaultRoundCount = 6;
  static const int defaultExercisesPerRound = 8;
  static const int maximumRoundCount = 12;
  static const int maximumExercisesPerRound = 15;

  final int _randomSeed;
  final AuthoringIdGenerator _draftIds;

  GuidebookGenerationPlan plan(
    Guidebook guidebook, {
    int roundCount = defaultRoundCount,
    int exercisesPerRound = defaultExercisesPerRound,
  }) {
    _validateCounts(roundCount, exercisesPerRound);
    final material = _GuidebookMaterial.from(guidebook);
    if (material.pairs.length < 3) {
      throw const GuidebookGenerationException(
        'Add at least three target/source vocabulary pairs to this Lesson Guidebook first. Example: casa = house.',
      );
    }
    final random = Random(_randomSeed);
    final rounds = <GuidebookRoundPlan>[];
    for (var i = 0; i < roundCount; i++) {
      final difficulty = roundCount == 1 ? .5 : i / (roundCount - 1);
      final pool = _poolFor(
        difficulty,
        hasExamples: material.hasExamples,
        hasMatchedExamples: material.hasMatchedExamples,
      );
      final offset = random.nextInt(pool.length);
      final presets = [
        for (var j = 0; j < exercisesPerRound; j++)
          pool[(j + offset + i) % pool.length],
      ];
      final pair = material.pairs[i % material.pairs.length];
      final phase = difficulty < .34
          ? 'Foundations'
          : difficulty < .67
          ? 'Practice'
          : 'Use in context';
      rounds.add(
        GuidebookRoundPlan(
          index: i,
          difficulty: difficulty,
          title: '$phase: ${pair.target}',
          presetIds: List.unmodifiable(presets),
        ),
      );
    }
    return GuidebookGenerationPlan(
      roundCount: roundCount,
      exercisesPerRound: exercisesPerRound,
      rounds: List.unmodifiable(rounds),
    );
  }

  List<LearningRound> createDrafts(
    Guidebook guidebook,
    GuidebookGenerationPlan plan,
  ) {
    final material = _GuidebookMaterial.from(guidebook);
    if (material.pairs.length < 3) {
      throw const GuidebookGenerationException(
        'GuideBook material is insufficient for generation.',
      );
    }
    final random = Random(_randomSeed);
    final duplication = AuthoringDuplicationService(ids: _draftIds);
    final sourceRefs = guidebook.content
        .map((content) => content.id)
        .take(6)
        .toList(growable: false);
    return [
      for (final roundPlan in plan.rounds)
        _createRound(roundPlan, material, sourceRefs, random, duplication),
    ];
  }

  LearningRound _createRound(
    GuidebookRoundPlan plan,
    _GuidebookMaterial material,
    List<String> sourceRefs,
    Random random,
    AuthoringDuplicationService duplication,
  ) {
    final exercises = <Exercise>[];
    for (var i = 0; i < plan.presetIds.length; i++) {
      final pair = material.pairs[(plan.index + i) % material.pairs.length];
      final template = _exerciseTemplate(
        plan.presetIds[i],
        pair,
        material,
        plan.difficulty,
        i,
        random,
      );
      exercises.add(duplication.duplicateExercise(template));
    }
    final content = <LearningContent>[
      if (plan.index == 0)
        LearningContent(
          id: _draftIds.next('intro'),
          kind: 'explanation',
          required: false,
          role: 'lesson_intro',
          text:
              'Before you start: ${material.overview.isEmpty ? 'review the Lesson GuideBook material' : material.overview}.',
          sourceRefs: sourceRefs,
        ),
      for (final exercise in exercises)
        LearningContent(
          id: exercise.id,
          kind: exercise.editorTemplate == 'flashcard'
              ? 'presentation'
              : 'exercise',
          editorTemplate: exercise.editorTemplate,
          exercise: exercise.editorTemplate == 'flashcard' ? null : exercise,
          presentation: exercise.editorTemplate == 'flashcard'
              ? Presentation.fromLegacyExercise(exercise)
              : null,
          sourceRefs: sourceRefs,
        ),
    ];
    return LearningRound(
      id: _draftIds.next('round'),
      title: plan.title,
      content: content,
    );
  }

  Exercise _exerciseTemplate(
    String preset,
    _GuidebookPair pair,
    _GuidebookMaterial material,
    double difficulty,
    int position,
    Random random,
  ) {
    final distractorCount = difficulty < .34 ? 1 : 2;
    final targetDistractors = _distractors(
      material.pairs.map((item) => item.target),
      pair.target,
      distractorCount,
    );
    Exercise select({
      required String type,
      required String prompt,
      required String question,
      required List<String> answers,
      String? tts,
    }) {
      final shuffled = [...answers]..shuffle(random);
      return _legacy(
        type: type,
        prompt: prompt,
        question: question,
        answers: shuffled,
        correct: shuffled.indexOf(answers.first),
        tts: tts,
      );
    }

    switch (preset) {
      case 'choice':
        return select(
          type: 'choice',
          prompt: 'How do you say “${pair.source}”?',
          question: '',
          answers: [pair.target, ...targetDistractors],
        );
      case 'gap_choice':
        final contextual = material.pairWithExample(position);
        final example = contextual.example;
        return select(
          type: 'gap_choice',
          prompt: '',
          question: example.replaceFirst(
            RegExp(RegExp.escape(contextual.pair.target), caseSensitive: false),
            '___',
          ),
          answers: [
            contextual.pair.target,
            ..._distractors(
              material.pairs.map((item) => item.target),
              contextual.pair.target,
              distractorCount,
            ),
          ],
        );
      case 'listening_choice':
        return select(
          type: 'listening_choice',
          prompt: '',
          question: 'What do you hear?',
          answers: [pair.target, ...targetDistractors],
          tts: pair.target,
        );
      case 'word_match':
      case 'audio_match':
        final pairs = [
          for (var i = 0; i < 3; i++)
            material.pairs[(position + i) % material.pairs.length],
        ];
        return _legacy(
          type: preset,
          prompt: preset == 'audio_match'
              ? 'Listen and match each expression with its meaning.'
              : 'Match each expression with its meaning.',
          pairs: [
            for (final item in pairs) [item.target, item.source],
          ],
        );
      case 'build_translation':
        final answer = _words(pair.target);
        return _legacy(
          type: preset,
          prompt: 'Build the translation of “${pair.source}”.',
          tokens: answer,
          orderAnswer: answer,
        );
      case 'word_order':
        final example = material.examples[position % material.examples.length];
        final answer = _words(example);
        return _legacy(
          type: preset,
          prompt: 'Put the GuideBook sentence in order.',
          tokens: answer,
          orderAnswer: answer,
        );
      case 'contextual_comprehension':
        final contextual = material.pairWithExample(position);
        return select(
          type: preset,
          prompt: contextual.example,
          question:
              'Which expression in this context means “${contextual.pair.source}”?',
          answers: [
            contextual.pair.target,
            ..._distractors(
              material.pairs.map((item) => item.target),
              contextual.pair.target,
              distractorCount,
            ),
          ],
        );
      case 'type_translation':
        return _legacy(
          type: preset,
          prompt: pair.source,
          accepted: [pair.target],
          hint: difficulty < .67 ? 'Use the Lesson GuideBook vocabulary.' : '',
        );
      default:
        throw StateError('Unsupported generated preset: $preset');
    }
  }

  Exercise _legacy({
    required String type,
    String prompt = '',
    String question = '',
    List<String> answers = const [],
    int? correct,
    String? tts,
    List<String> accepted = const [],
    List<String> tokens = const [],
    List<String> orderAnswer = const [],
    List<List<String>> pairs = const [],
    String hint = '',
  }) => Exercise(
    id: 'draft_template',
    type: type,
    prompt: prompt,
    question: question,
    answers: answers,
    correct: correct,
    tts: tts,
    accepted: accepted,
    tokens: tokens,
    orderAnswer: orderAnswer,
    pairs: pairs,
    hint: hint,
    icons: const [],
  );

  List<String> _poolFor(
    double difficulty, {
    required bool hasExamples,
    required bool hasMatchedExamples,
  }) {
    final candidates = difficulty < .34
        ? [
            'choice',
            if (hasMatchedExamples) 'gap_choice',
            'listening_choice',
            'word_match',
          ]
        : difficulty < .67
        ? [
            'build_translation',
            if (hasExamples) 'word_order',
            'audio_match',
            if (hasMatchedExamples) 'contextual_comprehension',
          ]
        : [
            'type_translation',
            if (hasMatchedExamples) 'contextual_comprehension',
            'build_translation',
            if (hasExamples) 'word_order',
          ];
    for (final preset in candidates) {
      if (ExercisePresetRegistry.byId(preset) == null) {
        throw StateError('Generator preset is not registered: $preset');
      }
    }
    return candidates;
  }

  List<String> _distractors(Iterable<String> values, String answer, int count) {
    final seen = <String>{_normalize(answer)};
    final result = <String>[];
    for (final value in values) {
      if (seen.add(_normalize(value))) result.add(value);
      if (result.length == count) break;
    }
    return result;
  }

  List<String> _words(String value) => value
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .toList(growable: false);

  void _validateCounts(int rounds, int exercises) {
    if (rounds < 1 || rounds > maximumRoundCount) {
      throw ArgumentError.value(
        rounds,
        'roundCount',
        'Choose between 1 and $maximumRoundCount Rounds.',
      );
    }
    if (exercises < 1 || exercises > maximumExercisesPerRound) {
      throw ArgumentError.value(
        exercises,
        'exercisesPerRound',
        'Choose between 1 and $maximumExercisesPerRound exercises per Round.',
      );
    }
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^\p{L}\p{N}]+', unicode: true), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

class _GuidebookMaterial {
  const _GuidebookMaterial({
    required this.overview,
    required this.pairs,
    required this.examples,
  });

  factory _GuidebookMaterial.from(Guidebook guidebook) {
    final pairs = <_GuidebookPair>[];
    final seen = <String>{};
    for (final raw in guidebook.vocabulary) {
      final parsed = _GuidebookPair.parse(raw);
      if (parsed != null &&
          seen.add(
            '${GuidebookRoundGenerator._normalize(parsed.target)}|${GuidebookRoundGenerator._normalize(parsed.source)}',
          )) {
        pairs.add(parsed);
      }
    }
    final examples = {
      ...guidebook.examples.map((value) => value.trim()),
      ...guidebook.expressions.map((value) => value.trim()),
    }.where((value) => value.isNotEmpty).toList(growable: false);
    return _GuidebookMaterial(
      overview: guidebook.overview.trim(),
      pairs: pairs,
      examples: examples,
    );
  }

  final String overview;
  final List<_GuidebookPair> pairs;
  final List<String> examples;

  bool get hasExamples => examples.isNotEmpty;

  bool get hasMatchedExamples => pairs.any(
    (pair) => examples.any(
      (example) => GuidebookRoundGenerator._normalize(
        example,
      ).contains(GuidebookRoundGenerator._normalize(pair.target)),
    ),
  );

  String? exampleContaining(String target) {
    final needle = GuidebookRoundGenerator._normalize(target);
    for (final example in examples) {
      if (GuidebookRoundGenerator._normalize(example).contains(needle)) {
        return example;
      }
    }
    return null;
  }

  ({_GuidebookPair pair, String example}) pairWithExample(int offset) {
    final matches = <({_GuidebookPair pair, String example})>[];
    for (final pair in pairs) {
      final example = exampleContaining(pair.target);
      if (example != null) matches.add((pair: pair, example: example));
    }
    if (matches.isEmpty) {
      throw const GuidebookGenerationException(
        'A GuideBook example must contain at least one vocabulary expression.',
      );
    }
    return matches[offset % matches.length];
  }
}

class _GuidebookPair {
  const _GuidebookPair(this.target, this.source);

  static _GuidebookPair? parse(String raw) {
    final line = raw.trim();
    for (final separator in const [' = ', ' → ', ' - ', ':']) {
      final at = line.indexOf(separator);
      if (at < 1) continue;
      final target = line.substring(0, at).trim();
      final source = line.substring(at + separator.length).trim();
      if (target.isNotEmpty && source.isNotEmpty) {
        return _GuidebookPair(target, source);
      }
    }
    return null;
  }

  final String target;
  final String source;
}
