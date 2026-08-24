# QuisquisLingo Course JSON format 3

Status: implemented baseline. The in-app Editor Help remains the author-facing reference.

## Root

Every native Course Model v3 course declares:

```json
"formatVersion": 3
```

`courseId` is an immutable globally unique course identity. Course updates retain it so learner course progress follows the update. A fork or separate imported copy receives a new `courseId` and may include `parentCourseId` plus `derivedFromVersion` to preserve its lineage.

The canonical hierarchy is:

`Course > chapters[] > topics[] > guidebook + rounds[] > content[]`

Chapters do not contain Guidebooks. Every learning Topic owns its Guidebook.

## Topic Guidebook

A learning Topic contains `guidebook.content[]`. Guidebook Content can include explanations, vocabulary, examples and text. It is learner-facing reference material and may also be used as authoring source material. `sourceRefs` can connect generated or derived Content to stable Guidebook Content IDs. Assessment Topics do not require a Guidebook.

The first Content item of Round 1 may be a non-exercise `topic_intro` derived from essential Topic Guidebook information. Bundled sample courses use this convention and tell the learner to read the Topic Guidebook for more.

## Content

Every Content object has a stable `id`, a `kind`, and `required`. `editorTemplate` is optional authoring metadata.

Initial kinds include `exercise`, `presentation`, `explanation`, `example`, `vocabulary`, `text`, `image`, `audio`, and `dialogue`.

## Exercise

Exercise Content uses:

`prompt[] + interaction + evaluation`

Initial interaction primitives are `select`, `input`, `arrange`, and `match`.

Initial evaluation primitives are `selected_items`, `text_match`, `ordered_items`, and `matched_items`.

Options/tokens/match members are stable Items. Evaluation refers to Item IDs, never display indexes. For `text_match`, v3 writes accepted text as `acceptedAnswers`. The importer also understands the older v2 `accepted` key for compatibility.

## Presentation

Flashcard is `kind: presentation`. Its completion actions include `understood` and `review_later`. It has no correct/incorrect result.

## Assessment Topics

Language Duel is represented as a Topic with `role: assessment` and `assessment.purpose: skip_test`. The standard QuisquisLingo configuration selects 25 eligible Chapter exercises and uses 4 lives. There is no score or pass threshold: the learner wins by completing all 25 questions before losing all four lives.

## Compatibility

Course Model v3 is the native runtime/export format. Course Model v2 remains importable through a deterministic compatibility migration. A v2 Chapter Guidebook is converted into Topic Guidebooks with new stable Topic-scoped Content IDs so the migrated course does not create duplicate Guidebook IDs. Export writes `formatVersion: 3`. Older historical formats are project references rather than a second runtime format.
