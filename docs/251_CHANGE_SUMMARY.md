# Build 251 change summary

## Revision 0 — Shared Course sections

`2.0.51+251000`, dated 2026-09-24. `CoursesScreen` retains the shared Sort,
Search and Show unavailable controls. The embedded All Courses and Course
Studio tab bodies keep their own data loading and Course actions. Both use one
`CourseLibrarySection` with `CourseLibraryCategories` and
`CourseLibraryFilter`; the existing `CourseLibraryRow` and
`CourseLibraryPresentation` remain shared.

The five sections, learner-scoped Favorites, Expanded/Compact state per section
(including across tab reloads),
border and header colors, counts, empty copy, ordering, Search and unavailable
filtering retain their Revision 1 behavior. Existing public standalone screens,
widget keys, membership, authoring rights, import, Audit and navigation remain
unchanged. Course Model v11, package format 1, stored keys, progression, scoring
and the Editor confirmation remain unchanged.

The Beta expiry is `2026-10-24 23:59:59` local time, 30 days from this
revision's release date. This is a source release without a Windows package.
See [251_VALIDATION.md](251_VALIDATION.md) for verification evidence and
[251_HANDOFF.md](251_HANDOFF.md) for the next step.
