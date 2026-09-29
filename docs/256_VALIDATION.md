# Build 256 validation

Evidence per revision. Commands run from `C:\QQL\QuisquisLingo` (that
spelling) with Flutter 3.47.4 / Dart 3.13.3 on Windows 10, the complete
suite through the keep-awake wrapper (`ES_CONTINUOUS | ES_SYSTEM_REQUIRED`
held for the run and cleared afterwards).

## Revision 7 (2.0.56+256007): Laboratory, Assign, final verification, 29 September 2026

- Stage 1 (the Assign runtime): `assign_runtime_256_test.dart` (10) with
  the registry, description, architecture and runtime-canonical tests: 42
  green after two test corrections (a moved item is taken back first; the
  registry's unplayable examples are regions and drag).
- Stage 2 (the Laboratory's Assign Lesson): generator `--check`,
  `tools/validate_courses.py`: pass (7 Lessons, 28 Rounds, 128 examples);
  the presentation recorded for all 128 examples and the baseline rebuilt:
  six new records, no other record changed; `exercise_laboratory_254_test`
  261 green.
- Stage 3 (the future fixture) and Stage 4 (negative and semantic tests):
  `laboratory_future_256_test` (4), `negative_cases_256_test` (9),
  `semantic_equality_256_test` (4) with the parity, bundled-Course,
  package, flashcard, library and Help tests: **120 passed, 0 failed**
  (after the parity test learned to skip the canonical Assign Lesson).
- `flutter analyze`: no issues; `dart format` clean on every changed file.
- Complete suite, first run (28 September, 23:32–23:58): 3218 passed, 1
  skipped, **11 failed**, all from the Assign Lesson having no preset and
  Assign now playing: `canonical_primitives_256_test` (the preset pin),
  the three end-to-end tests whose fixture Assign became playable (its
  placement is drag now, still unplayable), the six recipe tests over the
  Assign examples (no recipe represents them), and the canonical-editor
  test that expected a blank Assign not to play. The six files rerun
  green (178 tests).
- Complete suite on the final tree (`flutter test --concurrency=1`, 28–29
  September 2026, 23:57–00:25): **3229 passed, 1 skipped, 0 failed**.
- Final verification list (plan Part D): the acceptance scenario is
  `interoperability_end_to_end_256_test` (Revision 6); Story tests are
  `story_runtime_256_test`, `story_model_256_test`, `flow_engine_256_test`,
  the Story cases of the end-to-end test and the future fixture; capability
  based Duel eligibility is `duel_eligibility_service_test` and
  `support_states_256_test`.

## Revision 7 follow-up (same version), 29 September 2026

- Owner review of the Revision 7 build: the Story editor list showing IDs
  (fixed first, 281 focused tests green), two Assign presets (Sort into
  groups, Fill the slots; no gap preset, the Laboratory's gap Round
  removed, the Piedmontese demo unchanged at 39 Lessons), the Match picture
  to word form (cards following the words; the last picture without its
  number and name), the Flashcard form (named languages, Read aloud instead
  of a pronunciation text), one field for the spelling presets. The
  GuideBook question was answered without code.
- Generators `--check` and `tools/validate_courses.py`: pass (Laboratory 7
  Lessons, 27 Rounds, 126 examples, 48 presets in the cases; Piedmontese
  42 catalogue presets, 39 Lessons, 117 examples); the v11 fixtures
  rewritten from the generators.
- `flutter analyze`: no issues on the edited tree (twice).
- Focused batch (the new test, field Help, catalogue, recipes, Piedmontese,
  Story presets, runtime-canonical, Help, Search, localization, parity,
  characterization, Story editor, Assign runtime, future fixture,
  negative, semantic, Audit, editor forms, end to end, capability
  description; 34 files): 525 passed, 7 failed, all fixed before the suite: the recipe's "two groups" rule dropped (the Laboratory's leftover example has one group and a word that belongs nowhere), the spelling Help pin (`order` instead of the retired `tokens`), the Piedmontese preset set (minus the two Assign presets), two blanks built as Drafts in the new test; the fixed files and the Laboratory rerun 425 green.
- Laboratory presentation baseline: recorded for the 126 examples and
  rebuilt: the two gap records removed, no other record changed (the `true`/`false` lines of the rebuild's report are its parse artifact).
- `dart format` clean on every changed Dart file.
- Complete suite on the final tree: **3238 passed, 1 skipped, 0 failed** (01:56–02:23, keep-awake wrapper).

## Revision 7 fourth follow-up (same version), 29 September 2026

- Owner review of the Windows build: bold preset name; capitals as a
  Warning (any capital); Sort into groups without leftover words, Animals
  and Plants; Name what you see as word blocks and Type what you see;
  Read and answer with a source-language text and a dialogue read-aloud,
  "to source" retired; the Round Wizard with preset exercises only.
- The Round Wizard check (`every generated exercise is represented by its
  own preset`) failed first on `reading_answer_target` only (the context
  slot), then passed after the slot became Pick the missing word (10
  tests of the two Round Wizard files green).
- Generators `--check` and `tools/validate_courses.py`: pass (Laboratory 7
  Lessons, 27 Rounds, 122 examples, 46 presets in the cases; Piedmontese
  42 catalogue presets, 39 Lessons, 117 examples; Edge Case reproducible);
  the v11 fixtures rewritten from the generators (the Edge Case fixture's
  `e07_long` edited to match).
- `revision7_fourth_followup_256_test.dart`: 12 passed (after one test fix:
  the form's blank is built without strict validation).
- Focused batch (58 files): 18 failures, all pins on the changed
  behaviour (field inventories, the Read and answer Help texts, the
  Laboratory's example count and presentation records, the old form's
  label, the learner kinds per preset), fixed; the Laboratory presentation
  re-recorded for the 122 examples and the baseline rebuilt: 9 records
  removed (the old reading examples, Read and answer (to source), the
  leftover example), 6 new (three groups, Name what you see, four Read and
  answer), Type what you see's heading and instruction changed, no other
  change (the `true`/`false` lines are the rebuild's parse artifact); the
  five files rerun: green after the reading form's hover Help regained its
  example.
- `flutter analyze`: no issues; `dart format` clean on every changed file.
- Complete suite run 1 (10:58–11:27): 3248 passed, 1 skipped, 2 failed,
  both pins fixed after they ran (`course_editor_224_test`: the label Text
  to read (source language); `guidebook_sentence_generator_test`: the
  Round Wizard no longer creates Read and answer); the two files rerun
  green.
- Complete suite on the final tree (run 2): **3250 passed, 1 skipped, 0
  failed** (11:28–11:52, keep-awake wrapper).

## Revision 7 third follow-up (same version), 29 September 2026

- Owner decisions: a Round made with New Round and played as a sequence is
  a plain ordered Round (Optional sequence title, "Sequence: <title>" in
  every list, the learner's path and the Round screen, the Audit's Round
  rules, exercises in the Duel, no mistake review); a Story is New Story's.
- Focused run 1 (11 Story and flow files): 14 failures, all tests whose
  Story Rounds lacked the `story` visual type New Story writes (so they
  had become sequences); the fixtures now carry it. The seven files rerun:
  67 passed, 0 failed. `sequence_round_256_test.dart`: 6 passed (after
  one finder: the Round screen's title has no PREVIEW prefix).
- Type the missing word: a probe confirmed the draft builder and the
  Audit accept "casa" / "abitazione" with Show the first letter off (the
  form's texts were the problem); `revision7_third_followup_256_test.dart`
  1 passed (after the test stopped assuming the switch's starting state),
  with `first_letter_226_03_test` and the two field-help tests: 78 passed.
- `flutter analyze`: no issues; `dart format` clean on every changed Dart
  file.
- Complete suite on the final tree: **3249 passed, 1 skipped, 0 failed**
  (09:47–10:12, keep-awake wrapper).

## Revision 7 second follow-up (same version), 29 September 2026

- Owner requests: the Rounds page's New round button in the size and
  colour of Round Wizard and New Story, one capitalization style; then the
  Choose the answer decisions (Correct answer number 1 on a new single-answer
  form, the Audit warning when every answer is correct, "Prompt (optional)"
  and "Question or sentence to complete" with grammar examples, the Prompt
  replacing the generic "Choose the correct answer." line); Match by
  meaning without the guessed "opposite" line; the Flashcard's
  Pronunciation TTS (if different) field; Missing letters' field label;
  Play as a sequence. The owner asked to stop the first complete suite
  and apply the changes first.
- Focused batch, run 1 (38 files): 9 failures, all test pins or the new
  test itself (the Help texts now also on the form's helpers, so the
  finders are scoped to the dialog; the Choose default pinned by the
  Pick the translation test; a not-executable card must still show its
  prompt; three more files naming the old Prompt label; the multiple-answer
  field keeps the 1). Run 2: 454 passed, 1 failed (the Preview-roles test still typing into "Question"; its label updated), then the two files green (field guidance, the follow-up test).
- `flutter analyze`: no issues.
- Laboratory presentation baseline: recorded for the 126 examples and rebuilt: 15 records changed deliberately (the Choose examples with a prompt, the inline-gap ones included, and the Match examples: the authored prompt is the instruction line and no longer the prompt text; Match by meaning without the guessed opposite line), no other change (the `true`/`false` lines are the rebuild's parse artifact).
- `dart format` clean on every changed Dart file.
- Complete suite on the final tree: **3242 passed, 1 skipped, 0 failed** (08:03–08:32, keep-awake wrapper).

## Revision 6 (2.0.56+256006): Interoperability, 28 September 2026

- Stage 1 (support states in the model, playability, Duel, Audit, import
  review, Round screen): `support_states_256_test.dart` (11) with the
  registry pins, Story runtime, XP regression, Duel, library operations,
  runtime canonical, playability, Audit, Laboratory, Edge Case, Piedmontese
  and bundled-Course tests: 409 passed, 2 failed (a duplicated prompt on the
  card, the severity-count pins), then green.
- Stage 2–4 (flow engine, interoperability, capability JSON):
  `flow_engine_256_test.dart` (8), `interoperability_256_test.dart` (7),
  `capability_description_256_test.dart` (2), the architecture test and the
  content-flow tests: green after one test fix (a doubled Continue finder).
  `dart run tools/export_capabilities.dart`, `tools/validate_courses.py`
  and the three generators' `--check`: pass with the JSON as the source.
- Stage 5 (end to end): `interoperability_end_to_end_256_test.dart` (10):
  5 failures on the first run (the Input text-answer Error on a numeric
  Input, the official fixture's lineage, the merge's Course version, an
  editor finder), then green.
- `flutter analyze`: no issues; `dart format` clean on every changed file.
- Complete suite on the final tree (`flutter test --concurrency=1`, 28
  September 2026, 22:35–23:00): **3182 passed, 1 skipped, 0 failed**.

## Revision 5 (2.0.56+256005): Stories, 28 September 2026

- Stage 1 (model, flow, speakers, avatars; the two presets, recipes,
  features, copy, field help, Search, Audit codes):
  `test/story_model_256_test.dart` (14) and the flow authoring tests green;
  `test/story_presets_256_test.dart` (7) green; batch 2 (Help, Audit,
  registry, field help) 335 passed, 3 failed: the registry severity pins
  moved to 103 / 58 / 39 and the field-help inventory, then green apart
  from the UI inventory awaiting the Stage 3 forms.
- Stage 2 (runtime): `test/story_runtime_256_test.dart` (5) green; batch 3
  (runtime, Duel, audio, Laboratory) 373 passed, 2 failed (a mistyped test
  path; the Laboratory's every-preset pin awaiting Stage 5).
- Demo change (owner, 28 September): batch 4 (navigation, Home, discovery,
  registry) 228 passed, 25 failed because those tests were built around the
  Korean demo; with the Korean demo as a test fixture (`registerKoreanFixture`,
  `CourseService.bundledAssets`) batch 5 262 passed, 3 failed: a mistyped
  path, the Piedmontese pin awaiting Stage 5, and the Selector test tapping
  the Korean row that had become the last row below the 600 px test surface
  (it taps the Edge Case row); then green.
- Stage 3 (editor): batch 6 (editor, field help UI, follow-up, Course
  editor, Lesson controls, Story tests, navigation) 170 passed, 4 failed:
  the four Course-editor Story tests forgot that the Course Editor opens
  Locked (`course-editor-lock`, Edit); `test/story_editor_256_test.dart`
  10 green on the rerun.
- Stage 4 (Story Wizard): batch 8 (Wizard, editor, GuideBook generator,
  production transaction, field help UI, Lesson controls) 90 passed, 1
  failed: a cover without a picture and without a title line was a plain
  presentation, not a Story cover; the Wizard's cover now carries the Story
  title as its title line and the cover card shows it once;
  `test/story_wizard_256_test.dart` (3) and the runtime tests green on the
  rerun (8/8). Owner report (Preview showed a Story's cover picture twice):
  the shared illustration skips a Story cover; pinned in the runtime test
  (8/8 green).
- Stage 5 (bundled Courses): the three generators regenerate their Courses
  and pass `--check`; `tools/validate_courses.py` validates the three v12
  files (6, 6 and 40 Lessons); the two converter fixtures rewritten from
  the generators' v11 originals. Laboratory presentation baseline: record
  mode over 116 examples, `test/support/laboratory_presentation_254.dart`
  rebuilt: 9 new records (the Story Lesson), no changed record.
- Focused batch on the final tree (Courses, converter, demos, Laboratory,
  Story tests, Help catalogs, version pins; 33 files): 416 passed, 15
  failed, every one a pin of the previous shape: the Edge Case and
  bundled-source counts (6 Lessons, 11 Rounds, 36 exercises, 33 in the
  learner view) and its Merge needing a sixth Lesson choice, the
  Piedmontese Round-ID count (40), the parity filter refusing the cover
  Lesson's intro text, the runtime-kind map without the two Story presets,
  and the Beta lifecycle dates one day behind the new expiry; the rerun of
  those six files 49 passed, 1 failed (the Merge choice), then 7/7.
- `flutter analyze`: no issues. `dart format` on every changed Dart file.
- Complete suite, run 1 (13:56–14:22): **3114 passed, 1 skipped, 3
  failed**, the three being pins outside the focused batches that the
  Korean removal and the new Help section had moved
  (`course_library_screen_244_test.dart`: three bundled demos, "2 of 3
  shown", " · 3"; `course_library_view_255_test.dart`: "2 of 3" and "3 of
  3 shown"; `editor_help_translation_test.dart`: 29 editor sections);
  fixed in those tests, rerun green (27), then the complete suite once
  more on the final tree, run 2 (14:23–14:49): **3117 passed, 1 skipped,
  0 failed**.

## Revision 5 follow-up (same version), 28 September 2026, afternoon

- Owner review of Revision 5: Continue instead of Next (Round, Story,
  Duel) and Finish story; the Dialogue line instruction per mode; no XP, no
  Laurel and a plain completion for a Round without evaluable exercises;
  the derived "Story:" label; the avatar decoder; the scroll margin; the
  Laboratory Story rebuilt as a clean story plus a Story of the line
  options; the Piedmontese demo without the covers Lesson; the Edge Case
  demo's Story alternating lines and question plus the Story of covers
  alone.
- Generators `--check` and `tools/validate_courses.py`: pass (Laboratory 6
  Lessons, 26 Rounds, 122 examples; Piedmontese 39 Lessons, 117 examples;
  Edge Case 6 Lessons, 12 Rounds).
- Focused batch (Story, runtime, scoring, completion, playability, demos,
  converter, Review, Help; 26 files): a first run against a half-fixed
  tree (three analyzer findings: the rendering import for
  `RenderAbstractViewport`, a required argument in the new completion test,
  the decoder import awaiting its assertion), then 254 passed, 3 failed:
  the new card-only Round test's driver (it re-tapped a reviewed card) and
  the Top Bar test's fixture, whose "eligible" Rounds held only a note and
  are rightly not Laurel-eligible any more (they hold a question now); the
  two files rerun 24 passed, 1 failed, then the card-only test green.
- Laboratory presentation baseline: the Laboratory test in record mode
  (251 tests, 123 records, one of them dropped afterwards), `test/support/laboratory_presentation_254.dart`
  rebuilt: 15 Story records (the two Stories' cover, lines and questions,
  9 of them new IDs) and no changed record among the 107 earlier examples;
  the gate's `ROUND_CONTENT_LONG` on the 11-item Story led to dropping its
  last line (122 examples) and rebuilding once more.
- `flutter analyze`: no issues; `dart format` clean on every changed file.
- Complete suite, run 1 (17:48–18:14): **3139 passed, 1 skipped, 3
  failed**, all pins fixed in tests after they ran: the bundled release
  gate learning the intentional `STORY_WITHOUT_DIALOGUE` of the Story of
  covers alone, and the two Learner Status Bar tests whose fixture Rounds
  held only a note (a question each now); the gate rerun then exposed
  `ROUND_CONTENT_LONG` on the 11-item Laboratory Story, whose last line
  was dropped (122 examples, baseline rebuilt); the gate and the Laboratory
  rerun 252 green. Complete suite, run 2 on the final tree (19:09–19:39):
  **3139 passed, 1 skipped, 0 failed**.

## Revision 5 third follow-up (same version), 28 September 2026, night

- Owner requests (21:10 and 21:25): the Round Wizard and the Story Wizard
  move to the Rounds page, the Story Wizard is renamed New Story, the
  "Lines are never skipped" sentence leaves the Story options; in a Story
  the Round editor replaces New exercise / New canonical / Exercise Wizard
  with Add step (title block once and first, dialogue line, exercise).
- `flutter analyze`: no issues; `dart format` clean on every changed file.
- Focused batch (Add step, New Story, Story editor, Revision 3 follow-up,
  generator, transaction, 231 modes, Exercise Wizard, Help, workflow,
  translation choice, Audit, hierarchy indicators, Audit UI, context
  menus): 164 tests, **163 passed, 1 failed** (the new test reused the
  editor State between two pumps; helper fixed), then the five Add step
  tests green on their own.
- Complete suite on the final tree (`flutter test --concurrency=1`, 28
  September 2026, 22:03–22:28): **3144 passed, 1 skipped, 0 failed**.

## Revision 5 second follow-up (same version), 28 September 2026, evening

- Owner request: no DIALOGUE heading on a Dialogue line. One condition in
  the Round screen; `story_runtime_256_test` asserts no heading on a line.
- Laboratory presentation baseline re-recorded (254 tests with the runtime
  test): the ten line records lose their heading, no other record changed.
- `flutter analyze`: no issues; `dart format` clean.
- Complete suite on the final tree (`flutter test --concurrency=1`, 28
  September 2026, 19:58–20:22): **3139 passed, 1 skipped, 0 failed**.

## Revision 4 (2.0.56+256004): the preset catalogue, 27 September 2026

- Stage 1 (skill groups, directions, the coming-later list, the picker's
  filter, chips and greyed tiles): `test/preset_catalogue_256_test.dart`
  (7 tests) and the adjusted editor, Help, planner and Pick the translation
  tests: **680 passed, 7 failed** before the pins were moved, then green.
- Stage 2 (merged and paired presets, successors, the Audit on the
  catalogue, field help, Search, the source voice): focused batches of the
  editor, Help, Audit, recipe, converter, runtime and Laboratory tests
  after each script: 549/104, 590/30, 434/9, 338/12 (a typed translation
  no longer represented: the rebuild blank carried the preset ID as its
  v11 type and the base map made the builder reuse the blank's Select
  interaction; the blank now has the recipe's base type), then green apart
  from the bundled Courses awaiting Stage 4.
- Stage 3 (the 14 new presets, pictures on answers, runtime additions) and
  Stage 4 (generators, regenerated Courses, fixtures): batches 452/36,
  578/38, 667/59 (29 of them new Laboratory examples without a baseline
  record), each followed by its corrections (`docs/256_HANDOFF.md` lists
  them by script).
- Laboratory presentation baseline: the Laboratory test in record mode
  (**All tests passed**, 107 records), `test/support/laboratory_presentation_254.dart`
  rebuilt from the records; the diff against the Session 3 baseline shows
  27 new records and exactly two changed ones, both deliberate: the two
  inline-gap Build the translation examples are Drag the blocks into the
  gaps with a clue (heading BUILD THE SENTENCE, instruction "Put the words
  in the correct order."). Every other pre-existing record is byte-equal.
- The first run of that batch (657 passed, 11 failed) exposed four gaps,
  all closed before the rerun: the converter noted every `["continue"]`
  Note card as an unmapped detail; the Audit demanded a usage sentence and
  pronunciation from Note cards and Picture flashcards and called three
  "What is this?" pictures duplicates; the Piedmontese Read and answer
  (to source) passages were two words long and its Match picture to word
  instructions repeated; recognition picked Missing letters for a
  whole-word gap and Spell what you hear for a picture
  (`PresetVariants.fits`, with a direct test). The rerun (671 passed, 4
  failed) showed the v11 view reading an omitted completion mode as
  understood/review (so the converter's lossless check never held; fixed in
  `Presentation.fromExercise`), the two Note cards without a baseline
  record (recorded, baseline rebuilt) and the release-gate key of the
  Piedmontese opposites exercise still naming Lesson 20 (now Lesson 8).
  The second rerun (14 files, 6 failures) found the Edge Case asset out of
  date against its generator (the inline-gap presets `gap_blocks` and
  `gap_choice_inline` were never re-emitted; regenerated, `--check` PASS),
  the demo package roundtrip test assuming every card reviewable (a Note
  card continues) and the release-gate test skipping usage items only for
  the `flashcard` preset (now every card built on the flashcard recipe).
  Validators outside the suite: `python -X utf8 tools/validate_courses.py`
  (four v12 files; the Piedmontese count is 38 Lessons), the Piedmontese
  generator's `--check`, the v11 fixtures regenerated (`s36_fixtures.py`).
- Batch 9 (Laboratory, Piedmontese, recipes, primitive editor, runtime,
  converter parity, Select editor, Help, Audit, characterization, builder,
  catalogue, search, catalogs, field help, Pick the translation, follow-up,
  Course Editor, Edge Case, registry): 657 passed, 11 failed on the first run (`focused_s20.log`); 671 passed, 4 failed on the 26-file rerun (`focused_s21.log`); **439 passed, 0 failed** on the 12-file rerun of every file the fixes touched (`focused_s23.log`); after the complete suite, the seven files it failed: 51 passed, 1 failed, then green after the Wizard fix (`focused_s24.log`).
- `flutter analyze --no-pub`: **No issues found** after every script;
  after the final `dart format` (26 files) it reported one
  `curly_braces_in_flow_control_structures` info where the reflow had put
  an `if` body on its own line (`exercise_features.dart`): braces added,
  clean again.
- Complete suite, first run (00:40–01:06, 28 September): **3040 passed, 1
  skipped, 13 failed**, every failure in a file outside the focused
  batches, all pins on Revision 3 shapes: the five Arrange inline-gap tests
  tapped the removed Inline gaps switch (now they pick Drag the blocks into
  the gaps), the Audit report expected `choice (choice)` (a v11 Choose
  records `choice_target`), the image-removal fixture's Image Word kept a
  clue (its v11 prompt), so the widened spelling rule no longer needed its
  picture (the fixture has no prompt now), the Wizard test tapped the chip
  `Type the translation` (now `(to target)`), the two first-letter Editor
  tests tapped a Save row whose centre sits a pixel below the 600 px default
  window (big window like the other editor tests), the View-only test read
  the merged contextual comprehension form's context mode selector, and the
  Recognize characters help had been reworded (restored to the 226.03 text).
  No learner-visible behavior changed for these. The rerun then showed the
  one production defect behind the Wizard failure: `_blankExerciseForPreset`
  used the preset ID as the v11 type, so a catalogue twin fell back to a
  Select interaction and the Wizard saved a Select without items (accepted
  translations lost); it now builds on the recipe's base type with the
  preset as editor template. The seven files were rerun green before the
  second complete run.
- Complete suite on the final working tree (`flutter test --no-pub
  --concurrency=1` under the keep-awake wrapper): first run **3040 passed, 1 skipped, 13 failed** (00:40–01:06, 28 September, analysed above); second run on the final tree **3053 passed, 1 skipped, 0 failed** (01:26–01:52, `All other tests passed!`; the 13 fixed tests now count among the passes).

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

## Revision 3 second follow-up (same version), 27 September 2026, afternoon

- The owner's report that a scrolling Story plays like a normal Round was
  chased first: a scratch widget test drove the Round editor → Play as a
  Story → Scrolling → Preview (speech channel mocked) → answered → Next and
  found the finished-item card and the scrolling list; every save path
  (`OverlayRoundDraft`, the session's reconcile,
  `PublicationService._publishedRoundJson`, Course JSON) keeps
  `flow.presentation`. Not reproducible; the effect is now unmistakable
  (`story-now` marker, top-aligned scroll) and a debug event records each
  Round's Story state for the next report.
- `test/revision3_followup_256_test.dart` gained the `story-now` texts, the
  type-choice-on-a-new-exercise test and the Round Wizard tooltip test.
- Focused batches after the fixes: the follow-up file with the Story-flow,
  Course Editor, exercise workflow and localization tests (**57 passed**),
  then the extended follow-up file alone (**13 passed**).
- `dart format` on the changed files; `flutter analyze --no-pub`: **No
  issues found**.
- The complete suite started for this state (15:52) was stopped when the
  owner's next report arrived; the third follow-up's suite below covers
  both.

## Revision 3 third follow-up (same version), 27 September 2026, evening

- Owner's second inspection: the canonical editor still asked after New
  canonical → Assign/Submit (a primitive change on a blank new exercise is
  now no change); the scrolling Story showed the finished card but no
  scroll movement when the page fitted the window (a spacer below the
  active item gives the "Now" marker room to glide to the top); a Select
  the image exercise without icons warned only that it plays as a plain
  Choose (the warning now names the missing Icons / image keys, and the
  field says so too).
- Tests: the canonical Assign test flipped (no prompt while blank, prompt
  after an item is added), the scrolling test checks `story-spacer`, a new
  Audit test checks the Select the image hint.
- Focused batch (the follow-up file with the primitive editor, runtime
  canonical, Pick the translation and Audit tests): **97 passed** after a
  missing test import was added. `dart format`; `flutter analyze
  --no-pub`: **No issues found**.
- Complete suite on the final working tree (`flutter test --no-pub
  --concurrency=1` under the keep-awake wrapper, 16:16–16:42): **2,951
  passed, 1 skipped, 0 failed** (`All tests passed!` after 25 minutes
  55 seconds).

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
