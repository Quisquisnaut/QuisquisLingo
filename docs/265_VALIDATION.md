# Build 265 validation

## Revision 11 (2.0.65+265011, 7 October 2026): plural pictures

- `test/plural_pictures_265_test.dart`: 11 passed (the mark through JSON,
  refused on other elements; the getters; the minimum build; the
  capability description; marks applied and read back, Select the image
  still represented for a Course picture and a QQL icon key; the editor's
  Plural chips; `PluralPicture` three copies in one box; the Round draws
  the plural answer).
- Focused tests (the plural test, capabilities, the v12 model, Duel
  eligibility, the Help and field-Help tests, Match grading, negative
  cases, preset recipes, the canonical editor, semantic equality, the
  picture-answer and Fill-with-an-example reviews, the version tests):
  368 passed.
- `python tools/validate_courses.py`: both bundled Courses OK;
  `dart run tools/export_capabilities.dart` regenerated
  `docs/capabilities_v12.json` (the `plural` entry only).
- The look checked on a rendered sheet with QQL pictures (cat, apple, car,
  chair, one and plural): as the owner's mock-up A.
- `dart format` on the changed Dart files (not the Help catalogs, whose
  older entries are unformatted); `flutter analyze`: no issues.
- Added at the owner's word while testing: spelling needs two blocks and
  has Extra blocks with a note (`test/spelling_blocks_265_test.dart`, 13
  tests); nine family scenes, Man 2/3, Woman 2/3, Friends (women)
  (`test/family_scenes_265_test.dart`); `python tools/validate_images.py`
  2.9.0: 4,334 records, 4,020 WebP files, **0 issues**;
  `tools/validate_media_assets.py`: 4,380 files, 0 issues; six family
  scenes got the grey ring (their yellow ring makes a light edge).
- Complete suite, first run (`--concurrency=1`, 7 October 2026, 17:18–
  17:50): 3,854 passed, 1 skipped, **3 failed**: the script recognition
  candidate no longer crossed the builder as the same object
  (`PluralPictures.withMarks` copied an unchanged exercise: it now returns
  it), the library test found Man's tag line three times (Man 2 and 3
  share it: it reads Man's own tile), and a Build 256 test pinned "no
  recipe represents a spelling exercise with an extra block" (now Extra
  blocks represent it). Those tests passed after the fixes (50).
- Complete suite on the final tree (17:54–18:27): **3,857 passed, 1
  skipped, 0 failed**.

## Revision 10 (2.0.65+265010, 7 October 2026): historical figures and landmarks

- Catalogue: applied by a script from the Revision 9 commit; 0 problems;
  4,320 records, 66 historical figures, 30 landmarks; the only new tags
  equal to another picture's name are the country tags (the flags).
- `python tools/validate_images.py` (2.9.0): 4,320 records, 4,006 WebP
  files, 284 World Flags, 30 Lesson icons, 1,248 character pictures,
  **0 issues**. `python tools/validate_media_assets.py`: 4,366 files,
  0 issues.
- Drawings reviewed on contact sheets. Figures: eight redrawn after
  review (Bach's organ, Louis XIV's crown, Queen Victoria's veil,
  Catherine's dress, Mansa Musa's robe, Hokusai's wave twice, King
  Sejong's hat, the Trưng Sisters closer). Landmarks: Gyeongbokgung
  Palace's mountain raised above the roof. Nine pictures got the grey ring
  (six figures; Arc de Triomphe, Belém Tower, Parthenon).
- Focused tests (the new `figures_and_landmarks_265_test`, the catalogue
  rules and tags tests, the groups test, the manifest and metadata tests,
  the namesake test, the version tests): 78 passed; `flutter analyze`: no
  issues. `dart format` on the new test only.
- Complete suite: not run, at the owner's word.

## Revision 9 (2.0.65+265009, 7 October 2026): category groups

- `dart format` on the changed Dart files only; `flutter analyze`: no
  issues.
- Focused tests: the new `image_category_groups_265_test`, the library,
  categories, namesake, tag filter and rules tests, the Image Bank import
  tests (category mapping), the Help and QQL Guide tests, the catalogue
  rules and tags tests and the version tests: all passed (one edited test
  needed its group chip scrolled fully into view first).
- No catalogue change, so the image validators were not rerun.
- Complete suite: not run, at the owner's word ("skip the next full
  suite").

## Revision 8 (2.0.65+265008, 7 October 2026): group 4 tags; five tags become a rule

- Catalogue: applied by a script from the Revision 7 commit; 0 problems;
  no record outside the character categories below five tags; at most 15
  tags on a record, longest tag 52 characters.
- `tools/validate_images.py` 2.9.0 (now refusing fewer than 5 tags outside
  the characters, more than 32, or a tag over 80 characters): 4,259
  records, 3,945 WebP files, 284 World Flags, 30 Lesson icons, 1,248
  character pictures, **0 issues**. The new check was tried on in-memory
  records first: an animal with 2 tags, one with 33 tags and one with an
  81-character tag were refused; a character picture with 1 tag passed.
- `python tools/validate_media_assets.py`: 4,305 files, 0 issues.
- Focused tests (24 files: the catalogue rules with the new rule test, the
  Revision 5 test with every category complete, the library, metadata and
  version tests): 206 passed.
- `dart format` on the changed Dart files only; `flutter analyze`: no
  issues.
- Complete suite: not run, at the owner's word ("skip the next full
  suite").

## Revision 7 (2.0.65+265007, 7 October 2026): group 3 tags

- Catalogue: applied by a script from the Revision 6 follow-up commit; 0
  problems; group 3: 0 records below five tags; no new tag shared by two
  records. Descriptive tags were checked against two contact sheets of the
  drawings before applying (15 replaced, listed in the change summary);
  the Revision 6 pictures with descriptive tags were checked too (one
  correction, Hot).
- `python tools/validate_images.py` 2.8.0: 4,259 records, 3,945 WebP files,
  284 World Flags, 30 Lesson icons, 1,248 character pictures, 0 issues;
  tag report: 515 records below five tags (group 4).
- `python tools/validate_media_assets.py`: 4,305 files, 0 issues.
- Focused tests: the catalogue, library and version tests (24 files): 203
  passed, after two older tests that pinned the Man picture's tags were
  updated.
- `dart format` on the changed Dart files only; `flutter analyze`: no
  issues.
- Complete suite: **not run to the end, at the owner's word** ("skip the
  full suite and go on with next revision", 13:30). The run started at
  11:52 stopped making progress at 12:06 inside
  `guidebook_insights_226_04_r2_test.dart` (1,756 tests passed, none
  failed); that file passes alone (2 tests, 17 s). Cause found afterwards:
  `D:\QQL_test_temp` held 1.8 GB left by the runs stopped earlier and D:
  had 1.4 GB free; the folder (disposable test files) was emptied, D: is at
  3 GB free. The runner now passes `--timeout 10m`, so a hung test fails
  instead of blocking.

## Revision 6 (2.0.65+265006, 7 October 2026): group 2 tags, personal pronouns, friends, kids, greetings

- Pictures: 15 SVG drawings rendered by
  `D:\QQL_plus\nuove_immagini\serie7_265\draw6.py` (the `draw.py`
  pipeline, taller-window fix included): every WebP 256 × 256, lossless,
  12–20 KB, transparent margin 15 px. `tools/outline_light_edges.py`: five
  had a light edge of 26–35% (yellow halos, the girl's skin) and got the
  grey edge, as the library's "I am" and "We are" did. A first review sheet
  showed the high-five palms overlapping, the kid boy's hair reading as a
  cap, Bye's backpack straps outside the body and "Goodbye!" too wide for
  its bubble: redrawn before copying. Vest and Mango re-rendered by the
  patched `serie1_rifatte/redo.py` and compared with the Build 264 files
  (shadows whole now); Football goal unchanged.
- Catalogue: applied by a script from the Revision 5 commit; 0 problems
  (names unique per category, no tag equal to its name, at most 15 tags,
  longest tag 52 characters); group 2: 0 records below five tags. Every new
  tag checked against the other pictures' names and tags; the replaced
  words are listed in the change summary.
- `python tools/validate_images.py` 2.8.0: 4,259 records, 3,945 WebP files,
  284 World Flags, 30 Lesson icons, 1,248 character pictures, 0 issues; tag
  report: 1,061 records below five tags (groups 3–4).
- `python tools/validate_media_assets.py`: 4,305 files, 0 issues.
- Focused tests: catalogue rules, the updated Revision 5 test with the
  Revision 6 groups, the three older tests that pinned "Saltare" or Jump's
  tags, and the version pins: 86 passed; the other tests that read the
  catalogue (9 files): 116 passed.
- `dart format` on the changed Dart files only; `flutter analyze`: no
  issues.
- First complete run (09:52–10:24): 3813 passed, 1 skipped, **1 failed**:
  `unified_learner_layout_regression_test` keeps the retired path
  `assets/exercise_images/hello.webp` unused, and the new Hello! picture
  had taken it. The file is now `hello_greeting.webp` (ID unchanged); the
  regression test and the catalogue tests (5 files): 29 passed. Complete suite on the final tree (`--concurrency=1`, 10:26–10:56): **3814 passed, 1 skipped, 0 failed**.

### Revision 6 follow-up: Friend (woman) with two women

- `friend_woman.webp` redrawn by `draw6.py` with a woman in the speaker's
  place; no grey edge needed; catalogue unchanged.
- Focused (catalogue rules, Revision 5/6 tests, media integrity, the
  learner-layout regression): 27 passed; `validate_media_assets.py`: 0
  issues. Complete suite (11:11–11:43): **3814 passed, 1 skipped, 0 failed**.

## Revision 5 (2.0.65+265005, 7 October 2026): image library tags, a redrawn picture, ten new pictures

- Pictures: eleven SVG drawings rendered by
  `D:\QQL_plus\nuove_immagini\serie7_265\draw.py` (headless Chrome at 4x,
  longest side 220, centred): every WebP 256 × 256, lossless, 10–26 KB,
  transparent margin 15–17 px; `tools/outline_light_edges.py --dry-run` on
  the eleven: 0 to outline (light edge 0–13%). A review sheet of the
  eleven beside Tennis showed the Asteroid's circle cut flat at the bottom:
  headless Chrome paints about 100 pixels less than its window height, so
  `draw.py` now renders into a taller window and crops; all eleven
  re-rendered and checked again (the Asteroid round, every shadow whole).
- Catalogue: applied by a script from the Revision 4 catalogue; 0 problems
  (no tag equal to its name, no repeated tag, at most 15 tags, longest tag
  52 characters); group 1: 0 records below five tags. Every new tag checked
  against the other pictures' names and tags; the tags another picture
  answers better were replaced (listed in the change summary).
- `python tools/validate_images.py` 2.8.0 on the final files: 4,244 records, 3,930 WebP files, 284 World Flags, 30 Lesson icons, 1,248 character pictures, 0 issues; tag report: 1,600 records outside the character categories below five tags (groups 2–4), group 1 none.
- `python tools/validate_media_assets.py`: 4,290 files, 0 issues.
- Focused tests: the new `test/image_library_tags_265_test.dart` (6) with
  the catalogue rules and the version pins: 43 passed. The other tests that
  read the catalogue: three pinned Man's "friend" or Jump's three tags
  (`exercise_image_manifest_234_test`, `exercise_image_metadata_234_revision_test`,
  `flat_image_library_234_test`) and one searched "friend" to open Man
  (`exercise_image_metadata_admin_ui_234_revision_test`, now "adult man"):
  updated; the 17 test files that read the catalogue then passed.
- `dart format` on the changed Dart files only; `flutter analyze`: no
  issues.
- A first complete run was stopped after two minutes, to re-render the
  pictures (above). Complete suite on the final tree (`--concurrency=1`, 7 October 2026, 01:57–02:27): **3812 passed, 1 skipped, 0 failed**.

## Revision 4 (2.0.65+265004, 6 October 2026): distractor and Match limits become recommendations; Word Lookup fixes

- New `test/match_repeated_values_265_test.dart` (4): a Match with two
  "Ciao" rows is right with either matching (both orders), wrong with the
  same answer for both; Listen and match with two identical sounds is right
  with either matching.
- `test/course_audit_test.dart`: the Audio Match duplicates are Info and
  say "This may be deliberate"; Spell the word with one and with three
  extra blocks gives one `WORD_BLOCK_DISTRACTOR_COUNT` Info each (the
  draft gave only Info from three blocks and a Warning below). Registry
  counts 66 Errors, 14 Info.
- First focused run (9 files): 97 passed after a quoting error in the
  registry (`Lesson's` in a single-quoted string) was fixed.
- `dart format` on the changed Dart files except the three Help catalogs;
  `flutter analyze`: no issues.
- Audit, Help, localization, Match and Laboratory tests (19 files): 471
  passed.
- A first complete run was stopped after a few minutes when the owner
  asked to fix the review's Word Lookup defects in this revision.
- Word Lookup fixes: a widget test written before the fix showed the card
  closing when dragged inside (15 entries, the page still at offset 0);
  `word_lookup_ui_265_test` now keeps that case ("scrolling inside a long
  card keeps it open"). `word_lookup_265_test` gains `d'acqua`,
  `dell'acqua`, `un'amica` finding the article expression, the quotation
  marks group (‘gatto’ and 'gatto' found and highlighted without the mark,
  an expression inside quotes, `di'` and `po'` as written winning, marks
  without the closing quote), and keeps *Tom's* never borrowing *it's ten
  o'clock*. A first attempt in the tokenizer (tracking opening quotes) was
  undone before testing: a leading apostrophe is also an elision
  (Neapolitan *'o sole*, English *'em*). Word Lookup tests (5 files): 83
  passed.
- `flutter analyze`: no issues. Complete suite on the final tree
  (`--concurrency=1`, 6–7 October 2026, 23:46–00:19): **3806 passed, 1
  skipped, 0 failed**.

## Revision 3 (2.0.65+265003, 6 October 2026): the Lab's vocabulary; articles in Word Lookup

- Generators: `python -X utf8 tools/generate_exercise_laboratory_254.py`
  and `--check`; `python tools/generate_english_from_italian_260.py` and
  `--check` (PASS); the v11 fixture writer; `tools/validate_courses.py`:
  both bundled Courses OK.
- New `test/lab_vocabulary_265_test.dart` (8): the Lab's title and Lesson
  titles, 10–15 entries per Lesson that parse and reach Review vocabulary,
  98 entries in the index; the Round Wizard plans from every Lesson;
  `dov'è` and `l'acqua` whole; "acqua", "treno", "divano" inside articles'
  expressions; `un caffè` a coffee / an espresso and `il caffè` coffee /
  espresso by Lesson; a lone "il" finds nothing; "d'Italia" shows `Italia`;
  English from Italian's mass nouns without "the" ("bread" in "I like the
  bread." finds `il pane`).
- `test/word_lookup_265_test.dart`: the index helper passes Italian
  articles; "an article alone finds nothing"; "only articles may stand
  beside the word" ("è" no longer finds `dov'è`, "caffè" finds `il caffè`
  and `un caffè` but not `il suo caffè`); the owner's idiom
  `una lavata da gatto = a quick wash` shows only where the text uses it;
  English articles ("platform" finds `the platform`), no list for an
  unknown language; common words counted on distinct entries (34 tests).
- `test/guidebook_vocabulary_265_test.dart` expects `water` and `bread`.
- `dart format` on the changed files; `flutter analyze`: no issues. Word
  Lookup tests (6 files): 82 passed. Lab, Review, Round Wizard, Help,
  conversion and Course tests (20 files): 391 passed.
- After the owner's requests of the evening (dotted marks, gapped texts,
  narrower hints, the Page's "at the bar", the notice's three sentences,
  the Lesson only from another Lesson, the plural line): `word_lookup_ui_265_test` (26:
  marks drawn under words with entries and none otherwise, the Lesson line
  only for another Lesson, the new notice) and the Lab, Page, gap, Assign
  and conversion tests: 358, 343 and 31 passed (one compile error in a new
  test name, fixed). The presentation baseline's four hint lines follow
  the new hints.
- `tools/validate_courses.py`, `validate_images.py`,
  `validate_media_assets.py`, `check_world_flags_generator.py` and `git
  diff --check`: 0 issues; both demo generators `--check`: reproducible.
- Complete suite on the final tree (`--concurrency=1`, 6 October 2026,
  20:32–21:08; a first run stopped when the PC ran out of memory and was
  started again): **3796 passed, 1 skipped, 0 failed**.

## Revision 2 (2.0.65+265002, 6 October 2026): keyboard, screen readers, the Lab's name

- `test/word_lookup_ui_265_test.dart` gains three tests (23): Tab reaches
  the question and Enter lists `il gatto`, `dorme`, `il pane`, Enter again
  closes; the semantics node of the question carries "Vocabulary in this
  text" and performing it opens the same card; a text with nothing to look
  up has no lookup focus. First run 23 passed.
- Rename: `python -X utf8 tools/generate_exercise_laboratory_254.py` and
  `--check` (8 Lessons, 28 Rounds, 124 examples, 48 presets);
  `tools/validate_courses.py` OK. The v11 fixture writer (scratchpad
  `rev2/write_lab_v11_fixture.py`) reproduced the committed fixture exactly
  from the unchanged generator, then wrote the renamed one (title, credit
  title, checksum).
- Related tests (keyboard, learner panel, Korean discovery, provenance,
  Before you start, v11 conversion parity, Laboratory of the future,
  preset examples, Laboratory presentation, bundled Courses, demo package,
  media credits): 352 passed.
- Windows Narrator: not run in this session (no screen reader available
  to the agent); the owner may check that Narrator reads the text and
  offers "Vocabulary in this text".
- `dart format` on the changed files (not the three Help catalogs, whose
  older entries are unformatted); `flutter analyze`: no issues.
- Complete suite on the final tree (`--concurrency=1`, 6 October 2026,
  18:52–19:28): **3781 passed, 1 skipped, 0 failed**.

## Revision 1 (2.0.65+265001, 6 October 2026): Word Lookup on the learner's screen

- First run of the affected tests (23 files reading the changed texts):
  40 failures, all from tests reading `Text.data` of lines that had become
  `Text.rich` (the correct-answer line with its label, the "• " feedback
  lines). `LookupText` now draws the plain `Text` with the whole line as
  its `data` whenever nothing is styled or highlighted; rerun: 299 and 249
  passed.
- New `test/word_lookup_ui_265_test.dart` (20): a tap opens the card with
  the entry, its Lesson and the note; a word without an entry does nothing
  and keeps the plain `data`; the expression wins and another word replaces
  the card; Escape, a tap elsewhere, a second tap and scrolling close it;
  nothing is written to the learner's settings; no lookup in a Test Round,
  with Use GuideBook off, with Word Lookup off, on source-language text, on
  the authored Instruction, or in the panels without a scope (the Duel);
  the Preview looks up; a Page paragraph keeps its bold word and looks it
  up; a Story line in the learning language looks up, the source-language
  narrator does not; the notice once per learner and Course, again after
  Show one-time notices again, never in the Preview or with lookup off;
  `wordLookup` stored only when off, strict, kept by Copy as New Course;
  Lesson Options shows the switch only while Use GuideBook is on.
- Changed tests: the Editor Help counts (83 → 84 questions).
- Help, model, Merge and copy tests (25 files): 229 passed.
- `dart format` on the changed files (its unrelated reflow of the Image
  Library Help entries in the three Help catalogs undone); `flutter
  analyze`: no issues. UI, Help and version tests: 66 passed.
- Complete suite on the final tree (`--concurrency=1`, 6 October 2026,
  18:05–18:37): **3778 passed, 1 skipped, 0 failed**.

## Revision 0 (2.0.65+265000, 6 October 2026): one vocabulary reader, the lookup rules

- `python tools/generate_english_from_italian_260.py`, then `--check`:
  PASS (reproducible; 1 Lesson, 6 mixed Rounds of 6 and 2 Stories).
  `python tools/validate_courses.py`: both bundled Courses OK.
- A Dart check of the regular expressions before writing the tokenizer:
  `\p{Script_Extensions=…}` matches Han, Hiragana, Katakana (the long-vowel
  mark ー too), Thai with its marks, Lao, Khmer, Myanmar, Tibetan, and also
  CJK punctuation (。), which the tokenizer then drops because it is not a
  letter, mark or number.
- New tests:
  - `test/guidebook_vocabulary_265_test.dart` (5): the four separators in
    order, lines without two sides, English from Italian's 36 entries
    English first, Review vocabulary's prompt `thank you` → `grazie`, the
    Round Wizard planning "Foundations: hello, hi".
  - `test/word_lookup_265_test.dart` (30): every example of the plan
    (Mangio il pane, il pane fresco, l'acqua / l' + acqua, papa ≠ papà,
    e ≠ è, gatto in il gatto, the more-than-three rule, the Lesson rule,
    nothing found, gaps, 我的猫, a Japanese sentence, Thai with marks,
    Latin inside Han, Tom's against it's ten o'clock, you're welcome),
    tappable ranges, all entries of a text, the cache.
  - `test/word_lookup_sources_265_test.dart` (5): Published entries of
    every Lesson for the learner; Drafts in the Preview; nothing with Use
    GuideBook off; English from Italian's real lines (the train, the
    platform, thank you, what time is it?) and its Italian words never
    searched.
- Changed test: `english_from_italian_260_test` expects `thank you` →
  `grazie`.
- `dart format` on the changed files; `flutter analyze`: no issues.
- Focused batch (24 files: the new tests, Review vocabulary and Review
  flow, the Round Wizard and Round types, bundled Courses, demo package,
  flashcards, difficulty curve, Course Model v12, provenance, Course
  service, Edge Case, exercise titles, Course preview, version pins):
  **174 passed**.
- Complete suite on the final tree (`--concurrency=1`, 6 October 2026,
  17:04–17:35): **3758 passed, 1 skipped, 0 failed**.
