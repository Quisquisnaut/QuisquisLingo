# Build 256 handoff — exercise architecture redesign (Course Model v12)

Resume from this file alone. Plan: `docs/256_EXERCISE_ARCHITECTURE_PLAN.md`
(Part A decisions, Part B sessions, Part C verified audit notes, Part D
condensed specification). Working rules: Part A.1 of the plan. Reference:
`docs/EXERCISE_ARCHITECTURE_V12.md` (its "Course Model v12 JSON" section is
the Session 2 design). Summary: `docs/256_CHANGE_SUMMARY.md`. Evidence:
`docs/256_VALIDATION.md`.

## State (27 September 2026, 11:58)

- Branch `claude/256-exercise-architecture`, created from `main` at
  `611a1a1` (Build 255 handoff; version `2.0.55+255007`).
- Commits: `507be89` Build 256 Revision 0 (canonical definitions;
  `2.0.56+256000`); `e850cc2` Revision 1 (Course Model v12;
  `2.0.56+256001`); `41dd91a` **Build 256 Revision 2: runtime and Audit
  on canonical data** (`2.0.56+256002`; complete suite 2,840 passed, 1
  skipped, 0 failed; evidence in `docs/256_VALIDATION.md`); handoff
  commits between them.
- **Session 4 (Revision 3, `2.0.56+256003`) is in progress** (uncommitted;
  handoff written 11:35): step A `lib/services/preset_recipes.dart` +
  `test/preset_recipes_256_test.dart` (83 tests green); step B the exercise
  editor opens and reloads through `PresetRecipes.presetToEdit`/`decompose`
  (editor batch: 971 tests green); step C the Generic Primitive Editor:
  `lib/services/canonical_exercise_draft.dart` (pure draft; `toExercise`
  keeps carried metadata only while semantically unchanged and names the
  preset `PresetRecipes.recognize` finds, plan A.13; `blankExercise`),
  `lib/screens/primitive_editor_screen.dart` (sections Primitive, Options
  from the registry, Prompt, Items, Targets, Layout, Evaluation by mode,
  Feedback; Preview, Inspection, Save as draft, Save; runtime-support line;
  registry violations block Save), `lib/widgets/editor_dialogs.dart`
  (shared `confirmMoveToDraft`), wiring in `course_editor_screen.dart`
  (`_exerciseEditorFor` opens the canonical editor when no preset represents
  a stored exercise; Round editor button `new-canonical-exercise`; preset
  sheet entry `exercise-preset-canonical`; the preset form shows
  `exercise-unrepresentable-notice` and disables Save when no preset
  represents the exercise). Analyzer clean. `test/primitive_editor_256_test.dart`
  written; two expectations corrected (a Choose form has no hint field, so a
  hinted Choose is unrepresentable; a canonical exercise a recipe represents
  gets that preset on save); rerun pending.
- Done since (handoff 11:50, all uncommitted, analyzer clean before the
  last two steps): step D the v11-view readers moved to canonical data
  (`exercise_search_service.dart` through `PresetRecipes.presetToEdit` /
  `defaultPresetFor` and the canonical evaluation; `course_hierarchy_update_service.dart`
  `_contentText` through `ExerciseFeatures`; `script_recognition_editor.dart`
  rebuilds with `copyWith` and gives new images the `character` role; the
  editor's `_exerciseKindName` / `_exerciseTypeLabel` / `_exerciseSummary`
  helpers, `CourseAuditService.kindLabel` made public). Decision: the draft
  builder keeps constructing through `Exercise.v2`/`Exercise(...)` until
  Revision 4 rewrites the recipes. Step E **Stories survive authoring**: every
  `LearningRound(...)` rebuild dropped `flow` (Round editor, rename, Search
  save, GuideBook references, Move/Copy, duplication), so editing a Story made
  it a practice Round; `lib/services/round_flow_authoring.dart`
  (`linearFor`, `forContent`, `remapped`) and the Round editor's **Play as a
  Story** switch (`round-story-switch`, `_flow`, `_setStory`; a branching
  flow is kept as it is and asks before removal) fix that;
  `test/round_flow_authoring_256_test.dart` written, not yet run. Step F
  Help (A.12): the Exercise primitives technical page now has sections
  status, exerciseAnatomy, primitives, primitiveOptions, layouts,
  evaluationModes, promptAndItemMedia, presentationContent, presets,
  canonicalEditor, stories in EN/IT/ES, and Exercise Help has a
  `canonicalEditor` supplement (scratchpad `s4_help.py`). The editor test
  batch (`s4_batch2.log`, ~1,000 tests) was green at +917 when this was
  written.
- 11:55: the canonical-reads batch (`s4_batch2.log`) finished **1,215
  passed, 0 failed**. Version `2.0.56+256003` applied (pubspec,
  `app_metadata`, `qql_233_revision_platform_contract_test`,
  `qql_229_revision3_test`, `beta_lifecycle_test` title and service comment;
  Beta expiry unchanged, 27 October 2026, same release day), CHANGELOG entry,
  `docs/256_CHANGE_SUMMARY.md` and `docs/256_VALIDATION.md` Revision 3
  sections (validation has `<<FLOW>>`, `<<HELP>>`, `<<SUITE>>` placeholders
  to fill), `docs/EXERCISE_ARCHITECTURE_V12.md` status rows 4–7, README,
  AGENTS entry and invariants (scratchpad `s4_release.py`). Analyzer clean
  after one test fix (`CourseAuthoringTransferService()` is not const).
  Owner note (11:52): the future Picture flashcard also has a usage example
  with optional read-aloud; recorded in the catalogue plan.
- 12:09: the third batch finished 429 passed, 1 failed (the Story copy test
  used the official Laboratory, which Move/Copy and Copy as New Course
  refuse; the fixture is now a licensed Fork and the editor test saves as
  draft); `round_flow_authoring_256_test` then **7 passed**. Analyzer clean,
  every changed Dart file formatted. A first complete run (12:09) was
  stopped at +196 when `app_metadata_225_04_test` failed on the version
  pin: two more files pin the version (`app_metadata_225_04_test`,
  `course_audit_report_225_test`) and README line 352 names the Beta
  revision; all three moved to Revision 3 (plus the integer
  `correctiveRevision` pin in `app_metadata_225_04_test`, found on the
  next attempt). **The complete suite restarted at 12:05** after the five
  version tests passed (`run_awake.ps1`, log
  `scratchpad/suite_rev3.log`, UTF-16, about 23 minutes). Commit message
  ready in `scratchpad/commit_rev3.txt`. Version pins to remember for every
  revision: pubspec, `app_metadata.dart`, `beta_lifecycle_service.dart`
  comment, `qql_233_revision_platform_contract_test`,
  `qql_229_revision3_test`, `beta_lifecycle_test`,
  `app_metadata_225_04_test`, `course_audit_report_225_test`, README lines
  3 and 352.
- Still to do in Session 4: fix anything the batch shows; `dart format` on
  the last edited files; fill the validation placeholders; the complete
  suite once (`run_awake.ps1 -Command "flutter test --no-pub
  --concurrency=1" -LogFile …`, UTF-16 log, about 23 minutes); six-part
  report; commit "Build 256 Revision 3: presets as recipes and the Generic
  Primitive Editor" with `git add -A -- . ':!devtools_options.yaml'
  ':!tools/cloud_setup.sh'`; then `flutter build apk --debug --no-pub` with
  `JAVA_HOME="C:\Program Files\Android\Android Studio\jbr"` (output
  `build/app/outputs/flutter-apk/app-debug.apk`) and a sound
  (`C:\Windows\Media\tada.wav`); then start Session 5 (Revision 4, the
  catalogue). **Owner (11:30): handoff every 30 minutes; at the end of every
  revision build the Android debug APK and play a sound.**
- **Owner decisions of 27 September 2026 (11:30) on the preset catalogue**
  are recorded in `docs/256_PRESET_CATALOGUE_PLAN.md`: the catalogue overhaul
  (merges, renames, new and greyed presets, to-target/to-source pairs, picker
  filter, save guard against unchanged example content) is **its own
  revision right after Revision 3** (Revision 4, `2.0.56+256004`); the later
  sessions shift by one (Interoperability → Revision 5, Laboratory/Assign →
  Revision 6). Revision 3 keeps its planned scope.
- The owner asked (10:00) where to build a test release: from
  `C:\QQL\QuisquisLingo`, `tools\package_windows_release.ps1
  -RebuildFlutterApplication` writes
  `build\packages\quisquislingo_windows_beta_<buildnumber>.zip`; never
  while a `flutter test` run is going. No package was built by the agent.
- Untracked files that are the owner's and stay untouched:
  `devtools_options.yaml`, `tools/cloud_setup.sh` (commit with
  `git add -A -- . ':!devtools_options.yaml' ':!tools/cloud_setup.sh'`).
- Auto-resume: an in-session hourly cron (`CronCreate` job `6dfcb607`, at
  :23) re-enters the work from this handoff if the session stopped, until it
  expires after 7 days or all six sessions are committed (then delete it with
  `CronDelete`). It cannot survive the desktop app closing.

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
| 4 Presets and Generic Primitive Editor | 3 | 2.0.56+256003 | in progress |
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
