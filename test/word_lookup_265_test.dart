import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/word_lookup/word_lookup.dart';
import 'package:quisquislingo_app/services/word_lookup/word_lookup_articles.dart';
import 'package:quisquislingo_app/services/word_lookup/word_lookup_text.dart';

/// Build 265 Revision 0: the Word Lookup rules of
/// `docs/265_WORD_LOOKUP_PLAN.md`, one test per example of the plan.
/// Revision 3: the third rule passes over articles only.
void main() {
  WordLookupIndex index(List<(String, int)> lines, {String? language = 'it'}) =>
      WordLookupIndex.build([
        for (var i = 0; i < lines.length; i++)
          WordLookupSourceEntry(
            id: 'entry-$i',
            text: lines[i].$1,
            lessonIndex: lines[i].$2,
          ),
      ], articles: WordLookupArticles.forLanguage(language));

  int offsetOf(String text, String word, int occurrence) {
    var at = -1;
    for (var i = 0; i <= occurrence; i++) {
      at = text.indexOf(word, at + 1);
      if (at < 0) throw StateError('"$word" not in "$text"');
    }
    return at;
  }

  /// The entries a tap on [word] (its first character, or [shift] further)
  /// shows, written `target = source`.
  List<String> tap(
    WordLookupIndex index,
    String text,
    String word, {
    int lesson = 0,
    int occurrence = 0,
    int shift = 0,
  }) {
    final result = index.resultAt(
      text,
      offsetOf(text, word, occurrence) + shift,
      currentLessonIndex: lesson,
    );
    return [
      for (final entry in result?.entries ?? const <WordLookupEntry>[])
        '${entry.target} = ${entry.source}',
    ];
  }

  String highlighted(WordLookupIndex index, String text, String word) {
    final result = index.resultAt(
      text,
      text.indexOf(word),
      currentLessonIndex: 0,
    )!;
    return text.substring(result.range.start, result.range.end);
  }

  group('words', () {
    test('small letters, no punctuation, accents kept, ’ read as \'', () {
      expect(WordLookupText.keys('Come stai?'), ['come', 'stai']);
      expect(WordLookupText.keys('Bene, grazie.'), ['bene', 'grazie']);
      expect(WordLookupText.keys('Papà È'), ['papà', 'è']);
      expect(WordLookupText.keys('L’acqua'), ["l'", 'acqua']);
      expect(WordLookupText.keys("dell'uovo"), ["dell'", 'uovo']);
      expect(WordLookupText.keys('self-service'), ['self-service']);
      expect(WordLookupText.keys('A - B'), ['a', 'b']);
      // Composed and decomposed accents are one key.
      expect(WordLookupText.keys('è'), WordLookupText.keys('è'));
    });

    test('a word holding _ is a gap', () {
      final tokens = WordLookupText.tokenize('Il ___ dorme, dr_ink_.');
      expect(
        [for (final token in tokens) token.gap],
        [false, true, false, true],
      );
    });

    test('offsets point into the original text', () {
      const text = "Bevo l'acqua!";
      final tokens = WordLookupText.tokenize(text);
      expect(
        [for (final token in tokens) text.substring(token.start, token.end)],
        ['Bevo', "l'", 'acqua'],
      );
    });

    test('scripts without spaces split into characters', () {
      final chinese = WordLookupText.tokenize('我的猫');
      expect([for (final token in chinese) token.key], ['我', '的', '猫']);
      expect(chinese.every((token) => token.spaceless), isTrue);
      // A Thai letter keeps its vowel and tone marks.
      expect(WordLookupText.keys('ข้าว'), ['ข้', 'า', 'ว']);
      // The Katakana long-vowel mark belongs to the run.
      expect(WordLookupText.keys('コーヒー'), ['コ', 'ー', 'ヒ', 'ー']);
      expect(WordLookupText.keys('我的iPhone。'), ['我', '的', 'iphone']);
    });
  });

  group('expressions', () {
    final vocabulary = index([
      ('il pane', 0),
      ('pane = bread', 0),
      ('il pane = the bread', 0),
      ('mangio = I eat', 0),
    ]);

    test('the whole expression wins over the single word', () {
      const text = 'Mangio il pane.';
      expect(tap(vocabulary, text, 'pane'), ['il pane = the bread']);
      expect(tap(vocabulary, text, 'il'), ['il pane = the bread']);
      expect(tap(vocabulary, text, 'pane', shift: 3), ['il pane = the bread']);
      expect(highlighted(vocabulary, text, 'pane'), 'il pane');
      expect(tap(vocabulary, text, 'Mangio'), ['mangio = I eat']);
    });

    test('capitals do not count', () {
      expect(tap(vocabulary, 'IL PANE', 'PANE'), ['il pane = the bread']);
    });

    test('a line that is not an entry is skipped', () {
      expect(vocabulary.length, 3);
    });

    test('length is counted in words, not letters', () {
      final words = index([
        ('panettone = Christmas cake', 0),
        ('il pane = the bread', 0),
      ]);
      // Two short words beat one long word: only the expression covers both.
      expect(tap(words, 'il pane', 'pane'), ['il pane = the bread']);
      final tie = index([
        ('il pane = the bread', 0),
        ('pane fresco = fresh bread', 1),
      ]);
      const text = 'il pane fresco';
      // A tie of two words each: the Lesson rule, then both.
      expect(tap(tie, text, 'pane'), ['il pane = the bread']);
      expect(tap(tie, text, 'pane', lesson: 1), ['pane fresco = fresh bread']);
      expect(tap(tie, text, 'pane', lesson: 2), [
        'il pane = the bread',
        'pane fresco = fresh bread',
      ]);
      expect(tap(tie, text, 'il', lesson: 1), ['il pane = the bread']);
      expect(tap(tie, text, 'fresco'), ['pane fresco = fresh bread']);
    });

    test('a three-word expression beats two-word ones', () {
      final three = index([
        ('il pane = the bread', 0),
        ('pane fresco = fresh bread', 0),
        ('il pane fresco = the fresh bread', 2),
      ]);
      expect(tap(three, 'Ecco il pane fresco.', 'pane'), [
        'il pane fresco = the fresh bread',
      ]);
    });
  });

  group('apostrophes', () {
    test("l'acqua as an entry wins over acqua", () {
      final vocabulary = index([
        ("l' = the", 0),
        ('acqua = water', 0),
        ("l'acqua = the water", 0),
      ]);
      const text = "Bevo l'acqua.";
      expect(tap(vocabulary, text, 'acqua'), ["l'acqua = the water"]);
      expect(tap(vocabulary, text, "l'"), ["l'acqua = the water"]);
      expect(tap(vocabulary, 'Bevo l’acqua.', 'acqua'), [
        "l'acqua = the water",
      ]);
      expect(highlighted(vocabulary, text, 'acqua'), "l'acqua");
    });

    test("without l'acqua, l' and acqua are shown together", () {
      final vocabulary = index([("l' = the", 0), ('acqua = water', 0)]);
      const text = "Bevo l'acqua.";
      expect(tap(vocabulary, text, 'acqua'), ["l' = the", 'acqua = water']);
      expect(tap(vocabulary, text, "l'"), ["l' = the", 'acqua = water']);
      expect(highlighted(vocabulary, text, 'acqua'), "l'acqua");
      final onlyWater = index([('acqua = water', 0)]);
      expect(tap(onlyWater, text, "l'"), ['acqua = water']);
    });

    test('a piece never borrows an expression of other words', () {
      final vocabulary = index([("it's ten o'clock = sono le dieci", 0)]);
      expect(tap(vocabulary, "Tom's book", 'Tom'), isEmpty);
      expect(tap(vocabulary, "Tom's book", 's book'), isEmpty);
      expect(tap(vocabulary, "Yes, it's ten o'clock.", 'ten'), [
        "it's ten o'clock = sono le dieci",
      ]);
      expect(tap(vocabulary, "Yes, it's ten o'clock.", 'it'), [
        "it's ten o'clock = sono le dieci",
      ]);
    });

    test("you're welcome matches across the apostrophe", () {
      final vocabulary = index([("you're welcome = prego", 0)]);
      const text = 'Thanks! You’re welcome!';
      expect(tap(vocabulary, text, 'You'), ["you're welcome = prego"]);
      expect(tap(vocabulary, text, 'welcome'), ["you're welcome = prego"]);
    });

    // Build 265 Revision 4: a piece uses the third rule too, so `acqua`
    // after `d'` or `dell'` shows `l'acqua` as `acqua` alone does.
    test("a piece finds an expression beside articles: d'acqua", () {
      final vocabulary = index([
        ("l'acqua = water", 0),
        ("l'amica = the friend", 0),
      ]);
      const glass = "Bevo un bicchiere d'acqua.";
      expect(tap(vocabulary, glass, 'acqua'), ["l'acqua = water"]);
      expect(tap(vocabulary, glass, "d'"), ["l'acqua = water"]);
      expect(highlighted(vocabulary, glass, "d'acqua"), "d'acqua");
      expect(tap(vocabulary, "Il colore dell'acqua.", 'acqua'), [
        "l'acqua = water",
      ]);
      expect(tap(vocabulary, "Ho un'amica.", 'amica'), [
        "l'amica = the friend",
      ]);
      expect(tap(vocabulary, 'Acqua!', 'Acqua'), ["l'acqua = water"]);
    });
  });

  // Build 265 Revision 4: an apostrophe that closes a quotation is not part
  // of the word, while po' and di' keep theirs.
  group('quotation marks', () {
    test('a quoted word is found without its closing quote mark', () {
      final vocabulary = index([('il gatto = the cat', 0), ('sole = sun', 0)]);
      for (final text in ['Select ‘gatto’.', "Select 'gatto'."]) {
        expect(tap(vocabulary, text, 'gatto'), ['il gatto = the cat']);
        expect(highlighted(vocabulary, text, 'gatto'), 'gatto');
      }
      expect(tap(vocabulary, 'Select ‘sole’!', 'sole'), ['sole = sun']);
      expect(highlighted(vocabulary, 'Select ‘sole’!', 'sole'), 'sole');
      const quoted = '‘Il gatto’ dorme.';
      expect(tap(vocabulary, quoted, 'gatto'), ['il gatto = the cat']);
      expect(highlighted(vocabulary, quoted, 'Il'), 'Il gatto');
    });

    test('the word as written wins: di\', po\'', () {
      final vocabulary = index([
        ("di' = say!", 0),
        ('di = of', 0),
        ("un po' = a bit", 0),
      ]);
      expect(tap(vocabulary, "Di' la verità.", "Di'"), ["di' = say!"]);
      expect(tap(vocabulary, 'Un bicchiere di vino.', 'di'), ['di = of']);
      expect(tap(vocabulary, "Ne voglio un po'.", 'po'), ["un po' = a bit"]);
    });

    test('the dotted marks leave the closing quote mark out', () {
      final vocabulary = index([('il gatto = the cat', 0)]);
      const text = 'Select ‘gatto’.';
      final ranges = vocabulary
          .analyze(text, currentLessonIndex: 0)
          .tappableRanges;
      expect(
        [for (final r in ranges) text.substring(r.start, r.end)],
        ['gatto'],
      );
    });
  });

  group('accents', () {
    final vocabulary = index([('papà = dad', 0), ('è = is', 0)]);

    test('papa is not papà, e is not è', () {
      expect(tap(vocabulary, 'Il papa', 'papa'), isEmpty);
      expect(tap(vocabulary, 'Papà è qui', 'Papà'), ['papà = dad']);
      expect(tap(vocabulary, 'Papà è qui', 'è'), ['è = is']);
      expect(tap(vocabulary, 'Tom e Anna', 'e'), isEmpty);
      expect(tap(vocabulary, 'Papè', 'e'), isEmpty);
      expect(tap(vocabulary, 'Lei è qui', 'e', occurrence: 1), ['è = is']);
    });
  });

  group('a word inside an expression', () {
    test('gatto finds il gatto', () {
      final vocabulary = index([('il gatto = the cat', 0)]);
      expect(tap(vocabulary, 'Ho un gatto.', 'gatto'), ['il gatto = the cat']);
      expect(tap(vocabulary, 'Ho un gatto.', 'un'), isEmpty);
      expect(highlighted(vocabulary, 'Ho un gatto.', 'gatto'), 'gatto');
    });

    test('a word in more than three entries is too common', () {
      final four = index([
        ('il pane = the bread', 0),
        ('il latte = the milk', 0),
        ('il gatto = the cat', 0),
        ('il cane = the dog', 0),
        ('the bread = il pane', 1),
      ], language: null);
      expect(tap(four, 'Vedo il sole.', 'il'), isEmpty);
      // Without an article list, il is common in four entries: pane, alone
      // in the text, finds il pane through it.
      expect(tap(four, 'Mangio pane.', 'pane'), ['il pane = the bread']);
    });

    test('an article alone finds nothing', () {
      final three = index([
        ('il pane = the bread', 0),
        ('il latte = the milk', 0),
        ('il gatto = the cat', 0),
      ]);
      expect(tap(three, 'Vedo il sole.', 'il'), isEmpty);
    });

    test('only articles may stand beside the word (owner decision)', () {
      final vocabulary = index([
        ("dov'è = where is", 0),
        ("l'acqua = water", 0),
        ('il caffè = coffee', 0),
        ('un caffè = a coffee', 0),
        ('il suo caffè = your coffee', 0),
      ]);
      expect(tap(vocabulary, 'Roma è bella.', 'è'), isEmpty);
      expect(tap(vocabulary, 'Bevo acqua.', 'acqua'), ["l'acqua = water"]);
      expect(tap(vocabulary, 'Bevo caffè.', 'caffè'), [
        'il caffè = coffee',
        'un caffè = a coffee',
      ]);
    });

    test('an idiom shows only where the text uses it (owner example)', () {
      const idiom = 'una lavata da gatto = a quick wash';
      final vocabulary = index([('il gatto = the cat', 0), (idiom, 0)]);
      expect(tap(vocabulary, 'Il gatto dorme.', 'gatto'), [
        'il gatto = the cat',
      ]);
      expect(tap(vocabulary, 'Ho un gatto.', 'gatto'), ['il gatto = the cat']);
      const text = 'Stamattina mi sono dato una lavata da gatto.';
      expect(tap(vocabulary, text, 'gatto'), [idiom]);
      expect(tap(vocabulary, text, 'lavata'), [idiom]);
    });

    test('the learning language decides the articles', () {
      final english = index([
        ('the train = il treno', 0),
        ('the platform = il binario', 0),
      ], language: 'en-GB');
      expect(tap(english, 'It is on platform two.', 'platform'), [
        'the platform = il binario',
      ]);
      final unknown = index([('the train = il treno', 0)], language: 'xx');
      expect(tap(unknown, 'By train.', 'train'), isEmpty);
    });

    test('identical entries count once as common words', () {
      final repeated = index([
        ('ka pane = bread', 0),
        ('ka pane = bread', 1),
        ('ka pane = bread', 2),
        ('ka pane = bread', 3),
      ], language: null);
      expect(tap(repeated, 'pane', 'pane'), isEmpty);
      final distinct = index([
        ('ka pane = bread', 0),
        ('ka latte = milk', 0),
        ('ka gatto = cat', 0),
        ('ka cane = dog', 0),
      ], language: null);
      expect(tap(distinct, 'pane', 'pane'), ['ka pane = bread']);
    });
  });

  group('Lessons', () {
    test(
      'the current Lesson wins; otherwise every Lesson, in Course order',
      () {
        final vocabulary = index([('pane = bread', 1), ('pane = loaf', 0)]);
        expect(tap(vocabulary, 'pane', 'pane'), ['pane = loaf']);
        expect(tap(vocabulary, 'pane', 'pane', lesson: 1), ['pane = bread']);
        expect(tap(vocabulary, 'pane', 'pane', lesson: 2), [
          'pane = bread',
          'pane = loaf',
        ]);
      },
    );

    test('an expression of another Lesson beats a word of this one', () {
      final vocabulary = index([
        ('pane = bread', 0),
        ('il pane = the bread', 1),
      ]);
      expect(tap(vocabulary, 'Mangio il pane', 'pane'), [
        'il pane = the bread',
      ]);
    });

    test('identical entries are shown once, from the first Lesson', () {
      final vocabulary = index([('pane = bread', 0), ('Pane = bread.', 2)]);
      final result = vocabulary.resultAt('pane', 0, currentLessonIndex: 1)!;
      expect(result.entries, hasLength(1));
      expect(result.entries.single.lessonIndex, 0);
      expect(result.entries.single.id, 'entry-0');
    });

    test('two entries of the current Lesson are both shown', () {
      final vocabulary = index([
        ('la = the', 0),
        ('la = her', 0),
        ('la = there', 1),
      ]);
      expect(tap(vocabulary, 'la casa', 'la'), ['la = the', 'la = her']);
    });
  });

  group('nothing found', () {
    final vocabulary = index([
      ('il gatto = the cat', 0),
      ('dorme = sleeps', 0),
    ]);

    test('a word without an entry, a space or punctuation finds nothing', () {
      expect(tap(vocabulary, 'Il cane dorme.', 'cane'), isEmpty);
      expect(tap(vocabulary, 'Il cane dorme.', ' '), isEmpty);
      expect(tap(vocabulary, 'Il cane dorme.', '.'), isEmpty);
      expect(
        WordLookupIndex.empty.resultAt('gatto', 0, currentLessonIndex: 0),
        isNull,
      );
    });

    test('gaps are never looked up and never joined', () {
      final gaps = index([
        ('il pane = the bread', 0),
        ('pane = bread', 0),
        ('drink = bere', 0),
      ]);
      expect(tap(gaps, 'Il ___ dorme.', '___'), isEmpty);
      expect(tap(gaps, 'I dr_ink_ water.', 'dr_'), isEmpty);
      expect(tap(gaps, 'Il ___ pane.', 'pane'), ['pane = bread']);
    });
  });

  group('scripts written without spaces', () {
    test('Chinese: the longest entry covering the character', () {
      final vocabulary = index([
        ('我 = I', 0),
        ('我的 = my', 0),
        ('猫 = cat', 0),
        ('很好 = very good', 0),
      ]);
      const text = '我的猫很可爱。';
      expect(tap(vocabulary, text, '的'), ['我的 = my']);
      expect(tap(vocabulary, text, '我'), ['我的 = my']);
      expect(tap(vocabulary, text, '猫'), ['猫 = cat']);
      // No "word inside an expression" here: 很 alone finds nothing.
      expect(tap(vocabulary, text, '很'), isEmpty);
      expect(tap(vocabulary, text, '。'), isEmpty);
    });

    test('Japanese kana and kanji', () {
      final vocabulary = index([
        ('コーヒー = coffee', 0),
        ('飲みます = drink', 0),
        ('私 = I', 0),
      ]);
      const text = '私はコーヒーを飲みます。';
      expect(tap(vocabulary, text, 'ー'), ['コーヒー = coffee']);
      expect(tap(vocabulary, text, '飲'), ['飲みます = drink']);
      expect(tap(vocabulary, text, 'み'), ['飲みます = drink']);
      expect(tap(vocabulary, text, '私'), ['私 = I']);
      expect(tap(vocabulary, text, 'は'), isEmpty);
    });

    test('Thai with combining marks', () {
      final vocabulary = index([('ข้าว = rice', 0), ('กิน = eat', 0)]);
      const text = 'ฉันกินข้าว';
      expect(tap(vocabulary, text, 'ข้าว', shift: 1), ['ข้าว = rice']);
      expect(tap(vocabulary, text, 'ว'), ['ข้าว = rice']);
      expect(tap(vocabulary, text, 'กิน'), ['กิน = eat']);
      expect(tap(vocabulary, text, 'ฉ'), isEmpty);
    });

    test('Latin words inside a Han run keep the word rules', () {
      final vocabulary = index([('iPhone = iPhone', 0), ('我的 = my', 0)]);
      const text = '我的iPhone很好';
      expect(tap(vocabulary, text, 'Phone'), ['iPhone = iPhone']);
      expect(tap(vocabulary, text, '的'), ['我的 = my']);
    });
  });

  group('whole text', () {
    final vocabulary = index([
      ('il pane = the bread', 0),
      ('pane = bread', 0),
      ("l'acqua = the water", 0),
    ]);
    const text = "Mangio il pane e bevo l'acqua; il pane è buono.";

    test('tappable ranges are the words that find something', () {
      final analysis = vocabulary.analyze(text, currentLessonIndex: 0);
      expect(
        [
          for (final range in analysis.tappableRanges)
            text.substring(range.start, range.end),
        ],
        ['il', 'pane', "l'acqua", 'il', 'pane'],
      );
    });

    test('every entry found, in text order, once', () {
      final analysis = vocabulary.analyze(text, currentLessonIndex: 0);
      expect(
        [for (final entry in analysis.allEntries) entry.target],
        ['il pane', "l'acqua"],
      );
    });

    test('a text is read once per Lesson', () {
      final first = vocabulary.analyze(text, currentLessonIndex: 0);
      expect(
        identical(vocabulary.analyze(text, currentLessonIndex: 0), first),
        isTrue,
      );
      expect(
        identical(vocabulary.analyze(text, currentLessonIndex: 1), first),
        isFalse,
      );
    });
  });
}
