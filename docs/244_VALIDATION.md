# Build 244 validation

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
