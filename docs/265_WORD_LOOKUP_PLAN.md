# Build 265: Word Lookup (plan)

Owner decisions of 5 October 2026, from the discussion of the Build 265
proposal "let learners look up words they encounter in a Course by using
vocabulary already authored in that Course's GuideBooks". The plan is
confirmed; implementation starts only after Build 264 is closed (its
Revision 2 was in progress in the working tree when this plan was written,
last commit `b17f44c`).

On-screen name: **Word Lookup**.

## 1. What exists today

- A GuideBook vocabulary entry is one text line `A = B` (Content
  `kind: vocabulary`, role `vocabulary`; separators ` = `, ` → `, ` - `,
  `:`). It has no other fields: no forms, notes, audio or part of speech.
- Two copied parsers read it: `VocabularyReviewService._parsePair` (Review
  vocabulary) and `_GuidebookPair.parse` (Round Wizard,
  `lib/services/guidebook_round_generator.dart`).
- The side order was not consistent. The GuideBook editor says "One
  target/source pair per line. Example: casa = house" and the Round Wizard
  reads the left side as the target. QQL Demo: English from Italian (the
  only bundled Course with vocabulary, 36 entries) writes source = target
  (`ciao = hello, hi`), so the Round Wizard reads its Italian words as
  English. QQL Demo: Exercise Laboratory has no vocabulary (overviews only).
- Learner text is drawn in many places (about 180 `Text` sites in
  `lib/screens/round_screen.dart`, plus `PageCardView` and
  `ExercisePromptPanels`), so lookup is added with a shared widget at chosen
  sites, not with a global switch.
- Review vocabulary already follows Use GuideBook and leaves Draft
  GuideBooks out (`PublicationService.learnerGuidebook`).

## 2. Rules

### Source

- The vocabulary of the published GuideBooks of the **whole Course**
  (locked Lessons included; Draft GuideBooks excluded).
- Lookup exists only when the Course's Use GuideBook is on **and** its
  Word Lookup switch is on.
- Entry format: **target = source** (the convention the editor already
  states). One parser, `GuidebookVocabulary`, used by Review vocabulary, the
  Round Wizard and the lookup.
- No online dictionary, no invented translation: fully offline.

### Matching

- Only the **target** side of an entry is searched.
- Text and entries are normalized the same way: small letters, punctuation
  removed, spaces collapsed; **accents kept** (papa ≠ papà, e ≠ è); `'` and
  `’` are the same character and an apostrophe stays with its word
  (`l'acqua` is the elided `l'` followed by `acqua`).
- No inflected forms for now ("gatti" does not find "gatto").
- Priority, for the word the learner taps:
  1. the **longest expression** in the text that covers the tapped word and
     equals a whole target side (tapping "pane" or "il" in "Mangio il pane"
     finds `il pane = the bread`; the single word is not shown). Length is
     the **number of words**, never of letters (owner decision): an elided
     word with its apostrophe is one word, so `l'acqua` is two words (`l'` +
     `acqua`) and wins over `acqua`; a hyphenated word is one word. Two
     expressions with the same number of words covering the tapped word
     ("il pane" and "pane fresco" in "il pane fresco") go to the Lesson rule
     below; if they are still level, both are shown;
  2. the word alone equal to a whole target side;
  3. the word as one of the words of a target side ("gatto" in "un gatto"
     finds `il gatto = the cat`), except a word that appears in the target
     sides of **more than 3 entries** (il, la, the: a rule that needs no
     per-language stop-word list). Owner decision of 6 October 2026 (Build
     265 Revision 3): an expression the text does not contain is shown
     only when **every other word of it is an article** (the articles of
     the seven learner-panel languages, `WordLookupArticles`) or a word in
     more than 3 entries: "gatto" finds `il gatto`, "acqua" finds
     `l'acqua`, but "è" does not find `dov'è` and "caffè" does not find
     `il suo caffè`; a tapped article finds nothing this way.
- An apostrophe word without an entry of its own: tapping anywhere on
  "l'acqua" shows `l'acqua` when it is an entry; otherwise the card shows
  **together** the entries for `l'` and for `acqua`, those that exist.
  Since Build 265 Revision 4 each piece also uses rule 3 (`acqua` in
  `d'acqua` shows `l'acqua`), and a word ending with an apostrophe that no
  word follows is looked up as written (`po'`), then without it, as a
  closing quote mark (‘gatto’).
- Lessons: at the priority level reached, if the **current Lesson** (the
  Lesson of the Round, also in Review and Preview) has the entry, only its
  entries are shown (two different entries of that Lesson: both). Otherwise
  **all** entries of the other Lessons are shown in Course order, identical
  entries once. The number of words decides before the Lesson: an
  expression from another Lesson wins over a single word of the current
  Lesson.
- Nothing found: **nothing happens**, no message.

### Scripts written without spaces

Owner decision of 5 October 2026.

- Decided **by script, not by Course language**: the rules below apply to
  each run of Han (Chinese, Japanese kanji), Hiragana, Katakana, Thai, Lao,
  Khmer, Myanmar or Tibetan characters; Latin, Cyrillic, Greek and other
  spaced text in the same sentence keeps the word rules above.
- Inside such a run, an entry matches wherever its target text appears in
  the text; when the learner taps a character, every entry covering that
  character is a candidate. The Course's GuideBook is the dictionary: no
  segmentation dictionary or new dependency.
- Length is the **number of characters** (grapheme clusters, so a Thai
  letter with its vowel and tone marks is one character): the longest
  covering entry wins (in 我的猫 with entries 我, 我的, 猫, tapping 的 shows
  我的, tapping 猫 shows 猫). Ties: the Lesson rule, then both.
- No "word inside an expression" rule (rule 3) in these runs: there is no
  word to extract and a single character appears in too many entries.
- Everything else is unchanged: target side only, nothing when nothing is
  found, no lookup in Test Rounds or the Duel, the same card.
- Known limits: a short entry can match inside a longer word the GuideBook
  lacks; simplified and traditional Chinese, and full-width and half-width
  Japanese forms, are different text. Korean has spaces, so the word rules
  apply, but a particle attached to a noun (고양이가) hides the noun
  (고양이); Finnish, Turkish and Hungarian likewise: the same limit as
  inflected forms.

### Card

- The target side, under it the source side, then the Lesson as the
  learner's path names it ("Lesson N · title").
- A fixed line: **"One possible translation from this Course's
  GuideBook."** in the seven learner-panel languages
  (`lib/localization/learner_panel/`).
- No Play button for now.
- A small card next to the word (not a bottom sheet); it closes on a tap
  elsewhere, Escape or scrolling. The tapped word is highlighted while it is
  open.

### Where it works

- All Course text the learner sees, **before and after answering** (owner
  decision: these exercises teach more than they test; the card's line says
  the translation is one of the possible ones): question, sentence,
  passage, the authored Instruction or context, Dialogue lines once their
  text is visible (after the audio with `textReveal: afterAudio`), Page text
  blocks, the Before you start note, the Story cover title line, the
  correct-answer line.
- Not on answer options, word blocks, Match tiles (a tap answers there),
  Page links, the standard instruction lines and buttons (app text), or
  words with gaps (`___`, `dr_ink_`).
- **Never in Rounds of type Test and never in the Duel.**
- Timed Rounds: yes; the countdown keeps running while the card is open.
- Review: as in Rounds (a Test Round reviewed stays without lookup).
- Course Editor Preview: as the learner, with the GuideBooks of the content
  the preview shows.
- Not on the GuideBook screen or the Review vocabulary cards (they are the
  vocabulary).
- No effect on XP, Laurels, progress, activity or Review; a looked-up word
  is **not** added to Review vocabulary.

### Accessibility and discovery

- Each text block with lookup can take keyboard focus (Tab); Enter opens
  the card with every entry found in that text (each occurrence resolved as
  a tap, duplicates once). Screen readers get the action "Vocabulary in this
  text" (Narrator support to be checked on Windows). Nothing visible is
  added.
- On desktop the mouse cursor becomes a hand only over words that have a
  translation.
- Owner decision of 6 October 2026 (Build 265 Revision 3): a **light dotted
  underline** marks every target-language word that has an entry (drawn in
  the theme colour at 60% under the text, so the text itself is unchanged);
  the one-time notice says "Tap a word with a dotted underline to see a
  translation from this Course's GuideBook. Only some exercise types have
  them. It is a hint, one possible translation: it does not always match
  the answer to the exercise." The card names the Lesson only for an entry
  from another Lesson, and with several entries its line reads "Some
  possible translations from this Course's GuideBook." (same day).
- One-time notice "Tap a word to see a translation from this Course's
  GuideBook." the first time the learner opens a Round where lookup is
  available, **once per learner and per Course** (lookup may be off in some
  Courses), in the seven learner-panel languages, shown again after Show
  one-time notices again (`SettingsService.hasSeenLearnerOneTimeNotice` /
  `markLearnerOneTimeNoticeSeen`, key per learner × URI-encoded Course ID as
  for the primitive introductions).

### Word Lookup switch

- Course field `wordLookup`, on by default, stored only when off (like
  `allowPageSharing`), strictly boolean in `Course.fromJson`.
- In the Course Editor's Lesson Options (`course-lesson-options`), beside
  Use GuideBook and Create Duels; **hidden** while Use GuideBook is off.
- Fork, Copy as New Course and the transfer copy carry it; a Merge keeps
  the left Course's value (as for `allowPageSharing`).

## 3. Content

- **QQL Demo: English from Italian**: the 36 entries are turned to target =
  source (`hello, hi = ciao`) in `tools/generate_english_from_italian_260.py`.
  Its GuideBook and Review vocabulary show English first; that demo's Review
  vocabulary memory starts again (each entry's fingerprint changes; nothing
  else of the learner's data changes); the Round Wizard stops swapping its
  languages.
- **QQL Demo: Exercise Laboratory** is renamed **QQL Demo: Italian Exercise
  Lab** (title only: Course ID, file names and code names unchanged, so
  progress stays; as in Build 260 Revision 4: the generator
  `tools/generate_exercise_laboratory_254.py`, the bundled JSON, the v11
  fixture, the tests that name the title, Help EN/IT/ES, the credits line,
  `lib/services/preset_examples.dart` and `course_editor_screen.dart`).
- Each Laboratory Lesson's GuideBook gets **10–15 entries** (target =
  source) taken from the readable Italian text of its exercises, covering on
  purpose: a whole apostrophe expression (`l'acqua`), a word found only
  inside an expression, the same word in two Lessons with different
  translations, a common word excluded by the more-than-3 rule. Side
  effects: the Laboratory's Review shows vocabulary cards and the Round
  Wizard becomes usable on its Lessons (three pairs needed).

## 4. Revisions (one local commit each)

- **Revision 0**: `GuidebookVocabulary` (one parser for Review vocabulary,
  the Round Wizard and the lookup) and the target = source convention; the
  English from Italian entries turned; the lookup service (pure Dart, no
  Flutter: index per Course, normalization, expression and Lesson priority,
  apostrophe parts, the more-than-3 rule, scripts without spaces) with
  direct tests, including Chinese, Japanese and Thai sentences although no
  bundled Course uses them.
- **Revision 1**: the card on every surface listed above, the Test Round and
  Duel exclusion, the desktop cursor, the one-time notice, the Word Lookup
  switch, the learner-panel texts in seven languages, Help EN/IT/ES.
- **Revision 2**: keyboard and screen-reader access; the Laboratory rename
  and vocabulary.

Every revision bumps the version and the Beta expiry as usual. New
persisted keys (the notice) go to `AppResetService`, `InventoryService` and
`docs/239_RESET_STORAGE_INVENTORY.md` if the existing one-time-notice
handling does not already cover them.

## 5. Out of scope for now

Inflected forms, a Play button in the card, linking lookups to Review
vocabulary, disabling lookup per exercise (it would be a new canonical
option in the capability registry), structured vocabulary entries, online
dictionaries.
