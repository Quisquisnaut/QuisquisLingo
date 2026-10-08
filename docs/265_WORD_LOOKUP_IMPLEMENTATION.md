# Build 265: Word Lookup (implementation plan)

Written 6 October 2026, after Build 264 closed (Revision 10, `2.0.64+264010`,
committed and pushed). It turns `docs/265_WORD_LOOKUP_PLAN.md` (the owner's
decisions of 5 October) into files, steps and tests. Nothing here changes a
decision in that plan, except where §1 asks the owner to choose.

`docs/265_WORD_LOOKUP_PLAN.md` is still untracked (264 handoff): Revision 0
commits it with this file.

## 1. Owner decisions of 6 October 2026

Reading the code found four points the plan did not settle. The owner's
answers:

- **Q1:** skip source-language text, as recommended (no lookup on text
  stated `source`, on Story lines whose speaker is `source`, on the authored
  Instruction or on the Before you start note).
- **Q2:** no special rule. The owner's words: "I just meant not looking up
  source words. But do include target words in … from source exercises".
  Source-language words are never looked up (Q1). Target-language words keep
  lookup **before and after answering**, also in exercises whose answer is in
  the source language (Type the translation to source, Translation choice to
  source), as the plan says. The card may then show the answer; the owner
  accepts this. Example (Italian Exercise Lab, target Italian): the clue
  "buonanotte" in a translate-into-English exercise can be tapped; English
  words never can. In English from Italian the roles swap: English is the
  target and can be tapped; Italian never can.
- **Q3:** apostrophe pieces match whole entries only (rules 1–2), as
  recommended.
- **Q4:** Preview includes Draft GuideBooks and Draft entries. The owner asks
  whether Build 266 (GuideBook Modules) should come first; see §6.

The original questions follow for the record.

**Q1. Text in the learner's own language.** Prompt elements carry a language
(`source` / `target`). The authored Instruction is by definition the prompt
with no language, "written in the learners' language"
(`ExerciseFeatures.authoredInstruction`). The Before you start note and Story
narrators are usually in the source language too: in English from Italian
the narrator is `language: source` ("Tom entra in un bar di Londra.") and the
overview is Italian. Looking those words up against English targets gives no
useful hits, and can give false ones where the two languages share a spelling
(Italian *come* / English *come*, Spanish *a* / English *a*).
*Recommended:* look up only text that is not stated to be in the source
language: an element, a Story line (by its speaker's language) or a Page
block with `language: source` gets no lookup, and the authored Instruction and
the Before you start note are left out. Everything else in the plan's list
stays.

**Q2. Lookup that shows the answer.** When the answer is in the source
language, the card gives it away before the learner answers. For example,
*Type the translation* with the clue "good night" (target) shows
`good night = buonanotte`. *Translation choice* with "A coffee, please." shows
`the coffee = il caffè` when its answer is "Un caffè, per favore."
*Recommended:* in exercises whose answer is in the source language
(`ExerciseFeatures.answerLanguage == source`, Translation choice to source),
the prompt gets lookup only after answering. Every other exercise follows the
plan: lookup before and after.

**Q3. Apostrophe pieces in English.** The plan's rule (`l'acqua` = `l'` +
`acqua`) splits *you're*, *it's*, *Tom's* and *o'clock* in the same way.
Because the text and the entries are split identically, entries such as
`you're welcome` still match. But if rule 3 runs on a leftover piece like
`s` or `re`, tapping *Tom's* could show `it's ten o'clock`.
*Recommended:* when the card falls back to an apostrophe word's pieces, each
piece is looked up with rules 1–2 only (whole entries), never with rule 3.

**Q4. Preview and Draft GuideBooks.** Preview's Open GuideBook already opens
any GuideBook, Draft included (`round_screen.dart` near line 4537).
*Recommended:* in the Course Editor Preview, lookup also reads Draft
GuideBooks and Draft entries. The learner app never does.

## 2. Facts that shape the work

- Review vocabulary and the Round Wizard each have their own copy of the same
  parser: `VocabularyReviewService._parsePair` and `_GuidebookPair.parse`.
  Both use the separators `' = ', ' → ', ' - ', ':'` in that order.
  - Review reads only Published content (`learnerGuidebook`).
  - The Wizard reads `guidebook.vocabulary`, Drafts included.
  - The shared parser parses only: each caller keeps choosing its own
    entries.
- The Review fingerprint is `sha256(['qql232-v1', prompt, answer, []])`.
  Turning the English from Italian entries swaps prompt and answer, so that
  demo's Review memory starts again, as the plan says. No other Course is
  affected.
- `Course.fromJson` checks the types of known keys but does not refuse unknown
  Course keys. An earlier build ignores `wordLookup: false`, so lookup simply
  stays on there. **No `minimumAppBuild`** is needed. `wordLookup` joins the
  strict-boolean loop at line 1480.
- `allowPageSharing` is the pattern to copy: model lines 873/988/1393/1705,
  `authoring_duplication_service.dart:186`,
  `course_authoring_transfer_service.dart:364` and
  `course_merge_service.dart:227` (left value kept).
- The one-time notice fits the existing learner family:
  `SettingsService.hasSeenLearnerOneTimeNotice` / `markLearnerOneTimeNoticeSeen`
  store `learner_<id>_one_time_notice_seen_<id>`, which Show one-time notices
  again already clears. **No new persisted key family.** Revision 1 checks
  that `InventoryService` and `docs/239_RESET_STORAGE_INVENTORY.md` describe
  that family generically, and edits them only if they list ids one by one.
- `ExercisePromptPanels` is shared with the Duel. The Duel must stay without
  lookup, so the widget gets lookup only from a surrounding scope that the
  Duel never provides.
- No `SelectionArea` in the Round or Page widgets, so taps do not compete with
  text selection.
- Build 266 replaces `content` with modules. The lookup index therefore takes
  a flat list of `(entryId, text, lessonIndex)` and never reads the
  `Guidebook` shape itself, so 266 only changes how that list is fed.
- `LessonPresentationService.identity(course, index).fullText` produces the
  path's Lesson name ("Lesson 2: Al bar", with numbering modes and duplicates
  handled). The card uses it instead of building "Lesson N · title" by hand.

## 3. Design

### 3.1 Pure Dart (`lib/services/word_lookup/`, no Flutter)

- `guidebook_vocabulary.dart`:
  - `GuidebookVocabularyPair { target, source }`;
  - `static GuidebookVocabularyPair? parse(String line)`: today's algorithm,
    unchanged, so existing Courses parse the same way.
- `word_lookup_text.dart`, splitting text into words:
  - lower case; punctuation removed; spaces collapsed; accents kept;
  - `’` read as `'`; an apostrophe word splits as `l'` + `acqua`; a hyphenated
    word stays one word;
  - a word containing `_` is a gap and is never looked up;
  - runs of Han, Hiragana, Katakana, Thai, Lao, Khmer, Myanmar or Tibetan are
    detected by Unicode script ranges and split into grapheme clusters
    (`characters` package: pure Dart and already in the dependency graph via
    Flutter; it is declared explicitly in `pubspec.yaml` only if the analyzer
    asks);
  - every word keeps its start and end offsets in the original string.
- `word_lookup_index.dart`:
  - `WordLookupIndex.build(List<WordLookupSourceEntry>)`;
  - entries are kept in Course order; identical entries (same target and
    source after normalization) are shown once;
  - a word count (how many entries' target sides contain each word) drives
    the more-than-3 rule;
  - a map from first word (or first character) to the candidate entries is
    used for expression matching.
- `word_lookup.dart`:
  - `resultsAt(text, offset, currentLessonIndex) → List<WordLookupEntry>`
    implements the plan's priority: longest covering expression (counted in
    words, or in characters inside a no-space run), then the word alone, then
    the word inside an expression (spaced text only), then the Lesson rule,
    and the apostrophe fallback of Q3;
  - `tappableRanges(text, currentLessonIndex)`: the character ranges with a
    result, worked out once per text and cached. They drive the hand cursor
    and the hit test;
  - `allIn(text, currentLessonIndex)`: every distinct result in a text, for
    the keyboard path.
- `word_lookup_sources.dart`, `sourcesFor(Course, {includeDrafts})`:
  - Lessons in Course order, with their path index;
  - `learnerGuidebook(...)` content, or all content in Preview (Q4);
  - vocabulary only;
  - empty unless `useGuidebook && wordLookup`.

### 3.2 Widgets

- `WordLookupScope` (an InheritedWidget plus a controller):
  - holds the index, the current Lesson index, `enabled`, and the single open
    card (opening a new card closes the old one);
  - `RoundScreen` provides it when the conditions hold:
    - `course.useGuidebook && course.wordLookup`;
    - `round.roundType != RoundType.test`;
    - the index is not empty.
  - The Duel never provides it.
- `LookupText` (stateful) replaces `Text` / `Text.rich` at the chosen places:
  - Without a scope (or on source-language text, Q1) it draws exactly the
    old widget, so goldens and finders stay the same.
  - With a scope it draws one `RichText` and **no per-word recognizers**,
    because recognizers would turn every word into a separate link node for
    screen readers.
  - A `GestureDetector` over the paragraph maps the tap to a text offset
    (`RenderParagraph.getPositionForOffset`). On a tappable range it
    highlights that range and opens the card anchored to
    `getBoxesForSelection(range)`.
  - A `MouseRegion` with `onHover` switches to `SystemMouseCursors.click`
    only over a tappable range.
  - It accepts styled runs (from `InlineMarks.parse`), so Page bold and
    italic are kept: lookup works on the plain text and the styles are laid
    back on by offset.
- `WordLookupCard`:
  - an `OverlayPortal` beside the word, flipped above it near the bottom
    edge, at most 320 px wide;
  - shows the target, then the source, then the Lesson `fullText`, then the
    fixed line;
  - several results are listed one after another, in plan order;
  - closes on a tap outside (`TapRegion`), Escape, or any `ScrollNotification`
    from the Round's scroll view;
  - keys `word-lookup-card` and `word-lookup-entry-<i>`.

### 3.3 Where `LookupText` goes

Line numbers refer to `round_screen.dart` at `264010`.

| Surface | Place | Key / note |
|---|---|---|
| Question | `_selectExercise` ~2282 and the other kinds' question texts | `select-question-text` and its counterparts in Input, Arrange, Presentation |
| Context, dialogue turns, passage | `ExercisePromptPanels` 54–108 | turn text only, not the speaker name |
| Story line | `_lineBubble` 3625, when the text is shown | after the audio with `textReveal: afterAudio` (3392–3399); speaker language decides (Q1) |
| Story cover title line | `_storyCoverExercise` 3564 | |
| Page text blocks | `PageCardView` 140–189 | headings, paragraphs, quotes, lists; never links |
| Correct-answer line | ~1917, ~4968 | |
| Before you start note | ~4517 | never (Q1: learner's language) |
| Authored Instruction | | never (Q1: learner's language) |

Never: options, word blocks, Match tiles, Page links, standard instruction
lines and buttons, the GuideBook screen, Review vocabulary cards, the Duel.

### 3.4 Course switch

- `Course.wordLookup`: default `true`, written only when `false`, strict
  boolean.
- Carried by duplicate/fork and transfer; Merge keeps the left value.
- `tools/validate_courses.py` refuses a value that is not a boolean.
- Course Editor, Lesson Options (near the Use GuideBook switch, line ~2786):
  `SwitchListTile` `course-word-lookup`, hidden while Use GuideBook is off;
  its subtitle names what it does.

### 3.5 Texts

- Learner panel, seven languages (`lib/localization/learner_panel/*`):
  - `wordLookup.note` "One possible translation from this Course's
    GuideBook.";
  - `wordLookup.notice` "Tap a word to see a translation from this Course's
    GuideBook.";
  - `wordLookup.action` "Vocabulary in this text".
- Help EN/IT/ES:
  - a learner answer (what the card is, where it works, never in Tests or the
    Duel);
  - the Lesson Options entry for the switch;
  - the GuideBook vocabulary help states target = source.
- The editor hint "One target/source pair per line" stays. The Wizard's
  message "Example: casa = house" stays correct for a Course whose target
  language is Italian.

## 4. Revisions (one local commit each)

Each revision:

- bumps the version (`2.0.65+265000`, `265001`, `265002`) and the Beta expiry;
- updates CHANGELOG, README, AGENTS (release boundary), `265_CHANGE_SUMMARY`,
  `265_HANDOFF` and `265_VALIDATION`;
- runs the analyzer, the focused tests and the complete suite before the
  commit;
- keeps `docs/266_GUIDEBOOK_MODULES_PLAN.md` untracked unless the owner says
  otherwise.

### Revision 0: parser, convention, engine (no UI)

1. `guidebook_vocabulary.dart`; `VocabularyReviewService` and
   `guidebook_round_generator.dart` call it; `_parsePair` and
   `_GuidebookPair` are deleted.
2. `tools/generate_english_from_italian_260.py`:
   - the 36 entries become target = source;
   - the assertion at line 361 still holds (one `" = "`, no other
     separator);
   - regenerate the bundled JSON and its fixture, then check that the Round
     Wizard on that Lesson now uses English as the target.
3. `word_lookup_text.dart`, `word_lookup_index.dart`, `word_lookup.dart`,
   `word_lookup_sources.dart`.
4. Tests:
   - `test/guidebook_vocabulary_265_test.dart`: separators, empty sides, the
     old parsers' cases carried over.
   - `test/word_lookup_265_test.dart`, one case per example in the plan:
     - *Mangio il pane* (tapping "il" or "pane" finds `il pane`);
     - *il pane fresco* (a tie, settled by Lesson, then both shown);
     - `l'acqua` over `acqua`, and `l'` + `acqua` shown together;
     - `papa` ≠ `papà`, `e` ≠ `è`, `’` = `'`;
     - "gatto" in "un gatto" finds `il gatto`;
     - the more-than-3 rule (il, the);
     - the Lesson rule, including an expression from another Lesson beating
       a word of the current one;
     - nothing found gives an empty result;
     - gaps `___` and `dr_ink_`;
     - 我的猫 (taps on 的 and 猫), a Japanese sentence mixing kana and
       kanji, a Thai sentence with combining marks, Latin words inside a Han
       run;
     - the Q3 piece fallback.
   - `test/word_lookup_sources_265_test.dart`: Draft GuideBook and Draft
     entries excluded in the learner app and included in Preview (Q4); Use
     GuideBook off or `wordLookup: false` gives nothing; locked Lessons are
     included.
   - Existing Review and Wizard tests that name English from Italian
     prompts: update the expected sides.

### Revision 1: the card everywhere, the switch, the notice

1. `Course.wordLookup` and its copies, the validator, the editor switch.
2. `WordLookupScope`, `LookupText`, `WordLookupCard`; the sites of §3.3; the
   Test and Duel exclusion; the hand cursor; the Q1 language rule.
3. One-time notice, id `word_lookup_<Uri.encodeComponent(courseId)>`. It
   shows when a Round opens with lookup enabled; it is skipped when there is
   no active learner (Preview).
4. Learner-panel texts in 7 languages; Help EN/IT/ES.
5. Tests in `test/word_lookup_ui_265_test.dart`:
   - a tap opens the card with the right lines;
   - a tap outside, Escape or a scroll closes it;
   - no card in a Test Round, the Duel, or with Use GuideBook / Word Lookup
     off;
   - a timed Round keeps counting while the card is open;
   - Review and Preview behave as specified;
   - after-audio Story text has no lookup until it is revealed;
   - text stated `source`, a source-language narrator, the Instruction and
     the Before you start note have no lookup; a target clue in a
     translate-to-source exercise has lookup before and after answering;
   - no XP, progress or Review change after a lookup;
   - the notice shows once per learner and Course and comes back after Show
     one-time notices again;
   - model round-trip, the copies keep the value, Merge keeps the left value.

### Revision 2: keyboard, screen readers, Laboratory

1. Each `LookupText` with results gets a `Focus` (Tab). Enter opens the card
   with `allIn(...)`. `Semantics(customSemanticsActions: {wordLookup.action:
   …})`. No visible change.
2. Narrator on Windows: a manual check, written up in `265_VALIDATION`.
3. Rename **QQL Demo: Italian Exercise Lab**: the title only, at the places
   the plan lists.
4. 10–15 entries per Laboratory Lesson, written by hand from each Lesson's
   Italian text and shown to the owner before they are generated, covering
   the plan's four cases.
   - Check the Lab's Review vocabulary and the Wizard (three pairs or more
     per Lesson).
5. Tests:
   - keyboard opening;
   - the semantics action;
   - the Lab title wherever it is named;
   - the Lab's entries parse, and each Lesson has ≥ 3 pairs;
   - the four cases resolve as intended on the Lab's real sentences.

## 5. Risks

- **`round_screen.dart` is large** (≈187 KB). Changes stay at the sites in
  §3.3, and `LookupText` without a scope draws exactly the old `Text`, so
  existing finders (`find.text`, keys) keep working.
- **Hit testing on wrapped and bidirectional text:** offsets come from the
  paragraph's own layout, so line wraps are handled. Arabic and Hebrew are
  not a target of this build; they get words as in any spaced script.
- **Cost:** the index is built once per Round open (the Lab will have about
  100 entries), and tappable ranges are cached per text. No measurable
  effect is expected; Revision 1 measures the open time of a 15-exercise
  Round on the Lab.
- **Build 266:** only `word_lookup_sources.dart` should change there.

## 6. Order of Builds 265 and 266 (open)

- **265 first** (as both plans say today):
  - smaller and visible to learners sooner;
  - the engine reads a flat entry list, so in 266 only the sources adapter
    changes;
  - cost: the Laboratory's entries are written in the old shape and then
    moved into one module per Lesson by 266's generator helper. The English
    from Italian entries are turned once in 265 and split into modules in
    266 Revision 2. Both moves are mechanical.
- **266 first:**
  - content is written once, directly in modules;
  - 266 Revision 0 must then take over the `GuidebookVocabulary` parser and
    the target = source convention;
  - 266 is the larger and riskier build (every GuideBook reader, editors,
    converters, re-signed fixtures), so Word Lookup ships later.
- **Recommended:** keep 265 first. The rework it causes is small and
  mechanical; the risk of 266 is not.
