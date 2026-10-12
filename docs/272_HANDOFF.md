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

## Revision 1 (the five rules), prepared

`u1/apply_u1.py` in the session scratchpad
(`C:\Users\Domenico\AppData\Local\Temp\claude\C--QQL-QuisquisLingo\2f6486fd-094d-4fc7-b18f-9a9c8e7b76ba\scratchpad`)
holds the code changes; the screen cases of
`test/course_credits_272_test.dart` then change to pin the single rule
(points 1 to 5 above). If the scratchpad is gone, the changes are small:
the list above names the owner method for each.

## Revision 2 (the Course Info form), prepared (not in the repository yet)

Drafted in the same scratchpad, folder `r1/`, before the owner's decision
(so it still carries Revision 0's behaviour for points 3 and 5: regenerate
and adjust after Revision 1); to be copied in after Revision 1 is
committed:

- `lib/controllers/course_info_form.dart`: `CourseInfoForm` (the state of
  the Course Info Editor: fields from a Course, `addAuthor` /
  `removeAuthor`, `addRightsHolder` / `removeRightsHolder`,
  `addMediaCredit` / `removeMediaCredit`, `chooseLicense`, `setCover` with
  the cover-credit rule, `keepsLearningLanguage`, `validTitle`,
  `titleTakenBy`, `submit` -> `CourseInfoAccepted` | `CourseInfoRefused`,
  `dispose`) and the row classes `CourseCreditRow`,
  `CourseRightsHolderRow`, `CourseMediaCreditRow`.
- `lib/screens/course_info_editor.dart`: `showCourseInfoEditor` and the
  widget `CourseInfoEditor`, generated from the dialog's present text by
  `r1/gen_dialog.py` (exact text, only the names of what it reads change).
- `CourseInfoUpdateService.keepsLearningLanguage` (static; the dialog and
  `apply` share it).
- `r1/apply_r1.py`: the Course Editor's `_editCourseInfo` becomes a call of
  `showCourseInfoEditor`; `_closedCourseInfoEditors`, `_tagHelper`,
  `_languageTagsFromList` and `_localCourseDateTime` leave the screen (the
  dialog's State disposes its form).
- Tests drafted: `course_info_editor_272_test.dart` (5 screen cases, to run
  on the code BEFORE the move) and `course_info_form_272_test.dart` (the
  form without its dialog).
- To adapt: `course_editor_layout_regression_test` (two cases read the
  dialog's source in `course_editor_screen.dart`) and
  `qql_233_revision_platform_contract_test` ("Continue anyway" / "already
  exists" in the Course Editor's source).

Tests that read screen source as text (they need care when code moves, in
Revisions 1 and 2): `course_editor_layout_regression_test`,
`course_metadata_ui_v9_test`, `qql_233_revision_platform_contract_test`,
`unified_learner_layout_regression_test`.
