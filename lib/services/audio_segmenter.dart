import 'package:characters/characters.dart';

import '../models/course_models.dart';

/// How much of one text the recordings of an Audio Library say.
class AudioCoverage {
  const AudioCoverage({required this.clips, required this.missing});

  /// The recordings that say parts of the text, in order.
  final List<CourseAudioClip> clips;

  /// The runs of words no recording says, as written, without the
  /// punctuation around them.
  final List<String> missing;

  /// Whether recordings say the text from beginning to end, so playback
  /// joins them.
  bool get complete => missing.isEmpty && clips.isNotEmpty;
}

/// The one rule that matches a text to the recordings of an Audio Library
/// (pure Dart; `RecordedAudioService.segment` is this rule): capitals,
/// spaces and the punctuation around a text do not count, and the longest
/// recording that fits is taken first, so a one-word recording never takes
/// the place of a recording of the whole expression.
///
/// Build 276 Revision 0 (owner brief of 17 October 2026): an apostrophe
/// beside a letter at either end of a word is part of it, so the article
/// L' and the letter L, or un' and un, are two texts; ' ’ and ʼ are one
/// apostrophe, inside words too (dov'è = dov’è). Single quotes around a
/// word or a phrase ('ciao', ‘come here’) are quote marks and do not count
/// ([_withoutQuotes]); since an apostrophe that opens a word and one that
/// ends a later word may be elisions too ('O sole, pe' te), a run of words
/// is looked up as written first, then without such marks ([_longest]).
abstract final class AudioSegmenter {
  static final RegExp _spaces = RegExp(r'\s+');
  static final RegExp _wordCharacter = RegExp(
    r'[\p{L}\p{M}\p{N}]',
    unicode: true,
  );
  static final RegExp _letter = RegExp(r'\p{L}', unicode: true);

  /// The punctuation at the edges of a text without apostrophes: the rule
  /// before Build 276, kept as it was for such a text.
  static final RegExp _edges = RegExp(
    r'^[^\p{L}\p{M}\p{N}]+|[^\p{L}\p{M}\p{N}]+$',
    unicode: true,
  );

  /// The apostrophes that are one character for a recording.
  static const apostrophes = "'’ʼ";
  static final RegExp _apostrophe = RegExp('[$apostrophes]');

  /// The marks that open a quotation in single quotes: an apostrophe,
  /// ‘ (English, Italian) and ‚ (German, Polish).
  static const _openingQuotes = '$apostrophes‘‚';
  static final RegExp _quoteMark = RegExp('[$_openingQuotes]');

  /// The marks that close one: an apostrophe and ‘ (German ‚…‘).
  static const _closingQuotes = '$apostrophes‘';

  /// What may stand before an opening quote besides a space.
  static const _beforeOpening = '([{«‹“„"¿¡–—';

  /// What two texts must share to be the same text for a recording.
  static String key(String value) => unifyApostrophes(
    _trimmed(_withoutQuotes(value.trim().replaceAll(_spaces, ' '))),
  ).toLowerCase();

  /// [text] with ' ’ ʼ written as one apostrophe.
  static String unifyApostrophes(String text) =>
      text.replaceAll(_apostrophe, "'");

  static bool _isApostrophe(String character) =>
      apostrophes.contains(character);

  /// A letter, a mark or a digit; never an apostrophe (ʼ is a letter for
  /// Unicode).
  static bool _isWord(String character) =>
      !_isApostrophe(character) && _wordCharacter.hasMatch(character);

  static bool _isLetter(String character) =>
      !_isApostrophe(character) && _letter.hasMatch(character);

  static bool _isSpace(String character) => character.trim().isEmpty;

  /// [text] without the single quotes around a word or a phrase. An
  /// opening mark (an apostrophe, ‘ or ‚ before a letter or a digit, at the
  /// start or after a space or an opening bracket or quote) pairs with the
  /// first closing mark after it (an apostrophe or ‘ after anything but a
  /// space, at the end or before anything but a letter or a digit) when two
  /// letters or digits or more lie between them, and both go. A mark left
  /// unpaired is an apostrophe and stays (L', 'n), and so do both marks
  /// around a single letter (rock 'n' roll). An elision that opens a text
  /// and one that ends a later word ('O … pe') pair too: [_longest] tries
  /// the words as written first, so their own recordings are found. A mark
  /// is never a word by itself here (an opening one needs a letter or a
  /// digit after it, a closing one something before it), so the text keeps
  /// its words.
  static String _withoutQuotes(String text) {
    if (!_quoteMark.hasMatch(text)) return text;
    final characters = text.characters.toList();
    final dropped = <int>{};
    int? open;
    var inside = 0;
    for (var i = 0; i < characters.length; i++) {
      final character = characters[i];
      final before = i == 0 ? null : characters[i - 1];
      final after = i + 1 < characters.length ? characters[i + 1] : null;
      if (open != null &&
          _closingQuotes.contains(character) &&
          before != null &&
          !_isSpace(before) &&
          (after == null || !_isWord(after))) {
        if (inside >= 2) dropped.addAll([open, i]);
        open = null;
        continue;
      }
      if (open == null &&
          _openingQuotes.contains(character) &&
          after != null &&
          _isWord(after) &&
          (before == null ||
              _isSpace(before) ||
              _beforeOpening.contains(before))) {
        open = i;
        inside = 0;
        continue;
      }
      if (open != null && _isWord(character)) inside++;
    }
    if (dropped.isEmpty) return text;
    return [
      for (var i = 0; i < characters.length; i++)
        if (!dropped.contains(i)) characters[i],
    ].join();
  }

  /// [text] without the punctuation around it, keeping an apostrophe that
  /// ends a word after a letter or starts one before a letter. The text
  /// keeps its own characters (the missing words Texts in this Course shows
  /// are written as the author wrote them).
  static String _trimmed(String text) {
    if (!_apostrophe.hasMatch(text)) return text.replaceAll(_edges, '');
    final characters = text.characters.toList();
    var start = 0;
    while (start < characters.length && !_isWord(characters[start])) {
      start++;
    }
    var end = characters.length;
    while (end > start && !_isWord(characters[end - 1])) {
      end--;
    }
    if (start >= end) return '';
    // An apostrophe beside a letter (not a digit) at either end.
    if (start > 0 &&
        _isApostrophe(characters[start - 1]) &&
        _isLetter(characters[start])) {
      start--;
    }
    if (end < characters.length &&
        _isApostrophe(characters[end]) &&
        _isLetter(characters[end - 1])) {
      end++;
    }
    return characters.sublist(start, end).join();
  }

  static Map<String, CourseAudioClip> _byKey(List<CourseAudioClip> library) {
    final byText = <String, CourseAudioClip>{};
    for (final clip in library) {
      final clipKey = key(clip.text);
      if (clipKey.isNotEmpty) byText[clipKey] = clip;
    }
    return byText;
  }

  /// [text]'s words as written, and the same words without the single
  /// quotes paired on the whole text (the written words again when there
  /// are none).
  static (List<String>, List<String>) _words(String text) {
    final trimmed = text.trim();
    final written = trimmed.split(_spaces);
    final unquoted = _withoutQuotes(trimmed).split(_spaces);
    return (written, unquoted.length == written.length ? unquoted : written);
  }

  /// The longest run of words from [i] a recording says, and its length:
  /// each run as written first ('O and pe' find their own recordings), then
  /// without the quote marks ('come here' finds come and here).
  static (CourseAudioClip, int)? _longest(
    List<String> written,
    List<String> unquoted,
    int i,
    Map<String, CourseAudioClip> byText,
  ) {
    for (var length = written.length - i; length >= 1; length--) {
      final asWritten = written.sublist(i, i + length).join(' ');
      final withoutQuotes = unquoted.sublist(i, i + length).join(' ');
      final clip =
          byText[key(asWritten)] ??
          (withoutQuotes == asWritten ? null : byText[key(withoutQuotes)]);
      if (clip != null) return (clip, length);
    }
    return null;
  }

  /// The recordings that say [text] from beginning to end, or null when a
  /// word of it has none.
  static List<CourseAudioClip>? segment(
    String text,
    List<CourseAudioClip> library,
  ) {
    final (words, unquoted) = _words(text);
    if (words.isEmpty) return const [];
    final byText = _byKey(library);
    final out = <CourseAudioClip>[];
    var i = 0;
    while (i < words.length) {
      final found = _longest(words, unquoted, i, byText);
      if (found == null) return null;
      out.add(found.$1);
      i += found.$2;
    }
    return out;
  }

  /// [segment] that goes on past a word without a recording (Build 271
  /// Revision 2): the recordings that say parts of [text] and the words
  /// still missing. For a text recordings say whole, the same recordings as
  /// [segment].
  static AudioCoverage coverage(String text, List<CourseAudioClip> library) {
    final (words, unquoted) = text.trim().isEmpty
        ? (const <String>[], const <String>[])
        : _words(text);
    final byText = _byKey(library);
    final clips = <CourseAudioClip>[];
    final missing = <String>[];
    final run = <String>[];
    void closeRun() {
      if (run.isEmpty) return;
      // As the run's key reads it: its own single quotes paired.
      final written = _trimmed(_withoutQuotes(run.join(' ')));
      if (written.isNotEmpty) missing.add(written);
      run.clear();
    }

    var i = 0;
    while (i < words.length) {
      final found = _longest(words, unquoted, i, byText);
      if (found == null) {
        // A word of punctuation alone needs no recording.
        if (key(words[i]).isNotEmpty) run.add(words[i]);
        i++;
        continue;
      }
      closeRun();
      clips.add(found.$1);
      i += found.$2;
    }
    closeRun();
    return AudioCoverage(
      clips: List.unmodifiable(clips),
      missing: List.unmodifiable(missing),
    );
  }
}
