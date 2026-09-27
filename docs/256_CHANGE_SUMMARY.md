# Build 256 change summary

Build 256 is the exercise architecture redesign (Course Model v12). Its six
sessions are Revisions 0–5. Plan: `256_EXERCISE_ARCHITECTURE_PLAN.md`;
reference: `EXERCISE_ARCHITECTURE_V12.md`; evidence: `256_VALIDATION.md`.

## Revision 0 (2.0.56+256000, 27 September 2026): canonical definitions

Session 1. No Course JSON, learner, Audit or editor behavior changes.

### Files

- New `lib/models/canonical/`: `exercise_primitive.dart`,
  `evaluation_mode.dart`, `primitive_options.dart`,
  `primitive_capability_registry.dart`, `content_flow.dart` and the barrel
  `canonical.dart`.
- `lib/models/exercise_authoring.dart`: `ExercisePreset.primitive`
  (`ExercisePrimitive`) replaces `model` (`CanonicalExerciseModel`, removed).
- `lib/services/course_audit_service.dart`: the preset-versus-response check
  reads `preset.primitive.serialized`.
- Tests: new `canonical_primitives_256_test.dart`,
  `capability_registry_256_test.dart`, `content_flow_256_test.dart`; updated
  `exercise_architecture_224_test.dart`, `translation_choice_239_test.dart`,
  `exercise_laboratory_254_test.dart` (field rename) and the version tests.
- Docs: new `EXERCISE_ARCHITECTURE_V12.md`, `256_EXERCISE_ARCHITECTURE_PLAN.md`,
  `256_HANDOFF.md`, this file and `256_VALIDATION.md`;
  `EXERCISE_ARCHITECTURE_224.md` marked historical; README, CHANGELOG,
  AGENTS.md release boundary.
- Version `2.0.56+256000`; Beta expiry 27 October 2026 (unchanged date; the
  comment and the test title now name Build 256 Revision 0).

### Architecture decisions implemented

- Exactly nine primitives with strict lowercase identifiers; `executableToday`
  is documentation only, executability is decided per exercise.
- One option vocabulary: `OptionKey` (stable JSON name, value kind, union
  vocabulary), closed `OptionEnumValue` enums, `OptionValue` (enum, bool,
  int, language tag) with a parser that never coerces, `PrimitiveOptions`
  storing only what was given.
- `PrimitiveCapabilityRegistry`: per-primitive `OptionDefinition`s (legal
  subset, default, required, minimum), evaluation modes with a default,
  coded rules (`OptionImplication`, `OptionRequiresIntegers`,
  `EvaluationImplication`, `OptionEvaluationImplication`,
  `IntegerOrderRule`), `checkSelectionLimits`, `parseOptions`,
  `effectiveOptions`, `validate`, and the `runtimeSupportTable` of
  `SupportedConfiguration`s behind `runtimeSupport` (states executable,
  readableButNotExecutable, invalid; unsupportedModelVersion reserved for
  the Course level).
- `ContentFlow`: `FlowNode` (content or exercise, contentId),
  `FlowTransition` (next, onCorrect, onIncorrect, onChoice with
  choiceItemId, conditional with a `FlowCondition`), structural checks,
  `isLinear` and `linearNodeIds`, `ContentFlow.linear`.
- Final names for the plan's A.4 fields and the converter's list of
  behaviors that do not map cleanly are in `EXERCISE_ARCHITECTURE_V12.md`.

### Known limitations and deferrals

- Nothing is serialized yet: options, flows and the A.4 element attributes
  get their JSON form in Session 2.
- The runtime-support table describes today's behaviors; Session 3 makes the
  runtime read it, Session 6 adds Assign.
- Speak, Ink, Submit and Assign have definitions only.
