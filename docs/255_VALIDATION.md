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

## Revision 5 — `2.0.55+255005`, 26 September 2026

Beta expiry `2026-10-26 23:59:59` local time (unchanged: released on the same
day as Revision 4).

### Scope

The Backups folder (owner decisions of 26 September 2026, see the plan):
Course Backups leave QQL's private storage for `QuisquisLingo/Backups/Courses`,
beside Import, Export, Logs and ToBeMerged, on every system; learner backups
stay in `Export/UserData`; Wipe everything gains "Keep the Backups folder",
ticked by default. Android uses ordinary files in the Download folder (no
permission from Android 11; the storage permission on Android 7–10, Android 10
through the legacy storage flag). Version History lists readable versions and
names other files. The one-off tool moves every earlier backup into the new
folder.

### Focused evidence

- Layout: `QqlTopFolder.backups` (`Backups`) with `courseBackupsSegments`
  (`Backups/Courses`) and `courseBackupsLabel`; `{folderBackups}` joins the
  Help placeholders (`storage_roles_255_test`).
- `test/backups_folder_255_test.dart` (2): a file in a Course's backup folder
  that is not a backup is named in `skipped` and left unchanged while the
  strict listing still refuses; Version History shows the readable version
  and the skipped-file note.
- `android_quick_folders_255_test` (3 new): on Android 11 and later the
  Backups folder is `<Download>/QuisquisLingo/Backups/Courses` with no
  permission, and a backup written there is read back; on Android 7–10 the
  storage permission is asked, and a refusal throws
  `CourseBackupsAccessDenied` naming `Download/QuisquisLingo/Backups/Courses`;
  Inventory lists the folder and Wipe everything follows its tick.
- `app_reset_service_239_test`: the earlier private backup folders
  (`qql_course_backups_v11`, `QQL_CourseBackups`) follow the Backups choice
  and the earlier logs the Logs choice; the public Backups folder is kept by
  default and removed only when unticked.
- `device_administration_239_test`: the fourth tick, visible without
  scrolling and ticked, and its reminder in the last step.
- `inventory_239_test`, `universal_folders_255_test`: the Backups folder
  section (with the manifest's reason), the five folders, the earlier private
  backup folders, and a wipe sequence over all four ticks.
- `move_private_storage_255_test` (5): the tool moves backups from Revision
  4's `QQL_CourseBackups`, Revision 3's `qql_course_backups_v11` and the
  pre-Revision-3 Documents folder into `Documents/QuisquisLingo/Backups/Courses`,
  where Version History lists all three versions; without `--documents` the
  backups stay and are reported.
- The 25 test files that built `CourseBackupService` on the renamed seam
  (`backupsDirectoryProvider`) and five subclasses overriding the listings
  follow the new signatures; root-path expectations now name the Backups
  folder.
- Android 16 emulator (Pixel_8 AVD, API 36), `versionCode 255005` installed
  over the Revision 4 build, new test profile:
  1. A Fork of Exercise Laboratory was stored as
     `files/QQL_Courses/Custom/QQL_EN_IT_03e8633f-….json` ("No previous version
     existed, so no backup was required").
  2. In Edit, Use GuideBook changed and Confirm course changes wrote, with no
     permission screen,
     `/storage/emulated/0/Download/QuisquisLingo/Backups/Courses/QQL_bkp_EN_IT_03e8633f-…/QQL_bkp_EN_IT_03e8633f-…_v1_20260926T134911785940Z.json`
     (206,198 bytes, owned by the app); the confirmation's read-back check
     passed ("New course version: 2", with that backup path).
  3. Version History showed "Course Backups:
     /storage/emulated/0/Download/QuisquisLingo/Backups/Courses/QQL_bkp_EN_IT_03e8633f-…"
     and the version with Restore this version.
  4. Inventory showed "Backups folder (1) · 201.4 KB" at
     `Download/QuisquisLingo/Backups` with that file, "Written by QQL".
  5. Wipe everything showed the four ticks; with Keep the Backups folder
     unticked ("Backups folder: will be DELETED with everything else") it
     removed `Download/QuisquisLingo/Backups`, kept
     `Download/QuisquisLingo/Export/Courses/QQL_IT_NAP_….zip` and the logs.
  6. No Flutter error or crash in the device log.
- Not checked on a device: Android 7–10 (mocked tests only; Android 10's
  legacy storage flag cannot be checked on the Android 16 image). Course Info
  Editor shows the languages of an existing Course as read-only, so the
  folder rename on a language change (Revision 4) arises only through other
  routes and remains covered by tests.

### Final release checks

`flutter analyze --no-pub`: **No issues found**. Complete
`flutter test --no-pub --concurrency=1` on the final tree: **2,764 passed,
1 existing skip, 0 failed** in 32 min 27 s. An earlier start of the suite
was stopped when a doc comment in `android_storage_bridge.dart` turned out to
be outdated; after correcting it, the Android storage tests and the whole
suite ran again. No production or test file changed after that run. A debug
APK was built for the emulator check; no release package.

## Revision 6 — `2.0.55+255006`, 26 September 2026

Beta expiry `2026-10-26 23:59:59` local time (unchanged: released on the same
day as Revision 5).

### Scope

Twelve small owner-requested corrections (decisions of 26 September 2026 in
the handoff): demo licenses aligned to All rights reserved (Fork kept on the
two test demos), Piedmontais renamed Piedmontese, a Minimal view for Courses
sections and per-learner saved views, no startup Beta testing dialog,
Advanced (Admin) after Do Not Disturb, six demos removed, enlargeable Flag
Game flags and Course Info image, a Course cover set in the Course Info
Editor (up to 1 MB for the cover alone), and a Team Google Drive folder link.

### Focused evidence

- Course data: `python tools/validate_courses.py` validates the 4 remaining
  bundled Courses; `generate_exercise_laboratory_254.py --check`,
  `generate_edge_case_demo_254.py --check` and
  `generate_piedmontais_demo_254.py --check` pass (the last two regenerate
  Edge Case 1.1.0 and Piedmontese 1.1.0); `validate_media_assets.py`: 443
  files, 0 issues. Korean 1.2.0 was edited with the validator's checksum
  rule; the Dart checksum check of every bundled load agrees.
- `course_official_provenance_225_04_test` (new test): every demo is
  All rights reserved; Exercise Laboratory and Edge Case allow derivative
  works, Korean and Piedmontese forbid them. `piedmontais_course_254_test`:
  title, learning and target language say Piedmontese and nothing says
  Piedmontais. `demo_package_roundtrip_254_test`: the shipped Piedmontese
  refuses Fork; its content still takes the fork/export/import round trip
  through a test-only permissive copy.
- Removed demos: `course_service_test`, `bundled_demo_registry_254_test`,
  `bundled_courses_225_02_test`, `sample_courses_test`,
  `course_model_v6_test`, `course_model_v11_243_test`,
  `korean_production_discovery_225_03_test` and the Course Studio tests use
  the four remaining demos; `neapolitan_bundled_course_234_test` is removed
  with its Course. `leaderboard_navigation_test` uses the Korean sample as
  its navigation course (Sections and Duels); its Course Selector steps use
  fixed frames because the Piedmontese World Flag row keeps a loading
  indicator, and short lists get a frame after `scrollUntilVisible`.
  `course_entry_animation_228_test` checks the automatic FlagPainter flag
  with a synthetic flagless German Course.
- `course_library_view_255_test` (new, 8): the Expanded → Compact → Minimal
  cycle; Minimal shows only "S of N shown"; views saved per learner, tab and
  category (key `course_library_view_all_courses_other_local` = `minimal`),
  read back on a new visit, independent for another learner and for Course
  Studio; nothing written without a learner; the key suffix fits learner
  backups and is not a progress key; an imported Course's Minimal section is
  shown Expanded until the learner picks a view.
  `course_library_compact_244_test` follows the new cycle.
- Startup: `startup_profile_gate_test` waits for Home instead of the removed
  dialog and checks it never appears and its notice flag is never written;
  `startup_logging_regression_test` and `update_notice_239_test` check the
  update check starts without a notice in front of it.
- `device_administration_239_test`: Settings order Profile, Audio Settings,
  Do Not Disturb, Advanced (Admin), QQL Guide, Debug, Version and Build,
  Update for an admin; the page and its Help are titled Advanced (Admin).
- `enlarge_images_255_test` (new, 4): a question flag enlarges without its
  name and the question goes on; a reference flag enlarges with its name;
  Course Info opens the flag, or the cover shown instead of it, in the shared
  dialog. `course_artwork_preview_250_test` still passes through the shared
  dialog.
- `course_cover_255_test` (new, 8): a ready 512 × 512 picture is kept byte
  for byte; a 300 × 200 picture is centre-cropped (red left, blue right) and
  scaled to 512 × 512; a small one is enlarged; non-pictures and pictures
  over 10 MB are refused; a 512 × 512 cover above 50 KB is stored, copied and
  exported/imported as a cover but refused as an ordinary image; Quick
  Import through `CourseCoverField` and Remove cover; end to end, the Course
  Info Editor cover shows in the Course Editor header and is confirmed with
  the Course. `course_info_update_service_245_test`: the cover is set and
  cleared (omitted from JSON when empty).
- `team_shared_folder_255_test` (new, 6): accepted links and their stored
  form; 26 refused links (http, look-alike hosts, user info, ports, files,
  direct downloads, `open?id=`, Docs, shorteners, extra parameters, fragments,
  `javascript:`, `file:`, too long); registries without the field read
  unchanged and a bad stored link is refused; only a Team Leader sets or
  removes it; the member view opens it only after the download warning, with
  the stored form.

### Final release checks

`flutter analyze --no-pub`: **No issues found**. The first complete
`flutter test --no-pub --concurrency=1` (21 min 55 s) found 8 failures, all in
tests the smaller demo set or the version bump affected:
`qql_233_revision_platform_contract_test` still pinned `2.0.55+255005`; five
Course Studio and Course Library taps followed a `scrollUntilVisible` that
only brought an already built row into view without a frame (a `pump` before
the tap fixes it); `course_creation_flags_226_04_test` counted every World
Flag in the tree, including a Course Studio row below the Editor that the
shorter list now builds, and now looks only inside the Editor's AppBar. After
those corrections (the four files pass) and a clean analyzer, the complete
suite on the final tree: **2,766 passed, 1 existing skip, 0 failed** in
20 min 35 s. The course validators (`validate_courses.py`, the three
`--check` generators, `validate_media_assets.py`) pass. No production or test
file changed after that run. No Windows or Android package was built, and no
emulator check was made for this revision.

## Revision 7 — `2.0.55+255007`, 27 September 2026

Beta expiry `2026-10-27 23:59:59` local time (30 days from the 27 September
2026 release date).

### Scope

Owner-requested corrections to Revision 6 and a renewed first launch
(decisions of 26–27 September 2026 in the handoff): the whole refusal and a
smaller link type in the Team folder dialog; one line under Advanced (Admin),
shown greyed out to learners who are not admins; the cover in Create new
course; a custom cover crop; credit reminders and automatic known credits,
with the Audit counting the cover; no repetition of the current Course in the
Course Selector, which also shows covers; title and languages over an
enlarged Course image; the Edge Case demo's flag; and a first launch with only
the renewed Welcome Wizard in the language chosen in Create Profile.

### Focused evidence

- Course data: `validate_courses.py` validates the 4 bundled Courses;
  `generate_edge_case_demo_254.py` regenerates Edge Case 1.1.1 (flag `EN`)
  and `--check` passes; `validate_media_assets.py`: 443 files, 0 issues.
  `bundled_demo_registry_254_test` (new test): every bundled Course's flag
  resolves to a flag QQL can draw (a renderable QQL code or a World Flag in
  the manifest), and Edge Case says `EN`.
- `course_cover_255_test` (15; 7 new): `prepare(crop:)` crops the chosen
  square, kept inside the picture; a ready 512 × 512 picture is kept only when
  used whole; the crop dialog starts centred and as large as possible, the
  smallest size keeps the centre, a drag stops at the edge, the corner makes
  the square larger and Reset centres it again, Cancel returns nothing
  (drags are sent in small steps, as a real pointer does; the first test found
  that the dialog's scroll view took diagonal drags, so the dialog no longer
  scrolls); Quick Import goes through the crop dialog and leaves the reminder
  for an unknown picture; `knownImageCredit` for QQL, attributed and unknown
  pictures; the Course Info Editor adds a known cover credit, replaces it with
  the next cover's and keeps a row the author changed.
- `course_creation_flags_226_04_test` (2 new): Create new course's cover field
  stores for the allocated ID and the Editor receives that ID, the cover and
  its credit; cancelling the dialog deletes the stored cover's folder.
  `audio_library_media_248_test` (2 new): a new Course's session owns what its
  folder held and removes it when never stored, and keeps a stored cover.
- `media_attribution_test`: a cover raises MEDIA_ATTRIBUTION_MISSING.
  `image_credit_reminder_255_test` (new, 3): an imported Exercise image shows
  the reminder, a custom flag carries it and an Automatic one does not, and an
  import summary shows its note. `lesson_metadata_and_icon_test`: the Lesson
  icon message now ends with the reminder.
- `device_administration_239_test`: an admin opens Advanced (Admin), whose
  subtitle has one line; a learner who is not an admin sees it disabled with
  a lock, its tooltip says only an admin can open it and tapping opens
  nothing. `settings_profile_reorganization_228_01_test` lists it for
  everyone.
- Course Selector: `leaderboard_navigation_test` shows a stored cover in a
  44-pixel `CourseArtwork` while a Course without one keeps its flag, and no
  longer finds the current Course under Other courses;
  `korean_production_discovery_225_03_test` finds the current Course only in
  its own row; `course_entry_animation_228_test` chooses the current Course
  again through its Favorite row, which still replays nothing.
- `team_shared_folder_255_test`: the refusal is the whole message without a
  line limit and the field uses `bodyMedium`.
  `course_artwork_preview_250_test`: the enlarged cover has the title and
  "English → Italian" above it.
- First launch: `welcome_wizard_dialog_test` (4): the five steps, the
  mascots in order (kid, celebrating cat, monkey, robot, dog), Italian and
  Spanish text, and every key in all three catalogs.
  `startup_profile_gate_test` (new test): choosing Italiano in Create Profile
  stores the Italian Locale and the Wizard speaks Italian; this version's
  Welcome is marked seen and, after Skip, no other dialog follows; the English
  first run also shows only the Wizard. `leaderboard_navigation_test`'s dialog
  structure test sets the clock five days before expiry to see the Beta
  reminder; Home tests in eight files no longer wait for a reminder that now
  shows only in the last seven days (the suite clock sits fifteen days before
  expiry).

### Final release checks

`flutter analyze --no-pub`: **No issues found**. The first complete
`flutter test --no-pub --concurrency=1` (22 min 31 s): 2,782 passed, 1 skip,
4 failed, none a product defect: three `beta_lifecycle_test` cases still used
the calendar dates of the 26 October expiry (now one day later), and
`qql_233_profile_avatar_test` tapped Continue after the suffix message had
pushed it below the visible part of the longer Create Profile form (it now
scrolls to it). After those corrections (both files pass) and a clean
analyzer, the complete suite on the final tree: **2,786 passed, 1 existing
skip, 0 failed** in 22 min 41 s. `validate_courses.py`, the Edge Case
generator's `--check` and `validate_media_assets.py` pass. No production or
test file changed after that run. No Windows or Android package was built,
and no emulator check was made for this revision.

### Follow-up: Recognize characters, Choose from Image Bank (same version)

The owner asked on 27 September 2026 to fix the defect flagged above in the
same version. `ScriptRecognitionEditor._pickImage` pushed the image library as
a `String` route, but the library pops the chosen `ExerciseImageMetadata`. It
now pushes `<ExerciseImageMetadata>` and uses `assetPath`. QQL `assets/`
pictures and portable data stay as they are, other pictures become portable
bytes through `PortableExerciseImageService.fromFile`, and `_remindCredit` is
unchanged.

- New test in `script_recognition_226_03_test.dart`, *Choose from Image Bank
  adds the chosen QQL image as it is*. It opens the editor, chooses Choose
  from Image Bank, searches "apple" and taps Use image. Before the fix it
  failed with Flutter's "A request was made to pop a route with a result of
  type ExerciseImageMetadata, but the route expected a value of type String",
  and the library stayed open. After the fix the library closes,
  `assets/exercise_images/apple.webp` is added as it is, and no error or
  credit reminder appears.
- All 111 QQL Image Bank paths in `assets/exercise_images/metadata_v2.json`
  satisfy the portable-path rule, so a QQL picture never goes through
  `fromFile`.
- Focused run with `--concurrency=1` of the five files that use the editor or
  the reminder (`script_recognition_226_03_test`,
  `script_direction_help_226_03_r1_test`, `official_new_presets_226_03_test`,
  `exercise_laboratory_254_test`, `image_credit_reminder_255_test`): **201
  passed** in 2 min 6 s. `flutter analyze --no-pub`: **No issues found**.
- The complete suite was not run again after this change, at the owner's
  request (27 September 2026). The last complete run is the Revision 7 run
  above. The route for a picture imported on this device (`fromFile` and the
  reminder) has no widget test.
