# Build 250 validation

## Revision 1 — Course Studio and Courses layout

`2.0.50+250001`, 24 September 2026, on `codex/build-250-courses` from
Revision 0 commit `c08ecf6`. Beta expiry: `2026-10-24 23:59:59` local time.
The owner approved the soft amber Favorites treatment, the Course Studio
name, a Search icon on both tabs, Studio-only New course, separate tab Help,
one-line Sort by / Show unavailable controls, right-edge Course menus,
neutral gray Other Local Courses borders, Course Info in the Studio menu and
an enlarged cover/flag popup in both tabs.
Course Model v11, package format 1, preferences, rights, scoring, progression
and the Course Editor confirmation remain unchanged.

### Focused behavior and metadata evidence

* New row-layout and Course Studio Favorites/search widget tests first failed
  against Revision 0. After implementation, the row-layout file passed **4/4**,
  the Studio Favorites file **4/4**, and the Courses screen file **9/9**.
  The updated Courses test checked the Search field below Sort and no overflow
  at 320 px. An initial Favorites menu test used `pageBack()` on a popup;
  sending Escape fixed the test navigation without a production change.
* A Build 244/249 affected-file run passed **90 of 91** tests. The remaining
  empty-library test looked for the third Studio section while the new
  Favorites section pushed it below the lazy ListView viewport. It now checks
  the visible first empty section, and its isolated rerun passed.
* The Course Studio rename first failed the new `COURSE STUDIO` tab assertion.
  These focused runs then passed **66/66** across navigation, Help and nearby
  screens:
  `flutter test test/courses_screen_250_test.dart
  test/editor_help_translation_test.dart test/course_library_screen_244_test.dart
  test/info_page_translation_test.dart --no-pub --concurrency=1
  --reporter expanded` (**34/34**) and `flutter test
  test/course_creation_flags_226_04_test.dart
  test/course_editor_layout_regression_test.dart
  test/unreadable_stored_courses_243_test.dart
  test/course_package_import_ui_247_test.dart
  test/settings_profile_reorganization_228_01_test.dart --no-pub
  --concurrency=1 --reporter expanded` (**32/32**).
* Version `250001` and the 24 October Beta expiry first failed their updated
  assertions against Revision 0. `flutter test
  test/app_metadata_225_04_test.dart test/beta_lifecycle_test.dart
  test/qql_233_revision_platform_contract_test.dart --no-pub
  --concurrency=1 --reporter expanded` then passed **11/11**.
* The current Info page still described Editor actions and Help from an older
  build. Its new Course Studio Help assertion failed before the EN/IT text was
  corrected. `flutter test test/info_page_translation_test.dart --no-pub
  --concurrency=1 --reporter expanded` passed **6/6** afterward.
* Course Info is an always-available Course Studio menu entry, including for
  Courses without authoring rights. Its service and navigation suites passed
  **57/57**: `flutter test --no-pub --concurrency=1 --reporter expanded
  test/course_library_operations_249_test.dart
  test/course_manager_workflow_249_test.dart`.
* The new shared artwork tests first failed because row artwork had no opener.
  After adding the popup, the focused test file passed **3/3**: `flutter test
  --no-pub test/course_artwork_preview_250_test.dart --reporter expanded`.
  They cover an uncropped enlarged cover, the Studio flag without Editor
  navigation, a missing cover's flag fallback and a 320-pixel-wide viewport.

### Static and asset checks

* `flutter analyze --no-pub`: **No issues found** on the settled revision.
* `dart format --output=none --set-exit-if-changed` on the 40 changed Dart
  files: **0 files needed formatting** after applying the formatter.
* `python tools/validate_courses.py`: **10** bundled Course Model v11 files OK.
* `python tools/validate_images.py`: **111** assets, **0** issues.
* `python tools/validate_lesson_icons.py`: **14** assets, **0** issues.
* `python tools/validate_media_assets.py`: **443** files, **0** issues.

### Release gate

The first final-suite attempt was stopped when the format check found two
files needing formatting. After formatting, the settled tree passed the
uninterrupted serial release run:

`flutter test --no-pub --concurrency=1 --reporter expanded` — **2,417 passed,
0 failed** (33 minutes 18 seconds; exit 0). The temporary Windows
`ES_CONTINUOUS | ES_SYSTEM_REQUIRED` request used during this long run was
cleared when it ended. `flutter analyze --no-pub` found no issues; all four
asset validators above passed on the same source. Revision 1 is a source
release; no Windows package was requested or created.
`git diff --check` and `git diff --cached --check` exited 0. The staged file
list contains only Revision 1 source, tests, metadata and documents; four
pre-existing generated plugin registrant changes remain unstaged.

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
