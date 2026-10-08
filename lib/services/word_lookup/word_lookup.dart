import '../guidebook_vocabulary.dart';
import 'word_lookup_text.dart';

/// A GuideBook vocabulary line handed to [WordLookupIndex.build], in Course
/// order. [lessonIndex] is the Lesson's position in the Course the learner
/// is shown, so the card can name the Lesson as the learner's path does.
class WordLookupSourceEntry {
  const WordLookupSourceEntry({
    required this.id,
    required this.text,
    required this.lessonIndex,
  });

  final String id;
  final String text;
  final int lessonIndex;
}

/// One entry a lookup shows: the GuideBook's own two sides.
class WordLookupEntry {
  const WordLookupEntry({
    required this.id,
    required this.target,
    required this.source,
    required this.lessonIndex,
  });

  final String id;
  final String target;
  final String source;
  final int lessonIndex;

  @override
  String toString() => '$target = $source (Lesson index $lessonIndex)';
}

/// A span of the analyzed text, as UTF-16 offsets ([end] exclusive).
class WordLookupRange {
  const WordLookupRange(this.start, this.end);

  final int start;
  final int end;

  bool contains(int offset) => offset >= start && offset < end;

  @override
  bool operator ==(Object other) =>
      other is WordLookupRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => '[$start, $end)';
}

/// What a tap finds: the entries to show and the words to highlight.
class WordLookupResult {
  const WordLookupResult({required this.entries, required this.range});

  final List<WordLookupEntry> entries;
  final WordLookupRange range;
}

class _IndexedEntry {
  _IndexedEntry({
    required this.order,
    required this.entry,
    required this.keys,
    required this.sameAs,
  });

  final int order;
  final WordLookupEntry entry;

  /// The target side's word keys.
  final List<String> keys;

  /// Identical entries (same target and source once normalized) share this
  /// value and are shown once.
  final String sameAs;
}

class _Occurrence {
  const _Occurrence(this.entry, this.first, this.length, {this.loose = false});

  final _IndexedEntry entry;
  final int first;
  final int length;

  /// Matched with a word's final apostrophe read as a closing quote mark
  /// (‘gatto’ as `gatto`); an exact match of the same length wins.
  final bool loose;

  int get last => first + length - 1;

  bool covers(int token) => token >= first && token <= last;
}

/// The GuideBook vocabulary of one Course, ready for Word Lookup (Build 265,
/// `docs/265_WORD_LOOKUP_PLAN.md`). Pure Dart: built from a flat list of
/// entries, so it never reads the GuideBook's own shape.
///
/// Only the target side of an entry is searched. For the word under a tap:
/// 1. the longest entry found in the text that covers the word, counted in
///    words (in characters inside a script written without spaces);
/// 2. (the word alone is the shortest such entry);
/// 3. otherwise an entry of two or more words that contains the word when
///    every other word of it is an article ([articles]) or a common word (in
///    more than [commonWordLimit] entries): `gatto` shows `il gatto`, `è`
///    does not show `dov'è` (owner decision of 6 October 2026); a tapped
///    article or common word finds nothing this way.
/// At the length reached, entries of the current Lesson win; without one,
/// every Lesson's entries are shown in Course order, identical ones once.
/// An apostrophe word (`l'acqua`) is looked up whole first; when no entry
/// covers it whole, each piece is looked up with rules 1–3 and the results
/// are shown together (`acqua` in `d'acqua` shows `l'acqua`; rule 3 for the
/// pieces since Build 265 Revision 4). A word ending with an apostrophe
/// that no word follows is looked up as written (`po'`), else without it,
/// as a closing quote mark (‘gatto’).
class WordLookupIndex {
  WordLookupIndex._(this._entries, this._articles) {
    for (final entry in _entries) {
      _indexed[entry.entry] = entry;
      _byFirstKey.putIfAbsent(entry.keys.first, () => []).add(entry);
      for (final key in entry.keys.toSet()) {
        _byKey.putIfAbsent(key, () => []).add(entry);
      }
    }
    final seen = <String>{};
    for (final entry in _entries) {
      final target = entry.keys.join(' ');
      if (!seen.add(target)) continue;
      for (final key in entry.keys.toSet()) {
        _frequency.update(key, (value) => value + 1, ifAbsent: () => 1);
      }
    }
  }

  /// [articles] are the learning language's articles, normalized
  /// (`WordLookupArticles.forLanguage`).
  factory WordLookupIndex.build(
    Iterable<WordLookupSourceEntry> sources, {
    Set<String> articles = const {},
  }) {
    final entries = <_IndexedEntry>[];
    for (final source in sources) {
      final pair = GuidebookVocabulary.parse(source.text);
      if (pair == null) continue;
      final tokens = WordLookupText.tokenize(pair.target);
      if (tokens.isEmpty || tokens.any((token) => token.gap)) continue;
      final keys = [for (final token in tokens) token.key];
      entries.add(
        _IndexedEntry(
          order: entries.length,
          entry: WordLookupEntry(
            id: source.id,
            target: pair.target,
            source: pair.source,
            lessonIndex: source.lessonIndex,
          ),
          keys: keys,
          sameAs:
              '${keys.join(' ')}\u0000'
              '${WordLookupText.keys(pair.source).join(' ')}',
        ),
      );
    }
    return WordLookupIndex._(entries, articles);
  }

  static final WordLookupIndex empty = WordLookupIndex._(const [], const {});

  /// Rule 3 skips a word found in the target sides of more entries than this
  /// (il, la, the): no per-language list of common words is needed.
  static const int commonWordLimit = 3;

  static const int _cacheSize = 256;

  final List<_IndexedEntry> _entries;
  final Set<String> _articles;
  final Map<WordLookupEntry, _IndexedEntry> _indexed = Map.identity();
  final Map<String, List<_IndexedEntry>> _byFirstKey = {};
  final Map<String, List<_IndexedEntry>> _byKey = {};
  final Map<String, int> _frequency = {};
  final Map<String, WordLookupAnalysis> _cache = {};

  bool get isEmpty => _entries.isEmpty;

  /// An article, or a word found in more than [commonWordLimit] distinct
  /// entries.
  bool _isCommon(String key) =>
      _articles.contains(key) || (_frequency[key] ?? 0) > commonWordLimit;

  int get length => _entries.length;

  List<WordLookupEntry> get entries => [
    for (final entry in _entries) entry.entry,
  ];

  /// The analysis of [text] for a learner in the Lesson at
  /// [currentLessonIndex]; the last results are kept, so a text is read once.
  WordLookupAnalysis analyze(String text, {required int currentLessonIndex}) {
    final key = '$currentLessonIndex\u0000$text';
    final cached = _cache.remove(key);
    if (cached != null) return _cache[key] = cached;
    if (_cache.length >= _cacheSize) _cache.remove(_cache.keys.first);
    return _cache[key] = WordLookupAnalysis._(this, text, currentLessonIndex);
  }

  /// What a tap at [offset] of [text] finds, or null.
  WordLookupResult? resultAt(
    String text,
    int offset, {
    required int currentLessonIndex,
  }) => analyze(text, currentLessonIndex: currentLessonIndex).resultAt(offset);
}

/// One text read against a [WordLookupIndex].
class WordLookupAnalysis {
  WordLookupAnalysis._(this._index, this.text, this.currentLessonIndex)
    : _tokens = WordLookupText.tokenize(text) {
    _bare = [for (var i = 0; i < _tokens.length; i++) _bareKeyOf(i)];
    _findOccurrences();
    _findGroups();
  }

  final WordLookupIndex _index;
  final String text;
  final int currentLessonIndex;
  final List<WordLookupToken> _tokens;
  final List<_Occurrence> _occurrences = [];

  /// Per word: its key without the final apostrophe when no word follows
  /// it (‘gatto’, `po'`), else null. Tried only after the key as written.
  late final List<String?> _bare;

  String? _bareKeyOf(int i) {
    final token = _tokens[i];
    if (token.gap || token.spaceless || !token.elided) return null;
    if (token.key.length < 2) return null;
    if (i + 1 < _tokens.length && _tokens[i + 1].start == token.end) {
      return null;
    }
    return token.key.substring(0, token.key.length - 1);
  }

  /// Runs of tokens joined by elision apostrophes (`l'` + `acqua`); every
  /// other token stands alone. Gaps belong to no group.
  final List<List<int>> _groups = [];
  final Map<int, int> _groupOfToken = {};
  final Map<int, WordLookupResult?> _groupResults = {};

  void _findOccurrences() {
    for (var first = 0; first < _tokens.length; first++) {
      final token = _tokens[first];
      if (token.gap) continue;
      final bare = _bare[first];
      final candidates = <_IndexedEntry>{
        ...?_index._byFirstKey[token.key],
        if (bare != null) ...?_index._byFirstKey[bare],
      };
      for (final entry in candidates) {
        final loose = _matchesAt(entry.keys, first);
        if (loose == null) continue;
        _occurrences.add(
          _Occurrence(entry, first, entry.keys.length, loose: loose),
        );
      }
    }
  }

  /// Null when [keys] do not match from [first]; otherwise whether a word
  /// matched only without its final apostrophe.
  bool? _matchesAt(List<String> keys, int first) {
    if (first + keys.length > _tokens.length) return null;
    var loose = false;
    for (var i = 0; i < keys.length; i++) {
      final token = _tokens[first + i];
      if (token.gap) return null;
      if (token.key == keys[i]) continue;
      if (_bare[first + i] != keys[i]) return null;
      loose = true;
    }
    return loose;
  }

  void _findGroups() {
    for (var i = 0; i < _tokens.length; i++) {
      final token = _tokens[i];
      if (token.gap) continue;
      final previous = i > 0 ? _tokens[i - 1] : null;
      final joined =
          previous != null &&
          !previous.gap &&
          !previous.spaceless &&
          !token.spaceless &&
          previous.elided &&
          previous.end == token.start;
      if (joined && _groupOfToken.containsKey(i - 1)) {
        _groups.last.add(i);
      } else {
        _groups.add([i]);
      }
      _groupOfToken[i] = _groups.length - 1;
    }
  }

  /// What a tap at the UTF-16 [offset] finds, or null (nothing happens).
  WordLookupResult? resultAt(int offset) {
    for (var i = 0; i < _tokens.length; i++) {
      final token = _tokens[i];
      if (offset < token.start || offset >= token.end) continue;
      final group = _groupOfToken[i];
      return group == null ? null : _resultForGroup(group);
    }
    return null;
  }

  /// The spans where a tap finds something: the dotted marks and the hand
  /// cursor's places.
  late final List<WordLookupRange> tappableRanges = List.unmodifiable([
    for (var group = 0; group < _groups.length; group++)
      if (_resultForGroup(group) case final result?)
        _markedRange(group, result),
  ]);

  /// The word's own span, without a closing quote mark its result left out.
  WordLookupRange _markedRange(int group, WordLookupResult result) {
    final word = _groupRange(group);
    return WordLookupRange(
      word.start,
      result.range.end < word.end ? result.range.end : word.end,
    );
  }

  /// Every entry the text's words find, in text order, identical ones once
  /// (the keyboard and screen-reader list).
  List<WordLookupEntry> get allEntries {
    final seen = <String>{};
    final found = <WordLookupEntry>[];
    for (var group = 0; group < _groups.length; group++) {
      final result = _resultForGroup(group);
      if (result == null) continue;
      for (final entry in result.entries) {
        if (seen.add(_sameAsOf(entry))) found.add(entry);
      }
    }
    return found;
  }

  String _sameAsOf(WordLookupEntry entry) => _index._indexed[entry]!.sameAs;

  WordLookupRange _groupRange(int group) {
    final tokens = _groups[group];
    return WordLookupRange(
      _tokens[tokens.first].start,
      _tokens[tokens.last].end,
    );
  }

  WordLookupResult? _resultForGroup(int group) {
    if (_groupResults.containsKey(group)) return _groupResults[group];
    return _groupResults[group] = _lookUpGroup(group);
  }

  WordLookupResult? _lookUpGroup(int group) {
    final tokens = _groups[group];
    final whole = _longestCovering(tokens.first, tokens.last);
    if (whole.isNotEmpty) {
      return WordLookupResult(
        entries: _choose(whole.map((occurrence) => occurrence.entry)),
        range: _span(whole),
      );
    }
    if (tokens.length == 1) {
      final inside = _insideExpressions(tokens.single);
      if (inside == null) return null;
      return WordLookupResult(
        entries: _choose(inside.entries),
        range: inside.range,
      );
    }
    // The pieces of an apostrophe word, each looked up alone.
    final seen = <String>{};
    final entries = <WordLookupEntry>[];
    final spans = <_Occurrence>[];
    for (final piece in tokens) {
      final found = _longestCovering(piece, piece);
      final Iterable<_IndexedEntry> candidates;
      if (found.isNotEmpty) {
        spans.addAll(found);
        candidates = found.map((occurrence) => occurrence.entry);
      } else {
        // Build 265 Revision 4: rule 3 too, so `acqua` in `d'acqua` shows
        // `l'acqua` as `acqua` alone does.
        candidates = _insideExpressions(piece)?.entries ?? const [];
      }
      for (final entry in _choose(candidates)) {
        if (seen.add(_sameAsOf(entry))) entries.add(entry);
      }
    }
    if (entries.isEmpty) return null;
    final word = _groupRange(group);
    if (spans.isEmpty) return WordLookupResult(entries: entries, range: word);
    final range = _span(spans);
    return WordLookupResult(
      entries: entries,
      range: WordLookupRange(
        range.start < word.start ? range.start : word.start,
        range.end > word.end ? range.end : word.end,
      ),
    );
  }

  /// Rule 3 for the word at [index]: the entries of two or more words that
  /// contain it, every other word an article or a common word, and the
  /// span to highlight. Tried as written, then without a closing quote
  /// mark. Never for an article, a common word or a spaceless character.
  ({List<_IndexedEntry> entries, WordLookupRange range})? _insideExpressions(
    int index,
  ) {
    final token = _tokens[index];
    if (token.spaceless) return null;
    final bare = _bare[index];
    for (final key in [token.key, ?bare]) {
      if (_index._isCommon(key)) return null;
      final inside = [
        for (final entry in _index._byKey[key] ?? const <_IndexedEntry>[])
          if (entry.keys.length > 1 &&
              entry.keys.every((k) => k == key || _index._isCommon(k)))
            entry,
      ];
      if (inside.isNotEmpty) {
        return (
          entries: inside,
          range: WordLookupRange(
            token.start,
            key == token.key ? token.end : token.end - 1,
          ),
        );
      }
    }
    return null;
  }

  /// The longest occurrences covering every token from [first] to [last].
  List<_Occurrence> _longestCovering(int first, int last) {
    var longest = 0;
    final found = <_Occurrence>[];
    for (final occurrence in _occurrences) {
      if (!occurrence.covers(first) || !occurrence.covers(last)) continue;
      if (occurrence.length > longest) {
        longest = occurrence.length;
        found.clear();
      }
      if (occurrence.length == longest) found.add(occurrence);
    }
    // A word as written wins over the same word read without a closing
    // quote mark: `di'` (say) before `di` (of).
    if (found.any((occurrence) => !occurrence.loose)) {
      found.removeWhere((occurrence) => occurrence.loose);
    }
    return found;
  }

  WordLookupRange _span(List<_Occurrence> occurrences) {
    var start = text.length;
    var end = 0;
    for (final occurrence in occurrences) {
      final first = _tokens[occurrence.first].start;
      final lastToken = _tokens[occurrence.last];
      // A closing quote mark is not highlighted.
      final last = lastToken.key == occurrence.entry.keys.last
          ? lastToken.end
          : lastToken.end - 1;
      if (first < start) start = first;
      if (last > end) end = last;
    }
    return WordLookupRange(start, end);
  }

  /// The Lesson rule: the current Lesson's entries when it has any, else
  /// every Lesson's in Course order; identical entries once.
  List<WordLookupEntry> _choose(Iterable<_IndexedEntry> candidates) {
    final ordered = {...candidates}.toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    final current = [
      for (final entry in ordered)
        if (entry.entry.lessonIndex == currentLessonIndex) entry,
    ];
    final seen = <String>{};
    return [
      for (final entry in current.isNotEmpty ? current : ordered)
        if (seen.add(entry.sameAs)) entry.entry,
    ];
  }
}
