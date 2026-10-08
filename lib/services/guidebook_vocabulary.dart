/// One GuideBook vocabulary entry: the learning-language side first, then
/// its meaning in the learner's language (Build 265: `target = source`, as
/// the GuideBook editor states).
class GuidebookVocabularyPair {
  const GuidebookVocabularyPair(this.target, this.source);

  final String target;
  final String source;
}

/// The one reader of a `target = source` line. Since Build 266 a GuideBook
/// stores its entries with both sides apart, so this reads only lines typed
/// as text: the module page's Paste list (`GuidebookPasteList`) and a v11
/// GuideBook's vocabulary in the converter.
abstract final class GuidebookVocabulary {
  /// Tried in this order; the first one found with text on both sides wins.
  static const List<String> separators = [' = ', ' → ', ' - ', ':'];

  static GuidebookVocabularyPair? parse(String raw) {
    final line = raw.trim();
    for (final separator in separators) {
      final at = line.indexOf(separator);
      if (at < 1) continue;
      final target = line.substring(0, at).trim();
      final source = line.substring(at + separator.length).trim();
      if (target.isNotEmpty && source.isNotEmpty) {
        return GuidebookVocabularyPair(target, source);
      }
    }
    return null;
  }
}
