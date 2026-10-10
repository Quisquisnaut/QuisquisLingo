# Build 270 change summary

Build 270 fixes the weaknesses found by the audit of 10 October 2026
(`docs/270_AUDIT.md`), in the order the owner chose: the learner-data
store, learner separation, the Build 269 audio hold and the DST XP bug, the
import side doors, then the remaining findings by severity.

Owner threat model (10 October 2026): QQL's local PINs and rights stop easy
unauthorized access in the app. They are not meant to resist someone with
physical or filesystem access to the device, or hand-crafted files. Files
from other people (Course packages, Image Banks) keep full import
validation.

## Revision 0 (2.0.70+270000): learner data that survives a bad write

Audit item 1 (High). On Windows and Linux the shared_preferences plugins
keep every preference in one `shared_preferences.json` and rewrite it in
place, and read it at start-up without catching a decoding error. A crash, a
power cut or a full disk in the middle of a write left a file nobody could
read: QQL stopped at "Unable to load learner profiles." and Retry could
never work. Failed writes were silent (the plugin only printed them in debug
builds), two QQL windows overwrote each other's learner data, and the
Diagnostic Log, stored in the same file, rewrote all learner data for every
entry.

What changed:

- `AtomicPreferencesStore` (`lib/services/storage/atomic_preferences_store.dart`)
  replaces the plugin's store on Windows and Linux (installed in `main()`
  before anything reads a preference). Same file, same place, same JSON, so
  nothing is converted and an earlier version still reads it. Each write
  goes to `shared_preferences.json.tmp`, is flushed and renamed over the
  file (retried briefly when a virus scanner or sync client holds it).
  Writes run one at a time and always save the latest state, so a burst of
  changes is one write.
- Each successful start-up copies the file to
  `QQL_learner_data_last_good.json`. A file that cannot be read (empty, cut
  off, not a JSON object) is kept as `QQL_learner_data_damaged_<time>.json`
  and the last good copy is used; without a copy QQL starts without learner
  data. A read that failed (for example the folder could not be found) can
  be retried, so Retry on the start-up screen works.
- `LearnerDataNotices` (`lib/widgets/learner_data_notices.dart`) tells the
  learner: a dialog after the first frame when the copy was used or QQL
  started empty (with the copy's date and the kept file's name), and a
  SnackBar, at most once a minute, when a save failed. Every problem goes to
  the Crash Log; to the Diagnostic Log too once it has its file.
- The Diagnostic Log moves to `QQL_Logs/QQL_diagnostic.log` (256 KB) on the
  first start (`DiagnosticLogService.initialise`); the preference is removed.
  Wipe everything now keeps it with the Logs choice (it was erased with the
  preferences before). `BoundedLogWriter` trims a full log to three quarters,
  so the next entries are plain appends (the Crash Log rewrote 2 MB for each
  entry once full).
- One QuisquisLingo at a time: on Windows a named mutex in the runner (a
  second start brings the open window forward and exits); on Linux a unique
  `GApplication` whose second activation presents the open window.
- Inventory: section "Learner-data safety copies". Wipe everything removes
  them whatever is kept, so a damaged file can never bring wiped data back.
- `shared_preferences_platform_interface` becomes a direct dependency (same
  locked version, 2.4.2).

Unchanged: scoring, progression, Course files, the learner-data format and
keys, Android/iOS/macOS storage (their platforms already write atomically).
Beta expiry `2026-11-09 23:59:59` local time.

Known limits: the Linux runner change could not be built on this Windows
PC. A learner deleted after the last start-up stays in the last good copy
until the next start-up refreshes it (only Wipe everything removes the
copies at once).

## Revision 1 (2.0.70+270001): a PIN that is set stays a PIN

Audit item 2 (High), fixed within the owner's threat model. A learner who
gave their Access PIN stayed unlocked for the whole session even after a
switch (`ProfileService._sessionUnlockedProfileIds` was only cleared by Log
out), and Restore › Replace existing wrote the active learner directly. So a
child could restore a backup naming the parent after the parent had switched
to the child: the parent's data was replaced and the child was the parent,
without the PIN.

- `ProfileService._unlockOnly`: creating a learner, switching
  (`setActiveProfileById`) and the fallback after deleting the active
  learner unlock only the new active learner.
- `LearnerBackupService.replacingNeedsPin` (on the device, has a PIN, not
  active) and `restorePreservingIdentity(accessPin:)`: replacing such a
  learner needs their PIN (`ProfilePinException` otherwise, before anything
  is written); the restored learner becomes active through
  `setActiveProfileById`, never by writing the active-learner key.
- Profile › User Data asks for the PIN (`learner-import-replace-pin`) before
  Replace existing over another learner with a PIN; Cancel replaces nothing.

Deliberately unchanged (owner, 10 October 2026): the PIN stays optional for
every learner, admins included; no attempt limit; backups and Recovery Keys
may still bring a learner identity onto the device; admin actions keep their
current confirmations.

## Revision 2 (2.0.70+270002): Story lines never stuck, weekly XP across the clock change

Audit items 3 (High) and 4 (Medium), with the audio findings around them.

- `RoundScreen._lineCeiling` (`_armLineCeiling`, `lineCeilingSlack` 5 s):
  once a held line's voice has started, Continue is released after twice the
  line's estimate plus 5 s if the voice has not reported its end. flutter_tts
  4.2.5 on Android never completes `speak` after `onError` or an interrupting
  `onStop` (`awaitSpeakCompletion` is on there); a recording waits up to five
  minutes per clip; Linux `aplay` had no time limit. A line released this way
  teaches `SpokenLinePace` nothing (`_lineCeilingReached`).
- Play on a line (`story-line-play`) is disabled while the line reads itself
  aloud (`_lineSpeaking && !_lineVoiceEnded`) or a tap is playing
  (`_linePlaying`): Android's engine answers 0 while it speaks and QQL
  reported "audio unavailable".
- `_speak` and `_playLine` act only while their exercise is still the one
  shown (`_preparedExerciseGeneration`): a line already left no longer sets
  the next line's `_lineAudioPlayed` (which revealed text "after listening")
  or shows its failure SnackBar.
- `RoundScreen.dispose` stops speech and recordings:
  `TtsCacheService.stop` now calls `stopWindowsTts` (kills the PowerShell
  speaking; a stopped speech tries no other PowerShell) and `stopLinuxTts`;
  `RecordedAudioService.stopAll` stops the players playing. Linux speech
  runs eSpeak (30 s) and aplay (30 s + text length / 5) with time limits,
  and `_findExecutable` skips relative PATH entries.
- `XpService`: `_weekKey` and `_previousWeekKey` count calendar days
  (`DateTime(y, m, d - weekday % 7)`); `weekKeyFor` for tests. The rollover
  (`_rolloverWrites`, shared by the active learner and the per-profile
  rollover) checks the stored week and makes every change in one synchronous
  step, last week first (copied only once: `last_week_xp_week` already the
  previous week means it was), then the totals, the week marker last.
  `addXp` rolls over first and then reads and writes the language total, the
  week total and the per-Course week in one step.

Unchanged: scoring, progression, Course files and learner data.

Known limit: stopping speech when a Round is left was not tried by hand on
Windows or Linux in this session.

## Revision 3 (2.0.70+270003): no way around the import checks

Audit items 5 and 6 (Medium) and the learner backup value finding.

- `lib/models/bundled_asset.dart` (`bundledAsset`, `isBundledAsset`):
  `assets/` and segments of letters, digits, `_`, `-`, `.`, none starting
  with a dot. `Course.isValidImageReference`/`isValidAudioReference`
  (images, GuideBook pictures, the Audio Library) use it, `Course.fromJson`
  checks picture keys (role `icon` texts starting `assets/`), and
  `BundledPicture` and `RecordedAudioService.resolveSourceForClip` refuse
  anything else at run time. Every bundled file matches (tested).
- `CustomCourseTransferService.validateEmbeddedContent` (the World Flag,
  custom flag, Lesson icons and embedded pictures check of every import)
  is shared with `CourseBackupService.reinstateMedia`, which also checks
  each picture with `ImageValidator` (the cover with its own profile) and
  each recording with `Mp3Validator` before putting it back.
- `CourseBackupService.loadBackup`: a manifest over `maxManifestBytes`
  (16 MB) is refused before it is read; the JSON goes through
  `JsonLimits.imports` and the Course through `CourseShapeLimits`; an asset
  path must be one folder and one file, neither starting with a dot
  (`_assetPath`; `../x.png` was accepted).
- `LearnerBackupService.expectedValueKind` (`LearnerValueKind`): whole
  numbers `xp_*`, `week_xp`, `last_week_xp`, `streak_*`; texts the week keys,
  `week_xp_by_course`, `last_week_xp_by_course`, `week_goal_celebrated_week`,
  `last_active_*`, `skin_tone`, `hair_tone`, `theme_mode`; true or false
  `local_leaderboard_participation`, `guidebook_availability_notice_seen`;
  lists of texts `v4_*`, `study_days*`. Other values are kept as they are.
- `LearnerStatusController.refresh` reports any other error to the
  Diagnostic Log and keeps the bar instead of failing every refresh.

Owner threat model: the backup checks protect against files people put in
the Backups folder or receive, not against someone editing QQL's private
files.

Unchanged: scoring, progression and learner data. A stored Course that named
an `assets/` path outside the bundle (none of QQL's tools ever wrote one)
would now be listed as unreadable.

## Revision 4 (2.0.70+270004): ZIP files checked before they are read

Audit: "the ZIP central directory is fully parsed before the entry-count
limit" (Medium), overlapping entries (Low), local/central compression
(Info), the converter's plain decoder (Info).

- `BoundedZipReader._checkEndRecord`: before `ZipDirectory.read` (which
  parses the whole directory whatever the end record says), the end record,
  and the ZIP64 one when present, are read from the last 64 KB: more than
  `maxEntries` entries, or a directory larger than `maxEntries ×
  maxDirectoryBytesPerEntry` (512), is refused as too many entries; a
  directory outside the file as unreadable.
- `_checkNoOverlap`: every local header must start with its signature, use
  the central directory's compression method, and with its data lie apart
  from the others' and before the central directory.
- `tools/convert_course_to_v12.dart` reads packages with `BoundedZipReader`
  (Course package limits written in the tool: it runs with `dart run`, and
  `CoursePackageService` needs Flutter).

Unchanged: every ZIP QQL or the bundled tools write passes (the import,
package, Image Bank, Merge and Publisher tests, 219 tests in 19 files).

## Revision 5 (2.0.70+270005): a completion is saved whole

Audit: "progress is marked before XP is paid" and "no lock around XP and
activity writes" (Medium).

- `AtomicPreferencesStore.hold(body)` and the static `group(body)`: while a
  group runs, changes stay in memory (each `set` reports success at once)
  and are written in one write when the outermost group ends; a write queued
  before the group that runs during it skips (the group's write covers it),
  and every write takes its snapshot before it waits, so no file ever holds
  half a group. Without the store (Android, iOS, macOS, tests) a group simply
  runs. A failure of the group's write is reported as any failed write.
- `LearningCompletionService.completeRound` and `ProgressService.winDuel`
  run as one group: the Round's completion, recent-round record, Laurel,
  On Time claim, Lesson completion, XP and activity (or the Duel's victory,
  activity and XP) reach the disk together.
- `LearningActivityService.getStreak` only reads (it wrote 0 for a broken
  streak); `registerLearningActivity` looks up its keys first and then reads
  and writes everything in one synchronous step.

Unchanged: scoring, progression and what learners see (the stored streak
count of a broken streak now stays until the next study day restarts it).

## Revision 6 (2.0.70+270006): the audit's smaller findings

The Low findings that need no decision (planned as Revisions 6 and 7,
delivered together).

- `CustomCourseTransferService.importableCourseId`
  (`^[A-Za-z0-9][A-Za-z0-9._-]{0,63}$`) checked by `courseFromBytes` (every
  import route) before the embedded content; stored Courses are not
  re-checked.
- `isReservedWindowsName` (`import/safe_file_name.dart`; device stems, a
  trailing dot or space) refuses an Image Bank file name.
- `PageBlocks.isAcceptableLink` refuses a user part (the Audit's
  `PAGE_LINK_INVALID` follows).
- `UserRecoveryKeyService.findImportableUserRecoveryKeys` skips a file that
  is not a usable key, logs it, and names every skipped file with its reason
  when none is usable.
- `PageActionsBar` Print: `createTemp(printFolderPrefix)` for each print,
  earlier `QQL_print_*` folders removed (a file still open is left).
- `DiagnosticLogService.redact` (the home folder, both slash forms, written
  `~`) on every Diagnostic Log entry and every Crash Log report.
- `runReported` around Log out (`profile_screen`), the Course Editor mode,
  New Course's profile reads, Report a problem's copy (Round and Duel; the
  dialog closes either way, the success message only after a copy), the
  Audio Settings and Do Not Disturb switches (the switch changes only when
  saved). The Course Wizard's pause and the GuideBook picture catalog log
  their failures; Suggest pictures shows
  `guidebook-module-suggest-pictures-unavailable`.
- `RoundScreen._next` runs one advance at a time (`_advancing`; the body is
  `_advance`): a second Continue while the Test results waited for a setting
  showed the results twice and could complete the Round twice. The Round
  Wizard's `_approve` (`_approving`) and the Module Wizard's `_next` run
  once at a time.

Not done (need building or a device): the Android Save as… and MediaStore
findings, the Windows runner's `dwmapi.dll` load flag, stale launcher
version strings.
