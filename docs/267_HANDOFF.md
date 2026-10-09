# Build 267 handoff

Started 8 October 2026 (owner: "Start QQL 267"), in the main checkout
`C:\QQL\QuisquisLingo` on `main` (Build 266 is on `main` and pushed,
`ce4937e5`). Plan: `docs/267_COURSE_WIZARD_PLAN.md` (committed with
Revision 0, with a section "After Build 266"). Summary:
`docs/267_CHANGE_SUMMARY.md`; evidence: `docs/267_VALIDATION.md`.

Never stage `devtools_options.yaml`, `tools/cloud_setup.sh`,
`docs/COLLOCATION_PICTURES_PROPOSAL.*`. Commit locally only; never push or
open a pull request without the owner's word.

## What Build 266 already delivered from the 267 plan

- §5 picture prefill: done in 266 Revision 1 with the owner's later rules
  (exact name, singular, name before a bracket; never tags; on typing, Paste
  list and Fill only). Left from §5: a **Suggest pictures** button for rows
  that already exist.
- §6 picture exercises: 266 Revision 3 added Select the image, Match
  pictures to words and Picture flashcard. Left: five more presets and
  **Prefer picture exercises**.
- §10: the learner thumbnail is done (266 Revision 0).

**Owner's answers of 9 October 2026** (to the questions of 8 October):
1. **Yes**: a Suggest pictures button on the module page, with 266's
   matching rules (exact name, singular, name before a bracket; never tags),
   filling only empty picture slots, never replacing a chosen picture.
2. **Yes, all five and the switch**: What is in the picture, Spell the word
   in the picture, Name what you see, Type what you see and Listen and pick
   the image join the Round Wizard, with **Prefer picture exercises** (on
   by default when a module has pictured words: about half of each Round's
   focus slots).
3. **Spelling (9 October 2026, later):** Spell the word in the picture takes
   words of **at most 12 letters** (one tile per letter; the plan's 10 was
   only a proposal), and the Wizard spells **the word without its leading
   article** ("il gatto" → g-a-t-t-o; QQL's article lists of Word Lookup,
   `WordLookupArticles`, decide what an article is).
They come in Revision 3 (picture aids); Check and publish becomes Revision 4.

## Revision 0 (2.0.67+267000), the frame: committed

Decisions taken in this session (told to the owner in chat):
- The step bar lists only the steps that exist: steps 1–5 in Revision 0.
  Step 5's button is **Finish**: it saves, forgets the Wizard and opens the
  Course Editor. Revision 1 adds step 6.
- One `CourseAuthoringSession` per Wizard run; every save is
  `session.confirm` (version + 1, backup), version notes "Course Wizard:
  <step title>". `CourseAuthoringSession` now clears its new-Course flag
  after the first confirmation (a second confirmation threw before).
- The flag selector is on step 2 with the cover (New Course offered it; the
  plan's step lists did not name it).
- The Maintainer is the active profile; the Wizard offers no Maintainer
  choice (Course Info transfers it). Step 3's explanation says so.
- Lesson icons in the Wizard: Numbers, the preinstalled icons or a QQL
  picture of the library; importing a custom icon stays on the Lesson's page.
- Lessons step: cards with up/down arrows (no drag inside the page's list).
- Default Timed limits: preset chips, stored longest first.
- Closing the Wizard by the back button: no unsaved change → paused at this
  step ("Course Wizard paused."); an unsaved change → Save for now / Leave
  without saving / Keep working.

Checked (see the validation): analyzer clean, 18 new tests, the focused
batch of 639 tests, the complete suite 3,959 passed and 1 skipped (POSIX
only). Committed on 8 October 2026 as "Build 267 Revision 0: the Course
Wizard's frame" (the hash is in `git log`), local only.

## Revision 1 (2.0.67+267001), the GuideBook step: committed

Implemented: step 6 (`CourseWizardStep.guidebook`, `CourseWizardGuidebook`,
the screen's GuideBook fields, the pause's `lessonId`, `describe(course)`),
Help EN/IT/ES, docs, version pins. Decisions: a GuideBook being written in
the Wizard is a Draft and needs "This Lesson's GuideBook is ready" again
after a change; done = a module with 3+ words and Published; Finish names
the first Lesson not done. The Suggest pictures button is not in (owner's
answer pending). Analyzer clean; `course_wizard_267_test.dart` 21 tests and
a focused batch of 218 passed; complete suite 3,961 passed, 1 skipped.
Committed locally on 8 October 2026 as "Build 267 Revision 1: the Course
Wizard's GuideBook step".

## Revision 2 (2.0.67+267002), the Rounds step: committed

Implemented: step 7 (`CourseWizardStep.rounds`, `CourseWizardRounds`, Make
Rounds through `GuidebookRoundGeneratorScreen`, the Rounds list and Duel
line, shared Lesson chips), the Round Wizard's Round titles switch and Duel
count, Help EN/IT/ES, docs, version 2.0.67+267002 dated 9 October (Beta
expiry 8 November: the suite ends after midnight). Not in: the five further
picture presets and Prefer picture exercises (owner's answer pending).
Analyzer clean; `course_wizard_267_test.dart` 22 passed; focused batch 191
passed; the first complete suite failed 2 narrow-window tests (the Round
titles switch moved Review generation plan below the fold; the test now
scrolls), the second passed 3,963, 1 skipped. Committed on 9 October 2026.

## Revision 3 (2.0.67+267003), picture aids and a simpler Wizard: committed

Implemented: Suggest pictures on the module page
(`guidebook-module-suggest-pictures`, 266's matching rules, empty slots
only); the Round Wizard's five further picture presets and **Prefer picture
exercises** (`generator-prefer-pictures`; Review slots keep the text
presets, `reviewSafe`; Spell the word in the picture: at most 12 letters,
without the leading article); Review generation plan pinned in the Round
Wizard's bottom bar while configuring, the total above the switches; the
owner's simplification of the Wizard (below), with the GuideBook and
Rounds explanations split, the Round Wizard titled Generate Rounds, and a
tap on a paused Wizard Course's row opening the Wizard; the Round Wizard's
default Round types (Discover, Practice, Test) with a Listen Round switch;
Turn on audio for the learner; the Preview's audio waiting for Before you
start's Continue (owner report); the Finish popup; Audit in the exercise
menu; nothing asked twice in a Round, and two Matches of different pairs no
longer duplicates for the Audit. Version 2.0.67+267003 dated 9 October (Beta expiry
8 November). Analyzer clean; `picture_aids_267_test.dart` 7 and
`course_wizard_267_test.dart` 22 passed; focused batch 248 passed; complete
suite 3,975 passed, 1 skipped (POSIX only). Committed locally on 9 October 2026 as "Build 267 Revision 3:
picture aids; a simpler Course Wizard".

## Revision 4 (2.0.67+267004), Check and publish: committed

Implemented: step 8 (`CourseWizardStep.check`, `CourseWizardCheck`,
`CourseWizardPublish`), the Lesson cards, Open the Audit, Preview, Publish
(one confirmed save, what an Audit error names stays Draft and is listed),
Finish / Finish without publishing, the Finish message adapted (owner), the
plan pages' "Nothing is created yet: this is only the plan.", Help EN/IT/ES.
Analyzer clean; `check_and_publish_267_test.dart` 2 and `course_wizard_267_test.dart` 22 passed; focused batch 112; complete suite 3,977 passed, 1 skipped. Committed locally on 9 October 2026 as
"Build 267 Revision 4: the Course Wizard's Check and publish".

## Revision 5 (2.0.67+267005), GuideBook size advice: committed

Implemented as decided (the advice texts approved in chat on 9 October
2026): `GuidebookSizeAdvice`, `GuidebookSizeHint` on the GuideBook page,
the module page (live count), the Wizard's GuideBook step and the Round
Wizard's plan; Audit Info `GUIDEBOOK_MODULE_SIZE` and
`GUIDEBOOK_MODULE_COUNT`; Help EN/IT/ES. "Over 12 entries" counts each list
(words or Sentences) on its own, as the Round Wizard cycles each list.
Analyzer clean; `guidebook_size_advice_267_test.dart` 5 passed; complete
suite 3,982 passed, 1 skipped. Committed locally on 9 October 2026 as
"Build 267 Revision 5: GuideBook size advice for the Round Wizard".

## Revision 6 (2.0.67+267006), Create Duels off; New Course and paused Wizards: committed

Implemented as decided: `createDuels: false` where a Course is created (not
the model default: the JSON stores the field only when false), the
paused-Wizard dialog on New Course, the selector's New Course through
`startNewCourse`. Help EN/IT/ES. Analyzer clean; complete suite 3,984 passed, 1
skipped. Committed locally on 9 October 2026 as "Build 267 Revision 6:
Create Duels off for new Courses; New Course and paused Wizards".

## Next

- Revision 7, the picture answer border (owner decisions of 9 October 2026, mock-up in
  chat): look A, a thin neutral grey line (about 1.5 px) following the
  round or square shape, distinct from selection and feedback colours;
  picture answers only (Select the image, Listen and pick the image); on
  by default for new Courses only (existing Courses keep today's look);
  a Course choice in Lesson Options that an exercise can override, like
  size, shape and per row.
- Revision 8, **Editor Notes**: an optional notes field on every item of
  a Round (scored exercises, Before you start cards, Pages, Dialogue
  lines, Story covers), in the preset and canonical forms; stored in the
  Course file (export, import, Copy, Fork keep it), removed by Export as
  Publisher Course; never shown to learners, outside semantic equality
  and preset recognition; a note icon on the exercise's row in the Round
  editor shows it on hover or long press; a new optional Course field, so
  `minimumAppBuild` rises on confirmation like Page blocks or plurals.
  JSON (told to the owner on 9 October 2026): `editorNotes`, a string on
  the Content object beside `id`, `kind` and `authoringMetadata`; stored
  only when not empty; not inside `exercise` (canonical, semantic
  equality) nor inside `authoringMetadata` (cleared when the exercise
  changes, plan A.13); proposed limit 2,000 characters.
- Then, later and not now (owner: "leave it for afterwards"): the Italian
  picture-led demo built with the Wizard (each module and Round approved
  by the owner).

## Owner's simplification of the Wizard (9 October 2026, ~01:30)

Folded into Revision 3 (with the picture aids), before its complete suite:
- Step 1 **Basics**: Title, Source language (the owner first suggested
  "Learner's language", then, ~01:45, kept **Source** as everywhere in the
  app: a wording to discuss later, not to publish), Target language, Variant (optional; example "American English", never "Italian of
  Italy" or "Brazilian Portuguese"; Fill with an example leaves it empty).
  A shorter introduction.
- New step 2 **Flag or cover image**: the flag and cover section only.
- Step 3 **About the Course**: Description and Authors in view; everything
  else of Course Info (levels, study hours, minimum age, keywords, roles,
  license, derivative works, Rights Holders, Buy a Coffee, publisher
  contact) behind **Advanced**, explained as fields that can wait and be
  filled in later. The Credits and rights step is gone.
- The long explanations are hidden: a short line in view, the rest behind a
  "Tell me more" toggle.
- **Course options**: nothing but Advanced (all options keep their defaults).
- **Lessons**: titles only; icons, sections and the longer explanation under
  Advanced.
- The step bar scrolls to the current step on Next, Back and jumps.
- GuideBook step: **Fill with an example** opens the example module on the
  module page. The long GuideBook explanation is split (owner): what a
  module holds, the picture suggestions and Fill sit in a short note above
  the modules (`course-wizard-module-explanation`); the panel keeps what is
  needed now and the approval.
- Rounds step, the same split (owner): what the Round Wizard does stands
  above Make Rounds (`course-wizard-rounds-explanation`); the Round Wizard's
  page title "Generate Rounds from GuideBook" becomes **Generate Rounds**
  (owner: "rename Generate rounds from generator to Generate rounds", read
  as that title; the Make Rounds button keeps its name).
- Course Studio: a tap on the row of a paused Wizard Course opens the
  Wizard (`_openRow`, when Continue Course Wizard is available); Edit in the
  ⋮ menu opens the Course Editor.
- Later revision (owner, 9 October 2026): a **New Course** button in the
  learner's Course Selector.
- Round types (owner, 9 October 2026: "not Practice six times"): the plan
  proposes Discover first, Test last, Practice between. The owner first
  chose a Listen Round in the middle too; told that a learner with Audio
  Exercises off (the default) could then never finish that Round nor its
  Lesson, the owner answered "Ask", then "Both": the author is asked (the
  Round Wizard's **Listen Round** switch, off by default) and the learner
  is asked (**Turn on audio** on a Round of audio exercises).
- Step 7 (owner: "make it simple"): the Round Wizard from the Course
  Wizard starts with Round titles off.
- Owner, 9 October 2026: "We need an Audit option for exercise 3 dots! I
  don't know why some are red, in the Wizard". Every red generated exercise
  was the `ROUND_DUPLICATE_CONTENT` Warning (180 in 10 sample plans): the
  generator reused a sentence or a pair in a Round, the sample has "il
  conto" twice, and two Matches of different words counted as one. Done:
  Audit in the exercise ⋮ menu (`RoundEditorScreen._auditExercise`), the
  generator's fresh-content choice (`_Material.withFreshContent`,
  `_freshSlot`, `_contentKey` by the words shown), and the Audit's key
  compares a Match's pairs. 0 warnings after.
- Owner, 9 October 2026: Finish shows a short popup (congratulations,
  what is still red, Edit mode, Publish): `_congratulate`.
- Fix (owner report): the Preview played the first exercise's audio behind
  Before you start (`_isPreparedExerciseActive` returned true in Preview);
  it now waits for Continue. History is squashed, so when it began is not
  known; the Preview has shown the card since Build 257.
- Deferred by the owner ("can wait"): a **Border** option for picture
  answers, in the Wizard and in the Course Editor's Lesson Options alike.
