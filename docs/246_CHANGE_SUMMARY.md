# Build 246 — Merge workflow change summary

## Revision 0 — one owner for Merge media and confirmation

Version **2.0.46+246000**. Beta expiry: **2026-10-22 23:59:59 local**,
30 days from the 22 September 2026 release date.

`CourseEditorService.confirmMergedCourse` now owns copying referenced media
from the left and right source Courses, calling the established final Course
confirmation, and deciding cleanup after a failure. The Merge screen calls
this operation after its existing Audit and warning steps. Temporary media
from a right-hand Course package remains available until that call finishes.
`CourseMergeService` continues to build and validate the candidate Course.
The Merge screen now holds one submission active through package cleanup and
freezes the selected Lessons and options for that attempt. This prevents a
second tap from removing temporary right-hand media while the first Merge is
still using it.

The previous screen copied media outside its confirmation guard, so a partial
copy could leave destination files behind. Its catch also deleted the entire
merged media folder if confirmation threw, even though confirmation can throw
after the Course record is written. The new operation removes only files this
attempt added when absence of a saved Course is proven. It keeps the media
when a record exists or its state is unreadable. The original error still
reaches the screen. A precommit rejection after both copies is covered as
well as partial-copy and postcommit failures.

Course Model v11, stored formats and keys, authoring rights, successful Merge
result, and the single top-level save boundary are unchanged. The
existing treatment of a reference missing from both source folders remains
unchanged. See [246_VALIDATION.md](246_VALIDATION.md) for failure-injection
evidence and [246_HANDOFF.md](246_HANDOFF.md) for the next boundary.
