import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/course_models.dart';
import 'package:quisquislingo_app/services/course_backup_service.dart';
import 'package:quisquislingo_app/services/course_file_store.dart';
import 'package:quisquislingo_app/services/storage/qql_earlier_private_folders.dart';

import '../tools/convert_stored_courses_256.dart';

/// Build 256 Session 2 (Revision 1): Course Model v12 serialization, preset
/// metadata, semantic equality, structural refusals, inline layouts, linear
/// flows, representative v11 conversions and the storage clean cut.
void main() {
  final when = DateTime.utc(2026, 9, 27, 12);

  Exercise select({
    Map<String, Object?> metadata = const {},
    PrimitiveOptions? options,
    List<String> correct = const ['b'],
  }) => Exercise.canonical(
    id: 'ex',
    updatedAt: when,
    primitive: ExercisePrimitive.select,
    options: options,
    promptElements: const [
      PromptElement(role: 'question', type: 'text', text: 'water'),
    ],
    items: const [
      ExerciseItem(
        id: 'a',
        content: [PromptElement(type: 'text', text: 'libro')],
      ),
      ExerciseItem(
        id: 'b',
        content: [PromptElement(type: 'text', text: 'acqua')],
      ),
    ],
    canonicalEvaluation: CanonicalEvaluation(
      mode: correct.length > 1
          ? EvaluationMode.exactSet
          : EvaluationMode.exactItem,
      correctItemIds: correct,
    ),
    hint: 'a drink',
    authoringMetadata: metadata,
  );

  Map<String, dynamic> roundTrip(Map<String, dynamic> json) =>
      jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

  group('v12 exercise JSON', () {
    test('serializes canonical fields only and parses back', () {
      final json = select().toJson();
      expect(json, {
        'updatedAt': '2026-09-27T12:00:00.000Z',
        'primitive': 'select',
        'prompt': [
          {'role': 'question', 'type': 'text', 'text': 'water'},
        ],
        'items': [
          {
            'id': 'a',
            'content': [
              {'role': 'primary', 'type': 'text', 'text': 'libro'},
            ],
          },
          {
            'id': 'b',
            'content': [
              {'role': 'primary', 'type': 'text', 'text': 'acqua'},
            ],
          },
        ],
        'evaluation': {
          'mode': 'exactItem',
          'correctItemIds': ['b'],
        },
        'hint': 'a drink',
      });
      final parsed = Exercise.fromJson(
        roundTrip(json),
        contentId: 'ex',
        publicationState: PublicationState.published,
      );
      expect(parsed.toJson(), json);
      expect(parsed.primitive, ExercisePrimitive.select);
      expect(parsed.options.isEmpty, isTrue);
      expect(
        parsed.effectiveOptions.enumValue<SelectionMode>(
          OptionKey.selectionMode,
        ),
        SelectionMode.single,
      );
      expect(parsed.canonicalEvaluation.correctItemIds, ['b']);
      expect(parsed.semanticallyEquals(select()), isTrue);
    });

    test(
      'options, elements, items, targets, layout and feedback round-trip',
      () {
        final exercise = Exercise.canonical(
          id: 'gaps',
          updatedAt: when,
          primitive: ExercisePrimitive.input,
          options: PrimitiveOptions({
            OptionKey.cardinality: const EnumOptionValue(Cardinality.multiple),
            OptionKey.layout: const EnumOptionValue(LayoutValue.inlineGaps),
            OptionKey.accentHandling: const EnumOptionValue(
              AccentHandling.exact,
            ),
          }),
          promptElements: const [
            PromptElement(
              type: 'audio',
              text: 'Vado a Roma domani.',
              playback: AudioPlayback.automatic,
              required: false,
            ),
            PromptElement(
              type: 'text',
              text: 'Listen.',
              language: TextLanguage.source,
            ),
          ],
          targets: const [
            ExerciseTarget(id: 'g1'),
            ExerciseTarget(id: 'g2', reveal: TargetReveal.firstGrapheme),
          ],
          layout: const [
            LayoutElement.text('Vado a '),
            LayoutElement.target('g1'),
            LayoutElement.text(' '),
            LayoutElement.target('g2'),
            LayoutElement.text('.'),
          ],
          canonicalEvaluation: const CanonicalEvaluation(
            mode: EvaluationMode.expression,
            targetAnswers: [
              TargetAnswers(targetId: 'g1', answers: ['Roma']),
              TargetAnswers(
                targetId: 'g2',
                answers: ['domani'],
                literalAnswers: ['Domani'],
              ),
            ],
          ),
          feedback: const ExerciseFeedback(
            correct: 'Bravo',
            showAlternatives: FeedbackAlternatives.ranked,
          ),
        );
        final json = roundTrip(exercise.toJson());
        expect(json['options'], {
          'cardinality': 'multiple',
          'layout': 'inlineGaps',
          'accentHandling': 'exact',
        });
        expect((json['prompt'] as List).first, {
          'role': 'primary',
          'type': 'audio',
          'text': 'Vado a Roma domani.',
          'playback': 'automatic',
          'required': false,
        });
        expect((json['prompt'] as List).last['language'], 'source');
        expect(json['targets'], [
          {'id': 'g1'},
          {'id': 'g2', 'reveal': 'firstGrapheme'},
        ]);
        expect((json['layout'] as List).length, 5);
        expect((json['layout'] as List)[1], {
          'type': 'target',
          'targetId': 'g1',
        });
        expect(json['feedback'], {
          'correct': 'Bravo',
          'showAlternatives': 'ranked',
        });
        final parsed = Exercise.fromJson(
          json,
          contentId: 'gaps',
          publicationState: PublicationState.published,
        );
        expect(parsed.toJson(), exercise.toJson());
        expect(parsed.semanticallyEquals(exercise), isTrue);
        expect(parsed.inlineSentence, 'Vado a Roma ___.');
        expect(parsed.accepted, ['Roma', 'domani']);
        expect(parsed.missingWords, ['Roma']);
        expect(
          parsed.promptElements.first.effectivePlayback,
          AudioPlayback.automatic,
        );
        expect(parsed.promptElements.first.isRequired, isFalse);
        // v11 readers never saw an Input layout.
        expect(parsed.interaction.layout, isEmpty);
      },
    );

    test('a Match carries sides and relations, an Arrange its orders', () {
      final match = Exercise.canonical(
        id: 'm',
        updatedAt: when,
        primitive: ExercisePrimitive.match,
        items: const [
          ExerciseItem(
            id: 'l',
            side: MatchSide.left,
            content: [PromptElement(type: 'text', text: 'cat')],
          ),
          ExerciseItem(
            id: 'r',
            side: MatchSide.right,
            content: [PromptElement(type: 'text', text: 'gatto')],
          ),
        ],
        canonicalEvaluation: const CanonicalEvaluation(
          mode: EvaluationMode.exactRelations,
          relations: [
            ['l', 'r'],
          ],
        ),
      );
      final json = roundTrip(match.toJson());
      expect((json['items'] as List).first['side'], 'left');
      expect(json['evaluation'], {
        'mode': 'exactRelations',
        'relations': [
          ['l', 'r'],
        ],
      });
      final parsed = Exercise.fromJson(
        json,
        contentId: 'm',
        publicationState: PublicationState.published,
      );
      expect(parsed.items.map((item) => item.side), [
        MatchSide.left,
        MatchSide.right,
      ]);
      expect(parsed.pairs, [
        ['cat', 'gatto'],
      ]);
      final arrange = Exercise.canonical(
        id: 'o',
        updatedAt: when,
        primitive: ExercisePrimitive.arrange,
        options: PrimitiveOptions({
          OptionKey.joiner: const EnumOptionValue(Joiner.none),
        }),
        items: const [
          ExerciseItem(
            id: 'c',
            content: [PromptElement(type: 'text', text: 'c')],
          ),
          ExerciseItem(
            id: 'a',
            content: [PromptElement(type: 'text', text: 'a')],
          ),
        ],
        canonicalEvaluation: const CanonicalEvaluation(
          mode: EvaluationMode.exactOrder,
          correctOrders: [
            OrderedAnswer(text: 'ca', itemIds: ['c', 'a']),
          ],
        ),
      );
      final parsedArrange = Exercise.fromJson(
        roundTrip(arrange.toJson()),
        contentId: 'o',
        publicationState: PublicationState.published,
      );
      expect(parsedArrange.orderAnswer, ['c', 'a']);
      expect(parsedArrange.evaluation.kind, 'ordered_items');
      expect(parsedArrange.type, 'word_order');
    });
  });

  group('preset metadata', () {
    test('is optional, preserved when unknown, and never changes meaning', () {
      final plain = select();
      final known = select(metadata: const {'presetId': 'choice'});
      final unknown = select(
        metadata: const {
          'presetId': 'someone_elses_recipe',
          'wizardStep': 3,
          'nested': {'a': 1},
        },
      );
      expect(plain.editorTemplate, '');
      expect(known.editorTemplate, 'choice');
      expect(unknown.editorTemplate, 'someone_elses_recipe');
      expect(plain.toJson(), known.toJson());
      expect(plain.toJson(), unknown.toJson());
      expect(plain.semanticallyEquals(known), isTrue);
      expect(plain.semanticallyEquals(unknown), isTrue);
      for (final exercise in [plain, known, unknown]) {
        expect(exercise.primitive, ExercisePrimitive.select);
        expect(exercise.correct, 1);
        expect(exercise.interaction.kind, 'select');
      }
      final content = LearningContent(
        id: 'ex',
        kind: 'exercise',
        exercise: unknown,
      );
      final json = roundTrip(content.toJson());
      expect(json['authoringMetadata'], {
        'presetId': 'someone_elses_recipe',
        'wizardStep': 3,
        'nested': {'a': 1},
      });
      expect(json.containsKey('editorTemplate'), isFalse);
      final reloaded = LearningContent.fromJson(json);
      expect(reloaded.authoringMetadata, json['authoringMetadata']);
      expect(reloaded.exercise!.semanticallyEquals(plain), isTrue);
      final absent = LearningContent.fromJson(
        roundTrip(
          LearningContent(id: 'ex', kind: 'exercise', exercise: plain).toJson(),
        ),
      );
      expect(absent.authoringMetadata, isEmpty);
      expect(absent.editorTemplate, '');
      expect(absent.exercise!.type, 'choice');
    });

    test('semantic equality sees every canonical change and ignores state', () {
      final base = select();
      expect(
        base.semanticallyEquals(
          base.withPublicationState(PublicationState.draft),
        ),
        isTrue,
      );
      expect(
        base.semanticallyEquals(
          base.withPublicationState(
            PublicationState.published,
            updatedAt: DateTime.utc(2030),
          ),
        ),
        isTrue,
      );
      expect(
        base.semanticallyEquals(
          select(
            options: PrimitiveOptions({
              OptionKey.shuffleItems: const BoolOptionValue(true),
            }),
          ),
        ),
        isTrue,
        reason: 'an explicit default equals the omitted option',
      );
      expect(
        base.semanticallyEquals(
          select(
            options: PrimitiveOptions({
              OptionKey.layout: const EnumOptionValue(LayoutValue.grid),
            }),
          ),
        ),
        isFalse,
      );
      expect(base.semanticallyEquals(select(correct: const ['a'])), isFalse);
      final reordered = Exercise.canonical(
        id: base.id,
        updatedAt: when,
        primitive: base.primitive,
        promptElements: base.promptElements,
        items: base.items.reversed.toList(),
        canonicalEvaluation: base.canonicalEvaluation,
        hint: base.hint,
      );
      expect(
        base.semanticallyEquals(reordered),
        isFalse,
        reason: 'item order counts',
      );
      expect(
        base.semanticallyEquals(
          Exercise.canonical(
            id: 'other',
            updatedAt: when,
            primitive: base.primitive,
            promptElements: base.promptElements,
            items: base.items,
            canonicalEvaluation: base.canonicalEvaluation,
            hint: base.hint,
          ),
        ),
        isFalse,
        reason: 'IDs count',
      );
    });
  });

  group('structural refusals', () {
    Map<String, dynamic> base() => roundTrip(select().toJson());

    test('an unknown primitive, option or evaluation mode is refused', () {
      for (final (label, mutate)
          in <(String, void Function(Map<String, dynamic>))>[
            ('primitive', (j) => j['primitive'] = 'story'),
            ('primitive case', (j) => j['primitive'] = 'Select'),
            ('option key', (j) => j['options'] = {'selectionmode': 'single'}),
            ('option value', (j) => j['options'] = {'selectionMode': 'both'}),
            (
              'inapplicable option',
              (j) => j['options'] = {'inputMode': 'text'},
            ),
            (
              'evaluation mode',
              (j) => (j['evaluation'] as Map)['mode'] = 'fuzzy',
            ),
            ('evaluation key', (j) => (j['evaluation'] as Map)['pairs'] = []),
            (
              'legacy interaction',
              (j) => j['interaction'] = {'kind': 'select'},
            ),
            (
              'element language',
              (j) => (j['prompt'] as List)[0]['language'] = 'latin',
            ),
            ('item side', (j) => (j['items'] as List)[0]['side'] = 'middle'),
            ('feedback', (j) => j['feedback'] = {'showAlternatives': 'some'}),
            (
              'target reveal',
              (j) => j['targets'] = [
                {'id': 't', 'reveal': 'all'},
              ],
            ),
            (
              'layout element',
              (j) => j['layout'] = [
                {'type': 'gap', 'text': 'g'},
              ],
            ),
          ]) {
        final json = base();
        mutate(json);
        expect(
          () => Exercise.fromJson(
            json,
            contentId: 'ex',
            publicationState: PublicationState.published,
          ),
          throwsFormatException,
          reason: label,
        );
      }
    });

    test(
      'an illegal primitive/evaluation pairing parses but the registry flags it',
      () {
        final json = base();
        (json['evaluation'] as Map)['mode'] = 'exactOrder';
        final parsed = Exercise.fromJson(
          json,
          contentId: 'ex',
          publicationState: PublicationState.published,
        );
        final violations = PrimitiveCapabilityRegistry.validate(
          primitive: parsed.primitive,
          options: parsed.options,
          evaluationMode: parsed.canonicalEvaluation.mode,
        );
        expect(
          violations.map((v) => v.code),
          contains(CapabilityViolationCode.illegalEvaluationMode),
        );
        final support = PrimitiveCapabilityRegistry.runtimeSupport(
          primitive: parsed.primitive,
          options: parsed.options,
          evaluationMode: parsed.canonicalEvaluation.mode,
        );
        expect(support.state, ExerciseSupportState.invalid);
      },
    );

    test('v11 Content shapes are refused with the conversion tool named', () {
      for (final json in [
        {
          'id': 'c',
          'publicationState': 'published',
          'kind': 'exercise',
          'required': true,
          'editorTemplate': 'choice',
          'exercise': select().toJson(),
        },
        {
          'id': 'c',
          'publicationState': 'published',
          'kind': 'presentation',
          'required': true,
          'presentation': {'content': []},
        },
      ]) {
        expect(
          () => LearningContent.fromJson(json),
          throwsA(
            isA<FormatException>().having(
              (e) => e.message,
              'message',
              contains('convert_course_to_v12'),
            ),
          ),
        );
      }
    });
  });

  group('content flow in a Round', () {
    test('a linear Story round-trips through Round JSON', () {
      final round = LearningRound(
        id: 'story',
        updatedAt: when,
        title: 'Story',
        visualType: 'story',
        content: [
          const LearningContent(
            id: 'narration',
            kind: 'dialogue',
            required: false,
            text: 'Anna: Ciao!',
          ),
          LearningContent(id: 'question', kind: 'exercise', exercise: select()),
        ],
        flow: ContentFlow.linear(const [
          FlowNode(
            id: 'n1',
            kind: FlowNodeKind.content,
            contentId: 'narration',
          ),
          FlowNode(
            id: 'n2',
            kind: FlowNodeKind.exercise,
            contentId: 'question',
          ),
        ]),
      );
      final json = roundTrip(round.toJson());
      expect(json['flow'], {
        'start': 'n1',
        'nodes': [
          {
            'id': 'n1',
            'kind': 'content',
            'contentId': 'narration',
            'transitions': [
              {'trigger': 'next', 'target': 'n2'},
            ],
          },
          {'id': 'n2', 'kind': 'exercise', 'contentId': 'question'},
        ],
      });
      final parsed = LearningRound.fromJson(json);
      expect(parsed.flow!.isLinear, isTrue);
      expect(parsed.flow!.linearNodeIds(), ['n1', 'n2']);
      expect(parsed.toJson(), json);
      final practice = LearningRound.fromJson(
        roundTrip(round.toJson()..remove('flow')),
      );
      expect(practice.flow, isNull);
    });

    test('branching transitions and conditions survive serialization', () {
      final flow = ContentFlow(
        startNodeId: 'q',
        nodes: const [
          FlowNode(
            id: 'q',
            kind: FlowNodeKind.exercise,
            contentId: 'question',
            transitions: [
              FlowTransition(
                trigger: FlowTrigger.onCorrect,
                targetNodeId: 'end',
              ),
              FlowTransition(
                trigger: FlowTrigger.onIncorrect,
                targetNodeId: 'hint',
              ),
              FlowTransition(
                trigger: FlowTrigger.onChoice,
                targetNodeId: 'end',
                choiceItemId: 'b',
              ),
            ],
          ),
          FlowNode(
            id: 'hint',
            kind: FlowNodeKind.content,
            contentId: 'narration',
            transitions: [
              FlowTransition(
                trigger: FlowTrigger.conditional,
                targetNodeId: 'end',
                condition: FlowCondition(
                  kind: FlowConditionKind.visited,
                  nodeId: 'q',
                ),
              ),
            ],
          ),
          FlowNode(
            id: 'end',
            kind: FlowNodeKind.content,
            contentId: 'narration',
          ),
        ],
      );
      final parsed = ContentFlow.fromJson(roundTrip(flow.toJson()));
      expect(parsed.toJson(), flow.toJson());
      expect(parsed.check(), isEmpty);
      expect(parsed.hasBranching, isTrue);
      expect(() => ContentFlow.fromJson({'start': 'a'}), throwsFormatException);
      expect(
        () => ContentFlow.fromJson({
          'start': 'a',
          'nodes': [
            {'id': 'a', 'kind': 'scene', 'contentId': 'x'},
          ],
        }),
        throwsFormatException,
      );
    });
  });

  group('representative v11 conversions', () {
    Exercise legacy(
      String type, {
      String prompt = '',
      String question = '',
      List<String> answers = const [],
      int? correct,
      String? tts,
      List<String> accepted = const [],
      List<String> tokens = const [],
      List<String> orderAnswer = const [],
      List<List<String>> pairs = const [],
      List<String> missingWords = const [],
      List<String> correctTranslations = const [],
    }) => Exercise(
      id: type,
      type: type,
      prompt: prompt,
      question: question,
      answers: answers,
      correct: correct,
      tts: tts,
      accepted: accepted,
      tokens: tokens,
      orderAnswer: orderAnswer,
      correctTranslations: correctTranslations,
      pairs: pairs,
      hint: '',
      icons: const [],
      missingWords: missingWords,
    );

    test('Select presets keep their behaviors as options and attributes', () {
      final listening = legacy(
        'listening_choice',
        question: 'What did you hear?',
        answers: const ['ciao', 'casa'],
        correct: 0,
        tts: 'ciao',
      );
      expect(listening.primitive, ExercisePrimitive.select);
      expect(listening.canonicalEvaluation.mode, EvaluationMode.exactItem);
      expect(
        listening.promptElements
            .singleWhere((e) => e.isAudio)
            .effectivePlayback,
        AudioPlayback.automatic,
      );
      // The v11-shaped view names the recipe the successor is built on.
      expect(listening.type, 'listening_comprehension');
      // Build 256 Revision 4: the converter records the successor preset.
      expect(listening.editorTemplate, 'listening_answer_target');

      final toTarget = legacy(
        'translation_choice_to_target',
        question: 'I am going to London',
        answers: const ['Vado a Londra.', 'Vengo da Londra.'],
        correct: 0,
      );
      expect(toTarget.promptElements.single.language, TextLanguage.source);
      expect(
        toTarget.items.map((item) => item.content.single.language),
        everyElement(TextLanguage.target),
      );

      final multi = Exercise.v2(
        id: 'multi',
        editorTemplate: 'choice',
        promptElements: const [PromptElement(type: 'text', text: 'Pick fruit')],
        interaction: const ExerciseInteraction(
          kind: 'select',
          minSelections: 2,
          maxSelections: 3,
          items: [
            ExerciseItem(
              id: 'i0',
              content: [PromptElement(type: 'text', text: 'apple')],
            ),
            ExerciseItem(
              id: 'i1',
              content: [PromptElement(type: 'text', text: 'carrot')],
            ),
            ExerciseItem(
              id: 'i2',
              content: [PromptElement(type: 'text', text: 'pear')],
            ),
          ],
        ),
        evaluation: const ExerciseEvaluation(
          kind: 'selected_items',
          correctItemIds: ['i0', 'i2'],
        ),
      );
      expect(multi.options.toJson(), {
        'selectionMode': 'multiple',
        'minimumSelections': 2,
        'maximumSelections': 3,
        'evaluationTiming': 'explicit',
      });
      expect(multi.canonicalEvaluation.mode, EvaluationMode.exactSet);
      expect(multi.isMultiSelect, isTrue);
      expect(multi.requiredSelectionCount, 2);
      expect(multi.maxSelectionCount, 3);
      expect(
        PrimitiveCapabilityRegistry.runtimeSupport(
          primitive: multi.primitive,
          options: multi.options,
          evaluationMode: multi.canonicalEvaluation.mode,
        ).state,
        ExerciseSupportState.executable,
      );
    });

    test('Input presets: accents, typos, literal answers, gaps', () {
      final translation = legacy(
        'type_translation',
        prompt: 'good morning',
        accepted: const ['buongiorno'],
      );
      expect(translation.primitive, ExercisePrimitive.input);
      expect(translation.options.toJson(), {'typoTolerance': 'conservative'});
      expect(
        translation.effectiveOptions.enumValue<AccentHandling>(
          OptionKey.accentHandling,
        ),
        AccentHandling.missingAccentsAccepted,
      );
      expect(translation.canonicalEvaluation.mode, EvaluationMode.expression);
      expect(
        translation.feedback.showAlternatives,
        FeedbackAlternatives.ranked,
      );
      expect(translation.promptElements.single.language, TextLanguage.source);
      expect(translation.evaluation.normalization['accents'], 'preserve');

      final fillBlank = legacy(
        'fill_blank',
        question: 'Buona____',
        accepted: const ['sera'],
        tts: 'Buonasera',
      );
      expect(fillBlank.canonicalEvaluation.answers, ['sera']);
      expect(fillBlank.canonicalEvaluation.literalAnswers, ['Buonasera']);
      expect(fillBlank.layout, isEmpty, reason: '___ stays display text');

      final missingWord = legacy(
        'type_missing_word',
        prompt: 'I would like a ___.',
        accepted: const ['cappuccino', 'coffee'],
      );
      expect(missingWord.options.toJson(), {
        'layout': 'inlineGaps',
        'typoTolerance': 'conservative',
      });
      expect(missingWord.targets.single.reveal, TargetReveal.firstGrapheme);
      expect(missingWord.layout.map((e) => e.isTarget), [false, true, false]);
      expect(missingWord.prompt, 'I would like a ___.');
      expect(missingWord.accepted, ['cappuccino', 'coffee']);
      expect(missingWord.promptElements, isEmpty);

      final listenGaps = legacy(
        'missing_word',
        prompt: 'La casa è grande e bella.',
        tts: 'La casa è grande e bella.',
        accepted: const ['casa', 'bella'],
        missingWords: const ['casa', 'bella'],
      );
      expect(listenGaps.options.toJson(), {
        'cardinality': 'multiple',
        'layout': 'inlineGaps',
      });
      expect(listenGaps.targets.map((t) => t.id), ['gap_1', 'gap_2']);
      expect(listenGaps.inlineSentence, 'La casa è grande e bella.');
      expect(listenGaps.missingWords, ['casa', 'bella']);
      expect(listenGaps.accepted, ['casa', 'bella']);
      expect(
        listenGaps.promptElements.single.effectivePlayback,
        AudioPlayback.automatic,
      );
      expect(
        PrimitiveCapabilityRegistry.runtimeSupport(
          primitive: listenGaps.primitive,
          options: listenGaps.options,
          evaluationMode: listenGaps.canonicalEvaluation.mode,
        ).state,
        ExerciseSupportState.executable,
      );
    });

    test('Arrange, Match and Presentation presets', () {
      final imageWord = legacy(
        'image_word',
        prompt: 'Build the word',
        tokens: const ['c', 'a', 't'],
        orderAnswer: const ['c', 'a', 't'],
      );
      expect(imageWord.options.toJson(), {
        'unusedItems': 'forbidden',
        'joiner': 'none',
      });
      expect(imageWord.canonicalEvaluation.mode, EvaluationMode.exactOrder);
      expect(imageWord.canonicalEvaluation.correctOrders.single.text, 'cat');

      final build = legacy(
        'build_translation',
        prompt: 'I eat',
        tokens: const ['mangio', 'io', 'tu'],
        correctTranslations: const ['io mangio', 'mangio'],
      );
      expect(build.canonicalEvaluation.mode, EvaluationMode.acceptedOrders);
      expect(build.feedback.showAlternatives, FeedbackAlternatives.all);
      expect(build.correctTranslationTexts, ['io mangio', 'mangio']);

      final match = legacy(
        'audio_match',
        prompt: 'Match',
        pairs: const [
          ['ciao', 'hello'],
          ['casa', 'house'],
        ],
      );
      expect(match.primitive, ExercisePrimitive.match);
      expect(match.items.map((i) => i.side), [
        MatchSide.left,
        MatchSide.right,
        MatchSide.left,
        MatchSide.right,
      ]);
      expect(match.canonicalEvaluation.relations, [
        ['item_0', 'item_1'],
        ['item_2', 'item_3'],
      ]);
      expect(match.answers, ['hello', 'house']);

      final card = legacy(
        'flashcard',
        prompt: 'gatto',
        question: 'cat',
        answers: const ['Il gatto dorme.', 'The cat sleeps.'],
        tts: 'gatto',
      );
      expect(card.primitive, ExercisePrimitive.presentation);
      expect(card.canonicalEvaluation.mode, EvaluationMode.none);
      expect(card.type, 'flashcard');
      expect(
        {for (final e in card.promptElements) e.role: e.text},
        {
          'term': 'gatto',
          'meaning': 'cat',
          'audio': 'gatto',
          'usage': 'Il gatto dorme.',
          'usage_translation': 'The cat sleeps.',
        },
      );
      expect(card.answers, ['Il gatto dorme.', 'The cat sleeps.']);
      final content = LearningContent.fromExercise(card);
      expect(content.kind, 'exercise');
      expect(content.presentation!.actions, ['understood', 'review_later']);
      expect(
        LearningContent.fromJson(
          roundTrip(content.toJson()),
        ).exercise!.semanticallyEquals(card),
        isTrue,
      );
    });
  });

  group('storage clean cut', () {
    late Directory root;
    setUp(() async {
      root = await Directory.systemTemp.createTemp('qql_v12_storage_');
    });
    tearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    String path(String relative) =>
        '${root.path}${Platform.pathSeparator}${relative.replaceAll('/', Platform.pathSeparator)}';

    Map<String, dynamic> v11Record() => {
      'courseId': 'course_old',
      'entry': {
        'course': {..._v11Course(), 'courseId': 'course_old'},
      },
    };

    test('the Build 255 store is never read and a v11 backup is named', () async {
      final file = File(path('QQL_Courses/Custom/QQL_EN_IT_old.json'))
        ..createSync(recursive: true)
        ..writeAsStringSync(jsonEncode(v11Record()));
      final store = CourseFileStore(supportDirectory: () async => root);
      expect(CourseFileStore.rootDirectoryName, 'QQL_Courses_v12');
      expect(
        (await store.readReadable(CourseStoreKind.custom)).records,
        isEmpty,
      );
      expect(await file.exists(), isTrue);
      expect(QqlEarlierPrivateFolders.retired, contains('QQL_Courses'));

      final manifest =
          File(
              path(
                'Backups/Courses/QQL_bkp_EN_IT_old/QQL_bkp_EN_IT_old_v1_x.json',
              ),
            )
            ..createSync(recursive: true)
            ..writeAsStringSync(
              jsonEncode({
                'format': CourseBackupService.earlierBackupFormat,
                'courseId': 'course_old',
                'course': _v11Course(),
              }),
            );
      final backups = CourseBackupService(
        backupsDirectoryProvider: () async =>
            Directory(path('Backups/Courses')),
      );
      final skipped = <String>[];
      expect(
        await backups.listBackups('course_old', skipped: skipped),
        isEmpty,
      );
      expect(skipped, [manifest.uri.pathSegments.last]);
      await expectLater(
        backups.loadBackup(manifest, expectedCourseId: 'course_old'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            contains('format 11'),
          ),
        ),
      );
      expect(
        CourseBackupService.backupFormat,
        'QuisquisLingo Course Backup v12',
      );
    });

    test(
      'convert_stored_courses_256 moves custom Courses forward, nothing else',
      () async {
        File(path('QQL_Courses/Custom/QQL_EN_IT_old.json'))
          ..createSync(recursive: true)
          ..writeAsStringSync(jsonEncode(v11Record()));
        File(path('QQL_Courses/Custom/broken.json'))
          ..createSync(recursive: true)
          ..writeAsStringSync('not json');
        File(path('QQL_Courses/Publisher/QQL_EN_IT_pub.json'))
          ..createSync(recursive: true)
          ..writeAsStringSync(
            jsonEncode({
              'courseId': 'pub',
              'entry': {'source': {}},
            }),
          );
        final dry = await convertStoredCourses(support: root, dryRun: true);
        expect(dry.converted, 1);
        expect(dry.kept, 2);
        expect(Directory(path('QQL_Courses_v12')).existsSync(), isFalse);

        final report = await convertStoredCourses(support: root);
        expect(report.converted, 1);
        expect(report.kept, 2);
        expect(report.lines, hasLength(3));
        final store = CourseFileStore(supportDirectory: () async => root);
        final snapshot = await store.readReadable(CourseStoreKind.custom);
        expect(snapshot.records.keys, ['course_old']);
        expect(snapshot.skipped, isEmpty);
        final converted = Course.fromJson(
          Map<String, dynamic>.from(
            (snapshot.records['course_old'] as Map)['course'] as Map,
          ),
        );
        expect(converted.formatVersion, 12);
        expect(
          converted
              .lessons
              .single
              .rounds
              .single
              .content
              .single
              .exercise!
              .primitive,
          ExercisePrimitive.select,
        );
        // The earlier files are untouched, and a second run keeps the new one.
        expect(
          File(path('QQL_Courses/Custom/QQL_EN_IT_old.json')).existsSync(),
          isTrue,
        );
        expect(
          File(path('QQL_Courses/Custom/broken.json')).existsSync(),
          isTrue,
        );
        final again = await convertStoredCourses(support: root);
        expect(again.converted, 0);
        expect(again.kept, 3);
      },
    );
  });
}

const _profileId = '12345678-1234-4234-9234-123456789abc';

/// A hand-written Course Model v11 custom Course, as the converter's input.
Map<String, dynamic> _v11Course() => {
  'formatVersion': 11,
  'publicationState': 'published',
  'lessonNumberingMode': 'lesson',
  'defaultLessonIconStyle': 'monochrome',
  'createDuels': false,
  'useGuidebook': false,
  'courseId': 'course_31b11b63-e6d2-4f2a-a731-a71ba236960c',
  'originType': 'custom',
  'originalCourseCreator': {
    'type': 'qqlUser',
    'id': _profileId,
    'displayName': 'Converter tester',
  },
  'maintainer': {'profileId': _profileId},
  'originalCreatedAtUtc': '2026-09-07T10:00:00.000Z',
  'lastVersionEditorProfileId': _profileId,
  'lastVersionEditorDisplayName': 'Converter tester',
  'modifiedAtUtc': '2026-09-07T10:00:00.000Z',
  'learningLanguage': 'Italian',
  'interfaceLanguage': 'English',
  'sourceLanguage': 'English',
  'targetLanguage': 'Italian',
  'title': 'v11 input',
  'ttsLanguage': 'it-IT',
  'courseVersion': '1',
  'audioMode': 'tts',
  'license': 'All rights reserved',
  'textDirection': 'ltr',
  'flagCode': 'IT',
  'temporarySample': false,
  'lessons': [
    {
      'lessonId': 'lesson-1',
      'publicationState': 'published',
      'updatedAt': '2026-09-07T10:00:00.000Z',
      'title': 'Greetings',
      'section': false,
      'guidebook': {'content': []},
      'rounds': [
        {
          'id': 'round-1',
          'publicationState': 'published',
          'updatedAt': '2026-09-07T10:01:00.000Z',
          'visualType': 'generic',
          'content': [
            {
              'id': 'exercise-1',
              'publicationState': 'published',
              'kind': 'exercise',
              'required': true,
              'editorTemplate': 'choice',
              'exercise': {
                'updatedAt': '2026-09-07T10:02:00.000Z',
                'prompt': [
                  {'role': 'question', 'type': 'text', 'text': 'water'},
                ],
                'interaction': {
                  'kind': 'select',
                  'minSelections': 1,
                  'maxSelections': 1,
                  'items': [
                    {
                      'id': 'item_0',
                      'content': [
                        {'role': 'primary', 'type': 'text', 'text': 'acqua'},
                      ],
                    },
                    {
                      'id': 'item_1',
                      'content': [
                        {'role': 'primary', 'type': 'text', 'text': 'libro'},
                      ],
                    },
                  ],
                },
                'evaluation': {
                  'kind': 'selected_items',
                  'correctItemIds': ['item_0'],
                },
              },
            },
          ],
        },
      ],
      'duel': {'id': 'lesson-1_duel', 'title': 'Duel'},
    },
  ],
};
