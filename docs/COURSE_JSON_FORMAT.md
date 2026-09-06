# QuisquisLingo Course JSON format 6

Status: implemented current format. The in-app Editor Help remains the author-facing reference.

## Root

Every native Course Model v6 course declares:

```json
"formatVersion": 6,
"publicationState": "draft | published",
"lessonNumberingMode": "lesson",
"defaultLessonIconStyle": "monochrome"
```

`courseId` is an immutable globally unique course identity. Course updates retain it so learner course progress follows the update. A fork or separate imported copy receives a new `courseId` and may include `parentCourseId` plus `derivedFromVersion` to preserve its lineage.

Phase 226.04 adds optional, backward-compatible Course Model v6 presentation and availability fields:

- `createDuels` and `useGuidebook`: booleans, each defaulting to `true` when absent. Canonical JSON writes only `false`; explicit non-boolean values, including null, are rejected.
- `sectionNames`: an optional ordered catalog of reusable, non-empty trimmed Section names. Duplicate names are removed while retaining first occurrence order. An empty catalog is omitted. Existing Lesson assignments remain discoverable without automatically adding a catalog to older JSON.
- `worldFlagId`: an optional trimmed stable ID from the authoritative World Flags SVG library. An empty value is omitted. A present value must be a string. It references bundled artwork; SVG bytes and external file paths are not copied into the Course.

These defaults preserve older v6 exports and bundled checksum payloads. No format-version migration or rewrite of existing course files is required. Current copy, transfer, editor transactions and exports retain explicitly stored choices and the complete canonical model.

New Course's **Number of Lessons** (default 3, range 1–100) and **Rounds per Lesson** (default 1, range 1–20) are one-time scaffolding inputs, not JSON fields. The generated canonical Lessons and empty Rounds persist normally, including their stable IDs and order. Neither these creation ranges nor the defaults constrain supported course imports, the Course Model or later editing; a course with more Lessons or Rounds remains supported.

## Origin, provenance and versions

Every course serializes `originType` as `custom`, `bundledOfficial`, or `externalOfficial`. Existing v6 custom files that predate Build 225.04 remain custom when the optional field is absent. Official courses also require publisher identity, a publisher-owned official version and release timestamp, a lowercase SHA-256 `officialChecksum`, and distribution channel. They serialize `publisherVerificationStatus` (`verified` or `unverified`); release notes and publisher signatures are optional. Signatures can support future distribution verification.

Build 226.01 official courses are locally read-only and use the publisher-owned `officialCourseVersion`. There is no local official authoring branch or local version counter. Former `baseCourseId`, `basePublisherId`, `baseOfficialCourseVersion`, `baseOfficialChecksum`, `localCourseVersion`, `localAuthorProfileId`, `localAuthorUsername`, `localModifiedAtUtc` and `localVersionNotes` fields are no longer part of the serialized model. Old overrides are not used, converted to forks or deleted.

A custom course begins at `courseVersion: "1"` on its first confirmed creation. This integer version is stored as a JSON string and increments by one per later confirmed course-level transaction. Nested Save/Save as draft, cancellation and failed confirmation do not advance it. Existing ordinary Build 225 v6 custom courses remain supported.

Custom provenance records `createdByProfileId`, `createdByUsername`, `createdAtUtc`, `lastModifiedByProfileId`, `lastModifiedByUsername`, `lastModifiedAtUtc`, `versionNotes`, and `restoredFromVersion`. These are course metadata, not learner progress.

Optional `derivativeWorksPolicy` is `allowed`, `forbidden` or `unspecified`. Missing/null means unspecified, which is omitted by canonical serialization. Only `allowed` enables the explicit **Fork as custom course** action. Neither a missing policy nor human-readable `license` text grants permission; the original license text is retained. Bundled courses currently have no explicit derivative permission.

A licensed official fork receives a new custom `courseId`, fresh owned content IDs, `parentCourseId` and `derivedFromVersion`, and starts an independent custom history. Its immutable `forkProvenance` object contains `originalPublisherId`, `originalPublisherName`, `originalCourseId`, `originalOfficialCourseVersion`, `originalOfficialChecksum`, `originalCourseTitle`, `originalAuthor` and `originalAuthors` (including roles), plus separately `forkCreatedByProfileId`, `forkCreatedByUsername` and `forkCreatedAtUtc`. Required identities must be nonempty, the checksum lowercase SHA-256 and the creation timestamp UTC. Original author credits are copied, never replaced with the fork creator; later custom contributors and version authors remain separate. Renaming, editing, versioning, restore and export/import retain this object. Existing-course replacement cannot change or remove it. Official courses cannot contain `forkProvenance`.

The Build 226.01 official checksum algorithm is `CourseBackupService.officialContentChecksum`:

1. Start with the complete Course Model v6 object serialized by `Course.toJson()` after normal model parsing. Hash the model's serialized values and optional-field rules, not original file bytes or a partial content projection.
2. Remove exactly three root fields: `officialChecksum` (the digest cannot include itself), `publisherVerificationStatus` and `publisherSignature` (authenticity classification and signature metadata are separate from the authenticated payload). Identically named nested fields are not removed.
3. Recursively sort every remaining object's string keys using Dart's default string ordering; preserve list order and serialized scalar values. Encode with Dart `jsonEncode` (compact JSON), then UTF-8, without a BOM or trailing newline.
4. Compute SHA-256 and store the 64-character lowercase hexadecimal digest in `officialChecksum`.

No other serialized fields are excluded. Publisher identity, origin, official version/release metadata, content and any explicitly allowed/forbidden derivative policy are covered. `restoredFromVersion`, if serialized, is also covered; official courses have no local restore workflow. Removed local-variant fields no longer reach serialization. Existing bundled source digests remain unchanged because none of those fields occurred in their payloads. The bundled generator and validator use the same exclusions and compact, recursively key-sorted UTF-8 JSON for bundled model values, including the serialized author `role` beside `roles` and omission of unspecified derivative policy.

The separate backup `courseChecksumSha256` hashes the complete `Course.toJson()` with the same sorting/encoding and **no exclusions**, including custom fork provenance. Referenced course-owned audio copies have separate SHA-256 checksums over their bytes, verified before custom restore remaps their paths. Official history/export retains the publisher's original payload paths so its checksum remains valid. Official Version History exposes publisher sources only; obsolete local-variant manifests remain on disk without being loaded or restored.

Official source loading and external official installation validate content integrity separately from publisher authenticity. External file installation records `publisherVerificationStatus: unverified` even if a file declares `verified`; publisher signatures are not authenticated. A checksum alone is not proof of publisher authenticity. Updates require the same official identity/publisher, a newer official version and valid integrity; only the official source is replaced, never an existing fork.

The canonical hierarchy is:

`Course > lessons[] > guidebook + rounds[] + duel > content[]`

Course owns an ordered list of Lessons. Every Lesson owns its Guidebook, ordered Rounds and stable Duel identity. Chapter and assessment-Lesson fields are not part of Course Model v6.

Every mutable Lesson, Round and Exercise object requires `updatedAt` as a canonical UTC ISO-8601 timestamp ending in `Z`. Nested authoring Save writes only to the current Course Editor working copy. No child save updates live persistence or the course version. Deterministic bundled generation assigns explicit stable creation timestamps so repeated runs are byte-identical.

Every Lesson requires `lessonId` and `title`. Optional presentational metadata uses this shape:

```json
{
  "lessonId": "stable_opaque_id",
  "publicationState": "published",
  "updatedAt": "2026-09-04T12:00:00.000Z",
  "title": "At the railway station",
  "section": true,
  "sectionName": "Travel",
  "themeIconAsset": "assets/lesson_icons/train.png"
}
```

`section` defaults to false. When false, `sectionName` is omitted; when true, `sectionName` must be a non-empty trimmed string. Consecutive Lessons with the same name form one visual Section block. An unsectioned Lesson does not inherit its predecessor's assignment. Section has no ID or independently owned progress, unlock, XP or Duel state; only its catalog and Lesson assignment metadata persist. Relative Section Lesson numbering is derived from Lesson order.

`lessonNumberingMode` is required and is one of `lesson`, `unit`, `topic`, `module`, `skill`, `chapter`, `stage`, `step`, `part`, `other`, `numberOnly`, or `none`. The UI labels `lesson`, `numberOnly` and `none` as **Lesson + number**, **Number only** and **Title only** without changing stored values. `other` also requires a trimmed non-empty `customLessonLabel`; all existing alternative prefixes remain supported. `defaultLessonIconStyle` is required and is `monochrome` or `coloredLessonNumbers`, displayed as **Theme-colored circle** or **Four-color circle** on Lessons. These fields affect presentation only. Learner numbers come from Published Lesson order. A title identical to its generated prefix is displayed once; the default `Lesson N` is also displayed as `N` in Number only mode. Stored titles remain unchanged, including when Unit or custom prefixes are selected.

`themeIconAsset` is optional. It names either an approved 256 × 256 transparent preinstalled PNG under `assets/lesson_icons/` or a managed Course reference such as `course-assets/lesson-icons/custom_123.png`. Managed references resolve only through the same Course’s optional `lessonIconAssets[]` registry; arbitrary and unresolved filesystem paths are rejected. Because Course transfer is the established JSON-only portable format, each managed registry entry contains its safe `assetId` and canonical `base64Png`. Import normalizes one author image by contain-scaling it without distortion onto a transparent 256 × 256 PNG canvas. The original path is never serialized or needed after import. Course duplication remaps managed asset IDs and Lesson duplication within one Course may share the immutable reference.

The former decorative Lesson `imageAsset` field is not part of Course Model v6 and is rejected. It is not an alias for `themeIconAsset` and is not migrated into one. Exercise Content may still use its own image field where that exercise type requires it.

The structural fields `topics`, `topicId` and Lesson `id` are invalid in v6. Opaque stable identifier values from earlier bundled content may retain historical text because changing their values would break references and course-owned progress.

## Lesson Guidebook

A Lesson contains a Guidebook with `content[]`. Its optional `publicationState` is `draft` or `published`; absence retains the compatible Published default, and canonical serialization adds the field only for Draft. A Draft Guidebook and its content stay out of learner delivery while the Lesson and its Rounds can remain Published. Guidebook Content can include explanations, vocabulary, examples and text. It is learner-facing reference material and may also be used as authoring source material. `sourceRefs` can connect generated or derived Content to stable Guidebook Content IDs.

The displayed GuideBook Internal ID is derived as `${lessonId}_guidebook` from the immutable owning Lesson ID. It is not a new persisted Guidebook field and does not replace stable Guidebook Content IDs. Renaming or moving the Lesson preserves it; a duplicated Lesson receives its own derived GuideBook identity.

Course `useGuidebook: false` preserves the complete Guidebook, its publication state and source references. It disables learner GuideBook interactions while retaining the Home Lesson/book presentation, and suppresses only the canonical `LESSON_GUIDEBOOK_EMPTY` Warning. Malformed-content findings remain active. Reenabling the preference restores current canonical Audit and learner access subject to the existing publication and access rules.

The first Content item of Round 1 may be a non-exercise `lesson_intro` derived from essential Lesson Guidebook information. Bundled sample courses use this convention and tell the learner to read the Lesson Guidebook for more.

## Round

A Round contains a stable `id`, required `publicationState`, required UTC `updatedAt`, optional learner-facing `title`, `visualType` and ordered `content[]`. An empty or omitted title is valid and every learner, editor, Review, Audit and report surface falls back to its current position-derived `Round N` label without changing identity. `visualType` is one of `listening`, `story`, `generic` or `test` and is independent of exercise type.

## Content

Every Content object has a stable `id`, canonical `publicationState`, a `kind`, and `required`. Exercise Content also requires its canonical UTC `updatedAt`. `editorTemplate` is optional authoring metadata.

Initial kinds include `exercise`, `presentation`, `explanation`, `example`, `vocabulary`, `text`, `image`, `audio`, and `dialogue`.

## Exercise

Exercise Content uses:

`prompt[] + interaction + evaluation`

Initial interaction primitives are `select`, `input`, `arrange`, and `match`.

Initial evaluation primitives are `selected_items`, `text_match`, `ordered_items`, and `matched_items`.

Options, tokens and match members are stable Items. Evaluation refers to Item IDs, never display indexes. For `text_match`, v6 writes accepted text as `acceptedAnswers`; legacy `accepted` is rejected rather than adapted.

Phase 226.03 retains formatVersion 6 and the existing canonical fields. Translation expressions and materialized independent answers both remain ordinary `evaluation.acceptedAnswers` strings; no expression-to-answer synchronization metadata is stored. `editorTemplate: type_missing_word` uses Input/text_match with complete accepted words and one `___` prompt gap; its initial grapheme is derived at runtime, not serialized. Existing presets and absent optional fields retain their existing parsing/defaults.

`editorTemplate: script_recognition` uses Select/selected_items, stable option Item IDs and exactly one `correctItemIds` entry. Image to text stores prompt image elements and text option elements; Text to image stores a text prompt and image option elements. The mode derives from these canonical fields, with no new mode field or migration. Portable image assets are safe bundled `assets/exercise_images/...` references or bounded `data:image/png;base64,...`, `data:image/jpeg;base64,...` or `data:image/webp;base64,...` strings in the existing element `asset` field. Embedded images preserve original bytes, are limited to 50 KB and 4096 pixels per dimension, and travel with JSON exports, backups, copies and forks. Invalid assets are rejected by Audit/authoring gates; incomplete Drafts retain their canonical content for later correction. Unknown/legacy malformed input is not silently converted or discarded.

Build 224 groups these primitives as the canonical Select, Input, Arrange and Match models, with Presentation for non-response learning material. Concrete `editorTemplate` presets remain authoring metadata and several presets intentionally share one model. Prompt elements can independently carry text, audio or image media plus a semantic `role`; structured dialogue may add an optional `speaker` string to a text element whose role is `dialogue_turn`. Contextual comprehension stores its question and context as separate prompt roles.

Build the translation uses canonical `arrange` interaction Items and one or more `ordered_items.correctOrders` objects. Each object stores the complete literal target-language `text` plus the stable `itemIds` for the exact block occurrences that construct it. The same Item may not be reused within one answer, but repeated words are supported by separate Item occurrences. Terminal sentence punctuation is stored in the literal answer and does not require an artificial punctuation Item. The legacy single `correctOrder` field is rejected without an adapter.

The Build-the-translation editor creates, deletes and reorders complete literal translations. Every answer must be non-empty, unique after the configured literal normalization, constructible from the available block occurrences and leave no more than two blocks unused across the exercise. Runtime accepts any listed answer with ordinary literal normalization and always displays all configured answers in author order after submission. Type-the-translation expression syntax and typo/similarity acceptance do not apply to Build the translation.

Accepted text entries may be separate complete equivalents or use optional `{...}`, independent alternative `[a|b|c]`, linked alternative `[*:a|b]`, and explicitly scoped reorder `(a <> b)` expressions. Two or more linked groups align by index, require equal alternative counts and never produce cross-combinations. Linked groups compose with the other syntax. Without parentheses, `<>` applies to the whole expression. Reordering keeps terminal punctuation at the final sentence end. Expansion is deterministic, de-duplicated and limited to 128 results; malformed, unequal or oversized expressions are invalid.

In 226.03 revision 1, syntactically present optional operands and linked members may expand to empty strings. Original linked cardinality and column positions are validated before optional removal. Empty final branches are excluded from answers and materialization; the existing intermediate 128-variant safety limit remains in force before final deduplication. A materially absent `<>` operand remains invalid. Terminal sentence punctuation is appended after non-empty expansion. No syntax or persistence field is added. Type the missing word continues to store complete accepted words; learners now enter that complete word and the revealed first grapheme is only a hint.

Answer acceptance and correction selection are separate. Structured evaluation returns correctness, the nearest matched canonical answer, an exact/normalized/missing-diacritic/typo reason and only the differences actually used. Correct typed feedback displays those diagnostics without inventing reasons for exact answers. Wrong answers retain the same nearest-correction ranking through exact shared tokens, graded spelling similarity, incompatible extras, absent words and token order; exact ties retain author order and cannot change correctness.

## Authoring identity and generated drafts

Editing and Draft/Published transitions preserve every existing Course, Lesson, Round, Exercise, Content and Item ID. Learner visibility requires the object and all ancestors to be Published. Draft descendants are retained in authoring export but excluded from learner selection, numbering, Sections, execution, completion, Review, Duel and XP. Duplicating a Course or subtree recursively allocates fresh owned IDs and starts the duplicate as Draft. Generated GuideBook material likewise becomes real fresh-ID Draft content only when explicitly approved; approval is not publication.

Course Editor authoring uses one in-memory transaction: immutable original snapshot plus editable working copy. Nested **Save** and **Save as draft** update that working copy only. The entire working copy is persisted only after the top-level **Confirm course changes** action has created and verified a complete backup and assigned the next internal course version. **Cancel course changes** serializes nothing.

The Exercise Creation Wizard and GuideBook Round Generator are editor workflows, not serialized Course Model concepts. Wizard-created Exercises and approved generated Rounds/Exercises are Draft. GuideBook plans remain outside the Lesson until approval appends them after existing Rounds. Neither workflow changes `formatVersion: 6`.

Source-format conversion is isolated behind an import-normalization representation before producing these native structures. No source taxonomy is a runtime exercise discriminator, and build 224 does not include a production converter for third-party course formats.

## Presentation

Flashcard is `kind: presentation`. Its completion actions include `understood` and `review_later`. It has no correct/incorrect result.

Round `content[]` is also the structured content container for future Story-like sequences: narration, dialogue or other presentation blocks can be interleaved with independently evaluated exercises. There is no separate monolithic Story evaluator.

## Lesson Duel

Every Lesson serializes a Duel object with a stable `id` and `title`. Availability is not serialized. At runtime QuisquisLingo collects exercises from that Lesson only, applies the established eligibility and deduplication rules, and requires 25 eligible exercises.

Course `createDuels` defaults to true. When false, the learner renders no Duel or reserved Duel spacing and Audit emits no `DUEL_UNAVAILABLE` finding. When true, the same shared eligible pool drives learner availability and the non-blocking `DUEL_UNAVAILABLE` Info finding. An insufficient pool also renders no learner Duel placeholder. The preference never deletes Duel identity, course-owned victory history, Lesson completion or earned XP.

The standard Duel uses 25 unique questions and 4 lives. There is no score or pass threshold: the learner wins by completing all 25 questions before losing all four lives. If the actual eligible pool has fewer than 25 exercises, that Lesson's Duel is normally unavailable; questions are not duplicated and gameplay rules are not changed. Six Rounds, often roughly 48 exercises, is author guidance only and never determines availability.

## Compatibility

Course Model v6 is the only native runtime, bundled, editor-storage, import and export format. v5 and every other `formatVersion` are unsupported and rejected with a clear error. No compatibility migration runs, incompatible source files and older local-storage namespaces are not deleted, and export writes only canonical v6 fields. Missing or invalid required publication, numbering, icon-style, timestamp or evaluation fields are rejected rather than inferred.
