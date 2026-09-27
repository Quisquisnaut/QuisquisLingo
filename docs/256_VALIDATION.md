# Build 256 validation

Evidence per revision. Commands run from `C:\QQL\QuisquisLingo` (that
spelling) with Flutter 3.47.4 / Dart 3.13.3 on Windows 10, the complete
suite through the keep-awake wrapper (`ES_CONTINUOUS | ES_SYSTEM_REQUIRED`
held for the run and cleared afterwards).

## Revision 3 (2.0.56+256003): presets as recipes and the Generic Primitive Editor, 27 September 2026

- Recipes first: `test/preset_recipes_256_test.dart` (83 tests) proves every
  Laboratory example is represented by its own preset, is recognized again
  once its metadata is stripped, that a shape no recipe expresses (an extra
  spoken text on a Choose) is not recognized, and that recognition writes
  nothing. Green before the editor was touched.
- Editor batch after the editor started decomposing through the recipes
  (every test naming the exercise editor, the draft builder or the Course
  Editor file, plus the Laboratory): **971 passed, 0 failed**.
- Generic Primitive Editor: `test/primitive_editor_256_test.dart` (an
  untouched draft rebuilds all 80 Laboratory exercises unchanged with their
  metadata; a changed draft keeps only a preset that still represents it,
  and a hinted Choose is unrepresentable because the Choose form has no hint
  field; a blank exercise; saving an unchanged exercise returns the same
  object; moving the correct answer keeps the preset and stamps the clock; a
  Select built from nothing is recognized as Choose; read-only and
  Inspection). Two expectations were corrected after the first run (the
  hint case and the recognized Choose); **7 passed** on the rerun.
- Canonical reads and wiring batch (editor, Audit, Search, hierarchy,
  Recognize characters, Laboratory, runtime, recipes, primitive editor;
  every test naming the exercise editor, the draft builder, the Course
  Editor file or the Audit service): **1,215 passed, 0 failed** (`All tests
  passed!` after 12 minutes 39 seconds).
- Stories: `test/round_flow_authoring_256_test.dart` (linear flows follow
  content order; `forContent` keeps none, regenerates linear, keeps
  branching; `remapped` renames nodes, content, targets, choices and
  conditions; duplication keeps a flow over the copied IDs; copying an
  exercise into a Story extends its flow; the Round editor keeps a Story
  and its switch turns a practice Round into a linear Story and back):
  **7 passed** after two fixture corrections (Move/Copy and Copy as New
  Course refuse an official Course, so the fixture is a licensed Fork of
  the Laboratory, which also proves the fork carries the flow; the fork's
  content is Draft, so the editor test saves as draft).
- Third batch (the flow, primitive editor and recipe tests with
  `localization_catalog_test` (EN/IT/ES key parity, section IDs), the QQL
  Guide, Editor Help, version, Beta, transfer, hierarchy-indicator and
  duplication tests): **429 passed, 1 failed** (the official-Course
  fixture above, then fixed and rerun green).
- `dart format` on the changed files (8 reformatted); `flutter analyze
  --no-pub`: **No issues found** after every step.
- Version pins: a first complete run (12:09) was stopped at +196 when
  `app_metadata_225_04_test` failed on the old build number; that file,
  `course_audit_report_225_test` and README's Beta sentence were moved to
  Revision 3 (the integer `correctiveRevision` pin needed a second look),
  the five version and Beta tests passed (27 tests) and the suite was
  restarted.
- Complete suite on the final working tree (`flutter test --no-pub
  --concurrency=1` under the keep-awake wrapper, 12:05–12:26): **2,937
  passed, 1 skipped, 0 failed** (`All tests passed!` after 21 minutes
  2 seconds).

## Revision 3 follow-up (same version), 27 September 2026, afternoon

- Reproduction first: a widget test at 1280×800, 900×600 and 700×480 found
  both wizard buttons on screen (the owner's "missing wizards" were the
  editors' bottom bar under the Windows taskbar on a window taller than the
  work area; the runner now clamps the window), and neither discard prompt
  reproduced with the Laboratory exercises (the editors now decide by
  comparison, which removes the prompt whatever raised the flag).
- `test/revision3_followup_256_test.dart` (new): flow presentation JSON
  (scroll stored, step omitted, unknown value refused) and its survival
  through `forContent`, `remapped` and `withPresentation`; blank Assign,
  Submit, Speak and Ink drafts legal from the start and `changePrimitive`
  filling required options; the canonical editor not asking after a
  re-selected mode and asking after a primitive change, and Assign/Submit
  without a registry refusal; the Match the pairs form not asking after a
  focused field and asking after typing; the Round editor's two buttons,
  the Draft Exercises message on Save, and the Story control writing
  `presentation: scroll`; a scrolling Story keeping the first item, its
  answer and the second question on one page through Next and Finish
  round; the first-time introduction shown once and remembered; the Help
  catalogs naming the wizards, the two buttons and Scrolling in EN/IT/ES.
- Focused batch (the new file with every Round editor, exercise editor,
  Round screen, flow, Help and localization test): **703 passed, 2
  failed**, both corrected and rerun green: the Draft Exercises message
  now appears only when the Audit refuses the save, so a Round with a
  Published Exercise and a Draft duplicate still saves
  (`authoring_context_menu_224_test`); the Match the pairs test targets
  the `exercise-field-pairs` key and the editors are pushed above a home
  page, so Back pops to it (`revision3_followup_256_test`: 11 passed).
- `dart format` on the changed files (4 reformatted); `flutter analyze
  --no-pub`: **No issues found**.
- Complete suite on the final working tree (`flutter test --no-pub
  --concurrency=1` under the keep-awake wrapper, 14:28–14:52): **2,948
  passed, 1 skipped, 0 failed** (`All tests passed!` after 24 minutes
  11 seconds).

## Revision 2 (2.0.56+256002): runtime and Audit on canonical data, 27 September 2026

- Baseline first: `exercise_laboratory_254_test` records what the Round
  screen shows for every one of the 80 Laboratory examples before and after
  the correct answer (`_presentation`); the records were captured in record
  mode (`QQL_RECORD_PRESENTATION`, 165 tests passed) before any runtime
  change and compared afterwards on every batch. The only differences are
  the three marked in `test/support/laboratory_presentation_254.dart`:
  Match the words' instruction (its sides now carry languages), and the
  Dialogue response situation shown once instead of twice (before and
  after answering).
- Validators outside the Flutter suite after each converter refinement:
  `python -X utf8 tools/validate_courses.py` (four v12 files), the three
  generators' checks, the Korean Course reconverted from its v11 fixture,
  parity in `course_model_v11_243_test`.
- `dart format` on the changed Dart files: nothing to change on the final
  tree. `flutter analyze --no-pub`: **No issues found** (interim lint
  findings, all `curly_braces_in_flow_control_structures` and one
  `unnecessary_import`, were fixed as they appeared).
- Focused batches during the session, each green before the next step:
  the converter, Laboratory and bundled-Course tests after the role
  refinements (300 passed); every Round-screen test plus the copy,
  converter and bundled tests after the heading switched to the derived
  kind (483 passed, 2 deliberate Match-instruction records then updated);
  the same after the Round-screen refactor (427 passed, 1 deliberate
  dialogue record then updated); the Round, Duel, audio and playability
  tests after the Duel and availability changes (475 passed, 1 fixed: Pick
  the translation's audio had to be `required: false`); the translation,
  runtime, converter and package tests (104 passed, 1 fixed: a Story's end
  button still offered the mistake review); every Audit-related test with
  the Laboratory and runtime tests after the Audit rewrite (583 passed, 8
  failed, all resolved: pinned code counts and severities, the duplicate
  content key, the three-pair rule applied to Match the words, the
  image-word wording, the single-selection correct-count rule, the short
  listening passage rule tied to its preset); the registry, bundled-Course,
  Audit and Laboratory files again (**197 passed**); the version tests and
  `localization_catalog_test` before the suite.
- New tests: `test/runtime_canonical_256_test.dart` (the kind every
  preset's exercises derive to in all four bundled Courses; headings need
  no preset; Duel eligibility by capability with Contextual comprehension
  and Recognize characters in and multiple-answer Choose out; audio
  exercises by required audio incl. the bundled Pick the translation
  exercises; a linear Story plays five nodes in authored order without a
  mistake review; a branching Story is not playable; two identical blocks
  fill either gap). Rewritten: the Duel eligibility preset-list test
  (canonical eligibility), the registry counts (102 rules: 56 Errors, 40
  Warnings, 6 Info), the severity pins of the preset rules.
- Complete suite on the final working tree (second run, 09:44–10:07): **2,840 passed, 1 skipped, 0 failed** (`All tests passed!` after 22 minutes 51 seconds). A first complete run on the pre-fix tree (09:14–09:36, 22 minutes 13 seconds) had given 2,837 passed, 1 skipped, 3 failed: `course_image_removal_test` (the image-word image rule had become a Warning; restored as an Error, a solvability rule of word-building Arrange emitted by kind), `imported_course_v6_regression_test` (a source-structure test pinned the v11 preset dispatch; it now checks the canonical dispatch), and `authoring_transfer_ui_226_02_test` (its destination Round was red only because of the retired unexpected-field warning on a Choose with a hint; it now expects green). The affected files were rerun (216 passed) before this final run.

## Revision 1 (2.0.56+256001): Course Model v12, 27 September 2026

- Validators outside the Flutter suite: `python -X utf8 tools/validate_courses.py`
  validates the four bundled Course Model v12 files; the three generators'
  `--check` runs (Exercise Laboratory 5 Lessons, 19 Rounds, 80 examples, 24
  presets; Edge Case matches its deterministic generator; Piedmontese 24
  named types, 24 Lessons, 72 examples) pass.
- `dart format` on the 63 changed Dart files: nothing to change. (A
  tree-wide run earlier in the session reformatted 61 files that predate
  Build 256; those were reverted with `git checkout --`, as unrelated
  formatting is out of scope.)
- `flutter analyze --no-pub`: **No issues found** (one `unnecessary_import`
  in `exercise_architecture_224_test.dart` was removed first: the canonical
  primitive import became redundant once `course_models.dart` exports it).
- Focused batch, first pass (45 test files touched by the session, plus the
  version tests and `localization_catalog_test`): 688 tests, **686 passed,
  2 failed**: `course_model_v6_test` still expected `formatVersion` 11, and
  the Publisher conversion test in `course_model_v11_243_test` lacked the
  official provenance (`originalCourseCreator` of type publisher, release
  date, checksum, distribution channel) that the v12 constructor requires.
  Both fixed; second pass of the two files: **62 passed**.
- Complete suite, first run (`flutter test --no-pub --concurrency=1`,
  07:14–07:36, 22 minutes 11 seconds): **2,812 passed, 1 skipped, 17
  failed** in seven files the focused batch had not covered. Causes and
  fixes: `course_image_removal_test` built its presentations in the v11
  `kind: presentation` shape (fixture moved to the `presentation`
  primitive) and exposed a real gap, `CourseImageRemoval` still read the
  v11 `interaction.items` JSON, so item images would no longer have been
  cleared (now reads v12 `items`); `course_options_226_04_test`,
  `course_ownership_team_229_r1_test`, `course_transfer_v6_225_02_test`
  pinned format 11 or the "format 11 only" message (a sweep of the test
  tree found five more such pins, in `guidebook_publication_226_02_revision4_test`,
  `qql_233_course_governance_test`, `provisional_draft_model_test`,
  `piedmontais_course_254_test` and `sample_courses_test`; they were
  corrected while the run was in progress, before the runner reached those
  files, so they are not among the 17); `flat_image_library_243_source_test` read
  `exercise.interaction.items` from the demo JSON;
  `production_course_transaction_225_04_test` wrote an `id` inside the
  exercise object, which v12 refuses (the Content ID is the exercise ID);
  `publisher_signing_help_test` compares `docs/PUBLISHER_SIGNING_GUIDE.md`
  with the English Help, so the guide received the same v12 wording.
- Focused re-run of the fourteen fixed or affected files
  (`course_image_removal`, `course_image_usage`, `course_options_226_04`,
  `course_ownership_team_229_r1`, `course_transfer_v6_225_02`,
  `guidebook_publication_226_02_revision4`, `qql_233_course_governance`,
  `provisional_draft_model`, `piedmontais_course_254`, `sample_courses`,
  `publisher_signing_help`, `production_course_transaction_225_04`,
  `flat_image_library_243_source`, `flat_image_library_removal`):
  **109 passed, 0 failed**.
- Complete suite, second run on the final working tree (`flutter test --no-pub --concurrency=1`, 07:40–08:02, 21 minutes 59 seconds):
  **2,829 passed, 1 skipped, 0 failed** (`All tests passed!`).
- New tests (`test/course_model_v12_256_test.dart`): parsing and
  serialization of every canonical field, authoring metadata present,
  absent and unknown, semantic equality (default options, IDs and item
  order), invalid primitive, option and pairing refusals, inline layout,
  linear flow round trip, representative v11 conversions, the v11 Content
  shapes refused with the tool named, the conversion tool on JSON and ZIP,
  the one-off stored-Course tool, and the storage cut (the Build 255 store
  never read, a v11 backup named as unreadable). `course_model_v11_243_test`
  gained the converter group: generator/converter parity on every bundled
  Course, the demo package, notes for stale fields and non-standard
  presentation actions, a Publisher Course losing its signature.

## Revision 0 (2.0.56+256000): canonical definitions, 27 September 2026

- `dart format` on every changed Dart file: clean (12 files formatted, 4
  changed by the formatter on first pass, then stable).
- `flutter analyze --no-pub`: **No issues found** (after two fixes during
  the session: the `library;` directive had to precede the imports of the
  registry file, and `exercise_laboratory_254_test.dart` still read
  `preset.model`).
- Focused tests, first pass (`canonical_primitives_256_test`,
  `capability_registry_256_test`, `content_flow_256_test`,
  `exercise_architecture_224_test`, `translation_choice_239_test`,
  `exercise_laboratory_254_test`, `app_metadata_225_04_test`,
  `course_audit_report_225_test`, `qql_229_revision3_test`,
  `qql_233_revision_platform_contract_test`, `beta_lifecycle_test`,
  `localization_catalog_test`): 278 tests, **276 passed, 2 failed**, both on
  `expect(AppMetadata.build, '255')`, an expectation the version bump had
  not covered.
- Focused tests, second pass after that fix (`app_metadata_225_04_test`,
  `qql_229_revision3_test`, `qql_233_revision_platform_contract_test`,
  `course_audit_report_225_test`): **23 passed**.
- New tests: 7 in `canonical_primitives_256_test` (nine primitives in order,
  strict parsing, strict evaluation-mode parsing, unique option names,
  invalid values never canonical, immutable value semantics, presets
  configure only executable primitives); 11 in
  `capability_registry_256_test` (registry consistency, the evaluation
  matrix, the option inventory, every supported configuration lists every
  enumeration option, parsing drops illegal entries, defaults, legal
  configurations, coded illegal combinations, selection limits, executable
  set, readable-not-executable set, invalid state); 8 in
  `content_flow_256_test` (linear Story, strict identifiers, correctness
  branch, choice branch, conditional transition, every structural issue
  code, cycles).
- Complete suite (`flutter test --no-pub --concurrency=1`, 27 September 2026,
  05:27–05:48): **2,813 passed, 1 skipped, 0 failed** (`All tests passed!`
  after 21 minutes 30 seconds).
- Tree-wide `dart format --set-exit-if-changed lib test tools` reports 61
  files that predate Build 256 (for example `test/storage_roles_255_test.dart`
  and `tools/move_private_storage_255.dart`); they are left untouched, as
  unrelated formatting changes are out of scope. Every file this revision
  changed is formatted.
