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
| `Documents/QuisquisLingo/Imports`, `Merges` and other files | user staging folders and files | everything |
| `<AppSupport>/exercise_images`, `<AppSupport>/image_banks`, `<AppSupport>/quisquislingo_audio` | imported exercise images, image banks, recorded MP3 files | imported media, custom courses, everything |

The text-to-speech engine keeps no on-disk cache of its own.

## Notes
- Media bundled with the app (`assets/`: image library, flags, lesson icons, mascots, bundled course audio) lives inside the app package, is read-only, and is never touched by any reset. The stored image-metadata key holds the admin's edited copy of the catalog; removing it makes QQL fall back to the built-in catalog.
- *Everything* clears all SharedPreferences (`clear()`), so it is complete by construction; only its file list needs upkeep.
- The application support directory can also hold the preferences file itself, so it is never deleted as a whole: only the folders listed above.
- Course-scoped progress of a removed custom course is not removed by *custom courses*; it is orphaned but harmless and is removed by *learner progress* or *everything*.
