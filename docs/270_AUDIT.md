# QQL 270 audit: weaknesses and vulnerabilities

Audit of `main` at `7900f58b` (`2.0.69+269000`), 10 October 2026. The audit
was read-only: nothing was changed, built or run while it was made. Eight
areas were read in parallel (import parsing, media, trust and signatures,
local authorization, platform and network, persistence, UI lifecycle,
repository hygiene). Findings marked ✔ were re-checked against the code by
the session that wrote this report.

**Overall:** the import gates, signature verification, media validation, the
update checker and process launching are well built. The real weaknesses are
(1) learner data durability, (2) separation between learners on one device,
(3) side doors that skip the import gates (the Backups folder, `assets/`
paths, learner backups) and (4) three new Build 269 audio-hold bugs.

## Owner decisions (10 October 2026)

- Fix in this order: the learner-data store, learner separation, the Build
  269 audio hold and the DST XP bug, the import side doors; then continue with
  the remaining findings by severity, one revision each, asking only where a
  design choice is needed.
- The Diagnostic Log moves out of the learner-data file into its own
  size-limited file.
- Threat model for local security: QQL's PINs and rights stop **easy
  unauthorized access in the app**; they are not meant to resist someone with
  physical or filesystem access, or hand-crafted files. So: no required admin
  PIN, no PIN attempt limit, no lock-down of identity creation from backups or
  Recovery Keys. In-app paths where a PIN that is set can be bypassed with
  ordinary taps are still fixed. Untrusted files from other people (Course
  packages, Image Banks) keep full import validation.

## Fix first

1. **One bad write can lock every learner out (✔ High).** On Windows and
   Linux all learner data is one `shared_preferences.json` that the plugin
   (`shared_preferences_windows`/`_linux` 2.4.1, `_writePreferences`)
   rewrites in place with no temp file; the start-up read decodes it with no
   catch. A crash, power cut or full disk mid-write leaves "Unable to load
   learner profiles." and a Retry that can never work (`lib/main.dart:430`).
   Made worse by:
   - write failures are silent: the plugin returns `false`, QQL ignores it
     in about 70 places, so XP shows saved and vanishes on restart;
   - no single-instance guard (✔): two windows each rewrite the whole file
     from their own copy and the last writer wins; the second instance's
     start-up also deletes the first one's import staging files
     (`ImportStager().removeLeftovers()`, `lib/main.dart:60`);
   - the Diagnostic Log lives in the same file, so each spoken line causes
     about seven whole-file rewrites (`tts_cache_service.dart`,
     `audio_diagnostic_service.dart:130`, `diagnostic_log_service.dart`).
2. **Any learner can overwrite any other learner and can take over a
   PIN-protected admin (✔ High).** Profile › User Data › Restore ›
   "Replace existing" has no actor check and writes the active-profile key
   directly (`learner_backup_service.dart:320-361`). Switching learners never
   removes the previous one's session unlock (`profile_service.dart:552`;
   only Log out clears it, `:571`). A parent (admin, PIN) switches to the
   child; the child restores a backup naming the parent's ID (shown in
   Course Info with Internal IDs); the child is now the parent admin without
   the PIN.
3. **Build 269: Continue can stay grey forever (✔ High).** On Android,
   flutter_tts 4.2.5 never completes `speak` after `onError` or an
   interrupting `onStop` (`FlutterTtsPlugin.kt`, the progress listener);
   once the voice has started only that future releases the line
   (`round_screen.dart:1225-1246`). Same with a recorded MP3 (up to 5
   minutes per clip, `recorded_audio_service.dart:384`) or a stuck Linux
   `aplay` (no timeout, `tts_linux_backend_io.dart:65-80`).
4. **Weekly XP lost in the spring DST week (✔ Medium).** `_weekKey`
   subtracts 24-hour days from local midnight (`xp_service.dart:39-46`); in
   Europe/Rome on 29 March 2026 the Sunday keys `03-29` and Monday–Saturday
   `03-28`, so the rollover takes the "skipped week" branch and zeroes last
   week's XP, twice. Streaks are not affected (checked).
5. **The Backups folder is a side door past every import gate (✔ Medium).**
   Version History reads every `.json` in the user-visible `Backups/Courses`
   with no size cap or `JsonLimits` (`course_backup_service.dart:320, 345`);
   restored media go to `CourseMediaStore.addBytes` without `ImageValidator`
   or `Mp3Validator` (`:409-435`); the checksum is unkeyed; the asset path
   pattern accepts `../x.png` (`:382`). On Android 7–10 other apps with the
   storage permission can write there.
6. **`assets/` references accept any path (✔ Medium).**
   `isValidAudioReference`/`isValidImageReference` check only the prefix
   (`course_models.dart:1291-1300`); picture keys stored as text (icon keys)
   are not checked at all (`round_screen.dart:4330`, `duel_screen.dart:497`).
   A Course can push any bundled file through the SVG or raster decoder
   unbounded, and `assets/../..` might reach outside the bundle on desktop
   (not confirmed at runtime).

## Other security findings

| Sev | Finding | Where |
|---|---|---|
| Med | Received Custom Course "updates" can be forged: any copy with the same IDs and a higher version is offered as a newer version; the real author's updates are then refused and the learner cannot delete it | `course_received_service.dart:64-117` |
| Med | A custom Course can take a Publisher Course's ID: the signed Course can then never be installed; after a Publisher Course is removed, a custom one with its ID inherits its progress | `course_editor_service.dart:376-381, 1337-1342` |
| Med | The admin PIN is a weak gate: changed or removed without the current PIN, the first admin may have none, no attempt limit; delete learner, Make admin and reset another's PIN ask no PIN while the Inventory does | `profile_screen.dart:160-180`, `home_screen.dart:1014-1084` |
| Med | The Recovery Key secret is never checked, so any profile ID can be created and becomes Maintainer of a received Course whose file names it | `user_recovery_key_service.dart:256-277` |
| Med | Learner backup values are not type-checked: one wrong type (`"study_days_all": 5`) throws on every read and only deleting the profile cures it; 5,000 entries / 10 MB allowed | `learner_backup_service.dart:286-306, 476-497` |
| Med | The ZIP central directory is fully parsed before the entry-count limit; a 300 MB package of tiny headers could allocate GBs (size not measured) | `import/bounded_zip_reader.dart:76-86` |
| Low | Overlapping deflate entries are not detected and reads run on the UI isolate, so long freezes are possible | `bounded_zip_reader.dart:141-187` |
| Low | Page links: `https` and any host, including `user@host` and LAN addresses; they open without showing the address (the Team Drive link does) | `page_blocks.dart:16-19` |
| Low | Package and Image Bank images are header-checked only, never test-decoded; Duel and `data:` images are decoded without `cacheWidth` | `course_package_service.dart:455-470`, `duel_screen.dart:691, 736`, `portable_exercise_image.dart:44` |
| Low | `courseId` has no length or character limit: about 230-character IDs make backup file names longer than 255, so every later save fails | `course_models.dart:1675` |
| Low | Image Bank file names `NUL.png`, `CON.png` are accepted (Windows devices) | `image_bank_service.dart:458-464` |
| Low | The Diagnostic and Crash Logs record full user paths, against the file-name-only policy | `inventory_action_service.dart:88-90`, `widgets/reported_action.dart:34-39` |
| Low | Print writes a predictable PDF name in the temp folder and never deletes it | `widgets/page_actions.dart:176-183` |
| Low | Linux TTS: no timeout; relative `PATH` entries are searched | `tts_linux_backend_io.dart:34-80` |
| Low | Android Save as… may delete a file the user chose to overwrite when opening it fails; Android 10 MediaStore deletes are not limited to QQL's own entries | `QqlStorageBridge.kt:269-276`, `QuickFolders.kt:395-432` |
| Info | A Private course's title can show in the import collision dialog; its JSON sits in plain text in Backups | `course_library_operations.dart:568-571` |
| Info | Import refusals (hidden Private course, Audit errors) are enforced in the screen, not again in the service | `course_editor_service.dart:325-440` |
| Info | Official version comparison counts non-numeric segments as 0 | `course_editor_service.dart:1461-1474` |
| Info | A Publisher update over an unopenable stored source skips the version check and the backup | `course_editor_service.dart:1363-1394` |

## Data integrity and reliability

| Sev | Finding | Where |
|---|---|---|
| Med | Completion writes the Round, Laurel and Lesson markers before XP: a crash in between loses the XP for good. The weekly rollover writes the new week marker before zeroing the totals | `learning_completion_service.dart:164-239`, `xp_service.dart:95-97` |
| Med | No lock around XP and activity writes: rollover against `addXp` at a week boundary, two `addXp` calls, `getStreak` writing 0 from a getter | `xp_service.dart:77-97, 208-212`, `learning_activity_service.dart:193` |
| Med | Course backups are never pruned; every save copies all media into a new folder and hashes it three or four times on the UI isolate (100 MB × 50 saves ≈ 5 GB) | `course_backup_service.dart:239-397` |
| Med | Every Course save decodes every stored Course several times on the UI isolate | `course_file_store.dart:172-209` |
| Med | Android 7–10: refusing the storage permission blocks every Course save (the pre-change backup cannot be written) | `storage/android_storage_backend.dart:110-116` |
| Med | Course Wizard: "Leave without saving" says "This step has changes" but discards several staged steps | `course_wizard_screen.dart:961-993` |
| Med | Diagnostic logging volume: about seven events per spoken line, each rewriting the preferences file; the Crash Log rewrites about 2 MB per append once full | `audio_diagnostic_service.dart:130`, `bounded_log_writer.dart:69-86` |
| Med | Windows and Linux TTS `stop()` does nothing; leaving a Round or tapping Play repeatedly lets PowerShell voices overlap for up to 30 s | `tts_cache_service.dart:348-353` |
| Low | A Test Round may pay first-completion XP twice after a second tap during the results awaits (plausible) | `round_screen.dart:2108-2214` |
| Low | Deleting a Course keeps no final backup; its learner keys stay forever and `CourseLibraryService.contains` re-adds membership from them | `course_editor_service.dart:713-749`, `course_library_service.dart:44-60` |
| Low | One bad file stops the whole Recovery Key folder scan | `user_recovery_key_service.dart:183-200` |
| Low | About 12 button handlers await service calls without `runReported` (wizard pause catches, Suggest pictures, Log out, editor mode, settings switches, clipboard) | `course_wizard_screen.dart:667, 926`, `guidebook_editor_screen.dart:540, 782`, `profile_screen.dart:357`, `course_editor_screen.dart:2375`, `course_projects_screen.dart:1144, 1155`, `round_screen.dart:1505`, `duel_screen.dart:357`, `tts_settings_screen.dart:69-82`, `do_not_disturb_settings_screen.dart:67-80` |
| Low | Device image metadata is one ever-growing preferences value | `exercise_image_metadata_service.dart:510-525` |
| Low | Orphan `*.tmp` files in the Course store are never cleaned; no directory fsync after rename on POSIX | `course_file_store.dart:491-537` |
| Low | The image library re-filters 4,334 pictures with regexes on every keystroke | `flat_image_library_screen.dart:1956-2016` |
| Info | `createBackup` throws when one stored media file's hash differs, which blocks every later save of that Course | `course_backup_service.dart:261-265` |

## Build 269 and audio (besides item 3)

- Play on a line still being read (Android): the plugin returns 0 while
  speaking, so a false "audio unavailable" SnackBar appears
  (`round_screen.dart:3890, 3925`).
- A previous line's audio finishing after Continue can reveal the next
  line's "after listening" text and show a late SnackBar on the wrong line
  (`round_screen.dart:1249, 3923`; predates Build 269).
- Leaving a Round does not stop TTS or MP3 playback (`round_screen.dart`
  `dispose`).
- Test hygiene: `SpokenLinePace.shared` and `RoundScreen.lineStopwatch` are
  not reset in `test/flutter_test_config.dart`.
- macOS/iOS flutter_tts returns at once; `realEndShare` already allows for it.

## Build, release, repository

| Sev | Finding | Where |
|---|---|---|
| Med | Android ships as a debuggable debug APK; the release buildType is also signed with the debug key | `tools/package_android_debug.ps1`, `android/app/build.gradle.kts:31-36` |
| Med | The release manifest has no INTERNET permission, so the Android update check always fails (✔) | `android/app/src/main/AndroidManifest.xml` |
| Med | The Windows packager packages whatever is in `build\windows\x64\runner\Release`; a build made with `QQL_ENABLE_DUMMY_PUBLISHER` (whose private key is public in `test/fixtures`) could ship | `tools/package_windows_release.ps1:457-488` |
| Low | Release artifacts are unsigned with no SHA256SUMS; the Gradle wrapper has no `distributionSha256Sum`; `.gitignore` lacks `*.pem`, `*.key`, `*.p12` and transcript files | `android/gradle/wrapper/gradle-wrapper.properties`, `.gitignore` |
| Low | `tools/sign_course.dart` has its own media walker (misses `imageLibrary` and avatars; 50 KB image cap) and can build Publisher packages the app refuses | `tools/sign_course.dart:183, 214-243` |
| Low | `tools/convert_course_to_v12.dart` reads ZIPs with an unbounded `ZipDecoder` | `tools/convert_course_to_v12.dart:86` |
| Low | The untracked `tools/cloud_setup.sh` sets `safe.directory '*'` system-wide, runs `chmod -R a+rwX` and downloads the SDK without a checksum | `tools/cloud_setup.sh:34, 49, 75` |
| Info | The private Piedmontese files remain reachable only from local tags (`v2.0.35`–`v2.0.65`), the branch `claude/dazzling-hawking-a3ca2e` and `refs/codex/*`. GitHub has no tags and no Releases (✔), so nothing is exposed; it also means the update checker finds nothing today | local refs |
| Info | The Windows runner statically imports `dwmapi.dll`; stale version strings in the launcher log (`2.0.29+2293`) and `QUISQUISLINGO_STARTUP_ALPHA` | `windows/runner/CMakeLists.txt:36`, `windows/launcher/launcher_main.cpp:19` |
| Info | The Windows TTS text travels in an environment variable, limited to 32,767 characters | `tts_windows_backend_io.dart` |

## Checked and rejected

- "Windows frees a Story line too early because flutter_tts returns at once":
  wrong. QQL speaks on Windows through its own PowerShell `System.Speech`
  call, which returns when the line has been spoken
  (`tts_windows_backend_io.dart`).
- "The private Piedmontese files are publicly reachable on GitHub": no (see
  above).

## Verified solid

- Publisher signatures: the signed message covers the publisher, the key ID
  and a checksum recomputed from the parsed Course; an empty key can never
  verify; revoked keys, a wrong publisher name and downgrades of an
  openable installed Course are refused; stored Publisher Courses are
  re-verified on every read.
- ZIP entries: absolute paths, drive letters, `..`, case-folded duplicates,
  symlinks and encryption are refused; every entry is inflated to its exact
  declared size and CRC-checked; the package layout is an allowlist; media
  are content-addressed (`media:<sha256>.<ext>`), so Course data never
  reaches a file path.
- `ImageValidator` (header dimensions, pixel cap, no animation, metadata cap)
  and `Mp3Validator` (isolate with a watchdog, every frame walked, artwork
  refused); no user SVG ever reaches flutter_svg; no remote audio or images.
- The update checker: fixed HTTPS endpoint, default TLS, no redirects, a
  256 KB cap; it never downloads or runs anything.
- Processes: no shell anywhere; eSpeak gets `--` before the text; the
  Windows TTS text travels Base64 in an environment variable; QQL-Tools is
  admin-only.
- The Course file store: a stale-copy token, temp file, rename and read-back;
  unreadable files are never replaced.
- Learner backups never carry the PIN verifier or the recovery secret and
  cannot touch the admin list, Teams or other learners' prefixes (they can
  still replace another learner's namespace, item 2).
- Secrets: the only private key ever committed is the documented Dummy
  TEST ONLY key; production trusts it only through a compile-time define.

Not covered: the correctness of the Course Audit's rules, Word Lookup and
grading.

## Fix progress (Build 270)

| Revision | Scope | Status |
|---|---|---|
| 0 | This report; learner-data store: atomic writes, a last-good copy and recovery at start-up, reported write failures, the Diagnostic Log in its own file, one QQL window at a time | done |
| 1 | Learner separation (item 2, within the owner's threat model): only the active learner is unlocked; Replace existing over another learner with a PIN needs that PIN; a restore activates as a switch does | done |
| 2 | Build 269 audio hold (item 3: the line ceiling, Play while speaking, a line already left, audio stopped on leaving a Round, Linux time limits) and weekly XP (item 4 and the rollover order and race) | done |
| 3 | Import side doors: Course Backups checked like an import (item 5), only bundle paths for `assets/` (item 6), learner backup value types, the status bar's catch-all | done |
| 4 | ZIP end record checked before the directory is parsed; overlapping entries and a different local compression refused; the converter's bounded reader | done |
| 5 | A Round's or Duel's completion written as one group; streak reads write nothing; activity registered in one step | done |
| 6 | The Low findings without a decision: Course ID and Image Bank names at import, Page link user part, Recovery Key scan, Print folders, the home folder in logs, silent buttons, double taps | done |
| 7 | Release tooling: the packager refuses a Dummy-publisher build; `sign_course` uses the app's media rule and limits; key files ignored | done |
| 8+ | Findings that need the owner's decision (see the handoff) | asked |
