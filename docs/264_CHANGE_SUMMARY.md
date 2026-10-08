# Build 264 change summary

The owner expanded QQL's Image Bank on another computer: 3,314 new pictures
drawn with Claude in a web chat, 3,425 in all, 103 categories (commit
`58a213f`). Its message left seven tests failing, and GitHub Copilot left
uncommitted caches and loosened tests. The owner asked for a review; the
decisions of 5 October 2026 are in `docs/264_HANDOFF.md`. The owner gave
the go for Build 264 the same afternoon.

Revisions (plan):

- Revision 0: the catalog loads inside the tests again, Copilot's caches
  corrected, the catalog's rules tested, the tag rule, unique names.
- Revision 1: content (World Flags in the library, three new World Flags,
  cleaner country names, removals, grandparents, `design/` moves, mascots
  as WebP).
- Revision 2: categories (reorganization, Characters with subcategories,
  Recognize characters opening on Characters, no Admin categories, Image
  Bank mapping, the non-blocking tag hint for Admin pictures).
- Later: confetti after a won Duel and a passed Test Round, QQL pictures
  drawn as pictures in the Duel, the owner's new pictures (110 objects, 16
  "4 colors" Lesson icons, 26 block letters).

## Revision 10 (2.0.64+264010, 6 October 2026): categories and tags as one; the image library's Help

**Why.** The owner found it confusing that a category and the tag of the
same name do not show each other (Restaurant: 22 pictures in the category,
the tag "restaurant" on 7 others, 6 of them outside it; 32 categories have
a namesake tag). Of two ways (merge the views, data unchanged; or true
multiple categories, a format change) the owner chose the first, decided
that singular and plural count as one, set aside an A–Z tag picker, and
asked to shorten the text at the top of the library to its first sentence,
to put the full text in a Help screen behind a question mark, and to move
the number of pictures from the title to the right of the badge row, where
it follows the chosen category.

**What changed.**

- `image_library_rules.dart`: `imageTagKey` (normalized, every word in its
  singular: "ies" → "y", "sses/shes/ches/xes/zes" lose "es", a final "s"
  goes unless the word ends in "ss", "us" or "is"; "news" and "goods"
  stay); `carriesImageTag` compares by it and counts the namesake category;
  `belongsToImageCategory` (own category, or a tag or Local word naming it;
  never for the characters' categories, the characters group or Other);
  `matchesImageSearch` also compares singular forms.
- `FlatImageLibraryScreen`: a category shows `belongsToImageCategory`; the
  title is "Shared Images" / "Image Library" without the number; the badge
  row is always there with `exercise-image-count` ("N images", the pictures
  shown) on its right (the badge chips only when there are two kinds); the
  Course notice keeps its first sentence; `image-library-help` (?) opens
  the new `ImageLibraryHelpScreen` (`imageLibraryHelpSectionIds`: saving,
  finding, badges, details; EN/IT/ES), also a QQL Guide destination
  (`image-library`). Editor Help `findPicture` names the change and the
  Help.

**Not changed.** The catalog, device pictures, Image Banks and Course files
(still one stored category per picture); scoring, progression and learner
data.

## Revision 9 (2.0.64+264009, 6 October 2026): the World Flags tool matches the bundle

**Why.** Revision 1 found that `tools/generate_world_flags.py` listed 19
language flags while QQL ships 24; the owner asked to fix it ("yes", 6
October) and allowed the downloads needed. Comparing the tool with the
bundle showed more drift: ten of its nineteen pins differ from the bundled
files (Esperanto, Amazigh, Ladin and Neapolitan were replaced; Sardinian,
Sicilian, Aragonese, Livonian, West Frisian and Piedmontese re-normalized),
the five language suggestions of the missing flags were absent, and four
of the five carry hand-chosen Flag Game colours. The eight sources were
downloaded (`scratchpad/flags_src/`): West Frisian matches its pin, the
five missing flags' sources have newer versions on Commons, Neapolitan and
Piedmontese hit the rate limit. The bundled files cannot be rebuilt from
today's sources.

**What changed.**

- `LANGUAGE_RELATED`: the pins follow the bundled manifest (source SHA-1,
  and `assetSha1` when the bundled file was normalized); the five flags
  are added with their aliases, Commons page and address, license,
  author, the notice's note and, for four, their `distractorTags`;
  `LANGUAGE_SUGGESTIONS` gains `lij`, `lmo`, `mwl`, `rm`, `vec` in the
  manifest's order.
- `read_language_asset(spec, cache, bundled)` returns a bundled file whose
  SHA-1 matches its pin without downloading; `language_entity` builds a
  flag's manifest entry (main and the check share it; hand-chosen colours
  win); the notice states the count in words, links CC BY 4.0 and appends
  a flag's note.
- New `tools/check_world_flags_generator.py` (offline, no flag-icons
  checkout): every language flag from its bundled file, its entity equal
  to the manifest's (after the banned pairs), the suggestions and the
  notice identical; added to `tools/validate_release.ps1`.
- `assets/world_flags/LICENSE-language-related-flags.md` is the tool's
  notice: Mirandese's CC BY 4.0 and Venetian's CC BY-SA 3.0 are links, and
  Romansh's authors read "Kanton Graubünden; Anton Nigg" as in the
  manifest.

**Not changed.** Every flag file, the manifest, the app, scoring,
progression, Course files and learner data.

### Follow-up in the same version: the Duel (owner, 6 October 2026)

**Why.** The owner saw a Duel question "Che cos'è?" with no picture in the
Viterbese Course: its "What is in the picture?" exercises (a Select with a
`picture` image) are Duel-eligible, but `DuelScreen` drew the prompt's
picture only in its Pick the translation branch. The owner also asked that
the last Lesson's Duel stop reading "Final Duel" both in the top bar and as
the page heading, by changing the heading rather than dropping it; of two
options (the Lesson's name, or always "Language Duel") the owner chose the
Lesson's name: even the Final Duel asks only the last Lesson's words.

**What changed.** `DuelScreen` draws `ExerciseFeatures.illustrationAsset`
under the question in the general branch too (`duel-question-picture`,
`CourseMediaImage`, 200 px, as in the translation branch); the page heading
(`_pageHeading`, `duel-page-heading`) is the Lesson's name from
`LessonPresentationService.identity(...).fullText` in every Duel, so the
Final Duel is named once, in the top bar. The learner panel key
`duel.title` ("Language Duel") stays in the catalogs, unused by the Duel.
Tests: `test/celebrations_264_test.dart` (a question with a picture shows
it, one without shows none, the Final Duel's top bar and its Lesson
heading); `learner_panel_260_test.dart` reads the new heading.

**Not changed.** Duel eligibility, rules, scoring, progression and learner
data.

## Revision 8 (2.0.64+264008, 6 October 2026): Lesson icons, sixteen new and any library picture

**Why.** On 5 October the owner approved sixteen new Lesson icon themes,
asked that they also appear in the image library, and that the Lesson icon
picker may use the whole library. The owner drew the icons (series 2). They
have smooth edges and up to five colours, where the fourteen icons of 2
September were flattened to four exact colours; on 6 October the owner
decided to keep them as drawn and to name the library category after what
they are, not "4 colors".

**What changed.**

- `assets/lesson_icons/`: the 16 PNG files; `LessonIconCatalog.options`
  30 entries, `addedInBuild264` the 16 new paths; the provenance notice
  `assets/lesson_icons/LICENSE.md` gains their section.
- `tools/validate_lesson_icons.py`: the four-exact-colours rule becomes a
  flat style (`_flat_style_issue`: shades within 24 levels merged, at most
  12 groups above 1% of the opaque pixels, covering at least 90%); the 14
  old icons score 3–4 groups at 100%, the 16 new 5–11 at 91–96%.
- Library: category `lesson_icons` (`imageCategories`, the validator's
  copy), 30 records `lesson_icon_<id>` whose `assetPath` is the icon's PNG,
  one for each catalog icon (tested and validated like the World Flags);
  `tools/validate_images.py` 2.7.0; `bundledImageCount` 4234.
- `LessonIconCatalog.isLibraryPicture` (`assets/exercise_images/<name>.webp`)
  is accepted for `themeIconAsset` by `Lesson.fromJson`, the Audit
  (`LESSON_THEME_ICON_INVALID` texts name the library) and
  `tools/validate_courses.py`.
- Lesson icon sheet: `lesson-icon-from-library` opens the library; a QQL
  picture or a library lesson icon becomes the Lesson icon, anything else
  is refused with `lesson-icon-from-library-refused`; the field and the
  collapsed row name it "Picture from the image library".
- `LessonIconPictures.withMinimumAppBuild` (on Course confirmation, beside
  Pages and picture answers): `minimumAppBuild` 264008 when a Lesson uses
  a library picture or one of the 16 new icons.
- Help EN/IT/ES: `editorHelp.qa.lessonIcon.a`.

**Not changed.** The fourteen icons, custom Course icons, Numbers, the
learner path's drawing; scoring, progression and learner data.

## Revision 7 (2.0.64+264007, 6 October 2026): everyday objects and toy-block letters

**Why.** The owner's first delivery of 5 October (series 1: 110 objects;
series 3: 26 capital letters built from toy bricks; series 2: 16 Lesson
icons) was checked that afternoon, but its list was written before the
tag rule and the category reorganization of Revisions 0 and 2. Vest,
Football goal and Mango were redrawn at the owner's request.

**What changed.**

- `assets/exercise_images/`: 136 WebP files; Vest, Football goal and Mango
  from `D:\QQL_plus\nuove_immagini\serie1_rifatte`; 30 objects with the
  grey edge.
- `metadata_v2.json`: 136 records. Objects keep the list's IDs except the
  seven whose category changed (five `urban_places` → `city_places` by the
  alias table, Nail clippers and Tweezers → `appearance`, where Revision 2
  put the grooming tools); the tag equal to the name is dropped (each
  keeps at least one). Block letters are `char_block_latin_capital_<x>` in
  `characters_blocks`, so the validator's glyph check applies.
- `lib/models/image_categories.dart`: `characters_blocks` ("toy blocks")
  after `characters_latin` in `imageCategories` and
  `characterCategoryLabels`; the copy in `tools/validate_images.py`.
- `bundledImageCount` 4204; Help EN/IT/ES (`findPicture`) names the
  toy-block letters; the category test checks the new label.

**Not changed.** The series 2 Lesson icons (a later revision, with the
picker); scoring, progression, Course files and learner data.

## Revision 6 (2.0.64+264006, 6 October 2026): 798 new pictures

**Why.** The owner noticed common words without a picture (player,
athlete, news, film maker…). A check of 2,776 common picturable words
against the catalog found 746 missing: 277 of priority A, 469 of B. The
owner also asked for clergy and places of worship of several religions,
more cats, dog breeds and the continent maps, and decided to rename the
friar Monk beside the new Buddhist monk. QQL wrote the lists (names,
categories, tags, what to draw, prompts in batches); the owner drew the
pictures and delivered them as `serie4_parole_A.zip`,
`serie5_religione.zip` and `serie6_parole_B.zip`.

**What changed.**

- `assets/exercise_images/`: 798 WebP files (295 + 13 + 490), each 256 ×
  256 within 50 KB; the 136 whose edge was at least a quarter near-white
  carry the grey edge drawn by `tools/outline_light_edges.py`.
- `metadata_v2.json`: 798 records appended (ID `<category>_<name>`, the
  list's tags, origin bundled); `religious_figures_monk` is labelled
  "Monk (Christian)"; series 4's 18 job names in Title Case.
- `test/support/bundled_image_catalog.dart`: `bundledImageCount` 4068.
- The SVG sources stay with the owner's ZIPs; they are not bundled.

**Checks before adding.** Every file as listed, with its SVG; format,
size, margins and the man/woman framing; every one of the 798 looked at on
contact sheets, the doubtful ones enlarged with the grey edge: nothing to
redraw.

**Not changed.** The app's code, categories, scoring, progression, Course
files and learner data.

## Revision 5 (2.0.64+264005, 6 October 2026): tags that open their pictures

**Why.** The owner asked whether the tags could be listed like the
categories. Measured: 6,889 different tags, 5,787 of them on a single
picture, so a list would be unusable; per category a row of frequent tags
would mostly repeat what Search finds. Decided on 5 October: no list and
no row, but the tags in a picture's card become links ("OK 1, no 2"), and
a tag shows the pictures that carry it exactly, not every word containing
its letters ("Ok B"; numbers shown: Search "cat" 63, "red" 43, "man" 163).

**What changed.**

- `carriesImageTag` (`lib/services/image_library_rules.dart`): a picture
  carries a tag when one of its tags, Local words or its name equals it,
  capitals and spaces ignored (QQL never repeats the name as a tag, so the
  name must count: the tag cat on the character 猫 shows the Cat picture
  too).
- `FlatImageLibraryScreen`: the card lists `Tags:` and `Local:` words as
  buttons (`image-preview-tag-<i>`, `image-preview-local-<i>`); a tap
  closes the card and sets the tag filter (`_openTag`: category All,
  search cleared), shown as an InputChip `exercise-image-tag-filter`
  ("Tag: …", delete tooltip "Remove the tag filter"); every category chip
  and the card's category go through `_chooseCategory` / `_openCategory`,
  which end it. The tiles keep their tag text.
- Help EN/IT/ES: `editorHelp.qa.findPicture.a`.

**Not changed.** The search (still "contains"), Search all, the tiles,
catalog, scoring, progression, Course files and learner data.

## Revision 4 (2.0.64+264004, 5 October 2026): a grey edge for light pictures

**Why.** Many of the new pictures are white or pale and nearly vanish on
the library's white tiles and in light-theme exercises (as Vest and
Football goal did before they were redrawn). The owner saw three options
rendered (a backdrop behind every picture, a grey outline around every
light figure, a grey edge only where the figure's edge is light) and chose
the last, B2, on 5 October.

**What changed.**

- The share of a picture's outer edge (its 1-pixel boundary, alpha ≥ 128)
  that is near-white (luminance > 225) measures how much of it is lost on
  white. 230 pictures had a quarter or more (110 at least half): every one
  now has a soft grey ring (colour 150/160/168, about 3 pixels, faded)
  outside the light parts of its edge only. Lossless pictures stay
  lossless (23), the others are lossy WebP at quality 92 (207); all stay
  256 × 256 and within 50 KiB (the largest 26.8 KB). After the change the
  most near-white edge left is Empty (a glass), 48%.
- `tools/outline_light_edges.py` holds the measure and the edge: for new
  pictures (files named on the command line, from a quarter near-white)
  and `--catalog` (only what the validator refuses, so a second run never
  draws a second ring).
- `tools/validate_images.py` 2.6.0 refuses a non-character WebP whose
  edge is half or more near-white, naming the tool.

**Not changed.** Picture names, tags, categories and IDs; character
pictures and flags; the app's code; scoring, progression, Course files and
learner data.

## Revision 3 (2.0.64+264003, 5 October 2026): confetti for a won Duel and a passed Test; Duel pictures

**Why.** The owner discussed replacing the Duel with a final Test and chose
to keep the Duel as it is, adding confetti for a won Duel and for a
successful Test Round (with a threshold: reaching it; without one: a
perfect result, confirmed on 5 October). The review also found that the
Duel showed the word of a QQL picture answer instead of the picture.

**What changed.**

- `DuelScreen._finishDuel` shows `ConfettiBurst` over the result dialog
  when the Duel is won, in every mode (a Preview or View Only Duel records
  nothing, but the confetti is only decoration).
- `RoundScreen`'s Test results dialog shows it when the Test is passed:
  `percent >= testPassingPercent`, or, without a threshold, every answer
  right.
- Both read Animations (`SettingsService.areAnimationsEnabled`) and use
  `ConfettiBurst.allowed`, so reduced motion and Animations off show none.
- The Duel's answers and its correct-answer line draw a QQL picture named
  by an icon key (`assets/…`) with `BundledPicture`, like the Round.
- Help EN/IT/ES (the XP and progress answer) and the Animations subtitle
  in Do Not Disturb name the three celebrations.

**Not changed.** The Duel's rules, scoring, progression, Course files and
learner data.

## Revision 2 (2.0.64+264002, 5 October 2026): image categories, Search all, no Admin categories

**Why.** The expansion brought 103 categories, some overlapping (two family
categories, two relationship categories, three games categories, four
city and service categories), two grab bags and twenty separate character
categories. The owner decided: reorganize, gather the characters under one
category with subcategories (Numbers apart, icon symbols not characters),
open Recognize characters on the characters, let no Admin create
categories (no device categories exist today) and map an Image Bank's
unknown categories to existing ones, and suggest, without blocking, a tag
different from the name for Admin pictures. During the revision the owner
added: a Search all box (on by default), the category in a picture's card
opening that category, and the removal of the two petting pictures.

**What changed.**

- `lib/models/image_categories.dart` is the one list: 72 ordinary
  categories, 20 character subcategories (`characters_…`) and `other`;
  `imageCategoryAliases` maps the 34 earlier names (and `food`, `home`) to
  the new ones, so a device picture or an Image Bank that still uses an old
  name is read correctly; `imageCategoryLabel` names them ("characters ›
  latin").
- The catalog's categories follow the map (`scratchpad/b264/rev2_map.py`):
  whole categories renamed or merged, and single pictures moved (the grab
  bags, the grooming items, the six character symbols, the clergy Bishop).
  No two pictures share a name in a category.
- The library shows "characters" as one chip; choosing it opens a second
  row ("all characters" and the 20 subcategories). Recognize characters
  opens there. Search all, on by default, makes a search look everywhere;
  unticked, it looks only in the category being browsed. The card's
  "Category: …" is a button that shows that category alone and clears the
  search.
- No category can be created or renamed any more. The device categories
  dialog appears only when the device has categories from before, and can
  only remove them. An Image Bank's unknown category opens a dialog with a
  menu per category (Other preselected); a category outside the library is
  refused.
- Tag hint: in Edit metadata, while every tag repeats the name, a line in
  the theme's tertiary colour suggests adding one; Save is never blocked.
  After adding pictures (one or several) and after an Image Bank import,
  the messages say how many have only their name as a tag.
- Editor Help (EN/IT/ES): How do I find a picture? (new) and the Image Bank
  answer. Technical docs: `FLAT_IMAGE_LIBRARY.md`, `IMAGE_BANK_PACKAGES.md`,
  `COURSE_EDITOR.md`.

**Not changed.** Course files (a Course's `sharedImageSource.category` is
a snapshot and stays as written), scoring, progression and learner data.

## Revision 1 (2.0.64+264001, 5 October 2026): World Flags in the image library, removals, mascots

**Why.** The expansion had brought 252 flag pictures that duplicated the
World Flags the app already ships for the Flag Game and the Course flag
picker, 172 country maps and a few pictures the owner did not want. The
owner decided: use the World Flags directly, add the European Union, the
United Nations and Quebec to them (Shortlist, no new category), clean the
awkward country names, remove the maps and the pictures listed, keep Dice,
put the grandparents together, and keep the mascot originals outside the
app while shipping WebP copies. The owner allowed the three downloads
(European Union and United Nations from flag-icons v7.5.0, Quebec from
Wikimedia Commons).

**What changed.**

- **Flags.** The 252 WebP flags are deleted. The catalog has one flag
  record for each of the 284 World Flags, pointing at its SVG. A record
  keeps the ID and tags of the WebP flag it replaces (242 matched, by ID
  or by name), adds the old name as a tag where the World Flag's name
  differs ("DR Congo", "Ivory Coast", "East Timor"), and takes the World
  Flag's name; the other 42 (language flags, ISO territories) get "flag",
  "flag of …" (or "… flag" and "language flag") and the aliases. Each
  record carries the flag's credit; when a Course uses a flag, Course Info
  adds that credit instead of "Original QuisquisLingo asset". Canary
  Islands, Bavaria, California, Texas, Hawaii and the Olympic flag had no
  World Flag and leave (owner: not added).
- **Drawing.** `BundledPicture` draws a QQL picture: WebP or PNG as before,
  an SVG through flutter_svg, always whole. The Course pictures, the
  embedded-image widget, the Round's picture answers, the library tiles
  and therefore the Duel and the picture fields use it. Crop square is not
  offered for a drawing; the library's details name the format SVG.
- **World Flags.** European Union, United Nations and Quebec join the
  Shortlist (eleven entries). Seventeen names are cleaned (for example
  "Croatia (local Name: Hrvatska)" → Croatia, "North Macedonia, Republic
  of" → North Macedonia, Swaziland → Eswatini, "Sint Maarten (dutch Part)"
  → "Sint Maarten (Dutch part)", "Viet Nam" → Vietnam); entity IDs stay,
  because Courses and the Flag Game store them. ISO aliases read
  naturally ("Korea, Democratic People's Republic of"); seven common
  alternative names are aliases. `tools/generate_world_flags.py` produces
  the same (stable IDs, the cleaner, the new flags); the Quebec credit is
  in `LICENSE-language-related-flags.md`, the Image credits page and
  `docs/MEDIA_CREDITS.md`.
- **Removals.** The 172 country maps (the World map stays, in
  maps_navigation), Ganesha, Shiva, Krishna, Lakshmi, Vishnu, Durga, Jesus,
  the Virgin Mary, Saint Francis of Assisi, Saint Peter, Buddha, General
  Custer and Die; Dice moves to games. No bundled, test or private Course
  used any of them.
- **Grandparents.** The two portraits move from people_family to
  family_relatives, beside the family-tree pictures, which become
  "Grandfather (family tree)" and "Grandmother (family tree)" so names
  stay unique.
- **Mascots and plants.** `assets/mascots/` holds WebP copies (quality 90,
  same size; 1 MB instead of 7 MB, a mean difference under 1/255 on
  white); the PNG originals moved to `design/mascots/`, the six unused
  Lesson plants to `design/lesson_plants/`, and `assets/lesson_plants/`
  left `pubspec.yaml`. The mascot loader accepts WebP (and PNG);
  `tools/make_avatars.ps1` reads the originals.
- **Tests and validators.** The pinned count is 3,272. The rules test ties
  the flag records to the World Flags one to one, with their names and
  credits, and checks WebP only for WebP pictures. World Flags, mascot,
  Welcome Wizard and layout tests follow the new counts and files.

**Not changed.** Course files, scoring, progression and learner data. The
category list (the now empty country_maps category goes in Revision 2).

## Revision 0 (2.0.64+264000, 5 October 2026): the image catalog: loading, rules and tags

**Why.** With 3,425 pictures the catalog file `metadata_v2.json` passed
1 MB. Flutter's `AssetBundle.loadString` decodes a file of 50 KB or more in
another isolate (`compute`), and under a widget test's clock that isolate's
answer never arrives: the complete suite stopped at the image library tests
(Copilot's own run waited 2 hours 22 minutes). Copilot's caches then kept
the loading Future itself, and a Future made in one test never completes in
the next, so the image library stayed on its loading circle.

**What changed.**

- `ExerciseImageMetadataService` reads the catalog's bytes and decodes them
  itself, in a few milliseconds; the app is not affected. The parsed
  catalog and the content index of QQL's pictures are kept per asset bundle
  as finished values; a failed read or an index that missed a picture is
  not kept, so the next call reads again. The parsed list was already
  unmodifiable.
- **The tag rule** (owner): every QQL picture has at least one tag besides
  its name, and the name is never repeated as a tag, because the library
  search reads the name already. Compared ignoring capitals and spaces, not
  accents (Café keeps the tag "cafe", which the search needs). 2,038 tags
  were removed. Twelve pictures whose only tag was their name have new tags
  (Dress: clothes, frock, gown; Jacket: clothes, coat, outerwear; Shoes:
  footwear, pair of shoes; Hat: headwear, clothes; Scarf: clothes, winter,
  neck; Shorts: clothes, summer, short trousers; Socks: clothes, feet, pair
  of socks; Necklace: jewellery, jewelry, chain; Wallet: money, purse,
  cards; Soup: bowl of soup, hot food, meal; Bird: animal, wings, feathers;
  Pot: saucepan, cooking, kitchen). The owner had removed ten repeated tags
  before the commit; the one left (the Occitan picture's "Occitan" and
  "occitan") went with the rule. The rule covers the QQL catalog only: a
  picture an Admin adds to a device keeps its name as its tag until the
  Admin adds others (tags may never be empty); a non-blocking hint comes in
  Revision 2.
- **Unique names**: a name appears once in a category, compared exactly
  (A and a are two letters). The 38 professions and Customer, drawn as a
  man and as a woman, are named "Lawyer (man)" / "Lawyer (woman)" (owner
  decision; planned for Revision 1, done here because the rule needs it).
- **Tests.** `test/image_catalog_rules_264_test.dart` checks every rule:
  record and file match both ways, unique IDs and paths, QQL categories,
  names, tags, a character named by its code point (170 pictures, such as
  `_00e9`) is that character, single-frame 256 × 256 WebP of at most 50 KB
  read from the file header (lossy or lossless), and the catalog opening
  inside a widget test within a few frames. The number of pictures is
  pinned once, in `test/support/bundled_image_catalog.dart`
  (`bundledImageCount` = 3,425), which also says which categories hold
  characters. Copilot's loosened tests read that number; the transparency
  test applies to illustrations, and character pictures may be opaque
  (owner). Two tests expected the name among the tags and now expect
  another tag; the library UI test names its new device category "Musical
  instruments", because Sports is now a QQL category.
- **Validators.** `tools/validate_images.py` 2.3.0 checks the same rules
  and, with Python's Unicode names, that every letter and kana picture is
  the character its ID names (1,207 character pictures checked).
  `tools/validate_media_assets.py` accepts one pair of identical files on
  purpose: Đ (U+0110) and Ð (U+00D0) look the same.

**Not changed.** Course files, the Course format, scoring, progression and
learner data. The pictures themselves. `tools/generate_exercise_image_metadata.py`
is stale since Build 242 (it reads the deleted QQL 234 manifest and knows
111 pictures); the catalog is now edited directly.
