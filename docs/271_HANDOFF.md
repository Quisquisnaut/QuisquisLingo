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
| 1 | Deleting a Course (other learners named, reset my progress, delete its backups); saves never blocked by a backup; `*.tmp` cleanup; Publisher update over an unreadable copy keeps a backup |
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
`build-271` and the branch pushed. Next: Revision 1 (deleting a Course;
saves never blocked by a backup).

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
