# Build 247 handoff

## Revision 0 current state

Build 247 Revision 0 is `2.0.47+247000`, Course Model v11, on branch
`claude/247-package-import` from `main` `c543551` (`2.0.46+246001`). The
Beta expiry remains `2026-10-22 23:59:59` local time (30 days from the
22 September 2026 release date). The untracked `devtools_options.yaml` is the
owner's and stays untouched.

The owner approved the plan in
[247_PACKAGE_IMPORT_PLAN.md](247_PACKAGE_IMPORT_PLAN.md) on 2026-09-22 and
asked for one local commit per revision (no push or PR unless asked), no
approval checkpoint, and a new revision for a substantial fix. Manifest
decision: record the prompt-only `sharedImageSources` list as a known limit;
package format 1 unchanged.

`CoursePackageImport` (`lib/services/course_package_import.dart`) owns one
read package until the import ends. `CourseProjectsScreen._importCourse`
keeps file choice, Audit, dialogs and results and calls one action.
`CourseEditorService.installImportedCustomCourse`, `createCopyAsNewCourse` and
`createFork` accept an optional `package` and write its media only into the
destination Course's folder under that Course's lock; the Publisher route
reuses `installExternalOfficialUpdate(package:)` unchanged. Every action
discards staging before returning. `CoursePackage.withInstalledMedia`,
`installImportedCustomCourse(course)` without a package and
`persistedCustomCourseReferencesAny` remain for their other callers.

Tests: `test/course_package_import_247_test.dart` (16) and
`test/course_package_import_ui_247_test.dart` (2). Before the change, three
service tests and the Copy widget test failed; results are in
[247_VALIDATION.md](247_VALIDATION.md). Release records: `pubspec.yaml`,
`lib/services/app_metadata.dart` and its four version tests, `AGENTS.md`,
`README.md`, `CHANGELOG.md`, `docs/COURSE_JSON_FORMAT.md` (manifest known
limit), `docs/247_CHANGE_SUMMARY.md` and `docs/247_VALIDATION.md`.

Validation: the focused suites, the analyzer and the four asset validators
passed, and the complete Flutter suite passed 2,292/2,292 on the final tree
(18 min 50 s). `git diff --check` passed. Evidence is in
[247_VALIDATION.md](247_VALIDATION.md).

## Known limits

* A failed custom import keeps every file it created when the stored Course
  uses any package medium (`persistedCustomCourseReferencesAny`). A Replace
  rejected before it commits therefore leaves an unused new file until that
  Course's next confirmed save. Pinned by the test "a Replace rejected before
  commit keeps the previous Course and its media".
* Course Manager widget tests time out waiting for file IO when run in
  parallel; run them with `--concurrency=1`, as the release gate does.
* Observed, not changed (Build 246 Merge scope): the Merge screen still
  installs the right package's media temporarily into `right.courseId`'s
  folder through `CoursePackage.withInstalledMedia`.
* Manual device smoke testing and a platform release artifact remain
  outside this source revision.

## Next step

Revision 1 (`2.0.47+247001`): narrow the failed custom-import retention to
keep created media only when the stored Course uses **all** package media
(i.e. the import itself committed) or storage is unreadable, so a rejected
Replace removes the new files it created. Flip the pinned test, then
version, records, full suite, handoff and one commit. After Build 247 is
merged, Build 248 (Audio Library) starts in a new session from `main`.
