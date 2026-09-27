# Build 255 handoff

Plan and audit: [255_STORAGE_PLAN.md](255_STORAGE_PLAN.md). Validation:
[255_VALIDATION.md](255_VALIDATION.md). Built on branch
`claude/255-storage-roles` from `main` at `acf75e4`, one commit per revision,
and merged into `main` through
[PR #24](https://github.com/Quisquisnaut/QuisquisLingo/pull/24) (merge commit
`292044e`, 26 September 2026, 17:10 local time). The branch no longer exists.

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
| `09e88ba` | **Revision 4** `2.0.55+255004`: private folders and language pairs (`QQL_Courses`, `QQL_CourseMedia`, `QQL_CourseBackups`, `QQL_SharedImages`, `QQL_ImageBanks`, `QQL_ImportStaging`, `QQL_Logs`; `QQL_<pair>_<ID>` in every per-Course name, exports `QQL_<pair>_<title>.zip`, historical `QQL_bkp_…`), clean cut with `tools/move_private_storage_255.dart`, Android Auto Backup exclusions for the new media folders. Emulator-checked on Android 16. Suite 2,757 passed, 1 skip. |
| `75e699d` | **Revision 5** `2.0.55+255005`: the Backups folder — Course Backups in `QuisquisLingo/Backups/Courses` beside Import and Export on every system (Android: own files, no permission from Android 11, storage permission on 7–10), tolerant Version History, "Keep the Backups folder" in Wipe everything, the tool moves earlier backups there. Emulator-checked on Android 16. Suite 2,764 passed, 1 skip. |
| `292044e` | Merge of PR #24 into `main` (merge commit, as for earlier PRs; the repository has no CI). |
| `b56b9bf` | **Revision 6** `2.0.55+255006` on branch `claude/255-rev6-fixes` (from `main` at `2f4f89b`): twelve small corrections — four bundled demos left (German, Spanish, English-from-Spanish, Welsh, Portuguese and Neapolitan removed), All rights reserved demo licenses with Fork kept on Exercise Laboratory and Edge Case, Piedmontais renamed Piedmontese, Courses sections Minimal and saved per learner/tab/category, no startup Beta testing dialog, Advanced (Admin) after Do Not Disturb, enlargeable Flag Game flags and Course Info image, a Course cover in the Course Info Editor (1 MB for the cover alone), a Team Google Drive folder link. Suite 2,766 passed, 1 skip. |
| `1ec3277` | Handoff through Revision 6. |
| `6cc9154` | Merge of [PR #25](https://github.com/Quisquisnaut/QuisquisLingo/pull/25) into `main` (merge commit; the PR also carried `2f4f89b`, the handoff note for PR #24 that had stayed local). |
| `3d4de23` | Handoff note: merged through PR #25 (local on `main`, not pushed). |
| `d2b7132` | **Revision 7** `2.0.55+255007` on branch `claude/255-rev7-fixes` (from `main` at `3d4de23`): Team dialog refusal in full, Advanced (Admin) one line and greyed for non-admins, cover in Create new course, Crop the cover, known credits and reminders (Audit counts the cover), Selector covers without repeating the current Course, enlarged title and languages, Edge Case flag `EN`, first launch with only the renewed Welcome Wizard in the language chosen in Create Profile. Suite 2,786 passed, 1 skip. Beta expiry `2026-10-27 23:59:59`. |

## Status

**Revision 7 (`2.0.55+255007`) is complete and committed locally** (27
September 2026) as `d2b7132` on branch `claude/255-rev7-fixes`, created from
`main` at `3d4de23`; nothing is pushed. Owner decisions (26–27 September 2026):

1. Team shared folder dialog: the refusal message is shown in full (it was
   cut at "other websites and short…"); the link in the field is slightly
   smaller.
2. Settings: at most one line under Advanced (Admin). For non-admins the
   entry is shown greyed out and cannot be opened; a tooltip says what it
   holds and that it is reserved for admins.
3. Cover image already in "Create new course" (the Course ID is allocated
   when the dialog opens; a cancelled dialog deletes the stored cover; a new
   Course's editing session owns everything in its media folder).
4. Custom crop: after choosing a picture, "Crop the cover" lets the author
   move the square, resize it with its corner or a slider, and Reset it.
5. Credits (owner: "reminder for missing attribution of any image, automatic
   credit when the origin is known"): a reminder whenever a picture of
   unknown origin joins a Course (exercise image, Course image library,
   Lesson icon, custom flag, Recognize-characters image, cover); a cover made
   from a library picture whose credit QQL knows gets that credit in Media
   credits automatically (Applies to: Course cover); the Audit's
   MEDIA_ATTRIBUTION_MISSING also counts the cover.
6. Course Selector: the current Course is no longer repeated under Other
   courses (Favorites may still repeat it, Build 250 decision).
7. Enlarged Course image (Courses, Course Info): title and "Source → Target"
   above the picture.
8. First launch: only a renewed Welcome Wizard (five steps with mascots,
   including the monkey), in the explanation language chosen in Create
   Profile (EN/IT/ES, preselected from the system language; it becomes the
   learner's Help Language). The version Welcome shows only after an update;
   "Beta expiry" only in the last seven days. Wizard texts approved by the
   owner (27 September 2026); mascots in order: kid reading, celebrating
   cat, yawning monkey, running robot, laughing dog.
9. Course Selector rows show the cover when there is one, else the flag, in
   the square slot Courses uses. The Course flag stays separate and still
   appears in the top bar, the Flag Background and the Course entry
   animation; the cover field's text says so.
10. Edge Case demo flag: `flagCode` "GB" (which QQL does not draw, so the
    neutral flag showed; an invalid explicit choice never falls back to
    Automatic) becomes "EN"; Edge Case 1.1.1, regenerated with
    `tools/generate_edge_case_demo_254.py`. An Audit warning for undrawable
    flag codes was mentioned to the owner as a later idea, not in scope.

What Revision 7 contains: the Team dialog shows its whole refusal with a
smaller link; Advanced (Admin) has one line and is greyed out for
non-admins; the cover crop dialog (`lib/widgets/cover_crop_dialog.dart`, no
scroll view so drags are not taken by scrolling) and
`CourseCoverService.prepare/store(crop:)`; `CourseCoverField` without a
stored Course (`courseId`, optional `course`, `CourseCoverChoice` with the
known credit); the Create new course cover (preallocated ID, folder deleted
on cancel, `newCourse(courseId:, coverImage:, mediaAttributions:)`) and
`CourseAuthoringMedia(newCourse:)`; automatic cover credit rows in Course
Info from `knownImageCredit` (`lib/services/image_credit.dart`); credit
reminders (`lib/widgets/image_credit_reminder.dart`) at every entry point of
a picture of unknown origin; the Audit counting the cover; Selector covers
and no repetition of the current Course; the enlarged image's title and
languages; the Edge Case flag `EN`; the Welcome Wizard
(`lib/localization/welcome_text.dart`, mascots), the Create Profile language
(`new-learner-language`, written with `LocaleService`) and the first-run
sequence (`_showStartupNotices`; the Wizard marks this version's Welcome
seen; the Beta notice only when `warningStage()` is set). Help (EN/IT/ES),
CHANGELOG, README and AGENTS.md follow.

Validation: analyzer clean; the first complete suite found 4 test-only
failures (three `beta_lifecycle_test` cases on the 26 October dates, and a
Create Profile test that tapped Continue below the longer form), corrected;
the complete suite on the final tree: **2,786 passed, 1 existing skip, 0
failed** (22 min 41 s); course and media validators pass. No package or
emulator check. Details in `docs/255_VALIDATION.md`.

Out of scope, flagged as a separate task and not fixed here: the Recognize
characters "Choose from Image Bank" route pushes a `String` route but the
image library pops an `ExerciseImageMetadata`, so choosing an image there
most likely fails.

Next: the owner's smoke test of Revision 7; push, PR and merge only when
the owner asks.

**Revision 6 (`2.0.55+255006`) is complete and merged** (26 September
2026): commit `b56b9bf` reached `main` through
[PR #25](https://github.com/Quisquisnaut/QuisquisLingo/pull/25), merge commit
`6cc9154` (23:36 local time). The branch `claude/255-rev6-fixes` was deleted
on GitHub and locally; only `main` remains on both sides, and the local
checkout is on `main` at `6cc9154` plus this handoff note. The next build
starts from there. Small owner-requested corrections. Owner decisions
(26 September 2026):

1. Demo licenses: every remaining demo says `All rights reserved`. Exercise
   Laboratory and Edge Case keep `derivativeWorksPolicy: allowed` (they are
   the forkable test demos); Korean and Piedmontese get `forbidden` (the
   value QQL maps to All rights reserved). Edge Case's license text loses its
   "; derivative works allowed…" suffix. Changed demos get a minor
   `officialCourseVersion` bump with release notes (precedent: Korean 226.02).
2. Piedmontais becomes Piedmontese: title `AI-Slop Demo: Piedmontese`,
   learning/target language and every in-course mention; same Course ID,
   stable IDs, code `PMS`, TTS `pms-IT`; file names stay.
3. + 4. Courses sections: Expanded → Compact → Minimal (cycle button, like
   the Lesson display control). Minimal shows only the header with
   "S of N shown". Persisted per learner × tab × category
   (`course_library_view_<tab>_<category>`, default Expanded); an imported
   Course's Minimal section shows Expanded for that visit.
5. Remove the one-time "QuisquisLingo Beta testing" startup dialog; the
   startup update check stays.
6. + 7. "Device Administration" is labelled **Advanced (Admin)** (classes,
   files and keys unchanged) and sits after Do Not Disturb in Settings.
8. Delete German, Spanish, Inglés para hispanohablantes (EN), Welsh,
   Portuguese and Neapolitan; keep Exercise Laboratory, Korean, Edge Case and
   Piedmontese. IDs stay reserved, progress orphaned, media assets kept.
9. Flag Game: tap a flag to enlarge it (no name during a question; name in
   the reference lists).
10. Course Info: the Course image (cover if any, else flag, as in Courses) is
    tappable and opens the same enlargement dialog, extracted from the
    Courses row into one shared implementation.
11. Team: optional Google Drive shared-folder link (Team Leaders set it,
    members open it after a safety warning); only
    `https://drive.google.com/drive/(u/N/)folders/<ID>` is accepted.
12. Cover image in the Course Info Editor (Choose image / Quick Import / Open
    from… / Remove): any picture is centre-cropped and scaled to a 512 × 512
    PNG (a ready 512 × 512 file up to 1 MB is kept as it is). The cover alone
    may be up to **1 MB** (owner decision; other images stay at 50 KB): the
    store, package import, backup restore and Fork/Copy/Merge copies apply the
    cover limit only to the file that is the Course's cover. The Course
    Editor header shows the cover instead of the flag when there is one.

Status (22:27): all twelve tasks are implemented and documented (CHANGELOG,
README, AGENTS.md, `255_VALIDATION.md`, `239_RESET_STORAGE_INVENTORY.md`,
`WINDOWS_RELEASE_TEST.md` step 7, and `SEND_DEBUG_LOG_TO_DEVELOPER.txt`,
which still described the removed dialog). Analyzer clean; the complete
suite on the final tree passed: 2,766 passed, 1 existing skip, 0 failed
(20 min 35 s). A first complete run had found 8 failures in tests the
smaller demo set or the version bump affected (details in the validation);
they were corrected before the final run.

Revision 6 open points for the owner:

- Fork is unavailable on Korean and Piedmontese by decision; the Build 254
  package round-trip test keeps Piedmontese content covered through a
  test-only copy that allows derivative works.
- The removed demos' learner progress stays in preferences, orphaned, as
  after Build 254; until the week rolls over, the Gamification breakdown of
  last week's XP may name such a Course by its ID.
- The earlier `one_time_notice_seen_beta_testing` flag stays where it was
  set; nothing reads it any more.
- A cover made from a Shared Image Library picture is a new, cropped image
  and does not carry the library picture's provenance: credit it under
  Media credits. A Course package whose cover is over 50 KB does not import
  into Revision 5 or earlier.
- `tools/regenerate_bundled_courses_225_02.py` (historical) still names the
  removed files; as before, it must not be run.
- Not checked on a device: the cover's Quick Import and Open from… on
  Android, and opening a Team folder link on Android (desktop flows are
  covered by tests). No Windows or Android package was built.

Measured before deciding: library images (256 × 256 WebP) scaled to a
512 × 512 PNG weigh 10–87 KB; a detailed 1254 × 1254 logo 145 KB. Before this
revision the real cover limit was 50 KB, because every package image passed
the general 50 KB check before the declared 100 KB cover check.

**Build 255 is complete and merged** (26 September 2026): Revisions 0–5 and
the two earlier commits reached `main` through
[PR #24](https://github.com/Quisquisnaut/QuisquisLingo/pull/24), merge commit
`292044e`. The branch `claude/255-storage-roles` was deleted on GitHub and
locally; the old local branches `codex/build-253-localization` and
`codex/qql-tools-integration` were deleted too, after checking that all their
commits were in `main`. The local checkout is on `main`, up to date with
`origin/main`, and only `main` remains on both sides. The Android emulator
is closed. The next build starts from `main` at `292044e` (or this handoff's
own commit).

**Revision 5 (`2.0.55+255005`) is complete** (26 September 2026): the
Backups folder, analyzer clean, complete suite 2,764 passed with 1 existing
skip, emulator-checked on Android 16 (details in the validation).

- Course Backups are in `QuisquisLingo/Backups/Courses` on every system
  (`QqlTopFolder.backups`, `QqlStorage.courseBackupsDirectory()`), written and
  read as ordinary files; `CourseBackupService`'s seam is
  `backupsDirectoryProvider`. Android: no permission from Android 11
  (checked: a confirmation wrote and read back its backup in
  `Download/QuisquisLingo/Backups/Courses`), the storage permission on
  Android 7–10 (`requestBackupAccess`; manifest `WRITE_EXTERNAL_STORAGE` up
  to API 29 and `requestLegacyExternalStorage`), refused →
  `CourseBackupsAccessDenied` and the confirmation stops.
- Version History lists readable versions and names other files
  (`skipped:`); the strict listings still throw.
- Wipe everything: "Keep the Backups folder", ticked by default; the
  earlier private backup folders follow it. Inventory: "Backups folder".
- The one-off tool moves every earlier backup into
  `Documents/QuisquisLingo/Backups/Courses` (needs `--documents` off Windows).

**Revision 4 (`2.0.55+255004`) is complete** (26 September 2026, ~14:15):
private folders and language pairs, analyzer clean, complete suite 2,757
passed with 1 existing skip, emulator-checked on Android 16 (details in the
validation).

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

Revisions 0–2 were complete on 26 September 2026, 02:00.

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
- Import staging leftovers (`QQL_ImportStaging`, normally empty) are still
  included in Android's cloud Auto Backup; Course Backups no longer are
  (Revision 5). The older `qql_courses_v1` and `quisquislingo_audio` stay out
  of Inventory and Wipe (Build 243 decision).
- Android 10 (legacy storage flag for the Backups folder) and Android 7–9 are
  covered by mocked tests only. On Android, Version History lists only the
  backups this installation made; Open backup folder is best effort there.

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
  move). Superseded by Revision 5, which makes them public.
- Exported files start with `QQL_` instead of `quisquislingo_`, Save as…
  suggestions included.
- Android asks once for the whole `Download/QuisquisLingo` folder.
- Don't worry about existing files: no move, no hint.

## Owner decisions for Revision 4 (26 September 2026)

- QQL's private folders get `QQL_` names in the no-space style of the public
  ones (`QQL_Courses`, `QQL_CourseMedia`, `QQL_SharedImages`,
  `QQL_ImageBanks`, `QQL_ImportStaging`, `QQL_Logs`).
- No language folder levels: the language pair, source then target, goes into
  every per-Course name instead (`QQL_EN_IT_<ID>`; Italian → Neapolitan is
  `IT_NAP`); a QQL-made ID is not repeated after the prefix.
- Backups and exported earlier versions are marked `QQL_bkp_`; exports are
  `QQL_<pair>_<title>.zip`. The backup format stays as it is.
- Clean cut in the app, plus a one-off desktop tool the owner runs to move
  earlier Courses, media and backups.

## Owner decisions for Revision 5 (26 September 2026)

- For consistency, Course Backups move out of private storage into a public
  folder beside Import, Export, Logs and ToBeMerged, on every system:
  `Backups/Courses`.
- Learner backups (User Data) stay in `Export/UserData`.
- Wipe everything gets "Keep the Backups folder", ticked by default like the
  others.

## Gotchas

- Revision 6: the Course Selector and Course Studio lists are shorter now
  (four bundled demos), so rows are often already built: after
  `scrollUntilVisible` add `await tester.pump()` before tapping, and do not
  `pumpAndSettle` while the Piedmontese World Flag row is on screen (its
  loading indicator never settles; see `_settleSelector` in
  `leaderboard_navigation_test`). Here-doc scripts in the Bash tool lose
  escaped backslashes: put Python edit scripts in a file. Several files are
  not `dart format`-clean at HEAD (for example `course_editor_screen.dart`,
  `course_package_service.dart`, `exercise_image_service.dart`); check with
  a copy before formatting a whole file, or edit by hand.

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
- The emulator lags: pause after each input (`adb shell "input tap X Y; sleep
  1.5"`) and confirm with a screenshot, because a failed `uiautomator dump`
  leaves the previous XML behind and shows an old screen.
- `adb shell run-as org.quisquislingo.app` reaches the app's private files but
  not `/storage/emulated`; check the public folders with a plain `adb shell ls
  /sdcard/Download/QuisquisLingo`.
- Course Info Editor shows an existing Course's languages as read-only, so a
  language change (and Revision 4's rename) cannot be made from the UI.
