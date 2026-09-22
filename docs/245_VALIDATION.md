# Build 245 validation

## Revision 0 — Course Info update boundary (`2.0.45+245000`)

Validated on 22 September 2026 against the Revision 0 working tree.

| Check | Result |
| --- | --- |
| `flutter test --no-pub test/production_course_transaction_225_04_test.dart` before the screen extraction | 10/10 passed. The real Course → Lesson → Round → Exercise route preserved nondefault Content metadata, Course metadata and the pre-change backup. |
| `flutter test --no-pub` with the 11 focused Course Info, transaction, governance, layout and version test files | 77/77 passed after the screen extraction. The new operation tests cover optional-field removal, untouched content, Team-before-Maintainer order and authorization rejection. The Rights Holder widget test checks persisted JSON. |
| `flutter analyze` | No issues found (90.4 s). |
| `python tools/validate_courses.py` | 10 bundled Course Model v11 files valid. |
| `python tools/validate_images.py` | 111 assets; 0 issues. |
| `python tools/validate_lesson_icons.py` | 14 assets; 0 issues. |
| `python tools/validate_media_assets.py` | 443 files; 0 issues. |
| `git diff --check` | Passed. |

After reviewing the staged diff, the installed formatter's unrelated changes
to the 11,000-line screen were removed. The final narrow diff was rechecked:
`flutter test --no-pub test/course_info_update_service_245_test.dart
test/course_metadata_ui_v9_test.dart
test/production_course_transaction_225_04_test.dart` passed 15/15, and
`flutter analyze --no-pub` found no issues. The two new Dart files and the
changed test files were formatted; the existing screen style was retained to
avoid unrelated churn.

The full Flutter suite is scheduled for the integrated Build 245 gate. Manual
device smoke testing remains outstanding; this commit is a source revision,
not a release artifact.

## Revision 1 — authoring session (`2.0.45+245001`)

Validated on 22 September 2026 against the Revision 1 working tree.

| Check | Result |
| --- | --- |
| `flutter test --no-pub test/production_course_transaction_225_04_test.dart test/provisional_parent_save_ui_test.dart test/qql_231_revision1_test.dart` before migration | 24/24 passed. |
| `flutter test --no-pub test/course_authoring_session_245_test.dart` | 9/9 passed after TDD red checks. Covers stage permission and atomicity, audit freshness, cancel, history, failed and successful confirmation, and new Course confirmation before the Edit setting loads. |
| `flutter test --no-pub` with 12 focused authoring, publication, Course Info, governance and version test files after integration | 74/74 passed. |
| `flutter analyze --no-pub` | No issues found (24.8 s). |
| `python tools/validate_courses.py` | 10 bundled Course Model v11 files valid. |
| `python tools/validate_images.py` | 111 assets; 0 issues. |
| `python tools/validate_lesson_icons.py` | 14 assets; 0 issues. |
| `python tools/validate_media_assets.py` | 443 files; 0 issues. |
| `git diff --check` | Passed. |

The full Flutter suite and manual device smoke remain for the integrated Build
245 release gate.
