# Build 245 — architecture change summary

Build 245 reorganizes Course authoring by ownership of rules, state and side
effects. The architecture and revision sequence are in
[245_ARCHITECTURE_PLAN.md](245_ARCHITECTURE_PLAN.md). File moves alone are not
revision goals. Course Model v11, storage keys and formats, learner scoring,
progression, Course packages and Publisher signatures remain unchanged.

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
