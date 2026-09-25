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
