# Build 244 validation

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
