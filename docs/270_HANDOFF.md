# Build 270 handoff

Started 10 October 2026 after the read-only audit (`docs/270_AUDIT.md`), on
the branch `build-270` in the main checkout `C:\QQL\QuisquisLingo` (from
`main` at `7900f58b`, pushed). Git rule: one branch per Build; after each
revision's commit push the branch (`git push -u origin build-270`, standing
permission, a backup, no pull request); merge into `main` and push `main`
only on the owner's go. Summary: `docs/270_CHANGE_SUMMARY.md`; evidence:
`docs/270_VALIDATION.md`.

Never stage `devtools_options.yaml`, `tools/cloud_setup.sh`.

## Owner decisions (10 October 2026)

- Save the audit report as a file (done: `docs/270_AUDIT.md`) and fix in this
  order: (1) the learner-data store, (2) learner separation, (3) the Build 269
  audio hold and the DST XP bug, (4) the import side doors; then continue with
  the remaining findings by severity, one revision each, asking only where a
  design choice is needed.
- Diagnostic Log: its own file (chosen over "keep, write less").
- Threat model: "the app's security is just intended to avoid easy
  unauthorized access but do not intend to be hackerproof"; physical access
  defeats any hardening. So no required admin PIN, no PIN attempt limit, no
  lock-down of identity creation from backups or Recovery Keys. Fix only
  in-app paths that bypass a PIN that is set with ordinary taps.

## Plan

| Revision | Scope |
|---|---|
| 0 | Learner-data store (audit item 1) |
| 1 | Learner separation within the threat model: a restore never activates a PIN-protected learner without its PIN, "Replace existing" over another PIN-protected learner asks for that learner's PIN, switching learners ends the previous learner's unlocked session |
| 2 | Build 269 audio hold (Android speak future that never completes, MP3/aplay hangs; Play during a held line; stale line revealing the next; audio after leaving a Round) and the DST week-key XP bug |
| 3 | Import side doors: Course Backups read with the import gates (size, JsonLimits, media validators, no `..`), `assets/` allowlist, learner backup value types and size |
| 4+ | Remaining Medium findings, then Low (see the audit's tables) |

## Revision 0 (2.0.70+270000), learner data that survives a bad write

State: done. Code, tests and docs; version 2.0.70+270000 (Beta expiry
2026-11-09 23:59:59, unchanged: same release day). New tests 21 passed;
related files 131 passed; analyzer clean; Windows release build checked
against the owner's learner data (one instance, the Diagnostic Log moved,
the last good copy written, an emptied and a cut off file recovered with the
dialog alone, test files removed; the owner's earlier file is in the session
scratchpad `appdata_before_270`); complete suite 4,071 passed, 1 skipped
(03:18–03:52). Committed on `build-270` as `ae49bd5e` and
the branch pushed.

Gotchas:
- Tests never install the store (they use `setMockInitialValues`); the store
  has its own file tests with real temp folders.
- `DiagnosticLogService` stays in preference mode until `initialise()`;
  tests do not call it, so their expectations on the preference hold.
- Logging a failed learner-data write to the Diagnostic Log while it is
  still a preference would loop; `LearnerDataNotices` checks
  `DiagnosticLogService.logFile` first.
- D: has about 2.6 GB free (test temp); C: about 25 GB.

## Revision 1 (2.0.70+270001), a PIN that is set stays a PIN

State: done. `ProfileService._unlockOnly`; `LearnerBackupService`
`replacingNeedsPin` / `restorePreservingIdentity(accessPin:)`; the PIN
dialog in User Data. Tests 4 new; related 166 passed; analyzer clean;
complete suite 4,075 passed, 1 skipped (03:58–04:32). Committed on
`build-270` as `af5a7433` and the branch pushed.

Next: Revision 2. Drafts ready in the session scratchpad
(`patch_270002_xp.py`, `patch_270002_audio.py`,
`patch_270002_backends.py`, `week_xp_270_test.dart`,
`spoken_lines_270_group.dart` + `_helpers.dart` to append to
`test/spoken_lines_269_test.dart`): calendar week keys and a crash- and
race-safe rollover and `addXp` in `XpService`; the line ceiling
(`RoundScreen._lineCeiling`, twice the estimate + 5 s), Play disabled while
a line reads itself aloud or a tap plays, no reveal or SnackBar for a line
already left, audio stopped on leaving a Round
(`RecordedAudioService.stopAll`, `stopWindowsTts`, `stopLinuxTts` with time
limits and absolute PATH entries).

## Revision 2 (2.0.70+270002), Story lines never stuck, weekly XP

State: done (the drafts above applied; `_endless` test voice extends the
test's `_Speech`). Tests 5 + 3 new; related 353 passed; analyzer clean;
complete suite 4,083 passed, 1 skipped (04:40–05:13). Committed on
`build-270` as `6e4a3175` and the branch pushed.

Next: Revision 3, the import side doors. Drafts in the scratchpad:
`patch_270003.py` (bundled-asset pattern in `lib/models/bundled_asset.dart`
from `bundled_asset.dart`, used by `Course.isValid*Reference`, icon keys,
`BundledPicture`, `RecordedAudioService`; `CustomCourseTransferService.
validateEmbeddedContent` shared with `CourseBackupService.reinstateMedia`;
backup manifests read with a size cap, `JsonLimits`, `CourseShapeLimits`,
asset paths without dot segments, restored media through `ImageValidator` /
`Mp3Validator`; learner backup `expectedValueKind`; `LearnerStatusController`
catch-all). Still to write by hand: `maxManifestBytes`, `_assetPath`, the
imports, `expectedValueKind`/`_hasKind`; update the three tests that restore
fake MP3 bytes (`course_backup_missing_asset_test`, `course_media_243_test`,
`move_private_storage_255_test`) to `syntheticMp3`.

## Revision 3 (2.0.70+270003), no way around the import checks

State: done. Tests 9 new, 2 updated; related 252 passed; analyzer clean;
complete suite 4,092 passed, 1 skipped (05:20–05:54). Committed on
`build-270` as `5b8560e5` and the branch pushed.

Next, remaining findings by severity (owner: continue, one revision each,
ask only where a design choice is needed). Drafts in the scratchpad:
- Revision 4, ZIP directory: `patch_270004_zip.py` (end record checked
  before the library parses, 512 directory bytes per entry, overlap check,
  local/central compression), `zip_directory_270_test.dart`.
- Revision 5, learner-data groups and streaks: `patch_270005.py`
  (`AtomicPreferencesStore.hold`/`group`, Round completion and Duel victory
  grouped, `getStreak` pure, `registerLearningActivity` in one step; add the
  store import to `learning_completion_service.dart` and
  `progress_service.dart`), `learner_data_groups_270_test.dart`.
- Revision 6 (planned): Course ID length at import, Image Bank device
  names, Page link user part, Recovery Key scan skipping bad files, Print
  temp folders, home folder redacted in logs.
- Then ask the owner: forged received updates, Publisher ID squatting,
  backup pruning/dedupe, Android 7–10 backups when the permission is
  refused, the Course Wizard's leave dialog, the INTERNET permission, a
  confirmation before opening Page links. Course store scan speed: deferred
  (small with few Courses).

## Revision 4 (2.0.70+270004), ZIP files checked before they are read

State: done. Tests 6 new; related 266 passed; the converter tried by hand;
analyzer clean; complete suite 4,098 passed, 1 skipped (06:02–06:35).
Committed on `build-270` as `96cebb2c` and the branch pushed. Next: Revision 5
(`patch_270005.py`), Revision 6 (`patch_270006.py`,
`small_items_270_test.dart`), Revision 7 (planned: silent button handlers,
the Test Round's `_next` re-entry, the Round Wizard's approve and the Module
Wizard's next).

## Revision 5 (2.0.70+270005), a completion is saved whole

State: done. Tests 6 new, 2 updated; related 183 passed; analyzer clean;
complete suite 4,104 passed, 1 skipped (06:40–07:17). Committed on
`build-270` as `0a0627bb` and the branch pushed.

## Revision 6 (2.0.70+270006), the audit's smaller findings

State: done (the planned Revisions 6 and 7 together). Tests 6 + 2 new, 1
updated; related 232 passed; analyzer clean; complete suite 4,112 passed,
1 skipped (07:29–08:01). Committed on `build-270` and the branch pushed.

Next: Revision 7, release tooling (in the working tree already: the
packager's Dummy-key guard, `.gitignore` key patterns; to do: `sign_course`
media references from `CourseImageUsage` + the image library, image 300 KB /
cover 1 MB; test `sign_course_media_270_test.dart` in the scratchpad). Then
ask the owner the decisions listed under Revision 3.
