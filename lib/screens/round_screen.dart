import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/alpha_lifecycle_service.dart';
import '../widgets/alpha_expired_view.dart';
import '../models/course_models.dart';
import '../services/progress_service.dart';
import '../services/learning_completion_service.dart';
import '../services/report_service.dart';
import '../services/tts_cache_service.dart';
import '../services/settings_service.dart';
import '../services/course_service.dart';
import '../services/course_audit_service.dart';
import '../services/sound_effect_service.dart';
import '../services/recorded_audio_service.dart';
import '../services/exercise_copy_service.dart';
import '../services/crash_log_service.dart';
import 'guidebook_screen.dart';

class RoundScreen extends StatefulWidget {
  final Course course;
  final Chapter chapter;
  final Topic topic;
  final LearningRound round;
  final String ttsLanguage;
  final int roundIndex;
  final bool previewMode;

  const RoundScreen({
    super.key,
    required this.course,
    required this.chapter,
    required this.topic,
    required this.round,
    required this.ttsLanguage,
    required this.roundIndex,
    this.previewMode = false,
  });

  @override
  State<RoundScreen> createState() => _RoundScreenState();
}

class _ChoiceOption {
  final String text;
  final bool correct;
  const _ChoiceOption(this.text, this.correct);
}

class _MatchOption {
  final String id;
  final String label;
  const _MatchOption(this.id, this.label);
}

class _MatchPairView {
  final String leftId;
  final String leftLabel;
  final String rightId;
  const _MatchPairView({
    required this.leftId,
    required this.leftLabel,
    required this.rightId,
  });
}

class _RoundScreenState extends State<RoundScreen> {
  final _progress = ProgressService();
  late final LearningCompletionService _completion;
  final _ttsCache = TtsCacheService();
  final _reports = ReportService();
  final _settings = SettingsService();
  final _sounds = SoundEffectService();
  final _recordedAudio = RecordedAudioService();
  final _random = Random();

  List<int> _queue = [];
  bool _ready = false;
  bool _introAcknowledged = false;
  bool _initializationFailed = false;
  bool _ttsWasSkipped = false;
  bool _wasCompleted = false;
  final Set<int> _wrongFirstPass = {};
  int _position = 0;
  int _firstPassCorrect = 0;
  int _errorsThisAttempt = 0;
  bool _reviewPhase = false;
  bool _answered = false;
  bool _lastAnswerCorrect = false;
  String _feedback = '';
  int? _selected;
  final TextEditingController _textController = TextEditingController();
  final List<String> _builtOrder = [];
  final List<TextEditingController> _missingWordControllers = [];
  final Map<String, String> _matchingSelections = {};
  List<_ChoiceOption> _choiceOptions = [];
  List<String> _tokenOptions = [];
  List<_MatchOption> _matchingRightOptions = [];
  List<_MatchPairView> _matchingLeftPairs = [];

  static const _autumnBackgrounds = <Color>[
    Color(0xFFF4EBDD), // warm cream
    Color(0xFFE7E1CF), // oat
    Color(0xFFE9D9CE), // pale terracotta
    Color(0xFFDDE5D5), // sage
    Color(0xFFE9DFC7), // muted harvest gold
    Color(0xFFE5D9D2), // dusty rose-brown
  ];

  int get _exerciseIndex => _queue[_position];
  Exercise get _exercise => widget.round.exercises[_exerciseIndex];
  LearningContent? get _topicIntro {
    for (final content in widget.round.content) {
      if (content.role == 'topic_intro' && content.text.trim().isNotEmpty) {
        return content;
      }
    }
    return null;
  }

  int get _chapterNumber {
    final index = widget.course.chapters.indexWhere(
      (c) => c.id == widget.chapter.id,
    );
    return index < 0 ? 1 : index + 1;
  }

  @override
  void initState() {
    super.initState();
    _completion = LearningCompletionService(progressService: _progress);
    _initializeRound();
  }

  bool _usesTts(Exercise ex) {
    final text = ex.tts?.trim() ?? '';
    if (widget.course.audioMode == 'recorded') return false;
    if (widget.course.audioMode == 'hybrid' &&
        text.isNotEmpty &&
        _recordedAudio.segment(text, widget.course.audioLibrary) != null) {
      return false;
    }
    return ex.type == 'audio_match' ||
        ex.type == 'listening_choice' ||
        ex.type == 'listening_comprehension' ||
        text.isNotEmpty;
  }

  Future<bool> _playCourseAudio(String text) async {
    if (widget.course.audioMode != 'tts') {
      final recorded = await _recordedAudio.playConcatenated(
        text,
        widget.course.audioLibrary,
      );
      if (recorded) return true;
      if (widget.course.audioMode == 'recorded') return false;
    }
    return _ttsCache.speak(text: text, language: widget.ttsLanguage);
  }

  Future<void> _initializeRound() async {
    await CrashLogService.instance.recordDebugEvent(
      'Round: initialization started ${widget.round.id}',
    );
    try {
      // Locally edited courses may temporarily contain invalid exercises. The
      // Course Editor reports them, while the learner-facing Round screen skips
      // exercises with structural audit errors instead of indexing invalid data.
      final audit = CourseAuditService();
      final valid = List<int>.generate(widget.round.exercises.length, (i) => i)
          .where(
            (i) => !audit
                .auditExercise(widget.round.exercises[i])
                .any((issue) => issue.severity == AuditSeverity.error),
          )
          .toList();
      await CrashLogService.instance.recordDebugEvent(
        'Round: audit completed ${widget.round.id}, valid=${valid.length}',
      );
      final skipTts = await _settings.shouldSkipTtsExercises();
      final filtered = skipTts
          ? valid.where((i) => !_usesTts(widget.round.exercises[i])).toList()
          : valid;
      _ttsWasSkipped = filtered.length != valid.length;
      _queue = filtered;
      _wasCompleted = (await _progress.getCompletedRounds(
        courseId: widget.course.courseId,
      )).contains(widget.round.id);
      await CrashLogService.instance.recordDebugEvent(
        'Round: preferences loaded ${widget.round.id}, queue=${_queue.length}',
      );
      _shuffleDifferentInts(_queue);
      if (!mounted) return;
      if (_queue.isNotEmpty) {
        await CrashLogService.instance.recordDebugEvent(
          'Round: preparing first exercise ${widget.round.id}',
        );
        _prepareExercise();
        // Choice-based exercises must be fully prepared before the learner UI
        // becomes ready. This prevents a transient screen with no answer buttons.
        final first = _exercise;
        final needsChoices =
            first.type == 'choice' ||
            first.type == 'gap_choice' ||
            first.type == 'listening_choice' ||
            first.type == 'listening_comprehension' ||
            first.type == 'reading_comprehension' ||
            first.type == 'dialogue_response';
        if (needsChoices &&
            first.answers.isNotEmpty &&
            _choiceOptions.isEmpty) {
          _choiceOptions = List<_ChoiceOption>.generate(
            first.answers.length,
            (i) => _ChoiceOption(first.answers[i], i == first.correct),
          );
          _shuffleDifferentChoices(_choiceOptions);
          await CrashLogService.instance.recordDebugEvent(
            'Round: rebuilt missing choice options ${widget.round.id}/${first.id}',
          );
        }
        await CrashLogService.instance.recordDebugEvent(
          'Round: first exercise prepared ${widget.round.id}',
        );
      }
      if (!mounted) return;
      setState(() => _ready = true);
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

  @override
  void dispose() {
    _textController.dispose();
    for (final c in _missingWordControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _prepareExercise() {
    final ex = _exercise;
    _answered = false;
    _lastAnswerCorrect = false;
    _feedback = '';
    _selected = null;
    _textController.clear();
    _builtOrder.clear();
    for (final c in _missingWordControllers) {
      c.dispose();
    }
    _missingWordControllers
      ..clear()
      ..addAll(
        List.generate(ex.missingWords.length, (_) => TextEditingController()),
      );
    _matchingSelections.clear();

    _choiceOptions = List<_ChoiceOption>.generate(
      ex.answers.length,
      (i) => _ChoiceOption(ex.answers[i], i == ex.correct),
    );
    _shuffleDifferentChoices(_choiceOptions);

    _tokenOptions = _shuffledTokens(ex);
    if (ex.interaction.kind == 'match') {
      final byId = <String, ExerciseItem>{
        for (final item in ex.interaction.items) item.id: item,
      };
      _matchingRightOptions = [];
      _matchingLeftPairs = [];
      for (final pair in ex.evaluation.pairs) {
        if (pair.length != 2) continue;
        final left = byId[pair[0]];
        final right = byId[pair[1]];
        if (left == null || right == null) continue;
        _matchingLeftPairs.add(
          _MatchPairView(
            leftId: left.id,
            leftLabel: left.value,
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
      if (!mounted) return;
      final isListening =
          ex.type == 'listening_choice' ||
          ex.type == 'listening_comprehension' ||
          ex.type == 'audio_match' ||
          ex.type == 'missing_word' ||
          ex.type == 'listening_spelling';
      if (isListening) {
        // Recorded-only audio must remain available even when system TTS is
        // disabled. Skip only when this exercise actually requires TTS.
        final needsSystemTts = _usesTts(ex);
        final enabled = await _settings.isTtsEnabled();
        if (!mounted) return;
        if (needsSystemTts && !enabled) {
          _ttsWasSkipped = true;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              duration: Duration(seconds: 8),
              content: Text(
                'Audio exercise skipped because Text-to-speech is disabled.',
              ),
            ),
          );
          await _next();
          return;
        }
        if (ex.tts != null && ex.tts!.isNotEmpty) {
          await _speak();
        }
      } else {
        await _prepareTts();
      }
    });
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
    final tokens = List<String>.from(ex.tokens);
    if (tokens.length < 2) return tokens;

    // A valid random shuffle may legitimately reproduce the source order,
    // including the correct order in a sentence-building exercise.
    tokens.shuffle(_random);
    return tokens;
  }

  Future<void> _prepareTts() async {
    final text = _exercise.tts;
    if (text == null || text.isEmpty) return;
    if (widget.course.audioMode == 'tts' ||
        (widget.course.audioMode == 'hybrid' &&
            _recordedAudio.segment(text, widget.course.audioLibrary) == null)) {
      await _ttsCache.synthesizeCached(
        text: text,
        language: widget.ttsLanguage,
      );
    }
  }

  Future<void> _speakText(String text) async {
    if (text.trim().isEmpty) return;
    final ok = await _playCourseAudio(text);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 8),
          content: Text(
            'Audio unavailable. Enable Text-to-speech in Settings and make sure a voice for this course language is installed.',
          ),
        ),
      );
    }
  }

  Future<void> _speak() async {
    final text = _exercise.tts;
    if (text == null || text.isEmpty) return;
    final ok = await _playCourseAudio(text);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          duration: Duration(seconds: 8),
          content: Text(
            'Audio unavailable. Enable Text-to-speech in Settings and make sure a system voice is installed. On Linux, install eSpeak NG or eSpeak.',
          ),
        ),
      );
    }
  }

  String _correctAnswerText(Exercise ex) {
    switch (ex.type) {
      case 'choice':
      case 'gap_choice':
      case 'listening_choice':
      case 'listening_comprehension':
      case 'reading_comprehension':
      case 'dialogue_response':
      case 'icon_choice':
        if (ex.correct != null &&
            ex.correct! >= 0 &&
            ex.correct! < ex.answers.length) {
          return ex.answers[ex.correct!];
        }
        return 'See the course answer.';
      case 'flashcard':
        return 'Review the flashcard.';
      case 'missing_word':
        if (ex.missingWords.isNotEmpty) return ex.missingWords.join(' / ');
        break;
      case 'listening_spelling':
        if (ex.accepted.isNotEmpty) return ex.accepted.first;
        if ((ex.tts ?? '').trim().isNotEmpty) return ex.tts!.trim();
        break;
      case 'fill_blank':
        if (ex.tts != null && ex.tts!.trim().isNotEmpty) return ex.tts!;
        if (ex.accepted.isNotEmpty) return ex.accepted.first;
        break;
      case 'word_order':
        if (ex.orderAnswer.isNotEmpty) return ex.orderAnswer.join(' ');
        break;
      case 'image_word':
        if (ex.orderAnswer.isNotEmpty) return ex.orderAnswer.join('');
        break;
      case 'audio_match':
        if (ex.pairs.isNotEmpty) {
          return ex.pairs.map((p) => '${p[0]} = ${p[1]}').join('; ');
        }
        break;
      case 'matching':
      case 'word_match':
      case 'super_match':
        if (ex.pairs.isNotEmpty) {
          return ex.pairs.map((p) => '${p[0]} = ${p[1]}').join('; ');
        }
        break;
    }
    return 'See the course answer.';
  }

  String _answerState() {
    if (_selected != null && _selected! < _choiceOptions.length) {
      return 'Selected choice ${_selected! + 1}: ${_choiceOptions[_selected!].text}';
    }
    if (_textController.text.trim().isNotEmpty) {
      return 'Typed answer: ${_textController.text.trim()}';
    }
    if (_builtOrder.isNotEmpty) return 'Word order: ${_builtOrder.join(' ')}';
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
      chapter: widget.chapter,
      topic: widget.topic,
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
    if (_answered) return;
    setState(() {
      _answered = true;
      _lastAnswerCorrect = correct;
      _feedback = correct ? 'Correct' : 'Incorrect';
      if (!correct) _errorsThisAttempt++;
      if (!_reviewPhase) {
        if (correct) {
          _firstPassCorrect++;
        } else {
          _wrongFirstPass.add(_exerciseIndex);
        }
      }
    });
  }

  void _flashcardResult({required bool reviewAgain}) {
    if (_answered) return;
    setState(() {
      _answered = true;
      _lastAnswerCorrect = true; // Flashcards have no correct/incorrect answer.
      if (reviewAgain) {
        _feedback = 'This card will be shown again later in this round.';
        _queue.add(_exerciseIndex);
      } else {
        _feedback = 'Card reviewed.';
      }
    });
  }

  void _answerChoice(int displayedIndex) {
    _selected = displayedIndex;
    _mark(_choiceOptions[displayedIndex].correct);
  }

  String _normalize(String value, {bool stripDiacritics = false}) {
    var s = value.toLowerCase().replaceAll('’', "'");
    // Preserve apostrophes because they can distinguish correct spelling
    // (for example un'altra vs un altra). Ignore ordinary punctuation and
    // redundant whitespace without deleting meaningful word boundaries.
    s = s.replaceAll(RegExp(r'[.!?,;:\"“”()\[\]{}]'), ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (!stripDiacritics) return s;
    const accents = {
      'à': 'a',
      'á': 'a',
      'â': 'a',
      'ä': 'a',
      'ã': 'a',
      'å': 'a',
      'è': 'e',
      'é': 'e',
      'ê': 'e',
      'ë': 'e',
      'ì': 'i',
      'í': 'i',
      'î': 'i',
      'ï': 'i',
      'ò': 'o',
      'ó': 'o',
      'ô': 'o',
      'ö': 'o',
      'õ': 'o',
      'ù': 'u',
      'ú': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
      'ñ': 'n',
      'ý': 'y',
      'ÿ': 'y',
      'ß': 'ss',
    };
    accents.forEach((a, b) => s = s.replaceAll(a, b));
    return s;
  }

  bool _hasDiacritic(String value) => RegExp(r'[À-ÖØ-öø-ÿ]').hasMatch(value);

  bool _typedMatches(String typed, String expected) {
    final a = _normalize(typed);
    final b = _normalize(expected);
    if (a == b) return true;
    // A missing accent is tolerated for learners who do not have the target
    // keyboard. If the learner typed a diacritic, however, it must be the
    // correct one rather than a different accent.
    if (!_hasDiacritic(typed)) {
      return _normalize(typed, stripDiacritics: true) ==
          _normalize(expected, stripDiacritics: true);
    }
    return false;
  }

  void _submitFill() {
    final typed = _textController.text;
    final accepted = <String>{..._exercise.accepted};

    // Fill-in exercises accept both the missing fragment and the complete
    // displayed phrase when the course provides it through TTS. This makes
    // answers such as "buonasera" valid for "Buona____" as well as "sera".
    final tts = _exercise.tts?.trim();
    if (tts != null && tts.isNotEmpty) accepted.add(tts);

    final correct = accepted.any((expected) => _typedMatches(typed, expected));
    _mark(correct);
  }

  void _submitOrder() => _mark(
    _typedMatches(_builtOrder.join(' '), _exercise.orderAnswer.join(' ')),
  );

  void _submitImageWord() =>
      _mark(_typedMatches(_builtOrder.join(), _exercise.orderAnswer.join()));

  void _submitMatching() {
    if (_exercise.pairs.isEmpty) {
      _mark(false);
      return;
    }
    for (final pair in _matchingLeftPairs) {
      if (_matchingSelections[pair.leftId] != pair.rightId) {
        _mark(false);
        return;
      }
    }
    _mark(true);
  }

  Future<void> _next() async {
    if (_position + 1 < _queue.length) {
      setState(() => _position++);
      _prepareExercise();
      return;
    }

    if (!_reviewPhase && _wrongFirstPass.isNotEmpty) {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Review your mistakes'),
          content: const Text("Let's try again the exercises you got wrong."),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      setState(() {
        _reviewPhase = true;
        _queue = _wrongFirstPass.toList();
        _shuffleDifferentInts(_queue);
        _position = 0;
      });
      _prepareExercise();
      return;
    }

    if (widget.previewMode) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Preview complete'),
          content: Text(
            'Temporary result: ${_errorsThisAttempt == 0 ? 'perfect' : '$_errorsThisAttempt error${_errorsThisAttempt == 1 ? '' : 's'}'}. No learner progress was recorded.',
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
    final completion = await _completion.completeRound(
      LearningCompletionRequest(
        roundId: widget.round.id,
        courseId: widget.course.courseId,
        courseCode: code,
        readAttemptFacts: () => LearningCompletionAttemptFacts(
          errorsThisAttempt: _errorsThisAttempt,
          firstPassCorrect: _firstPassCorrect,
          wasCompletedAtStart: _wasCompleted,
          ttsWasSkipped: _ttsWasSkipped,
        ),
      ),
      onNewLaurel: () async {
        if (await _settings.areSoundEffectsEnabled()) {
          await _sounds.playDuelWin();
        }
      },
      getWeeklyXpTarget: _settings.getWeeklyXpTarget,
    );
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Round completed'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (completion.roundXp.correctAnswerXp > 0)
              Text('Correct answers: ${completion.roundXp.correctAnswerXp} XP'),
            if (completion.roundXp.perfectBonusXp > 0)
              Text('Perfect bonus: +${completion.roundXp.perfectBonusXp} XP'),
            if (completion.roundXp.laurelBonusXp > 0)
              Text('First Laurel: +${completion.roundXp.laurelBonusXp} XP'),
            Text('Total: ${completion.roundXp.totalXp} XP'),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (mounted &&
        completion.crossedWeeklyXpTarget &&
        await _completion.claimWeeklyGoalCelebration()) {
      if (await _settings.areSoundEffectsEnabled()) await _sounds.playDuelWin();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Weekly goal reached!'),
          content: Text(
            '${completion.weeklyXpAfter} / ${completion.weeklyXpTarget} XP',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  Widget _choiceExercise(Exercise ex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: List.generate(_choiceOptions.length, (i) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: FilledButton.tonal(
            onPressed: _answered ? null : () => _answerChoice(i),
            child: Text(_choiceOptions[i].text),
          ),
        );
      }),
    );
  }

  Widget _fillBlankExercise(Exercise ex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(ex.question, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 10),
        if (ex.hint.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              'Hint: ${ex.hint}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        const SizedBox(height: 16),
        TextField(
          controller: _textController,
          enabled: !_answered,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Your answer',
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _answered ? null : _submitFill,
          child: const Text('Check'),
        ),
      ],
    );
  }

  Widget _listeningSpellingExercise(Exercise ex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.tonalIcon(
          onPressed: _answered || (ex.tts ?? '').trim().isEmpty
              ? null
              : () => _speakText(ex.tts!),
          icon: const Icon(Icons.volume_up_outlined),
          label: const Text('Play audio'),
        ),
        const SizedBox(height: 14),
        if (ex.question.trim().isNotEmpty) ...[
          Text(ex.question, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _textController,
          enabled: !_answered,
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) {
            if (!_answered && _textController.text.trim().isNotEmpty) {
              _submitFill();
            }
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Your answer',
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _answered || _textController.text.trim().isEmpty
              ? null
              : _submitFill,
          child: const Text('Check'),
        ),
      ],
    );
  }

  Widget _wordOrderExercise(Exercise ex) {
    final available = List<String>.from(_tokenOptions);
    for (final token in _builtOrder) {
      available.remove(token);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          child: const Text('Check'),
        ),
      ],
    );
  }

  Widget _imageWordExercise(Exercise ex) {
    final available = List<String>.from(_tokenOptions);
    for (final token in _builtOrder) {
      available.remove(token);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ex.prompt.isNotEmpty &&
            !ExerciseCopyService.isLegacyInstruction(ex.prompt)) ...[
          Text(
            ExerciseCopyService.displayPrompt(widget.course, ex.prompt),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
        ],
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.55),
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
          onPressed: _answered || _builtOrder.isEmpty ? null : _submitImageWord,
          child: const Text('Check'),
        ),
      ],
    );
  }

  String _missingWordDisplay(Exercise ex) {
    var text = ex.prompt;
    for (final word in ex.missingWords) {
      final pattern = RegExp(RegExp.escape(word), caseSensitive: false);
      text = text.replaceFirst(pattern, '_____');
    }
    return text;
  }

  void _submitMissingWords(Exercise ex) {
    if (_answered) return;
    var correct = _missingWordControllers.length == ex.missingWords.length;
    for (
      var i = 0;
      i < _missingWordControllers.length && i < ex.missingWords.length;
      i++
    ) {
      if (!_typedMatches(_missingWordControllers[i].text, ex.missingWords[i])) {
        correct = false;
      }
    }
    _mark(correct);
  }

  Widget _missingWordExercise(Exercise ex) {
    final anyTyped = _missingWordControllers.any(
      (c) => c.text.trim().isNotEmpty,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.tonalIcon(
          onPressed: _answered || (ex.tts ?? '').trim().isEmpty
              ? null
              : () => _speakText(ex.tts!),
          icon: const Icon(Icons.volume_up_outlined),
          label: const Text('Play audio'),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            _missingWordDisplay(ex),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < _missingWordControllers.length; i++) ...[
          TextField(
            controller: _missingWordControllers[i],
            enabled: !_answered,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) {
              if (!_answered &&
                  _missingWordControllers.any(
                    (c) => c.text.trim().isNotEmpty,
                  )) {
                _submitMissingWords(ex);
              }
            },
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              labelText: _missingWordControllers.length == 1
                  ? 'Missing word'
                  : 'Missing word ${i + 1}',
            ),
          ),
          const SizedBox(height: 10),
        ],
        FilledButton(
          onPressed: _answered || !anyTyped
              ? null
              : () => _submitMissingWords(ex),
          child: const Text('Check'),
        ),
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
                      Text(pair.leftLabel, softWrap: true),
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
                        child: Text(pair.leftLabel, softWrap: true),
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
          child: const Text('Check'),
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
    final usage = ex.answers.isNotEmpty ? ex.answers[0] : '';
    final usageTranslation = ex.answers.length > 1 ? ex.answers[1] : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.62),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Text(
                ex.prompt,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              IconButton.filledTonal(
                tooltip: 'Pronounce word or phrase',
                onPressed: ex.tts == null ? null : () => _speakText(ex.tts!),
                icon: const Icon(Icons.volume_up_outlined),
              ),
              const SizedBox(height: 12),
              Text(
                ex.question,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (usage.isNotEmpty) ...[
                const Divider(height: 28),
                Text(
                  'Usage:',
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
                  tooltip: 'Pronounce usage sentence',
                  onPressed: () => _speakText(usage),
                  icon: const Icon(Icons.record_voice_over_outlined),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: _answered
              ? null
              : () => _flashcardResult(reviewAgain: true),
          child: const Text('Review again'),
        ),
        const SizedBox(height: 8),
        FilledButton(
          onPressed: _answered
              ? null
              : () => _flashcardResult(reviewAgain: false),
          child: const Text('Got it'),
        ),
      ],
    );
  }

  Widget _iconChoiceExercise(Exercise ex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ex.question.isNotEmpty) ...[
          Text(ex.question, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 16),
        ],
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(_choiceOptions.length, (i) {
            final originalIndex = ex.answers.indexOf(_choiceOptions[i].text);
            final iconKey =
                originalIndex >= 0 && originalIndex < ex.icons.length
                ? ex.icons[originalIndex]
                : '';
            final isAsset = iconKey.startsWith('assets/');
            return SizedBox(
              width: 112,
              height: 120,
              child: FilledButton.tonal(
                onPressed: _answered ? null : () => _answerChoice(i),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isAsset)
                      Expanded(
                        child: Image.asset(
                          iconKey,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image_outlined, size: 34),
                        ),
                      )
                    else
                      Icon(_iconFor(iconKey), size: 34),
                    if (!isAsset) ...[
                      const SizedBox(height: 5),
                      Text(
                        _choiceOptions[i].text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _audioMatchExercise(Exercise ex) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (ex.question.isNotEmpty) ...[
          Text(ex.question, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
        ],
        ..._matchingLeftPairs.map((pair) {
          final soundId = pair.leftId;
          final sound = pair.leftLabel;
          return Card(
            color: Colors.white.withValues(alpha: 0.55),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  IconButton.filledTonal(
                    tooltip: 'Play sound',
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
              : () {
                  final ok = _matchingLeftPairs.every(
                    (p) => _matchingSelections[p.leftId] == p.rightId,
                  );
                  _mark(ok);
                },
          child: const Text('Check matches'),
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
    if (ex.imageAsset.isEmpty) return const SizedBox.shrink();
    if (!ex.imageAsset.startsWith('assets/') &&
        !File(ex.imageAsset).existsSync()) {
      return _missingImageNotice(ex.imageAsset);
    }
    final image = ex.imageAsset.startsWith('assets/')
        ? Image.asset(
            ex.imageAsset,
            fit: BoxFit.contain,
            semanticLabel: 'Exercise illustration',
            errorBuilder: (_, __, ___) => _missingImageNotice(ex.imageAsset),
          )
        : Image.file(
            File(ex.imageAsset),
            fit: BoxFit.contain,
            semanticLabel: 'Exercise illustration',
            errorBuilder: (_, __, ___) => _missingImageNotice(ex.imageAsset),
          );
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420, maxHeight: 280),
        child: image,
      ),
    );
  }

  Widget _exerciseBody(Exercise ex) {
    switch (ex.type) {
      case 'choice':
      case 'gap_choice':
      case 'listening_choice':
      case 'listening_comprehension':
      case 'reading_comprehension':
      case 'dialogue_response':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (ex.type == 'listening_choice' ||
                ex.type == 'listening_comprehension') ...[
              Center(
                child: IconButton.filledTonal(
                  tooltip: 'Play audio again',
                  iconSize: 34,
                  onPressed: _speak,
                  icon: const Icon(Icons.volume_up_outlined),
                ),
              ),
              const SizedBox(height: 14),
            ],
            if ((ex.type == 'reading_comprehension' ||
                    ex.type == 'dialogue_response') &&
                ex.prompt.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.58),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  ex.prompt,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (ex.question.isNotEmpty) ...[
              Text(
                ex.question,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
            ],
            _choiceExercise(ex),
          ],
        );
      case 'icon_choice':
        return _iconChoiceExercise(ex);
      case 'flashcard':
        return _flashcardExercise(ex);
      case 'fill_blank':
        return _fillBlankExercise(ex);
      case 'word_order':
        return _wordOrderExercise(ex);
      case 'image_word':
        return _imageWordExercise(ex);
      case 'matching':
      case 'word_match':
      case 'super_match':
        return _matchingExercise(ex);
      case 'missing_word':
        return _missingWordExercise(ex);
      case 'listening_spelling':
        return _listeningSpellingExercise(ex);
      case 'audio_match':
        return _audioMatchExercise(ex);
      default:
        return Text('Unsupported exercise type: ${ex.type}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.previewMode && AlphaLifecycleService.isExpired()) {
      return const AlphaExpiredView();
    }
    final background =
        _autumnBackgrounds[widget.roundIndex % _autumnBackgrounds.length];
    final intro = _topicIntro;
    if (intro != null && !_introAcknowledged) {
      return Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          title: Text(
            widget.previewMode
                ? 'PREVIEW · ${widget.round.title}'
                : widget.round.title,
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              Text(
                'Before you start',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  intro.text,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GuidebookScreen(
                      chapter: widget.chapter,
                      topic: widget.topic,
                      chapterNumber: _chapterNumber,
                    ),
                  ),
                ),
                icon: const Icon(Icons.menu_book_outlined),
                label: const Text('Open Guidebook'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => setState(() => _introAcknowledged = true),
                child: const Text('Continue to Round'),
              ),
            ],
          ),
        ),
      );
    }
    if (!_ready) {
      return Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          title: Text(
            widget.previewMode
                ? 'PREVIEW · ${widget.round.title}'
                : widget.round.title,
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_queue.isEmpty) {
      return Scaffold(
        backgroundColor: background,
        appBar: AppBar(
          backgroundColor: background,
          title: Text(
            widget.previewMode
                ? 'PREVIEW · ${widget.round.title}'
                : widget.round.title,
          ),
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                _initializationFailed
                    ? 'This round could not be opened safely.'
                    : (_ttsWasSkipped
                          ? 'All exercises in this round use TTS and are currently skipped.'
                          : 'This round has no usable exercises.'),
              ),
              const SizedBox(height: 8),
              Text(
                _initializationFailed
                    ? 'QuisquisLingo kept the app running and wrote the error to the crash log.'
                    : (_ttsWasSkipped
                          ? 'Disable “Skip all TTS exercises” in Settings to play this round.'
                          : 'Open Course Editor > Run course audit to see the problems that need to be corrected.'),
              ),
            ],
          ),
        ),
      );
    }
    final ex = _exercise;
    final totalShown = _queue.length;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _reviewPhase
                  ? '${widget.round.title} · Review'
                  : widget.round.title,
            ),
            Text(
              '${widget.course.targetLanguage} · Chapter ${widget.course.chapters.indexWhere((c) => c.id == widget.chapter.id) + 1} · ${widget.topic.title}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
        actions: [
          if (ex.tts != null &&
              ex.tts!.isNotEmpty &&
              ex.type != 'listening_choice' &&
              ex.type != 'listening_comprehension')
            IconButton(
              tooltip: 'Play audio',
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
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            if (_reviewPhase)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Reviewing exercises you missed',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            Text(
              ExerciseCopyService.typeLabel(widget.course, ex.type),
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: .7,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ExerciseCopyService.instructionForExercise(widget.course, ex),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            if (ex.type != 'reading_comprehension' &&
                ex.type != 'flashcard' &&
                ex.type != 'missing_word' &&
                ex.type != 'image_word' &&
                ex.prompt.isNotEmpty &&
                !ExerciseCopyService.isLegacyInstruction(ex.prompt)) ...[
              const SizedBox(height: 12),
              Text(
                ExerciseCopyService.displayPrompt(widget.course, ex.prompt),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
            const SizedBox(height: 20),
            // Keep the whole exercise screen scrollable. On short desktop
            // windows or larger system text sizes this prevents a RenderFlex
            // overflow at the bottom while preserving normal phone behavior.
            if (ex.imageAsset.isNotEmpty) ...[
              _exerciseImage(ex),
              const SizedBox(height: 14),
            ] else
              ...[],
            _exerciseBody(ex),
            if (_answered) ...[
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _feedback,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (!_lastAnswerCorrect && ex.type != 'flashcard') ...[
                      const SizedBox(height: 5),
                      Text('Correct answer: ${_correctAnswerText(ex)}'),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _next,
                child: Text(
                  !_reviewPhase &&
                          _position + 1 == _queue.length &&
                          _wrongFirstPass.isNotEmpty
                      ? 'Review mistakes'
                      : (_position + 1 == _queue.length
                            ? 'Finish round'
                            : 'Next'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
