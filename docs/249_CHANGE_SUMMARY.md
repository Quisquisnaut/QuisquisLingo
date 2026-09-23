# Build 249 change summary

## Revision 0

`2.0.49+249000` — Build 249, Revision 0, Course Model v11.
Plan: [249_LIBRARY_OPERATIONS_PLAN.md](249_LIBRARY_OPERATIONS_PLAN.md).
Evidence: [249_VALIDATION.md](249_VALIDATION.md).

### What changed

Course Manager's workflow has one owner. Nothing a user sees has changed.

The storage operations Course Manager calls already had owners: importing a
package (`CoursePackageImport`, Build 247), confirming a merge
(`confirmMergedCourse`, Build 246), and Copy as New Course, Fork, Delete and
Publisher removal on `CourseEditorService`. What had no owner was the workflow
around them, which sat inside `CourseProjectsScreen` and could only be reached
by driving the widget:

* which Courses are listed, for whom, and whether the profile is an admin;
* which menu actions each Course offers;
* the titles of copies (`<title> copy`, `<title> copy 2`, …) and merges;
* where a Fork of an official Course takes its immutable source;
* composing a merge and refusing it on Audit errors;
* what an import may do: refuse a Bundled package, block on Audit errors,
  associate an unverified Publisher version, and which of Copy, Fork and
  Replace a matching Course ID allows;
* the Audit notice attached to an export;
* building the New Course from the create dialog's values;
* the result messages.

`CourseLibraryOperations` (`lib/services/course_library_operations.dart`) now
owns all of it. `load` returns a `CourseManagerLibrary` snapshot that answers
the pure questions (`actionsFor`, `capabilitiesFor`, `nextCopyTitle`,
`nextMergeTitle`, `hasCourseTitled`); the operations act on **stored** Courses
only; `CourseLibraryReports` holds the exact texts shown before.

The screen keeps its layout, every dialog and its wording, file pickers,
navigation and SnackBars. It still calls `CoursePackageImport` for the chosen
import action, so Build 247's single-attempt ownership is untouched.
`course_projects_screen.dart` shrinks from 2,677 to about 2,480 lines, and its
largest method, the New Course dialog, no longer builds the Course itself.

### Preserved

Course Model v11, stored formats and keys, package format 1 and signatures,
authoring rights, scoring and progression, the single top-level confirmed
Course save and the Course Editor working-copy invariant. No format or
compatibility change.

### Found, deliberately not changed here

* **A failed Delete is silently lost.** The error escapes the menu callback and
  nothing is shown. Proven by a characterization test, skipped in this
  revision, and fixed in Revision 2 at the owner's request.
* **Copy and merge titles avoid only the listed titles**, which are the active
  profile's personal-library Courses, not every Course on the device.
  Duplicate titles are allowed, so this is recorded rather than changed.

### Files

Source: `lib/services/course_library_operations.dart` (new),
`lib/screens/course_projects_screen.dart`.

Tests: `test/course_manager_workflow_249_test.dart` (new, 18 tests, one
skipped), `test/course_library_operations_249_test.dart` (new, 28 tests),
`test/course_metadata_ui_v9_test.dart` and
`test/imported_course_v6_regression_test.dart` (two source-text checks on the
screen replaced by behaviour checks on the owner).

Release: `pubspec.yaml`, `lib/services/app_metadata.dart`,
`lib/services/beta_lifecycle_service.dart` and their tests
(`app_metadata_225_04`, `course_audit_report_225`, `qql_229_revision3`,
`qql_233_revision_platform_contract`, `beta_lifecycle`,
`leaderboard_navigation`), `AGENTS.md`, `README.md`, `CHANGELOG.md`,
`docs/ARCHITECTURE_ROADMAP_246_PLUS.md` and the Build 249 documents.

The roadmap also records the owner's design decisions for the later two-tab
Courses screen (track steps 3 and 4), taken during this build; none of them is
implemented here.
