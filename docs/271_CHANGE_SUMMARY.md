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
when the Course is installed again.

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

### Second follow-up in the same version (owner decisions of 11 October 2026)

Owner's rule: the admin can clean up anything if necessary, whatever the
problem is, but has to be warned when a destructive action can have
undesired effects.

**Two Deletes the Inventory refused are now possible for the admin.**

- A Publisher Course that other learners have in their courses. Before:
  "Another profile still has this course in My courses. Nothing was
  removed."
- Another learner's custom Course (the admin is neither its Maintainer nor
  in its Team). Before: "Only the Course Maintainer or a member of the
  assigned Team can delete this Course."

Both now go through the same steps in the Inventory's dialog:

1. A warning that says who is affected and what they lose, and where each
   consequence is decided: "to reset it too, tick “Also reset everyone's
   progress on this Course” below", and for a custom Course that its saved
   versions stay in Backups/Courses unless "Also delete all its backups" is
   ticked.
2. The word **DELETE**, typed in capital letters.
3. A second confirmation ("Remove it from everyone?" / "Delete another
   learner's Course?") that repeats what was chosen for progress and
   backups, and how to change it ("choose Keep the Course and tick …").
4. The admin PIN. (Resetting everyone's progress still asks once more.)

The service checks the word and the PIN again; a learner who is not an admin
cannot use the override. Outside the Inventory both Deletes stay refused:
Course Studio's Delete and Remove Publisher Course from device are
unchanged.

**Progress on Courses no longer on this device.** When a Course is deleted
without the reset, its learners' progress stays (it comes back if the same
Course is installed again), but the Course is no longer listed, so there was
no place left to reset it: only installing the Course again, or resetting
every Course for everyone. The Inventory now has a section that lists that
progress by Course ID, names the learners who have it, and has **Reset**
(admin PIN): every learner's progress on that Course, with XP, Weekly XP,
study days and streaks kept. A Course that is on the device (bundled, stored,
or stored but unreadable) is never listed, and the Reset refuses it.

Code: `CourseEditorService.deleteUserCourse(adminOverride:)`,
`mayDeleteUserCourse`, `removePublisherCourseFromDevice(evenIfOthersHaveIt:)`;
`InventoryActionService.run(adminOverride:, typedWord:)`, `overrideWord`,
`InventoryCoursePreview.needsOverride` / `overrideWarning` / `overrideTitle`
/ `overrideQuestion`; `InventoryActionKind.resetCourseProgress`;
`ProgressService.courseIdsWithProgress`; `CourseLearnersService.leftProgress`;
`CourseService.bundledCourseIds`.

### Not changed

Scoring, progression, Course files and the learner-data format. No new
preference key and no new folder. Course Studio's Delete resets only the
deleting learner's progress: resetting other learners' progress needs the
admin's PIN, in the Inventory. Deleting a learner keeps its two refusals
(the only admin; a learner who maintains a Course).

## Revision 2 (2.0.71+271002): the Audio Library like the Image Library; the Course Editor's top bar

Owner decisions of 10 and 11 October 2026 (`docs/271_PLAN.md`, Revision 2).
Mock-ups of the four screens were shown before the work.

### What changes for an author

- **Audio Library.** The top bar has three icons: **Help** (the Editor Help
  at its sound questions), **Add to the Course** (Quick Import, Open from…)
  and **Check** (Texts in this Course, Unused MP3 files). Before, the two
  imports sat in a card and the check in a list row, all scrolling away with
  a long explanation above them. With On-Device TTS the two menus are greyed
  out and their tooltip says to choose Recorded MP3 only or Hybrid first.
- **A fixed header**: the one-line notice, the audio source with one line of
  explanation and the A–Z bar stay in place; only the recordings scroll.
  When the window is too short (under 420 pixels of body), everything
  scrolls, so the recordings always have room.
- **Rows** no longer show the stored file name (a 64-character code); a
  recording without text says "Tap to give it its text". An empty library in
  a recorded mode says where to add recordings.
- **Associate recording** shows **Original file** (the name the file had
  when it was imported, when known) and **Stored as** (the name in the
  Course's folder, in full, selectable), **Play**, **Open folder** on
  Windows, Linux and macOS, the text field and **Texts in this Course**.
  Apply is greyed while the field is empty. A text that already has its own
  recording asks: "“Buongiorno.” already has a recording. Replace it? The
  old one loses its text and moves under #."
- **Texts in this Course** lists every text the Course speaks, with how many
  exercises say it, a Draft mark and one of four states (Its own recording,
  All parts recorded, Some parts recorded with the words still missing, No
  recording); Search; **Only texts without a complete recording**; **Copy**
  and **Save as…**.
- **The original file name** is kept with every recording imported from now
  on and removed by Export as Publisher Course.
- **A Course's Image Library** opens with the same one-line notice, and its
  Help is the Editor Help's picture questions.
- **Course Editor main page**: Save now is a disk icon; Show internal IDs is
  a switch in Course Info Editor.

### How it is built

- `CourseAudioClip.originalFileName`, `labelOf`, `withText`
  (`lib/models/course_models.dart`); strict parse.
- `AudioSegmenter` (`lib/services/audio_segmenter.dart`): the one matching
  rule; `RecordedAudioService.segment` delegates to it; `coverage` goes on
  past a word without a recording and names what is missing.
- `CourseAudioTexts` (`lib/services/course_audio_texts.dart`): the list, its
  states, the filter and the export.
- `AudioTextsScreen` (`lib/screens/audio_texts_screen.dart`), a new file;
  the Audio Library screen and its dialog stay in
  `course_editor_screen.dart`.
- `LibrarySaveNotice` (`lib/widgets/library_save_notice.dart`): one text for
  both libraries.
- `ImageLibraryHelpScreen` is deleted; its content is in the Editor Help
  answers `findPicture`, `pictureBadges` (new), `addPictures` and
  `pictureDetails`.

### Decisions taken while building

- **The two menus are greyed in On-Device TTS**, as the import card and the
  check row were hidden there since Build 243 Revision 17.
- **The header scrolls in a very short window** (a phone held sideways):
  the plan asks for a fixed header; with about 200 pixels of header a short
  window would leave no room for the recordings.
- **Apply is greyed while the text is empty.** Before, Apply with an empty
  field closed the dialog and changed nothing.
- **A new Editor Help question**, "Which texts still need a recording?", so
  that the answer on adding recordings does not grow further.
- **The field Help of the audio fields** says "choose Add to the Course ›
  Quick Import" where it said "press Quick Import" (EN, IT).

### Not changed

- Which recordings a Course plays for a text.
- The read-only Course Info page: it has no Show internal IDs switch; someone
  who may not edit turns the IDs on from the Lessons page.
- The Shared Image Library (it saves each change at once and shows no
  notice).

## Revision 2 follow-up (2.0.71+271002, same version)

Owner decisions and report of 11 October 2026.

### Fixed: Save now, then the Editor still asked about unsaved changes

Save now always wrote the Course (a test reads the stored file after it).
What went wrong is the moment in between: a save first makes its backup and
then writes, which takes a moment on a Course with many pictures and
recordings, and during that time the Editor stayed in use with nothing on
the screen saying so. Pressing Back then found the changes not yet saved and
showed "Unsaved course changes", as if Save had only applied them. Choosing
Save course there started a second save beside the first, and a change
applied while a save was running was lost when it finished.

Now every save from the Editor (Save now, Save course on leaving, the save
when the access mode changes) goes through one function that shows a small
window, **Saving the Course…**, until the Course is written; nothing else
can be pressed meanwhile, Back included.

Not proven: that this is what happened on the owner's PC. It is the one way
found in the code to get that question after pressing Save, and a test now
reproduces it and passes with the fix. If the question still appears after
the message "Saved as version N.", the steps are needed.

### The disk icon only where the Course is written

Since Build 270 Revision 12 "Save" writes to the device and "Apply" changes
the working copy. Four Apply buttons still showed a disk, the icon Save now
got in this revision: the exercise form's Apply and Apply as draft, the
canonical editor's Apply and the GuideBook page's Apply. Apply now shows a
check mark, Apply as draft the note with a pencil the other pages already
used.

### Audio Library: the original file name on a row without text

A recording without text shows, under "Tap to give it its text", the name
its file came with, in grey. A recording with a text still shows no file
name.

### The admin may delete a learner who maintains Courses

In the Inventory, Delete on such a learner shows which Courses they
maintain (a Private course and one this version cannot open are marked) and
what becomes of them, asks for the word DELETE, then a second confirmation,
then the PIN. The learner's progress and settings go; the Courses stay on
the device without a Maintainer. Without a Maintainer a Course can be edited
only by the members of a Team already assigned to it, nobody can change its
Maintainer or its Team, and a Private course is seen only by that Team; the
admin can delete such a Course in the Inventory (its own override).

Unchanged: the only admin cannot be deleted; the last Team Leader of a Team
cannot be deleted; Profile's own Delete and the reset "Remove all learners
except admins" still refuse a learner who maintains a Course, and now say
that the Inventory can delete them. When a stored Course file cannot be read
at all, QQL cannot tell who maintains it: the Inventory says so and the
admin may still go ahead.

### Fixed: a deleted learner still listed under Learner profiles

Home keeps a copy of the learner list for its Learners sheet, loaded when
Home loads. A learner deleted in the Inventory (or by the reset that removes
learners) was gone from QQL's settings but not from that copy, so Profile ›
Learner profiles still showed them, without an avatar, and choosing them
answered "Unknown learner profile". The sheet now reads the learners and
the admins afresh each time it opens.

### The Lesson screen's GuideBook tile

In the Course Editor's Lesson screen the tile that opens the GuideBook reads
**GuideBook** (it said "Lesson Guidebook") and is bold like the Rounds tile
above it.

## Revision 2 second follow-up (2.0.71+271002, same version)

Owner decisions of 11 October 2026.

### One order: the warnings, the PIN, the typed word

Wherever a warning and a PIN meet, the warnings now come first, then the
PIN, then the typed word.

- **Inventory.** Every Delete, Forget and Reset has two dialogs. The first
  says what goes and shows the warnings and the choices; its button opens the
  second confirmations (a Delete the service refuses otherwise, and the reset
  of everyone's progress). The second dialog asks for the admin PIN and, for
  a Delete that needs it, the word DELETE under the PIN. Before, the PIN and
  the word were typed in the first dialog, above or beside the warning, and
  the second confirmations came after them.
- **Wipe out everything.** The reminder of what is deleted no longer asks
  for the words; the last dialog asks for the PIN and then, under it, for
  NUKE EVERYTHING, and its button waits for the words. Before, the words
  were typed before the PIN.

### The last Team Leader of a Team

In the Inventory the admin can delete a learner who is the last Team Leader
of a Team, with the warning, a second confirmation, the PIN and the word
DELETE. A Team always has a Team Leader, so the member who was added first
takes over, and the warning names them. When the learner is the Team's only
member, the Team is removed. Profile's own Delete still refuses and says
that the Inventory can do it.

### Deleting a Team

Until now nobody could delete a Team, not even its Team Leader: a Team only
went with the reset that removes learners, or with Wipe out everything. The
Inventory has a **Teams** section (each Team with its Team Leaders, how many
members it has and how many Courses are assigned to it) and Delete, for the
admin: the warning names the members and the Courses assigned to it, then a
second confirmation, the PIN and the word DELETE. The members stay as
learners; they lose the access the Team gave them to those Courses, which
stay with their Maintainers and keep the Team's ID until another Team is
assigned. The service refuses a Team's Delete without the word.

### Not changed

- Team Leaders still cannot delete their own Team from the Team Manager
  (owner's choice: the Inventory only).
- The only admin still cannot be deleted.
- Course files: deleting a Team rewrites none.

## Revision 3 (2.0.71+271003): a save is faster and shows where it is

Owner report of 12 October 2026: "Save works but is slow, and the time is
not signalled." This is the first part of the plan's Revision 3 (speed).

### What was slow

Measured before changing anything, on the owner's Windows PC, with tests
that save a Course the way the Course Editor does.

1. **The backup before each save.** With 700 small pictures in the Course, a
   save took about 2.1 seconds, and 1.8 of them were the backup. For every
   picture and recording of the Course it read the stored file and worked
   out its checksum, read the copy the backups hold and worked out its
   checksum, wrote nothing (the copy was there), and then read the copy and
   worked out its checksum a third time when the finished backup was read
   back.
2. **Finding the Course.** A stored Course is found by the ID inside its
   file, so finding one read and decoded every Course on the device. A save
   finds its Course three times (to read it, to replace it, to check what
   was written). With 31 stored Courses of the Exercise Laboratory's size a
   save took about 0.85 seconds; with one, about 0.3.
3. **Listing the versions.** Version History, and the question about older
   backups after a save when Course Info keeps a number of them, read every
   picture and recording of every version: about 2 seconds for 4 versions of
   the 700-picture Course.

### What changed

- **Name and length.** A stored picture or recording and its copy in the
  backups are both named by their content, and both were checked when they
  were written. When the backups hold a file with the same name and the same
  length, the backup records it without reading either file. A file the
  backups do not hold yet, or hold with another length, is read, checked,
  copied and checked again as before. A missing file is a gap, as before.
- **The versions are listed by what is there.** The listing checks that
  every file a version names exists (one listing per folder). The content
  is checked when a version is restored: each file is compared with its
  name before it goes back into the Course's folder. A changed or missing
  file stops the restore with a message, and nothing is loaded.
- **Another Course's file is told by its first bytes.** QQL writes a stored
  Course as `{"courseId":"<id>",…`. Finding a Course reads the first 1,024
  bytes of the other files and passes over those that begin with another
  ID. A file named for the Course, one that begins with its ID and one that
  does not have this shape are still read whole, so two files that claim
  one Course are still refused, and so is a file named for the Course that
  cannot be read.
- **The window of a save.** "Saving the Course…" now has a bar and one line
  that names the step: Checking the Course…, Making the backup: N of M
  pictures and recordings, Writing the Course…, Checking what was written….
  The window is on the screen before the work starts; before, it faded in
  while the save was already running. A save never waits for the window
  when nothing is drawn (a minimized window): it starts after a quarter of
  a second at the latest. The Course Wizard's Save now, Save
  and leave, Continue by hand and Finish show the same window; before, they
  showed nothing.

### Measured afterwards

| Case | Before | After |
|---|---|---|
| Save, Course with 700 small pictures | about 2,080 ms | 514 to 589 ms |
| First save of that Course (every file is copied) | about 6,100 ms | about 5,700 ms |
| Save, 31 stored Courses of the Laboratory's size | 792 to 918 ms | 251 to 333 ms |
| Save, 1 stored Course of that size | 267 to 293 ms | 268 to 312 ms |
| Listing the versions of the 700-picture Course | 2,022 ms (4 versions) | 654 ms (3 versions) |

The pictures of these tests are tiny (4 × 4 pixels). Real pictures and
recordings are thousands of times larger, and the reading that was removed
grows with their size, so the gain on a real Course should be larger; that
was not measured.

### What this costs

Stated plainly, because a check was moved:

- A copy in the backup folder that is changed from outside QQL without
  changing its length was rewritten by the next save. Now it stays as it
  is until a restore reads it, finds that it is not what the Course names,
  and says so.
- A stored picture or recording changed from outside QQL without changing
  its length was recorded as a gap (and written to the Diagnostic Log) by
  the next save. Now, while the backups hold its copy, the backup names
  that copy, which is the right one.
- Version History lists a version whose files were changed (same names);
  before, it named that version as unreadable. Restoring it says what is
  wrong.
- The first save of a Course with many pictures and recordings still takes
  as long as copying them takes. The window now counts them.

### Not changed

- Course files and the backup format: a backup written by this version is
  the same file as before.
- A backup is still made and checked before every save, and the Course is
  still read back after it is written.
- No new key or folder. Scoring, progression and learner data.

### Not in this commit

The plan's other speed items: one Audit per change of the working copy,
Lesson and Round Audits of their own Lesson or Round, image library search
keys. They are the follow-up below.

## Revision 3 follow-up (2.0.71+271003, same version)

The rest of the plan's Revision 3. Nothing looks different; the same pages
answer sooner.

### One Audit for each change

The red and green borders of the Course Editor come from the Audit. The
main page, the Lessons page and every row of Course Studio ran the whole
Audit of their Course each time they were drawn again, also when nothing
in the Course had changed. On the Exercise Laboratory that is 30 to 80 ms
each time; a Course ten times as large takes about ten times as long.

The result is now kept with the Course it was worked out for. A Course is
never changed in place in QQL: every change makes a new Course. So the same
Course is audited once, and a changed one is audited when it is first
shown.

### A Lesson's pages audit their Lesson

The Lesson page, the Rounds page and the Round page did more: each built
the Course as it shows it (the stored Course with the page's own changes)
three or four times for each drawing, 15 to 19 ms each on the Laboratory,
and audited the whole of it.

- Each page now builds that Course once for each drawing.
- Their borders come from the Audit of their own Lesson. The other Lessons
  are read only for their IDs, because a repeated ID and a source reference
  are found across the whole Course.
- The Audit of a Lesson and of a Round (in their menus, and when a Lesson
  or Round is applied as Published) does the same.

The findings are the same as the whole Audit's for that Lesson or Round.
`test/audit_speed_271_test.dart` compares them one by one, for every Lesson
and Round of the two bundled Courses, the Edge Case fixtures, the Korean
fixture, the Laboratory of the future, and a Course made for it with IDs
repeated across Lessons (a Lesson, a Duel, a module, a Sentence, a Word, a
Round with its exercises) and a source reference to another Lesson.

| On the Exercise Laboratory (8 Lessons) | Before | After |
|---|---|---|
| The borders of a Course already audited | 30 to 80 ms | 0 ms |
| The Audit of one Lesson | 28 ms | 9 ms |
| The Audit of one Round | 28 ms | 9 ms |
| The Course a Lesson's page shows, built for one drawing | 3 or 4 times | once |

### The image library's search

The search compared each picture's name, tags, Local words, ID and category
with what was typed, after writing each of them in small letters and in the
singular; the same again for a category and for a tag. Every keystroke did
this for every picture: about 40,000 texts for QQL's own pictures.

These texts are now worked out once for each picture and kept with it (a
picture's record never changes: a picture with other tags or Local words is
a new record).

| Over QQL's 4,334 pictures | Before | After |
|---|---|---|
| Search "c" | 109 ms | 6 ms |
| Search "ca" | 226 ms | 19 ms |
| Search "cat" | 279 ms | 17 ms |
| Search "food and drink" | 303 ms | 9 ms |
| A category and a tag together | 208 ms | 5 ms |

The results are the same: `test/image_search_keys_271_test.dart` compares
the search, the tag filter and the category filter with the rules as they
were written before, for every picture and for 24 searches, a few hundred
tags and every category.

### Decisions taken while building

- **No pause before the search.** The plan said the search would filter
  "after a short pause instead of on every keystroke". With the texts kept,
  a keystroke costs 6 to 19 ms, so a pause would only make the results come
  later. Not added.
- **Courses are still read on the screen's thread.** The plan allowed
  moving it "if needed". After Revision 3 a save of a Course of the
  Laboratory's size takes about 0.3 s whatever else is stored. Not moved.
- Sorting the pictures by name (13 to 18 ms for the whole library) was
  tried with a kept key and was no faster, so it is as it was.

### Not changed

- What the Audit finds and how it is shown; what a search, a tag and a
  category find.
- Course files, scoring, progression and learner data. No new key or
  folder.
- The whole Audit of a Course still takes as long as before the first time
  a Course is shown.

## Revision 4 (2.0.71+271004): imports check what they bring in; Android file safety

Plan `docs/271_PLAN.md`, Revision 4.

### Pictures are opened once at import

A picture of a Course package or of an Image Bank had its structure read
(its type, its size, its parts and their checksums), not its content. A
picture with every part in place and data that is not a picture passed, was
installed, and was then shown as "Image file missing" wherever it was used.

Each picture is now opened once while the package or the ZIP is read, as a
picture chosen by hand already was. One that cannot be drawn stops the
import with its name and "The image is damaged. Export it again as a still
PNG, JPEG or WebP image and retry." Nothing is installed or added.

The cost: reading takes longer, in proportion to the number of pictures. It
was not measured on a large Image Bank.

### Every import action refuses what the screen refuses

The import screen refuses someone else's Private course, and a Course whose
Audit has errors ("Course import blocked"). The actions behind the screen
(install, Copy as New Course, Fork, the Publisher install) did not check
either: whatever else called them could bring such a Course in. They now
refuse both themselves, before anything is written, with the same words.
The screen is unchanged for the user.

### A Course ID already in use

When the Course being imported has the ID of a stored Course, the Matching
Course ID dialog named the stored Course by its title. If that Course was
someone else's Private course, its title was shown to a learner who must not
see it. The dialog now says "a custom Course with ID … already exists: a
Private course", or "A Private course stored with ID …" when this version
cannot open it.

### Publisher versions

A Publisher update is accepted only with a version newer than the one
installed. The comparison split the version at its dots and read each part
as a whole number; a part that is not one counted as 0. So `1.0.beta` and
`1.0.rc` were the same version, and so were `2026-09` and `2026-10`: the
update was refused as "not newer".

Two whole numbers still compare as numbers (10 is after 9, 1.0 equals 1).
Any other pair of parts compares as text, and a missing part is 0.

### Android: Save as…

Save as… opens the system's screen, where the user names a new file or
chooses one that exists. When QQL then could not open that file for
writing, it deleted it. Nothing of it had been replaced yet, so a file that
was there before was lost for a write that never started. QQL now leaves it
as it is and reports the failure. A write that starts and fails part-way
still removes the incomplete file, as before.

### Android 10: QQL's own files in the Download folder

Quick Export, the Inventory and Wipe out everything find QQL's files in
`Download/QuisquisLingo` through Android's list of downloads, and chose
them by their folder alone. From Android 11 an app sees only its own files
there. On Android 10, where QQL holds the storage permission, the list also
shows files that another app, or the user with a file manager, put in those
folders: they could be listed as QQL's, replaced by an export of the same
name, or deleted by Wipe out everything. QQL now also asks for the files it
made itself.

### The version shown in Settings

Found while checking on the emulator: since Revision 2, Settings › Version
and Build and the Audit report said "Build 271, Revision 1". The build
number (271002, 271003) was right; the label and the tests that pin it had
not been moved. They now say Revision 4.

### Checked on the emulator, and not

Android 16 emulator (the only image here), with the app built from this
revision:

- Quick Export Crash Log, repeated: still one file
  `Download/QuisquisLingo/Logs/QQL_crash_log.txt`, replaced (its time
  changes), and one entry for it in Android's list, with QQL as the one
  that made it.
- The Inventory lists it under Logs folder as "Written by QQL".
- Android's list accepts a delete chosen by folder and maker: with another
  maker nothing is removed, with QQL the file is removed (run from the
  shell, not from the app).
- Save log copy as… writes the file chosen in the system's screen.

Not checked: Android 10, the version the last change is for (no emulator
image here; the owner declined downloading older images); Wipe out
everything from the app on the emulator; a chosen file that cannot be
opened, which cannot be provoked by hand.

### Not changed

- Course files, the package format, scoring, progression and learner data.
  No new key or folder.
- What the import screen shows, apart from the dialog's sentence.

## Revision 5 (2.0.71+271005): the names of a Course's items stay in English; tidy-ups

### The owner's decisions (12 October 2026)

The plan said "labels are never translated". Looking at how an Italian
Course showed its labels, the owner found a mix: "Lesson 2" on the learner
path and "Lezione 2" in the Round, "Final Duel" on the path and "Duello
finale" in the Duel, "Review" on the button and "Ripasso" on the page.
The decisions:

1. The app interface is in English.
2. The names of the main items of a Course are in English, as they are
   written originally: Lesson, Round and the Round types, Story, Sequence,
   Duel, Language Duel, Final Duel, GuideBook, Review.
3. They stay in English inside ordinary sentences too. The reason: they are
   like proper names of the main items of a Course.
4. In the learner's language: the exercise instructions (7 languages) and
   Help, the FAQ and App Info (3 languages).
5. Localization is left to a future project.
6. A document, `docs/LOCALIZATION_CURRENT_STATE.md`, records the state.

### What a learner sees

Only in a Course whose learners read Spanish, Italian, German, Portuguese,
Dutch or French. A Course for English readers shows what it showed.

| Where | Before (Italian) | Now |
|---|---|---|
| Under a Round's title | English · Lezione 2 · Primi passi | English · Lesson 2: Primi passi |
| A Round's last button | Termina il round | Termina il Round |
| A Story's last button | Termina la storia | Termina la Story |
| The end of a Round | Lezione completata: +25 XP | Lesson completata: +25 XP |
| Before you start | Apri la guida | Apri il GuideBook |
| The Final Duel's top bar | Duello finale | Final Duel |
| The Duel's result | Duello vinto | Duel vinto |
| The Review page | Ripasso, Prossimo ripasso | Review, Prossima Review |
| A Round in Review | Ripasso · Practice · Saluti | Review · Practice · Saluti |

The line under a Round's title now reads exactly as the learner path: the
label the author chose for Lessons (Lesson, their own word, a number alone,
or nothing), the number, a colon and the title. Before, only the default
label was translated, and it was written with dots.

In each of the six languages 40 to 45 buttons and messages changed, and 3
exercise texts (the Story cover's heading, title and instruction): 274
texts in all. Each name takes the article of its language: il Round, la
Lesson, la Story, la Sequence, il Duel, il GuideBook, la Review in Italian;
el Round, la Lesson in Spanish; die Round, die Lesson, das Duel, das Review
in German; o Round, a Lesson in Portuguese; de Round, het Duel in Dutch; le
Round, la Lesson in French.

### Decisions taken while building

To tell the owner, who can change any of them:

- **"Course" is still translated** (corso, curso, Kurs, cursus, cours) in
  the seven texts that use it as an ordinary word, such as "Torna al corso".
  It was not in the owner's list.
- **A Round's own repetition of the exercises missed is still "Ripasso"**
  ("Practice · Ripasso", "Ripasso degli esercizi sbagliati"). English calls
  it "review", but it is not the Review page.
- **The Laurel is still translated** in the end-of-Round summary ("Primo
  alloro"), while the Welcome Wizard writes "Laurel".
- **The English texts were not touched**: "Finish round", "Open Guidebook"
  keep their small letters and their earlier spelling.
- **The articles** above were chosen by the AI that wrote the translations.

### The document

`docs/LOCALIZATION_CURRENT_STATE.md`: the decisions; a table of what is in
which language and what it follows; the names that stay in English, with
the same seven texts in the seven languages; what is still translated on
purpose; what is English only; and the lists, English with Italian: the 128
buttons and messages around an exercise, the 119 exercise titles, headings
and instruction lines, the Welcome Wizard, Course Info, the 141 Help titles,
the 90 Editor Help questions and the 21 short texts of the Help pages. The
491 long Help texts are counted by part of Help, not listed. The tables are
written by a script from the catalogs.

### Tidy-ups

- **Cyrillic order in the Audio Library.** The letter groups and the texts
  inside them were ordered by the letters' code numbers, which put Ukrainian
  Є, І and Ї before А, and Ґ after Я. Eighteen letters of Ukrainian,
  Serbian, Macedonian and Kazakh now stand after the letter their alphabet
  puts them after. Ї stays with І and Ў with У, as before. Latin and Greek
  are unchanged.
- **Course Info Editor.** Its text fields were released by a timer 300
  milliseconds after the dialog closed. They are now released when the next
  Course Info opens or when the Course Editor closes.
- **Test seams.** `RoundScreen.openLink`, `RoundScreen.lineStopwatch` and
  `SpokenLinePace.shared` are set back before every test of the suite.

### Not done

- **The mascot.** The plan asked that the Round screen place its mascot
  after the frame instead of writing state while it builds. Doing it after
  the frame makes the sentence move a frame after it appears; doing it
  before means passing the placement through every exercise page. What is
  written while building is the same on every build, so nothing goes wrong
  today. It is now in the plan under "Not in Build 271".

### Not changed

No new key or folder. Course files, scoring, progression and learner data.
The three removed catalog keys were only read by the two screens changed
here.

## Revision 5, follow-up (same version): the exercise mascot in its own module

Owner request of 12 October 2026. The report on Revision 5 said the plan's
mascot item was not done; the owner asked what it was about, whether
splitting the Round screen would meet the same difficulty, and then: can it
have a module now?

### What was wrong

Nothing a learner could see. The mascot is the picture beside the sentence
of some exercises. While the Round screen drew a page, it also decided two
things and wrote them down: which picture the exercise takes from the
Round's order, and where the picture goes. A screen should only read while
it draws; deciding belongs to the moments when something happens.

### Why not as the plan worded it

The plan said "after the frame". Then the sentence is drawn first without
its mascot and moves a moment later to make room: a small jump at every
exercise. The other way, deciding before and passing the result through
every exercise page, is a wide change of a very large file.

### What was done

The two decisions were separated, and each has its own owner outside the
screen.

- **Which picture: `ExerciseMascotCast`** (plain Dart). The screen tells it
  two things: another exercise came on the page; the page has room for a
  mascot, or not. The first time an exercise has room it gets the Round's
  next picture, and keeps it until the next exercise. An exercise that
  never has room spends no picture.
- **How much room: `ExerciseMascotRoom`**. The measure that was in the
  Round screen, unchanged: the sentence in the text style and between the
  margins the page gives it, 220 pixels of text at least, three lines at
  most, a window at least 560 pixels high. It changes nothing: asked again
  on the same page, it gives the same answer.
- **The Round screen** tells the cast when an exercise comes on the page and
  when the window, the text size or the theme changes. While it draws, it
  reads the picture and asks for the room. It is 24 lines shorter.

### What a learner sees

The same as before. Three new tests of the Round screen were run against
the code as it was and against the new code, and pass with both: a window
made wider shows the mascot, a narrower one hides it and the same picture
comes back; an exercise that never had room spends no picture; a page drawn
again and again takes no other picture.

One difference cannot be seen: an exercise waiting behind the Before you
start page gets its picture when it is prepared instead of when its page is
first drawn. It is the same picture.

### Not changed

Which exercises show a mascot and where (`ExerciseMascotPolicy`), the order
of the pictures (`ExerciseMascotSequence`), the widget that draws one. No
new key, folder or setting; nothing is stored.
