# Build 257 validation

Evidence for each Build 257 revision. Process: `docs/256_HANDOFF.md`
("Requirements and process").

## Revision 0 (2.0.57+257000, 29 September 2026): Before you start cards

### Generated data

- `python tools/generate_exercise_laboratory_254.py`, `generate_edge_case_demo_254.py`
  and `generate_piedmontais_demo_254.py`, then each with `--check`: all
  reproducible (Laboratory 7 Lessons, 27 Rounds, 122 examples; Edge Case
  matches; Piedmontese 39 Lessons, 117 examples).
- `python tools/validate_courses.py`: the three bundled Course Model v12
  files OK (a Before you start card first in each Lesson's first Round).
- `dart run tools/export_capabilities.dart`: `docs/capabilities_v12.json`
  gains `guidebookButton`.

### Static analysis

- `flutter analyze --no-pub`: no issues (final tree).

### Tests

- New: `test/before_you_start_card_257_test.dart` (model, recipe,
  playability, Audit, v11 conversion, bundled Courses, Round Wizard, Round
  screen with and without Open GuideBook, Review, the Preview of a card
  alone, the editor switch).
- Updated for the card (old notes replaced by cards, counts): Audit rule
  count 108 → 110 (`audit_code_registry_226_02_test`,
  `audit_branch_ownership_226_02_revision4_test`), Editor Help questions
  66 → 67 (`editor_help_qa_256_test`, `editor_help_translation_test`),
  presets 42 → 43 (`story_presets_256_test`, `piedmontais_course_254_test`),
  exercises per bundled Course (`edge_case_course_254_test`,
  `bundled_source_254_test`), the Laboratory's examples exclude the cards
  (`exercise_laboratory_254_test`), the Round Wizard's first Round
  (`guidebook_sentence_generator_test`), and the Round-screen tests that
  built a `lesson_intro` note (`audio_settings_runtime_228_04_test`,
  `guidebook_learner_delivery_226_02_test`,
  `optional_learning_paths_226_04_test`,
  `qql_230_learner_flow_hardening_test`).
- Version pins 2.0.57+257000 / Build 257, Revision 0.

- Also updated: `revision7_followup_256_test` (the Assign Lesson's examples
  exclude its card; found by the first complete run).

### Results

- Focused batch 1 (57 files, before the test updates): the expected
  failures only (old notes, counts, the Laboratory's per-example loop
  reaching the cards), all addressed.
- Focused batch 2 (27 files: the new test, every failing file, the version
  pins, the converter parity): 523 passed, 3 failed (the new editor test
  opened a Published card, a fixture's `exercises.single`, the field-Help
  UI loop's picture check); fixed and rerun: 80 passed.
- Story editor, Add step and sequence tests after the Story steps fix: 23
  passed.
- Complete suite, run 1 (15:21–15:49, `--concurrency=1`): 3306 passed,
  1 skipped, 1 failed (`revision7_followup_256_test`: the Assign Lesson's
  example count now saw the card). Fixed; the file rerun passed (16).
- Complete suite, run 2 on the final tree (15:50–16:18, `--concurrency=1`,
  under the keep-awake wrapper): **3307 passed, 1 skipped, 0 failed**.
