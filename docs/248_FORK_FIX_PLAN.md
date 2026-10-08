# Build 248 Revision 3 — Fork leaves the Course Editor

Status: requested by the owner on 2026-09-23 after noticing that Revision 2
removed export and Copy as New Course from the Course Editor but left Fork.
Version `2.0.48+248003`.

Unlike Revisions 1 and 2, this **is** a correction within Build 248's own
scope: Revision 2 set out to stop the Editor acting on the unconfirmed working
copy and removed two of the three actions that did so.

## The defect

`_forkCourse` calls `createFork(source: _course)`, where `_course` is
`_session.workingCourse` — the **unconfirmed working copy**. It is the same
line shape as the `_copyAsNewCourse` Revision 2 removed.

Fork **persists** a new Course, so:

1. open a Course you do not maintain,
2. change it in the working copy,
3. Fork,
4. cancel the original session,

leaves a permanent forked Course built from edits that were never confirmed,
whose `forkProvenance` names a source version that exists nowhere.

## Course Manager already covers every case, and better

Checked before removing anything, as the recorded caveat required:

* Its menu entry is gated by the same `access.canFork`.
* `_forkCourse(course)` passes the **stored** Course.
* For an **official** Course it first resolves the immutable official source
  (`officialSourceFor`, using `loadBundledCourse` for a bundled Course) and
  forks that, refusing when the source is unavailable. The Editor's version
  forked whatever the Editor happened to hold.

So the Editor's Fork is not merely a duplicate; it is the less correct of the
two on both counts.

## The change

Remove `course-editor-fork-course` and `_forkCourse` from
`lib/screens/course_editor_screen.dart`, together with any symbol left
unreferenced. `widget.access.canFork` stays as the capability; only the
Editor's entry point goes. Course Manager, `CourseAccessPolicy` and
`CourseEditorService.createFork` are untouched, so who may fork and what a fork
inherits are unchanged.

## Proof

1. A test that fails on the current tree: the Course Editor offers no Fork for
   a custom Course an outsider may fork, where the tile exists today.
2. A test that Course Manager still offers Fork for the same Course, so the
   capability is proven to survive rather than assumed.
3. Existing assertions on `course-editor-fork-course` are repointed; that they
   fail first is the evidence.
4. `flutter analyze --no-pub`, the four validators, one complete suite at
   `--concurrency=1`, version and release records, handoff, `git diff --check`,
   one local commit.

## Preserved

Course Model v11, stored formats and keys, package format 1 and signatures,
fork provenance and lineage rules, authoring rights, scoring, progression and
the single top-level confirmed Course save.
