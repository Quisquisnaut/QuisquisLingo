import 'dart:math';
import 'package:flutter/material.dart';
import '../services/course_language_resolver.dart';
import '../services/beta_lifecycle_service.dart';
import '../widgets/beta_expired_view.dart';
import '../models/course_models.dart';
import '../models/exercise_features.dart';
import '../services/duel_eligibility_service.dart';
import '../services/progress_service.dart';
import '../services/report_service.dart';
import '../services/tts_cache_service.dart';
import '../services/sound_effect_service.dart';
import '../services/course_service.dart';
import '../services/settings_service.dart';
import '../services/recorded_audio_service.dart';
import '../services/audio_exercise_availability_service.dart';
import '../services/translation_choice_service.dart';
import '../widgets/course_media_image.dart';
import '../widgets/exercise_prompt_panels.dart';
import '../widgets/portable_exercise_image.dart';

class DuelScreen extends StatefulWidget {
  final Course course;
  final Lesson lesson;
  final String ttsLanguage;
  final bool viewOnlyMode;
  final SettingsService? settingsService;

  const DuelScreen({
    super.key,
    required this.course,
    required this.lesson,
    required this.ttsLanguage,
    this.viewOnlyMode = false,
    this.settingsService,
  });

  @override
  State<DuelScreen> createState() => _DuelScreenState();
}

class _DuelItem {
  final Lesson lesson;
  final LearningRound round;
  final Exercise exercise;
  const _DuelItem({
    required this.lesson,
    required this.round,
    required this.exercise,
  });
}

class _DuelChoice {
  final String text;
  final bool correct;
  final ExerciseItem item;
  const _DuelChoice(this.text, this.correct, this.item);
}

class _DuelScreenState extends State<DuelScreen> {
  final _progress = ProgressService();
  final _reports = ReportService();
  final _tts = TtsCacheService();
  final _sounds = SoundEffectService();
  late final SettingsService _settings;
  final _recordedAudio = RecordedAudioService();
  final _eligibility = const DuelEligibilityService();
  late final AudioExerciseAvailabilityService _audioAvailability;
  bool _optionalAudioEnabled = false;
  final _random = Random();
  late ExerciseFeatures _features;
  int _index = 0;
  List<_DuelItem> _items = const [];
  bool _ready = false;
  bool _initializationFailed = false;
  int _lives = 4;
  int? _selected;
  bool _answerCorrect = false;
  List<_DuelChoice> _choices = [];
  bool _finishing = false;

  static const _backgrounds = <Color>[
    Color(0xFFE7E1CF),
    Color(0xFFE9D9CE),
    Color(0xFFDDE5D5),
    Color(0xFFE9DFC7),
  ];

  /// The bright autumn backgrounds only suit the light theme. In dark mode the
  /// background is taken from the theme surface (as in Round), so the theme's
  /// light text and icons stay readable.
  Color _duelBackground(Color lightBackground) {
    final theme = Theme.of(context);
    if (theme.brightness == Brightness.light) return lightBackground;
    return Color.alphaBlend(
      lightBackground.withValues(alpha: 0.08),
      theme.colorScheme.surface,
    );
  }

  /// The Select panels' surface, as on the Round screen.
  Color get _panelColor {
    final scheme = Theme.of(context).colorScheme;
    return Theme.of(context).brightness == Brightness.dark
        ? scheme.surfaceContainerHigh
        : scheme.surfaceContainerLowest;
  }

  Color get _feedbackPanelColor {
    final theme = Theme.of(context);
    return theme.brightness == Brightness.dark
        ? theme.colorScheme.surfaceContainerHigh
        : Colors.white.withValues(alpha: 0.62);
  }

  bool get _isFinalLesson =>
      widget.course.lessons.isNotEmpty &&
      widget.course.lessons.last.lessonId == widget.lesson.lessonId;

  String get _duelTitle =>
      _isFinalLesson ? 'Final Duel' : widget.lesson.duel.title;
  String get _screenTitle =>
      widget.viewOnlyMode ? 'VIEW ONLY · $_duelTitle' : _duelTitle;

  @override
  void initState() {
    super.initState();
    _settings = widget.settingsService ?? SettingsService();
    _audioAvailability = AudioExerciseAvailabilityService(
      recordedAudio: _recordedAudio,
    );
    _initializeDuel();
  }

  Future<void> _initializeDuel() async {
    try {
      final audioExercisesEnabled = await _settings.areAudioExercisesEnabled();
      final ttsEnabled =
          audioExercisesEnabled && await _settings.isTtsEnabled();
      final eligibility = await _eligibility.evaluateEffective(
        widget.course,
        widget.lesson,
        audioExercisesEnabled: audioExercisesEnabled,
        ttsEnabled: ttsEnabled,
        audioAvailability: _audioAvailability,
      );
      final candidates = eligibility.candidates
          .map(
            (candidate) => _DuelItem(
              lesson: widget.lesson,
              round: candidate.round,
              exercise: candidate.exercise,
            ),
          )
          .toList();
      _shuffleDifferentItems(candidates);
      if (!mounted) return;
      setState(() {
        _items = candidates
            .take(DuelEligibilityService.requiredQuestionCount)
            .toList();
        _optionalAudioEnabled =
            audioExercisesEnabled &&
            (ttsEnabled || widget.course.audioMode != 'tts');
        _ready = true;
      });
      _prepareCurrent();
      try {
        await _sounds.playDuelSuspense();
      } catch (_) {
        // Intro music is optional and cannot make a prepared Duel unavailable.
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = const [];
        _initializationFailed = true;
        _ready = true;
      });
    }
  }

  @override
  void dispose() {
    _sounds.dispose();
    super.dispose();
  }

  void _prepareCurrent() {
    final items = _items;
    if (items.isEmpty || _index >= items.length) return;
    final ex = items[_index].exercise;
    final f = _features = ExerciseFeatures(ex);
    _selected = null;
    _answerCorrect = false;
    final correct = ex.canonicalEvaluation.correctItemIds.toSet();
    _choices = [
      for (final item in ex.items)
        _DuelChoice(item.value, correct.contains(item.id), item),
    ];
    _shuffleDifferentChoices(_choices);
    final automatic = f.automaticAudio;
    if (automatic != null && automatic.text.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _speak(ex));
    }
  }

  void _shuffleDifferentChoices(List<_DuelChoice> values) {
    if (values.length < 2) return;
    // A valid random shuffle may legitimately reproduce the source order.
    values.shuffle(_random);
  }

  void _shuffleDifferentItems(List<_DuelItem> values) {
    if (values.length < 2) return;
    // A valid random shuffle may legitimately reproduce the source order.
    values.shuffle(_random);
  }

  Future<void> _speak(Exercise ex) {
    final f = ExerciseFeatures(ex);
    return _speakText(
      f.primaryAudioText ?? '',
      language: f.primaryAudioLanguage,
    );
  }

  /// The speech language for text in [language]: the Course's source
  /// language for source-language audio, else the learning language.
  String _voiceFor(TextLanguage? language) {
    if (language != TextLanguage.source) return widget.ttsLanguage;
    final code = CourseLanguageResolver.base(widget.course).code ?? '';
    return code.isEmpty ? widget.ttsLanguage : code;
  }

  Widget _translationAudioButton(String text) => IconButton.filledTonal(
    key: const Key('translation-choice-audio'),
    tooltip: _optionalAudioEnabled ? 'Play audio' : 'Audio unavailable',
    onPressed: _optionalAudioEnabled ? () => _speakText(text) : null,
    icon: const Icon(Icons.volume_up_outlined),
  );

  Widget _translationAudioUnavailableNote() => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(
      'Audio is turned off or unavailable. The exercise still works.',
      key: const Key('translation-choice-audio-note'),
      style: Theme.of(context).textTheme.bodySmall,
    ),
  );

  Future<void> _speakText(String text, {TextLanguage? language}) async {
    if (text.isEmpty) return;
    var ok = false;
    if (widget.course.audioMode != 'tts') {
      ok = await _recordedAudio.playConcatenated(
        text,
        widget.course.audioLibrary,
        courseId: widget.course.courseId,
      );
    }
    if (!ok && widget.course.audioMode != 'recorded') {
      ok = await _tts.speak(
        text: text,
        language: _voiceFor(language ?? _features.audioLanguageOf(text)),
        learningLanguage: widget.course.learningLanguage,
        targetLanguage: widget.course.targetLanguage,
      );
    }
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 8),
          content: Text(
            _tts.lastFailureDescription ??
                'Audio unavailable. Enable Text-to-speech in Settings and make sure a system voice is installed. On Linux, install eSpeak NG or eSpeak.',
          ),
        ),
      );
    }
  }

  ExerciseItem? _correctItem(Exercise ex) {
    final id = ex.canonicalEvaluation.correctItemIds.firstOrNull;
    return ex.items.where((item) => item.id == id).firstOrNull;
  }

  String _correctAnswer(Exercise ex) {
    final value = _correctItem(ex)?.value ?? '';
    return value.isEmpty ? 'See the course answer.' : value;
  }

  /// The text shown above the question: the primary or clue text. Passages,
  /// situations and context have their own panels.
  String get _displayedPrompt => _features.primaryText.isNotEmpty
      ? _features.primaryText
      : _features.clueText;

  String _answerState(Exercise ex) {
    if (_selected == null) return 'Not answered yet';
    if (_selected! >= 0 && _selected! < _choices.length) {
      return 'Selected choice ${_selected! + 1}: ${_choices[_selected!].text}';
    }
    return 'Choice selected';
  }

  Future<void> _copyReport(ReportKind kind, _DuelItem item) async {
    final roundIndex = item.round.exercises.indexWhere(
      (exercise) => exercise.id == item.exercise.id,
    );
    await _reports.copyExerciseReport(
      kind: kind,
      course: widget.course,
      lesson: item.lesson,
      round: item.round,
      exercise: item.exercise,
      exerciseIndex: roundIndex < 0 ? 0 : roundIndex,
      screen: 'Language Duel (${_index + 1}/${_items.length})',
      answerState: _answerState(item.exercise),
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

  void _showReportSheet(_DuelItem item) {
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
                'Choose the problem type. QuisquisLingo will copy the exact duel exercise and its course location to the clipboard. Add your description and paste it into your report.',
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: const Text('Course error'),
                subtitle: const Text(
                  'Wrong answer, typo, translation, audio, instruction or other course content.',
                ),
                onTap: () => _copyReport(ReportKind.courseError, item),
              ),
              ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: const Text('App bug'),
                subtitle: const Text(
                  'Something does not work, display or respond as expected.',
                ),
                onTap: () => _copyReport(ReportKind.bug, item),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _finishDuel() async {
    final won = _lives > 0 && _index + 1 >= _items.length;
    final isFinalLesson = _isFinalLesson;
    int? awardedXp;
    if (won && !widget.viewOnlyMode) {
      awardedXp = await _progress.winDuel(
        widget.lesson.duel.id,
        courseId: widget.course.courseId,
        courseCode: CourseService.codeForCourse(widget.course),
      );
    }
    try {
      if (won) {
        await _sounds.playDuelWin();
      } else {
        await _sounds.playDuelLost();
      }
    } catch (_) {
      // Completion feedback is optional and must not hide a persisted result.
    }
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(
          widget.viewOnlyMode
              ? 'View Only duel result'
              : won && isFinalLesson
              ? 'Final Duel completed!'
              : won
              ? 'Duel won'
              : 'Duel lost',
        ),
        content: Text(
          widget.viewOnlyMode
              ? 'Preview result: ${won ? 'Duel won' : 'Duel lost'}. No learning progress or rewards were recorded.'
              : won
              ? isFinalLesson
                    ? '+$awardedXp XP'
                    : 'Duel won: +$awardedXp XP\n\nYou proved your knowledge. The next Lesson can now unlock.'
              : (_lives <= 0
                    ? 'Duel lost. You have lost all four lives.'
                    : 'The duel ended before all 25 questions were completed.'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Back to course'),
          ),
        ],
      ),
    );
  }

  Future<void> _next() async {
    if (_finishing) return;
    final items = _items;
    if (_lives > 0 && _index + 1 < items.length) {
      setState(() => _index++);
      _prepareCurrent();
      return;
    }
    if (!mounted) return;
    setState(() => _finishing = true);
    final persistenceStarted =
        _lives > 0 && _index + 1 >= items.length && !widget.viewOnlyMode;
    try {
      await _finishDuel();
    } catch (_) {
      if (!mounted) return;
      if (!persistenceStarted) setState(() => _finishing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Duration(seconds: 8),
          content: Text(
            persistenceStarted
                ? 'Duel completion did not finish safely. Return to the course before trying again.'
                : 'Duel completion could not be shown. Please try again.',
          ),
        ),
      );
    }
  }

  void _selectChoice(int i) {
    if (_selected != null) return;
    setState(() {
      _selected = i;
      _answerCorrect = _choices[i].correct;
      if (!_answerCorrect) {
        _lives = max(0, _lives - 1);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (BetaLifecycleService.isExpired()) return const BetaExpiredView();
    if (!_ready) {
      return Scaffold(
        appBar: AppBar(title: Text(_screenTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final items = _items;
    if (items.length < DuelEligibilityService.requiredQuestionCount) {
      return Scaffold(
        appBar: AppBar(title: Text(_screenTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              _initializationFailed
                  ? 'This Duel could not be opened safely. Return to the course and try again.'
                  : 'Duel unavailable for this Lesson because there are not enough suitable exercises.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final item = items[_index];
    final ex = item.exercise;
    final background = _duelBackground(
      _backgrounds[_index % _backgrounds.length],
    );

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: Text(_screenTitle),
        actions: [
          IconButton(
            tooltip: 'Report a problem',
            icon: const Icon(Icons.flag_outlined),
            onPressed: () => _showReportSheet(item),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const IgnorePointer(
            child: CustomPaint(painter: _DuelBackdropPainter()),
          ),
          SafeArea(
            top: false,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  _isFinalLesson ? 'Final Duel' : 'Language Duel',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Question ${_index + 1}/${items.length} · 4 lives'),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        4,
                        (i) => Padding(
                          padding: const EdgeInsets.only(left: 2),
                          child: Icon(
                            i < _lives ? Icons.person : Icons.person_outline,
                            size: 25,
                            color: i < _lives
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_features.automaticAudio != null &&
                    _features.automaticAudio!.role != 'context') ...[
                  Center(
                    child: IconButton.filledTonal(
                      tooltip: 'Play audio again',
                      iconSize: 34,
                      onPressed: () => _speak(ex),
                      icon: const Icon(Icons.volume_up_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                if (_features.isTranslationChoice) ...[
                  // Single learner-facing instruction: no prompt, no
                  // fallback text and no editor-only type name.
                  Text(
                    TranslationChoice.instructionFor(
                      widget.course,
                      _features.itemLanguage!,
                    ),
                    key: const Key('translation-choice-instruction'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _features.questionText,
                          key: const Key('translation-choice-text'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      if (_features.questionLanguage == TextLanguage.target &&
                          _features.questionText.trim().isNotEmpty)
                        _translationAudioButton(_features.questionText.trim()),
                    ],
                  ),
                  if (_features.questionLanguage == TextLanguage.target &&
                      !_optionalAudioEnabled)
                    _translationAudioUnavailableNote(),
                  if (_features.illustrationAsset.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Center(
                      child: CourseMediaImage(
                        courseId: widget.course.courseId,
                        asset: _features.illustrationAsset,
                        height: 200,
                      ),
                    ),
                  ],
                ] else ...[
                  ExercisePromptPanels(
                    features: _features,
                    panelColor: _panelColor,
                    onPlayContextAudio:
                        _selected != null ||
                            _features.contextAudio.trim().isEmpty
                        ? null
                        : () => _speakText(_features.contextAudio.trim()),
                  ),
                  if (_displayedPrompt.isNotEmpty) ...[
                    Text(
                      _displayedPrompt,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    _features.questionText.isEmpty
                        ? 'Listen and choose the meaning.'
                        : _features.questionText,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
                const SizedBox(height: 18),
                ...List.generate(
                  _choices.length,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FilledButton.tonal(
                      onPressed: _selected == null
                          ? () => _selectChoice(i)
                          : null,
                      child: _choices[i].item.image.isNotEmpty
                          ? _choices[i].item.image.startsWith('media:')
                                ? CourseMediaImage(
                                    courseId: widget.course.courseId,
                                    asset: _choices[i].item.image,
                                    width: 128,
                                    height: 128,
                                    cacheWidth: 256,
                                    cacheHeight: 256,
                                  )
                                : PortableExerciseImage(
                                    asset: _choices[i].item.image,
                                    width: 128,
                                    height: 128,
                                  )
                          : Text(_choices[i].text),
                    ),
                  ),
                ),
                if (_selected != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _feedbackPanelColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _answerCorrect ? 'Correct' : 'Incorrect',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (!_answerCorrect) ...[
                          const SizedBox(height: 5),
                          if (_correctItem(ex)?.image.isNotEmpty == true) ...[
                            const Text('Correct answer:'),
                            PortableExerciseImage(
                              asset: _correctItem(ex)!.image,
                              width: 128,
                              height: 128,
                            ),
                          ] else
                            Text('Correct answer: ${_correctAnswer(ex)}'),
                        ],
                        if (_features.isTranslationChoice &&
                            _features.itemLanguage == TextLanguage.target) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Expanded(
                                child: Text('Listen to the answer'),
                              ),
                              _translationAudioButton(_correctAnswer(ex)),
                            ],
                          ),
                          if (!_optionalAudioEnabled)
                            _translationAudioUnavailableNote(),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _selected == null || _finishing ? null : _next,
                  child: Text(
                    _finishing
                        ? 'Finishing duel…'
                        : _lives <= 0 || _index + 1 == items.length
                        ? 'Finish duel'
                        : 'Continue',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DuelBackdropPainter extends CustomPainter {
  const _DuelBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final ground = Paint()..color = const Color(0x1F8B6F47);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height * .83),
        width: size.width * .92,
        height: 62,
      ),
      ground,
    );

    void fighterPlant(double x, bool facesRight) {
      final stem = Paint()
        ..color = const Color(0x38546934)
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round;
      final leaf = Paint()..color = const Color(0x335F7A43);
      final pot = Paint()..color = const Color(0x35B86F4B);
      final baseY = size.height * .79;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(x, baseY + 28), width: 54, height: 42),
          const Radius.circular(8),
        ),
        pot,
      );
      final dir = facesRight ? 1.0 : -1.0;
      canvas.drawLine(
        Offset(x, baseY + 8),
        Offset(x + 10 * dir, baseY - 90),
        stem,
      );
      for (var i = 0; i < 6; i++) {
        final yy = baseY - 22 - i * 14.0;
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(x + (i.isEven ? 18 : -10) * dir, yy),
            width: 34,
            height: 15,
          ),
          leaf,
        );
      }
      final glove = Paint()..color = const Color(0x33A25C43);
      canvas.drawCircle(Offset(x + 42 * dir, baseY - 55), 13, glove);
      canvas.drawLine(
        Offset(x + 8 * dir, baseY - 55),
        Offset(x + 30 * dir, baseY - 55),
        stem..strokeWidth = 4,
      );
    }

    fighterPlant(size.width * .18, true);
    fighterPlant(size.width * .82, false);

    final vs = TextPainter(
      text: const TextSpan(
        text: 'VS',
        style: TextStyle(
          color: Color(0x334F622D),
          fontSize: 42,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    vs.paint(canvas, Offset((size.width - vs.width) / 2, size.height * .70));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
