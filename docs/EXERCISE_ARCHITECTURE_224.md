# Exercise architecture and interoperability (2.0.24+224)

This is the engineering reference for the build-224 exercise inventory, canonical models, import-normalization boundary, and deterministic text-answer engine. The Course Editor's in-app Exercise Help and `COURSE_EDITOR.md` are the author-facing references.

## Final active inventory

Build 223 had 17 active exercise discriminators. Build 224 retains all 17 and adds `type_translation`, `build_translation`, and `contextual_comprehension`, for 20 authoring presets. Existing IDs and JSON remain unchanged. Separately, ordered Round content supports `presentation`, `explanation`, `example`, `vocabulary`, `text`, `image`, `audio`, and `dialogue` blocks.

All exercise rows serialize as Course Model v5 `prompt[] + interaction + evaluation`, use the shared Round renderer, are available to the ordinary mistake-review flow where an evaluated answer applies, and round-trip through native v5 import/export. “Duel” below means the unchanged explicit Duel-eligible set. “Generator” refers to existing Guidebook/source generation, not manual Editor support.

| Discriminator / author preset | Canonical model | Prompt and media | Response, distractors, correctness | Randomization and feedback | Duel | Generator | Bundled build-223 use |
|---|---|---|---|---|---|---|---:|
| `choice` / How do you say | Select | Text; optional audio/image | Text items; one correct item ID; remaining items distract | Choices shuffle; correct choice shown | Yes | Yes | 144 |
| `gap_choice` / Fill in the blank | Select | Text gap; optional audio | Text items; one correct item ID | Choices shuffle; correct completion shown | Yes | Yes | 144 |
| `icon_choice` / Select the image | Select | Text and image options | Image/items; one correct item ID | Choices shuffle; correct image shown | Yes | No | 56 |
| `listening_choice` / What do you hear | Select | Audio plus text options | Text items; one correct item ID | Choices shuffle; correct transcription shown | Yes | Yes | 144 |
| `listening_comprehension` / Listen and choose | Select | Audio passage and separate text question | Text items; one correct item ID | Choices shuffle; correct answer shown | No | Yes | 0 |
| `reading_comprehension` / Reading comprehension | Select | Text passage and question; optional image | Text items; one correct item ID | Choices shuffle; correct answer shown | Yes | Yes | 144 |
| `dialogue_response` / Dialogue response | Select | Text situation/question | Two response items; one correct item ID | Choices shuffle; best response shown | No | No | 144 |
| `contextual_comprehension` / Contextual comprehension | Select | Separate question; text, audio, or both; optional structured dialogue/image | Text answer items; one correct item ID | Choices shuffle; correct answer shown | No | No | New |
| `fill_blank` / Type a missing word | Input | Text gap; optional full-phrase audio | One or more accepted text expressions; no distractors | No shuffle; deterministic correction | No | Yes | 96 |
| `listening_spelling` / Type what you hear | Input | Audio | Accepted transcription expressions | No shuffle; deterministic correction | No | Yes | 64 |
| `missing_word` / Listen for missing words | Input | Audio and transcript | Ordered missing text entries | No shuffle; expected entries shown | No | No | 8 |
| `type_translation` / Type the translation | Input | Source text; optional hint | One or more accepted translation expressions | No shuffle; bounded typo acceptance and closest correction | No | No | New |
| `word_order` / Word order | Arrange | Text | Stable blocks plus at most two distractors; correct item-ID order | Blocks shuffle; expected order shown | No | Yes | 40 |
| `image_word` / Image-prompt ordering | Arrange | Image and text | Stable letter/syllable blocks; correct item-ID order | Blocks shuffle; expected construction shown | No | No | 48 |
| `build_translation` / Build the translation | Arrange | Source text | Stable target-language blocks plus at most two distractors; correct item-ID order | Blocks shuffle; expected translation shown | No | No | New |
| `matching` / Match the pairs | Match | Text | Stable left/right item IDs and pair relations | Both columns shuffle independently; pair result shown | No | No | 0 |
| `word_match` / Match the words | Match | Text | Three unique stable text pairs | Both columns shuffle independently; pair result shown | No | Yes | 72 |
| `super_match` / Match related words | Match | Text | Three unique stable related-word pairs | Both columns shuffle independently; pair result shown | No | No | 0 |
| `audio_match` / Listen and match | Match | Audio and text | Three unique stable audio/text pairs | Both sides shuffle independently; pair result shown | No | Yes | 48 |
| `flashcard` / Flashcard | Presentation | Text; optional audio/image/usage | `understood` / `review_later`; no evaluated correct answer or distractor | No answer shuffle; non-scored presentation feedback | No | Yes | 0 |

The separate non-exercise explanation content appears 72 times in bundled build-223 courses. Editor-only presets remain valid even when absent from bundled samples.

## Canonical models and authoring categories

The internal models are:

- **Select** — stable options plus selected-item evaluation.
- **Input** — free text plus accepted-text evaluation.
- **Arrange** — stable blocks plus ordered-item evaluation.
- **Match** — stable items plus pair evaluation.
- **Presentation** — ordered learning material without an ordinary scored response.

Prompt/context capabilities are orthogonal elements with roles, media type (`text`, `audio`, `image`), content, asset reference, and optional dialogue speaker. Item IDs are stable and evaluation refers to IDs, never display indices. A future Speech interaction can be added as another interaction/evaluation kind without restructuring Select, Input, Arrange, Match, or Presentation; speech recognition is deliberately not implemented in 224.

The Course Editor exposes concrete presets in six groups:

| Category | Presets and canonical mapping |
|---|---|
| Multiple choice | How do you say → Select; Fill in the blank → Select; Select the image → Select; What do you hear → Select; Listen and choose → Select; Reading comprehension → Select; Dialogue response → Select; Contextual comprehension → Select |
| Translation | Type the translation → Input; Build the translation → Arrange |
| Text input | Type a missing word → Input; Type what you hear → Input; Listen for missing words → Input |
| Matching | Match the pairs → Match; Match the words → Match; Match related words → Match; Listen and match → Match |
| Ordering | Word order → Arrange; Image-prompt ordering → Arrange |
| Presentation | Flashcard → Presentation |

The searchable picker, validator, and Exercise Help all read the same registry. Canonical model names are engineering concepts, not primary author-facing exercise names.

## Context and ordered content

`contextual_comprehension` keeps the question separate from context. Context mode is derived from context prompt elements and supports `text`, `audio`, and `textAndAudio`. A dialogue is an ordered list of text prompt elements with role `dialogue_turn` and a separate `speaker` value; answers remain ordinary stable Select items.

A Story-like experience is represented by the existing ordered `Round.content` sequence. Presentation/narration/dialogue blocks and independently evaluated Select, Input, Arrange, or Match blocks can be interleaved without a monolithic Story evaluator. Full Story authoring and production import are deferred; the model can already preserve the ordered structure.

## Accepted-answer expressions

Input presets may provide multiple complete accepted answers as separate lines. Each line can optionally use:

- `{text}` for an optional segment;
- `[a|b|c]` for two or more alternatives;
- `(part one <> part two)` to permute only the explicitly declared parts within that parenthesized scope;
- `part one <> part two` to apply the same rule to the whole expression when parentheses are absent.

The parser never generates arbitrary word permutations. It validates balance, empty segments, incomplete separators, parentheses without a reorder separator, and empty alternatives. Expansion order is deterministic, duplicates are removed while preserving first-author order, and the aggregate limit is 128 variants. Exceeding the limit is an error; variants are never silently truncated.

## Acceptance and correction selection

Acceptance and correction choice are separate algorithms.

The acceptance engine expands all authored answers, then preserves established normalization: case is ignored unless explicitly preserved, ordinary punctuation is ignored unless preserved, runs of whitespace collapse unless preserved, curly and straight apostrophes normalize to a meaningful apostrophe, and an omitted expected diacritic is tolerated when the learner entered no competing diacritic. Apostrophes are not erased. Type the translation additionally permits one accidentally omitted or duplicated repeated letter in exactly one token when both tokens are at least five characters, token count/order is unchanged, neither token contains a diacritic, and the set of common negation tokens is unchanged. It does not accept substitutions, missing/extra words, wrong lexical items, broad fuzzy matches, person/tense ending changes, or changed negation.

For a wrong answer, correction selection scores each expanded valid answer independently: exact shared words receive the strongest reward, one-edit near words receive a smaller reward, incompatible learner extras and unused candidate words are penalized, and longest common word order is a secondary signal. The highest-scoring valid answer is shown. Exact ties retain author order. This score can never change an incorrect response into a correct one.

Optional decisive-word metadata was audited and deferred: a new author syntax would be brittle without broader language-specific semantics. The bounded acceptance guard explicitly protects common negations in 224.

## Import normalization boundary

Engineering imports use this boundary:

`source format → NormalizedImportExercise → canonical Course Model v5 Exercise`

The normalized object carries a source type only for diagnostics plus a QQL preset, prompt/context/media elements, interaction, evaluation, and hint. Conversion receives the destination stable exercise ID explicitly. Source taxonomy never reaches learner runtime dispatch, and the intermediate object is not a second Course Model. No production external importer is included in 224.

## Engineering interoperability matrix

`DIRECT` means the known semantics map without loss. `CONFIGURATION` means source fields must be assigned to a QQL preset/capability. `LOSSY` means only the currently modeled subset is preserved. `UNSUPPORTED` means required semantics are not known or the response capability is deliberately absent.

| External pattern | Status | Current/final QQL mapping | New canonical model? | New 224 preset? |
|---|---|---|---|---|
| PickOne | CONFIGURATION | Select / How do you say | No | No |
| ImagePick | CONFIGURATION | Select / Select the image | No | No |
| FlashCard | DIRECT | Presentation / Flashcard | No | No |
| PickOneAudio | UNSUPPORTED | Source semantics not sufficiently known | No decision | No |
| SpellingPick | CONFIGURATION | Select / What do you hear | No | No |
| Match | DIRECT | Match / Match the pairs | No | No |
| AudioMatch | DIRECT | Match / Listen and match | No | No |
| WriteWords | CONFIGURATION | Input / Type the translation | No | Yes |
| PickWords | CONFIGURATION | Arrange / Build the translation | No | Yes |
| PickOneMeaning | CONFIGURATION | Select / Contextual comprehension | No | Yes |
| PickMissingWord | DIRECT | Select / Fill in the blank | No | No |
| Rich Text | CONFIGURATION | Ordered presentation content | No | No new Exercise preset |
| Multiple Choice | DIRECT | Select / How do you say | No | No |
| Fill Blank | CONFIGURATION | Select or Input according to source response | No | No |
| Word Order | DIRECT | Arrange / Word order | No | No |
| Listen & Tap | DIRECT | Select / What do you hear | No | No |
| Match Pairs | DIRECT | Match / Match the pairs | No | No |
| Select Image | CONFIGURATION | Select / Select the image | No | No |
| Translate/type an answer | DIRECT | Input / Type the translation | No | Yes |
| Translate using word tiles | DIRECT | Arrange / Build the translation | No | Yes |
| Tap what you hear | DIRECT | Select / What do you hear | No | No |
| Type what you hear | DIRECT | Input / Type what you hear | No | No |
| Listen for a missing word | DIRECT | Input / Listen for missing words | No | No |
| Type a missing word | DIRECT | Input / Type a missing word | No | No |
| Multiple choice | DIRECT | Select / How do you say | No | No |
| Choose a grammatical form | DIRECT | Select / Fill in the blank | No | No |
| Select image | CONFIGURATION | Select / Select the image | No | No |
| Listen and choose | DIRECT | Select / Listen and choose | No | No |
| Matching pairs | DIRECT | Match / Match the pairs | No | No |
| Audio matching | DIRECT | Match / Listen and match | No | No |
| Comprehension checks | CONFIGURATION | Select / Contextual comprehension | No | Yes |
| Dialogue response | CONFIGURATION | Select / Contextual comprehension or Dialogue response | No | Yes for structured context |
| Speaking/repeat | UNSUPPORTED | Future Speech response | Future capability | No |
| Spoken response | UNSUPPORTED | Future Speech response | Future capability | No |
| Flashcard/vocabulary presentation | DIRECT | Presentation / Flashcard | No | No |
| Story-based comprehension | LOSSY | Ordered content sequence plus canonical assessed blocks | No | Full authoring deferred |

## Compatibility decisions

Course Model remains v5. New prompt `speaker` data is optional; old v5 JSON is unchanged, while new structured dialogue remains valid v5 prompt metadata. Existing authoring-template aliases are accepted at validation through their authoritative runtime type without rewriting stored data. Course, Lesson, Round, Exercise, item, option, pair, and reference IDs are not regenerated. Review, Duel eligibility, XP, Laurel, streak, Round completion, and presentation scoring rules are unchanged.
