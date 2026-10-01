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

## Revision 2 (2.0.60+260002, 1 October 2026): QQL Demo: English from Italian

**Generators and validator**
- `tools/generate_english_from_italian_260.py` writes
  `assets/courses/english_from_italian_it_en.json`; `--check` reproducible.
  The other four generators: `--check` reproducible, no change.
- `tools/validate_courses.py`: the four bundled Courses pass (the new one
  with en-GB and one Lesson).
- While authoring, two exercises were not represented by their preset and
  were corrected in the generator: the spelling preset stores the blocks in
  the word's order (the Round shuffles them), and Pick the missing word has
  no instruction field. The same two shapes, and the stored order of a
  Listen and answer (to source) prompt, leave nine exercises of the
  Piedmontese demo (Lessons 13, 25 and 34) unrepresented; that demo is not
  changed here (reported to the owner).

**Tests**
- New: `test/english_from_italian_260_test.dart` (a bundled Course counted
  as English; three Rounds, a Story, three Rounds, a Story; six ordinary
  Rounds of six exercises of six types each with a GuideBook card and one
  audio exercise, 36 types in all, not in the catalogue's order, each
  represented by its preset; the Stories with a cover, six lines and two
  questions; the GuideBook's four notes and 35 words; the learner panel in
  Italian; the Audit with no error or warning).
- Updated for the fourth bundled Course: `bundled_courses_225_02_test` (a
  model demo, so no Duel is required; four Courses),
  `course_library_screen_244_test` and `course_library_view_255_test` (the
  counts), `course_official_provenance_225_04_test` (title, derivative
  works forbidden), `course_service_test` (the registry and the startup
  reconciliation), `korean_production_discovery_225_03_test` (six bundled
  assets with the fixtures), `course_model_v11_243_test` (its Course ID),
  `leaderboard_navigation_test` (the Course picker is scrolled to the
  Korean row, now below the first screen).
- Focused run (the 50 files that read the bundled Courses): 7 failures,
  all in the tests above, fixed; the eight files re-run: 104 passed.
- `flutter analyze --no-pub`: no issues.
- **Complete suite** (`--concurrency=1`, keep-awake, 29 min 41 s):
  **3493 passed, 1 skipped, 0 failed**.

## Revision 3 (2.0.60+260003, 1 October 2026): Piedmontese showcase and Before you start

**Generators and validator**
- The Piedmontese, QQL Demo: Piedmontese and QQL Demo: English from Italian
  generators rewrite their Courses; the v11 fixture of the Piedmontese demo
  is rewritten from `build_course_v11()` (the Laboratory's is unchanged).
  All five generators: `--check` reproducible.
- `tools/validate_courses.py`: the four bundled Courses pass.

**Tests**
- New: `test/owner_review_260_revision3_test.dart` (Pick the missing word
  and One word fills all keep an Instruction or context through the
  builder, Recognition and the form's values, and store nothing without
  one; every exercise of the four bundled Courses is represented by its
  preset; the Piedmontese demo's instructions, source answers and ordered
  blocks; the QQL Demo Courses open only each Lesson's first Round with a
  card).
- Updated: `piedmontese_mixed_259_test` and `english_from_italian_260_test`
  (the first Round's card only), `exercise_field_help_ui_226_02_test` (the
  two forms' new field).
- Focused run (the 38 files that read these presets, the Piedmontese
  Courses, the field Help or the cards): 15 failures. 13 came from a gap
  this revision opened: the Exercise Help page (and its search) looks up
  every form field in `exerciseHelpFieldKeyByPresetAndField`, which had no
  entry for the new field, so it threw; the two entries were added. The
  other two were the field list above. The four files re-run: 124 passed.
- `flutter analyze --no-pub`: no issues.
- **Complete suite** (`--concurrency=1`, keep-awake, 29 min 38 s):
  **3500 passed, 1 skipped, 0 failed**.

## Revision 4 (2.0.60+260004, 1 October 2026): QQL Demo titles

**Generators and validator**
- The Laboratory and Piedmontese generators write the new titles; QQL
  Demo: Piedmontese is unchanged (it replaces the title it copies). The v11
  fixtures of both are rewritten; the Laboratory-of-the-future fixture's
  checksum follows the Laboratory's (only that line changes). All five
  generators: `--check` reproducible. `tools/validate_courses.py`: the four
  bundled Courses pass.

**Tests**
- Updated: the tests that name the two Courses
  (`bundled_courses_225_02_test`, `course_official_provenance_225_04_test`,
  `korean_production_discovery_225_03_test`, `leaderboard_navigation_test`,
  `piedmontais_course_254_test`).
- Focused run (the 41 files that name the Courses, read their files or the
  fixtures, or show the credits): 830 passed.
- `flutter analyze --no-pub`: no issues.
- **Complete suite** (`--concurrency=1`, keep-awake, 30 min 13 s):
  **3500 passed, 1 skipped, 0 failed**.

## Revision 5 (2.0.60+260005, 1 October 2026): exercise difficulty

**Generators and validator**
- No Course file changes; `tools/validate_courses.py` passes.

**Tests**
- New: `test/exercise_difficulty_260_test.dart` (the level of every
  Laboratory example, for all its presets, matches the expected level;
  Recognize characters is 1 or 2 by direction; a Round's average counts
  its answered exercises only; the badge's tooltips; the Editor Help
  question in EN, IT and ES).
- Updated: the Editor Help counts (70) in `editor_help_qa_256_test` and
  `editor_help_translation_test`.
- Focused run (the new test and the two Help tests): 19 passed. The Round
  editor's and Rounds page's rows keep their texts as separate widgets, so
  no test reading them needed a change (checked by search before the
  suite).
- `flutter analyze --no-pub`: no issues.
- **Complete suite** (`--concurrency=1`, keep-awake, 29 min 25 s):
  **3505 passed, 1 skipped, 0 failed**.
