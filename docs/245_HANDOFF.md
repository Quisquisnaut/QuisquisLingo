# Build 245 — handoff

Update this file at the end of every revision before that revision's commit.
Plan: [245_ARCHITECTURE_PLAN.md](245_ARCHITECTURE_PLAN.md). Change summary:
[245_CHANGE_SUMMARY.md](245_CHANGE_SUMMARY.md). Validation:
[245_VALIDATION.md](245_VALIDATION.md). Repository rules: `AGENTS.md`.

## Current state

Revision 3 is complete in this commit on branch `codex/245-architecture`,
from Revision 2 commit `cc66c4e`. Version: `2.0.45+245003` (Build 245,
Revision 3).
Beta expiry: `2026-10-22 23:59:59` local time. The pre-existing untracked
`devtools_options.yaml` is unrelated and must remain unstaged.

Integrated Course → Lesson → Rounds → Round → Exercise routes now stage each
accepted edit through the one `CourseAuthoringSession` adopter. Nested parents
receive the canonical Course to update their view without reconciling again,
and identical route results are not staged after a live callback. The session
accepts the route's exact prior Course for Draft promotion; Exercise transfer
retains its existing no-prior rule. The direct Course Audit → Exercise fallback
uses the current canonical Round. Standalone route callbacks, unsaved working
copy, final confirmation and Course Model v11 remain intact. There was no
physical screen split.

Fresh checks are recorded in [245_VALIDATION.md](245_VALIDATION.md): the
baseline test exposed repeated route updates; 115/115 broad focused tests,
including the direct Audit → Exercise and integrated Exercise transfer
regressions, analyzer and four validators passed after the migration. The
full suite and manual device smoke are still
outstanding for the integrated Build 245 release gate.

## Next step

Revision 4: replace `CourseEditorService`'s `_loadKey`/`_saveKey` whole-store
map bridge with intent-specific per-Course create, replace and remove commands.
Prove the stale-map race first: a Course created while another confirmation is
paused must survive, and a same-ID intervening change must cause stale
confirmation to fail. Use identity-aware snapshots and a shared per-Course
mutation lock through access checks, backup, commit, readback and media
cleanup. Keep readable listing, strict destructive reads, the `qql_courses_v2`
format and the public service facade. Test corrupt or duplicate IDs, truncated
temp writes, failure recovery, package media retention and publisher paths
before retiring the map bridge. Version: `2.0.45+245004` if completed on this
release date.

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
