# Build 256 handoff — exercise architecture redesign (Course Model v12)

Resume from this file alone. Plan: `docs/256_EXERCISE_ARCHITECTURE_PLAN.md`
(Part A decisions, Part B sessions, Part C verified audit notes, Part D
condensed specification). Working rules: Part A.1 of the plan. Reference:
`docs/EXERCISE_ARCHITECTURE_V12.md` (its "Course Model v12 JSON" section is
the Session 2 design). Summary: `docs/256_CHANGE_SUMMARY.md`. Evidence:
`docs/256_VALIDATION.md`.

## State (27 September 2026, 09:43)

- Branch `claude/256-exercise-architecture`, created from `main` at
  `611a1a1` (Build 255 handoff; version `2.0.55+255007`).
- Commits: `507be89` Build 256 Revision 0 (canonical definitions;
  `2.0.56+256000`); `4e19353` handoff; `e850cc2` Build 256 Revision 1
  (Course Model v12; `2.0.56+256001`; suite 2,829 passed, 1 skipped);
  `b480e15`, `af15ff0` handoffs.
- **Session 3 (Revision 2, `2.0.56+256002`) is complete in the working
  tree, uncommitted, with the complete suite running for the second time**
  through the keep-awake wrapper (log: scratchpad `full_rev2b.log`,
  UTF-16). The first run (09:14–09:36) gave 2,837 passed, 1 skipped, 3
  failed, all fixed since: `IMAGE_WORD_IMAGE_REQUIRED` is an Error again
  (the picture is the prompt of a word-building Arrange: a solvability
  rule, now emitted by kind), `imported_course_v6_regression_test` checks
  the canonical dispatch of the listening-spelling renderer, and
  `authoring_transfer_ui_226_02_test` expects a green destination Round
  (a hint on a Choose is no longer the retired "unexpected field"
  warning). Analyzer clean; the affected files pass (216 tests). When the suite passes:
  write the Revision 2 section of `docs/256_VALIDATION.md`, commit
  everything except the owner's untracked `devtools_options.yaml` and
  `tools/cloud_setup.sh` as "Build 256 Revision 2: runtime and Audit on
  canonical data", write this handoff again and commit it, then start
  Session 4 at once (plan Part B, Session 4; A.12, A.13). If the suite
  fails: rerun the failing file alone; any fix means rerunning that file
  and the complete suite before the commit (plan A.1).
- Untracked files that are the owner's and stay untouched:
  `devtools_options.yaml`, `tools/cloud_setup.sh` (commit with
  `git add -A -- . ':!devtools_options.yaml' ':!tools/cloud_setup.sh'`).
- Auto-resume: an in-session hourly cron (`CronCreate` job `6dfcb607`, at
  :23) re-enters the work from this handoff if the session stopped, until it
  expires after 7 days or all six sessions are committed (then delete it with
  `CronDelete`). It cannot survive the desktop app closing.

## Session 3 (done in the working tree)

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

## Session 3 design (Revision 2, `2.0.56+256002`): runtime and Audit on canonical data

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
| 3 Runtime and Audit | 2 | 2.0.56+256002 | complete in the working tree; suite running |
| 4 Presets and Generic Primitive Editor | 3 | 2.0.56+256003 | not started |
| 5 Interoperability | 4 | 2.0.56+256004 | not started |
| 6 Laboratory, Assign, final verification | 5 | 2.0.56+256005 | not started |

## Decisions in flight

- None new. Applied so far in Session 2 without asking (all within the
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
