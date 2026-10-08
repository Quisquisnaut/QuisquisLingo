import 'package:flutter/material.dart';

import '../models/course_models.dart';
import '../services/settings_service.dart';

/// What the popup says about one primitive.
class PrimitiveIntroText {
  const PrimitiveIntroText({
    required this.learner,
    required this.fields,
    required this.tip,
  });

  /// What the learner does, one sentence.
  final String learner;

  /// The fields that matter, one line each.
  final List<String> fields;

  final String tip;
}

/// The popup that explains a primitive the first time the canonical editor
/// shows it in a Course (Build 261 Revision 6, owner decisions of 2 October
/// 2026): once per primitive, per learner and per Course, in English like
/// every editor popup. Stored as a learner one-time notice, so "Show
/// one-time notices again" brings it back.
abstract final class PrimitiveIntro {
  /// Test seam: the suite turns the popups off in
  /// `test/flutter_test_config.dart`, because a modal dialog on the first
  /// open would block every canonical editor test; their own test turns
  /// them on.
  static bool enabled = true;

  static String noticeId(ExercisePrimitive primitive, String courseId) =>
      'primitive_intro_${primitive.serialized}_'
      '${Uri.encodeComponent(courseId.trim())}';

  static const _notPlayable =
      'This version cannot play it yet: the exercise stays in the Course and '
      'learners skip it in Rounds.';

  static const texts = <ExercisePrimitive, PrimitiveIntroText>{
    ExercisePrimitive.select: PrimitiveIntroText(
      learner: 'The learner picks the correct answer among the items.',
      fields: [
        'Prompt: a Text with the role question, such as "Which animal '
            'barks?".',
        'Items: one per answer.',
        'Evaluation: tick the correct item (mode exactItem); for several '
            'correct items use exactSet with selectionMode multiple.',
      ],
      tip: 'Three or four items are enough; make the wrong ones plausible.',
    ),
    ExercisePrimitive.input: PrimitiveIntroText(
      learner: 'The learner types the answer.',
      fields: [
        'Prompt: the question or the sentence to complete.',
        'Evaluation: the accepted answers, one per line; {a|b} accepts '
            'either word.',
        'Options: caseHandling, accentHandling and the others decide how '
            'strictly the answer is compared.',
      ],
      tip:
          'For gaps inside a sentence, add Targets and place them with the '
          'Layout.',
    ),
    ExercisePrimitive.arrange: PrimitiveIntroText(
      learner: 'The learner puts blocks in the right order.',
      fields: [
        'Prompt: an instruction, such as "Put the words in order.".',
        'Items: one per block; a block left out of the correct order is a '
            'distractor.',
        'Evaluation: a correct order with its answer text and the item IDs '
            'in order.',
      ],
      tip:
          'Use at most two distractors; joiner none spells a word from '
          'letter blocks.',
    ),
    ExercisePrimitive.match: PrimitiveIntroText(
      learner:
          'The learner pairs each item on the left with one on the '
          'right.',
      fields: [
        'Items: give each item its side, Left or Right.',
        'Evaluation: one pair per match, a Left item and its Right item.',
      ],
      tip: 'Four or five pairs fit on one screen.',
    ),
    ExercisePrimitive.assign: PrimitiveIntroText(
      learner:
          'The learner places items into groups, slots or the gaps of '
          'a text: a tap on an item, then on its place.',
      fields: [
        'Options: targetMode says what the targets are (categories, slots '
            'or gaps).',
        'Targets: one per group, slot or gap; the Layout puts gaps in the '
            'text.',
        'Items: the words to place. Evaluation: which item IDs belong in '
            'each target.',
      ],
      tip:
          'The presets Sort into groups and Fill the slots write Assign '
          'exercises for you.',
    ),
    ExercisePrimitive.speak: PrimitiveIntroText(
      learner: 'The learner says something aloud.',
      fields: ['Prompt: what to say, such as "Good morning".'],
      tip: _notPlayable,
    ),
    ExercisePrimitive.ink: PrimitiveIntroText(
      learner: 'The learner writes by hand, such as tracing a letter.',
      fields: ['Prompt: what to write, such as "Trace the letter a.".'],
      tip: _notPlayable,
    ),
    ExercisePrimitive.submit: PrimitiveIntroText(
      learner: 'The learner hands in a free answer to check or review.',
      fields: [
        'Prompt: the task.',
        'Options: submissionType says what is handed in.',
      ],
      tip: _notPlayable,
    ),
    ExercisePrimitive.presentation: PrimitiveIntroText(
      learner: 'Nothing to answer: the learner reads a card and goes on.',
      fields: [
        'Prompt: for a Flashcard, Texts with the roles term and meaning '
            '(usage for an example).',
        'Options: completionMode decides how the learner moves on.',
      ],
      tip:
          'The presets Flashcard, Before you start, Dialogue line, Story '
          'cover and Page are easier ways to write cards.',
    ),
  };

  /// Shows [primitive]'s popup once per learner and Course; a null
  /// [courseId] (standalone forms) or no active learner shows nothing.
  static Future<void> showIfNeeded(
    BuildContext context, {
    required ExercisePrimitive primitive,
    required String? courseId,
    SettingsService? settings,
  }) async {
    if (!enabled || courseId == null || courseId.trim().isEmpty) return;
    final service = settings ?? SettingsService();
    final id = noticeId(primitive, courseId);
    if (await service.hasSeenLearnerOneTimeNotice(id) != false) return;
    if (!context.mounted) return;
    final text = texts[primitive]!;
    final bold = Theme.of(
      context,
    ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        key: const Key('primitive-intro'),
        title: Text('${primitive.label}: how it works'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(text.learner),
              const SizedBox(height: 12),
              Text('Fill in', style: bold),
              const SizedBox(height: 4),
              for (final field in text.fields)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• $field'),
                ),
              const SizedBox(height: 8),
              Text('Tip', style: bold),
              const SizedBox(height: 4),
              Text(text.tip),
              const SizedBox(height: 12),
              const Text(
                'Every element has a Role: pick it from the menu, which says '
                'what each role does. On a new exercise, Fill with an example '
                'shows a working one; Help explains this primitive.',
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            key: const Key('primitive-intro-ok'),
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
    await service.markLearnerOneTimeNoticeSeen(id);
  }
}
