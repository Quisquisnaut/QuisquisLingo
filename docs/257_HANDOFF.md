# Build 257 handoff — Before you start cards

Resume from this file alone. Build 256's handoff (`docs/256_HANDOFF.md`)
holds the process rules (version pins, focused batches, the complete suite
under the keep-awake wrapper, commit staging); they apply unchanged.

## State (29 September 2026, 15:22)

- Branch `claude/257-before-you-start-card`, created from
  `claude/256-revision9-exercise-mascots` at `158d18a` (Revision 9 and its
  handoff, not pushed). Work in progress, nothing committed yet.
- Target version `2.0.57+257000`, **QQL Build 257, Revision 0**.

## Owner decisions (29 September 2026, conversation)

The owner asked how to edit a Round's "Before you start" note (it had no
editor field) and chose to make it a special case of **interactive
presentation cards**:

1. Start small: the card's actions are Continue and **Open GuideBook**; no
   branching (a flow's `onChoice` stays parked with Adventures).
2. The card is **not shown in Review** (before Build 257 it was).
3. Open GuideBook is a **switch on each card**, greyed out while the Course
   has Use GuideBook off, and the button is hidden from learners while the
   Lesson's GuideBook is Draft (Preview shows it).
4. Existing notes: "choose the simpler solution". Claude chose the **clean
   cut**: stored `lesson_intro` text Content is no longer shown; the v11
   converter (Dart and Python) and the generators write the new card.
   Reason: official checksums are computed from the parsed Course, so
   reading old notes as cards would have changed every bundled checksum
   anyway; outside the bundled Courses the only stored notes were the
   Round Wizard's Draft ones, which learners never saw.
5. Bump to Build 257; commit and write the handoff at the end.

This revises the 29 September Build 256 decision recorded in
`docs/256_HANDOFF.md` (the card stayed Round content, no interactive
presentation primitive).

## Design (implemented in the working tree)

- No new primitive: the `presentation` primitive gains the boolean option
  **`guidebookButton`** (default false; `OptionKey.guidebookButton`,
  registry, `docs/capabilities_v12.json` regenerated).
- A **Before you start card** is a presentation whose prompt has a text
  element with role **`intro`**: `ExerciseFeatures.introElements`,
  `introText`, `guidebookButton`, `LearnerExerciseKind.roundIntro`.
  One constructor: `Exercise.beforeYouStart` (form builder, Round Wizard,
  Dart converter); Python `before_you_start()` in `tools/qql_course_v12.py`.
- Preset **`before_you_start`** "Before you start" (Cards and notes,
  canonical-only recipe; form: Note + `before-you-start-guidebook-switch`,
  no picture field). `ExerciseDraftValues.guidebookButton`.
- Runtime: `RoundPlayabilityService` never counts the card as a step
  (`isRoundIntro`, `introFor`); `RoundScreen._lessonIntro` is the first
  published card with a note and no Audit error, null in Review; the Open
  GuideBook button (`before-you-start-guidebook`) needs the card's switch,
  Use GuideBook and a published GuideBook (any in Preview); a Preview of the
  card alone shows it and closes (`before-you-start-continue`, "Close
  preview").
- Round editor: a new card goes first; the list names it by its note.
- Audit (110 rules): `ROUND_INTRO_EMPTY` (Error), `ROUND_INTRO_DUPLICATE`
  (Warning); `LESSON_INTRO_MISSING` now looks for the card.
- Round Wizard: its first Round starts with a Draft card (the GuideBook
  overview, Open GuideBook on).
- Converters: v11 `lesson_intro` text → card with Open GuideBook on
  (`course_model_v12_converter.dart`, `qql_course_v12.convert_content`);
  generators mark those Story flow nodes `exercise` (`becomes_exercise`).
  Bundled Courses and `test/fixtures/v12/laboratory_future_en_it.json`
  regenerated; `--check` and `tools/validate_courses.py` pass (validator:
  a Lesson's first Round starts with a Before you start card).
- Search definition, field Help, preset Help and a new Editor Help question
  (`beforeYouStart`, 67 questions) in EN/IT/ES.

## Progress

- Done in the working tree: all code above, the new test file
  `test/before_you_start_card_257_test.dart`, the updated tests (see
  `docs/257_VALIDATION.md`), the version bump to `2.0.57+257000` (all pins),
  CHANGELOG, README, AGENTS entry and invariant, `docs/257_CHANGE_SUMMARY.md`,
  `docs/257_VALIDATION.md` (results pending), `docs/COURSE_JSON_FORMAT.md`
  and `docs/EXERCISE_ARCHITECTURE_V12.md`. `dart format` on changed files,
  `flutter analyze --no-pub` clean.
- `notCompletableReason` ignores cards (a Round of a card and unplayable
  exercises still gets ROUND_NOT_COMPLETABLE); the future fixture's cards
  carry no preset (the fixture is canonical-only).
- Batch 1 (57 files) found the expected failures, all fixed; batch 2 (27
  files) left three, fixed and rerun green (80 tests). A Story's steps line
  no longer counts a card (Story editor tests green).
- Complete suite run 1 (15:21–15:49): 3306 passed, 1 skipped, 1 failed
  (`revision7_followup_256_test`, the Assign example count saw the card);
  fixed, file rerun green; run 2 (15:50–16:18) **3307 passed, 1 skipped,
  0 failed** (`suite.log`; run 1 is `suite_run1.log`).
- Owner request during the run (29 September): after the commit and the
  handoff, prepare a **read-only plan** for textbook-like page cards
  (headings, bold, italic, alignment for texts and images, video, a
  dedicated preset). Draft in this session's scratchpad
  (`258_PAGE_CARD_PLAN.md`), to become `docs/258_PAGE_CARD_PLAN.md`.

## Remaining

- Batch 2 green, then the complete suite once, the validation results,
  one local commit "Build 257 Revision 0: Before you start cards", this
  handoff with the hash, the sound.
