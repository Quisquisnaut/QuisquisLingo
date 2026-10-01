# Build 260 validation

## Revision 0 (2.0.60+260000, 1 October 2026): Course languages

**Generators and validator**
- The Laboratory, Piedmontese, QQL Demo: Piedmontese and Edge Case
  generators: `--check` reproducible for all (no Course file changes in
  this revision).
- `tools/validate_courses.py`: the three bundled Courses pass.

**Laboratory presentation baseline**
- Unchanged: the Laboratory's base language is English, whose lines are
  the same as before.

**Tests**
- New: `test/course_languages_260_test.dart` (227 languages with unique
  tags and the curated three-letter ones; resolution by tag, English name,
  native name and instruction-language name, ignoring capitals and
  accents; tag shape; names in the seven instruction languages; every
  catalog has only keys English has and the same placeholders; learner
  lines such as "Traduce al italiano.", "Traduci in napoletano.",
  "Traduis en allemand.", an English fallback for a base language QQL does
  not have, a hand-written language kept as written, the Course's own name
  for learners; Course Info's tag rules; the `LanguageField` widget: a
  listed language shows its tag, a language not in the list is kept as
  typed, a bad tag is flagged).
- `course_info_update_service_245_test` passes the three new fields.
- Updated: the Editor Help count (69), the instruction-language lists
  (French instead of Finnish and Welsh) in `assign_runtime_256_test` and
  the Build 259 Revision 3 and 4 tests, the Revision 7 test (a Spanish-base
  Course now reads "Traduce al italiano."), the QQL Guide line.
- Focused run (27 files, 519 tests): 2 failures fixed.
  `course_editor_layout_regression_test` forbids `helperMaxLines: 3` in
  the Course Info region, so the learners' name field uses a `helper`
  text; `owner_review_259_revision7_test` gave the Laboratory a new
  base-language name while its `en-GB` tag still decided, so the test
  removes the tag.
- `flutter analyze --no-pub`: no issues.
- **Complete suite** (`--concurrency=1`, keep-awake, 28 min 29 s):
  **3481 passed, 1 skipped, 0 failed**.
