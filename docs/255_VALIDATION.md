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
