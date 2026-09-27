# Build 256 change summary

Build 256 is the exercise architecture redesign (Course Model v12). Its six
sessions are Revisions 0–5. Plan: `256_EXERCISE_ARCHITECTURE_PLAN.md`;
reference: `EXERCISE_ARCHITECTURE_V12.md`; evidence: `256_VALIDATION.md`.

## Revision 1 (2.0.56+256001, 27 September 2026): Course Model v12

Session 2. Course files change format (clean cut); learner, Audit and
editor behavior do not, apart from one editor fix.

### Files

- `lib/models/exercise_canonical.dart` (new): `ExerciseTarget`,
  `LayoutElement`, `CanonicalEvaluation`, `ExerciseFeedback`,
  `OrderedAnswer`, the element attribute enums, strict JSON parsing
  (unknown keys are format errors).
- `lib/models/course_models.dart`: `Course.currentFormatVersion = 12`;
  `LearningRound.flow`; `LearningContent` with `authoringMetadata` and the
  derived views `kind`, `exercise`, `editorTemplate`, `presentation`;
  `PromptElement.language/playback/required`; `ExerciseItem.side`;
  `Exercise` rebuilt on the canonical fields (`Exercise.canonical`,
  `toJson`/`fromJson`, `effectiveOptions`, `semanticJson`,
  `semanticallyEquals`, `copyWith`, `withPublicationState`,
  `withAuthoringMetadata`), `Exercise.convertV11` as the one v11 → v12
  mapping (used by `Exercise.v2` and the legacy constructor), and the
  v11-shaped read-only views kept for the runtime, Audit and editor until
  Sessions 3–4.
- `lib/models/canonical/content_flow.dart`: JSON for flows, nodes,
  transitions and conditions.
- `lib/services/course_model_v12_converter.dart` (new, no Flutter imports):
  `convertCourseJsonToV12` with plain-language notes.
- `tools/convert_course_to_v12.dart` (new: JSON or ZIP, `--overwrite`),
  `tools/convert_stored_courses_256.dart` (new, one-off device
  conversion), `tools/qql_course_v12.py` (new Python mirror),
  `tools/validate_courses.py` (v12), the three `tools/generate_*_254.py`
  generators (emit v12); `tools/convert_course_to_v11.dart` retired.
- Storage: `CourseFileStore.rootDirectoryName = 'QQL_Courses_v12'`;
  `QqlEarlierPrivateFolders.coursesV11` (retired `QQL_Courses`);
  `CourseBackupService.backupFormat` 12 with `earlierBackupFormat`;
  `InventoryService` label.
- Call sites moved from `arrangeLayout`/`arrangeGapAssignments` to
  `layout`/`targetAssignments`: `round_screen`, `course_editor_screen`,
  `course_audit_service`, `course_image_usage`,
  `authoring_duplication_service` (deep-copies answers),
  `exercise_draft_builder`; `exercise_search_service` indexes
  `inlineSentence`.
- Editor: `_withExercisePublication` and `_withSelectedSharedSource` copy
  the canonical exercise instead of rebuilding it through the v11 views.
- `lib/services/course_image_removal.dart` clears image uses from the v12
  `items` JSON (it still read the v11 `interaction`; found by the
  complete suite).
- Data: `assets/courses/*.json` (four bundled Courses), the demo package
  JSON and ZIP, the Publisher fixtures (`dummy-*.json`, re-signed with the
  test key; `dummy-signed-media.zip` rebuilt); `test/fixtures/v11/` holds
  the v11 originals.
- Help EN/IT/ES: every line that named the format or the converter.
- Docs: `COURSE_JSON_FORMAT.md` (format 12), `239_RESET_STORAGE_INVENTORY.md`,
  `EXERCISE_ARCHITECTURE_V12.md` (status, JSON section), AGENTS.md
  (invariants rewritten for v12, boundary entry), README, CHANGELOG.
- Tests: `test/course_model_v12_256_test.dart` (new) and the updated v11
  suites listed in `256_VALIDATION.md`.

### Architecture decisions implemented

- Plan §A.4 (extra canonical fields), §A.8 and §A.14 (clean cut, storage
  Option 2, one-off tool), §A.13 (semantic equality; v11 shapes as helpers
  only), §B Session 2.
- One mapping, three homes: `Exercise.convertV11` (memory),
  `convertCourseJsonToV12` (files), `qql_course_v12.py` (generators); the
  parity test in `course_model_v11_243_test.dart` compares Dart and Python
  output on every bundled Course.
- The runtime is not moved yet: the v11 views on `Exercise` exist so that
  Session 2 changes the format without changing behavior; Sessions 3–4
  remove them.

### Known limitations and deferrals

- Options, flows and executability are stored and validated but not yet
  read by the runtime or the Audit (Session 3); presets still act as
  templates in the editor (Session 4).
- A Presentation converted from a v11 file gets its Round's `updatedAt`
  (v11 presentations had none).
- The package manifest keeps `packageFormat: 1`; Publisher Courses must be
  re-signed after conversion.

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
