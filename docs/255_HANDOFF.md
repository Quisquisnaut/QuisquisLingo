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
| `86abde0` | **Revision 3** `2.0.55+255003`: one folder pattern on every system (`Import`, `Export`, `Logs`, `ToBeMerged` below the QuisquisLingo folder, one subfolder per kind), flag from `Import/Flags`, `QQL_` export names, private Crash Log and Course Backups, Crash Log Quick Export, one Android permission for `Download/QuisquisLingo`. Emulator-checked on Android 16. Suite 2,739 passed, 1 skip. |

## Status

**Revision 4 (`2.0.55+255004`) is complete** (26 September 2026, ~14:15):
private folders and language pairs, analyzer clean, complete suite 2,757
passed with 1 existing skip, emulator-checked on Android 16 (details in the
validation). Nothing is pushed.

- `CourseStorageNames` (`lib/services/storage/course_storage_names.dart`,
  plain Dart) names every per-Course file and folder:
  `QQL_Courses/Custom|Publisher/QQL_<pair>_<ID>.json`,
  `QQL_CourseMedia/QQL_<pair>_<hash>` (`QQL_<hash>` until first stored),
  `QQL_CourseBackups/QQL_bkp_<pair>_<ID>/…_v<version>_<stamp>.json`, exports
  `QQL_<pair>_<title>.zip` and `QQL_bkp_<pair>_<title>_v<version>.zip`.
  Stores find a Course by the ID inside a file or by the ID or ID hash at
  the end of a folder name; `CourseEditorService` aligns the media and
  backup folders after every store write, and the file store renames in
  place, so a language change renames all three.
- Other private folders: `QQL_SharedImages`, `QQL_ImageBanks`,
  `QQL_ImportStaging`, `QQL_Logs` (`QQL_crash.log`, `QQL_session.marker`);
  temp prefixes `QQL_ImageBank_`, `QQL_TTS_`. `QqlEarlierPrivateFolders`
  lists the earlier names (never read, except earlier shared images and
  banks through their stored paths), matches them by exact name and renames
  Revision 3's `qql_logs` to `QQL_Logs` where case is ignored.
- Inventory has a "Private folders from earlier versions" section; Wipe
  everything removes those folders (earlier logs with the Logs choice).
  Android Auto Backup excludes the new media folders (both XML files; a test
  ties them to the constants).
- The store no longer blocks a save because of a readable file holding
  another Course; a taken name is still never replaced.
- `tools/move_private_storage_255.dart` (+ test) moves the owner's earlier
  Courses, media and backups; a dry run on the development PC would move 6
  Courses and 6 media folders (22 files). It has **not** been run for real:
  the owner decides when (QQL closed).

**Revision 3 (`2.0.55+255003`) is complete** (26 September 2026): one folder
pattern on every system, analyzer clean, complete suite 2,739 passed with
1 existing skip, emulator-checked on Android 16 (details in the validation).

Revisions 0–2 were complete on 26 September 2026, 02:00. Nothing is pushed.

Open points for the owner:

- Android 10 (folder creation before the folder screen, by a pending
  MediaStore placeholder) and Android 7–9 (storage permission) are covered
  by mocked tests only; the owner chose not to download older emulator
  images. Check on a real device or an emulator image later.
- Merge keeps the labels "Merge Course package or JSON" and "Merge From…";
  renaming them to match Quick Import is a possible follow-up.
- No Windows or Android release package was built (debug APK only, for the
  emulator checks).
- Run `dart run tools/move_private_storage_255.dart --dry-run`, then without
  `--dry-run`, on each desktop with earlier Courses (QQL closed). Until then
  those Courses are not listed; nothing is lost.
- Not in Revision 4, for a later decision: Course Backups (`QQL_CourseBackups`,
  with media copies) and staging leftovers are still included in Android's
  cloud Auto Backup, as before; the older `qql_courses_v1` and
  `quisquislingo_audio` stay out of Inventory and Wipe (Build 243 decision).

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

## Owner decisions for Revision 3 (26 September 2026)

- Desktop and mobile behave the same wherever possible: one universal
  pattern below the QuisquisLingo folder, `Import`, `Export`, `Logs` and
  `ToBeMerged` (not `Merges`, not inside Import) with a `Courses` subfolder.
- Every kind of file gets its own subfolder; folder names have no spaces
  (`LessonIcons`, `UserData`, `RecoveryKeys`, `AuditReports`).
- Fix the flag: it is read from `Import/Flags`.
- A Quick Export button for the Crash Log; the live Crash Log is private on
  every system.
- Course Backups are private everywhere; desktop backups made before stay
  where they were, unread (owner chose this after discussion, not a one-time
  move).
- Exported files start with `QQL_` instead of `quisquislingo_`, Save as…
  suggestions included.
- Android asks once for the whole `Download/QuisquisLingo` folder.
- Don't worry about existing files: no move, no hint.

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
