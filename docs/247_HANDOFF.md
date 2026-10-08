# Build 247 handoff

## Revision 1 current state

Build 247 Revision 1 is `2.0.47+247001`, Course Model v11, following
Revision 0 commit `eb16e21` on branch `claude/247-package-import` from `main`
`c543551`. The Beta expiry remains `2026-10-22 23:59:59` local time. The
untracked `devtools_options.yaml` is the owner's and stays untouched.

A failed custom package import now keeps the media it created only when the
stored Course uses **every** package medium — what a committed import leaves
behind — or when storage cannot be read. A Replace rejected before it commits
removes the files that attempt added and leaves the previous Course's own
media in place; a Replace that commits before a later error still keeps its
new media. `CourseEditorService.persistedCustomCourseReferencesAny`
implemented the replaced "any medium" test and had no caller left after
Revision 0, so it is removed and `_persistedCustomCourseUsesAll` is the one
rule. `CoursePackage.withInstalledMedia` and Copy/Fork recovery are unchanged.

Changed in Revision 1: `lib/services/course_editor_service.dart`,
`test/course_package_import_247_test.dart` (rewritten rejected-Replace test,
new committed-Replace test) and `test/course_storage_race_245_test.dart`
(now drives `CoursePackageImport`), plus `pubspec.yaml`,
`lib/services/app_metadata.dart` and its four version tests, `AGENTS.md`,
`README.md`, `CHANGELOG.md`, `docs/247_CHANGE_SUMMARY.md`,
`docs/247_VALIDATION.md` and this handoff.

Validation: 17/17 and 28/28 focused tests passed, the analyzer found no
issues, the four asset validators passed, and the complete Flutter suite
passed 2,293/2,293 on the final tree (19 min 28 s). `git diff --check`
passed. Evidence is in [247_VALIDATION.md](247_VALIDATION.md).

## Revision 0 state

Revision 0 is commit `eb16e21`, `2.0.47+247000`. `CoursePackageImport`
(`lib/services/course_package_import.dart`) owns one read package until the
import ends. `CourseProjectsScreen._importCourse` keeps file choice, Audit,
dialogs and results and calls one action.
`CourseEditorService.installImportedCustomCourse`, `createCopyAsNewCourse`
and `createFork` accept an optional `package` and write its media only into
the destination Course's folder under that Course's lock; the Publisher route
reuses `installExternalOfficialUpdate(package:)` unchanged. Every action
discards staging before returning, so a Copy or Fork opens its Editor with no
staged files. Its full suite passed 2,292/2,292 (18 min 50 s).

Before Revision 0, three service tests and the Copy widget test failed: media
written outside the Course lock, Copy and Fork writing package media into the
same-ID installed Course's folder, and staging surviving into the Copy's
Editor. The manifest fixture confirmed the prompt-only `sharedImageSources`
list, recorded as a known limit in `docs/COURSE_JSON_FORMAT.md`; package
format 1 is unchanged, so Builds 246 and 247 still accept each other's
packages.

## Known limits

* Course Manager widget tests time out waiting for file IO when run in
  parallel; run them with `--concurrency=1`, as the release gate does.
* Observed, not changed (Build 246 Merge scope): the Merge screen still
  installs the right package's media temporarily into `right.courseId`'s
  folder through `CoursePackage.withInstalledMedia`.
* An in-isolate per-Course lock does not coordinate external writers; this
  remains the documented Build 245 storage limit.
* Manual device smoke testing and a platform release artifact remain outside
  this source revision.

## Next boundary

Build 247 is complete unless its tests prove another correction necessary.
Push, PR and merge follow the owner's direction. Merge Build 247 before
starting Build 248 (Audio Library) in a new session from the then-current
`main`; read `AGENTS.md`, `pubspec.yaml`, this handoff and the
[approved architecture roadmap](ARCHITECTURE_ROADMAP_246_PLUS.md) first, then
write the Build 248 contract and characterization tests before moving the
ownership of newly imported recordings and their cleanup.
