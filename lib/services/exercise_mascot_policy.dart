import 'dart:math';

import '../models/course_models.dart';
import '../models/exercise_features.dart';
import 'exercise_copy_service.dart';

/// Where a learner exercise's mascot sits: beside the one sentence the
/// learner reads or hears (Build 256 Revision 9, owner decisions of
/// 29 September 2026).
enum ExerciseMascotAnchor {
  /// No mascot.
  none,

  /// The question shown in the exercise body (a translation question, a
  /// Choose question, a first-letter sentence).
  question,

  /// The authored prompt above the body: the text to translate, a clue, or
  /// a plain Choose's prompt drawn as its instruction.
  prompt,

  /// The panel holding a sentence with gaps.
  gappedText,

  /// The button that plays the sentence the learner listens to.
  playButton,
}

/// Which learner exercises show a mascot, and where. Three rules, read from
/// canonical data only (never a preset ID, plan A.3):
///
/// 1. the exercise shows no picture, avatar or anything but words and
///    sound (no image element, no image or icon answer, no speaker);
/// 2. it has a sentence the learner reads or hears ([isSentence]);
/// 3. there is room beside that sentence ([fits], measured on screen).
///
/// Exercises built from blocks of letters, lines to put in order, Match,
/// Assign and cards have no sentence beside which a mascot would fit.
class ExerciseMascotPolicy {
  const ExerciseMascotPolicy._();

  /// Mascots the Round path shows but exercises never do (owner decision:
  /// the sleeping monkey stays on the Round path only).
  static const excludedAssets = {'assets/mascots/qql-monkey-sleeping.webp'};

  /// The narrowest the sentence beside a mascot may become.
  static const minimumTextWidth = 220.0;

  /// The most lines the sentence beside a mascot may take.
  static const maximumLines = 3;

  /// The lowest window in which a mascot is drawn.
  static const minimumViewportHeight = 560.0;

  /// The space between the mascot and the sentence.
  static const gap = 12.0;

  /// The pictures exercises may show: every renderable mascot but the
  /// excluded ones, sorted.
  static List<String> exercisePool(Iterable<String> mascotAssets) =>
      mascotAssets.toSet().where((a) => !excludedAssets.contains(a)).toList()
        ..sort();

  /// The character a mascot picture shows: the first word of its file name,
  /// after an optional `qql-` prefix (`cat_reading.webp` and
  /// `cat-celebrating_tr.webp` are both `cat`).
  static String characterOf(String asset) {
    var name = asset.split('/').last.toLowerCase();
    final dot = name.lastIndexOf('.');
    if (dot > 0) name = name.substring(0, dot);
    if (name.startsWith('qql-')) name = name.substring(4);
    return RegExp(r'^[a-z0-9]+').firstMatch(name)?.group(0) ?? name;
  }

  /// Whether [text] is a sentence: two words or more, or ending in sentence
  /// punctuation ("Grazie." counts, "ciao" does not).
  static bool isSentence(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return false;
    if (RegExp('[.!?…。！？][\\s"\'»”’)\\]]*\$').hasMatch(trimmed)) return true;
    return trimmed.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length >= 2;
  }

  /// The mascot's size for a content area [contentWidth] wide.
  static double mascotSize(double contentWidth) =>
      contentWidth >= 600 ? 96 : 72;

  /// Rule 3: whether the mascot fits beside a sentence that takes [lines]
  /// lines in [textWidth] (the width left beside the mascot), in a window
  /// [viewportHeight] high. [lines] is null for a play button, which has no
  /// text to measure.
  static bool fits({
    required double textWidth,
    required int? lines,
    required double viewportHeight,
  }) =>
      textWidth >= minimumTextWidth &&
      viewportHeight >= minimumViewportHeight &&
      (lines == null || lines <= maximumLines);

  /// Rules 1 and 2: where [exercise]'s mascot goes, or
  /// [ExerciseMascotAnchor.none]. It follows the Round screen's renderers:
  /// the sentence in the body wins over the prompt above it.
  static ExerciseMascotAnchor anchorFor(Exercise exercise) {
    if (!exercise.isExecutable) return ExerciseMascotAnchor.none;
    final f = ExerciseFeatures(exercise);
    if (!wordsAndSoundOnly(f)) return ExerciseMascotAnchor.none;
    ExerciseMascotAnchor when(String text, ExerciseMascotAnchor anchor) =>
        isSentence(text) ? anchor : ExerciseMascotAnchor.none;
    switch (exercise.primitive) {
      case ExercisePrimitive.select:
        if (f.isTranslationChoice) {
          return when(f.questionText, ExerciseMascotAnchor.question);
        }
        final automatic = f.automaticAudio;
        if (automatic != null &&
            automatic.role != 'context' &&
            automatic.role != 'dialogue_turn') {
          return when(
            f.primaryAudioText ?? '',
            ExerciseMascotAnchor.playButton,
          );
        }
        if (f.hasInlineTargets) {
          return when(
            gappedSentence(exercise),
            ExerciseMascotAnchor.gappedText,
          );
        }
        if (f.questionText.isNotEmpty) {
          return when(f.questionText, ExerciseMascotAnchor.question);
        }
        return _promptAnchor(f);
      case ExercisePrimitive.input:
        if (f.gapFieldTargets.isNotEmpty) {
          return when(
            gappedSentence(exercise),
            ExerciseMascotAnchor.gappedText,
          );
        }
        if (f.automaticAudio != null && f.revealTarget == null) {
          return when(
            f.primaryAudioText ?? '',
            ExerciseMascotAnchor.playButton,
          );
        }
        if (f.kind == LearnerExerciseKind.inputTranslation) {
          return _promptAnchor(f);
        }
        if (f.revealTarget != null) {
          return when(f.inlineSentence, ExerciseMascotAnchor.question);
        }
        if (f.questionText.isNotEmpty) {
          return when(f.questionText, ExerciseMascotAnchor.question);
        }
        return _promptAnchor(f);
      case ExercisePrimitive.arrange:
        if (f.arrangeInline) {
          return when(
            gappedSentence(exercise),
            ExerciseMascotAnchor.gappedText,
          );
        }
        // Spelling (blocks of letters) and lines to put in order.
        if (f.joinsWithoutSpaces ||
            f.kind == LearnerExerciseKind.arrangeLines) {
          return ExerciseMascotAnchor.none;
        }
        return _promptAnchor(f);
      case ExercisePrimitive.match:
      case ExercisePrimitive.assign:
      case ExercisePrimitive.presentation:
      case ExercisePrimitive.speak:
      case ExercisePrimitive.ink:
      case ExercisePrimitive.submit:
        return ExerciseMascotAnchor.none;
    }
  }

  /// The text the mascot sits beside at [anchor], for measuring; null for a
  /// play button.
  static String? sentenceAt(Exercise exercise, ExerciseMascotAnchor anchor) {
    final f = ExerciseFeatures(exercise);
    return switch (anchor) {
      ExerciseMascotAnchor.question =>
        f.revealTarget != null && exercise.primitive == ExercisePrimitive.input
            ? f.inlineSentence
            : f.questionText,
      ExerciseMascotAnchor.prompt => displayedPrompt(f),
      ExerciseMascotAnchor.gappedText => gappedSentence(exercise),
      ExerciseMascotAnchor.playButton || ExerciseMascotAnchor.none => null,
    };
  }

  /// Rule 1: only words and sound. No image of any role in the prompt (a
  /// picture, an illustration, a character specimen, an avatar), nothing
  /// but text and audio elements, no image or icon answers, no speaker
  /// (dialogue turns or a Story line: a mascot beside named speakers looks
  /// like one of them).
  static bool wordsAndSoundOnly(ExerciseFeatures f) {
    for (final element in f.prompt) {
      if (!element.isText && !element.isAudio) return false;
      if (element.speakerId.isNotEmpty) return false;
    }
    return !f.hasImageItems && !f.hasIconItems && f.dialogueTurns.isEmpty;
  }

  /// The authored prompt the Round screen shows above the body, or an empty
  /// string when it shows none (the same test as the screen's).
  static String displayedPrompt(ExerciseFeatures f) {
    final prompt = f.primaryText.isNotEmpty ? f.primaryText : f.clueText;
    if (f.isTranslationChoice ||
        f.kind == LearnerExerciseKind.arrangeWord ||
        prompt.isEmpty ||
        ExerciseCopyService.isLegacyInstruction(prompt)) {
      return '';
    }
    return prompt;
  }

  static ExerciseMascotAnchor _promptAnchor(ExerciseFeatures f) =>
      isSentence(displayedPrompt(f))
      ? ExerciseMascotAnchor.prompt
      : ExerciseMascotAnchor.none;

  /// The inline layout as one text, every gap a blank.
  static String gappedSentence(Exercise exercise) => [
    for (final element in exercise.layout)
      if (element.isText) element.text else '_____',
  ].join();
}

/// The mascot pictures one Round shows, in order (Build 256 Revision 9):
/// every picture at most once, and two pictures in a row never show the
/// same character. The exercises that draw a mascot take the pictures in
/// this order, so the next mascot the learner sees is always another
/// character, whatever exercises without a mascot come between. When the
/// order is used up, later exercises show none.
class ExerciseMascotSequence {
  ExerciseMascotSequence._(this.order);

  /// The pictures in the order they are shown.
  final List<String> order;
  int _next = 0;

  /// A random order of [pool] in which neighbours are different characters.
  /// It uses every picture when that is possible (no character holds more
  /// than half of them, rounded up); otherwise it stops where the next
  /// picture would repeat the character before it.
  factory ExerciseMascotSequence.build(List<String> pool, Random random) {
    final byCharacter = <String, List<String>>{};
    for (final asset in pool.toSet()) {
      byCharacter
          .putIfAbsent(ExerciseMascotPolicy.characterOf(asset), () => [])
          .add(asset);
    }
    for (final assets in byCharacter.values) {
      assets
        ..sort()
        ..shuffle(random);
    }
    final order = <String>[];
    String? last;
    while (true) {
      final remaining = byCharacter.values.fold<int>(
        0,
        (total, assets) => total + assets.length,
      );
      if (remaining == 0) break;
      final characters =
          byCharacter.keys
              .where((c) => c != last && byCharacter[c]!.isNotEmpty)
              .toList()
            ..sort();
      if (characters.isEmpty) break;
      // A character holding more than half of what is left must come now,
      // or the rest could not alternate.
      final pressing = characters
          .where((c) => byCharacter[c]!.length * 2 > remaining)
          .toList();
      final choices = pressing.isNotEmpty ? pressing : characters;
      final character = choices[random.nextInt(choices.length)];
      order.add(byCharacter[character]!.removeLast());
      last = character;
    }
    return ExerciseMascotSequence._(List.unmodifiable(order));
  }

  /// The next picture, or null when every picture of the order is used.
  String? next() => _next < order.length ? order[_next++] : null;

  /// How many pictures have been taken.
  int get taken => _next;
}
