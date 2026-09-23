# Build 249 validation

## Revision 0

`2.0.49+249000` — Build 249, Revision 0, Course Model v11, branch
`claude/249-library-operations` from `main` `fbdb825`.
Plan: [249_LIBRARY_OPERATIONS_PLAN.md](249_LIBRARY_OPERATIONS_PLAN.md).
Change summary: [249_CHANGE_SUMMARY.md](249_CHANGE_SUMMARY.md).

### 1. Characterization before the source change

`test/course_manager_workflow_249_test.dart` was written first and run against
unchanged code on `flutter test --no-pub --concurrency=1`. Result:
**17 passed, 1 failed**, matching the plan's predicted table.

| Test | Before | After the extraction |
| --- | --- | --- |
| Menu per Course kind, rights and admin status | passed | passed |
| A non-admin is not offered Publisher removal | passed | passed |
| Copy stores `<title> copy`, reports it and opens the copy | passed | passed |
| Copy counts past a listed copy title (`copy 2`) | passed | passed |
| Copy avoids only personal-library titles (known limit) | passed | passed |
| A failing Copy is reported and stores nothing | passed | passed |
| Fork of an outsider's Custom Course records its source | passed | passed |
| Fork of a Publisher Course forks the stored signed source | passed | passed |
| Delete asks twice and removes the record and media folder | passed | passed |
| **A failing Delete is reported and keeps the Course listed** | **failed** | **failed identically; skipped** |
| Export writes the package and reports its path | passed | passed |
| Publisher removal refused while another profile uses it | passed | passed |
| Publisher removal when nobody else uses it | passed | passed |
| A new imported Course is installed and reported | passed | passed |
| Maintainer's matching ID offers Copy and Replace | passed | passed |
| Locked import-only mode offers no Copy or Fork | passed | passed |
| Outsider's matching ID offers only Fork | passed | passed |
| Merge names the result `<title> merged` | passed | passed |

Every test drives the real `CourseProjectsScreen` over the real Course store,
the real `CourseMediaStore` and the real bundled assets in the test's own
temporary folders. Storage failures are injected by a `CourseFileStore`
subclass that throws on `createIfAbsent` or `removeIfUnchanged`, the pattern
Build 247 used.

The Delete failure: `_delete` is started from the popup menu's `onSelected`
without being awaited, and has no `try`/`catch`, so the storage error escapes
as an uncaught `Bad state` and no message appears. Revision 0 keeps that
exactly; the test is skipped with its reason and becomes Revision 2's proof.

### 2. The owner on its own

`test/course_library_operations_249_test.dart`: **28 passed**. It reaches
load, the menu decisions, titles, Copy, Fork (including the refusal when an
official source is unavailable), Merge (composing writes nothing), import
review, Export, Audit, Delete, Publisher removal, New Course and the report
texts, without building a widget.

### 3. Focused regression

Every existing test file that builds Course Manager, Merge, Export or Import
screens (22 files): **226 passed, 1 skipped, 0 failed**.

A first run of the same set reported 2 failures. It overlapped the version
bump: `leaderboard_navigation_test.dart` and `qql_229_revision3_test.dart`,
both in that set, were edited while it ran. The rerun on the settled tree
passed, and the complete suite below is the authoritative result.

### 4. Release gate

* `flutter analyze --no-pub`: **No issues found.**
* `tools/validate_courses.py`: 10 bundled Course Model v11 files OK.
* `tools/validate_images.py`: 111 assets, 0 issues.
* `tools/validate_lesson_icons.py`: 14 assets, 0 issues.
* `tools/validate_media_assets.py`: 443 files, 0 issues.
* Complete suite, `flutter test --no-pub --concurrency=1 --reporter
  expanded`: **2,353 passed, 1 skipped, 0 failed** in 29 min 19 s. The
  skipped test is the known Delete failure.
* `git diff --check`: clean.

The first complete run (27 min 58 s) reported **2,351 passed, 1 skipped,
2 failed**. Both failures were source-text tests that read
`course_projects_screen.dart` and looked for code the extraction moved into
the owner, not changes in behaviour:

* `course_metadata_ui_v9_test.dart` "Create Course exposes structured Rights
  Holder editing" searched for `CourseRightsHolder(` and
  `rightsHolders: rightsHolders`;
* `imported_course_v6_regression_test.dart` "Course Manager classifies its
  current course by declared origin" searched for the current-Course
  substitution.

As `AGENTS.md` requires for a moved responsibility, both now check the same
rule by behaviour: `CourseLibraryOperations.newCourse` builds only the
non-empty, trimmed Rights Holders with their types, and
`CourseLibraryOperations.load` substitutes the current Course only when its
declared origin is Bundled. The first test keeps its checks of the dialog's
wording and keys, which stay in the screen. Both files then passed in
isolation, the analyzer was rerun, and the complete suite above was run again
on the final tree.

### 5. Version

`pubspec.yaml` and `AppMetadata` are `2.0.49+249000`, Build 249, Revision 0.
The Beta expiry is recalculated from this release's date, 23 September 2026:
`2026-10-23 23:59:59` local time, one day later than Build 248's.
