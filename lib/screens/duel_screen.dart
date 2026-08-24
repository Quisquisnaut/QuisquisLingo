import 'dart:math';
import 'package:flutter/material.dart';
import '../services/alpha_lifecycle_service.dart';
import '../widgets/alpha_expired_view.dart';
import '../models/course_models.dart';
import '../services/progress_service.dart';
import '../services/app_errors.dart';
import '../services/diagnostic_log_service.dart';
import '../services/report_service.dart';
import '../services/tts_cache_service.dart';
import '../services/sound_effect_service.dart';
import '../services/course_service.dart';

class DuelScreen extends StatefulWidget {
  final Course course;
  final Chapter chapter;
  final String ttsLanguage;

  const DuelScreen({
    super.key,
    required this.course,
    required this.chapter,
    required this.ttsLanguage,
  });

  @override
  State<DuelScreen> createState() => _DuelScreenState();
}

class _DuelItem {
  final Topic topic;
  final LearningRound round;
  final Exercise exercise;
  const _DuelItem({
    required this.topic,
    required this.round,
    required this.exercise,
  });
}

class _DuelChoice {
  final String text;
  final bool correct;
  const _DuelChoice(this.text, this.correct);
}

class _DuelScreenState extends State<DuelScreen> {
  final _progress = ProgressService();
  final _reports = ReportService();
  final _tts = TtsCacheService();
  final _sounds = SoundEffectService();
  final _random = Random();
  int _index = 0;
  late List<_DuelItem> _items;
  int _lives = 4;
  int? _selected;
  bool _answerCorrect = false;
  List<_DuelChoice> _choices = [];

  static const _backgrounds = <Color>[
    Color(0xFFE7E1CF),
    Color(0xFFE9D9CE),
    Color(0xFFDDE5D5),
    Color(0xFFE9DFC7),
  ];

  List<_DuelItem> get _duelItems {
    // Duels are built from the active chapter itself, so switching course
    // automatically switches language, content and TTS. No Italian fallback.
    final candidates = <_DuelItem>[];
    const supportedTypes = {
      'choice',
      'gap_choice',
      'dialogue_response',
      'icon_choice',
      'listening_choice',
      'listening_comprehension',
      'reading_comprehension',
    };
    final seen = <String>{};
    for (final topic in widget.chapter.learningTopics) {
      for (final round in topic.rounds) {
        for (final exercise in round.exercises) {
          final validCorrect =
              exercise.correct != null &&
              exercise.correct! >= 0 &&
              exercise.correct! < exercise.answers.length;
          if (supportedTypes.contains(exercise.type) &&
              exercise.answers.length >= 2 &&
              validCorrect) {
            final correctText = exercise.answers[exercise.correct!];
            final key = [
              exercise.id,
              exercise.type,
              exercise.prompt.trim().toLowerCase(),
              exercise.question.trim().toLowerCase(),
              (exercise.tts ?? '').trim().toLowerCase(),
              correctText.trim().toLowerCase(),
            ].join('|');
            if (seen.add(key)) {
              candidates.add(
                _DuelItem(topic: topic, round: round, exercise: exercise),
              );
            }
          }
        }
      }
    }
    candidates.shuffle(_random);
    return candidates.take(25).toList();
  }

  @override
  void initState() {
    super.initState();
    _items = List<_DuelItem>.from(_duelItems);
    _shuffleDifferentItems(_items);
    _prepareCurrent();
    _sounds.playDuelSuspense();
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
    _selected = null;
    _answerCorrect = false;
    _choices = List.generate(
      ex.answers.length,
      (i) => _DuelChoice(ex.answers[i], i == ex.correct),
    );
    _shuffleDifferentChoices(_choices);
    if ((ex.type == 'listening_choice' ||
            ex.type == 'listening_comprehension') &&
        ex.tts != null &&
        ex.tts!.isNotEmpty) {
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

  Future<void> _speak(Exercise ex) async {
    if (ex.tts == null || ex.tts!.isEmpty) return;
    final ok = await _tts.speak(text: ex.tts!, language: widget.ttsLanguage);
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

  String _correctAnswer(Exercise ex) {
    if (ex.correct != null &&
        ex.correct! >= 0 &&
        ex.correct! < ex.answers.length) {
      return ex.answers[ex.correct!];
    }
    return 'See the course answer.';
  }

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
      chapter: widget.chapter,
      topic: item.topic,
      round: item.round,
      exercise: item.exercise,
      exerciseIndex: roundIndex < 0 ? 0 : roundIndex,
      screen: 'Language Duel (${_index + 1}/${_duelItems.length})',
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
    if (won) {
      await _progress.winDuel(
        widget.chapter.duel.id,
        courseId: widget.course.courseId,
        courseCode: CourseService.codeForCourse(widget.course),
      );
      await _sounds.playDuelWin();
    } else {
      await _sounds.playDuelLost();
    }
    if (!mounted) return;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(won ? 'Duel won' : 'Duel lost'),
        content: Text(
          won
              ? 'You proved your knowledge. The next chapter can now unlock.'
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
    final items = _items;
    if (_lives <= 0) {
      await _finishDuel();
      return;
    }
    if (_index + 1 < items.length) {
      setState(() => _index++);
      _prepareCurrent();
      return;
    }
    await _finishDuel();
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
    if (AlphaLifecycleService.isExpired()) return const AlphaExpiredView();
    final items = _items;
    if (items.length < 25) {
      DiagnosticLogService().log(
        AppErrorCode.duelInsufficientExercises,
        context: 'Chapter: ${widget.chapter.id}',
      );
      return Scaffold(
        appBar: AppBar(title: Text(widget.chapter.duel.title)),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'This Chapter does not contain enough exercises for a Language Duel.\n\nError DUEL-001',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final item = items[_index];
    final ex = item.exercise;
    final background = _backgrounds[_index % _backgrounds.length];

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: background,
        title: Text(widget.chapter.duel.title),
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
                  'Language Duel',
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
                if (ex.type == 'listening_choice' ||
                    ex.type == 'listening_comprehension') ...[
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
                Text(ex.prompt, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text(
                  ex.question.isEmpty
                      ? 'Listen and choose the meaning.'
                      : ex.question,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 18),
                ...List.generate(
                  _choices.length,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: FilledButton.tonal(
                      onPressed: _selected == null
                          ? () => _selectChoice(i)
                          : null,
                      child: Text(_choices[i].text),
                    ),
                  ),
                ),
                if (_selected != null) ...[
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
                          _answerCorrect ? 'Correct' : 'Incorrect',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (!_answerCorrect) ...[
                          const SizedBox(height: 5),
                          Text('Correct answer: ${_correctAnswer(ex)}'),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _selected == null ? null : _next,
                  child: Text(
                    _lives <= 0 || _index + 1 == items.length
                        ? 'Finish duel'
                        : 'Next',
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
