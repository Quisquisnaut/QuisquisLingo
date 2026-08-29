# QuisquisLingo Course JSON format 4

Status: implemented current format. The in-app Editor Help remains the author-facing reference.

## Root

Every native Course Model v4 course declares:

```json
"formatVersion": 4
```

`courseId` is an immutable globally unique course identity. Course updates retain it so learner course progress follows the update. A fork or separate imported copy receives a new `courseId` and may include `parentCourseId` plus `derivedFromVersion` to preserve its lineage.

The canonical hierarchy is:

`Course > topics[] > guidebook + rounds[] + duel > content[]`

Course owns an ordered list of Topics. Every Topic owns its Guidebook, ordered Rounds and stable Duel identity. Chapter and assessment-Topic fields are not part of Course Model v4.

## Topic Guidebook

A Topic contains `guidebook.content[]`. Guidebook Content can include explanations, vocabulary, examples and text. It is learner-facing reference material and may also be used as authoring source material. `sourceRefs` can connect generated or derived Content to stable Guidebook Content IDs.

The first Content item of Round 1 may be a non-exercise `topic_intro` derived from essential Topic Guidebook information. Bundled sample courses use this convention and tell the learner to read the Topic Guidebook for more.

## Round

A Round contains a stable `id`, `title`, `visualType` and ordered `content[]`. `visualType` is one of `listening`, `story`, `generic` or `test` and is independent of exercise type.

## Content

Every Content object has a stable `id`, a `kind`, and `required`. `editorTemplate` is optional authoring metadata.

Initial kinds include `exercise`, `presentation`, `explanation`, `example`, `vocabulary`, `text`, `image`, `audio`, and `dialogue`.

## Exercise

Exercise Content uses:

`prompt[] + interaction + evaluation`

Initial interaction primitives are `select`, `input`, `arrange`, and `match`.

Initial evaluation primitives are `selected_items`, `text_match`, `ordered_items`, and `matched_items`.

Options, tokens and match members are stable Items. Evaluation refers to Item IDs, never display indexes. For `text_match`, v4 writes accepted text as `acceptedAnswers`; the parser also accepts `accepted` for that exercise field.

## Presentation

Flashcard is `kind: presentation`. Its completion actions include `understood` and `review_later`. It has no correct/incorrect result.

## Topic Duel

Every Topic serializes a Duel object with a stable `id` and `title`. Availability is not serialized. At runtime QuisquisLingo collects exercises from that Topic only, applies the established eligibility and deduplication rules, and requires 25 eligible exercises.

The standard Duel uses 25 unique questions and 4 lives. There is no score or pass threshold: the learner wins by completing all 25 questions before losing all four lives. If the actual eligible pool has fewer than 25 exercises, that Topic's Duel is normally unavailable; questions are not duplicated and gameplay rules are not changed. Six Rounds, often roughly 48 exercises, is author guidance only and never determines availability.

## Compatibility

Course Model v4 is the only native runtime, import and export format. Chapter-based formats and any other `formatVersion` are unsupported and rejected; QuisquisLingo does not read, migrate or convert them. Export writes `formatVersion: 4`.
