import 'package:flutter_test/flutter_test.dart';
import 'package:quisquislingo_app/models/canonical/canonical.dart';

PrimitiveOptions options(Map<OptionKey, Object> values) => PrimitiveOptions({
  for (final entry in values.entries)
    entry.key: switch (entry.value) {
      final OptionEnumValue value => EnumOptionValue(value),
      final bool value => BoolOptionValue(value),
      final int value => IntOptionValue(value),
      final String value => LanguageOptionValue(value),
      _ => throw ArgumentError(entry.value),
    },
});

List<CapabilityViolationCode> codes(List<CapabilityViolation> violations) =>
    violations.map((violation) => violation.code).toList();

void main() {
  group('registry consistency', () {
    test('every primitive has exactly one capability with legal defaults', () {
      final covered = PrimitiveCapabilityRegistry.capabilities
          .map((capability) => capability.primitive)
          .toList();
      expect(covered.toSet(), ExercisePrimitive.values.toSet());
      expect(covered.toSet(), hasLength(covered.length));
      for (final primitive in ExercisePrimitive.values) {
        final capability = PrimitiveCapabilityRegistry.capabilityOf(primitive);
        expect(capability.evaluationModes, isNotEmpty, reason: primitive.label);
        expect(
          capability.evaluationModes,
          contains(capability.defaultEvaluationMode),
          reason: primitive.label,
        );
        expect(capability.options, isNotEmpty, reason: primitive.label);
        final keys = capability.optionKeys;
        expect(keys.toSet(), hasLength(keys.length), reason: primitive.label);
        for (final definition in capability.options) {
          final reason = '${primitive.label}.${definition.key.serialized}';
          if (definition.key.kind == OptionValueKind.enumeration) {
            expect(definition.legalValues, isNotEmpty, reason: reason);
            expect(
              definition.key.vocabulary,
              containsAll(definition.legalValues),
              reason: reason,
            );
          } else {
            expect(definition.legalValues, isEmpty, reason: reason);
          }
          if (definition.key.kind == OptionValueKind.integer) {
            expect(definition.minimum, isNotNull, reason: reason);
          }
          if (definition.required) {
            expect(definition.defaultValue, isNull, reason: reason);
          }
          final fallback = definition.defaultValue;
          if (fallback != null) {
            expect(definition.accepts(fallback), isTrue, reason: reason);
          }
        }
        final ruleIds = capability.rules.map((rule) => rule.id).toList();
        expect(
          ruleIds.toSet(),
          hasLength(ruleIds.length),
          reason: primitive.label,
        );
        for (final rule in capability.rules) {
          expect(rule.id, startsWith('${primitive.serialized}.'));
          expect(rule.description.trim(), isNotEmpty, reason: rule.id);
        }
      }
    });

    test('only legal evaluation modes are registered per primitive', () {
      const expected = <ExercisePrimitive, List<EvaluationMode>>{
        ExercisePrimitive.select: [
          EvaluationMode.exactItem,
          EvaluationMode.exactSet,
          EvaluationMode.subset,
          EvaluationMode.orderedSelections,
          EvaluationMode.perSelection,
        ],
        ExercisePrimitive.input: [
          EvaluationMode.exactText,
          EvaluationMode.acceptedTexts,
          EvaluationMode.expression,
          EvaluationMode.numericExact,
          EvaluationMode.numericRange,
          EvaluationMode.numericTolerance,
          EvaluationMode.regex,
          EvaluationMode.manual,
        ],
        ExercisePrimitive.arrange: [
          EvaluationMode.exactOrder,
          EvaluationMode.acceptedOrders,
          EvaluationMode.gapAssignments,
        ],
        ExercisePrimitive.match: [
          EvaluationMode.exactRelations,
          EvaluationMode.requiredRelations,
          EvaluationMode.partialRelations,
        ],
        ExercisePrimitive.assign: [
          EvaluationMode.exactAssignments,
          EvaluationMode.acceptedTargets,
          EvaluationMode.categoryMembership,
          EvaluationMode.partialAssignments,
        ],
        ExercisePrimitive.speak: [
          EvaluationMode.transcriptionMatch,
          EvaluationMode.acceptedTranscriptions,
          EvaluationMode.pronunciation,
          EvaluationMode.combined,
          EvaluationMode.manual,
          EvaluationMode.none,
        ],
        ExercisePrimitive.ink: [
          EvaluationMode.recognition,
          EvaluationMode.strokeMatch,
          EvaluationMode.shapeSimilarity,
          EvaluationMode.manual,
          EvaluationMode.none,
        ],
        ExercisePrimitive.submit: [
          EvaluationMode.presence,
          EvaluationMode.manual,
          EvaluationMode.none,
        ],
        ExercisePrimitive.presentation: [EvaluationMode.none],
      };
      for (final entry in expected.entries) {
        expect(
          PrimitiveCapabilityRegistry.capabilityOf(entry.key).evaluationModes,
          entry.value,
          reason: entry.key.label,
        );
      }
      final registered = PrimitiveCapabilityRegistry.capabilities
          .expand((capability) => capability.evaluationModes)
          .toSet();
      expect(registered, EvaluationMode.values.toSet());
    });

    test('the option inventory matches the specification', () {
      List<String> legal(ExercisePrimitive primitive, OptionKey key) =>
          PrimitiveCapabilityRegistry.legalValues(
            primitive,
            key,
          ).map((value) => value.serialized).toList();
      expect(legal(ExercisePrimitive.select, OptionKey.selectionTarget), [
        'items',
        'textSpans',
        'regions',
        'cells',
      ]);
      expect(legal(ExercisePrimitive.select, OptionKey.layout), [
        'list',
        'grid',
        'inline',
        'overlay',
      ]);
      expect(legal(ExercisePrimitive.select, OptionKey.evaluationTiming), [
        'immediate',
        'explicit',
        'onCompletion',
      ]);
      expect(legal(ExercisePrimitive.input, OptionKey.layout), [
        'field',
        'inlineGaps',
        'grid',
        'multiline',
      ]);
      expect(legal(ExercisePrimitive.input, OptionKey.accentHandling), [
        'exact',
        'missingAccentsAccepted',
        'ignore',
      ]);
      expect(legal(ExercisePrimitive.arrange, OptionKey.itemReuse), [
        'forbidden',
      ]);
      expect(legal(ExercisePrimitive.arrange, OptionKey.placementMode), [
        'sequence',
        'inlineGaps',
        'grid',
      ]);
      expect(legal(ExercisePrimitive.arrange, OptionKey.joiner), [
        'space',
        'none',
      ]);
      expect(legal(ExercisePrimitive.match, OptionKey.interactionStyle), [
        'pair',
        'dropdown',
        'connect',
        'memory',
      ]);
      expect(legal(ExercisePrimitive.assign, OptionKey.targetMode), [
        'categories',
        'slots',
        'gaps',
        'regions',
        'cells',
      ]);
      expect(legal(ExercisePrimitive.assign, OptionKey.placementMode), [
        'drag',
        'selectTarget',
        'tapTarget',
      ]);
      expect(legal(ExercisePrimitive.speak, OptionKey.playback), [
        'none',
        'allowed',
        'requiredBeforeSubmit',
      ]);
      expect(legal(ExercisePrimitive.ink, OptionKey.inkMode), [
        'freehand',
        'trace',
        'character',
        'diagram',
      ]);
      expect(legal(ExercisePrimitive.submit, OptionKey.submissionType), [
        'audio',
        'video',
        'image',
        'file',
        'textDocument',
      ]);
      expect(legal(ExercisePrimitive.presentation, OptionKey.completionMode), [
        'continue',
        'acknowledge',
        'understoodReview',
        'automatic',
      ]);
      expect(legal(ExercisePrimitive.presentation, OptionKey.scoring), [
        'none',
      ]);
      expect(legal(ExercisePrimitive.select, OptionKey.inputMode), isEmpty);
      expect(
        PrimitiveCapabilityRegistry.optionDefinition(
          ExercisePrimitive.assign,
          OptionKey.targetMode,
        )!.required,
        isTrue,
      );
      expect(
        PrimitiveCapabilityRegistry.optionDefinition(
          ExercisePrimitive.submit,
          OptionKey.submissionType,
        )!.required,
        isTrue,
      );
      expect(
        PrimitiveCapabilityRegistry.defaultOf(
          ExercisePrimitive.input,
          OptionKey.accentHandling,
        ),
        const EnumOptionValue(AccentHandling.missingAccentsAccepted),
      );
      expect(
        PrimitiveCapabilityRegistry.defaultOf(
          ExercisePrimitive.select,
          OptionKey.maximumSelections,
        ),
        isNull,
      );
    });

    test('every supported configuration lists every enumeration option', () {
      expect(PrimitiveCapabilityRegistry.runtimeSupportTable, isNotEmpty);
      for (final configuration
          in PrimitiveCapabilityRegistry.runtimeSupportTable) {
        final capability = PrimitiveCapabilityRegistry.capabilityOf(
          configuration.primitive,
        );
        expect(
          capability.evaluationModes,
          containsAll(configuration.evaluationModes),
          reason: configuration.description,
        );
        for (final definition in capability.options) {
          if (definition.key.kind != OptionValueKind.enumeration) continue;
          final listed = configuration.values[definition.key];
          expect(
            listed,
            isNotNull,
            reason:
                '${configuration.description}: ${definition.key.serialized}',
          );
          expect(listed, isNotEmpty, reason: configuration.description);
          expect(
            definition.legalValues,
            containsAll(listed!),
            reason:
                '${configuration.description}: ${definition.key.serialized}',
          );
        }
        for (final key in configuration.values.keys) {
          expect(
            capability.optionDefinition(key),
            isNotNull,
            reason: '${configuration.description}: ${key.serialized}',
          );
        }
      }
      final supported = PrimitiveCapabilityRegistry.runtimeSupportTable
          .map((configuration) => configuration.primitive)
          .toSet();
      expect(supported, ExercisePrimitive.executableToday.toSet());
    });
  });

  group('parsing and validation', () {
    test(
      'unknown, inapplicable and illegal options are reported, not kept',
      () {
        final parsed =
            PrimitiveCapabilityRegistry.parseOptions(ExercisePrimitive.select, {
              'selectionMode': 'multiple',
              'selectionmode': 'single',
              'inputMode': 'text',
              'layout': 'columns',
              'shuffleItems': 'yes',
              'minimumSelections': 0,
              'maximumSelections': 3,
            });
        expect(parsed.options.toJson(), {
          'selectionMode': 'multiple',
          'maximumSelections': 3,
        });
        expect(codes(parsed.violations), [
          CapabilityViolationCode.unknownOption,
          CapabilityViolationCode.optionNotApplicable,
          CapabilityViolationCode.illegalOptionValue,
          CapabilityViolationCode.illegalOptionValue,
          CapabilityViolationCode.illegalOptionValue,
        ]);
        expect(
          parsed.violations
              .where((violation) => violation.key == OptionKey.layout)
              .single
              .message,
          allOf(contains('columns'), contains('list, grid, inline, overlay')),
        );
      },
    );

    test(
      'defaults fill in and illegal values are dropped in effective options',
      () {
        final effective = PrimitiveCapabilityRegistry.effectiveOptions(
          ExercisePrimitive.select,
          options({
            OptionKey.layout: LayoutValue.columns,
            OptionKey.shuffleItems: false,
          }),
        );
        expect(effective.toJson(), {
          'selectionMode': 'single',
          'selectionTarget': 'items',
          'minimumSelections': 1,
          'itemReuse': 'forbidden',
          'layout': 'list',
          'evaluationTiming': 'immediate',
          'shuffleItems': false,
        });
      },
    );

    test('legal configurations produce no violations', () {
      final cases = <(ExercisePrimitive, PrimitiveOptions, EvaluationMode)>[
        (
          ExercisePrimitive.select,
          PrimitiveOptions.empty,
          EvaluationMode.exactItem,
        ),
        (
          ExercisePrimitive.select,
          options({
            OptionKey.selectionMode: SelectionMode.multiple,
            OptionKey.minimumSelections: 2,
            OptionKey.maximumSelections: 4,
            OptionKey.evaluationTiming: EvaluationTiming.explicit,
          }),
          EvaluationMode.exactSet,
        ),
        (
          ExercisePrimitive.select,
          options({
            OptionKey.selectionTarget: SelectionTarget.regions,
            OptionKey.layout: LayoutValue.overlay,
          }),
          EvaluationMode.exactItem,
        ),
        (
          ExercisePrimitive.input,
          PrimitiveOptions.empty,
          EvaluationMode.expression,
        ),
        (
          ExercisePrimitive.input,
          options({OptionKey.inputMode: InputMode.number}),
          EvaluationMode.numericTolerance,
        ),
        (
          ExercisePrimitive.arrange,
          options({
            OptionKey.placementMode: PlacementMode.inlineGaps,
            OptionKey.layout: LayoutValue.inline,
          }),
          EvaluationMode.gapAssignments,
        ),
        (
          ExercisePrimitive.match,
          PrimitiveOptions.empty,
          EvaluationMode.exactRelations,
        ),
        (
          ExercisePrimitive.match,
          options({
            OptionKey.relationship: MatchRelationship.manyToMany,
            OptionKey.itemReuse: ItemReuse.allowed,
            OptionKey.interactionStyle: MatchInteractionStyle.connect,
            OptionKey.layout: LayoutValue.free,
          }),
          EvaluationMode.partialRelations,
        ),
        (
          ExercisePrimitive.assign,
          options({
            OptionKey.targetMode: AssignTargetMode.gaps,
            OptionKey.layout: LayoutValue.inline,
          }),
          EvaluationMode.exactAssignments,
        ),
        (
          ExercisePrimitive.speak,
          options({OptionKey.language: 'it', OptionKey.maxDurationSeconds: 30}),
          EvaluationMode.transcriptionMatch,
        ),
        (
          ExercisePrimitive.ink,
          PrimitiveOptions.empty,
          EvaluationMode.recognition,
        ),
        (
          ExercisePrimitive.submit,
          options({OptionKey.submissionType: SubmissionType.audio}),
          EvaluationMode.presence,
        ),
        (
          ExercisePrimitive.presentation,
          PrimitiveOptions.empty,
          EvaluationMode.none,
        ),
      ];
      for (final (primitive, given, mode) in cases) {
        expect(
          PrimitiveCapabilityRegistry.validate(
            primitive: primitive,
            options: given,
            evaluationMode: mode,
          ),
          isEmpty,
          reason: '${primitive.label} ${mode.serialized} ${given.toJson()}',
        );
      }
    });

    test('illegal combinations and pairings are coded', () {
      List<CapabilityViolation> check(
        ExercisePrimitive primitive,
        PrimitiveOptions given,
        EvaluationMode? mode,
      ) => PrimitiveCapabilityRegistry.validate(
        primitive: primitive,
        options: given,
        evaluationMode: mode,
      );

      final singleWithLimits = check(
        ExercisePrimitive.select,
        options({OptionKey.maximumSelections: 3}),
        EvaluationMode.exactItem,
      );
      expect(codes(singleWithLimits), [
        CapabilityViolationCode.illegalCombination,
      ]);
      expect(singleWithLimits.single.ruleId, 'select.single.maximum');

      final setOnSingle = check(
        ExercisePrimitive.select,
        PrimitiveOptions.empty,
        EvaluationMode.exactSet,
      );
      expect(codes(setOnSingle), [
        CapabilityViolationCode.evaluationRequiresOption,
        CapabilityViolationCode.evaluationRequiresOption,
      ]);
      expect(setOnSingle.map((violation) => violation.ruleId), [
        'select.set.multiple',
        'select.set.timing',
      ]);

      final minAboveMax = check(
        ExercisePrimitive.select,
        options({
          OptionKey.selectionMode: SelectionMode.multiple,
          OptionKey.minimumSelections: 3,
          OptionKey.maximumSelections: 2,
          OptionKey.evaluationTiming: EvaluationTiming.explicit,
        }),
        EvaluationMode.exactSet,
      );
      expect(minAboveMax.single.ruleId, 'select.limits.order');

      expect(
        check(
          ExercisePrimitive.select,
          options({OptionKey.selectionTarget: SelectionTarget.textSpans}),
          EvaluationMode.exactItem,
        ).single.ruleId,
        'select.textSpans.layout',
      );
      expect(
        check(
          ExercisePrimitive.select,
          options({OptionKey.itemReuse: ItemReuse.unlimited}),
          EvaluationMode.exactItem,
        ).single.ruleId,
        'select.reuse.inline',
      );
      expect(
        check(
          ExercisePrimitive.input,
          PrimitiveOptions.empty,
          EvaluationMode.numericExact,
        ).single.ruleId,
        'input.numeric.mode',
      );
      expect(
        check(
          ExercisePrimitive.input,
          options({OptionKey.cardinality: Cardinality.multiple}),
          EvaluationMode.expression,
        ).single.ruleId,
        'input.multiple.layout',
      );
      expect(
        check(
          ExercisePrimitive.arrange,
          PrimitiveOptions.empty,
          EvaluationMode.gapAssignments,
        ).single.ruleId,
        'arrange.gapAssignments.placement',
      );
      expect(
        codes(
          check(
            ExercisePrimitive.arrange,
            options({OptionKey.itemReuse: ItemReuse.allowed}),
            EvaluationMode.exactOrder,
          ),
        ),
        [CapabilityViolationCode.illegalOptionValue],
      );
      expect(
        check(
          ExercisePrimitive.match,
          options({OptionKey.interactionStyle: MatchInteractionStyle.memory}),
          EvaluationMode.exactRelations,
        ).single.ruleId,
        'match.memory.layout',
      );
      expect(
        check(
          ExercisePrimitive.match,
          options({OptionKey.relationship: MatchRelationship.oneToMany}),
          EvaluationMode.exactRelations,
        ).single.ruleId,
        'match.many.reuse',
      );
      expect(
        codes(
          check(
            ExercisePrimitive.assign,
            PrimitiveOptions.empty,
            EvaluationMode.exactAssignments,
          ),
        ),
        [CapabilityViolationCode.missingRequiredOption],
      );
      expect(
        check(
          ExercisePrimitive.assign,
          options({
            OptionKey.targetMode: AssignTargetMode.gaps,
            OptionKey.layout: LayoutValue.inline,
            OptionKey.targetCapacity: TargetCapacity.multiple,
          }),
          EvaluationMode.exactAssignments,
        ).single.ruleId,
        'assign.gaps.capacity',
      );
      expect(
        check(
          ExercisePrimitive.speak,
          options({OptionKey.speechMode: SpeechMode.freeResponse}),
          EvaluationMode.pronunciation,
        ).single.ruleId,
        'speak.freeResponse.evaluation',
      );
      expect(
        check(
          ExercisePrimitive.speak,
          options({OptionKey.transcription: TranscriptionMode.none}),
          EvaluationMode.combined,
        ).single.ruleId,
        'speak.transcription.needed',
      );
      expect(
        check(
          ExercisePrimitive.ink,
          options({OptionKey.strokeOrder: StrokeOrder.checked}),
          EvaluationMode.recognition,
        ).single.ruleId,
        'ink.strokeOrder.mode',
      );
      expect(
        check(
          ExercisePrimitive.submit,
          options({
            OptionKey.submissionType: SubmissionType.file,
            OptionKey.evaluationTiming: EvaluationTiming.none,
          }),
          EvaluationMode.presence,
        ).map((violation) => violation.ruleId),
        ['submit.noTiming.evaluation', 'submit.evaluated.timing'],
      );
      expect(
        check(
          ExercisePrimitive.submit,
          options({
            OptionKey.submissionType: SubmissionType.file,
            OptionKey.captureSource: CaptureSource.device,
          }),
          EvaluationMode.presence,
        ).single.ruleId,
        'submit.device.type',
      );
      expect(
        codes(
          check(
            ExercisePrimitive.presentation,
            PrimitiveOptions.empty,
            EvaluationMode.exactItem,
          ),
        ),
        [CapabilityViolationCode.illegalEvaluationMode],
      );
      expect(
        codes(check(ExercisePrimitive.match, PrimitiveOptions.empty, null)),
        [CapabilityViolationCode.missingEvaluationMode],
      );
      expect(
        codes(
          check(
            ExercisePrimitive.speak,
            options({OptionKey.selectionMode: SelectionMode.single}),
            EvaluationMode.none,
          ),
        ),
        [CapabilityViolationCode.optionNotApplicable],
      );
      expect(
        codes(
          check(
            ExercisePrimitive.select,
            options({OptionKey.evaluationTiming: EvaluationTiming.none}),
            EvaluationMode.exactItem,
          ),
        ),
        [CapabilityViolationCode.illegalOptionValue],
      );
    });

    test('impossible selection limits are detected with the items', () {
      final exactSet = PrimitiveCapabilityRegistry.checkSelectionLimits(
        options: options({
          OptionKey.selectionMode: SelectionMode.multiple,
          OptionKey.minimumSelections: 3,
          OptionKey.maximumSelections: 3,
        }),
        evaluationMode: EvaluationMode.exactSet,
        correctCount: 2,
        itemCount: 4,
      );
      expect(codes(exactSet), [
        CapabilityViolationCode.selectionLimitsImpossible,
      ]);
      expect(exactSet.single.message, contains('minimumSelections (3)'));

      expect(
        PrimitiveCapabilityRegistry.checkSelectionLimits(
          options: options({
            OptionKey.selectionMode: SelectionMode.multiple,
            OptionKey.maximumSelections: 1,
          }),
          evaluationMode: EvaluationMode.exactSet,
          correctCount: 2,
          itemCount: 4,
        ).single.message,
        contains('maximumSelections (1)'),
      );
      expect(
        PrimitiveCapabilityRegistry.checkSelectionLimits(
          options: options({
            OptionKey.selectionMode: SelectionMode.multiple,
            OptionKey.maximumSelections: 5,
          }),
          evaluationMode: EvaluationMode.exactSet,
          correctCount: 2,
          itemCount: 4,
        ).single.message,
        contains('exceeds the number of items'),
      );
      expect(
        PrimitiveCapabilityRegistry.checkSelectionLimits(
          options: PrimitiveOptions.empty,
          evaluationMode: EvaluationMode.exactItem,
          correctCount: 2,
          itemCount: 4,
        ).single.message,
        contains('exactly one correct item'),
      );
      expect(
        PrimitiveCapabilityRegistry.checkSelectionLimits(
          options: PrimitiveOptions.empty,
          evaluationMode: EvaluationMode.exactItem,
          correctCount: 0,
          itemCount: 4,
        ).single.message,
        contains('At least one correct item'),
      );
      expect(
        PrimitiveCapabilityRegistry.checkSelectionLimits(
          options: options({
            OptionKey.selectionMode: SelectionMode.multiple,
            OptionKey.minimumSelections: 2,
            OptionKey.maximumSelections: 3,
          }),
          evaluationMode: EvaluationMode.exactSet,
          correctCount: 3,
          itemCount: 4,
        ),
        isEmpty,
      );
    });
  });

  group('runtime support', () {
    ExerciseRuntimeSupport support(
      ExercisePrimitive primitive,
      PrimitiveOptions given,
      EvaluationMode? mode,
    ) => PrimitiveCapabilityRegistry.runtimeSupport(
      primitive: primitive,
      options: given,
      evaluationMode: mode,
    );

    test("today's behaviors are executable", () {
      final executable =
          <(ExercisePrimitive, PrimitiveOptions, EvaluationMode)>[
            (
              ExercisePrimitive.select,
              PrimitiveOptions.empty,
              EvaluationMode.exactItem,
            ),
            (
              ExercisePrimitive.select,
              options({OptionKey.layout: LayoutValue.grid}),
              EvaluationMode.exactItem,
            ),
            (
              ExercisePrimitive.select,
              options({
                OptionKey.selectionMode: SelectionMode.multiple,
                OptionKey.minimumSelections: 2,
                OptionKey.maximumSelections: 4,
                OptionKey.evaluationTiming: EvaluationTiming.explicit,
              }),
              EvaluationMode.exactSet,
            ),
            (
              ExercisePrimitive.select,
              options({
                OptionKey.layout: LayoutValue.inline,
                OptionKey.itemReuse: ItemReuse.unlimited,
                OptionKey.evaluationTiming: EvaluationTiming.explicit,
              }),
              EvaluationMode.exactItem,
            ),
            (
              ExercisePrimitive.input,
              PrimitiveOptions.empty,
              EvaluationMode.expression,
            ),
            (
              ExercisePrimitive.input,
              options({
                OptionKey.typoTolerance: TypoTolerance.conservative,
                OptionKey.accentHandling: AccentHandling.exact,
              }),
              EvaluationMode.acceptedTexts,
            ),
            (
              ExercisePrimitive.input,
              options({
                OptionKey.cardinality: Cardinality.multiple,
                OptionKey.layout: LayoutValue.inlineGaps,
              }),
              EvaluationMode.expression,
            ),
            (
              ExercisePrimitive.arrange,
              PrimitiveOptions.empty,
              EvaluationMode.exactOrder,
            ),
            (
              ExercisePrimitive.arrange,
              options({
                OptionKey.joiner: Joiner.none,
                OptionKey.unusedItems: UnusedItems.forbidden,
              }),
              EvaluationMode.acceptedOrders,
            ),
            (
              ExercisePrimitive.arrange,
              options({
                OptionKey.placementMode: PlacementMode.inlineGaps,
                OptionKey.layout: LayoutValue.inline,
              }),
              EvaluationMode.gapAssignments,
            ),
            (
              ExercisePrimitive.match,
              PrimitiveOptions.empty,
              EvaluationMode.exactRelations,
            ),
            (
              ExercisePrimitive.presentation,
              PrimitiveOptions.empty,
              EvaluationMode.none,
            ),
            (
              ExercisePrimitive.presentation,
              options({
                OptionKey.completionMode: CompletionMode.understoodReview,
                OptionKey.mediaPlayback: MediaPlayback.automatic,
              }),
              EvaluationMode.none,
            ),
          ];
      for (final (primitive, given, mode) in executable) {
        final result = support(primitive, given, mode);
        expect(
          result.state,
          ExerciseSupportState.executable,
          reason:
              '${primitive.label} ${mode.serialized} ${given.toJson()}: ${result.reason}',
        );
        expect(result.configuration, isNotNull);
      }
    });

    test(
      'legal but unimplemented configurations are readable, not executable',
      () {
        final readable =
            <(ExercisePrimitive, PrimitiveOptions, EvaluationMode)>[
              (
                ExercisePrimitive.select,
                options({
                  OptionKey.evaluationTiming: EvaluationTiming.onCompletion,
                }),
                EvaluationMode.exactItem,
              ),
              (
                ExercisePrimitive.select,
                options({
                  OptionKey.selectionMode: SelectionMode.multiple,
                  OptionKey.evaluationTiming: EvaluationTiming.explicit,
                }),
                EvaluationMode.subset,
              ),
              (
                ExercisePrimitive.select,
                options({
                  OptionKey.selectionTarget: SelectionTarget.textSpans,
                  OptionKey.layout: LayoutValue.inline,
                  OptionKey.evaluationTiming: EvaluationTiming.explicit,
                }),
                EvaluationMode.exactItem,
              ),
              (
                ExercisePrimitive.select,
                options({
                  OptionKey.selectionTarget: SelectionTarget.regions,
                  OptionKey.layout: LayoutValue.overlay,
                }),
                EvaluationMode.exactItem,
              ),
              (
                ExercisePrimitive.input,
                options({OptionKey.inputMode: InputMode.number}),
                EvaluationMode.numericExact,
              ),
              (
                ExercisePrimitive.input,
                PrimitiveOptions.empty,
                EvaluationMode.regex,
              ),
              (
                ExercisePrimitive.input,
                PrimitiveOptions.empty,
                EvaluationMode.manual,
              ),
              (
                ExercisePrimitive.input,
                options({OptionKey.layout: LayoutValue.multiline}),
                EvaluationMode.expression,
              ),
              (
                ExercisePrimitive.arrange,
                options({
                  OptionKey.placementMode: PlacementMode.grid,
                  OptionKey.layout: LayoutValue.grid,
                }),
                EvaluationMode.exactOrder,
              ),
              (
                ExercisePrimitive.arrange,
                options({OptionKey.layout: LayoutValue.vertical}),
                EvaluationMode.exactOrder,
              ),
              (
                ExercisePrimitive.match,
                options({
                  OptionKey.interactionStyle: MatchInteractionStyle.pair,
                }),
                EvaluationMode.exactRelations,
              ),
              (
                ExercisePrimitive.match,
                options({
                  OptionKey.relationship: MatchRelationship.oneToMany,
                  OptionKey.itemReuse: ItemReuse.allowed,
                }),
                EvaluationMode.exactRelations,
              ),
              (
                ExercisePrimitive.assign,
                options({OptionKey.targetMode: AssignTargetMode.categories}),
                EvaluationMode.exactAssignments,
              ),
              (
                ExercisePrimitive.speak,
                PrimitiveOptions.empty,
                EvaluationMode.transcriptionMatch,
              ),
              (
                ExercisePrimitive.ink,
                PrimitiveOptions.empty,
                EvaluationMode.recognition,
              ),
              (
                ExercisePrimitive.submit,
                options({OptionKey.submissionType: SubmissionType.image}),
                EvaluationMode.presence,
              ),
              (
                ExercisePrimitive.presentation,
                options({OptionKey.navigation: PresentationNavigation.paged}),
                EvaluationMode.none,
              ),
              (
                ExercisePrimitive.presentation,
                options({OptionKey.completionMode: CompletionMode.automatic}),
                EvaluationMode.none,
              ),
            ];
        for (final (primitive, given, mode) in readable) {
          final result = support(primitive, given, mode);
          expect(
            result.state,
            ExerciseSupportState.readableButNotExecutable,
            reason:
                '${primitive.label} ${mode.serialized} ${given.toJson()}: ${result.reason}',
          );
          expect(
            result.reason,
            contains('kept, editable and exported unchanged'),
          );
        }
      },
    );

    test('an illegal configuration is invalid, never executable', () {
      final result = support(
        ExercisePrimitive.select,
        PrimitiveOptions.empty,
        EvaluationMode.exactSet,
      );
      expect(result.state, ExerciseSupportState.invalid);
      expect(result.violations, isNotEmpty);
      expect(
        support(ExercisePrimitive.select, PrimitiveOptions.empty, null).state,
        ExerciseSupportState.invalid,
      );
    });
  });
}
