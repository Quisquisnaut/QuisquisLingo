# Build 267 validation

## Revision 0 (2.0.67+267000), 8 October 2026

Run on the owner's Windows PC (4 cores, 8 GB), `TEMP`/`TMP` on
`D:\QQL_test_temp` for the test processes only.

- `dart format` on the changed Dart files only (36 files; 7 reformatted, all
  of them files this revision changed).
- `flutter analyze --no-pub`: **No issues found.**
- New tests, `test/course_wizard_267_test.dart`: **18 passed**:
  - the pause record (round trip, description, unusable records ignored, a
    later build's step read as the last step) and the device memory (one
    key per URI-encoded Course ID, `all()` skips unusable records, forget);
  - the step values: the first save (Draft, no Lessons, New Course's
    defaults), About (fields, cleared ones left out, the cover credit added
    once, study hours and keyword limits), Credits, Course options (Use
    GuideBook kept on, custom label, Picture answers, Timed limits, defaults
    and problems), Lessons (new Drafts with empty GuideBooks, kept IDs and
    Rounds through a rename and a move, removal named, a title required),
    the example forming one coherent Course with approved icons;
  - one authoring session saving a new Course twice (versions 1 and 2, the
    second with a backup and the step's notes);
  - deleting the Course forgets its paused Wizard, and Course Manager offers
    Continue Course Wizard first; for someone who cannot edit the Course the
    entry is greyed with its reason, and without a paused Wizard it is not
    shown;
  - Course Studio: New Course opens the Wizard, Cancel stores nothing;
    Create it myself opens New Course's form with the first screen's
    values; Continue with the Course Wizard saves version 1, Fill and Next
    save version 2 with "Course Wizard: About the Course", Save for now
    closes and the row reads "Course Wizard paused: step 3 of 5 (Credits and
    rights)", Continue Course Wizard (first in the menu) resumes at step 3
    with steps 1–2 ticked; Finish refuses no Lessons and an untitled Lesson,
    Clear all asks first, Finish saves the Lessons and opens the Course
    Editor and forgets the Wizard; the Course Editor's paused line and
    Continue reopen the Wizard, Continue by hand forgets it;
  - leaving with an unsaved change asks; Leave without saving keeps the
    stored Course and the paused step;
  - every step fits a 360-pixel window;
  - Use GuideBook off asks first (Keep it on, Turn it off; turning it on
    asks nothing).
- Reset and Inventory: `app_reset_service_239_test.dart` (the custom-course
  reset removes `qql_course_wizard_…`, the other scopes keep it),
  `inventory_239_test.dart` (Paused Course Wizards listed, Forget allowed).
- Existing tests changed because the behaviour changed on purpose: New
  Course goes through Create it myself (`course_creation_flags_226_04`,
  `course_editor_layout_regression` (its source-structure finder made
  tolerant of the new `_createCourse(` parameter), `course_ownership_team_229_r1`
  (taps the dialog's own Cancel), `new_course_structure_226_04`,
  `provisional_mytest_workflow`); turning the GuideBook off confirms the
  notice (`lesson_controls_226_04`, `optional_learning_paths_226_04` ×2,
  `word_lookup_ui_265`); Editor Help has 87 questions
  (`editor_help_qa_256`, `editor_help_translation`); the version pins.
- Focused batch (48 files near the change, the Help and version tests):
  **639 passed.**
- Complete suite (`flutter test --no-pub --concurrency=1 --reporter compact`,
  Windows kept awake, 22:05–22:36): **3,959 passed, 1 skipped** (POSIX only),
  exit code 0. The Wizard's 18th test (the greyed menu entry) was added
  before the runner reached its file and ran in this suite.

## Revision 1 (2.0.67+267001), 8 October 2026

- `dart format` on the changed Dart files only; `flutter analyze --no-pub`:
  **No issues found.**
- `test/course_wizard_267_test.dart`: **20 passed** (written 21 at first,
  corrected on 9 October). New or changed for the
  GuideBook step:
  - the step's logic: a new Lesson is not done; a module with three Words &
    Expressions written as a Draft is usable but not done; approved
    (Published) it is done; `firstProblem` moves to the next Lesson; a
    Round focusing on a removed module loses the link, and `roundsNote` says
    so before; the paused line names the Lesson ("step 6 of 6 (GuideBook,
    Lesson 2)");
  - Course Studio: Next from Lessons saves them and opens step 6 with the
    first Lesson remembered; Finish names the Lesson without a usable
    module, then the one not approved; Fill and This Lesson's GuideBook is
    ready for each of three Lessons, each a saved version ("Course Wizard:
    GuideBook, Lesson N", Published, the module "Al bar"); Finish opens the
    Course Editor and forgets the Wizard;
  - the step on its own: the paused Lesson is shown; Add a module through
    the module page (title and three words, Done); Fill asks first over a
    module; move up; Remove asks first;
  - every step, the GuideBook included, fits a 360-pixel window.
- Inventory test: "step 3 of 6".
- Focused batch (the Wizard, Inventory, reset, Help, version pins, Course
  Studio and Course Manager, the GuideBook module tests of Build 266):
  **218 passed.**
- Complete suite (`flutter test --no-pub --concurrency=1 --reporter compact`,
  Windows kept awake, 22:48–23:21): **3,961 passed, 1 skipped** (POSIX only),
  exit code 0.

## Revision 2 (2.0.67+267002), 8–9 October 2026

- `dart format` on the changed Dart files only; `flutter analyze --no-pub`:
  **No issues found.**
- `test/course_wizard_267_test.dart`: **22 passed**. New or changed:
  - the Round Wizard makes untitled Rounds on request, the same number as
    titled ones; `CourseWizardRounds` (first Lesson without Rounds, adding,
    replacing, the Duel count of a Lesson);
  - the GuideBook flow now ends with Next to step 7 and Save for now, the
    row reading "step 7 of 7 (Rounds, Lesson 1)";
  - the Rounds step: a one-Lesson Course with an approved GuideBook, paused
    at step 7; "No Rounds yet", "Duel: 0 questions (25 needed)"; Finish
    refused naming the Lesson; Make Rounds opens the Round Wizard, Round
    titles off, the plan shows the Duel count, Generate and Approve; the
    Rounds are saved untitled and Draft ("Course Wizard: Rounds, Lesson 1");
    Finish opens the Course Editor and forgets the Wizard;
  - the step counts read "of 7"; the 360-pixel test covers step 7.
- Beta: the expiry moves to 8 November (the revision is committed on
  9 October); `beta_lifecycle_test.dart` shifts its dates by one day.
- First complete suite (8–9 October, 23:34–00:07): 3,961 passed, 1 skipped,
  **2 failed**: `exercise_responsive_224_test.dart` at 320 and 375 logical
  pixels tapped Review generation plan without scrolling, and the new Round
  titles switch had moved it below the fold. The app is right (the button
  scrolls into view); the test now scrolls the Round Wizard's list to the
  button first (`scrollUntilVisible`). The file passes alone (4 tests).
- Second complete suite (9 October, 00:10–00:43): **3,963 passed, 1 skipped**
  (POSIX only), exit code 0.

## Revision 3 (2.0.67+267003), 9 October 2026

- `dart format` on the changed Dart files only; `flutter analyze --no-pub`:
  **No issues found.**
- `test/picture_aids_267_test.dart` (new): **7 passed**:
  - spelling tiles are letters, an accent kept with its letter;
  - Prefer picture exercises makes every second focus exercise a picture
    exercise;
  - Review slots stay Reviews when the earlier modules have no pictures;
  - the five new picture presets (What is in the picture, Spell the word in
    the picture, Name what you see, Type what you see, Listen and pick the
    image) are planned and built as their forms build them; Spell the word
    spells the word without its article and never a word over 12 letters;
  - the Round Wizard's Prefer picture exercises switch is on with pictured
    words and greyed without;
  - Suggest pictures fills the empty rows of a reopened module, never a
    chosen picture, and is offered only in a Course to or from English.
- `test/course_wizard_267_test.dart`: **22 passed**, updated for the
  simpler Wizard: step 2 Flag or cover image, step 3 About the Course
  (description and authors, the rest under Advanced), Course options with
  only Advanced, Lessons' icons and sections under Advanced, Tell me more,
  the step bar scrolled to the step shown, the GuideBook step's Fill with an
  example opening the sample module on the module page, the module note
  above the modules (`course-wizard-module-explanation`), "Source language"
  kept (owner).
- After the owner's last changes (the Rounds note above Make Rounds, the
  Round Wizard titled Generate Rounds, a paused Wizard Course's row opening
  the Wizard; the paused-line test now opens the Wizard from the row, saves
  for now, and reaches the Course Editor's paused line through Edit):
  `course_wizard_267_test.dart`, `qql_231_course_editor_ui_test.dart`,
  `guidebook_sentence_generator_test.dart`,
  `round_wizard_modules_266_test.dart`, `picture_aids_267_test.dart` and
  `exercise_responsive_224_test.dart`: **57 passed**.
- Then the Round types, the Listen Round switch, Turn on audio, Round
  titles off from the Course Wizard and the Preview audio fix:
  - `picture_aids_267_test.dart`: the default types for 1, 2, 3 and 6
    Rounds, with and without the Listen Round, in the plan and the drafts;
  - `audio_settings_runtime_228_04_test.dart`: the Preview keeps the audio
    silent behind Before you start (fails without the fix: Expected 0,
    Actual 1), and Turn on audio switches Audio Exercises on (not
    Text-to-speech in a recorded-MP3 Course) and plays the Round;
  - `course_wizard_267_test.dart`: from step 7 the Round Wizard starts with
    Round titles and Listen Round off;
  - the Round Wizard, GuideBook generator, Story Wizard, Before you start,
    Round type, Timed and audio test files (16 files): **144 passed**.
- Then the red exercises (owner: "I don't know why some are red, in the
  Wizard"): a temporary probe (deleted) audited 10 Round Wizard plans of
  the Course Wizard's sample: every red mark was `ROUND_DUPLICATE_CONTENT`
  (180 Warnings: Pick the missing word, Word order, Build the translation,
  two Matches); after the fresh-content choice and the Match key, 0.
  `picture_aids_267_test.dart` (10 passed): nothing asked twice for three
  seeds with and without pictures; an identical Match copy is still one
  duplicate; Audit in the exercise ⋮ menu opens Exercise Audit with that
  finding. `course_wizard_267_test.dart`: Finish shows the congratulations
  popup (red or clean line, Edit mode, Publish) before the Course Editor.
  Audit and bundled-Course tests (16 files): **381 passed**; Round Wizard
  related files (11): **96 passed**.
- Focused batch before the GuideBook explanation split (the Wizard, the
  Round Wizard, the GuideBook editor, picture matching, reset, Inventory,
  New Course, Use GuideBook, narrow windows): **248 passed**; after the
  split, `course_wizard_267_test.dart` again 22 passed.
- Focused runs found two Round Wizard regressions, fixed before the
  complete suite: `round_wizard_modules_266_test.dart` lost its "Review:"
  line because a picture preset took a Review slot (`reviewSafe`: Review
  slots keep the text presets); the sentence generator tests could not
  reach Review generation plan and the total (the button is now pinned in
  the bottom bar while configuring, the total stands above the switches;
  Revision 2's scroll in `exercise_responsive_224_test.dart` is no longer
  needed and is removed).
- Beta: the expiry stays 8 November (committed on 9 October).
- First complete suite (9 October): 3,974 passed, 1 skipped, **1 failed**:
  `reset_unreadable_course_266_test.dart`, "a reset button opens its
  explanation", found no `admin-reset-continue`. The test waited a fixed
  0.6 s of real time for the reset preview, which reads the stored
  Courses; under the suite's load it took longer. The file passed 3 times
  out of 3 alone. The test now waits for the dialog
  (`pumpUntilFileIoState`), as the other file I/O tests do; no app change.
- Second complete suite (9 October): **3,975 passed, 1 skipped (POSIX only)**, exit code 0.

## Revision 4 (2.0.67+267004), 9 October 2026

- `dart format` on the changed Dart files only; `flutter analyze --no-pub`:
  **No issues found.**
- `test/check_and_publish_267_test.dart` (new, 2 passed): a clean Course
  (one Lesson of the Wizard's sample, its approved GuideBook, six Round
  Wizard Rounds) is published whole: the Course, the Lesson, the GuideBook,
  every Round and every item, the Provisional Draft markers cleared, no
  Draft left in the check; a Before you start card with an empty note
  (ROUND_INTRO_EMPTY, an Error) stays Draft and is the one line listed
  ("Lesson 1 · … · item 1: …"), while its Round and the rest are published.
- `test/course_wizard_267_test.dart` (22 passed): every step reads "of 8";
  the Rounds step's button is Next; step 8 shows the Lesson card, no Fill
  with an example, "Finish without publishing"; Publish saves once
  ("Course Wizard: Check and publish"), the stored Course, its Lesson and
  Rounds are Published, the button becomes Finish; the Finish message says
  learners can study the Course; a pause of a later build reads as step 8.
- `exercise_creation_wizard_test.dart` reads the new plan line; Inventory
  reads "step 3 of 8".
- Focused batch (the Wizard, publish, Inventory, Exercise Wizard, version
  pins, Beta, Help, reset, the GuideBook generator): **112 passed**.
- Complete suite (9 October): **3,977 passed, 1 skipped (POSIX only)**, exit code 0.

## Revision 5 (2.0.67+267005), 9 October 2026

- `dart format` on the changed Dart files only; `flutter analyze --no-pub`:
  **No issues found.**
- `test/guidebook_size_advice_267_test.dart` (new, 5 passed): the Lesson
  hint for 0, 1, 2, 3–6 and 7 modules, an empty module not counted; the
  module hint (4 words and 1 Sentence; 5/2, 8/3, 12/5 none; 14 words or 13
  Sentences to split; an untitled module; the count line); the Audit's
  `GUIDEBOOK_MODULE_SIZE` and `GUIDEBOOK_MODULE_COUNT` (Info, the module's
  location, "For the Round Wizard: …"), none with Use GuideBook off or for
  four modules of 8 words and 3 Sentences; the GuideBook page shows the
  Lesson hint and only the small module's hint; the module page counts as
  the author writes (5 → 4 words, the hint appears).
- `test/course_wizard_267_test.dart`: the GuideBook step shows
  `course-wizard-guidebook-advice` and the Round Wizard's plan
  `generator-size-advice` for the sample's single module.
- The Audit registry counts: `audit_code_registry_226_02_test.dart` 17 Info
  (130 rules); `audit_branch_ownership_226_02_revision4_test.dart` adds the
  two Info codes to a Lesson with one small module.
- Focused batch (Wizard, size advice, Audit and registry, bundled Courses,
  Laboratory, English from Italian, GuideBook modules and aids, Round
  Wizard, Help, publish): 511 passed and the 2 registry tests above, fixed
  and rerun (27 passed); version pins and Beta (54 passed).
- Complete suite (9 October): **3,982 passed, 1 skipped (POSIX only)**, exit code 0.
