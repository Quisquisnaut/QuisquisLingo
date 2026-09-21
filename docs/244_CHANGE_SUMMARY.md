# Build 244 — change summary

Build 244 turns **Available on this device** into the **Course Library**.
Plan: [COURSE_LIBRARY_244_PLAN.md](COURSE_LIBRARY_244_PLAN.md).

## Revision 1 — shared Course Draft rule

Version **2.0.44+244001**. Beta expiry: **2026-10-21 23:59:59 local**, the
30-day policy applied to this release's own date, 21 September 2026.

Structural only; nothing visible changes. The authored-Draft rule
(unpublished Lesson, GuideBook or GuideBook content while GuideBook is on,
Round or Round content, Exercise) moves from `AuthoringHierarchyStatus` in
`course_editor_screen.dart` to `CourseDraftStatus` in
`lib/models/course_draft_status.dart`. `AuthoringHierarchyStatus` keeps its
API and delegates. The helper reads publication states only and never runs
the Course Audit, so the Course Library can evaluate every Course cheaply.
