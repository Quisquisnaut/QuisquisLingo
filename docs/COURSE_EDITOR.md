# QuisquisLingo Course Editor

Updated for Version 2.0.26, Build 226.01 and Course Model v6

## Unlocking the editor

Course Editor is an Easter Egg so ordinary learners do not encounter authoring controls accidentally. Open **Settings** and tap/click anywhere in the complete **Version and Build** row ten times within about five seconds. `Course Editor unlocked` appears and the Course Editor entry becomes visible. The unlock state is stored locally on the device.

## Editable hierarchy

The authoring actions below apply to custom courses. Bundled and external official courses instead open **Official course - read only**, with Course Info, Audit, Preview, publisher Version History and Lesson/Round/Exercise inspection. No official content editing, save, publication, media or authoring transaction is available.

For custom courses the editor supports the whole authoring tree:

- Course → open **Lessons**, the first content section
- Lessons → use the authoritative Lock control and create/reorder Lessons; each Lesson menu provides Edit, Rename, Delete, Duplicate, Preview and Audit
- Lesson → edit its title, Section metadata, preinstalled or custom managed theme icon and GuideBook; open the linked Rounds page; a stable Duel identity is retained automatically
- Rounds → the first section inside a Lesson; create/reorder Rounds, with Edit, Rename, Delete, Duplicate, Preview and Audit actions
- Round → create/reorder Exercises; every Exercise menu includes Edit, Duplicate, Preview, transfer and delete actions

New objects receive generated local IDs. Deleting an object removes its descendants from the current working copy. Official source content is never modified by local authoring.

Each Lesson can optionally enable **Belongs to a Section** and then requires a trimmed, non-empty **Section name**. Section is consecutive-order display metadata only: it is not a hierarchy, has no ID, and owns no progress or navigation. Disabling the switch clears the stored Section name.

The controlled **Lesson theme icon** picker separates **Preinstalled** and **Custom**. For **Import custom icon**, keep exactly one PNG/JPG/JPEG/WebP in `Documents/QuisquisLingo/Imports/Lesson Icons`. The input must be non-empty, no larger than 2 MB (2,097,152 bytes), and 1–8192 pixels on each side. QQL decodes the first frame, scales it up or down proportionally, and centers it without cropping or distortion on a transparent 256 × 256 PNG canvas. Existing transparency survives; an opaque background is not removed. Missing/multiple files, unsupported or unreadable image data, excessive size/dimensions and failed PNG conversion stop import. The source is left in place. The Course-owned managed asset stores embedded PNG data, so no external source path is serialized or needed later. Managed icons survive Course export/import and Course duplication; Lesson duplication within the Course reuses the immutable asset. `None` uses the Course’s monochrome or deterministic colored-number fallback. Every learner icon uses the established 84 × 84 footprint.

## One course-level editing transaction

Opening a custom course in Course Editor loads the current persisted course, preserves an immutable original snapshot, and creates a separate editable working copy. Course Info, Lesson, Round, Exercise, GuideBook, generated-content acceptance, deletion, duplication and reordering mutate only that working copy. The live learner course remains unchanged during the editing session.

Nested editors use **Save**, or **Save as draft** when Draft status is supported. Save stores a normal non-Draft item in the working copy; Save as draft stores a Draft item there. Neither action persists the course, creates a backup, increments the internal course version, or represents final publication. Nested pages return without a course-level confirmation. Leaving an Exercise with unsaved changes offers **Keep editing**, **Discard changes**, **Save as draft** or **Save**. Discard affects only that Exercise form; earlier working-copy changes remain. Other nested pages retain their established Back behavior.

Course Editor compares canonical course content rather than a one-way dirty flag. Restoring the original semantic values makes the session clean again. Transient focus, selection, controllers and scroll state are not course content. Only an attempt to leave the top-level Course Editor can show the single unapplied-course dialog, with these explicit actions:

- **Confirm course changes** — optionally records a multiline version note, creates and verifies a complete backup of the currently persisted course, increments its separate internal course version by exactly one, atomically applies and verifies the whole working copy, shows the resulting version and backup path, and exits only after success.
- **Cancel course changes** — discards the complete working copy, creates no backup, performs no version increment, leaves the persisted course untouched, and exits.

If the working copy equals the original, the Editor exits directly. A backup or persistence failure leaves the original unchanged, preserves the working copy and version note, and keeps the Editor open with a clear error.

Course, Lesson, Round and Exercise content retains explicit `Draft` / `Published` state for learner projection. A Published child below a Draft parent remains hidden. Draft Courses are not learner-selectable; Draft Lessons do not affect numbering, Sections or unlock order; Draft Rounds and Exercises do not affect play, completion, Review, Duel or XP. Nested Save is the replacement for the former nested Publish label; final application of the complete course happens only through Confirm course changes.

Course info controls the learner-visible Lesson prefix: Lesson, Unit, Topic, Module, Skill, Chapter, Stage, Step, Part, a trimmed custom label, number only, or none. Numbers use Published Lesson order only. The exact untouched default `Lesson N` is shown once when Lesson mode would otherwise duplicate it. Course info also chooses the monochrome or colored-number fallback style and stores an optional validated **Buy a Coffee** HTTPS URL.

The Lesson form keeps Lesson metadata readily accessible and links to one dedicated **Rounds** page instead of expanding the complete list inline. The page reuses the existing Round workflow and returns naturally to the Lesson working copy. Navigation alone writes nothing. Every stable ID remains intact unless an explicit duplication creates a new identity.

Duplicate inserts the independent copy immediately after its source. Lesson duplication recursively allocates fresh Lesson, Duel, GuideBook Content, Round, Exercise and item IDs; Round and Exercise duplication applies the corresponding subtree rule. Internal ID references are remapped while shared immutable image/audio asset paths remain references. Editing a duplicate cannot mutate its source. Rename changes only the title and preserves identity and descendants. Preview uses learner rendering without writing completion, XP, streak, Laurel, Review, Duel or unlock state.

**Move Exercise to…** and **Copy Exercise to…** choose an explicit Course → Lesson → Round destination within the current course working copy. **Move Round to…** and **Copy Round to…** choose a Lesson there. Move preserves the moved object's stable identity, content and Draft/Published state while removing it from its original parent. Copy allocates fresh IDs throughout the owned subtree and remaps internal references. Copies use the existing duplication policy: the copied object and owned descendants start as Draft. Neither action confirms the course or changes the persisted learner course.

Exercise **Previous** and **Next** follow the current Round order, stop at its boundaries and use the same unsaved-change protection as Back. Breadcrumbs show readable Course, Lesson, Round and Exercise context; navigating a safe parent level also protects unsaved Exercise values. **Preview** sits beside the Save actions and uses the complete current unsaved form, including a new or Draft Exercise. Insufficient runtime data produces a validation message without losing edits. Returning restores the same form values; Preview does not save content or change publication state, versions, backups or learner data.

An empty Round title is intentionally supported in Create and Edit Round. The form explains how to keep it untitled; learner and editor labels use its current **Round N** position without creating a stored title or changing its ID.

An orange Round outline means it currently contains at least one Draft Exercise. A pink outline continues to mean an Audit Error. Both outlines are visible when both conditions apply. Lesson rows show their Draft Exercise counts and Course Editor shows the course total; these counts and outlines follow the working copy, including saves, publication changes, deletion, Move and Copy.

Rounds normally contain 15 exercises. The editor does not enforce 15 as a hard maximum. Course Audit reports unusually short or long rounds so the author can review them.

## Exercise type is immutable

Choose the exercise type only when creating an exercise. Once created, the type is locked. This prevents stale fields from one type being reinterpreted as another. To replace a type, create a new exercise, copy/adapt the content, then delete the old exercise.

The editor displays only fields used by the current exercise type. Examples:

- Flashcard: Word/expression, Translation/meaning, Pronunciation TTS, Usage sentence
- Reading comprehension: Reading passage, Comprehension question, Answers, Correct answer
- Listening comprehension: Spoken passage, Comprehension question, Answers, Correct answer
- Word Blocks: Translation prompt, Available word blocks, Correct sentence
- Audio Match: Three sound matches producing exactly three visible choices, with no distractors

Technical fields such as numeric JSON indices are minimized. Correct choice remains an author-facing answer number for compact editing.

## Exercise presets and Help

When creating an exercise, the grouped searchable picker offers concrete teaching presets rather than internal model names:

- **Multiple choice:** How do you say, Fill in the blank, Select the image, What do you hear, Listen and choose, Reading comprehension, Dialogue response, Contextual comprehension
- **Translation:** Type the translation, Build the translation
- **Text input:** Type a missing word, Type what you hear, Listen for missing words
- **Matching:** Match the pairs, Match the words, Match related words, Listen and match
- **Ordering:** Word order, Image-prompt ordering
- **Presentation:** Flashcard

The **Exercise Help** action next to the preset control uses the same registry as the picker and validation. It explains what the learner sees and does, the fields and media the author supplies, how correctness is defined, and any restrictions for every available preset.

Field Help is directly accessible beside each non-obvious Exercise field, including Context mode, correct-translation entries and Exercise image. Shared definitions explain the field's purpose, what to enter, one versus multiple values, line rules, formatting, validation and useful examples. The same controller can have different semantics in different presets: Flashcard usage lines are presentation, answer-option lines are choices, Build the translation has separate complete-answer entries, and Word order requires one ordered block per line. Help preserves those distinctions. Typed-answer fields explain the existing accepted-answer syntax below; literal Arrange answers and Listen for missing words gap lists do not expand it.

### Type the translation

Provide source-language text and one or more complete accepted target-language translations, one per line. A hint is optional and must not reveal the solution. The learner types freely. A conservative typo allowance accepts only one accidentally omitted or duplicated repeated letter in a sufficiently long single token while preserving word count, order, diacritics and negation safeguards; substitutions and broader lexical or grammatical changes are not treated as spelling mistakes.

### Build the translation

Provide source-language text, literal target-language blocks and one or more complete correct translations. Add, delete and reorder answers directly; their order is preserved in saved JSON and feedback. Each answer must be non-empty, unique after case/spacing/terminal-punctuation normalization and constructible from distinct block occurrences. Repeated words require repeated block occurrences, internal punctuation is preserved, and no more than two blocks may remain unused. Build the translation uses literal matching only: it does not expand Type-the-translation syntax and does not apply similarity or typo acceptance. After either a correct or incorrect response, every configured correct translation is shown in author order.

### Contextual comprehension

Question and Context are separate. Choose text, audio, or text and audio context, then provide answer choices and the correct answer. Dialogue is optional and is entered as one `Speaker: text` turn per line; ordinary prose is also valid context. An exercise image may supplement the context. The learner reads and/or listens, then answers the separate question.

### Accepted-answer variants

Multiple complete equivalent answers can always be entered as separate lines. Compact syntax is optional:

- `{Io} prendo un cappuccino` makes `Io` optional.
- `{Io} [prendo|vorrei] un cappuccino` declares alternatives.
- `[*:I want|We want] [*:a coffee|two coffees]` links alternatives by index, producing two paired answers rather than four cross-combinations. Use at least two linked groups with equal counts.
- `(non arrivo <> oggi)` allows only those declared phrase parts to swap inside the parentheses.
- `a casa <> domani` applies reordering to the whole expression when no parentheses are present.

Syntax is validated before save. Expansion is deterministic, duplicate results are removed, and the combined limit is 128 answers; larger combinations must be split or simplified. During `<>` reordering, final punctuation such as `.`, `?`, `!`, `…` and `?!` is detached and reattached only at the generated sentence end; internal punctuation is not moved. Generated variants capitalize the first alphabetic character of the sentence and after `.`, `?` or `!`, remove merely structural capitalization when a common phrase starter moves inward, and preserve distinguishable proper names/acronyms such as Jane, Roma and USA.

QQL applies its established case, punctuation, whitespace, apostrophe and accent rules for acceptance. Correct typed feedback always shows the nearest canonical Correct answer and names only differences actually used—such as capitalization, ignored punctuation, normalized whitespace, omitted diacritic or the explicitly allowed typo. Exact answers show no false reason. If a response remains wrong, correction selection independently scores exact shared words, graded word-level spelling similarity, incompatible extra words, missing candidate words and common word order. The nearest construction is displayed, with author order as the exact-tie fallback. This display choice never turns an incorrect response into a correct one.

## Exercise Creation Wizard

In the Round editor, **Creation Wizard** sits beside the unchanged **New exercise** action. Choose between 1 and 30 Exercises, then select one criterion:

- **Balanced mix:** deterministic distribution across registry categories without unnecessary consecutive identical presets
- **Random mix:** registry-backed selection using deterministic seedable randomness
- **By category:** cycle through every preset in the chosen categories
- **Selected exercise types:** cycle through the exact selected registry presets
- **Repeat a pattern:** preserve the author's selection order and repeat it to the requested count

Reviewing the exact N-entry plan creates no Exercise objects. Confirming starts `Exercise 1 of N` and reuses the normal preset-specific Exercise editor. **Save** validates and remains on the current step. **Preview** uses the same draft and returns without copying or advancing. **Next** validates/saves and advances exactly once; the final action is **Finish**, which returns the created Exercises in order. Cancelling after explicit saves requires confirmation and keeps only those valid saved Exercises; future and invalid placeholders are never inserted.

## Generate Rounds from GuideBook

The Lesson Editor generator uses only the current Lesson GuideBook. It requires at least three usable `target = source` vocabulary pairs and never fabricates material from another Lesson. Authors choose 1–12 Rounds and 1–15 Exercises per Round; defaults are 6 and 8, displayed as `6 Rounds × 8 exercises = 48 exercises`.

Before generation, the plan shows the counts, total, normalized difficulty per Round and registry-backed preset distribution without creating final objects. Difficulty is `0…1` by Round position (or `0.5` for a single Round). Early plans emphasize guided recognition/comprehension and fewer distractors; middle plans add matching, ordering, construction and context; late plans emphasize Type the translation and less-scaffolded production, using only media and example-dependent presets supported by the GuideBook. Concise draft titles use the phase and a relevant vocabulary target.

Generated Rounds remain review drafts. Authors can edit them in the authoritative Round editor, preview, delete or regenerate them. **Approve and add Rounds** first requires a clean error-level Course Audit, then allocates final fresh IDs and appends the result after every existing Round. Cancelling or merely viewing the plan changes nothing. Automated generation does not guarantee pedagogical correctness; every Round and Exercise needs human review.

## Word Blocks

A valid Word Block exercise may have 0, 1 or at most 2 extra distractor blocks. The correct sentence is reconstructed from the required block occurrences. Repeated words are counted by occurrence, not only by distinct spelling. Early Lesson rounds should normally use fewer distractors and later rounds may use more.

## Generate exercise set from reading

Open the menu of a Reading comprehension exercise and select **Generate exercise set**. Generation is optional. The reading remains the source exercise.

The author chooses which linked exercises to generate:

- Listening comprehension using the passage, with at least one word-recognition question
- Audio Match using three distinct words from the passage plus two visible distractors
- Translation exercises when an exact source/target sentence pair can be inferred from existing course content
- Word Block translations when an exact sentence pair can be inferred, including one distractor block

Generated exercises are previewed before insertion and passed through Course Audit. QuisquisLingo does not invent a translation when no reliable pair exists; the author can create that translation manually.

## Course Audit

Run **Course Audit** from the top of Course Editor. Severity levels:

- Error: structural or functional problem likely to make an exercise invalid
- Warning: likely authoring problem or non-standard structure
- Info: non-blocking guidance or neutral authoring information

Checks include:

- duplicate or missing IDs
- empty courses/lessons/rounds
- round length versus the standard 15
- unsupported exercise types
- missing/out-of-range correct answers
- duplicate/blank options
- listening exercises without TTS
- empty Reading passages (Error), or one- and two-word lexical Reading passages (`READING_PASSAGE_TOO_SHORT` Warning); three or more Unicode/apostrophe-aware words do not warn
- hints that repeat the prompt (`HINT_REPEATS_PROMPT` Warning) or reveal any canonical accepted answer (Error)
- Word Blocks with more than two distractors or with impossible token counts
- Flashcards without usage or pronunciation
- Audio Match repeated sounds, repeated correct matches, repeated visible choices, missing matches, or a count other than three sound/text pairs without distractors
- icon/answer count mismatch
- fields that do not belong to the selected exercise type
- likely source/target capitalization inconsistency
- repeated prompt/question inside one round
- unavailable Lesson Duels after applying the actual eligibility rules

Audit does not certify grammar, translation accuracy, cultural appropriateness or teaching quality. Those remain human editorial responsibilities.

A Lesson with fewer than six Rounds receives author guidance only. Missing Reading- or Listening-comprehension coverage produces no finding. Existing malformed Reading comprehension still receives its normal validation findings. Duel availability never depends on Round count: fewer than 25 actual eligible Lesson exercises produces a non-blocking `DUEL_UNAVAILABLE` suggestion and is normal supported behavior.

Audit can sort by Lesson, friendly Exercise type or **Recently modified**. Recent order is `updatedAt` descending with deterministic stable tie-breaks. Displayed and exported findings are numbered progressively inside each severity group after the active scope, filter and sort are applied.

Open **Course Editor Help → Technical reference → Audit Codes** to search by code or descriptive text. Every currently emitted rule is defined in the registry shared by Audit and this reference, with its severity, scope, meaning, trigger, creator action and blocking status. Known rules have specific stable codes; `GENERAL` is only a defensive fallback for an unexpected unclassified finding.

## Storage and recovery

Custom courses retain the Course Model v6/build-225 user-course namespace. External official storage loads only its publisher source; bundled loading uses only the bundled asset. Old official overrides remain physically untouched but are not read as content, migrated or converted into forks. A complete custom course is validated structurally before saving and before learner use. Malformed current-namespace JSON is preserved and copied aside before loading fails clearly; it is never silently replaced with an empty collection. Local authoring data has an 8 MB safety limit.

Each successful confirmation of an existing custom course first writes a verified backup below:

`Documents/QuisquisLingo/Exports/Course Backups/<sanitized courseId>`

The manifest contains the complete Course Model v6 JSON, origin and publisher provenance, custom or official versions, author/profile identity, UTC timestamps, reason, optional version notes, SHA-256 integrity data and referenced managed audio. Timestamps are displayed in local date and time. Asset copies are verified before persistence begins. Backups are never pruned or silently deleted.

**Version History** lists the current version and verified backups newest first, with the exact backup folder and portable JSON export. Custom history permits restore into the working copy. Official history contains publisher versions only, with no local restore/copy action; the explicit licensed fork workflow is on the official inspection page. Obsolete local-variant history files remain on disk and are not loaded or presented as official versions. Restore never writes directly to the live course: it becomes another pending working-copy mutation and the next confirmed version remains monotonic. Corrupt or incomplete history is reported and never silently accepted.

## Course origin and official updates

Course Model v6 distinguishes `custom`, `bundledOfficial` and `externalOfficial` origin. Bundled official course assets are immutable source versions. External official files retain publisher identity and a verified or unverified status. Custom courses created or imported locally never acquire official provenance by title or course ID.

An official update requires the same stable course ID and publisher, a newer official version, and a matching content checksum. QuisquisLingo archives the previous official source first, then installs the new official source without a content merge. Only the official source changes; existing custom forks and their histories remain unchanged. A file whose publisher authenticity cannot be established can only be installed after an explicit warning and is labeled **External official — unverified**. A failed archive or write leaves the previous course unchanged.

For custom courses, the first confirmed creation is internal version 1. Later confirmations increment by exactly one. Official courses use only their publisher's official version and cannot be confirmed through a local authoring transaction. The active local QQL profile is required and recorded as creator or last modifier; a missing active profile blocks confirmation rather than inventing identity.

## Licensed custom forks

**Fork as custom course** is enabled only for explicit `derivativeWorksPolicy: allowed`. Forbidden and unspecified policies show an explanation and do not enable a fork; a human-readable license is never interpreted as an implicit grant. No bundled course currently grants derivative permission. Ordinary **Duplicate custom course** remains a separate custom authoring action.

A fork receives fresh course/content IDs and opens as a new editable custom working copy, initially retaining the original license text. First confirmation creates version 1; later changes use ordinary custom backups and version history. Course Info permanently distinguishes original publisher, official identity/version/checksum, title and authors from the local fork creator and later custom version authors. Renaming, editing, restore and export/import retain the original provenance. Cancelling a new fork leaves no saved custom course. Official updates never merge, rebase or replace an existing fork.

## Word Blocks language rule (0.4.25)

A Word Blocks exercise may contain 0, 1 or at most 2 extra distractor blocks. Every distractor must be in the same language as the other visible blocks. This is determined by the language of the answer blocks, not simply by the course target language, because translation exercises can run in either direction.

For **Build the translation**, enter every correct translation as a separate complete literal answer. Terminal `.`, `!`, `?` or `…` punctuation is not an artificial block: each answer resolves to stable canonical Item occurrences while retaining its literal display text.

The bundled-course validator builds conservative source/target lexicons from explicitly oriented matching pairs and flashcards and reports high-confidence cross-language distractors. The in-app audit validates the structural invariant of 0 to 2 usable extra blocks. Language identification is intentionally conservative: ambiguous words shared by two languages must not be auto-rejected solely on spelling.

Capitalization should be consistent across paired sentences and expressions while preserving language-specific orthography, especially German noun capitalization.

## 0.5 authoring behavior

Course Editor is an unlockable Creator mode inside the same QuisquisLingo app. Tap
or click the version label 10 times within about five seconds to unlock it. The
Duel victory sound confirms the unlock when sound effects are enabled.

The editor can work with an entirely empty course. An empty course shows
**Create first Lesson** rather than failing. Lessons, Rounds and
Exercises can be created, deleted and reordered within their parent. Every learning
Lesson has its own editable Guidebook. Deletions require confirmation. Exercise type is selected only at
creation time and cannot be changed afterwards; create a replacement exercise
when a different type is needed.

Word Blocks may contain 0, 1 or at most 2 extra distractors in the same
language as the blocks. The learner is expected to leave any distractor blocks
unused. Early Lesson rounds should normally use fewer distractors than later ones.

A Reading comprehension exercise can optionally generate a linked draft set:
Listening comprehension, Audio Match, translation exercises and Word Blocks.
Generation is opt-in and previews the drafts before insertion. Automatically
generated Word Blocks only take a distractor from the same-language passage;
when no safe distractor exists, that derived Word Block is not generated.

Each learning Lesson has a dedicated **Lesson GuideBook** available from the Lesson
page. It can store overview text, goals, vocabulary pairs, grammar notes,
expressions and example sentences. Its contents are also the sole source for the
configurable draft-Round generator described above. Planning, generation and
approval remain separate; existing Rounds are never replaced.

Course Audit treats an empty course/Lesson as authoring guidance rather
than a learner-runtime crash. It continues to report invalid answer indices,
missing fields, duplicate IDs, duplicate Audio Match words, malformed Word
Blocks, malformed actual Reading/Listening content, oversized text and other structural
problems. Audit does not certify grammar or translation accuracy.

The Audit can be scoped to a Course, Lesson or Round and sorted by Lesson, friendly Exercise type or Recently modified. Error, Warning and Info are distinct: only Error is structurally blocking. A Lesson with fewer than three Rounds receives Info guidance; missing Reading or Listening comprehension does not. In the Round management page, a pink outline means that Round currently has at least one Audit Error; Warning and Info never add that outline. Orange separately identifies Draft Exercises, and both remain visible together. Audit results refresh after authoring mutations.

## Temporary sample courses
Bundled courses carry a course-level `temporarySample` flag. The UI displays a TEMPORARY SAMPLE badge and Course Editor displays the sample-content warning every time a marked course is opened. Creators can remove or restore the flag from the Course Editor menu. Sample material must be replaced and human-reviewed before publication.

## Preview mode
Round and exercise previews launch the learner renderer but suppress all progress writes, XP, streaks, Review history, unlocks, Status and laurel crowns. A temporary result may be shown and is discarded on exit.

## One-time notice
The first Course Editor opening explains that bundled material is sample content. Settings > Do Not Disturb > Show one-time notices again makes this and future one-time notices eligible to appear again. The learner-level Guidebook availability notice is deliberately separate.

## Course Audit filters and reports
Course Audit can show All, Errors, Warnings or Info without changing the underlying audit result.

**Copy report** copies the complete current Audit result as deterministic plain text. **Export report** writes that same complete result to `Documents/QuisquisLingo/Exports` with a filesystem-safe Course/timestamp filename. Report filtering affects only the visible list: reports retain every Error, Warning and Info plus their stable codes and Course/Lesson/Round/Exercise context. A failed export displays an error and never claims that a file was created.


## Recorded audio

Course Editor > Audio Library supports System TTS, Recorded MP3 only, and Hybrid playback. See `docs/AUDIO_LIBRARY.md`.

**Import MP3** reads all `.mp3` files in `Documents/QuisquisLingo/Imports/Audio`, up to 50 MB (52,428,800 bytes) per file, and copies their original bytes to local support storage grouped by learning language. The metadata and references belong to the Course even though physical files use that language grouping. It reports a missing source set or oversized file; it does not re-encode audio or impose duration, bitrate or sample-rate rules. Preview each imported recording and map it to its exact spoken word or expression. The source files remain in place, so remove them from the transfer folder after a successful import to avoid repeated imports. Course JSON stores metadata and local file paths, not MP3 bytes. Verified course-version backups copy referenced recordings; JSON alone and learner **Export my data** do not transfer course audio. A distributable Audio Pack exporter is future work, not an available authoring action.


## Flat image library (v0.5.7)
The editor can assign, change or remove an optional image on any exercise. Choose from the bundled verified flat WebP assets or import a custom PNG/JPG/WebP. Built-in assets are referenced by path and are not duplicated when reused. Sample courses use images only where they support the task without revealing an answer.

For **Import custom image**, keep exactly one PNG, JPG/JPEG or WebP in `Documents/QuisquisLingo/Imports/Images`. Maximum size is 50 KB (51,200 bytes). The suggested 256 × 256 resolution and 15 KB or less are recommendations, not enforced pixel dimensions. Import checks the extension, file count and byte size, then copies the original bytes to local app storage without decoding, resizing, cropping or changing transparency. Missing/multiple sources and oversized files stop import; Preview reports missing or unreadable images. The source stays in place. Course JSON retains the local image path and does not embed custom exercise image bytes, so these images are not portable through course JSON alone. Image-prompt ordering requires an image; other current presets may omit it.

**Import Image Bank ZIP** uses the same folder and requires exactly one ZIP containing `image_bank_manifest.json` as a JSON list and its referenced PNG/JPG/JPEG/WebP assets. Each entry needs a unique `id`, `primary_term` or `label`, and a safe `filename`. Limits are 50 MB ZIP, 2 MB manifest, 5000 archive entries, 2500 image entries, 50 KB per image and 50 MB total decompressed image bytes. Import rejects missing files, duplicate/colliding IDs, duplicate filenames, unsafe paths, unsupported extensions and exceeded limits. It copies unchanged image bytes and a local manifest to app storage. It does not normalize dimensions or transparency, and imported bank image paths in course JSON are still device-local. Keep the original bank package separately; the source ZIP is not deleted by import.


## Missing Word
Course Editor supports `missing_word` exercises. Enter the complete passage transcript, the audio text, and one or more words/expressions to hide. Learner mode plays TTS/recorded/hybrid course audio, shows the transcript with blanks, and enables Check as soon as at least one answer field contains text. Course Audit verifies that every hidden word occurs in the transcript and that audio text is present.


## Small-screen authoring

Course Editor dialogs and author rows are designed to stack vertically on narrow screens. Long labels, custom roles, course metadata and audit messages must remain scrollable and must not require a desktop-width window. Test the editor at approximately 320 logical pixels wide and with enlarged system text before release.

## Audit and edge cases

Course Audit should be run after structural edits and before distribution. It checks IDs, Round structure, exercise invariants, the actual Lesson-local Duel eligible pool, suspicious duplicate content, early Opposite exercises, isolated-word capitalization, author metadata, long descriptions and malformed `lastUpdated` dates. Audit codes are stable identifiers for reporting a rule even if its explanatory text changes.


## 0.7.3 Course Info roles and languages

Course Info displays Source language and Target language as read-only values. They identify the language used for learner instructions/support and the language being learned. Editing these values is deliberately disabled for now because changing them can affect TTS, instructions, course validation and content semantics.

An author can have multiple roles. Course Creator means original creation/design of a substantial part of the course; Editor means ongoing maintenance or substantial revision of existing content; Contributor means a specific or limited contribution. Team Leader coordinates the team and can be combined with other roles. Reviewer, Native Speaker and Audio Contributor describe narrower contributions. Custom roles are allowed. Roles describe contributions, not hierarchy.

## Alpha expiry and authoring

The current time-limited alpha expires on 2026-10-05. Expiry blocks learner exercises and Review but deliberately leaves Course Editor available so authoring work can be inspected, recovered and exported. Expiry never deletes local data.


## Bundled official and local courses

The Course Editor entry screen identifies bundled official sources and groups stored custom or external-official installations under **Local courses**. A created or ordinarily imported course remains custom even when it is currently selected. Temporary sample material refers to bundled sample courses supplied with early/current development builds and is progressively replaced by reviewed course content. A newly created custom course starts as an unpersisted working copy with 3 placeholder Lessons, each with a stable Lesson-scoped Duel identity, and no automatic Rounds. Its first **Confirm course changes** creates internal version 1; cancellation leaves no stored course.

When creating a custom course, the author can use one of QuisquisLingo's existing flags or import a PNG/JPG image. Imported flags are checked for file size and resolution. Images that are too small or excessively large are rejected; accepted large images are resized to a maximum 256 px longest side while preserving their aspect ratio. The processed PNG is stored with the course so it remains available if the original file is moved or deleted.

Courses can be imported from and exported to `.json` files without a file chooser. For import, copy the course file to `Documents/QuisquisLingo/Exports/import.json`, then press **Import course JSON**. The imported course is added under **Local courses** and `import.json` is left in place. Course Audit errors block import; warnings are reported for review but do not block it. Imports must be UTF-8 Course Model v6 JSON and are validated through the normal `Course` parser. v5 and older formats are unsupported and are not read, migrated, converted or deleted; export writes the canonical v6 structure. Files larger than 10 MB are refused. Origin collisions are handled explicitly: custom content cannot overwrite an official identity, and external official replacements require the same course ID and declared publisher ID, a newer official version and a valid content checksum. Publisher authenticity remains unverified in Build 226.01 file imports; installation requires the explicit unverified-publisher warning described above. Exports contain the complete canonical v6 object, including origin/version metadata and optional custom flag data. Learner **Export my data** remains separate and does not contain courses.


### Home course selection and navigation

The compact flag in the Home Top Bar opens the full-size course selector, which lists bundled courses and every locally available custom course, including courses created in the editor and courses imported from JSON. Selecting one makes it the current course. The unified learner page resumes the active learner at the last Lesson opened in that specific course; first use falls back to Lesson 1. When real Section metadata exists, the fixed Section selector opens the ordered consecutive Section blocks and jumps to each block's first Lesson; consecutive unsectioned runs appear only in that UI as `Other lessons`. Courses with no real Sections show no Section selector. Back from a Round returns directly to the unified Home learner page.

### Copy edits as JSON vs Export course JSON

**Copy edits as JSON** copies the current working Course Model v6 object to the clipboard and does not create a file. **Export course JSON** writes a complete portable Course Model v6 JSON file to `Documents/QuisquisLingo/Exports`. Neither action confirms or persists the editing transaction.

When `Documents/QuisquisLingo/Exports/import.json` is imported successfully, QuisquisLingo validates it and lists it under **Local courses**. The stored course no longer depends on `import.json`; the transfer file is left in place. The stable `courseId` identifies the course internally. Course Info remains available even when the course content is locked. Renaming the visible Course name in Course Info does not change `courseId`; the Lock protects structural/content editing, not course metadata.

### Custom course flags

Custom flag import also avoids desktop file choosers. Copy a PNG or JPEG flag image to `Documents/QuisquisLingo/Exports/` and name it `flag.png`, `flag.jpg`, or `flag.jpeg`, then press **Import flag** in **Create new course**. If multiple supported names exist, the first in that order wins. The input must be no larger than 2 MB (2,097,152 bytes), at least 64 × 40 pixels, and at most 8192 pixels on either side. QQL checks the actual PNG/JPEG signature, decodes the first frame and reduces large images to at most 256 pixels on the longest side while preserving proportions; smaller accepted images are not enlarged. There is no square canvas or cropping. Existing PNG transparency is retained, while JPEG keeps its opaque background. The result is embedded base64 PNG in the Course and survives course JSON export/import, backups and duplication without the original source. Import leaves the source in place. Missing, empty, unsupported, unreadable, oversized, too-small or over-resolution images and failed PNG conversion produce errors. Course JSON import separately checks the embedded flag's base64 validity and its 1 MB encoded-data safety limit.


## Fixed authoring import folders (1.1.8)

To avoid desktop file-picker and portal dependencies, creator media imports use fixed folders under the user's Documents directory:

- Images and Image Bank ZIPs: `Documents/QuisquisLingo/Imports/Images`
- Recorded MP3 files: `Documents/QuisquisLingo/Imports/Audio`
- Custom Lesson icons: `Documents/QuisquisLingo/Imports/Lesson Icons`
- Custom course flags: `Documents/QuisquisLingo/Exports` with the exact supported flag filename

For a single-image import, keep exactly one supported image file in the Images folder. For an Image Bank package, keep exactly one ZIP in that folder. Audio Library imports every MP3 currently present in the Audio folder. Source files are not deleted automatically.
