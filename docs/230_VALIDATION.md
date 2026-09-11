# QQL 230 implementation and validation

## Release identity and boundary

QQL 230 is Version `2.0.30`, Build `230`, Revision `0`, technical build `230`, and pubspec `2.0.30+230`. The established 30-day Alpha lifetime is refreshed from the September 11 release date to `2026-10-11 23:59:59` local time. Course Model remains v7 (`formatVersion: 7`). No course JSON field, checksum input, persistence key, XP formula, progression rule, Review rule, or new feature family is introduced.

The source baseline was clean `main` at `b4822e5794ff23a8faf774a52e4fb1087f1a6b35`. The audit covered learner Round/Duel/Review entry and completion, Course Manager and Team authorization, custom/official Course lifecycle, Course Editor transactions and backups, learner backup/restore, activity/streak/XP persistence, update comparison, recorded audio, TTS platform routing, diagnostics, and analyzer health.

## Corrected robustness defects

### Learner completion and Review

- Round completion now latches final submission immediately and `LearningCompletionService` shares one in-flight operation per Course/Round. Rapid taps cannot duplicate completion, recent-Round history, Laurel, Lesson completion, activity, or XP writes. Review uses the same hardened Round path.
- Duel final submission is likewise latched before victory persistence. Optional sound failures cannot conceal an already persisted Round/Duel result or invite another reward attempt.
- **Audio Exercises Off** is authoritative. `DuelEligibilityService` now computes the effective Lesson-local candidate pool after the learner setting and runtime audio availability are applied. Home displays that result and Duel entry recalculates through the same service: 25 remaining non-audio exercises keep the Duel available, while a smaller effective pool produces a visible disabled Home card.
- The Round `Before you start` surface cannot expose Continue until asynchronous filtering and queue construction complete. Duel initialization failures leave the spinner and show a bounded safe state.
- Laurel feedback and weekly-target settings are explicitly non-authoritative side effects. Their failure cannot interrupt earned XP/activity accounting.

### Course Editor, Manager, ownership, and Teams

- Imported custom Courses cannot reuse a bundled or external official `courseId`. Same-ID custom replacement now uses the normal confirmed transaction boundary: current-owner authorization, stale-state comparison, immutable ownership/lineage checks, a verified backup, monotonic versioning, atomic verified replacement, and rollback on failure.
- Custom `courseVersion` text is sanitized before backup filenames are built, and every candidate manifest path is normalized and required to remain a strict child of its Course backup directory.
- Course Manager catches invalid local registry data and shows a diagnostic with Retry instead of remaining on an endless loading spinner. The invalid data remain preserved.
- Profile deletion is blocked while that profile is the individual Owner of a custom Course, preventing a permanently uneditable original. Team final-Lead protection remains authoritative. Generated Team-ID collisions are rejected before registry mutation.
- Shared Course Editor storage-key constants and an isolated ownership-deletion guard remove raw persistence knowledge from the profile lifecycle service.

### Learner and shared persistence

- Replace-in-place learner restore snapshots the exact profile registry, active learner, and learner namespace. Every write/removal is verified; any failure restores the snapshot. A failed separate-copy restore removes its partial profile and namespace and restores the prior active learner.
- Backup v2 rejects malformed keys and unsupported value shapes instead of silently omitting them.
- Learning activity projections ignore malformed day keys, clamp corrupt stored streak values, and preserve the authoritative last-active day when the device clock moves backward.
- XP reads and per-Course breakdown decoding clamp corrupt negative or oversized values to the existing supported range. Reward formulas and persistence keys are unchanged.

### Updates, audio, diagnostics, and maintainability

- Update comparison preserves and numerically compares QQL `+build` values, so a corrective build is no longer treated as equal to an earlier build with the same semantic version.
- Recorded-audio segmentation recognizes Unicode letters, marks, and numbers. New imports use a traversal-safe, Course-ID-derived storage directory and collision-safe clip IDs; completion waits are bounded.
- Linux TTS validates course language metadata and passes valid base languages such as Finnish, Korean, and Irish through to eSpeak instead of silently selecting English. Invalid metadata produces an unavailable result.
- One shared bounded writer serializes concurrent crash/audio file appends. Preference diagnostics retain at most 256 KiB and the crash/audio file at most 2 MiB, retaining the newest evidence after rotation.
- Analyzer-recommended braces were added to 70 existing control-flow statements in Course Audit, the flat image library, and Settings. One unused test helper was removed. This changes no branch condition or behavior and establishes a clean analyzer baseline.

## Targeted modularization

The audit identified several large or tightly coupled implementation surfaces: `CourseEditorScreen` (about 9,100 lines) combines hierarchy navigation, metadata and media authoring UI; `HomeScreen` (about 3,600 lines) combines learner loading, selection, navigation and continuous-path rendering; `RoundScreen` (about 2,270 lines) combines exercise presentation, input and flow control; and `CourseAuditService` (about 1,820 lines) evaluates the 102-rule registry. These are explicit future decomposition candidates, but QQL 230 does not mechanically split them: doing so without an independently testable responsibility would enlarge regression risk without improving a real boundary.

QQL 230 therefore applies targeted modularization only where the audit demonstrated coupling, duplication or an unsafe dependency:

| Boundary | Before | After and dependency direction | Regression protection |
| --- | --- | --- | --- |
| `CourseEditorStorage` | Course persistence identities were private literals inside the large editor service, making a cross-lifecycle ownership check depend on raw knowledge or the entire service. | One small constants boundary owns the unchanged keys. `CourseEditorService` and the ownership guard depend on it; profile lifecycle code does not depend on Course Editor orchestration. | Course replacement, ownership and learner-profile lifecycle suites. |
| `CourseOwnershipGuard` | Profile deletion had no narrow place to enforce custom-Course ownership and could orphan an individually owned original. | Ownership parsing and the deletion invariant live in one model-aware guard called by `ProfileService`, outside UI and the large editor service. | Owner/non-owner deletion, malformed storage and Team ownership cases. |
| `BoundedLogWriter` | Preference diagnostics and crash/audio file logs had separate unbounded append paths and inconsistent concurrency behavior. | Both logging services delegate retention, Unicode-safe truncation, file rotation and per-file serialization downward to one writer. | Six direct boundary tests plus startup/diagnostic/audio logging suites. |
| `DuelEligibilityService.evaluateEffective` | Structural eligibility lived in the service, but `DuelScreen` separately filtered audio and Home advertised only the structural result. | The service owns structural validation plus effective audio filtering. Home presentation, Home's tap-time guard and `DuelScreen` all depend on that result; no UI contains a second eligibility rule set. | Eleven service tests and Home/Duel widget cases for Audio On, Audio Off with 25 remaining, and Audio Off with 24 remaining. |
| `LearningCompletionService` single-flight boundary | The existing orchestration service allowed concurrent calls for the same Course/Round to run independently. | The existing service—not the screen—owns one in-flight completion operation per Course/Round, while UI latches submission before calling it. | Deterministic concurrent-completion and rapid-submit widget tests. |

Duplicate policy was removed rather than merely wrapped in the Duel and logging paths. The storage constants were centralized without changing their values. The ownership guard adds a missing cross-domain invariant at a narrow seam. Other persistence, restore, replacement and error-handling work strengthens existing service boundaries rather than being presented as a new extraction.

No modularization change alters Course Model v7, serialized Course JSON, SharedPreferences keys or value formats, learner progress, XP/scoring, Review rules, or ownership semantics. New boundaries point from screens and lifecycle services toward smaller policy/storage utilities; none depends back on UI code.

## Compatibility invariants

- Course Model v7 and the nine bundled Course sources/checksums are unchanged.
- Completed Rounds/Lessons, Laurels, Review history, Duel state, language XP, global Weekly XP, activity, streak, IDDQD, Theme, Flag Background, Hide/Unhide, and authoring data retain their established keys and formats.
- Round, Lesson, Review, and Duel XP values are unchanged.
- Official originals remain immutable; Duplicate/Fork, Creator/Owner, Team membership, and derivative-license rules remain unchanged except for the new deletion/collision guards that prevent invalid lifecycle states.
- Existing recorded-audio file paths remain readable. Only newly imported files use the Course-ID-derived directory.

## Deliberately unresolved decisions

The audit found issues that need a product or compatibility decision rather than an implicit 230 behavior change:

1. Arbitrary custom language names can fall back to the same two-letter language key. Correcting that safely needs an explicit compatibility/migration rule because XP, streak, and study days are deliberately language-scoped.
2. Imported authoring MP3s are copied before the top-level Course transaction is confirmed. A complete staged-asset commit/cancel protocol is preferable to heuristic deletion and needs an explicit authoring-transaction design.
3. Course backup asset manifests and history recovery need a future compatible policy for strict asset completeness and skipping/reporting individual corrupt manifests. QQL 230 hardens path containment without silently changing existing backup validity.

## Fresh verification

All commands were run against the final working tree through the repository's existing Flutter SDK without fetching dependencies.

- `flutter analyze --no-pub`: pass, no issues.
- Focused learner completion, Round/Duel, Course transaction/ownership, learner identity, activity, XP, update, audio/TTS, log, metadata, and Alpha lifecycle suites: pass. This includes all three effective-Duel-pool states at both the service boundary and Home/Duel integration boundary.
- Full repository suite: pass, 1,346 tests and zero failures in 12 minutes 8 seconds with concurrency bounded to four workers.
- All nine bundled Course sources: checksum verification passed unchanged.
- `git diff --check`: pass; only the repository's existing Windows line-ending conversion notices were emitted.

An initial integration run exposed a cross-test/lifecycle failure caused by a static preference-log write queue retaining a failed asynchronous zone, plus three release-sensitive assertions that still named the prior version or direct append implementation. The queue is now scoped to each diagnostic service instance, and the contracts assert the bounded writer and current release identity. Effective Duel integration also exposed two older navigation tests that implicitly relied on Audio Off still allowing an audio-dependent Duel; those tests now make their unrelated Audio On precondition explicit. The uninterrupted final run above is green.

No commit, tag, push, package, installer, or source archive is part of this task.
