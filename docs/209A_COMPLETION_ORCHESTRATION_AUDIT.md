# 209A Completion Orchestration Audit

Date: 2026-08-26

Status: completed read-only production audit for QuisquisLingo 2.0.9+209, Modularization Phase 2A.

## Scope and outcome

209A audited the current learner completion flow and proposes a test-first extraction plan. No production code, tests, platform code, persistence, application behavior, or app version was changed during the audit.

The intended later direction is:

```text
RoundScreen
    |
    v
LearningCompletionService
    |-- ProgressService
    |-- XpService
    `-- LearningActivityService (not present in the current tree)
```

The extraction is feasible, but it is ordering-sensitive. In particular:

- `ProgressService.completeRound()` already records learning activity, and `RoundScreen` records it a second time later.
- Topic completion and its 25 XP occur in `TopicScreen` only after `RoundScreen` has completed weekly-goal handling and returned.
- Topic completion currently re-awards 25 XP when invoked for an already-completed Topic.
- Persistence is sequential and non-transactional, so reordering changes partial-failure behavior.

209B should add behavior-level characterization tests before any production extraction.

## Baseline Git and version state

- App version/build: `2.0.8+208` (`pubspec.yaml:4`).
- Baseline branch: `main`.
- Baseline commit: `a26d8af10080c5a8a2cdb610d37fd31172bf8ed5` (`Initial QuisquisLingo baseline 2.0.8+208`).
- Upstream: `origin/main`.
- Baseline synchronization: `+0/-0` relative to `origin/main`.
- No tracked or staged changes existed at audit start.
- The worktree was technically dirty only because of two pre-existing untracked files:
  - `QuisquisLingo_Roadmap_post_208_UPDATED.md`
  - `QuisquisLingo_Roadmap_post_208_UPDATED.txt`
- Those files were treated as user-owned and were not modified or included in the 209A checkpoint.
- No Flutter, Dart, build, validator, or packaging command was run during the read-only audit. Current test pass status was not freshly executed in 209A.

## Current completion-related source surface

The primary implementation is `lib/screens/round_screen.dart`:

- service instances and attempt state: lines 66-97;
- initialization, exercise auditing, TTS filtering, and completed-state snapshot: lines 158-223;
- dynamic TTS-disabled exercise skip: lines 300-325;
- answer/error/first-pass bookkeeping: lines 536-565;
- completion coordinator `_next()`: lines 665-782;
- potential-XP text and Finish button: lines 1727-1745.

Completion-related callers and continuations are:

- `lib/screens/topic_screen.dart:60-98` for normal course-path Rounds and later Topic completion;
- `lib/screens/review_screen.dart:76-89` for Review replays;
- `lib/screens/course_editor_screen.dart:3175-3210` for whole-Round and single-exercise previews;
- `lib/screens/duel_screen.dart:261-296` for analogous but distinct Duel completion orchestration, which is outside 209.

No other production callers of `completeRound`, `recordRecentRound`, `markPerfectRound`, `markTtsSkippedPerfectRound`, or `completeTopic` were found.

## Attempt state that feeds completion

`RoundScreen._initializeRound()` performs the following before play:

1. Runs Course Audit checks and excludes exercises with structural audit errors.
2. Reads the setting that skips TTS exercises.
3. Filters valid exercises that require TTS when that setting is active.
4. Sets `_ttsWasSkipped` when filtering removed at least one valid exercise.
5. Stores the filtered exercise indices in `_queue`.
6. Reads course-owned completed Rounds and snapshots `_wasCompleted` before the attempt.
7. Shuffles the presented queue and prepares the first exercise.

A listening exercise can also be skipped dynamically when it requires system TTS and TTS is disabled. That path:

- sets `_ttsWasSkipped`;
- shows the existing TTS-disabled SnackBar;
- calls `_next()` without marking the answer;
- leaves the exercise index in the mutable queue.

Answer bookkeeping is owned by the widget:

- `_errorsThisAttempt` increments for every incorrect submission, including review-phase errors;
- `_firstPassCorrect` increments only for first-pass correct answers;
- `_wrongFirstPass` records only first-pass misses;
- one mandatory review pass presents the missed exercises;
- corrections during review do not retroactively earn first-pass XP;
- flashcards do not increment first-pass-correct XP;
- flashcard "Review again" appends another occurrence to `_queue`.

These values are authoritative inputs to current completion behavior. A new service must not reconstruct them from the nominal Round model.

## Exact current order of Round completion

The sole Round finish coordinator is `_next()` at `lib/screens/round_screen.dart:665-782`.

### Pre-completion branches

1. If another queue position exists, advance and prepare the next exercise.
2. If the first pass ended with mistakes:
   - show the non-dismissible "Review your mistakes" dialog;
   - replace `_queue` with `_wrongFirstPass`;
   - shuffle it, reset position, and run one review pass;
   - review errors increase `_errorsThisAttempt`, but do not create another review pass.
3. If `previewMode` is active after any review pass:
   - show "Preview complete";
   - write no learner progress, Review history, perfect state, activity, or XP;
   - pop the route with `null`, not `true`.

### Persisted completion branch

For a normal learner Round, operations are awaited sequentially in this exact order:

1. Derive `courseCode` with `CourseService.codeForCourse(widget.course)`.
2. Call `ProgressService.completeRound(roundId, courseId, courseCode)`.
3. Inside `completeRound`:
   - write the course-owned completed-Round ID set;
   - call `registerLearningActivity(courseCode)` for the first activity registration.
4. Call `ProgressService.recordRecentRound(courseId, roundId, errors)`.
5. Inside `recordRecentRound`:
   - remove the previous entry for the same course/Round identity;
   - add the current result with `_now()` and the total error count;
   - retain at most 50 distinct recent Round IDs per course;
   - persist the profile-level encoded recent-Round list.
6. If the result has zero errors and no TTS skip:
   - call `markPerfectRound`;
   - persist the permanent laurel;
   - remove the same Round from the provisional TTS-skipped set;
   - return whether the laurel was newly earned;
   - if newly earned and sound effects are enabled, await the existing victory sound before XP is calculated or written.
7. Otherwise, if the result has zero errors and TTS was skipped:
   - call `markTtsSkippedPerfectRound`;
   - do nothing if a permanent laurel already exists;
   - otherwise persist the provisional TTS-skipped mark.
8. Calculate XP in `RoundScreen`:

   ```text
   fullRoundXp = final mutable _queue.length * 5

   if _errorsThisAttempt == 0 and _wasCompleted == true:
       awardedXp = fullRoundXp ~/ 2
   else:
       awardedXp = _firstPassCorrect * 5
   ```

9. Read Weekly XP into `weekBefore`. This read may perform Sunday rollover.
10. Call `addXp(awardedXp, courseCode, courseId)`, even when `awardedXp` is zero.
11. Inside `XpService.addXp`, write in order:
    - language XP;
    - learner-global current Weekly XP;
    - per-course Weekly XP JSON keyed by trimmed `courseId`.
12. Read Weekly XP into `weekAfter`.
13. Read the device-level Weekly XP target from `SettingsService`.
14. Explicitly call `ProgressService.registerLearningActivity(courseCode)` for the second activity registration.
15. If all of the following are true:
    - `RoundScreen` is still mounted;
    - `weekBefore < weekTarget`;
    - `weekAfter >= weekTarget`;
    - the current week is not already marked celebrated;
16. Then:
    - mark the weekly goal celebrated;
    - optionally await the existing victory sound;
    - show the "Weekly goal reached!" dialog with `weekAfter / weekTarget`;
    - wait for Continue.
17. If still mounted, pop `RoundScreen` with `true`.

There is no ordinary results screen. The last first-pass exercise shows only potential perfect XP before completion; `awardedXp` itself is not rendered after completion.

## Topic completion ordering and semantics

Topic completion is not performed by `RoundScreen`.

On the normal course path, `TopicScreen._openRound()`:

1. pushes `RoundScreen` and awaits its `bool?` route result;
2. reloads completed/perfect/TTS-skipped Round state only when the result is `true`;
3. counts completed Round IDs belonging only to the current Topic;
4. if the Topic is nonempty and every current Topic Round is complete, calls `ProgressService.completeTopic`;
5. shows the existing `Topic completed. +25 XP` SnackBar.

`ProgressService.completeTopic` then:

1. writes the completed-Topic set;
2. registers learning activity;
3. adds 25 XP.

Current confirmed consequences:

- `completeTopic` does not check whether the Topic ID was newly added before recording activity and awarding 25 XP.
- `TopicScreen` performs its all-Rounds-complete check after every Round route return; only the reload is conditional on a `true` result.
- Replaying a Round in an already-completed Topic can therefore re-award 25 XP.
- Backing out of a Round with `null` can also re-award 25 XP when the cached Topic is already complete.
- Topic XP is added only after Round weekly-goal handling and route return.
- A weekly target crossed solely by the Topic's 25 XP is neither displayed nor marked celebrated by this flow.
- Review replays never perform the Topic completion continuation.

This is surprising current behavior, but correcting it would change Topic and XP semantics. A behavior-preserving 209 extraction must not silently make Topic completion idempotent or move it into the Round transaction.

## Responsibilities currently in RoundScreen

### Business and orchestration responsibilities suitable for extraction

- persist completed-Round state;
- persist/update the recent-Round result;
- choose permanent laurel versus provisional TTS-skipped state;
- calculate awarded XP from the widget-provided attempt facts;
- read Weekly XP before and after accounting;
- account for language XP, learner-global Weekly XP, and course breakdown XP;
- perform the existing second activity registration;
- decide whether the weekly target was newly crossed;
- read/mark weekly-goal celebration state.

### Presentation and interaction responsibilities that should remain in RoundScreen

- Course Audit filtering and exercise presentation;
- TTS filtering, playback, disabled-TTS skips, and existing TTS SnackBar;
- answer validation, answer feedback, first-pass counters, and error counters;
- mistake-review queue and dialog;
- preview-mode dialog and no-write exit;
- mounted/lifecycle checks;
- sound playback;
- weekly-goal dialog text and interaction;
- potential-XP wording;
- route navigation and the `true`/`null` result contract.

### Responsibilities that should explicitly not move in 209

- Topic completion into the Round completion method;
- Duel completion orchestration;
- Review ranking/history rules beyond recording the existing latest Round result;
- TTS semantics;
- UI wording or appearance;
- navigation behavior;
- a general-purpose public `XpCalculator` boundary;
- persistence keys, formats, migrations, or compatibility fallbacks;
- course identity/import behavior;
- startup diagnostics;
- packaging or platform code.

## Existing service boundaries

### ProgressService

`ProgressService` is the current compatibility-facing facade. Completion-relevant APIs include:

- `getCompletedRounds`;
- `completeRound`;
- `recordRecentRound` / `getRecentRounds`;
- `getPerfectRounds` / `markPerfectRound`;
- `getTtsSkippedPerfectRounds` / `markTtsSkippedPerfectRound`;
- `getCompletedTopics` / `completeTopic`;
- `getStreak`, `getDaysStudied`, and `registerLearningActivity`;
- compatibility delegations for XP and weekly-goal methods.

`completeRound`, `completeTopic`, and `winDuel` already combine progress writes with activity registration. `completeTopic` and `winDuel` also award XP.

### XpService

`XpService` owns:

- language XP totals;
- learner-global current and previous Weekly XP;
- per-course Weekly XP breakdowns;
- Sunday rollover and skipped-week behavior;
- weekly-goal celebration state;
- XP validation and integer clamping.

`RoundScreen` does not currently construct `XpService`; it reaches these operations through `ProgressService`.

### LearningActivityService

No `LearningActivityService` file or class exists in the current tree.

The actual activity API and implementation currently live in `ProgressService`:

- `getDaysStudied` at lines 122-123;
- `getStreak` at lines 125-146;
- `registerLearningActivity` at lines 148-191.

That implementation owns the current profile-key behavior, uppercase language normalization, injectable local clock, streak-freeze rules, last-active timestamps, global study-day history, and language study-day history.

The smallest 209C implementation should use the real `ProgressService` activity facade. If the target architecture requires a concrete `LearningActivityService` during build 209, extract it as a separate 209D step by moving only the current activity/streak/study-day behavior and keeping `ProgressService` public APIs as delegations.

## Legacy and compatibility audit

No LingoGrow-specific identifier, persistence-key fallback, filesystem fallback, package-name fallback, or migration branch was found in the audited Round/Progress/XP completion path.

The current completion work should therefore target only the active QuisquisLingo keys, formats, and behavior. It must not add a pre-QuisquisLingo migration or compatibility branch.

Unrelated compatibility code exists elsewhere in the repository, including Course Model v2 import handling, legacy course-author/input representations, and the retained startup-animation preference key. Those paths are outside 209 and were not removed or otherwise modified.

## Current persistence and ordering dependencies

Principal current formats include:

- completed Rounds: profile/course-scoped `StringList`;
- completed Topics: profile/course-scoped `StringList`;
- permanent and TTS-skipped perfect Rounds: separate profile/course-scoped `StringList` values;
- Review history: profile-level `StringList` entries encoded as `courseId|roundId|ISO timestamp|errors`;
- language XP: profile/language-scoped integer;
- current Weekly XP: profile-level integer;
- Weekly XP by course: profile-level JSON object keyed by trimmed `courseId`;
- current and previous week markers: Sunday `YYYY-MM-DD` strings;
- weekly celebration: profile-level Sunday week string;
- streak: profile/language-scoped integer;
- last activity: profile/language-scoped ISO string;
- global and language study days: sorted `StringList` values of `YYYY-MM-DD`.

Extraction-sensitive dependencies are:

- `_wasCompleted` must remain a pre-attempt snapshot. Reading after `completeRound` would halve every first perfect completion as though it were a repeat.
- XP uses the final mutable queue length, not the nominal Round exercise count.
- Dynamic TTS skips and flashcard queue extension can affect that queue.
- `_errorsThisAttempt` includes review errors; `_firstPassCorrect` excludes review corrections.
- `addXp(0)` still performs current rollover and persistence operations; optimizing it away could change stored shape.
- `getWeeklyXp()` is not a pure read because it may roll the week over.
- all writes are sequential and non-transactional;
- a failure can leave completed-Round state without later Review, laurel, XP, activity, celebration, or navigation effects;
- the newly-earned-laurel sound is awaited before XP;
- weekly celebration marking is currently gated by widget lifecycle;
- the two activity registrations can observe different local days if completion spans midnight;
- multiple time reads can cross a local-day or Sunday boundary;
- there is no in-flight Finish guard, so current repeated-tap race behavior must not be silently changed in 209.

## Relevant existing tests

### Round behavior-level coverage

`test/round_xp_completion_regression_test.dart` currently covers:

- imperfect first completion stores progress and Review history and awards only first-pass-correct XP;
- perfect first completion stores a laurel and awards 5 XP per exercise;
- perfect repeat uses the established half-full-Round cap;
- a perfect presented subset with skipped TTS stores the provisional mark without a laurel;
- preview completion returns `null` and writes no progress or XP.

The suite mounts `RoundScreen` directly, not through `TopicScreen` or `ReviewScreen`.

### Lower-level service coverage

`test/progress_service_test.dart` covers:

- course and learner isolation;
- completed Rounds/Topics, laurels, provisional marks, Duels, and Review history;
- permanent laurel replacement of a provisional TTS-skipped mark;
- recent-result replacement and prioritization;
- service re-instantiation persistence;
- course reset scope and XP preservation;
- current principal progress/XP key names and formats;
- `completeRound` alone awarding no XP.

`test/progress_time_test.dart` covers:

- Weekly XP rollover and skipped weeks;
- weekly-goal celebration reset at Sunday;
- deterministic streak and study-day behavior;
- multiple-language streak freeze/break rules;
- learner-profile isolation;
- Review recency using an injected clock.

`test/xp_service_test.dart` covers:

- language and learner-global XP persistence;
- per-course Weekly XP breakdowns;
- negative-XP rejection and integer clamping;
- Sunday rollover and skipped-week behavior;
- profile-scoped leaderboard and weekly celebration state.

`test/unlock_service_test.dart` covers Chapter unlocking from completed Topic sets, but does not prove that finishing Rounds through `TopicScreen` produces those Topic completions.

There are no widget tests for `TopicScreen`, `ReviewScreen`, or `DuelScreen`, and no test observes the exact full completion operation order.

## Missing characterization coverage

Before production extraction, the smallest important additions are:

1. Connect full Round completion to learning activity:
   - normal Round completion creates one observable study day/streak;
   - preview completion creates no activity.
2. Characterize dynamic TTS-disabled zero-XP completion:
   - completed-Round state;
   - latest Review entry;
   - provisional TTS-skipped mark;
   - no laurel;
   - zero XP;
   - current activity and zero-award persistence effects.
3. Characterize Round weekly-target crossing:
   - completion/Review/laurel/XP/activity are persisted before the dialog;
   - weekly celebration is marked before presentation;
   - the parent route does not complete until Continue;
   - the same week is not celebrated twice.
4. Add an imperfect-repeat case to freeze current repeat scoring.
5. Add a reset-then-perfect case to freeze restored first-completion eligibility.
6. Characterize TopicScreen behavior:
   - a non-final Round does not complete the Topic or award 25 XP;
   - the final Round does;
   - unrelated completed Rounds in the course are ignored;
   - Topic-only weekly-target crossing is not celebrated;
   - the current already-complete/cancelled-return re-award behavior is either frozen or separately authorized for change.
7. Add a ReviewScreen caller-context case if practical:
   - perfect replay updates Review/laurel and repeat XP;
   - no Topic completion or Topic bonus occurs.

Exact collaborator order is not practically observable from the hard-wired `RoundScreen` without changing production code. Avoid source-text tests. When `LearningCompletionService` is introduced but before the screen is wired to it, use injected fakes with an event log to assert the service call sequence and result fields.

## Proposed LearningCompletionService boundary

The service should receive the attempt facts already determined by the widget rather than the full `Course`, `Topic`, or `LearningRound` model.

Suggested input shape:

```dart
LearningCompletionRequest(
  roundId,
  courseId,
  courseCode,
  errorsThisAttempt,
  firstPassCorrect,
  repeatCapExerciseCount, // final mutable queue length
  wasCompletedAtStart,
  ttsWasSkipped,
)
```

Suggested minimal result shape:

```dart
LearningCompletionResult(
  awardedXp,
  weeklyXpBefore,
  weeklyXpAfter,
  newlyEarnedLaurel,
)
```

The service should orchestrate:

- completed-Round persistence;
- recent-Round persistence;
- permanent/provisional perfect state;
- the exact current XP calculation;
- XP accounting and Weekly XP reads;
- the existing activity-registration points;
- weekly-goal state checking/claiming through a narrow method.

`RoundScreen` should use the result only for presentation and navigation.

The laurel sound is currently interleaved before XP. To preserve that ordering without moving sound playback into the service, 209C should use a small staged call or a narrow newly-earned-laurel callback. Weekly-goal claiming must remain gated by `mounted`; the service must not claim it unconditionally merely to make its API one-shot.

A standalone public `XpCalculator` is not required in 209. The exact formula can temporarily be a small pure helper within the completion-service implementation and be tested directly through the new service result.

## Expected files for later phases

### Expected core files

- `lib/services/learning_completion_service.dart` (new)
- `lib/screens/round_screen.dart`
- `test/learning_completion_service_test.dart` (new)
- `test/round_xp_completion_regression_test.dart`
- `test/topic_completion_regression_test.dart` (new)
- optionally `test/review_screen_completion_regression_test.dart` (new)

### Only if LearningActivityService is included in build 209

- `lib/services/learning_activity_service.dart` (new)
- `lib/services/progress_service.dart`
- `test/progress_time_test.dart`
- possibly `test/progress_service_test.dart`

### Release-hygiene files after implementation validates

- `pubspec.yaml`
- `lib/services/alpha_lifecycle_service.dart`
- `test/alpha_lifecycle_test.dart`
- `CHANGELOG.md`
- `README.md`
- current roadmap and validation documentation

Under the recommended smallest scope, `TopicScreen`, `ReviewScreen`, `DuelScreen`, course/import code, startup diagnostics, platform code, and packaging scripts should not require production changes.

## Identified implementation risks

1. Misclassifying first completion as a repeat by reading completion state after persistence.
2. Recalculating from nominal exercise count instead of the final mutable queue.
3. Losing dynamic TTS-skip or flashcard queue semantics.
4. Counting review corrections as first-pass XP or excluding review errors from latest-result errors.
5. Collapsing the current two activity registrations without an explicit behavior decision.
6. Reordering clock-dependent operations across midnight or Sunday rollover.
7. Skipping zero-XP accounting and changing stored Weekly XP breakdown shape.
8. Parallelizing currently sequential, non-transactional writes.
9. Moving laurel sound after XP and changing partial-failure ordering.
10. Marking weekly celebration after widget disposal when current code would not.
11. Folding Topic completion into Round completion and changing normal-path versus Review behavior.
12. Making Topic completion idempotent and thereby changing current XP amounts.
13. Including Topic bonus in Round weekly-goal crossing when current behavior excludes it.
14. Accidentally fixing or changing existing Finish re-entrancy behavior.
15. Introducing legacy migrations or fallback keys that the current QuisquisLingo code does not use.

## Recommended 209B test plan

209B should change tests only and should not bump the app version.

1. Extend `test/round_xp_completion_regression_test.dart` with:
   - activity assertions for normal completion and preview;
   - dynamic TTS-disabled zero-XP completion;
   - weekly-goal crossing, persistence-before-dialog, and once-per-week behavior;
   - imperfect repeat;
   - reset-then-perfect eligibility.
2. Add `test/topic_completion_regression_test.dart` through the public `TopicScreen` seam:
   - partial versus final Topic completion;
   - filtering to current Topic Round IDs;
   - exact 25 XP and SnackBar behavior;
   - current post-Round weekly-goal ordering;
   - explicit handling of the current repeated/cancelled-return Topic award behavior.
3. Add the Review caller-context regression if it can remain small and deterministic.
4. Run focused tests after each addition, then the existing Progress/XP/time suites.
5. Do not add source-text assertions for the future service or call ordering.

Suggested 209B validation:

```powershell
dart format <touched test Dart files>
flutter test test/round_xp_completion_regression_test.dart
flutter test test/topic_completion_regression_test.dart
flutter test test/progress_service_test.dart test/progress_time_test.dart test/xp_service_test.dart
git diff --check
```

Stop after 209B tests and their validation before beginning production extraction.

## Later implementation sequence

### 209C - introduce LearningCompletionService

- Add the service and its direct tests with injectable collaborators.
- Assert exact collaborator order and result values before caller migration.
- Move the smallest coherent Round completion path.
- Keep TopicScreen and all presentation behavior unchanged.

### 209D - complete extraction only if required

- Move the remaining XP/activity/weekly-goal orchestration out of `RoundScreen` while preserving ordering.
- If required for the delivered architecture, extract the real current `LearningActivityService` behavior and retain `ProgressService` delegations.
- Do not fold Topic completion into the same Round method.

### 209E - final validation and release hygiene

- Format touched Dart files.
- Run focused tests, `flutter analyze`, and full `flutter test`.
- Run bundled course and Image Bank validators.
- Run `git diff --check`, inspect final status, and review every changed line.
- Only after implementation is green, bump to `2.0.9+209` and refresh Alpha expiry from the actual release date.
- Update changelog and current release/validation documentation.
- Do not package, commit, or push without the applicable explicit instruction.

## 209A conclusion

The safest next action is 209B characterization tests only. The current repeated Topic 25 XP behavior is the one policy point that should be deliberately frozen or separately authorized for change before production extraction. No 209B work is included in this audit checkpoint.
