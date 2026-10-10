# Build 270 validation

## Revision 0 (2.0.70+270000), learner data that survives a bad write

10 October 2026, owner's Windows 10 PC, `build-270`.

- New tests: `test/learner_data_store_270_test.dart` (12: the plugin's file
  and JSON kept, a burst of changes saved whole, the shared_preferences API on
  the store, the last good copy, an empty / cut off / non-object file kept and
  the copy used, starting empty without a copy, a missing file, a leftover
  temporary file, a failed write reported and recovered, a failed read
  retried) and `test/learner_data_270_test.dart` (9: the Diagnostic Log
  file, its one-time move, trimming to three quarters, the write-failure
  SnackBar once a minute, the recovery dialog after the first frame, the
  learner page waiting for it, starting empty, the Inventory section, Wipe
  everything): 21 passed.
- Related files: `bounded_log_writer_test`, `debug_logs_228_03_test`,
  `universal_folders_255_test`, `app_reset_service_239_test`,
  `inventory_239_test`, `stored_course_edge_cases_266_test`,
  `audio_settings_runtime_228_04_test`, `file_dialogs_240_features_test`,
  `android_storage_bridge_255_test`: 131 passed with the new files.
- `flutter analyze`: no issues.
- Windows release build (`flutter build windows --release`), run against the
  owner's own learner data (copied to the session scratchpad first):
  - a second start exited at once with code 0 and one window stayed open;
  - the first start moved the Diagnostic Log out of the learner data
    (`shared_preferences.json` 332,631 → 66,291 bytes,
    `QQL_Logs/QQL_diagnostic.log` 196,608 bytes) and wrote
    `QQL_learner_data_last_good.json`; the Crash Log showed a clean session;
  - an emptied `shared_preferences.json`, and then a cut off one, were kept as
    `QQL_learner_data_damaged_<time>.json` and the last good copy was used;
    the first try showed the recovery dialog under the version Welcome, so
    the learner page now waits for it, and the second build showed it alone
    ("Learner data restored", the copy's time and the kept file's name).
    The test files were removed afterwards.
- Complete suite (`flutter test --no-pub --concurrency=1`, kept awake, TEMP
  on D:): **4,071 passed, 1 skipped**, 33:42 (10 October 2026, 03:18–03:52).

Not checked: the Linux runner (no Linux build on this PC); Android, iOS and
macOS are unchanged (their preference stores already write atomically).

## Revision 1 (2.0.70+270001), a PIN that is set stays a PIN

- New tests: `test/learner_separation_270_test.dart` (4: a learner left with
  a switch is locked again; Replace existing over another learner with a PIN
  refuses no PIN and a wrong PIN and changes nothing, then works with the
  PIN and makes that learner active; your own data without your PIN; a
  learner without a PIN and one new to the device).
- Related files: `learner_profile_identity_test`,
  `qql_233_revision_profile_security_test`, `qql_233_user_recovery_key_test`,
  `qql_229_revision2_test`, `file_dialogs_240_features_test` (80 passed with
  the new file); `profile_navigation_test`, `device_administration_239_test`,
  `startup_profile_gate_test`, `learner_status_controller_test`,
  `app_reset_service_239_test`, `learner_organization_229_test` (86 passed).
- `flutter analyze`: no issues.
- Complete suite: **4,075 passed, 1 skipped**, 33:33 (10 October 2026,
  03:58–04:32).

Not covered by a widget test: the PIN dialog in Profile › User Data (the
restore flow reads files through Quick Import or the system dialog); the
service refuses the replacement without the PIN whatever the screen does.
