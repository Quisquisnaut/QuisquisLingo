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

## Revision 2 — typed hierarchy updates (`2.0.45+245002`)

Validated on 22 September 2026 against the Revision 2 working tree.

| Check | Result |
| --- | --- |
| `flutter test --no-pub test/course_hierarchy_route_245_test.dart` before the screen migration | 1/1 passed, characterizing the standalone Round callback and pop result with rich Content metadata. |
| `flutter test --no-pub` with 17 focused authoring, icon, transfer, Audit issue, GuideBook, layout, publication and version test files after the final fix | 172/172 passed. Includes generated Round drafts absent from the base Course and duplicate Content/Lesson/Round IDs that must still open for Audit. |
| `flutter analyze --no-pub` | No issues found (73.9 s). |
| `python tools/validate_courses.py` | 10 bundled Course Model v11 files valid. |
| `python tools/validate_images.py` | 111 assets; 0 issues. |
| `python tools/validate_lesson_icons.py` | 14 assets; 0 issues. |
| `python tools/validate_media_assets.py` | 443 files; 0 issues. |
| `git diff --check` | Passed. |

An independent diff review found preview regressions for generated Rounds and
duplicate IDs before the final gate. Tolerant typed preview overlays and
regression tests fixed them. Strict ID-targeted mutation commands still reject
ambiguous targets; existing Audit remains accessible for malformed Courses.
The full Flutter suite and manual device smoke remain for the integrated Build
245 release gate.

## Revision 3 — canonical route propagation (`2.0.45+245003`)

Validated on 22 September 2026 against the Revision 3 working tree.

| Check | Result |
| --- | --- |
| `flutter test --no-pub test/canonical_authoring_route_245_test.dart` before migration | The integrated Course route exposed ten extra clock calls on Back (11 after Exercise Save, 21 at the Course); the standalone Round route emitted two callbacks for one Exercise Save. These were the characterization failures. |
| `flutter test --no-pub test/course_authoring_session_245_test.dart` | 11/11 passed, including explicit prior-Course and no-prior reconciliation. |
| `flutter test --no-pub` with 16 focused authoring, hierarchy, transfer, Audit, layout and version test files | 115/115 passed on the final candidate tree. The integrated Published Exercise path had no extra update on Back and confirmed once; standalone Round callback and pending Lesson metadata routes passed. |
| `flutter test --no-pub test/canonical_authoring_route_245_test.dart` | 5/5 passed. Includes direct Course Audit → Exercise (one live stage, none on return), integrated Course-root Exercise copy, nested Published save, standalone callback compatibility and pending Lesson metadata. |
| `flutter analyze --no-pub` | No issues found (30.5 s). |
| `python tools/validate_courses.py` | 10 bundled Course Model v11 files valid. |
| `python tools/validate_images.py` | 111 assets; 0 issues. |
| `python tools/validate_lesson_icons.py` | 14 assets; 0 issues. |
| `python tools/validate_media_assets.py` | 443 files; 0 issues. |
| `git diff --check` | Passed. |

The integrated nested routes now call one authoring session adopter. Ancestor
screens synchronize the returned canonical Course without reconciling it again;
identical pop results are ignored. A direct Audit → Exercise path also uses the
current canonical Round for its fallback. Standalone route callbacks remain
compatible. No route was moved to a new file solely to reduce line count.

The full Flutter suite and manual device smoke remain for the integrated Build
245 release gate.

## Revision 4 — per-Course storage commands (`2.0.45+245004`)

Validated on 22 September 2026 against the Revision 4 working tree.

| Check | Result |
| --- | --- |
| Deterministic pre-change race tests | 0/3 passed. Paused Course A confirmation erased a concurrently saved B; paused A deletion erased B; a direct same-ID file change during backup was overwritten instead of rejected. |
| `flutter test --no-pub test/course_storage_commands_245_test.dart test/course_file_store_test.dart` | 21/21 passed. Covers unchanged disk format, stale tokens, duplicate/alias IDs, corrupt canonical files, incomplete staged writes, external changes during staging, Windows case aliases and delayed async lock reentry. |
| `flutter test --no-pub test/course_storage_race_245_test.dart` | 7/7 passed. Concurrent B survives A confirmation and deletion; an out-of-band same-ID change rejects stale confirmation; a postcommit error leaves the new Course and backup readable; signed Publisher and custom packages retain newly installed referenced media after postcommit errors; a failed partial Copy as New removes its destination media. |
| `flutter test --no-pub test/course_package_media_recovery_245_test.dart` | 3/3 passed. Default rollback is retained; an explicit persisted-record check or unreadable storage preserves media after a failed save. |
| `flutter test --no-pub` with 17 focused persistence, package, publisher, backup and real editor test files | 118/118 passed before the final signed Publisher postcommit test was added. |
| First full `flutter test --no-pub` run | 2,256 passed, 1 failed: the Course Info wording route hit a null assertion on a metadata-only edit with no active profile. |
| `flutter test --no-pub` with Course Info wording, update-service and metadata UI test files after the fix | 8/8 passed. Descriptive edits allow no active actor; governance changes still require one. |
| Final full `flutter test --no-pub` run | 2,261/2,261 passed (16 min 24 s). |
| `flutter analyze --no-pub` on the final source tree | No issues found (41.5 s). |
| `python tools/validate_courses.py` | 10 bundled Course Model v11 files valid. |
| `python tools/validate_images.py` | 111 assets; 0 issues. |
| `python tools/validate_lesson_icons.py` | 14 assets; 0 issues. |
| `python tools/validate_media_assets.py` | 443 files; 0 issues. |

`CourseEditorService` now uses one-record snapshots and intent-specific create,
replace and remove operations. The store compares whole-record tokens and
verifies staged bytes before replacing a live file. A shared per-Course lock
covers service checks, backup, commit, readback and media cleanup across store
instances in the same isolate. Publisher package media is retained if a
postcommit failure leaves it referenced by the stored Course.

The storage command's duplicate-ID check scans other readable Course files, so
its read cost still grows with the number of files. A raw external writer can
still race in the narrow interval after the final token check and before the
filesystem rename or delete; the in-app lock and token checks prevent the
reproduced app-level races and detect earlier out-of-band changes.
