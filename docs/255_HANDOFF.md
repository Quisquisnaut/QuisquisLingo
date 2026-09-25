# Build 255 handoff

Plan and audit: [255_STORAGE_PLAN.md](255_STORAGE_PLAN.md). Validation:
[255_VALIDATION.md](255_VALIDATION.md). Branch `claude/255-storage-roles`
from `main` at `acf75e4`. One local commit per revision; not pushed, no PR.

The untracked `devtools_options.yaml` and `tools/cloud_setup.sh` are the
owner's and not part of this work: never stage, move or delete them.

## Commits

| Commit | What |
| --- | --- |
| `be330e4` | Owner's own correction, committed on its own at their request: Italian Debug Help, Crash Log "tiene" → "conserva". |
| `2d97210` | Tests only, owner request: the Exercise Laboratory and character-recognition image waits allow up to 10 s of real time (fake clock unchanged). |
| `ff4a572` | **Revision 0** `2.0.55+255000`: logical storage roles, every Quick route on them, Course Quick folders `Imports/Courses` / `Exports/Courses` on every desktop, Quick Import / Quick Export / Save as…, Help folder placeholders. Suite 2,698 passed, 1 skip. |
| `826f4e1` | **Revision 1** `2.0.55+255001`: Android Save as… / Open from… (SAF bridge). Emulator-checked on Android 16. Suite 2,711 passed, 1 skip. |
| `3e0f512` | **Revision 2** `2.0.55+255002`: Android public Quick folders (MediaStore Quick Export, persisted folder permission for Quick Import, Android 7–9 storage permission, Inventory and Wipe everything). Emulator-checked on Android 16. Suite 2,731 passed, 1 skip. Beta expiry `2026-10-26 23:59:59`. |

## Status

Build 255 is complete (26 September 2026, 02:00). Nothing is pushed.

Open points for the owner:

- Android 10 (folder creation before the folder screen, by a pending
  MediaStore placeholder) and Android 7–9 (storage permission) are covered
  by mocked tests only; the owner chose not to download older emulator
  images. Check on a real device or an emulator image later.
- Merge keeps the labels "Merge Course package or JSON" and "Merge From…";
  renaming them to match Quick Import is a possible follow-up.
- No Windows or Android release package was built (debug APK only, for the
  emulator checks).

The one-time scheduled task `resume-qql-build-255` fired at 00:35 while this
session was active; its run was stopped before it did anything and the task
is disabled.

## Owner decisions (25 September 2026)

- Course Quick folders move on Windows, Linux and macOS; no hint for old files.
- Android 7–9 may show the one-time storage permission prompt.
- Android Quick Import: one persisted permission for exactly
  `Download/QuisquisLingo/Imports`, with Open from… offered as the alternative.
- Wipe everything and Inventory cover the Android public folders; a full wipe
  releases the folder permission.
- Buttons renamed: Quick Import, Quick Export, Save as… (Open from… kept;
  Merge labels kept).
- Only the Android 16 emulator; no emulator downloads for now.
- The owner's Italian Help wording fix is its own commit; the exercise-test
  waits were lengthened on request.

## Gotchas

- Never run two Flutter commands at once (shared SDK lock), and do not start
  the emulator during a full suite: this PC has 4 cores and 8 GB RAM, and load
  makes file-I/O widget tests time out. Run the complete suite with
  `flutter test --no-pub --concurrency=1` (about 22–24 minutes) while holding
  the Windows execution state.
- Stop the Gradle and Kotlin daemons (`java`) after an APK build before
  starting the emulator; they hold about 2.8 GB.
- The Pixel_8 AVD boots from its quickboot snapshot, so app data and
  Download files from an earlier emulator run are gone on the next boot.
- Tests run on the Windows host, so the desktop layout applies; use
  `QqlStorageLayout.debugOverride` to check another platform's wording, and
  `test/support/fake_android_storage.dart` for the Android side.
- Python scripts are more reliable than shell heredocs for multi-line edits
  here (heredocs lose backslashes).
