# Build 267 change summary

Plan: `docs/267_COURSE_WIZARD_PLAN.md`. Evidence: `docs/267_VALIDATION.md`.
Handoff: `docs/267_HANDOFF.md`.

## Revision 0 (2.0.67+267000): the Course Wizard's frame

The plan's §2–§4 and §8 (owner decisions of 6 October 2026; started on the
owner's go of 8 October 2026).

### What changed for authors

- **New Course** opens the Course Wizard's first screen, **Basics**: the
  title, the source and target languages and the language variant, with an
  explanation of the two ways on.
  - **Continue with the Course Wizard** saves the Course at once: a Draft
    with no Lessons, the active profile as Original Course Creator,
    Maintainer and Author, All rights reserved and derivative works
    forbidden until changed.
  - **Create it myself** opens New Course's form, unchanged, with the title,
    languages and variant already filled in, then the Course Editor as
    before.
  - **Cancel** creates nothing.
- **The steps** of this revision: Basics, About the Course, Credits and
  rights, Course options, Lessons. A step bar shows them, ticks the done
  ones and goes back to any step reached; **Back** and **Next** move one
  step. On the last step **Finish** saves, ends the Wizard and opens the
  Course Editor. The GuideBook, Rounds and Check and publish steps come in
  Revisions 1–3.
  - About the Course: description, starting and target level, cover (the
    same field as Course Info), flag, study hours, minimum age, keywords.
  - Credits and rights: credits with their roles, license (with a line
    saying whether others may Fork), custom license and derivative works,
    Rights Holders, Buy a Coffee, publisher website and email.
  - Course options: Lesson label and numbering and Round label and numbering
    (each with what learners see, as "Learners see: Lesson 1: Coffee and
    pastries"), Word Lookup, Create Duels, Picture answers (size, shape, per
    row), Default Timed limits (preset chips). Use GuideBook is not offered:
    the Wizard keeps it on and says why.
  - Lessons: one card per Lesson with its title (required), icon (Numbers,
    the preinstalled icons or a QQL picture of the image library) and
    section; Add a Lesson, move up and down, remove (naming what a Lesson
    with a GuideBook or Rounds takes with it).
- **On every screen:** the explanation panel, a **Can wait** label with a
  tooltip naming where each field can be changed later, examples in the
  helpers, tooltips on the headings, **Fill with an example** (a sample
  Course, "Italian at the bar") and **Clear all** (this step only), asking
  first when the step holds something.
- **Saving:** every save is an ordinary confirmed Course save (version + 1,
  a backup, Version History), its version notes naming the step. **Save for
  now** saves and closes the Wizard; **Continue by hand** saves, ends it and
  opens the Course Editor; leaving with an unsaved change asks first.
- **Resuming:** Course Studio's row says where the Wizard stopped ("Course
  Wizard paused: step 3 of 5 (Credits and rights)") and **Continue Course
  Wizard** starts the Course's ⋮ menu; the Course Editor's page shows the
  same line with **Continue**. The Wizard re-reads the stored Course, so
  changes made by hand are kept.
- **Lesson Options:** turning **Use GuideBook** off asks first and explains
  why the GuideBook is recommended; the GuideBooks already written are kept.
- **Help EN/IT/ES:** Editor Help "How does the Course Wizard work?" (87
  questions), Course Studio's "Create a new course", the Lesson Options
  answer.

### Code

- `lib/services/course_wizard.dart` (new, pure Dart): `CourseWizardStep`,
  `CourseWizardPause`, `CourseWizardOutcome` (`CourseWizardCreateManually`,
  `CourseWizardOpenEditor`, `CourseWizardPaused`), the step values
  `CourseWizardBasics`, `CourseWizardAbout`, `CourseWizardCredits`,
  `CourseWizardOptions`, `CourseWizardLessonDraft` / `CourseWizardLessons`
  with `applyTo`, problems and "what goes" lines, `CourseWizardSample`.
- `lib/services/course_wizard_memory.dart` (new): the device key
  `qql_course_wizard_<URI-encoded Course ID>`.
- `lib/screens/course_wizard_screen.dart` (new): the Wizard.
- `lib/services/course_library_operations.dart`: `newWizardCourse` (New
  Course and the Wizard share one Course builder), `pausedWizards`,
  `CourseManagerAction.continueCourseWizard`, `wizardMemory`, Delete
  forgets the record.
- `lib/services/course_authoring_session.dart`: the new-Course flag clears
  after the first confirmation, so one session can save a new Course at
  every step (a second confirmation used to throw).
- `lib/screens/course_projects_screen.dart`: New Course through the Wizard,
  `_createCourse(prefill:)`, Continue Course Wizard, the row note, the
  Editor's Continue.
- `lib/screens/course_editor_screen.dart`: `onContinueCourseWizard`, the
  paused line, `_attemptLeave(beforePop:)`, the Use GuideBook notice.
- `lib/widgets/course_library_row.dart`: `note`.
- `lib/services/lesson_presentation_service.dart`: `prefixFor` (the label
  and number before a Lesson title, shared with the Wizard's example).
- `lib/services/app_reset_service.dart`, `inventory_service.dart`,
  `inventory_action_service.dart`, `docs/239_RESET_STORAGE_INVENTORY.md`:
  the new record.
- Help catalogs and `help_structure.dart`.

### Unchanged

The Course format (no new Course field), scoring, progression, learner
data and the Course Editor's single confirmation.

## Revision 1 (2.0.67+267001): the GuideBook step

The plan's §3 step 6.

- **Step 6, GuideBook**, after Lessons (Next from Lessons now saves and goes
  on; Finish moved to step 6). A chip per Lesson chooses the Lesson, ticked
  once its GuideBook is done. The Lesson's modules are listed with their
  counts and opened on the Course Editor's module page (Build 266: rows with
  Target, Source and Context, pictures with the English suggestions, Paste
  list, Fill with an example, Clear all, field Help); Add a module, move up
  and down, Remove (asking first, naming the Rounds that focus on it).
- **This Lesson's GuideBook is ready** saves the GuideBook as Published,
  version notes "Course Wizard: GuideBook, Lesson N", and shows the next
  Lesson still to do. While it is being written the GuideBook is a Draft;
  changing an approved GuideBook asks for the approval again.
- **Done:** a module with at least three Words & Expressions (the Round
  Wizard's minimum) and the approval. Finish names the first Lesson not done
  and shows it.
- **Fill with an example** fills the shown Lesson with Build 266's sample
  module ("Al bar"); **Clear all** empties it; both ask first when the
  Lesson has modules and say when Rounds lose their focus module ("Lesson 2
  has 6 Rounds. Clearing its modules does not remove them, but 6 lose their
  focus module.").
- **Paused** on this step, the Wizard remembers the Lesson: "Course Wizard
  paused: step 6 of 6 (GuideBook, Lesson 2)", and Continue opens it.
- **Unfinished rows** (a Target without a Source, or the reverse) never reach
  the Wizard: the module page refuses them, or offers to discard them,
  before it returns the module.
- Code: `CourseWizardStep.guidebook`, `CourseWizardGuidebook`,
  `CourseWizardSample.guidebook`, `CourseWizardPause.describe`; the screen's
  GuideBook fields; Course Studio and the Course Editor name the Lesson.
- Help EN/IT/ES: the Course Wizard answer.

## Revision 2 (2.0.67+267002): the Rounds step

The plan's §3 step 7 and §6, without the five further picture presets and
Prefer picture exercises (they wait for the owner's answer).

- **Step 7, Rounds**, after GuideBook (Next from GuideBook now saves and goes
  on; Finish moved to step 7). A chip per Lesson, ticked when it has Rounds;
  the Lesson's Rounds as learners see them ("Round 2 · Practice"), its
  exercises and, with Create Duels on, its Duel questions.
- **Make Rounds** opens the Round Wizard on the Lesson with its recommended
  settings; its plan comes first; the Rounds it makes are Drafts, added to
  the Lesson and saved ("Course Wizard: Rounds, Lesson N"); then the next
  Lesson without Rounds is shown. Fill with an example opens the Round
  Wizard too; Clear all removes the Lesson's Rounds, asking first. Finish
  needs Rounds in every Lesson.
- **The Round Wizard**, for the Wizard and the Rounds page alike:
  - **Round titles**, on by default: "Practice: Al bar"; off, the Rounds
    have no title and learners see the Round type and number.
  - **The Duel count**, with Create Duels on: "27 Duel questions (25
    needed) · 3 more need audio", counted by the Duel's own rule on the
    Rounds the plan makes plus the Lesson's own; below 25 it says to raise
    Rounds per module or Exercises per Round.
- Code: `CourseWizardStep.rounds`, `CourseWizardRounds`, the screen's Rounds
  fields and shared Lesson chips; `GuidebookRoundGenerator.createDrafts(
  roundTitles:)`; the Round Wizard screen's switch and Duel line.
- Help EN/IT/ES: the Course Wizard and Round Wizard answers; the Round
  Wizard's Help dialog.
- Beta expiry 8 November 2026 (release 9 October).
