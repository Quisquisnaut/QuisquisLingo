# QQL 232 Integrated Vocabulary Reinforcement in Review Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Deliver QQL `2.0.32+232` as an automatic, Course-scoped Round Review page with GuideBook vocabulary preparation, one-time post-Round reinforcement, persistent difficult-word memory, session-local Next Review exclusion, and an isolated Word List reset.

**Architecture:** `ProgressService` retains the authoritative candidate data and receives only the requested oldest-first tie-break correction. A focused `ReviewRoundResolver` resolves ordered records into Course locations, while `VocabularyReviewService` owns learner-local parsing, identity, fingerprinting, state, and reset. `ReviewScreen` coordinates the page state machine and delegates the unchanged exercise attempt to `RoundScreen`; `HomeScreen` exposes Review only from the bottom action and Current course menu.

**Tech Stack:** Flutter/Dart, `shared_preferences`, `crypto` SHA-256, Flutter widget tests, existing QQL Course Model v7 and learner services.

**Spec:** `docs/superpowers/specs/2026-09-11-qql-232-integrated-vocabulary-review-design.md`

## Global Constraints

- Work only in `C:\Users\ansa\Downloads\QQL\QuisquisLingo_source`; do not create or switch worktrees.
- Preserve all user work and all behavior outside QQL 232.
- Do not stage, commit, push, package, tag, publish, reset, revert, clean, or discard without the user's later confirmation.
- Use Version `2.0.32+232`, display Build `232`, Revision `0`, and Course Model v7.
- Preserve Alpha expiry exactly at `2026-10-13 23:59:59` local time.
- Preserve the existing 50-Round cap, Round mechanics, XP rules, course JSON, bundled assets, and checksums.
- Vocabulary state is learner × Course × Lesson × entry and contains no SRS, due dates, mastery, confidence, word XP, word streak, or separate progression.
- Review ignores IDDQD Off/On/View Only and operates only on genuinely completed Review records.
- Run focused tests while implementing; run the analyzer and complete Flutter suite exactly once on the final source/test tree.
- Because the user has withheld commit authority, every task ends with status/diff inspection instead of a commit.

---

### Task 1: Authoritative Review Ordering and Round Resolution

**Files:**
- Create: `lib/services/review_round_resolver.dart`
- Create: `test/qql_232_review_round_resolver_test.dart`
- Modify: `lib/services/progress_service.dart:226-247`
- Modify: `test/progress_service_test.dart`

**Interfaces:**
- Consumes: `ProgressService.getRecentRounds({String? courseId, int limit = 50})`, `Course.lessons`, `Lesson.rounds`.
- Produces: `ReviewRoundLocation` and `ReviewRoundResolver.firstPending(Course course, {Set<String> excludedRoundIds = const {}})`.

- [ ] **Step 1: Write failing ordering and timestamp-refresh tests**

Add deterministic clock-driven tests that use literal expected Round IDs:

```dart
test('Review orders more errors first and oldest timestamp first on ties', () async {
  var now = DateTime.utc(2026, 9, 1, 10);
  final progress = ProgressService(now: () => now);
  await progress.recordRecentRound('course', 'lesson', 'older-two', errors: 2);
  now = DateTime.utc(2026, 9, 1, 11);
  await progress.recordRecentRound('course', 'lesson', 'newer-two', errors: 2);
  now = DateTime.utc(2026, 9, 1, 12);
  await progress.recordRecentRound('course', 'lesson', 'three', errors: 3);

  expect(
    (await progress.getRecentRounds(courseId: 'course')).map((e) => e.roundId),
    ['three', 'older-two', 'newer-two'],
  );
});

test('recording a reviewed Round makes it newest for the next tie', () async {
  var now = DateTime.utc(2026, 9, 1, 10);
  final progress = ProgressService(now: () => now);
  await progress.recordRecentRound('course', 'lesson', 'first', errors: 2);
  now = DateTime.utc(2026, 9, 1, 11);
  await progress.recordRecentRound('course', 'lesson', 'second', errors: 2);
  now = DateTime.utc(2026, 9, 1, 12);
  await progress.recordRecentRound('course', 'lesson', 'first', errors: 2);

  expect(
    (await progress.getRecentRounds(courseId: 'course')).map((e) => e.roundId),
    ['second', 'first'],
  );
});
```

Create resolver tests proving the first valid ordered record is returned, stale records are skipped, and exclusions are session-local inputs:

```dart
final location = await ReviewRoundResolver(progress: progress).firstPending(
  course,
  excludedRoundIds: {'highest-errors'},
);
expect(location!.round.id, 'oldest-equal-errors');
expect(location.lesson.lessonId, 'lesson-b');
expect(location.lessonIndex, 1);
expect(location.roundIndex, 0);
```

- [ ] **Step 2: Run the focused tests and verify RED**

Run:

```powershell
flutter test --no-pub --reporter expanded --timeout 60s test\progress_service_test.dart test\qql_232_review_round_resolver_test.dart
```

Expected failures: equal-error entries are newest-first and `ReviewRoundResolver` does not exist.

- [ ] **Step 3: Apply the minimal ordering correction**

Change only the tie-break branch:

```dart
entries.sort((a, b) {
  final byErrors = b.errors.compareTo(a.errors);
  if (byErrors != 0) return byErrors;
  return a.completedAt.compareTo(b.completedAt);
});
```

- [ ] **Step 4: Add the resolver without copying sort logic**

Implement these exact public shapes:

```dart
class ReviewRoundLocation {
  const ReviewRoundLocation({
    required this.entry,
    required this.lessonIndex,
    required this.lesson,
    required this.roundIndex,
    required this.round,
  });

  final RecentRoundEntry entry;
  final int lessonIndex;
  final Lesson lesson;
  final int roundIndex;
  final LearningRound round;
}

class ReviewRoundResolver {
  ReviewRoundResolver({ProgressService? progress})
    : _progress = progress ?? ProgressService();

  final ProgressService _progress;

  Future<ReviewRoundLocation?> firstPending(
    Course course, {
    Set<String> excludedRoundIds = const {},
  }) async {
    final entries = await _progress.getRecentRounds(
      courseId: course.courseId,
      limit: 50,
    );
    for (final entry in entries) {
      if (excludedRoundIds.contains(entry.roundId)) continue;
      final lessonIndex = course.lessons.indexWhere(
        (lesson) => lesson.lessonId == entry.lessonId,
      );
      if (lessonIndex < 0) continue;
      final lesson = course.lessons[lessonIndex];
      final roundIndex = lesson.rounds.indexWhere(
        (round) => round.id == entry.roundId,
      );
      if (roundIndex < 0) continue;
      return ReviewRoundLocation(
        entry: entry,
        lessonIndex: lessonIndex,
        lesson: lesson,
        roundIndex: roundIndex,
        round: lesson.rounds[roundIndex],
      );
    }
    return null;
  }
}
```

The method requests `limit: 50`, skips excluded IDs and unresolved Lesson/Round records, and returns the first valid location.

- [ ] **Step 5: Verify GREEN and inspect the slice**

Rerun the focused command, then inspect:

```powershell
git diff -- lib/services/progress_service.dart lib/services/review_round_resolver.dart test/progress_service_test.dart test/qql_232_review_round_resolver_test.dart
git status --short
```

Confirm there is one sort implementation and no unrelated ProgressService change.

---

### Task 2: Vocabulary Domain, Identity, Persistence, and Reset

**Files:**
- Create: `lib/services/vocabulary_review_service.dart`
- Create: `test/qql_232_vocabulary_review_service_test.dart`

**Interfaces:**
- Consumes: Course Model v7 `Course`, `Lesson`, `Guidebook`, `LearningContent`; `PublicationService.learnerGuidebook`; `ProfileService`; `SharedPreferences`; SHA-256 from `crypto`.
- Produces: `VocabularyReviewEntry`, `VocabularyReviewState`, and `VocabularyReviewService` resolve/read/update/reset methods.

- [ ] **Step 1: Write failing parsing, identity, and eligibility tests**

Cover all four supported separators with literal prompt/answer values; published-only delivery; disabled/Draft GuideBooks; authored order; malformed lines; identical terms with different translations; identical entries with distinct IDs; and no supplementary fabrication.

Use an explicit fixture such as:

```dart
const vocabulary = <LearningContent>[
  LearningContent(
    id: 'casa-home',
    kind: 'vocabulary',
    role: 'vocabulary',
    text: 'casa = house',
  ),
  LearningContent(
    id: 'casa-family',
    kind: 'vocabulary',
    role: 'vocabulary',
    text: 'casa = household',
  ),
  LearningContent(
    id: 'malformed',
    kind: 'vocabulary',
    role: 'vocabulary',
    text: 'no answer here',
  ),
];
```

Assert:

```dart
final entries = service.resolveEntries(course, lesson);
expect(entries.map((entry) => entry.prompt), ['casa', 'casa']);
expect(entries.map((entry) => entry.answer), ['house', 'household']);
expect(entries.map((entry) => entry.supplementary), [isEmpty, isEmpty]);
```

- [ ] **Step 2: Write failing state-transition and persistence tests**

Create real profiles and mock preferences. Exercise new service instances to prove reopening persistence:

```dart
await service.markKnown(course.courseId, lesson.lessonId, entry);
expect(await service.stateFor(course.courseId, lesson.lessonId, entry),
    const VocabularyReviewState(encountered: true, needsReinforcement: false));

await VocabularyReviewService().requestReinforcement(
  course.courseId,
  lesson.lessonId,
  entry,
);
expect((await VocabularyReviewService().eligibleEntries(course, lesson)),
    [entry]);
```

Add independent tests for:

- missing state makes every usable entry eligible;
- known entries disappear;
- reinforcement entries remain eligible until cleared;
- prompt or answer change under the same content ID is new;
- Course/Lesson title-only changes preserve state;
- newly added vocabulary is new and deleted vocabulary cannot crash;
- distinct duplicate occurrences do not share state;
- learner A/B, Course A/B, and same Lesson ID in two Courses do not collide;
- malformed stored JSON is ignored and replaced safely on the next valid write;
- reset clears only the active learner/current Course vocabulary value.

- [ ] **Step 3: Write the no-side-effect/reset isolation test before production code**

Seed real `ProgressService` and `XpService`-backed state, snapshot it, execute all vocabulary actions plus reset, and assert literal equality afterward for completed Rounds/Lessons, recent ordering, XP, Weekly XP, streak, laurels, and Duels. Also assert another learner and Course vocabulary state remains unchanged.

- [ ] **Step 4: Run the service test and verify RED**

Run:

```powershell
flutter test --no-pub --reporter expanded --timeout 60s test\qql_232_vocabulary_review_service_test.dart
```

Expected failure: the vocabulary domain/service API is absent.

- [ ] **Step 5: Implement the minimal immutable domain types**

Use these shapes:

```dart
class VocabularyReviewEntry {
  const VocabularyReviewEntry({
    required this.identity,
    required this.contentId,
    required this.fingerprint,
    required this.prompt,
    required this.answer,
    this.supplementary = const [],
  });

  final String identity;
  final String contentId;
  final String fingerprint;
  final String prompt;
  final String answer;
  final List<String> supplementary;
}

class VocabularyReviewState {
  const VocabularyReviewState({
    this.encountered = false,
    this.needsReinforcement = false,
  });

  final bool encountered;
  final bool needsReinforcement;
}
```

- [ ] **Step 6: Implement the service boundary and versioned storage**

Expose:

```dart
class VocabularyReviewService {
  List<VocabularyReviewEntry> resolveEntries(Course course, Lesson lesson);
  Future<List<VocabularyReviewEntry>> eligibleEntries(
    Course course,
    Lesson lesson,
  );
  Future<VocabularyReviewState> stateFor(
    String courseId,
    String lessonId,
    VocabularyReviewEntry entry,
  );
  Future<void> markKnown(
    String courseId,
    String lessonId,
    VocabularyReviewEntry entry,
  );
  Future<void> requestReinforcement(
    String courseId,
    String lessonId,
    VocabularyReviewEntry entry,
  );
  Future<void> keepReinforcement(
    String courseId,
    String lessonId,
    VocabularyReviewEntry entry,
  );
  Future<void> resetCourse(String courseId);
}
```

Implementation rules:

- filter through `PublicationService.learnerGuidebook` and iterate its `content`, not `Guidebook.vocabulary`, so stable Content IDs survive;
- accept only published `kind == 'vocabulary'` records that parse to two non-empty sides;
- preserve every valid authored occurrence and its order;
- use stable Content ID plus deterministic same-ID occurrence suffix, with fingerprint/occurrence fallback only for empty in-memory IDs;
- fingerprint `jsonEncode(['qql232-v1', prompt, answer, supplementary])` with SHA-256;
- store one versioned JSON document below `ProfileService.key('v1_vocabulary_review_course_$courseDigest')`, where `courseDigest` is lowercase SHA-256 of the trimmed immutable Course ID;
- store only fingerprint, `encountered`, and `needsReinforcement` below Lesson/entry identity;
- write `true/false` transitions immediately and remove only the active Course key on reset.

- [ ] **Step 7: Verify GREEN, format, and inspect the slice**

Run:

```powershell
dart format lib\services\vocabulary_review_service.dart test\qql_232_vocabulary_review_service_test.dart
flutter test --no-pub --reporter expanded --timeout 60s test\qql_232_vocabulary_review_service_test.dart
git diff -- lib/services/vocabulary_review_service.dart test/qql_232_vocabulary_review_service_test.dart
git status --short
```

---

### Task 3: Continuous Review Page and Vocabulary Card Flow

**Files:**
- Modify: `lib/screens/review_screen.dart`
- Modify: `lib/screens/round_screen.dart`
- Create: `test/qql_232_review_flow_test.dart`
- Modify: `test/lesson_completion_regression_test.dart`
- Modify: `test/learner_status_bar_test.dart`

**Interfaces:**
- Consumes: `ReviewRoundResolver`, `VocabularyReviewService`, existing `RoundScreen`, `CourseLanguageResolver`.
- Produces: automatic Review page state machine with pre-Round, Round, post-Round, congratulations, Next Review, reset, Help, context, and progress; optional `RoundScreen.reviewMode` presentation that leaves ordinary Round entry unchanged.

- [ ] **Step 1: Write failing direct-entry and page-shell tests**

Create Review records where the expected first Round is not first in Course order. Pump `ReviewScreen`, wait for `RoundScreen`, and assert its Course/Lesson/Round IDs. Add no-candidate coverage and assert:

```dart
expect(find.byType(LearnerStatusBar), findsNothing);
expect(find.byKey(const Key('review-reset-word-list')), findsOneWidget);
expect(find.byKey(const Key('review-help')), findsOneWidget);
expect(find.text('There are no Rounds available for Review in this course.'),
    findsOneWidget);
```

- [ ] **Step 2: Write failing pre-Round vocabulary tests**

Use a two-word published GuideBook and assert:

```dart
expect(find.text('Before the Round'), findsOneWidget);
expect(find.text(course.title), findsOneWidget);
expect(find.textContaining('Lesson 1'), findsOneWidget);
expect(find.textContaining('Round 1'), findsOneWidget);
expect(find.text('casa'), findsOneWidget);
expect(find.text('house'), findsNothing);
expect(find.text('I know it'), findsNothing);
expect(find.text('Show it to me again'), findsNothing);
await tester.tap(find.text('Show answer'));
await tester.pumpAndSettle();
expect(find.text('house'), findsOneWidget);
expect(find.text('I know it'), findsOneWidget);
expect(find.text('Show it to me again'), findsOneWidget);
```

Add separate tests proving disabled, Draft, empty, and malformed vocabulary routes directly to the Round, and that long Course/Lesson titles wrap without ellipsis.

- [ ] **Step 3: Write failing post-Round and interruption tests**

Drive A known, B reinforcement, C known, D reinforcement; complete the real Round; assert only B and D appear once after the Round. Verify post buttons are hidden until reveal. Mark B known and D still unknown, then assert persisted states.

In another test, request reinforcement and pop the Round before completion. Reopen Review and assert that word remains eligible before the Round while completed known decisions remain omitted and the existing Review record remains valid.

- [ ] **Step 4: Write failing Next Review tests**

Seed three candidates, finish the first, tap `Next Review`, and prove the first Round ID is excluded even if its refreshed error count would still rank highest. Finish a second Round from the same Lesson and assert only the difficult/new words appear; known entries stay skipped.

After exhausting every valid candidate, tap `Next Review` and assert the congratulations page remains with:

```dart
expect(find.text('No more Rounds are available in this Review session.'),
    findsOneWidget);
expect(find.byKey(const Key('review-back-to-course')), findsOneWidget);
```

Pop and reopen Review to prove the session-local exclusion set was discarded while vocabulary memory remained.

- [ ] **Step 5: Write failing reset, Help, progress, and congratulations tests**

Assert reset opens the exact confirmation, Cancel is inert, and confirmation resets the active Course. If reset occurs during pre-Round vocabulary, restart preparation from all usable entries; if it occurs after the Round, discard the pending post list so later actions cannot silently recreate pre-reset state.

Assert Help contains each learner-facing rule from the specification, the vocabulary phase has a `LinearProgressIndicator`, and congratulations offers `Next Review` plus `Back to course` without replay/Word Review actions.

- [ ] **Step 6: Run widget tests and verify RED**

Run:

```powershell
flutter test --no-pub --reporter expanded --timeout 60s test\qql_232_review_flow_test.dart test\lesson_completion_regression_test.dart test\learner_status_bar_test.dart
```

Expected failures: Review still shows the 50-card list/status wrapper and the integrated controls/states are absent.

- [ ] **Step 7: Implement the Review page state machine**

Replace the selectable-list state with explicit private stages:

```dart
enum _ReviewStage {
  loading,
  preVocabulary,
  openingRound,
  postVocabulary,
  congratulations,
  empty,
}
```

Maintain:

```dart
final Set<String> _reviewedRoundIds = {};
ReviewRoundLocation? _location;
List<VocabularyReviewEntry> _preEntries = const [];
List<VocabularyReviewEntry> _postEntries = const [];
int _entryIndex = 0;
bool _answerRevealed = false;
bool _noMoreRounds = false;
```

Do not wrap the page in `LearnerStatusPage`. Build a plain `Scaffold` with Review app-bar reset/help icons. Use a shared card builder for the exact pre/post labels and buttons. Persist each decision before advancing.

- [ ] **Step 8: Delegate only the central attempt to existing RoundScreen**

Add `final bool reviewMode` to `RoundScreen`, defaulting false. When true, label the screen as Review and render this complete, wrapping subtitle from existing model/index data:

```dart
'${widget.course.title} · ${widget.course.targetLanguage} · '
'Lesson ${lessonIndex + 1}: ${widget.lesson.title} · '
'Round ${widget.roundIndex + 1}'
'${widget.round.title.trim().isEmpty ? '' : ': ${widget.round.title.trim()}'}'
```

Do not alter queue construction, progress calculation, audio/report actions, correctness, completion, or ordinary `reviewMode == false` presentation.

Keep the existing optional `ReviewScreen.viewOnlyMode` constructor argument for source compatibility, but do not read it when building the Review flow and do not forward it to `RoundScreen`. Push the selected `RoundScreen` with `reviewMode: true`. Treat route result `true` as normal completion, add the Round ID to `_reviewedRoundIds`, then show the post list or congratulations. On a null result, pop Review back to the preserved Learner Panel.

`Next Review` calls the resolver with `_reviewedRoundIds`; no candidate sets `_noMoreRounds = true` and remains on congratulations.

- [ ] **Step 9: Verify GREEN, format, and inspect the slice**

Run:

```powershell
dart format lib\screens\review_screen.dart lib\screens\round_screen.dart test\qql_232_review_flow_test.dart test\lesson_completion_regression_test.dart test\learner_status_bar_test.dart
flutter test --no-pub --reporter expanded --timeout 60s test\qql_232_review_flow_test.dart test\lesson_completion_regression_test.dart test\learner_status_bar_test.dart
git diff -- lib/screens/review_screen.dart lib/screens/round_screen.dart test/qql_232_review_flow_test.dart test/lesson_completion_regression_test.dart test/learner_status_bar_test.dart
git status --short
```

---

### Task 4: Current-Course-Only Course Selector Navigation

**Files:**
- Modify: `lib/screens/home_screen.dart:937-1390,1818-1837,2157`
- Modify: `test/leaderboard_navigation_test.dart`

**Interfaces:**
- Consumes: existing `_openReview`, Course Selector `courseTile`, active `_course`, existing bottom Review action.
- Produces: Review item only on Current course menu; both entry paths preserve the active Home route/scroll and ignore IDDQD.

- [ ] **Step 1: Write the failing Course Selector navigation test**

Open Course Selector and assert Review appears once only after opening the Current course menu. Close it and inspect representative recent, included, local, and hidden Course menus to prove no Review item exists.

Select Current course > Review and assert the routed `ReviewScreen.course.courseId` equals the active Course ID. Seed another Course with a higher-error record and prove it cannot leak into the active Course Review.

Set active-Course IDDQD to View Only, complete Review, and assert the ordinary Review record/XP effects occur exactly as existing Review rules require.

- [ ] **Step 2: Write the failing route-return scroll test**

Scroll the Learner Panel to a stable offset, record the controller position through the visible list, open Review, return using Back, and assert the same Home state and approximately equal scroll offset without a Course switch or reload-induced jump.

- [ ] **Step 3: Run the navigation tests and verify RED**

Run:

```powershell
flutter test --no-pub --reporter expanded --timeout 60s test\leaderboard_navigation_test.dart
```

Expected failure: Current course menu has no Review item and Home passes View Only into Review.

- [ ] **Step 4: Add the single permitted menu action**

Add a `showReview` argument to the local `courseTile` builder, default false. Pass true only for the `_course` Current course row. Add this menu item before Course Info:

```dart
if (showReview)
  const PopupMenuItem(
    value: 'review',
    child: ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(Icons.history_edu_outlined),
      title: Text('Review'),
    ),
  ),
```

On selection, close the Course Selector, wait through its dismissal using the established deferred-action pattern, and call `_openReview(_course!)`. Do not add Review to other `courseTile` calls or hidden-course menus.

- [ ] **Step 5: Remove IDDQD influence from Review only**

Stop passing `_iddqdMode == LearnerIddqdMode.viewOnly` to `ReviewScreen`; preserve IDDQD behavior everywhere else. The retained compatibility argument has no effect inside Review. Keep `courseCode` Course-specific using the active Course's established resolver/code.

- [ ] **Step 6: Verify GREEN, format, and inspect the slice**

Run:

```powershell
dart format lib\screens\home_screen.dart test\leaderboard_navigation_test.dart
flutter test --no-pub --reporter expanded --timeout 60s test\leaderboard_navigation_test.dart
git diff -- lib/screens/home_screen.dart test/leaderboard_navigation_test.dart
git status --short
```

---

### Task 5: QQL 232 Metadata, Instructions, and Release Documentation

**Files:**
- Modify: `pubspec.yaml`
- Modify: `lib/services/app_metadata.dart`
- Modify: `test/app_metadata_225_04_test.dart`
- Modify: `test/qql_229_revision3_test.dart`
- Modify: `test/course_audit_report_225_test.dart`
- Modify: `test/course_entry_animation_228_test.dart`
- Modify: `test/leaderboard_navigation_test.dart`
- Modify: `test/learner_round_path_test.dart`
- Modify: `test/alpha_lifecycle_test.dart`
- Modify: `AGENTS.md`
- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Modify: `docs/ROADMAP.md`
- Modify: `docs/PLATFORM_COMPATIBILITY.md`
- Modify: `docs/COURSE_EDITOR.md`
- Modify: `docs/SAMPLE_COURSE.md`
- Modify: `docs/TEAM_MANAGER.md`
- Create: `docs/232_VALIDATION.md`

**Interfaces:**
- Consumes: established `AppMetadata` formatting and show-once technical-version key.
- Produces: Version `2.0.32+232`, Build `232`, Revision `0`, accurate QQL 232 current documentation, unchanged Alpha deadline.

- [ ] **Step 1: Update metadata expectations first and verify RED**

Change literal expectations to:

```dart
expect(AppMetadata.releaseVersion, '2.0.32');
expect(AppMetadata.build, '232');
expect(AppMetadata.platformBuildNumber, '232');
expect(AppMetadata.technicalVersion, '2.0.32+232');
expect(AppMetadata.displayLabel, 'Version 2.0.32\nBuild 232\nRevision 0');
```

Update mock welcome keys from `one_time_notice_seen_welcome_2.0.31+2311` to `one_time_notice_seen_welcome_2.0.32+232`. Update the Alpha test name/metadata expectation while retaining the exact existing deadline.

Run:

```powershell
flutter test --no-pub --reporter expanded --timeout 60s test\app_metadata_225_04_test.dart test\qql_229_revision3_test.dart test\course_audit_report_225_test.dart test\alpha_lifecycle_test.dart
```

Expected failure: production metadata still reports QQL 231.1.

- [ ] **Step 2: Apply release metadata without changing Alpha lifecycle**

Set:

```yaml
version: 2.0.32+232
```

and:

```dart
static const String releaseVersion = '2.0.32';
static const String buildNumber = '232';
static const String developmentPhase = buildNumber;
static const int correctiveRevision = 0;
static const String build = buildNumber;
static const String platformBuildNumber = buildNumber;
static const String technicalVersion = '$releaseVersion+$platformBuildNumber';
static const String displayLabel =
    'Version $releaseVersion\nBuild $buildNumber\nRevision $correctiveRevision';
```

Do not edit `lib/services/alpha_lifecycle_service.dart` or its expiry value.

- [ ] **Step 3: Update current documentation narrowly**

Add a top QQL 232 section to `CHANGELOG.md`; add the QQL 232 release boundary and Review/vocabulary invariants to `AGENTS.md`; update current-version headers in the listed current docs; add a QQL 232 roadmap entry; and create `docs/232_VALIDATION.md` with implementation decisions plus empty evidence rows labelled `Pending final verification` until commands actually run.

Document the exact GuideBook schema, oldest-first tie-break, Current-course-only menu, session-local Round exclusion, persistent word state, fingerprint strategy, interruption safety, Reset isolation, no SRS/Word Review/independent XP, IDDQD independence, no status bar, context/progress, and congratulations choices.

Do not rewrite QQL 231 historical validation or `docs/EXERCISE_TYPE_INVENTORY_231.md`.

- [ ] **Step 4: Verify metadata GREEN and inspect expiry preservation**

Run the focused metadata command again, then:

```powershell
git diff -- lib/services/alpha_lifecycle_service.dart test/alpha_lifecycle_test.dart README.md docs/232_VALIDATION.md
git diff -- pubspec.yaml lib/services/app_metadata.dart AGENTS.md CHANGELOG.md docs
git status --short
```

Confirm the lifecycle source has no timestamp change and documentation consistently says `2026-10-13 23:59:59`.

---

### Task 6: Integrated Verification and Final Evidence

**Files:**
- Modify: `docs/232_VALIDATION.md` only to replace pending evidence with observed results after all checks.

**Interfaces:**
- Consumes: the complete integrated working tree.
- Produces: fresh evidence and a final uncommitted diff ready for user review.

- [ ] **Step 1: Run focused cross-boundary suites**

Run once after all known focused failures are fixed:

```powershell
flutter test --no-pub --reporter expanded --timeout 60s test\qql_232_review_round_resolver_test.dart test\qql_232_vocabulary_review_service_test.dart test\qql_232_review_flow_test.dart test\progress_service_test.dart test\lesson_completion_regression_test.dart test\leaderboard_navigation_test.dart test\learner_status_bar_test.dart test\guidebook_learner_delivery_226_02_test.dart test\guidebook_insights_226_04_r2_test.dart test\optional_learning_paths_226_04_test.dart
```

- [ ] **Step 2: Run formatting and final analyzer**

Format only changed Dart files, confirm formatting creates no unrelated churn, then run:

```powershell
flutter analyze --no-pub
```

Expected: exit code 0 and `No issues found!`.

- [ ] **Step 3: Run the complete Flutter suite exactly once on the final source/test tree**

Run:

```powershell
flutter test --no-pub --reporter compact --timeout 60s
```

Expected: exit code 0 with zero failing tests. If it fails, diagnose only the failing test, correct it, rerun the affected focused test, then rerun the complete suite because source/test files changed.

- [ ] **Step 4: Run non-suite validators**

Run:

```powershell
git diff --check
flutter test --no-pub --reporter expanded --timeout 60s test\sample_courses_test.dart
```

If the repository has a dedicated bundled checksum validator discovered by `git ls-files tools tool test | Select-String checksum`, run it and record the exact command. Otherwise record that `sample_courses_test.dart` verified bundled assets and that no asset file changed.

- [ ] **Step 5: Record evidence without changing production/tests afterward**

Replace `Pending final verification` rows in `docs/232_VALIDATION.md` with exact commands, exit codes, test totals, analyzer output, `git diff --check`, checksum/asset evidence, and unchanged expiry evidence. Because only documentation changes afterward, run:

```powershell
git diff --check
```

- [ ] **Step 6: Final scope and safety inspection**

Run:

```powershell
git status --short --branch
git diff --stat
git diff --name-only
git diff --check
```

Inspect every changed file and confirm no bundled course, checksum, Alpha lifecycle timestamp, unrelated generated platform file, or user work changed.

- [ ] **Step 7: Stop for explicit user confirmation**

Report the 28 requested final-report items, current uncommitted status, exact remaining limitations, and verification evidence. Ask the user whether to request revisions or authorize commit, push, package, tag, and publication. Do not perform any of those operations in this task without the user's answer.
