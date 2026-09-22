# Build 247 validation

## Revision 0 — Package Import workflow (`2.0.47+247000`)

Validated on 22 September 2026 against the Build 247 Revision 0 working tree.

### Characterization before the source change

The new tests were first run against the unchanged import composition (the
exact calls `CourseProjectsScreen._importCourse` made).

| Test | Result on the old code |
| --- | --- |
| `test/course_package_import_247_test.dart` (12 route tests at that point) | 9 passed, 3 failed. **Failed:** a new custom import wrote its media while another operation held that Course's lock; Copy as New Course and Fork wrote the package's media into the same-ID installed Course's folder. **Passed:** new install, partial media write, rejection before commit, post-commit error, unreadable recovery check, successful Replace, Replace rejected before commit (keeps an unused new file), rejected Copy, manifest fixture. |
| `test/course_package_import_ui_247_test.dart` | Copy failed: one staged `.part` file was still in `qql_import_staging` when the Copy's Course Editor opened. Cancel on Matching Course ID passed. |
| Manifest fixture | Confirmed: only the Exercise prompt image is listed in `sharedImageSources`; answer item, layout, presentation, GuideBook and Course image library provenance is absent from the manifest, present in `course.json`, and the package imports unchanged. Recorded as a known limit. |

### After the change

| Check | Result |
| --- | --- |
| `flutter test test/course_package_import_247_test.dart test/course_package_import_ui_247_test.dart` | 18/18 passed: the 12 route tests, 4 import-attempt tests (single use, close without writing, mismatched package refused before any write, Publisher install with staging cleared) and 2 widget tests. |
| Existing import, Publisher, Merge, storage-race, persistence, draft-promotion and editor-transfer suites (15 files) | All passed. Parallel execution timed out three Course Manager widget files (5 tests) waiting for file IO; rerun with `--concurrency=1`, `publisher_import_ui_test.dart`, `qql_230_course_persistence_hardening_test.dart` and `course_editor_layout_regression_test.dart` passed 21/21. |
| Version tests (`app_metadata_225_04`, `course_audit_report_225`, `qql_229_revision3`, `qql_233_revision_platform_contract`, `beta_lifecycle`, `package_naming_regression`) | 28/28 passed with `--concurrency=1`. |
| `flutter analyze --no-pub` | No issues found. |
| `python tools/validate_courses.py` | 10 bundled Course Model v11 files valid. |
| `python tools/validate_images.py` | 111 assets; 0 issues. |
| `python tools/validate_lesson_icons.py` | 14 assets; 0 issues. |
| `python tools/validate_media_assets.py` | 443 files; 0 issues. |
| Complete `flutter test --no-pub --concurrency=1 --reporter compact` | 2,292/2,292 passed on the final source and test tree (18 min 50 s). |
| `git diff --check` | Passed on the working tree; the final staged diff is checked before commit. |

Successful imports store the same Course and media as before; the tests
compare stored records and every affected media folder, not only the
return values. Merge (Build 246) was not changed and still stages its right
package through `CoursePackage.withInstalledMedia`. Manual device smoke
testing and a platform release artifact remain outside this source revision.
