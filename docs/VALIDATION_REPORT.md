# QuisquisLingo 2.0.15+215 release validation report

Date: 28 August 2026

## Baseline and scope

- Work began on `main` at commit `c796dbd12d1efb3308c38ed38b5fdd519d3cb8a6` with a clean working tree and package version `2.0.14+214`.
- The target package version is `2.0.15+215`.
- The established 30-day Alpha lifetime expires at the end of 27 September 2026; the date is unchanged because builds 214 and 215 were prepared on the same day.
- Course Model v4 is a clean cut: Course owns ordered Topics directly, Chapter-based structures are rejected, and no legacy course or progress migration is present.
- A newly created custom Course starts with three placeholder Topics and no automatically created Rounds.
- Learner navigation is unified around Course → Lesson → Round while retaining the existing learner status bar, Leaderboard/Gamification route, Review, Course Info and Settings behavior.
- The unified learner page uses the supplied QuisquisLingo logo and follows the operating-system light/dark appearance without adding an application switch or changing unrelated screens.
- Topic Duel availability is derived at runtime from the actual Topic-local eligible pool. Fewer than 25 eligible exercises is a normal unavailable state, independent of the six-Round author recommendation.

## Preserved scoring and progress behavior

- First Round completion remains 5 XP per first-attempt-correct evaluable exercise; repeats and Review remain 2 XP.
- Every zero-error completed Round retains the repeatable 5 XP perfect bonus, and the first Laurel retains its one-time 25 XP bonus.
- The final required Round and first Topic completion still share one completion result and popup, with the one-time 25 XP Topic award persisted exactly once.
- Duel remains 25 unique questions, 4 lives, no score or separate pass threshold, with 50 XP for the first victory and 10 XP for later victories.
- Round, Topic, Duel, Laurel and Review state is learner- and course-scoped. Language XP, streak and study days remain language-scoped; Weekly XP remains learner-global.

## Course and schema validation

- `python tools\validate_courses.py` passed all eight bundled Course Model v4 JSON files.
- Each bundled course contains nine deterministically ordered Topics and two Rounds per Topic, with stable Topic/Round/content identity preserved.
- Current bundled Topics contain 10 or 11 Duel-eligible exercises, so their 25-question Duels are normally unavailable by design.
- Focused parser tests cover v4-only input, rejection of `chapters`, obsolete Topic assessment fields, unsupported Duel fields, missing/invalid Round `visualType`, ordering and text-match compatibility.

## Automated validation

- `flutter test --no-pub --reporter compact`: **260 tests passed, 0 failed** in approximately **2m01s**.
- Focused widget coverage includes the three-Topic custom-Course default, final-Lesson `Duel Won!` wording, the supplied header logo, operating-system light/dark rendering for the learner page, loading state and Lesson picker, direct Course → Lesson → Round navigation, Back behavior, Lesson switching, normal unavailable-Duel messaging, Home Leaderboard routing, Gamification absence from Settings, course refresh after returning from Settings, four-life Duel loss and a 320 px Home with 1.5× text scaling.
- `flutter analyze --no-pub`: no errors or warnings; the same **7 pre-existing info-only** `curly_braces_in_flow_control_structures` findings remain in `course_editor_service.dart`, `profile_service.dart` and `settings_service.dart`.
- `git diff --check`: passed with no whitespace errors.

## Manual release checks still required

- Visually compare the unified learner page in both operating-system appearances at phone, tablet and desktop sizes, including high system text scaling, odd Round counts, Perfect laurels and Topic images.
- Exercise a real custom-course create/import/edit/export/delete cycle and confirm Home refresh and double-confirmation deletion on each supported desktop platform.
- Manually open a content-rich custom Topic with at least 25 eligible exercises and complete both a winning and losing Duel path with audio enabled.
- Smoke-test platform TTS, external support links, file-system export/import paths and desktop window resizing on release targets.
- Produce and inspect release packages separately; no package, commit or push is part of this implementation task.
