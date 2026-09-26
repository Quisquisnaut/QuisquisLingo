# QQL 239 Revision 3: storage inventory for Device Administration resets

Where QuisquisLingo keeps data, and which reset scope removes it.

## SharedPreferences (device-wide)
| Key | Contents | Scopes that remove it |
|---|---|---|
| `learner_profiles_v2`, `active_learner_profile_id`, `local_admin_profile_ids_v1` | learner registry, active learner, admin list | non-admin learners (their records only), everything |
| `qql_device_display_name_v1` | device name | everything |
| `quisquislingo_user_courses_v9_233030`, `quisquislingo_external_official_courses_v9_233030`, `quisquislingo_course_editor_corrupt_backup_v9_233030` | obsolete course blobs and corrupt-course backup; no longer read or migrated by the file store | custom courses, everything |
| `quisquislingo_authoring_teams_v1_2291` | authoring teams | custom courses, everything |
| `quisquislingo_received_custom_course_<URI-encoded trimmed Course ID>` | device-local `true` flag for a Custom Course imported while no local profile was its Maintainer or in its assigned Team; absent means not received | custom courses, everything; also cleared on physical deletion or local authoring of that Course |
| `quisquislingo_imported_image_banks_v2`, `quisquislingo_exercise_image_metadata_v2` | imported image bank index and image metadata | imported media (images), custom courses, everything |
| `audio_orphan_check_last_<COURSECODE>` | device-level date the Audio Library orphan check last ran for that Course code | imported media (audio), custom courses, everything |
| `quisquislingo_diagnostic_log` | diagnostic log text | everything |
| `qql_file_dialog_downloads_offered_v1` (QQL 240) | flag: the first Save to… / Open from… dialog already started in Downloads | everything |
| `flag_game_best_*`, `editor_show_internal_ids_v1`, welcome/one-time notice keys, update-check keys | device settings and notices | everything |

## SharedPreferences (per learner, prefix `learner_<id>_`)
Everything under the prefix belongs to that learner and is removed when the learner is removed, or by everything.

Progress keys (removed by *learner progress*), matched by suffix start:
`v4_` (completed/perfect rounds and lessons, won duels, seen guidebooks, recent rounds), `v1_vocabulary_review_course_`, `xp_`, `week_xp`, `last_week_xp`, `week_goal_celebrated_week`, `study_days`, `streak_`, `last_active_`, `guidebook_availability_notice_seen`.

Everything else under the prefix (identity, avatar, theme, PIN verifier, recovery credential, TTS and audio settings, Course visibility and display settings, IDDQD mode, editor unlock) is kept by *learner progress*.

## Files
| Location | Contents | Scopes that remove it |
|---|---|---|
| `<QQL>/Export` (Build 255 Revision 3) | Quick Export files: `Courses`, `UserData` (learner backups), `RecoveryKeys`, `AuditReports` | everything, only when the admin unticks "Keep the Export folder" |
| `<QQL>/Logs` | copies of the Crash Log and the Diagnostic Log made with Quick Export (`QQL_crash_log.txt`, `QQL_diagnostic_log.txt`) | everything, only when the admin unticks "Keep the Logs folder" |
| `<QQL>/Import` | the original files people copied there for Quick Import: `Courses`, `Audio`, `Images`, `LessonIcons`, `Flags`, `UserData`, `RecoveryKeys` | everything, only when the admin unticks "Keep the Import and ToBeMerged folders" |
| `<QQL>/ToBeMerged` | `Courses`: the second Course of a Course Merge | everything, with the same tick as `Import` |
| `<QQL>/Backups` (Build 255 Revision 5) | `Courses`: the Course Backups Version History lists, one folder per Course, `QQL_bkp_<pair>_<ID>`, holding `QQL_bkp_<pair>_<ID>_v<version>_<date-time>.json` and its `…_assets` folder. Android: ordinary files QQL wrote itself (Android 7–10 with the storage permission) | everything, only when the admin unticks "Keep the Backups folder" |
| `<QQL>/Imports`, `<QQL>/Exports`, `<QQL>/Merges` (earlier versions; `Exports` also holds Course Backups made before Revision 3) | never read since Build 255 Revision 3; Inventory lists them as "Folders from earlier versions" | everything, with the tick of `Import`, `Export` and `ToBeMerged` respectively |
| other files in `<QQL>` | anything people added there themselves | everything |
| `<AppSupport>/QQL_Logs` (Build 255 Revision 4; Revision 3 named it `qql_logs`) | the live Crash Log `QQL_crash.log` and the Windows/Linux session marker `QQL_session.marker`, private on every system | everything, only when the admin unticks "Keep the Logs folder" |

`<QQL>` is `Documents/QuisquisLingo` on Windows, Linux and macOS and the
public `Download/QuisquisLingo` on Android. On Android 10 and later, Export
and Logs hold MediaStore entries QQL owns, and Import and ToBeMerged are read
through one folder permission for `Download/QuisquisLingo`; every full wipe
releases that permission (and one an earlier version held). On Android the
app's own documents folder holds only earlier versions' files (Crash Log,
Course Backups).
| `<AppSupport>/QQL_Courses/Custom`, `<AppSupport>/QQL_Courses/Publisher` (Build 255 Revision 4; the retired `qql_courses_v1` tree of v9/v10 Courses is left untouched and is neither read, listed nor reset) | one JSON file per custom or installed Publisher Course, `QQL_<pair>_<ID>.json` (the language pair, source then target, such as `EN_IT`; a QQL-made ID without its `course_` prefix); interrupted `.tmp` files also belong to this store | custom courses, everything |
| `<AppSupport>/QQL_ImportStaging` (Build 255 Revision 4) | temporary copies of files being checked during an import (Build 243 Revision 10); normally empty, `.part` leftovers are removed at startup | everything |
| `<AppSupport>/QQL_SharedImages`, `<AppSupport>/QQL_ImageBanks`, `<AppSupport>/QQL_CourseMedia` (Build 255 Revision 4), and the earlier `exercise_images` and `image_banks`, whose images keep working because their records hold full paths | shared-library images and image banks; each Course's own images and recorded MP3s, one folder per Course, `QQL_<pair>_<hash of the ID>` (`QQL_<hash>` until the Course is first stored; the retired `quisquislingo_audio` folder is left untouched and unread) | imported media (images or audio, chosen separately: course media is removed by file type), custom courses (both), everything |
| `<AppSupport>/qql_courses_v2`, `quisquislingo_course_media`, `qql_course_backups_v11`, `qql_import_staging`, `qql_logs` (names before Build 255 Revision 4), and Revision 4's private `QQL_CourseBackups` | never read since Revisions 4 and 5; Inventory lists them as "Private folders from earlier versions"; `tools/move_private_storage_255.dart` moves earlier Courses and media to the new names and earlier backups to `<QQL>/Backups/Courses`. Where case is ignored (Windows, macOS) `qql_logs` is the same folder as `QQL_Logs` and gets the new name at startup | everything; the earlier `qql_logs` with the Logs tick, the earlier backup folders with the Backups tick |

The text-to-speech engine keeps no on-disk cache of its own.

**Android backup.** These same `<AppSupport>` media folders (the Revision 4 names and the earlier ones) are the only QQL data excluded from Android's Auto Backup, because the platform quota is 25 MB per app and exceeding it silently disables an app's backup completely. Everything else in this inventory — SharedPreferences (progress, profiles, the PIN verifier and the recovery credential) and the `QQL_Courses` course files — is backed up on purpose, since QQL has no server and this is the only way a learner survives a phone change. Direct device-to-device transfer is not restricted and carries the media too. Course Backups are in the public `Download/QuisquisLingo/Backups` folder (Build 255 Revision 5), outside the app's Auto Backup: they survive an uninstall, and a restore does not bring them back. A reset removes local data; it does not reach a backup Android has already taken, so a later restore can bring data back. Adding a new media folder here means adding it to `res/xml/data_extraction_rules.xml` **and** `res/xml/backup_rules.xml`; see `docs/SECURITY_AND_ROBUSTNESS.md`.

## Notes
- File store: `CourseFileStore` writes each Course through a temporary file and rename, then verifies its contents. The limit is 10 MB per Course. Old course preference blobs are neither read nor migrated. Unreadable files are preserved in place and reported.
- The Inventory lists actual course files, paths, byte sizes and filesystem modification times, including unreadable files. Reset preview detects files even without legacy preference keys; custom-course and full resets remove the entire `QQL_Courses` root, including temporary or malformed files. Other reset scopes preserve it.
- QQL 240 (`Save to…` / `Open from…`): imports through the system file dialog store data in exactly the same places as the fixed-folder imports above, so no scope changes. Files saved with `Save to…` go to a location the user chooses, outside QQL, and are never tracked or removed by a reset. Custom lesson theme icons and "portable" images are embedded in the Course record, not stored as files. See `docs/240_FILE_DIALOGS_PLAN.md` §8.3 for known orphan cases (MP3 and exercise-image files left behind when a clip, exercise or Course is removed; only the bulk media reset removes them).
- Media bundled with the app (`assets/`: image library, flags, lesson icons, mascots, bundled course audio) lives inside the app package, is read-only, and is never touched by any reset. The stored image-metadata key holds the admin's edited copy of the catalog; removing it makes QQL fall back to the built-in catalog.
- *Everything* clears all SharedPreferences (`clear()`), so it is complete by construction; only its file list needs upkeep.
- The application support directory can also hold the preferences file itself, so it is never deleted as a whole: only the folders listed above.
- Course-scoped progress of a removed custom course is not removed by *custom courses*; it is orphaned but harmless and is removed by *learner progress* or *everything*.


### Personal course libraries (Build 241 Revision 1)

`learner_<UUID>_course_library_member_<URI-encoded-course-ID>` is a boolean membership override in SharedPreferences. It never alters Course JSON. Bundled courses and the creator/maintainer's own Custom Courses default to included; pre-existing course-scoped v4 learner records preserve existing access. Imports explicitly add the importer only. An explicit false overrides these defaults.

Build 250 reuses `learner_<UUID>_course_hidden_<Uri.encodeComponent(courseId.trim())>` as the active **Hide in Learner** flag. `true` hides a Personal Library Course from the learner Course Selector; absence shows it. Hiding does not remove Personal Library membership or Course data, and the Course being studied cannot be hidden. `learner_<UUID>_course_favorite_<Uri.encodeComponent(courseId.trim())>` is a separate `true`/absent Favorite flag. Favorite can be set for any Course, including one outside the Personal Library, and does not change membership. These are learner settings, not Course JSON or progress.

Progress reset preserves membership, Hide in Learner and Favorite. Profile deletion/non-admin-profile reset removes that profile's three kinds of keys with its prefix; full reset clears them all. Course-store reset and individual admin uninstall preserve these learner settings and progress for reinstallation. Inventory lists active Favorite flags in its Course Favorites section with the learner owner; membership and Hide remain covered by the Learners section's settings description. No new file folder is introduced.

### Received Custom Courses (Build 250)

`quisquislingo_received_custom_course_<URI-encoded trimmed Course ID>` is a device-level SharedPreferences boolean. Only `true` is meaningful; missing keys are not inferred from Course metadata, including Courses stored before this feature. An imported Custom Course is marked received only when no profile on this device is its Maintainer or belongs to its assigned Team. A later local Maintainer or assigned Team profile blocks the special received-update path. Physical Course deletion and local authoring clear the flag. The flag is never written into Course JSON, package files or learner progress.

An update through this path requires that the importing profile include the Course in its Personal Library, that the Maintainer, assigned Team ID and immutable provenance match, and that both Course versions are positive integers with the imported version strictly newer. It preserves the imported version and learner progress and makes the usual pre-change Course backup. The Inventory lists the flags as records in QQL settings. Learner-progress, non-admin-learner and imported-media resets preserve them; custom-course and full resets remove them.
