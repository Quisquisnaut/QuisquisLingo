# Build 271 validation

## Revision 0 (2.0.71+271000), content that plays wrong

11 October 2026, owner's Windows 10 PC, `build-271`.

- New tests: `test/content_plays_right_271_test.dart`, **16 passed**:
  - Missing letters (8): the spoken text stored as optional audio that
    still plays by itself; the kind and the line "Write the missing
    letters."; the preset represents it and reads its fields back; an
    exercise stored earlier keeps its required audio, is still represented
    by its preset and takes the new shape when its form rebuilds it; Listen
    and fill the gaps is still an audio exercise; the Laboratory example;
    as a learner with audio off, the exercise is in the Round, with no Play
    audio, nothing spoken and no message; with audio on, the text is spoken
    and Play audio shows; an earlier exercise is still skipped without
    audio.
  - Put the sentences in order (6): the blocks carry the role `line` and
    two short lines are lines; without the mark the text is still guessed
    (two short lines read as words, three-word or closed lines as lines)
    and such an exercise still opens in its form, which saves the mark; Put
    the words in order is not marked; the canonical editor offers the role;
    the two Laboratory examples; as a learner, two short lines show PUT THE
    SENTENCES IN ORDER and "Arrange the lines in a logical order."
  - A Round copied whole (2): a Test Round keeps every field (state,
    provisional mark, time stamp, title, type, fixed order, passing percent,
    focus and supporting modules); a Timed Round keeps its limits and a
    sequence its flow.
- Generators: `tools/generate_exercise_laboratory_254.py --check`,
  `tools/generate_english_from_italian_260.py --check` and
  `tools/generate_edge_case_demo_254.py --check` pass;
  `tools/validate_courses.py`: 2 bundled Course Model v12 files validated.
  The regenerated Laboratory differs from the committed one only in the
  Missing letters example's `required: false`, the eight `line` roles of the
  two Put the sentences in order examples and the checksum.
- Laboratory presentation baseline
  (`test/support/laboratory_presentation_254.dart`): one record changed,
  `qql_lab254_missing_letters_audio`, its instruction only ("Write the
  missing letters." before and after answering); 123 records unchanged.
- Related files, first batch (22 files, two test processes): 609 passed,
  2 failed. One was the baseline record above before it was updated. The
  other, `exercise_laboratory_254_test` "learner completes
  qql_lab254_reading_dialogue_automatic", recorded the two dialogue lines in
  the wrong order; the file run alone afterwards: **253 passed**.
- Related files, second batch (33 files with the new file and the version
  pins): **280 passed**.
- `flutter analyze --no-pub`: no issues.
- Complete suite (`flutter test --no-pub --concurrency=1`, kept awake, TEMP
  on D:): **4,175 passed, 1 skipped**, 40:49 (11 October 2026,
  10:03–10:44). It ran with about 1.2 GB of memory free (two browsers
  open), slower than usual; no test failed and none failed to load.

Not checked: the Linux, Android, iOS and macOS builds (no platform code
changed); a Windows release build was not made for this revision.

## Revision 1 (2.0.71+271001), deleting a Course; saves never blocked

11 October 2026, owner's Windows 10 PC, `build-271`.

- New tests: `test/deleting_a_course_271_test.dart`, **17 passed**:
  - A backup never blocks a save (2): a stored file whose bytes no longer
    match its name is recorded as a gap and logged, the version is listed
    and restores the rest; a Course with such a file is saved again through
    the Course Editor's confirmation (it threw before).
  - The backups of a Course (2): counted, measured and deleted whole, also a
    file this version cannot read, another Course's backups untouched; a
    stored copy this version cannot open is kept, twice under two names, and
    Version History names both as unreadable.
  - The Course store (4): leftover temporary files removed from both
    folders, the running process's and other files kept; nothing to clean
    without a store; the folder flushed after a save and after a rename
    (recording seam); the default flush does nothing on Windows.
  - A Publisher update over a copy this version cannot open (1): the stored
    record is kept in the Course's backup folder and the update is
    installed.
  - Deleting a Course (6): the other learners named (added, or with
    progress; not one who removed it), a Private course in nobody else's
    courses; a plain Delete leaves progress and backups; with both extras
    the deleting learner's progress on that Course and its backups go while
    XP, the other Course, the other learner's progress and the other
    Course's backups stay; a Delete that fails changes nothing else; the
    texts.
  - The Inventory (2): one whole-folder row for a Course no longer here,
    not counted among the files; Delete all needs the admin PIN, refuses a
    folder a stored Course owns and any folder that is not a Course media
    folder, and removes only the folder asked.
- `test/course_manager_workflow_249_test.dart`: two new cases in Delete (the
  other learner named, both boxes off, both ticked, the list in the second
  confirmation, the message, progress and backups gone; a Course without
  backups offers none); its four Delete cases pass.
- Related files (25 files: Course Studio workflow and operations, backups,
  Inventory, resets, the Course store, Publisher installs, Version History,
  the version pins, Help translations): **274 passed**.
- `flutter analyze --no-pub`: no issues.
- Complete suite (`flutter test --no-pub --concurrency=1`, kept awake, TEMP
  on D:): **4,194 passed, 1 skipped**, 49:56 (11 October 2026,
  12:17–13:07; slower than usual, with little memory free).

Not checked:

- The folder flush on Linux and macOS (the system's `sync` on the Course
  folder): no Linux or macOS build on this PC. The suite turns it off, so no
  test starts a process for it on any system.
- Android: deleting backup files written by an earlier installation (the
  system may refuse; the message then says some files stayed).
- A Windows release build was not made for this revision; the dialogs were
  exercised by widget tests, not by hand.

## Revision 1 follow-up (2.0.71+271001, same version)

11 October 2026, owner's Windows 10 PC, `build-271`. Owner decisions of the
same day: the Inventory's Delete on a Course, the backups option for a
Course this version cannot open, and no kept Publisher copy.

- `test/deleting_a_course_271_test.dart`, now **27 passed**. Two cases of
  the first commit went with the kept Publisher copy (the copy itself, and
  the update keeping it). New or changed:
  - A Publisher update over a copy this version cannot open replaces it and
    keeps no copy (1).
  - The learners of a Course (2): progress found and reset learner by
    learner, a recent Round alone counting, another Course untouched; who
    has a Course and who removed it but kept their progress, with the
    Course and by its ID alone.
  - Deleting a Course (2 more): a Course this version cannot open goes with
    its backups when asked, and keeps them otherwise.
  - The Inventory (7 more): the preview and its sentences; Delete with both
    extras resets all three learners' progress (also the one who removed
    the Course) and deletes its backups, keeps the other Course, XP and the
    other Course's backups, and changes nothing with a wrong PIN; without
    the extras progress and backups stay; a refused Delete resets nothing;
    the extras are refused for anything but a Course; a Publisher Course is
    refused while another learner has it (nothing reset, nothing deleted)
    and then goes with both extras; the dialog (widget test) names the
    learners, has both boxes off, asks again before the reset, keeps
    everything on "Keep their progress", and afterwards says what was done.
- `test/course_manager_workflow_249_test.dart`: one more Delete case (a
  Course this version cannot open: its backups counted, the caution, the
  box off, the second confirmation naming the backup, both gone); its five
  Delete cases pass.
- Related files (17 files): **243 passed**.
- `flutter analyze --no-pub`: no issues.
- Complete suite (`flutter test --no-pub --concurrency=1`, kept awake, TEMP
  on D:): **4,205 passed, 1 skipped**, 58:24 (11 October 2026,
  14:32–15:31; slow, with little memory free).

Not checked: the dialogs by hand (no Windows release build was made).

## Revision 1 second follow-up (2.0.71+271001, same version)

11 October 2026, owner's Windows 10 PC, `build-271`. Owner's rule of the
same day: the admin can clean up anything, after a warning.

- `test/deleting_a_course_271_test.dart`, now **35 passed**. New or changed
  in The Inventory:
  - the admin removes a Publisher Course two other learners have: refused
    without the override; refused with a wrong word ("", "delete",
    "DELETE IT", "REMOVE") and with a wrong PIN; removed with DELETE, the
    learners' progress kept because nothing else was asked;
  - the admin deletes another learner's custom Course: the preview says
    whose it is, the warning and the second confirmation name where
    progress and backups are decided (both wordings, ticked and not), the
    admin's own Course needs no override; refused without the override and
    with a wrong word; deleted with DELETE, backups and progress kept;
  - a learner who is not an admin cannot force a Delete through the service;
  - only the Delete of a Course can be forced;
  - progress left by Courses no longer here: not listed while the Course is
    stored or bundled, and the Reset refuses such a Course; listed after the
    Course is deleted without the reset, with the learners' names; Reset
    needs the PIN, clears every learner's progress on that Course and leaves
    the other Courses' progress and XP;
  - `CourseService.bundledCourseIds` equals the bundled assets' Course IDs;
  - two widget tests of the dialog: a Publisher Course others have (the
    warning with where progress is reset, no second confirmation without
    the word, "Keep the Course" keeps everything, the confirmation's wording
    with the reset box ticked, the reset's own confirmation, the result);
    another learner's Course (whose it is, "To delete it anyway, type
    DELETE.", the confirmation naming the backups choice, the Course and
    its backups gone).
- Related files (15 files): **244 passed**.
- `flutter analyze --no-pub`: no issues.
- Complete suite (`flutter test --no-pub --concurrency=1`, kept awake, TEMP
  on D:): **4,213 passed, 1 skipped**, 45:53 (11 October 2026,
  16:46–17:32).

Not checked: the dialogs by hand (no Windows release build was made).

## Revision 2 (2.0.71+271002), the Audio Library like the Image Library

11 October 2026, owner's Windows 10 PC, `build-271`.

- `test/audio_library_271_test.dart`, new, **29 passed**:
  - the original file name: `labelOf` keeps the base name (Windows and
    other paths), removes control characters and cuts at 120 characters; it
    is stored only when known and read back; a path, a control character, a
    longer name, a number or null is a format error; `withText` keeps it; a
    copy of the Course keeps it; Export as Publisher Course leaves it out;
  - how far recordings go in a text: for a text they say whole, `coverage`
    gives the recordings playback joins (`RecordedAudioService.segment`);
    for "Il treno per Roma parte alle nove." with only "per Roma" recorded
    it names "Il treno" and "parte alle nove"; capitals and the punctuation
    around a text do not count;
  - Texts in this Course: the four states on the Laboratory's texts; the
    order ignores accents (È among the E's); a text only Draft content says
    is marked Draft; the search ignores capitals and accents; the switch
    keeps the texts without a complete recording; the export has one text
    per line with its state, a text of several lines on one line, and the
    file name `QQL_EN_IT_…_texts.txt`; `ownRecordingOf`;
  - the Texts screen: the count, the search, Copy (the clipboard holds the
    export of the texts shown), Save as… (the suggested name and the bytes),
    the switch, the empty message with Copy greyed;
  - the Audio Library: three actions in the top bar and Help opening the
    Editor Help at `audioModes`; On-Device TTS greys the two menus and says
    why; the notice is the shared line and the header keeps its place while
    the list scrolls (900 × 900); a 440-pixel-high window scrolls the header
    away; rows show no file name and "Tap to give it its text"; the empty
    message; a 360 × 640 window (the screen, both menus, Associate
    recording, Texts in this Course) without overflow;
  - Associate recording: the original and the stored name in full, the
    missing-file line, Apply greyed while empty, a recording imported
    earlier with only its stored name; applying a text; a text that already
    has its own recording asks, Cancel returns to the dialog, Replace moves
    the old recording under # with its original name still shown; Texts in
    this Course fills the field; Open folder is not offered for a recording
    outside the Course's folder or where the system opens no folders, says
    "The folder could not be opened." when the folder does not exist, and
    opens the Course's media folder when it does;
  - the three lines under the audio source, word for word; the Editor Help
    has `textsToRecord` and `pictureBadges` in EN/IT/ES with the on-screen
    names, no `imageLibraryHelp.` key is left, and the QQL Guide has no
    Image Library entry.
- `test/course_editor_top_bar_271_test.dart`, new, **1 passed**: three
  icons in the Course Editor's top bar (Save now with its tooltip, greyed
  when nothing is unsaved; the access mode; Help), no IDs toggle and no
  "Save now" text; Course Info Editor's Show internal IDs shows and hides
  the Course ID and stores the preference.
- Existing tests changed for the new layout: `media_messages_revision17`
  (the modes and the menus), `audio_library_media_248` (Quick Import through
  the menu), `audio_usage_270` (Check › Unused MP3 files),
  `audio_library_letters_270` (the jump measured from the list's top; the
  two imports in the menu), `image_library_namesake_264` (Help opens the
  Editor Help), `save_now_270` (an icon), `editor_diagnostics_226_02_revision3`
  and `official_hierarchy_id_order_226_02` (no IDs toggle on the main page),
  `qql_guide_screen` (no Image Library entry), `editor_help_qa_256` and
  `editor_help_translation` (90 questions).
- `flutter analyze --no-pub`: no issues.
- Complete suite (`flutter test --no-pub --concurrency=1`, kept awake, TEMP
  on D:): **4,243 passed, 1 skipped**, 48:19 (11 October 2026,
  19:26–20:14). The first run of the suite had two failures, both fixed
  before this one: the new 360-pixel test tapped a row that the test font's
  wide letters push below the window, and the answer on adding recordings
  had lost two phrases that `exercise_field_help_226_02_test` reads
  (restored in EN/IT/ES).

Not checked: the screens by hand (no Windows release build was made); Open
folder on Linux and macOS; the Audio Library on an Android phone (the short
window rule was checked only in tests).

## Revision 2 follow-up (2.0.71+271002, same version)

11 October 2026, owner's Windows 10 PC, `build-271`.

- `test/course_editor_top_bar_271_test.dart`, one new case: with a change
  applied, Save now and its confirmation show `course-saving` ("Saving the
  Course…") while the file work has not run; the system Back and the Back
  button then neither leave nor ask about unsaved changes; once the save is
  done the window is gone, the stored Course is version 2 with the change,
  and leaving asks nothing and returns the save. Before the fix the same
  steps showed "Unsaved course changes".
- `test/editor_diagnostics_226_02_revision3_test.dart`: the exercise form's
  Apply has a check mark and no disk icon.
- `test/audio_library_271_test.dart`: a row without text shows the original
  file name, one with a text does not, one without a known name shows only
  the request.
- `test/deleting_a_course_271_test.dart`, four new cases: the learner
  preview (the Courses, a Private one marked, the warning and the second
  confirmation in their parts); refused without the override, with a wrong
  word and with a wrong PIN; with DELETE the learner and their settings are
  gone, their two Courses and the admin's stay with the same Maintainer IDs,
  and the Inventory then deletes such a Course ("A learner no longer on this
  device"); only an admin can force it and the only admin stays; a stored
  file nobody can read gives the "cannot tell" warning and the admin may go
  ahead; the dialog (warning, word, Keep the learner, Delete anyway, the
  result).
- `test/leaderboard_navigation_test.dart`, one new case: a learner deleted
  while Home is on screen is not listed when Learner profiles opens.
- `test/official_course_ui_226_01_test.dart`,
  `test/official_hierarchy_id_order_226_02_test.dart` and
  `test/production_course_transaction_225_04_test.dart` follow the Lesson
  screen's tile, now "GuideBook".
- `flutter analyze --no-pub`: no issues.
- Complete suite (`flutter test --no-pub --concurrency=1`, kept awake, TEMP
  on D:): **4,250 passed, 1 skipped**, 45:52 (11 October 2026, 20:57–21:43).

Not checked: the screens by hand; how long a save takes on the owner's
Courses, so whether the save in progress is what made the Editor ask after
Save now on the owner's PC (it is the one way found in the code, and the
test above reproduces it).

## Revision 2 second follow-up (2.0.71+271002, same version)

11 October 2026, owner's Windows 10 PC, `build-271`.

- `test/deleting_a_course_271_test.dart`:
  - the four dialog tests follow the new order: the first dialog shows the
    warning and no PIN or word field; its button opens the second
    confirmation (Keep the Course / Keep the learner goes back to it) and
    the reset confirmation; only then the PIN dialog, where the word field
    is below the PIN field, a run without the word says "Type DELETE in
    capital letters" and changes nothing, and a Delete that needs no
    override asks for the PIN alone;
  - four new cases for Teams: `AuthoringTeam.without`, `successorOf` and
    `isLastLead` (the member added first leads; nobody left, no Team); the
    admin deletes the last Team Leader (the preview names "Carla" for
    “Editors” and the removal of “Solo”; refused without the override; with
    DELETE the Team has Carla as its only member and Team Leader and “Solo”
    is gone); the admin deletes a Team (the Teams section's row, the warning
    and the second confirmation word for word, refused without the word,
    with a wrong word, with a wrong PIN and for a learner who is not an
    admin; with DELETE the Team is gone, its members stay and the Course
    still names the Team's ID; a Team with no Course says nobody loses
    access); the Team dialog (warning, Keep the Team, Delete the Team, the
    PIN, the word, the result).
- `test/device_administration_239_test.dart`: the wipe's reminder has no
  field for the words; the last dialog has the words' field below the PIN
  field, and its button stays greyed for five wrong spellings.
- `test/stored_course_edge_cases_266_test.dart`: Forget shows what it
  removes first, then the PIN in its own dialog, with no word field.
- Help, localization, Inventory and Team tests (16 files): 156 passed.
- `flutter analyze --no-pub`: no issues.
- Complete suite (`flutter test --no-pub --concurrency=1`, kept awake, TEMP
  on D:): **4,254 passed, 1 skipped**, 57:49 (11 October 2026, 22:53–23:51).

Not checked: the dialogs by hand.

## Revision 3 (2.0.71+271003), a save is faster and shows where it is

12 October 2026, owner's Windows 10 PC, `build-271`.

- Measurements (temporary tests, removed; the numbers are in
  `docs/271_CHANGE_SUMMARY.md`): a save of a Course with 700 small pictures,
  a save with 1 and with 31 stored Courses of the Exercise Laboratory's
  size, the listing of the versions; each before and after.
- `test/save_speed_271_test.dart`, 19 cases:
  - the backup: the second version writes its own file only and names the
    copies the first one made, and read on its own with every content
    checked it is whole; a copy is told by its name and its length (with
    the stored file and the copy both changed to another content of the
    same length, nothing is written or logged and the copy is left as it
    is); a stored file of another length is read and is a gap when it is
    not what its name says (logged); a copy of another length is written
    again with the right content; the progress is (0, n), (1, n) … (n, n),
    also when nothing is copied, and (0, 0) without media;
  - the versions: a version whose copy was changed is listed, refused by
    `loadBackup` with "A course backup asset failed integrity validation.",
    and refused by the restore with the same message while the Course's
    folder stays empty; with the right content again the restore puts the
    file back; a version whose file is gone is named in `skipped` and stops
    the strict listing;
  - the store: `leadingCourseId` for what QQL writes (also an ID with a
    quote, a backslash and an accent), for what follows a good beginning,
    and null for a file with spaces and line breaks, the ID not first, no
    comma after it, a number, an empty file, an ID longer than 1,024 bytes
    and a missing file; what `write` wrote begins with its ID; another
    Course's file that could not be read whole is passed over; a second
    file with the same ID is refused whatever its name and shape (compact,
    then with spaces and line breaks; `write` refuses too), and is no
    obstacle once it holds another ID; a file named for the Course that
    cannot be read is refused;
  - the steps: the seven labels word for word, a bar that never goes back
    and stays between 0 and 1; a real save of a Course with two pictures
    reports checking, the backup (0 of 0, 0 of 2, 1 of 2, 2 of 2), writing,
    checking what was written; a Course saved for the first time reports
    checking, writing, checking; a save with three stored Courses changes
    only its own;
  - the window: it is on the screen when the work starts, shows the first
    step and a bar at .05, then "Making the backup: 1 of 4 pictures and
    recordings" at .275, stays through Back and a tap on what is behind
    (the work is not started twice), and goes at the end with the result;
    when no frame is drawn, the save starts after a quarter of a second
    anyway; when the save throws, the window goes, the caller gets the
    error and the page is in use again.
- Eight test doubles take the new optional `onProgress` parameter (six
  `createBackup`, two `confirmCourseTransaction`).
- Focused, before the last changes to the store and the restore (22 files
  around saving and backups): 240 passed. After them (39 files, with the
  Help and version tests): 435 passed, 3 failed, all three in
  `beta_lifecycle_test`: its other dates had not moved by a day with the
  new expiry. Moved; the file passes. A first complete suite was stopped at
  574 passed, none failed, to add two safeguards found on rereading the
  code (a name that is not a media reference is a gap and never a path; a
  save does not wait for a frame while the window is hidden); the six files
  around them: 81 passed.
- `flutter analyze --no-pub`: no issues.
- Complete suite (`flutter test --no-pub --concurrency=1`, kept awake, TEMP
  on D:): **4,273 passed, 1 skipped (the usual one), none failed**, in
  56:04.

Not checked: the window and the speed by hand in the running app; a Course
with real pictures and recordings (the measurements use 4 × 4 pixel
pictures); Android.

## Revision 3 follow-up (2.0.71+271003, same version)

12 October 2026, owner's Windows 10 PC, `build-271`.

- Measurements (a temporary test, removed; the numbers are in
  `docs/271_CHANGE_SUMMARY.md`), before and after: the whole Audit of the
  Exercise Laboratory, the status of the same Course object asked again,
  the Course a page builds through JSON, `auditLesson`, `auditRound`; four
  searches, a category with a tag, and the sorting by name over the 4,334
  pictures.
- `test/audit_speed_271_test.dart`, 18 cases:
  - for each of seven Courses (the two bundled ones, the Edge Case fixture
    and its importable copy, the Laboratory of the future, the Korean
    fixture, and a Course with IDs repeated across Lessons): the findings
    of `auditLesson` for every Lesson and of `auditRound` for every Round
    are, line by line (severity, code, location, message, Round, exercise,
    type, date), the whole Audit's findings for them; a Lesson or Round the
    Course does not have gives none;
  - the same with the Course the source references are read from;
  - the Course made for it has what it is meant to have: a repeated ID, a
    missing source reference, and the Duel, module, Sentence and Word IDs
    that its Lesson 6 repeats from Lesson 1 found in Lesson 6;
  - for each of the seven Courses, `forLesson` answers as `fromCourse` for
    every Lesson (Rounds, GuideBook, the Lesson, Drafts), every Round and
    every exercise; a Lesson the Course does not have is all clear;
  - the same Course object gets the same status object; the same content
    in another object gets its own, with the same answers; a changed copy
    (its first Lesson without Rounds) is audited as it is.
- `test/image_search_keys_271_test.dart`, 4 cases: over the 4,334 pictures
  and 40 with Local words, 24 searches, a few hundred tags (real names and
  tags among them) and every category and group give what the rules gave as
  they were written before; a picture's keys are worked out once, and a changed
  picture is a new record with its own.
- Focused (56 files: every Audit test, every image library test, and the
  tests that read the borders): 457 passed. The two new files after their
  last change: 22 passed.
- `flutter analyze --no-pub`: no issues.
- Complete suite (`flutter test --no-pub --concurrency=1`, kept awake, TEMP
  on D:): **4,295 passed, 1 skipped (the usual one), none failed**, in
  56:29.

Not checked: the pages by hand in the running app; a Course much larger
than the Laboratory; Android.

## Revision 4 (2.0.71+271004), imports check what they bring in; Android file safety

12 October 2026, owner's Windows 10 PC, `build-271`.

- `test/import_safety_271_test.dart`, 12 cases:
  - a PNG made for it (every part in place and checked, picture data that
    is not a picture) passes the structure check and is refused when it is
    opened; a real picture passes both;
  - a Course package with that picture is refused, the message naming the
    file and saying "The image is damaged"; with a real picture the package
    is read;
  - an Image Bank with that picture is refused ("Image Bank image
    thing.png: The image is damaged…"); with a real picture it is read;
  - someone else's Private course is refused by install, Copy as New Course
    and Fork, nothing is stored, and its Maintainer imports it;
  - a Course whose Audit has an error (no source language) is refused by
    the three actions with the screen's sentence, nothing is stored, and
    the same Course without the error is imported;
  - a refused attempt has ended (a second use is a StateError);
  - the two refusals word for word, and the screen's texts are these;
  - a stored Private course of another learner with the same ID: the review
    marks it hidden and the dialog's text is "A custom Course with ID
    “shared” already exists: a Private course. …", without its title; a
    Course the learner may see is named; a stored Course this version
    cannot open, hidden and not;
  - versions: 2 before 10, 1.10 after 1.9, 1.0 equal to 1, 1.02 equal to
    1.2, numbers of 20 digits; 1.0.rc after 1.0.beta (before: equal),
    2026-10 after 2026-09, 1.0b after 1.0a, 1.0.beta after 1.0, spaces
    around the parts ignored.
- `test/android_storage_bridge_255_test.dart`: a document that cannot be
  opened is left as it is (nothing asks for it to be deleted, its content is
  unchanged, the save is reported as failed).
- The pinned version tests: the visible label "Build 271, Revision 4" (four
  test files), `correctiveRevision` 4.
- Focused, the Dart changes before the new tests (62 files around imports,
  packages, Image Banks and Publisher versions): 797 passed. The two test
  files above: 26 passed.
- Android: `flutter build apk --debug` builds (the Kotlin changes compile).
  On the Android 16 emulator, what `docs/271_CHANGE_SUMMARY.md` lists under
  "Checked on the emulator, and not".
- `flutter analyze --no-pub`: no issues.
- Complete suite (`flutter test --no-pub --concurrency=1`, kept awake, TEMP
  on D:): **4,308 passed, 1 skipped (the usual one), none failed**, in
  57:19.

Not checked: Android 10; Wipe out everything on the emulator; a chosen file
that cannot be opened; the time a large Image Bank now takes to read; the
dialogs by hand on Windows.

## Revision 5 (2.0.71+271005), the names of a Course's items stay in English; tidy-ups

12 October 2026, owner's Windows 10 PC, `build-271`.

- `test/labels_in_english_271_test.dart`, 12 cases:
  - the catalogs: every text whose English names a Lesson, a Round, a
    Story, a Sequence, a Duel or the GuideBook writes that name, with its
    capital, in each of the six translations, and the nine texts that name
    the Review page write "Review" (more than 250 checks); no text of the
    six languages uses its own word for one of them (lezione, storia,
    duello, ripasso, ronda, Runde, leçon…), except the two texts of a
    Round's own repetition; fifteen Italian texts word for word; the three
    removed keys are in none of the seven catalogs;
  - the Round screen of a Course whose learners read Italian: "English ·
    Lesson 1: Primi passi" with "Controlla" beside it and no "Lezione";
    an author's label ("Unità 1: Primi passi") and no label ("Primi
    passi"); in Review the line "… · Lesson 1: Primi passi · Round 1:
    Practice · Saluti", the title "Review · Practice · Saluti" and no
    "Ripasso";
  - the Audio Library: the groups of Ukrainian, Serbian and Kazakh texts in
    the order of their alphabets, Latin and Greek as before, and texts in
    alphabet order inside a group;
  - Course Info Editor opened, applied and closed twice, the test ending at
    once (before, the pending timer failed such a test);
  - the seams: a test replaces all three, and the next test finds the app's
    own again.
- The test found one text the first pass had missed: Spanish "Bonificación
  por ronda perfecta" (the English says "Perfect bonus", without the name).
  Now "Bonificación por Round perfecto".
- Focused (44 files around the learner panel, the Review, the
  Round screen, the Duel, the Audio Library, Course Info, Help and the
  version pins): **362 passed**.
- `flutter analyze --no-pub`: no issues.
- Complete suite (`flutter test --no-pub --concurrency=1`, kept awake, TEMP
  on D:): **4,319 passed, 1 skipped, 1 failed** (77:41; the earlier runs
  of Build 271 took about 57 minutes).
- The one failure is a time limit, not a wrong result:
  `course_backups_270_test`, "Course Info sets the number and the Course
  Editor's save asks". Its wait for the Course Info Editor to open allows
  10 seconds of real time, and it ran out while the PC was stalled: the
  browsers were open, 0.7 GB of 8 GB of memory was free, and the test just
  before it, which takes one second, took three minutes. That file run
  alone straight afterwards: **11 passed**. Revision 5 does not change how
  the Course Info Editor opens the first time. The suite was not run again.

Not checked: the screens by hand in the running app; the German, Portuguese,
Dutch and French texts by a speaker of those languages (the articles are
the AI's); Android.
