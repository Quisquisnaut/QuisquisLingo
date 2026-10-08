# Build 251 validation

## Revision 1 — Course Editor device state

`2.0.51+251001`, 24 September 2026, on `codex/build-251-architecture`.
Beta expiry is `2026-10-24 23:59:59` local time, 30 days from this
revision's release date. The Course Model, package format and stored
SettingsService keys and values are unchanged.

Before extraction, the new characterization cases in
`test/qql_231_revision1_test.dart` passed **15/15** against the Revision 0
code. They cover immediate per-learner mode and one-time notice writes,
legacy mode values, seven-day scheduling by Course code, the
`canEditOriginal`/Edit gate, recording the date after the automatic check,
dialog timing and the separate manual Audit path. The new
`test/course_editor_device_state_251_test.dart` failed before the owner
existed, then passed after extraction. The final combined focused run passed
**18/18**:

```text
flutter test --no-pub test/course_editor_device_state_251_test.dart \
  test/qql_231_revision1_test.dart --reporter expanded
```

The screen delegates only the preference reads/writes and the automatic
schedule to `CourseEditorDeviceState`. A read-only independent review found
no concrete difference in their ordering, the existing dialogs, manual Audit,
governance lookups or duplicate-title reads. `flutter analyze --no-pub`
reported **no issues**. The ten new/changed owner, metadata and test Dart
files passed `dart format --output=none --set-exit-if-changed`; the large
Course Editor file was kept to a narrow 29-line wiring diff. `git diff
--check` passed. The four asset validators passed: 10 bundled Course Model
v11 files, 111 images, 14 Lesson icons and 443 media files, with zero issues.

The final release gate ran on the settled source and test tree:

```text
flutter test --no-pub --concurrency=1 --reporter compact
```

**2,430/2,430 passed** in 28 minutes 24 seconds, exit code 0. Immediately
before starting Flutter, the
supervising PowerShell process requested Windows
`ES_CONTINUOUS | ES_SYSTEM_REQUIRED`; its `finally` block cleared the request
after Flutter exited. The command output confirmed both transitions. No
Windows package was built by this task.

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
