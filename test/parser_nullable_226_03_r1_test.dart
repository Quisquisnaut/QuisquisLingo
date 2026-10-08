import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/services/answer_engine.dart';
import 'package:quisquislingo_app/services/answer_materialization_service.dart';

void main() {
  test(
    'deep optional syntax hits bounded expansion without recursive overflow',
    () {
      final source = '${'{' * 10000}word${'}' * 10000}';
      expect(
        () => AnswerExpressionParser.expand(source),
        throwsA(isA<AnswerExpressionException>()),
      );
    },
  );
  const examples = <String, List<String>>{
    'come stai <> {tu}': ['Come stai', 'Come stai tu', 'Tu come stai'],
    'come [*:stai|state] {[*:tu|voi]}': [
      'Come stai',
      'Come state',
      'Come stai tu',
      'Come state voi',
    ],
    'come [*:stai|state] <> {[*:tu|voi]}': [
      'Come stai tu',
      'Come state voi',
      'Come stai',
      'Come state',
      'Tu come stai',
      'Voi come state',
    ],
  };
  for (final example in examples.entries) {
    test(
      'nullable expression preserves exact deterministic order: ${example.key}',
      () {
        expect(AnswerExpressionParser.expand(example.key), example.value);
        expect(AnswerExpressionParser.expand(example.key), example.value);
      },
    );
    test(
      'nullable expression retains one final question mark: ${example.key}',
      () {
        final answers = AnswerExpressionParser.expand('${example.key}?');
        expect(answers, example.value.map((value) => '$value?').toList());
        expect(
          answers.every((answer) => '?'.allMatches(answer).length == 1),
          isTrue,
        );
        expect(answers.every((answer) => answer.endsWith('?')), isTrue);
      },
    );
  }

  const threeGroupCases = <String, List<String>>{
    '{[*:io|noi]} [*:sono|siamo] [*:pronto|pronti]': [
      'Sono pronto',
      'Siamo pronti',
      'Io sono pronto',
      'Noi siamo pronti',
    ],
    '[*:io|noi] {[*:sono|siamo]} [*:pronto|pronti]': [
      'Io pronto',
      'Noi pronti',
      'Io sono pronto',
      'Noi siamo pronti',
    ],
    '[*:io|noi] [*:sono|siamo] {[*:pronto|pronti]}': [
      'Io sono',
      'Noi siamo',
      'Io sono pronto',
      'Noi siamo pronti',
    ],
  };
  for (final example in threeGroupCases.entries) {
    test(
      'optional member of three linked groups keeps column alignment: ${example.key}',
      () {
        expect(AnswerExpressionParser.expand(example.key), example.value);
      },
    );
  }

  test(
    'optional content inside linked columns retains empty column positions',
    () {
      expect(AnswerExpressionParser.expand('[*:{io}|noi] [*:sono|siamo]'), [
        'Sono',
        'Noi siamo',
        'Io sono',
      ]);
      expect(AnswerExpressionParser.expand('[*:{io}|{noi}] [*:sono|siamo]'), [
        'Sono',
        'Siamo',
        'Noi siamo',
        'Io sono',
      ]);
    },
  );

  test(
    'independent alternatives compose with optional linked members without crossing columns',
    () {
      expect(
        AnswerExpressionParser.expand(
          '[ciao|salve] [*:tu|voi] {[*:sei|siete]}',
        ),
        [
          'Ciao tu',
          'Salve tu',
          'Ciao voi',
          'Salve voi',
          'Ciao tu sei',
          'Salve tu sei',
          'Ciao voi siete',
          'Salve voi siete',
        ],
      );
    },
  );

  test(
    'nested supported optionals and reorder scopes may have empty derived operands',
    () {
      expect(AnswerExpressionParser.expand('come ({molto {bene}} <> stai)'), [
        'Come stai',
        'Come molto stai',
        'Come stai molto',
        'Come molto bene stai',
        'Come stai molto bene',
      ]);
      expect(AnswerExpressionParser.expand('({io} <> {no})?'), [
        'No?',
        'Io?',
        'Io no?',
        'No io?',
      ]);
    },
  );

  test(
    'fully optional answers never materialize empty or punctuation-only rows',
    () {
      expect(AnswerExpressionParser.expand('{io}{no}'), ['No', 'Io', 'Iono']);
      expect(AnswerExpressionParser.expand('{io} {no}?'), [
        'No?',
        'Io?',
        'Io no?',
      ]);
      final result = AnswerMaterializationService.materialize(
        expressions: ['{io} {no}?'],
        existing: const ['Già presente'],
      );
      expect(result.answers, ['Già presente', 'No?', 'Io?', 'Io no?']);
      expect(result.generated, 3);
      expect(
        result.answers.any((answer) => answer.trim().isEmpty || answer == '?'),
        isFalse,
      );
    },
  );

  for (final invalid in [
    'come stai <>',
    '<> tu',
    'come stai <> ?',
    '{come <>} resta',
    '{<> tu} resta',
    'come [bene <>|male]',
  ]) {
    test(
      'raw missing reorder operand is rejected before optional removal: $invalid',
      () {
        expect(
          () => AnswerExpressionParser.expand(invalid),
          throwsA(
            isA<AnswerExpressionException>().having(
              (error) => error.message,
              'diagnostic',
              '<> requires an expression on both sides.',
            ),
          ),
        );
      },
    );
  }

  for (final invalid in [
    '{[*:tu|voi]}',
    '[*:sono|siamo] {[*:io|noi|loro]}',
    '[*:sono|siamo] {[*:io|]}',
    '[*:sono|siamo] {[*:|noi]}',
    '{[g:io|noi]} resto',
    '{ } resto',
  ]) {
    test(
      'invalid original linked/optional syntax is not hidden by absence: $invalid',
      () {
        expect(
          () => AnswerExpressionParser.expand(invalid),
          throwsA(isA<AnswerExpressionException>()),
        );
      },
    );
  }

  test('128 raw optional branches remain bounded before deduplication', () {
    final maximum =
        'base ${List.generate(7, (index) => '{word$index}').join(' ')}';
    expect(AnswerExpressionParser.expand(maximum), hasLength(128));
    final beyond =
        'base ${List.generate(8, (index) => '{word$index}').join(' ')}';
    expect(
      () => AnswerExpressionParser.expand(beyond),
      throwsA(
        isA<AnswerExpressionException>().having(
          (error) => error.message,
          'limit',
          contains('128'),
        ),
      ),
    );
    expect(
      AnswerExpressionParser.expand(List.filled(7, '{x}').join()),
      hasLength(7),
    );
    expect(
      () => AnswerExpressionParser.expand(List.filled(8, '{x}').join()),
      throwsA(isA<AnswerExpressionException>()),
    );
  });

  test(
    'overflow or malformed later expression cannot partially materialize earlier answers',
    () {
      final existing = <String>['Keep this exact answer'];
      final snapshot = List<String>.of(existing);
      for (final failing in [
        'come stai <>',
        'base ${List.generate(8, (index) => '{word$index}').join(' ')}',
      ]) {
        expect(
          () => AnswerMaterializationService.materialize(
            expressions: ['come stai <> {tu}', failing],
            existing: existing,
          ),
          throwsA(isA<AnswerExpressionException>()),
        );
        expect(existing, snapshot);
      }
    },
  );
}
