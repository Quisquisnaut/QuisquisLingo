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

## Revision 1 (2.0.60+260001, 1 October 2026): the learner panel's buttons and messages

**Generators and validator**
- No Course file changes; the bundled Courses' learner panels change only
  for a base language other than English (none of the three bundled
  Courses).

**Tests**
- New: `test/learner_panel_260_test.dart` (seven catalogs, each with every
  English key, no empty text and the English placeholders; the panel
  follows the base language and falls back to English for a language QQL
  does not have; placeholders filled; an Italian-base Round shows
  Controlla, La tua risposta, Sbagliato, the Italian translation heading
  and Rivedi gli errori; an Italian-base Duel shows Duello linguistico and
  "Domanda 1/25 · 4 vite").
- Focused run (the 55 files that open the Round, the Duel, the Review page
  or the exercise lines, and the Revision 0 test): 950 passed.
- `flutter analyze --no-pub`: no issues.
- First complete suite: 3485 passed, 1 skipped, 1 failed:
  `imported_course_v6_regression_test` searched the Round screen's source
  for `labelText: 'Your answer'`; it now checks `labelText:
  _t('yourAnswer')` and that the English catalog says "Your answer".
  Re-run alone: passed.
- **Complete suite** (second run, `--concurrency=1`, keep-awake,
  28 min 45 s): **3486 passed, 1 skipped, 0 failed**.
