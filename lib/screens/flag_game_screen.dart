import 'dart:async';

import 'package:flutter/material.dart';

import '../models/world_flag_entity.dart';
import '../services/flag_game_engine.dart';
import '../services/flag_game_score_service.dart';
import '../services/profile_service.dart';
import '../services/sound_effect_service.dart';
import '../services/world_flag_repository.dart';
import '../widgets/world_flag_art.dart';
import '../widgets/learner_avatar.dart';
import 'world_flag_reference_screen.dart';

class FlagGameScreen extends StatefulWidget {
  final WorldFlagRepository? repository;
  final FlagGameEngine? engine;
  final SoundEffectService? soundEffectService;
  final FlagGameScoreService? scoreService;
  final DateTime Function()? now;
  final Duration correctAnswerFeedbackDuration;
  final Duration wrongAnswerFeedbackDuration;

  const FlagGameScreen({
    super.key,
    this.repository,
    this.engine,
    this.soundEffectService,
    this.scoreService,
    this.now,
    this.correctAnswerFeedbackDuration = const Duration(milliseconds: 800),
    this.wrongAnswerFeedbackDuration = const Duration(milliseconds: 700),
  });

  @override
  State<FlagGameScreen> createState() => _FlagGameScreenState();
}

enum _FlagGameStage { setup, playing, results }

class _FlagGameScreenState extends State<FlagGameScreen> {
  late final WorldFlagRepository _repository;
  late final FlagGameEngine _engine;
  late final SoundEffectService _sounds;
  late final FlagGameScoreService _scores;
  late final bool _ownsSounds;
  late final DateTime Function() _now;
  List<WorldFlagEntity> _entities = const [];
  List<FlagGameQuestion> _questions = const [];
  List<String> _previousTargetOrder = const [];
  FlagGameMode _mode = FlagGameMode.unMembers;
  _FlagGameStage _stage = _FlagGameStage.setup;
  int _questionIndex = 0;
  int _score = 0;
  String? _selectedId;
  bool _answerLocked = false;
  DateTime? _startedAt;
  Duration _elapsed = Duration.zero;
  Timer? _advanceTimer;
  Object? _loadError;
  Map<FlagGameMode, List<FlagGameScoreEntry>> _scorecard = const {};
  bool _scorecardLoading = false;
  String? _activeProfileId;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? WorldFlagRepository();
    _engine = widget.engine ?? FlagGameEngine();
    _ownsSounds = widget.soundEffectService == null;
    _sounds = widget.soundEffectService ?? SoundEffectService();
    _scores = widget.scoreService ?? FlagGameScoreService();
    _now = widget.now ?? DateTime.now;
    _load();
  }

  Future<void> _load() async {
    try {
      final entities = await _repository.load();
      if (mounted) setState(() => _entities = entities);
      await _loadScorecard();
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    }
  }

  Future<void> _loadScorecard() async {
    final scorecard = await _scores.getScorecard();
    final activeProfileId = await ProfileService().getActiveProfileId();
    if (!mounted) return;
    setState(() {
      _scorecard = scorecard;
      _activeProfileId = activeProfileId;
    });
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    if (_ownsSounds) unawaited(_sounds.dispose());
    super.dispose();
  }

  void _startGame() {
    final questions = _engine.createGame(
      entities: _entities,
      mode: _mode,
      previousTargetOrder: _previousTargetOrder,
    );
    setState(() {
      _questions = questions;
      _previousTargetOrder = questions
          .map((question) => question.target.id)
          .toList();
      _stage = _FlagGameStage.playing;
      _questionIndex = 0;
      _score = 0;
      _selectedId = null;
      _answerLocked = false;
      _startedAt = null;
      _elapsed = Duration.zero;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _stage == _FlagGameStage.playing && _startedAt == null) {
        setState(() => _startedAt = _now());
      }
    });
  }

  Future<void> _selectAnswer(WorldFlagEntity option) async {
    if (_answerLocked) return;
    final question = _questions[_questionIndex];
    final correct = option.id == question.target.id;
    setState(() {
      _answerLocked = true;
      _selectedId = option.id;
      if (correct) _score++;
    });
    if (correct) {
      await _sounds.playVictory();
    } else {
      await _sounds.playDefeat();
    }
    if (!mounted) return;
    _advanceTimer = Timer(
      correct
          ? widget.correctAnswerFeedbackDuration
          : widget.wrongAnswerFeedbackDuration,
      _advance,
    );
  }

  void _advance() {
    if (!mounted || _stage != _FlagGameStage.playing) return;
    if (_questionIndex + 1 >= _questions.length) {
      setState(() {
        _elapsed = _now().difference(_startedAt ?? _now());
        _stage = _FlagGameStage.results;
        _scorecardLoading = true;
      });
      unawaited(_saveResultAndLoadScorecard());
      return;
    }
    setState(() {
      _questionIndex++;
      _selectedId = null;
      _answerLocked = false;
    });
  }

  Future<void> _saveResultAndLoadScorecard() async {
    try {
      await _scores.recordResult(
        mode: _mode,
        score: _score,
        elapsedTime: _elapsed,
        achievedAt: _now(),
      );
    } on StateError {
      // The game can still complete if a test or exceptional app state has no
      // active learner. No synthetic learner namespace is created.
    }
    final scorecard = await _scores.getScorecard();
    final activeProfileId = await ProfileService().getActiveProfileId();
    if (!mounted) return;
    setState(() {
      _scorecard = scorecard;
      _activeProfileId = activeProfileId;
      _scorecardLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Flag Game'),
      leading: IconButton(
        tooltip: 'Close Flag Game',
        onPressed: () => Navigator.maybePop(context),
        icon: const Icon(Icons.close),
      ),
    ),
    body: SafeArea(
      child: switch ((_loadError, _entities.isEmpty, _stage)) {
        (final Object error, _, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Flag Game could not load: $error'),
          ),
        ),
        (null, true, _) => const Center(child: CircularProgressIndicator()),
        (null, false, _FlagGameStage.setup) => _buildSetup(context),
        (null, false, _FlagGameStage.playing) => _buildQuestion(context),
        (null, false, _FlagGameStage.results) => _buildResults(context),
      },
    ),
  );

  Widget _buildSetup(BuildContext context) => ListView(
    key: const Key('flag-game-setup'),
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
    children: [
      Icon(
        Icons.flag_outlined,
        size: 64,
        color: Theme.of(context).colorScheme.primary,
      ),
      const SizedBox(height: 12),
      Text(
        'Choose a flag pool',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 6),
      const Text(
        'Each game has 12 flags, with 5 answer choices per question. Select the flag pool for your game.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 18),
      _modeSelector(),
      const SizedBox(height: 18),
      Center(
        child: FilledButton.icon(
          key: const Key('flag-game-start'),
          onPressed: _startGame,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start new game'),
        ),
      ),
      const SizedBox(height: 24),
      _referenceArea(context),
      const SizedBox(height: 24),
      _buildScorecard(context),
    ],
  );

  Widget _modeSelector() => Semantics(
    label: 'Flag Game pool selector',
    child: Wrap(
      key: const Key('flag-game-mode-selector'),
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final mode in FlagGameMode.values)
          ChoiceChip(
            key: ValueKey('flag-game-mode-${mode.name}'),
            label: Text(mode.label),
            selected: _mode == mode,
            onSelected: (_) => setState(() => _mode = mode),
          ),
      ],
    ),
  );

  Widget _buildQuestion(BuildContext context) {
    final question = _questions[_questionIndex];
    final selectedCorrect = _selectedId == question.target.id;
    return ListView(
      key: ValueKey('flag-game-question-$_questionIndex'),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 18),
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          runSpacing: 4,
          children: [
            Text(
              'Question ${_questionIndex + 1} / ${FlagGameEngine.questionCount}',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            Text('Score $_score / ${FlagGameEngine.questionCount}'),
          ],
        ),
        const SizedBox(height: 10),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 290, maxHeight: 180),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: WorldFlagArt(entity: question.target),
            ),
          ),
        ),
        SizedBox(
          height: 40,
          child: Center(
            child: _answerLocked
                ? Semantics(
                    liveRegion: true,
                    child: Text(
                      selectedCorrect
                          ? 'Correct'
                          : 'Correct answer: ${question.target.displayNameEn}',
                      key: const Key('flag-game-feedback'),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selectedCorrect
                            ? Colors.green.shade700
                            : Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 4),
        for (final option in question.options) ...[
          _answerButton(context, option, question),
          const SizedBox(height: 7),
        ],
      ],
    );
  }

  Widget _answerButton(
    BuildContext context,
    WorldFlagEntity option,
    FlagGameQuestion question,
  ) {
    final selected = option.id == _selectedId;
    final correct = option.id == question.target.id;
    Color? background;
    Color? foreground;
    if (_answerLocked && correct) {
      background = Colors.green.shade700;
      foreground = Colors.white;
    } else if (_answerLocked && selected) {
      background = Theme.of(context).colorScheme.error;
      foreground = Theme.of(context).colorScheme.onError;
    }
    return FilledButton(
      key: ValueKey('flag-game-answer-${option.id}'),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        backgroundColor: background,
        foregroundColor: foreground,
      ),
      onPressed: _answerLocked ? null : () => _selectAnswer(option),
      child: Text(option.displayNameEn, textAlign: TextAlign.center),
    );
  }

  Widget _buildResults(BuildContext context) => ListView(
    key: const Key('flag-game-results'),
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
    children: [
      Icon(
        _score == FlagGameEngine.questionCount
            ? Icons.emoji_events
            : Icons.flag_circle,
        size: 78,
        color: _score == FlagGameEngine.questionCount
            ? Colors.amber.shade700
            : Theme.of(context).colorScheme.primary,
      ),
      const SizedBox(height: 12),
      Text(
        _score == FlagGameEngine.questionCount
            ? 'Perfect flags! Brilliant work!'
            : 'Flag Game complete',
        key: const Key('flag-game-result-title'),
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 8),
      Text(
        '$_score / ${FlagGameEngine.questionCount}',
        key: const Key('flag-game-final-score'),
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w900),
      ),
      Text(
        '${_elapsed.inMilliseconds / 1000.0}s',
        key: const Key('flag-game-elapsed'),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 18),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            key: const Key('flag-game-play-again'),
            onPressed: () => setState(() => _stage = _FlagGameStage.setup),
            icon: const Icon(Icons.replay),
            label: const Text('Play again'),
          ),
          OutlinedButton.icon(
            key: const Key('flag-game-close'),
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.close),
            label: const Text('Close'),
          ),
        ],
      ),
      const SizedBox(height: 24),
      _buildScorecard(context),
      const SizedBox(height: 24),
      _referenceArea(context),
    ],
  );

  Widget _referenceArea(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Browse flags',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 8),
      Wrap(
        key: const Key('flag-game-reference-buttons'),
        alignment: WrapAlignment.center,
        spacing: 7,
        runSpacing: 7,
        children: [
          for (final category in WorldFlagReferenceCategory.values)
            OutlinedButton(
              key: ValueKey('flag-reference-${category.name}'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WorldFlagReferenceScreen(
                    category: category,
                    entities: WorldFlagRepository.referenceFor(
                      _entities,
                      category,
                    ),
                  ),
                ),
              ),
              child: Text(category.label),
            ),
        ],
      ),
    ],
  );

  Widget _buildScorecard(BuildContext context) => Column(
    key: const Key('flag-game-scorecard'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'Top 5 Players · This device',
        textAlign: TextAlign.center,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 8),
      if (_scorecardLoading) const LinearProgressIndicator(),
      for (final mode in FlagGameMode.values)
        Card(
          key: ValueKey('flag-game-scorecard-${mode.name}'),
          color: mode == _mode
              ? Theme.of(context).colorScheme.primaryContainer
              : null,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  mode.label,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 5),
                if ((_scorecard[mode] ?? const []).isEmpty)
                  const Text('No local scores yet.')
                else
                  for (final indexed in (_scorecard[mode] ?? const []).indexed)
                    _scoreEntry(context, indexed.$1, indexed.$2),
              ],
            ),
          ),
        ),
    ],
  );

  Widget _scoreEntry(
    BuildContext context,
    int index,
    FlagGameScoreEntry entry,
  ) {
    final mine = entry.learnerProfileId == _activeProfileId;
    return FutureBuilder<ProfileAvatarAppearance?>(
      future: ProfileService().getAvatarAppearanceForProfile(
        entry.learnerProfileId,
      ),
      builder: (context, snapshot) {
        final appearance = snapshot.data;
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: SizedBox(
            width: 38,
            height: 44,
            child: appearance == null
                ? CircleAvatar(child: Text('${index + 1}'))
                : LearnerAvatar(
                    skinTone: appearance.skinTone,
                    hairTone: appearance.hairTone,
                  ),
          ),
          title: Text(
            entry.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: mine ? FontWeight.w900 : FontWeight.w600,
            ),
          ),
          subtitle: Text(
            '${entry.score}/${FlagGameEngine.questionCount} · '
            '${(entry.elapsedTime.inMilliseconds / 1000).toStringAsFixed(1)} s · '
            '${_formatCompactDate(entry.achievedAt)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: mine ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
        );
      },
    );
  }

  String _formatCompactDate(DateTime value) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final day = value.day.toString().padLeft(2, '0');
    return '$day ${months[value.month - 1]} ${value.year}';
  }
}
