# Build 256 — preset catalogue (Revision 4 plan)

Owner decisions taken on 27 September 2026 during Session 4, and the
proposed catalogue that follows from them. Revision 3 (presets as recipes and
the Generic Primitive Editor) stays as planned; this catalogue is its own
revision right after it. The later sessions shift by one (see the handoff).

**Delivered in Revision 4 (2.0.56+256004, 27 September 2026)** with these
differences from section 3: Listen and answer is paired too (to target / to
source), so the active count is 38, not 35; Choose the answer (to target)
means *answers* in the target language (the question may be in either),
Choose the answer (to source) means question and answers in the source
language; Match the words keeps its source = target pairs for new
exercises and also keeps the former Matching shape (left target, right
source) of an existing exercise; Type the missing word absorbs Fill in the
blank through its first-letter switch (off = one field under the sentence);
the save guard on example content is not implemented (no form prefills
examples). Evidence in `docs/256_VALIDATION.md`.

## 1. Decisions (owner, 27 September 2026)

- Merge the overlapping presets so each one has one clear job. Do not keep
  legacy behavior for its own sake. Rename and clarify the confusing ones.
  Add new presets and greyed-out future ones. The count may exceed 28, but no
  two presets may overlap or confuse.
- A switch inside a preset exists only where it makes sense on its own, never
  to preserve an old difference.
- **Pick the translation (to target)** and **Pick the translation (to source)**
  stay exactly as they are.
- **Choose** becomes a generic **Choose the answer**: any question, any
  answers, optional picture. Help and tooltips say that it can ask about
  grammar, culture or meaning, not only translations.
- Some presets exist twice, *to target* and *to source*, so that creators have
  a straightforward tool and QQL knows which language to read aloud
  (optionally with a button, as in Pick the translation): Type the
  translation, Build the translation, Choose the answer, Read and answer.
- The **Choose an exercise preset** screen groups presets by skill and writes
  the action (Choose, Type, Arrange, Match, Card) on every tile, and can
  filter to *to target*, *to source* or both.
- **Inline gaps** are presets of their own (one for choosing words into gaps,
  one for dragging blocks into gaps), never a switch inside other presets.
- New presets now: Missing letters, Complete the text, True or false, Put the
  sentences in order, Note card, What is in the picture (choose), Name what
  you see (type; several accepted answers; the same engine as freely typed
  translations), Listen and pick the image, Picture flashcard (optional read
  aloud; that never makes it an audio exercise), Spell what you hear; letter
  order and syllable order exercises; image-to-text and image-to-sound pairs.
- Greyed out, "in a later version": Speaking, Handwriting, Sorting and
  labelling, Free writing, Match picture to sound (until its runtime exists),
  Adventures (branching stories).
- Every new exercise starts with its preset's example content. **Save is
  refused while any required field still equals its example**; optional
  fields (hint, feedback) may stay empty.
- Renames approved: Image-prompt ordering → Spell the word in the picture,
  Fill in the blank (choose) → Pick the missing word, Match related words →
  Match by meaning, Listen for missing words → Listen and fill the gaps.
- Directions (owner, 27 September 2026, afternoon): a preset that has a
  meaningful other direction exists in **both** directions, always as a
  pair, and the pair's titles carry the bracket **(to target)** /
  **(to source)**: Pick, Type and Build the translation, Choose the answer,
  True or false, Read and answer, Listen and answer. Presets whose "to
  source" twin would only exercise the learner's own language (spelling,
  characters, gaps, word and sentence order, synonyms, listening gaps) stay
  target-only, show "To target" on the tile and in the filter, and carry
  no bracket in the title. Presets with no language side (Match the words,
  picture answers, cards and notes) carry neither.

## 2. Rules the catalogue follows

- A preset is a recipe over one primitive (Build 256 plan A.3, A.13): it never
  changes what learners see. Retiring or renaming a preset changes only
  `authoringMetadata.presetId`; the exercise's canonical content is untouched.
- **Retired IDs** are not read back as presets. An exercise that carries a
  retired ID opens in the first current preset whose recipe represents it
  exactly (`PresetRecipes.recognize`), else in the plainest preset of its
  primitive (`defaultPresetFor`). Nothing is rewritten until the creator saves.
- **Direction** is a preset attribute (`toTarget`, `toSource`, `both`, `none`)
  used only by the picker filter and the tile chip.
- **Read-aloud** follows the element `language` attribute the recipe writes;
  a preset with a `to source` twin sets `language: source` on the text it
  shows and `language: target` on the answer side. `required: false` audio is
  optional (a button), as in Pick the translation.
- **Example content** per preset lives in the recipe (`exampleDraft`): short
  English placeholders labelled with the Course's language names, as the New
  Course scaffold already does. `requiredFields` names the fields that must
  change; Save lists the ones still equal to the example.
- **Switches that stay** because they make sense on their own: one or several
  correct answers (Choose the answer, Read and answer, Listen and answer);
  show the first letter (Type the missing word); letters or syllables
  (the three Spell presets); text or dialogue lines (Read and answer).
  Every other former switch is gone or became a preset.
- The Laboratory (Session 7) shows every active preset at least once and the
  presentation baseline is re-recorded for the renamed and merged ones.

## 3. Proposed catalogue

Status: **kept** (unchanged), **renamed**, **merged**, **new**, **new + runtime**
(needs a small runtime change in the same revision), **greyed** (listed,
disabled, "in a later version"). Direction: T = to target, S = to source,
B = both, – = none. Action = the word written on the tile.

### Vocabulary

| Preset | ID | Action | Dir | Status | Notes |
|---|---|---|---|---|---|
| Pick the translation (to target) | `translation_choice_to_target` | Choose | T | kept | Unchanged. |
| Pick the translation (to source) | `translation_choice_to_source` | Choose | S | kept | Unchanged. |
| Type the translation (to target) | `type_translation_to_target` | Type | T | renamed | Was `type_translation`. Accepted answers, ranked feedback, typo tolerance. |
| Type the translation (to source) | `type_translation_to_source` | Type | S | new | Same engine, languages swapped. |
| Build the translation (to target) | `build_translation_to_target` | Arrange | T | renamed | Was `build_translation`. |
| Build the translation (to source) | `build_translation_to_source` | Arrange | S | new | Blocks in the source language. |
| Match the words | `word_match` | Match | B | merged | Absorbs `matching`. Left target, right source. |
| Match by meaning | `super_match` | Match | T | renamed | Synonyms, opposites, word and definition, all in the target language. |
| Flashcard | `flashcard` | Card | – | kept | |
| Picture flashcard | `picture_flashcard` | Card | – | new | Picture, word, meaning, optional usage example with its translation (as Flashcard keeps them), optional read-aloud of the word and of the usage example (`required: false`, never an audio exercise). Owner note of 27 September 2026. |

### Grammar and sentences

| Preset | ID | Action | Dir | Status | Notes |
|---|---|---|---|---|---|
| Choose the answer (target text) | `choice_target` | Choose | T | merged | Replaces `choice`. Any question, optional picture; one or several correct answers. |
| Choose the answer (source text) | `choice_source` | Choose | S | new | Same, question in the source language. |
| True or false | `true_false` | Choose | T | new | Statement (optional read aloud), two fixed answers prefilled in the source language. |
| Pick the missing word | `gap_choice` | Choose | T | renamed | Was Fill in the blank: one blank, answers listed. |
| Pick the words for the gaps | `gap_choice_inline` | Choose | T | new | Several inline gaps, one choice per gap, item reuse option. Was the Choose switch. |
| Type the missing word | `type_missing_word` | Type | T | merged | Absorbs `fill_blank`. One gap; optional "show the first letter". |
| Complete the text | `complete_text` | Type | T | new | Several typed gaps, no audio. |
| Missing letters | `missing_letters` | Type | T | new + runtime | Gaps inside words (`dr__`), one underscore per letter; optional context text, audio or picture. Runtime: within-word gap field. |
| Word order | `word_order` | Arrange | T | kept | Blocks of one sentence, 0–2 distractors. |
| Drag the blocks into the gaps | `gap_blocks` | Arrange | T | new | Was the Word order / Build the translation switch. |
| Put the sentences in order | `sentence_order` | Arrange | T | new | Story or dialogue lines. |
| Sort into groups | `sort_into_groups` | Sort | – | Revision 7 follow-up | Assign categories, capacity unlimited: groups as "Name: word, word", optional words that belong nowhere. |
| Fill the slots | `fill_the_slots` | Sort | – | Revision 7 follow-up | Assign slots: "what the learner sees = word", optional extra words, a switch for a word filling several slots. |

### Listening

| Preset | ID | Action | Dir | Status | Notes |
|---|---|---|---|---|---|
| Listen and answer | `listening_answer` | Choose | T | merged | Absorbs `listening_choice` and `listening_comprehension`: a word, a sentence or a passage; optional question; one or several correct answers. |
| Listen and pick the image | `listening_image_choice` | Choose | T | new | Audio prompt, picture answers. |
| Type what you hear | `listening_spelling` | Type | T | kept | |
| Listen and fill the gaps | `missing_word` | Type | T | renamed | Was Listen for missing words. |
| Spell what you hear | `spell_heard` | Arrange | T | new + runtime | Audio prompt, letter or syllable tiles. Runtime: tiles without a picture. |
| Listen and match | `audio_match` | Match | T | kept | |

### Reading and dialogue

| Preset | ID | Action | Dir | Status | Notes |
|---|---|---|---|---|---|
| Read and answer (target question) | `reading_answer_target` | Choose | T | merged | Absorbs `reading_comprehension`, `contextual_comprehension`, `dialogue_response`: passage or dialogue lines in the target language, question and answers in the target language. |
| Read and answer (source question) | `reading_answer_source` | Choose | S | new | Same passage, question and answers in the source language. |

### Pictures and characters

| Preset | ID | Action | Dir | Status | Notes |
|---|---|---|---|---|---|
| Select the image | `icon_choice` | Choose | T | kept | Word or sentence prompt, picture answers. Owner (27 September 2026, evening): today's form takes only icon keys or bundled asset paths; Revision 4 gives it one picture picker per answer (Image Library or Course images) and draws those pictures on the Round and Duel screens, the same machinery as What is in the picture, Listen and pick the image and Match picture to word. |
| What is in the picture | `picture_choice` | Choose | T | new | Picture prompt, text answers. |
| Name what you see | `picture_name` | Type | T | new | Picture prompt, typed answer; accepted answers list, same engine as Type the translation. |
| Spell the word in the picture | `image_word` | Arrange | T | renamed | Was Image-prompt ordering; letter or syllable tiles. |
| Spell the word | `spell_word` | Arrange | T | new | Clue in the source language (word or definition), letter or syllable tiles. |
| Match picture to word | `picture_word_match` | Match | T | new + runtime | Picture on the left, words on the right. Runtime: picture left items. |
| Recognize characters | `script_recognition` | Choose | T | kept | Image to text and text to image, as today. |

### Cards and notes

| Preset | ID | Action | Dir | Status | Notes |
|---|---|---|---|---|---|
| Note card | `note_card` | Card | – | new | A tip, a grammar or cultural note; no answer. |

(Flashcard and Picture flashcard are listed under Vocabulary.)

### Coming later (greyed out)

| Preset | Primitive | Why later |
|---|---|---|
| Say it / Read aloud | speak | Needs speech recognition. |
| Write the character / Write the word by hand | ink | Needs the Ink runtime. |
| Sort into groups | assign | Needs the Assign runtime (Session 7 plans Assign). Moved to the catalogue by the Revision 7 follow-up (29 September 2026), with Fill the slots; no gap preset (the inline gap presets cover gaps). |
| Label the picture | assign (regions) | Needs the Assign runtime with regions. |
| Answer in your own words / Describe the picture | submit | Needs the Submit runtime (self-check). |
| Match picture to sound | match | Needs a tap-to-pair Match layout (the dropdown Match cannot hold audio). |
| Adventure (branching story) | Round flow | Branching flows are not playable yet (plan A.7); the tile points to the Round editor's Story options. |

Retired IDs after this revision: `choice`, `fill_blank`, `matching`,
`listening_choice`, `listening_comprehension`, `reading_comprehension`,
`contextual_comprehension`, `dialogue_response`, `type_translation`,
`build_translation`. Active presets: 35. Greyed: 7.

## 4. Runtime and editor work this revision needs

- Within-word Input gap (Missing letters): a gap field with no surrounding
  spaces, sized by the letter count, underscores in the prompt view.
- Arrange word tiles without a picture (Spell what you hear, Spell the word):
  the `arrangeWord` kind no longer requires an image; the Audit's
  `IMAGE_WORD_IMAGE_REQUIRED` applies only when the recipe is Spell the word
  in the picture (it becomes "a picture, an audio or a clue is required").
- Syllable tiles: the recipe splits the word at `|`; the runtime already joins
  tiles without spaces.
- Match with picture left items (Match picture to word).
- Picture answers everywhere a preset lists pictures: one picker per answer
  in the form (Image Library or Course images, `media:` assets copied into
  the Course), image elements on the items, and the Round screen drawing
  them through `CourseMediaImage` as the Duel already does (owner decision
  of 27 September 2026: Revision 4, not a follow-up).
- Picker: skill groups, action chip, direction filter, greyed tiles.
- Save guard: `requiredFields` per recipe; refusal message lists the fields.
- Help (EN/IT/ES): the catalogue chapter, Choose the answer's tooltip, the
  greyed presets, the direction filter.
- Laboratory (Session 7): every active preset; baseline re-recorded.

## 5. Open points (proposals, not blocking)

- Match the words: left target and right source is proposed as the one
  layout. Say if the other side should be available.
- True or false: the two answers are prefilled in the Course's source language
  when QQL knows it (the eight copy languages), else in English; creators can
  edit them.
- Picture flashcard and Note card use completion mode `proceed`, like
  Flashcard.
