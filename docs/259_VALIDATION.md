# Build 259 validation

Plan: `CONTEXT_AND_HINT_PLAN.md`; change summary: `259_CHANGE_SUMMARY.md`;
handoff: `259_HANDOFF.md`.

## Revision 0 (2.0.59+259000, 30 September 2026): instructions and questions

**Generators and validator**
- Laboratory: 8 Lessons, 28 Rounds, 124 examples, `--check` reproducible.
- Piedmontese: 39 Lessons, 117 examples, `--check` reproducible.
- Edge Case: `--check` unchanged.
- v11 converter fixtures (`test/fixtures/v11/exercise_laboratory_en_it.json`,
  `piedmontais_en.json`) are written from `course_v11()` /
  `build_course_v11()` with their checksum (the method verified against
  the previous fixtures' checksums).
- `tools/validate_courses.py`: all three Courses pass after the Laboratory
  Lesson count was corrected to 8. It had failed on `main` since Build 258
  Revision 3.

**Laboratory presentation baseline**
- Record run (`QQL_RECORD_PRESENTATION`): 124 records, rebuilt into
  `test/support/laboratory_presentation_254.dart` and formatted.
- Compared record by record with the previous baseline: 87 unchanged and
  37 changed. Every change is deliberate:
  - **Instruction line replaced by the authored instruction** (the prompt
    line disappears): Word order (5), Drag the blocks into the gaps (6,
    including the two meanings "Anna reads a book." and "We drink
    water."), Spell the word in the picture (3), Type what you hear (2),
    Recognize characters image to text (2), Put the sentences in order
    (2), Listen and match (1), the story's word order (1).
  - **The Choose examples ask in their question** (5): the standard
    "Choose the correct answer." returns and the question moves to the
    body.
  - **Recognize characters text to image** asks in its question (1).
  - **The instruction is now visible** where it had not been shown at
    all: What is in the picture, Type what you see and Name what you see
    (3, "What is this?"), and the four Assign examples (4).
  - **Match by meaning's instructions are in English** (2).

**Tests**
- New: `test/instructions_and_questions_259_test.dart`, 36 tests:
  - the rule (instruction, material, standard line, the two spelling
    presets, Type what you see, an Assign);
  - the six fields that became Instruction or context (stored as
    `primary`, represented by their preset, field keys and title);
  - Choose the answer (to source) leaves its instruction unmarked;
  - a Published save refuses every required question or sentence, and
    the form shows the message;
  - the form's helper quotes the standard line;
  - Recognize characters (question, controller, Audit);
  - the Duel line appears with audio only.
- Updated to the new labels and roles: the field Help tests and the
  inventory of every form, the editor workflow and route tests, the
  wizard, the Choose editor fixture (a question is never optional), the
  Assign and Name what you see tests, and Match by meaning's English
  instruction.
- Focused batch of the 44 files that touch the change, first run before
  the test updates: 772 passed, 111 failed, all on old labels, old roles
  and the baseline. After the updates, the 18 failing files, the
  Laboratory test and the version and Help tests were rerun and pass; the
  complete suite covers the rest.
- `flutter analyze --no-pub`: no issues.
- **First complete suite** (10:13–10:53, `--concurrency=1`, keep-awake
  wrapper): 3377 passed, 1 skipped, 2 failed.
  - `fill_blank_hint_226_04_r1_test` pinned the old Pick the missing word
    helper text; it now expects the new one.
  - `authoring_hierarchy_indicators_226_02_test` failed to save because
    the longer helper made the form taller: its scroll step left Save
    8 pixels below the 1,200-pixel test window, so the tap missed (the
    log's hit-test warning). The helper now calls `ensureVisible` before
    tapping. The app itself was correct.

  Both files pass after the fix.
- **Second complete suite** (10:56–11:33, `--concurrency=1`, keep-awake
  wrapper): **3379 passed, 1 skipped, 0 failed**.

## Revision 1 (2.0.59+259001, 30 September 2026): Complete the text and Put the sentences in order

**Generators and validator**
- Laboratory: 8 Lessons, 28 Rounds, 124 examples, `--check` reproducible.
- Piedmontese: 39 Lessons, 117 examples, `--check` reproducible.
- Edge Case: `--check` unchanged.
- v11 converter fixtures rewritten from `course_v11()` / `build_course_v11()`
  with their checksum; the test-only future fixture changes only its
  checksum, as in Revision 0.
- `tools/validate_courses.py`: all three Courses pass.

**Laboratory presentation baseline**
- Record run: 124 records, rebuilt and formatted. Compared with Revision 0:
  120 unchanged, 4 changed, all deliberate:
  - Complete the text: the instruction line is the authored "Anna's
    morning before work.", the hint shows, and the greyed Play audio button
    is gone (a text exercise has no audio).
  - Missing letters (the example without audio): no Play audio button.
  - Put the sentences in order, the story: the instruction line sets the
    scene ("Anna stops at the bar for a coffee.").
  - Put the sentences in order, the dialogue: the instruction line, the
    hint and the extra line (five blocks instead of four).

**Tests**
- New: `test/complete_text_and_sentence_order_259_test.dart`, 16 tests:
  - Complete the text: the clue instruction and the hint (built,
    represented, decomposed), its form and Help, the Round (instruction,
    hint, no Play audio), the form's field order and save, the Audit's
    `HINT_REVEALS_ANSWER` for a hint that gives away a missing word;
  - the gap screen: Missing letters shows its hint, an empty hint draws no
    panel, a gap exercise with audio keeps Play audio;
  - Put the sentences in order: lines once with extra lines and a hint,
    item IDs kept by text and the stored item order (an exercise whose
    lines were stored out of order is still represented), a Published save
    needs two lines, every bundled example opens in its form, the Round
    (instruction and hint above the lines, no panel without a hint), Name
    what you see's hint;
  - the demo content: Piedmontese Lessons 18 and 21 can be worked out.
- The first focused run failed one new test: `represents` rebuilt from a
  blank original, so an exercise stored out of order could not be
  represented. `PresetRecipes.rebuild` now gives Put the sentences in order
  the stored items.
- Updated: the field Help tests (field lists, the Help UI table) and the
  Laboratory test's Complete the text question.
- `flutter analyze --no-pub`: no issues.
- **Complete suite** (11:53–12:25, `--concurrency=1`): **3395 passed,
  1 skipped, 0 failed**.
- Keep-awake: the wrapper script meant to hold `ES_CONTINUOUS |
  ES_SYSTEM_REQUIRED` failed to set it in this run and in Revision 0's two
  runs. PowerShell 5.1 reads `0x80000000` as a negative `Int32`, so the
  cast to `UInt32` failed; the suites ran and completed anyway. The script
  now uses `2147483648`.

## Revision 2 (2.0.59+259002, 30 September 2026): the Listen and answer split

**Generators and validator**
- Laboratory: 8 Lessons, 28 Rounds, 125 examples (48 generator preset
  names), `--check` reproducible.
- Piedmontese: 44 catalogue presets, 41 Lessons, 123 examples, `--check`
  reproducible.
- Edge Case: `--check` unchanged.
- v11 converter fixtures rewritten with their checksum; the future fixture
  changes only its checksum.
- `tools/validate_courses.py`: all three Courses pass (Piedmontese expects
  41 Lessons).

**Laboratory presentation baseline**
- Record run: 125 records, rebuilt and formatted. Compared with Revision 1:
  1 added, 2 changed, 122 unchanged; all deliberate:
  - added `listening_source_question` (Listen and answer (to source));
  - `select_listening_word` and `listening_source` (now Listen and choose):
    the authored instruction replaces "Listen and choose the correct
    answer.", and the text is counted as the prompt instead of the
    question.

**Tests**
- New: `test/listen_and_choose_259_test.dart`, 13 tests: the catalogue
  (order, names, twins, directions, base, kinds, required Question), its
  form, Search and Help keys in EN/IT/ES; Listen and choose (instruction
  without a language, the source twin marks only the answers, recognition
  for an exercise without a question, the Round's instruction line, the
  form); Listen and answer (Published needs the Question, a draft does
  not, a new one asks about the passage, the form's label, the Round's
  standard line and question); the demo content (Laboratory and
  Piedmontese).
- First focused run: 17 failures, every one a pin on the old catalogue
  (registry 44 presets, field Help and mascot tables, the runtime kind and
  Duel tables, the Round Wizard pools, "Question (optional)", the
  Piedmontese counts), plus the new test's field list, which gains
  `image` like every form. Updated; the Duel test's listening helper
  builds a Listen and choose (a Listen and answer without a question is
  now refused on a Published save).
- `flutter analyze --no-pub`: no issues.
- **Complete suite** (12:39–13:08, `--concurrency=1`, keep-awake wrapper
  now working): **3415 passed, 1 skipped, 0 failed**.

## Revision 3 (2.0.59+259003, 30 September 2026): the owner's review

**Generators and validator**
- Laboratory: 8 Lessons, 28 Rounds, 126 examples, `--check` reproducible.
  `complete_text_alternatives` joins its Round after the v11 conversion.
- Piedmontese: 41 Lessons, 123 examples, `--check` reproducible.
- Edge Case: `--check` unchanged.
- v11 converter fixtures rewritten with their checksum; the future fixture
  changes only its checksum.
- `tools/validate_courses.py`: all three Courses pass. It flagged the
  Piedmontese dictations once their redundant answer line was gone: it
  wanted an expression answer. It now counts a literal answer, as the
  Audit does.

**Laboratory presentation baseline**
- Record run: 126 records, rebuilt and formatted. Compared with Revision 2:
  1 added, 10 changed, 115 unchanged, all deliberate:
  - added `complete_text_alternatives`;
  - "Type the word that completes the sentence." for the three one-gap
    typed examples (`input_fragment`, `input_fragment_audio`,
    `input_gap_variants`) and "Type the missing letters." for Missing
    letters;
  - "Listen and answer the question." for the two Listen and answer
    examples;
  - WHAT IS IN THE PICTURE? for What is in the picture;
  - Type what you hear: the correct-answer line shows the Audio text
    ("Grazie.", "Il treno parte alle nove.") now that the redundant
    lowercase lines are gone; the variants example plays "Arrivo alle
    otto." under the instruction "Anna tells you when she arrives.".

**Tests**
- New: `test/owner_review_259_revision3_test.dart`, 17 tests, one or more
  per point A–G plus the eight learner languages.
- Point D was confirmed with a test before the fix. At 800 × 600 the Lab's
  small Sort into groups still showed Finish round. At 800 × 450, with
  Check scrolled to the bottom as a learner would, Finish round was not
  even built. The test runs at 800 × 450 and passes with the scroll.
- A wrong answer showed "Correct answer: Il treno": the expansion
  capitalizes a sentence start. The gap now keeps the author's small
  letter. A draft Complete the text without ___ reopened empty; it now
  keeps its text.
- Updated: the Revision 0–2 test files (the ___ text, the listening and
  arranging lines), the field Help and form tables, the editor and
  workflow tests (the box label), the Audit test (a literal answer
  counts), the runtime kind table, the Laboratory test (literal-only
  answers, expression gaps, 126 examples) and the Piedmontese test.
- `flutter analyze --no-pub`: no issues.
- **Complete suite** (16:15–16:44, `--concurrency=1`, keep-awake):
  **3435 passed, 1 skipped, 0 failed**.

## Revision 4 (2.0.59+259004, 30 September 2026): the second review

**Generators and validator**
- Laboratory: 8 Lessons, 28 Rounds, 124 examples, `--check` reproducible.
- Piedmontese: 41 Lessons, 123 examples, `--check` reproducible.
- Edge Case: regenerated (e17–e19 fill their gaps with words), `--check`
  reproducible. Its v11 fixture is updated only for the Lesson's GuideBook
  line and the gap Round. The fixture was already behind its generator on
  the Course description, version and date, and its checksum was already
  stale; both are left as they were, because the parity test compares
  exercises.
- v11 fixtures of the Laboratory and the Piedmontese demo rewritten with
  their checksum.
- `tools/validate_courses.py`: all three Courses pass.

**Laboratory presentation baseline**
- Record run: 124 records, rebuilt and formatted. Compared with Revision 3:
  2 added (`select_gap_all_article`, `select_gap_all_verb`), 4 removed (the
  reusable-option gaps `select_gap_one`, `_distinct`, `_reuse`, `_audio`),
  5 changed:
  - "Build the word you hear." for Spell what you hear (2);
  - "Build the word that matches the clue." for Spell the word (2);
  - Name what you see's hint "Include the article.".

**Tests**
- New: `test/owner_review_259_revision4_test.dart`, 15 tests covering
  points 1, 2, 3, 4–7, 8 and 9 and the eight learner languages.
- Updated to the owner's decisions:
  - the gap editor, builder and characterization tests (`_word_`, Pick the
    words for the gaps, a word needed twice offered twice);
  - the Select editor tests: a Select whose option fills two gaps is
    represented by no preset;
  - the field Help and form tables, and the mascot, runtime-kind and Duel
    tables;
  - the Laboratory test (the `_word_` reconstruction, a picture row found
    by its picture, 124 examples);
  - the Edge Case, Revision 0, Revision 1 and Revision 7 tests.
- **First complete suite** (18:57–19:42): 3444 passed, 1 skipped, 1
  failed. `select_gap_fill_238_test` expected a converted v11 Choose with
  gaps to pass the Audit with no issue. The converters still tagged it
  with the retired `gap_choice_inline`, so the Audit reported a preset that
  no longer fits it. Both converters (Dart and Python) now record no
  preset for such a Choose. The generators' output is unchanged; the
  converter, Select and parity tests pass.
- `flutter analyze --no-pub`: no issues.
- **Second complete suite** (19:45–20:22, `--concurrency=1`, keep-awake):
  **3445 passed, 1 skipped, 0 failed**.

## Revision 5 (2.0.59+259005, 30 September 2026): the third review

**Generators and validator**
- Edge Case: the generator writes `demo_courses/edge_case_it_en.json` (the
  custom Course to import) and `test/fixtures/v12/edge_case_it_en.json`
  (the former asset, moved with `git mv` and byte-identical); `--check`
  reproducible for both.
- Laboratory: `--check` reproducible (8 Lessons, 28 Rounds, 124 examples);
  only the coverage document's "Match pictures to words" label changed.
- Piedmontese: regenerated for the renamed Lesson (title, Round title and
  Before you start card, new checksum); `--check` reproducible (41 Lessons,
  123 examples). Its v11 fixture rewritten with its checksum (the same
  three texts).
- `tools/validate_courses.py`: the two bundled Courses pass.

**The exported Course**
- The app's own export (`buildCourseExport`) of the Course to import was
  written by a throwaway test, deleted afterwards, to the owner's
  `Documents/QuisquisLingo/Import/Courses/QQL_IT_EN_temporary_demo_edge_case_course.zip`
  (12,614 bytes). It is not in the repository.

**Laboratory presentation baseline**
- Record run: 124 records, rebuilt and formatted. Compared with Revision 4:
  none added or removed, 10 changed, all Dialogue lines, whose instruction
  line is gone (`options_*` and `story_*`).

**Tests**
- New: `test/owner_review_259_revision5_test.dart` (the name, two words,
  no Exercise image, the bundle); the Edge Case test imports the Course to
  import as JSON and as the exported ZIP (custom, same Lessons, the three
  intentional warnings, Fork allowed, installed); the Match form test
  refuses a single word and shows no Exercise image.
- Updated: the Story tests (no "Now · step", no line instruction), and
  every test that read the Edge Case as a bundled Course. Those that need
  it bundled register the fixture (`registerEdgeCaseFixture`); the rest
  read the Course to import or the fixture file.
- `leaderboard_navigation_test` registers the fixture only in its three
  Edge Case tests. Registered for the whole file, the extra Course made
  "Home reloads the selected custom course after returning from Settings"
  fail (reproducible alone, passing without the fixture). As the last
  Selector row, the Edge Case needed `ensureVisible` before its tap.
- Focused run: 428 tests, 4 failures fixed as above (the Piedmontese v11
  fixture, the Story "Listen first" line, the two Selector tests); then
  the Laboratory authoring test found the two-word check reading the wrong
  field (the form sends the words as `picture = word` lines), fixed.
- `flutter analyze --no-pub`: no issues.
- **Complete suite** (22:45–23:12, `--concurrency=1`, keep-awake):
  **3451 passed, 1 skipped, 0 failed**.

## Revision 6 (2.0.59+259006, 1 October 2026): QQL Demo: Piedmontese

**Generators and validator**
- `tools/generate_piedmontese_mixed_259.py --check`: reproducible (2
  Lessons, 20 mixed Rounds of 6 and the Story). The generator asserts that
  it takes 120 exercises, that every Round has a scored exercise and that
  no ID of the source Course is left.
- Piedmontese: regenerated for the new title; `--check` reproducible. Its
  v11 fixture rewritten with its checksum (the title only).
- Laboratory and Edge Case: `--check` reproducible, unchanged.
- `tools/validate_courses.py`: the three bundled Courses pass (an empty
  GuideBook is accepted when `useGuidebook` is false).

**Tests**
- New: `test/piedmontese_mixed_259_test.dart` (the registry code and the
  Piedmontese language code, JSON round trip and checksum; the same 120
  exercises as the source with IDs set aside; no Round of one type;
  20 Rounds of a card and six exercises, each with a scored one; the
  Story unchanged; no GuideBook; no Audit error or warning).
- Updated: the bundled-course counts and titles (provenance, registry,
  Audit of the bundle, Course Library and Selector counts, discovery), the
  Editor Help question count (67) and the Beta expiry dates (shifted by
  one day).
- `flutter analyze --no-pub`: no issues.
- **First complete suite** (01:48–02:14, `--concurrency=1`, keep-awake):
  3454 passed, 1 skipped, 1 failed: `owner_review_259_revision5_test`
  pinned the bundle at two Courses. It now checks only that the Edge Case
  left it.
- **Second complete suite** (02:15–02:42): **3455 passed, 1 skipped, 0
  failed**.
