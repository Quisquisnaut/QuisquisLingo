# Build 251 validation

## Revision 0 — Shared Course sections

`2.0.51+251000`, 24 September 2026, on `codex/build-251-architecture`
from PR #15 merge `942d8f5`. Beta expiry is `2026-10-24 23:59:59` local
time, recalculated as 30 days from this revision's release date.

The existing Courses, Course Studio Favorites, Compact and All Courses screen
tests passed **26/26** before extraction. The new
`test/course_library_section_251_test.dart` first failed because the shared
owners did not yet exist. After extraction and the state-lifetime correction,
the focused run passed **40/40**:

```text
flutter test --no-pub --concurrency=1 \
  test/course_library_section_251_test.dart \
  test/courses_screen_250_test.dart \
  test/course_manager_favorites_250_test.dart \
  test/course_library_compact_244_test.dart \
  test/course_library_screen_244_test.dart \
  test/course_library_sort_244_test.dart \
  test/course_library_row_layout_250_test.dart
```

The first extraction moved Compact flags into section widgets that a Studio
reload temporarily unmounted. A new widget test reproduced this regression:
the favorite row's Version reappeared after refresh. The final code keeps
section flags in the tab states and the new test passes. All Courses also
retains its load-time Draft snapshot, so Search rebuilds do not change when
that status is computed.

Version and Course Audit report assertions were changed first and failed
against `2.0.50+250001`, then passed after the version metadata update. The
metadata, Audit report, older Build-label and platform-contract test files
were exercised. A final metadata, Beta lifecycle and Course Audit report run
passed **13/13**. The Beta expiry remains the same calendar date as Build 250
Revision 1 because both revisions were released on 24 September; the 30-day
calculation was checked in `test/beta_lifecycle_test.dart`.

`flutter analyze --no-pub` found no issues. The 16 changed Dart files passed
`dart format --output=none --set-exit-if-changed`, and `git diff --check`
passed. The
asset validators passed: `python tools/validate_courses.py` (10 Course Model
v11 files), `python tools/validate_images.py` (111 assets, 0 issues),
`python tools/validate_lesson_icons.py` (14 assets, 0 issues), and
`python tools/validate_media_assets.py` (443 files, 0 issues). An independent
read-only review of the repaired diff found no further actionable difference
in categories, Favorites, filtering, sort, counts, empty states, colors, keys,
row actions, Compact lifetime or tab navigation.

The complete Flutter suite is scheduled at the final Build 251 release gate
after Revision 1, in accordance with `AGENTS.md` test execution policy. No
Windows package was created.
