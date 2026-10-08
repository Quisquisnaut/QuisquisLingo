import 'package:characters/characters.dart';
import 'package:unorm_dart/unorm_dart.dart' as unorm;

/// One word of a text as Word Lookup reads it (Build 265).
///
/// [start] and [end] are UTF-16 offsets in the original text, so a tap can
/// be mapped back to the word under it.
class WordLookupToken {
  const WordLookupToken({
    required this.start,
    required this.end,
    required this.key,
    required this.spaceless,
    required this.gap,
  });

  final int start;
  final int end;

  /// The normalized form compared with GuideBook entries: small letters,
  /// `’` read as `'`, composed accents (NFC). Accents are kept.
  final String key;

  /// One character of a script written without spaces (Chinese, Japanese,
  /// Thai, Lao, Khmer, Burmese, Tibetan): there a character plays the role a
  /// word plays elsewhere.
  final bool spaceless;

  /// A word holding `_`, such as `___` or `dr_ink_`: an exercise gap, never
  /// looked up and never part of an expression.
  final bool gap;

  /// Whether the word ends with an elision apostrophe (`l'`, `dell'`).
  bool get elided => key.endsWith("'");
}

/// Splits text into the words Word Lookup compares (Build 265).
///
/// The same rules read the learner's text and the target side of every
/// GuideBook entry, so both sides always split alike:
/// - punctuation separates words and is otherwise ignored;
/// - an apostrophe after a letter stays with its word and ends it:
///   `l'acqua` is the two words `l'` and `acqua`;
/// - a hyphen between letters joins: `self-service` is one word;
/// - `_` belongs to its word and makes it a gap;
/// - in scripts written without spaces each character (grapheme cluster) is
///   a word of its own.
abstract final class WordLookupText {
  static final RegExp _spacelessScript = RegExp(
    r'[\p{Script_Extensions=Han}\p{Script_Extensions=Hiragana}'
    r'\p{Script_Extensions=Katakana}\p{Script_Extensions=Thai}'
    r'\p{Script_Extensions=Lao}\p{Script_Extensions=Khmer}'
    r'\p{Script_Extensions=Myanmar}\p{Script_Extensions=Tibetan}]',
    unicode: true,
  );
  static final RegExp _wordCharacter = RegExp(
    r'^[\p{L}\p{M}\p{N}]',
    unicode: true,
  );
  static const Set<String> _apostrophes = {"'", '’'};
  static const Set<String> _hyphens = {'-', '‐', '‑'};

  static List<WordLookupToken> tokenize(String text) {
    final tokens = <WordLookupToken>[];
    final clusters = <(int, String)>[];
    var offset = 0;
    for (final cluster in text.characters) {
      clusters.add((offset, cluster));
      offset += cluster.length;
    }

    var wordStart = -1;
    final word = StringBuffer();
    var gap = false;
    void close(int end) {
      if (wordStart < 0) return;
      tokens.add(
        WordLookupToken(
          start: wordStart,
          end: end,
          key: normalize(word.toString()),
          spaceless: false,
          gap: gap,
        ),
      );
      wordStart = -1;
      word.clear();
      gap = false;
    }

    for (var i = 0; i < clusters.length; i++) {
      final (at, cluster) = clusters[i];
      if (_isSpaceless(cluster)) {
        close(at);
        tokens.add(
          WordLookupToken(
            start: at,
            end: at + cluster.length,
            key: normalize(cluster),
            spaceless: true,
            gap: false,
          ),
        );
      } else if (_isWordCharacter(cluster) || cluster == '_') {
        if (wordStart < 0) wordStart = at;
        word.write(cluster);
        if (cluster == '_') gap = true;
      } else if (_apostrophes.contains(cluster) && wordStart >= 0) {
        word.write(cluster);
        close(at + cluster.length);
      } else if (_hyphens.contains(cluster) &&
          wordStart >= 0 &&
          i + 1 < clusters.length &&
          _isWordCharacter(clusters[i + 1].$2) &&
          !_isSpaceless(clusters[i + 1].$2)) {
        word.write(cluster);
      } else {
        close(at);
      }
    }
    close(offset);
    return tokens;
  }

  /// The keys of [text]'s words, gaps included.
  static List<String> keys(String text) => [
    for (final token in tokenize(text)) token.key,
  ];

  static String normalize(String value) =>
      unorm.nfc(value.toLowerCase().replaceAll('’', "'"));

  static bool _isSpaceless(String cluster) =>
      _isWordCharacter(cluster) && _spacelessScript.hasMatch(cluster);

  static bool _isWordCharacter(String cluster) =>
      _wordCharacter.hasMatch(cluster);
}
