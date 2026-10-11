# QQL Build 271 plan

Owner decisions of 10 and 11 October 2026, after Build 270 Revision 13
(`c3f783a4`). Build 271 fixes the more relevant open findings of the Build 270
audit (`docs/270_AUDIT.md`), the side findings of the modularization audit
(`docs/272_MODULARIZATION_PLAN.md`) and two older findings (Build 259 C and
E), and reorganizes the Audio Library.

Every revision: version `2.0.71+271RRR`, Beta expiry 30 days from its release
day, `CHANGELOG.md`, `README.md`, the `AGENTS.md` release entry,
`docs/271_CHANGE_SUMMARY.md`, `docs/271_VALIDATION.md`,
`docs/271_HANDOFF.md`; focused tests while working, `flutter analyze` and the
complete suite once on the final tree; one commit, the branch pushed. Help
EN/IT/ES wherever a screen changes.

## Revision 0: content that plays wrong

- **Missing letters**: the optional Spoken text is stored as optional audio
  (`required: false`), so with Audio Exercises off the exercise is no longer
  skipped. Exercises already stored keep their audio as it is (owner: no
  handling of earlier exercises). The Laboratory generator and the bundled
  Laboratory are regenerated so its example is right.
- **Put the sentences in order**: saving marks its blocks as lines (a role on
  the blocks' elements, registered in `ElementRoles`), and
  `ExerciseFeatures.isLineOrder` reads the mark. The guess from the text (three
  words or a closing . ! ?) remains only for exercises without it. Today two
  short lines ("Ciao Anna", "Ciao Marco") show the title PUT THE SENTENCES IN
  ORDER with the line "Arrange the words in the correct order."
- **The Audit flow** copies the whole Round instead of rebuilding it field by
  field (`course_editor_screen.dart`, the Round rebuilt in the Audit flow), so
  a future Round field cannot be dropped there.

## Revision 1: deleting a Course; saves never blocked

- **Delete checks other learners first**: every other learner on this device
  whose Course list shows the Course (`CourseLibraryService.contains`: added
  it, or has progress on it) is named: "Anna and Marco have this Course in
  their courses. Delete it anyway?"
- **Delete asks two more things**, both off by default: **also reset my
  progress on this Course** (the reset of Remove from my courses: completed
  Rounds and Lessons, Laurels, Duels, GuideBooks read, recent Rounds; XP,
  Weekly XP, study days and streaks kept) and **also delete all its
  backups** (its versions in `Backups/Courses` and the media only they hold).
- **A backup never blocks a save**: a stored media file whose bytes no longer
  match its name is recorded as a gap, like a missing one, and logged, instead
  of stopping every later save of the Course (`course_backup_service.dart`).
- Leftover `*.tmp` files in the Course store are cleaned up at start-up; on
  Linux and macOS the folder is flushed after a rename.
- A Publisher update over an unreadable stored copy keeps a backup of that
  copy. (Dropped on 11 October 2026, owner decision: the copy could not be
  used inside QQL and held nothing of the user's.)
- Added on 11 October 2026 (owner decisions): the Inventory deletes the
  media folder of a Course no longer on the device with one action; its
  Delete on a Course names the learners who have it and those who kept
  progress on it, and can reset everyone's progress on it and delete its
  backups (also for a Publisher Course, which keeps everything by default);
  removing a Course this version cannot open can delete its backups too.

## Revision 2: the Audio Library like the Image Library; the Course Editor's top bar

Audio Library:
- **Top bar, three icons**: **Help** (the Editor Help opened at its sound
  questions: audio modes, adding recordings, how recordings travel);
  **Add to the Course** (a menu: Quick Import, Open from…); **Check** (a menu:
  Texts in this Course, Unused MP3 files).
- **Fixed area**: the one-line notice, the audio source with a one-line
  explanation, the A–Z bar; only the groups and recordings scroll.
- **The one-line notice**, word for word the same in the Audio Library and a
  Course's Image Library (one shared constant): "Changes are applied to the
  Course when you leave; Save now or Save course writes them."
- **The audio source's line**:
  - On-Device TTS: "The device's voice reads every text; no recordings are
    needed."
  - Recorded MP3 only: "Only your recordings play; a text without a complete
    recording stays silent."
  - Hybrid: MP3 + TTS fallback: "Your recordings play first; the device's
    voice reads a text they don't fully cover."
  - What leaves the screen goes to the Help answers: the longest recordings
    are joined, how to give a recording its text, where Quick Import reads,
    Discard changes also removes recordings imported since the last save.
- **Rows** no longer show the file name; a recording without text says "Tap
  to give it its text".
- **Associate recording**: the original file name (when known) and the stored
  file name in full; **Play**; **Open folder** where the system allows it
  (Windows, Linux, macOS; `FolderOpener`); Word or expression; **Texts in
  this Course**. Applying a text that already has its own recording asks:
  "'Buongiorno.' already has a recording. Replace it? The old one loses its
  text and moves under #."
- **Texts in this Course** (from Associate recording, where a tap fills the
  field, and from the Check menu): every text the Course speaks
  (`CourseAudioUsage.spokenTexts`), Draft exercises included and marked
  Draft; alphabetical, ignoring accents and punctuation; how many exercises
  say each text; a search box; four states, each a dot and a few words:
  - its own recording (one recording says exactly this text),
  - all parts recorded (recordings of its parts join into it),
  - some parts recorded ("still missing: …"),
  - no recording.
  **Copy** and **Save as…** (a `.txt` file through the system dialog): one
  text per line with its state and Draft mark; a switch "Only texts without a
  complete recording" for a recording session.
- **The original file name**: an optional field on each recording, set by
  Quick Import and Open from…: the base name only (no folders), control
  characters removed, at most 120 characters; a label, never a path; shown in
  Associate recording; removed by Export as Publisher Course, as Editor Notes.
  Recordings imported earlier show only the stored name. Owner: no concern for
  older app versions.

Image Library (a Course's own):
- The same one-line notice.
- **Help** opens the Editor Help at its picture questions; a new question on
  the badges (QQL, DEVICE, COURSE, IN USE); "Saving your changes" joins the
  answer on adding pictures; `ImageLibraryHelpScreen` and its QQL Guide entry
  are removed. EN/IT/ES.

Course Editor main page, three icons:
- **Save now** becomes an icon (greyed when there is nothing to save; tooltip
  "Save now: write a new version and keep editing"); "Unsaved changes" stays
  under the title.
- **Show internal IDs** moves into the Course Info dialog, whose IDs it
  controls (Course ID, User, Team); the other Editor pages keep their toggle.
- The access mode and Help are unchanged.

## Revision 3: speed

- The Course Editor's main page audits once per change of the working copy,
  not on every rebuild; Lesson and Round Audits check only their own Lesson
  or Round.
- A Course save reads the stored Courses once, not several times; measured
  first with a test of many Courses, then, if needed, decoding moves off the
  screen's thread.
- Image library search uses precomputed search keys and filters after a short
  pause instead of on every keystroke.

## Revision 4: import and Android file safety

- Pictures from packages and Image Banks are test-decoded once at import
  (`ImageValidator.validate`).
- The service re-checks the import refusals (someone else's Private course,
  Audit errors), not only the screen.
- The import collision dialog says "a Private course" instead of its title.
- Version comparison compares non-numeric parts as text instead of counting
  them as 0.
- Android: Save as… never deletes the file the user chose when opening it
  fails; Android 10 MediaStore deletes touch only QQL's own entries. Checked on
  the emulator.

## Revision 5: tidy-ups

- **Labels are never translated** (owner): the Round screen's Lesson line and
  Review show the label as the learner path does ("Lesson 2", or the author's
  label), and Review's "Round N" too; the words around them stay in the
  learner's language (`LessonPresentationService.panelNamesLessons` goes).
- The Audio Library index puts Cyrillic letters in alphabet order (Ukrainian
  Є, І, Ї after their neighbours, not before А).
- The Round screen places its mascot after the frame instead of writing state
  during build.
- Test seams reset between tests (`RoundScreen.openLink`,
  `RoundScreen.lineStopwatch`, `SpokenLinePace.shared`).
- Course Info disposes its controllers normally (no 300 ms delay).

## Not in Build 271

- Android release signing with the owner's key (later, owner decision).
- The modularization (its own build, ownership first,
  `docs/272_MODULARIZATION_PLAN.md`), with the import cycle between
  `LearningRound.fromJson` and `RoundTypeCompatibility`.
- Device image metadata out of one growing preference value.
- The Windows TTS length cap (32,767 characters).
- `tools/cloud_setup.sh` (the owner's untracked file).
- The local tags and branch that hold the private Piedmontese files: deleted
  only on the owner's explicit go.
- The owner's Windows Narrator check of Word Lookup.

## Order and branch

Owner decisions of 11 October 2026: the revisions in the order above;
`build-270` is merged into `main` first and `build-271` starts from `main`.
The modularization plan is `docs/272_MODULARIZATION_PLAN.md`, for Build 272.
