# Build 255 validation

Plan and audit: [255_STORAGE_PLAN.md](255_STORAGE_PLAN.md). Handoff:
[255_HANDOFF.md](255_HANDOFF.md).

## Revision 0 — `2.0.55+255000`, 25 September 2026

Beta expiry `2026-10-25 23:59:59` local time (30 days from the release date).

### Scope

Logical storage roles and layout (`lib/services/storage/`); every Quick route
moved onto them; Course Quick folders `Imports/Courses` and `Exports/Courses`
on Windows, Linux and macOS; renames (Quick Import, Quick Export, Save as…);
folder names in screens, fallback hints and EN/IT/ES Help through the layout.
Course Model v11, package format 1, rights, scoring, progression and learner
data are unchanged.

### Focused evidence during implementation

- New `test/storage_roles_255_test.dart` (13 tests): Course folders on every
  desktop platform (and iOS) resolve to `Imports/Courses` and
  `Exports/Courses`; every other role keeps its desktop place; roles and Help
  placeholders are unique and complete; every Help entry in all three
  languages resolves with no raw `{folder…}` placeholder and no literal Quick
  folder, and translations never name a folder English does not; a caller's
  own value still wins; the file-system backend creates import folders when
  asked and export folders on first write, lists ordinary files only, finds
  exact names, refuses links (where the host allows creating one), writes
  `_2`/`_3` and replaces on request, and `readQuickImportFile` enforces its
  limit; Course Quick Export and Quick Import use the new folders **without
  any dialog call**; an `import.zip` in the old `Imports` place is not read;
  an empty `import.zip` reports "import.zip is empty.".
- Adapted tests for the removed path methods (`transferDirectory`,
  `importDirectory`, `importFilePath`, `fixedImportDirectory`, …) now use the
  storage roles or `test/support/quick_folders.dart`; source-text contracts
  (Recovery Key folders, QuisquisLingo branding) now check the roles and the
  storage layer that name the folders.
- The first focused run found two real problems, both fixed: the Debug page
  created the Logs folder merely to display its path (a widget test timed
  out), so export folders are now created by their first write, as before;
  and the Diagnostic Log file name constant is spelled out again.

### Test-wait change (owner request, separate commit)

`test/exercise_laboratory_254_test.dart` (`_until`) and
`test/script_recognition_226_03_test.dart` (`_waitForImageAction`) now allow
up to 10 seconds of real time for real file and decoder work, like the shared
`pumpUntilFileIoState`; the fake clock still advances at most 100 steps
exactly as before, so no exercise timing changes. Reason: during Revision 0
validation the PC was heavily loaded by other programs (CPU 70–80%), and all
44 Laboratory "learner completes" tests timed out after about one second of
real time, although the file passes 165/165 when run alone. After the change
both files pass (188/188).

### Final release checks

`flutter analyze --no-pub`: **No issues found**.

Complete-suite history, all with `flutter test --no-pub --concurrency=1`
except the first:

1. A parallel run (default concurrency) was stopped after one known-style
   file-I/O timing failure in `device_administration_239_test.dart`, which
   passed 21/21 alone.
2. Two sequential runs were stopped while the PC was overloaded (see above).
3. The run after the test-wait change: **2,697 passed, 1 existing skip,
   1 failed** in 24 min 51 s. The failure was a version test
   (`qql_229_revision3_test.dart` still expected build `254`); fixed, and the
   five version test files passed (27/27).
4. Final complete run on the final tree: **2,698 passed, 1 existing skip,
   0 failed** in 23 min 42 s. No production or test file changed after it.

Revision 0 is a source revision; no Windows or Android package was built.

## Revision 1 — `2.0.55+255001`, 25 September 2026

Beta expiry `2026-10-25 23:59:59` local time.

### Scope

Android Save as… and Open from… through the Storage Access Framework:
`QqlStorageBridge.kt` (registered by `MainActivity`), the Dart bridge
`android_storage_bridge.dart`, `AndroidFileDialogBackend`,
`FileDialogService.backendFor(QqlStoragePlatform)` and
`ExternalFileSource.document`. Quick Import and Quick Export are unchanged.

### Focused evidence

- New `test/android_storage_bridge_255_test.dart` (13 tests, mocked Android
  channels): a save writes all bytes in chunks of at most 1 MB and names the
  document; a cancelled save writes and says nothing; a failed write deletes
  the new document and the Diagnostic Log never contains a document address;
  Open from… streams the document into staging and returns its bytes; reading
  stops as soon as the caller's limit is passed; a provider failure part-way
  and an unreadable document fail cleanly with the ordinary messages; a
  cancelled picker opens nothing; provider names are sanitized for display
  while the exact name is kept for checks; several documents stage one by one
  within the batch limits; a real Course package opened from a document passes
  the ordinary package checks; picker filters are generous hints and saves
  declare one type; Android gets the document pickers while desktops keep
  theirs and iOS has none. Every handle is closed in every case.
- `flutter build apk --debug --no-pub` compiled the Kotlin bridge (134 s).
- Android 16 emulator (Pixel_8 AVD, API 36), debug APK, fresh test profile:
  Course Studio → Export Course showed **Quick Export** and **Save as…**;
  Save as… opened Android's save screen in Downloads with the suggested name,
  and saving wrote `quisquislingo_ai_slop_demo_german_for_english_speakers.zip`
  (33,011 bytes, a valid package: manifest plus `course.json`, Course Model
  v11, 9 Lessons). Course Import → **Open from…** listed that ZIP, and picking
  it read it through the bridge and the ordinary checks, which correctly
  refused to reinstall a bundled official Course ("Bundled official courses
  are installed only with QuisquisLingo application builds."). Cancelling the
  picker showed nothing.
- Not tested on a device: Android 7–10 (no emulator images, owner decision);
  the Storage Access Framework screens are the same there.

### Final release checks

`flutter analyze --no-pub`: **No issues found**. Complete
`flutter test --no-pub --concurrency=1` on the final tree: **2,711 passed,
1 existing skip, 0 failed** in 23 min 29 s. No production or test file changed
after it. A debug APK was built for the emulator check; no release package.

## Revision 2 — `2.0.55+255002`, 26 September 2026

Beta expiry `2026-10-26 23:59:59` local time (30 days from this revision's
release date).

### Scope

Android public Quick folders: `QqlStorageLayout.androidPublic`,
`AndroidStorageBackend` (MediaStore Quick Export; persisted folder permission
for Quick Import; Android 7–9 storage permission), `QuickFolders.kt`,
`ensureQuickImportAccess` at every Quick Import button, Inventory and Wipe
everything for the public folders, honest Inventory and Help wording on
Android, `WRITE_EXTERNAL_STORAGE` (`maxSdkVersion 28`).

### Focused evidence

- New `test/android_quick_folders_255_test.dart` (20 tests, mocked Android
  side in `test/support/fake_android_storage.dart`): every role's Android
  folder; Help names the Android folders (and says where the Crash Log is);
  Quick Export writes to `Download/QuisquisLingo/Exports/Courses` with `_2`
  naming and **no screen or dialog call**; the Diagnostic Log snapshot
  replaces its copy; Quick Import without access reads nothing and uses no
  private folder; with access it reads `Imports/Courses` through the ordinary
  checks with no dialog; an empty folder names the Android folder; a deleted
  folder and a permission revoked between check and read both ask again;
  every answer of the folder screen maps correctly and only "granted" gives
  access; Android 7–9 Quick Export asks for the storage permission, writes to
  Download and announces the file, a refused permission writes nothing, and
  Quick Import reads Download once the permission is held; Inventory lists
  QQL's exports and, with access, the Imports files; a full wipe follows the
  Keep ticks and always gives back the folder permission; the explanation
  goes straight on where access exists, asks once, honours Open from…
  instead and Cancel, hides Open from… where there is none, and explains a
  wrong folder.
- `flutter build apk --debug --no-pub` compiled `QuickFolders.kt` and the
  extended bridge.
- Android 16 emulator (Pixel_8 AVD, API 36), debug APK, fresh test profile:
  1. Course Quick Export wrote
     `Download/QuisquisLingo/Exports/Courses/quisquislingo_ai_slop_demo_german_for_english_speakers.zip`
     with no dialog, and a second export `_2.zip`.
  2. The first Quick Import showed the explanation (folder, steps, Open from…
     instead); Continue opened Android's folder screen exactly on
     `Download › QuisquisLingo › Imports`, which QQL had created; Use this
     folder and Allow granted it; QQL created `Courses`, `Merges`, `Audio`,
     `Images` and `Lesson Icons` inside and reported that no Course file was
     there yet.
  3. With a package copied into `Imports/Courses/import.zip` by another app
     (adb), Quick Import read it with no dialog; a bundled Course was
     correctly refused, and a forked Course reached the same-ID choice and
     imported as a new Course.
  4. Export my data wrote `Download/QuisquisLingo/Exports/…_backup.json`;
     Import my data read `Imports/learner_import.json` with no dialog.
  5. Moving the Imports folder away made Quick Import ask again; Open from…
     instead opened Android's document picker; moving it back restored access
     with no dialog.
  6. Inventory listed "Quick Export folder (3)" and "Quick Import folder (1)"
     with their Download locations.
  7. Wipe everything with Keep Exports and Keep Imports unticked removed every
     file below `Download/QuisquisLingo` (QQL's own exports and the copied-in
     imports) and QQL no longer held any URI permission
     (`dumpsys activity permissions`).
- Not tested on a device: Android 10 (folder creation before the folder
  screen, by a pending MediaStore placeholder) and Android 7–9 (storage
  permission); owner decision to skip emulator downloads. Both are covered by
  the mocked tests above.

### Final release checks

`flutter analyze --no-pub`: **No issues found**. Complete
`flutter test --no-pub --concurrency=1` on the final tree: **2,731 passed,
1 existing skip, 0 failed** in 21 min 33 s. No production or test file changed
after it. A debug APK was built for the emulator checks; no release package.

## Revision 3 — `2.0.55+255003`, 26 September 2026

Beta expiry `2026-10-26 23:59:59` local time (unchanged: released on the same
day as Revision 2).

### Scope

One folder pattern on every system (owner decisions of 26 September 2026,
see the plan): `Import`, `Export`, `Logs` and `ToBeMerged` below the
QuisquisLingo folder, one subfolder per kind without spaces; Upload custom
flag reads `Import/Flags`; exported files start with `QQL_`; the live Crash
Log and Course Backups are private on every system; a Crash Log Quick Export
button in Settings › Debug; Android's one folder permission covers the whole
`Download/QuisquisLingo`; Inventory and Wipe everything follow the four
folders and treat the earlier `Imports`, `Exports` and `Merges` like their
replacements. EN/IT/ES Help name the new folders through placeholders
(`{folderExport}`, `{folderLogs}`, … and `{folderRoot}` join the role
placeholders).

### Focused evidence

- New `test/universal_folders_255_test.dart` (6 tests): the flag is read from
  `Import/Flags` and not from the old `Exports`; learner backups and the
  Diagnostic Log copy are named `QQL_…` in `Export/UserData` and `Logs`; the
  live Crash Log (`<support>/qql_logs`) and Course Backups
  (`<support>/qql_course_backups_v11`) are private; the Crash Log Quick Export
  copies the live log to `Logs/QQL_crash_log.txt` and replaces its copy;
  desktop Inventory lists the four folders, the two private folders, the
  earlier folders (with an old Course backup recognised) and other files;
  a full wipe keeps each ticked folder with its earlier counterpart, always
  removes Course Backups and removes the private Crash Log only with Logs.
- `test/android_quick_folders_255_test.dart` (22 tests, rewritten for the new
  layout): every Android folder equals the desktop one below
  `Download/QuisquisLingo`; Help names them; Quick Export and the Diagnostic
  and Crash Log copies write `Export/…` and `Logs/…` with no dialog; Quick
  Import without permission names `Download/QuisquisLingo`; with it, Import
  reads `Import/Courses` and Merge reads `ToBeMerged/Courses` through the same
  permission; granting it asks Android to create exactly the eight Import and
  ToBeMerged folders; Android 7–9 writes and reads the new folders; Inventory
  lists Export and Logs (QQL's own entries) and, with access, Import and
  ToBeMerged; a full wipe follows each of the three ticks separately.
- `test/storage_roles_255_test.dart` (13): the one-pattern table for every
  role, no spaces, the Help placeholders (roles, four folders, root), no
  catalog spelling out a folder path or an old `Imports/`, `Exports/` or
  `Merges/` path, and the Course Quick routes with `QQL_` names.
- Test environment: 34 test files give path_provider only app support. The
  Crash Log used to live in the documents folder, so it was unavailable there;
  now in app support, its real file writes stalled widget flows in fake time
  (the first batch showed this in `audio_settings_runtime_228_04_test` and
  `field_guidance_226_03_r1_test`; a blocker file did not help, because
  creating the folder is itself real I/O). Those files now call
  `keepCrashLogUnavailable()` from `test/support/test_directories.dart`,
  which uses the test-only `CrashLogService.debugMarkUnavailable()` and keeps
  their earlier environment exactly, without touching storage.
- The first sequential run of the 54 affected files (559 passed, 51 failed)
  found only expected changes: old folder names and file names in 20 test
  files, the renamed backup seam in three `CourseBackupService` subclasses, and
  the Crash Log environment above. All were updated.
- The first complete run (2,738 passed, 1 existing skip, 1 failed) found that
  `docs/PUBLISHER_SIGNING_GUIDE.md` must follow the changed English Help word
  for word; the guide was updated and `publisher_signing_help_test` passes.
- `flutter build apk --debug --no-pub` built `versionCode 255003` with the
  changed Kotlin (143 s).
- Android 16 emulator (Pixel_8 AVD, API 36), fresh install, test profile:
  1. The first-run Beta message and Settings › Debug show the live Crash Log
     at `/data/user/0/org.quisquislingo.app/files/qql_logs/quisquislingo_crash.log`;
     Debug shows the Quick Export location
     `Download/QuisquisLingo/Logs/QQL_crash_log.txt`.
  2. **Quick Export Crash Log** wrote that file (1,016 bytes) with no dialog;
     pressing it again replaced it (one file, newer time).
  3. Course Studio › Export Course › **Quick Export** wrote
     `Download/QuisquisLingo/Export/Courses/QQL_ai_slop_demo_german_for_english_speakers.zip`
     (33,011 bytes) with no dialog.
  4. The first **Quick Import** explained that QQL reads the Import and
     ToBeMerged folders of `Download/QuisquisLingo` and offered Open from…;
     Continue opened Android's folder screen exactly on
     `Download › QuisquisLingo`; Use this folder and Allow granted it
     (`dumpsys`: persisted tree
     `primary%3ADownload%2FQuisquisLingo`), and QQL created `Import/Audio`,
     `Courses`, `Flags`, `Images`, `LessonIcons`, `RecoveryKeys`, `UserData`
     and `ToBeMerged/Courses`.
  5. With a package in `Import/Courses/import.zip`, Quick Import read it with
     no dialog (a bundled Course, correctly refused).
  6. For a new custom Course, **Merge Course package or JSON** read
     `ToBeMerged/Courses` through the same permission with no dialog: first
     "No Course file found… Download/QuisquisLingo/ToBeMerged/Courses", then,
     with `merge.zip` there, the package was read (a bundled Course, correctly
     refused).
  7. Inventory listed Course backups and Crash Log (private, in `files/`),
     and the Export, Import, ToBeMerged and Logs folders with their files.
  8. Wipe everything with Keep Export and Keep Import unticked and Keep Logs
     ticked emptied `Export/Courses`, `Import` and `ToBeMerged`, kept
     `Logs/QQL_crash_log.txt`, and released the folder permission
     (`persisted=0x0`).
  9. No crash or Flutter error in the device log.
- The check showed that the one-time Beta testing message still told testers
  to attach the live Crash Log from its (now private) path. `lib/main.dart`
  now tells them to attach the copy Quick Export makes and still shows where
  the live log is kept. No test reads that sentence; the startup tests pass.

### Final release checks

`flutter analyze --no-pub`: **No issues found**. Complete
`flutter test --no-pub --concurrency=1` on the final tree: **2,739 passed,
1 existing skip, 0 failed** in 27 min 42 s. No production or test file
changed after it. A debug APK was built for the emulator check; no release
package.

## Revision 4 — `2.0.55+255004`, 26 September 2026

Beta expiry `2026-10-26 23:59:59` local time (unchanged: released on the same
day as Revision 3).

### Scope

Private folders and language pairs (owner decisions of 26 September 2026,
see the plan): QQL's private storage uses `QQL_` names (`QQL_Courses`,
`QQL_CourseMedia`, `QQL_CourseBackups`, `QQL_SharedImages`, `QQL_ImageBanks`,
`QQL_ImportStaging`, `QQL_Logs` with `QQL_crash.log` and
`QQL_session.marker`); every per-Course name carries the language pair,
source then target (`QQL_EN_IT_<ID>.json`, media `QQL_EN_IT_<hash>`, backups
`QQL_bkp_EN_IT_<ID>/…_v<version>_<stamp>.json`, exports
`QQL_EN_IT_<title>.zip`, historical exports `QQL_bkp_EN_IT_<title>_v3.zip`);
no language folder levels; the backup format is unchanged; clean cut with a
one-off tool, `tools/move_private_storage_255.dart`.

### Focused evidence

- New `test/private_storage_names_255_test.dart` (12 tests): language codes
  (tag, name table, the name itself cut to 16, `UNKNOWN`) and pairs
  (`IT_NAP`, the learning language when no target is named); file, media,
  backup and export names, including a QQL-made ID written once and an empty
  version saved as `v0`; the Course store names Custom (`course`) and
  Publisher (`source`) entries by their pair, renames a file in place on
  `replaceIfUnchanged` and on `write`, finds a file by the ID inside it
  whatever its name, and never replaces a taken name (`course_ab` and `ab`
  share the name part `ab`: both are stored, and a rename onto the other's
  name is refused); a confirmed language change through
  `CourseEditorService` renames the Course file, its media folder (which was
  `QQL_<hash>` before the first save) and its backup folder, while the saved
  version keeps the name of the languages it had; `qql_logs` becomes
  `QQL_Logs` only where case is ignored and earlier folders are matched by
  exact name; both Android Auto Backup files exclude every bulk media folder,
  new and earlier.
- New `test/move_private_storage_255_test.dart` (4): the tool moves a
  Revision 3 layout (Courses of both kinds, media, a private backup folder
  and a Documents backup folder made by the app's own services) to the new
  names, where `CourseFileStore`, `CourseMediaStore` and
  `CourseBackupService.listBackups`/`reinstateMedia` read it; a dry run
  changes nothing; a Course or file already under the new names is never
  overwritten and is reported; option parsing and the Windows defaults.
- `app_reset_service_239_test`: imported media removes the new and the
  earlier image and bank folders; Wipe everything removes the earlier
  private folders, the earlier Crash Log only with Logs (two new tests).
- `inventory_239_test`, `universal_folders_255_test`: the pair-named Course
  file, media owners found by the ID hash, images and banks from old and new
  folders, the new "Private folders from earlier versions" section.
- Existing tests follow the new names (export names now carry `EN_IT`; the
  race and corruption tests write the file the store actually uses). Three
  widget tests waited a fixed number of frames for file work that Revision 4
  lengthened (Version History now finds its folder by listing, Inventory and
  the media dialog read more folders); they now wait for the expected screen
  state with the repo's `pumpUntilFileIoState` (10 s real-time bound).
- Dry run of the tool on the development PC's real data: 6 Courses and 6
  media folders (22 files) would move to `QQL_Courses/Custom` and
  `QQL_CourseMedia` as `EN_IT`; no earlier backups there. Nothing was
  changed; the owner runs it.
- A case-only folder rename (`qql_logs` → `QQL_Logs`) was checked directly
  on Windows with the project's Dart: it keeps the folder and its files.

- `flutter build apk --debug --no-pub` built `versionCode 255004` (200 s).
- Android 16 emulator (Pixel_8 AVD, API 36), installed over the 2.0.42 build
  the image still held, with Revision 3's private folders laid out by hand
  in the app's `files/` (`qql_logs/quisquislingo_crash.log`,
  `qql_courses_v2/custom/course_earlier.json`,
  `quisquislingo_course_media/course_<hash>/aa.png`,
  `qql_course_backups_v11/course_earlier/…json`,
  `qql_import_staging/left.part`), and a new test profile:
  1. At start QQL created `files/QQL_Logs/QQL_crash.log` and left every
     earlier folder untouched; Android tells case apart, so `qql_logs` stayed
     a separate folder, as intended.
  2. The first-run Beta message and Settings › Debug show the live Crash Log
     at `/data/user/0/org.quisquislingo.app/files/QQL_Logs/QQL_crash.log`;
     the Quick Export location is unchanged
     (`Download/QuisquisLingo/Logs/QQL_crash_log.txt`).
  3. Course Studio › AI-Slop Demo: Napoletano per italofoni › Export Course ›
     **Quick Export** wrote
     `Download/QuisquisLingo/Export/Courses/QQL_IT_NAP_ai_slop_demo_napoletano_per_italofoni.zip`
     (32,760 bytes) with no dialog: Italian → Neapolitan is `IT_NAP`.
  4. **Fork** of Exercise Laboratory stored
     `files/QQL_Courses/Custom/QQL_EN_IT_e1729b00-2fc8-4a1b-ab54-7d709e3eb96c.json`
     for the Course ID `course_e1729b00-…`: the pair is there and `course_` is
     not repeated.
  5. Inventory listed the fork by title and owner with that file, the Crash
     Log in `QQL_Logs`, the 2.0.42 build's documents-folder log under
     "Folders from earlier versions", and the five earlier files under the new
     "Private folders from earlier versions", each with its note.
  6. Wipe everything with all three Keep choices ticked removed
     `QQL_Courses` and the four earlier internal folders, kept `QQL_Logs` and
     the earlier `qql_logs` (Logs choice) and the exported ZIP (Export
     choice).
  7. No Flutter error or crash from QQL in the device log; QQL's own Crash Log
     holds only the session header and debug events.
- Not checked on the device: the rename after a language change (Course Info
  is read-only until the Editor is in Edit mode; the unit test runs the same
  `CourseEditorService` path) and the tool, which is for desktops.

### Final release checks

`flutter analyze --no-pub`: **No issues found**. Complete
`flutter test --no-pub --concurrency=1` on the final tree: **2,757 passed,
1 existing skip, 0 failed** in 23 min 42 s. No production or test file
changed after it. A debug APK was built for the emulator check; no release
package.
