/// The text rules of a GuideBook entry (Build 266, GuideBook Modules; pure
/// Dart, no Flutter).
///
/// A Target may mark words that can be left out, such as an understood
/// subject, with QQL's optional-word braces: `{io} sono stanco`. Only `{…}`,
/// never nested; no other answer syntax (`[…|…]`, `<>`) is allowed in
/// GuideBook text. Learners see "(io) sono stanco" with *io* in grey; Word
/// Lookup and typed answers accept both forms; word blocks and displayed
/// sentences use the form without the optional words.
abstract final class GuidebookText {
  /// A Context names a sense, a subject area, formality or who speaks: a
  /// short note, never a sentence.
  static const maxContextLength = 40;

  /// From this many characters an Overview is long: the module page shows a
  /// hint and the Audit an Info (`GUIDEBOOK_MODULE_OVERVIEW_LONG`), never
  /// blocking. A longer topic is better split into shorter modules.
  static const longOverviewLength = 500;

  /// What is wrong with [target]'s optional words, or null when it is fine.
  static String? targetProblem(String target) {
    if (target.contains('[') || target.contains(']') || target.contains('|')) {
      return 'only {…} may mark optional words; [, ] and | are not allowed';
    }
    if (target.contains('<>')) {
      return 'only {…} may mark optional words; <> is not allowed';
    }
    var open = -1;
    for (var i = 0; i < target.length; i++) {
      final char = target[i];
      if (char == '{') {
        if (open >= 0) return 'optional words {…} cannot be nested';
        open = i;
      } else if (char == '}') {
        if (open < 0) return 'a } has no matching {';
        if (target.substring(open + 1, i).trim().isEmpty) {
          return 'optional words {…} cannot be empty';
        }
        open = -1;
      }
    }
    if (open >= 0) return 'a { has no matching }';
    if (withoutOptionalWords(target).isEmpty) {
      return 'it needs words outside the optional {…}';
    }
    return null;
  }

  /// Whether [target] marks optional words.
  static bool hasOptionalWords(String target) => target.contains('{');

  /// [target] with its optional words kept: `{io} sono stanco` → `io sono
  /// stanco`.
  static String withOptionalWords(String target) =>
      _tidy(target.replaceAll('{', '').replaceAll('}', ''));

  /// [target] without its optional words: `{io} sono stanco` → `sono stanco`.
  /// What word blocks and displayed sentences use.
  static String withoutOptionalWords(String target) =>
      _tidy(target.replaceAll(RegExp(r'\{[^{}]*\}'), ''));

  /// Both forms of [target], the longer first; one when it marks nothing.
  static List<String> forms(String target) {
    final full = withOptionalWords(target);
    final short = withoutOptionalWords(target);
    return [full, if (short != full && short.isNotEmpty) short];
  }

  /// [target] in pieces for display: the optional words apart, so a screen
  /// can show them as "(io)" in grey.
  static List<({String text, bool optional})> runs(String target) {
    final result = <({String text, bool optional})>[];
    var start = 0;
    for (final match in RegExp(r'\{([^{}]*)\}').allMatches(target)) {
      if (match.start > start) {
        result.add((
          text: target.substring(start, match.start),
          optional: false,
        ));
      }
      result.add((text: match.group(1)!.trim(), optional: true));
      start = match.end;
    }
    if (start < target.length) {
      result.add((text: target.substring(start), optional: false));
    }
    return result;
  }

  /// [target] as one line of plain text with the optional words in
  /// brackets: `{io} sono stanco` → `(io) sono stanco`.
  static String display(String target) => _tidy(
    target.replaceAllMapped(
      RegExp(r'\{([^{}]*)\}'),
      (match) => '(${match.group(1)!.trim()})',
    ),
  );

  static String _tidy(String value) => value
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r' (?=[.,!?;:…])'), '')
      .trim();
}
