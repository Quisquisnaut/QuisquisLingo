# Build 272 change summary

Build 272 is the modularization build (plan
`docs/272_MODULARIZATION_PLAN.md`, the read-only audit of 10 October 2026).
Owner rule: no file is split unless the responsibility first gets an owner
of its own that can be tested without the screen. One owner per revision.
**Nothing an author or a learner sees changes**: every revision first
writes tests on the code as it is, and they must still pass afterwards.

## Revision 0 (2.0.72+272000): the credits and licence owner

### Before

Three screens let an author enter who made a Course and what others may do
with it: the Course Info Editor, New Course's form and the Course Wizard.
Each had its own copy of the same rules:

- which roles a credit gets (three copies);
- how stored roles are shown again as chips and a text field (two copies);
- which entry of the licence list shows a stored licence (two copies);
- which licence and which derivative-works policy are stored for a choice
  (three copies);
- which Rights Holder rows are stored (three copies).

The text "Other / Custom license" was written in nine places and compared
letter by letter.

### Now

- `CourseCredits` (`lib/services/course_credits.dart`, pure Dart, no screen
  and no storage) is the one owner:
  - `rolesOf(standard, custom)`: the standard roles in their standard
    order, then the author's own roles from the text field (separated by
    commas, each once, as typed), `Contributor` when there is none;
  - `standardRolesIn(roles)` and `customRolesIn(roles)`: a stored credit
    split into the chips shown selected and the text of the other roles;
  - `author(...)` and `rightsHolder(...)`: one row of a form, or nothing for
    a row without a name; names are trimmed;
  - `licenseChoiceFor(license)`: the entry of the list for a stored
    licence;
  - `licenseOf(choice, customText)`: the licence stored for a choice;
  - `policyOf(choice, chosen)`: the policy stored with a choice (the
    author's own for a custom licence, the licence's otherwise);
  - `policyKeepingStored(...)`: the same for a form that edits a stored
    Course (see difference 2 below);
  - `policyAfterChoosing(choice, current)`: the policy a form shows after a
    choice.
- `CourseMetadataOptions.customLicense` is the one place of the text
  "Other / Custom license".
- The Course Info Editor, New Course's form, `CourseLibraryOperations`
  (which builds New Course's Course) and the Course Wizard call the owner.
  `CourseLibraryOperations._rolesOf` and the Wizard's own constant are gone.

### Differences between the three screens, kept as they are

(Kept in Revision 0 only. The owner decided the same day that they must
become the same: Revision 1, below.)

While reading the three copies four differences came out. This revision
keeps each of them (a test pins each one), because changing them is the
owner's decision, not a side effect of tidying:

1. **Choosing Other / Custom license.** New Course then shows "Derivative
   works: Not specified". Course Info and the Course Wizard keep the policy
   shown before the choice (for example "Forbidden" after "All rights
   reserved").
2. **A licence left unchanged.** Course Info keeps the policy the Course
   stores, also one the licence does not state: a Course that is "All
   rights reserved" and allows derivative works (as QQL Demo: Italian
   Exercise Lab, and any Fork of it) stays so. The Course Wizard always stores the licence's own
   policy. In practice a Course made by the Wizard never has such a pair, so
   nobody should have met this.
3. **The Custom license field.** Course Info fills it with the stored
   licence also when that is one of the list (so switching to Other / Custom
   license starts from "CC BY 4.0"); the Course Wizard leaves it empty then.
4. **A credit row that is added.** It starts as Contributor in Course Info
   and in New Course, and as Author in the Course Wizard.

A fifth point, the same in all three: a role of the author's own that
contains a comma is split into two roles the next time the credit is saved,
because the text field separates roles with commas.

### Tests

`test/course_credits_272_test.dart`: 5 cases for the owner and 6 cases that
drive the three screens (Course Info 3, New Course 2, Course Wizard 1). The
6 screen cases were written and run on the code **before** the change and
passed there.

Course files, scoring, progression and learner data are unchanged. No new
key or folder.

## Revision 1 (2.0.72+272001): the three screens follow the same rules

Owner decision of 12 October 2026 on the differences Revision 0 found:
"They must become the same", then "Agree on all five, own revision".

| # | The rule, now the same in Course Info, New Course and the Course Wizard | What changed |
|---|---|---|
| 1 | Choosing Other / Custom license keeps the derivative-works policy shown before the choice | New Course: it showed "Not specified" |
| 2 | A licence left unchanged keeps the policy the Course stores | Course Wizard: it stored the licence's own policy on every save of its step |
| 3 | The Custom license field starts empty for a licence of the list, and with the stored text when the licence is the author's own | Course Info: it started from the stored licence, for example "CC BY 4.0" |
| 4 | The creator's own credit row is Author; a person added afterwards starts as Contributor | Course Wizard: every added person was an Author |
| 5 | Other / Custom license without a text says "Type the custom license, or choose a license from the list." | Course Info and New Course: the button did nothing, without a word |

### What an author may notice

- **New Course**: after "CC BY-SA 4.0", choosing Other / Custom license
  shows "Allowed" (before: "Not specified"). Starting from the default "All
  rights reserved" it shows "Forbidden". The author can still choose any of
  the three.
- **Course Wizard**: a person added with **Add a person** is credited as
  Contributor unless another role is chosen under Advanced. The first row,
  which the Wizard fills with the creator's name, is still Author.
- **Course Wizard**: saving the About step no longer changes the policy of
  a Course whose licence was not touched.
- **Course Info**: switching to Other / Custom license starts from an empty
  field. A licence the author wrote earlier is still shown there.
- **Course Info and New Course**: with Other / Custom license and no text,
  Apply and Continue to Editor say what is missing.

Stored Courses are not converted: credits and policies already stored stay
as they are. No screen layout changes.

### How

- `CourseCredits` gains `customLicenseTextFor(license)`,
  `customLicenseMissing` (the one text of the refusal) and `creatorRole`.
- New Course's licence list calls `policyAfterChoosing`.
- The Course Wizard stores `policyKeepingStored` against its working copy
  (`_derivativeValue`); the line under the licence list ("Derivative works
  are allowed…") reads the same value. `_CreditRow` starts as
  `CourseCredits.defaultRole`; Add a person gives the creator's row
  `creatorRole`.
- Course Info's Custom license field starts from `customLicenseTextFor`;
  its Apply and New Course's Continue to Editor show
  `customLicenseMissing`.

### Tests

`test/course_credits_272_test.dart`, 12 cases: the screen cases that pinned
a difference in Revision 0 now pin the one rule (points 1 to 5), and one
more owner case covers the new owner members.

Course files, scoring, progression and learner data are unchanged. No new
key or folder.

## Revision 2 (2.0.72+272002): the Course Info Editor's form and its own file

Nothing an author sees changes.

### Before

The Course Info Editor was one method of the Course Editor screen, about
1,530 lines long. It held about forty variables at once: the text fields,
the rows of Authors, Rights Holders and Media credits, the licence, the
cover and its credit, the switches. The same method drew the dialog, kept
the rule for the credit of a cover, checked the fields on Apply and
assembled the change for the Course. None of that could be tested without
opening the Course Editor and the dialog.

### Now

- **`CourseInfoForm`** (`lib/controllers/course_info_form.dart`) is the
  owner of the form: what the fields show for a Course (with one blank row
  where a list is empty), adding and removing rows, the licence choice, the
  cover with the credit QQL knows for it, the checks of Apply and the change
  it gives. It draws nothing and stores nothing.
- **`CourseInfoEditor`** (`lib/screens/course_info_editor.dart`) is the
  dialog: it draws the form, asks about a name another Course has, and
  hands back the change. The Course Editor screen keeps what belongs to it:
  it reads what the dialog needs, opens it, and stages the change in its
  working copy.
- `CourseCreditRow` and `CourseRightsHolderRow`
  (`lib/controllers/course_credit_rows.dart`) are the credit rows any Course
  form can use.
- `CourseInfoUpdateService.keepsLearningLanguage` is the one rule that says
  whether a learning language may take a tag (it must not move the
  language's XP and streak). The dialog and the service had a copy each.

### How the dialog was moved

Its 1,000 lines of layout were not retyped. A script took the text as it
was and changed only the names of what it reads (for example `names[i]`
became `_form.authors[i].name`). Afterwards every text and key of the old
dialog was compared with the new files: all 186 are there, as often as
before. The differences are the renamed variables inside five messages, and
"Contributor", which now comes from `CourseCredits.defaultRole`.

### A mistake caught before the commit

An independent review compared the old dialog with the new files line by
line. It found one real mistake, made by the renaming script: the help text
under "Learning language name for learners" would have ended with
"Leave it empty for “Instance of 'CourseInfoForm'…”" instead of
"“Italian”". Inside a text, the script had written
`$_form.defaultLearnerLanguageName` where `${_form.defaultLearnerLanguageName}`
is needed. My own comparison had listed that sentence as different and I
took it for one of the plain renamings, because the list was cut at 110
characters.

What was done about it:

- the script now puts the braces, and stops if a renamed name is left
  without them;
- the comparison prints every differing text in full;
- the characterization test now reads that help sentence (and passes on the
  code before the move as well as after);
- the review found nothing else that changes what an author sees or what is
  stored. On its remark that a Course the form cannot read would have opened
  a broken dialog, the form is now made before the dialog opens, as the old
  code did.

### Small things that changed inside

- The dialog releases its text fields when it has left the screen (its own
  State does it). Before, the Course Editor kept a list of closed dialogs
  and released them when the next one opened or the Editor closed.
- The field "Learning language name for learners" is released too. Before
  it never was.
- Two test files that read the dialog's source text now read its new file.

### Tests

- `test/course_info_form_272_test.dart`, 21 cases on the form alone: the
  values a Course opens with, rows, the eight cases of the cover's credit,
  the licence, what Apply gives and refuses with its messages, the name,
  the language tag, the release of every field.
- `test/course_info_editor_272_test.dart`, 5 cases through the Course
  Editor, written on the code before the move and passed there.

Course files, scoring, progression and learner data are unchanged. No new
key or folder.

## Revision 3 (2.0.72+272003): New Course's form and its own file

Nothing an author sees changes.

### Before

New Course's form ("Create new course", reached with Continue by hand) was
one method of the Course Studio screen, about 730 lines long, with about
twenty text fields and their rules in the same place as the layout. It could
be tested only by opening Course Studio.

### Now

- **`NewCourseForm`** (`lib/controllers/new_course_form.dart`) is the owner
  of the form: the fields with New Course's defaults (the creator as Author,
  "All rights reserved", 3 Lessons of 1 Round), what the Course Wizard's
  first screen held, the rows, the licence choice, the cover, the check of
  the numbers, and the Draft Course that Continue to Editor makes.
- **`NewCourseDialog`** (`lib/screens/new_course_dialog.dart`) is the
  dialog: it draws the form and asks about a name another Course has.
  Course Studio reads the learners of the device and opens it.
- The Course Wizard's own two row classes are replaced by the shared
  `CourseCreditRow` and `CourseRightsHolderRow` of Revision 2.

The Course Studio file goes from 3,504 to 2,772 lines.

### How the dialog was moved

As in Revision 2: the layout was taken as it was by a script that changes
only the names of what it reads, every text and key was compared before and
after, and a second reader compared the old and the new code line by line
before the suite.

### Tests

- `test/new_course_form_272_test.dart`: the form alone.
- `test/new_course_dialog_272_test.dart`: 2 cases through Course Studio,
  written on the code before the move and passed there.
- Already there and unchanged: the numbers of Lessons and Rounds, the flag,
  the cover and its deletion on Cancel, the Maintainer list, the Wizard's
  prefill, credits and licence.

Course files, scoring, progression and learner data are unchanged. No new
key or folder.

## Revision 4 (2.0.72+272004): Lesson Options

Nothing an author sees changes.

### Before

Lesson Options (under the Lessons tile of the Course Editor) are settings of
the whole Course: how Lessons and Rounds are numbered, Use GuideBook, Word
Lookup, Create Duels, the default Timed limits and the look of picture
answers. The Course Editor screen wrote each of them into the Course's data
by itself, in seven places; the Course Wizard's options step wrote the same
settings in its own way. The small rules were spread among the buttons: a
custom label belongs only to the custom numbering; two stages cannot have
the same Timed limit; the standard look of picture answers is not stored.

### Now

- **`LessonOptions`** (`lib/services/lesson_options.dart`) holds those
  rules. `LessonOptions.apply(course, …)` gives the Course with the
  settings named and leaves the others alone.
- The Course Editor's panel and the Course Wizard's options step both call
  it. A test checks that the Wizard's step still writes exactly what it
  wrote before.
- **`LessonOptionsPanel`** (`lib/widgets/lesson_options_panel.dart`) is the
  panel: it draws the working copy and hands back the Course with one
  setting changed. The Course Editor stages it as before.
- The name prompt and the Time limit menu, which other Editor pages use
  too, are in `lib/widgets/editor_dialogs.dart`.

The Course Editor file goes from 13,288 to 12,748 lines.

### What the independent review found, fixed before the commit

On the normal paths the review found the panel identical to the old code.
It found two edge cases where the first version of the panel was not:

1. **A dialog's answer could be dropped.** The panel is one item of the
   Course Editor's list, and a list lets go of an item that is far from
   what is seen. If that happened while the panel's own dialog was open
   (the custom label, the Time limit, the Use GuideBook notice), the answer
   was thrown away without a word, because the panel, not the page, was
   waiting for it. Before the move the page waited. In today's layout
   Lesson Options stands near the top of the page, so the keyboard alone
   cannot push it that far; the case would have come alive the day
   something is added above it.
2. **Two changes in the same instant.** The panel started each change from
   the Course it had drawn, so of two changes made before the screen was
   drawn again only the second was kept. Before the move each change
   started from the working copy as it was at that moment.

Both are exactly as before now: the panel's dialogs and messages open on
the Course Editor page and their answer is staged while the page is there,
and every change starts from the working copy of that moment. Two tests pin
them; both pass on the code before the move, and the first version of the
panel failed them.

### Owner decisions for the rest of the Build (12 October 2026)

1. One complete suite for every revision that creates an owner or touches a
   rule; pure file moves go two or three per suite.
2. The exercise editor leaves the Course Editor file next, as Revision 5.
3. Build 272 does the low-risk owners and the free moves. The medium-risk
   items of the plan (answer grading among them) become Build 273.
4. A Windows package after this revision, to try the changed forms by hand.

### Tests

- `test/lesson_options_272_test.dart`: the rules alone.
- `test/lesson_options_panel_272_test.dart`: 4 cases through the Course
  Editor; all pass on the code before the move.
- Already there and unchanged: the numbering menus with Cancel, Use
  GuideBook and its notice, Word Lookup, Create Duels, picture size, shape
  and number per row, the first default Timed limit.

Course files, scoring, progression and learner data are unchanged. No new
key or folder.

## Revision 5 (2.0.72+272005): the exercise editor has its own file

Nothing an author sees changes. Owner decision of 12 October 2026: the
exercise editor leaves the Course Editor file right after Lesson Options.

### What moved

`ExerciseEditorScreen`, the form in which an author fills a preset exercise
(Choose the answer, Match, Flashcard and the others), is now
`lib/screens/exercise_editor_screen.dart`. Its 3,153 lines were moved as
they were. Its logic, building the exercise from the form's values, already
had an owner since Build 252 (`ExerciseDraftBuilder`), so this is a move and
not a new owner.

| File | Before | After |
|---|---|---|
| Course Editor (`course_editor_screen.dart`) | 12,748 lines | 9,530 lines |
| Exercise editor (`exercise_editor_screen.dart`) | - | 3,186 lines |

At the start of this Build the Course Editor file had 14,839 lines.

### The five ties that had to be cut

The editor used five small private helpers of the Course Editor file, and
the Exercise Wizard used one of the editor's:

- **A new exercise of a preset, as its form starts** (also what Clear all
  returns to): now `PresetRecipes.blankFor`. A rule, with a test for every
  preset.
- **The name an author reads for a preset**: now
  `ExercisePresetRegistry.nameOrId`. A rule, with a test.
- **The chip with a preset's action word** (Choose, Type, Match…): now the
  widget `PresetActionChip`.
- Two one-line shortcuts and one shared helper object are written out at
  the one place the editor used them.

The Course Editor file still gives access to the exercise editor, so the 51
test files and the screens that open it did not change.

### How it was checked

The moved class was compared with its old text line by line: 18 lines
differ, all at the five points above. The complete suite is shared with
Revision 6 (owner decision: pure file moves go two or three per suite).

Course files, scoring, progression and learner data are unchanged. No new
key or folder.

## Revision 6 (2.0.72+272006): four more pages leave the Course Editor file

Nothing an author sees changes.

### What moved

| What | New file | Lines |
|---|---|---|
| Audio Library, with its Associate recording dialog | `lib/screens/audio_library_screen.dart` | 1,051 |
| Audit page | `lib/screens/course_audit_screen.dart` | 223 |
| Lesson preview | `lib/screens/lesson_authoring_preview_screen.dart` | 83 |
| The status rule of the Editor's lists (red, green, blue) | `lib/services/authoring_hierarchy_status.dart` | 152 |

Each was moved as it was and compared with its old text line by line: the
Audit page, the Lesson preview and the status rule are identical; the Audio
Library differs in three lines, the three calls named below.

### Two small things that got a proper place

- **The names an author reads for an exercise**: its kind name, its type
  label and the one line that identifies it in a list. They were three
  private functions used by the Editor's lists, the Audit locations and the
  Audio Library. They are `ExerciseLabels` now, with tests on every
  exercise of the bundled Courses.
- **Opening an exercise's editor** (the preset form, or the canonical
  editor when no preset represents the exercise), also from a search result
  or from a recording's "Used in N exercises": these two functions are in
  the exercise editor's file now, so the Audio Library does not need the
  Course Editor file.

### Where the Course Editor file stands

| Moment | Lines |
|---|---|
| Start of Build 272 | 14,839 |
| After Revision 2 (Course Info Editor) | 13,288 |
| After Revision 4 (Lesson Options) | 12,748 |
| After Revision 5 (exercise editor) | 9,530 |
| After Revision 6 | 7,927 |

What remains in it: the Course Editor's main page, the four hierarchy pages
(Lessons, Lesson, Rounds, Round), the Round Wizard, the Story Wizard and the
Exercise Wizard.

### Tests

`test/exercise_labels_272_test.dart`, 5 cases. Revisions 5 and 6 share one
independent review and one complete suite (owner decision for pure file
moves).

Course files, scoring, progression and learner data are unchanged. No new
key or folder.

## Revision 7 (2.0.72+272007): the Timed Round's clock

Nothing a learner sees changes.

### What it is

A Timed Round counts down from its limit. Until now the Round screen itself
kept everything about that countdown, spread over eight fields and four
pieces of code: when the time ends, two timers, the seconds shown, whether
the time ran out, whether the last answer came in time.

That is one job, and it now has one owner, `TimedRoundClock`, in a file of
its own. It can be tested without drawing a screen: a test sets the time and
lets timer time pass.

### What stayed in the Round screen

What the screen does when the countdown ends, because those are the screen's
own actions:

- when the time runs out: lock the page, close the "Review your mistakes"
  notice if it is open, save the XP of the answers given, show the Time's
  up page;
- when the Round is finished in time: claim the limit for the On Time bonus.

### How it was checked

- Seven tests of the Round screen were written first, on the screen as it
  was; they pass on that screen and on the changed one: the seconds shown
  second by second,
  the time running out when the device clock passes the deadline, and also
  after the limit of waiting when the device clock does not move, an answer
  tapped after the deadline (not taken), the last answer in time (the clock
  stops where it is), the mistakes notice closed by the time running out,
  and the Preview (nothing kept).
- Eleven tests of the clock alone.
- An independent line-by-line review before the complete suite.
- The complete suite ran twice. Its first run had one failure, in the new
  screen test file itself: one case tapped the answer of "question 1", and a
  Round shows its questions in a new order each time, so the case failed
  about one run in two. The app was right; the test was corrected and
  repeated (12 runs of 12 pass, and 4 of 4 on the screen before the change).
  The second run: 4,418 passed, 1 skipped.

The Round screen file goes from 5,826 to 5,794 lines. The gain here is not
the size: it is that the Timed rules can now be read and tested in one
place.

Course files, scoring, progression and learner data are unchanged. No new
key or folder. The Beta expiry moves to 12 November 2026 (a new release
day).

## Revision 8 (2.0.72+272008): one owner for the media reference rule

Nothing an author or a learner sees changes.

### What it is

A Course names its own pictures and recordings by their content, as
`media:` followed by a long code and the kind of file, never by a path on
the author's device. That is what lets a Course travel to another device.

The rule that says what such a name looks like was written nine times
(the media store had two):

| Where | What it checked |
|---|---|
| Course models | the cover |
| Course models | a recording of the Audio Library |
| Course models | a picture of an exercise |
| Course models | a picture taken from the shared library |
| Course models | a Story avatar |
| Media store | any Course media, and the stored file's name |
| Package service | a file inside a Course package |
| Signing tool | the media a signed package must carry |

Nine copies of one rule can drift apart: a new kind of file added in one
place and forgotten in another would make a Course that one part of the app
accepts and another refuses. Now there is one, `CourseMediaReference`, and
the nine places read it. The media store's list of the kinds of file (mp3,
png, jpg, jpeg, webp) is the owner's too.

The check that refuses a Course file naming a recording or a picture by a
path of one device moved to the same owner, with the same messages.

### How it was checked

- 28 tests written first, on the code as it was: twenty names (good ones,
  wrong kinds of file, wrong codes, paths of one device, QQL's own files)
  asked at every place that decides, and the seven refusals of a Course file
  with their exact messages. They pass unchanged afterwards.
- 25 tests on the owner, among them one that reads each pattern and
  compares it letter for letter with the text written before.
- An independent review before the complete suite.
- The complete suite ran twice. The first run was slow (83 minutes instead
  of 45, the PC was busy) and one older test failed because its wait for
  Course Studio to read the stored Courses had a limit of 10 seconds. That
  test passes alone, 4 times out of 4, and nothing of this revision is
  involved. The limit, which is only there so that a wait cannot last for
  ever, is 30 seconds now, and 1.2 GB of leftover test files were removed.
  The second run: 4,471 passed, 1 skipped.

The Course models file goes from 5,809 to 5,748 lines.

Course files, scoring, progression and learner data are unchanged. No new
key or folder.

## Revision 9 (2.0.72+272009): shared readers for a Course file

Nothing an author or a learner sees changes.

### What it is

When QQL opens a Course file it reads thousands of small values: a title
that must be there, a note that may be missing, a list of answers, a date.
For each kind of value there is a small reader that also says what is wrong
when the file is broken ("Missing or invalid lesson.title").

Those readers were private to the file they were written in, and the two
files of the Course models each had their own copies. Now there is one set,
`JsonRead`, and 167 calls use it.

This matters for what comes later: the Course models are one file of almost
6,000 lines, and its classes could not be moved to files of their own while
they all leaned on helpers private to that one file.

### Two copies were not the same

| Reader | In the Course models | In the canonical exercise |
|---|---|---|
| A list of texts that is wrong | "tags must be a list." | "evaluation.answers must be a list." (the place too) |
| A list of objects that is missing | refused | read as empty |

In this revision both rules are kept exactly, each under its own name, so
that nothing changes. You decided on 13 October that they be fixed: that is
Revision 10.

### How it was checked

- 6 tests written first, on the Laboratory's own file broken in one place
  each (a missing title, a date without its time zone, a Lesson without its
  Rounds, a list of the wrong kind, an unknown field), with the exact words
  the file is told. They pass unchanged afterwards.
- 9 tests on the readers themselves.
- The renaming was done by a script, and a second script confirmed that
  each file is the same code as before apart from the names and the layout.
- An independent review before the complete suite.

### Size

The Course models file goes from 5,748 to 5,796 lines. The readers' longer
names make the formatter wrap more lines than the removed copies took, so
this revision does not shrink it; it removes what kept it from being split.

Course files, scoring, progression and learner data are unchanged. No new
key or folder.

## Revision 10 (2.0.72+272010): one wording, one rule for a list that may be left out

Your decision of 13 October 2026 on the two differences Revision 9 found
("Fix the two things", then yes to the proposal). This revision changes
behaviour, on purpose and alone, for Course files that are wrong or unusual.
A Course that QQL wrote reads exactly as before.

### 1. A wrong list is told where it is

| Field | Before | Now |
|---|---|---|
| A content's `sourceRefs` | "sourceRefs must be a list." | "content.sourceRefs must be a list." |
| A shared picture's `tags` | "tags must be a list." | "sharedImageSource.tags must be a list." |
| A card's `actions` | "actions must be a list." | "presentation.completion.actions must be a list." |
| Earlier exercise shape: `correctItemIds`, `acceptedAnswers`, `pairs` | "pairs must be a list." | "evaluation.pairs must be a list." |

The canonical exercise already named the place; now every list does. (The
Course's `sectionNames` has a check of its own that was already complete.)

### 2. A list the file may leave out

Two kinds of list stay, because they are two different things:

- **a list the file must have** (a Lesson's Rounds, a Round's content, an
  exercise's prompt, a GuideBook's modules): refused when missing, as
  before;
- **a list the file may leave out** (an exercise's items, targets, layout,
  the accepted answers, a module's sentences and words): QQL does not write
  it when it is empty.

What changes is that the second kind now has **one** rule, where seven
places each had a check of their own:

| The file has | GuideBook module `sentences`, `words` | Earlier exercise shape `items`, `layout` | The other four |
|---|---|---|---|
| no such list | empty | empty | empty |
| the list written as `null` | **was refused, now empty** | empty | empty |
| a text, a number or an object instead of a list | refused | **was read as empty, now refused** | refused |
| a list holding something that is not an object | refused | refused | refused |

So one case is more lenient (a `null` in a GuideBook module) and one is
stricter (a wrong value in the earlier exercise shape, which only the
converter from v11 reads). QQL itself never writes either.

### How it was checked

- What the code said before was recorded by a probe on ten cases, then the
  tests were written for the new rules: 19 cases in
  `test/json_read_272_test.dart`.
- An independent review of the change against the two decisions, before
  the complete suite. It confirmed the table above cell by cell, and found
  one thing I had not seen: the shared reader gave back, for a list left
  out, an empty list "of nothing" instead of an empty list of exercise
  items (or targets, or layout pieces). Looking in such a list with a
  fallback would have stopped with an error. It is fixed and has a test.

### What this revision does not cover

Seven lists of the Course's own root are read by checks written at their
place, not by the shared readers: Section names, keywords, authors, Rights
Holders, custom Lesson icons, the Audio Library and the default Timed
limits. They have wordings of their own, and they do not all follow the rule
above: five of them refuse a list written as `null`, and an Audio Library
that is not a list is read as empty. They were not among the differences
you decided on; I am listing them so that you can decide.

Course files written by QQL, scoring, progression and learner data are
unchanged. No new key or folder.

## Revision 11 (2.0.72+272011): the Merge page's choices

Nothing an author sees changes.

### What it is

On the Course Merge page an author decides, for two versions of a Course,
where each Lesson comes from and, for each setting the two differ on (title,
Create Duels, Use GuideBooks, Lesson numbering, Section names, Buy a Coffee,
description, flag, start and target level), which Course gives it.

Those rules lived inside the page: twelve fields and three functions among
the buttons and the layout. They now have an owner, `CourseMergeSelection`,
that can be tested without drawing the page:

- a Lesson comes from the left Course, from the right one or from neither,
  never from both;
- Select all takes a side wherever that Course has a Lesson;
- there is something to merge once one Lesson is chosen;
- a side is offered only for the settings that differ, always in the same
  order;
- every setting starts on the left Course.

The page keeps what is a page's: loading the second Course, the dialogs,
the messages, the layout.

### How it was checked

- 10 tests written first, on the page as it was: which settings are
  offered, what is handed to the merge with every setting Left, with some
  Right and with all Right, the rows and the ticks, Select all with Courses
  of different length. They pass unchanged afterwards (six runs of six).
- 5 tests on the owner.
- An independent review before the complete suite.

The Course Studio file goes from 2,764 to 2,622 lines.

Course files, scoring, progression and learner data are unchanged. No new
key or folder.

## Revision 12 (2.0.72+272012): seven widgets leave two files

Nothing an author sees changes. Two pure moves.

### Out of the Course Studio file

| What | New file | Lines |
|---|---|---|
| Course Import page | `lib/screens/course_import_screen.dart` | 73 |
| Course Export page | `lib/screens/course_export_screen.dart` | 83 |
| Course Merge page | `lib/screens/course_merge_screen.dart` | 434 |
| Three small helpers the pages share with Course Studio | `lib/widgets/course_package_notes.dart` | 28 |

### Out of the canonical editor's file

| What | New file | Lines |
|---|---|---|
| The four rows of the canonical editor (an element, an item, a target, a piece of the layout) and their one-line menu text | `lib/widgets/primitive_editor_rows.dart` | 668 |

Each moved piece was compared with its old text line by line: identical
apart from the names that had to become public (three helpers, four
widgets, one small function).

### Where the large files stand

| File | Start of Build 272 | Now |
|---|---|---|
| Course Editor | 14,839 | 7,927 |
| Course models | 5,809 | 5,787 |
| Round screen | 5,826 | 5,794 |
| Course Wizard | 3,726 | 3,673 |
| Course Studio | 3,494 | 2,041 |
| Canonical editor | 2,479 | 1,818 |

### Tests

`test/free_moves_272_r12_test.dart`, 4 cases. One independent review and
one complete suite for the two moves (your decision for pure file moves).

Course files, scoring, progression and learner data are unchanged. No new
key or folder.

## Revision 13 (2.0.72+272013): a Course import shows what its check found

A change of behaviour, asked by you on 13 October 2026. It is not part of
the modularization; it has a revision of its own.

### What changes for the user

Every Course import now shows a pop-up before anything is stored, and the
pop-up stays on screen until you answer.

- **The file has anomalies**: the pop-up lists them. **Import anyway**
  imports the file exactly as before this revision; **Cancel** stores
  nothing.
- **The file has none**: the pop-up says that QuisquisLingo checked the
  file and found no anomalies, and tells you about the Course. **Import**
  or **Cancel** (you confirmed Cancel: the facts may show it is the wrong
  file).

A file that was refused before is still refused, with its message. Nothing
that was accepted before is refused now.

### What counts as an anomaly at import

| Anomaly | What the pop-up says |
|---|---|
| No author | The file names no author. |
| No license | The file states no license: QuisquisLingo reads it as "All rights reserved". |
| A license, no Rights Holder (not for CC0 1.0) | A license is stated (its name) but no Rights Holder is named. |
| An audio mode QQL does not know | It is read as On-Device TTS. |
| The Audio Library is not written as a list | The Course will be imported without recordings. |
| Entries of the Audio Library that are not recordings | They will be skipped (with their number). |
| Set to play recordings first (Hybrid), and has none | Said, with the reminder below. |
| No Lessons, Lessons without Rounds | "Lessons without Rounds: 2." |
| Other Audit warnings | Their number; the Course's Audit lists them after the import. |
| Exercises this version cannot play | Their number. |

### Two things that are not in the list, and why

The independent review found that two lines I had promised you could never
appear: **a Round with nothing in it** and **a Course set to play only its
recordings that has none**. The Course Audit counts both as errors, and a
file with Audit errors is refused before the pop-up, as it was before this
revision. So they are not in the pop-up; the refusal names them.

### What the pop-up tells about a Course without anomalies

Your list: authors (with their roles), Maintainer, Team, last edited,
license (with its Rights Holders), number of Lessons, Rounds and exercises.

- **Maintainer**: a Course file holds only the Maintainer's ID. When that
  person is a learner of this device, their name here is shown. When not,
  the name the file records for them as the Course's creator or last
  editor, followed by "(not a learner on this device)"; when the file
  records none, "Not a learner on this device". A Publisher Course shows
  its Publisher instead, and no Team line.
- **Team**: its name when the Team is on this device, "A Team that is not
  on this device" when it is not, "None" when no Team is assigned.
- **Last edited**: the date and time as Course Info writes them, and by
  whom when the file says it.
- **Exercises** are counted as the Course Editor counts them (cards and
  Story lines included).

### The Course's own labels

When a Course gives its Lessons or Rounds another label in Lesson Options,
both pop-ups use it: "Units: 4 · Rounds: 12 · Exercises: 96". A label the
author wrote ("Unità") is shown exactly as written; QuisquisLingo cannot
know its plural, so the pop-ups write the label and then the number
("Unità: 4", "Unità without Tappa: 2.") and never add an "s" to it.

### Reminders (never anomalies)

- A Course without recordings that the device's voice reads: your wording,
  QuisquisLingo will use the device's voice; please check that
  Text-to-speech is set up correctly for the language studied (named).
- Recordings in a Course whose audio mode is On-Device TTS: they are not
  played. A file that has recordings but leaves its audio mode out, or
  writes one QuisquisLingo does not know, loses them this way, so the
  pop-up says it.
- A ZIP with its files inside a folder of its name: accepted. The notice
  at the bottom of the page is still shown; the pop-up covers it, so it
  repeats it.

### Course Merge

The same pop-up, once, when the second Course is loaded (you decided: both
pop-ups, as at import). Its buttons say **Continue anyway** / **Continue**
and **Cancel**; Cancel leaves the Merge as it was.

In a Merge the pop-up lists:

- the file's **author and license** anomalies, as at import (you decided:
  they may be relevant when merging);
- what concerns its **Lessons**: Lessons without Rounds, the Audit's
  warnings, exercises that cannot be played;
- the Audit's **errors**, because a Merge does not refuse the file for
  them when it is loaded ("The Course Audit has 2 errors in this Course: a
  Merge whose result has Audit errors is refused.").

The facts are shown as at import. The audio lines and the device-voice
reminder are left out: a Merge keeps the recordings and the audio mode of
the Course already stored.

### See the Audit

You asked whether the user can open the Audit of a file. Before, no: a
refused file showed "Course import blocked" with the number of errors and
the first eight of them, and nothing else. Now **See the Audit** is in
that dialog and in both pop-ups. It opens the Course Audit of the file:
every error, warning and note, the page's filter and sorting, Copy report
and Export report. Nothing is stored by opening it, and when you close it
the dialog is still there, waiting for its answer.

### What the two independent reviews found, all corrected

- A damaged Teams list on the device could have stopped an import that
  worked before. It no longer can; the pop-up then says the Team is not
  known.
- Any failure of the check itself now goes to the Diagnostic Log, and the
  import or the Merge goes on without the pop-up.
- A double click on Quick Import would have opened two pop-ups. One import
  runs at a time now.
- Very long or odd texts in a file (a license of a megabyte, an audio mode
  that is a list) are shortened to one line before they are shown, never
  in the middle of an emoji.
- An empty Lesson was said twice, in words and among the Audit warnings.
- The pop-up said the Course "can be imported" before later checks, which
  can still refuse it, had run.
- In a Merge the pop-up spoke of "the import".
- "License" is written as in the rest of the app.

### Decided with you for the next revision

A license without a Rights Holder is a weakness of the Course itself, so
QuisquisLingo will fix it at the source: New Course and the Course Wizard
name the author of the form as Rights Holder (not the app's creator name);
a Course Audit warning, which never blocks; Export as Publisher Course
refuses without one; CC0 1.0 is exempt; the Courses already stored are
audited one by one, never changed automatically. Until then a Course made
with the defaults shows the Rights Holder anomaly at import.

### Three things I decided, for you to confirm or change

1. **The pop-up also comes before a Publisher Course's confirmation.** The
   same rule for every Course file.
2. **The Audit warnings are counted in the pop-up, not written out.**
   Their own lines say "Lesson 2" and "Round 1" whatever labels the Course
   uses, which would break your rule about labels inside the pop-up. See
   the Audit shows them in full.
3. **In a Merge, no line about audio** (see above).

### About the complete suite

It passed (4,605 passed, 1 skipped, 0 failed) on the revision as it stood
before your last two decisions: author and license in a Merge, and See the
Audit. As you said, I did not run it again for those two. They were
checked with the analyzer, the two new test files run six times, and the
related test files. The next revision's complete suite will cover them.

### Not tested here

The import of a Publisher Course with the pop-up on (it needs a signed
file driven through the screen). The pop-up is called before the Publisher
branch, on the same line of code as for every other import.

### Tests

`test/course_import_check_272_test.dart` (the anomalies, each line checked
against what the reader and the Course Audit really do with the file; the
labels; the facts; the Merge; the check through the import's review) and
`test/course_import_check_dialog_272_test.dart` (the pop-ups in Course
Studio and on the Merge page: each stays, Cancel stores nothing and lets
the read file go, Import anyway stores the same Course as an import
without the pop-up, one import at a time, the pop-up comes before the
question about a Course ID already in use, a file with Audit errors is
refused as before, See the Audit opens the Audit and comes back to a
dialog that still waits), and one case in
`course_manager_workflow_249_test` (Course Studio gives the Merge page its
check).

Course files, scoring, progression and learner data are unchanged. No new
key or folder.
