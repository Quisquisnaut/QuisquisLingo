# Build 271 change summary

Build 271 fixes the more relevant findings still open after Build 270 (the
audit `docs/270_AUDIT.md`, the side findings of the modularization audit
`docs/272_MODULARIZATION_PLAN.md` and two older findings, Build 259 C and E)
and reorganizes the Audio Library. Plan and owner decisions:
`docs/271_PLAN.md`.

## Revision 0 (2.0.71+271000): content that plays wrong

Owner decisions of 10 and 11 October 2026.

### Missing letters with a spoken text

Before: the form's **Spoken text (optional)** was stored as audio the
exercise needs (`required` absent, which means true). A learner with Audio
Exercises off never saw the exercise: it was skipped with the listening
exercises (Build 259 finding C).

Now:

- Saving stores the spoken text as an aid: the audio element carries
  `required: false`. Its `playback` stays `automatic`.
- With the learner's audio on, nothing changes in what is heard: the text is
  read aloud when the exercise opens and **Play audio** repeats it.
- With the learner's audio off, the exercise stays in the Round. Nothing
  plays, there is no Play audio button (in the exercise or in the top bar)
  and no "audio unavailable" message (`RoundScreen._gapAudioSilent`).
- The line under the title is **"Write the missing letters."** with or
  without a spoken text. Before, a spoken text made it "Fill in the missing
  word you hear.", which was wrong for letters and wrong without sound.
  `ExerciseFeatures.kind` is `inputListenGaps` only when the audio that
  plays by itself is required; with optional audio the kind is
  `inputComplete`.
- Listen and fill the gaps (the listening preset) keeps its required audio.

### Put the sentences in order

Before: whether an Arrange showed lines or words was guessed from the text
of its blocks (two or more blocks, each with three words or ending with
. ! ? …). Two short lines such as "Ciao Anna" and "Ciao Marco" showed the
title PUT THE SENTENCES IN ORDER over the line "Arrange the words in the
correct order." (Build 259 finding E).

Now:

- Saving marks every block as a line: the item's text element has the role
  `line`. `ExerciseFeatures.isLineOrder` reads the mark first; the guess
  from the text remains only for an exercise without it.
- `line` is in `ElementRoles` (item place), so the canonical editor's Role
  menu offers it and describes it.

### Exercises saved before this version

Owner decision: no handling of earlier exercises. Nothing is converted.

- A Missing letters stored with required audio is still an audio exercise
  and is still skipped without audio.
- A Put the sentences in order without the mark is still guessed from its
  text.
- Both still open in their preset's form and keep their title:
  `PresetVariants.withSaveMarks` is what saving adds that no form field
  shows, and `PresetRecipes.represents` compares with those marks on both
  sides. Saving such an exercise in its form stores the new shape.

### The Audit flow copies the Round

`CourseEditorScreen._openAuditIssue` rebuilt the Round field by field after
an exercise opened from an Audit finding was saved. A Round field added
later would have been dropped there without any test noticing. It now calls
`CourseHierarchyUpdateService.roundWithContent`, which copies the whole
Round and replaces only its content. Nothing changes on screen.

### Content

- `tools/generate_exercise_laboratory_254.py`: the `missing_letters_audio`
  example has optional audio; the two `sentence_order` examples carry the
  `line` role.
- Regenerated: `assets/courses/exercise_laboratory_en_it.json`,
  `docs/254_LABORATORY_COVERAGE.md`,
  `test/fixtures/v12/laboratory_future_en_it.json` and
  `test/fixtures/v11/exercise_laboratory_en_it.json`.
- QQL Demo: English from Italian has neither exercise type and is unchanged.

### Help

EN/IT/ES: the Missing letters answer says the spoken text is an aid and that
a learner with audio off gets the exercise without it; the Put the sentences
in order answer says a line may be as short as two words. The form's Spoken
text helper says the same.

### Not changed

Scoring, progression, Review, the Duel, learner data and the Course format
(roles are free strings; `required` already existed). No `minimumAppBuild`
is raised: an earlier app version plays both exercises as it did before.

## Revision 1 (2.0.71+271001): deleting a Course; saves never blocked

Owner decisions of 10 and 11 October 2026.

### Delete course

Before: Delete asked twice and removed the Course and its media. It said
nothing about other learners, kept the deleting learner's progress and
always kept the Course's backups, which then stayed in `Backups/Courses`
with no Course (on the owner's PC, five of nine backup folders).

Now, in Course Studio:

- **Other learners are named.** The first confirmation shows, when it
  applies, "Anna and Marco have this Course in their courses. Delete it
  anyway?" A learner counts when their Course list shows the Course
  (`CourseLibraryService.contains`: they added it, or have progress on it).
  A Private course is in nobody else's courses.
- **Two extras, both off:**
  - **Also reset my progress on this Course**: the reset of Remove from my
    courses (completed Rounds and Lessons, Laurels, Duels, GuideBooks read,
    recent Rounds). XP, Weekly XP, study days and streaks are kept. Only the
    deleting learner's progress; other learners keep theirs.
  - **Also delete all its backups**: the Course's whole backup folder, with
    the count and size shown ("12 saved versions in Backups/Courses
    (37 MB)"). Greyed with "It has no backups." when there are none.
- **The second confirmation lists what will go** (the Course, your progress
  on it, its N backups) and its button is red.
- **A message afterwards** says what was deleted, and what could not be
  ("Some of its backup files could not be deleted; they are still in
  Backups/Courses.").
- The Delete comes first: when it fails (rights, storage), nothing else
  changes. The two extras never undo a Delete that succeeded.

Code: `CourseLibraryOperations.previewDelete` and
`deleteCourse(resetMyProgress:, deleteBackups:)`,
`CourseBackupService.summaryOf` and `deleteAllBackups`, texts in
`CourseLibraryReports`.

### A backup never blocks a save

Every save of a custom Course first backs up the stored version. A stored
picture or recording whose bytes did not match its name made that backup
throw "Course media … does not match its reference", so no later save of the
Course could succeed, not even the one replacing the damaged file.

Now such a file is recorded as a gap (`missing: true`, `damaged: true`), as
a missing file already was, and the Diagnostic Log gets a line naming it.
The damaged bytes are not copied into the backup. Restoring that version
puts back everything else.

### The Course store after an interrupted save

- A save stages the Course in a temporary file and renames it. A crash in
  between left the temporary file for good. Start-up now removes them
  (`CourseFileStore.removeLeftoverTemporaryFiles`): only files with the
  staging name in the two Course folders, never one the running QQL made.
- On Linux and macOS a renamed file's new name is part of its folder, which
  the system writes later. After each rename QQL now asks the system to
  flush that folder (`sync <folder>`), so a power cut right after a save
  cannot bring the earlier version back. Windows needs nothing. This could
  not be run here (no Linux or macOS build on this PC); it is best effort
  and a failure changes nothing else.

### A Publisher update over a copy this version cannot open

Dropped in the same version (owner decision of 11 October 2026). Revision 1
first kept the stored record in the Course's backup folder before the
publisher's update replaced it. That file could not be used inside QQL
(Version History only named it as unreadable), came without its media and
held nothing of the user's, because a Publisher Course cannot be edited: its
own package is its copy. The update again replaces the stored copy without
keeping it, as since Build 266 Revision 2.

### Inventory: Delete all

The Inventory already deleted the media of a Course no longer on the device
one file at a time, asking the admin PIN for each. Above those files it now
shows one row per such folder with **Delete all** (the file count and size),
which removes the whole folder with one PIN. The action checks again that
the folder is a Course media folder and that no stored Course, readable or
not, owns it.

### The "Remove unused media" idea

Examined on 11 October 2026 and closed (owner decision): the plan of
20 September (`docs/240_REMOVE_UNUSED_MEDIA_PLAN.md`) described the storage
before Build 243. Its header now says what handles each case. The owner's PC
had no orphan Course media.

### Follow-up in the same version (owner decisions of 11 October 2026)

**Inventory, Delete on a Course.** The dialog now shows, above the PIN:

- who has the Course in their courses ("Anna, Marco and you have this
  Course in your courses.");
- who removed it from their courses but kept their progress ("Carla removed
  it from their courses but kept their progress on it.");
- **Also reset everyone's progress on this Course**, off: every learner on
  this device, also those who removed the Course and kept their progress.
  XP, Weekly XP, study days and streaks are kept. Ticked, it is confirmed
  once more ("Confirm progress reset") before anything happens;
- **Also delete all its backups**, off, with their count and size.

The Delete comes first: when it is refused (a wrong PIN, no rights),
nothing is reset and no backup is deleted.

**Remove Publisher Course from device** (Inventory) has the same two
extras. Unticked it keeps progress, media and backups for a reinstallation,
as before, and the texts say that learners may want their progress back
when the Course is installed again. It is still refused while another
learner has the Course in their courses; that rule was not changed.

**A Course this version cannot open.** Its removal in Course Studio offers
**Also delete all its backups**, off, with a caution: its backups may be the
last copies that can still be read. The Inventory's Delete of such a Course
shows the same caution, and knows its learners by the Course ID alone.

Code: `ProgressService.resetCourseForProfile` and `hasCourseProgress`,
`CourseLearnersService` (`lib/services/course_learners.dart`),
`InventoryActionService.previewCourse` and `run(resetEveryonesProgress:,
deleteBackups:)`, `InventoryCoursePreview`, the Inventory screen's
`_CourseExtras` and `_confirmReset`, `CourseLibraryOperations.backupsOf`
and `removeUnopenableCourse`.

### Not changed

Scoring, progression, Course files and the learner-data format. No new
preference key and no new folder. Course Studio's Delete resets only the
deleting learner's progress: resetting other learners' progress needs the
admin's PIN, in the Inventory.
