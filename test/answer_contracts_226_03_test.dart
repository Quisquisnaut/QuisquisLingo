import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/answer_engine.dart';
import 'package:quisquislingo_app/services/answer_materialization_service.dart';

void main() {
  const engine = AnswerEngine();
  final expressionError = throwsA(isA<AnswerExpressionException>());

  group('226.03 authoritative expression contract', () {
    test(
      'master optional and independent example preserves expansion order',
      () {
        expect(
          AnswerExpressionParser.expand('{Io} [prendo|vorrei] un cappuccino'),
          [
            'Prendo un cappuccino',
            'Vorrei un cappuccino',
            'Io prendo un cappuccino',
            'Io vorrei un cappuccino',
          ],
        );
      },
    );

    test(
      'optional linked groups and scoped reorder combine deterministically',
      () {
        const expression = '{oggi} ([*:io|noi] [*:vado|andiamo] <> a casa)';
        expect(AnswerExpressionParser.expand(expression), [
          'Io vado a casa',
          'A casa io vado',
          'Noi andiamo a casa',
          'A casa noi andiamo',
          'Oggi io vado a casa',
          'Oggi a casa io vado',
          'Oggi noi andiamo a casa',
          'Oggi a casa noi andiamo',
        ]);
      },
    );

    test(
      'nested optional and independent groups preserve baseline semantics',
      () {
        expect(AnswerExpressionParser.expand('qui {(oggi <> domani)}'), [
          'Qui',
          'Qui oggi domani',
          'Qui domani oggi',
        ]);
        expect(AnswerExpressionParser.expand('{[io|noi]} arrivo'), [
          'Arrivo',
          'Io arrivo',
          'Noi arrivo',
        ]);
        expect(AnswerExpressionParser.expand('{oggi {qui}} arrivo'), [
          'Arrivo',
          'Oggi arrivo',
          'Oggi qui arrivo',
        ]);
      },
    );

    test('whole reorder retains terminal punctuation and proper names', () {
      expect(AnswerExpressionParser.expand('Jane visita Roma <> oggi.'), [
        'Jane visita Roma oggi.',
        'Oggi Jane visita Roma.',
      ]);
      expect(AnswerExpressionParser.expand('oggi <> oggi'), ['Oggi oggi']);
      expect(AnswerExpressionParser.expand('[caffè|caffè]'), ['Caffè']);
    });

    test('malformed and mismatched linked syntax cannot partially expand', () {
      for (final expression in [
        '[*:a|b]',
        '[*:a|b] [*:c|d|e]',
        '[g:a|b] [g:c|d]',
        '[a|]',
        '{}',
        '[a|b',
        '(a b)',
        'a < b',
      ]) {
        expect(
          () => AnswerExpressionParser.expand(expression),
          expressionError,
        );
      }
    });

    test('zero outputs reject and one literal stays exact', () {
      expect(() => AnswerExpressionParser.expand('   '), expressionError);
      expect(() => AnswerExpressionParser.expandAll(const []), expressionError);
      expect(AnswerExpressionParser.expand('caffè!'), ['caffè!']);
    });

    test('128 variants succeed in stable order and 129 rejects', () {
      final expression = _alternatives(128);
      final expected = List.generate(128, (index) => 'Answer$index');
      expect(AnswerExpressionParser.expansionLimit, 128);
      expect(AnswerExpressionParser.expand(expression), expected);
      expect(
        () => AnswerExpressionParser.expand(_alternatives(129)),
        expressionError,
      );
      expect(
        () => AnswerExpressionParser.expandAll([...expected, 'one more']),
        expressionError,
      );
    });

    test(
      'aggregate limit counts source and identical materialized variants once',
      () {
        final expression = _alternatives(128);
        final expanded = AnswerExpressionParser.expand(expression);
        expect(
          AnswerExpressionParser.expandAll([
            expression,
            ...expanded,
            expression,
          ]),
          expanded,
        );
        expect(AnswerExpressionParser.expandAll(['first', 'second', 'first']), [
          'first',
          'second',
        ]);
      },
    );
  });

  group('226.03 independent materialization', () {
    test('inspection leaves source and explicit answers unchanged', () {
      final source = ['{Io} [prendo|vorrei] un cappuccino'];
      final before = List<String>.of(source);
      final answers = AnswerMaterializationService.expand(source);
      expect(answers, hasLength(4));
      expect(source, before);
      answers.removeAt(0);
      expect(source, before);
    });

    test(
      'counts normalized duplicates already explicit and keeps source independent',
      () {
        const expression = '{Io} [prendo|vorrei] un cappuccino';
        final existing = [expression, '  prendo un CAPPUCCINO! '];
        final result = AnswerMaterializationService.materialize(
          expressions: const [expression],
          existing: existing,
        );
        expect(result.generated, 4);
        expect(result.added, 3);
        expect(result.alreadyPresent, 1);
        expect(existing, [expression, '  prendo un CAPPUCCINO! ']);
        final edited = result.answers.toList()..remove(expression);
        expect(engine.accepts('Io vorrei un cappuccino', edited), isTrue);
        existing[0] = 'another source';
        expect(edited, contains('Io vorrei un cappuccino'));
        expect(edited, isNot(contains('another source')));
        expect(() => result.answers.add('unexpected'), throwsUnsupportedError);
      },
    );

    test(
      'normalization preserves accents and honors case-preserving exercises',
      () {
        expect(engine.normalizedAnswer('  CAFFÈ!  '), 'caffè');
        expect(engine.distinctAnswers(['Caffè', 'caffè!', 'caffe']), [
          'Caffè',
          'caffe',
        ]);
        final preserved = AnswerMaterializationService.materialize(
          expressions: const ['Coffee'],
          existing: const ['coffee'],
          normalization: const {'case': 'preserve'},
        );
        expect(preserved.answers, ['coffee', 'Coffee']);
        expect(preserved.added, 1);
        final ignored = AnswerMaterializationService.materialize(
          expressions: const ['Coffee'],
          existing: const ['coffee'],
        );
        expect(ignored.answers, ['coffee']);
        expect(ignored.added, 0);
      },
    );

    test('maximum materialization succeeds even while expression remains', () {
      final expression = _alternatives(128);
      final result = AnswerMaterializationService.materialize(
        expressions: [expression],
        existing: [expression],
      );
      expect(result.generated, 128);
      expect(result.added, 128);
      expect(result.answers, hasLength(129));
      expect(engine.validAnswers(result.answers), hasLength(128));
    });

    test(
      'overflow and later malformed source leave existing list untouched',
      () {
        final existing = ['preserved'];
        for (final expressions in [
          [_alternatives(129)],
          ['valid answer', '[malformed'],
          [_alternatives(128)],
        ]) {
          expect(
            () => AnswerMaterializationService.materialize(
              expressions: expressions,
              existing: existing,
            ),
            expressionError,
          );
          expect(existing, ['preserved']);
        }
      },
    );

    test(
      'canonical materialized answers roundtrip with complete exercise fields',
      () {
        final answers = AnswerMaterializationService.materialize(
          expressions: const ['[coffee|cappuccino]'],
          existing: const [],
        ).answers;
        final timestamp = DateTime.utc(2026, 9, 6, 12);
        final exercise = Exercise.v2(
          id: 'stable-exercise',
          publicationState: PublicationState.draft,
          updatedAt: timestamp,
          editorTemplate: 'type_translation',
          promptElements: const [
            PromptElement(type: 'text', text: 'Translate the drink'),
            PromptElement(
              role: 'context',
              type: 'audio',
              text: 'Context audio',
            ),
          ],
          interaction: const ExerciseInteraction(kind: 'input'),
          evaluation: ExerciseEvaluation(
            kind: 'text_match',
            accepted: answers,
            normalization: const {'case': 'preserve', 'accents': 'preserve'},
          ),
          hint: 'A drink',
          feedback: const {'correct': 'Custom feedback'},
        );
        final json =
            jsonDecode(jsonEncode(exercise.toV2Json())) as Map<String, dynamic>;
        final reloaded = Exercise.fromV2Json(
          json,
          contentId: exercise.id,
          editorTemplate: exercise.editorTemplate,
          publicationState: exercise.publicationState,
        );
        expect(reloaded.toV2Json(), exercise.toV2Json());
        expect(reloaded.id, 'stable-exercise');
        expect(reloaded.publicationState, PublicationState.draft);
        expect(reloaded.updatedAt, timestamp);
        expect(reloaded.accepted, ['Coffee', 'Cappuccino']);
        expect(reloaded.feedback, {'correct': 'Custom feedback'});
        expect(reloaded.evaluation.normalization['case'], 'preserve');
        final legacy = Map<String, dynamic>.from(json['evaluation'] as Map)
          ..remove('acceptedAnswers')
          ..['accepted'] = answers;
        expect(
          () => ExerciseEvaluation.fromJson(legacy),
          throwsFormatException,
        );
      },
    );
  });

  group('226.03 authoritative display ranking', () {
    test('exact response ranks before extra and missing word candidates', () {
      expect(
        engine.rankedAnswers('we walk home', const [
          'we walk home now',
          'we walk',
          'we walk home',
        ]).first,
        'we walk home',
      );
      expect(
        engine.rankedAnswers('we walk', const [
          'we walk home now',
          'we walk home',
        ]),
        ['we walk home', 'we walk home now'],
      );
    });

    test('Vorrete ranks Volete nearest without accepting a lexical change', () {
      const answers = [
        'Vuoi un cappuccino oggi?',
        'Volete un cappuccino oggi?',
      ];
      expect(engine.rankedAnswers('Vorrete un cappuccino oggi?', answers), [
        'Volete un cappuccino oggi?',
        'Vuoi un cappuccino oggi?',
      ]);
      expect(engine.accepts('Vorrete un cappuccino oggi?', answers), isFalse);
    });

    test(
      'ties retain deterministic author order and ranking never mutates answers',
      () {
        final answers = ['prima', 'seconda'];
        expect(engine.rankedAnswers('unknown', answers), answers);
        expect(engine.rankedAnswers('unknown', answers.reversed), [
          'seconda',
          'prima',
        ]);
        expect(engine.rankedAnswers('unknown', answers), ['prima', 'seconda']);
        expect(answers, ['prima', 'seconda']);
      },
    );

    test(
      'ranking deduplicates normalized spellings without erasing diacritics',
      () {
        expect(
          engine.rankedAnswers('caffè', const [
            'Caffè!',
            'caffè',
            'caffe',
          ]).length,
          2,
        );
        expect(
          engine.rankedAnswers('caffè', const ['latte', 'caffè']).first,
          'caffè',
        );
        expect(engine.accepts('caffe', const ['caffè']), isTrue);
        expect(engine.accepts('caffé', const ['caffè']), isFalse);
      },
    );

    test(
      'display ranking shares correction ordering while acceptance stays separate',
      () {
        const answers = ['Io vorrei un cappuccino', 'Io prendo un cappuccino'];
        for (final example in <String, bool>{
          'Io vorrei un cappuccino': true,
          'io vorrei un cappuccino!': true,
          'Io vorrei un capuccino': true,
          'Io vorrei cappuccino': false,
          'Io vorrei un cappuccino domani': false,
          'Io torno': false,
        }.entries) {
          final before = engine.evaluate(example.key, answers);
          final ranked = engine.rankedAnswers(example.key, answers);
          expect(ranked.first, engine.bestCorrection(example.key, answers));
          expect(before.isCorrect, example.value);
          expect(
            engine.evaluate(example.key, answers).isCorrect,
            before.isCorrect,
          );
        }
      },
    );
  });
}

String _alternatives(int count) =>
    '[${List.generate(count, (index) => 'answer$index').join('|')}]';
