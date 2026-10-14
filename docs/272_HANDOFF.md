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
| 0 | Course credits and licence owner (`CourseCredits`) (done, `7c8f28fe`) |
| 1 | The five credits and licence rules made the same in the three screens (done, `4d0d708c`) |
| 2 | Course Info form owner; the Course Info Editor dialog in its own file (done, `89b51291`) |
| 3 | New Course form owner; the New Course dialog in its own file (done) |
| 4 | Lesson Options owner (`LessonOptions`) and panel; then a Windows package for the owner to try |
| 5 | The exercise editor (`ExerciseEditorScreen`, 3,153 lines) moves whole to its own file (done, `1aa0d72d`) |
| 6 | Free moves from the Course Editor file: Audio Library, Audit page, Lesson preview, the hierarchy status; `ExerciseLabels` (done, `bd1c2550`) |
| 7 | `TimedRoundClock` (done, `7d79280c`) |
| 8 | Media-reference owner (done, `6f565380`) |
| 9 | Shared JSON readers for the models (`JsonRead`), both rules of the differing copies kept (done, `a35c34f3`) |
| 10 | The two differences between the readers fixed (owner decision of 13 October 2026) (done, `68906c87`) |
| 11 | Merge selection owner (`CourseMergeSelection`) (done, `8fb7a7ff`) |
| 12 | Free moves: the Merge, Import and Export pages leave Course Studio; the canonical editor's four rows leave its file |
| 13 | A Course import shows what its check found; the same check in Merge (owner request, a behaviour change) |
| 14 | A license names its Rights Holder (owner decisions of 13 October 2026, below) |
| then | Home's Round path and Course preview; the small free moves of the plan |
| then | The other free moves, two or three per complete suite |
| Build 273 | The plan's medium-risk items: answer grading, Story cast, the publish gate, the profile service split, Audit rule sets, the earlier exercise shapes, the Round screen's state owners, the Course save sequence |

Owner decisions of 12 October 2026 (22:15, answers to four questions):

1. **Suite**: every revision that creates an owner or touches a rule gets
   its own complete suite; pure file moves with no logic go two or three
   per suite, each still with focused tests and the independent review.
2. **Exercise editor**: it leaves the Course Editor file right after Lesson
   Options (Revision 5).
3. **Scope**: Build 272 = the low-risk owners and the free moves; the
   medium-risk items are Build 273, after the owner has used this Build.
4. **Try it**: a Windows package after Revision 4 (Lesson Options), so the
   owner can try the Course Info Editor, New Course's form, the Wizard's
   credits and Lesson Options by hand.

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

## Revision 3 (2.0.72+272003), New Course's form and its own file

State: done (12 October 2026). Analyzer clean; new tests 13 passed; 17 related files 209 passed; complete suite 4,380 passed, 1 skipped (20:58 to 21:42, 44 minutes). Committed on `build-272` and the branch pushed (hash in `git log`). Revision 2 is `89b51291`.

What was done (details in `docs/272_CHANGE_SUMMARY.md`):

- `lib/controllers/new_course_form.dart`: `NewCourseForm`,
  `NewCourseSubmission` (`NewCourseAccepted` | `NewCourseRefused`).
- `lib/screens/new_course_dialog.dart`: `showNewCourseDialog` (makes the
  form, deletes a stored cover when the form is cancelled),
  `NewCourseDialog`; the layout generated from the old text by
  `r3/gen_dialog.py`; all 76 texts and keys of the old dialog are in the
  new files (`r3/after_move.py`).
- `CourseProjectsScreen._createCourse` is 30 lines; the file went from
  3,504 to 2,772 lines; `_DisposeOnUnmount` and nine imports left.
- The Course Wizard uses `CourseCreditRow` / `CourseRightsHolderRow`.
- Source-text tests follow the code: `course_editor_layout_regression_test`,
  `course_metadata_ui_v9_test`, `qql_233_revision_platform_contract_test`.
- Tests: `new_course_form_272_test`, `new_course_dialog_272_test` (2,
  passed on the code before the move).
- The independent review before the suite found no visible or stored
  difference. One point made exact: the name check asks the Course list
  as it is when Continue to Editor is pressed
  (`titleTaken: (title) => _library.hasCourseTitled(title)`), not a
  tear-off bound when the form opened.

## Revision 4 (2.0.72+272004), Lesson Options

State: done (12 October 2026). Analyzer clean; the independent review's two
edge cases fixed and pinned; complete suite 4,391 passed, 1 skipped (22:40
to 23:24, 44 minutes). Committed on `build-272` and the branch pushed
(hash in `git log`). Revision 3 is `213dc5c6`.

The review's two edge cases (see `docs/272_CHANGE_SUMMARY.md`): the panel is
an item of the Course Editor's lazy list and can leave the tree while its
own dialog is open; and it drew a Course that could be older than the
working copy. Now `LessonOptionsPanel(working: () => _course, canModify:,
onChanged:, host: context)`: dialogs and messages open on `host`, an answer
is staged while `host.mounted`, a change starts from `working()`. **Apply
the same to any widget taken out of a screen whose members read the live
working copy and the screen's own `mounted`.** I had started the suite
before the review ended, betting on no finding, and lost ten minutes: wait
for the review first.

What was done (details in `docs/272_CHANGE_SUMMARY.md`):

- `lib/services/lesson_options.dart`: `LessonOptions` (pure).
- `lib/widgets/lesson_options_panel.dart`: `LessonOptionsPanel`, taken
  from the Course Editor's members by `r4/apply_r4.py`; every JSON write
  replaced by `LessonOptions.apply`.
- `lib/widgets/editor_dialogs.dart`: `askAuthoringName`,
  `chooseTimedLimit` (was `_chooseTimedLimit`).
- `CourseWizardOptions.applyTo` calls `LessonOptions.apply`.
- The Course Editor file went from 13,288 to 12,748 lines.
- Tests: `lesson_options_272_test` (the rules; the Wizard's step against
  what it wrote before), `lesson_options_panel_272_test` (2, passed on
  the code before the move).

Revision 4 is `b17ae621`. The Windows package for the owner is made
(12 October, 23:30): `build\packages\quisquislingo_windows_beta_272004.zip`.
To try: Course Info Editor, New Course's form, the Wizard's credits
(Advanced on step 3), Lesson Options. Awaiting the owner's word on it.

Follow-up commit, same version: `tools/package_windows_release.ps1` line 494
held a BEL character instead of `\a` in `data\app.so` since Build 270
Revision 7 (a shell heredoc had eaten the backslash), so the script could
not finish; fixed, and the script then ran through. **Before a release
check a script for control characters**:
`python -c "import sys; print(sorted(set(b for b in open(sys.argv[1],'rb').read() if b < 32 and b not in (9,10,13))))" <file>`.

## Revision 5 (2.0.72+272005), the exercise editor has its own file

State (12 October 2026, 23:45): code, tests and documents done; analyzer clean; 12 related files 153 passed; committed locally (hash in `git log`), NOT pushed yet: by the owner's decision this pure move shares its independent review and its complete suite with Revision 6. Revision 4 is `b17ae621`, its follow-up `9765999e`.

What was done (details in `docs/272_CHANGE_SUMMARY.md`):

- `lib/screens/exercise_editor_screen.dart`: `ExerciseEditorScreen`,
  moved by exact text (`r5/apply_r5.py`); 18 lines differ, all at the
  five ties (`r5/diff_region.py`). The Course Editor file re-exports it
  and is at 9,530 lines.
- `PresetRecipes.blankFor`, `ExercisePresetRegistry.nameOrId`,
  `PresetActionChip` (`lib/widgets/preset_action_chip.dart`).
- Tests: `exercise_editor_move_272_test` (4).

Gotchas:

- A new file's imports: start from all the imports of the file the code
  came from, run `flutter analyze --no-pub > log`, then
  `python prune_imports.py log` (scratchpad) removes what the analyzer
  calls unused or unnecessary, in every file; analyze again.
- The blank exercise went to `PresetRecipes`, not to
  `ExerciseDraftBuilder`: the recipes import the builder.
- A public widget needs `{super.key}` (lint).
- `course_editor_screen.dart` holds a control character (0x02) on purpose
  as a separator in the exercise form's snapshot (`_pluralPictures`
  joined); it moved with the editor. Left as found.

## Revision 6 (2.0.72+272006), four more pages leave the Course Editor file

State (13 October 2026, 00:52): done. Analyzer clean; 18 focused files 166 passed; the independent review of Revisions 5 and 6 found no behaviour difference (two tidy-ups done: the async import, the labels owner's comment); the ONE complete suite for both: 4,400 passed, 1 skipped. Committed (hash in `git log`) and pushed with Revision 5 (`1aa0d72d`).

What was done (details in `docs/272_CHANGE_SUMMARY.md`):

- `lib/services/exercise_labels.dart`: `ExerciseLabels.kindName`,
  `typeLabel`, `summary` (were `_exerciseKindName`, `_exerciseTypeLabel`,
  `_exerciseSummary` of the Course Editor file).
- `exerciseEditorFor` and `openSearchResult` are public functions at the
  end of `lib/screens/exercise_editor_screen.dart`.
- Own files, moved by exact text (`r6/apply_r6.py`, then `r6/fix_tail.py`):
  `lib/screens/audio_library_screen.dart` (1,051 lines),
  `lib/screens/course_audit_screen.dart` (223),
  `lib/screens/lesson_authoring_preview_screen.dart` (83),
  `lib/services/authoring_hierarchy_status.dart` (152). The Course Editor
  file re-exports them and is at 7,927 lines.
- Tests: `exercise_labels_272_test` (5).

Gotchas:

- Taking a run "to the end of the file" also takes what stands after the
  class meant: `_lessonName` and `_roundName` followed the Audio Library
  and went with it; `fix_tail.py` put them back in the Course Editor
  file, where their users are. Name the end of a run, never `EOF`,
  unless the last declaration is the one meant.
- Wait for the focused tests to end before the version bump or any edit
  in `lib/` or `test/`; wait for the independent review before the
  complete suite.

## Revision 7 (2.0.72+272007), the Timed Round's clock

State (13 October 2026, 02:41): done. Analyzer clean; 16 focused files 171 passed; the independent review found no behaviour difference. The first complete suite had ONE failure, in the new `timed_round_screen_272_test` (it tapped 'Right q1', but a Round shuffles its questions); corrected, and `keepCrashLogUnavailable()` added to its setUp; 12 of 12 runs pass, 4 of 4 on the screen before the change. Second complete suite: 4,418 passed, 1 skipped. Committed (hash in `git log`) and pushed. Also on this branch: `docs/274_PLAN.md` (the owner's nine points for Build 274, planned while this suite ran; a documents-only commit).

What was done (details in `docs/272_CHANGE_SUMMARY.md`):

- `lib/services/timed_round_clock.dart`: `TimedRoundClock` (`now`,
  `canRefresh`, `onSecondsChanged`, `onDue`; `setLimit`, `start`,
  `isDue`, `expire`, `completeInTime`, `stop`).
- `RoundScreen._timed` (a `late final` field) replaces eight names of
  the screen's State; made by `r7/apply_r7.py` (exact texts, each
  asserted to match once; it also asserts that no old name is left).
- Tests: `timed_round_screen_272_test` (7, written before the change),
  `timed_round_clock_272_test` (11).
- The Beta expiry moved to 2026-11-12 (release day 13 October 2026):
  `expiry.py 12 13` in the scratchpad, run after `bump.py`, changes the
  service, every date of `test/beta_lifecycle_test.dart` and the
  README's line.

Gotchas:

- A pure owner that uses `Timer` is tested with `testWidgets` only for
  its clock of timers (`tester.pump(d)` lets `d` pass); the time the
  owner reads is set by hand.
- On a Timed Round's last question with mistakes to repeat the button
  reads "Review mistakes", not Continue.
- A Round shows its questions in a new order each time: a test taps the
  answer shown (`find.textContaining('Right q').first`), never the
  answer of a numbered question.
- A test file that opens the Round screen calls
  `keepCrashLogUnavailable()` in its `setUp`
  (`test/support/test_directories.dart`); without it a real Crash Log
  write left unfinished at the end of one case can hold every later
  case of the file (seen once in nine runs).
- A new widget test file is run several times (six or more) before the
  complete suite: one pass does not show a case that fails one run in
  two. This cost a second complete suite here.

## Revision 8 (2.0.72+272008), one owner for the media reference rule

State (13 October 2026, 05:51): done. Analyzer clean; 24 focused files 316 passed; the independent review found no behaviour difference, its follow-ups done. The first complete suite (83 minutes, a busy PC) had ONE failure, in `qql_230_course_persistence_hardening_test` (the 10-second guard of `pumpUntilFileIoState` ran out); the file passes alone 4 of 4; the guard is 30 seconds now and `D:\QQL_test_temp` was emptied. Second complete suite: 4,471 passed, 1 skipped. Committed (hash in `git log`) and pushed, with the Build 274 plan (`docs/274_PLAN.md`: `f9989981`, `d561323d`).

What was done (details in `docs/272_CHANGE_SUMMARY.md`):

- `lib/models/course_media_reference.dart`: `CourseMediaReference`
  (patterns `image`, `audio`, `any`, `fileName`, `packagePath`, the
  text `imageBody`; `isImage`, `isAudio`, `isAny`, `isValidAudio`,
  `isValidImage`, `checkCourseJson`).
- Its eight users read it (`r8/apply_r8.py`): four places of
  `course_models.dart`, two of `course_media_store.dart`,
  `course_package_service.dart`, `tools/sign_course.dart`.
- Tests: `course_media_reference_272_test` (28 written before the
  change + 24 on the owner).

Gotchas:

- `dart format` on a file of `git status` also rewraps old lines of that
  file that were never formatted (`course_media_store.dart` had one):
  read the diff after formatting and put such a line back.
- A pattern built from `const` texts is compared with the old literal
  in a test (`RegExp.pattern`), not by eye.

## Revision 9 (2.0.72+272009), shared readers for a Course file

State (13 October 2026, 06:44): done. Analyzer clean; 26 focused files 334 passed; the independent review found no behaviour difference; complete suite 4,486 passed, 1 skipped. Committed (hash in `git log`) and pushed. Revision 10 is prepared in `r10/` (`apply_r10.py`, `tests_r10.py`).

What was done (details in `docs/272_CHANGE_SUMMARY.md`):

- `lib/models/json_read.dart`: `JsonRead` (`requiredString`,
  `optionalString`, `optionalInt`, `stringListByKey`, `stringList`,
  `pairList`, `requiredList`, `optionalList`, `refuseUnknownKeys`,
  the three timestamp functions).
- `course_models.dart` (135 calls) and `exercise_canonical.dart` (32)
  call it (`r9/apply_r9.py`; `r9/same_code.py` compares a formatted
  file with the renamed old text).
- Tests: `json_read_272_test` (6 written before the change + 9).

Gotchas:

- `dart format` in a scratch folder uses another style than in the
  repository (no `pubspec.yaml` there): the line counts of a dry run
  differ from the real ones. Compare code, not layout.
- A check of its own can stand before a reader: `course.sectionNames`
  and an exercise without `prompt` never reach `JsonRead`. Run a
  characterization test before believing what a file is told.
- The models file grows (5,748 to 5,796 lines): longer names wrap.

## Revision 10 (2.0.72+272010), one wording, one rule for a list that may be left out

State (13 October 2026, 07:49): done. Analyzer clean; 26 focused files 605 passed; the independent review confirmed the two fixes and found one side effect, fixed (`optionalList` returns `List<T>.unmodifiable`, not a bare `const []`); complete suite 4,490 passed, 1 skipped. Committed (hash in `git log`) and pushed. **Asked of the owner, no answer yet**: seven lists of the Course root keep checks of their own (`sectionNames`, `keywords`, `authors`, `rightsHolders`, `lessonIconAssets`, `audioLibrary`, `defaultTimedLimitsSeconds`); bring them under the same rule as the next revision? Recommended yes.

The owner said "Fix the two things" (13 October 2026), then yes to:

1. **Wording**: every refusal of a list names the place and the field.
2. **A missing list**: two readers stay (`requiredList`, `optionalList`);
   the seven hand-written checks of the models are `optionalList`; a
   list written as `null` means "not there" everywhere.

What was done (details in `docs/272_CHANGE_SUMMARY.md`):

- `JsonRead.stringListByKey` removed; `pairList(j, key, where)`.
- `course_models.dart`: seven calls name their place, seven checks are
  `optionalList` (`r10/apply_r10.py`; the tests by `r10/tests_r10.py`).
- What changes for a file: a GuideBook module's `sentences` / `words`
  as `null` (refused, now empty); the earlier exercise shape's `items`
  / `layout` when not a list (empty, now refused).
- `docs/COURSE_JSON_FORMAT.md`: the section Lists.
- Tests: `json_read_272_test` (18).

Gotchas:

- A script that edits a test by exact text must be written after the
  formatter has run on that test: its layout is the formatter's.
- A probe test (`zz_probe…`, printing what the code says for a list of
  cases, then deleted) is a quick way to record the "before" of a
  behaviour change.

## Revision 11 (2.0.72+272011), the Merge page's choices

State (13 October 2026, 08:48): done. Analyzer clean; 8 focused files 104 passed; the independent review found no behaviour difference; complete suite 4,505 passed, 1 skipped. Committed (hash in `git log`) and pushed. Revision 12 (the three pages out of Course Studio) is prepared in the scratchpad, `r12/apply_r12.py`.

What was done (details in `docs/272_CHANGE_SUMMARY.md`):

- `lib/services/course_merge_selection.dart`: `CourseMergeSelection`
  and `enum CourseMergeSetting`.
- `_CourseMergeScreenState` holds `_selection` instead of twelve fields
  (`r11/apply_r11.py`); `_options` and `_optionChoices` are gone.
- Tests: `course_merge_selection_272_test` (10 on the page, written
  before the change; 5 on the owner).

Gotchas:

- A widget test that pumps the same page twice reuses its State: one
  opening of the page for each test.
- After a merge the page's package is discarded: one DO MERGE! for each
  test.
- Python given through a Bash heredoc breaks on `\'` and `\n`: write
  the script with the Write tool, or edit the file with Edit. This
  cost three failed attempts in Revisions 10 and 11.

## Revision 12 (2.0.72+272012), seven widgets leave two files

Complete: reviewed, the complete suite passed at its second run (see Gotchas), committed and pushed.

What was done (details in `docs/272_CHANGE_SUMMARY.md`):

- `r12/apply_r12.py`: `CourseImportScreen`, `CourseExportScreen`,
  `CourseMergeScreen` to files of their own;
  `lib/widgets/course_package_notes.dart` (three helpers).
- `r12/apply_rows.py`: the canonical editor's four rows and `menuText`
  to `lib/widgets/primitive_editor_rows.dart`.
- Tests: `free_moves_272_r12_test` (4).

Gotchas:

- A new file in another folder: rewrite the same-folder imports of the
  head (`'round_screen.dart'` → `'../screens/round_screen.dart'`) before
  the first analyzer run, or it reports missing files instead of unused
  imports.
- `diff_region.py` looks for the same first line in the new file: when
  the class itself is renamed, compare with a script that renames the
  old run first (`r12/compare_rows.py`).
- `primitive_editor_narrow_261_test` takes about seven minutes: a
  focused batch with it must run in the background.
- The first complete suite failed with 122 cases of
  `exercise_laboratory_254_test` and nothing else: for twenty minutes
  the PC was about twelve times slower (8 GB of memory, two browsers
  open; the file took 21 min 38 s against 1 min 46 s in Revision 11's
  suite) and every wait of that file ran out at its 10 seconds. Alone
  the file passes (253, 2 min 23 s). Its wait is now 30 seconds, like
  `pumpUntilFileIoState`. When a suite fails in one file only, read the
  times of that file in the log before looking for a cause in the code.

## Revision 13 (2.0.72+272013), a Course import shows what its check found

Complete: reviewed twice and reworked, committed and pushed on the owner's go ("Go on and commit", 13 October 2026). The owner's last two decisions (author and license in a Merge; See the Audit) were made after the complete suite and, by the owner's instruction ("Don't run the suite now"), checked with the analyzer and the focused tests only: the next revision's suite covers them.

What was done (details in `docs/272_CHANGE_SUMMARY.md`):

- `lib/services/course_import_check.dart` (`CourseImportCheck`,
  `CourseImportFacts`, `CourseFileUse`, pure Dart) and
  `lib/widgets/course_import_check_dialog.dart` (two pop-ups: with
  anomalies, without; the words follow the use, import or Merge).
- `CourseLibraryOperations.checkCourseFile` (the one maker of a check;
  it never stops an import or a Merge), `CourseImportReview.check`,
  `CoursePackageImport.courseJsonBytes`, the call in
  `CourseProjectsScreen._importCourse` (one import at a time) and
  `CourseMergeScreen.checkCourse`.
- Help EN/IT/ES (`editorHelp.importCustomCourse.body`), the Merge
  page's Help.
- Tests: `course_import_check_272_test`,
  `course_import_check_dialog_272_test`, a case in
  `course_manager_workflow_249_test`.

Owner decisions of 13 October 2026 taken while it was made: a second
pop-up for a file without anomalies, with the author, Maintainer, Team,
last edit, license and the number of Lessons, Rounds and exercises, and
with Cancel too; the Course's own labels for Lessons and Rounds in the
pop-ups; the same check in Merge, for its second Course, both pop-ups.

Three decisions of mine reported to the owner for confirmation (in the
change summary): the pop-up also comes before a Publisher Course's
confirmation; the Audit warnings are counted, not written out (their
lines say Lesson and Round whatever the Course's labels); in a Merge no
line about authors, license or audio (they are the stored Course's).

Gotchas:

- The pop-up is off in every test (`test/flutter_test_config.dart`):
  the import tests written before it answer no question there. A test
  about the pop-up turns it on in its `setUp` and off in its
  `tearDown`.
- Before promising the owner a line of a pop-up, check that the flow
  can reach it: two anomalies of the first draft were Audit errors that
  refuse the file earlier (found by the first independent review).
- A fixture with a Lesson and a Round of the same ID has an Audit
  error (`ID_DUPLICATE`): an import review of it is refused.
- A Python script with apostrophes or backslashes goes through the
  Write tool, never a shell heredoc (three more failures today).

## Revision 14 (2.0.72+272014), a license names its Rights Holder

Committed `b0ffbb04` on 13 October 2026 (night) after the owner's "go" on
the commit description, and pushed to `origin/build-272`. Next: Revision
15 (see "After Revision 14" below).

What it is:
- The rule in `CourseCredits`: `rightsGivenUp`, `needsRightsHolder`,
  `mainAuthors`, `defaultRightsHolders` (each name once),
  `rightsHoldersOfNewCourse`, `rightsHoldersOfWizardCredits`,
  `rightsHoldersByHand`, `sameRightsHolders`, `sameAuthors`,
  `authorsAsFormsWrite`, `rightsHolderDefaultNote`,
  `rightsHolderMissingNote`, `rightsHolderNoteFor`.
- New Course: `CourseLibraryOperations._draftCourse` stores
  `rightsHoldersOfNewCourse`; note `new-course-rights-holder-note`.
- Course Wizard: `CourseWizardCredits.of` gives the form
  `rightsHoldersByHand`, `applyTo` stores `rightsHoldersOfWizardCredits`
  (a Course stored without a Rights Holder keeps none until its credits
  change); `CourseWizardSample.credits` leaves the rows empty; Add a
  Rights Holder opens with `_firstHolderRows()` (every main Author); the
  note `course-wizard-rights-holder-note` is `_holderNote` in a
  `ListenableBuilder`; a conditional sentence ends the About step's Tell
  me more.
- Audit Warning `LICENSE_RIGHTS_HOLDER_MISSING` (registry 131 rules, 66
  Errors, 48 Warnings, 17 Info), its license through `oneLineText`
  (`lib/models/one_line_text.dart`, new; `CourseImportCheck.shown`
  delegates to it); Export as Publisher Course refuses; the import pop-up
  says the missing Rights Holder under the Audit's own condition, also
  for a file without a license ("No Rights Holder is named either.").
- Help EN/IT/ES (`editorHelp.qa.authors.a`,
  `editorHelp.exportAsPublisherCourse.body`); a paragraph in
  `docs/COURSE_JSON_FORMAT.md`.
- Tests: `test/rights_holder_272_test.dart` (39), a widget case in
  `course_wizard_267_test`, two widget cases and two checks in
  `course_credits_272_test`, two cases of `course_import_check_272_test`
  updated. Older tests: the made-up Courses of nine test files name the
  made-up Rights Holder "Test Author" (the raw JSON of
  `persisted_learner_delivery_226_04_r1_test` too), the Publisher export
  test "Alice"; counts 130 → 131 and 47 → 48; the three Demo tests expect
  the new warning (Demo files unchanged).

Evidence (`docs/272_VALIDATION.md`): analyzer clean; focused files green;
each new widget case six times in a row; the complete suite **4,649
passed, 1 skipped, 0 failed** (84 min 46 s, a busy PC), once, on the final
tree. Two independent read-only reviews: the first of the whole revision
(three defects and smaller points), the second of the first one's
corrections (four more points); all acted on. The corrections after the
second review were not read by a third reader.

Left as they are and told to the owner in the change summary: what a
Warning newly shows, also on Courses the user cannot edit (red row in
Course Studio, export and import messages, Merge notice, the Wizard's
"Still red"); the default Rights Holder is always a person; only "CC0
1.0" written exactly is exempt; a Wizard Course left before step 3 keeps
the app name (a Discord handle when there is one) as Author and Rights
Holder; a Rights Holder typed with the Author's own name is the default.
Two things done beyond the owner's list, to confirm: Add a Rights Holder
opens with every Author of the form; the pop-up's "No Rights Holder is
named either." for a file without a license.

Owner questions answered on 13 October 2026 (evening): the made-up Rights
Holders are only in test files ("Test Author", "Alice", and in the new
tests "Maria Rossi", "Anna Bianchi", "mari_88", "Ada", "Ann", "Bo",
"Scuola Verde"); no Demo, stored Course or app text names them.

Scripts and logs in the scratchpad `r14/`; the suite log is
`suite272r14b.log`.

## Revision 15 (2.0.72+272015), QQL Demo: English from Italian leaves the repository

Committed `5269153c` on 13 October 2026 (about 21:00) after the owner's go
on the commit description, and pushed to `origin/build-272`. The notes
below are the working notes of the revision, kept for the record.

Owner, at the go: "Forget about renaming the folder for now." The rename
of `demo_courses` to `test_courses` is NOT to be done until the owner asks
again (`demo_image_banks` likewise untouched).


Started 13 October 2026 (night), after Revision 14's commit `b0ffbb04`.
Owner decision: "Take it out of the repo, like viterbese and piedmontese."
The model is Build 262 Revision 0 (`5ee20a5b`).

Plan:
1. Copy to the owner's private folder `D:\QQL_plus\Corsi_Privati` (outside
   the repository, never commit them), check the copies byte for byte,
   then remove from the repository:
   - `assets/courses/english_from_italian_it_en.json` → `bundled\`
   - `tools/generate_english_from_italian_260.py` and
     `tools/qql_v11_builders.py` (only that generator imports it) →
     `generators\`
   - `test/english_from_italian_260_test.dart`,
     `test/difficulty_curve_260_test.dart` → `tests\`
2. App: `CourseService.courseAssets` loses `EN_IT` (with its labels and its
   `_additionalBundledCodes` entry); the Course ID
   `course_65dce83b-fd0a-4b83-a5a1-8f8b97a58d05` stays reserved in
   `CourseEditorService`; `lib/screens/credits_screen.dart` line about
   "English from Italian / Edge Case courses"; `tools/validate_courses.py`.
   Check what Home does for a learner whose last Course was `EN_IT`.
3. Tests that name it (about 35 files). Three kinds:
   - about its own content: remove the case (bundled_courses_225_02,
     lab_vocabulary_265, guidebook_vocabulary_265, word_lookup_sources_265,
     owner_review_259_revision7 / 260_revision3 / 261_revision5,
     exercise_titles_261, course_official_provenance_225_04,
     course_service_test, course_model_v11_243, demo_package_roundtrip_254,
     korean_production_discovery_225_03, audit_speed_271,
     runtime_canonical_256, exercise_mascot_256, round_type_wizard_test);
   - using it as a sample Course: use another Course (the Laboratory `IT`,
     or the fixtures `registerEdgeCaseFixture()` `EN_EDGE` (Italian to
     English) and `registerKoreanFixture()` `KO`): courses_study_review_261,
     course_entry_animation_228, course_library_operations_249,
     course_manager_workflow_249, official_course_storage_226_01,
     private_course_259, publisher_course_export_262, course_preview_261,
     leaderboard_navigation_test, small_items_270, import_side_doors_270;
   - `EN_IT` as a language pair only (private_storage_names_255,
     course_backup_v9_clean_cut, `course_storage_names.dart`,
     learner_round_path_test's ID as a seed): nothing to do.
   Remember that Revision 16 takes the Laboratory out of the app too (it
   stays as a test fixture), so prefer the fixtures over the Laboratory
   where a test needs only "a bundled Course".
4. Documents (README lines that name it, CHANGELOG, AGENTS.md bullet,
   change summary, validation), version 272015, independent review,
   complete suite, the commit description shown to the owner first.

Scripts in the session scratchpad `r15/`.

Progress (13 October 2026, about 19:15):
- Done: version 272015; the five files copied to the private folder
  (each copy's SHA-256 checked), a section appended to its `LEGGIMI.txt`,
  then `git rm`; `CourseService` (registry, `bundledCourseIds`, labels,
  `_additionalBundledCodes`); credits page ("Edge Case course");
  `tools/validate_courses.py`; README. Home needs no change: a stored
  selection that no longer exists falls back to the first playable Course
  (`home_screen.dart`, "if (!playable.any(...))") and stale recent refs
  are filtered by `courseByRef.containsKey`.
- Running: a helper agent migrates the test files under `test/` only
  (rules: delete only cases about the removed Course's own content, move
  the others to the Laboratory or to the Edge Case / Korean fixtures,
  never weaken a test). Review its report and its diff before anything
  else; it runs the analyzer and the changed test files itself.
- Drafted in the scratchpad `r15/`: `changelog_r15.md`, `summary_r15.md`
  (placeholders TESTS_LINE / TESTS_SECTION to fill from the helper's
  report).
- Left for Revision 16 on purpose: App Info's "The bundled demo courses"
  (plural) in the three Help catalogs.
- Importable custom version made on the owner's request ("Ok, make an
  importable version"): `D:\QQL_plus\Corsi_Privati\custom  QQL_IT_EN_english_from_italian.json` (new Course ID
  `course_dff7519d-8973-4def-8988-5ca14c7cfc88`, Maintainer Tempesta
  35932, version 1), written by the new
  `make_custom_english_from_italian.py` there (it imports `custom_course`
  from the owner's `make_custom_courses.py`, which is unchanged, and
  writes this one file; the other custom files' hashes were compared
  before and after). `LEGGIMI.txt` describes it. STILL TO DO: check the
  file with the app's own import reader
  (`CustomCourseTransferService.courseFromBytes` and the Audit) in a
  throwaway test once the helper has finished its Flutter runs; delete
  the throwaway test afterwards.
- Seen while there, to tell the owner: the Piedmontese custom files of 3
  October are in the GuideBook shape of before Build 266 (`content`);
  check whether current QQL still imports them before saying so.

Progress (13 October 2026, about 20:15):
- The helper finished the test migration: 33 files under `test/` (31
  named the Course, plus `course_library_screen_244_test` and
  `course_library_view_255_test`, which count bundled rows); its own
  final run: analyzer clean, 340 passed in the 31 files. I read five of
  its diffs (roundtrip, owner reviews 259 r7 / 260 r3 / 261 r5, Publisher
  export): deletions are of the Demo's own content only, migrations keep
  their meaning.
- The importable custom file was checked with the app's import reader (a
  throwaway test, deleted): it reads, 0 Audit errors, 1 warning (Rights
  Holder). The same check: the owner's four other private custom Courses
  (two Piedmontese, Viterbese, Neapolitan) are REFUSED by the current app
  (GuideBook shape of before Build 266); told to the owner, not touched.
- Documents written: CHANGELOG entry, README, AGENTS.md bullet, the
  Revision 15 section of `docs/272_CHANGE_SUMMARY.md`.
  `python tools/validate_courses.py`: 1 bundled Course, OK.
- Running: the independent read-only review (the app's behaviour with
  leftover learner state for the removed Course; the test migration).
- Still to do: act on the review; `docs/272_VALIDATION.md` section; the
  complete suite once; show the owner the commit description; commit
  (the five deletions are already staged by `git rm`; stage the rest
  with an explicit list), push, beep, memory.
- New order decided by the owner the same evening: Revision 16 = the
  pair-count and Flashcard recommendations become Info (see "After that"
  below), Revision 17 = the Laboratory leaves the app.

Progress (13 October 2026, about 21:00):
- The independent review is back: no crash and no stale row for a device
  with leftover `EN_IT` state; four test points and one outside the
  repository, all acted on:
  - the owner's private `corsi_brevi/make_short_courses.py` imported
    `qql_v11_builders` from the repository's `tools/`: a copy now stands
    beside it (script unchanged, import checked), `LEGGIMI.txt` says so;
  - `korean_production_discovery_225_03_test`: its comment now says that
    two Courses of one language are no longer shown switching; two new
    cases (a stored selection that is no longer bundled; the selector with
    one Course);
  - `exercise_titles_261_test`: the Story case waits for a Continue that
    can be pressed and checks the instruction line again;
  - `word_lookup_sources_265_test`: taps inside "a cup of tea".
  - App: the Course selector draws "Other courses"
    (`course-selector-other-courses`) only over rows (`home_screen.dart`).
- Documents updated for all of this (CHANGELOG, AGENTS.md, change
  summary).
- Running: analyzer + seven test files (`r15/analyze1.log`,
  `r15/review1.log`). Then: validation section, the complete suite, the
  commit description for the owner.
- Not done from the review (reported in the change summary): the plural
  texts (Revision 17); `exercise_titles_261_test`'s loop over
  `courseAssets` lost its Italian sample (the single Edge Case case and
  `learner_panel_260_test` still check Italian titles).

STATE (13 October 2026, about 20:50): Revision 15 is READY and NOT
committed; the commit description is in the scratchpad
(`commit_272015.txt`) and was shown to the owner: commit only on the
owner's go. The five deletions are staged by `git rm`; stage the rest
with an explicit list (never `devtools_options.yaml`,
`tools/cloud_setup.sh`), push `build-272`, beep, update the memory file.
Evidence: analyzer clean; two new Home cases six times in a row; the
complete suite 4,629 passed, 1 skipped, 0 failed (37 min,
`suite272r15.log`); `docs/272_VALIDATION.md` has the section.

Owner, same evening:
- "Also the Edge Course can't be imported", then: "I used an old version.
  The current version can be imported." A throwaway test (deleted) had
  meanwhile imported `demo_courses/edge_case_it_en.json` through the real
  Course Studio screen: pop-up, Import anyway, imported. No bug.
  Note: Quick Import reads only `import.zip` or `import.json`.
- "the folder should be renamed from Demo Courses to Test Courses": do it
  as a follow-up commit of the same version right after Revision 15's
  commit: `git mv demo_courses test_courses`, then every reference
  (about 27 test files, `test/support/edge_case_fixture.dart`,
  `tools/generate_edge_case_demo_254.py`, the comment in
  `lib/services/course_service.dart`, README, AGENTS.md's current-state
  lines, `test/fixtures/v11/README.md`); earlier Builds' documents keep
  the old name as history. Run the analyzer and every test file that
  names the folder. `demo_image_banks/` was not named by the owner: ask.
- "what is Italian Demo 2?": answered (a small English to Italian sample
  of Build 239, 2 Lessons, 10 Rounds, 50 exercises, JSON and ZIP; used by
  about twelve test files as the sample Course for packages and the
  Image Library; Maintainer Tempesta 35932; no author, no Rights Holder).

## Revision 16 (2.0.72+272016), two recommendations stop being Warnings

Committed `b440745d` on 13 October 2026 (about 23:05) after the owner's go,
and pushed to `origin/build-272`. Earlier state: Evidence: analyzer clean; the new test file six times in a row;
the complete suite 4,646 passed, 1 skipped, 0 failed (35 min,
`suite272r16.log`); `docs/272_VALIDATION.md` has the section. The commit
description (scratchpad `commit_272016.txt`) was shown to the owner:
commit only on the owner's go, with an explicit file list (never
`devtools_options.yaml`, `tools/cloud_setup.sh`; the new file is
`test/recommendations_272_r16_test.dart`), push `build-272`, beep, update
the memory file. Then Revision 17 (the Laboratory leaves the app).

The notes below are the working notes of the revision.


Started 13 October 2026 (about 21:10), after Revision 15's commit
`5269153c`. Owner decision ("Agreed"): Build 274's planned Revision 1
(`docs/274_PLAN.md`) is brought forward. Owner's words about pairs: warn
only if "fewer than 2" or large numbers.

Done in the working tree (script `r16/apply_r16.py` in the scratchpad):
- version 272016;
- `audit_code_registry.dart`: `FLASHCARD_EXAMPLE_EMPTY`,
  `FLASHCARD_AUDIO_EMPTY`, `AUDIO_MATCH_PAIR_COUNT`, `MATCH_PAIR_COUNT`
  are Info with new texts (registry 131 rules: 66 Errors, 44 Warnings,
  21 Info);
- `course_audit_service.dart`: `recommendedPairs` (2 to 5),
  `pairCountOutsideAdvice` (1 pair, or more than 5), `pairCountAdvice`;
  the usage-sentence Info also for a Picture flashcard (Note cards
  exempt); the read-aloud message reads "Flashcard has no read-aloud.";
- forms (`exercise_editor_screen.dart`): "Usage sentence and optional
  translation (recommended)", "Target-language pairs (2 to 5)", "Sound
  matches (2 to 5)"; `exercise_field_help.dart` and
  `exercise_authoring.dart` texts; Help EN/IT/ES (the two presets' body,
  the two pairs fields, the Flashcard usage field);
  `docs/COURSE_EDITOR.md` line about Audio Match.

Still to do: update the tests that pin the old texts and counts
(`bundled_courses_225_02_test` five Flashcard warnings of the Laboratory,
`exercise_field_help_226_02_test`, `exercise_field_help_ui_226_02_test`,
`audit_code_registry_226_02_test` counts); a new test file
`test/recommendations_272_r16_test.dart` (pairs 1..6 for both presets,
both Flashcard kinds, Note card exempt, no Audit concern from these
alone, the form labels, a Listen and match of five pairs on a narrow
learner page); mark Revision 1 of `docs/274_PLAN.md` as delivered here;
documents; independent review; complete suite; the commit description
for the owner.

Progress (13 October 2026, about 21:40):
- Tests written: `test/recommendations_272_r16_test.dart` (new; the
  exercises are built by their own forms with `ExerciseDraftBuilder` and
  `PresetRecipes.blankFor`); older tests updated by `r16/tests_r16.py`
  (`bundled_courses_225_02_test`, `audit_code_registry_226_02_test`,
  `exercise_field_help_226_02_test`, `exercise_field_help_ui_226_02_test`).
- Documents written by `r16/docs_r16.py`: CHANGELOG, README, AGENTS.md
  bullet, the Revision 16 section of `docs/272_CHANGE_SUMMARY.md`, the
  note in `docs/274_PLAN.md` that its Revision 1 was delivered here.
- Running: analyzer and eleven focused files (`r16/analyze1.log`,
  `r16/focused1.log`).
- Still to do: read those results; the independent review; six runs of
  the two new widget cases; the complete suite; `docs/272_VALIDATION.md`;
  the commit description for the owner (scratchpad `commit_272016.txt`),
  commit on the owner's go, push, beep, memory. Then Revision 17.

Progress (13 October 2026, about 22:15):
- The independent review (one read-only reader) found no fault in the
  rule and seven small points; five acted on by `r16/review_fix.py` and
  `r16/label_fix.py`: `docs/COURSE_EDITOR.md` line 214; one wording
  "Flashcard has no usage sentence." for both kinds of card; the Read
  aloud field's Help (in-form and EN/IT/ES) names the note; the in-form
  Help sentence "Match type / instruction" corrected; the note sentence
  moved under Checks in the audio_match pairs Help; the usage field's
  helper starts with "Recommended." (a phone may cut the label; a widget
  test cannot measure it because the test font is 1 em wide).
- Left for Revision 17: the Laboratory's GuideBook sentence "use exactly
  three pairs" (regenerate the Laboratory then).
- The new test file passed six times in a row before the review's
  corrections (15 cases). Running now: analyzer and nine focused files
  (`r16/analyze2.log`, `r16/focused2.log`).
- Then: the complete suite, `docs/272_VALIDATION.md`, the commit
  description (scratchpad `commit_272016.txt`) for the owner.

## Revision 17 (2.0.72+272017) READY, waiting for the owner's go to commit: no Course comes with the app; a start page

STATE (14 October 2026, about 01:00): complete in the working tree and NOT
committed. Analyzer clean; complete suite once on the final tree: 4,675
passed, 1 skipped, 0 failed (35 min 49 s). The commit description is in the
session scratchpad (`commit_272017.txt`) and was shown to the owner. On his
go: `git add` the modified files and the five new ones (never
`devtools_options.yaml` or `tools/cloud_setup.sh`), commit with that
description, push `build-272`, update the memory note, then ask his go for
the merge of Build 272 into `main` (never push `main` or open a PR without
it).

Started 13 October 2026 (late evening), after Revision 16's commit
`b440745d` (pushed). The last revision of Build 272.

### What the owner decided (13 October 2026)

1. "Take it out of the course [the app] but leave it in the repo like the
   Edge Case Course": an importable custom file in `demo_courses/` and a
   test fixture registered through `CourseService.debugExtraAssets`.
2. Fill with an example, OPTION 1: the Laboratory's file stays inside the
   app only as the source of the examples (`PresetExamples`); it is not a
   Course anyone can open, list, study, inspect or fork.
3. The learner's page with no Course: a start page with **Import a
   Course** and **New Course**, with "some more words in order to be clear
   as to: 1. how to use import and new course, 2. how to activate QQL
   Editor in order to create or edit a course, 3. where courses could be
   found so to import them. Use some autogenerated graphics too." It must
   NOT mention the Lab Course or the Edge Case Course: where Courses come
   from = a file someone gives you (a friend, a teacher, your Team, a
   publisher) and how to import it.
4. "Update the App Info to say there are no bundled courses currently but
   courses can be created or imported" (EN/IT/ES).
5. At Revision 16's go: "In the next revision also rename the Lab course
   to QQL Test: En-It Exercise Lab, and rename the Edge Course to QQL
   Test: It-En Edge Case Course".
6. The folder `demo_courses` keeps its name ("Forget about renaming the
   folder for now").

### Carried over from Revisions 15 and 16

- The Laboratory's own GuideBook (Match Lesson) says these presets "use
  exactly three pairs": correct it in the generator
  (`tools/generate_exercise_laboratory_254.py`, about line 710) when the
  Laboratory is regenerated.
- "The bundled demo courses" in App Info
  (`appInfo.courseContentAndAi.body`, EN/IT/ES) and "The bundled courses
  titled QQL Demo" / the Course authors cards on the credits page.
- `owner_review_259_revision7_test` and `import_side_doors_270_test` read
  the Laboratory's file by path (it stays at
  `assets/courses/exercise_laboratory_en_it.json`, so nothing to do).

### Plan

A. App:
   - `CourseService.courseAssets`, `bundledCourseIds`, the labels: empty.
     The Laboratory's ID `course_50d68435-d2c2-4b63-9a0b-b23161357f1d`
     stays reserved in `CourseEditorService`. The machinery for bundled
     Courses stays (the owner said "currently"), exercised by the test
     fixtures.
   - `PresetExamples.loadBundled` reads the asset
     `assets/courses/exercise_laboratory_en_it.json` itself (with
     `rootBundle.load` + `utf8.decode`, never `loadString`: the file is
     far over 50 KB), not through the registry.
   - Every `'IT'` default (`home_screen.dart` `_selectedLanguage`,
     `_selectedCourseRef`, `getLastSelectedCourseCode() ?? 'IT'`;
     `LearnerStatusController` line 95; `loadItalianCourse`): check what
     each does with an empty registry.
   - Home's page for no playable Course (`_libraryEmpty`, today "My
     courses" with All Courses and Course Studio) becomes the start page
     of point 3. Explanations in the Help Language (EN/IT/ES) through the
     Help catalogs, like the Welcome Wizard; button names in English.
     Graphics: QQL's own pictures (mascots, pictures of the image library)
     and Material icons, no new asset unless needed.
   - Screens that list bundled Courses with none: All Courses / Course
     Library "Bundled Courses" section, Course Studio, the Course selector,
     Gamification's Last Week XP by course, Statistics.
   - App Info and the credits page.
B. Content: rename in the two generators, regenerate (the Laboratory's
   asset, its v11 fixture, the future fixture, the coverage document; the
   Edge Case fixture, its v11 fixture, `demo_courses/edge_case_it_en.json`)
   and write the new importable `demo_courses/exercise_laboratory_en_it.json`
   (custom, its own Course ID, the made-up QuisquisLingo profile as
   Maintainer, as the Edge Case importable).
C. Tests: `registerLaboratoryFixture()` (code `IT`, the asset path) in
   `test/support/`; decide between registering it for every test in
   `test/flutter_test_config.dart` and per file; a new test file for the
   app with no Course at all; titles and file names that change with the
   renames.
D. Documents, version 272017, independent review, complete suite, the
   commit description for the owner, then the owner's go for the merge of
   Build 272 into `main`.

Scripts in the session scratchpad `r17/`.

### Progress (13 October 2026, about 23:00)

Done in the working tree, nothing committed:

- Generators patched and run (`r17/gen_patch.py`): titles **QQL Test: En-It
  Exercise Lab** and **QQL Test: It-En Edge Case Course**; the Match
  Lesson's overview no longer says "exactly three pairs"; new output
  `demo_courses/exercise_laboratory_en_it.json` (custom, Course ID
  `course_5df44010-fd64-4c81-a2c8-deb49207f980`, the made-up Maintainer
  `afb065f8-701c-48d2-85f7-c80d44abecb9` of the Edge Case importable). Both
  `--check` pass. The v11 fixtures are left as they are (the parity test
  compares IDs and exercises, never titles or GuideBook text; the Edge
  Case v11 fixture's title was never kept in step either).
- App (`r17/lib_patch1.py`, `r17/lib_patch2.py`):
  `CourseService.courseAssets` and `bundledCourseIds` empty,
  `laboratoryAsset` constant, `targetLabels` / `sourceLabels` /
  `loadItalianCourse` removed; `PresetExamples.loadBundled` reads the asset
  itself (`rootBundle.load` + `utf8.decode`); `LearnerStatusController`
  falls back to the first bundled code or none; Home's `'IT'` defaults are
  `''`; `CourseStartPage` (`lib/screens/course_start_page.dart`, text in
  `lib/localization/start_page_text.dart` EN/IT/ES) replaces Home's empty
  page; Home's `_importCourse`, `_newCourseFromStart`,
  `_openCourseStudioFromStart`, `_openSettingsFromStart`,
  `_emptyLibraryWaitingCourses`. `flutter analyze lib`: no issues.

Decided while working:

- Tests: the Laboratory is registered for every test in
  `test/flutter_test_config.dart` (code `IT`, read through `rootBundle` as
  before), so the 90 test files that use it stay as they are; a new test
  file removes it and tests the app as it ships, with no Course. To be
  said plainly to the owner.
- Start page pictures: QQL's own (mascot `cat_reading`, library pictures
  friends, headteacher_woman, bookshop, folder, smartphone, pencil) and a
  small drawing of "Version and Build × 10". No new asset.

### Progress (13 October 2026, about 23:20)

Also done in the working tree, nothing committed:

- Wording EN/IT/ES (`r17/text_patch.py`): App Info, All Courses Help, the
  Editor Help's Fill with an example sentence, the Welcome Wizard's step 2,
  the credits page (no Course authors section).
- Found while reading my own change: with no Course and nobody logged in
  (Log out, Ask who is learning) Home never started the learner chooser,
  because `_showInitialLearnerFlow` was started only from the learner page,
  which needs a Course. The start page now starts it too. A first run is
  covered by `main.dart`'s profile gate.
- Tests: `test/support/laboratory_fixture.dart`; the Laboratory registered
  in `test/flutter_test_config.dart`; `CourseService.debugExtraCourseIds`
  behind the `bundledCourseIds` getter; sixteen test files loop over
  `bundledAssets` (`r17/tests_patch1.py`, `tests_patch2.py`);
  `test/no_bundled_course_272_r17_test.dart` (23 cases, pass); a first-run
  case in `startup_profile_gate_test` (pass); a batch of 21 older files:
  196 passed, 1 failed (an export file name that follows the Edge Case
  title, corrected).
- Documents: CHANGELOG, README, change summary (`r17/docs_r17.py`), the
  AGENTS bullet (`r17/agents_r17.py`). `flutter analyze`: no issues.
- The start page was rendered to PNG with the app's fonts
  (`r17/start_en.png`, `start_it.png`, `start_es_dark.png`) and sent to the
  owner. The throwaway test that made them is deleted.

### Progress (13 October 2026, about 23:55)

- The new widget cases six times in a row: 31 passed each time (before
  the review's corrections).
- The independent read-only review came back (about 23 minutes): no
  crash, wait or loss of data; it confirmed the logged-out fix was needed
  (a learner with an Access PIN and no Course would have been stuck). Its
  findings and what was done are in `docs/272_CHANGE_SUMMARY.md` ("What
  the independent review found"). Corrections made
  (`r17/fix1.py`, `fix2.py`, edits of the start page and its catalog,
  the generators, `docs_r17b.py`, `agents_r17.py`):
  - reset explanations, App Info (two keys), Editor Help
    (`coursesInLearnerMode`), README's list, the unlock message
    ("Version and Build");
  - `docs/LOCALIZATION_CURRENT_STATE.md` brought up to date (section 6.10);
  - the importable Edge Case Course is Course version 2 (a device with
    version 1 can take the renamed file as an update);
  - the start page says first when the device already holds Courses the
    learner could add (`addableCourses`, `_emptyLibraryAddableCourses`);
  - Italian and Spanish slips; Study now only when there is a Course to
    switch to; the example loader logs a failure again; step numbers do
    not grow out of their circles; nobody logged in is told nothing about
    Courses.
  - `test/no_bundled_course_272_r17_test.dart` is now 28 cases (a real
    import through Quick Import with the pop-up on, the shared-device case
    through All Courses, the Edge Case update, text twice as large in the
    dark theme, Settings pages without a Course); four older test names
    corrected.
- The batch of 20 test files: 479 passed, 0 failed.

### Progress (14 October 2026, about 00:20)

- The second read-only review (of the corrections) came back: no fault
  in the counts or the logic; five small leftovers and weak test checks,
  all acted on (`r17/fix3.py`, the test file, `agents_fix.py`,
  `docs_r17c.py`): the Matching Course ID dialog's "tap Version" line,
  "another learner made or imported it" (false for a Course the learner
  took out of their own courses), two Help sentences, "only Cancel"
  (Fork is offered too with Course Studio on), and the tests (the Edge
  Case update test writes out the earlier identity; two tests name the
  error they expect; the Settings pages test waits for a text of each
  page; the 360-pixel tests lay out both forms of the page).
- The work ran past midnight: the release day is 14 October 2026 and the
  Beta expiry 2026-11-13 (`r17/expiry.py`: the service, every date of
  `test/beta_lifecycle_test.dart`, README, CHANGELOG, the AGENTS bullet).
- `test/no_bundled_course_272_r17_test.dart`: 28 cases; with the first-run
  file six times in a row: 36 passed each time.
- `docs/272_VALIDATION.md` has its Revision 17 section (the suite line is
  still `SUITELINE`), the commit description is in the scratchpad
  (`commit_272017.txt`, with `SUITELINE`).
- `flutter analyze`: no issues. The complete suite was started at about
  00:18 (`r17/suite_r17.log`, read it with `suite_summary.py`).

**To tell the owner first:** the start page is translated EN/IT/ES, and
his rule of 12 October (Build 271 Revision 5) says nothing else is
translated until the localization project. It was my choice (the page is
explanation, like the Welcome Wizard before it). English alone is a
one-line change.

Still to do: read the suite's result and write it into the validation
document and the commit description; show the owner the commit
description; commit on the owner's go (never stage `devtools_options.yaml`
or `tools/cloud_setup.sh`; the five new files to add are
`demo_courses/exercise_laboratory_en_it.json`,
`lib/localization/start_page_text.dart`,
`lib/screens/course_start_page.dart`,
`test/no_bundled_course_272_r17_test.dart`,
`test/support/laboratory_fixture.dart`), push `build-272`, memory; then
ask the go for the merge of Build 272 into `main`.

Also to tell the owner: the import pop-up lists "no Rights Holder" for the
two test Courses (nobody invented); the Bundled Courses section of All
Courses stays, empty; the tests still run with the Laboratory as a bundled
test Course; export file names follow the new titles; the page names no
place where Courses are found (a neutral pointer waits for his sentence);
a former Laboratory learner sees the Course's ID in Last Week XP by course
and the first Status colour on Profile until they have a Course again.

## After Revision 14: owner decisions of 13 October 2026 (evening), not started

Asked which Rights Holder the Demo Courses should name, the owner instead
decided what happens to the Demos themselves:

- **Revision 15: QQL Demo: English from Italian leaves the repository**,
  "like viterbese and piedmontese" (Build 262 Revision 0 is the model): the
  bundled JSON, its generator `tools/generate_english_from_italian_260.py`
  (and `tools/qql_v11_builders.py` if nothing else uses it), its own tests
  and fixtures move to the owner's private folder
  `D:\QQL_plus\Corsi_Privati` (outside the repository, never commit
  them); `CourseService.courseAssets` loses `EN_IT`; its Course ID stays
  reserved in `CourseEditorService`; `tools/validate_courses.py` and the
  tests that list the bundled Courses follow.
- **Revision 16: the Lab leaves the app and stays in the repository "like
  the Edge Case Course"** (an importable file in `demo_courses/` and a test
  fixture registered through `CourseService.debugExtraAssets`): the app
  ships with NO bundled Course.
  - "Fill with an example": owner chose option 1. The Lab's file stays
    inside the app only as the source of those examples (`PresetExamples`);
    it is not a Course anyone can open, list, study, inspect or fork.
  - The learner's page with no Course: an empty state with **Import a
    Course** and **New Course**, and, in the owner's words, "some more
    words in order to be clear as to: 1. how to use import and new course,
    2. how to activate QQL Editor in order to create or edit a course,
    3. where courses could be found so to import them. Use some
    autogenerated graphics too."
  - "Update the App Info to say there are no bundled courses currently but
    courses can be created or imported" (EN/IT/ES).
  - Owner, same evening: on that page **do not mention the Lab course and
    the Edge course**. "Where Courses can be found" says only that a Course
    is a file someone gives you (a friend, a teacher, your Team, a
    publisher) and how to import it.
  - Home defaults to the Course code `IT` today
    (`home_screen.dart`: `_selectedLanguage`, `_selectedCourseRef`,
    `getLastSelectedCourseCode() ?? 'IT'`): that default goes.
  - The Lab's Course ID stays reserved; progress on it is listed by the
    Inventory ("Progress on Courses no longer on this device").
- With no Course shipped, the Rights Holder of the Demos matters only for
  the files in `demo_courses/` (the owner has not named one; a Rights
  Holder is a person or a legal body, never the app: explained to the
  owner, who answered by removing the Demos from the app).

## Decisions for Revision 14

Owner decisions of 13 October 2026 ("Discuss", then numbered answers):

1. New Course and the Course Wizard name a Rights Holder by default: the
   AUTHOR named in the form, not the app's creator name ("someone could
   create a course using someone else's material, or use a nickname in
   the app and another name as author").
2. A Course Audit Warning for a license without a Rights Holder is
   enough: the forms do not refuse.
3. Export as Publisher Course refuses a Course without a Rights Holder
   (it already refuses one without a license).
4. CC0 1.0 is exempt (`CourseCredits.rightsGivenUp`).
5. Courses already stored are never changed automatically: "let's audit
   them one by one". Ask the owner what the bundled QQL Demos should
   name (their generators write the Course files).

The rule belongs in `CourseCredits` (Revision 1's rule: the three
screens never differ on a credits or licence rule). It changes what New
Course writes: a revision of its own, with its suite.

## After that (not started)

Owner decision of 13 October 2026 (evening, "Yes, leave them for later"):
the plan's two remaining free moves are NOT part of Build 272. They go to
Build 273: Home's `LearnerRoundPath` with its painters and
`_LessonSection` (blocked by the shared private helpers
`_learnerMascotSeed` and `_learnerPageBackgroundOf`: they need a public
home first), and the Course preview (a `part` of `home_screen.dart`
because it uses six Home privates).

Owner decision of 13 October 2026 (about 19:30, "Agreed" to my
recommendation, after reporting that the Audit still warns that Audio
Match needs exactly 3 pairs): Build 274's planned Revision 1 ("two
recommendations stop being Warnings", `docs/274_PLAN.md`) is brought
forward into Build 272 as a revision of its own, right after Revision 15:
- `AUDIO_MATCH_PAIR_COUNT` and `MATCH_PAIR_COUNT`: Info, and only outside
  2 to 5 pairs (the owner's words: "fewer than 2", or large numbers: 1
  pair, or 6 and more); the Listen and match form's label "Sound matches
  (2 to 5)", the same wording for Match by meaning;
- `FLASHCARD_EXAMPLE_EMPTY` Info for both kinds of card (a Picture
  flashcard gets it too), the form's field "Usage sentence and optional
  translation (recommended)"; `FLASHCARD_AUDIO_EMPTY` Info;
- Help EN/IT/ES, the registry counts the tests pin. When it is delivered,
  mark Revision 1 of `docs/274_PLAN.md` as done in Build 272.

So Build 272 ends with Revision 17: Revision 15 (English from Italian
leaves the repository), Revision 16 (the two recommendations stop being
Warnings), Revision 17 (the Lab leaves the app; the start page with no
Course; App Info), then the owner's go for the merge into `main`.

Tests that read screen source as text (they need care when code moves, in
Revisions 1 and 2): `course_editor_layout_regression_test`,
`course_metadata_ui_v9_test`, `qql_233_revision_platform_contract_test`,
`unified_learner_layout_regression_test`.
