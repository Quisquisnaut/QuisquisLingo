# Build 249 — Course library operations owner plan

Status: pre-approved by the owner on 2026-09-23 as step 2 of the
"Second track: one Course library screen" in the approved
[architecture roadmap](ARCHITECTURE_ROADMAP_246_PLUS.md). The owner asked for
one local commit per revision, no separate contract checkpoint, and a new
revision only for a substantial fix proven by its own failing test.
Baseline: `main` `fbdb825`, `2.0.48+248003` (Build 248, Revision 3),
Course Model v11.

**Scope is track step 2 only.** The two screens are not merged (step 3) and
Hide in Learner is not added (it ships with the merge).

## What happens today

Course Manager is `CourseProjectsScreen` in
`lib/screens/course_projects_screen.dart` (2,677 lines). The **storage**
operations it calls already have owners:

| Operation | Owner |
| --- | --- |
| Import a package (custom install, Replace, Copy, Fork, Publisher install) | `CoursePackageImport` (Build 247) |
| Confirm a merged Course | `CourseEditorService.confirmMergedCourse` (Build 246) |
| Copy as New Course, Fork, Delete, remove a Publisher Course | `CourseEditorService.createCopyAsNewCourse`, `createFork`, `deleteUserCourse`, `removePublisherCourseFromDevice` |
| Find the immutable official source of an official Course | `CourseEditorService.officialSourceFor` |
| Personal library membership | `CourseLibraryService` |
| Package export | `CustomCourseTransferService.exportCourse` / `exportCourseTo` |

The **workflow around them** has no owner. It sits in the screen's state
class, reachable only by driving the widget:

1. **Loading** — which Courses the Manager lists (the personal-library Custom
   and Publisher Courses, and the included Bundled Courses with the current
   Course substituted), which files were unreadable, the active profile, its
   Teams, whether it is an admin, and whether import-time authoring is
   unlocked in import-only mode.
2. **Which action is offered for which Course** — the eleven-entry popup menu
   decides from `CourseAccessPolicy.evaluate`, origin type and admin status.
3. **Title generation** — `_nextCopyTitle` (`<title> copy`, `<title> copy 2`,
   …) and `_nextMergeTitle` (`<title> merged`, …), both against the titles the
   Manager currently lists.
4. **Fork source resolution** — an official Course is forked from its
   immutable official source (the bundled asset for a Bundled Course, the
   stored signed source for a Publisher Course), refused when unavailable.
5. **Merge composition** — compose the merged Course, refuse it when the Audit
   finds errors, warn when it finds warnings, then confirm.
6. **Import review** — refuse a Bundled Course package, run the Audit, block on
   errors, decide the Publisher route and whether an unverified existing
   version needs association, and for a matching custom Course ID decide which
   of Copy as New Course, Fork and Replace / update are offered.
7. **Export** — attach the Audit's export notice to the fixed-folder and
   Save to… routes.
8. **Audit** — check the World Flag reference, then audit.
9. **New Course** — build the scaffolded Draft Course from the create dialog's
   values: credits and roles, Rights Holders, license and derivative policy,
   speech language, the Lessons and Rounds, and the timestamps.
10. **Result reporting** — the confirmation, import, Publisher install and
    export messages.

`AvailableCoursesScreen` (662 lines) is the model: presentation over
`CourseLibraryService` and `CourseLibraryPresentation`.

## Owner and contract

A new `CourseLibraryOperations` (`lib/services/course_library_operations.dart`)
owns that workflow. It holds no widget state and never shows a dialog.

* **`load({currentCourse, importOnly})`** returns an immutable
  **`CourseManagerLibrary`** snapshot holding exactly what `_reload` gathers
  today, including the unreadable files. The snapshot answers the pure
  questions:
  * `capabilitiesFor(course)` — `CourseAccessPolicy.evaluate` with the
    snapshot's profile and Teams, as `_capabilities` does now.
  * `actionsFor(course)` — the ordered `CourseManagerAction`s the menu offers.
  * `nextCopyTitle(title)` and `nextMergeTitle(title)`.
  * `hasCourseTitled(title)` — the New Course duplicate-name warning.
* **`copyAsNewCourse(course, library)`** and **`fork(course)`** return the
  `CourseConfirmationResult` of the new stored Course. Fork resolves the
  official source exactly as today.
* **`composeMerge(...)`** returns a **`CourseMergeProposal`** (the merged
  Course and whether the Audit found warnings) or throws the existing
  "Course Audit found N errors" refusal; **`confirmMerge(...)`** calls
  `confirmMergedCourse`. The screen shows the warning dialog in between, so a
  closed screen still stops the merge where it does today.
* **`reviewImport(attempt, library)`** returns a **`CourseImportReview`**:
  the Course, its Audit errors and warnings, the existing same-ID Course, the
  Publisher association flag and the offered collision choices. It throws the
  existing Bundled-package refusal. A copy made from an import is named by the
  snapshot's `nextCopyTitle`. The screen keeps every dialog and still calls
  `CoursePackageImport` for the chosen action, so Build 247's single-attempt
  ownership is untouched.
* **`exportCourse`** / **`saveCourseTo`** return the path or dialog result with
  the Audit export notice. **`deleteCourse`**, **`removePublisherCourse`** and
  **`audit`** wrap their existing service calls.
* **`newCourse(...)`** builds the Draft Course from already-validated dialog
  values, with an injected clock instead of the screen's `DateTime.now()`.
  Field validation, its order and its messages stay in the dialog.
* Static **report** functions produce the exact message texts shown today.

**Stays in the screen:** every dialog and its wording (the double delete
confirmation, the Publisher removal confirmation, the import blocked /
Publisher / matching-ID dialogs, the merge warning), file pickers, navigation
to the Editor, Merge, Export, Audit, Team Manager and Shared Images screens,
SnackBars, and `removeFromMyCourses`, which is already a shared confirmation
over `CourseLibraryService`.

**Unchanged:** `CoursePackageImport`, `CourseEditorService`,
`CourseMergeService`, `CourseAccessPolicy`, `CustomCourseTransferService`,
`CourseLibraryService`, their contracts and every stored format. No second
persistence path, no second Course copy and no second import owner.

## Proof

1. **Characterization first**, against unchanged code, at the real boundary:
   the real Course Manager screen over the real Course store and Course media
   folder in each test's own temporary directories, the real bundled assets,
   and failures injected by a `CourseFileStore` subclass that throws on the
   storage call, the pattern Build 247 used.
   `test/course_manager_workflow_249_test.dart` records which assertions fail.
2. **Implement the owner** and reduce the screen to presentation and
   confirmation. Every characterization test must still pass unchanged.
3. **Prove the owner stands alone**:
   `test/course_library_operations_249_test.dart` reaches every operation
   without building a widget.
4. Focused tests, `flutter analyze --no-pub`, the four asset validators, one
   complete suite at `--concurrency=1`, version and release records, handoff,
   `git diff --check`, and one local commit.

### Expected characterization results

| Test | Before |
| --- | --- |
| The menu offers the right actions for a maintained Custom, an outsider's Custom, a Bundled and a Publisher Course (admin and not) | passes |
| Copy as New Course stores `<title> copy`, then `<title> copy 2`, reports the confirmation and opens the copy | passes |
| Fork of an outsider's Custom Course records the source and makes the active profile Maintainer | passes |
| Fork of a Bundled Course forks the bundled source | passes |
| Delete asks twice; Keep course keeps it, Delete permanently removes the record and media folder | passes |
| A failing Copy as New Course reports the error and stores nothing | passes |
| A failing Delete reports the error and keeps the Course listed | **expected to fail** — the error escapes the menu callback and nothing is shown |
| Export writes the package and reports its path | passes |
| Removing a Publisher Course another profile still uses is refused with a message | passes |
| A matching Course ID offers Copy, Fork and Replace exactly per rights and unlock | passes |
| Merge names the result `<title> merged` | passes |

A failing expectation is **not** fixed in Revision 0. Revision 0 must keep
behaviour identical, so any test that fails before the extraction must fail
the same way after it, and is then corrected in its own revision.

## Revisions

* **Revision 0**: the owner, the snapshot, and the screen reduced to
  presentation and confirmation. Behaviour identical.
* **Revision 1, requested by the owner on 2026-09-23**: the Course Manager
  menu shows unavailable entries **greyed out with a short reason line**
  instead of hiding them. Entries that depend on rights, license or admin
  status are greyed out; entries that can never apply to that kind of Course
  (for example Remove Publisher Course from device on a Custom Course, or
  Merge on an official Course) stay hidden. A behaviour change, so it follows
  the extraction in its own revision and updates the menu characterization
  test on purpose.
* **Revision 2, confirmed by the owner on 2026-09-23**: report a failed
  Delete instead of letting the error escape, and keep the Course listed.
  Proven by the characterization failure above, whose skip is removed in that
  revision; kept separate from the extraction.

## Preserved

Course Model v11, stored formats and keys, package format 1 and signatures,
authoring rights, scoring and progression, the Audit, the single top-level
confirmed Course save and the Build 248 Course Editor working-copy invariant
all remain unchanged. No format or compatibility change is proposed; the owner
will be asked before any is.

## Known limits recorded by this build

* Copy and merge titles avoid only the titles the Manager lists, which are the
  active profile's personal-library Courses, not every Course on the device.
  Duplicate titles are allowed, so this is recorded rather than changed.
* `CourseProjectsScreen._openUser` opens the Editor with a default
  `CourseEditorService` rather than the injected one; tests that open an
  existing Course's Editor therefore use the default storage paths. Recorded,
  not changed.
