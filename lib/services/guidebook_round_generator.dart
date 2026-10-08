import 'dart:math';

import '../models/course_models.dart';
import '../models/exercise_authoring.dart';
import '../models/guidebook_text.dart';
import 'authoring_duplication_service.dart';
import 'exercise_draft_builder.dart';
import 'round_type_compatibility.dart';
import 'round_flow_authoring.dart';

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
    this.roundType = RoundType.practice,
    this.focusModuleId,
    this.reviewPositions = const [],
    this.opensModule = false,
  });

  final int index;
  final double difficulty;
  final String title;
  final List<String> presetIds;
  final RoundType roundType;

  /// The module these Rounds practise (Build 266 Revision 3).
  final String? focusModuleId;

  /// The exercises that review earlier modules of the Lesson: about a third
  /// of the Round, never the first exercise, none in a Lesson's first module.
  final List<int> reviewPositions;

  /// The first Round of a run, or with All modules of each module: it opens
  /// with a Before you start card holding a copy of the module's Overview.
  final bool opensModule;

  GuidebookRoundPlan withType(RoundType type, List<String> presets) =>
      GuidebookRoundPlan(
        index: index,
        difficulty: difficulty,
        title: title,
        presetIds: List.unmodifiable(presets),
        roundType: type,
        focusModuleId: focusModuleId,
        reviewPositions: reviewPositions,
        opensModule: opensModule,
      );
}

class GuidebookGenerationPlan {
  const GuidebookGenerationPlan({
    required this.roundCount,
    required this.exercisesPerRound,
    required this.rounds,
    this.focusModuleId,
    this.skippedModules = const [],
  });

  /// Rounds of one focus module, or with All modules Rounds per module.
  final int roundCount;
  final int exercisesPerRound;
  final List<GuidebookRoundPlan> rounds;

  /// The module chosen, or null for All modules, in order.
  final String? focusModuleId;

  /// With All modules: the titles of the modules left out, which have fewer
  /// than three Words & Expressions entries.
  final List<String> skippedModules;

  int get totalExercises => rounds.length * exercisesPerRound;

  Map<String, int> get presetDistribution {
    final result = <String, int>{};
    for (final preset in rounds.expand((round) => round.presetIds)) {
      result[preset] = (result[preset] ?? 0) + 1;
    }
    return result;
  }
}

/// The Round Wizard (Build 266 Revision 3, plan §7, owner decisions of
/// 5–8 October 2026): Rounds built from the modules of a Lesson GuideBook.
///
/// - A focus module, or All modules in order (each module its own curve:
///   Foundations, Practice, Use in context).
/// - About a third of each Round reviews the earlier modules of the same
///   Lesson, nearest first, never as the first exercise.
/// - The Context is shown with the learners'-language text, so each
///   exercise has one right answer; an entry that differs only by its
///   Context is a good wrong answer; two entries with the same Target, or
///   synonyms (same Source and Context), are never offered against each
///   other, and a typed answer accepts every synonym's Target.
/// - Sentences give Build the translation and Word order.
/// - A module with at least three pictured Words & Expressions adds Select
///   the image, Match pictures to words and Picture flashcard.
/// - Each Round records its focus and the earlier modules it used; each
///   exercise's `sourceRefs` are the entries of its question and answer.
class GuidebookRoundGenerator {
  GuidebookRoundGenerator({
    int randomSeed = 0,
    AuthoringIdGenerator? draftIds,
    DateTime Function()? now,
  }) : _randomSeed = randomSeed,
       _draftIds = draftIds ?? TimestampAuthoringIdGenerator(),
       _now = now ?? (() => DateTime.now().toUtc());

  static const int defaultRoundCount = 6;

  /// With All modules the count is Rounds per module: 3 is the smallest
  /// that gives each module the three phases.
  static const int defaultRoundsPerModule = 3;
  static const int defaultExercisesPerRound = 8;
  static const int maximumRoundCount = 12;
  static const int maximumRoundsPerRun = 24;
  static const int maximumExercisesPerRound = 15;

  /// A module needs this many Words & Expressions entries to be practised.
  static const int minimumWords = 3;

  /// The share of a Round that reviews earlier modules.
  static const double reviewShare = .3;

  final int _randomSeed;
  final AuthoringIdGenerator _draftIds;
  final DateTime Function() _now;

  static bool supportsType(RoundType type) => switch (type) {
    RoundType.discover ||
    RoundType.practice ||
    RoundType.sequence ||
    RoundType.listening ||
    RoundType.flashcard ||
    RoundType.test => true,
    RoundType.reading ||
    RoundType.story ||
    RoundType.timed ||
    RoundType.speak => false,
  };

  static String unsupportedReason(RoundType type) => switch (type) {
    RoundType.reading =>
      'GuideBook vocabulary alone cannot produce a verifiable reading-comprehension question. Create a Read Round manually.',
    RoundType.story =>
      'GuideBook vocabulary alone has no authored dialogue or narrative flow. Use New Round → Story.',
    RoundType.speak => 'Speak Rounds are coming soon.',
    RoundType.timed => 'Set a time limit in New Round to create a Timed Round.',
    _ => '',
  };

  /// Why [module] cannot be a focus, or null when it can.
  static String? moduleProblem(GuidebookModule module) =>
      module.words.length < minimumWords
      ? 'It has fewer than $minimumWords Words & Expressions entries.'
      : null;

  GuidebookRoundPlan changeType(
    Guidebook guidebook,
    GuidebookRoundPlan source,
    RoundType type,
  ) {
    if (!supportsType(type)) {
      throw GuidebookGenerationException(unsupportedReason(type));
    }
    final material = _Material(guidebook);
    final module = material.focusOf(source.focusModuleId);
    final pool = material.poolFor(module, source.difficulty, type);
    if (pool.isEmpty) {
      throw GuidebookGenerationException(
        'This GuideBook has no compatible candidates for ${type.name}.',
      );
    }
    final presets = [
      for (var i = 0; i < source.presetIds.length; i++)
        pool[(source.index + i) % pool.length],
    ];
    return source.withType(type, presets);
  }

  /// [source] practising [moduleId] instead (the plan's per-Round focus).
  GuidebookRoundPlan changeFocus(
    Guidebook guidebook,
    GuidebookRoundPlan source,
    String moduleId,
  ) {
    final material = _Material(guidebook);
    final module = material.moduleById(moduleId);
    if (module == null || moduleProblem(module) != null) {
      throw GuidebookGenerationException(
        module == null
            ? 'This module is no longer in the GuideBook.'
            : moduleProblem(module)!,
      );
    }
    final pool = material.poolFor(module, source.difficulty, source.roundType);
    final presets = [
      for (var i = 0; i < source.presetIds.length; i++)
        pool[(source.index + i) % pool.length],
    ];
    return GuidebookRoundPlan(
      index: source.index,
      difficulty: source.difficulty,
      title: '${_phase(source.difficulty)}: ${_moduleTitle(module)}',
      presetIds: List.unmodifiable(presets),
      roundType: source.roundType,
      focusModuleId: module.id,
      reviewPositions: material.reviewPositions(module, presets.length),
      opensModule: source.opensModule,
    );
  }

  /// [focusModuleId] null practises All modules, in order: [roundCount] is
  /// then the number of Rounds per module.
  GuidebookGenerationPlan plan(
    Guidebook guidebook, {
    String? focusModuleId,
    int roundCount = defaultRoundCount,
    int exercisesPerRound = defaultExercisesPerRound,
  }) {
    _validateCounts(roundCount, exercisesPerRound);
    final material = _Material(guidebook);
    final List<GuidebookModule> focus;
    final skipped = <String>[];
    if (focusModuleId != null) {
      final module = material.moduleById(focusModuleId);
      if (module == null) {
        throw const GuidebookGenerationException(
          'This module is no longer in the GuideBook.',
        );
      }
      if (moduleProblem(module) != null) {
        throw GuidebookGenerationException(
          'Add at least three Words & Expressions entries to the module '
          '“${_moduleTitle(module)}” first. Example: casa = house.',
        );
      }
      focus = [module];
    } else {
      focus = [];
      for (final module in guidebook.modules) {
        if (moduleProblem(module) == null) {
          focus.add(module);
        } else {
          skipped.add(_moduleTitle(module));
        }
      }
      if (focus.isEmpty) {
        throw const GuidebookGenerationException(
          'Add at least three Words & Expressions entries to a module of '
          'this Lesson GuideBook first. Example: casa = house.',
        );
      }
      if (focus.length * roundCount > maximumRoundsPerRun) {
        throw ArgumentError.value(
          roundCount,
          'roundCount',
          'At most $maximumRoundsPerRun Rounds per run. With ${focus.length} '
              'modules, choose up to '
              '${maximumRoundsPerRun ~/ focus.length} Rounds per module.',
        );
      }
    }
    final random = Random(_randomSeed);
    final rounds = <GuidebookRoundPlan>[];
    for (final module in focus) {
      for (var i = 0; i < roundCount; i++) {
        final difficulty = roundCount == 1 ? .5 : i / (roundCount - 1);
        final pool = material.poolFor(module, difficulty, RoundType.practice);
        final offset = random.nextInt(pool.length);
        final index = rounds.length;
        final presets = [
          for (var j = 0; j < exercisesPerRound; j++)
            pool[(j + offset + index) % pool.length],
        ];
        rounds.add(
          GuidebookRoundPlan(
            index: index,
            difficulty: difficulty,
            title: '${_phase(difficulty)}: ${_moduleTitle(module)}',
            presetIds: List.unmodifiable(presets),
            focusModuleId: module.id,
            reviewPositions: material.reviewPositions(module, presets.length),
            opensModule: i == 0,
          ),
        );
      }
    }
    return GuidebookGenerationPlan(
      roundCount: roundCount,
      exercisesPerRound: exercisesPerRound,
      rounds: List.unmodifiable(rounds),
      focusModuleId: focusModuleId,
      skippedModules: List.unmodifiable(skipped),
    );
  }

  /// What [round] will use, for the plan: "Focus: Al bar — il conto,
  /// buongiorno · Review: Saluti — ciao".
  String wordsOf(Guidebook guidebook, GuidebookRoundPlan round) {
    final material = _Material(guidebook);
    final slots = material.resolve(round);
    String list(Iterable<_Slot> slots) {
      final byModule = <String, Set<String>>{};
      for (final slot in slots) {
        for (final item in slot.items) {
          (byModule[item.moduleTitle] ??= {}).add(item.shown);
        }
      }
      return [
        for (final entry in byModule.entries)
          '${entry.key} — ${entry.value.join(', ')}',
      ].join('; ');
    }

    final focus = slots.where((slot) => !slot.review);
    final review = slots.where((slot) => slot.review);
    return [
      'Focus: ${list(focus)}',
      if (review.isNotEmpty) 'Review: ${list(review)}',
    ].join(' · ');
  }

  /// The draft Rounds of [plan]. [roundTitles] (Build 267 Revision 2,
  /// default on) titles each Round "phase: module title"; off, the Rounds
  /// have no title and learners see the Round type and number.
  List<LearningRound> createDrafts(
    Guidebook guidebook,
    GuidebookGenerationPlan plan, {
    bool roundTitles = true,
  }) {
    final material = _Material(guidebook);
    if (material.allWords.length < minimumWords) {
      throw const GuidebookGenerationException(
        'GuideBook material is insufficient for generation.',
      );
    }
    final random = Random(_randomSeed);
    final duplication = AuthoringDuplicationService(ids: _draftIds);
    return [
      for (final roundPlan in plan.rounds)
        _createRound(
          roundPlan,
          material,
          random,
          duplication,
          roundTitles: roundTitles,
        ),
    ];
  }

  LearningRound _createRound(
    GuidebookRoundPlan plan,
    _Material material,
    Random random,
    AuthoringDuplicationService duplication, {
    required bool roundTitles,
  }) {
    if (!supportsType(plan.roundType)) {
      throw GuidebookGenerationException(unsupportedReason(plan.roundType));
    }
    final module = material.focusOf(plan.focusModuleId);
    final slots = material.resolve(plan);
    final exercises = <(Exercise, List<String>)>[];
    for (var i = 0; i < slots.length; i++) {
      final slot = slots[i];
      final template = _exercise(slot, material, plan.difficulty, random);
      exercises.add((
        duplication.duplicateExercise(template),
        [for (final item in slot.items) item.id],
      ));
    }
    for (final (exercise, _) in exercises) {
      final problems = RoundTypeCompatibility.issuesForExercise(
        plan.roundType,
        exercise,
      );
      if (problems.isNotEmpty) {
        throw GuidebookGenerationException(
          'Generated ${plan.roundType.name} exercise is incompatible: ${RoundTypeCompatibility.message(problems.first)}',
        );
      }
    }
    final opens =
        (plan.opensModule || plan.index == 0) &&
        plan.roundType != RoundType.flashcard &&
        plan.roundType != RoundType.test;
    final introId = opens ? _draftIds.next('intro') : '';
    final overview = module.overview.trim();
    final content = <LearningContent>[
      // Build 257: the introduction is a Before you start card, a Draft the
      // author edits and publishes like any card. Build 266 Revision 3: it
      // holds a copy of the focus module's Overview and has no sourceRefs.
      if (opens)
        LearningContent(
          id: introId,
          publicationState: PublicationState.draft,
          kind: 'exercise',
          required: false,
          exercise: Exercise.beforeYouStart(
            id: introId,
            publicationState: PublicationState.draft,
            updatedAt: _now(),
            text: overview.isEmpty
                ? 'Review the “${_moduleTitle(module)}” module of the '
                      'GuideBook before you start.'
                : overview,
            guidebookButton: true,
            authoringMetadata: const {'presetId': 'before_you_start'},
          ),
        ),
      for (final (exercise, refs) in exercises)
        LearningContent(
          id: exercise.id,
          publicationState: PublicationState.draft,
          kind: exercise.editorTemplate == 'flashcard'
              ? 'presentation'
              : 'exercise',
          editorTemplate: exercise.editorTemplate,
          exercise: exercise.editorTemplate == 'flashcard' ? null : exercise,
          presentation: exercise.editorTemplate == 'flashcard'
              ? Presentation.fromLegacyExercise(exercise)
              : null,
          sourceRefs: refs,
        ),
    ];
    final supporting = <String>{
      for (final slot in slots)
        if (slot.review)
          for (final item in slot.items) item.moduleId,
    };
    return LearningRound(
      id: _draftIds.next('round'),
      publicationState: PublicationState.draft,
      updatedAt: _now(),
      title: roundTitles ? plan.title : '',
      roundType: plan.roundType,
      content: content,
      flow: plan.roundType == RoundType.sequence
          ? RoundFlowAuthoring.linearFor(content)
          : null,
      focusModuleId: module.id,
      supportingModuleIds: [
        for (final candidate in material.modules)
          if (supporting.contains(candidate.id) && candidate.id != module.id)
            candidate.id,
      ],
    );
  }

  Exercise _exercise(
    _Slot slot,
    _Material material,
    double difficulty,
    Random random,
  ) {
    final distractorCount = difficulty < .34 ? 1 : 2;
    final item = slot.items.first;
    List<String> wrongTargets(_Item answer) => [
      for (final other in material.wrongAnswersFor(answer, distractorCount))
        other.shown,
    ];

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

    switch (slot.preset) {
      case 'choice_target':
        return select(
          type: 'choice',
          prompt: 'How do you say “${item.clue}”?',
          question: '',
          answers: [item.shown, ...wrongTargets(item)],
        );
      case 'gap_choice':
        final sentence = slot.items[1];
        return select(
          type: 'gap_choice',
          prompt: '',
          question: sentence.shown.replaceFirst(
            RegExp(RegExp.escape(item.shown), caseSensitive: false),
            '___',
          ),
          answers: [item.shown, ...wrongTargets(item)],
        );
      case 'listening_choose_target':
        // Listen and choose (Build 259 Revision 2): the learner picks what
        // was heard; the standard line says what to do.
        return select(
          type: 'listening_choice',
          prompt: '',
          question: '',
          answers: [item.shown, ...wrongTargets(item)],
          tts: item.shown,
        ).withAuthoringMetadata(const {'presetId': 'listening_choose_target'});
      case 'word_match':
      case 'audio_match':
        return _legacy(
          type: slot.preset,
          prompt: slot.preset == 'audio_match'
              ? 'Listen and match each expression with its meaning.'
              : 'Match each expression with its meaning.',
          pairs: [
            for (final pair in slot.items) [pair.shown, pair.clue],
          ],
        );
      case 'build_translation_to_target':
        final answer = _words(item.shown);
        return _legacy(
          type: 'build_translation',
          prompt: 'Build the translation of “${item.clue}”.',
          tokens: answer,
          correctTranslations: [item.shown],
        );
      case 'word_order':
        final answer = _words(item.shown);
        return _legacy(
          type: 'word_order',
          prompt: 'Put the words in order: “${item.clue}”.',
          tokens: answer,
          orderAnswer: answer,
        );
      case 'type_translation_to_target':
        return _legacy(
          type: 'type_translation',
          prompt: item.clue,
          accepted: [for (final synonym in material.synonymsOf(item)) synonym],
          hint: difficulty < .67 ? 'Use the Lesson GuideBook vocabulary.' : '',
        );
      case 'flashcard':
        return Exercise.presentation(
          id: 'draft_template',
          editorTemplate: 'flashcard',
          term: GuidebookText.display(item.entry.target),
          meaning: item.clue,
        );
      case 'icon_choice':
        final wrong = material.wrongPicturesFor(item, distractorCount + 1);
        final choices = [item, ...wrong]..shuffle(random);
        return _fromForm(
          'icon_choice',
          question: item.shown,
          answers: choices.map((choice) => choice.shown).join('\n'),
          icons: choices.map((choice) => choice.picture!.asset).join('\n'),
          correct: '${choices.indexOf(item) + 1}',
          plural: {
            for (final choice in choices)
              if (choice.picture!.plural) choice.picture!.asset,
          },
        );
      case 'picture_word_match':
        return _fromForm(
          'picture_word_match',
          answers: slot.items.map((pair) => pair.shown).join('\n'),
          pairs: [
            for (final pair in slot.items)
              '${pair.picture!.asset} = ${pair.shown}',
          ].join('\n'),
          plural: {
            for (final pair in slot.items)
              if (pair.picture!.plural) pair.picture!.asset,
          },
        );
      case 'picture_flashcard':
        return _fromForm(
          'picture_flashcard',
          prompt: GuidebookText.display(item.entry.target),
          question: item.clue,
          imageAsset: item.picture!.asset,
          plural: {if (item.picture!.plural) item.picture!.asset},
        );
      default:
        throw StateError('Unsupported generated preset: ${slot.preset}');
    }
  }

  /// A picture preset built as its form builds it, so the preset represents
  /// it and the Plural marks follow the pictures (Build 265 Revision 11).
  Exercise _fromForm(
    String preset, {
    String prompt = '',
    String question = '',
    String answers = '',
    String icons = '',
    String correct = '',
    String pairs = '',
    String imageAsset = '',
    Set<String> plural = const {},
  }) {
    final result = ExerciseDraftBuilder.build(
      ExerciseDraftValues(
        original: Exercise(
          id: 'draft_template',
          publicationState: PublicationState.draft,
          updatedAt: _now(),
          type: ExercisePresetRegistry.byId(preset)?.base ?? preset,
          editorTemplate: preset,
          prompt: '',
          question: '',
          answers: const [],
          correct: null,
          tts: null,
          accepted: const [],
          tokens: const [],
          orderAnswer: const [],
          pairs: const [],
          hint: '',
          icons: const [],
        ),
        type: preset,
        publicationState: PublicationState.draft,
        prompt: prompt,
        question: question,
        answers: answers,
        icons: icons,
        correct: correct,
        pairs: pairs,
        imageAsset: imageAsset,
        pluralPictures: plural,
      ),
    );
    final candidate = result.candidate;
    if (candidate == null) {
      throw GuidebookGenerationException(
        'A $preset exercise could not be built from the GuideBook pictures.',
      );
    }
    return candidate;
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
    List<String> correctTranslations = const [],
    List<List<String>> pairs = const [],
    String hint = '',
  }) => Exercise(
    id: 'draft_template',
    updatedAt: _now(),
    type: type,
    prompt: prompt,
    question: question,
    answers: answers,
    correct: correct,
    tts: tts,
    accepted: accepted,
    tokens: tokens,
    orderAnswer: orderAnswer,
    correctTranslations: correctTranslations,
    pairs: pairs,
    hint: hint,
    icons: const [],
  );

  static String _phase(double difficulty) => difficulty < .34
      ? 'Foundations'
      : difficulty < .67
      ? 'Practice'
      : 'Use in context';

  static String _moduleTitle(GuidebookModule module) =>
      module.title.trim().isEmpty ? 'Untitled module' : module.title.trim();

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

/// A GuideBook entry as the Wizard uses it.
class _Item {
  _Item(this.entry, this.module);

  final GuidebookEntry entry;
  final GuidebookModule module;

  String get id => entry.id;
  String get moduleId => module.id;
  String get moduleTitle => GuidebookRoundGenerator._moduleTitle(module);

  /// Shown and in blocks: the Target without its optional words.
  String get shown => GuidebookText.withoutOptionalWords(entry.target);

  /// The learners'-language side, with the Context that tells meanings apart.
  String get clue => entry.context.trim().isEmpty
      ? entry.source
      : '${entry.source} (${entry.context.trim()})';

  GuidebookPicture? get picture => entry.picture;

  String get targetKey => GuidebookRoundGenerator._normalize(shown);
  String get sourceKey => GuidebookRoundGenerator._normalize(entry.source);
  String get meaningKey =>
      '$sourceKey|${GuidebookRoundGenerator._normalize(entry.context)}';
}

/// One exercise of a planned Round: its preset, the entries of its question
/// and answer (a word, a sentence, or three pairs), and whether it reviews
/// an earlier module.
class _Slot {
  const _Slot(this.preset, this.items, {required this.review});

  final String preset;
  final List<_Item> items;
  final bool review;
}

class _Material {
  _Material(this.guidebook)
    : modules = guidebook.modules,
      _words = {
        for (final module in guidebook.modules)
          module.id: [for (final word in module.words) _Item(word, module)],
      },
      _sentences = {
        for (final module in guidebook.modules)
          module.id: [
            for (final sentence in module.sentences)
              if (GuidebookText.withoutOptionalWords(
                sentence.target,
              ).isNotEmpty)
                _Item(sentence, module),
          ],
      };

  final Guidebook guidebook;
  final List<GuidebookModule> modules;
  final Map<String, List<_Item>> _words;
  final Map<String, List<_Item>> _sentences;

  List<_Item> get allWords => [for (final m in modules) ..._words[m.id]!];

  GuidebookModule? moduleById(String id) =>
      modules.where((module) => module.id == id).firstOrNull;

  /// The module a Round practises; a Round planned before modules (no
  /// focus) takes the first module that can be practised.
  GuidebookModule focusOf(String? id) {
    final chosen = id == null ? null : moduleById(id);
    if (chosen != null) return chosen;
    return modules.firstWhere(
      (module) => GuidebookRoundGenerator.moduleProblem(module) == null,
      orElse: () => throw const GuidebookGenerationException(
        'Add at least three Words & Expressions entries to this Lesson GuideBook first. Example: casa = house.',
      ),
    );
  }

  List<_Item> wordsOf(GuidebookModule module) => _words[module.id] ?? const [];
  List<_Item> sentencesOf(GuidebookModule module) =>
      _sentences[module.id] ?? const [];

  /// The modules before [module] in the Lesson, nearest first.
  List<GuidebookModule> earlierThan(GuidebookModule module) {
    final at = modules.indexWhere((candidate) => candidate.id == module.id);
    return at <= 0 ? const [] : [for (var i = at - 1; i >= 0; i--) modules[i]];
  }

  /// The pictured Words & Expressions of [modules].
  List<_Item> pictured(Iterable<GuidebookModule> modules) => [
    for (final module in modules)
      for (final word in wordsOf(module))
        if (word.picture != null) word,
  ];

  /// Words with a sentence containing them, for Pick the missing word.
  List<(_Item, _Item)> matched(Iterable<GuidebookModule> modules) => [
    for (final module in modules)
      for (final word in wordsOf(module))
        for (final sentence in sentencesOf(module))
          if (GuidebookRoundGenerator._normalize(
            sentence.shown,
          ).contains(word.targetKey))
            (word, sentence),
  ];

  bool hasPictures(Iterable<GuidebookModule> modules) =>
      _distinctPictures(pictured(modules)).length >= 3;

  List<String> poolFor(
    GuidebookModule module,
    double difficulty,
    RoundType roundType,
  ) {
    final own = [module];
    final hasSentences = sentencesOf(module).isNotEmpty;
    final hasMatched = matched(own).isNotEmpty;
    final pictures = hasPictures(own);
    if (roundType == RoundType.flashcard) {
      return ['flashcard', if (pictures) 'picture_flashcard'];
    }
    if (roundType == RoundType.listening) {
      return const ['listening_choose_target'];
    }
    final candidates = difficulty < .34
        ? [
            'choice_target',
            if (hasMatched) 'gap_choice',
            'listening_choose_target',
            'word_match',
            if (pictures) 'icon_choice',
            if (pictures) 'picture_word_match',
          ]
        : difficulty < .67
        ? [
            'build_translation_to_target',
            if (hasSentences) 'word_order',
            'audio_match',
            // The expression in context is Pick the missing word: the Round
            // Wizard creates preset exercises only (owner, 29 September 2026).
            if (hasMatched) 'gap_choice',
            if (pictures) 'picture_word_match',
            if (pictures) 'icon_choice',
          ]
        : [
            'type_translation_to_target',
            if (hasMatched) 'gap_choice',
            'build_translation_to_target',
            if (hasSentences) 'word_order',
          ];
    for (final preset in candidates) {
      if (ExercisePresetRegistry.byId(preset) == null) {
        throw StateError('Generator preset is not registered: $preset');
      }
    }
    return candidates;
  }

  /// round(0.3 × M) positions, spread evenly, never the first; none when
  /// [module] is the Lesson's first or no earlier module has words.
  List<int> reviewPositions(GuidebookModule module, int count) {
    if (earlierThan(module).every((earlier) => wordsOf(earlier).isEmpty)) {
      return const [];
    }
    final wanted = (GuidebookRoundGenerator.reviewShare * count).round();
    final positions = <int>{};
    for (var k = 1; k <= wanted; k++) {
      final position = (k * count / (wanted + 1)).round();
      if (position >= 1 && position < count) positions.add(position);
    }
    return positions.toList()..sort();
  }

  /// The slots of [round], the same for the plan and the drafts.
  List<_Slot> resolve(GuidebookRoundPlan round) {
    final module = focusOf(round.focusModuleId);
    final earlier = earlierThan(module);
    return [
      for (var i = 0; i < round.presetIds.length; i++)
        _slot(
          round.presetIds[i],
          module,
          earlier,
          review: round.reviewPositions.contains(i),
          turn: round.index * 3 + i,
        ),
    ];
  }

  _Slot _slot(
    String preset,
    GuidebookModule module,
    List<GuidebookModule> earlier, {
    required bool review,
    required int turn,
  }) {
    if (review && earlier.isNotEmpty) {
      final reviewed = _items(preset, earlier, turn);
      if (reviewed != null) return _Slot(preset, reviewed, review: true);
    }
    // A review slot its preset cannot fill from earlier modules stays a
    // focus slot.
    final items = _items(preset, [module], turn);
    if (items == null) {
      throw GuidebookGenerationException(
        'The module “${GuidebookRoundGenerator._moduleTitle(module)}” has '
        'no material for $preset.',
      );
    }
    return _Slot(preset, items, review: false);
  }

  /// The entries [preset] needs from [modules] (together), or null.
  List<_Item>? _items(String preset, List<GuidebookModule> modules, int turn) {
    T? at<T>(List<T> list) => list.isEmpty ? null : list[turn % list.length];
    final words = [for (final module in modules) ...wordsOf(module)];
    final sentences = [for (final module in modules) ...sentencesOf(module)];
    switch (preset) {
      case 'gap_choice':
        final pair = at(matched(modules));
        return pair == null ? null : [pair.$1, pair.$2];
      case 'word_order':
        final sentence = at(sentences);
        return sentence == null ? null : [sentence];
      case 'build_translation_to_target':
        // Whole sentences with their meaning as the clue; a module without
        // Sentences builds its words.
        final item = at(sentences) ?? at(words);
        return item == null ? null : [item];
      case 'word_match':
      case 'audio_match':
        final three = _distinctPairs(words, turn);
        return three.length < 3 ? null : three;
      case 'picture_word_match':
        final three = _distinctPairs(
          _distinctPictures(pictured(modules)),
          turn,
        );
        return three.length < 3 ? null : three;
      case 'icon_choice':
        final pictures = _distinctPictures(pictured(modules));
        return pictures.length < 3 ? null : [at(pictures)!];
      case 'picture_flashcard':
        final word = at(pictured(modules));
        return word == null ? null : [word];
      default:
        final word = at(words);
        return word == null ? null : [word];
    }
  }

  /// Three entries from [items], from [turn] on, that can share a Match:
  /// never two with the same Target, nor synonyms.
  List<_Item> _distinctPairs(List<_Item> items, int turn) {
    final chosen = <_Item>[];
    for (var k = 0; k < items.length && chosen.length < 3; k++) {
      final item = items[(turn + k) % items.length];
      if (chosen.any(
        (other) =>
            other.targetKey == item.targetKey ||
            other.meaningKey == item.meaningKey,
      )) {
        continue;
      }
      chosen.add(item);
    }
    return chosen;
  }

  /// One entry per picture: the same picture with and without Plural is one
  /// picture (il gatto and i gatti are never choices of one exercise).
  List<_Item> _distinctPictures(List<_Item> items) {
    final seen = <String>{};
    return [
      for (final item in items)
        if (seen.add(item.picture!.asset)) item,
    ];
  }

  /// Wrong answers for [answer]: entries that differ only by their Context
  /// first, then its own module's, then the Lesson's other modules'; never
  /// the same Target, never a synonym (same Source and Context).
  List<_Item> wrongAnswersFor(_Item answer, int count) {
    final ordered = <_Item>[
      ...allWords.where(
        (item) =>
            item.sourceKey == answer.sourceKey &&
            item.meaningKey != answer.meaningKey,
      ),
      ...wordsOf(answer.module),
      ...allWords,
    ];
    final targets = <String>{answer.targetKey};
    final result = <_Item>[];
    for (final item in ordered) {
      if (result.length == count) break;
      if (item.meaningKey == answer.meaningKey) continue;
      if (!targets.add(item.targetKey)) continue;
      result.add(item);
    }
    return result;
  }

  /// Wrong pictures for [answer]: other pictured entries with another
  /// picture, never the same Target or a synonym.
  List<_Item> wrongPicturesFor(_Item answer, int count) {
    final pictures = <String>{answer.picture!.asset};
    final targets = <String>{answer.targetKey};
    final result = <_Item>[];
    for (final item in [
      ...pictured([answer.module]),
      ...pictured(modules),
    ]) {
      if (result.length == count) break;
      if (item.meaningKey == answer.meaningKey) continue;
      if (pictures.contains(item.picture!.asset)) continue;
      if (!targets.add(item.targetKey)) continue;
      pictures.add(item.picture!.asset);
      result.add(item);
    }
    return result;
  }

  /// Every Target a typed answer accepts for [item]: its own and its
  /// synonyms' (same Source and Context), with their optional words `{…}`.
  List<String> synonymsOf(_Item item) {
    final seen = <String>{};
    return [
      for (final other in [item, ...allWords])
        if (other.meaningKey == item.meaningKey &&
            seen.add(GuidebookRoundGenerator._normalize(other.entry.target)))
          other.entry.target,
    ];
  }
}
