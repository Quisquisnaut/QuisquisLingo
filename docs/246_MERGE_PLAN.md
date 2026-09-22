# Build 246, Revision 0 — Merge workflow plan

Status: approved in the Build 246 Merge task, from current `main` after the
approved [architecture roadmap](ARCHITECTURE_ROADMAP_246_PLUS.md). Baseline:
`2.0.45+245004` (Build 245, Revision 4).

## Intended owner and contract

`CourseMergeService` constructs and validates a candidate Course. The Merge
screen owns selection, Audit feedback and presentation. The right-hand Course
package temporarily installs its media for the callback. One
`CourseEditorService.confirmMergedCourse(left, right, merged)` operation owns
the destination Course's media copy, final confirmation and failure cleanup.
It copies references from the left Course first, then fills missing references
from the right Course, and calls the existing top-level
`confirmCourseTransaction` exactly once under the destination per-Course lock.

On failure, the operation inspects the destination Course record. It removes
only files absent before this attempt when storage proves no Course was saved.
It retains media if the record exists or storage cannot establish absence,
then propagates the original error. Existing nonblocking behavior for media
missing from both sources is preserved. The normal Merge screen result and
right-package staging lifetime are preserved.
The Merge screen accepts one submission at a time through the package's
cleanup, keeping its selected Lessons and options fixed for that attempt.

## Proof and implementation stages

1. Use real temporary Course and media stores with injected partial copy,
   post-create, post-save cleanup, and unreadable recovery failures. Assert
   record/media consistency and preservation of source and pre-existing
   destination files. Cover normal left/right copying and temporary package
   media before changing the production path. Prove that a second submission
   cannot start while the first is still using the right package.
2. Add the one service operation and route the Merge screen through it.
   Remove the separate `CourseMergeService.copyMedia` and `discardMedia`
   entry points after their callers and tests move to the new owner.
3. Run focused suites, analyzer, the full Flutter suite, four asset validators
   and `git diff --check`. Update version, release records and handoff before
   one local Revision 0 commit. Push after the validated commit as requested.

Course Model v11, persisted formats and keys, authoring rights, progression,
scoring, package/signature bytes and the single top-level save boundary remain
unchanged. Package Import and later ownership changes remain in their numbered
roadmap builds.
