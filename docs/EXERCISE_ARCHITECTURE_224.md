# Exercise architecture and interoperability (2.0.24+224)

This is the engineering reference for the build-224 exercise inventory, canonical models, import-normalization boundary, deterministic text-answer engine, recursive authoring duplication, Creation Wizard, and GuideBook Round Generator. The Course Editor's in-app Exercise Help and `COURSE_EDITOR.md` are the author-facing references.

## Final active inventory

Build 223 had 17 active exercise discriminators. Build 224 retains all 17 and adds `type_translation`, `build_translation`, and `contextual_comprehension`, for 20 authoring presets. Existing IDs and JSON remain unchanged. Separately, ordered Round content supports `presentation`, `explanation`, `example`, `vocabulary`, `text`, `image`, `audio`, and `dialogue` blocks.

All exercise rows serialize as Course Model v5 `prompt[] + interaction + evaluation`, use the shared Round renderer, are available to the ordinary mistake-review flow where an evaluated answer applies, and round-trip through native v5 import/export. “Duel” below means the unchanged explicit Duel-eligible set. “Generator” means at least one registry-aware build-224 authoring generator can produce the preset when its required GuideBook/source media exists.

| Discriminator / author preset | Canonical model | Prompt and media | Response, distractors, correctness | Randomization and feedback | Duel | Generator | Bundled build-223 use |
|---|---|---|---|---|---|---|---:|
| `choice` / How do you say | Select | Text; optional audio/image | Text items; one correct item ID; remaining items distract | Choices shuffle; correct choice shown | Yes | Yes | 144 |
| `gap_choice` / Fill in the blank | Select | Text gap; optional audio | Text items; one correct item ID | Choices shuffle; correct completion shown | Yes | Yes | 144 |
| `icon_choice` / Select the image | Select | Text and image options | Image/items; one correct item ID | Choices shuffle; correct image shown | Yes | No | 56 |
| `listening_choice` / What do you hear | Select | Audio plus text options | Text items; one correct item ID | Choices shuffle; correct transcription shown | Yes | Yes | 144 |
| `listening_comprehension` / Listen and choose | Select | Audio passage and separate text question | Text items; one correct item ID | Choices shuffle; correct answer shown | No | Yes | 0 |
| `reading_comprehension` / Reading comprehension | Select | Text passage and question; optional image | Text items; one correct item ID | Choices shuffle; correct answer shown | Yes | Yes | 144 |
| `dialogue_response` / Dialogue response | Select | Text situation/question | Two response items; one correct item ID | Choices shuffle; best response shown | No | No | 144 |
| `contextual_comprehension` / Contextual comprehension | Select | Separate question; text, audio, or both; optional structured dialogue/image | Text answer items; one correct item ID | Choices shuffle; correct answer shown | No | Yes | New |
| `fill_blank` / Type a missing word | Input | Text gap; optional full-phrase audio | One or more accepted text expressions; no distractors | No shuffle; deterministic correction | No | Yes | 96 |
| `listening_spelling` / Type what you hear | Input | Audio | Accepted transcription expressions | No shuffle; deterministic correction | No | Yes | 64 |
| `missing_word` / Listen for missing words | Input | Audio and transcript | Ordered missing text entries | No shuffle; expected entries shown | No | No | 8 |
| `type_translation` / Type the translation | Input | Source text; optional hint | One or more accepted translation expressions | No shuffle; bounded typo acceptance and closest correction | No | Yes | New |
| `word_order` / Word order | Arrange | Text | Stable blocks plus at most two distractors; correct item-ID order | Blocks shuffle; expected order shown | No | Yes | 40 |
| `image_word` / Image-prompt ordering | Arrange | Image and text | Stable letter/syllable blocks; correct item-ID order | Blocks shuffle; expected construction shown | No | No | 48 |
| `build_translation` / Build the translation | Arrange | Source text | Stable target-language blocks plus at most two distractors; correct item-ID order | Blocks shuffle; expected translation shown | No | Yes | New |
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
- `[*:a|b]` in two or more equal-length groups for alternatives linked by index without Cartesian cross-combinations;
- `(part one <> part two)` to permute only the explicitly declared parts within that parenthesized scope;
- `part one <> part two` to apply the same rule to the whole expression when parentheses are absent.

Linked groups compose with optional, independent-alternative and valid reorder syntax. The parser never generates arbitrary word permutations. It validates balance, empty segments, incomplete separators, linked-group count/cardinality, parentheses without a reorder separator, and empty alternatives. Expansion order is deterministic, duplicates are removed while preserving first-author order, and the aggregate limit is 128 variants. Exceeding the limit is an error; variants are never silently truncated.

For `<>`, terminal punctuation (`.`, `?`, `!`, `…`, `?!` and equivalent combinations) is detached before moving declared phrase parts and reattached to the final sentence end. Internal punctuation such as commas stays with its authored structure. Structurally generated variants capitalize the first alphabetic character and the first alphabetic character after `.`, `?`, or `!`. When a common sentence starter moves inward, its original initial uppercase is removed; distinguishable names and acronyms such as Jane, Roma and USA retain lexical capitalization.

## Acceptance and correction selection

Acceptance and correction choice are separate algorithms. Structured evaluation returns `isCorrect`, the nearest `matchedAcceptedAnswer`, an exact/normalized/missing-diacritic/typo acceptance reason, and the actual accepted differences. Correct typed feedback always shows the canonical answer but names only differences genuinely used; an exact response never receives a false normalization reason.

The acceptance engine expands all authored answers, then preserves established normalization: case is ignored unless explicitly preserved, ordinary punctuation is ignored unless preserved, runs of whitespace collapse unless preserved, curly and straight apostrophes normalize to a meaningful apostrophe, and an omitted expected diacritic is tolerated when the learner entered no competing diacritic. Apostrophes are not erased. Type the translation additionally permits one accidentally omitted or duplicated repeated letter in exactly one token when both tokens are at least five characters, token count/order is unchanged, neither token contains a diacritic, and the set of common negation tokens is unchanged. It does not accept substitutions, missing/extra words, wrong lexical items, broad fuzzy matches, person/tense ending changes, or changed negation.

For a wrong answer, correction selection scores each expanded valid answer independently: exact shared words receive the strongest reward; non-exact tokens receive a graduated normalized Levenshtein-similarity reward above a conservative floor; incompatible learner extras and unused candidate words are penalized; and longest common token order is a secondary signal. This makes `Vorrete un cappuccino oggi?` select `Volete un cappuccino oggi?` rather than the author-first `Vuoi…` candidate. The highest-scoring valid answer is shown, exact ties retain author order, and the score can never change an incorrect response into a correct one.

## Authoring navigation, menus and recursive identity

Course Editor navigation is `Course → Lessons → Lesson → Rounds → Round / Exercises`. The main Course page contains only a compact Lessons link. The dedicated Lessons page owns the single existing Lock control and returns one updated Course draft to its parent; child mutations are not independently persisted. Course, Lesson and Round surfaces expose scoped Audit and Draft/Publish actions alongside the appropriate Edit, Rename, Delete, Duplicate and Preview actions. Exercise rows expose Edit, Duplicate and Draft/Publish alongside retained preview, transfer and delete actions. Only error-level Round Audit findings produce the pink management outline.

Edit preserves identity. Lesson Rename changes only its required title; Round Rename changes only its optional title and allows clearing it. Duplicate is inserted immediately after its source. `AuthoringDuplicationService` recursively allocates fresh Lesson, Duel, GuideBook Content, Round, Exercise, Content and Item IDs, remaps evaluation and internal `sourceRefs`, and retains shared immutable asset paths/external references. Clipboard Copy uses the same deep duplication at paste; Move deliberately preserves identity. Preview uses `RoundScreen(previewMode: true)` and therefore does not write progress, XP, streak, Laurel, Review, Duel or unlock state.

Course, Lesson, Round and Exercise authoring shares an explicit Draft/Published concept. Learner projection includes only Published objects with Published ancestors. Draft Course selection, Draft Lesson numbering/Sections/unlocks, Draft Round execution and Draft Exercise completion/Review/Duel/XP are all excluded. Publishing a parent does not rewrite descendants. Unpublishing preserves IDs and learner history. New, duplicated, Wizard-created and generated objects default to Draft. The exact shared unsaved-changes guard protects dirty Course, Lesson, Round and Exercise pages; generator drafts are guarded separately from explicit approval.

Course presentation metadata controls Lesson/Unit/Topic/Module/Skill/Chapter/Stage/Step/Part/custom/number-only/no-prefix display and monochrome versus deterministic colored-number fallback art. Numbering uses Published order and exactly de-duplicates untouched `Lesson N` titles in Lesson mode. An explicit preinstalled or Course-managed custom icon overrides the fallback. Custom imports are contain-normalized to a transparent 256 × 256 PNG, stored in the portable Course-owned registry, referenced without an external path, and rendered in the shared 84 × 84 slot.

## Exercise Creation Wizard

`ExerciseCreationPlanner` consumes the canonical preset registry and returns only a planned preset-ID sequence—no Exercises. Count is validated from 1 through 30. Balanced mix deterministically rotates across categories and within category registries without avoidable adjacent repeats. Random mix uses injected/seeded Dart randomness. By category, Selected exercise types and Repeat a pattern cycle the exact registry-derived pool or ordered pattern until the plan contains exactly N entries.

After plan confirmation, the Wizard opens the authoritative `ExerciseEditorScreen` for each preselected preset with a fresh Exercise ID. Save marks the validated draft and stays on the current step; Preview renders that same draft without advancing or duplicating it; Next saves and advances exactly one step; Finish saves the last step and returns the complete order. Cancelling after one or more explicit saves requires confirmation and returns only those saved valid Exercises. No future placeholder object is created.

## GuideBook Round Generator

The generator accepts only current-Lesson GuideBook material and requires at least three distinct target/source vocabulary pairs. Counts are configurable at 1–12 Rounds and 1–15 Exercises per Round, with defaults 6×8 = 48. A plan contains only counts, normalized positional difficulty, concise phase/vocabulary titles and registry preset IDs; it has no final Round or Exercise models. For one Round difficulty is `0.5`; otherwise it is `index / (roundCount - 1)`.

Early pools use recognition/comprehension and one distractor where applicable (`choice`, matched-example `gap_choice`, `listening_choice`, `word_match`). Middle pools use construction/context (`build_translation`, example-backed `word_order`, `audio_match`, matched-example contextual comprehension). Late pools emphasize production (`type_translation`, contextual comprehension, construction and example-backed word order) with less hint scaffolding. Unsupported image/audio assets are never fabricated. Generated Rounds remain editable/deletable/regenerable drafts and are audited. Approval deep-copies them to fresh final IDs and appends them after existing Rounds; cancellation or plan review changes nothing.

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

Course Model remains v5. New prompt `speaker` data is optional; old v5 JSON is unchanged, while new structured dialogue remains valid v5 prompt metadata. Existing authoring-template aliases are accepted at validation through their authoritative runtime type without rewriting stored data. Existing Course, Lesson, Round, Exercise, item, option, pair, and reference IDs are not regenerated; only genuinely new, duplicated or explicitly approved generated objects receive fresh identity. Review, Duel eligibility, XP, Laurel, streak, Round completion, and presentation scoring rules are unchanged.
