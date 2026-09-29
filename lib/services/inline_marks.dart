/// Build 258 (Page blocks): the two inline marks a Page's body text may
/// carry, `**bold**` and `*italic*`, parsed by QQL itself (no Markdown or
/// HTML: Course content is data, never markup to execute).
///
/// A mark opens only before a character that is not a space and closes only
/// after one, so `2 * 3` stays as typed. A mark that finds no partner is
/// shown as typed and reported by [hasUnmatched] (the Audit warns). A
/// backslash before a star (`\*`) always shows the star.
library;

/// A stretch of text with one style.
class InlineRun {
  const InlineRun(this.text, {this.bold = false, this.italic = false});

  final String text;
  final bool bold;
  final bool italic;

  @override
  bool operator ==(Object other) =>
      other is InlineRun &&
      other.text == text &&
      other.bold == bold &&
      other.italic == italic;

  @override
  int get hashCode => Object.hash(text, bold, italic);

  @override
  String toString() =>
      'InlineRun(${bold ? 'b' : ''}${italic ? 'i' : ''} "$text")';
}

abstract final class InlineMarks {
  /// [text] as runs of plain, bold, italic or bold italic text.
  static List<InlineRun> parse(String text) => _parse(text).runs;

  /// Whether [text] has a mark without its partner.
  static bool hasUnmatched(String text) => _parse(text).unmatched;

  /// [text] without its marks: what read-aloud speaks and Search finds.
  static String plain(String text) => parse(text).map((run) => run.text).join();

  static ({List<InlineRun> runs, bool unmatched}) _parse(String text) {
    final tokens = _tokenize(text);
    // Pair each kind of mark on its own: the latest opener waits for the
    // next marker of its kind that can close.
    int? openBold;
    int? openItalic;
    final matched = <int>{};
    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      if (token.marker == null) continue;
      final bold = token.marker == '**';
      final open = bold ? openBold : openItalic;
      if (open != null && token.canClose) {
        matched
          ..add(open)
          ..add(i);
        if (bold) {
          openBold = null;
        } else {
          openItalic = null;
        }
      } else if (token.canOpen) {
        if (bold) {
          openBold = i;
        } else {
          openItalic = i;
        }
      }
    }
    final runs = <InlineRun>[];
    var bold = false;
    var italic = false;
    var unmatched = false;
    void add(String value) {
      if (value.isEmpty) return;
      if (runs.isNotEmpty &&
          runs.last.bold == bold &&
          runs.last.italic == italic) {
        runs[runs.length - 1] = InlineRun(
          runs.last.text + value,
          bold: bold,
          italic: italic,
        );
      } else {
        runs.add(InlineRun(value, bold: bold, italic: italic));
      }
    }

    for (var i = 0; i < tokens.length; i++) {
      final token = tokens[i];
      final marker = token.marker;
      if (marker == null) {
        add(token.text);
      } else if (matched.contains(i)) {
        if (marker == '**') {
          bold = !bold;
        } else {
          italic = !italic;
        }
      } else {
        unmatched = true;
        add(marker);
      }
    }
    return (runs: runs, unmatched: unmatched);
  }

  static List<_Token> _tokenize(String text) {
    final tokens = <_Token>[];
    final buffer = StringBuffer();
    bool spaceAt(int index) =>
        index < 0 || index >= text.length || text[index].trim().isEmpty;
    var i = 0;
    while (i < text.length) {
      if (text[i] == r'\' && i + 1 < text.length && text[i + 1] == '*') {
        buffer.write('*');
        i += 2;
        continue;
      }
      if (text[i] != '*') {
        buffer.write(text[i]);
        i++;
        continue;
      }
      if (buffer.isNotEmpty) {
        tokens.add(_Token.text(buffer.toString()));
        buffer.clear();
      }
      final length = text.startsWith('**', i) ? 2 : 1;
      tokens.add(
        _Token.marker(
          length == 2 ? '**' : '*',
          canOpen: !spaceAt(i + length),
          canClose: !spaceAt(i - 1),
        ),
      );
      i += length;
    }
    if (buffer.isNotEmpty) tokens.add(_Token.text(buffer.toString()));
    return tokens;
  }
}

class _Token {
  _Token.text(this.text) : marker = null, canOpen = false, canClose = false;
  _Token.marker(this.marker, {required this.canOpen, required this.canClose})
    : text = '';

  final String text;
  final String? marker;
  final bool canOpen;
  final bool canClose;
}
