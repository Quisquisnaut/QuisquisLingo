# Build 247 — Package Import workflow change summary

## Revision 1 — cleanup after a failed custom import

Version **2.0.47+247001**. Beta expiry remains **2026-10-22 23:59:59
local**, 30 days from the 22 September 2026 release date.

Revision 0 kept the Build 245 retention test: after a failed custom import,
the media it created stayed whenever the stored Course used **any** package
medium. A Replace whose save was rejected before it committed met that test
through the media the previous version already used, so the new files that
attempt had added stayed in the Course folder unused until that Course's next
confirmed save. Revision 0's characterization test pinned this.

The rule is now: keep the created media when the stored Course uses **every**
package medium — the state a committed import leaves — or when storage cannot
be read. A rejected Replace removes exactly the files that attempt created and
never touches media that existed before it, and a Replace that commits before
a later error still keeps its new media. `persistedCustomCourseReferencesAny`
had no caller left after Revision 0 moved import ownership, and is removed
with the rule it implemented, so one rule decides this question.

Course Model v11, stored formats and keys, package format 1 and signatures,
authoring rights, scoring and progression, and the single top-level Course
save boundary are unchanged.

## Revision 0 — one owner for a Course package import

Version **2.0.47+247000**. Beta expiry: **2026-10-22 23:59:59 local**,
30 days from the 22 September 2026 release date.

`CoursePackageImport` (`lib/services/course_package_import.dart`) now holds
one read Course package from reading until the import attempt ends. Course
Manager still reads the file, shows the Audit, the Publisher and Matching
Course ID dialogs and the result, and chooses the route. It then calls one
action: install a custom Course (new or Replace / update), Copy as New
Course, Fork, install a Publisher Course, or close. Each action runs once
and discards the staged media as soon as the installation ends.

`CourseEditorService.installImportedCustomCourse`, `createCopyAsNewCourse`
and `createFork` accept the package. They write its media into the
destination Course's own folder and save the Course under one hold of that
Course's lock. The Publisher installer already worked this way and is reused
unchanged.

What changed for the files on disk:

* A custom import previously wrote its media before and outside the Course
  lock. Now another operation holding that Course is never interleaved with
  the import's media writes.
* Copy as New Course and Fork from an import previously wrote the package's
  media temporarily into the **same-ID installed Course's** folder, copied
  them to the new Course, and then deleted them again. They now go straight
  into the new Course's folder; the installed Course's folder is untouched.
* After Copy or Fork, the staged package files previously stayed on disk
  while the new Course's Editor was open. They are removed before that Editor
  opens.

Successful imports end with the same stored Course and the same media
folders as before. Failure recovery keeps the established rule: media this
attempt created are removed only when storage proves no stored Course uses
them; an unreadable record keeps them. The custom-import retention test is
unchanged: created media stay when the stored Course uses any package
medium, so a Replace rejected before it commits can leave an unused new file
until that Course's next confirmed save. Revision 0 keeps that behavior; a
characterization test pins it for a separate correction.

The package manifest lists shared-image provenance only for images in
Exercise prompts. A fixture confirmed that answer, layout, presentation,
GuideBook and Course image library provenance is absent from the manifest
but travels intact in `course.json`, and the package still imports. On the
owner's default, this is a known limit; package format 1 is unchanged, so
Builds 246 and 247 still accept each other's packages.

Course Model v11, stored formats and keys, package format 1 and signatures,
authoring rights, scoring and progression, Merge (Build 246), and the single
top-level Course save boundary are unchanged. See
[247_PACKAGE_IMPORT_PLAN.md](247_PACKAGE_IMPORT_PLAN.md),
[247_VALIDATION.md](247_VALIDATION.md) and [247_HANDOFF.md](247_HANDOFF.md).
