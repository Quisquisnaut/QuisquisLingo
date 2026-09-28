# QuisquisLingo Build 256 — exercise architecture redesign (Course Model v12)

Branch `claude/256-exercise-architecture`, created from `main` at
`611a1a1` (Build 255 handoff: merged through PR #26, Windows package 255007)
on 27 September 2026. Sessions 1–6 are Build 256 Revisions 0–5
(`2.0.56+256000` … `2.0.56+256005`), one local commit each.

Part A holds the owner's decisions (verbatim from the start prompt, plus the
decisions taken at the start of the work, §A.14). Part B is the agreed session
plan. Part C holds the audit notes from the planning session, verified against
the Build 255 tree. Part D condenses the original task specification. Where
Part A or B differs from Part D, A and B win. Where this plan differs from
`AGENTS.md` for this work, this plan wins.

Running record: `docs/256_HANDOFF.md`. Evidence: `docs/256_VALIDATION.md`.
Change summary: `docs/256_CHANGE_SUMMARY.md`.

## PART A — Decisions

### A.1 Process
- Sessions 1–6 are Build 256 Revisions 0–5: `2.0.56+256000` … `2.0.56+256005`.
- Every revision is a delivered version: version bump (pubspec.yaml, lib/services/app_metadata.dart and the other touchpoints in docs/NEW_EXERCISE_TYPE_CHECKLIST.md §10, including tests that hard-code version strings); Beta expiry 30 days after that revision's date, 23:59:59 local time (lib/services/beta_lifecycle_service.dart, its tests, README, current docs); CHANGELOG.md; docs/256_CHANGE_SUMMARY.md, docs/256_VALIDATION.md, docs/256_HANDOFF.md; one concise AGENTS.md "Current release boundary" entry.
- End of every session: `dart format`, `flutter analyze`, focused tests, then the complete `flutter test` suite once (Windows keep-awake per AGENTS.md; always the path spelling `C:\QQL\QuisquisLingo`). Then write the six-part session report in plain language, update the handoff, make one local commit "Build 256 Revision N: …" (never push), and start the next session immediately. This replaces Part D's rules against committing and against starting the next session automatically.
- Stop and ask me only when (a) a test or analyzer failure can't be fixed within the session's scope, (b) a decision comes up that Part A doesn't cover and that could change behavior, saved data, scoring or compatibility, or (c) a step would need something Part A rules out. When you stop, say so plainly at the top of your message.
- Update the handoff after every commit and at least every 30 minutes, so a new session can resume from it alone.
- Report failures honestly; never weaken tests or validation to get a pass.

### A.2 What learners can play by the final session (Session 8 after the 28 September renumbering)
- Exactly today's behaviors plus Assign. Every other legal combination is valid but not yet executable: Speak, Ink, Submit; Input number/range/tolerance/regex/manual; Select subset/orderedSelections, textSpans/regions/cells, evaluationTiming onCompletion; Match one-to-many/many-to-one/many-to-many, connect/memory; Arrange grid; and similar.
- Executability is computed per exercise (primitive + options + evaluation mode) from a runtime-support table in the capability registry. It is never stored in Course data.

### A.3 Preset metadata never changes behavior (strict)
- Nothing learners see may read preset or authoring metadata: rendering, grading, feedback, audio, playability, Duel eligibility, search, Audit validity.
- Learner headings and instructions (today `ExerciseCopyService`, 8 languages, keyed by preset) are derived from canonical features, e.g. Select with required automatic audio → "Listen and choose"; combinations without a specific label get the generic one. Existing Courses must look the same because their converted data describes the same features.
- Session 3's report of preset-dependent runtime branches must be empty. If one can't be removed within scope, stop and ask.

### A.4 Extra canonical fields (approved; final names in the Session 1 report)
These keep today's preset-only behaviors once presets are gone:
- Media and text elements: `playback` automatic|manual (listening presets autoplay today); `required` true|false (today any exercise with spoken prompt text is skipped when audio is unavailable, except Pick the translation, where audio is optional); text `language` source|target (drives Pick the translation's instruction and its optional target-language audio).
- Input: `accentHandling` with three values: exact (strict, new), missing-accents-accepted (today's default and the value for every converted exercise: "citta" is accepted for "città" when the learner typed no accent at all), ignore. Extra literal answers (today fill_blank, listening_spelling and type_translation also accept the spoken prompt text literally). First-grapheme reveal on a target (type_missing_word). `typoTolerance` conservative for type_translation and type_missing_word.
- Feedback: ranked alternative answers (type_translation: up to 3 when wrong, 2 when right); show all accepted answers (build_translation); completed-sentence display (type_missing_word).
- Arrange: a joiner (image_word joins blocks without spaces) or content-sequence evaluation.
- Match: explicit item side (left|right); v11 implies it from pair order.
- Select layouts: list | grid | inline.
- Regions: normalized rectangles on one referenced image.

### A.5 Audit severity
- Errors (which block import, publishing and learner play) only for invalid canonical data: unknown or illegal values, illegal combinations, illegal primitive/evaluation pairing, broken item/target/layout references, impossible selection limits (exactSet: minimumSelections ≤ correctCount ≤ maximumSelections ≤ itemCount), missing required values.
- Preset rules (Dialogue response exactly 2 answers; Match the words, Match related words and Listen and match exactly 3 pairs; Pick the translation at most 5 options; Image-prompt ordering no extra blocks; and similar) become a non-blocking Warning "does not match its preset". The editor clears the metadata on the next edit.
- AGENTS.md content rules (Arrange 0–2 unused blocks; a hint must not reveal the answer) keep today's severity but apply to every exercise by its content, with or without a preset.
- An unknown preset ID is preserved and never blocks anything (today EXERCISE_PRESET_UNKNOWN is an Error).

### A.6 Exercises that can't run yet
- One Info finding per exercise ("learners using this version skip this …; it is kept, editable and exported unchanged"). The import dialog adds one line counting them.
- Practice Rounds: they are removed at the same step where invalid and unpublished exercises are removed (`RoundPlayabilityService`), before the audio filter. They are not in the queue, the mistake review or "Correct answers x/y", and give no XP. One line in the Round-completed dialog counts them.
- Laurel: reuse today's audio-skip rule (`LearningCompletionService`; stored key `v4_tts_skipped_perfect_rounds` unchanged, no new key). Zero errors with something skipped gives the "skipped perfect" mark, not the Laurel; a later full attempt can earn the Laurel; the +5 perfect bonus is unchanged.
- A Round-level Warning when learners can't complete a Round or Story in this version. Unlock rules are unchanged.
- Stories: a card replaces the exercise (its prompt read-only, one sentence, Continue) and follows the node's `next`. With no `next`, the Story ends there and nothing is recorded. Preview shows the same card, in practice Rounds too.
- The Duel never includes them; Review behaves like practice Rounds.

### A.7 Stories and content flow
- A Story is a Round whose flow delivery is authored sequence. It keeps Round IDs, completion, the normal Round XP rules, Review, Laurels and Lesson completion. It is not shuffled and has no end-of-Round mistake review.
- A Round without an explicit flow is today's practice Round: lesson_intro first ("Before you start"), then shuffled exercises, then the mistake review.
- Linear Story playback from Session 3. Branch transitions (onCorrect, onIncorrect, onChoice, conditional) are modeled, validated and tested with a stand-alone flow engine in Sessions 5–6, but not played. A Story that contains them counts as "can't run yet" at Round level.

### A.8 v11 → v12: clean cut
- The app reads only v12. v11 files and folders stay untouched and unread; the unsupported-format message names the conversion tool.
- New storage `qql_courses_v3` and `Course Backups v12`, added to `AppResetService`, `InventoryService` and docs/239_RESET_STORAGE_INVENTORY.md. Version History starts fresh. *(Superseded by §A.14: the Build 255 names are the starting point.)*
- One converter library in `lib/`, kept free of Flutter imports so `dart run` works, used by `tools/convert_course_to_v12.dart INPUT OUTPUT [--overwrite]` (model: tools/convert_course_to_v11.dart). It accepts a Course ZIP (keeps the media and regenerates the package manifest from the converted Course) or plain Course JSON, never modifies the input, lists anything it can't convert exactly, and strips Publisher signatures (re-sign with tools/sign_course.dart).
- In the repo: convert the 10 bundled Courses (new official checksums); update tools/generate_*_254.py, tools/validate_courses.py, the Publisher test fixtures (re-signed), docs/COURSE_JSON_FORMAT.md, and the EN/IT/ES Help that names the format (one line still says "writes formatVersion: 9"). *(Build 255 Revision 6 left 4 bundled Courses; see Part C.)*
- Document the user workflow (export from the old version → convert → Quick Import) in docs and in the Session 2 report.

### A.9 AGENTS.md
- In Session 2, rewrite the "Course Model v11 invariants" section for v12 (primitives, options, presets as optional metadata, content flow, clean cut, capability registry). Each session adds one release-boundary entry.

### A.10 Duel (Session 3)
- Capability-based: every single-answer Select (single selection, items shown as choices, exactItem) is eligible, including Contextual comprehension and Recognize characters, drawn by the same Select renderer as Rounds (context panels, dialogue, image answers).
- Multiple-answer Choose leaves the pool, which fixes a bug: today the Duel grades it as single-answer.
- Report the changed Duel availability in the CHANGELOG and the session report.

### A.11 Arrange grading (Session 3)
- Blocks with identical content become interchangeable when grading inline-gap Arrange. Today it compares block IDs, so in the Laboratory's arrange_gap_repeat a visibly correct answer can be marked wrong. This is a deliberate, reported behavior change.

### A.12 Help and Laboratory
- The new Help chapters (Primitives, Primitive options, Layouts, Evaluation modes, Presets) are written in EN, IT and ES; test/localization_catalog_test.dart enforces key parity. Command and button names stay English inside IT and ES text.
- The Laboratory is reorganized by primitive × option combination. Speak, Ink, Submit and branching Stories go in a test-only fixture Course written by the same generator. The bundled Laboratory stays fully playable, and Assign joins it in Session 6.

### A.13 Defaults
- The primitive is locked after an exercise is created.
- Semantic equality includes IDs and item order, ignores authoring metadata, timestamps and publication state, and treats an omitted option as its default.
- Unknown preset metadata is preserved through import, export and copy, and cleared when the exercise's canonical content is edited in QQL. Editor dirty state still counts metadata-only changes.
- Exact preset recognition: the preset's form can represent the exercise with nothing lost (decompose → rebuild → semantically equal). Recognition never writes.
- The capability description is a JSON generated by a Dart tool into docs/, with a drift test; tools/validate_courses.py reads it instead of keeping its own lists.
- The v11 shapes (`Exercise(...)`, `Exercise.v2`, `ExerciseInteraction`, `ExerciseEvaluation`) survive only as converter input and test-construction helpers (72 test files use `Exercise(...)`, 31 use the v11 classes). The runtime uses only v12.

### A.14 Decisions taken at the start (27 September 2026)
Asked and answered before the branch was created.

- **v12 storage (Option 2 of three).** Stored Courses move to a new private
  folder, `QQL_Courses_v12/Custom|Publisher` (Build 255's `QQL_Courses` stays
  untouched and unread, is listed by Inventory as an earlier folder and is
  removed by Wipe everything). Course Backups **keep** the public folder
  `Documents/QuisquisLingo/Backups/Courses` and the per-Course folder names;
  the backup manifest format becomes v12, and Version History lists a v11
  backup as unreadable (format 11) instead of starting fresh. No Help text
  about the Backups folder changes. The reasons the owner weighed: the
  Backups folder is user-facing and documented; an unreadable entry is honest
  and consistent with Build 255 Revision 5; the private folder is never seen.
  Media folders (`QQL_CourseMedia`) are keyed by Course ID and do not move.
- **Owner data.** Besides `tools/convert_course_to_v12.dart`, a one-off tool
  `tools/convert_stored_courses_256.dart` converts every custom Course from
  the Build 255 private folder into the v12 one, never overwriting or
  deleting, and reports what it could not convert. Publisher Courses are not
  converted because conversion strips their signature; they must be
  re-imported signed.
- **Assumptions stated, not asked.** The Course package manifest keeps
  `packageFormat: 1` (only `course.json` inside changes to v12; a format
  change would be an owner decision). The bundled Courses are the 4 left by
  Build 255 Revision 6. The canonical runtime class keeps the name `Exercise`
  with v12 internals; the v11 unnamed constructor survives as a helper that
  builds v12 data through the converter's mapping rules, so the 72 test files
  keep compiling while the runtime reads only v12 data.

## PART B — Session plan
1. **Canonical definitions** (no JSON or behavior change).
   - `lib/models/canonical/`: `ExercisePrimitive` (nine values, strict parsing), typed options, `EvaluationMode`, and `PrimitiveCapabilityRegistry`. The registry holds per-primitive value sets for shared keys such as placementMode, layout, itemReuse and evaluationTiming; defaults; required values; illegal combinations; evaluation implications; the runtime-support table; and coded violations that the Audit, editor and import will reuse.
   - Content-flow nodes and transitions with structural checks.
   - `ExercisePreset.model` becomes `ExercisePrimitive`.
   - New docs/EXERCISE_ARCHITECTURE_V12.md; mark docs/EXERCISE_ARCHITECTURE_224.md historical.
   - Report the exact field list for A.4.
2. **Course Model v12.**
   - Canonical serialization, with `authoringMetadata` replacing Content `editorTemplate`; Round flow; Presentation as a primitive; neutral names replacing `arrangeLayout`/`arrangeGapAssignments` at every call site; semantic equality.
   - Converter and tool; storage cut (A.8, A.14); ID remapping in duplication and copy; every media walker covering the new references.
   - Bundled Courses, generators, validator, fixtures, AGENTS.md.
   - Temporary read-only compatibility views keep runtime, Audit and editor behavior unchanged until Sessions 3–4.
3. **Runtime and Audit on canonical data.**
   - First extend the Laboratory widget test to record what each example shows (instruction, prompt panels, controls, feedback).
   - Then refactor Select → Input → Arrange → Match → Presentation, plus the Duel screen, with focused tests after each: prompt drawn by role, audio from media flags, feedback from `feedback`, one inline-layout path.
   - Rounds run as flows.
   - Audit through the registry (A.5), with new codes and the pinned code count updated.
   - A.10 and A.11.
4. **Presets as recipes, and the Generic Primitive Editor.**
   - New files, not inside course_editor_screen.dart; controls and values from the registry.
   - Exact recognition, metadata clearing, View only and Inspection.
   - Help (A.12); Round editor for content nodes and Story order.
5. **Preset catalogue** (added 27 September 2026 by owner decision; `docs/256_PRESET_CATALOGUE_PLAN.md`).
   - Merges, renames, new presets, to-target/to-source pairs, greyed future presets, the skill-grouped picker with the direction filter, and the save guard against unchanged example content.
   - The small runtime changes the new presets need (within-word Input gap, word tiles without a picture, picture left items in Match).
6. **Stories** (added 28 September 2026 by owner decision; `docs/256_STORY_PLAN.md`). Delivered as Revision 5 (`2.0.56+256005`, 28 September 2026).
   - Narrator and reusable characters with avatars and voice preferences; the Dialogue line and Story cover presets; the Story options (title, scrolling, filtered dialogue log, read-aloud); the Story Wizard; Story exercises out of the Duel pool; lines never skipped when audio is unavailable.
7. **Interoperability.**
   - Canonical import and interoperability mappings, with the preset only as a hint.
   - The four support states and A.6.
   - Conditional transitions and the flow engine.
   - The service sweep from Part D; the capability JSON tool; end-to-end tests.
8. **Laboratory, Assign, final verification.**
   - Laboratory by primitive and options, plus the fixture Course; negative tests.
   - Assign runtime (categories, slots, gaps, regions if the overlay fits; capacity single/multiple; reuse forbidden/allowed; exactAssignments) with Generic Primitive Editor support.
   - Story tests; semantic-equality tests; the final verification list.

## PART C — Audit notes, verified on 27 September 2026
Line numbers are approximate. Corrections after Build 255 are marked **(255)**.

- **Exercise model**, lib/models/course_models.dart (3,520 lines):
  - `Exercise` (~2774): v11 unnamed constructor maps a preset `type` through `_legacyPrompt`/`_legacyInteraction`/`_legacyEvaluation` (~3104–3406); `Exercise.v2`; `toV2Json`/`fromV2Json` (the Content's `id`, `editorTemplate` and `publicationState` are passed in); derived getters `type`, `prompt`, `question`, `tts`, `answers`, `correct`, `accepted`, `tokens`, `arrangeLayout`, `arrangeGapAssignments`, `hasArrangeGaps`, `isMultiSelect`, `contextMode`.
  - `ExerciseInteraction` (~2640): free-string `kind`, `inputType`, `minSelections`/`maxSelections`, `items`, `layout` (text/gap elements).
  - `ExerciseEvaluation` (~2701): `kind` selected_items | text_match | ordered_items | matched_items (the Edge Case Course also uses gap_items), `correctItemIds`, `acceptedAnswers`, `correctOrders`, `pairs`, `normalization`, `gapAssignments`.
  - `LearningContent` (~2124): `kind` exercise | presentation | explanation | example | vocabulary | text | dialogue (validator also lists image, audio), `role` (lesson_intro, round_note), `editorTemplate`, `required`, `sourceRefs`; `asRunnableExercise` projects presentations and textual kinds into a flashcard-shaped `Exercise`.
  - `Presentation` (~2266): content elements by role (term, meaning, usage, usage_translation, audio) and completion actions.
  - `_legacyTypeFromTemplate`: an unknown interaction kind silently becomes `choice`.
- **Presets**: lib/models/exercise_authoring.dart (280 lines; 24 presets → 5 `CanonicalExerciseModel` values, `helpByPreset`); Help keys in lib/localization/help/help_structure.dart; `ExerciseHelpScreen` in lib/screens/editor_help_screen.dart.
- **Learner runtime**, lib/screens/round_screen.dart (2,940 lines, 51 preset references): `_exerciseBody` switch on `ex.type` (~2451), a second switch (~713), `_isListeningExercise` (~539), typo tolerance (~960), spoken prompt text accepted literally (~949), inline gaps (~1373–1856), Arrange graded by ID (~1779). The Round shuffles its queue and adds a mistake-review pass; the evaluable count is taken before the audio filter.
- **Duel and related services**: lib/screens/duel_screen.dart (734 lines) grades only `ex.correct` (~181). Also audio_exercise_availability_service.dart, exercise_copy_service.dart (en, es, it, de, pt, nl, fi, cy), translation_choice_service.dart, first_letter_answer_service.dart, round_playability_service.dart, learning_completion_service.dart, answer_engine.dart (missing-diacritic tolerance even when accents are "preserve"; ’→' normalization; bounded typo rule).
- **Audit**: lib/services/course_audit_service.dart (2,036 lines): `auditExercise` (~1203); the multi-select check (~1457) misses impossible limits. lib/services/audit_code_registry.dart: 104 codes, count pinned in test/audit_branch_ownership_226_02_revision4_test.dart line 212.
- **Editor**: lib/screens/course_editor_screen.dart (10,142 lines): `ExerciseEditorScreen` (~7644); unknown types open as `choice` (~7721); Inspection panel (~9399). Also exercise_draft_builder.dart, widgets/script_recognition_editor.dart, exercise_field_help.dart, exercise_search_service.dart, exercise_creation_planner.dart, guidebook_round_generator.dart, new_course_structure.dart.
- **Data plumbing**: authoring_duplication_service.dart (ID remapping), course_hierarchy_update_service.dart, course_editor_transaction.dart (dirty check ignores `updatedAt`), course_merge_service.dart; course_image_usage.dart (single image walker), course_image_removal.dart, course_media_store.dart; course_package_service.dart (`packageFormat: 1`, `sharedImageSources`), custom_course_transfer_service.dart; course_checksums.dart, publisher_verification_service.dart, course_service.dart.
- **Storage (255)**: course_file_store.dart `rootDirectoryName = 'QQL_Courses'` with `Custom` and `Publisher` (Build 255 Revision 4; `qql_courses_v2` is an earlier folder in `QqlEarlierPrivateFolders`); course_backup_service.dart `backupFormat = 'QuisquisLingo Course Backup v11'` writing to `Documents/QuisquisLingo/Backups/Courses/QQL_bkp_<pair>_<ID>` (Revision 5); app_reset_service.dart, inventory_service.dart, `QqlEarlierPrivateFolders`.
- **Interoperability**: models/exercise_interoperability.dart (285 lines) and models/normalized_import_exercise.dart (34 lines, `presetId` required; used only by tests). The QQL-Tools integration only runs an external `validate --json`.
- **Tools and data (255)**: tools/convert_course_to_v11.dart, tools/move_private_storage_255.dart, tools/sign_course.dart, tools/generate_exercise_laboratory_254.py (`--check`), tools/generate_edge_case_demo_254.py, tools/generate_piedmontais_demo_254.py, tools/validate_courses.py (own INTERACTIONS/EVALUATIONS/CONTENT_KINDS lists and DUEL_SUPPORTED_PRESETS). **4 bundled Courses** in assets/courses: exercise_laboratory_en_it.json, edge_case_it_en.json, korean_en.json, piedmontais_en.json (Build 255 Revision 6 removed the other six; the exercise counts in the planning note covered ten). Publisher fixtures in test/fixtures/publishers/ (dummy key pair present).
- **Conversion traps**: missing_word blanks the first case-insensitive occurrence of each missing word at runtime and its `missingWords` duplicates `acceptedAnswers`; `___` in gap_choice, fill_blank and type_missing_word text is display text, not a target; a text_match without a normalization map (4 in the Edge Case Course) means ignore/ignore/normalize/missing-accents-accepted; whole-sentence Arrange grades joined text, not IDs; Match sides come from pair order.
- **Docs**: EXERCISE_ARCHITECTURE_224.md, COURSE_JSON_FORMAT.md, 254_LABORATORY_COVERAGE.md, NEW_EXERCISE_TYPE_CHECKLIST.md, 239_RESET_STORAGE_INVENTORY.md.

## PART D — Original task specification (condensed)

### Objective
QQL must represent exercises imported through external converters without
depending on QQL's editor presets. The semantic representation of an exercise
is: primitive, primitive options, prompt/content/media, items and/or targets,
layout, evaluation, feedback. Presets are authoring conveniences only: a preset
may be recorded as authoring metadata but is never required to understand,
validate, render, evaluate, import, export or edit an exercise. Canonical data
always wins over preset metadata; removing preset metadata changes nothing;
unknown preset metadata never invalidates a Course; two exercises that differ
only in preset/editor metadata are semantically equivalent.

### The nine primitives (serialized lowercase)
`select`, `input`, `arrange`, `match`, `assign`, `speak`, `ink`, `submit`,
`presentation`. Nothing else: translation, cloze, multiple choice, true/false,
comprehension, hotspot, word search, crossword, dialogue, Story, interactive
video and branching scenarios are all expressed through these nine plus
options, media, layout, evaluation and content flow.

### Content flow
Course › Lesson › activity/Round/Story › content flow › content nodes and
exercise nodes › primitive › options › items/targets › layout › evaluation.
A Story is not a primitive: it is a sequence or graph of content and exercise
nodes. Transitions: next, onCorrect, onIncorrect, onChoice, conditional. The
first implementation may play linear flows only, but serialization must not
prevent branching. Dialogue is content; a learner response is an exercise node.

### Presets
A preset defines: id, name, description, category, primitive, locked canonical
options, default canonical options, visible author fields, Help. It never
carries hidden runtime semantics. Selecting a preset creates or edits a normal
canonical exercise; the saved exercise stays valid without the preset. When an
edit makes the canonical configuration no longer match the recipe exactly, the
metadata is cleared. Exact recognition may be offered for preset-free
exercises; recognition never writes; near matches are not exact matches.

### Media and layout rules
Text, images and audio are media in prompt/content structures, not primitive
options: TTS is not part of Speak; a Select may have a spoken prompt; an Input
may be a dictation. Layout is neutral and shared: an inline layout is a
sequence of text runs and targets; the primitive decides what a target does
(Select: a reusable item fills it; Arrange: an occurrence is consumed; Assign:
an item is assigned to a destination; Input: it becomes a field). Names that
imply Arrange ownership (`arrangeLayout`, `arrangeGapAssignments`) go.

### Capability registry
One authoritative registry defines every option: name, data type, legal values
or range, default, required or optional, applicable primitives, incompatible
combinations, evaluation implications. Strong typing inside; stable serialized
values. Editor, Audit, runtime and import all derive legality from it.

### Option inventory required by the specification
- **Select**: selectionMode single|multiple; selectionTarget items|textSpans|regions|cells; minimumSelections, maximumSelections (positive integers); itemReuse forbidden|allowed|unlimited; layout (Select-compatible values); evaluationTiming immediate|explicit|onCompletion; shuffleItems. Evaluation: exactItem, exactSet, subset, orderedSelections, perSelection. exactSet requires minimumSelections ≤ correct count ≤ maximumSelections ≤ selectable items.
- **Input**: inputMode text|number|date|formula|code; cardinality single|multiple; layout field|inlineGaps|grid|multiline; caseHandling exact|ignore; punctuationHandling exact|ignore; whitespaceHandling exact|normalize; accentHandling (A.4: exact|missingAccentsAccepted|ignore); typoTolerance none|conservative; evaluationTiming explicit|onCompletion. Evaluation: exactText, acceptedTexts, expression, numericExact, numericRange, numericTolerance, regex, manual. Answer-expression syntax becomes an evaluation capability.
- **Arrange**: placementMode sequence|inlineGaps|grid; itemReuse (normally forbidden); unusedItems forbidden|allowed; layout horizontal|vertical|wrapped|inline (plus what QQL needs); shuffleItems; evaluationTiming explicit|onCompletion. Evaluation: exactOrder, acceptedOrders, gapAssignments. Arrange works with item occurrences: a repeated word needs two occurrences.
- **Match**: relationship oneToOne|oneToMany|manyToOne|manyToMany; interactionStyle pair|dropdown|connect|memory; itemReuse forbidden|allowed; layout columns|cards|free; shuffleLeft, shuffleRight; evaluationTiming explicit|onCompletion. Evaluation: exactRelations, requiredRelations, partialRelations.
- **Assign**: targetMode categories|slots|gaps|regions|cells; targetCapacity single|multiple|unlimited; itemReuse forbidden|allowed|unlimited; placementMode drag|selectTarget|tapTarget; layout inline|columns|overlay|grid|free; shuffleItems; evaluationTiming explicit|onCompletion. Evaluation: exactAssignments, acceptedTargets, categoryMembership, partialAssignments. Assign is for drag-into-gaps, categorizing, labelling images and maps, grouping and table cells.
- **Speak**: speechMode repeat|readAloud|freeResponse; captureMode microphone; language (QQL locale conventions); transcription none|optional|required; playback none|allowed|requiredBeforeSubmit; evaluationTiming explicit|onCompletion; maxDurationSeconds (positive integer or absent). Evaluation: transcriptionMatch, acceptedTranscriptions, pronunciation, combined, manual, none. No recognition runtime yet.
- **Ink**: inkMode freehand|trace|character|diagram; inputDevice pointer|touch|stylus|any; strokeOrder ignored|checked; templateVisible; eraseAllowed; evaluationTiming explicit|onCompletion. Evaluation: recognition, strokeMatch, shapeSimilarity, manual, none.
- **Submit**: submissionType audio|video|image|file|textDocument; cardinality single|multiple; captureSource device|file|either; reviewMode self|manual|external; evaluationTiming none|onCompletion. Evaluation: presence, manual, none. A recording analysed by QQL is Speak; one stored for review is Submit.
- **Presentation**: completionMode continue|acknowledge|understoodReview|automatic; navigation singlePage|paged; mediaPlayback manual|automatic|none; scoring none; evaluationTiming none. Evaluation: none. Used for flashcards, explanations, examples, vocabulary presentations and non-interactive content.

### Sessions (condensed; Part B and A win on conflicts)
1. Audit the current architecture; add the nine primitive definitions, the capability registry (legal values, defaults, required values, illegal combinations, evaluation modes per primitive), content-flow node and transition definitions. No runtime for Assign/Speak/Ink/Submit, no serialization change. Tests: exactly nine primitives; every primitive has capabilities; only legal evaluation modes; invalid enum values never become canonical; flow definitions structurally valid. Report files, primitive list, option inventory, evaluation matrix, flow definitions, behaviors that do not map cleanly, tests.
2. Course Model v12: canonical serialization (prompt/content/media, primitive, options, items, targets, neutral layout, evaluation, feedback, optional authoring metadata), registry validation, neutral layout shared by Select/Input/Arrange/Assign, canonical target IDs, flow serialization (start, content and exercise nodes, linear transitions; extensible to branching), v11 → v12 conversion of representative exercises. Tests for parsing, serialization, metadata present/absent/unknown, semantic equality, invalid primitive/option/pairing, inline layout, linear flow, conversions. Report lossy data.
3. Refactor learner runtime for Select, Input, Arrange, Match, Presentation (behavior from primitive/options/layout/evaluation, never from preset IDs), then Audit through the registry (compatibility, items, targets, layout references, selection limits, reuse, capacity, required values, illegal combinations; fix the impossible multi-select case). Unify inline-layout handling; Presentation as a genuine primitive; normal Rounds as linear flows. Report remaining preset-dependent branches (must be empty per A.3).
4. Presets as optional recipes; preset identity only as metadata; clearing on divergence; exact recognition; Generic Primitive Editor (Primitive, Options, Prompt/media, Items, Targets, Layout, Evaluation, Feedback) fed by the registry; Help around Primitives, Options, Layouts, Evaluation modes, Presets; basic linear multi-node authoring including Stories. Tests listed in Part D.
5. Normalized import and interoperability around canonical semantics (external type → primitive → options → layout → evaluation; presets as hints only); the four states executable, readableButNotExecutable, invalid, unsupportedModelVersion; unimplemented primitives parsed, validated, preserved, inspectable, editable, duplicable, exportable, re-importable; conditional transitions; the service sweep (import/export, copy, duplication, merge, search, inspection, publisher handling, checksums, Audit, Duel eligibility, Review, GuideBook generation, Laboratory generation); machine-readable capability description; end-to-end tests including a Story without preset metadata.
6. Laboratory by primitive and option (minimum configuration, option combinations, boundaries, layouts, media, evaluation modes, serialization, duplication, copy, editor reopen/save, learner completion); negative tests (the list in Part D); Assign runtime (categories, slots, gaps, regions where reasonable; capacity single/multiple; reuse forbidden/allowed; exactAssignments) with Generic Primitive Editor support; Story tests (linear, multimedia, branching, choice branch, imported); capability-based Duel eligibility; semantic-equality tests; final verification (dart format, flutter analyze, focused suites, full suite).

### Final acceptance scenario
An external converter creates a valid v12 Course with a Story whose exercises
carry no preset metadata; QQL imports it, validation succeeds, executable
primitives run, not-yet-executable primitives are preserved, the Generic
Primitive Editor inspects and edits them, export and re-import preserve the
canonical semantics. QQL separates PRIMITIVE (what the learner does), OPTIONS
(how it behaves), PRESET (what the editor makes easy) and CONTENT FLOW (how
content and exercises are ordered or branched).

### Session report (every session)
1. files changed; 2. architecture decisions implemented; 3. tests added or
changed; 4. tests executed and exact results; 5. known limitations;
6. anything intentionally deferred.
