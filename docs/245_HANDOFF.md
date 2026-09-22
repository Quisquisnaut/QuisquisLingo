# Build 245 — handoff

Update this file at the end of every revision before that revision's commit.
Plan: [245_ARCHITECTURE_PLAN.md](245_ARCHITECTURE_PLAN.md). Change summary:
[245_CHANGE_SUMMARY.md](245_CHANGE_SUMMARY.md). Validation:
[245_VALIDATION.md](245_VALIDATION.md). Repository rules: `AGENTS.md`.

## Current state

Revision 1 is complete in this commit on branch `codex/245-architecture`,
from Revision 0 commit `b2e52a1`. Version: `2.0.45+245001` (Build 245,
Revision 1).
Beta expiry: `2026-10-22 23:59:59` local time. The pre-existing untracked
`devtools_options.yaml` is unrelated and must remain unstaged.

`CourseAuthoringSession` now owns top-level staging, publication reconciliation,
Audit freshness, mode-dependent edit permission, history load coordination,
cancel and final confirm. It holds the existing `CourseEditorTransaction`,
so there is one working Course and one final persistence path. The editor
still owns dialogs, settings persistence and route navigation. Nested editor
reconciliation remains until Revision 2. Course Model v11 and storage formats
did not move.

Fresh checks are recorded in [245_VALIDATION.md](245_VALIDATION.md): 74/74
integrated focused tests, analyzer with no issues, all four validators, and
`git diff --check` passed. The full suite and manual device smoke are still
outstanding for the integrated Build 245 release gate.

## Next step

Revision 2: introduce typed hierarchy update commands applied to the current
working Course by stable Lesson, Round and Exercise IDs. Characterize rich
`LearningContent` wrappers (`required`, `sourceRefs`, role and presentation)
before migrating one route at a time. Move nested provisional reconciliation
only when its route uses the new command contract, preserving the immediate
previous Course for each accepted update. Keep standalone public editor
routes and existing pop results functional. Version: `2.0.45+245002` if
completed on this release date.

## Previous handoff

Revision 0 is commit `b2e52a1` (`2.0.45+245000`). It introduced the typed
Course Info operation and preserved the existing transaction boundary. Its
focused tests, analyzer and four validators passed; see the Revision 0 section
of [245_VALIDATION.md](245_VALIDATION.md).
