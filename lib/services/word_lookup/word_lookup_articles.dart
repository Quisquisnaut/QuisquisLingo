import 'word_lookup_text.dart';

/// The articles Word Lookup's third rule may pass over (Build 265 Revision
/// 3, owner decision of 6 October 2026): a word found only inside a
/// GuideBook expression shows that expression when every other word of it
/// is an article, as `gatto` shows `il gatto` and `acqua` shows `l'acqua`,
/// but `è` does not show `dov'è`. The seven languages of the learner panel
/// have their articles here; in any language a word found in more than
/// three entries counts too.
abstract final class WordLookupArticles {
  static const Map<String, List<String>> _byLanguage = {
    'en': ['the', 'a', 'an'],
    'it': ['il', 'lo', 'la', "l'", 'i', 'gli', 'le', 'un', 'uno', 'una', "un'"],
    'es': ['el', 'la', 'lo', 'los', 'las', 'un', 'una', 'unos', 'unas'],
    'fr': ['le', 'la', "l'", 'les', 'un', 'une', 'des'],
    'de': [
      'der',
      'die',
      'das',
      'den',
      'dem',
      'des',
      'ein',
      'eine',
      'einen',
      'einem',
      'einer',
      'eines',
    ],
    'pt': ['o', 'a', 'os', 'as', 'um', 'uma', 'uns', 'umas'],
    'nl': ['de', 'het', 'een'],
  };

  /// The articles of the language [tag] names (its primary subtag, such as
  /// `it` in `it-IT`), normalized as Word Lookup compares words; empty for a
  /// language without a list.
  static Set<String> forLanguage(String? tag) {
    final primary = (tag ?? '').trim().split(RegExp('[-_]')).first;
    return {
      for (final article in _byLanguage[primary.toLowerCase()] ?? const [])
        WordLookupText.normalize(article),
    };
  }
}
