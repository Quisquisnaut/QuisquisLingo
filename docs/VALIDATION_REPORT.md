# QuisquisLingo 2.0.17+217 release validation report

Date: 30 August 2026

## Baseline and scope

- Build 217 work began from clean commit `d7fae5b` (`2.0.16+216`).
- The target package version is `2.0.17+217`.
- The established 30-day Alpha lifetime expires at the end of 29 September 2026.
- Course Model v4 is a clean cut: Course owns ordered Topics directly, Chapter-based structures are rejected, and no legacy course or progress migration is present.
- A newly created custom Course starts with three placeholder Topics and no automatically created Rounds.
- Learner navigation remains unified around Course → Lesson → Round; the central learner area now flows continuously from the selected Lesson through every subsequent Lesson in course order while retaining the existing learner status bar, Leaderboard/Gamification route, Review, Course Info and Settings behavior.
- The unified learner page retains the supplied QuisquisLingo logo, uses the selected-course flag as its background, places the protected user/logo/Settings strip above the unchanged status bar, and follows the operating-system light/dark appearance.
- The existing Lesson selector continues to open the complete Lesson picker and retain its established persistence behavior. Direct selection restarts the continuous flow at that Lesson; after natural scrolling ends, the selector follows the Lesson with the greatest visible section area using viewport-relative hysteresis.
- Lessons are built lazily at the outer list level. Locked Lessons remain present in course order but their GuideBook, Rounds and Duel stay inaccessible unless genuine progress or existing IDDQD access permits them.
- The existing course picker continues to place up to three newest other recent courses between the current course and complete course list without changing recent-course persistence.
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

- `flutter test --no-pub`: **268 tests passed, 0 failed** in approximately **1m35s**.
- Focused learner/version coverage passed **20 tests** and includes lazy ordered flow through multiple subsequent Lessons, one section per Lesson, direct selector restart/persistence, scroll-driven selector synchronization without boundary oscillation, inaccessible locked content, fixed User Bar/Status Bar/course selector/Lesson selector, fixed icon-only bottom controls, final-Lesson reachability, direct Course → Lesson → Round navigation, normal unavailable-Duel messaging and the refreshed Alpha lifecycle.
- `flutter analyze`: no errors or warnings; the same **7 pre-existing info-only** `curly_braces_in_flow_control_structures` findings remain in `course_editor_service.dart`, `profile_service.dart` and `settings_service.dart`.
- `git diff --check`: passed with no whitespace errors.

## Manual release checks still required

- Visually compare the continuous Lesson flow in both operating-system appearances at phone, tablet and desktop sizes, including selector synchronization across boundaries, locked/IDDQD sections, high system text scaling, odd Round counts, Perfect laurels and Topic images.
- Exercise a real custom-course create/import/edit/export/delete cycle and confirm Home refresh and double-confirmation deletion on each supported desktop platform.
- Manually open a content-rich custom Topic with at least 25 eligible exercises and complete both a winning and losing Duel path with audio enabled.
- Smoke-test platform TTS, external support links, file-system export/import paths and desktop window resizing on release targets.
- Produce and inspect release packages separately; no package, commit or push is part of this implementation task.
