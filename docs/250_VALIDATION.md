# Build 250 validation

## Revision 0 — Courses screen and learner visibility

`2.0.50+250000`, Course Model v11, 23 September 2026, on
`codex/build-250-courses`. The starting `HEAD`
and `main` were both merge `a412c736671d6d1616228accd7a25700eb8319b5`,
Build 249 Revision 2 (`2.0.49+249002`). The current repository tree was used;
no older archive was restored, and `devtools_options.yaml` was left untouched.
Scope and decisions: [250_COURSES_SCREEN_PLAN.md](250_COURSES_SCREEN_PLAN.md).
Behavior: [250_CHANGE_SUMMARY.md](250_CHANGE_SUMMARY.md).

### Focused evidence

* The new Courses screen, Favorite/Hide services, received-update path and
  release metadata: `flutter test test/courses_screen_250_test.dart
  test/course_learner_visibility_250_test.dart
  test/course_favorite_service_250_test.dart
  test/received_custom_course_250_test.dart
  test/app_metadata_225_04_test.dart test/course_audit_report_225_test.dart
  --concurrency=1 --no-pub`: **34 passed**. This includes an import-return
  check that clears a Search filter and turns Show unavailable back on when
  the imported Course needs it, and fault-injection checks around received
  Course pre- and post-commit failures.
* `flutter test test/course_package_import_ui_247_test.dart
  --concurrency=1 --no-pub`: **4 passed**. Copy installs its media and closes
  staging without opening the Editor; a locked matching-ID Import greys Copy
  and Fork while leaving an authorized Replace available; Cancel writes
  nothing and closes staging. A 320×568 viewport first exposed a 136-pixel
  dialog overflow; the explanations now scroll within the dialog, and the
  Replace button remains hit-testable at that size.
* The isolated Selector Hide and direct Import case passed after its test
  fixture used the existing `_loadCourse(tester, 'DE')` helper for async asset
  loading. The original new test had awaited `CourseService.loadCourse`
  directly in a widget test and stalled before entering Home. No production
  change was needed for that test setup correction.
* The received-Course and adjacent import, library operations, reset and
  inventory suites passed **95 tests** in a serial affected-file run. See the
  received-update fault cases in `test/received_custom_course_250_test.dart`.
* After independent review, `flutter test test/courses_screen_250_test.dart
  test/received_custom_course_250_test.dart --concurrency=1 --no-pub` passed
  **20 tests**. The added cases check readable Favorite popup actions, one
  Manager status label, and preserved creator and origin provenance for a
  received update.
* A further direct received-update test first accepted an unavailable World
  Flag, then rejected it after the matching pre-write validation was added.
  A changed assigned Team ID likewise passed before its preserving check and
  was rejected afterward. `flutter test test/received_custom_course_250_test.dart
  test/course_library_operations_249_test.dart --concurrency=1 --no-pub`:
  **51 passed**; targeted Flutter analysis found no issues.
* The full-suite run then exposed narrow All Courses trailing controls in two
  existing Build 244 tests. Changing that action group from Row to Wrap kept
  both controls and their keys. `flutter test
  test/course_library_compact_244_test.dart
  test/course_library_rows_244_test.dart test/courses_screen_250_test.dart
  --concurrency=1 --no-pub`: **20 passed**.
* Legacy test expectations were updated for the approved Build 250 screen and
  import flow, without changing production behavior: the Course Library
  screen file passed **9/9**, Home/Library **8/8**, and Course Manager workflow
  **19/19**. They check the new count and Help wording, tab entry, shared
  status badges, disabled Import choices and import result returned to its
  opener.
* The Audit report test file passed **7/7** in isolation after a Dart VM heap
  exhaustion while loading it during a resource-contended exploratory full
  run. Its release metadata assertions match Build 250.
* `flutter test test/inventory_239_test.dart --concurrency=1 --no-pub` passed
  **9 tests**, including the new learner-owned Favorite flag inventory case.
* `flutter test test/qql_233_revision_platform_contract_test.dart
  test/qql_229_revision3_test.dart --concurrency=1 --no-pub`: **14 passed**
  after updating their release-version assertions from Build 249 to Build
  250. The first full-suite attempt was stopped before reaching these files.

### Static and asset checks

* `flutter analyze --no-pub`: **No issues found.** The preceding run found
  one context-after-await lint and one unnecessary test null assertion;
  both were corrected before the clean run. A repeat after the independent
  review corrections also found no issues.
* `python tools/validate_courses.py`: 10 bundled Course Model v11 files OK.
* `python tools/validate_images.py`: 111 assets, 0 issues.
* `python tools/validate_lesson_icons.py`: 14 assets, 0 issues.
* `python tools/validate_media_assets.py`: 443 files, 0 issues.

### Full release gate

Exploratory serial runs exposed stale version/UI assertions and the narrow
layout defects above; each was corrected and checked in its focused file.
One exploratory run also had a Flutter tester heap exhaustion; the failed
Audit report file passed **7/7** alone. The settled source then passed an
uninterrupted solo run:

`flutter test --no-pub --concurrency=1 --reporter expanded` — **2,402 passed,
0 failed** (26 minutes 6 seconds; exit 0). No other Flutter job was running.

The final `flutter analyze --no-pub` reported **No issues found** (exit 0).
All four asset validators above also passed again on the settled tree.
`git diff --check` and `git diff --cached --check` both exited 0. The staged
file list contains only Build 250 source, tests, release metadata and the
specified documents; no generated registry or `devtools_options.yaml` was
staged, and there is no unstaged diff. The Revision 0 local commit on
`codex/build-250-courses` uses subject **Build 250 Revision 0: Courses screen
and learner visibility**.

### Preserved boundaries and known limit

Course Model v11, package format 1, Publisher signatures, scoring,
progression, authoring rights and the Course Editor's top-level confirmation
remain unchanged. The received Custom Course marker is separate from the
Course file. A process crash in the small interval after writing the marker
and before creating the Course file could leave a harmless stale marker;
caught pre-commit failures clear it, and the next import under that ID
reconciles it from actual ownership. Unsigned Custom updates retain the
accepted impersonation risk documented in the plan and change summary.
