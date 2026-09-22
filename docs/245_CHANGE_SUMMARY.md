# Build 245 — architecture change summary

Build 245 reorganizes Course authoring by ownership of rules, state and side
effects. The architecture and revision sequence are in
[245_ARCHITECTURE_PLAN.md](245_ARCHITECTURE_PLAN.md). File moves alone are not
revision goals. Course Model v11, storage keys and formats, learner scoring,
progression, Course packages and Publisher signatures remain unchanged.

## Revision 2 — typed hierarchy updates

Version **2.0.45+245002**. Beta expiry: **2026-10-22 23:59:59 local**, 30
days from this release date, 22 September 2026.

Typed Lesson, Round and Exercise update commands own hierarchy reconstruction
and Content-wrapper preservation. Editors retain transient form and navigation
state. The session remains responsible for adopting staged updates and Audit
freshness, and the existing final confirmation remains the only persistence
point. Route callbacks and nested reconciliation retain their current behavior until
Revision 3, when canonical propagation can preserve each prior-Course
snapshot. Route coverage and any remaining migration work are recorded in
[245_VALIDATION.md](245_VALIDATION.md) and [245_HANDOFF.md](245_HANDOFF.md).
Course Model v11, stored data and user-visible behavior are preserved.

## Revision 1 — Course authoring session

Version **2.0.45+245001**. Beta expiry: **2026-10-22 23:59:59 local**, 30
days from this release date, 22 September 2026.

One non-UI authoring session coordinates the existing Course Editor working
copy, top-level provisional publication reconciliation and draft adoption, dirty state,
Audit freshness and final confirm/cancel. The screen retains presentation and
navigation state. The session keeps one working Course, passes the relevant
previous snapshot to publication reconciliation, and uses the existing final
confirmation path. Nested editor reconciliation remains for Revision 2.
Course Model v11 and user-visible behavior are preserved.

See [245_VALIDATION.md](245_VALIDATION.md) for fresh checks and
[245_HANDOFF.md](245_HANDOFF.md) for the next revision.

## Revision 0 — Course Info update boundary

Version **2.0.45+245000**. Beta expiry: **2026-10-22 23:59:59 local**, 30
days from this release date, 22 September 2026.

The Course Info dialog retains form and interaction state. A typed update
result is applied by one Course Info operation, which owns the ordered Team
assignment and Maintainer transfer calls, optional-field omission and Course
metadata reconstruction. The result still enters the existing Course Editor
working-copy transaction; only top-level confirmation persists it. Existing
authoring rights and visible behavior are preserved.

See [245_VALIDATION.md](245_VALIDATION.md) for fresh checks and
[245_HANDOFF.md](245_HANDOFF.md) for the next revision.
