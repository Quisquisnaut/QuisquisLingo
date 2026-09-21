# Build 244 validation

## Revision 6 — Compact sections (`2.0.44+244006`)

Validation on 22 September 2026, before the Revision 6 commit.

- New `test/course_library_compact_244_test.dart`: every section starts
  Expanded; Compact hides the four detail lines and shrinks the artwork to
  40 × 40 in its own section only, keeping languages and Add; sections toggle
  independently and revert to 64 × 64 with details; status labels remain in
  Compact rows; all sections toggled at 320 px do not overflow.
- Focused run: five Course Library suites **36 passed, 0 failed**; version
  tests pass; `flutter analyze` on the changed files: no issues.

## Revision 5 — Sort by (`2.0.44+244005`)

Validation on 22 September 2026, before the Revision 5 commit.

- New `test/course_library_sort_244_test.dart`: Title (case-insensitive,
  trimmed, courseId tie-break), Language (target, source, title), Maintainer,
  Most recent (newest first, title tie-break) and Duration (shortest first,
  unknown last); every ordering is independent of input order; in the page,
  choosing Duration reorders Other Local Courses and leaves Bundled Courses
  and the empty sections unchanged.
- The controls wrap at 320 px (the test font's wide glyphs exposed a 25 px
  overflow of the Sort by row, now a `Wrap`).
- Beta expiry moved to 2026-10-22: `beta_lifecycle_test` dates shifted by one
  day; the first-run dialog expectation in `leaderboard_navigation_test`
  updated.
- Focused run: four Course Library suites **32 passed, 0 failed**; lifecycle,
  first-run dialog and version tests pass; `flutter analyze` on the changed
  files: no issues.

## Revision 4 — Richer Course rows and covers (`2.0.44+244004`)

Validation on 21 September 2026, before the Revision 4 commit.

- New `test/course_library_rows_244_test.dart`: version for Custom, bundled
  and Publisher Courses and omitted when empty; `modifiedAtUtc` parsing and
  the defensive malformed case; duration singular, plural and absent; the
  expanded row lists its fields in order under the title (`Last edited: Sep
  20, 2026`); absent version and duration lines are omitted; a stored cover
  shows as a `ResizeImage`-bounded image with no flag; no cover, a missing
  media file and undecodable bytes each show the flag; the slot is 64 × 64 in
  every case; a 320 px row with a long title, every field and a label does not
  overflow and puts Add below the details.
- `test/course_library_test.dart` reads titles and rows by key instead of
  `ListTile`.
- Focused run: the three Course Library suites **25 passed, 0 failed**;
  version tests pass; `flutter analyze` on the changed files: no issues.

## Revision 3 — Course Library sections (`2.0.44+244003`)

Validation on 21 September 2026, before the Revision 3 commit.

- `test/course_library_screen_244_test.dart` adds: four sections in fixed
  order, each with its heading; counts ` · N` and ` · S shown · H hidden`
  before and after the switch; all-hidden and empty section messages; a Draft
  Course stays inside its own section; the web section is absent by default;
  with a site set it is first, calls the launcher with that site and shows the
  failure SnackBar.
- `test/course_library_test.dart` uses the new section names.
- Focused run: both Course Library suites **16 passed, 0 failed**; the four
  version tests pass. `flutter analyze` on the changed files: no issues.

## Revision 2 — Course Library and availability switch (`2.0.44+244002`)

Validation on 21 September 2026, before the Revision 2 commit.

- New `test/course_library_screen_244_test.dart`: the title is Course
  Library; by default the unpublished, Draft and unverified Courses are hidden
  and the clean one is shown; the switch reveals each with exactly its own
  labels and hides them again; toggling never changes membership or Course
  JSON; every bundled Course is published and Draft-free, so none is hidden.
- `test/course_library_test.dart` updated for the new name, the default-off
  switch and the `Unpublished` label; one tap now scrolls its button fully
  into view (the switch row moved the list down by one row).
- Shared fixture builder moved to `test/support/course_library_fixtures.dart`.
- Focused run: the two Course Library suites, the Draft rule test and the
  four version tests: **40 passed, 0 failed**. `flutter analyze` on the
  changed files: no issues. `git diff --check`: clean.

## Revision 1 — shared Course Draft rule (`2.0.44+244001`)

Validation on 21 September 2026, before the Revision 1 commit.

- New `test/course_draft_status_244_test.dart`: published hierarchy has no
  Draft; Draft at Lesson, Round, Exercise and GuideBook level marks the Course;
  a Draft GuideBook is ignored while GuideBook is off; `AuthoringHierarchyStatus`
  agrees with `CourseDraftStatus`.
- Existing Draft indicator suites (`authoring_hierarchy_indicators_226_02`,
  `draft_container_visibility_226_04_r1`) pass unchanged.
- Focused run: the new test, the four version tests and the Draft/Audit
  suites (`audit_branch_ownership_226_02_revision4`, `draft_promotion_239`,
  `new_course_structure_226_04`, `optional_learning_paths_226_04`,
  `persisted_learner_delivery_226_04_r1`): **87 passed, 0 failed**.
- `flutter analyze` on the changed Dart files: no issues. `git diff --check`:
  clean. The full suite runs once at the end of Build 244 (`AGENTS.md`).
