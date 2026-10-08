# 210A Learning Activity Architecture Audit

Date: 2026-08-26

Status: completed architecture audit for QuisquisLingo 2.0.10+210, Modularization Phase 2B. This checkpoint documents the current `2.0.9+209` behavior only. It does not implement `LearningActivityService`.

Evidence labels used below:

- **VERIFIED — source:** directly established from the current production tree.
- **VERIFIED — test:** exercised by a current test, including the fresh focused run recorded below.
- **INFERENCE:** a plausible consequence that depends on runtime timing, concurrency, platform behavior, or another assumption not established by source alone. Deterministic control flow can be **VERIFIED — source** without a dedicated test.
- **UNRESOLVED:** not determined by the current code/tests or dependent on an uncontrolled environment.

## 1. Baseline verified

The required baseline gate passed before the audit began.

| Check | Verified result |
| --- | --- |
| Branch | `main` |
| Expected HEAD | `acfdc8c6d3eba9af810b1fe099bd80c4fbfbae0b` |
| Local HEAD | `acfdc8c6d3eba9af810b1fe099bd80c4fbfbae0b` |
| `origin/main` after `git fetch origin main` | `acfdc8c6d3eba9af810b1fe099bd80c4fbfbae0b` |
| Fetched remote `main` | `acfdc8c6d3eba9af810b1fe099bd80c4fbfbae0b` |
| Ahead/behind | `0/0` |
| Worktree at audit start | Clean |
| App version/build | `2.0.9+209` (`pubspec.yaml:4`) |

Recent build-209 history was read in chronological order:

| Commit | Subject | Relevant result |
| --- | --- | --- |
| `0b7e3f183ed33fba9a7a0aa67359684020484de5` | `Document 209A completion orchestration audit` | Recorded the two Round activity registrations and their ordering risk. |
| `38e454e18ff8ee1d08cb0a86f993e88ca100a3e1` | `Add 209B completion characterization tests` | Added Round, Topic, Review, activity-outcome, and XP characterization. |
| `2301ffb8412d017ef2d027484b4a94b8d365be9b` | `Extract Round completion orchestration service` | Added `LearningCompletionService`, moved the explicit second Round registration into it, and retained the first inside `ProgressService.completeRound`. |
| `acfdc8c6d3eba9af810b1fe099bd80c4fbfbae0b` | `Prepare QuisquisLingo 2.0.9+209` | Completed release hygiene and documented preservation of the second registration and operation order. |

There is no separate commit whose subject identifies a 209D checkpoint. The 209A plan made a separate 209D conditional. The repository history therefore supports the sequence above; assigning an additional undocumented 209D result would be speculation.

Fresh read-only verification was also run:

```powershell
flutter test test/progress_time_test.dart test/progress_service_test.dart test/learning_completion_service_test.dart test/round_xp_completion_regression_test.dart test/topic_completion_regression_test.dart test/xp_service_test.dart
```

Result: **48 tests passed** with exit code 0. Widget tests emitted their expected mocked crash-logger initialization messages. Dependency resolution did not leave a tracked or untracked change.

## 2. Current architecture overview

**VERIFIED — source:** activity ownership is concentrated in `ProgressService`, while several completion methods invoke it as a hidden side effect.

```text
Read/display path

HomeScreen._reload
    -> ProgressService.getStreak              (may persist a reset to 0)
    -> ProgressService.getDaysStudied
    -> StatusService.rank                     (pure consumer)

Round path

TopicScreen / ReviewScreen
    -> RoundScreen
        -> LearningCompletionService.completeRound
            -> ProgressService.completeRound
                -> completed-Round persistence
                -> registerLearningActivity #1
            -> Review/perfect-state work
            -> XP and Weekly XP work
            -> weekly-target read
            -> ProgressService.registerLearningActivity #2

Normal course-path continuation only

TopicScreen, when all Topic Rounds are complete
    -> ProgressService.completeTopic
        -> completed-Topic persistence
        -> registerLearningActivity #3
        -> +25 XP

Duel path

DuelScreen, on win only
    -> ProgressService.winDuel
        -> won-Duel persistence
        -> registerLearningActivity
        -> +50 XP
```

The activity implementation itself consists of:

- an injected clock;
- profile- and language-scoped key construction;
- local calendar-day formatting/parsing;
- a profile-global set of study dates;
- a per-language set of study dates;
- a per-language last-active date and streak integer;
- `getDaysStudied`, `getStreak`, and `registerLearningActivity`.

There is no `LearningActivityService` file or class in the current tree.

## 3. Method ownership table

### Core activity and mixed completion methods

| Current method | Location | Current responsibility and persistence | Production callers | Future 210 boundary |
| --- | --- | --- | --- | --- |
| `ProgressService({DateTime Function()? now})` | `lib/services/progress_service.dart:43-50` | Owns `_now` and constructs `XpService` with the supplied clock. | Every `ProgressService` construction; production generally uses the default. | Pass the same activity clock seam into `LearningActivityService`. `ProgressService` must retain a clock for Review timestamps, and `XpService` retains its own clock responsibility. |
| `_code`, `_lk` | `progress_service.dart:54-56`; `profile_service.dart:67-70` | Trims/uppercases language codes and creates language-scoped activity bases through the active-profile prefix. | Private activity methods. `XpService` has separate helpers. | Move equivalent activity-specific normalization/key resolution; `ProfileService` remains the profile authority. |
| `_k`, `_ck` | `progress_service.dart:52-58` | Generic profile and course key helpers used across activity, leaderboard preference, Review, Guidebook, course progress, and reset behavior. | Many private `ProgressService` paths. | Do not move these helpers wholesale. `ProgressService` retains its generic/course key needs; the activity service resolves only its own profile keys. |
| `_dayString`, `_parseDay` | `progress_service.dart:60-66` | Converts a `DateTime` to `YYYY-MM-DD` through local calendar fields and parses stored last-active strings. | `getStreak`, `registerLearningActivity`. | Move the activity copies. Do not move the separate XP week/date helpers from `XpService`. |
| `_globalStudyDays` | `progress_service.dart:112-115` | Reads `study_days_all` into a set. | `getStreak`, `registerLearningActivity`. | Move. |
| `_languageStudyDays` | `progress_service.dart:117-120` | Reads one language's study dates into a set. | `getDaysStudied`, `registerLearningActivity`. | Move. |
| `getDaysStudied` | `progress_service.dart:122-123` | Returns the number of distinct raw strings in the language study-day list. | `HomeScreen._reload`. | Move implementation; retain a `ProgressService` compatibility delegation. |
| `getStreak` | `progress_service.dart:125-146` | Reads last-active/global dates and can persist the language streak as `0`. | `HomeScreen._reload`. | Move implementation exactly; retain the public facade. It is not a pure getter. |
| `registerLearningActivity` | `progress_service.dart:148-191` | Applies streak transition rules and sequentially writes streak, last-active, global dates, and language dates. | `completeRound`, `completeTopic`, `winDuel`, and the explicit second call through `LearningCompletionService`. | Move implementation; retain the public facade and every current call site/order. |
| `completeRound` | `progress_service.dart:199-209` | Writes a course-owned completed-Round set, then records activity. It does not award XP by itself. | `LearningCompletionService` adapter. | Completion persistence stays in `ProgressService`; only the existing activity call delegates. |
| `recordRecentRound` | `progress_service.dart:214-248` | Writes Review history with `_now()` timestamps. | `LearningCompletionService`. | Remain outside `LearningActivityService`; it is temporal Review history, not study-day/streak state. |
| `completeTopic` | `progress_service.dart:326-337` | Writes course-owned Topic state, records activity, then awards 25 XP. | `TopicScreen._openRound`. | Topic completion remains in `ProgressService`; activity delegates; XP stays in `XpService`. |
| `winDuel` | `progress_service.dart:344-355` | Writes course-owned Duel state, records activity, then awards 50 XP. | `DuelScreen._finishDuel` on a win. | Duel completion remains in `ProgressService`; activity delegates; XP stays in `XpService`. |
| `resetCourse` | `progress_service.dart:389-416` | Deletes course-owned keys and that course's Review entries while intentionally retaining language activity. | `UserDataSettingsScreen`. | Remain outside the activity service; it must continue not to clear activity. |

### Adjacent owners that must remain separate

| Current method/owner | Location | Relationship to activity | Future boundary |
| --- | --- | --- | --- |
| `LearningCompletionProgress.registerLearningActivity` and adapter | `lib/services/learning_completion_service.dart:55-89,179-228` | Preserves the explicit second Round registration through the existing `ProgressService` facade. | Keep the narrow interface unless a later caller migration is explicitly authorized. A direct UI-to-activity-service dependency is unnecessary for 210. |
| `LearningCompletionService.completeRound` | `learning_completion_service.dart:101-168` | Orchestrates the first hidden registration, then XP, then the explicit second registration. | Keep completion orchestration outside the activity service. |
| `XpService` | `lib/services/xp_service.dart:14-199` | Owns language XP, learner-global Weekly XP, course breakdowns, week rollover, and weekly celebration state. | Entirely outside `LearningActivityService`. |
| `ProfileService.key` | `lib/services/profile_service.dart:67-70` | Produces the learner prefix and falls back to profile name `default`. | Remains the profile/key authority used by the new service. |
| `ProfileService.deleteProfile` | `profile_service.dart:53-64` | Deletes every key whose string starts with the computed learner prefix. This can also match a longer underscore-prefixed learner name. | Remains profile lifecycle behavior; do not fix or duplicate it inside the activity extraction. |
| `LearnerBackupService.exportActiveProfile` / `importProfile` | `lib/services/learner_backup_service.dart:29-49,74-140` | Generic prefix export includes activity values and can include a longer underscore-prefixed learner's keys; import writes the supplied suffixes. | Remains backup behavior; unchanged keys/types and current prefix matching must not be silently redesigned in 210. |
| `StatusService.score` / `rank` | `lib/services/status_service.dart:24-43` | Purely consumes XP, streak, days, completed Rounds, and laurels. | Outside the activity service. |

## 4. Production call graph

### Startup, load, and display

`HomeScreen.initState` calls `_reload` (`lib/screens/home_screen.dart:77-81`). `_reload` reads streak and days at `home_screen.dart:191-267`, specifically `:239-242`, and later feeds them to `StatusService.rank` at `:645-651`.

Home repeats that load after:

- changing a bundled or custom course (`home_screen.dart:283-321`);
- creating, switching, or deleting a learner (`:324-465`);
- returning from the course, Review, Settings, or Chapters (`:603-631,675-685,731-742`);
- pull-to-refresh (`:702-704`).

**KNOWN CURRENT BEHAVIOR:** this display path can mutate persistence because `getStreak` writes `0` when it discovers a completed profile-wide blank day. No startup path registers new learning activity.

### Round completion

`RoundScreen` constructs `LearningCompletionService` around its `ProgressService` at `lib/screens/round_screen.dart:67-74,128-132`. A non-preview finish calls it at `round_screen.dart:721-744`.

The exact activity order is:

1. `LearningCompletionService.completeRound` calls its progress boundary (`learning_completion_service.dart:101-110`).
2. The adapter calls `ProgressService.completeRound` (`:185-190`).
3. `ProgressService.completeRound` writes the completed-Round list and invokes `registerLearningActivity` — registration #1 (`progress_service.dart:199-209`).
4. Learning completion records Review history, handles permanent/provisional perfect state, reads Weekly XP, calls `addXp`, reads Weekly XP again, and reads the weekly target (`learning_completion_service.dart:111-158`).
5. It explicitly invokes `registerLearningActivity` — registration #2 (`:156-160`, adapter `:219-221`).
6. `RoundScreen` then handles weekly celebration and route completion (`round_screen.dart:742-764`).

`test/learning_completion_service_test.dart:5-73` protects this two-registration interaction and ordering with an event-log fake. `:201-243` protects it for zero XP, and `:247-288` proves a new-laurel callback failure leaves only the first registration.

### Topic continuation

`TopicScreen._openRound` awaits `RoundScreen` and reloads Round state only when the route returns `true`, but its all-Rounds-complete check is outside that condition (`lib/screens/topic_screen.dart:60-88`). When satisfied, it calls `ProgressService.completeTopic`, which writes Topic state, registers activity, and then awards 25 XP (`progress_service.dart:326-337`).

Consequences:

- a final normal course-path Round can perform **three** registrations: the two Round registrations plus the Topic registration;
- replaying a Round in a completed Topic repeats the Topic registration and 25 XP award;
- backing out of a Round with a `null` result can still register Topic activity and award 25 XP when cached completed-Round state already satisfies the Topic check;
- Review never performs this Topic continuation.

These are current behavior, not recommendations for 210.

### Review

`ReviewScreen._open` launches the ordinary non-preview `RoundScreen` (`lib/screens/review_screen.dart:76-90`). A completed Review Round therefore receives Round registrations #1 and #2. It bypasses `TopicScreen`, so it does not receive registration #3 or Topic XP.

### Duel

Only a win calls `ProgressService.winDuel` (`lib/screens/duel_screen.dart:261-269`). The method writes the won-Duel set, registers activity once, and then awards 50 XP (`progress_service.dart:344-355`). A lost or abandoned Duel does not register activity.

### Preview and Guidebook

Course Editor whole-Round and single-exercise previews construct `RoundScreen(previewMode: true)` at `lib/screens/course_editor_screen.dart:3175-3210`. The preview branch returns at `round_screen.dart:701-720`, before the completion service, so it records no activity.

Guidebook reading does not register activity. `GuidebookScreen` explicitly presents it as not affecting progress, XP, streaks, or unlocking (`lib/screens/guidebook_screen.dart:47`).

### Exhaustiveness result

Repository-wide exact-symbol searches found no additional production callers of `registerLearningActivity`, `getStreak`, or `getDaysStudied`. No UI writes the activity keys directly. The ordinary load/display path can nevertheless mutate streak state through `getStreak`; separate profile deletion and learner-backup import lifecycle paths can delete or overwrite activity keys as documented in sections 5 and 10.

`main.dart:275-279` mounts `HomeScreen` after the startup gate. Exact-symbol searches of `CourseEntryScreen`, `ChaptersScreen`, and `ChapterScreen` found no activity getter or mutator call; those screens provide learning navigation and consume other progress state rather than registering study activity themselves.

## 5. Persistence key inventory

All keys use the active-profile prefix from `ProfileService.key`:

```text
learner_<Uri.encodeComponent(profile)>_<base>
```

When no active profile exists, the key prefix uses the literal profile name `default` (`profile_service.dart:67-70`). Language codes use `courseCode.trim().toUpperCase()` (`progress_service.dart:54-56`). Activity keys contain no `courseId`.

**KNOWN CURRENT BEHAVIOR:** prefix-wide profile lifecycle operations are not collision-safe for all permitted profile names. For example, profile names `A` and `A_B` produce prefixes `learner_A_` and `learner_A_B_`; the second starts with the first. Deleting profile `A` therefore also deletes `A_B`'s learner-prefixed activity values, and exporting `A` also includes matching `A_B` values. This is a source-verified data-isolation risk in `ProfileService.deleteProfile` and `LearnerBackupService.exportActiveProfile`; 210 must report and preserve it rather than fix it incidentally.

| Exact key format | Type | Scope | Default/creation | Update behavior | Deletion/reset behavior |
| --- | --- | --- | --- | --- | --- |
| `learner_<profile>_streak_<CODE>` | `int` | Profile + normalized language | No key is required initially. `getStreak` returns 0 when last-active is absent/unparseable. First registration writes 1. | A new qualifying language day increments it by one; a broken span registers as 1; `getStreak` can write 0. Same-day registration leaves the integer untouched. | Retained by course reset/deletion/import. Removed by profile deletion. Restored/overwritten if supplied by learner backup import. |
| `learner_<profile>_last_active_<CODE>` | `String` | Profile + normalized language | Missing/unparseable is treated as no last activity. | Every registration writes `DateTime(today.year, today.month, today.day).toIso8601String()`, a zone-less local-midnight value. | Same lifecycle as the streak key. |
| `learner_<profile>_study_days_<CODE>` | `List<String>` | Profile + normalized language | Missing means empty. | Read into a set, current `YYYY-MM-DD` added, lexically sorted, and rewritten. Duplicate stored entries collapse logically in the in-memory set on read; storage is deduplicated only on a later registration/write. | Same lifecycle as the streak key. |
| `learner_<profile>_study_days_all` | `List<String>` | Profile-wide across all languages | Missing means empty. | Current `YYYY-MM-DD` is added to a set, sorted, and rewritten. It is the union used for freeze/break decisions. | Deliberately retained by course reset and course deletion. Removed by profile deletion. |

There is no persisted:

- freeze availability, token, counter, or consumed-freeze value;
- global learner streak;
- global last-active timestamp;
- course-specific activity/streak state;
- separate daily-activity flag beyond the two study-day lists.

Compatibility details verified from source:

- study-day strings are not validated before counting;
- `getDaysStudied` counts the size of a set of raw strings;
- an invalid `last_active` is treated as absent;
- a stored streak integer is not clamped or otherwise validated;
- a missing streak integer with a valid last-active value defaults to 0 when read/incremented;
- all writes are separate `SharedPreferences` operations rather than one transaction.

Learner backup export includes every supported value matched by the active learner prefix (`learner_backup_service.dart:29-49`), including the prefix-collision case above. Import overwrites supplied suffixes but does not remove existing activity keys omitted from the backup (`:116-139`).

## 6. Temporal semantics

### Normal calendar progression

**VERIFIED — source and nominal tests:**

1. **Before first activity:** `getStreak` returns 0 and `getDaysStudied` returns 0. Reads do not create activity keys.
2. **First activity:** streak becomes 1; last-active becomes the current local midnight; the date is added to global and language study days.
3. **Same calendar date:** the streak branch is skipped. Last-active and both date lists are still rewritten, but their logical contents do not change.
4. **Immediately following date:** there are no intervening dates, so the stored streak increments by one.
5. **Return after one or more other-language dates:** every calendar date strictly between this language's last-active date and today is checked in `study_days_all`. If all are present, the streak increments by exactly one on return, regardless of how many frozen dates passed.
6. **Return after any profile-wide blank date:** registration writes streak 1. If `getStreak` is called first, it writes and returns 0; the later registration then writes 1.
7. **Study-day count:** cumulative number of distinct dates for that language. A broken streak does not remove prior study days.

### One-day grace and lazy reset

Only completed dates can break a streak. `getStreak` scans from the date after last-active while the candidate is strictly before today (`progress_service.dart:134-143`). Therefore, a language studied yesterday still reports its current streak throughout today even if no activity has occurred today. It resets only once a fully blank date lies between last-active and the current date.

**KNOWN CURRENT BEHAVIOR:** the transition is lazy and per language. A profile-wide blank date does not proactively rewrite every language streak. The next `getStreak` for an affected language persists 0; a direct registration without that read instead restarts the streak at 1.

### Clock sampling and midnight

`getStreak` and each `registerLearningActivity` call sample the injected `_now()` once. Production defaults to local `DateTime.now` (`progress_service.dart:43-50`). A single registration therefore chooses one date even if its awaited writes finish after midnight.

Separate registrations sample independently:

- if Round registration #1 is before midnight and #2 is after midnight, one Round completion records two language/global study dates and can increment the streak twice across those dates;
- Topic registration #3 creates another independent boundary on the final course-path Round;
- if the weekly-goal dialog remains open, Topic registration occurs only after the learner continues and `RoundScreen` returns, so it can land on a later local date than registration #2.

This cross-midnight consequence is **VERIFIED — source** but is not yet covered by a real-collaborator persistence test.

### Timezone and wall-clock behavior

The implementation uses `_now()`'s year/month/day fields and reconstructs `DateTime(year, month, day)` without UTC conversion (`progress_service.dart:60-63,131-133,151-153`). Last-active is stored without a UTC offset; study-day entries contain only `YYYY-MM-DD`.

Therefore:

- **VERIFIED — source:** production behavior follows the device's current local calendar date rather than a persisted timezone;
- **INFERENCE:** changing device timezone can move the apparent calendar date without converting stored activity dates;
- **VERIFIED — source:** if the current date is earlier than a valid stored last-active date, the `lastDay != today` branch runs, the forward-only gap loop performs no iterations, the streak increments, and last-active is rewritten backwards;
- **UNRESOLVED:** exact behavior across platform/timezone-specific daylight-saving transitions. The loop advances local `DateTime` values with `Duration(days: 1)`, but no timezone-controlled test exists.

No relevant activity method body calls `DateTime.now()` directly; the only direct reference is the constructor default. Review recency and XP also use injected clocks, but remain separate responsibilities.

## 7. Multi-language semantics

**VERIFIED — source:** activity is partially shared:

- streak is profile + language;
- last-active is profile + language;
- displayed study-day count is profile + language;
- `study_days_all` is shared by all languages for one profile;
- ordinary activity reads/writes use separate exact keys for each profile, but prefix-wide deletion/export can cross profile boundaries for names such as `A` and `A_B`;
- different courses with the same normalized target-language code share the same activity state.

Concrete consequences:

- studying IT and DE on the same date gives each language its own date and first streak value, while the global list contains that date once;
- alternating languages on consecutive dates freezes each inactive language because another language fills the global calendar;
- returning to a language after multiple continuously studied other-language dates increments that language streak by one, not by the number of elapsed dates;
- one profile-wide blank date eventually breaks each language streak whose last-active date precedes that blank date, but each persisted streak becomes 0 lazily when that language is read;
- freeze is automatic and unlimited; there is no availability check or consumption event.

**VERIFIED — test:** `test/progress_time_test.dart:157-186` covers consecutive IT dates, one DE freeze date, return to IT, a blank-date break, and cumulative per-language study-day counts. `:188-208` covers ordinary isolation for non-overlapping profile names; it does not cover the prefix-collision lifecycle behavior.

## 8. Duplicate-registration behavior

### Two calls on the same date

Two sequential calls for the same language/date are logically idempotent for public state:

- streak does not increment on the second call;
- language day count remains one;
- global day count remains one;
- last-active remains the same local-midnight string.

They are not operationally free. The second call re-resolves profile keys and rewrites last-active, the global list, and the language list. It creates additional I/O, await boundaries, and failure points.

`test/progress_time_test.dart:143-155` verifies the public same-day result and case normalization.

### Two calls in one Round completion

Build 209 deliberately retains:

- registration #1 immediately after completed-Round persistence;
- registration #2 after Review/perfect work, XP accounting, Weekly XP reads, and the weekly-target read.

Thus later failure can make the duplicate externally relevant:

- failure after #1 but before #2 leaves a study day even though later completion work did not finish;
- failure in #2 occurs after XP and other state have already persisted and prevents normal completion return;
- same-day success produces the same final activity values as one call but performs the extra writes;
- a midnight boundary produces two distinct dates and a streak transition.

The event-log tests verify two effective interactions and the partial-failure order, but their first registration is simulated by the fake `completeRound`; they do not exercise real `SharedPreferences` or a changing clock.

### Additional registrations

A final normal course-path Round can add Topic registration #3. A completed Topic's cancelled/replayed Round path can also register Topic activity independently. These registrations are same-day-idempotent in the common case but retain all the temporal and partial-failure effects above.

## 9. XP/completion boundary

`registerLearningActivity`, `getStreak`, and `getDaysStudied` do not read or write XP.

Current coupling exists only in sequential orchestration:

| Flow | Verified order |
| --- | --- |
| Round | completed Round -> activity #1 -> Review/perfect work -> Weekly XP before -> XP write -> Weekly XP after -> weekly target -> activity #2 -> possible weekly celebration |
| Topic | completed Topic -> activity -> 25 XP |
| Duel win | won Duel -> activity -> 50 XP -> win sound |

`XpService` owns:

- language XP;
- learner-global current and previous Weekly XP;
- current/previous week markers and Sunday rollover;
- per-course Weekly XP breakdowns;
- weekly-goal celebration state;
- XP validation/clamping and leaderboard XP.

Those concerns remain outside `LearningActivityService`. `getWeeklyXp` is itself a clock-dependent mutating read because it can perform rollover, but that fact does not make Weekly XP part of learning activity.

`StatusService` combines XP, streak, days studied, completed-Round count, and laurels into a display rank. It consumes multiple domains and owns none of their persistence.

## 10. Reset behavior

### Course reset

`ProgressService.resetCourse(courseId)` removes active-profile keys that end with `_course_<encoded courseId>` and removes that course's Review entries (`progress_service.dart:395-415`). None of the four activity key families has that suffix.

**VERIFIED — source:** course reset preserves language streak, last-active, language study days, and profile-global study days. The comments at `progress_service.dart:389-394` explicitly preserve global days because historic activity may freeze another language's streak.

### Language reset

There is no learner-language reset API. `CourseEditorService.resetCourse(languageCode)` (`lib/services/course_editor_service.dart:92`) resets authored bundled-course overrides, not learner progress. It is unrelated to activity state.

### Profile/all-progress reset

There is no separate learner `resetAllProgress` API. Deleting a learner profile is the available all-profile deletion path. `ProfileService.deleteProfile` removes every preference key beginning with the computed learner prefix (`profile_service.dart:53-64`), including all four activity key families.

**KNOWN CURRENT BEHAVIOR:** that `startsWith` deletion is broader than exact identity when another permitted profile name extends the first with an underscore. Deleting `A` also matches `learner_A_B_...` keys. This audit does not fix the data-loss risk.

### Course deletion and import replacement

Custom-course deletion and same-ID import replacement only update Course Editor storage through `CourseEditorService.saveUserCourse` / `deleteUserCourse` (`course_editor_service.dart:76-90`; `lib/screens/course_projects_screen.dart:404-442,488-534`). They do not call `ProgressService` and do not delete language activity.

That is coherent with the current language scope: deleting or replacing one course must not erase study history shared with other courses in the same language.

## 11. Existing test coverage

The focused suites are green, but coverage for extraction is partial.

| Behavior | Existing evidence | Coverage judgment |
| --- | --- | --- |
| First activity / one logical Round day | `round_xp_completion_regression_test.dart:62-85` | Covered through a real Round; raw values are not asserted. |
| Repeated same-day activity | `progress_time_test.dart:143-155` | Public result covered. Redundant rewrites are not observable. |
| Consecutive-day increment | `progress_time_test.dart:157-176` | Covered. |
| One other-language freeze date | `progress_time_test.dart:157-177` | Covered. |
| Blank-day reset and restart | `progress_time_test.dart:179-184` | Covered when `getStreak` performs the reset before registration. Direct reset-on-registration is not covered. |
| Per-language study-day counts | `progress_time_test.dart:176-184` | Covered nominally. |
| Profile isolation and injected clock | `progress_time_test.dart:188-208` | Ordinary non-overlapping names covered; prefix-wide deletion/export collision missing. |
| Two Round activity interactions/order | `learning_completion_service_test.dart:5-73,201-243` | Covered with a fake, not real persistence. |
| Failure after first Round registration | `learning_completion_service_test.dart:247-288` | Covered with a fake. |
| Normal Round versus preview | `round_xp_completion_regression_test.dart:62-85,135-161` | Activity versus no activity covered. |
| Zero-XP TTS-only completion still records activity | `round_xp_completion_regression_test.dart:163-203` | Covered. |
| Activity before weekly-goal dialog | `round_xp_completion_regression_test.dart:206-245` | Public persisted result covered. |
| Topic/Duel hidden activity side effects | Production source; Topic tests verify Topic/XP results | Not directly asserted as activity behavior. |
| Course reset retains activity | Production source and UI text | Not explicitly asserted. |
| Profile deletion clears activity | Production source | Not explicitly asserted. |
| Exact key names/types/formats | Production source | Not asserted by current compatibility test. |
| Real duplicate registration across midnight | Production source | Missing. |
| Home write-on-read reset | Lower-level `getStreak` test only | No Home/widget coverage; lower-level characterization is sufficient for extraction if expanded. |
| DST/timezone changes | None | Unresolved. |

`test/progress_service_test.dart:356-486` exercises course reset but never reads the activity values afterward. Its storage compatibility test at `:489-529` invokes activity-producing completion methods but asserts only course progress, XP, and Review keys.

`test/topic_completion_regression_test.dart` protects Topic completion/re-award and Review boundaries but does not assert streak/day effects. `test/xp_service_test.dart` appropriately protects the separate XP boundary.

## 12. Missing characterization tests recommended for 210B

The following gaps should be closed before production extraction:

1. Exact raw key names, normalized language suffix, value types, local-midnight last-active representation, and list sorting/deduplication behavior. A seeded unsorted/duplicate-list case must distinguish logical in-memory deduplication on read from persisted cleanup on registration.
2. First-ever public defaults and exact first-registration persistence.
3. One-day grace followed by `getStreak`'s lazy persisted reset on the next date.
4. Direct registration after a blank date without a preceding `getStreak`, proving restart at 1.
5. Two languages on the same date with one global date and separate language dates/streaks.
6. Multiple consecutive other-language dates, proving automatic unlimited freeze and a single increment on return.
7. Both active languages lazily breaking after one profile-wide blank date.
8. Activity sharing between two courses with the same normalized language code.
9. Exact preservation of all four activity values across `resetCourse`.
10. Exact removal of all activity key families for a non-overlapping profile, plus the current `A`/`A_B` prefix-collision behavior in profile deletion and learner backup export.
11. Real `LearningCompletionService` plus real clock-injected `ProgressService` with the clock advanced in `getWeeklyXpTarget`, proving the known two-date/midnight result while complementing the fake two-call interaction test.
12. `completeTopic` and `winDuel` activity side effects in addition to their existing completion/XP assertions.
13. Malformed/missing last-active behavior with existing streak/list values, because extraction must preserve compatibility with stored data.
14. Backward wall-clock behavior, month/year boundaries, and leap-day stepping.

DST-specific results should remain explicitly unresolved unless 210B gains a deterministic timezone-controlled seam. Do not add a production timezone abstraction merely to satisfy this audit.

## 13. Proposed narrow LearningActivityService responsibility boundary

The smallest coherent service should own only:

- the injected activity clock;
- access to `SharedPreferences` and `ProfileService` needed for activity keys;
- activity-specific uppercase language normalization/key construction;
- activity day formatting/parsing;
- global and language study-day reads;
- `getDaysStudied({required String courseCode})`;
- `getStreak({required String courseCode})`;
- `registerLearningActivity({required String courseCode})`.

The compatibility shape should be:

```text
UI / LearningCompletionService
    -> existing ProgressService public APIs
        -> LearningActivityService for activity implementation only

ProgressService.completeRound / completeTopic / winDuel
    -> retain their existing completion responsibilities and call order
    -> delegate their activity step through the same compatibility method

ProgressService
    -> retain Review timestamps, course reset, course progress, and facade APIs

XpService
    -> retain all XP and weekly-state responsibilities
```

This avoids an oversized service and avoids migrating screens during the extraction. It also ensures there is one authoritative activity implementation rather than a copied implementation in both services.

The new service should not own:

- completed Rounds, Topics, or Duels;
- Review history/timestamps;
- course reset or profile deletion;
- XP, Weekly XP, weekly goals, or scoring;
- Status calculation;
- UI refresh, celebration, navigation, or sounds;
- course import/deletion identity behavior.

No activity-specific reset API is needed because none exists today.

## 14. Known current behaviors that 210 must preserve

Unless a separate behavior-change request explicitly replaces them, 210B/210C must preserve:

1. Profile + normalized-language scope for streak, last-active, and language study days.
2. Profile-global, cross-language `study_days_all` used to derive freeze continuity.
3. No freeze token, availability count, consumption, or limit.
4. First activity = streak 1; same-day activity does not increment.
5. Same-day activity still rewrites last-active and both lists.
6. Each return after an uninterrupted span increments by one, not elapsed-day count.
7. One-day grace because today is excluded from break detection.
8. `getStreak` as a mutating read that lazily writes 0.
9. Broken-span registration restarting at 1.
10. Study days remaining cumulative after a streak break.
11. Exact four key families, types, formats, profile fallback, and uppercase/trim normalization.
12. No validation/clamping of stored streak/day strings beyond current parsing/set behavior.
13. Sequential, non-transactional activity writes in their current order.
14. Both Round registrations and their exact position around Review/perfect/XP/weekly-target work.
15. Cross-midnight duplicate calls being able to record two dates.
16. A possible third Topic registration after a final course-path Round.
17. Topic registration/reward after a cancelled or replayed Round when current cached completion satisfies the Topic check.
18. Topic and Duel ordering: progression write -> activity -> XP.
19. Review using the two Round registrations but no Topic continuation.
20. Preview and lost/abandoned Duel producing no activity.
21. Course reset/deletion/import retaining language activity and global study dates.
22. Prefix-wide profile deletion removing activity, including its current longer-name collision behavior.
23. Learner backup continuing to include/restore activity through unchanged keys and current prefix matching.
24. The injected-clock seam; no new direct `DateTime.now()` inside activity logic.
25. Review and XP temporal responsibilities remaining outside the extracted service.

Source-verified edge behavior that is currently untested also includes invalid last-active being treated as absent and backward wall-clock registration incrementing while rewriting last-active backwards. A behavior-preserving extraction must not accidentally change these paths merely because they are surprising.

## 15. Risks, ordering, and lifecycle considerations for 210C

1. **Duplicate collapse:** removing either Round registration changes midnight, partial-failure, and I/O behavior.
2. **Call relocation:** moving activity after XP in `completeRound`, or after XP in Topic/Duel, changes partially persisted outcomes.
3. **Getter purification:** making `getStreak` read-only changes when stale streak integers reset.
4. **Scope drift:** adding `courseId` to activity keys or removing `study_days_all` breaks cross-course and cross-language behavior.
5. **Key drift:** even a semantically equivalent rename/format change would break existing profiles and learner backups.
6. **Clock drift:** constructing the new service with an unrelated/non-injected clock breaks deterministic tests and can make completion collaborators disagree at midnight.
7. **Temporal ownership drift:** moving Review timestamps or XP week logic merely because they use time would create an oversized service.
8. **Partial writes:** current streak, last-active, global days, and language days are separate awaited writes. Reordering or parallelizing them changes failure recovery.
9. **Active-profile lifecycle — INFERENCE:** profile identity is resolved repeatedly across awaits rather than snapshotted. A concurrent profile switch could split one operation across learner keys. 210C should not silently redesign this race without an explicit behavior decision.
10. **Concurrent registrations — INFERENCE:** read-modify-write operations are unsynchronized; concurrent calls can overwrite set updates. Do not introduce or remove concurrency as part of extraction.
11. **Local date iteration:** fixed `Duration(days: 1)` stepping on local `DateTime` values has no timezone-controlled characterization. Preserve the implementation in 210C rather than opportunistically replacing it.
12. **Facade construction:** `ProgressService` still requires `_now` for `recordRecentRound` and still owns `XpService`; extracting activity must not remove those collaborators.
13. **Topic continuation:** migrating only the obvious Round calls can miss `completeTopic`, its third/cancel-path activity, and its pre-XP ordering.
14. **Duel continuation:** a Duel win's activity call is hidden inside `winDuel`; a lost Duel must remain activity-free.
15. **Backup/reset lifecycle:** a new key prefix, custom reset, or migration layer would diverge from generic profile backup and deletion behavior.
16. **Profile-prefix collision:** deletion/export use raw prefix matching, so names such as `A` and `A_B` are not lifecycle-isolated. This is a reportable current data-loss/leakage risk, but correcting it would exceed behavior-preserving 210 scope.

## 16. Explicit out-of-scope items for 210

For the full behavior-preserving build 210, do not include:

- the learner status bar (planned build 211);
- streak celebration (planned build 212);
- a pure `XpCalculator` or XP formula extraction (planned build 213);
- the new XP formula (planned build 214);
- any XP, Weekly XP, weekly-goal, Status, or scoring redesign;
- a new streak/freeze rule, freeze token, grace policy, or timezone policy;
- removal/deduplication of Round or Topic activity registrations;
- changes to Topic re-award/cancel behavior;
- changes to course, language, profile, or reset semantics;
- Finish re-entrancy guards;
- persistence migrations, fallback keys, renamed keys, or new formats;
- a general course-identity/import/deletion refactor;
- UI, navigation, wording, sound, celebration, or presentation work;
- unrelated cleanup or broad `ProgressService` decomposition.

For 210A specifically, production code, tests, app version, Alpha expiry, release files, and packaging are out of scope. This audit creates only this document.

## 17. Recommended exact scope for 210B

210B should be a tests-only characterization checkpoint with no production code, version bump, Alpha-expiry change, or release packaging.

Expected touched files:

- `test/progress_time_test.dart`
- `test/progress_service_test.dart`
- `test/learning_completion_service_test.dart`

Recommended exact additions:

1. In `progress_time_test.dart`, assert first-ever defaults and raw first-registration persistence for `courseCode: ' it '`, including exact four keys, types, normalized `IT` suffix, and local-midnight ISO value. Re-instantiate `ProgressService` and verify public values. In a separate seeded case, prove that unsorted/duplicate study-day values deduplicate logically without rewriting on read, then rewrite sorted and deduplicated on registration.
2. Add one-day-grace and lazy-write tests: activity on date 1, unchanged streak read on date 2, persisted zero on date 3.
3. Add direct broken-span registration without a preceding getter, proving restart at 1.
4. Add same-date IT/DE/IT activity, proving two language states and one global date.
5. Add multiple automatic freeze dates (IT date 1, DE dates 2 and 3, IT date 4), proving IT returns at streak 2 across that span. Absence of a token/limit remains separately verified from source.
6. Seed both language streaks before a profile-wide blank date, then prove each breaks lazily when read.
7. Add deterministic month/year/leap-day coverage and current backward-clock behavior. Keep DST explicitly unresolved unless it can be controlled without production change.
8. In `progress_service_test.dart`, verify two different courses with the same language share activity through the current composite methods.
9. Verify `completeRound`, `completeTopic`, and `winDuel` each produce their existing activity step by advancing a controlled clock between calls.
10. Verify `resetCourse` preserves the exact raw activity values and public streak/day results.
11. Verify `ProfileService.deleteProfile` removes all activity keys and recreating a non-overlapping learner begins at 0/0. Separately characterize the current `A`/`A_B` prefix collision for deletion and `LearnerBackupService.exportActiveProfile`; label it a known current risk, not desired behavior.
12. In `learning_completion_service_test.dart`, add a real-collaborator midnight test: use `ProgressService(now: clock.call)`, advance the clock from date N to N+1 inside `getWeeklyXpTarget`, and assert streak 2, both language/global dates, and last-active on N+1. Retain the existing fake call-count/order assertions; the existing Round widget tests already cover the real same-day public result.
13. Add malformed/missing last-active compatibility cases only through seeded preferences; do not weaken or redesign persistence validation.

No new widget seam or source-text assertion is required. Existing Round/Topic widget tests plus direct service tests already establish the caller continuation; 210B should characterize state transitions through public behavior and raw persistence only where the key contract itself is the requirement.

Suggested 210B validation:

```powershell
dart format test/progress_time_test.dart test/progress_service_test.dart test/learning_completion_service_test.dart
flutter test test/progress_time_test.dart test/progress_service_test.dart test/learning_completion_service_test.dart
flutter test test/round_xp_completion_regression_test.dart test/topic_completion_regression_test.dart test/xp_service_test.dart
flutter analyze
flutter test
git diff --check
git status --short
```

Stop after the independently reviewed 210B test checkpoint. Do not begin `LearningActivityService` production extraction until those characterizations are green.
