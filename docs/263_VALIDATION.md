# Build 263 validation

## Revision 2 follow-up (same version, 4 October 2026): the standard look, at most three per row

- `test/owner_review_263_revision2_test.dart` rewritten for the new rules:
  18 passed (the standard look stored as nothing; large squares two per
  row without a choice; the spare picture in the middle for three pictures
  two per row and for four pictures three per row; the earlier look with
  its tiles and centred rows; an exercise overriding the Course; a
  360-pixel screen keeping three per row; Lesson Options in the order
  GuideBook, Duel, Timed, Picture answers, with no 4).
- Laboratory presentation: the normal run failed on the two picture-answer
  examples (`'<Column>'` became `'<Image>'` in their buttons), recorded with
  `QQL_RECORD_PRESENTATION`, then only those two records were updated; the
  test then passed (253).
- `docs/capabilities_v12.json` regenerated (no `four`).
- Focused (23 files, among them Lesson Options, Timed Rounds, the bundled
  English from Italian, the picture and Select tests, registry, Help):
  285 passed.
- `flutter analyze`: no issues.
- Complete suite on the final tree (`--concurrency=1`, 4 October 2026,
  14:31–15:01): **3668 passed, 1 skipped, 0 failed**.

## Revision 2 (2.0.63+263002, 4 October 2026): picture answers: size, square crop, per row

- `test/owner_review_263_revision2_test.dart` (new): 16 passed. The
  `minimumAppBuild` test failed until the version reached 263002, as
  intended (the look needs this build).
- `capability_registry_256_test.dart` first failed twice: every Select
  runtime-support configuration must list the new enumeration options
  (added, with every value), and the pinned Select defaults now include the
  three `course` defaults (test updated). `docs/capabilities_v12.json`
  regenerated with `dart run tools/export_capabilities.dart`; the capability
  description test passes; `tools/validate_courses.py`: both bundled Courses
  OK.
- Focused (36 files: registry and description, canonical primitives,
  Course Model v12, the canonical editor and its narrow layout, semantic
  equality, the canonical runtime, interoperability, negative cases, Story
  model, localization, field Help and its UI, Editor Help, Timed Rounds,
  duplication, transfer, Merge, covers, optional learning paths, the preset
  catalogue, Select editor, Pick the translation, Course Editor, the
  Laboratory presentation, Revisions 0–2 and the version pins): 690 passed,
  2 failed: the field inventory of `exercise_field_help_226_02_test` (the
  two presets have three more fields) and one
  `optional_learning_paths_226_04_test` whose 1200-pixel window lost the
  Lessons card once Lesson Options grew (now 1800 pixels). Both updated;
  rerun 40 passed. The Laboratory presentation baseline is unchanged.
- `flutter analyze`: no issues.
- Complete suite on the final tree (`--concurrency=1`, 4 October 2026,
  07:22–07:44): **3666 passed, 1 skipped, 0 failed**.

## Revision 1 (2.0.63+263001, 4 October 2026): Fill with an example and Clear all in the preset forms

- `test/owner_review_263_revision1_test.dart` (new): 11 passed, among them
  Fill, Save as draft and a check of the saved exercise for every one of the
  46 presets. On the way: the form had to be pushed over a host page (Save
  pops it), Recognize characters' save decodes its pictures (real time must
  pass), and the Page example needs a taller test window; no change to the
  app came out of these.
- Focused (22 files, `--concurrency=1`): exercise forms (opening and
  Previous/Next after the loader change: `exercise_workflow_226_02`,
  `select_editor_238`, `script_recognition_226_03`, `page_card_258`,
  `story_presets_256`, `preset_catalogue_256`, `revision3_followup_256`,
  `revision7_fourth_followup_256`, `owner_review_261_revision6`,
  `translation_ui_226_03`, `flashcard_usage_254`, `course_editor_225`),
  Help (`editor_help_qa_256`, `editor_help_translation`) and the version
  pins: 281 passed.
- `flutter analyze`: no issues.
- Complete suite on the final tree (`--concurrency=1`, 4 October 2026,
  06:22–06:50): **3650 passed, 1 skipped, 0 failed**.

## Revision 0 (2.0.63+263000, 4 October 2026): titles and lines, picture answers

- The check behind the change: a scratchpad script compared, for every
  preset, each standard line its exercises can show with the preset's title
  in the seven learner languages, and each kind's lines with the kind's
  heading. Before: EN 11 presets (plus Put the sentences in order with
  single-word lines), IT 8, ES 12, FR 14, NL 10, DE 3, PT 0 opened with the
  title's first word. After: none, titles and headings.
- `test/owner_review_263_revision0_test.dart` (new): 19 passed. The picture
  test was run once with the old caption rule restored and failed ("mela"
  found), then passed with the fix.
- Laboratory presentation: recorded with `QQL_RECORD_PRESENTATION`
  (`exercise_laboratory_254_test.dart`, 253 passed), then only the
  `instruction` values of the baseline were replaced from the recording:
  19 records, 38 values, every one an old standard line becoming its new
  line; no authored instruction and no other field changed (the normal run
  of the test then passed).
- Focused (20 files, `--concurrency=1`): 566 passed and 3 failed in
  `translation_choice_239_test.dart`, whose `textContaining('Pick the
  correct')` probes still named the old line; corrected, the file and the
  new test then passed (71).
- `flutter analyze`: one info (an unnecessary import in the new test),
  removed; then no issues.
- Complete suite on the final tree (`--concurrency=1`, 4 October 2026,
  05:38–06:07): **3639 passed, 1 skipped, 0 failed**.
