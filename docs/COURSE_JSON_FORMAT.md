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

## Origin, provenance and versions

Every course serializes `originType` as `custom`, `bundledOfficial`, or `externalOfficial`. Existing v6 custom files that predate Build 225.04 remain custom when the optional field is absent. Official courses also require publisher identity, a publisher-owned official version and release timestamp, a lowercase SHA-256 `officialChecksum`, release notes, distribution channel, and `publisherVerificationStatus` (`verified` or `unverified`). Optional publisher signatures can support future distribution verification.

The official source version is distinct from local authoring history. A bundled or external official course retains `officialCourseVersion`; its first confirmed local edit creates `localCourseVersion: 1`, and each later confirmed local edit increments that separate integer by one. Base fields (`baseCourseId`, `basePublisherId`, `baseOfficialCourseVersion`, and `baseOfficialChecksum`) identify the exact official source underlying local work. A custom course instead begins at `courseVersion: "1"` on its first confirmed creation; this field stores its integer version as a JSON string and increments by one per later confirmed course-level transaction. Nested Save/Save as draft, cancellation and failed confirmation do not advance either version counter.

Custom provenance can record `createdByProfileId`, `createdByUsername`, `createdAtUtc`, `lastModifiedByProfileId`, `lastModifiedByUsername`, `lastModifiedAtUtc`, `versionNotes`, and `restoredFromVersion`. Official local edits use the corresponding `localAuthorProfileId`, `localAuthorUsername`, `localModifiedAtUtc`, and `localVersionNotes`. These fields are course metadata, not learner identity or progress. A separate copy clears official provenance, receives a new course ID and becomes custom.

The Build 225.04 official checksum algorithm is `CourseBackupService.officialContentChecksum`:

1. Start with the complete Course Model v6 object serialized by `Course.toJson()` after normal model parsing. Hash the model's serialized values and optional-field rules, not the original file bytes or a partial content projection.
2. Remove exactly these 13 root fields; identically named nested fields are not removed:

   | Excluded fields | Reason |
   | --- | --- |
   | `officialChecksum` | The digest cannot include itself. |
   | `publisherVerificationStatus`, `publisherSignature` | Verification status and signature metadata are separate from the content digest. Local authenticity classification must not change it, and signature data must not become part of the payload it may authenticate. |
   | `baseCourseId`, `basePublisherId`, `baseOfficialCourseVersion`, `baseOfficialChecksum` | These describe a local variant's reference to its official source. |
   | `localCourseVersion`, `localAuthorProfileId`, `localAuthorUsername`, `localModifiedAtUtc`, `localVersionNotes` | These describe local authoring history rather than the official source. |
   | `restoredFromVersion` | This records a local restore operation. |

3. Recursively sort every remaining object's string keys using Dart's default string ordering; preserve list order and serialized scalar values. Encode the result with Dart `jsonEncode` (compact JSON without indentation), then UTF-8, with no added BOM or trailing newline.
4. Compute SHA-256 and store the 64-character lowercase hexadecimal digest in `officialChecksum`.

No other fields are excluded by the checksum algorithm. In particular, publisher identity, `originType`, `officialCourseVersion`, release date and notes, `distributionChannel`, content, and any serialized custom-authoring fields such as `courseVersion` remain covered. The bundled generator and validator use the same exclusion set and compact, recursively key-sorted UTF-8 JSON for the bundled model values. They also reproduce the model's serialized author `role` field alongside `roles` before hashing.

In a Build 225.04 local official variant, `officialChecksum` remains the source digest and `baseOfficialChecksum` records that same digest; neither is recomputed from locally edited content. Changing content can therefore make a recomputed official-content checksum differ from the retained source checksum. The local variant is protected in a backup by the separate `courseChecksumSha256`: `CourseBackupService.courseChecksum` hashes the complete `Course.toJson()` with the same sorting/encoding and **no field exclusions**. Referenced course-owned audio copies have separate SHA-256 checksums over their bytes, verified before restore remaps their paths.

Official source loading and external official installation validate content integrity separately from publisher authenticity. External file installation records `publisherVerificationStatus: unverified` even if the file declares `verified`; Build 225.04 does not authenticate publisher signatures. A checksum alone is not proof of publisher authenticity.

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

`section` defaults to false. When false, `sectionName` is omitted; when true, `sectionName` must be a non-empty trimmed string. Consecutive Lessons with the same name form one visual Section block. Section has no ID, persistence, progress, unlock, XP, Duel or navigation state, and relative Section Lesson numbering is derived from Lesson order.

`lessonNumberingMode` is required and is one of `lesson`, `unit`, `topic`, `module`, `skill`, `chapter`, `stage`, `step`, `part`, `other`, `numberOnly`, or `none`. `other` also requires a trimmed non-empty `customLessonLabel`. `defaultLessonIconStyle` is required and is `monochrome` or `coloredLessonNumbers`. These fields affect presentation only. Learner numbers come from Published Lesson order, and exact default `Lesson N` titles are de-duplicated only in Lesson mode.

`themeIconAsset` is optional. It names either an approved 256 × 256 transparent preinstalled PNG under `assets/lesson_icons/` or a managed Course reference such as `course-assets/lesson-icons/custom_123.png`. Managed references resolve only through the same Course’s optional `lessonIconAssets[]` registry; arbitrary and unresolved filesystem paths are rejected. Because Course transfer is the established JSON-only portable format, each managed registry entry contains its safe `assetId` and canonical `base64Png`. Import normalizes one author image by contain-scaling it without distortion onto a transparent 256 × 256 PNG canvas. The original path is never serialized or needed after import. Course duplication remaps managed asset IDs and Lesson duplication within one Course may share the immutable reference.

The former decorative Lesson `imageAsset` field is not part of Course Model v6 and is rejected. It is not an alias for `themeIconAsset` and is not migrated into one. Exercise Content may still use its own image field where that exercise type requires it.

The structural fields `topics`, `topicId` and Lesson `id` are invalid in v6. Opaque stable identifier values from earlier bundled content may retain historical text because changing their values would break references and course-owned progress.

## Lesson Guidebook

A Lesson contains `guidebook.content[]`. Guidebook Content can include explanations, vocabulary, examples and text. It is learner-facing reference material and may also be used as authoring source material. `sourceRefs` can connect generated or derived Content to stable Guidebook Content IDs.

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

Build 224 groups these primitives as the canonical Select, Input, Arrange and Match models, with Presentation for non-response learning material. Concrete `editorTemplate` presets remain authoring metadata and several presets intentionally share one model. Prompt elements can independently carry text, audio or image media plus a semantic `role`; structured dialogue may add an optional `speaker` string to a text element whose role is `dialogue_turn`. Contextual comprehension stores its question and context as separate prompt roles.

Build the translation uses canonical `arrange` interaction Items and one or more `ordered_items.correctOrders` objects. Each object stores the complete literal target-language `text` plus the stable `itemIds` for the exact block occurrences that construct it. The same Item may not be reused within one answer, but repeated words are supported by separate Item occurrences. Terminal sentence punctuation is stored in the literal answer and does not require an artificial punctuation Item. The legacy single `correctOrder` field is rejected without an adapter.

The Build-the-translation editor creates, deletes and reorders complete literal translations. Every answer must be non-empty, unique after the configured literal normalization, constructible from the available block occurrences and leave no more than two blocks unused across the exercise. Runtime accepts any listed answer with ordinary literal normalization and always displays all configured answers in author order after submission. Type-the-translation expression syntax and typo/similarity acceptance do not apply to Build the translation.

Accepted text entries may be separate complete equivalents or use optional `{...}`, independent alternative `[a|b|c]`, linked alternative `[*:a|b]`, and explicitly scoped reorder `(a <> b)` expressions. Two or more linked groups align by index, require equal alternative counts and never produce cross-combinations. Linked groups compose with the other syntax. Without parentheses, `<>` applies to the whole expression. Reordering keeps terminal punctuation at the final sentence end. Expansion is deterministic, de-duplicated and limited to 128 results; malformed, unequal or oversized expressions are invalid.

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

The standard Duel uses 25 unique questions and 4 lives. There is no score or pass threshold: the learner wins by completing all 25 questions before losing all four lives. If the actual eligible pool has fewer than 25 exercises, that Lesson's Duel is normally unavailable; questions are not duplicated and gameplay rules are not changed. Six Rounds, often roughly 48 exercises, is author guidance only and never determines availability.

## Compatibility

Course Model v6 is the only native runtime, bundled, editor-storage, import and export format. v5 and every other `formatVersion` are unsupported and rejected with a clear error. No compatibility migration runs, incompatible source files and older local-storage namespaces are not deleted, and export writes only canonical v6 fields. Missing or invalid required publication, numbering, icon-style, timestamp or evaluation fields are rejected rather than inferred.
