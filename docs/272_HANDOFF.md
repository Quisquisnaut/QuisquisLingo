# Build 272 handoff

Started 12 October 2026 on the branch `build-272` in the main checkout
`C:\QQL\QuisquisLingo` (from `main` at `4963cb42`, pushed). Plan:
`docs/272_MODULARIZATION_PLAN.md` (the read-only audit of 10 October 2026;
its line numbers are those of Build 270 Revision 10). Git rule: one branch
per Build; after each revision's commit push the branch
(`git push -u origin build-272`, standing permission, a backup, no pull
request); merge into `main` and push `main` only on the owner's go.
Summary: `docs/272_CHANGE_SUMMARY.md`; evidence: `docs/272_VALIDATION.md`.

Never stage `devtools_options.yaml`, `tools/cloud_setup.sh`.

## Rules of this Build

- Owner rule (10 October 2026): no physical file split unless an extracted,
  testable owner comes first. Never a mechanical cut of a screen that keeps
  sharing one state class.
- One owner per revision. Characterize the behaviour with tests that pass
  **before** the change, then move it. No behaviour change: a difference
  found between copies is kept and reported, never unified silently.
- Each revision: version bump in every pin, CHANGELOG, summary, validation,
  this handoff, AGENTS.md release boundary; analyzer; the complete suite
  once; one commit; push the branch.

## Plan

| Revision | Scope |
|---|---|
| 0 | Course credits and licence owner (`CourseCredits`): roles, licence choice, derivative policy, Rights Holder rows; Course Info, New Course and the Course Wizard use it (done) |
| 1 | The five credits and licence rules made the same in the three screens (owner decision of 12 October 2026, below): a behaviour change, on purpose in a revision of its own |
| 2 | Course Info form owner; the Course Info Editor dialog becomes a widget of its own |
| 3 | New Course form owner; the New Course dialog becomes a widget of its own |
| 4 | Lesson Options transforms and panel |
| 5 | `TimedRoundClock` |
| 6 | `AnswerGrader` |
| 7 | Media-reference owner |
| 8 | Shared JSON readers for the models |
| 9 | Merge selection owner; Merge, Import and Export screens leave Course Studio |
| later | Free moves; then the plan's medium-risk items 8–14 |

Owner decision of 12 October 2026 ("They must become the same", then "Agree
on all five, own revision"), Revision 1:

1. After choosing Other / Custom license every screen keeps the policy
   shown before (New Course changes: `CourseCredits.policyAfterChoosing`).
2. A licence left unchanged keeps the policy the Course stores (the Course
   Wizard changes: `policyKeepingStored` against the working copy).
3. The Custom license field is empty for a licence of the list, the stored
   text for the author's own (Course Info changes:
   `CourseCredits.customLicenseTextFor`).
4. The creator's own credit row is Author; every person added afterwards
   starts as Contributor (the Course Wizard changes).
5. Other / Custom license without a text says "Type the custom license, or
   choose a license from the list." in all three
   (`CourseCredits.customLicenseMissing`; Course Info and New Course were
   silent).

Asked of the owner and not answered yet (12 October, 18:12): whether to run
the complete suite once every two or three revisions instead of every
revision while the PC is short of memory (85 minutes a run). Until an
answer: one complete suite per revision.

## Revision 0 (2.0.72+272000), the credits and licence owner

State: done (12 October 2026). Analyzer clean; new tests 11 passed; focused
files 170 passed; complete suite 4,338 passed, 1 skipped (17:13 to 18:39,
85 minutes: the PC was short of memory). Committed on `build-272` and the
branch pushed (hash in `git log`).

What was done (details in `docs/272_CHANGE_SUMMARY.md`):

- `lib/services/course_credits.dart`, pure Dart, `CourseCredits`:
  `rolesOf`, `standardRolesIn`, `customRolesIn`, `author`, `rightsHolder`,
  `licenseChoiceFor`, `isCustomLicenseChoice`, `licenseOf`, `policyOf`,
  `policyKeepingStored`, `policyAfterChoosing`, `defaultRole`.
- `CourseMetadataOptions.customLicense`: the one place of the text
  "Other / Custom license".
- The Course Info Editor (`course_editor_screen.dart`), New Course's form
  (`course_projects_screen.dart`), `CourseLibraryOperations._draftCourse`
  and the Course Wizard (`_CreditRow`, `_setCredits`, `_creditsValue`,
  `_problem`, the licence list) call the owner.
  `CourseLibraryOperations._rolesOf` and the Wizard's `_customLicenseChoice`
  are gone.
- Tests: `test/course_credits_272_test.dart` (5 owner cases, 6 screen
  cases; the 6 passed on the code before the change).

Differences between the three screens, kept as they are, pinned by tests
and reported to the owner (`docs/272_CHANGE_SUMMARY.md`):

1. New Course sets the derivative policy to the licence's own on every
   choice, so choosing Other / Custom license shows "Not specified"; Course
   Info and the Wizard keep the policy shown before.
2. Course Info keeps the Course's stored policy while the licence is
   unchanged; the Wizard writes the licence's own policy.
3. Course Info fills the Custom license field with the stored licence also
   when it is a standard one; the Wizard leaves it empty then.
4. An added credit row starts as Contributor in Course Info and New Course,
   as Author in the Wizard.

Gotchas:

- A Dart record that holds a list never equals another one in `expect`
  (`(name, [roles])`): compare maps or lists.
- The Wizard shows a step's problem only when Next or Save now is pressed.
- Bash heredocs break on an apostrophe in the text: write scripts and test
  blocks with the Write tool (scratchpad), then run them.
- The PC had 1.2 to 1.5 GB of memory free (Chrome, Firefox and Claude take
  about 4 GB): the analyzer took 270 s.

## Revision 1 (2.0.72+272001), the three screens follow the same rules

State: done (12 October 2026). Analyzer clean; credits tests 12 passed; 12
related files 167 passed; complete suite 4,339 passed, 1 skipped (18:49 to
19:32, 43 minutes). Committed on `build-272` and the branch pushed (hash in
`git log`). Revision 0 is `7c8f28fe`.

What was done (details in `docs/272_CHANGE_SUMMARY.md`): the owner's five
points above.

- `CourseCredits`: `customLicenseTextFor`, `customLicenseMissing`,
  `creatorRole`.
- New Course: the licence list calls `policyAfterChoosing`; Continue to
  Editor shows `customLicenseMissing`.
- Course Info: the Custom license field starts from
  `customLicenseTextFor`; Apply shows `customLicenseMissing`.
- Course Wizard: `_derivativeValue` (`policyKeepingStored` against the
  working copy) for the stored policy and the note under the licence
  list; `_CreditRow` starts as Contributor, Add a person gives the
  creator's row Author.
- Tests: `test/course_credits_272_test.dart`, 12 cases.

Decisions taken while working (say so in the report):

- The Wizard's "stored" policy is the one of its working copy (what the
  step opened on, or what an earlier step staged), not the file on disk.
- No Help text changed: none described one of the five differences.
- `docs/COURSE_EDITOR.md` says "No bundled course currently grants
  derivative permission", which is stale (the Italian Exercise Lab
  does); left as found, outside this revision.

Session scratchpad (drafts of the next revisions):
`C:\Users\Domenico\AppData\Local\Temp\claude\C--QQL-QuisquisLingo\2f6486fd-094d-4fc7-b18f-9a9c8e7b76ba\scratchpad`

## Revision 2 (2.0.72+272002), the Course Info Editor's form and its own file

State: done (12 October 2026). Analyzer clean; new tests 26 passed; 17
related files 163 passed; complete suite 4,367 passed, 1 skipped (19:57 to
20:45, 48 minutes). Committed on `build-272` and the branch pushed (hash
in `git log`). Revision 1 is `4d0d708c`.

The independent review of the move (a second reader comparing the old
dialog with the new files line by line, before the suite) found one real
mistake of the renaming script: inside a text, `$defaultLearnerLanguageName`
had become `$_form.defaultLearnerLanguageName` (Dart reads `$_form` and then
the rest as plain text). Fixed in the script (`r1/gen_dialog.py` braces a
renamed interpolation and stops if one is left), in the comparison (it
prints differing texts in full) and with a test on that help sentence. On
its other remark the form is now made in `showCourseInfoEditor`, before the
dialog opens, as the old code did. **Keep doing this review for every moved
screen: the tests and my own comparison had both missed it.**

What was done (details in `docs/272_CHANGE_SUMMARY.md`):

- `lib/controllers/course_info_form.dart`: `CourseInfoForm`,
  `CourseMediaCreditRow`, `CourseInfoSubmission` (`CourseInfoAccepted` |
  `CourseInfoRefused`).
- `lib/controllers/course_credit_rows.dart`: `CourseCreditRow`,
  `CourseRightsHolderRow` (for Revision 3 and the Wizard too).
- `lib/screens/course_info_editor.dart`: `showCourseInfoEditor`,
  `CourseInfoEditor`, `CourseInfoEditorResult`; the layout generated from
  the old text by `r1/gen_dialog.py` (scratchpad), then compared: all 186
  texts and keys of the old dialog are in the new files
  (`r1/compare_literals.py`).
- `CourseEditorScreen._editCourseInfo` is 65 lines; the file went from
  14,839 to 13,288 lines. `_closedCourseInfoEditors`, `_tagHelper`,
  `_languageTagsFromList`, `_localCourseDateTime` and nine imports left.
- `CourseInfoUpdateService.keepsLearningLanguage`.
- Source-text tests follow the code: `course_editor_layout_regression_test`
  (two cases), `qql_233_revision_platform_contract_test`.
- Tests: `course_info_form_272_test` (21), `course_info_editor_272_test`
  (5, passed on the code before the move).

Gotchas:

- `FormalNamePolicy.validatePresentationLabel` refuses a name with spaces
  before or after; it does not trim.
- A Course built without a policy has `DerivativeWorksPolicy.unspecified`.
- Course Info's Apply reads the stored Courses (file I/O) before its other
  checks: a test must wait for the message, not pump once.
- "Version history" is on the Course Editor page and in the dialog: use
  `.last`; the Version history page shows a spinner while it reads, so
  `pumpAndSettle` times out: wait with `pumpUntilFileIoState`.

Owner questions of 12 October, answered in chat: the exercise editor
(`ExerciseEditorScreen`, 3,153 lines, five private helpers shared with the
rest of the file, `labelForType` used by the Exercise Wizard) is not in
the plan's free moves; I recommended moving it whole to its own file as
the first free move (or as Revision 4 if the owner wants the big cut
early). No answer yet.

## Revision 3 (the New Course form), prepared

In the scratchpad (`C:\Users\Domenico\AppData\Local\Temp\claude\C--QQL-QuisquisLingo\2f6486fd-094d-4fc7-b18f-9a9c8e7b76ba\scratchpad`), folder `r3/`:
`new_course_form.dart` (`NewCourseForm`, for `lib/controllers/`),
`gen_dialog.py` + `dialog_head.txt` + `dialog_tail.txt` (they generate
`lib/screens/new_course_dialog.dart`: `showNewCourseDialog`,
`NewCourseDialog`). Still to write: the characterization tests on the
code before the move (name another Course has, name refused, no
languages, Buy a Coffee not HTTPS, a cancelled form deletes its cover),
the form's own tests, the change of `CourseProjectsScreen._createCourse`,
`_DisposeOnUnmount` removed if unused, the Wizard's `_CreditRow` /
`_HolderRow` replaced by the shared rows, and the source-text tests that
read `course_projects_screen.dart` (`course_editor_layout_regression_test`,
`course_metadata_ui_v9_test`, `qql_233_revision_platform_contract_test`).

Tests that read screen source as text (they need care when code moves, in
Revisions 1 and 2): `course_editor_layout_regression_test`,
`course_metadata_ui_v9_test`, `qql_233_revision_platform_contract_test`,
`unified_learner_layout_regression_test`.
