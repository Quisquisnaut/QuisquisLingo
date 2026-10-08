# Build 264 validation

## Revision 10 (2.0.64+264010, 6 October 2026): categories and tags as one; the image library's Help

- Measure for the decision: 4,234 pictures, 93 categories, 9,351 tags
  (1,645 on two or more pictures); 32 categories also exist as a tag.
- New `test/image_library_namesake_264_test.dart`: the singular rule
  (cats, boxes, berries, glasses, ice creams, body_parts; news, bus,
  glass, cactus kept), the namesake tag and category, characters and Other
  left out, the plural in Search, Restaurant showing more than its own
  pictures on the catalog; on screen the title without the number, the
  count at the right of the badge row following the Restaurant chip, and
  the question mark opening the Help. First run: the chip tap missed (the
  chip row stops scrolling with the chip at its edge); the test brings it
  fully into view; then 7 passed.
- `flutter analyze`: no issues. Library, Help and catalog tests (28
  files): two expected failures fixed in the tests (the QQL Guide's list
  of Help pages gains `image-library`; `flat_image_library_243_source_test`
  reads the count beside the badges instead of the title); rerun 7 passed.
- Related tests after the version and docs (84 files: library, catalog,
  Help, QQL Guide, Editor Help, version pins): 904 passed.
- `flutter analyze`: no issues. Complete suite on the final tree
  (`--concurrency=1`, 6 October 2026, 14:47–15:17): **3718 passed, 1
  skipped, 0 failed**.

## Revision 9 (2.0.64+264009, 6 October 2026): the World Flags tool matches the bundle

- Downloads (owner's go): five current Commons sources differ from the
  bundled pins (Ligurian, Lombard, Mirandese, Romansh, Venetian), West
  Frisian's matches, Neapolitan's and Piedmontese's were refused (HTTP 429);
  nothing downloaded is bundled.
- Comparison of the old tool with the bundle: 10 of 19 pins differ, 5
  flags and 5 suggestions missing, 4 hand-chosen colour sets.
- `scratchpad/flagtool/patch.py` applied to a copy and checked offline
  (`check.py`, downloads disabled) until: every language flag from its
  bundled bytes, every entity equal to the manifest's, suggestions equal,
  the notice different only in Mirandese's and Venetian's license links
  and Romansh's author separator (accepted; the notice is now the tool's).
  Then applied to `tools/generate_world_flags.py`.
- `tools/check_world_flags_generator.py`: 24 language flags checked
  offline, 0 issues. `tools/validate_images.py` 2.7.0 and
  `tools/validate_media_assets.py`: 0 issues.
- Focused: the 37 test files that read the World Flags, their notice or
  the credits: 334 passed.
- `flutter analyze`: no issues.
- Complete suite on the final tree (`--concurrency=1`, 6 October 2026,
  05:43–06:12): **3708 passed, 1 skipped, 0 failed**.

### Follow-up in the same version: the Duel (6 October 2026)

- The Viterbese Course (`D:\QQL_plus\Corsi_Privati\custom\
  QQL_IT_VIT_viterbese_per_italiani.json`): six "Che cos'è?" exercises,
  preset What is in the picture?, each with a `picture` image that exists
  (boy, baby, window, chair, egg, cheese); the Round draws it, the Duel
  did not.
- `test/celebrations_264_test.dart`: three new tests (the picture shown,
  none without one, "Final Duel" once, in the top bar, and "Lesson 1: L"
  as the heading); 10 passed. First version dropped the heading; the owner
  asked to change it instead (the Lesson's name, chosen over "Language
  Duel"). The 28 test files that open the Duel or read the learner panel
  texts: 368 passed, 1 failed, `learner_panel_260_test.dart` expecting the
  Italian "Duello linguistico" heading; it now reads the Lesson heading;
  rerun with the Duel tests: 15 passed.
- `flutter analyze`: no issues. Complete suite on the final tree
  (`--concurrency=1`, 6 October 2026, 13:57–14:27): **3711 passed, 1
  skipped, 0 failed**.

## Revision 8 (2.0.64+264008, 6 October 2026): Lesson icons, sixteen new and any library picture

- The 16 delivered icons are 256 × 256 non-interlaced RGBA PNGs with
  transparency, but have 391–1,252 exact colours (smooth edges, a cream
  fifth colour in some): the four-colour rule refused them; the owner kept
  them as drawn. Flat-style measure: old icons 3–4 groups at 100%, new
  5–11 groups at 91.3–96.3%. `tools/validate_lesson_icons.py`: 30 assets,
  0 issues.
- `tools/validate_images.py` 2.7.0: 4,234 records, 3,920 WebP files, 284
  World Flags, 30 Lesson icons, 1,248 character pictures, 0 issues;
  `tools/validate_media_assets.py`: 4,280 files, 0 issues;
  `tools/validate_courses.py`: the two bundled Courses OK.
- New `test/lesson_icon_library_264_test.dart`: every QQL WebP qualifies as
  a library icon and no flag does; `Lesson.fromJson` reads and writes one
  and refuses a flag, capitals, `..` and `media:`; the Audit accepts it;
  the minimum build is set for a library icon and a new icon, kept when
  already set; two widget tests choose Bread and the library's Music icon
  through `lesson-icon-from-library`. First runs: a Course needing 264008
  was refused while the app was still 264007 (the version moved first),
  and a Course needing a later build cannot be built in a test (that case
  now checks one already at 264008). `image_catalog_rules_264_test` checks
  the lesson icon records one to one; `lesson_metadata_and_icon_test`
  counts 30 icons.
- `flutter analyze`: no issues.
- Focused: the 105 test files that read Lesson icons, the Audit codes,
  minimum builds, Editor Help, the image catalog or the library, and the
  version pins: 1,234 passed, 2 failed, both in
  `image_validator_tranche2_test.dart`: its import tests add the Home
  Lesson icon to Shared Images, which is now a QQL picture of the library,
  so QQL rightly refused it as a duplicate. They now add the same icon
  with a comment chunk (`_ownPng`); rerun 12 passed, and the seven other
  files that read the Home icon as a fixture: 77 passed.
- Complete suite on the final tree (`--concurrency=1`, 6 October 2026,
  05:05–05:35): **3708 passed, 1 skipped, 0 failed**.

## Revision 7 (2.0.64+264007, 6 October 2026): everyday objects and toy-block letters

- Staging (`scratchpad/integrate123/stage.py`, on the Revision 6
  catalog): 136 records (110 objects, 26 letters), 30 objects outlined,
  7 category changes, 136 tags equal to the name dropped (every record
  keeps at least one tag), no ID, file or name already taken.
- `tools/validate_images.py` 2.6.0: 4,204 records, 3,920 WebP files, 284
  World Flags, 1,248 character pictures (the glyph check accepts the
  block letters), 0 issues; `tools/validate_media_assets.py`: 4,264
  files, 0 issues; `outline_light_edges.py --catalog --dry-run`: 0.
- Focused: the 70 test files that read the image catalog, the categories
  or Help, and the version pins: 809 passed.
- `flutter analyze`: no issues.
- Complete suite on the final tree (`--concurrency=1`, 6 October 2026,
  03:43–04:11): **3700 passed, 1 skipped, 0 failed**.

## Revision 6 (2.0.64+264006, 6 October 2026): 798 new pictures

- Deliveries (`scratchpad/series4/check_delivery.py`): series 4 295/295,
  series 5 13/13, series 6 490/490 files as listed, each with its SVG;
  lossy WebP with alpha, 256 × 256, 2.4–25.5 KB, subject 220–222 px,
  margins 17–18 px; man/woman framing within 9 px; 0 issues.
- Visual review: contact sheets of all 798 (`sheets/`), the doubtful ones
  enlarged with the grey edge (`zoom.png`): Border collie, Hand luggage,
  Sunbed, Single/Double room, Frost, Disgusting, Sprained ankle, Ski
  resort, Speedboat read correctly; nothing to redraw.
- Staging (`scratchpad/integrate456/stage.py`, the catalog's JSON checked
  to round-trip unchanged first): 798 records, 136 outlined (highest share
  after the edge 12.4%), 18 job names to Title Case, Monk renamed; the
  catalog's rules asserted (QQL category, name unique in its category,
  tags present, unique, none equal to the name, IDs and paths unique).
- `tools/validate_images.py` 2.6.0: 4,068 records, 3,784 WebP files, 284
  World Flags, 1,222 character pictures, 0 issues;
  `tools/validate_media_assets.py`: 4,128 files, 0 issues;
  `tools/outline_light_edges.py --catalog --dry-run`: 0 to outline.
- Focused: the 66 test files that read the image catalog, the library or
  Image Banks, the Laboratory and the Duel, and the version pins: 978
  passed.
- `flutter analyze`: no issues.
- Complete suite on the final tree (`--concurrency=1`, 6 October 2026,
  03:00–03:29): **3700 passed, 1 skipped, 0 failed**.

## Revision 5 (2.0.64+264005, 6 October 2026): tags that open their pictures

- Measure for the decision: 6,889 different tags in the catalog, 5,787 on
  one picture only, 297 on five or more; the search's "contains" finds
  63 pictures for "cat", 43 for "red", 163 for "man", the exact tag far
  fewer ("cat": Cat and 猫).
- New `test/image_tag_filter_264_test.dart`: `carriesImageTag` (tag, Local
  word and name; capitals and spaces; never part of a word; on the
  catalog narrower than the search) and two widget tests on a tag chosen
  from the catalog (today "baking" from Bake: Bake, Flour, Cake
  Decorating in three categories): the card's tag closes the card, shows
  the chip, empties the search and shows exactly those pictures; removing
  the chip or choosing a category ends it. First run: the chip's delete
  icon is not `Icons.cancel` in Material 3, so the test taps it by its
  tooltip; then 5 passed. `flat_image_library_234_test.dart` reads the
  card's tags as buttons instead of one text.
- `flutter analyze`: no issues.
- Focused: 29 test files (image library, Image Banks, image metadata,
  Recognize characters, Help, version pins): 217 passed.
- Complete suite on the final tree (`--concurrency=1`, 6 October 2026,
  02:14–02:44): **3700 passed, 1 skipped, 0 failed**.

## Revision 4 (2.0.64+264004, 5 October 2026): a grey edge for light pictures

- Measure (`scratchpad/white/measure.py`, the same as
  `edge_white_share`): of 1,764 non-character WebP pictures, 230 had a
  near-white edge share of 25% or more, 110 of 50% or more. The owner's
  "237" came from an earlier measure (more than 60% of all pixels
  near-white, on the catalog before the maps were removed): 249 today, of
  which the 172 not in the edge list have mostly coloured outlines (at
  most 24.6% white edge) and stay visible; B2 covers the ones that are
  lost.
- Preview before applying (`b2_preview.png`, 36 pictures across the three
  bands, on white and on the dark surface): the edge appears only where
  the picture is light; coloured edges unchanged; on dark it is a faint
  grey line. Then the 12 worst after applying (`b2_after.png`): Pegasus,
  Polar Bear, Sugar, Toilet Paper, Cloud, Winter now have a visible edge;
  Tennis's white strings show.
- Applied to 230: 207 lossy at quality 92, 23 lossless; 1.95 MB → 2.20 MB
  in all, largest 26.8 KB; every picture's share after < 50% (highest:
  Empty, 61% → 48%; a second pass would only add a ring, so the tool's
  `--catalog` starts at 50% and reports nothing to do).
- `tools/validate_images.py` 2.6.0: 3,270 records, 2,986 WebP files, 284
  World Flags, 1,222 character pictures, 0 issues; with the original Empty
  put back it reports "edge mostly near-white, lost on a white page"
  (restored afterwards). `tools/validate_media_assets.py`: 3,330 files, 0
  issues.
- `flutter analyze`: no issues.
- Focused: 18 test files (image catalog rules, libraries, Image Banks,
  image metadata, version pins): 95 passed.
- Complete suite on the final tree (`--concurrency=1`, 5 October 2026,
  21:00–21:36): **3695 passed, 1 skipped, 0 failed**.

## Revision 3 (2.0.64+264003, 5 October 2026): confetti for a won Duel and a passed Test; Duel pictures

- New `test/celebrations_264_test.dart`: a Test reaching its threshold
  shows confetti, below it none, without a threshold only all-right
  answers, none with Animations off; a won Duel shows confetti, a lost one
  none; a QQL picture answer in the Duel is a `BundledPicture`, not its
  word. First run: the lost-Duel helper looked for Continue where the last
  wrong answer offers Finish duel (test fixed); then 7 passed.
- `flutter analyze`: no issues.
- Focused: 50 test files (Round, Test, Duel, Do Not Disturb, Help, version
  pins): 533 passed.
- Complete suite on the final tree (`--concurrency=1`, 5 October 2026,
  19:50–20:33): **3695 passed, 1 skipped, 0 failed**.

## Revision 2 (2.0.64+264002, 5 October 2026): image categories, Search all, no Admin categories

- Category map (`scratchpad/b264/rev2_map.py`) checked before applying:
  no name shared within a category, no removed category left in use; the
  apply script asserts the same and every single-picture move. 91
  categories in the catalog (92 with Other).
- `tools/validate_images.py` 2.5.0: 3,270 records, 2,986 WebP files, 284
  World Flags, 1,222 character pictures, 0 issues;
  `tools/validate_media_assets.py`: 3,330 files, 0 issues.
- `flutter analyze`: the first run listed the tests still using the removed
  API (`addDeviceCategory`, `renameDeviceCategory`, `NewCategoryChoice`,
  `chooseNewCategories`, `maxDeviceCategories`); rewritten for the new
  behaviour; then no issues.
- New `test/image_library_categories_264_test.dart` (catalog categories ⊂
  the list, aliases, labels, the tag hint rule, the character row, opening
  on the characters, Search all, the card's category, the tag hint in Edit
  metadata). First run: two chips not found because the chip row is built
  as it scrolls (the row got the key `exercise-image-category-filter`; the
  tests scroll to the chip); the Image Bank widget test picked a menu item
  the dropdown had not built (it opens on Other; now Numbers).
- Focused: 100 test files (images, Image Banks, Recognize characters,
  Editor Help, version pins): 1,412 passed, 1 failed:
  `flat_image_library_234_test.dart` expected Man and Woman among the
  first pictures found by "people family", which now has 36; it checks the
  first ones by name. Rerun: passed.
- Complete suite on the final tree (`--concurrency=1`, 5 October 2026,
  19:03–19:32): **3688 passed, 1 skipped, 0 failed**.

## Revision 1 (2.0.64+264001, 5 October 2026): World Flags in the image library, removals, mascots

- Downloads (owner's permission): `eu.svg` 1,295 bytes, `un.svg` 18,702
  bytes (flag-icons v7.5.0), `Flag_of_Quebec.svg` 835 bytes (Wikimedia
  Commons; the file page gives the same size, public domain, author René
  Chaloult, vector Krun); no script, style, marker or external link.
- Content script (`scratchpad/b264/rev1_content.py`, round-trip checks
  before writing): World Flags 284 (ISO 249, UN 193, ISO extras 56,
  Shortlist 11, language 24), 17 names cleaned, IDs unchanged; catalog
  3,425 → 3,272 records, 284 flag records on the World Flags (242 keep a
  WebP flag's ID and tags), 437 WebP deleted; the six flags with no World
  Flag (Canary Islands, Bavaria, California, Texas, Hawaii, Olympic) are
  exactly the ones left over (asserted).
- Rendering: a temporary widget test drew the European Union, United
  Nations, Quebec (its `<use x=…>`), Croatia, Piedmontese and Italy flags
  through flutter_svg into PNG files; all correct (not committed).
- Mascots: WebP quality 90 at the same size, mean difference on white
  0.39–0.90 of 255; 6.9 MB → 0.97 MB.
- `tools/validate_images.py` 2.4.0: 3,272 records, 2,988 WebP files, 284
  World Flags, 1,207 character pictures, 0 issues.
  `tools/validate_media_assets.py`: 3,332 files, 284 World Flags, 0 issues.
- `flutter analyze`: no issues (twice: after the code, after the test
  fixes).
- Focused: 112 test files (images, World Flags, mascots, credits, Welcome
  Wizard, picture answers, version pins): 1,516 passed, 5 failed, all
  expected and fixed: the catalog-fields test did not allow a flag's
  `attribution`; the Laboratory presentation baseline recorded `<Image>`
  inside the picture-answer buttons of two examples, now `<BundledPicture>`
  (4 lines); the credits test counted the new Quebec entry among the
  language flags and the page's sentence lost its capital. Rerun of the
  three files with the render check: 267 passed.
- Complete suite on the final tree (`--concurrency=1`, 5 October 2026,
  17:36–18:16): **3678 passed, 1 skipped, 0 failed**.

## Revision 0 (2.0.64+264000, 5 October 2026): the image catalog: loading, rules and tags

- Diagnosis: with the decoding fix alone, `loadCatalog()` completed in one
  frame inside a widget test (it never did through `loadString`), but the
  library UI test still waited for ever when another test had loaded the
  catalog first: Copilot's cache held that test's Future, which never
  completes in the next test. Caching finished values fixed it (both tests
  of `exercise_image_metadata_0b_ui_test.dart` then reached the library at
  once).
- Catalog script (`scratchpad/b264/rev0_catalog.py`, checks the JSON
  round-trips unchanged before writing): 3,425 records; 78 names given
  "(man)" / "(woman)"; 2,038 tags equal to the name removed; 12 pictures
  given new tags; no picture left without tags; no repeated tag left.
- `tools/validate_images.py` 2.3.0: 3,425 records, 3,425 WebP files, 1,207
  character pictures, 0 issues. Its glyph check catches a wrong letter
  (`char_latin_capital_b` named "A"), a wrong code point (`_00e9` named
  "è") and a wrong kana (`hiragana_i` named "あ") and accepts the Arabic
  isolated forms.
- `tools/validate_media_assets.py`: 3,772 files, 0 issues (it reported the
  identical Đ / Ð pictures before `IDENTICAL_BY_DESIGN`).
- Focused: the new rules test and the six image tests it touches (37
  passed, then one more expectation fixed: the Man picture's tags); then
  the 61 test files that read the image catalog, the library or Image
  Banks: 737 passed; one failure, `flat_image_library_234_test.dart`
  expecting "man" among the Man picture's tags (one of the seven failures
  left by `58a213f`), fixed and rerun with the version tests (28 passed).
  The batch list also caught the new helper file, which holds no test.
- `flutter analyze`: one warning in the new test (`then` returning a list
  from `onError`), fixed; then no issues.
- Complete suite on the final tree (`--concurrency=1`, 5 October 2026,
  16:12–16:47): **3676 passed, 1 skipped, 0 failed**. The suite no longer
  stops at the image library tests.
