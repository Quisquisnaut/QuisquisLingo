import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/rendering.dart' show RenderAbstractViewport;
import '../services/course_language_resolver.dart';
import '../services/first_letter_answer_service.dart';
import '../widgets/bundled_picture.dart';
import '../widgets/confetti_burst.dart';
import '../widgets/course_media_image.dart';
import '../widgets/exercise_mascot.dart';
import '../widgets/exercise_prompt_panels.dart';
import '../services/inline_marks.dart';
import '../services/page_blocks.dart';
import '../widgets/page_actions.dart';
import '../widgets/page_card.dart';
import '../widgets/plural_picture.dart';
import '../widgets/portable_exercise_image.dart';
import '../widgets/reported_action.dart';
import '../services/beta_lifecycle_service.dart';
import '../widgets/beta_expired_view.dart';
import '../models/course_models.dart';
import '../models/exercise_features.dart';
import '../services/progress_service.dart';
import '../services/exercise_difficulty.dart';
import '../services/learner_panel_text.dart';
import '../services/learning_completion_service.dart';
import '../services/xp_calculator.dart';
import '../services/timed_round_rules.dart';
import '../services/report_service.dart';
import '../services/tts_cache_service.dart';
import '../services/settings_service.dart';
import '../services/course_service.dart';
import '../services/round_playability_service.dart';
import '../services/round_type_presentation.dart';
import '../services/sound_effect_service.dart';
import '../services/recorded_audio_service.dart';
import '../services/exercise_copy_service.dart';
import '../services/crash_log_service.dart';
import '../services/answer_engine.dart';
import '../services/audio_exercise_availability_service.dart';
import '../services/audio_diagnostic_service.dart';
import '../services/translation_choice_service.dart';
import '../services/exercise_mascot_policy.dart';
import '../services/learner_mascots.dart';
import '../services/lesson_presentation_service.dart';
import '../services/word_lookup/word_lookup.dart';
import '../services/word_lookup/word_lookup_sources.dart';
import '../widgets/word_lookup_view.dart';
import 'guidebook_screen.dart';

class RoundScreen extends StatefulWidget {
  /// Opens a Page link in the browser (Build 258). A test seam: widget
  /// tests replace it; the app never downloads or plays video itself.
  static Future<bool> Function(Uri url) openLink = (url) =>
      launchUrl(url, mode: LaunchMode.externalApplication);

  final Course course;
  final Lesson lesson;
  final LearningRound round;
  final String ttsLanguage;
  final int roundIndex;
  final bool previewMode;
  final bool viewOnlyMode;
  final bool reviewMode;
  final bool completeLessonOnFinish;
  final SettingsService? settingsService;
  final TtsCacheService? ttsCacheService;
  final RecordedAudioService? recordedAudioService;

  /// The mascot pictures to choose from (Build 256 Revision 9); null loads
  /// the bundled `assets/mascots/`. Tests pass their own list.
  final List<String>? mascotAssets;

  /// The random source of the mascot order; tests pass a seeded one.
  final Random? mascotRandom;
  final DateTime Function()? timedClock;

  const RoundScreen({
    super.key,
    required this.course,
    required this.lesson,
    required this.round,
    required this.ttsLanguage,
    required this.roundIndex,
    this.previewMode = false,
    this.viewOnlyMode = false,
    this.reviewMode = false,
    this.completeLessonOnFinish = false,
    this.settingsService,
    this.ttsCacheService,
    this.recordedAudioService,
    this.mascotAssets,
    this.mascotRandom,
    this.timedClock,
  });

  @override
  State<RoundScreen> createState() => _RoundScreenState();
}

/// One finished item of a scrolling Story, kept on the page.
class _StoryEntry {
  const _StoryEntry({
    required this.heading,
    required this.prompt,
    required this.answer,
    required this.correct,
    required this.evaluable,
    this.headingIsInstruction = false,
    this.kind = LearnerExerciseKind.other,
    this.speaker,
    this.picture = '',
    this.language,
  });

  final String heading;
  final String prompt;
  final String? answer;
  final bool correct;
  final bool evaluable;

  /// A Story's entry is headed by the instruction, not a title.
  final bool headingIsInstruction;

  /// Build 256 Revision 5: a dialogue line or a Story cover is drawn as it
  /// was shown (bubble, cover), any other item as a card.
  final LearnerExerciseKind kind;
  final StorySpeaker? speaker;
  final String picture;

  /// The language of a line or a cover's title line (Word Lookup leaves
  /// source-language text alone, Build 265).
  final TextLanguage? language;
}

class _ChoiceOption {
  final String text;
  final bool correct;
  final ExerciseItem? item;
  const _ChoiceOption(this.text, this.correct, {this.item});
}

class _MatchOption {
  final String id;
  final String label;
  const _MatchOption(this.id, this.label);
}

class _MatchPairView {
  final String leftId;
  final String leftLabel;
  final String leftImage;

  /// Whether the left picture shows several (Build 265 Revision 11).
  final bool leftPlural;
  final String rightId;
  const _MatchPairView({
    required this.leftId,
    required this.leftLabel,
    this.leftImage = '',
    this.leftPlural = false,
    required this.rightId,
  });
}

class _RoundScreenState extends State<RoundScreen> {
  String get _roundTitle => RoundTypePresentation.title(
    widget.round,
    widget.roundIndex + 1,
    widget.course.roundNumberingMode,
    customPrefix: widget.course.customRoundLabel,
  );
  String get _screenTitle => widget.previewMode
      ? 'PREVIEW · $_roundTitle'
      : widget.viewOnlyMode
      ? 'VIEW ONLY · $_roundTitle'
      : widget.reviewMode
      ? _t('reviewOfRound', {'round': _roundTitle})
      : _roundTitle;
  int get _lessonIndex => widget.course.lessons.indexWhere(
    (lesson) => lesson.lessonId == widget.lesson.lessonId,
  );
  String get _reviewContext {
    final roundTitle = _roundTitle;
    return '${widget.course.title} · ${widget.course.targetLanguage} · '
        '${_t('review.lesson', {'n': _lessonIndex + 1, 'title': widget.lesson.title})} · '
        '${_t('review.round', {'n': widget.roundIndex + 1})}'
        '${roundTitle.isEmpty ? '' : ': $roundTitle'}';
  }

  final _progress = ProgressService();
  late final LearningCompletionService _completion;
  late final TtsCacheService _ttsCache;
  final _reports = ReportService();
  late final SettingsService _settings;
  final _sounds = SoundEffectService();
  late final RecordedAudioService _recordedAudio;
  late final AudioExerciseAvailabilityService _audioAvailability;
  final _roundPlayability = RoundPlayabilityService();
  final _answerEngine = const AnswerEngine();
  final _random = Random();

  List<int> _queue = [];
  bool _ready = false;
  bool _introAcknowledged = false;
  bool _initializationFailed = false;
  bool _ttsWasSkipped = false;

  /// Build 256 Revision 6 (plan A.6): audio exercises left out, and the
  /// exercises this version cannot play (skipped in a practice Round, shown
  /// as cards in a Story). Either keeps a zero-error attempt from the Laurel.
  bool _audioWasSkipped = false;
  int _versionSkipped = 0;
  bool _audioExercisesEnabled = false;
  bool _optionalAudioEnabled = false;
  bool _wasCompleted = false;
  AudioDiagnosticLifecycle? _preparedAudioDiagnostic;
  Future<void> _preparedAudioPreparation = Future<void>.value();
  int _preparedExerciseGeneration = 0;
  int? _suppressedAudioGeneration;
  int? _startedAudioGeneration;
  final Set<int> _wrongFirstPass = {};
  int _position = 0;
  int _firstPassCorrect = 0;

  /// The sum of the difficulty levels of the exercises answered correctly at
  /// the first attempt: the Difficulty bonus (Build 260 Revision 6).
  int _firstPassDifficulty = 0;
  int _evaluableExerciseCount = 0;
  int _errorsThisAttempt = 0;
  bool _reviewPhase = false;
  bool _finishing = false;
  Timer? _timedTicker;
  Timer? _timedExpiryTimer;
  DateTime? _timedDeadline;
  int? _activeTimedLimitSeconds;
  int _timedSecondsLeft = 0;
  bool _timedOut = false;
  bool _timedCompletedBeforeZero = false;
  bool _timedReviewDialogOpen = false;
  bool _timeoutSaving = false;
  bool _timeoutSaved = false;
  int _timeoutXp = 0;
  String? _timeoutError;

  DateTime get _timedNow => (widget.timedClock ?? DateTime.now)();

  void _startTimedCountdown() {
    if (widget.round.roundType != RoundType.timed ||
        _timedDeadline != null ||
        _timedOut ||
        _activeTimedLimitSeconds == null ||
        _queue.isEmpty) {
      return;
    }
    _timedDeadline = _timedNow.add(
      Duration(seconds: _activeTimedLimitSeconds!),
    );
    _timedExpiryTimer = Timer(
      Duration(seconds: _activeTimedLimitSeconds!),
      _expireTimedAttempt,
    );
    _timedTicker = Timer.periodic(const Duration(milliseconds: 250), (_) {
      if (!mounted || _timedOut || _finishing) return;
      final millis = _timedDeadline!.difference(_timedNow).inMilliseconds;
      if (millis <= 0) {
        _expireTimedAttempt();
      } else {
        setState(() => _timedSecondsLeft = (millis + 999) ~/ 1000);
      }
    });
  }

  void _expireTimedAttempt() {
    if (_timedOut || _finishing) return;
    _timedTicker?.cancel();
    _timedExpiryTimer?.cancel();
    _timedOut = true; // Input is locked before any persistence await.
    FocusManager.instance.primaryFocus?.unfocus();
    if (_timedReviewDialogOpen && mounted) {
      Navigator.of(context).pop();
    }
    setState(() => _timedSecondsLeft = 0);
    unawaited(_saveTimedTimeoutXp());
  }

  Future<void> _saveTimedTimeoutXp() async {
    if (_timeoutSaving || _timeoutSaved) return;
    _timeoutSaving = true;
    if (mounted) setState(() => _timeoutError = null);
    final award = const XpCalculator().calculateTimedTimeoutAward(
      firstPassCorrect: _firstPassCorrect,
      wasCompletedAtStart: _wasCompleted,
    );
    try {
      if (!widget.previewMode && !widget.viewOnlyMode && award.totalXp > 0) {
        await _progress.addXp(
          award.totalXp,
          courseCode: CourseService.codeForCourse(widget.course),
          courseId: widget.course.courseId,
        );
      }
      _timeoutSaved = true;
      _timeoutXp = widget.previewMode || widget.viewOnlyMode
          ? 0
          : award.totalXp;
    } catch (_) {
      _timeoutError = 'XP could not be saved. Try again before leaving.';
    } finally {
      _timeoutSaving = false;
      if (mounted) setState(() {});
    }
  }

  /// The Round plays its flow in the authored order: a Story, or a sequence
  /// (a plain Round played in order; Build 256 Revision 7, third follow-up).
  bool _playsInOrder = false;

  /// What the learner is told this Round is: a Story, a Sequence or a Round.
  String get _roundNoun => RoundTypePresentation.label(widget.round.roundType);

  /// The same, as the suffix of the learner panel keys (Build 260 Revision
  /// 1): `round`, `story` or `sequence`.
  String get _nounKey => switch (widget.round.roundType) {
    RoundType.story => 'story',
    RoundType.sequence => 'sequence',
    _ => 'round',
  };

  /// The learner panel text of [key] in the Course's instruction language.
  String _t(String key, [Map<String, Object> values = const {}]) =>
      LearnerPanelText.of(widget.course, key, values);
  late ExerciseFeatures _features;
  bool _answered = false;
  bool _lastAnswerCorrect = false;
  final List<({bool correct, String correction})> _testResults = [];

  /// Build 256 Revision 5: a dialogue line's audio has played once, so a
  /// text shown "after listening" may appear.
  bool _lineAudioPlayed = false;
  String _feedback = '';
  String _displayedCorrection = '';
  List<String> _translationFeedback = const [];
  bool _translationFeedbackPartial = false;
  List<String> _acceptedDifferences = const [];
  int? _selected;
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();
  final List<String> _builtOrder = [];

  /// A scrolling Story (`flow.presentation: scroll`): finished items stay on
  /// the page above the active one, which the page scrolls to.
  bool _storyScrolls = false;
  final List<_StoryEntry> _storyLog = [];
  final ScrollController _storyScroll = ScrollController();

  /// The exercise page's scroll (Build 259 Revision 3): after an answer the
  /// page scrolls down to the feedback panel and its Continue or Finish
  /// button, which a tall exercise (Sort into groups) left below the screen.
  final ScrollController _pageScroll = ScrollController();
  final GlobalKey _storyNowKey = GlobalKey();
  final List<TextEditingController> _missingWordControllers = [];
  final Map<String, String> _matchingSelections = {};
  List<_ChoiceOption> _choiceOptions = [];
  List<String> _tokenOptions = [];
  List<_MatchOption> _matchingRightOptions = [];
  List<_MatchPairView> _matchingLeftPairs = [];

  // Gap-based Arrange state. `_gapFill` maps each gap ID from the exercise's
  // layout to the item ID currently placed there (or null when empty).
  // `_armedGapId` is the gap most recently tapped by its own tile, awaiting a
  // second tap on a destination gap to move/swap it, or a re-tap to cancel.
  final Map<String, String?> _gapFill = {};
  String? _armedGapId;
  List<String> _gapTileOrder = [];

  // Multi-select Select state: indices into `_choiceOptions` currently
  // selected by the learner. Only used when the exercise's `maxSelections`
  // is greater than 1; single-select exercises keep using `_selected`.
  final Set<int> _multiSelected = {};

  // Assign state (Build 256 Revision 7): the items placed in each target, in
  // placement order, and the bank tile armed for the next destination tap.
  final Map<String, List<String>> _assignPlacements = {};
  String? _armedAssignItemId;
  List<String> _assignTileOrder = [];

  // Linked-gap Select state: maps each gap ID from the exercise's layout to
  // the item ID currently filling it (or null when empty), mirroring
  // Arrange's `_gapFill`/`_armedGapId`. Unlike Arrange, options are never
  // consumed from the option list, since the same option may need to fill
  // several gaps.
  final Map<String, String?> _selectGapFill = {};
  String? _selectArmedGapId;

  // Mascots (Build 256 Revision 9): the Round's picture order, null when
  // this Round shows none; the active exercise's picture, taken from the
  // order the first time its mascot fits on screen; and where this build
  // draws it.
  ExerciseMascotSequence? _mascots;
  String? _exerciseMascot;
  ({ExerciseMascotAnchor anchor, String asset, double size})? _mascotPlacement;

  static const _autumnBackgrounds = <Color>[
    Color(0xFFF4EBDD), // warm cream
    Color(0xFFE7E1CF), // oat
    Color(0xFFE9D9CE), // pale terracotta
    Color(0xFFDDE5D5), // sage
    Color(0xFFE9DFC7), // muted harvest gold
    Color(0xFFE5D9D2), // dusty rose-brown
  ];

  Color get _exercisePanelColor {
    final scheme = Theme.of(context).colorScheme;
    return Theme.of(context).brightness == Brightness.dark
        ? scheme.surfaceContainerHigh
        : scheme.surfaceContainerLowest;
  }

  Color _roundBackground(Color lightBackground) {
    if (Theme.of(context).brightness == Brightness.light) {
      return lightBackground;
    }
    final scheme = Theme.of(context).colorScheme;
    return Color.alphaBlend(
      lightBackground.withValues(alpha: 0.08),
      scheme.surface,
    );
  }

  Color get _feedbackPanelColor {
    final scheme = Theme.of(context).colorScheme;
    final accent = _lastAnswerCorrect ? scheme.primary : scheme.error;
    return Color.alphaBlend(
      accent.withValues(alpha: 0.12),
      _exercisePanelColor,
    );
  }

  int get _exerciseIndex => _queue[_position];
  Exercise get _exercise => widget.round.exercises[_exerciseIndex];

  /// The Before you start card (Build 257): an ordinary card of the Round,
  /// shown on its own page before the Round starts and never in Review
  /// (owner decision, 29 September 2026). Found once the Round is prepared.
  Exercise? _lessonIntro;

  /// Build 265: the Course's GuideBook vocabulary for Word Lookup, empty
  /// when the Course's Use GuideBook or Word Lookup is off and in a Test
  /// Round. The Preview reads Draft GuideBooks too.
  late final WordLookupIndex _wordLookup;
  bool _wordLookupNoticeChecked = false;

  @override
  void initState() {
    super.initState();
    _wordLookup =
        widget.course.useGuidebook &&
            widget.course.wordLookup &&
            widget.round.roundType != RoundType.test
        ? WordLookupSources.indexFor(
            widget.course,
            includeDrafts: widget.previewMode,
          )
        : WordLookupIndex.empty;
    _settings = widget.settingsService ?? SettingsService();
    _ttsCache = widget.ttsCacheService ?? TtsCacheService();
    _recordedAudio = widget.recordedAudioService ?? RecordedAudioService();
    _audioAvailability = AudioExerciseAvailabilityService(
      recordedAudio: _recordedAudio,
    );
    _completion = LearningCompletionService(progressService: _progress);
    _initializeRound();
  }

  /// The speech language for text in [language]: the Course's source
  /// language for source-language audio (a "to source" preset), else the
  /// learning language.
  String _voiceFor(TextLanguage? language) {
    if (language != TextLanguage.source) return widget.ttsLanguage;
    final code = CourseLanguageResolver.base(widget.course).code ?? '';
    return code.isEmpty ? widget.ttsLanguage : code;
  }

  /// The audio that plays when the exercise becomes active: an element with
  /// automatic playback, or a dialogue line's audio when the line follows a
  /// Story whose read-aloud is automatic (Build 256 Revision 5).
  PromptElement? _automaticAudioOf(ExerciseFeatures f) {
    final automatic = f.automaticAudio;
    if (automatic != null) return automatic;
    if (f.kind != LearnerExerciseKind.dialogueLine) return null;
    final audio = f.lineAudio;
    if (audio == null || audio.playback != null) return null;
    final readAloud = widget.round.flow?.readAloud ?? FlowReadAloud.automatic;
    return readAloud == FlowReadAloud.automatic ? audio : null;
  }

  /// Who says a dialogue line: its character, else the narrator (also for a
  /// character the Course no longer has; the Audit names that).
  StorySpeaker _lineSpeaker(ExerciseFeatures f) =>
      widget.course.speakerOf(f.speakerId) ?? widget.course.narrator;

  /// The language a dialogue line is spoken in: the line's own, else its
  /// speaker's.
  TextLanguage _lineLanguage(ExerciseFeatures f) =>
      f.lineAudio?.language ??
      f.lineElements
          .map((e) => e.language)
          .whereType<TextLanguage>()
          .firstOrNull ??
      _lineSpeaker(f).language;

  Future<bool> _playCourseAudio(
    String text, {
    TextLanguage? language,
    StoryVoice? voice,
  }) async {
    if (widget.course.audioMode != 'tts') {
      final recorded = await _recordedAudio.playConcatenated(
        text,
        widget.course.audioLibrary,
        courseId: widget.course.courseId,
        enableDiagnostics: !widget.previewMode,
      );
      if (recorded) return true;
      if (widget.course.audioMode == 'recorded') return false;
    }
    return _ttsCache.speak(
      text: text,
      language: _voiceFor(language),
      learningLanguage: widget.course.learningLanguage,
      targetLanguage: widget.course.targetLanguage,
      applyLearnerSettings: !widget.previewMode,
      // A Story speaker's voice preference (Build 256 Revision 5).
      voicePreference: voice == null || voice == StoryVoice.any
          ? null
          : voice.serialized,
    );
  }

  Future<void> _initializeRound() async {
    await CrashLogService.instance.recordDebugEvent(
      'Round: initialization started ${widget.round.id}',
    );
    try {
      // Locally edited courses may temporarily contain invalid exercises. The
      // Course Editor reports them, while the learner-facing Round screen skips
      // exercises with structural audit errors instead of indexing invalid data.
      // Build 256 Revision 6 (plan A.6): an exercise this version cannot
      // play leaves a practice Round here, with the invalid and unpublished
      // ones and before the audio filter; a Story and the editor Preview
      // keep it and draw a card in its place.
      final keepsCards = widget.previewMode || widget.round.flow != null;
      final valid = _roundPlayability.playableExerciseIndices(
        widget.round,
        includeDrafts: widget.previewMode,
        keepNotExecutable: keepsCards,
      );
      final notExecutable = _roundPlayability.notExecutableIndices(
        widget.round,
        includeDrafts: widget.previewMode,
      );
      _versionSkipped = widget.previewMode ? 0 : notExecutable.length;
      _lessonIntro = widget.reviewMode
          ? null
          : _roundPlayability.introFor(
              widget.round,
              includeDrafts: widget.previewMode,
            );
      await CrashLogService.instance.recordDebugEvent(
        'Round: audit completed ${widget.round.id}, valid=${valid.length}, '
        'notExecutable=${notExecutable.length}',
      );
      // Resolve availability before preparing an exercise. Authoring Preview
      // bypasses learner Audio Settings and never filters its selected content.
      final audioExercisesEnabled =
          widget.previewMode || await _settings.areAudioExercisesEnabled();
      final ttsEnabled =
          widget.previewMode ||
          (audioExercisesEnabled && await _settings.isTtsEnabled());
      final filtered = <int>[];
      if (widget.previewMode) {
        filtered.addAll(valid);
      } else {
        // Build 256 Revision 5: a dialogue line or a Story cover is never
        // skipped (without audio the learner reads it), nor is any card of
        // a Story; an exercise marked as needing the Story's audio is
        // skipped like an audio exercise when audio cannot play.
        final flow = widget.round.flow;
        final audioDependent =
            flow?.audioDependentContentIds ?? const <String>{};
        final storyAudioPlayable =
            ttsEnabled || widget.course.audioMode != 'tts';
        for (final index in valid) {
          final exercise = widget.round.exercises[index];
          final kind = ExerciseFeatures(exercise).kind;
          final neverSkipped =
              kind == LearnerExerciseKind.dialogueLine ||
              kind == LearnerExerciseKind.storyCover ||
              // Build 258: a Page is read; its audio is optional.
              kind == LearnerExerciseKind.page ||
              (flow != null &&
                  exercise.primitive == ExercisePrimitive.presentation);
          if (neverSkipped) {
            filtered.add(index);
            continue;
          }
          if (!exercise.isExecutable) {
            // A card in a Story (plan A.6): never an audio matter.
            filtered.add(index);
            continue;
          }
          final ownAudio = _audioAvailability.isAudioExercise(exercise);
          final dependsOnStory = audioDependent.contains(exercise.id);
          if (!ownAudio && !dependsOnStory) {
            filtered.add(index);
            continue;
          }
          if (!audioExercisesEnabled) continue;
          if (!ownAudio) {
            if (storyAudioPlayable) filtered.add(index);
            continue;
          }
          if (await _audioAvailability.isAvailable(
            widget.course,
            exercise,
            ttsEnabled: ttsEnabled,
          )) {
            filtered.add(index);
          }
        }
      }
      _audioExercisesEnabled = audioExercisesEnabled;
      _optionalAudioEnabled =
          audioExercisesEnabled &&
          (ttsEnabled || widget.course.audioMode != 'tts');
      _audioWasSkipped = filtered.length != valid.length;
      // Something the learner could not do (audio, or an exercise this
      // version cannot play) keeps a zero-error attempt from the Laurel and
      // gives the "skipped perfect" mark instead (plan A.6; one stored key).
      _ttsWasSkipped = _audioWasSkipped || _versionSkipped > 0;
      _queue = filtered;
      _evaluableExerciseCount = valid
          .where(
            (i) =>
                widget.round.exercises[i].primitive !=
                    ExercisePrimitive.presentation &&
                widget.round.exercises[i].isExecutable,
          )
          .length;
      _wasCompleted =
          !widget.previewMode &&
          !widget.viewOnlyMode &&
          (await _progress.getCompletedRounds(
            courseId: widget.course.courseId,
          )).contains(widget.round.id);
      await CrashLogService.instance.recordDebugEvent(
        'Round: preferences loaded ${widget.round.id}, queue=${_queue.length}',
      );
      final flowOrder = _flowOrder;
      _playsInOrder = flowOrder != null;
      _storyScrolls =
          _playsInOrder &&
          widget.round.flow?.presentation == FlowPresentation.scroll;
      await CrashLogService.instance.recordDebugEvent(
        'Round: ${widget.round.id} story=$_playsInOrder scrolling=$_storyScrolls '
        'presentation=${widget.round.flow?.presentation.serialized ?? 'none'}',
      );
      if (flowOrder != null) {
        // A Story plays its nodes in authored order and is never shuffled
        // (Build 256, plan A.7).
        _queue = [
          for (final index in flowOrder)
            if (filtered.contains(index)) index,
        ];
      } else if (widget.round.roundType != RoundType.test ||
          !widget.round.testFixedOrder) {
        _shuffleDifferentInts(_queue);
      }
      // Mascots (Build 256 Revision 9): never in a Story, whose characters
      // are its cast. Pictures that cannot be loaded leave the Round without
      // mascots, never without its exercises.
      if (ExerciseMascot.enabled && !widget.round.isStory) {
        try {
          final assets =
              widget.mascotAssets ?? await loadProductionLearnerMascotAssets();
          _mascots = ExerciseMascotSequence.build(
            ExerciseMascotPolicy.exercisePool(assets),
            widget.mascotRandom ?? _random,
          );
        } catch (error, stackTrace) {
          _mascots = null;
          await CrashLogService.instance.record(
            error,
            stackTrace,
            source: 'RoundScreen._initializeRound mascots',
          );
        }
      }
      if (!mounted) return;
      if (_queue.isNotEmpty) {
        await CrashLogService.instance.recordDebugEvent(
          'Round: preparing first exercise ${widget.round.id}',
        );
        _prepareExercise(trigger: 'round_initialized');
        // Choice-based exercises must be fully prepared before the learner UI
        // becomes ready. This prevents a transient screen with no answer buttons.
        final first = _exercise;
        final needsChoices = first.primitive == ExercisePrimitive.select;
        if (needsChoices && first.items.isNotEmpty && _choiceOptions.isEmpty) {
          _choiceOptions = _choiceOptionsFor(first);
          await CrashLogService.instance.recordDebugEvent(
            'Round: rebuilt missing choice options ${widget.round.id}/${first.id}',
          );
        }
        await CrashLogService.instance.recordDebugEvent(
          'Round: first exercise prepared ${widget.round.id}',
        );
      }
      if (!mounted) return;
      if (widget.round.roundType == RoundType.timed) {
        final completed = widget.previewMode
            ? <int>{}
            : await _progress.getCompletedTimedLimits(
                widget.round.id,
                courseId: widget.course.courseId,
              );
        if (!mounted) return;
        _activeTimedLimitSeconds = TimedRoundRules.activeLimit(
          widget.round,
          completed,
        );
        _timedSecondsLeft = _activeTimedLimitSeconds ?? 0;
      }
      setState(() => _ready = true);
      if (_queue.isNotEmpty) {
        final exercise = _exercise;
        final generation = _preparedExerciseGeneration;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _activatePreparedAudio(exercise, generation, trigger: 'round_ready');
          if (mounted && _lessonIntro == null) _startTimedCountdown();
        });
      }
    } catch (error, stackTrace) {
      await CrashLogService.instance.record(
        error,
        stackTrace,
        source: 'RoundScreen._initializeRound',
      );
      if (!mounted) return;
      setState(() {
        _queue = [];
        _initializationFailed = true;
        _ready = true;
      });
    }
  }

  /// Whether Turn on audio also switches on Text-to-speech: a Course that
  /// speaks only with recorded MP3s does not need it.
  bool get _turnsOnTts => widget.course.audioMode != 'recorded';

  /// The answer to "Turn on audio to play it?" on a Round whose exercises
  /// all need audio while Audio Exercises are off, such as a Listen Round
  /// (owner decision of 9 October 2026): the learner's Audio Exercises, and
  /// Text-to-speech when the Course speaks with it, are switched on, and
  /// the Round starts again with its audio exercises.
  Future<void> _turnOnAudio() async {
    final done = await runReported(context, 'Turn on audio', () async {
      await _settings.setAudioExercisesEnabled(true);
      if (_turnsOnTts) await _settings.setTtsEnabled(true);
      return true;
    });
    if (done != true || !mounted) return;
    setState(() => _ready = false);
    await _initializeRound();
  }

  @override
  void dispose() {
    _timedTicker?.cancel();
    _timedExpiryTimer?.cancel();
    final diagnostic = _preparedAudioDiagnostic;
    if (diagnostic != null) {
      unawaited(diagnostic.dispose(outcome: 'round_disposed'));
    }
    _textController.dispose();
    _storyScroll.dispose();
    _pageScroll.dispose();
    _textFocusNode.dispose();
    for (final c in _missingWordControllers) {
      c.dispose();
    }
    super.dispose();
  }

  /// The exercise indices in the Round's linear flow order, or null for a
  /// practice Round (no flow) or a flow this version cannot play.
  List<int>? get _flowOrder {
    if (widget.round.roundType != RoundType.story &&
        widget.round.roundType != RoundType.sequence) {
      return null;
    }
    final flow = widget.round.flow;
    if (flow == null) return null;
    final nodeIds = flow.linearNodeIds();
    if (nodeIds == null) return null;
    final exercises = widget.round.exercises;
    final indexById = {
      for (var i = 0; i < exercises.length; i++) exercises[i].id: i,
    };
    return [
      for (final nodeId in nodeIds)
        if (indexById[flow.nodeById(nodeId)?.contentId] case final index?)
          index,
    ];
  }

  List<_ChoiceOption> _choiceOptionsFor(Exercise ex) {
    final correct = ex.canonicalEvaluation.correctItemIds.toSet();
    final options = [
      for (final item in ex.items)
        _ChoiceOption(item.value, correct.contains(item.id), item: item),
    ];
    _shuffleDifferentChoices(options);
    return options;
  }

  void _prepareExercise({required String trigger}) {
    final previousDiagnostic = _preparedAudioDiagnostic;
    if (previousDiagnostic != null) {
      unawaited(previousDiagnostic.dispose(outcome: 'target_changed'));
    }
    _preparedAudioDiagnostic = null;
    _preparedAudioPreparation = Future<void>.value();
    _suppressedAudioGeneration = null;
    _startedAudioGeneration = null;
    final generation = ++_preparedExerciseGeneration;
    final ex = _exercise;
    final f = _features = ExerciseFeatures(ex);
    _exerciseMascot = null;
    _answered = false;
    _lineAudioPlayed = false;
    _lastAnswerCorrect = false;
    _feedback = '';
    _displayedCorrection = '';
    _translationFeedback = const [];
    _translationFeedbackPartial = false;
    _acceptedDifferences = const [];
    _selected = null;
    _textController.clear();
    _builtOrder.clear();
    for (final c in _missingWordControllers) {
      c.dispose();
    }
    _missingWordControllers
      ..clear()
      ..addAll(
        List.generate(f.gapFieldTargets.length, (_) => TextEditingController()),
      );
    _matchingSelections.clear();
    _gapFill.clear();
    _armedGapId = null;
    _multiSelected.clear();
    _selectGapFill.clear();
    _selectArmedGapId = null;
    _assignPlacements.clear();
    _armedAssignItemId = null;
    _assignTileOrder = const [];
    if (f.primitive == ExercisePrimitive.assign) {
      _assignTileOrder = f.shuffleItems
          ? _shuffledItemIds(ex.items)
          : [for (final item in ex.items) item.id];
      for (final target in ex.targets) {
        _assignPlacements[target.id] = [];
      }
    }
    _gapTileOrder = f.arrangeInline ? _shuffledItemIds(ex.items) : const [];
    if (f.arrangeInline) {
      for (final element in ex.layout) {
        if (element.isTarget) _gapFill[element.targetId] = null;
      }
    }
    if (f.selectInline) {
      for (final element in ex.layout) {
        if (element.isTarget) _selectGapFill[element.targetId] = null;
      }
    }

    // One text field is focused here; several gap fields focus their first
    // one themselves.
    if (f.primitive == ExercisePrimitive.input && f.gapFieldTargets.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_answered) _textFocusNode.requestFocus();
      });
    }

    _choiceOptions = f.primitive == ExercisePrimitive.select
        ? _choiceOptionsFor(ex)
        : const [];
    _tokenOptions = f.primitive == ExercisePrimitive.arrange
        ? _shuffledTokens(ex)
        : const [];
    if (f.primitive == ExercisePrimitive.match) {
      final byId = <String, ExerciseItem>{
        for (final item in ex.items) item.id: item,
      };
      _matchingRightOptions = [];
      _matchingLeftPairs = [];
      for (final pair in ex.canonicalEvaluation.relations) {
        if (pair.length != 2) continue;
        final left = byId[pair[0]];
        final right = byId[pair[1]];
        if (left == null || right == null) continue;
        _matchingLeftPairs.add(
          _MatchPairView(
            leftId: left.id,
            leftLabel: left.label,
            leftImage: left.image,
            leftPlural: left.pictureIsPlural,
            rightId: right.id,
          ),
        );
        _matchingRightOptions.add(_MatchOption(right.id, right.value));
      }
      _matchingRightOptions.shuffle(_random);
      _matchingLeftPairs.shuffle(_random);
    } else {
      _matchingRightOptions = [];
      _matchingLeftPairs = [];
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || generation != _preparedExerciseGeneration) return;
      // An audio element with automatic playback is prepared now and plays
      // when the exercise becomes active; any other audio only warms the
      // synthesizer for the learner's own taps.
      final automatic = _automaticAudioOf(f);
      if (automatic != null) {
        if (automatic.text.isNotEmpty) {
          final diagnostic = AudioDiagnosticLifecycle.start(
            kind: 'round_activation',
            enabled: !widget.previewMode,
          );
          _preparedAudioDiagnostic = diagnostic;
          final active = _isPreparedExerciseActive(ex, generation);
          final uiState = _learnerAudioUiState;
          _preparedAudioPreparation = () async {
            await _recordRoundAudioEvent(
              diagnostic,
              'preparation',
              outcome: 'prepared',
              exercise: ex,
              active: active,
              trigger: trigger,
              uiState: uiState,
            );
            await _recordRoundAudioEvent(
              diagnostic,
              'source_resolution',
              outcome: 'eligibility_confirmed',
              exercise: ex,
              active: active,
              trigger: trigger,
              backend: widget.course.audioMode,
              uiState: uiState,
            );
          }();
          await _preparedAudioPreparation;
          await _activatePreparedAudio(
            ex,
            generation,
            trigger: 'exercise_prepared',
          );
        }
      } else {
        await _prepareTts();
      }
    });
  }

  String get _learnerAudioUiState => _lessonIntro != null && !_introAcknowledged
      ? 'before_you_start'
      : 'exercise_active';

  bool _isPreparedExerciseActive(Exercise exercise, int generation) {
    if (!mounted || generation != _preparedExerciseGeneration) return false;
    if (_exercise.id != exercise.id) return false;
    // The Preview shows the Before you start card too (Build 257): its
    // first exercise stays silent behind it until Continue (owner report of
    // 9 October 2026).
    if (widget.previewMode) return _learnerAudioUiState == 'exercise_active';
    return _ready && _learnerAudioUiState == 'exercise_active';
  }

  Future<void> _recordRoundAudioEvent(
    AudioDiagnosticLifecycle diagnostic,
    String phase, {
    required String outcome,
    required Exercise exercise,
    required bool active,
    required String trigger,
    String? backend,
    String? uiState,
  }) => diagnostic.event(
    phase,
    outcome: outcome,
    backend: backend,
    uiState: uiState ?? _learnerAudioUiState,
    targetExerciseId: exercise.id,
    exerciseType: ExerciseFeatures(exercise).kind.name,
    prepared: true,
    active: active,
    trigger: trigger,
  );

  Future<void> _activatePreparedAudio(
    Exercise exercise,
    int generation, {
    required String trigger,
  }) async {
    final diagnostic = _preparedAudioDiagnostic;
    if (diagnostic == null || generation != _preparedExerciseGeneration) return;
    await _preparedAudioPreparation;
    if (diagnostic != _preparedAudioDiagnostic ||
        generation != _preparedExerciseGeneration) {
      return;
    }
    final active = _isPreparedExerciseActive(exercise, generation);
    if (!active) {
      if (_suppressedAudioGeneration == generation) return;
      _suppressedAudioGeneration = generation;
      await _recordRoundAudioEvent(
        diagnostic,
        'playback',
        outcome: 'suppressed_not_active',
        exercise: exercise,
        active: false,
        trigger: trigger,
      );
      return;
    }
    if (_startedAudioGeneration == generation) return;
    _startedAudioGeneration = generation;
    await _recordRoundAudioEvent(
      diagnostic,
      'activation',
      outcome: 'active',
      exercise: exercise,
      active: true,
      trigger: trigger,
    );
    await _recordRoundAudioEvent(
      diagnostic,
      'playback',
      outcome: 'requested',
      exercise: exercise,
      active: true,
      trigger: trigger,
    );
    final played = await _speak();
    await _recordRoundAudioEvent(
      diagnostic,
      'playback',
      outcome: played ? 'completed' : 'failed',
      exercise: exercise,
      active: true,
      trigger: trigger,
    );
    await diagnostic.dispose(outcome: played ? 'completed' : 'failed');
  }

  void _shuffleDifferentInts(List<int> values) {
    if (values.length < 2) return;
    // A valid random shuffle may legitimately reproduce the source order.
    values.shuffle(_random);
  }

  void _shuffleDifferentChoices(List<_ChoiceOption> values) {
    if (values.length < 2) return;
    // A valid random shuffle may legitimately reproduce the source order.
    values.shuffle(_random);
  }

  List<String> _shuffledTokens(Exercise ex) {
    final tokens = [
      for (final item in ex.items)
        if (item.value.isNotEmpty) item.value,
    ];
    if (tokens.length < 2) return tokens;

    // A valid random shuffle may legitimately reproduce the source order,
    // including the correct order in a sentence-building exercise.
    tokens.shuffle(_random);
    return tokens;
  }

  List<String> _shuffledItemIds(List<ExerciseItem> items) {
    final ids = items.map((item) => item.id).toList();
    if (ids.length < 2) return ids;
    // A valid random shuffle may legitimately reproduce the source order.
    ids.shuffle(_random);
    return ids;
  }

  Future<void> _prepareTts() async {
    final text = _features.primaryAudioText;
    if (text == null || text.isEmpty) return;
    if (widget.course.audioMode == 'tts' ||
        (widget.course.audioMode == 'hybrid' &&
            _recordedAudio.segment(text, widget.course.audioLibrary) == null)) {
      await _ttsCache.synthesizeCached(
        text: text,
        language: _voiceFor(_features.primaryAudioLanguage),
        applyLearnerSettings: !widget.previewMode,
      );
    }
  }

  Future<void> _speakText(String text) async {
    if (text.trim().isEmpty) return;
    final ok = await _playCourseAudio(
      text,
      language: _features.audioLanguageOf(text),
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text(_audioFailureDescription),
        ),
      );
    }
  }

  /// The pause between two dialogue lines read aloud (Read and answer,
  /// Build 256 Revision 7 fourth follow-up; owner decision: a second).
  static const dialogueLinePause = Duration(seconds: 1);

  /// Reads a Read and answer dialogue aloud, each line in turn with
  /// [dialogueLinePause] between them, and stops when the learner moves on.
  /// The read-aloud is optional: with Audio Exercises or Text-to-speech off
  /// it stays silent and reports nothing.
  Future<bool> _speakDialogue() async {
    final lines = _features.dialogueAudio;
    if (lines.isEmpty || !_optionalAudioEnabled) return false;
    final exercise = _exercise;
    var ok = true;
    for (var i = 0; i < lines.length; i++) {
      if (i > 0) await Future<void>.delayed(dialogueLinePause);
      if (!mounted || !identical(_exercise, exercise)) return ok;
      final line = lines[i];
      ok = await _playCourseAudio(line.text, language: line.language) && ok;
    }
    return ok;
  }

  Future<bool> _speak() async {
    // A dialogue read aloud automatically plays line by line.
    if (_features.automaticAudio?.role == 'dialogue_turn') {
      return _speakDialogue();
    }
    final text = _features.primaryAudioText;
    if (text == null || text.isEmpty) return false;
    final line = _features.kind == LearnerExerciseKind.dialogueLine;
    final ok = await _playCourseAudio(
      text,
      language: line
          ? _lineLanguage(_features)
          : _features.primaryAudioLanguage,
      voice: line ? _lineSpeaker(_features).voice : null,
    );
    if (ok && line && mounted) {
      setState(() => _lineAudioPlayed = true);
    }
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text(_audioFailureDescription),
        ),
      );
    }
    return ok;
  }

  String get _audioFailureDescription => widget.course.audioMode == 'recorded'
      ? 'Recorded audio unavailable. Check this Course’s Audio Library mappings and referenced MP3 files.'
      : _ttsCache.lastFailureDescription ??
            'Audio unavailable. Enable Text-to-speech in Settings and check the system voice for this course language. On Linux, install eSpeak NG or eSpeak.';

  /// The first answer an answer expression accepts, else the expression.
  /// The expansion capitalizes a sentence start; a gap keeps the author's
  /// small first letter.
  String _firstVariant(String expression) {
    String variant;
    try {
      variant =
          _answerEngine.validAnswers([expression]).firstOrNull ?? expression;
    } on AnswerExpressionException {
      return expression;
    }
    final letter = RegExp(r'\p{L}', unicode: true);
    final authored = letter.firstMatch(expression)?.group(0);
    final first = letter.firstMatch(variant);
    if (authored == null ||
        first == null ||
        authored != authored.toLowerCase()) {
      return variant;
    }
    return variant.replaceRange(
      first.start,
      first.end,
      first.group(0)!.toLowerCase(),
    );
  }

  String _correctAnswerText(Exercise ex) {
    final f = _features;
    switch (ex.primitive) {
      case ExercisePrimitive.select:
        if (f.hasInlineTargets) return _gapAnswerText(ex);
        if (f.multipleSelection) return _selectMultiAnswerText(ex);
        final value = _itemValue(
          ex,
          ex.canonicalEvaluation.correctItemIds.firstOrNull,
        );
        return value.isEmpty ? _t('seeCourseAnswer') : value;
      case ExercisePrimitive.presentation:
        return _t('reviewTheFlashcard');
      case ExercisePrimitive.input:
        if (f.gapFieldTargets.isNotEmpty) {
          // The first answer each gap accepts, written out: a gap answer
          // may use the answer syntax, such as [il|un] gatto (Build 259
          // Revision 3).
          final words = [
            for (final target in f.gapFieldTargets)
              ...?f.answersFor(target.id)?.answers.take(1).map(_firstVariant),
          ];
          if (words.isNotEmpty) return words.join(' / ');
          break;
        }
        if (_displayedCorrection.isNotEmpty) return _displayedCorrection;
        // Written from audio: the authored answer first, then the spoken
        // text; otherwise the spoken text is the fuller answer.
        final candidates = f.kind == LearnerExerciseKind.inputListenWrite
            ? [...f.acceptedAnswers, ...f.literalAnswers]
            : [...f.literalAnswers, ...f.acceptedAnswers];
        final first = candidates
            .map((answer) => answer.trim())
            .where((answer) => answer.isNotEmpty)
            .firstOrNull;
        if (first != null) return first;
        break;
      case ExercisePrimitive.arrange:
        if (f.hasInlineTargets) return _gapAnswerText(ex);
        final orders = ex.canonicalEvaluation.correctOrders;
        if (orders.isEmpty) break;
        if (f.showAlternatives == FeedbackAlternatives.all) {
          return orders.map((order) => order.text).join(' / ');
        }
        final joined = _orderText(ex, orders.first);
        if (joined.isNotEmpty) return joined;
        break;
      case ExercisePrimitive.match:
        final pairs = _pairTexts(ex);
        if (pairs.isNotEmpty) {
          return pairs.map((pair) => '${pair[0]} = ${pair[1]}').join('; ');
        }
        break;
      case ExercisePrimitive.assign:
        final answer = _assignAnswerText(ex, {
          for (final entry in f.assignmentsByTarget.entries)
            entry.key: entry.value.toList(),
        });
        if (answer.isNotEmpty) return answer;
        break;
      case ExercisePrimitive.speak:
      case ExercisePrimitive.ink:
      case ExercisePrimitive.submit:
        break;
    }
    return _t('seeCourseAnswer');
  }

  String _itemValue(Exercise ex, String? itemId) {
    if (itemId == null) return '';
    return ex.items
            .where((item) => item.id == itemId)
            .map((item) => item.label)
            .firstOrNull ??
        '';
  }

  /// An ordered answer as the learner would build it: its blocks joined
  /// with the exercise's joiner.
  String _orderText(Exercise ex, OrderedAnswer order) => order.itemIds
      .map((id) => _itemValue(ex, id))
      .where((value) => value.isNotEmpty)
      .join(_features.joinsWithoutSpaces ? '' : ' ');

  /// The Match relations as [left value, right value] pairs.
  List<List<String>> _pairTexts(Exercise ex) => [
    for (final pair in ex.canonicalEvaluation.relations)
      if (pair.length == 2) [_itemValue(ex, pair[0]), _itemValue(ex, pair[1])],
  ];

  String _gapAnswerText(Exercise ex) {
    final assignments = _features.targetAssignments;
    if (assignments.isEmpty) return _t('seeCourseAnswer');
    return assignments.entries
        .map((entry) => _itemValue(ex, entry.value))
        .where((value) => value.isNotEmpty)
        .join(' ');
  }

  String _selectMultiAnswerText(Exercise ex) {
    final correctIds = ex.canonicalEvaluation.correctItemIds.toSet();
    final values = ex.items
        .where((item) => correctIds.contains(item.id))
        .map((item) => item.value)
        .where((value) => value.isNotEmpty)
        .toList();
    return values.isEmpty ? _t('seeCourseAnswer') : values.join(' / ');
  }

  String _answerState() {
    if (_selected != null && _selected! < _choiceOptions.length) {
      return 'Selected choice ${_selected! + 1}: ${_choiceOptions[_selected!].text}';
    }
    if (_multiSelected.isNotEmpty) {
      return 'Selected choices: ${_multiSelected.map((i) => _choiceOptions[i].text).join(' | ')}';
    }
    if (_selectGapFill.values.any((itemId) => itemId != null)) {
      return 'Gaps: ${_selectGapFill.entries.map((e) => '${e.key}=${_itemValue(_exercise, e.value)}').join(' | ')}';
    }
    if (_textController.text.trim().isNotEmpty) {
      return 'Typed answer: ${_textController.text.trim()}';
    }
    if (_builtOrder.isNotEmpty) return 'Word order: ${_builtOrder.join(' ')}';
    if (_gapFill.values.any((itemId) => itemId != null)) {
      return 'Gaps: ${_gapFill.entries.map((e) => '${e.key}=${_itemValue(_exercise, e.value)}').join(' | ')}';
    }
    if (_missingWordControllers.any((c) => c.text.trim().isNotEmpty)) {
      return 'Missing words: ${_missingWordControllers.map((c) => c.text.trim()).join(' | ')}';
    }
    if (_matchingSelections.isNotEmpty) {
      return 'Matches: ${_matchingSelections.entries.map((e) => '${e.key}=${e.value}').join(' | ')}';
    }
    return _answered ? _feedback : 'Not answered yet';
  }

  Future<void> _copyReport(ReportKind kind) async {
    await _reports.copyExerciseReport(
      kind: kind,
      course: widget.course,
      lesson: widget.lesson,
      round: widget.round,
      exercise: _exercise,
      exerciseIndex: _exerciseIndex,
      screen: _reviewPhase ? 'Round review' : 'Round',
      answerState: _answerState(),
    );
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        duration: Duration(seconds: 8),
        content: Text(
          'Copied to clipboard. You can paste it into your report.',
        ),
      ),
    );
  }

  void _showReportSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Report a problem',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              const Text(
                'Choose the problem type. QuisquisLingo will copy the exercise and its exact course location to the clipboard. Add your description and paste it into your report.',
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: const Text('Course error'),
                subtitle: const Text(
                  'Wrong answer, typo, translation, audio, instruction or other course content.',
                ),
                onTap: () => _copyReport(ReportKind.courseError),
              ),
              ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: const Text('App bug'),
                subtitle: const Text(
                  'Something does not work, display or respond as expected.',
                ),
                onTap: () => _copyReport(ReportKind.bug),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mark(bool correct) {
    if (_answered || _timedOut) return;
    if (widget.round.roundType == RoundType.timed &&
        _timedDeadline != null &&
        !_timedNow.isBefore(_timedDeadline!)) {
      _expireTimedAttempt();
      return;
    }
    setState(() {
      _answered = true;
      _lastAnswerCorrect = correct;
      _feedback = correct ? _t('correct') : _t('incorrect');
      if (!correct) _errorsThisAttempt++;
      if (!_reviewPhase) {
        if (correct) {
          _firstPassCorrect++;
          _firstPassDifficulty += ExerciseDifficulty.of(_exercise)?.value ?? 0;
        } else {
          _wrongFirstPass.add(_exerciseIndex);
        }
      }
      if (widget.round.roundType == RoundType.test) {
        _testResults.add((
          correct: correct,
          correction: correct ? '' : _correctAnswerText(_exercise),
        ));
      }
    });
    if (widget.round.roundType == RoundType.timed &&
        _position + 1 == _queue.length &&
        (_reviewPhase || _wrongFirstPass.isEmpty)) {
      _timedTicker?.cancel();
      _timedExpiryTimer?.cancel();
      _timedCompletedBeforeZero = true;
    }
    if (widget.round.roundType != RoundType.test) _revealFeedback();
  }

  /// Scrolls the page down to the feedback panel, the last thing on it,
  /// once it is drawn (Build 259 Revision 3). A scrolling Story keeps its
  /// own scroll.
  void _revealFeedback() {
    if (_storyScrolls) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_pageScroll.hasClients) return;
      final position = _pageScroll.position;
      if (position.pixels >= position.maxScrollExtent) return;
      await _pageScroll.animateTo(
        position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
      // The list builds lazily: its end may have grown on the way down.
      if (mounted &&
          _pageScroll.hasClients &&
          _pageScroll.position.pixels < _pageScroll.position.maxScrollExtent) {
        _pageScroll.jumpTo(_pageScroll.position.maxScrollExtent);
      }
    });
  }

  void _flashcardResult({required bool reviewAgain}) {
    if (_answered) return;
    setState(() {
      _answered = true;
      _lastAnswerCorrect = true; // Flashcards have no correct/incorrect answer.
      if (reviewAgain) {
        _feedback = _t('cardAgainLater');
        _queue.add(_exerciseIndex);
      } else {
        _feedback = _t('cardReviewed');
      }
    });
    _revealFeedback();
  }

  void _answerChoice(int displayedIndex) {
    _selected = displayedIndex;
    _mark(_choiceOptions[displayedIndex].correct);
  }

  void _submitFill() {
    if (_answered) return;
    final enteredWord = _textController.text.trim();
    if (enteredWord.isEmpty) return;
    final f = _features;
    final accepted = <String>{...f.acceptedAnswers};
    final normalization = f.normalization;
    var evaluation = _answerEngine.evaluate(
      enteredWord,
      accepted,
      normalization: normalization,
      typoTolerance: f.toleratesTypos,
    );
    // Literal answers (a spoken phrase, for instance) are accepted verbatim,
    // never parsed as author expressions.
    if (!evaluation.isCorrect) {
      for (final literal in f.literalAnswers) {
        if (literal.trim().isEmpty) continue;
        final result = _answerEngine.evaluateLiteral(
          enteredWord,
          literal,
          normalization: normalization,
        );
        if (result.isCorrect || accepted.isEmpty) evaluation = result;
        if (result.isCorrect) break;
      }
    }
    _displayedCorrection = evaluation.matchedAcceptedAnswer;
    _acceptedDifferences = evaluation.acceptedDifferences;
    if (f.showAlternatives == FeedbackAlternatives.ranked) {
      final ranked = _answerEngine.rankedAnswers(
        enteredWord,
        accepted,
        normalization: normalization,
      );
      final matched = _answerEngine.normalizedAnswer(
        evaluation.matchedAcceptedAnswer,
        normalization: normalization,
      );
      final remaining = evaluation.isCorrect
          ? ranked
                .where(
                  (answer) =>
                      _answerEngine.normalizedAnswer(
                        answer,
                        normalization: normalization,
                      ) !=
                      matched,
                )
                .toList()
          : ranked;
      final limit = evaluation.isCorrect ? 2 : 3;
      _translationFeedback = remaining.take(limit).toList();
      _translationFeedbackPartial = remaining.length > limit;
    }
    _mark(evaluation.isCorrect);
  }

  void _submitOrder() {
    final built = _builtOrder.join(_features.joinsWithoutSpaces ? '' : ' ');
    _mark(
      _exercise.canonicalEvaluation.correctOrders.any(
        (order) => _answerEngine.evaluateLiteral(built, order.text).isCorrect,
      ),
    );
  }

  void _submitMatching() {
    if (_exercise.canonicalEvaluation.relations.isEmpty) {
      _mark(false);
      return;
    }
    _mark(_matchingReadsAsExpected());
  }

  /// Whether the learner's pairs read as the expected pairs, for Match and
  /// Listen and match alike. A Match may repeat a value (Ciao = Hi, Ciao =
  /// Bye; owner decision of 6 October 2026, Build 265 Revision 4): two rows,
  /// two sounds or two answers then look or sound the same, so whichever of
  /// the identical ones was used is right. Each side is compared as the
  /// learner sees it: a row by its text and picture, an answer by its text;
  /// an item with neither is told apart by its ID.
  bool _matchingReadsAsExpected() {
    final rightLabels = {
      for (final option in _matchingRightOptions) option.id: option.label,
    };
    String leftKey(_MatchPairView pair) =>
        pair.leftLabel.isNotEmpty || pair.leftImage.isNotEmpty
        // A plural picture looks unlike the same picture alone.
        ? '${pair.leftLabel}\u0000${pair.leftImage}\u0000${pair.leftPlural}'
        : pair.leftId;
    String rightKey(String id) {
      final label = rightLabels[id] ?? '';
      return label.isNotEmpty ? label : id;
    }

    final expected = <String, int>{};
    final made = <String, int>{};
    for (final pair in _matchingLeftPairs) {
      final selected = _matchingSelections[pair.leftId];
      if (selected == null) return false;
      final wanted = '${leftKey(pair)}\u0001${rightKey(pair.rightId)}';
      final given = '${leftKey(pair)}\u0001${rightKey(selected)}';
      expected[wanted] = (expected[wanted] ?? 0) + 1;
      made[given] = (made[given] ?? 0) + 1;
    }
    return expected.length == made.length &&
        expected.entries.every((entry) => made[entry.key] == entry.value);
  }

  /// What the learner answered, for the finished-item card of a scrolling
  /// Story; null when the exercise kind keeps no single answer text.
  String? _learnerAnswerText() {
    final selected = _selected;
    if (selected != null && selected < _choiceOptions.length) {
      return _choiceOptions[selected].text;
    }
    if (_builtOrder.isNotEmpty) {
      return _builtOrder.join(_features.joinsWithoutSpaces ? '' : ' ');
    }
    if (_assignPlacements.values.any((placed) => placed.isNotEmpty)) {
      return _assignAnswerText(_exercise, _assignPlacements);
    }
    final typed = _textController.text.trim();
    return typed.isEmpty ? null : typed;
  }

  /// "Animals: gatto, cane · Plants: rosa" for the given placements; targets
  /// are named by their layout label, else by their position.
  String _assignAnswerText(Exercise ex, Map<String, List<String>> placements) {
    final f = ExerciseFeatures(ex);
    final parts = <String>[];
    for (var i = 0; i < ex.targets.length; i++) {
      final target = ex.targets[i];
      final items = (placements[target.id] ?? const <String>[])
          .map((id) => _itemValue(ex, id))
          .where((value) => value.isNotEmpty)
          .toList();
      if (items.isEmpty) continue;
      final label = f.targetLabel(target.id);
      parts.add(
        '${label.isEmpty ? _assignTargetFallbackLabel(f, i) : label}: ${items.join(', ')}',
      );
    }
    return parts.join(' · ');
  }

  String _assignTargetFallbackLabel(ExerciseFeatures f, int index) =>
      switch (f.assignTargetMode) {
        AssignTargetMode.slots => _t('slotNumber', {'n': index + 1}),
        AssignTargetMode.gaps => _t('gapNumber', {'n': index + 1}),
        _ => _t('groupNumber', {'n': index + 1}),
      };

  void _logStoryItem() {
    if (!_storyScrolls) return;
    final ex = _exercise;
    final kind = _features.kind;
    // Build 256 Revision 5: lines and covers stay as they were shown; with
    // the dialogue log nothing else is kept.
    if (kind == LearnerExerciseKind.dialogueLine) {
      final audio = _features.lineAudio;
      _storyLog.add(
        _StoryEntry(
          heading: '',
          prompt: _features.lineText.isNotEmpty
              ? _features.lineText
              : (audio?.text ?? ''),
          answer: null,
          correct: true,
          evaluable: false,
          kind: kind,
          speaker: _lineSpeaker(_features),
          language: _lineLanguage(_features),
        ),
      );
      return;
    }
    if (kind == LearnerExerciseKind.storyCover) {
      _storyLog.add(
        _StoryEntry(
          heading: widget.round.flow?.title ?? '',
          prompt: _features.coverTitle,
          answer: null,
          correct: true,
          evaluable: false,
          kind: kind,
          picture: _features.illustrationAsset,
          language: _features.textLanguageOf('title'),
        ),
      );
      return;
    }
    if ((widget.round.flow?.log ?? FlowLog.all) == FlowLog.dialogue) return;
    if (!ex.isExecutable) {
      _storyLog.add(
        _StoryEntry(
          heading: 'Not playable in this version',
          prompt: _notExecutablePrompt(ex),
          answer: null,
          correct: true,
          evaluable: false,
        ),
      );
      return;
    }
    _storyLog.add(
      _StoryEntry(
        // A Story shows no exercise title, only its instruction; a
        // sequence keeps the title (Build 261 Revision 3).
        heading: widget.round.isStory
            ? (_promptAsInstruction
                  ? ExerciseCopyService.displayPrompt(
                      widget.course,
                      _displayedPrompt,
                    )
                  : ExerciseCopyService.instructionForExercise(
                      widget.course,
                      ex,
                    ))
            : ExerciseCopyService.title(widget.course, ex),
        headingIsInstruction: widget.round.isStory,
        // An authored instruction heading a Story's entry is not repeated.
        prompt:
            _displayedPrompt.isNotEmpty &&
                !(widget.round.isStory && _promptAsInstruction)
            ? ExerciseCopyService.displayPrompt(widget.course, _displayedPrompt)
            : (_features.questionText.isNotEmpty
                  ? _features.questionText
                  : _features.inlineSentence),
        answer: _learnerAnswerText(),
        correct: _lastAnswerCorrect,
        evaluable: ex.primitive != ExercisePrimitive.presentation,
      ),
    );
  }

  /// Brings the active item ("Now") near the top of the page after
  /// Continue: a fifth of the viewport, at most [storyScrollMargin] pixels,
  /// stays above it, so the tail of the previous item remains readable
  /// (owner decision, 28 September 2026).
  static const double storyScrollMargin = 120;

  void _scrollStoryToEnd() {
    if (!_storyScrolls) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final now = _storyNowKey.currentContext;
      final render = now?.findRenderObject();
      final viewport = render == null
          ? null
          : RenderAbstractViewport.maybeOf(render);
      if (render != null && viewport != null && _storyScroll.hasClients) {
        final position = _storyScroll.position;
        final margin = min(storyScrollMargin, position.viewportDimension * 0.2);
        final reveal = viewport.getOffsetToReveal(render, 0).offset - margin;
        _storyScroll.animateTo(
          reveal.clamp(0.0, position.maxScrollExtent),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOut,
        );
      } else if (_storyScroll.hasClients) {
        _storyScroll.animateTo(
          _storyScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// The marker above the active item of a scrolling Story.
  /// The step count, once, above the title block; after the first step
  /// only an invisible anchor marks the active item, which the page scrolls
  /// to the top (Build 259 Revision 5, owner decision: no "Now · step k of
  /// N" line).
  Widget _storyNowMarker() => _storyLog.isEmpty
      ? _storyStepsLine(key: _storyNowKey)
      : SizedBox(key: _storyNowKey, width: double.infinity);

  Widget _storyStepsLine({Key? key}) => Padding(
    key: key,
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Icon(
          Icons.play_arrow_rounded,
          size: 18,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 4),
        Text(
          _t('steps.$_nounKey', {'n': _queue.length}),
          key: const Key('story-now'),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
        const Expanded(child: Divider(indent: 8)),
      ],
    ),
  );

  Widget _storyEntryCard(_StoryEntry entry, int number) {
    switch (entry.kind) {
      case LearnerExerciseKind.dialogueLine:
        return Padding(
          key: ValueKey('story-entry-$number'),
          padding: const EdgeInsets.only(bottom: 12),
          child: _lineBubble(
            speaker: entry.speaker!,
            text: entry.prompt,
            language: entry.language,
          ),
        );
      case LearnerExerciseKind.storyCover:
        return Container(
          key: ValueKey('story-entry-$number'),
          margin: const EdgeInsets.only(bottom: 12),
          child: _coverCard(
            title: entry.heading,
            line: entry.prompt,
            picture: entry.picture,
            lineLanguage: entry.language,
          ),
        );
      default:
        return _storyExerciseCard(entry, number);
    }
  }

  Widget _storyExerciseCard(_StoryEntry entry, int number) => Container(
    key: ValueKey('story-entry-$number'),
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: _exercisePanelColor.withValues(alpha: .6),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                entry.heading,
                style: entry.headingIsInstruction
                    ? Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      )
                    : Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: .7,
                      ),
              ),
            ),
            if (entry.evaluable)
              Icon(
                entry.correct ? Icons.check_circle : Icons.cancel,
                color: entry.correct
                    ? Colors.green.shade700
                    : Colors.red.shade700,
                size: 20,
              ),
          ],
        ),
        if (entry.prompt.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(entry.prompt, style: Theme.of(context).textTheme.bodyLarge),
        ],
        if (entry.answer != null) ...[
          const SizedBox(height: 6),
          Text(
            entry.answer!,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ],
    ),
  );

  Future<void> _next() async {
    if (_finishing || _timedOut) return;
    _logStoryItem();
    if (_position + 1 < _queue.length) {
      setState(() => _position++);
      _prepareExercise(trigger: 'exercise_advanced');
      _scrollStoryToEnd();
      return;
    }
    if (_playsInOrder && !widget.previewMode && !_exercise.isExecutable) {
      // Plan A.6: a Story ending on a step this version cannot play ends
      // there and nothing is recorded.
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          key: const Key('story-ends-unplayable'),
          title: Text('$_roundNoun not finished'),
          content: Text(
            'This version of QuisquisLingo cannot play the last step of this $_roundNoun, so the $_roundNoun ends here and nothing was recorded. A later version will play it.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop();
      return;
    }

    if (!_reviewPhase &&
        _wrongFirstPass.isNotEmpty &&
        !_playsInOrder &&
        widget.round.roundType != RoundType.test) {
      _timedReviewDialogOpen = true;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text(_t('reviewMistakesTitle')),
          content: Text(_t('reviewMistakesBody')),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_t('continue')),
            ),
          ],
        ),
      );
      _timedReviewDialogOpen = false;
      if (!mounted || _timedOut) return;
      setState(() {
        _reviewPhase = true;
        _queue = _wrongFirstPass.toList();
        _shuffleDifferentInts(_queue);
        _position = 0;
      });
      _prepareExercise(trigger: 'review_started');
      return;
    }

    if (widget.round.roundType == RoundType.test && !_reviewPhase) {
      final threshold = widget.round.testPassingPercent;
      final percent = _testResults.isEmpty
          ? 0
          : (100 *
                    _testResults.where((r) => r.correct).length /
                    _testResults.length)
                .round();
      // A passed Test is celebrated with confetti (Build 264 Revision 3,
      // owner decisions of 5 October 2026): its threshold reached, or,
      // without one, every answer right.
      final passed =
          _testResults.isNotEmpty &&
          (threshold == null
              ? _testResults.every((r) => r.correct)
              : percent >= threshold);
      final animationsEnabled = await _settings.areAnimationsEnabled();
      if (!mounted) return;
      final confetti =
          passed &&
          ConfettiBurst.allowed(context, animationsEnabled: animationsEnabled);
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => Stack(
          fit: StackFit.expand,
          children: [
            AlertDialog(
              key: const Key('test-results'),
              title: Text(
                _t(
                  threshold == null
                      ? 'testResults'
                      : percent >= threshold
                      ? 'testPassed'
                      : 'testBelowThreshold',
                  {'percent': percent},
                ),
              ),
              content: SizedBox(
                width: 380,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (var i = 0; i < _testResults.length; i++)
                      ListTile(
                        title: Text(
                          _t('testQuestion', {
                            'n': i + 1,
                            'status': _t(
                              _testResults[i].correct ? 'correct' : 'incorrect',
                            ),
                          }),
                        ),
                        subtitle: _testResults[i].correction.isEmpty
                            ? null
                            : Text(
                                _t('correctAnswer', {
                                  'answer': _testResults[i].correction,
                                }),
                              ),
                      ),
                  ],
                ),
              ),
              actions: [
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text(_t('continue')),
                ),
              ],
            ),
            if (confetti) const ConfettiBurst(key: Key('test-passed-confetti')),
          ],
        ),
      );
    }
    if (!mounted || _timedOut) return;
    _timedTicker?.cancel();
    _timedExpiryTimer?.cancel();
    setState(() => _finishing = true);
    var persistenceStarted = false;
    var persistenceCompleted = false;
    try {
      if (widget.previewMode || widget.viewOnlyMode) {
        if (!mounted) return;
        final viewOnly = widget.viewOnlyMode;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(viewOnly ? 'View Only result' : 'Preview complete'),
            content: Text(
              '${viewOnly ? 'Preview' : 'Temporary'} result: ${_errorsThisAttempt == 0 ? 'perfect' : '$_errorsThisAttempt error${_errorsThisAttempt == 1 ? '' : 's'}'}. ${viewOnly ? 'No learning progress or rewards were recorded.' : 'No learner progress was recorded.'}',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
        );
        if (mounted) Navigator.of(context).pop();
        return;
      }
      final code = CourseService.codeForCourse(widget.course);
      String? completedLessonId;
      if (widget.completeLessonOnFinish && widget.lesson.rounds.isNotEmpty) {
        final completedLessons = await _progress.getCompletedLessons(
          courseId: widget.course.courseId,
        );
        final completedRounds = await _progress.getCompletedRounds(
          courseId: widget.course.courseId,
        );
        final completesLesson = widget.lesson.rounds.every(
          (round) =>
              round.id == widget.round.id || completedRounds.contains(round.id),
        );
        if (completesLesson &&
            !completedLessons.contains(widget.lesson.lessonId)) {
          completedLessonId = widget.lesson.lessonId;
        }
      }
      persistenceStarted = true;
      final completion = await _completion.completeRound(
        LearningCompletionRequest(
          roundId: widget.round.id,
          lessonId: widget.lesson.lessonId,
          courseId: widget.course.courseId,
          courseCode: code,
          completedLessonId: completedLessonId,
          readAttemptFacts: () => LearningCompletionAttemptFacts(
            errorsThisAttempt: _errorsThisAttempt,
            firstPassCorrect: _firstPassCorrect,
            evaluableExerciseCount: _evaluableExerciseCount,
            wasCompletedAtStart: _wasCompleted,
            ttsWasSkipped: _ttsWasSkipped,
            firstPassDifficulty: _firstPassDifficulty,
          ),
          claimOnTimeBonus:
              widget.round.roundType == RoundType.timed &&
                  _timedCompletedBeforeZero &&
                  _activeTimedLimitSeconds != null
              ? () => _progress.claimTimedLimit(
                  widget.round.id,
                  _activeTimedLimitSeconds!,
                  courseId: widget.course.courseId,
                )
              : null,
        ),
        onNewLaurel: () async {
          if (await _settings.areSoundEffectsEnabled()) {
            await _sounds.playDuelWin();
          }
        },
        getWeeklyXpTarget: _settings.getWeeklyXpTarget,
      );
      persistenceCompleted = true;
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(_t('completed.$_nounKey')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            // A Round or Story without a scored exercise (cards, covers,
            // lines only) awards nothing and shows no XP arithmetic (owner
            // decision, 28 September 2026).
            children: completion.evaluableExerciseCount == 0
                ? [
                    Text(
                      _t('nothingToScore.$_nounKey'),
                      key: const Key('round-completed-unscored'),
                    ),
                    if (completion.lessonCompletionXp > 0) ...[
                      Text(
                        _t('summary.lessonCompleted', {
                          'xp': completion.lessonCompletionXp,
                        }),
                      ),
                      Text(_t('summary.total', {'xp': completion.awardedXp})),
                    ],
                    if (_versionSkipped > 0) _versionSkippedLine(),
                  ]
                : [
                    Text(
                      _t('summary.correctAnswers', {
                        'correct': completion.firstPassCorrect,
                        'total': completion.evaluableExerciseCount,
                        'xp': completion.roundXp.correctAnswerXp,
                      }),
                    ),
                    if (completion.roundXp.difficultyBonusXp > 0)
                      Text(
                        _t('summary.difficultyBonus', {
                          'xp': completion.roundXp.difficultyBonusXp,
                        }),
                        key: const Key('round-completed-difficulty-bonus'),
                      ),
                    if (completion.roundXp.onTimeBonusXp > 0)
                      Text(
                        _t('summary.onTimeBonus', {
                          'xp': completion.roundXp.onTimeBonusXp,
                        }),
                        key: const Key('round-completed-on-time-bonus'),
                      ),
                    if (completion.roundXp.perfectBonusXp > 0)
                      Text(
                        _t('summary.perfectBonus', {
                          'xp': completion.roundXp.perfectBonusXp,
                        }),
                      ),
                    if (completion.roundXp.laurelBonusXp > 0)
                      Text(
                        _t('summary.firstLaurel', {
                          'xp': completion.roundXp.laurelBonusXp,
                        }),
                      ),
                    if (completion.lessonCompletionXp > 0)
                      Text(
                        _t('summary.lessonCompleted', {
                          'xp': completion.lessonCompletionXp,
                        }),
                      ),
                    Text(_t('summary.total', {'xp': completion.awardedXp})),
                    if (_versionSkipped > 0) _versionSkippedLine(),
                  ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(_t('continue')),
            ),
          ],
        ),
      );
      if (mounted &&
          completion.crossedWeeklyXpTarget &&
          await _completion.claimWeeklyGoalCelebration()) {
        if (await _settings.areSoundEffectsEnabled()) {
          await _sounds.playDuelWin();
        }
        final animationsEnabled = await _settings.areAnimationsEnabled();
        if (!mounted) return;
        // Confetti over the dialog (Build 261 Revision 0).
        final confetti = ConfettiBurst.allowed(
          context,
          animationsEnabled: animationsEnabled,
        );
        await showDialog<void>(
          context: context,
          builder: (ctx) => Stack(
            fit: StackFit.expand,
            children: [
              AlertDialog(
                title: Text(_t('weeklyGoalReached')),
                content: Text(
                  '${completion.weeklyXpAfter} / ${completion.weeklyXpTarget} XP',
                ),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(_t('continue')),
                  ),
                ],
              ),
              if (confetti)
                const ConfettiBurst(key: Key('weekly-goal-confetti')),
            ],
          ),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error, stackTrace) {
      await CrashLogService.instance.record(
        error,
        stackTrace,
        source: 'RoundScreen._next',
      );
      if (!mounted) return;
      if (persistenceCompleted) {
        Navigator.of(context).pop(true);
        return;
      }
      if (!persistenceStarted) setState(() => _finishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 8),
          content: Text(
            persistenceStarted
                ? 'Round completion did not finish safely. Return to the course before trying again.'
                : 'Round completion could not be prepared. Your answers are still here; please try again.',
          ),
        ),
      );
    }
  }

  /// Optional audio control for the Pick the translation types. It is
  /// always visible when it applies, and greyed out (never hiding or skipping
  /// the exercise) when the learner turned audio or TTS off.
  Widget _translationAudioButton(String text) => IconButton.filledTonal(
    key: const Key('translation-choice-audio'),
    tooltip: _optionalAudioEnabled ? _t('playAudio') : _t('audioUnavailable'),
    onPressed: _optionalAudioEnabled ? () => _speakText(text) : null,
    icon: const Icon(Icons.volume_up_outlined),
  );

  Widget _translationAudioUnavailableNote() => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      _t('audioOffNote'),
      key: const Key('translation-choice-audio-note'),
      style: Theme.of(context).textTheme.bodySmall,
    ),
  );

  /// After answering a translation Select whose items are in the target
  /// language, the learner may hear the correct answer. Nothing is spoken
  /// automatically.
  List<Widget> _translationFeedbackAudio(Exercise ex) {
    final f = _features;
    if (!f.isTranslationChoice || f.itemLanguage != TextLanguage.target) {
      return const [];
    }
    final spoken = TranslationChoice.spokenTextFor(f, answered: _answered);
    if (spoken == null) return const [];
    return [
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(child: Text(_t('listenToAnswer'))),
          _translationAudioButton(spoken),
        ],
      ),
      if (!_optionalAudioEnabled) _translationAudioUnavailableNote(),
    ];
  }

  Widget _translationChoiceExercise(Exercise ex) {
    final f = _features;
    final spoken = f.questionLanguage == TextLanguage.target
        ? TranslationChoice.spokenTextFor(f, answered: _answered)
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (f.questionText.trim().isNotEmpty) ...[
          _withMascot(
            ExerciseMascotAnchor.question,
            Row(
              children: [
                Expanded(
                  child: Text(
                    f.questionText,
                    key: const Key('translation-choice-text'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                if (spoken != null) _translationAudioButton(spoken),
              ],
            ),
          ),
          if (spoken != null && !_optionalAudioEnabled) ...[
            const SizedBox(height: 8),
            _translationAudioUnavailableNote(),
          ],
          const SizedBox(height: 16),
        ],
        if (f.illustrationAsset.isNotEmpty) ...[
          _exerciseImage(ex),
          const SizedBox(height: 14),
        ],
        _choiceExercise(ex),
      ],
    );
  }

  /// Every Select exercise. Its panels come from the prompt elements' roles
  /// and attributes and its options from the items and the layout; nothing
  /// depends on the preset that authored it (Build 256, plan A.3).
  Widget _selectExercise(Exercise ex) {
    final f = _features;
    if (f.isTranslationChoice) return _translationChoiceExercise(ex);
    final automatic = f.automaticAudio;
    final contextAudio = f.contextAudio.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Context audio and the dialogue's read-aloud have their own
        // buttons in the panels below.
        if (automatic != null &&
            automatic.role != 'context' &&
            automatic.role != 'dialogue_turn') ...[
          Center(
            child: _besideCentered(
              ExerciseMascotAnchor.playButton,
              IconButton.filledTonal(
                tooltip: _t('playAudioAgain'),
                iconSize: 34,
                onPressed: _speak,
                icon: const Icon(Icons.volume_up_outlined),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
        ExercisePromptPanels(
          features: f,
          panelColor: _exercisePanelColor,
          onPlayContextAudio: _answered || contextAudio.isEmpty
              ? null
              : () => _speakText(contextAudio),
          onPlayDialogue: f.dialogueAudio.isEmpty || !_optionalAudioEnabled
              ? null
              : () => _speakDialogue(),
        ),
        if (f.questionText.isNotEmpty && !f.hasInlineTargets) ...[
          _withMascot(
            ExerciseMascotAnchor.question,
            LookupText(
              _questionShown(f),
              textKey: const Key('select-question-text'),
              style: Theme.of(context).textTheme.headlineSmall,
              language: f.questionLanguage,
            ),
          ),
          const SizedBox(height: 16),
        ],
        if ((f.kind == LearnerExerciseKind.selectComplete ||
                f.kind == LearnerExerciseKind.selectCompleteAll) &&
            ex.hint.trim().isNotEmpty) ...[
          Text(
            _t('hint', {'hint': ex.hint}),
            key: const Key('gap-choice-hint'),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
        ],
        _choiceExercise(ex),
      ],
    );
  }

  /// The question as drawn: once One word fills all is answered, the chosen
  /// word appears in every gap (Build 259 Revision 4).
  String _questionShown(ExerciseFeatures f) {
    final selected = _selected;
    if (f.kind != LearnerExerciseKind.selectCompleteAll ||
        !_answered ||
        selected == null ||
        selected < 0 ||
        selected >= _choiceOptions.length) {
      return f.questionText;
    }
    final word =
        _choiceOptions[selected].item?.label ?? _choiceOptions[selected].text;
    return f.questionText.replaceAll(RegExp(r'_{3,}'), word);
  }

  Widget _choiceExercise(Exercise ex) {
    final f = _features;
    if (f.hasInlineTargets) return _selectGapFillExercise(ex);
    if (f.multipleSelection) return _multiSelectChoiceExercise(ex);
    // Icon keys and captioned pictures make a grid; image-only options (a
    // Recognize characters text-to-image exercise) keep the list below.
    if (f.hasIconItems ||
        ex.items.any((item) => item.image.isNotEmpty && item.text.isNotEmpty)) {
      return _iconChoiceExercise(ex);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(_choiceOptions.length, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FilledButton.tonal(
            onPressed: _answered ? null : () => _answerChoice(i),
            child: _choiceOptions[i].item?.image.isNotEmpty == true
                ? PluralPicture.wrap(
                    plural: _choiceOptions[i].item!.pictureIsPlural,
                    child: _itemImage(_choiceOptions[i].item!.image),
                  )
                : Text(_choiceOptions[i].text),
          ),
        );
      }),
    );
  }

  void _toggleMultiChoice(int index) {
    if (_answered) return;
    setState(() {
      if (_multiSelected.contains(index)) {
        _multiSelected.remove(index);
      } else if (_multiSelected.length < _features.maximumSelections) {
        _multiSelected.add(index);
      }
    });
  }

  void _submitMultiChoice(Exercise ex) {
    final selectedIds = _multiSelected
        .map((i) => _choiceOptions[i].item!.id)
        .toSet();
    final correctIds = ex.canonicalEvaluation.correctItemIds.toSet();
    _mark(
      selectedIds.length == correctIds.length &&
          selectedIds.containsAll(correctIds),
    );
  }

  Widget _multiSelectChoiceExercise(Exercise ex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < _choiceOptions.length; i++)
          CheckboxListTile(
            key: Key('multi-select-option-$i'),
            title: Text(_choiceOptions[i].text),
            value: _multiSelected.contains(i),
            onChanged: _answered ? null : (_) => _toggleMultiChoice(i),
          ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed:
              _answered || _multiSelected.length < _features.minimumSelections
              ? null
              : () => _submitMultiChoice(ex),
          child: Text(_t('check')),
        ),
      ],
    );
  }

  /// Tapping an option always targets a specific gap, exactly like tapping a
  /// tile in gap-based Arrange: a gap armed by [_onSelectGapSlotTap] is
  /// filled first; otherwise the option fills the first remaining empty gap
  /// in layout order, whether or not that option is actually the correct
  /// answer for that gap — placement never depends on correctness, only on
  /// gap order, so a wrong option can occupy a gap and be checked exactly
  /// like a correct one. Unlike Arrange, an option is never removed from
  /// this list once placed, since the same option may need to fill more
  /// than one gap (tap it again to place it in the next empty gap).
  void _onSelectGapOptionTap(Exercise ex, String itemId) {
    if (_answered) return;
    setState(() {
      final armed = _selectArmedGapId;
      if (armed != null && _selectGapFill[armed] == null) {
        _selectGapFill[armed] = itemId;
        _selectArmedGapId = null;
        return;
      }
      final target = ex.layout
          .where(
            (segment) =>
                segment.isTarget && _selectGapFill[segment.targetId] == null,
          )
          .map((segment) => segment.targetId)
          .firstOrNull;
      if (target == null) return;
      _selectGapFill[target] = itemId;
    });
  }

  void _onSelectGapSlotTap(String gapId) {
    if (_answered) return;
    setState(() {
      final armed = _selectArmedGapId;
      if (armed == null) {
        // Arm this gap. An empty gap awaits an option tap; a filled gap
        // awaits a destination gap to move/swap its option into.
        _selectArmedGapId = gapId;
        return;
      }
      if (armed == gapId) {
        // Tapping the armed gap again cancels the pending action.
        _selectArmedGapId = null;
        return;
      }
      if (_selectGapFill[armed] == null) {
        // The armed gap is empty; re-arm to the newly tapped gap instead.
        _selectArmedGapId = gapId;
        return;
      }
      // Move (or swap) the armed gap's option into the tapped gap.
      final movingItemId = _selectGapFill[armed];
      final displacedItemId = _selectGapFill[gapId];
      _selectGapFill[gapId] = movingItemId;
      _selectGapFill[armed] = displacedItemId;
      _selectArmedGapId = null;
    });
  }

  void _removeSelectGapFill(String gapId) {
    if (_answered) return;
    setState(() {
      _selectGapFill[gapId] = null;
      if (_selectArmedGapId == gapId) _selectArmedGapId = null;
    });
  }

  void _submitSelectGaps(Exercise ex) {
    final assignments = _features.targetAssignments;
    if (assignments.isEmpty || _selectGapFill.values.any((v) => v == null)) {
      _mark(false);
      return;
    }
    final correct = assignments.entries.every(
      (entry) => _selectGapFill[entry.key] == entry.value,
    );
    _mark(correct);
  }

  Widget _selectGapFillExercise(Exercise ex) {
    final allGapsFilled = _selectGapFill.values.every((v) => v != null);
    final itemById = {for (final item in ex.items) item.id: item};
    final audio = _features.primaryAudioText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (audio != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: () => _speakText(audio),
              icon: const Icon(Icons.volume_up_outlined),
              label: Text(_t('playAudio')),
            ),
          ),
          const SizedBox(height: 14),
        ],
        _withMascot(
          ExerciseMascotAnchor.gappedText,
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _exercisePanelColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 8,
              children: [
                for (final segment in ex.layout)
                  if (segment.isText)
                    LookupText(
                      segment.text,
                      style: Theme.of(context).textTheme.titleMedium,
                    )
                  else
                    _selectGapSlot(
                      gapId: segment.targetId,
                      label: itemById[_selectGapFill[segment.targetId]]?.value,
                      armed: _selectArmedGapId == segment.targetId,
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in ex.items)
              FilterChip(
                key: Key('select-gap-option-${item.id}'),
                label: Text(item.value),
                selected: _selectGapFill.values.contains(item.id),
                onSelected: _answered
                    ? null
                    : (_) => _onSelectGapOptionTap(ex, item.id),
              ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _answered || !allGapsFilled
              ? null
              : () => _submitSelectGaps(ex),
          child: Text(_t('check')),
        ),
      ],
    );
  }

  Widget _fillBlankExercise(Exercise ex) {
    final f = _features;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Type the translation names the language of the answer in its
        // instruction line (Build 259 Revision 7): the fixed "Translate from
        // <source> into <target>:" line here was wrong for a "to source"
        // exercise.
        if (f.kind == LearnerExerciseKind.inputTranslation)
          ...const <Widget>[]
        else if (f.revealTarget != null)
          _withMascot(
            ExerciseMascotAnchor.question,
            Text(
              _answered && widget.round.roundType != RoundType.test
                  ? FirstLetterAnswerService.completedSentence(
                      f.inlineSentence,
                      _displayedCorrection,
                    )
                  : FirstLetterAnswerService.display(
                      f.inlineSentence,
                      f.acceptedAnswers,
                    ),
              key: const Key('first-letter-sentence'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          )
        // Type what you see asks with its instruction line and has no
        // question of its own (Build 259).
        else if (f.questionText.isNotEmpty)
          _withMascot(
            ExerciseMascotAnchor.question,
            Text(
              f.questionText,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        const SizedBox(height: 10),
        if (ex.hint.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _exercisePanelColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              _t('hint', {'hint': ex.hint}),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        const SizedBox(height: 16),
        TextField(
          controller: _textController,
          focusNode: _textFocusNode,
          enabled: !_answered,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submitFill(),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: _t('yourAnswer'),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _answered || _textController.text.trim().isEmpty
              ? null
              : _submitFill,
          child: Text(_t('check')),
        ),
      ],
    );
  }

  Widget _listeningSpellingExercise(Exercise ex) {
    final f = _features;
    final audio = f.primaryAudioText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _withMascot(
          ExerciseMascotAnchor.playButton,
          FilledButton.tonalIcon(
            onPressed: _answered || audio == null
                ? null
                : () => _speakText(audio),
            icon: const Icon(Icons.volume_up_outlined),
            label: Text(_t('playAudio')),
          ),
        ),
        const SizedBox(height: 14),
        if (f.questionText.trim().isNotEmpty) ...[
          Text(f.questionText, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _textController,
          focusNode: _textFocusNode,
          enabled: !_answered,
          autofocus: true,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _submitFill(),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: _t('yourAnswer'),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _answered || _textController.text.trim().isEmpty
              ? null
              : _submitFill,
          child: Text(_t('check')),
        ),
      ],
    );
  }

  /// The hint of a gap or order exercise (Build 259 Revision 1), drawn as
  /// Type the missing word draws its own.
  Widget _hintPanel(Exercise ex, Key key) => Container(
    key: key,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _exercisePanelColor,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      _t('hint', {'hint': ex.hint.trim()}),
      style: Theme.of(context).textTheme.bodyLarge,
    ),
  );

  Widget _wordOrderExercise(Exercise ex) {
    final available = List<String>.from(_tokenOptions);
    for (final token in _builtOrder) {
      available.remove(token);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ex.hint.trim().isNotEmpty) ...[
          _hintPanel(ex, const Key('order-hint')),
          const SizedBox(height: 16),
        ],
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _builtOrder
              .map(
                (token) => InputChip(
                  label: Text(token),
                  onDeleted: _answered
                      ? null
                      : () => setState(() => _builtOrder.remove(token)),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: available
              .map(
                (token) => ActionChip(
                  label: Text(token),
                  onPressed: _answered
                      ? null
                      : () => setState(() => _builtOrder.add(token)),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _answered || _builtOrder.isEmpty ? null : _submitOrder,
          child: Text(_t('check')),
        ),
      ],
    );
  }

  void _onGapTileTap(String itemId) {
    if (_answered) return;
    setState(() {
      final armed = _armedGapId;
      if (armed != null && _gapFill[armed] == null) {
        // A tile tap while an empty gap is armed fills that specific gap.
        _gapFill[armed] = itemId;
        _armedGapId = null;
        return;
      }
      // Otherwise fill the first empty gap in layout order.
      final target = _gapFill.entries
          .firstWhere(
            (entry) => entry.value == null,
            orElse: () => const MapEntry('', ''),
          )
          .key;
      if (target.isEmpty) return;
      _gapFill[target] = itemId;
    });
  }

  void _onGapSlotTap(String gapId) {
    if (_answered) return;
    setState(() {
      final armed = _armedGapId;
      if (armed == null) {
        // Arm this gap. An empty gap awaits a bank tile; a filled gap awaits
        // a destination gap to move/swap its tile into.
        _armedGapId = gapId;
        return;
      }
      if (armed == gapId) {
        // Tapping the armed gap again cancels the pending action.
        _armedGapId = null;
        return;
      }
      if (_gapFill[armed] == null) {
        // The armed gap is empty; re-arm to the newly tapped gap instead.
        _armedGapId = gapId;
        return;
      }
      // Move (or swap) the armed gap's tile into the tapped gap.
      final movingItemId = _gapFill[armed];
      final displacedItemId = _gapFill[gapId];
      _gapFill[gapId] = movingItemId;
      _gapFill[armed] = displacedItemId;
      _armedGapId = null;
    });
  }

  void _removeGapTile(String gapId) {
    if (_answered) return;
    setState(() {
      _gapFill[gapId] = null;
      if (_armedGapId == gapId) _armedGapId = null;
    });
  }

  void _submitArrangeGaps() {
    final ex = _exercise;
    final assignments = _features.targetAssignments;
    if (assignments.isEmpty || _gapFill.values.any((v) => v == null)) {
      _mark(false);
      return;
    }
    // Blocks with the same content are interchangeable: the gap is right
    // when the placed block reads like the assigned one (Build 256, plan
    // A.11), so two identical blocks can fill either of their gaps.
    final correct = assignments.entries.every(
      (entry) =>
          _itemValue(ex, _gapFill[entry.key]) == _itemValue(ex, entry.value),
    );
    _mark(correct);
  }

  Widget _arrangeGapFillExercise(Exercise ex) {
    final placed = _gapFill.values.whereType<String>().toSet();
    final available = _gapTileOrder.where((id) => !placed.contains(id));
    final itemById = {for (final item in ex.items) item.id: item};
    final allGapsFilled = _gapFill.values.every((v) => v != null);
    final audio = _features.primaryAudioText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (audio != null) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: () => _speakText(audio),
              icon: const Icon(Icons.volume_up_outlined),
              label: Text(_t('playAudio')),
            ),
          ),
          const SizedBox(height: 14),
        ],
        _withMascot(
          ExerciseMascotAnchor.gappedText,
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _exercisePanelColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              runSpacing: 8,
              children: [
                for (final segment in ex.layout)
                  if (segment.isText)
                    LookupText(
                      segment.text,
                      style: Theme.of(context).textTheme.titleMedium,
                    )
                  else
                    _gapSlot(
                      gapId: segment.targetId,
                      label: itemById[_gapFill[segment.targetId]]?.value,
                      armed: _armedGapId == segment.targetId,
                    ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final itemId in available)
              ActionChip(
                key: Key('arrange-tile-$itemId'),
                label: Text(itemById[itemId]?.value ?? ''),
                onPressed: _answered ? null : () => _onGapTileTap(itemId),
              ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _answered || !allGapsFilled ? null : _submitArrangeGaps,
          child: Text(_t('check')),
        ),
      ],
    );
  }

  Widget _gapSlot({
    required String gapId,
    required String? label,
    required bool armed,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 56),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: label == null
            ? scheme.surfaceContainerHighest
            : scheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: armed ? scheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // A sibling (not nested) tap target arms the gap for a move/swap,
          // or fills it from an armed empty gap.
          GestureDetector(
            key: Key('gap-slot-$gapId'),
            behavior: HitTestBehavior.opaque,
            onTap: _answered ? null : () => _onGapSlotTap(gapId),
            child: Text(
              label ?? '___',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (label != null) ...[
            const SizedBox(width: 4),
            // A separate sibling tap target removes the placed tile.
            GestureDetector(
              key: Key('gap-remove-$gapId'),
              behavior: HitTestBehavior.opaque,
              onTap: _answered ? null : () => _removeGapTile(gapId),
              child: const Icon(Icons.close, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  /// A read-only gap slot for linked-gap Select: unlike Arrange's `_gapSlot`,
  /// it has no tap-to-arm or remove affordance, since filling and clearing a
  /// gap in Select happens by toggling its linked option chip instead.
  Widget _selectGapSlot({
    required String gapId,
    required String? label,
    required bool armed,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minWidth: 56),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: label == null
            ? scheme.surfaceContainerHighest
            : scheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: armed ? scheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // A sibling (not nested) tap target arms the gap for a move/swap,
          // or fills it from an armed empty gap.
          GestureDetector(
            key: Key('select-gap-slot-$gapId'),
            behavior: HitTestBehavior.opaque,
            onTap: _answered ? null : () => _onSelectGapSlotTap(gapId),
            child: Text(
              label ?? '___',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          if (label != null) ...[
            const SizedBox(width: 4),
            // A separate sibling tap target removes the placed option.
            GestureDetector(
              key: Key('select-gap-remove-$gapId'),
              behavior: HitTestBehavior.opaque,
              onTap: _answered ? null : () => _removeSelectGapFill(gapId),
              child: const Icon(Icons.close, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _imageWordExercise(Exercise ex) {
    final prompt = _features.displayedPrompt;
    final available = List<String>.from(_tokenOptions);
    for (final token in _builtOrder) {
      available.remove(token);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A spelling clue (with its language) stays here; an instruction
        // is drawn in the instruction line (Build 259).
        if (prompt.isNotEmpty &&
            !_promptAsInstruction &&
            !ExerciseCopyService.isLegacyInstruction(prompt)) ...[
          Text(
            ExerciseCopyService.displayPrompt(widget.course, prompt),
            key: const Key('exercise-prompt-text'),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
        ],
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _exercisePanelColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Wrap(
            alignment: WrapAlignment.center,
            spacing: 4,
            runSpacing: 4,
            children: _builtOrder
                .map(
                  (token) => InputChip(
                    label: Text(token),
                    onDeleted: _answered
                        ? null
                        : () => setState(() => _builtOrder.remove(token)),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: available
              .map(
                (token) => ActionChip(
                  label: Text(token),
                  onPressed: _answered
                      ? null
                      : () => setState(() => _builtOrder.add(token)),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _answered || _builtOrder.isEmpty ? null : _submitOrder,
          child: Text(_t('check')),
        ),
      ],
    );
  }

  /// The transcript with a blank for every gap.
  /// The gapped text: a gap inside a word (Missing letters) shows one
  /// underscore per missing letter, a whole-word gap a fixed blank.
  /// Whether each gap target sits inside a word (letters touch it), by
  /// target ID: Missing letters asks for letters, Complete the text for
  /// words.
  String _missingWordDisplay() {
    final layout = _exercise.layout;
    final inWord = _features.gapsInWord;
    final buffer = StringBuffer();
    for (final element in layout) {
      if (!element.isTarget) {
        buffer.write(element.text);
        continue;
      }
      final answer =
          _features.answersFor(element.targetId)?.answers.firstOrNull ?? '';
      buffer.write(
        (inWord[element.targetId] ?? false) && answer.isNotEmpty
            ? '_' * answer.length
            : '_____',
      );
    }
    return buffer.toString();
  }

  /// The label of gap field [i]: "Missing letters" for a gap inside a word
  /// (owner report, 29 September 2026: "Missing word" misled), "Missing
  /// word" otherwise, numbered when there are several.
  String _gapFieldLabel(int i) {
    final targets = _features.gapFieldTargets;
    final inWord =
        i < targets.length && (_features.gapsInWord[targets[i].id] ?? false);
    final noun = inWord ? _t('missingLetters') : _t('missingWord');
    return _missingWordControllers.length == 1 ? noun : '$noun ${i + 1}';
  }

  void _submitMissingWords(Exercise ex) {
    if (_answered) return;
    if (!_missingWordControllers.any((c) => c.text.trim().isNotEmpty)) return;
    final f = _features;
    final targets = f.gapFieldTargets;
    var correct = _missingWordControllers.length == targets.length;
    for (
      var i = 0;
      i < _missingWordControllers.length && i < targets.length;
      i++
    ) {
      final answers = f.answersFor(targets[i].id);
      if (answers == null ||
          !_answerEngine.accepts(
            _missingWordControllers[i].text,
            answers.answers,
            typoTolerance: false,
          )) {
        correct = false;
      }
    }
    _mark(correct);
  }

  Widget _missingWordExercise(Exercise ex) {
    final anyTyped = _missingWordControllers.any(
      (c) => c.text.trim().isNotEmpty,
    );
    final audio = _features.primaryAudioText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Play audio only when there is audio (Build 259 Revision 1): a
        // greyed button made a text-only exercise look like a listening one.
        if (audio != null) ...[
          FilledButton.tonalIcon(
            onPressed: _answered ? null : () => _speakText(audio),
            icon: const Icon(Icons.volume_up_outlined),
            label: Text(_t('playAudio')),
          ),
          const SizedBox(height: 14),
        ],
        _withMascot(
          ExerciseMascotAnchor.gappedText,
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _exercisePanelColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: LookupText(
              _missingWordDisplay(),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
        const SizedBox(height: 14),
        if (ex.hint.trim().isNotEmpty) ...[
          _hintPanel(ex, const Key('gap-fields-hint')),
          const SizedBox(height: 14),
        ],
        for (var i = 0; i < _missingWordControllers.length; i++) ...[
          TextField(
            controller: _missingWordControllers[i],
            enabled: !_answered,
            autofocus: i == 0,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _submitMissingWords(ex),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: _gapFieldLabel(i),
            ),
          ),
          const SizedBox(height: 10),
        ],
        FilledButton(
          onPressed: _answered || !anyTyped
              ? null
              : () => _submitMissingWords(ex),
          child: Text(_t('check')),
        ),
      ],
    );
  }

  /// A Match left item: its text, or its picture with the text beside it
  /// (Match pictures to words).
  Widget _matchLeftContent(_MatchPairView pair) {
    if (pair.leftImage.isEmpty) return Text(pair.leftLabel, softWrap: true);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PluralPicture.wrap(
          plural: pair.leftPlural,
          child: _itemImage(pair.leftImage, size: 64),
        ),
        if (pair.leftLabel.isNotEmpty) ...[
          const SizedBox(width: 8),
          Flexible(child: Text(pair.leftLabel, softWrap: true)),
        ],
      ],
    );
  }

  Widget _matchingExercise(Exercise ex) {
    Widget selector(_MatchPairView pair) => DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: _matchingSelections[pair.leftId],
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      ),
      items: _matchingRightOptions
          .map(
            (v) => DropdownMenuItem(
              value: v.id,
              child: Text(
                v.label,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: _answered
          ? null
          : (value) => setState(() {
              if (value != null) _matchingSelections[pair.leftId] = value;
            }),
    );

    return Column(
      children: [
        ..._matchingLeftPairs.map(
          (pair) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // On phone-width windows, stack the two sides vertically. This
                // prevents RenderFlex overflow while keeping the text readable.
                if (constraints.maxWidth < 390) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _matchLeftContent(pair),
                      const SizedBox(height: 7),
                      selector(pair),
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: _matchLeftContent(pair),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(flex: 6, child: selector(pair)),
                  ],
                );
              },
            ),
          ),
        ),
        FilledButton(
          onPressed:
              _answered ||
                  _matchingSelections.length != _matchingLeftPairs.length
              ? null
              : _submitMatching,
          child: Text(_t('check')),
        ),
      ],
    );
  }

  IconData _iconFor(String key) {
    switch (key) {
      case 'water':
        return Icons.water_drop_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'coffee':
        return Icons.coffee_outlined;
      case 'person':
        return Icons.person_outline;
      case 'hello':
        return Icons.waving_hand_outlined;
      case 'sun':
        return Icons.wb_sunny_outlined;
      case 'moon':
        return Icons.nightlight_outlined;
      case 'thanks':
        return Icons.favorite_border;
      case 'tree':
        return Icons.park_outlined;
      case 'flower':
        return Icons.local_florist_outlined;
      case 'bread':
        return Icons.bakery_dining_outlined;
      case 'train':
        return Icons.train_outlined;
      case 'bus':
        return Icons.directions_bus_outlined;
      case 'bike':
        return Icons.pedal_bike_outlined;
      case 'shirt':
        return Icons.checkroom_outlined;
      case 'book':
        return Icons.menu_book_outlined;
      case 'food':
        return Icons.restaurant_outlined;
      case 'shop':
        return Icons.storefront_outlined;
      default:
        return Icons.image_outlined;
    }
  }

  Widget _flashcardExercise(Exercise ex) {
    final f = _features;
    final term = f.textOf('term');
    final meaning = f.textOf('meaning');
    final usage = f.textOf('usage');
    final usageTranslation = f.textOf('usage_translation');
    final audio = f.audioOf('audio').trim();
    final reviewable = f.completionMode == CompletionMode.understoodReview;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _exercisePanelColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                term,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              IconButton.filledTonal(
                tooltip: _t('pronounceWord'),
                onPressed: audio.isEmpty ? null : () => _speakText(audio),
                icon: const Icon(Icons.volume_up_outlined),
              ),
              const SizedBox(height: 12),
              Text(
                meaning,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (usage.isNotEmpty) ...[
                const Divider(height: 28),
                Text(
                  _t('usage'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  usage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                if (usageTranslation.isNotEmpty)
                  Text(usageTranslation, textAlign: TextAlign.center),
                const SizedBox(height: 6),
                IconButton(
                  tooltip: _t('pronounceUsage'),
                  onPressed: () => _speakText(usage),
                  icon: const Icon(Icons.record_voice_over_outlined),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (reviewable) ...[
          OutlinedButton(
            onPressed: _answered
                ? null
                : () => _flashcardResult(reviewAgain: true),
            child: Text(_t('reviewAgain')),
          ),
          const SizedBox(height: 8),
        ],
        FilledButton(
          onPressed: _answered
              ? null
              : () => _flashcardResult(reviewAgain: false),
          child: Text(reviewable ? _t('gotIt') : _t('continue')),
        ),
      ],
    );
  }

  /// A Story dialogue line (Build 256 Revision 5): the speaker's avatar and
  /// name, the line as a bubble, its audio (automatic through the activation
  /// path, or on request) and Continue. Never skipped: without audio the
  /// learner reads the line.
  Widget _dialogueLineExercise(Exercise ex) {
    final f = _features;
    final speaker = _lineSpeaker(f);
    final audio = f.lineAudio;
    final text = f.lineText;
    final audioPlayable = audio != null && _optionalAudioEnabled;
    final hidden =
        text.isNotEmpty &&
        audio != null &&
        f.textReveal == TextReveal.afterAudio &&
        audioPlayable &&
        !_lineAudioPlayed;
    final transcript = text.isNotEmpty ? text : (audio?.text ?? '');
    final showsText = text.isNotEmpty ? !hidden : !audioPlayable;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _lineBubble(
          speaker: speaker,
          text: showsText ? transcript : null,
          language: _lineLanguage(f),
          placeholder: hidden
              ? _t('listenFirst')
              : (audio != null && !showsText ? _t('listen') : null),
          trailing: audio == null
              ? null
              : IconButton.filledTonal(
                  key: const Key('story-line-play'),
                  tooltip: audioPlayable ? _t('play') : _t('audioUnavailable'),
                  onPressed: audioPlayable ? () => _playLine(f) : null,
                  icon: const Icon(Icons.volume_up_outlined),
                ),
        ),
        if (audio != null && !audioPlayable)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _t('audioNotOnDevice'),
              key: const Key('story-line-audio-note'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('story-line-continue'),
          onPressed: _answered ? null : _continueLine,
          child: Text(_t('continue')),
        ),
      ],
    );
  }

  Future<void> _playLine(ExerciseFeatures f) async {
    final audio = f.lineAudio;
    if (audio == null) return;
    final ok = await _playCourseAudio(
      audio.text,
      language: _lineLanguage(f),
      voice: _lineSpeaker(f).voice,
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _lineAudioPlayed = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text(_audioFailureDescription),
        ),
      );
    }
  }

  /// Continue on a dialogue line or a Story cover: no feedback step, the
  /// next item follows at once (a card is never scored).
  void _continueLine() {
    if (_answered) return;
    setState(() {
      _answered = true;
      _lastAnswerCorrect = true;
      _feedback = '';
    });
    _next();
  }

  /// A Page (Build 258): its blocks, then Continue. Read-aloud and audio
  /// blocks follow the learner's Audio Settings; links open in the browser.
  Widget _pageExercise(Exercise ex) {
    final blocks = _features.pageBlocks;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageCardView(
          blocks: blocks,
          background: _exercisePanelColor,
          pictureBuilder: _pagePicture,
          onSpeak: _optionalAudioEnabled ? _speakBlock : null,
          onOpenLink: (url) => _openPageLink(url),
        ),
        // Build 258 Revision 4: Share, Save PDF and Print, when the Course
        // allows it (on by default).
        if (widget.course.allowPageSharing) ...[
          const SizedBox(height: 12),
          PageActionsBar(
            course: widget.course,
            blocks: blocks,
            pictureBuilder: _pagePicture,
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('page-continue'),
          onPressed: _answered ? null : _continueLine,
          child: Text(_t('continue')),
        ),
      ],
    );
  }

  /// A Page picture at [width]: Course media through the media store, a
  /// bundled or portable picture as before.
  Widget _pagePicture(PromptElement picture, double width) =>
      picture.asset.startsWith('media:')
      ? CourseMediaImage(
          courseId: widget.course.courseId,
          asset: picture.asset,
          width: width,
          // Decode at the size shown (the pixel size of a Course picture is
          // not bounded by its file size).
          cacheWidth: 1024,
          semanticLabel: picture.text.isEmpty ? null : picture.text,
          missing: _missingImageNotice(picture.asset),
        )
      : PortableExerciseImage(asset: picture.asset, width: width);

  /// Reads a Page's text block (without its marks) or plays its audio
  /// block, in the block's language.
  Future<void> _speakBlock(PromptElement block) async {
    final text = block.isText
        ? block.text
              .split('\n')
              .map(InlineMarks.plain)
              .where((line) => line.trim().isNotEmpty)
              .join('\n')
        : block.text;
    if (text.trim().isEmpty) return;
    final ok = await _playCourseAudio(text, language: block.language);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text(_audioFailureDescription),
        ),
      );
    }
  }

  Future<void> _openPageLink(String url) async {
    final uri = Uri.tryParse(url);
    var opened = false;
    if (uri != null && PageBlocks.isAcceptableLink(url)) {
      try {
        opened = await RoundScreen.openLink(uri);
      } catch (_) {
        opened = false;
      }
    }
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          content: Text(_t('linkNotOpened')),
        ),
      );
    }
  }

  /// A Story cover (Build 256 Revision 5): the Story's title, the cover
  /// picture and an optional title line, then Continue.
  Widget _storyCoverExercise(Exercise ex) {
    final f = _features;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _coverCard(
          title: widget.round.flow?.title ?? '',
          line: f.coverTitle,
          picture: f.illustrationAsset,
          lineLanguage: f.textLanguageOf('title'),
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('story-cover-continue'),
          onPressed: _answered ? null : _continueLine,
          child: Text(_t('continue')),
        ),
      ],
    );
  }

  Widget _coverCard({
    required String title,
    required String line,
    required String picture,
    TextLanguage? lineLanguage,
  }) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: _exercisePanelColor,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        if (title.isNotEmpty)
          Text(
            title,
            key: const Key('story-cover-title'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        if (picture.isNotEmpty) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: _itemImage(picture, size: 220),
          ),
        ],
        // A title line that repeats the Story title is shown once.
        if (line.isNotEmpty && line != title) ...[
          const SizedBox(height: 12),
          LookupText(
            line,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
            language: lineLanguage,
          ),
        ],
      ],
    ),
  );

  /// A speaker's line as a bubble beside their avatar and name; the narrator
  /// without an avatar speaks in a quieter, centred style.
  Widget _lineBubble({
    required StorySpeaker speaker,
    String? text,
    String? placeholder,
    Widget? trailing,
    TextLanguage? language,
  }) {
    final theme = Theme.of(context);
    final Widget body = text == null
        ? Text(
            placeholder ?? '',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        : LookupText(
            text,
            style: theme.textTheme.bodyLarge,
            language: language,
          );
    if (speaker.isNarrator && speaker.avatar.isEmpty) {
      return Padding(
        key: const Key('story-line-narrator'),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (speaker.name.isNotEmpty)
                    Text(
                      speaker.name,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge,
                    ),
                  DefaultTextStyle.merge(
                    style: const TextStyle(fontStyle: FontStyle.italic),
                    textAlign: TextAlign.center,
                    child: body,
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      );
    }
    return Row(
      key: const Key('story-line-bubble'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _speakerAvatar(speaker),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (speaker.name.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    speaker.name,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _exercisePanelColor,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: body,
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 6), trailing],
      ],
    );
  }

  Widget _speakerAvatar(StorySpeaker speaker) => SizedBox(
    width: 44,
    height: 44,
    child: speaker.avatar.isEmpty
        ? CircleAvatar(
            child: Text(
              speaker.name.isEmpty
                  ? '?'
                  : speaker.name.characters.first.toUpperCase(),
            ),
          )
        : ClipOval(child: _itemImage(speaker.avatar, size: 44)),
  );

  /// An item's picture: a Course medium through the media store, a bundled
  /// asset or a portable data URI as before.
  Widget _itemImage(
    String asset, {
    double size = 128,
    BoxFit fit = BoxFit.contain,
  }) => asset.startsWith('media:')
      ? CourseMediaImage(
          courseId: widget.course.courseId,
          asset: asset,
          width: size,
          height: size,
          fit: fit,
          cacheWidth: 256,
          cacheHeight: 256,
        )
      : PortableExerciseImage(
          asset: asset,
          width: size,
          height: size,
          fit: fit,
        );

  /// Picture answers (Build 263 Revision 2, owner decisions of 4 October
  /// 2026): the Course's look from Lesson Options, which the exercise may
  /// override; without a choice large squares, two per row. Every row is
  /// centred, so the pictures a last row does not fill stand in its middle;
  /// the earlier look (normal, round, as many as fit) keeps its tiles.
  Widget _iconChoiceExercise(Exercise ex) {
    final style = widget.course.pictureAnswers.overriddenBy(ex.options);
    final width = style.size == PictureSize.large ? 176.0 : 112.0;
    final perRow = style.perRowCount;
    if (perRow == null) {
      return Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: List.generate(
          _choiceOptions.length,
          (i) => _pictureAnswer(i, width: width, shape: style.shape),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 10.0;
        final fitted = min(
          width,
          (constraints.maxWidth - spacing * (perRow - 1)) / perRow,
        );
        final count = _choiceOptions.length;
        return Column(
          key: const Key('picture-answer-rows'),
          children: [
            for (var start = 0; start < count; start += perRow)
              Padding(
                padding: EdgeInsets.only(
                  bottom: start + perRow < count ? spacing : 0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (
                      var i = start;
                      i < min(start + perRow, count);
                      i++
                    ) ...[
                      if (i > start) const SizedBox(width: spacing),
                      _pictureAnswer(i, width: fitted, shape: style.shape),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  /// One picture answer [width] wide: round, the standard tile scaled from
  /// its 112 pixels, or a square the picture fills.
  Widget _pictureAnswer(
    int i, {
    required double width,
    required PictureShape shape,
  }) {
    final item = _choiceOptions[i].item;
    final image = item?.image ?? '';
    // Build 265 Revision 11: a picture answer marked Plural shows several.
    final plural = item?.pictureIsPlural ?? false;
    final iconKey = item == null || image.isNotEmpty
        ? ''
        : item.content
                  .where((element) => element.role == 'icon')
                  .map((element) => element.text)
                  .firstOrNull ??
              '';
    // A picture on the item, else an icon key naming a bundled asset
    // (drawn as before), else a named icon.
    final isAsset = image.isEmpty && iconKey.startsWith('assets/');
    // Never a picture's file path (Build 259 Revision 4). Only a named
    // icon shows its word: a picture, QQL or Course, shows none, which
    // would give the answer away (Build 263 Revision 0).
    final caption = _choiceOptions[i].item?.label ?? _choiceOptions[i].text;
    final showCaption = image.isEmpty && !isAsset && caption.isNotEmpty;
    final scale = width / 112;
    final captionText = Text(
      caption,
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 12 * scale.clamp(1.0, 1.4)),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
    if (shape == PictureShape.square) {
      return SizedBox(
        key: ValueKey('picture-answer-square-$i'),
        width: width,
        height: width,
        child: FilledButton.tonal(
          style: FilledButton.styleFrom(
            padding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          onPressed: _answered ? null : () => _answerChoice(i),
          child: image.isNotEmpty
              ? PluralPicture.wrap(
                  plural: plural,
                  child: _itemImage(image, size: width, fit: BoxFit.cover),
                )
              : isAsset
              ? PluralPicture.wrap(
                  plural: plural,
                  child: BundledPicture(
                    iconKey,
                    width: width,
                    height: width,
                    fit: BoxFit.cover,
                    errorBuilder: (_) =>
                        Icon(Icons.broken_image_outlined, size: 34 * scale),
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_iconFor(iconKey), size: 34 * scale),
                    if (showCaption) ...[
                      const SizedBox(height: 5),
                      captionText,
                    ],
                  ],
                ),
        ),
      );
    }
    return SizedBox(
      width: width,
      height: (image.isNotEmpty ? 150 : 120) * scale,
      child: FilledButton.tonal(
        onPressed: _answered ? null : () => _answerChoice(i),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (image.isNotEmpty)
              Expanded(
                child: Center(
                  child: PluralPicture.wrap(
                    plural: plural,
                    child: _itemImage(image, size: 88 * scale),
                  ),
                ),
              )
            else if (isAsset)
              Expanded(
                child: Center(
                  child: PluralPicture.wrap(
                    plural: plural,
                    child: BundledPicture(
                      iconKey,
                      fit: BoxFit.contain,
                      errorBuilder: (_) =>
                          Icon(Icons.broken_image_outlined, size: 34 * scale),
                    ),
                  ),
                ),
              )
            else
              Icon(_iconFor(iconKey), size: 34 * scale),
            if (showCaption) ...[const SizedBox(height: 5), captionText],
          ],
        ),
      ),
    );
  }

  Widget _audioMatchExercise(Exercise ex) {
    final question = _features.questionText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (question.isNotEmpty) ...[
          Text(question, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
        ],
        ..._matchingLeftPairs.map((pair) {
          final soundId = pair.leftId;
          final sound = pair.leftLabel;
          return Card(
            color: _exercisePanelColor,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  IconButton.filledTonal(
                    tooltip: _t('playSound'),
                    onPressed: () => _speakText(sound),
                    icon: const Icon(Icons.volume_up_outlined),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: _matchingRightOptions
                        .map(
                          (word) => ChoiceChip(
                            label: Text(word.label),
                            selected: _matchingSelections[soundId] == word.id,
                            onSelected: _answered
                                ? null
                                : (_) => setState(
                                    () =>
                                        _matchingSelections[soundId] = word.id,
                                  ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        FilledButton(
          onPressed:
              _answered ||
                  _matchingSelections.length != _matchingLeftPairs.length
              ? null
              : () => _mark(_matchingReadsAsExpected()),
          child: Text(_t('checkMatches')),
        ),
      ],
    );
  }

  Widget _missingImageNotice(String path) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.orange.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.broken_image_outlined),
        const SizedBox(width: 8),
        Expanded(child: Text('Image asset file is missing: $path')),
      ],
    ),
  );

  Widget _exerciseImage(Exercise ex) {
    final asset = _features.illustrationAsset;
    if (asset.isEmpty) return const SizedBox.shrink();
    // Decode at the size actually shown. Nothing bounds the pixel dimensions
    // of a course-media image: a 300 KB PNG may declare 30,000 × 30,000 and
    // cost gigabytes to rasterize. The portable path already enforces 4096;
    // this bounds the decode for the rest.
    const decodeWidth = 840;
    const decodeHeight = 560;
    final image = CourseMediaImage(
      courseId: widget.course.courseId,
      asset: asset,
      cacheWidth: decodeWidth,
      cacheHeight: decodeHeight,
      semanticLabel: 'Exercise illustration',
      missing: _missingImageNotice(asset),
    );
    return Center(
      key: const Key('exercise-image'),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 280),
        // Build 265 Revision 11: the picture marked Plural shows several.
        child: PluralPicture.wrap(
          plural: _features.illustrationPlural,
          child: image,
        ),
      ),
    );
  }

  /// Where this build draws the active exercise's mascot, or null (Build 256
  /// Revision 9). [ExerciseMascotPolicy] names the sentence; the mascot is
  /// drawn only when the sentence keeps room beside it on this screen. The
  /// picture is taken from the Round's order the first time the mascot is
  /// drawn, and kept until the next exercise: so the learner never sees a
  /// picture twice in one Round, nor the same character twice in a row.
  ({ExerciseMascotAnchor anchor, String asset, double size})? _placeMascot(
    BuildContext context,
    Exercise ex,
  ) {
    final mascots = _mascots;
    if (mascots == null) return null;
    final anchor = ExerciseMascotPolicy.anchorFor(ex);
    if (anchor == ExerciseMascotAnchor.none) return null;
    final media = MediaQuery.of(context);
    // The Round body is a ListView with 20 pixels on each side.
    final contentWidth = media.size.width - media.padding.horizontal - 40;
    final size = ExerciseMascotPolicy.mascotSize(contentWidth);
    final text = Theme.of(context).textTheme;
    final (TextStyle? style, double reserved) = switch (anchor) {
      // A translation question keeps room for its audio button.
      ExerciseMascotAnchor.question => (
        text.headlineSmall,
        _features.isTranslationChoice ? 48.0 : 0.0,
      ),
      ExerciseMascotAnchor.prompt => (
        _promptAsInstruction
            ? text.bodyMedium?.copyWith(fontWeight: FontWeight.w600)
            : text.titleMedium,
        0.0,
      ),
      // The gapped sentence sits in a panel with padding on both sides.
      ExerciseMascotAnchor.gappedText => (
        ex.primitive == ExercisePrimitive.input
            ? text.bodyLarge
            : text.titleMedium,
        28.0,
      ),
      ExerciseMascotAnchor.playButton ||
      ExerciseMascotAnchor.none => (null, 0.0),
    };
    final textWidth = contentWidth - size - ExerciseMascotPolicy.gap - reserved;
    int? lines;
    final sentence = ExerciseMascotPolicy.sentenceAt(ex, anchor);
    if (sentence != null) {
      if (textWidth <= 0) return null;
      final painter = TextPainter(
        text: TextSpan(text: sentence, style: style),
        textDirection: Directionality.of(context),
        textScaler: media.textScaler,
      )..layout(maxWidth: textWidth);
      lines = painter.computeLineMetrics().length;
      painter.dispose();
    }
    if (!ExerciseMascotPolicy.fits(
      textWidth: textWidth,
      lines: lines,
      viewportHeight: media.size.height,
    )) {
      return null;
    }
    final asset = _exerciseMascot ??= mascots.next();
    if (asset == null) return null;
    return (anchor: anchor, asset: asset, size: size);
  }

  /// [child] with the active exercise's mascot on its leading side when the
  /// mascot sits at [anchor]; else [child] alone.
  Widget _withMascot(ExerciseMascotAnchor anchor, Widget child) {
    final placement = _mascotPlacement;
    if (placement == null || placement.anchor != anchor) return child;
    return ExerciseMascot.beside(
      asset: placement.asset,
      size: placement.size,
      child: child,
    );
  }

  /// A centred [child] (the replay button) with the mascot beside it.
  Widget _besideCentered(ExerciseMascotAnchor anchor, Widget child) {
    final placement = _mascotPlacement;
    if (placement == null || placement.anchor != anchor) return child;
    return Row(
      key: const Key('exercise-mascot-row'),
      mainAxisSize: MainAxisSize.min,
      children: [
        ExerciseMascot(asset: placement.asset, size: placement.size),
        const SizedBox(width: ExerciseMascotPolicy.gap),
        child,
      ],
    );
  }

  /// The text shown above the exercise body: the primary or clue text.
  /// Passages, situations, context and the Flashcard's term have their own
  /// place in the body.
  String get _displayedPrompt => _features.displayedPrompt;

  /// An authored Instruction or context (a prompt with no language) takes
  /// the place of the standard instruction line under the heading, in every
  /// exercise (Build 259, owner decisions of 29 September 2026; Choose and
  /// Match did so since Build 256).
  bool get _promptAsInstruction {
    final instruction = _features.authoredInstruction;
    return _exercise.isExecutable &&
        !_features.isTranslationChoice &&
        instruction.isNotEmpty &&
        !ExerciseCopyService.isLegacyInstruction(instruction);
  }

  /// Whether the authored prompt has a line of its own above the exercise
  /// body: material with a language, such as a text to translate. A
  /// spelling exercise draws its clue in its body.
  bool get _promptShown =>
      !_promptAsInstruction &&
      !_features.isTranslationChoice &&
      _features.kind != LearnerExerciseKind.arrangeWord &&
      _displayedPrompt.isNotEmpty &&
      !ExerciseCopyService.isLegacyInstruction(_displayedPrompt);

  Widget _exerciseBody(Exercise ex) {
    final f = _features;
    // Build 256 Revision 6 (plan A.6): a configuration this version cannot
    // play is a card here, whatever its primitive.
    if (!ex.isExecutable) return _notExecutableCard(ex);
    switch (ex.primitive) {
      case ExercisePrimitive.select:
        return _selectExercise(ex);
      case ExercisePrimitive.input:
        if (f.gapFieldTargets.isNotEmpty) return _missingWordExercise(ex);
        if (f.automaticAudio != null && f.revealTarget == null) {
          return _listeningSpellingExercise(ex);
        }
        return _fillBlankExercise(ex);
      case ExercisePrimitive.arrange:
        if (f.arrangeInline) return _arrangeGapFillExercise(ex);
        if (f.joinsWithoutSpaces) return _imageWordExercise(ex);
        return _wordOrderExercise(ex);
      case ExercisePrimitive.match:
        return f.leftItemsHaveAudio
            ? _audioMatchExercise(ex)
            : _matchingExercise(ex);
      case ExercisePrimitive.presentation:
        if (f.kind == LearnerExerciseKind.dialogueLine) {
          return _dialogueLineExercise(ex);
        }
        if (f.kind == LearnerExerciseKind.storyCover) {
          return _storyCoverExercise(ex);
        }
        if (f.kind == LearnerExerciseKind.page) return _pageExercise(ex);
        return _flashcardExercise(ex);
      case ExercisePrimitive.assign:
        return _assignExercise(ex);
      case ExercisePrimitive.speak:
      case ExercisePrimitive.ink:
      case ExercisePrimitive.submit:
        return _notExecutableCard(ex);
    }
  }

  /// Assign (Build 256 Revision 7): tap a bank tile, then the destination
  /// that takes it; a placed item's chip gives it back. Groups and slots are
  /// bins in a column, gaps are slots inside the text. Capacity single
  /// replaces what a destination held; multiple and unlimited add to it. A
  /// reusable item stays in the bank; otherwise it leaves the bank and any
  /// other destination.
  Widget _assignExercise(Exercise ex) {
    final f = _features;
    final itemById = {for (final item in ex.items) item.id: item};
    final placed = {
      for (final placements in _assignPlacements.values) ...placements,
    };
    final bank = _assignTileOrder.where(
      (id) => f.assignItemReuse || !placed.contains(id),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _exercisePanelColor,
            borderRadius: BorderRadius.circular(14),
          ),
          child: f.assignTargetMode == AssignTargetMode.gaps
              ? _assignInlineLayout(ex, itemById)
              : _assignBins(ex, itemById),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final itemId in bank)
              ChoiceChip(
                key: Key('assign-tile-$itemId'),
                label: Text(itemById[itemId]?.value ?? ''),
                selected: _armedAssignItemId == itemId,
                onSelected: _answered ? null : (_) => _onAssignTileTap(itemId),
              ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('assign-check'),
          onPressed: _answered || placed.isEmpty ? null : _submitAssign,
          child: Text(_t('check')),
        ),
      ],
    );
  }

  Widget _assignBins(Exercise ex, Map<String, ExerciseItem> itemById) {
    final f = _features;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < ex.targets.length; i++)
          InkWell(
            key: Key('assign-target-${ex.targets[i].id}'),
            borderRadius: BorderRadius.circular(10),
            onTap: _answered
                ? null
                : () => _onAssignTargetTap(ex.targets[i].id),
            child: Container(
              margin: EdgeInsets.only(
                bottom: i + 1 < ex.targets.length ? 8 : 0,
              ),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _armedAssignItemId != null
                      ? scheme.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    f.targetLabel(ex.targets[i].id).isEmpty
                        ? _assignTargetFallbackLabel(f, i)
                        : f.targetLabel(ex.targets[i].id),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final itemId
                          in _assignPlacements[ex.targets[i].id] ??
                              const <String>[])
                        InputChip(
                          key: Key('assign-placed-${ex.targets[i].id}-$itemId'),
                          label: Text(itemById[itemId]?.value ?? ''),
                          onDeleted: _answered
                              ? null
                              : () => _removeAssignPlacement(
                                  ex.targets[i].id,
                                  itemId,
                                ),
                        ),
                      if ((_assignPlacements[ex.targets[i].id] ?? const [])
                          .isEmpty)
                        Text(
                          f.assignTargetMode == AssignTargetMode.slots
                              ? _t('empty')
                              : _t('nothingHereYet'),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _assignInlineLayout(Exercise ex, Map<String, ExerciseItem> itemById) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 8,
      children: [
        for (final segment in ex.layout)
          if (segment.isText)
            LookupText(
              segment.text,
              style: Theme.of(context).textTheme.titleMedium,
            )
          else
            GestureDetector(
              key: Key('assign-slot-${segment.targetId}'),
              behavior: HitTestBehavior.opaque,
              onTap: _answered
                  ? null
                  : () => _onAssignTargetTap(segment.targetId),
              child: Container(
                constraints: const BoxConstraints(minWidth: 56),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      (_assignPlacements[segment.targetId] ?? const []).isEmpty
                      ? scheme.surfaceContainerHighest
                      : scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _armedAssignItemId != null
                        ? scheme.primary
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Text(
                  (_assignPlacements[segment.targetId] ?? const <String>[])
                      .map((id) => itemById[id]?.value ?? '')
                      .join(', '),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
      ],
    );
  }

  void _onAssignTileTap(String itemId) {
    if (_answered) return;
    setState(
      () => _armedAssignItemId = _armedAssignItemId == itemId ? null : itemId,
    );
  }

  void _onAssignTargetTap(String targetId) {
    if (_answered) return;
    final itemId = _armedAssignItemId;
    if (itemId == null) return;
    setState(() {
      final f = _features;
      final placements = _assignPlacements.putIfAbsent(targetId, () => []);
      if (!f.assignItemReuse) {
        // An item lives in one place: take it out of wherever it was.
        for (final placed in _assignPlacements.values) {
          placed.remove(itemId);
        }
      } else if (placements.contains(itemId)) {
        _armedAssignItemId = null;
        return;
      }
      if (f.targetCapacity == TargetCapacity.single) placements.clear();
      placements.add(itemId);
      _armedAssignItemId = null;
    });
  }

  void _removeAssignPlacement(String targetId, String itemId) {
    if (_answered) return;
    setState(() => _assignPlacements[targetId]?.remove(itemId));
  }

  /// exactAssignments: every target holds exactly the items authored for it
  /// (order does not matter); a target with no authored items stays empty.
  void _submitAssign() {
    if (_answered) return;
    final expected = _features.assignmentsByTarget;
    if (expected.isEmpty) {
      _mark(false);
      return;
    }
    for (final target in _exercise.targets) {
      final placed = (_assignPlacements[target.id] ?? const <String>[]).toSet();
      final wanted = expected[target.id] ?? const <String>{};
      if (placed.length != wanted.length || !placed.containsAll(wanted)) {
        _mark(false);
        return;
      }
    }
    _mark(true);
  }

  /// The text the card shows for an exercise this version cannot play: its
  /// question, primary text, passage or inline sentence, else its first
  /// text element.
  String _notExecutablePrompt(Exercise ex) {
    final f = ExerciseFeatures(ex);
    for (final text in [
      f.questionText,
      f.primaryText,
      f.passageText,
      f.inlineSentence,
    ]) {
      if (text.trim().isNotEmpty) return text.trim();
    }
    return ex.promptElements
            .where((element) => element.isText)
            .map((element) => element.text.trim())
            .where((text) => text.isNotEmpty)
            .firstOrNull ??
        '';
  }

  /// A card in place of an exercise this version of QQL cannot play (Build
  /// 256 Revision 6, plan A.6): the prompt stays read-only above it, the
  /// card says why in one sentence, Continue moves on. A Story shows it and
  /// follows the node's next; the editor Preview shows it in practice
  /// Rounds too, which learners skip instead.
  Widget _notExecutableCard(Exercise ex) {
    return Column(
      key: const Key('not-executable-card'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _exercisePanelColor,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                'Not playable in this version',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 12),
              Text(
                'This version of QuisquisLingo cannot play this ${ex.primitive.label} exercise yet; it stays in the Course for a later version.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          key: const Key('not-executable-continue'),
          onPressed: _answered ? null : _skipNotExecutable,
          child: Text(_t('continue')),
        ),
      ],
    );
  }

  void _skipNotExecutable() {
    if (_answered) return;
    setState(() {
      _answered = true;
      _lastAnswerCorrect = true; // Nothing was asked.
      _feedback = 'Not playable in this version.';
    });
    _revealFeedback();
  }

  Widget _versionSkippedLine() => Text(
    '$_versionSkipped exercise${_versionSkipped == 1 ? '' : 's'} this version of QuisquisLingo cannot play ${_playsInOrder ? 'appeared as cards' : 'were skipped'}.',
    key: const Key('round-completed-version-skipped'),
  );

  PreferredSizeWidget _simpleRoundAppBar(Color background) => AppBar(
    backgroundColor: background,
    toolbarHeight: widget.reviewMode ? 104 : null,
    title: widget.reviewMode
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_screenTitle, softWrap: true),
              Text(
                _reviewContext,
                softWrap: true,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          )
        : Text(_screenTitle),
  );

  /// The language the answers are in: the answer side of a translation,
  /// else the items' stated language.
  TextLanguage? get _answerLanguage => _features.isTranslationClue
      ? _features.answerLanguage
      : _features.itemLanguage;

  /// "Correct answer: …" with the answer open to Word Lookup and its label
  /// not (Build 265).
  Widget _correctAnswerLine(String answer) {
    const marker = '\u0000';
    final line = _t('correctAnswer', {'answer': marker});
    final at = line.indexOf(marker);
    if (at < 0) return Text(_t('correctAnswer', {'answer': answer}));
    final after = line.substring(at + marker.length);
    return LookupText(
      answer,
      leading: TextSpan(text: line.substring(0, at)),
      trailing: after.isEmpty ? null : TextSpan(text: after),
      language: _answerLanguage,
    );
  }

  String _wordLookupLessonName(int lessonIndex) =>
      lessonIndex >= 0 && lessonIndex < widget.course.lessons.length
      ? const LessonPresentationService()
            .identity(widget.course, lessonIndex)
            .fullText
      : '';

  /// The one-time notice (Build 265), once per learner and Course, the
  /// first time a Round with Word Lookup opens; not in the Preview (no
  /// learner) nor in a Timed Round, whose clock would run behind it.
  void _maybeShowWordLookupNotice() {
    if (_wordLookupNoticeChecked ||
        !_ready ||
        _wordLookup.isEmpty ||
        widget.previewMode ||
        widget.round.roundType == RoundType.timed ||
        !WordLookupNotice.enabled) {
      return;
    }
    _wordLookupNoticeChecked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final id = WordLookupNotice.noticeId(widget.course.courseId);
      final seen = await _settings.hasSeenLearnerOneTimeNotice(id);
      if (seen != false || !mounted) return;
      await _settings.markLearnerOneTimeNoticeSeen(id);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          key: const Key('word-lookup-notice'),
          content: Text(_t('wordLookup.notice')),
          actions: [
            FilledButton(
              key: const Key('word-lookup-notice-ok'),
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(_t('gotIt')),
            ),
          ],
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final page = _buildPage(context);
    if (_wordLookup.isEmpty) return page;
    _maybeShowWordLookupNotice();
    return WordLookupScope(
      index: _wordLookup,
      currentLessonIndex: _lessonIndex,
      lessonName: _wordLookupLessonName,
      note: _t('wordLookup.note'),
      notePlural: _t('wordLookup.notes'),
      actionLabel: _t('wordLookup.action'),
      courseId: widget.course.courseId,
      child: page,
    );
  }

  Widget _buildPage(BuildContext context) {
    if (!widget.previewMode && BetaLifecycleService.isExpired()) {
      return const BetaExpiredView();
    }
    final background = _roundBackground(
      _autumnBackgrounds[widget.roundIndex % _autumnBackgrounds.length],
    );
    final intro = _lessonIntro;
    // The Preview of a card alone shows the card and closes after it.
    if (_ready &&
        !_initializationFailed &&
        (_queue.isNotEmpty || widget.previewMode) &&
        intro != null &&
        !_introAcknowledged) {
      final introFeatures = ExerciseFeatures(intro);
      return Scaffold(
        backgroundColor: background,
        appBar: _simpleRoundAppBar(background),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              Text(
                _t('beforeYouStart'),
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _exercisePanelColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  introFeatures.introText,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              // The card's Open GuideBook action (Build 257): asked for by
              // the card, offered while the Course uses GuideBooks and the
              // GuideBook is published (any GuideBook in Preview).
              if (introFeatures.guidebookButton &&
                  widget.course.useGuidebook &&
                  (widget.previewMode ||
                      widget
                          .lesson
                          .guidebook
                          .publicationState
                          .isPublished)) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  key: const Key('before-you-start-guidebook'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => GuidebookScreen(
                        course: widget.course,
                        lesson: widget.lesson,
                        lessonIndex: widget.course.lessons.indexWhere(
                          (lesson) => lesson.lessonId == widget.lesson.lessonId,
                        ),
                        includeDraftContent: widget.previewMode,
                        // Build 266: at the Round's focus module.
                        focusModuleId: widget.round.focusModuleId,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: Text(_t('openGuidebook')),
                ),
              ],
              const SizedBox(height: 8),
              FilledButton(
                key: const Key('before-you-start-continue'),
                onPressed: () {
                  if (_queue.isEmpty) {
                    Navigator.of(context).maybePop();
                    return;
                  }
                  setState(() => _introAcknowledged = true);
                  final exercise = _exercise;
                  final generation = _preparedExerciseGeneration;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _startTimedCountdown();
                    _activatePreparedAudio(
                      exercise,
                      generation,
                      trigger: 'before_you_start_continue',
                    );
                  });
                },
                child: Text(
                  _queue.isEmpty ? 'Close preview' : _t('continueToRound'),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_timedOut) {
      return Scaffold(
        backgroundColor: background,
        appBar: _simpleRoundAppBar(background),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_off_outlined, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    _t('timed.timeUp'),
                    key: const Key('timed-timeout'),
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(_t('timed.incomplete')),
                  if (_timeoutSaving) const CircularProgressIndicator(),
                  if (_timeoutSaved)
                    Text(
                      _t('timed.correctXpKept', {'xp': _timeoutXp}),
                      key: const Key('timed-timeout-xp'),
                    ),
                  if (_timeoutError != null) ...[
                    Text(_timeoutError!),
                    TextButton(
                      onPressed: _saveTimedTimeoutXp,
                      child: Text(_t('timed.retrySaving')),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton(
                    key: const Key('timed-retry'),
                    onPressed: !_timeoutSaved
                        ? null
                        : () => Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => RoundScreen(
                                course: widget.course,
                                lesson: widget.lesson,
                                round: widget.round,
                                ttsLanguage: widget.ttsLanguage,
                                roundIndex: widget.roundIndex,
                                previewMode: widget.previewMode,
                                viewOnlyMode: widget.viewOnlyMode,
                                reviewMode: widget.reviewMode,
                                completeLessonOnFinish:
                                    widget.completeLessonOnFinish,
                                settingsService: widget.settingsService,
                                ttsCacheService: widget.ttsCacheService,
                                recordedAudioService:
                                    widget.recordedAudioService,
                                mascotAssets: widget.mascotAssets,
                                mascotRandom: widget.mascotRandom,
                                timedClock: widget.timedClock,
                              ),
                            ),
                          ),
                    child: Text(_t('timed.retry')),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    if (!_ready) {
      return Scaffold(
        backgroundColor: background,
        appBar: _simpleRoundAppBar(background),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_queue.isEmpty) {
      return Scaffold(
        backgroundColor: background,
        appBar: _simpleRoundAppBar(background),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                _initializationFailed
                    ? 'This round could not be opened safely.'
                    : (_audioWasSkipped
                          ? !_audioExercisesEnabled
                                ? 'All exercises in this round use audio and Audio Exercises are disabled.'
                                : 'All audio exercises in this round are currently unavailable.'
                          : _versionSkipped > 0
                          ? 'This version of QuisquisLingo cannot play the exercises of this round yet.'
                          : 'This round has no usable exercises.'),
              ),
              const SizedBox(height: 8),
              Text(
                _initializationFailed
                    ? 'QuisquisLingo kept the app running and wrote the error to the crash log.'
                    : (_audioWasSkipped
                          ? !_audioExercisesEnabled
                                ? 'Turn on audio to play it? The button below '
                                      'switches on Enable Audio Exercises'
                                      '${_turnsOnTts ? ' and Text-to-speech' : ''} '
                                      'in your Audio Settings, where you can '
                                      'switch them off again.'
                                : 'Check Text-to-speech and available Recorded MP3 sources in Audio Settings.'
                          : _versionSkipped > 0
                          ? 'They are kept in the Course unchanged; a later version of QuisquisLingo will play them.'
                          : 'Open Course Editor > Run course audit to see the problems that need to be corrected.'),
              ),
              if (!_initializationFailed &&
                  _audioWasSkipped &&
                  !_audioExercisesEnabled &&
                  !widget.previewMode) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    key: const Key('round-turn-on-audio'),
                    onPressed: _turnOnAudio,
                    icon: const Icon(Icons.volume_up_outlined),
                    label: const Text('Turn on audio'),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
    final ex = _exercise;
    final totalShown = _queue.length;
    _mascotPlacement = _placeMascot(context, ex);

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        toolbarHeight: widget.reviewMode ? 104 : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.reviewMode) ...[
              Text(_screenTitle, softWrap: true),
              Text(
                _reviewContext,
                softWrap: true,
                style: Theme.of(context).textTheme.labelSmall,
              ),
              if (_reviewPhase)
                Text(
                  _t('reviewingMissed'),
                  style: Theme.of(context).textTheme.labelSmall,
                ),
            ] else ...[
              Text(
                _reviewPhase
                    ? _t('roundInReview', {'round': _roundTitle})
                    : _roundTitle,
              ),
              Text(
                _t('lessonLine', {
                  'language': widget.course.targetLanguage,
                  'n': _lessonIndex + 1,
                  'title': widget.lesson.title,
                }),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ],
          ],
        ),
        actions: [
          // A Select with automatic audio has its replay control in the body.
          if (_features.primaryAudioText != null &&
              !(ex.primitive == ExercisePrimitive.select &&
                  _features.automaticAudio != null))
            IconButton(
              tooltip: _t('playAudio'),
              icon: const Icon(Icons.volume_up_outlined),
              onPressed: _speak,
            ),
          IconButton(
            tooltip: 'Report a problem',
            icon: const Icon(Icons.flag_outlined),
            onPressed: _showReportSheet,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(value: (_position + 1) / totalShown),
        ),
      ),
      body: SafeArea(
        child: ListView(
          key: _storyScrolls ? const Key('story-scroll') : null,
          controller: _storyScrolls ? _storyScroll : _pageScroll,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            if (widget.round.roundType == RoundType.timed)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _t('timed.timeLeft', {
                    'time':
                        '${_timedSecondsLeft ~/ 60}:${(_timedSecondsLeft % 60).toString().padLeft(2, '0')}',
                  }),
                  key: const Key('timed-countdown'),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            if (_storyScrolls) ...[
              if (_storyLog.isNotEmpty) _storyStepsLine(),
              for (var i = 0; i < _storyLog.length; i++)
                _storyEntryCard(_storyLog[i], i),
              _storyNowMarker(),
            ],
            if (_reviewPhase)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  _t('reviewingMissed'),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ...[
              // Every exercise has a title, its preset's name, and an
              // instruction (Build 261 Revision 3, owner decisions of 2
              // October 2026). Inside a Story no title is shown, only the
              // instruction (the Round is already called "Story: …"). A
              // dialogue line shows no heading (owner decision, 28 September
              // 2026): the speaker's bubble says what it is. A card for an
              // exercise this version cannot play shows neither heading nor
              // instruction (Build 256 Revision 6).
              if (!widget.round.isStory &&
                  ExerciseFeatures(ex).kind !=
                      LearnerExerciseKind.dialogueLine &&
                  ExerciseFeatures(ex).kind != LearnerExerciseKind.page &&
                  ex.isExecutable) ...[
                Text(
                  ExerciseCopyService.title(widget.course, ex),
                  key: const Key('exercise-heading'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: .7,
                  ),
                ),
                const SizedBox(height: 4),
              ],
              // A Page has no instruction line either (Build 258), nor a
              // Dialogue line (Build 259 Revision 5, owner decision: no
              // "Read or listen, then continue.").
              if (ex.isExecutable &&
                  ExerciseFeatures(ex).kind != LearnerExerciseKind.page &&
                  ExerciseFeatures(ex).kind != LearnerExerciseKind.dialogueLine)
                _withMascot(
                  _promptAsInstruction
                      ? ExerciseMascotAnchor.prompt
                      : ExerciseMascotAnchor.none,
                  Text(
                    _promptAsInstruction
                        ? ExerciseCopyService.displayPrompt(
                            widget.course,
                            _displayedPrompt,
                          )
                        : ExerciseCopyService.instructionForExercise(
                            widget.course,
                            ex,
                          ),
                    key: _features.isTranslationChoice
                        ? const Key('translation-choice-instruction')
                        : const Key('exercise-instruction'),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
            if (_promptShown && !_promptAsInstruction) ...[
              const SizedBox(height: 12),
              _withMascot(
                ExerciseMascotAnchor.prompt,
                LookupText(
                  ExerciseCopyService.displayPrompt(
                    widget.course,
                    _displayedPrompt,
                  ),
                  textKey: const Key('exercise-prompt-text'),
                  style: Theme.of(context).textTheme.titleMedium,
                  language: _features.promptLanguage,
                ),
              ),
            ],
            const SizedBox(height: 20),
            // Keep the whole exercise screen scrollable. On short desktop
            // windows or larger system text sizes this prevents a RenderFlex
            // overflow at the bottom while preserving normal phone behavior.
            // A Story cover draws its picture on the cover card (Build 256
            // Revision 5), so the shared illustration would show it twice.
            if (_features.illustrationAsset.isNotEmpty &&
                !_features.isTranslationChoice &&
                _features.kind != LearnerExerciseKind.storyCover) ...[
              _exerciseImage(ex),
              const SizedBox(height: 14),
            ] else
              ...[],
            KeyedSubtree(
              key: Key('exercise-renderer-${ex.primitive.serialized}'),
              child: _exerciseBody(ex),
            ),
            if (_answered && widget.round.roundType != RoundType.test) ...[
              const SizedBox(height: 18),
              Container(
                key: const Key('exercise-feedback-surface'),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _feedbackPanelColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _feedback,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    ..._translationFeedbackAudio(ex),
                    if (_features.showAlternatives ==
                            FeedbackAlternatives.all &&
                        ex.canonicalEvaluation.correctOrders.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Semantics(
                        label:
                            '${ex.canonicalEvaluation.correctOrders.length} correct translations',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _t('correctTranslations'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            for (final answer
                                in ex.canonicalEvaluation.correctOrders)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: LookupText(
                                  answer.text,
                                  leading: const TextSpan(text: '• '),
                                  language: _answerLanguage,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ] else if (_features.kind ==
                            LearnerExerciseKind.selectCharacter &&
                        !_lastAnswerCorrect) ...[
                      Text(_t('correctAnswerLabel')),
                      for (final item in ex.items.where(
                        (item) => ex.canonicalEvaluation.correctItemIds
                            .contains(item.id),
                      ))
                        if (item.image.isNotEmpty)
                          PortableExerciseImage(
                            asset: item.image,
                            width: 128,
                            height: 128,
                          )
                        else
                          Text(item.text),
                    ] else if (_features.showAlternatives ==
                        FeedbackAlternatives.ranked) ...[
                      if (_translationFeedback.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _lastAnswerCorrect
                              ? _t('otherCorrectTranslations')
                              : _translationFeedbackPartial
                              ? _t('somePossibleTranslations')
                              : _t('correctTranslations'),
                          key: const Key('translation-feedback-heading'),
                        ),
                        for (var i = 0; i < _translationFeedback.length; i++)
                          LookupText(
                            _translationFeedback[i],
                            leading: const TextSpan(text: '• '),
                            textKey: ValueKey('translation-feedback-answer-$i'),
                            language: _answerLanguage,
                          ),
                      ],
                    ] else if (ex.primitive != ExercisePrimitive.presentation &&
                        (!_lastAnswerCorrect ||
                            (ex.primitive == ExercisePrimitive.input &&
                                _features.gapFieldTargets.isEmpty))) ...[
                      const SizedBox(height: 5),
                      _correctAnswerLine(_correctAnswerText(ex)),
                    ],
                    if (_lastAnswerCorrect &&
                        _acceptedDifferences.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        _t(
                          _acceptedDifferences.length == 1
                              ? 'acceptedDifference'
                              : 'acceptedDifferences',
                          {'list': _acceptedDifferences.join(', ')},
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _finishing ? null : _next,
                // One verb for moving on (owner decision, 28 September
                // 2026): Continue, as after a card or a line; the terminal
                // labels stay.
                child: Text(
                  _finishing
                      ? _t('finishing.$_nounKey')
                      : !_reviewPhase &&
                            !_playsInOrder &&
                            _position + 1 == _queue.length &&
                            _wrongFirstPass.isNotEmpty
                      ? _t('reviewMistakes')
                      : (_position + 1 == _queue.length
                            ? (_playsInOrder &&
                                      !widget.previewMode &&
                                      !_exercise.isExecutable
                                  ? _t('leave.$_nounKey')
                                  : _t('finish.$_nounKey'))
                            : _t('continue')),
                ),
              ),
            ],
            if (_answered && widget.round.roundType == RoundType.test) ...[
              const SizedBox(height: 18),
              FilledButton(
                key: const Key('test-next'),
                onPressed: _finishing ? null : _next,
                child: Text(
                  _position + 1 == _queue.length
                      ? _t('testSeeResults')
                      : _t('testNextQuestion'),
                ),
              ),
            ],
            // A scrolling Story keeps room below the active item, so "Now"
            // can always be scrolled to the top and the move is visible.
            if (_storyScrolls)
              SizedBox(
                key: const Key('story-spacer'),
                height: MediaQuery.sizeOf(context).height * 0.6,
              ),
          ],
        ),
      ),
    );
  }
}
