# QQL 232 Integrated Vocabulary Reinforcement in Review — Design

## Status and controlling requirements

This design implements QQL `2.0.32+232`, Build 232, Revision 0, on the committed QQL `2.0.31+2311` baseline. It incorporates the attached QQL 232 specification and the user's subsequent corrections. The current checkout remains the source of truth.

No worktree, staging, commit, push, package, tag, publication, reset, revert, clean, discard, unrelated refactor, or bundled-course content change is authorized during implementation. The Alpha expiry remains exactly `2026-10-13 23:59:59` local time despite the version update, as explicitly required by the user.

## Learner experience and navigation

Review remains a dedicated learner page. It is reachable in exactly two ways:

1. the existing Review button at the bottom of the active Course's Learner Panel;
2. a new Review item in the three-dot menu of the **Current course** row in Course Selector.

No Review action is added to recent, included, local, hidden, or otherwise inactive Course rows. Both entry points therefore open Review for the already active Course. Returning with system/app Back restores the existing Learner Panel route and its retained scroll position; Review does not switch or reload another Course.

The Review page has no learner status bar. Its app bar has two Review-specific icon buttons at the upper right: Reset Word List and Help. Vocabulary phases and terminal states use this Review app bar. The existing Round exercise surface remains the authoritative Round UI during the central Round attempt and retains its existing mechanics, app bar, exercise progress indicator, audio/report actions, and completion dialogs. A Review-only presentation parameter labels that surface as Review and expands its existing subtitle to the full Course title, target language, Lesson number/title, and Round number/title; ordinary Round entry remains unchanged.

The Review page starts its flow automatically after loading. It does not first show the former selectable list of up to 50 Round cards and does not expose a separate Word Review destination.

## Authoritative Round selection

`ProgressService.getRecentRounds(courseId: ..., limit: 50)` remains the single source of Review candidates. Its authoritative ordering changes for QQL 232 to:

1. larger latest-attempt error count first;
2. at equal error count, older latest-attempt timestamp first.

The Review coordinator selects the first ordered entry that still resolves to a real Lesson and Round in the active Course. It does not use Lesson order, Round creation order, learner-panel position, or another queue.

Completing the reviewed Round continues to call the existing `recordRecentRound` path. That replaces the Round's latest result and timestamp, so the just-reviewed Round becomes the newest Round for the next ordering calculation while retaining its newly recorded error count.

If no stored Review candidate resolves, the page displays a concise no-Review-available state. It does not fabricate a Round or destroy stale progress data.

## Review session state machine

For the selected Round in Lesson L, the Review page coordinates these states:

1. loading and authoritative Round resolution;
2. optional pre-Round vocabulary preparation;
3. the existing Round Review attempt;
4. optional post-Round vocabulary reinforcement;
5. a congratulations page.

The Review route owns a session-local, non-persisted set of Round IDs completed during that visit. The congratulations page offers exactly two forward choices:

- `Next Review`, which recalculates the authoritative Review ordering while excluding every Round already completed in the current Review session;
- return to the active Course's Learner Panel.

System/app Back has the same destination as the return action. If `Next Review` finds no remaining valid Round, Review shows a concise notice and stays on the congratulations page so the learner can return to the Learner Panel. Leaving Review discards only the session-local excluded-Round set; it does not clear Review history or vocabulary memory.

If the learner abandons the flow before normal Round completion, Review returns to the Learner Panel. Decisions already persisted remain authoritative. In particular, `Show it to me again` is persisted before the Round and is not silently converted to known.

Vocabulary cards show a phase label (`Before the Round` or `After the Round`), the full Course title, target-language name, Lesson number/title, Round number/title, and card position. Long custom titles wrap without truncating the learner's context. Vocabulary phases use a linear progress indicator. During the Round, the established Round exercise progress indicator remains authoritative.

## GuideBook Vocabulary source and presentation

The current Course Model v7 schema stores GuideBook Vocabulary as ordered `LearningContent` entries:

- stable non-empty `id`;
- `publicationState`;
- `kind: vocabulary`;
- normally `role: vocabulary`;
- a single authored `text` string.

The Course Editor describes each string as one target/source pair such as `casa = house`. The existing generator accepts the first valid separator among ` = `, ` → `, ` - `, and `:`. QQL 232 uses the same pair interpretation but does not reuse the generator's deduplication behavior.

Only the learner-safe published GuideBook branch is consumed. A usable card requires a non-empty term before a supported separator and a non-empty answer after it. The term is the initial prompt; the answer is revealed by `Show answer`. The current schema has no structured vocabulary fields for gender, pronunciation, examples, notes, alternative meanings, or parts of speech, so QQL 232 displays none and fabricates none. Malformed or unsupported entries are skipped safely.

If `Course.useGuidebook` is false, the GuideBook is Draft, no published usable vocabulary exists, or every vocabulary entry is malformed, Review proceeds directly to the Round.

Authored order is preserved. Entries are never randomized or alphabetized. Entries with the same term are not merged, and genuinely identical authored occurrences remain distinct.

## Vocabulary domain and persistence boundary

A dedicated `VocabularyReviewService` owns:

- resolving learner-safe vocabulary for a Course and Lesson;
- parsing authored prompt/answer pairs;
- determining eligible entries in authored order;
- reading and updating `encountered` and `needsReinforcement`;
- detecting review-relevant content changes;
- resetting the current learner's current-Course Word List.

A small `ReviewRoundResolver` delegates ordering to `ProgressService.getRecentRounds`, accepts an optional session-local set of excluded Round IDs, and resolves the first remaining valid Course/Lesson/Round location. Widgets do not sort Review candidates or manipulate raw vocabulary persistence.

Vocabulary memory is stored in `SharedPreferences` under the active opaque learner prefix and one Course-specific key. The value is versioned JSON containing records scoped by Lesson ID and vocabulary-entry identity. Each record contains only:

- the deterministic content fingerprint;
- `encountered`;
- `needsReinforcement`.

Missing, malformed, obsolete, or stale records behave as absent and cannot crash Review. Course JSON and GuideBook content are never mutated. Reset removes only this learner-and-Course vocabulary value.

IDDQD Off, On, and View Only do not affect Review entry, ordering, Round behavior, or vocabulary persistence. Review candidates are already genuinely completed Rounds, and Review runs as ordinary Review regardless of the Learner Panel's current IDDQD display/access mode.

## Entry identity and change detection

The existing stable `LearningContent.id` is the primary authored identity. The service appends a deterministic same-ID occurrence index if malformed imported data repeats an ID. If an entry lacks a usable ID in an in-memory object, the fallback identity is its content fingerprint plus its authored duplicate-occurrence index.

The fingerprint is SHA-256 over a versioned, deterministic encoding of exactly the review-presented authored prompt, answer, and any future structured supplementary fields that the service actually supports. Course title, Lesson title, Lesson position, Round title, and Round position are excluded.

Consequences:

- reopening and title changes preserve state;
- a changed displayed term or answer has a different fingerprint and behaves as new;
- a newly added entry is new;
- a deleted entry disappears without disturbing neighboring state;
- identical entries with distinct stable IDs retain distinct state;
- fallback duplicate occurrences remain deterministic without relying on Dart runtime hash values.

## Pre-Round vocabulary behavior

Eligible entries are those whose current fingerprint is either not encountered or marked `needsReinforcement`. Encountered entries without reinforcement are omitted.

Each card first shows the authored prompt and `Show answer`. After reveal it shows the authored answer and exactly two decisions:

- `I know it`: persist `encountered = true`, `needsReinforcement = false` and omit the entry from this session's post-Round phase;
- `Show it to me again`: persist `encountered = true`, `needsReinforcement = true`, append the entry once to this session's post-Round list, and continue to the next pre-Round card.

Persisting the reinforcement request immediately is the interruption-safety mechanism. No resumable session store, schedule, SRS, mastery model, or additional queue is introduced.

## Round Review behavior

After pre-Round decisions, the coordinator opens the existing `RoundScreen` with the selected Course, Lesson, Round, Round index, and Course-derived language. No IDDQD View Only flag is propagated into Review.

The Round keeps its existing questions, filtering, correctness, audio, feedback, lives, mistake review, completion orchestration, XP, progress, Review-history update, and error handling. QQL 232 adds no vocabulary XP or Round-side scoring rule.

Only a normally concluded Round advances to post-Round reinforcement or congratulations. Abandonment does not complete the vocabulary session, but already persisted pre-Round decisions remain intact.

## Post-Round reinforcement behavior

Only entries selected through `Show it to me again` in this exact session appear, in their original relative order, once each. Each card again requires `Show answer`, then offers exactly:

- `I know it`: persist `encountered = true`, `needsReinforcement = false`;
- `I still don't know it`: persist `encountered = true`, `needsReinforcement = true`.

Neither action repeats the card again during the same Round Review. After the final post-Round decision, Review adds that Round to the session-local completed set and shows the congratulations page.

If `Next Review` selects another Round from the same Lesson, only changed/new entries and entries still needing reinforcement return before that Round. Known entries are skipped. The same rule applies to a later Review visit and when the same Round is reviewed again after the current session ends. A word marked `I still don't know it` after its second appearance therefore remains eligible; no additional repetition occurs inside that same Round Review.

## Reset Word List and Help

Reset Word List is the first Review app-bar icon action and is visually secondary. It opens a confirmation dialog equivalent to:

`Reset Word List?`

`All vocabulary for this course will be treated as new again. Round Review and course progress will not be changed.`

Cancel makes no change. Confirmation clears both vocabulary flags for every Lesson in the active Course for the active learner only. If reset occurs during pre-Round vocabulary, that preparation restarts with all usable entries. If reset occurs during post-Round reinforcement, the remaining post list is discarded so no old session decision can silently recreate state after the reset. A later Round Review—including a `Next Review` selection from the same Lesson—therefore treats all usable Course vocabulary as new again. Reset does not alter other learners/Courses, Round or Lesson completion, the session-local reviewed-Round set, Review ordering, XP, Weekly XP, streak, laurels, Duels, unlocking, GuideBook content, ownership, authoring metadata, Course version, or any unrelated preference.

Help is the second Review app-bar icon. Its concise learner-oriented dialog explains the integrated pre-Round and post-Round flow, eligibility, the three decisions, non-repetition of known words, Reset Word List, the absence of separate vocabulary XP/progression, and that GuideBook Vocabulary is the authored source.

## Non-goals and compatibility

QQL 232 does not add a Word Review page, three-Lesson preparation window, Lesson `prepared` state, independent vocabulary queue, SRS, due dates, confidence, mastery, per-word XP, word streak, vocabulary audio architecture, Course Model field, course migration, bundled content update, checksum change, or separate vocabulary statistic.

Existing learners start with missing vocabulary state, which means every usable published entry is new on the first applicable Review. The existing 50-Round cap and learner/Course isolation remain intact.

## Release metadata and documentation

Implementation updates `pubspec.yaml` and `AppMetadata` to Version `2.0.32+232`, display Build 232, Revision 0. It adds QQL 232 release notes/validation documentation and narrowly updates current-version references in `AGENTS.md`, `README.md`, `CHANGELOG.md`, and other current release metadata documents where required. Historical release records remain historical.

The Alpha lifecycle implementation, expiry tests, and expiry timestamp remain unchanged at `2026-10-13 23:59:59` local time by explicit user instruction.

## Verification strategy

Implementation follows test-first slices. Focused coverage will establish:

- error-descending/oldest-first Review ordering and timestamp refresh after Review;
- direct Review entry, session-local exclusion through `Next Review`, and initial/no-more-candidates states;
- Current-course-only Course Selector action and route isolation;
- published GuideBook parsing, authored order, no-vocabulary/disabled behavior, malformed data, and no fabrication;
- pre/post decisions, one-time per-Round reinforcement, persistent difficult-word memory, same-Lesson `Next Review`, later-Round and repeated-Round behavior;
- interruption safety;
- identity/fingerprint behavior, additions, changes, deletions, duplicates, reopening, and title stability;
- learner/Course/Lesson isolation;
- confirmation-gated reset and non-vocabulary-state isolation;
- Review Help, app-bar actions, no learner status bar, context text, progress, and congratulations actions;
- no independent XP, Weekly XP, completion, streak, laurel, Duel, unlocking, or Review-order effects from vocabulary interactions.

After focused tests are green, run formatting, affected GuideBook/navigation regressions, `flutter analyze --no-pub`, the complete Flutter test suite exactly once on the final source/test tree, checksum validation if the repository provides it, and `git diff --check`. Final status and diff are inspected before reporting. No commit or later release operation occurs until the user gives separate confirmation after reviewing the completed implementation and evidence.
