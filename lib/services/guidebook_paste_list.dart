import '../models/guidebook_text.dart';
import 'guidebook_vocabulary.dart';

/// One line Paste list could read: an entry without its ID yet.
typedef GuidebookPastedEntry = ({String target, String source, String context});

/// A line Paste list could not read, and why.
typedef GuidebookUnreadLine = ({int number, String line, String reason});

/// Paste list on the GuideBook module page (Build 266 Revision 1): one entry
/// per line, `target = source [context]`, the Context in square brackets at
/// the end and optional. The separators are [GuidebookVocabulary]'s
/// (` = `, ` → `, ` - `, `:`). Blank lines are skipped; every other line it
/// cannot read is named with the reason, never guessed.
abstract final class GuidebookPasteList {
  static const exampleLines = [
    'il conto = the bill [restaurant]',
    'il conto = the account [bank]',
    'buongiorno = good morning',
    '{io} sono stanco = I am tired',
  ];

  static final _context = RegExp(r'\s*\[([^\[\]]*)\]\s*$');

  static ({
    List<GuidebookPastedEntry> entries,
    List<GuidebookUnreadLine> unread,
  })
  read(String text) {
    final entries = <GuidebookPastedEntry>[];
    final unread = <GuidebookUnreadLine>[];
    final lines = text.split(RegExp(r'\r\n|\r|\n'));
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      void refuse(String reason) =>
          unread.add((number: i + 1, line: line, reason: reason));
      var rest = line;
      var context = '';
      final bracket = _context.firstMatch(rest);
      if (bracket != null) {
        context = bracket.group(1)!.trim();
        rest = rest.substring(0, bracket.start).trim();
      }
      final pair = GuidebookVocabulary.parse(rest);
      if (pair == null) {
        refuse('write it as target = source');
        continue;
      }
      final problem = GuidebookText.targetProblem(pair.target);
      if (problem != null) {
        refuse('Target: $problem');
        continue;
      }
      if (pair.source.contains('[') || pair.source.contains(']')) {
        refuse('put the Context in [ ] at the end of the line');
        continue;
      }
      if (context.length > GuidebookText.maxContextLength) {
        refuse(
          'the Context is longer than '
          '${GuidebookText.maxContextLength} characters',
        );
        continue;
      }
      entries.add((target: pair.target, source: pair.source, context: context));
    }
    return (entries: entries, unread: unread);
  }
}
