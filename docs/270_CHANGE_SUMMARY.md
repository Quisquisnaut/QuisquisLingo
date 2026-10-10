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
