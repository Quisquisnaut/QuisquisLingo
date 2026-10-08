import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/answer_engine.dart';

void main() {
  group('answer-expression parser', () {
    test('expands optional text and alternatives deterministically', () {
      expect(
        AnswerExpressionParser.expand('{Io} [prendo|vorrei] un cappuccino'),
        [
          'Prendo un cappuccino',
          'Vorrei un cappuccino',
          'Io prendo un cappuccino',
          'Io vorrei un cappuccino',
        ],
      );
    });

    test('reorders only declared scoped phrase parts', () {
      expect(AnswerExpressionParser.expand('{io} (non arrivo <> oggi)'), [
        'Non arrivo oggi',
        'Oggi non arrivo',
        'Io non arrivo oggi',
        'Io oggi non arrivo',
      ]);
    });

    test('reordering keeps terminal punctuation terminal and fixes case', () {
      final variants = AnswerExpressionParser.expand(
        '{[Tu|Voi]} [vuoi|volete] un cappuccino <> oggi?',
      );
      expect(variants, hasLength(12));
      expect(variants, everyElement(endsWith('?')));
      expect(variants, contains('Oggi tu vuoi un cappuccino?'));
      expect(variants, isNot(contains('Oggi Tu vuoi un cappuccino?')));
      expect(AnswerExpressionParser.expand('Jane visita Roma <> oggi.'), [
        'Jane visita Roma oggi.',
        'Oggi Jane visita Roma.',
      ]);
      expect(AnswerExpressionParser.expand('USA arriva <> ora!'), [
        'USA arriva ora!',
        'Ora USA arriva!',
      ]);
    });

    test('whole-expression reorder, duplicate removal and validation work', () {
      expect(AnswerExpressionParser.expand('oggi <> oggi'), ['Oggi oggi']);
      expect(
        () => AnswerExpressionParser.expand('[a|]'),
        throwsA(isA<AnswerExpressionException>()),
      );
      expect(
        () => AnswerExpressionParser.expand('(a b)'),
        throwsA(isA<AnswerExpressionException>()),
      );
    });

    test('rejects combinations above the 128 expansion safety limit', () {
      expect(
        () => AnswerExpressionParser.expand(
          '[a|b|c|d|e|f] [g|h|i|j|k|l] [m|n|o|p|q|r]',
        ),
        throwsA(isA<AnswerExpressionException>()),
      );
    });

    test('linked *: groups expand by index without a cross product', () {
      expect(AnswerExpressionParser.expand('[*:i|il] [*:tuoi|tuo]'), [
        'I tuoi',
        'Il tuo',
      ]);
      expect(
        AnswerExpressionParser.expand('[*:il|i] [*:tuo|tuoi] [*:denaro|soldi]'),
        ['Il tuo denaro', 'I tuoi soldi'],
      );
      expect(
        AnswerExpressionParser.expand(
          '{oggi} [*:il|i] [*:tuo|tuoi] [denaro|soldi]',
        ),
        [
          'Il tuo denaro',
          'Il tuo soldi',
          'I tuoi denaro',
          'I tuoi soldi',
          'Oggi il tuo denaro',
          'Oggi il tuo soldi',
          'Oggi i tuoi denaro',
          'Oggi i tuoi soldi',
        ],
      );
    });

    test('linked *: groups validate count and equal cardinality', () {
      expect(
        () => AnswerExpressionParser.expand('[*:a|b]'),
        throwsA(isA<AnswerExpressionException>()),
      );
      expect(
        () => AnswerExpressionParser.expand('[*:a|b] [*:c|d|e]'),
        throwsA(isA<AnswerExpressionException>()),
      );
      expect(
        () => AnswerExpressionParser.expand('[g:a|b] [g:c|d]'),
        throwsA(isA<AnswerExpressionException>()),
      );
    });
  });

  group('answer acceptance', () {
    const engine = AnswerEngine();

    test('accepts canonical, explicit and syntax-expanded answers', () {
      const answers = [
        'Desidero un caffè',
        '{Io} [prendo|vorrei] un cappuccino',
      ];
      expect(engine.accepts('desidero un caffè', answers), isTrue);
      expect(engine.accepts('Vorrei un cappuccino!', answers), isTrue);
      expect(engine.accepts('io prendo un cappuccino', answers), isTrue);
    });

    test(
      'preserves apostrophes and tolerates omitted but not wrong accents',
      () {
        expect(engine.accepts('un altra', const ["un'altra"]), isFalse);
        expect(engine.accepts('caffe', const ['caffè']), isTrue);
        expect(engine.accepts('caffé', const ['caffè']), isFalse);
      },
    );

    test(
      'bounded typo tolerance accepts one small typo but no lexical change',
      () {
        expect(
          engine.accepts('vorrei un capuccino', const ['vorrei un cappuccino']),
          isTrue,
        );
        expect(
          engine.accepts('vorrei una cioccolata', const [
            'vorrei un cappuccino',
          ]),
          isFalse,
        );
        expect(
          engine.accepts('vorrei cappuccino', const ['vorrei un cappuccino']),
          isFalse,
        );
        expect(engine.accepts('non arrivo', const ['arrivo']), isFalse);
        expect(engine.accepts('io parlo', const ['io parla']), isFalse);
      },
    );
  });

  group('best correction', () {
    const engine = AnswerEngine();

    test(
      'shared words and typo-like forms select the closest valid answer',
      () {
        expect(
          engine.bestCorrection('io vorrei un capuccino', const [
            'Io prendo un cappuccino',
            'Io vorrei un cappuccino',
          ]),
          'Io vorrei un cappuccino',
        );
      },
    );

    test('graded token similarity prefers Volete for Vorrete', () {
      const answers = [
        'Vuoi un cappuccino oggi?',
        'Volete un cappuccino oggi?',
      ];
      expect(
        engine.bestCorrection('Vorrete un cappuccino oggi?', answers),
        'Volete un cappuccino oggi?',
      );
      expect(engine.accepts('Vorrete un cappuccino oggi?', answers), isFalse);
    });

    test(
      'incompatible extra words are penalized and ties keep author order',
      () {
        expect(
          engine.bestCorrection('we walk', const [
            'we walk home now',
            'we walk home',
          ]),
          'we walk home',
        );
        expect(
          engine.bestCorrection('unknown', const ['prima', 'seconda']),
          'prima',
        );
      },
    );

    test('correction selection never changes acceptance', () {
      const answers = ['Io vado', 'Io parto'];
      expect(engine.bestCorrection('Io torno', answers), isNotEmpty);
      expect(engine.accepts('Io torno', answers), isFalse);
    });
  });

  group('structured answer diagnostics', () {
    const engine = AnswerEngine();

    test('exact and accepted differences are reported only when used', () {
      final exact = engine.evaluate('Voglio un caffè', const [
        'Voglio un caffè',
      ]);
      expect(exact.isCorrect, isTrue);
      expect(exact.matchedAcceptedAnswer, 'Voglio un caffè');
      expect(exact.acceptanceReason, AcceptanceReason.exact);
      expect(exact.acceptedDifferences, isEmpty);

      final accent = engine.evaluate('Voglio un caffe', const [
        'Voglio un caffè',
      ]);
      expect(accent.isCorrect, isTrue);
      expect(accent.matchedAcceptedAnswer, 'Voglio un caffè');
      expect(accent.acceptedDifferences, ['missing diacritic']);

      final normalized = engine.evaluate('  VOGLIO   un caffè! ', const [
        'Voglio un caffè',
      ]);
      expect(normalized.isCorrect, isTrue);
      expect(
        normalized.acceptedDifferences,
        containsAll([
          'capitalization',
          'ignored punctuation',
          'normalized whitespace',
        ]),
      );
    });

    test('accepted and incorrect results share nearest-answer selection', () {
      const answers = ['Io prendo un cappuccino', 'Io vorrei un cappuccino'];
      final accepted = engine.evaluate('io vorrei un capuccino', answers);
      expect(accepted.isCorrect, isTrue);
      expect(accepted.matchedAcceptedAnswer, 'Io vorrei un cappuccino');
      expect(accepted.acceptedDifferences, ['explicitly allowed typo']);

      final incorrect = engine.evaluate('Io desidero un cappuccino', answers);
      expect(incorrect.isCorrect, isFalse);
      expect(
        incorrect.matchedAcceptedAnswer,
        engine.bestCorrection('Io desidero un cappuccino', answers),
      );
    });
  });
}
