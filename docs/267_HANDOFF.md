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

## Next

- If the owner says yes to question 1: the Suggest pictures button on the
  module page (a Revision 1 follow-up).
- If the owner says yes to question 2: the five further picture presets and
  Prefer picture exercises in the Round Wizard (a Revision 2 follow-up or its
  own revision).
- Revision 3: step 8 (Check and publish, Publish, Finish).
