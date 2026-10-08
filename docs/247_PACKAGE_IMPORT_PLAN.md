# Build 247 — Package Import workflow plan

Status: approved by the owner on 2026-09-22 in the Build 247 Package Import
session, under the approved [architecture roadmap](ARCHITECTURE_ROADMAP_246_PLUS.md).
The owner asked for one local commit per revision, no separate contract
checkpoint, and a new revision only for a substantial fix. Baseline: `main`
`c543551`, `2.0.46+246001` (Build 246, Revision 1).

## Current routes

Fixed-folder Import (`Imports/import.zip` or `import.json`) and Open from…
(ZIP or JSON) both return a `CoursePackage` from
`CustomCourseTransferService`. ZIP media wait in `qql_import_staging`; a JSON
package carries no media. `CourseProjectsScreen._importCourse` then refuses
a bundled Course, blocks on Audit errors, and follows one of five routes:

| Route | Today |
| --- | --- |
| Publisher Course | `installExternalOfficialUpdate(package:)` installs media and the record under the Course lock and retains media when the stored source matches the update or cannot be read. |
| New custom Course | `package.withInstalledMedia(course.courseId, installImportedCustomCourse)`: media are written **before and outside** the Course lock. |
| Replace / update | The same call; the save is `confirmCourseTransaction`. |
| Copy as New Course, Fork | Package media are written temporarily into the **same-ID installed Course's** folder, copied by `_withCopiedMedia` into the new Course's folder, then removed. |
| Cancel, Audit block, error | The screen discards staging in `finally`. |

After Copy or Fork, the screen opens the new Course's Editor while still
holding the package, so staged media remain until that Editor closes.

## Owner and contract

A new `CoursePackageImport` (`lib/services/course_package_import.dart`) holds
one read package from reading until the attempt ends. The screen still picks
the file, shows Audit results, dialogs and messages, and decides which
choices to offer. It calls exactly one action:

* `installCustomCourse()` — a new custom Course or Replace / update;
* `copyAsNewCourse(title:)` or `fork()` — a new Course identity;
* `installPublisherCourse(confirmUnverifiedAssociation:)`;
* or `close()` — Cancel, Audit block or error.

Each action may run once. It discards staging before it returns, so the
Copy/Fork Editor opens with no staged files, and `close()` is safe to call
again. `CourseEditorService` keeps the Course lock and persistence: the
package's media are materialized into the **destination** Course's folder
inside that Course's lock, and the existing single confirmation runs in the
same lock (`createIfAbsent` for a new import, `confirmCourseTransaction` for
Replace, Copy and Fork, and the Publisher installer). Nothing is written into
another Course's folder.

Recovery keeps the Build 245/246 rule: media created by the attempt are
removed only when storage proves they are unowned; an unreadable record keeps
them. Revision 0 keeps today's retention test for a custom import (retain
all created media when the stored Course uses any package medium).

## Revisions

* **Revision 0**: the owner, the lock boundary, destination-folder
  installation and the staging lifetime. Successful imports end in the same
  stored Course and the same media folders as today.
* **Revision 1, only if characterized as a defect**: narrow retention after a
  failed custom import to exactly the created files the stored Course uses,
  so a failed Replace leaves no unused files.
* **Manifest**: the package manifest lists shared-image provenance only for
  Exercise prompt images. Provenance elsewhere travels in `course.json`.
  Owner default: record this as a known limit and keep package format 1;
  changing it would make Build 246 and 247 refuse each other's packages.

## Proof

1. Characterization before the source change, with real temporary stores and
   a real ZIP: every route's stored record and media folders; Copy and Fork
   never writing into the same-ID Course; no media written while another
   operation holds the destination lock; staging empty when the Copy/Fork
   Editor opens and after Cancel, Audit block and failure; partial media write,
   save rejected before commit, post-commit error and unreadable recovery;
   and a manifest fixture with provenance on answer, layout, presentation,
   GuideBook and Course image library images. Record which assertions fail.
2. Add the owner and route the screen through it. Merge (Build 246) keeps its
   own right-package staging. `CoursePackage.withInstalledMedia`,
   `installImportedCustomCourse(course)` and
   `persistedCustomCourseReferencesAny` stay available for existing callers.
3. Focused tests, `flutter analyze`, the four asset validators, one full
   suite, version and release records, handoff, `git diff --check`, and one
   local commit.

Course Model v11, stored formats and keys, package format 1 and signatures,
authoring rights, scoring and progression, and the single top-level save
boundary remain unchanged.
