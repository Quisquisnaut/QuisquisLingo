# Build 264 handoff

Saved 5 October 2026, 16:05. **The owner gave the go ("Go") at about
15:40; Revision 0 is in progress.**

## Revision 0 progress (2.0.64+264000)

Done in the working tree (16:05): the service reads the catalog bytes and
caches finished values only (the cached Future of Copilot's version was the
real cause of the library UI test hang: a Future from an earlier test never
completes in the next); catalog edited with
`scratchpad/b264/rev0_catalog.py` (2,038 name tags removed, 12 pictures
tagged, 78 names "(man)/(woman)"); `test/image_catalog_rules_264_test.dart`
and `test/support/bundled_image_catalog.dart` (count 3425 pinned there);
Copilot's tests pointed at the pinned count; transparency for illustrations
only; UI test category "Musical instruments"; `people_family_man` tag
expectations; `tools/validate_images.py` 2.3.0 (0 issues) and
`tools/validate_media_assets.py` (Đ/Ð allowed, 0 issues); version bump
264000, expiry 2026-11-04; CHANGELOG, README, AGENTS, 264_CHANGE_SUMMARY.
The 61 image-related test files: 737 passed; the one real failure
(`flat_image_library_234_test.dart` expected "man" among the tags) fixed
and rerun. Analyzer clean. Complete suite 16:12–16:47: 3676 passed, 1
skipped, 0 failed. Committed as "Build 264 Revision 0: the image catalog:
loading, rules and tags" (hash in the next handoff save). Moved from
Revision 1 into Revision 0: the "(man)" / "(woman)" names (the unique-name
rule needs them).

The owner allowed the three flag downloads ("Go", 5 October, 16:40):
`eu.svg` (1,295 bytes, SHA-1 ebbe870f77114dc2a12e385c56a5a7c993b3f22d)
and `un.svg` (18,702 bytes, SHA-1 a92b62e2309c12176e3957a2b4d81a84509f4cf8)
from flag-icons v7.5.0 `flags/4x3/`, `Flag_of_Quebec.svg` (835 bytes, SHA-1
a7ac82df064bb3627cb26752b1397446fd39e04f, Wikimedia Commons, public
domain), saved in `scratchpad/b264/flags/`; no script, style, marker or
external link.

## Revision 0 committed: `84cfa04`

## Revision 1 progress (2.0.64+264001)

Done in the working tree (17:15): `scratchpad/b264/rev1_content.py` wrote
the World Flags manifest (284, Shortlist 11, 17 names cleaned, aliases),
the three SVGs, and the catalog (3,272 records: 284 flag records on the
World Flags' SVGs with credits; maps, deities, Custer, Die removed; Dice in
games; grandparents in family_relatives, trees "(family tree)"); 437 WebP
deleted with `git rm`; mascots WebP + `design/`; `BundledPicture`;
`knownImageCredit`; Crop square hidden for SVG; library details "SVG";
generator, notice, credits page, docs; validators 2.4.0 / 284 (0 issues);
tests (count 3272, flags ↔ manifest, World Flags counts, mascots .webp);
version 264001 (expiry unchanged, same day); CHANGELOG, README, AGENTS,
264_CHANGE_SUMMARY. Analyzer clean. Focused 112 files: 1,516 passed, 5
expected failures fixed and rerun (267 passed). Complete suite 17:36–18:16:
3678 passed, 1 skipped, 0 failed. Committed as "Build 264 Revision 1:
World Flags in the image library, removals, mascots".

Committed `b17f44c`. Next: Revision 2 (categories), see the plan below.

## Owner decisions during Revision 2 (5 October 2026, evening)

- Confetti for a Test Round without a threshold: only on a perfect result
  (confirmed "YEs").
- Library: a **Search all** checkbox beside the search field, default on
  (search every category, not only the one being browsed); in an image's
  card the **category is clickable** and opens that category. Both go into
  Revision 2.
- Religious figures: the owner asks for Priest and Bishop and a few
  figures of other religions, "respectfully, discuss". Bishop exists (in
  people_roles, a clergy bishop): Revision 2 moves it to
  religious_figures. Proposed to the owner (waiting): people in their
  roles, never deities or prophets: Priest, Orthodox priest, Pastor,
  Rabbi, Imam, Buddhist monk, Hindu priest (pujari), Sikh granthi; the
  current Monk as "Monk (Christian)"; optional places of worship (Church,
  Mosque, Synagogue, Temple, Gurdwara) in architecture; drawn by the owner
  like series 1.
- The owner noticed common words without a picture (player, athlete; also
  news, title, anchorperson, film maker, artist): a background check lists
  missing common picturable words in `scratchpad/vocab/missing_common_words.md`
  / `.csv` (to give the owner a generation list).
- Rabbi and Synagogue: already in the proposal (owner asked); kept.
- Remove "Petting a Cat" and "Petting a Dog" (done in Revision 2, no Course
  used them); instead draw more cats (black cat, ginger cat) and dogs by
  breed; add continent maps (Africa, Asia, Europe, North America, South
  America, Oceania, Antarctica). All for the second generation list, to
  prepare with the missing words.
- Missing words check done (18:45): 2,776 candidates, 1,553 covered, 746
  missing (277 priority A, 469 B), report and CSV in
  `D:\QQL_plus\nuove_immagini\parole_mancanti\` (sent to the owner). The
  owner's words: player, athlete, team, fan, coach, referee, title, news
  anchor, TV presenter, film director, audience, camera operator, duel,
  sword, shield, black cat, ginger cat, kitten, puppy, 11 dog breeds, 7
  continent maps are missing (A); news, artist, film maker, arrow/bow are
  covered (some weakly). The owner approved the 277 A words as series 4
  ("Ok 1"): 295 rows (18 jobs as man/woman pairs), checked against the
  catalog rules (0 issues), in `D:\QQL_plus\nuove_immagini\serie4\` (list,
  Italian specs, 15 batches to paste); generators and `check.py` in
  `scratchpad/series4/`. New labels are sentence case ("Bus driver (man)")
  while the catalog's jobs are Title Case: align at integration. Still
  waiting: the religious list, the B words later.

## Revision 2 progress (2.0.64+264002)

Done in the working tree (18:46): `lib/models/image_categories.dart`;
catalog recategorized (`scratchpad/b264/rev2_map.py`, `rev2_catalog.py`);
service (fixed list, aliases, no add/rename); Image Bank `mapNewCategories`;
library (character row, Search all, clickable card category,
`initialCategory`, tag hints, no New category); Recognize characters opens
on the characters; petting pictures removed (3,270); validator 2.5.0;
Help `findPicture` EN/IT/ES (83); docs; tests (new
`image_library_categories_264_test.dart`, device category, Image Bank and
UI tests rewritten); version 264002; CHANGELOG, README, AGENTS,
264_CHANGE_SUMMARY. Analyzer clean. Focused 100 files: 1,412 passed, 1
fixed and rerun. Complete suite 19:03–19:32: 3688 passed, 1 skipped, 0
failed. Committed `f74ad3a` "Build 264 Revision 2: image categories,
Search all, no Admin categories". Gotcha: another session wrote
`docs/265_WORD_LOOKUP_PLAN.md` (Build 265 Word Lookup plan) into this
checkout at 18:52; `git add -A` swept it into the first commit, taken out
with `git rm --cached` and an amend. Leave it untracked; exclude it when
staging.

## White pictures on white (owner, 5 October, evening: "sono un problema")

Measured in `scratchpad/white/` (`measure.py`, `ranked.json`): the share of
each WebP picture's outer edge that is near-white (luminance > 225) and of
its body. 110 pictures have at least half of their edge near-white (66 at
least 60%); the worst are white objects with a faint grey edge (Toilet
Paper, Pegasus, Unicorn, Polar Bear, Cloud, Plate, Saucer, Sink, Toilet,
Bathtub, Sugar, Garlic, Milk, Empty, Angel, Refrigerator) and scenes on a
pale panel (maps, Winter, Spring, Showering). Options shown to the owner
(`options.png`, `option_b2.png`): A a soft backdrop behind pictures in the
app (helps little), B a soft grey outline around the whole figure, **B2
(recommended) a soft grey ring outside the figure only where its edge is
light** (coloured parts keep no outline), applied to those ~110 pictures
and to new ones, with a test rule so that no picture's edge is mostly
near-white. The owner chose **B2** ("Ok B2"): Revision 4 applies it
(`selective_outline` in `scratchpad/white/`) to the pictures with at least
half of their edge near-white, adds the rule as a test or validator check,
and new series pass the same check at integration (so the generation
prompts ask for no edge of their own).

Generation lists given to the owner (20:05): series 4 (unchanged, 295
rows) and **series 5, religion** in `D:\QQL_plus\nuove_immagini\serie5\`
(`new_images_list_series5.csv`, `batch_01_of_01.txt`; generator
`scratchpad/series5/build.py`, checked against the catalog, series 1 and
4): Priest, Orthodox priest, Pastor, Rabbi, Imam, Buddhist monk, Hindu
priest, Sikh granthi (religious_figures); Synagogue, Hindu temple,
Buddhist temple, Gurdwara, Cathedral (architecture); every one tagged
religion like Church, Mosque and Monk. My first answer missed Church and
Mosque (a case-sensitive search); the owner pointed it out. Still to ask:
renaming the existing Monk (a friar) to "Monk (Christian)" beside Buddhist
monk; the 469 B words.

Tags as a list (owner idea, 5 October, evening): measured 6,889 distinct
tags, 5,787 on one picture only, 297 on five or more; per category, tags on
three or more pictures give useful groups in 63 of 91 categories (flags by
continent, home_household by room, animals by habitat). Decided ("OK 1, no
2"): **Revision 5 makes the tags in an image's card clickable**: a tap
searches that tag across the library (Search all), as the card's category
opens its category. No tag row under the categories and no global tag list
(the search and the clickable tags already find them); so no tag clean-up
either. Order: Revision 3 commit, Revision 4 B2 outline, Revision 5
clickable tags.

The 5 language flags missing from `tools/generate_world_flags.py`'s
`LANGUAGE_RELATED` (Ligurian, Lombard, Mirandese, Romansh, Venetian): the
app has all 24; offered to fix the tool in the next revision.

## Revision 3 progress (2.0.64+264003)

Done in the working tree (19:55): Duel confetti and QQL pictures in the
Duel's answers (`duel_screen.dart`), Test Round confetti
(`round_screen.dart`), Help EN/IT/ES and the Animations subtitle, the
`ConfettiBurst` comment, `test/celebrations_264_test.dart` (7 passed),
version 264003, CHANGELOG, README, AGENTS, 264_CHANGE_SUMMARY. Analyzer
clean. Focused 50 files: 533 passed. Complete suite 19:50–20:33: 3695
passed, 1 skipped, 0 failed. Committed as "Build 264 Revision 3: confetti
for a won Duel and a passed Test; Duel pictures" `d42180e`.
Committed `828d293`. Next: Revision 4 (B2 outline).

Planned before (now Revision 3): confetti after a won Duel and a passed Test Round (with
a threshold: reaching it; without: a perfect result, owner confirmed),
Respecting Animations and reduced motion; QQL pictures (icon keys
`assets/…`) drawn as pictures in the Duel answers. Then the owner's
pictures as they arrive (series 1 objects with the three redrawn, series 2
Lesson icons with the "4 colors" category and the picker change, series 3
block letters, later series 4 and the religious list).

Found while working: `tools/generate_world_flags.py`'s `LANGUAGE_RELATED`
lists 19 language flags, the bundled notice and manifest have 24 (five were
added outside the generator before Build 264); not fixed (out of scope),
recorded in AGENTS.

## Revision 1 design notes (prepared during the Revision 0 suite)

- No Course, fixture or private Course (`D:\QQL_plus\Corsi_Privati`)
  references a `flag_*.webp` or `map_*.webp` picture: removing them breaks
  nothing.
- World Flags in the library: keep catalog records in `metadata_v2.json`
  (one per World Flag entity, category `flags`), whose `assetPath` is the
  entity's SVG (`assets/world_flags/flags/<id>.svg`); delete the 252 WebP
  flags. 224 WebP flag records match a World Flag by ID slug, 18 more by
  name (Bosnia, Croatia, Curaçao, DR Congo, Eswatini, French Southern
  Lands, Ivory Coast, Macau, North Macedonia, Pitcairn, Saint Helena, Sint
  Maarten, East Timor, Türkiye, US Virgin Islands, Vietnam, Wallis and
  Futuna, Western Sahara); keep their curated tags. Canary Islands,
  Bavaria, California, Texas, Hawaii and Olympic go (owner: not added);
  European Union, United Nations, Quebec become World Flags (Shortlist).
  The remaining World Flags without a WebP record (language flags, ISO
  extras) get generated tags ("flag", "flag of …"). A test ties the
  catalog's flag records to the World Flags manifest one to one.
- Keep World Flag entity IDs (the Flag Game's scorecards may key on them);
  clean only `displayNameEn` (and `DISPLAY_OVERRIDES` in
  `tools/generate_world_flags.py` for a future regeneration).
- SVG drawing wherever a QQL picture is drawn from `assets/`: a `.svg`
  path is drawn with `SvgPicture.asset`, always `BoxFit.contain` (flags are
  4:3, never cropped); no Crop square for an SVG.
- The three new flag files must be downloaded (flag-icons v7.5.0
  `flags/4x3/eu.svg`, `flags/4x3/un.svg`; Wikimedia Commons
  `Flag_of_Quebec.svg`): asked the owner for permission.

## New images delivered (5 October, afternoon)

- The owner delivered the three series as `serie1_oggetti.zip`,
  `serie2_lesson_icons.zip` and `serie3_lettere_blocchi.zip` (in `C:\QQL\`
  and in `D:\QQL_plus\nuove_immagini\`), each image with its SVG source in a
  `svg/` folder. All 152 pass the technical checks: names exactly as in
  `new_images_list.csv`, 256 × 256, WebP lossy with alpha (objects,
  letters) or PNG RGBA not interlaced (icons), one frame, 2–29 KB, margins
  17–23 px, no ID or label already in the catalog, every SVG parses.
- Objects: Vest, Football goal and Mango were redrawn by me at the owner's
  request (the first two almost vanished on white, the mango looked like an
  orange or a peach). Use the redrawn files, not the ones in the ZIP:
  `D:\QQL_plus\nuove_immagini\serie1_rifatte\` (`vest.webp`,
  `football_goal.webp`, `mango.webp`, SVGs in `svg/`, and `redo.py`, which
  renders the SVGs with headless Chrome and fits them like the series:
  longest side 220 px, centred).
- Lesson icons: consistent with the 14 current ones (same palette and
  outline, no grain); accepted.
- Block letters: built from many small bricks in red, yellow, blue and
  green rather than one single-colour letter-shaped brick; the owner
  accepts them as they are (5 October). Categories: Characters › Latin as
  a separate series, as planned.
- Tags: the owner removed 10 repeated tags before commit `58a213f`; one
  remains that differs only by a capital (`languages_lang_occitan`:
  "Occitan" and "occitan"), because `tools/validate_images.py` line 230
  compares exact text. Remove it in Revision 0 with the case-insensitive
  test. Six loose variants (hairdryer / hair dryer, café / cafe, takeaway /
  take away, piñata / pinata, roadworks / road works, checkmate / check
  mate) stay: the library search does not ignore spaces or accents
  (`normalizeImageSearchText`), so they help.
- **Owner rule (5 October): every image has one or more tags different
  from its name, and the name is never repeated as a tag** (the search
  reads the label, the ID and the category as well, so a tag equal to the
  name adds nothing). Compare ignoring capitals and spaces, not accents
  (Café keeps the tag "cafe"). Today 2,113 of 3,425 images repeat the name;
  2,101 keep other tags once it is removed, 12 have only their name and
  need new tags (Dress, Jacket, Shoes, Hat, Scarf, Shorts, Socks, Necklace,
  Wallet, Soup, Bird, Pot; proposals given to the owner, to confirm). The
  new series follow it too: the 110 objects and 26 letters keep other tags,
  the 16 Lesson icons have only their name in `new_images_list.csv` and need
  tags at integration. Revision 0: remove the repeated names, add the tags,
  and test the rule (with the other tag rules).
- The rule is enforced only on the QQL catalog (owner, 5 October, on my
  recommendation). Admin images on the device stay as today: never without
  tags, the name allowed as the only tag (a single image added still gets
  its name as its tag, `exercise_image_service.dart:271`; tags can never
  be empty, because `_normalizeTags` refuses it, the device document would
  not load and a Course's `sharedImageSource` requires tags). **Add a
  non-blocking suggestion** (owner: "aggiungi un suggerimento ma non
  bloccare"), in Revision 2 with the other Admin changes: in Metadata edit,
  under Tags, a hint while every tag equals the name ("Add at least one tag
  different from the name, such as a synonym or a related word"); the
  result of a single image add and of an Image Bank import says how many
  images have only their name as a tag and where to add more. Save and
  import are never refused for this. Help EN/IT/ES.

## Where things stand

- Branch `claude/263-preset-forms`, pushed to `origin` by the owner. On top
  of Build 263 (`92e56cf`, `0242185`, `565fe00`, `f970266`, version
  2.0.63+263002) it holds the owner's commit `58a213f` "Expand bundled image
  bank to 3425 assets": 3,314 new WebP images generated with Claude in a web
  chat on another computer, `metadata_v2.json` (3,425 records, 103
  categories), `tools/validate_images.py` 2.2.0 (lossy WebP accepted; the
  old lossless `vp8l_info` check is no longer called) and 90 new categories
  in `ExerciseImageMetadataService.categories`. Its message says seven test
  failures were left unresolved.
- Uncommitted in the working tree, by GitHub Copilot (keep and finish them
  in Revision 0, do not discard):
  - `lib/services/exercise_image_metadata_service.dart`: per-`AssetBundle`
    caches (`Expando`) of the parsed bundled records and of the bundled
    content index, hashes computed in batches of 32. Correct; two small
    fixes to make: do not keep a failed load in the cache (retry), and make
    the cached list unmodifiable.
  - Four tests: the fixed count 111 replaced by the catalog's own count
    (fine); in `media_asset_integrity_234_test.dart` the QQL 234
    "transparent outer border" check replaced by "uses transparency".
- The old course zip that sat in `assets/lesson_plants/` (an older export of
  QQL Demo: English from Italian, same Course ID) was moved to the Windows
  Recycle Bin at the owner's request.

## Why the suite hangs (found 5 October)

`AssetBundle.loadString` decodes an asset of 50 KB or more in another
isolate with `compute()`. `metadata_v2.json` is now about 1.5 MB, so in a
widget test (fake async) the first catalog load never completes: the
complete suite stopped at test 1,296
(`exercise_image_metadata_admin_ui_234_revision_test.dart`, "Admin edits
attribution for a device image in Metadata edit") and Copilot's own run
hung for 2 h 22 min. Before that, two failures in
`exercise_image_metadata_0b_ui_test.dart`: a device category named
`sports` (now a bundled category) and the library not opening in time
(same cause). Fix planned: the service reads the catalog bytes
(`_bundle.load`) and decodes them with `utf8.decode` itself (a few
milliseconds), so tests work without changes. The real app is not
affected.

## Owner decisions (5 October 2026)

Tests and files
- Image tests check: every record has its file and vice versa; IDs and
  paths unique; category allowed; label not empty and unique within its
  category; tags without duplicates ignoring case (one repeated tag today:
  `languages_lang_occitan`); expected image count pinned in one place;
  WebP single frame, 256 × 256, at most 50 KB, lossy or lossless;
  character images match their Unicode character (a scratchpad check found
  all 1,020 correct); the library opens in reasonable time.
- Transparency: illustrations need some transparent pixels (all 3,425
  already have them); character images are exempt. The 382 images that
  reach the border (all illustrations) are accepted.

Content
- Flags: use the **World Flags** (SVG, `assets/world_flags/`) directly in
  the image library, no duplicate WebP flags (the 252 `flag_*.webp` go).
  Draw `.svg` exercise images with `flutter_svg` wherever exercise images
  are drawn (PortableExerciseImage, CourseMediaImage asset path, the Round
  tiles, the library tile, the image field preview, the Duel); flags are
  4:3, so draw them whole (contain) in square tiles; no Crop square for
  them. Add **European Union, United Nations and Quebec** to World Flags in
  the **Shortlist** category (no new category; Flag Game pools unchanged in
  kind); sources flag-icons (MIT) for EU and UN, Wikimedia Commons (public
  domain) for Quebec; update the credits page. Correct the awkward ISO
  display names (for example "Croatia (local Name: Hrvatska)", "North
  Macedonia, Republic of", "Swaziland", "Bosnia and Herzegowina", "Sint
  Maarten (dutch Part)", "Wallis and Futuna Islands", "Heard and Mc Donald
  Islands", "Saint Martin (french Part)", "Timor-leste"); this also shows in
  the Flag Game.
- Remove: the 172 country maps (only "World map" stays; there are no
  continent maps), the Olympic flag, the six Hindu deities, Jesus, the
  Virgin Mary, Saint Francis, Saint Peter, Buddha and General Custer
  (Angel, Nun, Monk and Pope stay); one of Die/Dice (keep "Dice" in games).
- Labels: jobs as "Lawyer (man)" / "Lawyer (woman)"; flag and map share
  names today (maps go). Grandparents: both image pairs in the same family
  category.
- Assets: move the 10 mascot PNGs and the 6 unused `lesson_plants` PNGs to
  a repository folder that is not bundled (`design/`), and ship the mascots
  as WebP in `assets/mascots/` (the mascot loader lists the whole folder:
  never keep both formats there); remove `assets/lesson_plants/` from
  `pubspec.yaml`.

Categories
- Reorganize: merge `people_family` with `family_relatives`,
  `relationships` with `relationships_marriage`, `games` with
  `games_cards`/`games_chess`; split the grab bags `everyday_misc` (Passport,
  Village, Sweater, Dinner, weather) and `time_space` (Hourglass, Calendar /
  Planet, Rocket); move grooming items out of `health_care`; reduce the four
  city/places/services categories to two; fold the tiny ones
  (`safety_emergency` 2, `baby_care`, `inheritance`, `people_roles` 4).
- **Characters** with subcategories (two-level category menu): Latin,
  accented, Greek, Cyrillic, Armenian, Georgian, Hebrew, Arabic, Devanagari,
  Thai, Korean, Hiragana, Katakana, Chinese, diacritics, confusable pairs,
  punctuation, currency symbols, mathematical symbols, @ # & © ® ™.
  **Numbers** stays a category of its own; icon symbols (prohibition,
  power, play, pause, stop) are not characters.
- Recognize characters: the image picker opens with Characters
  preselected, and the author may change it.
- The Admin can no longer create categories (no device categories exist
  today). Image Bank import: an unknown category is mapped by the Admin to
  an existing category or goes to `other`.

Duel and Test
- Do not redesign the Duel. Add `ConfettiBurst` on a Duel win and on a
  successful Test-type Round (with a threshold: reaching it; without a
  threshold: a perfect result, as proposed; confirm with the owner).
  Respect Animations and reduced motion as today.
- Fix the Duel inconsistency: QQL pictures stored as icon keys
  (`assets/...`) are drawn as pictures in the Duel answers, not as words.
- For reference: the Duel path icon is the Material icon
  `sports_martial_arts_outlined`; the plants beside the Duel screen are
  drawn by `fighterPlant` in `duel_screen.dart`. Both are inside the app
  package, so they show on any device.

Lesson icons and new images
- Lesson icons: add 16 icons in the "4 colors" style (themes approved:
  animals, nature and weather, body and health, clothing, sports, music, art
  and culture, colours and shapes, numbers and maths, emotions, city, world
  and countries, technology, celebrations, alphabet and writing, questions
  and conversation); they also appear in the image library as category
  "4 colors"; the Lesson icon picker may also choose any library image
  (format change of `themeIconAsset`, `minimumAppBuild`).
- New images are generated by the owner with Claude in a web chat and
  integrated here: specifications and list sent to the owner on 5 October
  (`new_images_specs.md`, `new_images_list.csv` in the session scratchpad
  `…\scratchpad\images\deliverables\`): 110 common objects (WebP), 16
  Lesson icons (PNG, palette `#301040`, `#9030F0`, `#10B0A8`, `#F0C040`),
  26 capital letters as 3D toy construction bricks (WebP, category
  Characters › Latin as a separate series). The owner delivers one folder
  or ZIP per series outside the repository.

## Plan (Build 264, same branch, one local commit per revision)

- Revision 0: catalog decoding fix, the image test rules above, Copilot's
  cache with the two fixes, the two failing UI tests.
- Revision 1: content (World Flags in the library with SVG drawing, the
  three new World Flags and the cleaned names, removals, labels,
  grandparents, `design/` moves, mascots as WebP).
- Revision 2: categories (reorganization, Characters subcategories,
  Recognize characters preselection, no Admin categories, Image Bank
  mapping).
- Next revisions: Duel confetti and picture fix, Test confetti; then the
  owner's new images (objects, Lesson icons with the "4 colors" category and
  the picker change, block letters).

Out of scope until asked: replacing the Duel with a final Test (discussed;
the owner chose to keep the Duel).

Scratchpad tools used in the review (session-specific): `images/analyse.py`
(format, border, duplicates), `images/glyphs.py` (characters vs Unicode),
`images/sheets.py` (contact sheets per category), `images/border.py`,
`images/asset_audit.py`, `images/missing.py`, `images/make_list.py`.

## Revision 4 progress (2.0.64+264004)

Done in the working tree (21:30): 230 pictures outlined (edge >= 25%
near-white; `scratchpad/white/outline.py`, `applied.json`, previews
`b2_preview.png`, `b2_after.png`); new `tools/outline_light_edges.py`
(the measure and the edge; files from 25%, `--catalog` from 50%);
`tools/validate_images.py` 2.6.0 refuses an edge >= 50% near-white
(checked with the original Empty); version 264004; CHANGELOG, README,
AGENTS, 264_CHANGE_SUMMARY, 264_VALIDATION. Analyzer clean; focused 18
files 95 passed. Complete suite 21:00–21:36: 3695 passed, 1 skipped, 0
failed. Committed as "Build 264 Revision 4: a grey edge for light
pictures" `d42180e`. Use the tool on every new
series before integrating it. Next: Revision 5 (clickable tags).

Revision 5 design (owner "Ok B", 5 October, evening): a tap on a tag in an
image's card opens an **exact tag filter**, not the search box: only
pictures that carry that tag or are named so (capitals and spaces ignored),
in every category, shown with a removable chip "Tag: <tag> ×" above the
results. Typing in the search box stays the substring search. Numbers
shown to the owner: substring "cat" 63, "red" 43, "man" 163; exact
"europe" 54, "kitchen" 9, "bird" 9. Local words in the card may work the
same way (they are searched like tags).

Owner, 5 October, evening ("Yes to all"): rename Monk (a friar) to
"Monk (Christian)"; prepare the 469 B words as series 6 (being written in
`scratchpad/series6/`, output `D:\QQL_plus\nuove_immagini\serie6\`, same
format as series 4); fix `tools/generate_world_flags.py` so its
`LANGUAGE_RELATED` knows all 24 bundled language flags. Series 4 (295) and
series 5 (13) delivered as `C:\QQL\serie4_parole_A.zip` and
`C:\QQL\serie5_religione.zip`: every file rule passes
(`scratchpad/series4/check_delivery.py`: names, SVGs, 256 x 256 WebP with
alpha, <= 50 KiB, subject 220–222 px, margins 17–18, job pairs within
7 px); 48 need the grey edge (46 + 2); visual review still to do.

Series 6 ready (21:45): 490 rows for the 469 B words (21 job pairs in
Title Case, 0 dropped, 0 issues), `D:\QQL_plus\nuove_immagini\serie6\`
(list, Italian specs, report, 25 batches); scripts in
`scratchpad/series6/`; sent to the owner. Open in its report: whether
Clown, Magician, Influencer, Headteacher and Orchestra Conductor are pairs
or single pictures. Series 4 job labels go to Title Case at integration.
Plan after Revision 5 (clickable tags): integrate series 4 and 5 (with
Monk → "Monk (Christian)" and the grey edge on the 48 light ones), then
series 1–3 (objects, "4 colors" Lesson icons with the picker change,
block letters); the World Flags generator fix in one of them.

Series 6 delivered (`C:\QQL\serie6_parole_B.zip`, 23:17): 490/490 files
with SVGs, every file rule passes (`check_delivery.py`), 88 need the grey
edge (38 of them at 50% or more). Visual review of all three deliveries
(contact sheets `scratchpad/series4/sheets/`, doubtful ones enlarged in
`zoom.png` with the edge): nothing to redraw; Border collie (herding
pose), Hand luggage, Sunbed, Single/Double room (one bed and lamp vs two),
Frost, Disgusting, Sprained ankle, Ski resort, Speedboat read correctly
once outlined. Pairs such as Deep/Shallow, Young/Old, Upstairs/Downstairs
are one scene with the meant part highlighted, as specified.

## Revision 5 progress (2.0.64+264005)

Done in the working tree (6 October): `carriesImageTag`, the card's tag
and Local word links, `_openTag` / `_chooseCategory`, the Tag chip, Help
EN/IT/ES, `test/image_tag_filter_264_test.dart`, version 264005,
CHANGELOG, README, AGENTS, 264_CHANGE_SUMMARY, 264_VALIDATION. Analyzer
clean; focused 29 files 217 passed. Complete suite 02:14–02:44: 3700
passed, 1 skipped, 0 failed. Committed as "Build 264 Revision 5: tags
that open their pictures" `4d76681`. Next: Revision 6, series 4, 5 and 6 (staged in
`scratchpad/integrate456/`: `stage.py` → `staging/`, `apply.py` copies
it in and sets `bundledImageCount` 4068).

## Revision 6 progress (2.0.64+264006)

Done in the working tree (6 October, morning): `apply.py` copied the 798
staged WebP files and the catalog (4,068 records), `bundledImageCount`
4068, version 264006, CHANGELOG, README, AGENTS, 264_CHANGE_SUMMARY,
264_VALIDATION. Validators 0 issues; the 66 test files that read the
catalog: 978 passed. Analyzer clean; complete suite 03:00–03:29: 3700
passed, 1 skipped, 0 failed. Committed as "Build 264 Revision 6: 798 new
pictures" `cae629a`. Next:
Revision 7, series 1–3 (a `four_colors` category for the 16 Lesson icons,
a separate Characters subcategory for the block letters A–Z because the
names A–Z are taken in `characters_latin`, tags besides the name, the
three redrawn objects from `serie1_rifatte`); the Lesson icon picker
change (any library picture as a Lesson icon, `themeIconAsset` and
`minimumAppBuild`) to confirm with the owner before it is built.

## Revision 7 progress (2.0.64+264007)

Done in the working tree (6 October, 03:45): `scratchpad/integrate123/`
`stage.py` + `apply.py` (136 pictures, `characters_blocks`, count 4204),
Help EN/IT/ES, category test, version 264007, CHANGELOG, README, AGENTS,
264_CHANGE_SUMMARY, 264_VALIDATION. Validators 0 issues; focused 70 files
809 passed. Analyzer clean; complete suite 03:43–04:11: 3700 passed, 1
skipped, 0 failed. Committed as "Build 264 Revision 7: everyday objects
and toy-block letters" `bfb041c`. Next: the 16 "4
colors" Lesson icons and the Lesson icon picker (confirm the design with
the owner first: the model change of `themeIconAsset` and
`minimumAppBuild`), and the World Flags generator's language list.

World Flags generator (owner "yes", 5 October): not done yet, needs the
owner's permission to download. `tools/generate_world_flags.py`
`LANGUAGE_RELATED` lacks Ligurian, Lombard, Mirandese, Romansh and
Venetian, and three of its pins no longer match the bundled files
(Neapolitan source SHA-1 `c0cccc…` vs bundled `9d222f…`; West Frisian and
Piedmontese assetSha1 vs the notice's renderer-normalized SHA-1). The
generator reads each source SVG (download or `--language-flags` cache) and
checks both pins, so a fix can only be verified with the eight source
files from Wikimedia Commons (small SVGs; the five's direct URLs follow
from Commons' MD5 path rule). Mirandese, Romansh and Venetian are
renderer-normalized in the bundle by transforms the generator does not
contain. Ask the owner for the download, then: add the five specs (with a
note field for the "geographic proxy" sentences of the notice), correct
the three pins, count the flags in the notice text, and check that
generating into a scratch folder reproduces the bundled notice, manifest
entries and files byte for byte.

## Revision 8 progress (2.0.64+264008)

Owner, 6 October morning: "Yes fix the world flag tool. Yes keep the 16
new theme icons. Maybe rename the category if they are not exactly 4
color." Done in the working tree: picker from the library, the 16 icons
(kept as drawn; flat-style rule), library category `lesson_icons` (30
records), minimum build 264008, Help, tests, version 264008, docs.
Analyzer clean; related tests pass after the duplicate-fixture fix.
Complete suite 05:05–05:35: 3708 passed, 1 skipped, 0 failed. Committed
as "Build 264 Revision 8: Lesson icons, sixteen new and any library
picture" `4a35501`. Next: Revision 9, the World Flags tool:
downloads done (`scratchpad/flags_src/`; Ligurian, Lombard, Mirandese,
Romansh, Venetian are newer on Commons than the pinned sources; West
Frisian matches its pin; Neapolitan and Piedmontese hit Wikimedia's rate
limit). The shipped files cannot be rebuilt from today's sources, so the
tool will keep a shipped file whose SHA-1 matches its pin and download
only a new flag; the five specs, the three stale pins and the notice's
note and count to add, verified offline against the bundled notice and
manifest.

## Revision 9 progress (2.0.64+264009)

Done in the working tree (6 October, 05:50): the tool patched
(`scratchpad/flagtool/patch.py`), `tools/check_world_flags_generator.py`
(0 issues; added to `validate_release.ps1`), the notice rewritten by the
tool, version 264009, docs. Focused 37 files 334 passed. Analyzer clean;
complete suite 05:43–06:12: 3708 passed, 1 skipped, 0 failed. Committed
as "Build 264 Revision 9: the World Flags tool matches the bundle" `580fb49`. Now: Build 264 is complete (Revisions 0–9, local,
not pushed); report to the owner and ask about pushing / the PR.

Follow-up of 264009 (owner, 6 October, morning): the Duel drew no picture
for "What is in the picture?" questions (Viterbese "Che cos'è?"), and the
last Lesson's Duel read "Final Duel" twice. Fixed in `duel_screen.dart`
(`duel-question-picture`; `_pageHeading` = the Lesson's name, owner's
choice of option A after "I didn't mean drop but change"); tests in
`celebrations_264_test.dart`, `learner_panel_260_test.dart`. Analyzer
clean; complete suite 13:57–14:27: 3711 passed, 1 skipped, 0 failed.
Committed as "Build 264 Revision 9 follow-up: the Duel's picture and
heading" `a1ea78e`.

Under discussion (owner, 6 October): namesake tag and category should
show each other; pictures in several categories; an A–Z tag picker above
the categories. Data: 4,234 pictures, 93 categories, 9,351 tags (1,645 on
two or more pictures); 32 categories also exist as a tag (restaurant: 22
in the category, the tag on 7, 6 outside it; grammar: 17 + 22 outside).
Proposed A (merge the views, data unchanged; recommended) vs B (true
multiple categories, format change); questions asked: A or B, A–Z list
of tags on 2+ pictures only, singular/plural, layout on narrow screens.
Do not implement before the owner's answers.
Still open for the owner: push/PR; a minimum app build for Courses whose
exercises use pictures added in Build 264.

## Revision 10 progress (2.0.64+264010)

Owner, 6 October afternoon: "I like your A proposal. Plural and singular
should count as one. No A-Z picker for now. Also, shorten the text on top
of Image Library … Have the full text in a Help screen … Remove the number
of pics on top but show the number on the right of the All badges row";
"only categories show on the bar … when you select a category, the pic
number updates". Done in the working tree: rules (`imageTagKey`,
`belongsToImageCategory`, namesake in `carriesImageTag`, plural in
Search), screen (title, count row, short notice, Help icon),
`ImageLibraryHelpScreen` + Help EN/IT/ES + QQL Guide, tests, version
264010, docs. Related 84 files 904 passed; analyzer clean; complete
suite 14:47–15:17: 3718 passed, 1 skipped, 0 failed. Committed as
"Build 264 Revision 10: categories and tags as one; the image library's
Help" and pushed (owner: "if all green, commit and push").
