# QQL 239 Revision 3: storage inventory for Device Administration resets

Where QuisquisLingo keeps data, and which reset scope removes it.

## SharedPreferences (device-wide)
| Key | Contents | Scopes that remove it |
|---|---|---|
| `learner_profiles_v2`, `active_learner_profile_id`, `local_admin_profile_ids_v1` | learner registry, active learner, admin list | non-admin learners (their records only), everything |
| `qql_device_display_name_v1` | device name | everything |
| `quisquislingo_user_courses_v9_233030`, `quisquislingo_external_official_courses_v9_233030`, `quisquislingo_course_editor_corrupt_backup_v9_233030` | custom and external-official courses and the corrupt-course backup | custom courses, everything |
| `quisquislingo_authoring_teams_v1_2291` | authoring teams | custom courses, everything |
| `quisquislingo_imported_image_banks_v2`, `quisquislingo_exercise_image_metadata_v2` | imported image bank index and image metadata | imported media, everything |
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
| `Documents/QuisquisLingo/Exports` | learner and course backups, exports | everything, only when the admin unticks "keep" |
| `Documents/QuisquisLingo/Logs` | crash log, session marker, diagnostic export | everything, only when the admin unticks "keep" |
| `Documents/QuisquisLingo/Imports` | the original images, audio and course files the user copied there | everything, only when the admin unticks "keep" |
| `Documents/QuisquisLingo/Merges` and other files | merge input and other user files | everything |
| `<AppSupport>/exercise_images`, `<AppSupport>/image_banks`, `<AppSupport>/quisquislingo_audio` | imported exercise images, image banks, recorded MP3 files | imported media (images or audio, chosen separately), custom courses (both), everything |

The text-to-speech engine keeps no on-disk cache of its own.

**Android backup.** These same three `<AppSupport>` media folders are the only QQL data excluded from Android's Auto Backup, because the platform quota is 25 MB per app and exceeding it silently disables an app's backup completely. Everything else in this inventory — SharedPreferences, so all progress, profiles, course edits, the PIN verifier and the recovery credential — is backed up on purpose, since QQL has no server and this is the only way a learner survives a phone change. Direct device-to-device transfer is not restricted and carries the media too. A reset removes local data; it does not reach a backup Android has already taken, so a later restore can bring data back. Adding a new media folder here means adding it to `res/xml/data_extraction_rules.xml` **and** `res/xml/backup_rules.xml`; see `docs/SECURITY_AND_ROBUSTNESS.md`.

## Notes
- QQL 240 (`Save to…` / `Open from…`): imports through the system file dialog store data in exactly the same places as the fixed-folder imports above, so no scope changes. Files saved with `Save to…` go to a location the user chooses, outside QQL, and are never tracked or removed by a reset. Custom lesson theme icons and "portable" images are embedded in the Course record, not stored as files. See `docs/240_FILE_DIALOGS_PLAN.md` §8.3 for known orphan cases (MP3 and exercise-image files left behind when a clip, exercise or Course is removed; only the bulk media reset removes them).
- Media bundled with the app (`assets/`: image library, flags, lesson icons, mascots, bundled course audio) lives inside the app package, is read-only, and is never touched by any reset. The stored image-metadata key holds the admin's edited copy of the catalog; removing it makes QQL fall back to the built-in catalog.
- *Everything* clears all SharedPreferences (`clear()`), so it is complete by construction; only its file list needs upkeep.
- The application support directory can also hold the preferences file itself, so it is never deleted as a whole: only the folders listed above.
- Course-scoped progress of a removed custom course is not removed by *custom courses*; it is orphaned but harmless and is removed by *learner progress* or *everything*.
