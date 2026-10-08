# Build 245 — handoff

Update this file at the end of every revision before that revision's commit.
Plan: [245_ARCHITECTURE_PLAN.md](245_ARCHITECTURE_PLAN.md). Change summary:
[245_CHANGE_SUMMARY.md](245_CHANGE_SUMMARY.md). Validation:
[245_VALIDATION.md](245_VALIDATION.md). Repository rules: `AGENTS.md`.

## Current state

Revision 4 is complete in this commit on branch `codex/245-architecture`,
from Revision 3 commit `4a8ee80`. Version: `2.0.45+245004` (Build 245,
Revision 4).
Beta expiry: `2026-10-22 23:59:59` local time. The pre-existing untracked
`devtools_options.yaml` is unrelated and must remain unstaged.

`CourseEditorService` now uses per-Course create, replace and remove commands
instead of whole-store maps. `CourseFileStore` supplies a whole-record token,
shared per-Course lock, duplicate-ID checks, verified temp writes and
readback. Backups precede Course replacement; a stale or out-of-band changed
record is refused. Package media stays in place if a later failure occurs
after the Publisher Course record commits. Existing service entry points,
`qql_courses_v2` bytes, tolerant listing, strict destructive reads and Course
Model v11 remain in place.

Fresh checks are recorded in [245_VALIDATION.md](245_VALIDATION.md): the
storage race baseline reproduced three failures; 21 direct store tests, seven
service race/recovery tests, three package recovery tests and 118 focused
persistence/publisher tests passed after the migration. Analyzer and all four
validators passed. The final integrated suite passed 2,261/2,261 tests. A
Course Info metadata edit with no active profile failed in the first full run;
the actor requirement now applies only to governance changes, and the final
full run passed. Manual
device smoke remains outstanding before treating Build 245 as a release
artifact.

## Next step

No further QQL 245 source revision is planned. Before producing a release
artifact, perform the outstanding manual device smoke from the Build 244
validation record, especially Course Editor nested navigation, Cancel,
Publisher import/update and Course Library. The automated checks are source
verification, not device coverage. The storage command scans other readable
Course files to detect duplicate embedded IDs, so command reads are still
O(number of files). The shared lock coordinates app operations in one isolate;
an external writer can still race in the very small interval after the final
token check and before filesystem rename/delete. Do not treat this as a
cross-process database transaction.

## Previous handoff

Revision 0 is commit `b2e52a1` (`2.0.45+245000`). It introduced the typed
Course Info operation and preserved the existing transaction boundary. Its
focused tests, analyzer and four validators passed; see the Revision 0 section
of [245_VALIDATION.md](245_VALIDATION.md).

Revision 1 is commit `3825356` (`2.0.45+245001`). It introduced the
`CourseAuthoringSession` around the existing transaction, with top-level
staging, Audit freshness and final confirmation ownership. Its focused tests,
analyzer and four validators passed; see the Revision 1 validation section.

Revision 2 is commit `cc66c4e` (`2.0.45+245002`). It introduced typed
hierarchy update commands, Content-wrapper preservation and tolerant preview
overlays for Audit on malformed or generated hierarchy nodes. Its 172/172
focused tests, analyzer and four validators passed; see Revision 2 validation.

Revision 3 is commit `4a8ee80` (`2.0.45+245003`). It routed integrated nested
authoring updates through the one Course session, synchronized canonical
Course snapshots through ancestor screens, and deduplicated live callbacks
from route returns while preserving standalone callbacks. Its 115/115 focused
tests, analyzer and four validators passed; see Revision 3 validation.
