# Build 248 validation

`2.0.48+248000` — Build 248, Revision 0, Course Model v11, branch
`claude/248-audio-library` from `main` `f4de191`.
Plan: [248_AUDIO_LIBRARY_PLAN.md](248_AUDIO_LIBRARY_PLAN.md).
Change summary: [248_CHANGE_SUMMARY.md](248_CHANGE_SUMMARY.md).

## 1. Characterization before the source change

`test/audio_library_media_248_test.dart` was written first and run against
unchanged code, with the final test file, on
`flutter test --no-pub --concurrency=1`. Result: **2 passed, 3 failed**,
matching the plan's predicted table exactly.

| Assertion | Before the change |
| --- | --- |
| Cancel after importing recordings leaves no unreferenced MP3 | **failed** — both imported files remained |
| Leaving the Audio Library without Save removes only that session's recordings | **failed** — 3 files present where 2 were expected |
| A partial batch write leaves no unreferenced recording | **failed** — the 2 already-stored files remained |
| An unreadable stored Course retains the recordings | passed — recovery guard |
| A confirmed Course keeps every imported recording | passed — `deleteUnreferenced` guard |

Every test drives the real `CourseEditorScreen` and `AudioLibraryScreen`
against a real Course store and a real `CourseMediaStore` in the test's own
temporary support and Documents folders, which `test/flutter_test_config.dart`
installs per test. The recordings are real synthetic MP3s from
`test/support/synthetic_mp3.dart`.

The partial-batch failure is injected at the real boundary rather than mocked:
a directory is created at the third recording's target file name, so
`CourseMediaStore.addBytes` fails on its rename after the first two recordings
have already been stored, and `importMp3Files` propagates the error with its
whole clip list lost.

## 2. What implementation exposed

`PopScope.canPop` was `_routeMayPop || !_dirty`, so an **unchanged** Course
Editor popped directly and never reached `_popEditor`. That is precisely the
back-out-after-import path the plan had to cover, so the plan's assumption
that `_popEditor` saw every exit was wrong. `canPop` is now `_routeMayPop`
only, and every exit runs through `_attemptLeave` → `_popEditor`.

Consequence: closing an unchanged Course Editor completes after the folder
check rather than within the same frames. Four existing assertions waited with
`pumpAndSettle`, which does not advance real file IO, so they now use the
repository's existing `pumpUntilFileIoState` — the same helper the
confirmation path already required:

* `test/production_course_transaction_225_04_test.dart` — "restoring Course
  Info to the original value exits cleanly", "no-change top-level exit has no
  dialog, backup or version", "official inspection closes without a
  working-copy confirmation or backup".
* `test/course_ownership_team_229_r1_test.dart` — "persisted Copy as New
  Course and Fork close cleanly while edits prompt".

The cost in the common case is one directory listing: the stored Course is
read only when the folder actually gained a recording.

## 3. Focused tests after the change

| Suite | Result |
| --- | --- |
| `test/audio_library_media_248_test.dart` | 9/9 passed |
| `test/production_course_transaction_225_04_test.dart`, `test/course_ownership_team_229_r1_test.dart`, `test/audio_library_media_248_test.dart` | 31/31 passed |
| Editor batch 1 — `canonical_authoring_route_245`, `course_editor_224`, `authoring_hierarchy_indicators_226_02`, `audit_issue_save_propagation_226_02_revision4`, `course_editor_layout_regression`, `course_editor_export_226_02`, `course_ownership_team_229_r1`, `course_metadata_wording_226_04_r1`, `course_metadata_ui_v9`, `course_info_v11_fields_243` | 63 passed, 1 failure, since corrected |
| Editor batch 2 — 16 further `CourseEditorScreen` suites | 3 failures, all the unchanged-exit timing above, since corrected |

The four owner-level tests in the new file pin the rules the widget tests
cannot reach directly: a never-stored Course loses everything the session
created, pictures added while editing are left in place, an unreadable folder
removes nothing, and the sweep runs once.

## 4. Release gate on the final tree

| Check | Result |
| --- | --- |
| `flutter analyze --no-pub` | **No issues found** (8.4 s) |
| `python tools/validate_courses.py` | 10 bundled Course Model v11 files, OK |
| `python tools/validate_images.py` | 111 assets, 92 semantic replacements, 5 padding-only normalizations, 0 issues |
| `python tools/validate_lesson_icons.py` | 14 assets, 0 issues |
| `python tools/validate_media_assets.py` | 443 files, 19 locked audio, 281 world flags, 22 static references, 0 issues |
| `flutter test --no-pub --concurrency=1 --reporter compact` | **2,301 passed, 1 failed** of 2,302 (32 min 22 s) — see below |
| `git diff --check` | clean |

### The one full-suite failure

`test/guidebook_status_workflow_226_02_test.dart` — "empty Guidebook saved as
Draft is red and blue through Lesson and Lessons while Rounds stays green"
failed in the complete run and **passes in isolation** (5/5 on that file
alone, 27 s).

It is recorded as a load-induced flake, not a regression, on this evidence:

* It fails inside `_confirmCourse`, on the **confirmed save** path. This
  build's cleanup runs only when `_popEditor` pops with **no** confirmation
  result; with a result it is a no-op, so the confirm path is behaviourally
  unchanged.
* The Course is dirty at that point, so `PopScope.canPop` evaluated to `false`
  both before and after the `canPop` change. That change can only affect an
  **unchanged** working copy.
* The helper waits a fixed ~3 s of real filesystem time for the save to land,
  and the run followed more than an hour of back-to-back suites on the same
  machine.

The total is consistent with Build 247's 2,293 tests plus the 9 added here.
`tools/validate_release.ps1` runs the complete suite again as part of the
release gate, which re-checks this on an idle machine.

## 5. Version and release records

`pubspec.yaml` and `lib/services/app_metadata.dart` are `2.0.48+248000`,
`Build 248, Revision 0`, with the four version tests updated
(`test/app_metadata_225_04_test.dart`,
`test/course_audit_report_225_test.dart`, `test/qql_229_revision3_test.dart`,
`test/qql_233_revision_platform_contract_test.dart`).

The 30-day Beta expiry recalculated from this release's own date,
22 September 2026, is `2026-10-22 23:59:59` local time. That is the same date
Build 247 carried, because both were released on the same day, so
`lib/services/beta_lifecycle_service.dart`, its test, `README.md` and the
documentation expiry statements are unchanged rather than carried forward by
accident.

`AGENTS.md`, `README.md` and `CHANGELOG.md` record the new release boundary.

## 6. Preserved

Course Model v11, stored formats and keys, package format 1 and signatures,
authoring rights, scoring, progression and the single top-level confirmed
Course save are unchanged. No new persisted preference key and no new
user-file folder, so `AppResetService`, `InventoryService` and
`docs/239_RESET_STORAGE_INVENTORY.md` are unaffected. MP3 validation and
storage remain in `RecordedAudioService` and playback and controls remain in
the widget, as the roadmap row requires.
