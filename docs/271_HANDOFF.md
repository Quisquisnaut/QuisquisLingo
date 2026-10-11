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
| 3 | Speed: one Audit per change, one read of the stored Courses per save, image search keys |
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
1 skipped (12:17–13:07, 11 October 2026). Committed on `build-271` and the
branch pushed. Next: Revision 2 (the Audio Library like the Image Library;
the Course Editor's top bar), which starts with mock-ups for the owner.

What was done (details in `docs/271_CHANGE_SUMMARY.md`):

- `CourseLibraryOperations.previewDelete` / `deleteCourse(resetMyProgress:,
  deleteBackups:)`, `CourseDeletePreview`, `CourseDeleteResult`, texts in
  `CourseLibraryReports`; Course Studio's `_delete` and `_deletePreview`.
- `CourseBackupService`: a damaged stored file is a gap (logged through the
  `log` seam); `summaryOf`, `deleteAllBackups`, `keepUnreadableCopy`.
- `CourseEditorService._keepUnreadableOrSkip` in the Publisher update over a
  source this version cannot open.
- `CourseFileStore.removeLeftoverTemporaryFiles` (called in `main()`),
  `syncDirectory` / `flushDirectory`.
- Inventory: `InventorySection.groups`, `deleteCourseMediaFolder`.
- Help EN/IT/ES; `docs/240_REMOVE_UNUSED_MEDIA_PLAN.md` superseded;
  `docs/MEDIA_LIBRARIES_PLAN.md`, `docs/239_RESET_STORAGE_INVENTORY.md`.
- Tests: `test/deleting_a_course_271_test.dart` (17), two cases in
  `course_manager_workflow_249_test`.

Decisions taken while working (say so in the report):

- "Also delete all its backups" deletes the Course's whole backup folder,
  also files this version cannot read (earlier formats, a kept unreadable
  copy): they are its backups too, and a folder left with only those would
  have no Course to belong to.
- The warning about other learners uses the theme's error container (red
  tint); the mock-up showed amber, which the app's theme has no colour for.
- The first dialog opens at once and fills in the learners and backups when
  they are read ("Looking for its backups…" meanwhile).
- The folder flush on Linux and macOS runs the system's `sync` on the
  folder. Dart cannot flush a folder itself; calling the system library
  directly could not be tried on this PC and a mistake there would crash the
  app, so the safer route was taken. Not run on Linux or macOS.
- A kept unreadable Publisher copy does not include its media.
- The Inventory's own Delete of a Course and the removal of a Course this
  version cannot open were left as they are (no extras there).

Gotchas:

- In tests a learner with an Access PIN cannot be made active again without
  it (Build 270 Revision 1): set the PIN only in the tests that need it.
- A Bash heredoc with apostrophes in a long Python script fails ("unexpected
  EOF"): write the script and any Dart text with the Write tool.
- `test/flutter_test_config.dart` turns `CourseFileStore.syncDirectory` off
  for the whole suite; on Linux no test starts `sync`.
