# Build 255 handoff

Plan and audit: [255_STORAGE_PLAN.md](255_STORAGE_PLAN.md). Validation:
[255_VALIDATION.md](255_VALIDATION.md). Branch `claude/255-storage-roles`
from `main` at `acf75e4`. One local commit per revision; no push, no PR.

The untracked `devtools_options.yaml` and `tools/cloud_setup.sh` are the
owner's and not part of this work: never stage, move or delete them.

## Commits so far

| Commit | What |
| --- | --- |
| `be330e4` | Owner's own correction, committed on its own at their request: Italian Debug Help, Crash Log "tiene" → "conserva". |

## Status

Checkpoint 22:45, 25 September 2026.

Revision 0 (`2.0.55+255000`) is complete in the working tree and not yet
committed: storage roles and layout, every Quick route on them, Course Quick
folders `Imports/Courses` and `Exports/Courses` on every desktop, renames,
Help placeholders, version, CHANGELOG, README, AGENTS.md boundary, plan,
validation draft, reset-inventory doc note. Analyzer: 0 issues.

Owner request added during validation: exercise tests get a longer real-time
wait. Done in the working tree, test-only:
`test/exercise_laboratory_254_test.dart` `_until` and
`test/script_recognition_226_03_test.dart` `_waitForImageAction` now allow up
to 10 seconds of real time (like `pumpUntilFileIoState`); the fake clock still
advances at most 100 steps as before. Both files pass (188/188). Commit this
on its own ("Tests: give exercise tests up to 10 s of real time"), before
Revision 0.

Full-suite history for Revision 0: a first run in parallel was stopped (the
project runs `--concurrency=1`); two sequential runs were stopped because the
PC was heavily loaded by other programs, which made all 44 Laboratory
"learner completes" tests time out (the file passes 165/165 alone). The owner
closed the other programs; the final complete run is
`flutter test --no-pub --concurrency=1` via the scratchpad `run_suite.ps1`
(holds the execution state). When it passes: record the result in
`docs/255_VALIDATION.md` "Final release checks", commit the test-wait change,
then commit Revision 0 (`git add` the Revision 0 files; `help_it.dart` can now
be staged normally), update this handoff with the hashes.

## Next

1. Revision 1 (`2.0.55+255001`): Android Save as… / Open from…. Drafts are in
   the session scratchpad
   `C:\Users\Domenico\AppData\Local\Temp\claude\C--QQL-QuisquisLingo\ae742561-301e-4556-83ff-5f65a318ebf2\scratchpad\r1\`:
   `QqlStorageBridge.kt` (UI channel `org.quisquislingo.app/storage` for the
   SAF pickers; background I/O channel `org.quisquislingo.app/storage_io`
   with 1 MB read/write handles; a failed or abandoned write deletes the
   created document), `android_storage_bridge.dart`,
   `android_file_dialog_backend.dart` (to `lib/services/storage/`), the
   mocked-channel test and `docs_drafts.md`. Also: `MainActivity` registers
   the bridge and forwards `onActivityResult`; `FileDialogService` gets
   `backendFor(QqlStoragePlatform)`; `ExternalFileSource.document`. Build the
   debug APK and check on the Pixel_8 emulator (Android 16).
2. Revision 2 (`2.0.55+255002`): Android public Quick folders. Design notes
   and drafts in the scratchpad `r2\` (`notes.md`, `QuickFolders.kt`,
   `android_storage_backend.dart`, `quick_import_access.dart`).
3. **No emulator downloads.** The owner first approved the Android 10 image,
   then asked to skip it for now (25 September 2026, 22:50). Test on the
   existing Pixel_8 emulator (Android 16) only, and record the Android 10
   (folder creation before the permission screen) and Android 7–9 (storage
   permission) paths as "checked with mocked tests, not tested on a device".
   The scratchpad `install_api29.py` stays unused unless the owner asks again.

A one-time scheduled task `resume-qql-build-255` fires at 00:35 on
26 September 2026 to resume from this file if the original session
(`local_3715fe66-3203-454a-a5b9-eec983d3cabf`) has been idle 15 minutes.

## Owner decisions (25 September 2026)

- Course Quick folders move on Windows, Linux and macOS; no hint for old files.
- Android 7–9 may show the one-time storage permission prompt.
- Android Quick Import: one persisted permission for exactly
  `Download/QuisquisLingo/Imports`, with Open from… offered as the alternative.
- Wipe everything and Inventory cover the Android public folders; a full wipe
  releases the folder permission.
- Buttons renamed: Quick Import, Quick Export, Save as… (Open from… kept;
  Merge labels kept).

## Gotchas

- Never run two Flutter commands at once (shared SDK lock), and do not start
  the emulator or the image download during a full suite: this PC has 4 cores
  and 8 GB RAM, and load makes file-I/O widget tests time out.
- Tests run on the Windows host, so the desktop layout applies; use
  `QqlStorageLayout.debugOverride` to check another platform's wording.
- Python scripts are more reliable than shell heredocs for multi-line edits
  here (heredocs lose backslashes).
