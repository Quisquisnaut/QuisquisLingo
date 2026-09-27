# Build 256 handoff — exercise architecture redesign (Course Model v12)

Resume from this file alone. Plan: `docs/256_EXERCISE_ARCHITECTURE_PLAN.md`
(Part A decisions, Part B sessions, Part C verified audit notes, Part D
condensed specification). Working rules: Part A.1 of the plan. Reference:
`docs/EXERCISE_ARCHITECTURE_V12.md` (its "Course Model v12 JSON" section is
the Session 2 design). Summary: `docs/256_CHANGE_SUMMARY.md`. Evidence:
`docs/256_VALIDATION.md`.

## State (27 September 2026, 20:04; the 19:05–21:05 stamps below were estimates, the real clock is used from 19:29 on)

- **Revision 4 close-out in progress (20:04), everything applied in the
  working tree, uncommitted.** Batch 10 (`scratchpad/focused_s20.log`)
  ran 657 passed, 11 failed; `s38_fixes.py` closed four gaps (converter
  note for `["continue"]` cards, Audit usage/pronunciation Warnings only for
  vocabulary flashcards and `ROUND_DUPLICATE_CONTENT` counting the prompt's
  pictures, Piedmontese three-word Read and answer (to source) passages and
  distinct Match picture to word instructions, `PresetVariants.fits`/
  `hasInWordGap` asked by `PresetRecipes.represents`), the Piedmontese asset
  and both v11 fixtures regenerated, `tools/validate_courses.py` expects 38
  Piedmontese Lessons. Rerun `focused_s21.log` (26 files): 671 passed, 4
  failed; `s39_fixes.py` fixed `Presentation.fromExercise` (omitted mode =
  proceed), the Session 2 note test (`['ok']`), the release-gate key
  (`l08`). 20:19: the two Note cards recorded (`record2.log`), baseline
  rebuilt (107 records; the `s34_baseline.py` diff's true/false "renames"
  are its own parse artifact: it capitalises `true`/`false` inside the old
  keys), second rerun `focused_s22.log` (14 files): 6 failures →
  `s43_fixes.py` (Edge Case asset regenerated: its generator already emitted
  the inline-gap presets; roundtrip and release-gate tests read the card's
  completion mode / recipe). 20:22: `s43_fixes.py` applied, Edge Case asset
  regenerated (`--check` PASS for all three generators, validator OK),
  analyzer clean, third rerun `focused_s23.log` (12 files) was running when
  the owner paused to switch off the PC: its result is unknown, rerun it
  first. Nothing committed. Owner (20:0x): after the suite, commit, handoff,
  PUSH, then WAIT for approval before Revision 5. 28 September 00:35: PC
  back on; `dart format` on the git-status Dart files (26 changed), one
  `curly_braces_in_flow_control_structures` info the reflow produced in
  `exercise_features.dart` fixed with braces, analyzer clean, batch 3
  (`focused_s23.log`, 12 files) rerun: **439 passed, 0 failed** (00:40).
  00:41: complete suite running under `run_awake.ps1`
  (`scratchpad/suite_256004.log`, UTF-16; summarise with
  `s44_suite_summary.py`). After it: `s42_numbers.py`, handoff, commit
  (`commit_256004.txt`), push, sound, report, then WAIT.
  01:06: first complete run **3040 passed, 1 skipped, 13 failed** (7 files
  outside every focused batch; details in `docs/256_VALIDATION.md`);
  `s46_suite_fixes.py` (01:18) moved the pins (Arrange inline tests pick
  `Drag the blocks into the gaps`, report `choice_target (choice)`,
  image-removal fixture without a clue, Wizard chip `(to target)`,
  first-letter big window, qql_231 context selector block removed,
  Recognize characters help restored). Rerun of the seven files: 51 passed,
  1 failed: the Wizard saved a Select without items for Type the
  translation (to target): `_blankExerciseForPreset` used the preset ID as
  the v11 type (a catalogue twin is no v11 type → Select fallback); it now
  builds on the recipe's base type with the preset as editor template
  (production fix, in CHANGELOG / summary / validation / commit message);
  Wizard file green, analyzer clean, formatting clean. 01:26: second
  complete suite (`suite_256004b.log`, 01:26–01:52): **3053 passed, 1
  skipped, 0 failed**. 01:53: validation numbers filled; committing Revision 4
  (`commit_256004.txt`), then a handoff commit, then push (owner's request),
  sound, report, and WAIT for the owner's approval before Revision 5.
  **Next (the earlier list, from here):** record the two Note cards
  (`QQL_RECORD_PRESENTATION=scratchpad/record`, `--plain-name
  "learner completes qql_lab254_note_card"`), `s34_baseline.py` (expect
  exactly two new records), focused rerun of the touched files, `dart
  format` on the git-status Dart files, analyze, complete suite
  (`run_awake.ps1`), `s42_numbers.py <batch> <suite>`, commit with
  `scratchpad/commit_256004.txt`, handoff, **push** (owner, 20:04: "At the
  end of task, commit, handoff, and push. Then pause and wait for my
  approval before going on with next revision"), report (accomplished /
  issues / left), sound; no APK. Then WAIT for approval.

- **Session 5 (Revision 4, the preset catalogue) is in progress; Stage 1 is
  verified and Stage 2 is applied in the working tree (uncommitted, 17:20):**
  registry rewritten (`ExercisePreset.base`/`twin`/`direction`/`action`, 24
  catalogue presets, `successorOf` = `lib/models/preset_successors.dart`,
  `currentIdFor`), `lib/services/preset_variants.dart` (base recipe, form
  base, "to source" marking, first-letter switch), the draft builder runs
  the base recipe and finishes as the preset, `ExerciseFeatures` input kinds
  (`inputComplete` without reveal) and `isTranslationClue`, the editor forms
  (Read and answer dialogue lines, `type-missing-word-reveal` switch), the
  Audit (`currentIdFor`, kind sets, Read and answer / Listen and answer
  rules, four codes retired: DIALOGUE_RESPONSE_OPTION_COUNT,
  DIALOGUE_CONTEXT_REQUIRED, DIALOGUE_QUESTION_REQUIRED, CONTEXT_REQUIRED →
  **98 rules**; areas renamed), the field help (`revealFirstLetter`, 24
  IDs), `help_structure.dart` (24 IDs, field-key map regenerated), Search
  definitions, the source voice (`ExerciseFeatures.primaryAudioLanguage`,
  `audioLanguageOf`, `_voiceFor` in Round and Duel), the GuideBook Round
  generator and the interoperability catalog on the catalogue IDs, and the
  v11 converters (Dart `convertV11`, `_givenMetadata`, the file converter;
  Python `PRESET_SUCCESSOR`) record successors. Scripts: scratchpad
  `s10_registry.py`, `s10_recipes.py`, `s10_editor.py`, `s11a_successors.py`,
  `s11b_audit.py`, `s11c_fieldhelp.py`, `s11e_search_runtime.py`. **Next:**
  (18:40: catalogs done (`s11d_catalogs.py`); `s12_prod.py` + `s12_prod_b.py`
  added the shape hints `ExerciseDraftValues.textRole`/`audioRole` (decompose
  records them; `PresetVariants.baseFor` keeps an opened exercise's passage /
  situation / context or primary / passage shape), merged the two listening
  forms into one (`Spoken text`, `Question (optional)`), gave Read and answer
  a `Spoken text (optional)` field, removed the dialogue_response and
  contextual_comprehension form cases, direction labels for the translation
  twins, `Translation pairs` (at least two), six dead `ExerciseAuthoringField`
  values removed, to-source field help, Pick the translation Help restored
  verbatim from HEAD; `s12_tests.py` moved the test pins; bundled Courses
  regenerated with successor IDs: Laboratory and Edge Case by their
  generators, Korean and Piedmontese by `dart run tools/convert_course_to_v12.dart
  <fixture> <asset> --overwrite` (the Piedmontese generator asserts the
  registry unchanged: Stage 4 extends its Lessons); `flutter analyze` clean;
  second focused batch `scratchpad/focused_s12.log`: 590 passed, 30 failed;
  `s13_fixes.py` then made Type the missing word absorb the Fill-in shape
  (first-letter switch off = base recipe `fill_blank`, one field; decompose
  shows the question as the sentence), let the script candidate cross
  `finish` unchanged, removed the dead `pairs` field, renamed the Help
  supplement to "Read and answer example" and moved the last pins
  (`runtime_canonical_256` kinds as sets, Duel set, `translation_choice_239`
  v11 types back to `type: 'choice'`); third batch `focused_s13.log`
  ran: 434 passed, 9 failed; `s14_fixes.py` added the `matchSides` hint so
  Match the words also keeps the former Matching shape (left target, right
  source: base recipe `matching`), `s15_tests.py` fixed the picker test;
  `s16_tests.py` gave the Laboratory test's `_author` the decompose shape
  hints; `s17_fixes.py` added `presetRecipeBaseOf` (plain Dart, mirrored by
  `PRESET_BASE` in Python): the v11 `type` view and `convertV11` resolve a
  catalogue preset to the recipe it is built on, so `Exercise(type: 'choice',
  editorTemplate: 'choice_source')` converts as a Choose; batch 5: 338
  passed, 12 failed (typed translations no longer represented: the rebuild
  blank had the preset ID as its v11 type, so with the base map the builder
  reused the blank's Select interaction; fixed: the blank has the recipe's
  base type). **Stage 3 part A applied (`s20_stage3a.py`, analyzer clean):**
  14 new presets in the registry (`picture_flashcard`, `true_false`,
  `gap_choice_inline`, `complete_text`, `missing_letters`, `gap_blocks`,
  `sentence_order`, `listening_image_choice`, `spell_heard`,
  `picture_choice`, `picture_name`, `spell_word`, `picture_word_match`,
  `note_card`) with `helpByPreset` texts and `presetRecipeBaseOf` entries
  (Python `PRESET_BASE` too); `PresetRecipes.kinds`; decompose
  (`bracketedSentence` for Missing letters, picture items named by their
  picture); `PresetVariants.ownForms`/`formFor`/`isImageReference`, the
  Stage 3 `draftFor` cases (inline flags forced per preset, Missing letters
  brackets → gaps, Note card) and `_shape` (True or false answers in the
  source language, Spell the word clue, Picture flashcard optional audio,
  Match picture to word left pictures); builder `copyWith` fields and spoken
  text for `icon_choice`/`image_word`; converter: image-like icon keys become
  image elements, `icon_choice`/`image_word` audio automatic (Python too);
  `LearnerExerciseKind.arrangeLines` (+ copy in eight languages, Audit
  label); Audit preset rules for the new presets, `IMAGE_WORD_IMAGE_REQUIRED`
  now "a picture, a spoken word or a clue"; Round: captioned picture answers
  in the grid via `CourseMediaImage`, Match left pictures, within-word gap
  underscores; Duel item pictures via `CourseMediaImage`. Batch 6: 452
  passed, 36 failed (inline-gap examples now recognized as
  `gap_choice_inline`, Help crashing on missing catalog keys, image widgets):
  `s22_fixes.py` keeps `PortableExerciseImage`/`Image.asset` for portable
  and bundled pictures (only `media:` goes through `CourseMediaImage`) and
  updates the spelling-rule Audit test. **Part B applied (`s21_stage3b.py`,
  analyzer clean):** `formFor` switch, 13 own forms, `_answerPictures`
  (one `ExerciseImageField` per answer writing `_icons` lines), Match picture
  to word kept as words + pictures (`_picturePairsText`/`_splitPicturePairs`),
  inline switches removed from Choose, Word order and Build the translation,
  True or false prefilled in the source language (`_trueFalseAnswers`),
  Missing letters keeps its hint. **Part C applied (`s23a_stage3c.py`,
  `s23b_stage3c.py`, analyzer clean):** 12 new `ExerciseAuthoringField`
  values with their help, `editorFieldKeys`/`fieldForEditor` for the 14
  presets, `help_structure` (38 preset IDs, field-key map), Search
  definitions, EN/IT/ES catalog entries (14 descriptions and bodies, 15
  field bodies), test inventories (`_formFields`, `fieldsByPreset`,
  `_expectedKinds`, Duel set, search helper's missing words, catalogue test's
  empty group is Coming later). Batch 7: 578 passed, 38 failed (inline
  examples, Help lazy list, the removed inline switches in tests). **Stage 4
  applied:** `s30_converters.py` (an explicit `language` attribute wins over
  the preset-implied one in `convertV11`'s `withTextLanguage`/`withItemLanguage`
  and the Match sides, and in the Python mirror; the Choose recipe keeps a
  spoken statement), `s31_laboratory.py` (Laboratory generator: `text(language=)`,
  `audio(required=)`, `choose(language=, images=)`, `arrange(language=)`,
  `match(left_images=)`, `card(preset=, picture=)`; inline examples re-tagged
  `gap_choice_inline`/`gap_blocks`; new Rounds `select_source`,
  `input_source_and_pictures`, `arrange_source_and_lines`, `match_pictures`,
  `presentation_pictures_notes`: 107 examples, every preset), `s32_piedmontais.py`
  (one Lesson per preset in registry order, `gaps()`, `picture_card()`,
  `note()`, version 1.2.0), `s33_tests.py` (pins: 107 examples, 38 Lessons,
  inline presets picked in the editor tests, Help/picker lists dragged).
  Batch 8: 667 passed, 59 failed (29 new Laboratory examples without a
  baseline record, recognition and generator details). `s35_fixes.py`: Listen
  and pick the image needs its audio (`kinds` = selectListen), bundled
  `assets/` icon keys stay icon keys (only `media:`/`data:` become image
  elements), Choose twins drop a spoken text (True or false keeps it),
  Missing letters keeps its gaps when reopened without brackets, the
  Piedmontese generator remaps `gapAssignments`, generators expose
  `course_v11()`/`build_course_v11()`; `s36_fixtures.py` rewrote the v11
  converter fixtures of the Laboratory and Piedmontese; Help test lays the
  whole page out (320 × 60000). Analyzer clean. **Running now (one chain):**
  the Laboratory in record mode → `s34_baseline.py` (rebuilds
  `test/support/laboratory_presentation_254.dart`, diff in
  `scratchpad/baseline_diff.txt`, log `baseline.log`) → batch 9
  `focused_s19.log`: record mode passed (107 records; the diff against the
  Session 3 baseline: 27 new records, two deliberate changes: the inline
  Build the translation examples are Drag the blocks into the gaps), batch 9
  600 passed, 25 failed. `s37_fixes.py`: a target-language primary text is
  a translation clue (`isTranslationClue`), the to-source translation twins
  mark `primary` too, `picture_choice` drops spoken text, the picture presets
  carry their picture as `picture` (not `clue`) so their bases do not
  represent them, a Note card is `proceed` (Continue; generators write
  `["continue"]`), the converters map an inline v11 Choose / Word order /
  Build the translation to `gap_choice_inline` / `gap_blocks` (Dart and
  Python), the generators write bundled answer pictures as icon keys (as the
  picker does) and picture roles, fixtures carry a checksum. Docs written
  (`s41_docs.py`: CHANGELOG, change summary, validation with placeholders,
  AGENTS boundary, README, architecture status, catalogue plan status);
  `s40_version.py` ready (not yet applied). **Running now (one chain):**
  record → `s34_baseline.py` (against the restored Session 3 baseline) →
  batch 10 `focused_s20.log`. **Next:** `s40_version.py`, `dart format` on
  the changed Dart files, analyze, the complete suite (`run_awake.ps1`),
  validation numbers, commit; still red by design until Stage 4:
  `exercise_laboratory_254` (every current preset) and
  `piedmontais_course_254`) the focused tests and their pins (retired IDs → successors;
  `AuditCode.values` 98; `CONTEXT_REQUIRED` → `READING_PASSAGE_REQUIRED` in
  `contextual_comprehension_224_test`), then Stage 3 (new presets, picture
  answers), Stage 4 (generators, bundled Courses, baselines), version
  `2.0.56+256004`, docs, suite, commit.
- Branch `claude/256-exercise-architecture`, created from `main` at
  `611a1a1` (Build 255 handoff; version `2.0.55+255007`).
- Commits: `507be89` Build 256 Revision 0 (canonical definitions;
  `2.0.56+256000`); `e850cc2` Revision 1 (Course Model v12;
  `2.0.56+256001`); `41dd91a` **Build 256 Revision 2: runtime and Audit
  on canonical data** (`2.0.56+256002`; complete suite 2,840 passed, 1
  skipped, 0 failed; evidence in `docs/256_VALIDATION.md`); handoff
  commits between them.
- **Session 4 is done: `974f700` Build 256 Revision 3: presets as recipes
  and the Generic Primitive Editor** (`2.0.56+256003`; complete suite
  12:05–12:26 **2,937 passed, 1 skipped, 0 failed**; evidence in
  `docs/256_VALIDATION.md`, summary in `docs/256_CHANGE_SUMMARY.md`, the
  CHANGELOG entry and the AGENTS boundary entry). The Android debug APK
  was built right after the commit (`scratchpad/apk_and_sound.ps1`:
  `buildpp\outputslutter-apkpp-debug.apk`, 179,442,901 bytes,
  12:29) and the end-of-revision sound played (owner request: at the end of
  every revision). **Session 5 (Revision 4, the preset catalogue) starts next**
  from "Session 5 starting points" below and
  `docs/256_PRESET_CATALOGUE_PLAN.md`.
- **Session 5 (Revision 4, the preset catalogue) started 12:45 and stopped
  at 12:52 on the owner's usage limit.** Stage 1 is APPLIED BUT UNVERIFIED
  in the working tree (uncommitted; scratchpad `s5_stage1.py`): skill
  groups replace `ExerciseCategory` (vocabulary, grammarAndSentences,
  listening, readingAndDialogue, picturesAndCharacters, cardsAndNotes,
  comingLater), `PresetDirection` and `ExercisePreset.direction`/`action`,
  `ComingLaterPreset` + `ExercisePresetRegistry.comingLater` (seven greyed
  presets, not in `presets`), the 24 presets regrouped, five approved
  renames (Choose the answer, Pick the missing word, Match by meaning,
  Listen and fill the gaps, Spell the word in the picture) with the Audit
  kind labels and the Choose Help texts (EN/IT/ES) updated, the picker's
  direction filter (`exercise-preset-direction`), action chips
  (`_PresetActionChip`), greyed "Coming later" tiles
  (`exercise-preset-later-<id>`) and per-preset keys
  (`exercise-preset-<id>`), the Wizard skipping empty groups, the planner's
  `_balanced` skipping empty groups, Exercise Help's Coming later section,
  the catalogs' seven group keys and `exerciseHelp.comingLater`, and five
  test files adjusted (`exercise_architecture_224` 7 groups,
  `course_editor_224` group titles, `translation_choice_239` Vocabulary,
  `exercise_creation_planner` Vocabulary set incl. matching/word_match/super_match,
  `exercise_help_224` 'Choose the answer'). **Next:** `flutter analyze
  --no-pub`, then the focused tests (`exercise_architecture_224`,
  `course_editor_224`, `translation_choice_239`, `exercise_creation_planner`,
  `exercise_help_224`, `exercise_help_search_226_03_r1`,
  `localization_catalog`, `exercise_field_help*`, `qql_231_search_service`,
  `preset_recipes_256`, `canonical_primitives_256`, `exercise_laboratory_254`
  and the Wizard tests), fix what they show, write
  `test/preset_catalogue_256_test.dart` (groups, directions, coming-later
  list, picker filter and greyed tiles, planner with an empty group), then
  Stage 2 (merged and paired presets with canonical recipes, example
  content, save guard), Stage 3 (new presets and runtime additions), Stage
  4 (bundled Courses), version `2.0.56+256004` (see the version-pin list
  above), docs, suite, commit, APK, sound.
- **Revision 3 follow-up in progress (owner's ten points, same version,
  one commit "Build 256 Revision 3 follow-up: …"; Revision 4 Stage 1 is
  in `git stash` (stash@{0}) and resumes only after the owner approves).**
  Applied, analyzer clean, tests not yet written: `FlowPresentation`
  (`flow.presentation`: step | scroll, omitted when step) on `ContentFlow`
  and `RoundFlowAuthoring` (`linearFor(presentation:)`, `forContent` keeps
  it, `withPresentation`, `remapped` keeps it); the Round editor's
  `round-story-presentation` control (Step by step / Scrolling) under the
  Story switch; `RoundScreen` scrolling Story (`_storyScrolls`, `_storyLog`,
  `story-entry-N` cards with heading, prompt, the learner's answer and a
  tick/cross, auto-scroll to the active item); the canonical editor decides
  unsaved changes by semantic comparison (`_hasUnsavedChanges`) and required
  options get defaults (`CanonicalExerciseDraft.requiredOptionDefaults`, used
  by `blank`, `blankExercise`, `changePrimitive`: Assign/Submit no longer
  show a registry refusal); the preset form decides unsaved changes by
  comparing a form snapshot (`_formSnapshot`, `_openedSnapshot`,
  `_scriptDirty`); Round editor buttons **New exercise (presets)** /
  **New exercise (canonical)**; a published Round save with Draft
  Exercises shows `round-draft-exercises-notice` naming them; the
  first-time intro `ExerciseEditorIntro` (`lib/widgets/exercise_editor_intro.dart`,
  one-time notice `exercise_editor_intro_<courseId>`, test seam
  `enabled` turned off in `test/flutter_test_config.dart`) shown by both
  editors; Help EN/IT/ES: Round Wizard / Exercise Wizard names, the two
  buttons, presets versus canonical, scrolling Stories; the Windows runner
  clamps the initial window to the monitor's work area
  (`win32_window.cpp`; the owner's "missing wizards" were the bottom bar
  under the taskbar). Owner decisions recorded in the catalogue plan:
  pairs only where meaningful, bracket only on twins. 14:35:
  `test/revision3_followup_256_test.dart` written; CHANGELOG, AGENTS,
  change summary, validation (placeholders `<<BATCH>>`, `<<SUITE>>`) and
  the V12 status row carry the follow-up; commit message in
  `scratchpad/commit_rev3_followup.txt`. First focused batch
  (`s6_batch1.log`) showed two corrections, both applied: the Draft
  Exercises message now appears only when the Audit refuses the save (a
  Round with a Published Exercise and a Draft duplicate still saves, as
  `authoring_context_menu_224_test` expects), and the Match the pairs test
  targets `exercise-field-pairs` and pushes the editors above a home page.
  14:30: the corrected files are green (follow-up file 11 passed, context
  menu 4 passed), analyzer clean. 14:52: **complete suite 2,948 passed, 1
  skipped, 0 failed** (24 minutes). Committed as **`1068fa4` Build 256
  Revision 3 follow-up** (same version `2.0.56+256003`); the Android debug
  APK was rebuilt (`buildpp\outputslutter-apkpp-debug.apk`,
  208,700,575 bytes, 14:54) and the sound played.
  **Second follow-up in progress (owner's visual inspection of the Windows
  build, 15:10–):** applied and analyzer-clean: Round editor buttons **New
  exercise** / **New canonical** with a compact bottom-bar style
  (`_compactButtonStyle`, two rows instead of three), choosing a type on an
  untouched new exercise no longer counts as a change (`_openedSnapshot`
  reset in `_choosePreset`), the Lesson editor's Round Wizard is greyed with
  a tooltip while Use GuideBook is off, the intro dialog and Help EN/IT/ES
  name the two buttons; the owner's "scrolling Story does not scroll"
  could not be reproduced: a scratch test driving Round editor → Story on →
  Scrolling → Preview → answer → Next shows the finished-item card
  (`story-entry-0`); every save path (`OverlayRoundDraft`, session
  reconcile, `PublicationService._publishedRoundJson`, JSON) keeps
  `flow.presentation`. 15:50: the scrolling effect is now unmistakable
  (`story-now` marker "Story · N steps" / "Now · step k of N", the active
  item scrolled to the top after Next, a Crash Log debug event
  `story=… scrolling=… presentation=…`); tests added (13 in the follow-up
  file, all green; batch of 57 green), docs written (CHANGELOG second
  follow-up block, AGENTS sentence, change summary, validation with the
  `<<SUITE2>>` placeholder), commit message in
  `scratchpad/commit_rev3_followup2.txt`. That suite (15:52) was stopped
  when the owner's second inspection arrived (16:10): New canonical →
  Assign/Submit still asked to discard (a new exercise blank for its
  primitive now leaves silently: `_hasUnsavedChanges` compares with
  `blankExercise`), the scrolling Story showed the card but no visible
  scroll (a `story-spacer` below the active item lets "Now" glide to the
  top, 600 ms), and Select the image without icons warned only "plays as a
  plain Choose" (`CourseAuditService._mismatchHint` names what the preset
  needs; the Icons field has a helper). Tests updated and added (97
  passed in the focused batch), analyzer clean, docs written (CHANGELOG
  third block, AGENTS, validation with `<<SUITE3>>`), commit message in
  `scratchpad/commit_rev3_followup3.txt` (one commit for follow-ups 2 and
  3). **Complete suite running from 16:35**
  (`scratchpad/suite_rev3_followup3.log`, UTF-16). **No APK** (owner: do
  not build it unless already built); the sound still plays at the end.
  16:42: **complete suite 2,951 passed, 1 skipped, 0 failed**; committed as
  **`02a4aa5` Build 256 Revision 3 follow-up 3** (follow-ups 2 and 3
  together, same version), sound played, no APK (owner). Points 3 and 4 of
  the owner's list (direction tags in the picker, twin presets with
  brackets) and the picture answers of Select the image are Revision 4
  work (recorded in the catalogue plan). Owner (16:45): "after commit go
  on with next revision".
  **Revision 4 started 16:55**: `git stash pop` done (one conflict in
  `course_editor_screen.dart`, both inserted blocks kept: `_compactButtonStyle`
  and `_PresetActionChip`; stash dropped), analyzer clean, Stage 1 focused
  batch running (`scratchpad/s9_stage1.log`),
  `test/preset_catalogue_256_test.dart` written (registry groups,
  directions, renames, coming-later list, planner, picker filter and
  greyed tiles, Help section). Then Stage 2. The original note follows:
  `git stash pop`
  restores Stage 1 (stash@{0}) and Session 5 continues from "Session 5
  starting points" below, with the direction decisions (pairs only where
  meaningful, bracket only on the twins).
- Untracked files that are the owner's and stay untouched:
  `devtools_options.yaml`, `tools/cloud_setup.sh` (commit with
  `git add -A -- . ':!devtools_options.yaml' ':!tools/cloud_setup.sh'`).
- Auto-resume: an in-session hourly cron (`CronCreate` job `6dfcb607`, at
  :23) re-enters the work from this handoff if the session stopped, until it
  expires after 7 days or all seven sessions are committed (then delete it
  with `CronDelete`). It cannot survive the desktop app closing.

## Session 3 (done, `41dd91a`)

What the design below asked for is implemented (see `CHANGELOG.md` and
`docs/256_CHANGE_SUMMARY.md`, Revision 2): `ExerciseFeatures` and
`LearnerExerciseKind` (`lib/models/exercise_features.dart`), the Round
screen on primitives and features with the shared `ExercisePromptPanels`,
the Duel by capability with the same panels, `ExerciseCopyService` keyed by
kind, `TranslationChoice.instructionFor`/`spokenTextFor`, audio exercises
by required audio, linear Stories, content-based gap grading, the Audit on
canonical data through the registry (`presetKinds`; 102 codes), the
converter refinements (`situation`, `character`, Match side languages,
`clue` text languages, optional translation audio; bundled Courses
regenerated), the Laboratory presentation baseline
(`test/support/laboratory_presentation_254.dart`, three deliberate changes
marked) and `test/runtime_canonical_256_test.dart`. Preset-dependent
runtime branches remaining: none (plan A.3; `rg "\.type\b" lib/screens/round_screen.dart lib/screens/duel_screen.dart`
finds only the `_ChoiceOption`/element-type reads).

Session 5 starting points (Revision 4, `2.0.56+256004`: the preset
catalogue, `docs/256_PRESET_CATALOGUE_PLAN.md`; written 12:20 before the
Revision 3 commit):

- Registry: `ExercisePreset` gains `direction` (toTarget, toSource, both,
  none), `status` (active, comingLater with the reason) and a skill group
  replacing `ExerciseCategory` (vocabulary, grammarAndSentences, listening,
  readingAndDialogue, picturesAndCharacters, cardsAndNotes, comingLater);
  the action chip (Choose, Type, Arrange, Match, Card) comes from the
  primitive. Retired IDs (`choice`, `fill_blank`, `matching`,
  `listening_choice`, `listening_comprehension`, `reading_comprehension`,
  `contextual_comprehension`, `dialogue_response`, `type_translation`,
  `build_translation`) leave the registry; `PresetRecipes.presetToEdit`
  then recognizes by content, the Audit keeps their kinds in
  `_retiredPresetKinds` for Info only. Pick the translation (to target /
  to source) untouched.
- Recipes: rewrite `ExerciseDraftBuilder` preset by preset into canonical
  construction (`Exercise.canonical`), starting with the merged and paired
  presets, so the v11 shapes and the `Exercise` views can go; every recipe
  gets `exampleDraft(course)` (labelled placeholders like the New Course
  sample) and `requiredFields`; `PresetRecipes.represents` unchanged.
- Editor form: fields per preset from the recipe; the save guard refuses
  while any required field still equals its example (message lists them);
  switches only where the plan keeps them (one/several correct answers,
  show the first letter, letters/syllables, text/dialogue lines).
- Picker (`_choosePreset` sheet, and the Exercise Wizard's list): skill
  groups, action chips, direction filter (All / To target / To source),
  greyed "in a later version" tiles; Help and tooltips (Choose the answer
  asks about grammar, culture, meaning too).
- Runtime (small): within-word Input gap (Missing letters), word tiles
  without a picture (Spell what you hear, Spell the word; the
  `IMAGE_WORD_IMAGE_REQUIRED` rule becomes "picture, audio or clue"),
  syllable tiles (split at `|`), picture left items in Match; Picture
  flashcard = Flashcard + picture + optional usage example with optional
  read-aloud (`required: false`).
- Tests: recipes for every new preset (represents + recognize), the save
  guard, the picker filter, the runtime additions, the Laboratory
  presentation baseline re-recorded for renamed and merged presets (or the
  Laboratory generator extended for the new presets, else Session 7).
- Docs: CHANGELOG, `docs/256_CHANGE_SUMMARY.md`, `docs/256_VALIDATION.md`,
  AGENTS entry, Help EN/IT/ES for the catalogue; then the suite, commit
  "Build 256 Revision 4: the preset catalogue", APK, sound.
- Blast radius measured at 12:35 (preset IDs are enumerated in):
  `lib/models/exercise_authoring.dart` (registry, `helpByPreset`),
  `lib/services/exercise_draft_builder.dart` (recipes),
  `lib/services/preset_recipes.dart` (`kinds`, decompose),
  `lib/services/exercise_field_help.dart` (`editorFieldKeys` per preset,
  `forEditorField`), `lib/localization/help/help_structure.dart`
  (`exerciseHelpPresetIds`, `exerciseHelpCategoryIds`,
  `exerciseHelpFieldKeyByPresetAndField`) and the three catalogs
  (`exerciseHelp.preset.<id>.description/body`, field bodies),
  `lib/services/exercise_search_service.dart` (search definitions per
  preset), `lib/services/course_audit_service.dart` (preset Warning rules,
  `_retiredPresetKinds`), `lib/services/exercise_creation_planner.dart`
  and the Wizard UI (`ExerciseCategory` balancing), `lib/services/guidebook_round_generator.dart`
  (generates `choice`, `gap_choice`, `listening_choice`, `word_match`,
  `audio_match`, `flashcard`), `lib/models/exercise_interoperability.dart`
  (engineering catalog, presetId hints), `lib/models/course_models.dart`
  (`_legacyTypeFromTemplate`, converter roles per preset), the Python
  generators in `tools/` for the bundled Courses (the Laboratory has every
  preset, the Piedmontese demo one Lesson per preset: tests
  `piedmontais_course_254_test` pin 24, `exercise_laboratory_254_test`
  and the presentation baseline cover all examples). Stage the work:
  1 registry + picker + Help/tooltips (retired IDs recognized by content);
  2 recipes and forms for merged/paired presets, example content and the
  save guard; 3 new presets with their runtime additions; 4 bundled
  Courses regenerated (or the Laboratory left to Session 7 with the pins
  updated). Handoff after every stage.

Session 4 starting points (plan Part B Session 4; A.12, A.13):

- Presets as recipes: `ExercisePreset` gains the recipe (the kind it
  produces is `CourseAuditService.presetKinds`, to move next to the preset)
  and exact recognition (decompose → rebuild → `semanticallyEquals`), never
  writing; unknown `authoringMetadata` keys cleared when canonical content
  is edited (A.13); View only and Inspection show canonical data.
- The Generic Primitive Editor in new files (not inside
  `course_editor_screen.dart`): Primitive, Options (controls from the
  registry), Prompt/media, Items, Targets, Layout, Evaluation, Feedback.
- Move the editor, `exercise_draft_builder.dart`, `exercise_search_service.dart`,
  `authoring_duplication_service.dart`, `course_hierarchy_update_service.dart`
  and `script_recognition_editor.dart` off the v11 views on `Exercise`
  (`interaction`, `evaluation`, `type`, `prompt`, `question`, `tts`,
  `answers`, `correct`, `accepted`, `missingWords`, `tokens`, `orderAnswer`,
  `pairs`, `icons`, `imageAsset`, `contextText`, `contextAudio`,
  `dialogueTurns`, `contextMode`, `hasArrangeGaps`, `hasSelectGaps`,
  `isMultiSelect`, `correctItemIdSet`, `requiredSelectionCount`,
  `correctTranslationTexts`); delete each view when its last reader goes
  (`maxSelectionCount` and `orderAnswers` already have none in `lib/`).
- Help (A.12): Primitives, Primitive options, Layouts, Evaluation modes and
  Presets chapters in EN, IT and ES (`localization_catalog_test` enforces
  key parity); the Round editor for content nodes and Story order.
- Version `2.0.56+256003`, Beta expiry 30 days from the commit date,
  CHANGELOG, the three 256 documents, AGENTS.md boundary entry, then the
  six-part report and the commit "Build 256 Revision 3: presets as recipes
  and the Generic Primitive Editor".

## Session 3 design (Revision 2, `2.0.56+256002`): runtime and Audit on canonical data — delivered, kept for reference

Goal (plan A.3): nothing learners see reads a preset ID. Sizing on 27
September: `round_screen.dart` has 56 preset-dependent reads, the Audit
63, `duel_screen.dart` 9, `audio_exercise_availability_service.dart` 7,
`exercise_copy_service.dart` 5, `duel_eligibility_service.dart` 2; the
Laboratory covers every preset (24) and every converted shape but ten
(listed by the shape comparison over the four bundled Courses: the extra
ones are plain question-only Choose, a two-of-two multiple Choose, Choose
with image clues before the question, Fill in the blank with a `primary`
text, a Flashcard with audio last, Fill in the blank (Select) with a
`primary` sentence, Select the image with image+text items, What do you
hear with a written prompt, Build the translation with a `clue` text).

Order of work:

1. **Characterization first.** Extend `exercise_laboratory_254_test` so
   that, for every Laboratory example, the test records what the Round
   screen shows: heading, instruction, which panels are present (context,
   passage, dialogue, image, audio replay/play buttons), which controls
   (choice buttons, checkboxes, gap slots, text fields, chips, dropdowns)
   and the feedback texts after the correct answer. Compare with a map
   literal captured before the refactor; deliberate changes (A.10, A.11,
   merged headings below) are updated there with a comment.
2. **Features from canonical data**: a pure `ExerciseFeatures`
   (`lib/models/canonical/exercise_features.dart`) computed from primitive,
   options, elements, items, targets, layout, evaluation and feedback:
   inline layout, selection mode, automatic and required audio, passage
   (text or audio), context (text, audio, image, dialogue turns), question,
   clue image, image or icon items, text languages, `___` in a prompt
   text, joiner, showAlternatives, first-grapheme reveal, typo tolerance,
   literal answers, cardinality, Match left-side audio, completion mode.
   A `LearnerExerciseKind` derived from the features keys the headings and
   instructions (`ExerciseCopyService` re-keyed in all eight languages;
   the "opposite" heuristics stay, they read content). Kinds that today's
   presets distinguish only by preset ID merge into one label, reported in
   the session report: `matching` / `word_match` / `super_match` (one
   "MATCH" heading already; the instruction becomes the generic one unless
   the two sides carry different `language` attributes), and
   `dialogue_response` versus `reading_comprehension` (both a `passage` and
   a `question`; keep DIALOGUE by giving the converter a `dialogue` role for
   the passage of Dialogue response, regenerate the bundled Courses and the
   parity fixture) and `script_recognition` image-to-text versus Choose with
   an image clue (keep RECOGNIZE CHARACTERS through a `character` image
   role set by the converter). Decide each by the data in
   `assets/courses`; never by the preset ID.
3. **Runtime refactor by primitive** (Select → Input → Arrange → Match →
   Presentation), focused tests after each: `_exerciseBody` switches on
   the primitive and features; one Select renderer with optional panels,
   options as list or grid (text, image, icon), inline gap fill and
   multiple selection; Input as one field or inline gaps (a single gap with
   `reveal: firstGrapheme` is today's Type the missing word display, several
   gaps are today's Listen for missing words fields); Arrange as sequence
   chips (joiner) or inline gaps; Match as dropdown columns or audio cards
   (left items with audio); Presentation from the term/meaning/usage/
   usage_translation/audio roles with buttons from `completionMode`.
   Grading from `evaluation.mode` (exactItem, exactSet, assignments,
   expression/exactText/acceptedTexts with `literalAnswers` verbatim,
   `typoTolerance`, `showAlternatives` ranked → the translation feedback,
   exactOrder/acceptedOrders with the joiner, exactRelations). Audio: an
   element with `playback: automatic` is prepared and activated as today's
   listening exercises are; other audio elements get manual buttons (the
   app-bar Play audio button for a manual prompt audio). Correct-answer
   text and the feedback block from the evaluation; a wrong answer on a
   Select with image items shows the correct item's image (today only
   Recognize characters). `exercise-renderer-<type>` keys become
   `exercise-renderer-<primitive>` (used by six test files). The Duel
   screen reuses the extracted Select renderer (context panels, dialogue,
   image answers).
4. **Rounds as flows**: a Round with a linear `flow` plays its nodes in
   authored order, no shuffle and no mistake review; a content node shows
   the referenced textual Content as a card with Continue; exercise nodes
   run normally; XP, completion, Review and Laurels follow the normal Round
   rules (evaluable count = exercise nodes). A Round whose flow branches
   is not playable in this version (Round level, A.7); `RoundPlayabilityService`
   decides.
5. **Audit through the registry** (A.5): registry violations become Errors
   (`EXERCISE_OPTION_INVALID`, `EXERCISE_COMBINATION_ILLEGAL`,
   `EXERCISE_EVALUATION_MODE_INVALID`, `EXERCISE_SELECTION_LIMITS`,
   `EXERCISE_TARGET_REFERENCE`, plus the existing item ID and reference
   codes); the preset-specific rules become the non-blocking Warning
   `EXERCISE_PRESET_MISMATCH` ("does not match its preset"); an unknown
   preset ID is preserved and never blocks (Info); content rules (Arrange
   0–2 unused blocks, hint reveals the answer, automatic audio without
   text, inline layout without a target, `___` sentence rules) apply by
   content. Update the pinned code count
   (`test/audit_branch_ownership_226_02_revision4_test.dart` line 212) and
   the Audit Codes Help registry; fix the impossible multi-select limits
   case (Part C).
6. **A.10 Duel**: eligibility from features (Select, single selection,
   items in list or grid, exactItem, at least two items, exactly one
   correct); Contextual comprehension and Recognize characters join the
   pool, multiple-answer Choose leaves it. Report the availability change
   in the CHANGELOG and the session report.
7. **A.11**: inline-gap Arrange grades block content, not block IDs.
8. **`isAudioExercise`**: an exercise is an audio exercise when it has an
   audio element with `required` true (the default; Pick the translation
   converts with `required: false`), replacing the type list.
9. Delete each v11 view on `Exercise` when it loses its last reader
   (`type`, `prompt`, `question`, `tts`, `answers`, `correct`, `accepted`,
   `missingWords`, `tokens`, `orderAnswer(s)`, `correctTranslationTexts`,
   `pairs`, `icons`, `imageAsset`, `contextText`, `contextAudio`,
   `dialogueTurns`, `contextMode`, `interaction`, `evaluation`); the
   editor's readers stay until Session 4. `Exercise(...)` (72 test files)
   and `Exercise.v2` stay as test helpers.
10. Version `2.0.56+256002`, Beta expiry 30 days from the commit date,
    CHANGELOG, `256_CHANGE_SUMMARY.md`, `256_VALIDATION.md`, AGENTS.md
    boundary entry (and the "runtime reads v11 views" sentences in the
    invariants section), Help text where it names Duel eligibility, then
    the six-part report and the commit "Build 256 Revision 2: runtime and
    Audit on canonical data".

## Sessions

| Session | Revision | Version | State |
| --- | --- | --- | --- |
| 1 Canonical definitions | 0 | 2.0.56+256000 | committed `507be89` |
| 2 Course Model v12 | 1 | 2.0.56+256001 | committed `e850cc2` |
| 3 Runtime and Audit | 2 | 2.0.56+256002 | committed `41dd91a` |
| 4 Presets and Generic Primitive Editor | 3 | 2.0.56+256003 | committed `974f700` |
| 5 Preset catalogue (`docs/256_PRESET_CATALOGUE_PLAN.md`) | 4 | 2.0.56+256004 | not started (owner decisions taken 27 Sep 2026) |
| 6 Interoperability | 5 | 2.0.56+256005 | not started |
| 7 Laboratory, Assign, final verification | 6 | 2.0.56+256006 | not started |

## Decisions in flight

- Session 4, draft builder: `ExerciseDraftBuilder` keeps *constructing*
  candidates through `Exercise.v2(...)`/`Exercise(...)` (the v11 shapes are
  converter input, which AGENTS.md allows) while every *read* of an exercise
  moves to canonical fields or `ExerciseFeatures`. Rewriting the 24 recipes
  canonically now would be redone in Revision 4, which replaces the catalogue;
  the recipes are rewritten there, preset by preset.
- Preset catalogue (Session 5): every decision is in
  `docs/256_PRESET_CATALOGUE_PLAN.md` §1; §5 lists three small proposals the
  owner has not objected to (Match the words sides, True/False prefill
  language, card completion modes). Treat them as decided unless the owner
  says otherwise.
- None else new. Applied so far in Session 2 without asking (all within the
  plan): `tools/convert_course_to_v11.dart` is retired because it can no
  longer load v11 (the v12 converter takes v11 only; v9/v10 files need the
  Build 255 tool first); a Presentation given as the v11 shape without a
  timestamp gets the Round's `updatedAt` in files and the epoch in memory;
  custom presentation action lists become the standard completion mode.

## Gotchas

- Full suite: `flutter test --no-pub --concurrency=1` (about 22 minutes) run
  through the keep-awake wrapper (scratchpad `run_awake.ps1`). Always the
  path spelling `C:\QQL\QuisquisLingo`. Never run two Flutter commands at once.
- The Bash tool mangles some inline heredocs (quotes/backslashes): put edit
  scripts in the scratchpad with the file tool and run them by path.
- A Dart `library;` directive must precede imports.
- Audit code count is pinned at 104 in
  `test/audit_branch_ownership_226_02_revision4_test.dart` line 212.
- The keep-awake wrapper's `-LogFile` is written by `Tee-Object` as UTF-16:
  read it with Python (`open(p, 'rb').read().decode('utf-16')`), not with
  `rg`/`grep`, which see nothing. The runner compiles each test file when
  it reaches it, so a fix made during a run applies to files not yet
  loaded.
- Never `dart format` whole directories: 61 files predate Build 256
  unformatted. Format only the files `git status` lists; on 27 September
  at 07:00 a tree-wide run had to be undone with `git checkout --` on 53
  formatter-only files.
- Committing: stage with a pathspec that excludes `devtools_options.yaml`
  and `tools/cloud_setup.sh` (`git add -A -- . ':!devtools_options.yaml'
  ':!tools/cloud_setup.sh'`).
