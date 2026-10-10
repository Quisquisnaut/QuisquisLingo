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

## Revision 2 (2.0.70+270002), Story lines never stuck, weekly XP across the clock change

- The bug reproduced on this PC (Europe/Rome): the earlier week key of
  Monday 30 March 2026 was `03-28`, Sunday's `03-29`; the new key is `03-29`
  for both (a scratch Dart script).
- New tests: `test/week_xp_270_test.dart` (5: every day of 2026 at four hours
  keyed to its Sunday; XP of the week the clocks go forward stays one week and
  becomes last week; a rollover cut short after last week was copied, and
  after the totals were zeroed, keeps last week; twenty awards at the same
  time across a rollover all count) and three cases in
  `test/spoken_lines_269_test.dart` (a voice that never reports its end frees
  Continue at twice the estimate + 5 s and teaches no pace; Play waits while
  the line reads itself aloud; audio still playing when the learner goes on
  reveals nothing on the next line): 27 passed with `xp_service_test`.
- Related files: `audio_settings_runtime_228_04_test`,
  `recorded_audio_service_test`, `story_runtime_256_test`,
  `tts_process_arguments_test`, `tts_language_resolution_226_03_test`,
  `learner_round_audio_indicator_230_test`, `two_sided_flashcards_268_test`,
  `sequence_round_256_test`, `exercise_laboratory_254_test`,
  `runtime_canonical_256_test`, `tts_voice_test_dialog_228_test`,
  `revision7_fourth_followup_256_test`: 353 passed.
- `flutter analyze`: no issues (one `use_build_context_synchronously` from
  the first draft fixed by returning early).
- Complete suite: **4,083 passed, 1 skipped**, 33:03 (10 October 2026,
  04:40–05:13).

Not tried by hand: stopping speech on leaving a Round on Windows and Linux.

## Revision 3 (2.0.70+270003), no way around the import checks

- New tests: `test/import_side_doors_270_test.dart` (9: bundle paths accepted
  and refused; every file QQL ships matches; a Course naming a picture or a
  picture key outside the bundle refused; `BundledPicture` draws no such
  file; a backup asset path leaving its folder refused; a manifest larger
  than any Course not read and listed as skipped; a restore puts back only
  media passing the import checks; learner backup values of the wrong type
  refused, naming the value; one unreadable learner value keeps the status
  bar and reaches the Diagnostic Log).
- Updated: `course_backup_missing_asset_test` and `course_media_243_test`
  restore real MP3s (`syntheticMp3`) instead of three bytes.
- Related files (25: backups, Version History, Course packages and models,
  bundled Courses, Lesson icons, World Flags, recorded audio, learner status,
  GuideBook pictures, the demo package round trip): 252 passed.
- `flutter analyze`: no issues.
- Complete suite: **4,092 passed, 1 skipped**, 33:42 (10 October 2026,
  05:20–05:54).

## Revision 4 (2.0.70+270004), ZIP files checked before they are read

- New tests: `test/zip_directory_270_test.dart` (6: an ordinary ZIP opens
  and reads; too many entries by the end record; a directory claiming more
  bytes than the file; a directory too large for its entries; overlapping
  entries; a local header with another compression).
- The first draft compared the local entry's compression as the library's
  enum with the central number and refused every ZIP; it now compares the
  raw local header field (found by the related tests at once).
- Related files: `import_archives_tranche4_test`,
  `course_package_import_247_test`, `import_route_matrix_revision19_test`,
  `import_hardening_tranche0_test` (98 passed with the new file); Course
  packages, Image Banks, covers, Merge, Publisher packages and export, the
  demo package round trip (14 files, 121 passed); the converter tests
  (`course_model_v12_256_test`, `course_model_v11_243_test`,
  `negative_cases_256_test`, 47 passed).
- `tools/convert_course_to_v12.dart` converted a v11 package built from
  `test/fixtures/v11/italian_demo_2_pick_the_translation.json` with
  `dart run` (after dropping an import that pulled Flutter in).
- `flutter analyze`: no issues.
- Complete suite: **4,098 passed, 1 skipped**, 33:09 (10 October 2026,
  06:02–06:35).

## Revision 5 (2.0.70+270005), a completion is saved whole

- New tests: `test/learner_data_groups_270_test.dart` (6: changes made while
  held reach the disk together, nothing before; a write queued as a hold
  starts waits for it; nested groups write once; without the store a group
  simply runs; reading a broken streak writes nothing and the next day
  restarts at one; two sessions registered at the same moment add one day,
  where the earlier code added two).
- Updated: two characterization tests in `test/progress_time_test.dart`
  pinned the getter's write of 0 ("lazily persists zero"); they now check
  that the streak read is 0 and the stored count stays until the next study
  day.
- Related files: the store, XP, week, progress, completion, Duel and Lesson
  regression, Test Round, learner status and Statistics tests: 98 + 85
  passed.
- `flutter analyze`: no issues.
- Complete suite: **4,104 passed, 1 skipped**, 37:10 (10 October 2026,
  06:40–07:17).

## Revision 6 (2.0.70+270006), the audit's smaller findings

- New tests: `test/small_items_270_test.dart` (6: Windows device names; a
  Page link with a user part; the importable Course ID, and a 70-character
  ID refused by `courseFromBytes`; the home folder written `~`; one bad
  Recovery Key does not hide a good one and reaches the Diagnostic Log;
  with none usable each file is named with its reason), a Test Round case in
  `test/test_round_attempt_test.dart` (two presses of the last Continue show
  one result; without the guard it showed two, checked by disabling it),
  a Suggest pictures case in `test/picture_aids_267_test.dart`.
- Updated: `test/page_share_258_test.dart` finds the printed PDF in its own
  `QQL_print_` folder and one exported PDF beside it.
- Related files (20: Course Editor modes, Course Wizard, Courses screen,
  Debug logs, Image Banks, GuideBook modules, Module and Round Wizards,
  Pages, profiles, the Course Editor UI, Recovery Keys, Wizard wording, the
  import matrix, audio settings, stored-Course edge cases, folders, log
  writer): 232 passed.
- `flutter analyze`: no issues (a bidirectional character in a test literal
  replaced by its escape).
- Complete suite: **4,112 passed, 1 skipped**, 32:03 (10 October 2026,
  07:29–08:01).

## Revision 7 (2.0.70+270007), release tooling

- New test: `test/sign_course_media_270_test.dart` (a picture only in the
  image library is packaged and the app reads the package); with the earlier
  `tools/sign_course.dart` it fails ("Course package is missing …png").
- `test/publisher_package_243_test.dart` passes; `dart run
  tools/sign_course.dart` still runs (usage printed).
- The packager's guard: this PC's normal release build does not contain the
  Dummy key; the script parses with no errors (PowerShell parser).
- `flutter analyze`: no issues.
- Complete suite: **4,113 passed, 1 skipped**, 32:58 (10 October 2026,
  08:15–08:48).

## Revision 8 (2.0.70+270008), received and published Courses; a shared device

- New test: `test/course_trust_270_test.dart` (8: any learner may delete a
  received Course while an authored one keeps its rule; Course Studio offers
  Delete for a received Course; a published Course has an ID of its own, the
  same at every export; an installed Publisher Course keeps its ID from
  custom Courses after removal, in import review and installation; ten wrong
  PINs make the PIN wait a minute and a right PIN clears the count; the
  admin PIN gate names the wait and learner backups never carry it; with two
  learners each is told once about a shared device; one learner sees
  nothing).
- Updated: `test/publisher_course_export_262_test.dart` expects the derived
  Course ID; `test/flutter_test_config.dart` turns the shared-device notice
  off like the other one-time notices.
- Related files (Course Studio, Course import and review, Publisher export
  and signing, profiles and PINs, Inventory and resets, Help): 105 + 105 +
  83 + 26 passed.
- `flutter analyze`: no issues.
- Complete suite: **4,120 passed, 1 skipped, 1 failed**, 37:04 (10 October 2026,
  10:40–11:17). The failure, `publisher_signing_help_test`, found the
  distributable signing guide worded differently from the in-app Help this
  revision changed; the guide (`docs/PUBLISHER_SIGNING_GUIDE.md`, a docs file
  only) now carries the Help's sentence, and the test passes alone (5 passed).
