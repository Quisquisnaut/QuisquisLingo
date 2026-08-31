# QuisquisLingo 2.0.18+218 release validation report

Date: 31 August 2026

## Baseline and scope

- Build 218 work began from clean commit `34fc60e` (`2.0.17+217`).
- The target package version is `2.0.18+218`.
- The established 30-day Alpha lifetime expires at the end of 29 September 2026.
- Course Model v4 is a clean cut: Course owns ordered Topics directly, Chapter-based structures are rejected, and no legacy course or progress migration is present.
- A newly created custom Course starts with three placeholder Topics and no automatically created Rounds.
- Learner navigation remains unified around Course → Lesson → Round, and the central learner area retains its continuous lazy flow from the selected Lesson through every subsequent Lesson in course order.
- The fixed Learner Header now contains one theme-aware Top Bar followed by the separate Lesson selector. The Top Bar is ordered as compact Language/Course flag selector, one-line language Streak, vertical current/max course Laurel progress, vertical current/max learner-global Weekly XP, QuisquisLingo cat mark and Settings.
- The compact flag-only control opens the unchanged full-size Language/Course picker, while learner-profile management is available through Settings. The User group and redundant full-width course control are absent from the Top Bar and header.
- The Top Bar uses only the cat portion of the supplied logo through a non-destructive clipped presentation. The cat opens the existing App Info screen, where the unchanged complete logo appears above the existing content.
- Streak and Laurel dialogs state their language and course scopes explicitly. Standard informational tooltips identify the course flag dynamically, language Streak, course Laurels, learner-global Weekly XP and App Info without adding permanent labels or changing the existing actions.
- The Streak, Laurel and Weekly XP icons are subtly enlarged while the fixed 64 px Top Bar height, artwork, metric spacing and numeric presentation remain preserved.
- The selected-course flag remains behind the approximately 50%-opacity Lesson selector and the central learner content, but not behind the solid white or near-black Top Bar. No separate Course Progress Bar is present.
- The existing Lesson selector continues to open the complete Lesson picker and retain its established persistence behavior. Direct selection restarts the continuous flow at that Lesson; after natural scrolling ends, the selector follows the Lesson with the greatest visible section area using viewport-relative hysteresis.
- Lessons are built lazily at the outer list level. Locked Lessons remain present in course order but their GuideBook, Rounds and Duel stay inaccessible unless genuine progress or existing IDDQD access permits them.
- The existing full-size course picker continues to place up to three newest other recent courses between the current course and complete course list without changing recent-course persistence.
- Topic Duel availability is derived at runtime from the actual Topic-local eligible pool. Fewer than 25 eligible exercises is a normal unavailable state, independent of the six-Round author recommendation.

## Preserved scoring and progress behavior

- First Round completion remains 5 XP per first-attempt-correct evaluable exercise; repeats and Review remain 2 XP.
- Every zero-error completed Round retains the repeatable 5 XP perfect bonus, and the first Laurel retains its one-time 25 XP bonus.
- The Top Bar Laurel maximum counts distinct Rounds with at least one exercise accepted by the existing learner-facing Course Audit predicate (no `error` issue). Valid evaluated, flashcard and Round-note textual content remain eligible; Topic-intro-only, empty and all-invalid Rounds are excluded.
- The displayed current Laurel count is the intersection of the current course's distinct persisted perfect-Round IDs and those eligible Round IDs, so stale, foreign and ineligible IDs do not contribute and one Round contributes at most once.
- The final required Round and first Topic completion still share one completion result and popup, with the one-time 25 XP Topic award persisted exactly once.
- Duel remains 25 unique questions, 4 lives, no score or separate pass threshold, with 50 XP for the first victory and 10 XP for later victories.
- Round, Topic, Duel, Laurel and Review state is learner- and course-scoped. Language XP, streak and study days remain language-scoped; Weekly XP remains learner-global.

## Course and schema validation

- `python tools\validate_courses.py` passed all eight bundled Course Model v4 JSON files.
- Each bundled course contains nine deterministically ordered Topics and two Rounds per Topic, with stable Topic/Round/content identity preserved.
- Current bundled Topics contain 10 or 11 Duel-eligible exercises, so their 25-question Duels are normally unavailable by design.
- Focused parser tests cover v4-only input, rejection of `chapters`, obsolete Topic assessment fields, unsupported Duel fields, missing/invalid Round `visualType`, ordering and text-match compatibility.

## Automated validation

- Focused unified Top Bar coverage passed **11 tests** for exact order/actions, compact flag-only selection, semantics, standard tooltips, non-destructive cat cropping, subtly enlarged metric icons, preserved height, vertical metrics, exact explanatory-dialog wording, all required numeric ranges, stable single-row layout, group spacing and light/dark contrast.
- Focused streak and study-day clock coverage passed **21 tests**, including language-scoped counters and automatic cross-language freezing.
- Focused learner-status, shared Round playability, Round-XP regression, App Info and Alpha-lifecycle coverage passed **31 tests**.
- Focused final learner-navigation integration coverage passed **22 tests**, including the full course picker, Settings profile management, App Info navigation, Lesson selector separation and narrow layout.
- Full `flutter test --no-pub` passed **290 tests** in **1 minute 13 seconds**.
- Full `flutter analyze --no-pub` reported **no errors or warnings** and the same **7 pre-existing info-only** `curly_braces_in_flow_control_structures` diagnostics in untouched service files.
- `python tools\validate_courses.py` passed all eight bundled courses, and final `git diff --check` passed.
- At the documented 320 px narrow test width with 1.5× text, all six required groups, the clearly visible flag and maximum numeric values remain in one row without overflow, with the required interactive controls retaining at least 48 px height.

## Manual release checks still required

- Visually compare the unified Top Bar in both operating-system appearances at phone, tablet and desktop sizes, including maximum Streak, Laurel and Weekly XP values, enlarged system text and distinct group spacing.
- Confirm that the compact Top Bar cat excludes the wordmark without changing the source asset, opens App Info, and that App Info shows the complete logo and wordmark.
- Recheck the continuous Lesson flow, selector synchronization, locked/IDDQD sections and fixed bottom controls to confirm that the header-only change did not affect central learner behavior.
- Exercise a real custom-course create/import/edit/export/delete cycle and confirm Home refresh and double-confirmation deletion on each supported desktop platform.
- Manually open a content-rich custom Topic with at least 25 eligible exercises and complete both a winning and losing Duel path with audio enabled.
- Smoke-test platform TTS, external support links, file-system export/import paths and desktop window resizing on release targets.
- Produce and inspect release packages separately; packaging is outside this completion task.
