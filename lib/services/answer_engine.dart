class AnswerExpressionException implements Exception {
  const AnswerExpressionException(this.message);
  final String message;

  @override
  String toString() => message;
}

abstract final class AnswerExpressionParser {
  static const int expansionLimit = 128;

  static List<String> expand(String expression) {
    final source = expression.trim();
    if (source.isEmpty) {
      throw const AnswerExpressionException(
        'An answer expression cannot be empty.',
      );
    }
    _validateBalance(source);
    var variants = <String>[source];
    variants = _expandDelimited(variants, '{', '}', optional: true);
    variants = _expandLinkedAlternatives(variants);
    variants = _expandDelimited(variants, '[', ']', optional: false);
    variants = _expandReorders(variants);
    return _deduplicate(
      variants,
      normalizeCapitalization:
          source.contains('{') || source.contains('[') || source.contains('<>'),
    );
  }

  static List<String> expandAll(Iterable<String> expressions) {
    final result = <String>[];
    for (final expression in expressions) {
      result.addAll(expand(expression));
      _checkLimit(result.length);
    }
    return _deduplicate(result);
  }

  static void _validateBalance(String source) {
    const pairs = {'{': '}', '[': ']', '(': ')'};
    final stack = <String>[];
    for (var i = 0; i < source.length; i++) {
      final char = source[i];
      if (pairs.containsKey(char)) {
        stack.add(char);
      } else if (pairs.containsValue(char)) {
        if (stack.isEmpty || pairs[stack.removeLast()] != char) {
          throw AnswerExpressionException(
            'Malformed answer syntax near “$char”.',
          );
        }
      }
    }
    if (stack.isNotEmpty) {
      throw AnswerExpressionException(
        'Unclosed “${stack.last}” in answer expression.',
      );
    }
    if (source.contains('<') != source.contains('>')) {
      throw const AnswerExpressionException(
        'Reorder syntax must use the complete <> separator.',
      );
    }
    if (source.replaceAll('<>', '').contains('<') ||
        source.replaceAll('<>', '').contains('>')) {
      throw const AnswerExpressionException(
        'Malformed reorder separator; use <> between phrase parts.',
      );
    }
  }

  static List<String> _expandDelimited(
    List<String> input,
    String open,
    String close, {
    required bool optional,
  }) {
    var current = input;
    while (current.any((value) => value.contains(open))) {
      final next = <String>[];
      for (final value in current) {
        final start = value.indexOf(open);
        if (start < 0) {
          next.add(value);
          continue;
        }
        final end = _matchingClose(value, start, open, close);
        final before = value.substring(0, start);
        final body = value.substring(start + 1, end);
        final after = value.substring(end + 1);
        if (body.trim().isEmpty) {
          throw AnswerExpressionException(
            optional
                ? 'Optional text cannot be empty.'
                : 'Alternatives cannot be empty.',
          );
        }
        if (optional) {
          next
            ..add('$before$after')
            ..add('$before$body$after');
        } else {
          final alternatives = body
              .split('|')
              .map((part) => part.trim())
              .toList();
          if (alternatives.length < 2 ||
              alternatives.any((part) => part.isEmpty)) {
            throw const AnswerExpressionException(
              'Alternatives must contain at least two non-empty values separated by |.',
            );
          }
          for (final alternative in alternatives) {
            next.add('$before$alternative$after');
          }
        }
        _checkLimit(next.length);
      }
      current = next;
    }
    return current;
  }

  static List<String> _expandLinkedAlternatives(List<String> input) {
    final output = <String>[];
    final linkedPattern = RegExp(r'\[\*:(.*?)\]');
    for (final value in input) {
      if (RegExp(r'\[g:').hasMatch(value)) {
        throw const AnswerExpressionException(
          'Grouped alternatives use *:, not g:.',
        );
      }
      final matches = linkedPattern.allMatches(value).toList();
      if (matches.isEmpty) {
        output.add(value);
        continue;
      }
      if (matches.length < 2) {
        throw const AnswerExpressionException(
          'Linked *: alternatives require at least two groups.',
        );
      }
      final groups = <List<String>>[];
      for (final match in matches) {
        final alternatives = match
            .group(1)!
            .split('|')
            .map((part) => part.trim())
            .toList();
        if (alternatives.length < 2 ||
            alternatives.any((part) => part.isEmpty)) {
          throw const AnswerExpressionException(
            'Each linked *: group needs at least two non-empty alternatives.',
          );
        }
        groups.add(alternatives);
      }
      final cardinality = groups.first.length;
      if (groups.any((group) => group.length != cardinality)) {
        throw const AnswerExpressionException(
          'Linked *: groups must contain the same number of alternatives.',
        );
      }
      for (
        var alternativeIndex = 0;
        alternativeIndex < cardinality;
        alternativeIndex++
      ) {
        var expanded = value;
        for (
          var groupIndex = matches.length - 1;
          groupIndex >= 0;
          groupIndex--
        ) {
          final match = matches[groupIndex];
          expanded = expanded.replaceRange(
            match.start,
            match.end,
            groups[groupIndex][alternativeIndex],
          );
        }
        output.add(expanded);
        _checkLimit(output.length);
      }
    }
    return output;
  }

  static int _matchingClose(
    String value,
    int start,
    String open,
    String close,
  ) {
    var depth = 0;
    for (var i = start; i < value.length; i++) {
      if (value[i] == open) depth++;
      if (value[i] == close) {
        depth--;
        if (depth == 0) return i;
      }
    }
    throw AnswerExpressionException('Unclosed “$open” in answer expression.');
  }

  static List<String> _expandReorders(List<String> input) {
    var current = input;
    while (current.any((value) => value.contains('('))) {
      final next = <String>[];
      for (final value in current) {
        final end = value.indexOf(')');
        if (end < 0) {
          throw const AnswerExpressionException('Unclosed reorder scope.');
        }
        final start = value.lastIndexOf('(', end);
        final body = value.substring(start + 1, end);
        if (!body.contains('<>')) {
          throw const AnswerExpressionException(
            'Parentheses in an answer expression must delimit a <> reorder scope.',
          );
        }
        final before = value.substring(0, start);
        final after = value.substring(end + 1);
        for (final reordered in _reorder(body)) {
          next.add('$before$reordered$after');
          _checkLimit(next.length);
        }
      }
      current = next;
    }
    final out = <String>[];
    for (final value in current) {
      if (value.contains('<>')) {
        out.addAll(_reorder(value));
      } else {
        out.add(value);
      }
      _checkLimit(out.length);
    }
    return out;
  }

  static List<String> _reorder(String body) {
    final trimmed = body.trim();
    final terminal = RegExp(r'([.!?…]+)$').firstMatch(trimmed);
    final punctuation = terminal?.group(1) ?? '';
    final reorderBody = punctuation.isEmpty
        ? trimmed
        : trimmed.substring(0, terminal!.start).trimRight();
    final parts = reorderBody.split('<>').map((part) => part.trim()).toList();
    if (parts.length < 2 || parts.any((part) => part.isEmpty)) {
      throw const AnswerExpressionException(
        'Reorder syntax requires non-empty phrase parts on both sides of <>.',
      );
    }
    final output = <String>[];
    void visit(List<_ReorderPart> prefix, List<_ReorderPart> remaining) {
      if (remaining.isEmpty) {
        final text = <String>[];
        for (var i = 0; i < prefix.length; i++) {
          final part = prefix[i];
          text.add(
            part.originalIndex == 0 && i > 0
                ? _decapitalizeMovedStart(part.text)
                : part.text,
          );
        }
        output.add('${text.join(' ')}$punctuation');
        _checkLimit(output.length);
        return;
      }
      for (var i = 0; i < remaining.length; i++) {
        visit(
          [...prefix, remaining[i]],
          [...remaining.take(i), ...remaining.skip(i + 1)],
        );
      }
    }

    visit(const [], [
      for (var i = 0; i < parts.length; i++)
        _ReorderPart(text: parts[i], originalIndex: i),
    ]);
    return output;
  }

  static String _decapitalizeMovedStart(String value) {
    final match = RegExp(r'\p{L}+', unicode: true).firstMatch(value);
    if (match == null) return value;
    final word = match.group(0)!;
    if (word.length > 1 && word == word.toUpperCase()) return value;
    const structuralStarters = {
      'a',
      'an',
      'the',
      'i',
      'you',
      'he',
      'she',
      'we',
      'they',
      'io',
      'tu',
      'voi',
      'noi',
      'lui',
      'lei',
      'il',
      'la',
      'un',
      'una',
      'el',
      'los',
      'las',
      'der',
      'die',
      'das',
      'de',
      'het',
      'o',
      'os',
      'as',
      'um',
      'uma',
    };
    if (!structuralStarters.contains(word.toLowerCase())) return value;
    return value.replaceRange(
      match.start,
      match.start + 1,
      word[0].toLowerCase(),
    );
  }

  static String _normalizeSentenceCapitalization(String value) {
    final chars = value.split('');
    var capitalizeNext = true;
    for (var i = 0; i < chars.length; i++) {
      final char = chars[i];
      if (RegExp(r'\p{L}', unicode: true).hasMatch(char)) {
        if (capitalizeNext) chars[i] = char.toUpperCase();
        capitalizeNext = false;
      } else if (const {'.', '?', '!'}.contains(char)) {
        capitalizeNext = true;
      }
    }
    return chars.join();
  }

  static List<String> _deduplicate(
    Iterable<String> input, {
    bool normalizeCapitalization = false,
  }) {
    final out = <String>[];
    final seen = <String>{};
    for (final raw in input) {
      final collapsed = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
      final value = normalizeCapitalization
          ? _normalizeSentenceCapitalization(collapsed)
          : collapsed;
      if (value.isNotEmpty && seen.add(value)) out.add(value);
    }
    _checkLimit(out.length);
    if (out.isEmpty) {
      throw const AnswerExpressionException(
        'The expression does not produce a non-empty answer.',
      );
    }
    return out;
  }

  static void _checkLimit(int count) {
    if (count > expansionLimit) {
      throw const AnswerExpressionException(
        'Answer expression expands to more than 128 variants. Split it into smaller explicit answers.',
      );
    }
  }
}

enum AcceptanceReason { exact, normalized, missingDiacritic, typo }

class AnswerEvaluationResult {
  const AnswerEvaluationResult({
    required this.isCorrect,
    this.matchedAcceptedAnswer = '',
    this.acceptanceReason,
    this.acceptedDifferences = const [],
  });

  final bool isCorrect;
  final String matchedAcceptedAnswer;
  final AcceptanceReason? acceptanceReason;
  final List<String> acceptedDifferences;
}

class AnswerEngine {
  const AnswerEngine();

  List<String> validAnswers(Iterable<String> expressions) =>
      AnswerExpressionParser.expandAll(expressions);

  bool accepts(
    String response,
    Iterable<String> expressions, {
    Map<String, dynamic> normalization = const {},
    bool typoTolerance = true,
  }) => evaluate(
    response,
    expressions,
    normalization: normalization,
    typoTolerance: typoTolerance,
  ).isCorrect;

  AnswerEvaluationResult evaluate(
    String response,
    Iterable<String> expressions, {
    Map<String, dynamic> normalization = const {},
    bool typoTolerance = true,
  }) {
    final authored = expressions.toList();
    if (authored.isEmpty) {
      return const AnswerEvaluationResult(isCorrect: false);
    }
    return _evaluateAgainstAnswers(
      response,
      validAnswers(authored),
      normalization: normalization,
      typoTolerance: typoTolerance,
    );
  }

  AnswerEvaluationResult evaluateLiteral(
    String response,
    String answer, {
    Map<String, dynamic> normalization = const {},
    bool typoTolerance = false,
  }) => _evaluateAgainstAnswers(
    response,
    [answer],
    normalization: normalization,
    typoTolerance: typoTolerance,
  );

  AnswerEvaluationResult _evaluateAgainstAnswers(
    String response,
    List<String> answers, {
    required Map<String, dynamic> normalization,
    required bool typoTolerance,
  }) {
    final typed = _normalize(response, normalization);
    if (typed.isEmpty || answers.isEmpty) {
      return const AnswerEvaluationResult(isCorrect: false);
    }
    final accepted = <({String answer, AcceptanceReason reason})>[];
    for (final answer in answers) {
      final expected = _normalize(answer, normalization);
      if (response == answer) {
        accepted.add((answer: answer, reason: AcceptanceReason.exact));
      } else if (typed == expected) {
        accepted.add((answer: answer, reason: AcceptanceReason.normalized));
      } else if (_exactOrAccentOmission(response, answer, normalization)) {
        accepted.add((
          answer: answer,
          reason: AcceptanceReason.missingDiacritic,
        ));
      } else if (typoTolerance && _boundedTypoMatch(typed, expected)) {
        accepted.add((answer: answer, reason: AcceptanceReason.typo));
      }
    }
    final best = _bestCandidate(
      response,
      accepted.isEmpty
          ? answers
          : accepted.map((candidate) => candidate.answer).toList(),
      normalization,
    );
    if (accepted.isEmpty) {
      return AnswerEvaluationResult(
        isCorrect: false,
        matchedAcceptedAnswer: best,
      );
    }
    final selected = accepted.firstWhere(
      (candidate) => candidate.answer == best,
      orElse: () => accepted.first,
    );
    return AnswerEvaluationResult(
      isCorrect: true,
      matchedAcceptedAnswer: selected.answer,
      acceptanceReason: selected.reason,
      acceptedDifferences: _acceptedDifferences(
        response,
        selected.answer,
        selected.reason,
        normalization,
      ),
    );
  }

  String bestCorrection(
    String response,
    Iterable<String> expressions, {
    Map<String, dynamic> normalization = const {},
  }) {
    final answers = validAnswers(expressions);
    return _bestCandidate(response, answers, normalization);
  }

  String _bestCandidate(
    String response,
    List<String> answers,
    Map<String, dynamic> normalization,
  ) {
    if (answers.isEmpty) return '';
    final typed = _normalize(response, normalization).split(' ');
    var best = answers.first;
    var bestScore = _correctionScore(
      typed,
      _normalize(best, normalization).split(' '),
    );
    for (final candidate in answers.skip(1)) {
      final score = _correctionScore(
        typed,
        _normalize(candidate, normalization).split(' '),
      );
      if (score > bestScore) {
        best = candidate;
        bestScore = score;
      }
    }
    return best;
  }

  List<String> _acceptedDifferences(
    String typed,
    String expected,
    AcceptanceReason reason,
    Map<String, dynamic> rules,
  ) {
    if (reason == AcceptanceReason.exact) return const [];
    if (reason == AcceptanceReason.missingDiacritic) {
      return const ['missing diacritic'];
    }
    if (reason == AcceptanceReason.typo) {
      return const ['explicitly allowed typo'];
    }
    final differences = <String>[];
    bool needs(Map<String, dynamic> stricter) =>
        _normalize(typed, stricter) != _normalize(expected, stricter);
    final effective = <String, dynamic>{...rules};
    if (rules['case'] != 'preserve' &&
        needs({...effective, 'case': 'preserve'})) {
      differences.add('capitalization');
    }
    if (rules['punctuation'] != 'preserve' &&
        needs({...effective, 'punctuation': 'preserve'})) {
      differences.add('ignored punctuation');
    }
    if (rules['whitespace'] != 'preserve' &&
        needs({...effective, 'whitespace': 'preserve'})) {
      differences.add('normalized whitespace');
    }
    if (rules['accents'] == 'ignore' &&
        needs({...effective, 'accents': 'preserve'})) {
      differences.add('ignored diacritic');
    }
    return differences;
  }

  bool _exactOrAccentOmission(
    String typed,
    String expected,
    Map<String, dynamic> rules,
  ) {
    if (_normalize(typed, rules) == _normalize(expected, rules)) return true;
    if (_hasDiacritic(typed) || rules['accents'] == 'ignore') return false;
    return _stripDiacritics(_normalize(typed, rules)) ==
        _stripDiacritics(_normalize(expected, rules));
  }

  String _normalize(String value, Map<String, dynamic> rules) {
    var result = value.replaceAll('’', "'");
    if (rules['case'] != 'preserve') result = result.toLowerCase();
    if (rules['punctuation'] != 'preserve') {
      result = result.replaceAll(RegExp(r'[.!?,;:\"“”()\[\]{}]'), ' ');
    }
    if (rules['whitespace'] != 'preserve') {
      result = result.replaceAll(RegExp(r'\s+'), ' ').trim();
    }
    if (rules['accents'] == 'ignore') result = _stripDiacritics(result);
    return result;
  }

  bool _boundedTypoMatch(String typed, String expected) {
    final a = typed.split(' ');
    final b = expected.split(' ');
    if (a.length != b.length || a.isEmpty) return false;
    const decisive = {
      'not',
      'no',
      'non',
      'ne',
      'pas',
      'nie',
      'nicht',
      'geen',
      'ei',
      'nao',
      'não',
    };
    if (!const SetEquality<String>().equals(
      a.where(decisive.contains).toSet(),
      b.where(decisive.contains).toSet(),
    )) {
      return false;
    }
    var typoCount = 0;
    for (var i = 0; i < a.length; i++) {
      if (a[i] == b[i]) continue;
      if (a[i].length < 5 ||
          b[i].length < 5 ||
          _hasDiacritic(a[i]) ||
          _hasDiacritic(b[i]) ||
          !_approvedRepeatedLetterTypo(a[i], b[i])) {
        return false;
      }
      typoCount++;
      if (typoCount > 1) return false;
    }
    return typoCount == 1;
  }

  /// The initial tolerance is intentionally narrower than generic edit
  /// distance: it covers one accidentally omitted/duplicated repeated letter
  /// but never treats a letter substitution as spelling-only. This avoids
  /// accepting common person/tense ending changes or another short word.
  bool _approvedRepeatedLetterTypo(String left, String right) {
    if ((left.length - right.length).abs() != 1) return false;
    final longer = left.length > right.length ? left : right;
    final shorter = left.length > right.length ? right : left;
    for (var i = 0; i < longer.length; i++) {
      final without = longer.substring(0, i) + longer.substring(i + 1);
      if (without != shorter) continue;
      final repeatsPrevious = i > 0 && longer[i] == longer[i - 1];
      final repeatsNext = i + 1 < longer.length && longer[i] == longer[i + 1];
      if (repeatsPrevious || repeatsNext) return true;
    }
    return false;
  }

  int _correctionScore(List<String> typed, List<String> candidate) {
    var score = 0;
    final remaining = [...candidate];
    for (final word in typed) {
      final exact = remaining.indexOf(word);
      if (exact >= 0) {
        score += 12;
        remaining.removeAt(exact);
        continue;
      }
      var near = -1;
      var bestSimilarity = 0.0;
      for (var i = 0; i < remaining.length; i++) {
        final similarity = _tokenSimilarity(word, remaining[i]);
        if (similarity > bestSimilarity) {
          bestSimilarity = similarity;
          near = i;
        }
      }
      if (near >= 0 && bestSimilarity >= .35) {
        score += (bestSimilarity * 8).round();
        remaining.removeAt(near);
      } else {
        score -= 9;
      }
    }
    score -= remaining.length * 2;
    score += _longestCommonSubsequence(typed, candidate) * 3;
    return score;
  }

  double _tokenSimilarity(String left, String right) {
    if (left == right) return 1;
    final longest = left.length > right.length ? left.length : right.length;
    if (longest == 0) return 1;
    return 1 - (_editDistance(left, right) / longest);
  }

  int _longestCommonSubsequence(List<String> a, List<String> b) {
    final row = List<int>.filled(b.length + 1, 0);
    for (final left in a) {
      var diagonal = 0;
      for (var j = 1; j <= b.length; j++) {
        final previous = row[j];
        row[j] = left == b[j - 1]
            ? diagonal + 1
            : (row[j] > row[j - 1] ? row[j] : row[j - 1]);
        diagonal = previous;
      }
    }
    return row.last;
  }

  int _editDistance(String a, String b) {
    var previous = List<int>.generate(b.length + 1, (i) => i);
    for (var i = 0; i < a.length; i++) {
      final current = <int>[i + 1];
      for (var j = 0; j < b.length; j++) {
        current.add(
          a[i] == b[j]
              ? previous[j]
              : 1 + _min3(previous[j], previous[j + 1], current[j]),
        );
      }
      previous = current;
    }
    return previous.last;
  }

  int _min3(int a, int b, int c) => a < b ? (a < c ? a : c) : (b < c ? b : c);

  bool _hasDiacritic(String value) => RegExp(r'[À-ÖØ-öø-ÿ]').hasMatch(value);

  String _stripDiacritics(String value) {
    const accents = {
      'à': 'a',
      'á': 'a',
      'â': 'a',
      'ä': 'a',
      'ã': 'a',
      'å': 'a',
      'è': 'e',
      'é': 'e',
      'ê': 'e',
      'ë': 'e',
      'ì': 'i',
      'í': 'i',
      'î': 'i',
      'ï': 'i',
      'ò': 'o',
      'ó': 'o',
      'ô': 'o',
      'ö': 'o',
      'õ': 'o',
      'ù': 'u',
      'ú': 'u',
      'û': 'u',
      'ü': 'u',
      'ç': 'c',
      'ñ': 'n',
      'ý': 'y',
      'ÿ': 'y',
      'ß': 'ss',
    };
    var result = value;
    accents.forEach((from, to) => result = result.replaceAll(from, to));
    return result;
  }
}

class _ReorderPart {
  const _ReorderPart({required this.text, required this.originalIndex});
  final String text;
  final int originalIndex;
}

/// Tiny local replacement for package:collection's SetEquality.
class SetEquality<T> {
  const SetEquality();
  bool equals(Set<T> a, Set<T> b) => a.length == b.length && a.containsAll(b);
}
