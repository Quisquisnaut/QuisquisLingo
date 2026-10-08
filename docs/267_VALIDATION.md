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
