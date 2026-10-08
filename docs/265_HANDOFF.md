# Build 265 handoff

Saved 7 October 2026, 00:20. **Revisions 0–3 are merged into `main`
(PR #36, `bce14c2`). Their release `v2.0.65+265003` (Android debug
package) was deleted at the owner's request at midnight; the tag stays and
Latest is `v2.0.64+264010` again. Revision 4 (2.0.65+265004) is committed
on branch `claude/265-revision4` (not pushed):
another session's change of the same evening (distractor and Match limits
become Audit Info) taken in by the owner and completed here. The completion
covers four points:**

- **Spell the word extras become Info;**
- **Listen and match repeated values become Info, graded like Match (`_matchingReadsAsExpected`);**
- **notices say a repeat may be deliberate;**
- **firmer distractor recommendations in Help and tooltips (EN/IT/ES), AGENTS.md, CHANGELOG and docs.**

**Complete suite 23:46–00:19: 3806 passed, 1 skipped, 0 failed. Push, PR
and merge only on the owner's word. No Revision 5: Word Lookup stays available before answering (owner
decision). Still open for the owner: the Windows Narrator check. Known Word
Lookup defects found in review are fixed in this revision too (owner,
23:55): a long card stays open while scrolled, a quoted word is found,
apostrophe pieces use rule 3. Word Lookup tests pass (83).**

**Revisions 5–8 (owner's brief of 7 October 2026, "Image Library: tags, a
redrawn picture, new pictures"): one revision at a time, the next only after
the owner's review. Revision 5
(2.0.65+265005) is in progress in the working tree, see "Revision 5
progress" at the end.**

Plan: `docs/265_WORD_LOOKUP_PLAN.md` (owner decisions of 5 October).
Files, steps and the owner's answers of 6 October (Q1–Q4):
`docs/265_WORD_LOOKUP_IMPLEMENTATION.md` (both committed with Revision 0).
Never stage
`docs/266_GUIDEBOOK_MODULES_PLAN.md`, `docs/267_COURSE_WIZARD_PLAN.md`
(other plans), `devtools_options.yaml` or `tools/cloud_setup.sh`.

## Revision 0 progress (2.0.65+265000)

Done in the working tree (17:05):

- `lib/services/guidebook_vocabulary.dart` (`GuidebookVocabulary.parse`,
  `GuidebookVocabularyPair`); `VocabularyReviewService` and
  `GuidebookRoundGenerator` use it, their copies deleted.
- `tools/generate_english_from_italian_260.py`: 36 entries English first;
  bundled JSON regenerated (`--check` PASS; `tools/validate_courses.py` OK).
- `lib/services/word_lookup/word_lookup_text.dart`, `word_lookup.dart`,
  `word_lookup_sources.dart`.
- Tests: `test/guidebook_vocabulary_265_test.dart`,
  `test/word_lookup_265_test.dart` (35 with the first), 
  `test/word_lookup_sources_265_test.dart`; `english_from_italian_260_test`
  expects `thank you = grazie`. Focused: all pass.
- Version pins (pubspec, app_metadata, beta_lifecycle_service and its test,
  four metadata tests), expiry 2026-11-05; README, CHANGELOG, AGENTS,
  `265_CHANGE_SUMMARY.md`.

Analyzer clean; focused batch 174 passed; complete suite 17:04–17:35:
3758 passed, 1 skipped, 0 failed. Committed as "Build 265 Revision 0:
Word Lookup: one vocabulary reader, the lookup rules".

## Revision 1 progress (2.0.65+265001)

Done in the working tree (18:05): `lib/widgets/word_lookup_view.dart`
(scope, `LookupText`, card, notice), `RoundScreen` (`_buildPage` wrapped
in the scope; sites in `265_CHANGE_SUMMARY.md`), `ExercisePromptPanels`,
`PageCardView`, `ExerciseFeatures.textLanguageOf`, `Course.wordLookup` with
its copies and the Merge key, the Lesson Options switch, the validator,
learner panel texts (7), Help EN/IT/ES, the notice seam in
`test/flutter_test_config.dart`, the storage inventory doc, version 265001.
Tests: `test/word_lookup_ui_265_test.dart` (20) and the related batches
pass; complete suite 18:05–18:37: 3778 passed, 1 skipped, 0 failed.
Committed as "Build 265 Revision 1: Word Lookup on the learner's
screen". Next: Revision 2 (keyboard and screen
readers; the Laboratory rename and its vocabulary, entries shown to the
owner before generating).

## Decisions taken while building

- The parser lives in `lib/services/guidebook_vocabulary.dart`, not under
  `word_lookup/`, because Review and the Wizard use it; index and rules share
  `word_lookup.dart`.
- Rule 3's "more than three entries" counts distinct target sides (an entry
  repeated in four Lessons counts once).
- The highlighted span of a result is the union of the winning
  occurrences (for the apostrophe-piece fallback, also the whole word).

## Next revisions

- Revision 1: the card, Test/Duel exclusion, cursor, notice, the
  `wordLookup` Course switch, texts, Help (implementation plan §4).
- Revision 2: keyboard and screen readers; the Laboratory rename and
  vocabulary (entries shown to the owner before generating).

## Revision 5 progress (2.0.65+265005)

Saved 7 October 2026, 01:37. Done in the working tree (not committed: the
owner's brief says "No commit"):

- Version pins and Beta expiry 2026-11-06 (release 7 October): pubspec,
  `app_metadata.dart`, `beta_lifecycle_service.dart` and the five pinned
  tests (every date of `beta_lifecycle_test.dart` one day later).
- Catalogue (`assets/exercise_images/metadata_v2.json`, 4,244 records),
  edited by a script that always starts from `git show HEAD:` and applies
  the data in the session scratchpad (`apply_rev5.py`, `rev5_data.py`,
  `g1_*.py`; copies of the final data go to the change summary):
  point 1 (seven records' tags), point 2 (`friend` off Man and Woman, also
  in `TAG_OVERRIDES` of `tools/generate_exercise_image_metadata.py`), the
  ten new records (appended), point 6 (group 1 complete: 546 records, none
  below five tags).
- Pictures: drawn in SVG and rendered with headless Chrome by
  `D:\QQL_plus\nuove_immagini\serie7_265\draw.py` (sources in `svg/`, WebP
  in `webp/`, outside the repository), copied to `assets/exercise_images/`:
  `tennis_racket.webp` (redrawn, same path), `artichoke`, `fig`,
  `macaroni`, `provolone`, `orange_soda`, `asteroid`, `dry_soil`,
  `tennis_player_man`, `tennis_player_woman`, `friends`. All lossless,
  10–26 KB, margins 15–17 px, none needs the grey edge (light edge 0–13%).
  IDs chosen by the catalogue's convention: `nature_asteroid` (not
  `time_space_asteroid`: `time_space` is no category; Comet, Galaxy and
  Planet are in nature); job labels in Title Case (`Tennis Player
  (woman)`).
- `tools/validate_images.py` 2.8.0: the tag report (point 5), not refused.

Tag rule applied (the owner's general rules): a new tag is checked against
every other record; it is dropped when another picture carries the same
word only as a tag and is the better answer (a word-to-picture match
ranks a tag below a name and breaks ties by
fewer name words, then ID, so the wrong picture could win: e.g. "gift",
"letter", "postbox", "scales", "underground", "take away", "close").
A tag equal to another picture's label is kept when it is the more general
or related word (the owner's own examples: dog: puppy, bed: bedroom); the
label wins there.

Update 01:57: tests done (`bundledImageCount` 4244,
`test/image_library_tags_265_test.dart`; four older tests that pinned Man's
"friend" or Jump's three tags updated, one searched "friend" to find Man and
now searches "adult man"); CHANGELOG, README, AGENTS.md, change summary and
`docs/265_REVISION5_TAGS.md` (every tag added, generated) written; analyzer
clean. The first complete-suite start was stopped after two minutes: the
review sheet showed the Asteroid cut at the bottom. Cause: headless Chrome
paints about 100 pixels less than its window height, so every render lost
its bottom ~6 units; `draw.py` now renders into a taller window and crops
(all eleven re-rendered and copied again). The Build 264 redraws (Vest,
Mango) have the same cut: flagged as a separate task, not fixed here.
Another session wrote `docs/COLLOCATION_PICTURES_PROPOSAL.md/.json` into
this checkout at 01:34 (a new "collocations" category, checked against the
Revision 4 catalogue): never stage or edit them; `apply_rev5.py` now refuses
to overwrite `metadata_v2.json` if it changed since its last write.

Done 02:30: complete suite 01:57–02:27, 3812 passed, 1 skipped, 0 failed;
`tools/validate_images.py` 2.8.0 and `tools/validate_media_assets.py`: 0
issues (tag report: 1,600 below five, all in groups 2–4);
`docs/265_VALIDATION.md` written.

Owner's answers of 7 October 2026 (morning): commit Revision 5 locally
(done: "Build 265 Revision 5: image library tags, a redrawn picture, ten new
pictures", not pushed); go on with Revision 6, which also takes: Vest and
Mango re-rendered, Jump renamed from "Saltare", one picture per person for
the personal pronouns (names "I, me, my, myself"…; "me" and "myself" move
from I am), friend (male/female), kid (boy/girl, other colours than Boy
and Girl), Hello, Bye, Goodbye (text if necessary), flag tags written in
`metadata_v2.json` (nothing builds them). Still under discussion: labels
"(man)/(woman)" versus "(male)/(female)" for people, and plurals (a badge?).

## Revision 6 progress (2.0.65+265006)

Saved 7 October 2026, 09:49. Revision 5 committed as `ea159c2` (local, not
pushed). Revision 6 in the working tree, not committed (commit only on the
owner's word):

- Version pins (expiry unchanged: same release day).
- Pictures (`D:\QQL_plus\nuove_immagini\serie7_265\draw6.py`): the eight
  pronouns, Friend (man/woman), Kid (boy/girl), Hello!/Bye!/Goodbye!;
  five got the grey edge. Vest and Mango re-rendered
  (`serie1_rifatte/redo.py` patched; old files kept as `*_before_265.webp`).
- Catalogue by scratchpad `apply_rev6.py` from `git show HEAD:` (guarded
  against other sessions' edits): Jump renamed, "me"/"myself" off I am,
  "glass of water" off Drink, 15 records, group 2 complete (539).
- Tests updated and focused batches green (86 + 116); docs written
  (CHANGELOG, README, AGENTS.md, change summary, `docs/265_REVISION6_TAGS.md`).

Done 10:57: analyzer clean; first complete run failed one test (the new
Hello! had taken the retired path `assets/exercise_images/hello.webp`; file
renamed `hello_greeting.webp`); rerun 10:26–10:56: 3814 passed, 1 skipped,
0 failed; validators 0 issues (tag report 1,061, groups 3–4);
`docs/265_VALIDATION.md` written. Owner (11:00): commit Revision 6 and start
Revision 7; Friend (woman) must show two women (a same-version follow-up
commit). Committed as "Build 265 Revision 6: group 2 tags, personal
pronouns, friends, kids, greetings" (`49865fb`, local, not pushed).
Follow-up in the working tree: `friend_woman.webp` redrawn with two women
(`draw6.py`: `SPEAKER_WOMAN`); complete suite 11:11–11:43: 3814 passed,
1 skipped, 0 failed; committed as "Build 265 Revision 6 follow-up: Friend
(woman) shows two women". Next: Revision 7.
Revision 7 (group 3, Lesson icon tags in `metadata_v2.json`) and Revision 8
(group 4 + the rule) wait for the owner's review; Revision 9 = plurals
(stacked copies, a per-picture switch; changes the Course format).

## Revision 7 progress (2.0.65+265007)

Saved 7 October 2026, 11:50. Revision 6 follow-up committed as `cb73c6a`
(Friend (woman) with two women). Revision 7 in the working tree: version
pins; group 3 complete (546, Lesson icons tagged in `metadata_v2.json`),
the owner's four "you" tags, "hoover" moved to Vacuum cleaner, Hot "hot
drink" (scratchpad `apply_rev7.py`, `rev7_data.py`, `g3_*.py`); tests and
docs written; focused batch 203 passed; analyzer clean; validators 0
issues. Complete suite skipped at the owner's word (13:30; a first run hung
on a nearly full D:, now cleaned). Committed as "Build 265 Revision 7:
group 3 tags" (local, not pushed).
Revision 8 = group 4 and the five-tag minimum as a rule; Revision 9 =
plurals.

## Revision 8 (2.0.65+265008)

Saved 7 October 2026, 13:50. Revision 7 committed as `9978ccd`. Revision 8
done: group 4 complete (515), no picture outside the characters below five
tags, `tools/validate_images.py` 2.9.0 refuses fewer than 5 / more than 32
/ a tag over 80 characters, `image_catalog_rules_264_test` checks the same;
"racket" moved from Tennis to Tennis racket. Focused 206 passed, analyzer
clean, validators 0 issues; complete suite skipped at the owner's word.
Committed as "Build 265 Revision 8: group 4 tags; five tags become a rule".

Owner decisions of 7 October 2026 (13:40, "Agreed"): **Revision 9 = image
category groups**, display only (stored categories unchanged, like the
Characters chip): people (people & family, jobs, relationships, life
stages, appearance, personality, emotions), food & drink (food & drinks,
food descriptions, restaurant), body & health (body parts, health care,
health & illness, death & remembrance), home & things (home, everyday
objects, tools, technology, materials, utilities), places & travel (city
places, architecture, landmarks, services, shopping, maps, travel,
transport, street signs, construction & farming), numbers & time (numbers,
clock times, time & calendar, units, sizes, shapes & patterns), language &
grammar (grammar, grammar_time, pronouns, question words, quantity &
pointing, directions & positions, opposites, greetings, languages), society
& culture (politics, crime & law, economy, business, ideas & opinions,
communication, culture & traditions, celebrations), history & stories
(historical figures, literary characters, mythology, religious figures),
free time (hobbies, sports, games, art & cinema), nature & animals (nature,
animals); alone: flags, Lesson icons, actions, movement, clothing, school &
work, concepts, symbols, colours, other, characters. Lowercase chip labels;
a group's name is searchable; the namesake-tag rule stays at category
level. **Revision 10 = plurals** (stacked copies, a per-picture switch;
changes the Course format).

## Revision 9 (2.0.65+265009)

Saved 7 October 2026, 14:00. Revision 8 committed as `90a174d`. Revision 9
done and waiting for the owner's review: category groups in the image
library (model, screen, search by a group's whole name, Help EN/IT/ES,
`docs/COURSE_EDITOR.md`, `test/image_category_groups_265_test.dart`).
Analyzer clean, focused tests passed; complete suite skipped at the
owner's word. Committed at the owner's word as "Build 265 Revision 9:
image category groups". Search matches a group only by its whole name
(owner asked for the explanation, 7 October: single words would flood
"time" 131 → 266 results, "people" 56 → 332).

Owner decisions of 7 October 2026 for **Revision 10 = historical figures**
(plurals move to Revision 11): remove Columbus; country tags on every
figure (Alexander the Great keeps no modern country); no sensitive figures
(Anne Frank, Sitting Bull, Moctezuma, Martin Luther), no Einstein, Frida
Kahlo, Martin Luther King or Picasso (name/likeness rights); Genghis Khan
kept; Pollock added; more figures from places still missing. No complete
suite for Revision 10.

## Revision 10 (2.0.65+265010)

Saved 7 October 2026. Revision 9 committed as `a68a2da`. Revision 10 done
and not committed: 40 figures drawn by
`D:\QQL_plus\nuove_immagini\serie8_265_figures\draw10.py`, Columbus
removed, country tags; the owner approved 22 landmarks (Big Ben …
Kilimanjaro, no religious buildings), drawn by `draw10_places.py` in the
same folder; accent-free spellings as tags. 4,320 pictures,
`test/figures_and_landmarks_265_test.dart`, validators 0 issues, no
complete suite (owner). Next: the owner's review and commit; Revision 11,
plurals.

## Revision 11 (2.0.65+265011)

Saved 7 October 2026. Revision 10 committed as `6fe9638`. Revision 11,
plural pictures (owner's look A with a per-picture switch), implemented
and not committed: element attribute `plural` (image elements, `icon`
text elements), `PluralPictures` (marks, minimum build 265011),
`ExerciseDraftValues.pluralPictures` applied by the builder and read by
`PresetRecipes.decompose`, the Plural chip in `ExerciseImageField`
(exercise picture and answer pictures), `PluralPicture` in the Round and
the Duel, capabilities and the Python validator, Help EN/IT/ES,
`test/plural_pictures_265_test.dart` (11 passed), focused tests 368
passed, analyzer clean. Added at the owner's word while testing (same
revision): spelling presets need two blocks; nine family scenes (person
ringed in yellow), the family-tree pictures named "(family tree)"; Man 2,
Man 3, Woman 2, Woman 3; Friends (women) (4,334 pictures); the spelling
forms' optional Extra blocks with a note (owner: "an extra field with a
note"). Revision 11 is the last
planned revision of Build 265. Complete suite on the final tree: 3,857
passed, 1 skipped, 0 failed; committed at the owner's word as "Build 265
Revision 11: plural pictures; family scenes; spelling blocks". Next: on
the owner's word, push `claude/265-revision4` and a pull request
(Revisions 4–11); the owner's Windows Narrator check is still open; then
Build 266 (GuideBook modules) on the owner's go.
