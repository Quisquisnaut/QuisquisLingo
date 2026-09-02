import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/answer_engine.dart';

void main() {
  group('answer-expression parser', () {
    test('expands optional text and alternatives deterministically', () {
      expect(
        AnswerExpressionParser.expand('{Io} [prendo|vorrei] un cappuccino'),
        [
          'prendo un cappuccino',
          'vorrei un cappuccino',
          'Io prendo un cappuccino',
          'Io vorrei un cappuccino',
        ],
      );
    });

    test('reorders only declared scoped phrase parts', () {
      expect(AnswerExpressionParser.expand('{io} (non arrivo <> oggi)'), [
        'non arrivo oggi',
        'oggi non arrivo',
        'io non arrivo oggi',
        'io oggi non arrivo',
      ]);
    });

    test('whole-expression reorder, duplicate removal and validation work', () {
      expect(AnswerExpressionParser.expand('oggi <> oggi'), ['oggi oggi']);
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
}
