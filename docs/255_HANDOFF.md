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
| `2d97210` | Tests only, owner request: the Exercise Laboratory and character-recognition image waits allow up to 10 s of real time (fake clock unchanged). |
| `ff4a572` | **Revision 0** `2.0.55+255000`: logical storage roles, every Quick route on them, Course Quick folders `Imports/Courses` / `Exports/Courses` on every desktop, Quick Import / Quick Export / Save as…, Help folder placeholders. Complete suite 2,698 passed, 1 skip. |
| `826f4e1` | **Revision 1** `2.0.55+255001`: Android Save as… / Open from… (SAF bridge). Emulator-checked on Android 16. Complete suite 2,711 passed, 1 skip. |

## Status

Checkpoint 01:45, 26 September 2026: Revision 2 (`2.0.55+255002`, Android
public Quick folders) is complete in the working tree and not yet committed:
`QqlStorageLayout.androidPublic`, `lib/services/storage/android_storage_backend.dart`,
bridge additions, `android/.../QuickFolders.kt`, `MainActivity` permission
hook, manifest `WRITE_EXTERNAL_STORAGE` (maxSdk 28),
`lib/widgets/quick_import_access.dart` at all Quick Import buttons, Inventory
and Wipe everything for the public folders, Help/Inventory wording, tests
`test/android_quick_folders_255_test.dart` (20 pass) with
`test/support/fake_android_storage.dart`, version bump, Beta expiry
`2026-10-26 23:59:59` (release date 26 September), CHANGELOG, README, AGENTS,
docs. Emulator-checked on Android 16 (see validation). Next: complete suite,
record it, commit Revision 2.

## Next

1. Revision 1 (`2.0.55+255001`): Android Save as… / Open from… — see Status.
   Its drafts came from the session scratchpad
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
  the emulator during a full suite: this PC has 4 cores and 8 GB RAM, and load
  makes file-I/O widget tests time out. Run the complete suite with
  `flutter test --no-pub --concurrency=1` through the scratchpad
  `run_suite.ps1` (holds the execution state); ~24 minutes.
- Tests run on the Windows host, so the desktop layout applies; use
  `QqlStorageLayout.debugOverride` to check another platform's wording.
- Python scripts are more reliable than shell heredocs for multi-line edits
  here (heredocs lose backslashes).
