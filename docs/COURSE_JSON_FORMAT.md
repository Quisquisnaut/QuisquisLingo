# QuisquisLingo Course JSON format 5

Status: implemented current format. The in-app Editor Help remains the author-facing reference.

## Root

Every native Course Model v5 course declares:

```json
"formatVersion": 5
```

`courseId` is an immutable globally unique course identity. Course updates retain it so learner course progress follows the update. A fork or separate imported copy receives a new `courseId` and may include `parentCourseId` plus `derivedFromVersion` to preserve its lineage.

The canonical hierarchy is:

`Course > lessons[] > guidebook + rounds[] + duel > content[]`

Course owns an ordered list of Lessons. Every Lesson owns its Guidebook, ordered Rounds and stable Duel identity. Chapter and assessment-Lesson fields are not part of Course Model v5.

Every Lesson requires `lessonId` and `title`. Optional presentational metadata uses this shape:

```json
{
  "lessonId": "stable_opaque_id",
  "title": "At the railway station",
  "section": true,
  "sectionName": "Travel",
  "themeIconAsset": "assets/lesson_icons/train.png"
}
```

`section` defaults to false. When false, `sectionName` is omitted; when true, `sectionName` must be a non-empty trimmed string. Consecutive Lessons with the same name form one visual Section block. Section has no ID, persistence, progress, unlock, XP, Duel or navigation state, and relative Section Lesson numbering is derived from Lesson order.

`themeIconAsset` is optional and, when present, must name an approved 256 × 256 transparent PNG from the canonical Lesson icon registry under `assets/lesson_icons/`. Each registry entry has a stable internal ID, author-facing label and asset path. Course JSON stores only the asset path, never image bytes, Base64, dimensions, scale or padding. Build-time asset validation verifies the exact registry/disk set, path, PNG structure and decoding, dimensions, transparency and four-color maximum.

The former decorative Lesson `imageAsset` field is not part of Course Model v5 and is rejected. It is not an alias for `themeIconAsset` and is not migrated into one. Exercise Content may still use its own image field where that exercise type requires it.

The structural fields `topics`, `topicId` and Lesson `id` are invalid in v5. Opaque stable identifier values from earlier bundled content may retain historical text because changing their values would break references and course-owned progress.

## Lesson Guidebook

A Lesson contains `guidebook.content[]`. Guidebook Content can include explanations, vocabulary, examples and text. It is learner-facing reference material and may also be used as authoring source material. `sourceRefs` can connect generated or derived Content to stable Guidebook Content IDs.

The first Content item of Round 1 may be a non-exercise `lesson_intro` derived from essential Lesson Guidebook information. Bundled sample courses use this convention and tell the learner to read the Lesson Guidebook for more.

## Round

A Round contains a stable `id`, optional learner-facing `title`, `visualType` and ordered `content[]`. An empty or omitted title is valid and the learner/editor UI falls back to its derived `Round N` label without changing identity. `visualType` is one of `listening`, `story`, `generic` or `test` and is independent of exercise type.

## Content

Every Content object has a stable `id`, a `kind`, and `required`. `editorTemplate` is optional authoring metadata.

Initial kinds include `exercise`, `presentation`, `explanation`, `example`, `vocabulary`, `text`, `image`, `audio`, and `dialogue`.

## Exercise

Exercise Content uses:

`prompt[] + interaction + evaluation`

Initial interaction primitives are `select`, `input`, `arrange`, and `match`.

Initial evaluation primitives are `selected_items`, `text_match`, `ordered_items`, and `matched_items`.

Options, tokens and match members are stable Items. Evaluation refers to Item IDs, never display indexes. For `text_match`, v5 writes accepted text as `acceptedAnswers`; the parser also accepts `accepted` for that exercise field.

Build 224 groups these primitives as the canonical Select, Input, Arrange and Match models, with Presentation for non-response learning material. Concrete `editorTemplate` presets remain authoring metadata and several presets intentionally share one model. Prompt elements can independently carry text, audio or image media plus a semantic `role`; structured dialogue may add an optional `speaker` string to a text element whose role is `dialogue_turn`. Contextual comprehension stores its question and context as separate prompt roles.

Accepted text entries may be separate complete equivalents or use optional `{...}`, alternative `[a|b|c]`, and explicitly scoped reorder `(a <> b)` expressions. Without parentheses, `<>` applies to the whole expression. Reordering detaches terminal `.`, `?`, `!`, `…` and equivalent combinations and reattaches them only at the final sentence end; internal punctuation stays in place. Structurally generated variants capitalize sentence starts and starts after `.`, `?` or `!`, avoid preserving capitalization that existed only because a common phrase began the authored form, and preserve distinguishable lexical capitals such as proper names and acronyms. Expansion is deterministic, de-duplicated and limited to 128 results. Malformed or oversized expressions are invalid course data.

Answer acceptance and wrong-answer correction selection are separate. Acceptance uses the established normalization and narrowly bounded Type-translation typo rule. Correction selection ranks valid expanded answers through exact shared tokens, graded token spelling similarity, incompatible learner extras, absent candidate tokens and common token order; exact ties retain author order and cannot change correctness.

## Authoring identity and generated drafts

Editing preserves every existing Course, Lesson, Round, Exercise, Content and Item ID. Duplicating an Exercise, Round or Lesson recursively allocates fresh IDs for that owned subtree and remaps references whose targets are inside it; immutable asset paths and external references remain shared. Generated GuideBook material likewise receives final stable IDs only when the author explicitly approves it.

The Exercise Creation Wizard and GuideBook Round Generator are editor workflows, not serialized Course Model concepts. Wizard plans contain only preset IDs from the canonical registry until the author edits and saves real Exercises. GuideBook plans contain counts, normalized difficulty, draft titles and registry preset IDs; generated Rounds remain outside the Lesson until approval appends them after existing Rounds. Neither workflow adds new JSON fields or changes `formatVersion: 5`.

Source-format conversion is isolated behind an import-normalization representation before producing these native structures. No source taxonomy is a runtime exercise discriminator, and build 224 does not include a production converter for third-party course formats.

## Presentation

Flashcard is `kind: presentation`. Its completion actions include `understood` and `review_later`. It has no correct/incorrect result.

Round `content[]` is also the structured content container for future Story-like sequences: narration, dialogue or other presentation blocks can be interleaved with independently evaluated exercises. There is no separate monolithic Story evaluator.

## Lesson Duel

Every Lesson serializes a Duel object with a stable `id` and `title`. Availability is not serialized. At runtime QuisquisLingo collects exercises from that Lesson only, applies the established eligibility and deduplication rules, and requires 25 eligible exercises.

The standard Duel uses 25 unique questions and 4 lives. There is no score or pass threshold: the learner wins by completing all 25 questions before losing all four lives. If the actual eligible pool has fewer than 25 exercises, that Lesson's Duel is normally unavailable; questions are not duplicated and gameplay rules are not changed. Six Rounds, often roughly 48 exercises, is author guidance only and never determines availability.

## Compatibility

Course Model v5 is the only native runtime, import and export format. Chapter-based formats and any other `formatVersion` are unsupported and rejected; QuisquisLingo does not read, migrate or convert them. Export writes `formatVersion: 5`.
