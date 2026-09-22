# Build 245 — handoff

Update this file at the end of every revision before that revision's commit.
Plan: [245_ARCHITECTURE_PLAN.md](245_ARCHITECTURE_PLAN.md). Change summary:
[245_CHANGE_SUMMARY.md](245_CHANGE_SUMMARY.md). Validation:
[245_VALIDATION.md](245_VALIDATION.md). Repository rules: `AGENTS.md`.

## Current state

Revision 0 is complete in this commit on branch `codex/245-architecture`,
from parent `2d40d81`. Version: `2.0.45+245000` (Build 245, Revision 0).
Beta expiry: `2026-10-22 23:59:59` local time. The pre-existing untracked
`devtools_options.yaml` is unrelated and must remain unstaged.

`CourseInfoChange` is the typed result of the existing Course Info form.
`CourseInfoUpdateService.apply` now owns Team-before-Maintainer governance,
optional-field omission and metadata reconstruction. The screen stages the
returned Course through its existing transaction; final confirmation remains
the only persistence point. Course Model v11 and storage formats did not move.

Fresh checks are recorded in [245_VALIDATION.md](245_VALIDATION.md): 77/77
integrated focused tests, analyzer with no issues, all four validators, and
`git diff --check` passed. The full suite and manual device smoke are still
outstanding for the integrated Build 245 release gate.

## Next step

Revision 1: introduce a `CourseAuthoringSession` that *uses* the existing
`CourseEditorTransaction` as its only working Course. Move top-level draft
adoption, publication reconciliation, audit freshness and confirm/cancel
coordination into that owner. Keep dialogs and settings in the widget.
Preserve the `previous` Course passed to reconciliation and the existing
backup-before-write confirmation path. Nested reconciliation remains until
Revision 2. First add session tests and rerun the real editor transaction
route before migrating each screen call site. Revision 1 version is
`2.0.45+245001` if completed on this release date.
