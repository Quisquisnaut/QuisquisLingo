# Build 271 handoff

Started 11 October 2026 on the branch `build-271` in the main checkout
`C:\QQL\QuisquisLingo` (from `main` at `bf8ef693`, pushed). Plan and owner
decisions: `docs/271_PLAN.md`. Git rule: one branch per Build; after each
revision's commit push the branch (`git push -u origin build-271`, standing
permission, a backup, no pull request); merge into `main` and push `main`
only on the owner's go. Summary: `docs/271_CHANGE_SUMMARY.md`; evidence:
`docs/271_VALIDATION.md`.

Never stage `devtools_options.yaml`, `tools/cloud_setup.sh`.

## Plan

| Revision | Scope |
|---|---|
| 0 | Content that plays wrong: Missing letters audio optional, Put the sentences in order marked as lines, the Audit flow copies the Round |
| 1 | Deleting a Course (other learners named, reset my progress, delete its backups); saves never blocked by a backup; `*.tmp` cleanup; Publisher update over an unreadable copy keeps a backup; Inventory Delete all (added 11 October) |
| 2 | The Audio Library like the Image Library; the Course Editor's top bar; Image Library Help into the Editor Help (mock-ups first: owner rule) |
| 3 | Speed: a save that is faster and shows where it is (done first, owner report of 12 October); then one Audit per change, Lesson and Round Audits, image search keys (follow-up, same version) |
| 4 | Import and Android file safety |
| 5 | Tidy-ups (labels never translated, Cyrillic order, mascot after the frame, test seams, Course Info controllers) |

Owner rules for this Build: at most three icons in a top bar; show a
mock-up before a screen changes; labels are never translated.

## Revision 0 (2.0.71+271000), content that plays wrong

State: done. Version 2.0.71+271000 (Beta expiry 2026-11-10 23:59:59,
unchanged: same release day as Build 270 Revisions 12 and 13). New tests 16
passed; related files 253 + 280 passed; analyzer clean; complete suite
4,175 passed, 1 skipped (10:03–10:44, 11 October 2026). Committed on
`build-271` as `1cb6f969` and the branch pushed.

What was done (details in `docs/271_CHANGE_SUMMARY.md`):

- `PresetVariants.withSaveMarks` (Missing letters: audio `required: false`;
  Put the sentences in order: item text role `line`), applied by `_shape`;
  `PresetRecipes.represents` compares with the marks on both sides.
- `ExerciseFeatures.isLineOrder` reads the mark, then guesses; `kind` is
  `inputListenGaps` only for required automatic audio.
- `RoundScreen._gapAudioSilent`: no automatic audio and no Play audio (body
  and top bar) for typed gaps with optional audio while the learner's audio
  is off.
- `ElementRoles`: item role `line`.
- `CourseHierarchyUpdateService.roundWithContent`, used by
  `CourseEditorScreen._openAuditIssue`.
- Laboratory generator, bundled JSON, coverage document, future fixture and
  v11 fixture regenerated.
- Help EN/IT/ES, the form's Spoken text helper, `docs/COURSE_JSON_FORMAT.md`,
  `docs/EXERCISE_ARCHITECTURE_V12.md`.
- Tests: `test/content_plays_right_271_test.dart` (16); the Laboratory
  presentation baseline's `missing_letters_audio` record (instruction only).

Decisions taken while working (not in the plan's text; say so in the report):

- The line under the title of a Missing letters with a spoken text is now
  "Write the missing letters." also with audio on. Keeping "Fill in the
  missing word you hear." would have been wrong without sound, and it named
  a word where letters are asked.
- With audio off the Play audio button is hidden, not greyed (a greyed
  button made a text exercise look like a listening one: Build 259
  Revision 1).
- An exercise stored before this version still opens in its preset's form,
  and saving it there writes the new shape. Without this it would have
  opened in the canonical editor and lost its title.
- Only the Missing letters gap screen got the "silent while audio is off"
  rule. A Flashcard whose read-aloud is automatic still tries to speak with
  audio off, as before (not in this revision's scope; worth a look in
  Revision 5).

Gotchas:

- The v11 Laboratory fixture is not written by the generator: write it from
  `course_v11(laboratory())` and add `officialChecksum` = SHA-256 of the
  sorted compact JSON without `publisherVerificationStatus` (the recipe in
  `docs/259_HANDOFF.md` omitted that last key).
- A Bash heredoc turns `\\n` into `\n` inside a Python script: write edit
  scripts with the Write tool.
- `exercise_laboratory_254_test` "learner completes
  qql_lab254_reading_dialogue_automatic" failed once in a batch run with
  two test processes (the two dialogue lines recorded in the wrong order);
  alone and in the complete suite it passes.
- The owner's private Piedmontese generators (outside the repository) use
  both exercise types and still write the earlier shape: their Missing
  letters with a spoken text stays an audio exercise until they pass
  `required=False`, and their Put the sentences in order items stay
  unmarked until they pass the role `line`. Not touched.
- The complete suite ran with 1.2 GB free (two browsers open) and took
  41 minutes instead of 35; it did not run out of memory this time.

## Owner decisions of 11 October 2026 (after Revision 0)

- The "Remove unused media" idea (`docs/240_REMOVE_UNUSED_MEDIA_PLAN.md`) was
  examined and closed: the plan is marked superseded and is not to be built.
  One gap was real and goes into Revision 1: the Inventory deleted the media
  of a Course no longer on the device one file and one PIN at a time.
- A mock-up of the two Delete dialogs, the message afterwards and the
  Inventory row was shown in the chat before they were built (owner rule).

## Revision 1 (2.0.71+271001), deleting a Course; saves never blocked

State: done. Version 2.0.71+271001 (Beta expiry 2026-11-10 23:59:59,
unchanged: same release day). New tests 17 passed plus two Course Studio
cases; related files 274 passed; analyzer clean; complete suite 4,194 passed,
1 skipped (12:17–13:07, 11 October 2026). Committed on `build-271` as
`6e54e7ff` and the branch pushed. A follow-up in the same version came
next (see below).

What was done (details in `docs/271_CHANGE_SUMMARY.md`):

- `CourseLibraryOperations.previewDelete` / `deleteCourse(resetMyProgress:,
  deleteBackups:)`, `CourseDeletePreview`, `CourseDeleteResult`, texts in
  `CourseLibraryReports`; Course Studio's `_delete` and `_deletePreview`.
- `CourseBackupService`: a damaged stored file is a gap (logged through the
  `log` seam); `summaryOf`, `deleteAllBackups`.
- `CourseFileStore.removeLeftoverTemporaryFiles` (called in `main()`),
  `syncDirectory` / `flushDirectory`.
- Inventory: `InventorySection.groups`, `deleteCourseMediaFolder`.
- Help EN/IT/ES; `docs/240_REMOVE_UNUSED_MEDIA_PLAN.md` superseded;
  `docs/MEDIA_LIBRARIES_PLAN.md`, `docs/239_RESET_STORAGE_INVENTORY.md`.
- Tests: `test/deleting_a_course_271_test.dart` (17), two cases in
  `course_manager_workflow_249_test`.

Decisions taken while working (say so in the report):

- "Also delete all its backups" deletes the Course's whole backup folder,
  also files this version cannot read (earlier formats): they are its
  backups too, and a folder left with only those would have no Course to
  belong to.
- The warning about other learners uses the theme's error container (red
  tint); the mock-up showed amber, which the app's theme has no colour for.
- The first dialog opens at once and fills in the learners and backups when
  they are read ("Looking for its backups…" meanwhile).
- The folder flush on Linux and macOS runs the system's `sync` on the
  folder. Dart cannot flush a folder itself; calling the system library
  directly could not be tried on this PC and a mistake there would crash the
  app, so the safer route was taken. Not run on Linux or macOS.

Gotchas:

- In tests a learner with an Access PIN cannot be made active again without
  it (Build 270 Revision 1): set the PIN only in the tests that need it.
- A Bash heredoc with apostrophes in a long Python script fails ("unexpected
  EOF"): write the script and any Dart text with the Write tool.
- `test/flutter_test_config.dart` turns `CourseFileStore.syncDirectory` off
  for the whole suite; on Linux no test starts `sync`.

## Revision 1 follow-up (same version 2.0.71+271001)

Owner decisions of 11 October 2026, after the Revision 1 report:

- The Inventory's Delete on a Course and the removal of a Course this
  version cannot open offer to delete the backups too.
- The Inventory's Delete on a Course lists the learners who have it, says
  who removed it but kept their progress, and can reset everyone's progress.
- Remove Publisher Course from device (Inventory): warn that learners may
  want their progress for a reinstallation, but allow the reset when the
  admin confirms.
- The kept unreadable Publisher copy is removed.

State: done. Related files 243 passed; analyzer clean; complete suite
4,205 passed, 1 skipped (14:32–15:31, 11 October 2026). Committed on
`build-271` as `daffb9a5` and the branch pushed. Revision 1's first commit
is `6e54e7ff`. A second follow-up came next (see below).

What was done (details in `docs/271_CHANGE_SUMMARY.md`, "Follow-up"):

- `ProgressService.resetCourseForProfile`, `hasCourseProgress`.
- `lib/services/course_learners.dart` (`CourseLearnersService`).
- `InventoryActionService.previewCourse`, `run(resetEveryonesProgress:,
  deleteBackups:)`, `InventoryCoursePreview`; the Inventory screen's Course
  dialog (`_CourseExtras`, `_confirmReset`).
- `CourseLibraryOperations.backupsOf`, `removeUnopenableCourse`; Course
  Studio's `_removeUnopenable`.
- Removed: `CourseBackupService.keepUnreadableCopy`,
  `CourseEditorService._keepUnreadableOrSkip`.
- Help EN/IT/ES, CHANGELOG, README, AGENTS, the plan, the storage inventory
  document.

Decisions taken while working (say so in the report):

- Remove Publisher Course from device is still refused while another
  learner has the Course in their courses. The owner asked for the reset to
  be allowed with a warning, not for that rule to go, so it stays; ask if it
  should be lifted for the Inventory.
- Ticking "reset everyone's progress" is confirmed in a second dialog
  ("Confirm progress reset"), as Remove from my courses does for its reset.
- Course Studio's Delete still resets only the deleting learner's progress.

Gotchas:

- `pumpUntilFileIoState` keeps pumping while frames are scheduled; a
  SnackBar shown after a dialog can be gone (4 seconds of test time) before
  it returns. Look for the message in a loop of your own.
- A Bash heredoc drops the backslash of `\'` in Dart text: use the Write
  or Edit tool for Dart strings with an apostrophe.

## Revision 1 second follow-up (same version 2.0.71+271001)

Owner's rule of 11 October 2026: "the admin can clean up anything if
necessary, whatever the problem is, but has to be warned when destructive
actions can have undesired effects." For a Delete that was refused: double
confirmation, the word DELETE, and the PIN. Also asked: the texts say where
the admin resets the learners' progress; and, since progress could not be
reset once a Course was gone, the Inventory lists and resets it (asked and
confirmed in the chat, with the override for another learner's custom
Course).

State: done. Related files 244 passed; analyzer clean; complete suite
4,213 passed, 1 skipped (16:46–17:32, 11 October 2026). Committed on
`build-271` and the branch pushed (the first follow-up is `daffb9a5`).
Next: Revision 2 (the Audio Library like the Image Library; the Course
Editor's top bar), which starts with mock-ups for the owner.

What was done (details in `docs/271_CHANGE_SUMMARY.md`, "Second follow-up"):

- `InventoryActionService.run(adminOverride:, typedWord:)`, `overrideWord`;
  `CourseEditorService.removePublisherCourseFromDevice(evenIfOthersHaveIt:)`,
  `deleteUserCourse(adminOverride:)`, `mayDeleteUserCourse`.
- `InventoryCoursePreview`: `notYours`, `maintainerName`, `needsOverride`,
  `overrideWarning`, `overrideTitle`, `overrideQuestion`, `overrideButton`.
- The Inventory dialog: the warning, the DELETE field, `_confirmOverride`.
- Inventory section "Progress on Courses no longer on this device",
  `InventoryActionKind.resetCourseProgress`,
  `CourseLearnersService.leftProgress`,
  `ProgressService.courseIdsWithProgress`, `CourseService.bundledCourseIds`.
- Help EN/IT/ES, CHANGELOG, README, AGENTS, the plan, the storage inventory
  document. Memory: the admin rule.

Decisions taken while working (say so in the report):

- The override exists only in the Inventory. Course Studio's Delete and
  Remove Publisher Course from device keep their refusals.
- The new section shows Course IDs, not titles: nothing of a deleted Course
  is left to read its title from.
- Deleting a learner keeps its two refusals (the only admin; a learner who
  maintains a Course). Not asked; by the owner's rule the second could get
  the same override, but it needs a decision about that learner's Courses.

Gotcha: `CourseService.bundledCourseIds` must change with `courseAssets`
(a test in `deleting_a_course_271_test` fails otherwise); without it the
Inventory would offer to reset progress on a bundled Course.

## Revision 2 (2.0.71+271002), the Audio Library like the Image Library

State: done and committed (11 October 2026). Version 2.0.71+271002, Beta expiry 2026-11-10 23:59:59. Analyzer clean; complete suite 4,243 passed, 1 skipped (48:19).

Plan: `docs/271_PLAN.md`, Revision 2. Mock-ups of the Audio Library,
Associate recording, Texts in this Course and the Course Editor's top bar
were shown in the chat on 11 October 2026; the owner answered "go on with
next revision".

What it holds (details in `docs/271_CHANGE_SUMMARY.md` and the `AGENTS.md`
release entry):

- Model: `CourseAudioClip.originalFileName` (`labelOf`, `withText`, strict
  parse); kept by copies, removed by Export as Publisher Course; documented
  in `docs/COURSE_JSON_FORMAT.md`.
- Pure Dart: `lib/services/audio_segmenter.dart` (the one matching rule,
  `coverage`), `lib/services/course_audio_texts.dart` (the texts, their
  states, the filter, the export).
- Screens: the Audio Library and `_AssociateRecordingDialog` in
  `lib/screens/course_editor_screen.dart`; `lib/screens/audio_texts_screen.dart`
  (new); `lib/widgets/library_save_notice.dart` (new, also in a Course's
  Image Library); the Course Editor's top bar (Save now icon; Show internal
  IDs in Course Info Editor).
- Help EN/IT/ES: Editor Help 90 questions (`textsToRecord`, `pictureBadges`
  new; the sound answers, `findPicture`, `addPictures`, `internalIds`,
  `workingCopy`, `leaveEditor`, `courseInfo` changed); the field Help of the
  audio fields (EN, IT); `ImageLibraryHelpScreen`, `imageLibraryHelp.*` and
  the QQL Guide entry removed.
- Documents: `docs/AUDIO_LIBRARY.md`, `docs/COURSE_EDITOR.md`.
- Tests: `test/audio_library_271_test.dart`,
  `test/course_editor_top_bar_271_test.dart`, and eleven existing files
  changed for the new layout (listed in `docs/271_VALIDATION.md`).

Decisions taken while building, for the owner to confirm or change:

1. Add to the Course and Check are greyed in On-Device TTS (tooltip says
   why), as their actions were hidden there before.
2. Under 420 pixels of body height the header scrolls with the list.
3. Apply in Associate recording is greyed while the text is empty.
4. The read-only Course Info page has no Show internal IDs switch.
5. Suggested, not built: the original file name in grey on a row without
   text.

What the first complete suite found (fixed before the second run): the new
360-pixel test tapped a row that the test font's wide letters push below the
window (it now opens the first row); the answer on adding recordings had lost
"derived from the stable Course ID" and "the metadata and references belong
to the Course", which `exercise_field_help_226_02_test` reads (restored in
EN/IT/ES).

Open, unchanged: the override for deleting a learner who maintains a Course
(the owner has to decide what happens to that learner's Courses).

Next: Revision 3, speed (`docs/271_PLAN.md`): the Course Editor's main page
audits once per change of the working copy; Lesson and Round Audits check
only their own part; a Course save reads the stored Courses once (measure
first); the image library search uses precomputed keys and a short pause.

## Revision 2 follow-up (same version 2.0.71+271002)

State: done and committed (11 October 2026, night), the branch pushed. Analyzer clean; complete suite 4,250 passed, 1 skipped (45:52).

Owner decisions and reports of 11 October 2026, after Revision 2
(`e594e6e3`):

1. **Decision**: the original file name in grey on a recording without text
   (`audio-clip-original-<id>`; a recording with a text shows none).
2. **Decision**: the admin may delete a learner who maintains Courses, with
   the warning, the word DELETE, a second confirmation and the PIN; "their
   courses will therefore be orphaned, but the same would happen if the
   maintainer left". In the Inventory only
   (`InventoryActionService.previewLearner`, `run(adminOverride:)`,
   `ProfileService.deleteProfileById(adminOverride:)`,
   `CourseMaintainerGuard.maintainedBy`). Profile's own Delete and the reset
   that removes non-admin learners still refuse and point to the Inventory.
   The last admin and the last Team Leader of a Team are still refused.
3. **Report**: after Save now the Editor still asked to confirm changes on
   exit. The owner's guess: Save only applied. Found: Save now writes (a test
   reads the stored file), but a save takes a moment and the Editor stayed in
   use meanwhile with no sign of it; Back in that moment asked "Unsaved
   course changes". Fix: `CourseEditorScreen._writeCourse` shows the modal
   `course-saving` for every save from the Editor. Not proven that this is
   what the owner saw: if the question still comes after "Saved as version
   N.", ask for the steps.
4. Found while looking at 3: four Apply buttons showed the disk icon of Save
   now. Apply now shows a check mark, Apply as draft the note with a pencil.
5. **Request**: the Lesson screen's tile reads "GuideBook", bold like Rounds.
6. **Report**: a learner deleted in the Inventory was still listed under
   Profile › Learner profiles ("Unknown learner profile" on a tap). Home's
   `_learners` is a copy; `_showLearners` now reads it afresh.
7. The owner first said to skip the complete suite for this follow-up, then
   to run it as usual at the end.

Open questions for the owner: none new. Still to confirm from Revision 2:
the two menus greyed in On-Device TTS, the header that scrolls in a very
short window, Apply greyed while the text is empty, no Show internal IDs
switch on the read-only Course Info page.

Next: Revision 3, speed (`docs/271_PLAN.md`).

## Revision 2 second follow-up (same version 2.0.71+271002)

State: done and committed (11 October 2026, night), the branch pushed. Analyzer clean; complete suite 4,254 passed, 1 skipped (57:49).

Owner decisions of 11 October 2026, after the first follow-up (`7b6638c0`):

1. "Last Team Leader too, with warnings": the admin may delete a learner
   who is the last Team Leader of a Team. Asked what becomes of the Team
   (a Team without a Team Leader is invalid data): the owner chose **the
   first other member leads**; a Team with nobody left is removed.
2. "The warning should come before the PIN, in all the cases where there are
   warnings and PIN requests. 1. Warnings, 2. PIN, 3. Type in DELETE."
   Applied to the Inventory (two dialogs) and to Wipe out everything (the
   words after the PIN). This is now a standing rule (AGENTS.md).
3. "Can Admin also delete a team": nobody could. Asked; the owner chose
   **yes, in the Inventory** (not for Team Leaders in the Team Manager), and
   added "but usual strong warning for such actions".

Where: `AuthoringTeam.isLastLead/successorOf/without`;
`ProfileService.deleteProfileById(adminOverride:)`, `teamsLedOnlyBy`;
`TeamService.deleteTeamAsAdmin`; `InventoryActionKind.deleteTeam`, the
Inventory's Teams section; `InventoryActionService.previewTeam`,
`InventoryLearnerPreview.teams`; `InventoryScreen._runAction` (dialogs
`inventory-action-dialog` then `inventory-action-pin-dialog`);
`DeviceAdministrationScreen._askPinAndRun` (`admin-nuke-phrase` under the
PIN).

Still refused, for everyone: deleting the only admin.

Open with the owner: the Save now report (is the save in progress what they
saw?); the four choices of Revision 2 (greyed menus in On-Device TTS, the
header that scrolls in a very short window, Apply greyed while empty, no
Show internal IDs switch on the read-only Course Info page).

Next: Revision 3, speed (`docs/271_PLAN.md`).

## Revision 3 (2.0.71+271003), a save is faster and shows where it is

State: done and committed (12 October 2026, early morning), the branch pushed. Analyzer clean; complete suite 4,273 passed, 1 skipped (56:04).

Owner report of 12 October 2026 (in Italian): "Il Save funziona ma è lento
e il tempo non viene segnalato." Taken as the first part of the plan's
Revision 3 (speed) and committed on its own; the plan's other items follow
as a follow-up in the same version.

What was found (measured, numbers in `docs/271_CHANGE_SUMMARY.md`):

1. The backup before each save read every picture and recording three
   times (stored file, backup copy, backup copy again) with a SHA-256 each.
2. `CourseFileStore._findUnlocked` read and decoded every stored Course;
   a save calls it three times, and once for the Publisher folder.
3. `listBackups` read every file of every version (also after each save
   when Course Info keeps a number of backups).

What was done:

- `CourseBackupService.createBackup(onProgress:)`: same name and same
  length in `QQL_media` means held, nothing read. `BackupMediaCheck`
  (content, presence, none); the listings use presence; `reinstateMedia`
  checks the SHA-256 of each copy before it puts it back.
- `CourseFileStore.leadingCourseId` and its use in `_findUnlocked`.
- `CourseSaveStep`, `CourseSaveProgress`; `onProgress` through
  `confirmCourseTransaction` and `CourseAuthoringSession.confirm`.
- `lib/widgets/course_saving.dart`: `CourseSaving.run`,
  `CourseSavingWindow`; used by `CourseEditorScreen._writeCourse` and
  `CourseWizardScreen._save`. The save starts when the window's frame is
  done or after `drawnWithin` (250 ms), whichever comes first.
- Help EN/IT/ES (`leaveEditor`, `backups`, `restore`).
- Tests: `test/save_speed_271_test.dart` (19).

Decisions taken while building (to tell the owner):

- The content of a backup's files is checked at restore, not at every save
  and every listing. A copy changed outside QQL with the same length is no
  longer rewritten by the next save; a restore finds it and says so.
- The bar has a value (steps and the count of files), not an endless
  animation: the widget tests' `pumpAndSettle` would never end with one.

Next: the Revision 3 follow-up (same version): the Course Editor's main
page audits once per change of the working copy (`AuthoringHierarchyStatus
.fromCourse(_course)` runs in `build`; 70 ms on the Laboratory); the Lesson,
Rounds and Round pages build a Course and audit it on every rebuild (the
Rounds page's `_auditableCourse` is a JSON round trip of the whole Course);
`auditLesson` / `auditRound` audit the whole Course and filter; image
library search keys and a short pause. Then Revision 4.

Open with the owner: unchanged from the second follow-up above.
