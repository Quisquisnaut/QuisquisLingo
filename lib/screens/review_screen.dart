import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../services/alpha_lifecycle_service.dart';
import '../services/course_language_resolver.dart';
import '../services/review_round_resolver.dart';
import '../services/vocabulary_review_service.dart';
import '../widgets/alpha_expired_view.dart';
import 'round_screen.dart';

class ReviewScreen extends StatefulWidget {
  final Course course;
  final String courseCode;

  /// Retained for source compatibility. Review always performs an ordinary,
  /// writable attempt based only on genuinely completed Round records.
  final bool viewOnlyMode;

  const ReviewScreen({
    super.key,
    required this.course,
    required this.courseCode,
    this.viewOnlyMode = false,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

enum _ReviewStage {
  loading,
  interReview,
  preVocabulary,
  openingRound,
  postVocabulary,
  empty,
}

class _ReviewScreenState extends State<ReviewScreen> {
  final ReviewRoundResolver _resolver = ReviewRoundResolver();
  final VocabularyReviewService _vocabulary = VocabularyReviewService();
  final Set<String> _reviewedRoundIds = {};

  _ReviewStage _stage = _ReviewStage.loading;
  ReviewRoundLocation? _location;
  List<VocabularyReviewEntry> _preEntries = const [];
  List<VocabularyReviewEntry> _postEntries = const [];
  int _entryIndex = 0;
  bool _answerRevealed = false;
  bool _noMoreRounds = false;
  bool _hasCompletedReview = false;
  bool _decisionPending = false;
  bool _roundOpeningScheduled = false;

  @override
  void initState() {
    super.initState();
    _loadNext(initial: true);
  }

  Future<void> _loadNext({bool initial = false}) async {
    if (mounted) {
      setState(() {
        _stage = _ReviewStage.loading;
        _noMoreRounds = false;
        _answerRevealed = false;
        _entryIndex = 0;
      });
    }
    final location = await _resolver.firstPending(
      widget.course,
      excludedRoundIds: _reviewedRoundIds,
    );
    if (!mounted) return;
    if (location == null) {
      setState(() {
        _location = null;
        _preEntries = const [];
        _postEntries = const [];
        _stage = initial ? _ReviewStage.empty : _ReviewStage.interReview;
        _noMoreRounds = !initial;
      });
      return;
    }
    final entries = await _vocabulary.eligibleEntries(
      widget.course,
      location.lesson,
    );
    if (!mounted) return;
    setState(() {
      _location = location;
      _preEntries = entries;
      _postEntries = const [];
      _stage = _ReviewStage.interReview;
    });
  }

  Future<void> _prepareLocation({bool refreshEntries = false}) async {
    final location = _location;
    if (location == null) return;
    final entries = refreshEntries
        ? await _vocabulary.eligibleEntries(widget.course, location.lesson)
        : _preEntries;
    if (!mounted || _location?.round.id != location.round.id) return;
    setState(() {
      _preEntries = entries;
      _postEntries = const [];
      _entryIndex = 0;
      _answerRevealed = false;
      _stage = entries.isEmpty
          ? _ReviewStage.openingRound
          : _ReviewStage.preVocabulary;
    });
    if (entries.isEmpty) _scheduleRound();
  }

  void _scheduleRound() {
    if (_roundOpeningScheduled) return;
    _roundOpeningScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _roundOpeningScheduled = false;
      if (!mounted || _stage != _ReviewStage.openingRound) return;
      await _openRound();
    });
  }

  Future<void> _openRound() async {
    final location = _location;
    if (location == null) return;
    final completed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RoundScreen(
          course: widget.course,
          lesson: location.lesson,
          round: location.round,
          roundIndex: location.roundIndex,
          ttsLanguage:
              CourseLanguageResolver.learning(widget.course).code ?? '',
          reviewMode: true,
        ),
      ),
    );
    if (!mounted) return;
    if (completed != true) {
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      return;
    }
    _reviewedRoundIds.add(location.round.id);
    if (_postEntries.isEmpty) {
      _hasCompletedReview = true;
      await _loadNext();
      return;
    }
    setState(() {
      _entryIndex = 0;
      _answerRevealed = false;
      _stage = _ReviewStage.postVocabulary;
    });
  }

  Future<void> _decide({required bool needsReinforcement}) async {
    if (_decisionPending) return;
    final location = _location;
    final entries = _stage == _ReviewStage.preVocabulary
        ? _preEntries
        : _postEntries;
    if (location == null || _entryIndex >= entries.length) return;
    _decisionPending = true;
    final entry = entries[_entryIndex];
    try {
      if (_stage == _ReviewStage.preVocabulary) {
        if (needsReinforcement) {
          await _vocabulary.requestReinforcement(
            widget.course.courseId,
            location.lesson.lessonId,
            entry,
          );
          if (!_postEntries.any((item) => item.identity == entry.identity)) {
            _postEntries = [..._postEntries, entry];
          }
        } else {
          await _vocabulary.markKnown(
            widget.course.courseId,
            location.lesson.lessonId,
            entry,
          );
        }
      } else if (needsReinforcement) {
        await _vocabulary.keepReinforcement(
          widget.course.courseId,
          location.lesson.lessonId,
          entry,
        );
      } else {
        await _vocabulary.markKnown(
          widget.course.courseId,
          location.lesson.lessonId,
          entry,
        );
      }
      if (!mounted) return;
      if (_entryIndex + 1 < entries.length) {
        setState(() {
          _entryIndex++;
          _answerRevealed = false;
        });
      } else if (_stage == _ReviewStage.preVocabulary) {
        setState(() {
          _stage = _ReviewStage.openingRound;
          _answerRevealed = false;
        });
        _scheduleRound();
      } else {
        _hasCompletedReview = true;
        await _loadNext();
      }
    } finally {
      _decisionPending = false;
    }
  }

  Future<void> _showResetConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset Word List?'),
        content: const Text(
          'All vocabulary for this course will be treated as new again. '
          'Round Review and course progress will not be changed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _vocabulary.resetCourse(widget.course.courseId);
    if (!mounted) return;
    if (_stage == _ReviewStage.interReview) {
      await _loadNext();
    } else if (_stage == _ReviewStage.preVocabulary) {
      await _prepareLocation(refreshEntries: true);
    } else if (_stage == _ReviewStage.postVocabulary) {
      _hasCompletedReview = true;
      await _loadNext();
    }
  }

  Future<void> _showHelp() => showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Review Help'),
      content: const SingleChildScrollView(
        child: Text(
          'Next Review starts a completed Round chosen from this course: '
          'Rounds with more errors come first, then the oldest attempt.\n\n'
          'Published GuideBook Vocabulary may appear before the Round. Reveal '
          'each answer, then choose I know it or Show it to me again. Only '
          'words requested again return once after the Round, where you can '
          'mark them known or say you still do not know them.\n\n'
          'Known words stay skipped in later Reviews. Reset Word List makes '
          'this course’s words new again for this learner without changing '
          'Round progress. Vocabulary has no separate XP or progression.',
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Close'),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (AlphaLifecycleService.isExpired()) return const AlphaExpiredView();
    if (_stage == _ReviewStage.openingRound) _scheduleRound();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review'),
        actions: [
          IconButton(
            key: const Key('review-reset-word-list'),
            tooltip: 'Reset Word List',
            onPressed: _showResetConfirmation,
            icon: const Icon(Icons.restart_alt_outlined),
          ),
          IconButton(
            key: const Key('review-help'),
            tooltip: 'Review Help',
            onPressed: _showHelp,
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: SafeArea(child: _body()),
    );
  }

  Widget _body() => switch (_stage) {
    _ReviewStage.loading || _ReviewStage.openingRound => const Center(
      child: CircularProgressIndicator(),
    ),
    _ReviewStage.interReview => _interReview(),
    _ReviewStage.preVocabulary => _vocabularyCard(afterRound: false),
    _ReviewStage.postVocabulary => _vocabularyCard(afterRound: true),
    _ReviewStage.empty => const Center(
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Text(
          'There are no Rounds available for Review in this course.',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  };

  Widget _vocabularyCard({required bool afterRound}) {
    final location = _location!;
    final entries = afterRound ? _postEntries : _preEntries;
    final entry = entries[_entryIndex];
    final roundTitle = location.round.title.trim();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Text(
          afterRound ? 'After the Round' : 'Before the Round',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        Text(widget.course.title, softWrap: true),
        Text(widget.course.targetLanguage, softWrap: true),
        Text(
          'Lesson ${location.lessonIndex + 1}: ${location.lesson.title}',
          softWrap: true,
        ),
        Text(
          'Round ${location.roundIndex + 1}'
          '${roundTitle.isEmpty ? '' : ': $roundTitle'}',
          softWrap: true,
        ),
        const SizedBox(height: 16),
        LinearProgressIndicator(value: _entryIndex / entries.length),
        const SizedBox(height: 6),
        Text(
          'Word ${_entryIndex + 1} of ${entries.length}',
          textAlign: TextAlign.end,
        ),
        const SizedBox(height: 18),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  entry.prompt,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                if (_answerRevealed) ...[
                  const SizedBox(height: 18),
                  Text(
                    entry.answer,
                    style: Theme.of(context).textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  for (final detail in entry.supplementary) Text(detail),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (!_answerRevealed)
          FilledButton(
            onPressed: () => setState(() => _answerRevealed = true),
            child: const Text('Show answer'),
          )
        else if (afterRound) ...[
          FilledButton(
            onPressed: _decisionPending
                ? null
                : () => _decide(needsReinforcement: false),
            child: const Text('Now I know it'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _decisionPending
                ? null
                : () => _decide(needsReinforcement: true),
            child: const Text("I still don't know it"),
          ),
        ] else ...[
          FilledButton(
            onPressed: _decisionPending
                ? null
                : () => _decide(needsReinforcement: false),
            child: const Text('I know it'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _decisionPending
                ? null
                : () => _decide(needsReinforcement: true),
            child: const Text('Show it to me again'),
          ),
        ],
      ],
    );
  }

  Widget _interReview() {
    final wordCount = _location == null ? null : _preEntries.length;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                _hasCompletedReview
                    ? Icons.celebration_outlined
                    : Icons.menu_book_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                _hasCompletedReview ? 'Review completed!' : 'Ready for Review',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (_noMoreRounds) ...[
                const SizedBox(height: 14),
                const Text(
                  'No more Rounds are available in this Review session.',
                  textAlign: TextAlign.center,
                ),
              ],
              if (wordCount != null) ...[
                const SizedBox(height: 14),
                Text(
                  '$wordCount ${wordCount == 1 ? 'word' : 'words'} to review in the next Review.',
                  key: const Key('review-next-word-count'),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                key: const Key('review-next'),
                onPressed: _location == null ? null : _prepareLocation,
                icon: const Icon(Icons.navigate_next),
                label: const Text('Next Review'),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                key: const Key('review-back-to-course'),
                onPressed: () => Navigator.of(context).maybePop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Course'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
