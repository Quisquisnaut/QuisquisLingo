# QuisquisLingo Course JSON format 5

Status: implemented current format. The in-app Editor Help remains the author-facing reference.

## Root

Every native Course Model v5 course declares:

```json
"formatVersion": 5,
"publicationState": "draft | published",
"lessonNumberingMode": "lesson",
"defaultLessonIconStyle": "monochrome"
```

`courseId` is an immutable globally unique course identity. Course updates retain it so learner course progress follows the update. A fork or separate imported copy receives a new `courseId` and may include `parentCourseId` plus `derivedFromVersion` to preserve its lineage.

The canonical hierarchy is:

`Course > lessons[] > guidebook + rounds[] + duel > content[]`

Course owns an ordered list of Lessons. Every Lesson owns its Guidebook, ordered Rounds and stable Duel identity. Chapter and assessment-Lesson fields are not part of Course Model v5.

Every Lesson requires `lessonId` and `title`. Optional presentational metadata uses this shape:

```json
{
  "lessonId": "stable_opaque_id",
  "publicationState": "published",
  "title": "At the railway station",
  "section": true,
  "sectionName": "Travel",
  "themeIconAsset": "assets/lesson_icons/train.png"
}
```

`section` defaults to false. When false, `sectionName` is omitted; when true, `sectionName` must be a non-empty trimmed string. Consecutive Lessons with the same name form one visual Section block. Section has no ID, persistence, progress, unlock, XP, Duel or navigation state, and relative Section Lesson numbering is derived from Lesson order.

`lessonNumberingMode` is required and is one of `lesson`, `unit`, `topic`, `module`, `skill`, `chapter`, `stage`, `step`, `part`, `other`, `numberOnly`, or `none`. `other` also requires a trimmed non-empty `customLessonLabel`. `defaultLessonIconStyle` is required and is `monochrome` or `coloredLessonNumbers`. These fields affect presentation only. Learner numbers come from Published Lesson order, and exact default `Lesson N` titles are de-duplicated only in Lesson mode.

`themeIconAsset` is optional. It names either an approved 256 × 256 transparent preinstalled PNG under `assets/lesson_icons/` or a managed Course reference such as `course-assets/lesson-icons/custom_123.png`. Managed references resolve only through the same Course’s optional `lessonIconAssets[]` registry; arbitrary and unresolved filesystem paths are rejected. Because Course transfer is the established JSON-only portable format, each managed registry entry contains its safe `assetId` and canonical `base64Png`. Import normalizes one author image by contain-scaling it without distortion onto a transparent 256 × 256 PNG canvas. The original path is never serialized or needed after import. Course duplication remaps managed asset IDs and Lesson duplication within one Course may share the immutable reference.

The former decorative Lesson `imageAsset` field is not part of Course Model v5 and is rejected. It is not an alias for `themeIconAsset` and is not migrated into one. Exercise Content may still use its own image field where that exercise type requires it.

The structural fields `topics`, `topicId` and Lesson `id` are invalid in v5. Opaque stable identifier values from earlier bundled content may retain historical text because changing their values would break references and course-owned progress.

## Lesson Guidebook

A Lesson contains `guidebook.content[]`. Guidebook Content can include explanations, vocabulary, examples and text. It is learner-facing reference material and may also be used as authoring source material. `sourceRefs` can connect generated or derived Content to stable Guidebook Content IDs.

The first Content item of Round 1 may be a non-exercise `lesson_intro` derived from essential Lesson Guidebook information. Bundled sample courses use this convention and tell the learner to read the Lesson Guidebook for more.

## Round

A Round contains a stable `id`, required `publicationState`, optional learner-facing `title`, `visualType` and ordered `content[]`. An empty or omitted title is valid and the learner/editor UI falls back to its derived `Round N` label without changing identity. `visualType` is one of `listening`, `story`, `generic` or `test` and is independent of exercise type.

## Content

Every Content object has a stable `id`, canonical `publicationState`, a `kind`, and `required`. For exercise/presentation Content this is the authored Exercise publication state. `editorTemplate` is optional authoring metadata.

Initial kinds include `exercise`, `presentation`, `explanation`, `example`, `vocabulary`, `text`, `image`, `audio`, and `dialogue`.

## Exercise

Exercise Content uses:

`prompt[] + interaction + evaluation`

Initial interaction primitives are `select`, `input`, `arrange`, and `match`.

Initial evaluation primitives are `selected_items`, `text_match`, `ordered_items`, and `matched_items`.

Options, tokens and match members are stable Items. Evaluation refers to Item IDs, never display indexes. For `text_match`, v5 writes accepted text as `acceptedAnswers`; the parser also accepts `accepted` for that exercise field.

Build 224 groups these primitives as the canonical Select, Input, Arrange and Match models, with Presentation for non-response learning material. Concrete `editorTemplate` presets remain authoring metadata and several presets intentionally share one model. Prompt elements can independently carry text, audio or image media plus a semantic `role`; structured dialogue may add an optional `speaker` string to a text element whose role is `dialogue_turn`. Contextual comprehension stores its question and context as separate prompt roles.

Accepted text entries may be separate complete equivalents or use optional `{...}`, independent alternative `[a|b|c]`, linked alternative `[*:a|b]`, and explicitly scoped reorder `(a <> b)` expressions. Two or more linked groups align by index, require equal alternative counts and never produce cross-combinations. Linked groups compose with the other syntax. Without parentheses, `<>` applies to the whole expression. Reordering keeps terminal punctuation at the final sentence end. Expansion is deterministic, de-duplicated and limited to 128 results; malformed, unequal or oversized expressions are invalid.

Answer acceptance and correction selection are separate. Structured evaluation returns correctness, the nearest matched canonical answer, an exact/normalized/missing-diacritic/typo reason and only the differences actually used. Correct typed feedback displays those diagnostics without inventing reasons for exact answers. Wrong answers retain the same nearest-correction ranking through exact shared tokens, graded spelling similarity, incompatible extras, absent words and token order; exact ties retain author order and cannot change correctness.

## Authoring identity and generated drafts

Editing and Draft/Published transitions preserve every existing Course, Lesson, Round, Exercise, Content and Item ID. Learner visibility requires the object and all ancestors to be Published. Draft descendants are retained in authoring export but excluded from learner selection, numbering, Sections, execution, completion, Review, Duel and XP. Duplicating a Course or subtree recursively allocates fresh owned IDs and starts the duplicate as Draft. Generated GuideBook material likewise becomes real fresh-ID Draft content only when explicitly approved; approval is not publication.

The Exercise Creation Wizard and GuideBook Round Generator are editor workflows, not serialized Course Model concepts. Wizard-created Exercises and approved generated Rounds/Exercises are Draft. GuideBook plans remain outside the Lesson until approval appends them after existing Rounds. Neither workflow changes `formatVersion: 5`.

Source-format conversion is isolated behind an import-normalization representation before producing these native structures. No source taxonomy is a runtime exercise discriminator, and build 224 does not include a production converter for third-party course formats.

## Presentation

Flashcard is `kind: presentation`. Its completion actions include `understood` and `review_later`. It has no correct/incorrect result.

Round `content[]` is also the structured content container for future Story-like sequences: narration, dialogue or other presentation blocks can be interleaved with independently evaluated exercises. There is no separate monolithic Story evaluator.

## Lesson Duel

Every Lesson serializes a Duel object with a stable `id` and `title`. Availability is not serialized. At runtime QuisquisLingo collects exercises from that Lesson only, applies the established eligibility and deduplication rules, and requires 25 eligible exercises.

The standard Duel uses 25 unique questions and 4 lives. There is no score or pass threshold: the learner wins by completing all 25 questions before losing all four lives. If the actual eligible pool has fewer than 25 exercises, that Lesson's Duel is normally unavailable; questions are not duplicated and gameplay rules are not changed. Six Rounds, often roughly 48 exercises, is author guidance only and never determines availability.

## Compatibility

Course Model v5 is the only native runtime, import and export format. Chapter-based formats and any other `formatVersion` are unsupported and rejected. Build-224 publication, Lesson-numbering and fallback-icon fields are a clean cut: missing or invalid required values are rejected rather than inferred or migrated. Export writes the canonical current fields.
