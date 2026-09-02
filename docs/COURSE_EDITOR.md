# QuisquisLingo Course Editor

Updated for current Course Model v4 editor (2.0.22+222)

## Unlocking the editor

Course Editor is an Easter Egg so ordinary learners do not encounter authoring controls accidentally. Open **Settings** and tap/click **the displayed QuisquisLingo version** ten times within about five seconds. `Course Editor unlocked` appears and the Course Editor entry becomes visible. The unlock state is stored locally on the device.

## Editable hierarchy

The editor supports the whole authoring tree:

- Course → create/delete/reorder Topics
- Topic → edit its Guidebook and image, and create/delete/reorder Rounds; a stable Duel identity is retained automatically
- Round → create/delete/reorder Exercises

New objects receive generated local IDs. Deleting an object removes its descendants from the local edited course. The bundled JSON asset is never modified. **Reset local edits** restores the bundled course.

Rounds normally contain 15 exercises. The editor does not enforce 15 as a hard maximum. Course Audit reports unusually short or long rounds so the author can review them.

## Exercise type is immutable

Choose the exercise type only when creating an exercise. Once created, the type is locked. This prevents stale fields from one type being reinterpreted as another. To replace a type, create a new exercise, copy/adapt the content, then delete the old exercise.

The editor displays only fields used by the current exercise type. Examples:

- Flashcard: Word/expression, Translation/meaning, Pronunciation TTS, Usage sentence
- Reading comprehension: Reading passage, Comprehension question, Answers, Correct answer
- Listening comprehension: Spoken passage, Comprehension question, Answers, Correct answer
- Word Blocks: Translation prompt, Available word blocks, Correct sentence
- Audio Match: Three sound matches and five visible choices

Technical fields such as numeric JSON indices are minimized. Correct choice remains an author-facing answer number for compact editing.

## Word Blocks

A valid Word Block exercise may have 0, 1 or at most 2 extra distractor blocks. The correct sentence is reconstructed from the required block occurrences. Repeated words are counted by occurrence, not only by distinct spelling. Early Topic rounds should normally use fewer distractors and later rounds may use more.

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
- Suggestion: quality/review recommendation

Checks include:

- duplicate or missing IDs
- empty courses/topics/rounds
- round length versus the standard 15
- missing Reading or Listening comprehension in a round
- unsupported exercise types
- missing/out-of-range correct answers
- duplicate/blank options
- listening exercises without TTS
- very short comprehension passages
- hint contains an accepted answer
- Word Blocks with more than two distractors or with impossible token counts
- Flashcards without usage or pronunciation
- Audio Match repeated sounds, repeated correct matches, repeated visible choices, missing matches, or unusual 3/5 cardinality
- icon/answer count mismatch
- fields that do not belong to the selected exercise type
- likely source/target capitalization inconsistency
- repeated prompt/question inside one round
- unavailable Topic Duels after applying the actual eligibility rules

Audit does not certify grammar, translation accuracy, cultural appropriateness or teaching quality. Those remain human editorial responsibilities.

A Topic with fewer than six Rounds receives author guidance only. Duel availability never depends on Round count: fewer than 25 actual eligible Topic exercises produces a non-blocking `DUEL_UNAVAILABLE` suggestion and is normal supported behavior.

## Storage and recovery

Local edited courses are stored separately from bundled assets. A complete course override is validated structurally before saving and before learner use. Corrupt local authoring JSON is backed up and ignored instead of crashing course loading. Local authoring data has a 8 MB safety limit.

**Copy edits as JSON** exports the local authoring override to the clipboard. **Reset local edits** removes it.

## Word Blocks language rule (0.4.25)

A Word Blocks exercise may contain 0, 1 or at most 2 extra distractor blocks. Every distractor must be in the same language as the other visible blocks. This is determined by the language of the answer blocks, not simply by the course target language, because translation exercises can run in either direction.

The bundled-course validator builds conservative source/target lexicons from explicitly oriented matching pairs and flashcards and reports high-confidence cross-language distractors. The in-app audit validates the structural invariant of 0 to 2 usable extra blocks. Language identification is intentionally conservative: ambiguous words shared by two languages must not be auto-rejected solely on spelling.

Capitalization should be consistent across paired sentences and expressions while preserving language-specific orthography, especially German noun capitalization.

## 0.5 authoring behavior

Course Editor is an unlockable Creator mode inside the same QuisquisLingo app. Tap
or click the version label 10 times within about five seconds to unlock it. The
Duel victory sound confirms the unlock when sound effects are enabled.

The editor can work with an entirely empty course. An empty course shows
**Create first Chapter** rather than failing. Chapters, Topics, Rounds and
Exercises can be created, deleted and reordered within their parent. Every learning
Topic has its own editable Guidebook; Chapters no longer have Guidebooks. Deletions require confirmation. Exercise type is selected only at
creation time and cannot be changed afterwards; create a replacement exercise
when a different type is needed.

Word Blocks may contain 0, 1 or at most 2 extra distractors in the same
language as the blocks. The learner is expected to leave any distractor blocks
unused. Early Topic rounds should normally use fewer distractors than later ones.

A Reading comprehension exercise can optionally generate a linked draft set:
Listening comprehension, Audio Match, translation exercises and Word Blocks.
Generation is opt-in and previews the drafts before insertion. Automatically
generated Word Blocks only take a distractor from the same-language passage;
when no safe distractor exists, that derived Word Block is not generated.

Each learning Topic has a dedicated **Topic Guidebook** available from the Topic page.
It can store overview text, goals, vocabulary pairs, grammar notes, expressions and
example sentences. Its contents are also authoring source material. In the Topic
Editor, **Generate 3 Rounds from Guidebook** proposes three progressively harder
Rounds using only the Topic Guidebook vocabulary and examples. Suitable material
and choice order are randomized, exact duplicate exercises are avoided, and Round 1
starts with a short non-exercise `topic_intro` Content item containing essential
Guidebook information plus a reminder to read the Topic Guidebook for more. All
three Rounds are previewed and audited first. They are created only after explicit
author approval and remain fully editable afterwards.

Course Audit treats an empty course/Chapter/Topic as an authoring warning rather
than a learner-runtime crash. It continues to report invalid answer indices,
missing fields, duplicate IDs, duplicate Audio Match words, malformed Word
Blocks, missing Reading/Listening coverage, oversized text and other structural
problems. Audit does not certify grammar or translation accuracy.

## Temporary sample courses
Bundled courses carry a course-level `temporarySample` flag. The UI displays a TEMPORARY SAMPLE badge and Course Editor displays the sample-content warning every time a marked course is opened. Creators can remove or restore the flag from the Course Editor menu. Sample material must be replaced and human-reviewed before publication.

## Preview mode
Round and exercise previews launch the learner renderer but suppress all progress writes, XP, streaks, Review history, unlocks, Status and laurel crowns. A temporary result may be shown and is discarded on exit.

## One-time notice
The first Course Editor opening explains that bundled material is sample content. Settings > Do Not Disturb > Show one-time notices again makes this and future one-time notices eligible to appear again. The learner-level Guidebook availability notice is deliberately separate.

## Course Audit filters
Course Audit can show All, Errors, Warnings or Suggestions without changing the underlying audit result.


## Recorded audio

Course Editor > Audio Library supports System TTS, Recorded MP3 only, and Hybrid playback. See `docs/AUDIO_LIBRARY.md`.


## Flat image library (v0.5.7)
The editor can assign, change or remove an optional image on any exercise. Choose from the bundled verified flat WebP assets or import a custom PNG/JPG/WebP. Built-in assets are referenced by path and are not duplicated when reused. Sample courses use images only where they support the task without revealing an answer.


## Missing Word
Course Editor supports `missing_word` exercises. Enter the complete passage transcript, the audio text, and one or more words/expressions to hide. Learner mode plays TTS/recorded/hybrid course audio, shows the transcript with blanks, and enables Check as soon as at least one answer field contains text. Course Audit verifies that every hidden word occurs in the transcript and that audio text is present.


## Small-screen authoring

Course Editor dialogs and author rows are designed to stack vertically on narrow screens. Long labels, custom roles, course metadata and audit messages must remain scrollable and must not require a desktop-width window. Test the editor at approximately 320 logical pixels wide and with enlarged system text before release.

## Audit and edge cases

Course Audit should be run after structural edits and before distribution. It checks IDs, Round structure, exercise invariants, the actual Topic-local Duel eligible pool, suspicious duplicate content, early Opposite exercises, isolated-word capitalization, author metadata, long descriptions and malformed `lastUpdated` dates. Audit codes are stable identifiers for reporting a rule even if its explanatory text changes.


## 0.7.3 Course Info roles and languages

Course Info displays Source language and Target language as read-only values. They identify the language used for learner instructions/support and the language being learned. Editing these values is deliberately disabled for now because changing them can affect TTS, instructions, course validation and content semantics.

An author can have multiple roles. Course Creator means original creation/design of a substantial part of the course; Editor means ongoing maintenance or substantial revision of existing content; Contributor means a specific or limited contribution. Team Leader coordinates the team and can be combined with other roles. Reviewer, Native Speaker and Audio Contributor describe narrower contributions. Custom roles are allowed. Roles describe contributions, not hierarchy.

## Alpha expiry and authoring

The current time-limited alpha expires on 2026-10-02. Expiry blocks learner exercises and Review but deliberately leaves Course Editor available so authoring work can be inspected, recovered and exported. Expiry never deletes local data.


## Current bundled course and My custom courses

The Course Editor entry screen separates the **Current bundled course** from **My custom courses**. A created or imported custom course remains custom even when it is the currently selected course and is never duplicated under Current bundled course. Temporary sample material refers to bundled sample courses supplied with early/current development builds and is progressively replaced by reviewed course content. A newly created custom course starts from a basic Course Model v4 authoring skeleton: 3 placeholder Topics, each with a stable Topic-scoped Duel identity. No Rounds are created automatically.

When creating a custom course, the author can use one of QuisquisLingo's existing flags or import a PNG/JPG image. Imported flags are checked for file size and resolution. Images that are too small or excessively large are rejected; accepted large images are resized to a maximum 256 px longest side while preserving their aspect ratio. The processed PNG is stored with the course so it remains available if the original file is moved or deleted.

Custom courses can be imported from and exported to `.json` files without a file chooser. For import, copy the course file to `Documents/QuisquisLingo/Exports/import.json`, then press **Import course JSON**. The imported course is added under **My custom courses** and `import.json` is left in place. Course Audit errors block import; warnings are reported for review but do not block it. Imports must be UTF-8 Course Model v4 JSON and are validated through the normal `Course` parser. Older Chapter-based formats are unsupported and are not read, migrated or converted; export writes the canonical v4 structure. Files larger than 10 MB are refused. An imported course with the same stable `courseId` as an existing custom course requires confirmation before replacement. Exports are written to the same `Documents/QuisquisLingo/Exports` directory and contain the canonical human-readable Course Model v4 object, including optional custom flag data. Learner **Export my data** remains separate and does not contain custom courses.


### Home course selection and navigation

The compact flag in the Home Top Bar opens the full-size course selector, which lists bundled courses and every locally available custom course, including courses created in the editor and courses imported from JSON. Selecting one makes it the current course. The unified learner page resumes the active learner at the last Lesson opened in that specific course; first use falls back to Lesson 1. The separate Lesson selector opens the complete Lesson picker without an intermediate hierarchy screen, and Back from a Round returns directly to the unified Home learner page.

### Copy edits as JSON vs Export course JSON

**Copy edits as JSON** is for the Current bundled course. Bundled assets are not rewritten; the editor stores a local override, and this command copies that override JSON to the clipboard. It does not create a file. **Export course JSON** is for a custom course and writes a complete portable Course Model v4 JSON file to `Documents/QuisquisLingo/Exports`.

When `Documents/QuisquisLingo/Exports/import.json` is imported successfully, QuisquisLingo validates it, copies the course into local custom-course storage and lists it under **My custom courses**. The stored course no longer depends on `import.json`; the transfer file is left in place. The stable `courseId` identifies the course internally. Course Info remains available even when the course content is locked. Renaming the visible Course name in Course Info does not change `courseId`; the Lock protects structural/content editing, not course metadata. Importing another JSON with the same `courseId` therefore requires confirmation before replacing the existing custom course.

### Custom course flags

Custom flag import also avoids desktop file choosers. Copy a PNG or JPEG flag image to `Documents/QuisquisLingo/Exports/` and name it `flag.png`, `flag.jpg`, or `flag.jpeg`, then press **Import flag** in **Create new course**. QuisquisLingo accepts up to 2 MB, requires at least 64×40 pixels, checks the actual PNG/JPEG signature, and resizes large images to at most 256 pixels on the longest side while preserving proportions.


## Fixed authoring import folders (1.1.8)

To avoid desktop file-picker and portal dependencies, creator media imports use fixed folders under the user's Documents directory:

- Images and Image Bank ZIPs: `Documents/QuisquisLingo/Imports/Images`
- Recorded MP3 files: `Documents/QuisquisLingo/Imports/Audio`

For a single-image import, keep exactly one supported image file in the Images folder. For an Image Bank package, keep exactly one ZIP in that folder. Audio Library imports every MP3 currently present in the Audio folder. Source files are not deleted automatically.
