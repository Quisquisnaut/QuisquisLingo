# Build 246 validation

## Revision 0 — Merge media and Course confirmation (`2.0.46+246000`)

Validated on 22 September 2026 against the Build 246 Revision 0 working tree.

| Check | Result |
| --- | --- |
| Boundary tests before implementation | The new media workflow test did not compile until `CourseEditorService.confirmMergedCourse` existed. The duplicate-submission widget test failed because `DO MERGE!` remained enabled during a pending callback. |
| `flutter test --no-pub --concurrency=1 test/course_merge_submission_246_test.dart test/course_merge_media_workflow_246_test.dart test/course_merge_service_test.dart test/course_media_243_test.dart` | 27/27 passed after the final same-frame submission guard. |
| Additional focused Course storage, transaction, version and Audit suites | 47/47 passed before the final screen guard. |
| `flutter analyze --no-pub` | No issues found on the final source tree. |
| `python tools/validate_courses.py` | 10 bundled Course Model v11 files valid. |
| `python tools/validate_images.py` | 111 assets; 0 issues. |
| `python tools/validate_lesson_icons.py` | 14 assets; 0 issues. |
| `python tools/validate_media_assets.py` | 443 files; 0 issues. |
| Complete `flutter test --no-pub --concurrency=1 --reporter compact` | 2,269/2,269 passed on the final source and test tree (20 min 43 s). |
| `git diff --check` | Passed; the final staged diff is checked before commit. |

The eight media workflow tests use real temporary Course and media stores. They
cover left/right copying, temporary right-package media, partial copy failure,
precommit rejection after copying, an existing destination, postcommit write
and cleanup errors, an unreadable recovery check, and a reference missing from
both sources. The widget test submits twice in the same frame and again while
the first callback remains pending; only one Merge callback may run.

An independent diff review identified the repeat-submission race and the
precommit test gap. Both were addressed before the final release gate. Manual
device smoke testing remains outstanding; this is a source revision, not a
platform release artifact.

An earlier full-suite attempt was interrupted at 353 tests when final review
found the same-frame callback gap. The 2,269-test result above is from a fresh
run after that guard and its focused regression test were complete. Flutter
normalized line endings in generated platform registrants during dependency
setup; their semantic diff is empty, so they are excluded from this revision.
