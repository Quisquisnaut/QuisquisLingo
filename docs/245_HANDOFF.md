# Build 245 — handoff

Update this file at the end of every revision before that revision's commit.
Plan: [245_ARCHITECTURE_PLAN.md](245_ARCHITECTURE_PLAN.md). Change summary:
[245_CHANGE_SUMMARY.md](245_CHANGE_SUMMARY.md). Validation:
[245_VALIDATION.md](245_VALIDATION.md). Repository rules: `AGENTS.md`.

## Current state

Revision 2 is complete in this commit on branch `codex/245-architecture`,
from Revision 1 commit `3825356`. Version: `2.0.45+245002` (Build 245,
Revision 2).
Beta expiry: `2026-10-22 23:59:59` local time. The pre-existing untracked
`devtools_options.yaml` is unrelated and must remain unstaged.

`CourseHierarchyUpdateService` now owns typed Lesson, Round and Exercise
reconstruction by stable ID, Exercise Content wrapper preservation and Round
Exercise ordering. The top-level session can apply a typed command to its one
working Course. Nested screens use the same pure operation to build candidates
and retain their existing callbacks and publication reconciliation for now.
Preview-only overlays tolerate generated Rounds and duplicate IDs so Audit
remains accessible; strict mutation commands reject ambiguous targets.
Course Model v11 and storage formats did not move.

Fresh checks are recorded in [245_VALIDATION.md](245_VALIDATION.md): 172/172
integrated focused tests, analyzer with no issues, all four validators, and
`git diff --check` passed. The full suite and manual device smoke are still
outstanding for the integrated Build 245 release gate.

## Next step

Revision 3: propagate one canonical Course updater through the integrated
Lesson Management → Lesson Editor → Lesson Rounds → Round Editor route chain.
Remove duplicate nested reconciliation and duplicate application of live
callback plus pop result while preserving each route's exact prior-Course
snapshot. Round mutation uses its local pre-change Course; Exercise transfer
currently reconciles without one. Preserve standalone public route callbacks
and pending Lesson metadata on exit. Only after this contract passes route
tests should cohesive presentation code move out of the large screen.
Version: `2.0.45+245003` if completed on this release date.

## Previous handoff

Revision 0 is commit `b2e52a1` (`2.0.45+245000`). It introduced the typed
Course Info operation and preserved the existing transaction boundary. Its
focused tests, analyzer and four validators passed; see the Revision 0 section
of [245_VALIDATION.md](245_VALIDATION.md).

Revision 1 is commit `3825356` (`2.0.45+245001`). It introduced the
`CourseAuthoringSession` around the existing transaction, with top-level
staging, Audit freshness and final confirmation ownership. Its focused tests,
analyzer and four validators passed; see the Revision 1 validation section.
