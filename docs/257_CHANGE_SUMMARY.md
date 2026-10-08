# Build 257 change summary

Build 257 starts interactive presentation cards with their first slice,
the **Before you start** card. Evidence: `257_VALIDATION.md`; handoff:
`257_HANDOFF.md`. Build 256's documents stay the reference for Course Model
v12 (`256_CHANGE_SUMMARY.md`, `EXERCISE_ARCHITECTURE_V12.md`).

## Revision 0 (2.0.57+257000, 29 September 2026): Before you start cards

The owner asked how to edit the "Before you start" note that introduces a
Round. It had no editor field: it was text Content with role `lesson_intro`
that only the bundled Courses carried, and the Round Wizard wrote one as a
Draft that nothing could publish. The owner decided (29 September 2026) to
make it a special case of interactive presentation cards:

1. start small: Continue and Open GuideBook only, no branching;
2. the card is not shown in Review (it was until now);
3. Open GuideBook is a switch on each card, greyed out while the Course
   does not use GuideBooks, and hidden from learners while the Lesson's
   GuideBook is Draft;
4. existing notes: "choose the simpler solution". Claude chose the clean
   cut (below) because official checksums are computed from the parsed
   Course, so reading old notes as cards would have changed every bundled
   checksum anyway, and outside the bundled Courses the only stored notes
   were the Round Wizard's Draft ones, which learners never saw.

### Model

- `OptionKey.guidebookButton` (boolean) on the presentation primitive,
  default false (`PrimitiveCapabilityRegistry`); `docs/capabilities_v12.json`
  regenerated with `tools/export_capabilities.dart`.
- A card is a presentation whose prompt has a text element with role
  `intro`: `ExerciseFeatures.introElements`, `introText`,
  `guidebookButton`, `LearnerExerciseKind.roundIntro` (derived after a
  Dialogue line, before a Story cover). `Exercise.beforeYouStart` is the one
  constructor (form builder, Round Wizard, Dart converter); Python mirrors
  it as `before_you_start()` in `tools/qql_course_v12.py`.

### Authoring

- Preset `before_you_start`, "Before you start" (Cards and notes,
  `PresetDirection.none`), a canonical-only recipe
  (`PresetRecipes.canonicalOnly`, `kinds`, `PresetVariants.ownForms` and
  `fits`); `ExerciseDraftValues.guidebookButton`;
  `ExerciseDraftBuilder._buildBeforeYouStart`.
- The form: **Note** (`exercise-field-prompt`, five lines) and **Open
  GuideBook button** (`before-you-start-guidebook-switch`), greyed out with
  an explanation while `Course.useGuidebook` is off; no picture field
  (`ExerciseFieldHelpRegistry.editorFieldKeys`). Field Help
  `ExerciseAuthoringField.introText` and `guidebookButton`.
- The Round editor inserts a new card first (`_isRoundIntro`) and names it
  in its list by the note (`_exerciseSummary`). Search finds the note
  (`ExerciseTypeSearchDefinition`). The Story's Add step does not offer it,
  and a Story's steps line (`_storyStepsSummary`) does not count a card as
  an exercise (the Edge Case Story opens with one).
- The Round Wizard's first Round opens with a Draft card holding the
  GuideBook overview (formerly "Before you start: <overview>.") with Open
  GuideBook on, carrying the same source references.

### Runtime

- `RoundPlayabilityService.isRoundIntro` and `introFor`: a card is never a
  playable step (no queue, no Laurel, no step count), and the card a learner
  sees is the first published one with a note and no Audit error (any card
  in Preview).
- `RoundScreen._lessonIntro` is found once when the Round is prepared,
  null in Review. The Before you start page shows the note; its Open
  Guidebook button (`before-you-start-guidebook`) needs the card's option,
  Use GuideBook and a published GuideBook (any GuideBook in Preview). A
  Preview of the card alone shows the page and closes with **Close
  preview** (`before-you-start-continue`).

### Audit (110 rules)

- `ROUND_INTRO_EMPTY` (Error): a card without a note.
- `ROUND_INTRO_DUPLICATE` (Warning): a second card in a Round; learners see
  only the first published one.
- `LESSON_INTRO_MISSING` (Info) now looks for a card in the first Round.
- `kindLabel` "a Before you start card"; `PRESET_CANONICAL_MISMATCH` hint.

### Existing data (clean cut)

- Text Content with role `lesson_intro` is no longer shown; it stays in the
  file untouched (the editor keeps non-runnable Content in place).
- The v11 → v12 converter maps a v11 `lesson_intro` note to a card with Open
  GuideBook on (as the note offered the GuideBook), preset
  `before_you_start`, the Round's timestamp: `course_model_v12_converter.dart`
  and `convert_content` in `tools/qql_course_v12.py`, kept equal by the
  parity test. The generators mark such Story flow nodes `exercise`
  (`becomes_exercise`).
- Regenerated: `assets/courses/exercise_laboratory_en_it.json`,
  `edge_case_it_en.json`, `piedmontais_en.json` and
  `test/fixtures/v12/laboratory_future_en_it.json`. `tools/validate_courses.py`
  now wants a Before you start card first in each Lesson's first Round.
- Not converted: the Publisher test fixtures (signed) and the Korean v12
  test fixture keep their old notes, which no longer show.

### Help (EN/IT/ES)

- Preset description and body, the Note and Open GuideBook button fields,
  and the Editor Help question `beforeYouStart` in Lessons and Rounds
  ("How do I write the Before you start note of a Round?"; 67 questions).

### Unchanged

Scoring, progression, Review selection, the Duel pool, learner data, the
Course format version (12) and package format 1.
