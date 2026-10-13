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

## Next: Revision 14, a license names its Rights Holder (not started)

Owner decisions of 13 October 2026 ("Discuss", then numbered answers):

1. New Course and the Course Wizard name a Rights Holder by default: the
   AUTHOR named in the form, not the app's creator name ("someone could
   create a course using someone else's material, or use a nickname in
   the app and another name as author").
2. A Course Audit Warning for a license without a Rights Holder is
   enough: the forms do not refuse.
3. Export as Publisher Course refuses a Course without a Rights Holder
   (it already refuses one without a license).
4. CC0 1.0 is exempt (`CourseImportCheck.rightsGivenUp`).
5. Courses already stored are never changed automatically: "let's audit
   them one by one". Ask the owner what the bundled QQL Demos should
   name (their generators write the Course files).

The rule belongs in `CourseCredits` (Revision 1's rule: the three
screens never differ on a credits or licence rule). It changes what New
Course writes: a revision of its own, with its suite.

## After that (not started)

From the plan's free moves: Home's `LearnerRoundPath` with its painters
and `_LessonSection` (blocked by the shared private helpers
`_learnerMascotSeed` and `_learnerPageBackgroundOf`: they need a public
home first), the Course preview (a `part` of `home_screen.dart` because
it uses six Home privates). Then the Build's end: the owner's go for
the merge into `main`.

Tests that read screen source as text (they need care when code moves, in
Revisions 1 and 2): `course_editor_layout_regression_test`,
`course_metadata_ui_v9_test`, `qql_233_revision_platform_contract_test`,
`unified_learner_layout_regression_test`.
