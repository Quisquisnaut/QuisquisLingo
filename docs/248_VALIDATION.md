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

The total is consistent with Build 247's 2,293 tests plus the 9 added here.

### Investigation, and what it did and did not establish

A first reading called this a load flake unrelated to the change, on the
argument that it fails on the **confirmed save** path, where this build is a
no-op (`_popEditor` sweeps only when it pops with no confirmation result), and
that the Course is dirty there, so `PopScope.canPop` was `false` both before
and after the `canPop` change. **That argument was stated with more confidence
than the evidence supported, and is withdrawn.** The change does add a folder
listing to every Course Editor open and to every unconfirmed close, so it is
not self-evidently free of timing effects.

The file was then run repeatedly on both sides:

| Tree | Runs | Failures |
| --- | --- | --- |
| Unchanged `main` (`f4de191`) | 13 | 0 |
| Build 248 branch | 19 | 2 |

That looks like a branch regression until the timing is taken into account:
**both failures occurred in one session on a machine that had been running
suites back to back for over an hour, and all 32 clean runs were on a rested
machine**, including 10 on the branch. `main` was never exercised under the
same load, so it was never given the same opportunity to fail. Machine load
predicts the failures better than the tree does, and the experiment therefore
**neither convicts nor clears the change**. It is recorded as unresolved.

### The correction actually made

Both failing tests waited for the confirmed save with a hand-rolled loop of
100 iterations at 30 ms — a fixed budget of roughly **3 s of real filesystem
time**. Both now use the repository's shared `pumpUntilFileIoState`, which
allows **10 s** and names the unmet condition when it gives up, as every other
Course Editor test already does. This is a test-robustness fix that stands on
its own merits: a 3 s stopwatch over real disk work is brittle on any loaded
machine, independently of this build.

Test file only; no application code is touched, and the behaviour verified by
the owner's manual smoke test is unchanged. After the correction: analyzer
clean and **10/10** runs of that file passed.

Honest limit of that verification: the file also passed 10/10 on a rested
machine **before** the correction, so those runs show the change is harmless,
not that it cures anything. The meaningful re-check is
`tools/validate_release.ps1`, which runs the complete suite under the same
kind of load that provoked the original failure.

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

---

# Revision 1 validation

`2.0.48+248001`. Plan: [248_EDITOR_LAYOUT_PLAN.md](248_EDITOR_LAYOUT_PLAN.md).

| Check | Result |
| --- | --- |
| `flutter analyze --no-pub` | **No issues found** |
| The four asset validators | all pass, 0 issues |
| `flutter test --no-pub --concurrency=1` | **2,305 / 2,305 passed**, 0 failed (27 min 35 s) |
| `git diff --check` | clean |

## What the existing tests proved

Twenty assertions across nine suites reached the moved or removed controls and
failed until they were repointed; that failure is the evidence the changes
landed. `lesson_naming_226_04` (6), `lesson_controls_226_04` (1),
`optional_learning_paths_226_04` (2), `qql_231_revision1` (1),
`qql_231_course_editor_ui` (2), `exercise_workflow_226_02` (3),
`generated_round_editor_route_245` (3), `editor_diagnostics_226_02_revision3`
(1) and `lesson_metadata_and_icon` (1).

Two needed restructuring rather than repointing, because a Course-level toggle
and the Lesson rows are no longer on one screen: the live-recompute intent is
now checked against the Course screen's own Lessons status card, which sits
beside the toggle.

Before deleting the Round editor's rename, its dialog was compared with the
Rounds page's: `_name(..., allowEmpty: true)` carries the same
`Title, or Enter to skip` label **and** the same `onFieldSubmitted` rule that
keeps an existing title when Enter is pressed on an empty field. Nothing was
removed without checking that the survivor behaves identically.

## The Revision 0 flake, re-checked

`guidebook_status_workflow_226_02_test.dart` passed in this complete run under
full-suite load — the first evidence on a loaded machine since the shared
10 s `pumpUntilFileIoState` replaced its hand-rolled 3 s budget. One clean run
is not proof, but it is the only observation so far taken under the conditions
that produced the original failure.

## Still owed by the owner

Revision 0's manual smoke test covered the Audio Library, which Revision 1
changes. That smoke test must be repeated before release.

---

# Revision 2 validation

`2.0.48+248002`. Plan:
[248_EXPORT_AND_LESSON_ACTIONS_PLAN.md](248_EXPORT_AND_LESSON_ACTIONS_PLAN.md).

| Check | Result |
| --- | --- |
| `flutter analyze --no-pub` | **No issues found** |
| The four asset validators | all pass, 0 issues |
| `flutter test --no-pub --concurrency=1` | **2,306 / 2,306 passed**, 0 failed (24 min 21 s) |
| `git diff --check` | clean |

## The defect this revision removes

`_exportCustomCourse` called `_transfer.exportCourse(_course)` and
`_copyAsNewCourse` called `createCopyAsNewCourse(source: _course)`, where
`_course` is the Course Editor's **working copy**. Both could therefore act on
changes that were never confirmed, and Copy additionally **persisted** a new
Course from them. Course Manager's equivalents pass the stored Course and are
unaffected.

`test/course_editor_layout_regression_test.dart` had pinned the defect in
place: its Copy as New Course case edited Course Info, left it unconfirmed,
copied, and asserted the copy carried those unsaved edits. It is replaced by a
case asserting the Editor offers neither action.

## Version History was considered and deliberately left alone

Moving it was proposed and withdrawn. Export and Copy **read** the working copy
and let it escape the confirmation; Version History **writes into** the working
copy through `_session.loadHistoricalCourse` and still defers to the single
confirmation, warning first when unapplied changes would be replaced. Moving it
to Course Manager would have required restoring straight to storage — a second
persistence path — and would have left media restored by
`CourseBackupService.reinstateMedia` with no session owner, reopening the leak
Revision 0 closed.

## Test work

Twenty assertions across eleven suites reached the removed or moved controls
and failed until repointed. Two probe rewrites were needed because the Editor's
export had been used as an observation point for the working copy:
`course_info_v11_fields_243` and `qql_229_revision3` now observe where the edit
actually lands. New `test/course_export_screen_248_test.dart` covers the Export
screen's two routes, the Course title it names, the stored-Course wording, and
**Save to…** being hidden where no system dialog exists.
