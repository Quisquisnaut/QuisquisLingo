# QQL 231 Exercise Type Inventory

This inventory covers every exercise type in `ExercisePresetRegistry` for Version 2.0.31, Build 231.1. Revision 1 does not change the authoritative searchable-field mapping. Course Model v7 is unchanged.

## Shared behavior verified for every type

| Concern | Authoritative behavior |
| --- | --- |
| Display name | `ExercisePresetRegistry.presets`; Search and the Course Editor use the same name. |
| Editor Help | Every preset ID has an `ExercisePresetRegistry.helpByPreset` entry. Field-level Help remains in `ExerciseFieldHelpRegistry` and the preset-specific editor. |
| Preview | The shared unsaved Exercise Preview and Round Preview paths render the canonical `Exercise` through `RoundScreen(previewMode: true)`. Preview writes no learner state or course working-copy state. |
| Draft | Publication state belongs to the canonical Exercise/Content. Save as draft and normal Save use the common Exercise editor workflow. |
| Audit | `CourseAuditService.auditExercise` applies common validation plus preset-specific Error/Warning rules. Search neither changes nor reinterprets Audit outcomes. |
| Move/Copy | All types use the same `CourseAuthoringTransferService`. Move retains stable IDs. Copy/Duplicate allocates fresh owned IDs, remaps internal references and starts the copy as Draft. |
| IDs | Search matches the Exercise ID, exactly or partially and case-insensitively. Item IDs and internal references are not searchable. Show/Hide IDs controls result ID visibility. |
| Learner/editor consistency | Both surfaces consume the same canonical Course Model v7 `Exercise`. Search reads that object without creating a parallel exercise representation. |

## Authoritative searchable authored text

The implementation source is `ExerciseSearchRegistry`. “Prompt text” includes the textual prompt roles used by that preset, such as primary prompt, passage, question, clue, context and dialogue text. “Answers/blocks” means authored text or audio text in canonical interaction items. Search token matching is case-insensitive and diacritic-insensitive and requires contiguous complete words. Asset paths, icon/image keys, option numbers, item IDs, correct-item IDs, normalization flags, publication state, timestamps, feedback configuration and other internal values are excluded.

| Preset ID | Exercise display name | Searchable authored fields | Preset-specific inventory note |
| --- | --- | --- | --- |
| `choice` | How do you say | Prompt text; answers | Canonical Select. Correct answer is referenced by item ID but the internal reference is excluded. |
| `gap_choice` | Fill in the blank | Prompt/question text; answer blocks; hint | The literal `___` gap remains ordinary authored prompt text. |
| `icon_choice` | Select the image | Question text; textual options | Icon/image keys and assets are excluded. |
| `script_recognition` | Recognize characters | Text prompt; textual options | The separate script-recognition editor remains authoritative; prompt/option image payloads and stable option IDs are excluded. |
| `listening_choice` | What do you hear | Spoken text; question; written answers | Audio-library paths and playback configuration are excluded. |
| `listening_comprehension` | Listen and choose | Spoken passage; question; answers | Search indexes authored audio text, not generated audio bytes. |
| `reading_comprehension` | Reading comprehension | Passage; question; answers | Existing reading-specific Audit rules remain unchanged. |
| `dialogue_response` | Dialogue response | Context; question; response options | Randomized learner display order is runtime configuration and is excluded. |
| `contextual_comprehension` | Contextual comprehension | Context/dialogue text; speaker labels; audio context; question; answers | Context mode is configuration and is excluded. |
| `type_translation` | Type the translation | Source text; accepted translations; hint | Expanded/materialized accepted answers are independent authored lines and therefore searchable. Normalization settings are excluded. |
| `build_translation` | Build the translation | Source text; available blocks; literal correct translations | Stable ordered item IDs are excluded; human-readable correct-order text is searchable. |
| `fill_blank` | Type a missing word | Incomplete word/phrase; accepted answers; hint; optional complete-phrase audio text | Answer-expression syntax remains authored text; Search does not expand or reinterpret it. |
| `type_missing_word` | Type the missing word | Gapped sentence; complete accepted words; hint | Unicode-first-grapheme validation remains an Audit/answer concern, not a Search rule. |
| `listening_spelling` | Type what you hear | Passage transcript; audio text; accepted transcription | Inventory inconsistency retained: the editor currently labels the accepted-transcription field “Missing word”; storage and learner behavior correctly use accepted answers. This is wording debt, not a QQL 231 behavior change. |
| `missing_word` | Listen for missing words | Transcript; audio text; missing words | Gap positions are derived by existing learner logic and are not separately indexed. |
| `matching` | Match the pairs | Instruction; both textual sides of every pair | Evaluation pair IDs are excluded. |
| `word_match` | Match the words | Instruction; both textual sides of the three pairs | Existing exactly-three-pairs Audit remains unchanged. |
| `super_match` | Match related words | Relationship instruction; both textual sides of the three pairs | Relationship semantics remain human-authored and audited as before. |
| `audio_match` | Listen and match | Instruction; authored audio text and visible text for each pair | Audio bytes/paths are excluded. Existing exactly-three-pairs Audit remains unchanged. |
| `word_order` | Word order | Instruction; available blocks; human-readable correct sentence | Correct-order item IDs are excluded. Distractor limits remain Audit behavior. |
| `image_word` | Image-prompt ordering | Instruction; available letter/syllable blocks; human-readable correct word | Image assets are excluded. Required-image validation remains Audit behavior. |
| `flashcard` | Flashcard | Term; meaning; usage text; optional pronunciation audio text | Canonical Presentation content continues to use the established compatibility view for editor and learner rendering. |

## Inconsistencies found, deliberately not redesigned

- Type what you hear uses the editor label “Missing word” for accepted transcriptions. The field is functionally consistent with learner evaluation, but the wording should be corrected in a separate narrow change if desired.
- Recognize characters uses its dedicated editor widget while the other presets use the shared field builder. It still has complete preset and field Help, Preview, Draft, Audit, Move/Copy and ID behavior.
- Revision 1 resolves the former presentation inconsistency: View only uses the ordinary preset-specific form with its mutation controls disabled, while canonical JSON is the explicit read-only Inspection presentation available through the root Inspection mode or local Exercise toggle. This changes no searchable field or Exercise serialization rule.

No Course Model fields, exercise type semantics, scoring, learner correctness, or serialization were changed by this inventory.
