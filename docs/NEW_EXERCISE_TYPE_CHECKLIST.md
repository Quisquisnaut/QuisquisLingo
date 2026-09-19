# Checklist: adding a new exercise type (preset)

Working checklist for a coding agent or author adding a new exercise type to
QuisquisLingo. It was written while preparing Build 239 (the two Select-based
translation choice types), so several items are phrased from that case. Each
item carries an applicability tag so the list can be reused for other types.

**Rule zero: ask when in doubt.** Every item marked **ASK** is a decision the
project owner must make. Do not silently pick a default; put the question in
the plan and wait for approval before changing code.

## How to read the tags

| Tag | Applies to |
| --- | --- |
| `[ALL]` | Every new exercise type |
| `[SELECT]` | Types built on the Select primitive (choice, gap choice, image choice, etc.) |
| `[INPUT]` / `[ARRANGE]` / `[MATCH]` | Types built on that primitive |
| `[AUDIO]` | Types that speak text, play recordings or depend on audio |
| `[TRANSLATION]` | Types whose content has a source and a target language |
| `[IMAGE]` | Types with an optional or required illustration |
| `[GAP]` | Types with inline gaps or blanks |

Skip an item when its tag does not match the new type, and note in the plan
that you skipped it and why.

---

## 1. Scope and decisions (before writing code)

- `[ALL]` State the scope in one paragraph and list what is explicitly out of
  scope. Existing types are normally not renamed, migrated or removed by a
  task that adds a new type.
- `[ALL]` Decide the primitive. A new type is a preset of an existing
  primitive (Select, Input, Arrange, Match, Presentation) unless the owner
  explicitly approves a new primitive. Do not duplicate learner execution
  logic that the primitive already provides.
- `[ALL]` Decide the Course Editor category. Do not create a new category
  unless asked. Category labels live in `ExerciseCategory`.
- `[ALL]` Decide the preset `id` (stable, lowercase, snake case), the editor
  name and a one-line description. The editor name is Course Editor
  terminology only; it must never appear on the learner screen. **ASK** if the
  owner has not supplied the exact names.
- `[ALL]` Write down what the type implies so authors never configure it:
  direction, language roles, selection mode, learner instruction, validation
  timing, audio rule. Anything implied by the type must not be an editor field.
- `[ALL]` List the fields the author does edit. Keep authoring deliberately
  small.
- `[ALL]` Check whether the type can reuse existing rules for option counts,
  limits and validation before inventing new ones. Do not add arbitrary limits
  that the primitive does not already impose.
- `[ALL]` **ASK** the recurring questions below when the answer is not
  already in the request:
  - Which language is the fixed learner instruction written in (fixed English,
    or localized like `ExerciseCopyService`)? `[TRANSLATION]`
  - Which stored language names feed generated text (for example
    `course.sourceLanguage` and `course.targetLanguage`)? `[TRANSLATION]`
  - Is the type eligible for Duel? If yes, do any problems appear in Duel
    (option count, rendering, audio)?
  - Should the Beta expiry date change with the version bump?
  - Is legacy compatibility needed for courses that use the new type in older
    builds? (Default: no migration; older builds will not open such courses.)
  - Work on a branch or on `main`? (Project history uses branches and squash
    merged PRs, so a branch is the recommended default.)
  - When audio is involved: automatic playback or button only, and what
    exactly the button speaks. `[AUDIO]`
  - Where does the illustration sit relative to the text and options? `[IMAGE]`

## 2. Mockup before implementation

- `[ALL]` Produce a mockup and get approval before touching rendering code.
  Include at least:
  - the learner screen before answering, after a correct answer and after a
    wrong answer;
  - every audio state (available, disabled, unavailable) `[AUDIO]`;
  - with and without illustration `[IMAGE]`;
  - the Course Editor form with the explanation text under each field;
  - the "?" tooltip and the Field Help dialog;
  - the Exercise Help entry and the type picker entry.
- `[ALL]` The mockup must show the single learner instruction and make clear
  that no editor-only preset name appears on the learner screen.

## 3. Touchpoint inventory (find every place the type must be registered)

The set of files drifts over time. Re-derive it instead of trusting this list:
pick a sibling type of the same primitive and search for its id.

```
grep -rn "dialogue_response" lib   # replace with a sibling preset id
```

Known touchpoints as of this checklist (verify each one still exists):

- `[ALL]` `lib/models/exercise_authoring.dart`: `ExercisePresetRegistry.presets`
  (id, name, description, category, model) and `helpByPreset` (one entry per
  preset; a test requires exactly one).
- `[ALL]` `lib/models/course_models.dart`: the primitive type lists in
  `_legacyInteraction` and `_legacyEvaluation` (and prompt-role mapping in
  `_legacyPrompt` when the type needs a special prompt role).
- `[ALL]` `lib/services/course_audit_service.dart`: `supportedTypes`,
  `choiceTypes` (Select types) and any type-specific checks.
- `[ALL]` `lib/services/audit_code_registry.dart`: new or updated Audit codes
  (see section 8).
- `[ALL]` `lib/screens/course_editor_screen.dart`: the `_choices`-style type
  set, the form `switch` for the type, the candidate builder (which of
  `prompt`, `question`, `tts`, `hint`, `icons`, image the type stores), the
  preset picker and the field keys.
- `[ALL]` `lib/services/exercise_field_help.dart`: `editorFieldKeys`,
  per-preset overrides in `forEditorField`, `fieldForEditor`.
- `[ALL]` `lib/services/exercise_search_service.dart`: one search definition
  per preset.
- `[ALL]` `lib/models/exercise_interoperability.dart`,
  `lib/services/authoring_duplication_service.dart`,
  `lib/services/new_course_structure.dart`,
  `lib/services/guidebook_round_generator.dart`: check whether they enumerate
  types or presets.
- `[ALL]` `lib/screens/round_screen.dart`: `_exerciseBody`, the list of types
  that need prepared options (`needsChoices`), `_correctAnswerText`, the header
  (type label, instruction, prompt), image placement.
- `[ALL]` `lib/screens/duel_screen.dart` and
  `lib/services/duel_eligibility_service.dart`: `supportedExerciseTypes` and
  the Duel renderer. `[SELECT]`
- `[AUDIO]` `lib/services/audio_exercise_availability_service.dart`:
  `isAudioExercise` (see section 6).
- `[ALL]` `lib/services/exercise_copy_service.dart`: learner-facing type
  labels and instructions; decide whether the new type uses them or bypasses
  them.
- `[ALL]` The Preview renderer. Confirm whether Preview uses the same
  `RoundScreen` (it does through `previewMode`) or a separate renderer.

## 4. Learner surfaces

Check every surface separately: normal Round, Duel, Preview, Review and view
only mode. Code that renders `prompt`, `question`, the type label or a fallback
message can differ between screens.

- `[ALL]` Exactly one principal learner instruction. Do not stack the type
  title, prompt, question and an automatic fallback when they duplicate each
  other.
- `[ALL]` The editor-only preset name is not shown to the learner.
- `[ALL]` The content (for example the text to translate) is visually distinct
  from the instruction and is not rendered as a second prompt.
- `[ALL]` Duel: no inappropriate fallback message (for example a listening
  fallback for a non-listening type).
- `[IMAGE]` The optional illustration renders in the agreed position, does not
  change evaluation or audio rules, and leaves no empty placeholder or error
  when absent. The generic header may place images before the body; override
  it for types that need another order.
- `[ALL]` Do not alter rendering of unrelated existing types.

## 5. Answer behavior

- `[SELECT]` Single or multiple selection. Single selection with immediate
  validation must not show Check or Submit.
- `[ALL]` State when the answer is evaluated (on tap, on Check, on Submit) and
  reuse the existing evaluation and feedback code (`_mark`, the feedback
  surface). Do not build a parallel feedback implementation.
- `[ALL]` After evaluation the learner cannot change the answer, following
  existing behavior.
- `[ALL]` A correct answer shows normal correct feedback. A wrong answer shows
  normal incorrect feedback and reveals the correct answer.
- `[SELECT]` Options are shuffled per attempt. Tests must select by visible
  text or stable key, never by pre-shuffle position.
- `[SELECT]` Enforce single answer at audit level too (see section 8).

## 6. Audio and text to speech

- `[AUDIO]` QQL speech concerns the course target language only. Do not speak
  a text merely because it is present in the exercise, and never introduce
  source-language speech for a type that does not specify it.
- `[AUDIO]` Decide, per direction and per state, which text (if any) the audio
  button speaks and whether playback is automatic. Optional audio should be a
  button the learner presses, not autoplay.
- `[AUDIO]` The exercise must remain fully solvable without audio. If the
  learner disabled TTS or audio exercises, or no voice exists, the exercise is
  presented normally, is not skipped and shows no missing-audio error by
  itself. The audio button is shown greyed out (disabled) with a short note.
- `[AUDIO]` **Trap:** `AudioExerciseAvailabilityService.isAudioExercise`
  returns true whenever the exercise has non-empty `tts`. Such an exercise is
  skipped when TTS is off. For optional audio, do not store the spoken text in
  `tts`; derive it from the content field at runtime, and exempt the type from
  `isAudioExercise`.
- `[AUDIO]` Playback failure at tap time reuses the existing QQL message.
  Only pre-disable the button from learner settings unless the owner approves
  probing voices in advance. **ASK**.
- `[AUDIO]` Preview bypasses learner audio settings (existing behavior); check
  that the new type is consistent with that.
- `[AUDIO]` Course `audioMode` (`tts`, `recorded`, `hybrid`) must keep working
  through `_playCourseAudio`.
- `[AUDIO]` Skip the skip-if-no-audio behavior intended for types whose
  essential information exists only in audio.

## 7. Course Editor and Help

- `[ALL]` Show only the fields the author must fill. Do not expose implied
  configuration (direction, languages, selection mode, generated instruction).
- `[ALL]` A short explanation under each field (`helper:` text).
- `[ALL]` Tooltips: the "?" button tooltip is the `purpose` line of the field
  help. Keep each `purpose` short and self-sufficient.
- `[ALL]` Field Help dialog per field: title, purpose, what to enter, checks
  and an example (`ExerciseFieldHelp`). Add per-preset overrides in
  `forEditorField` when the generic text does not fit, and list the field keys
  in `editorFieldKeys`.
- `[ALL]` Exercise Help entry in `helpByPreset`: what the learner sees, what
  to provide, what is supported (text, audio, image), how it is checked,
  authoring advice and an example.
- `[ALL]` Say which primitive the type uses (for example start the description
  and Help entry with "Select") so authors understand its behavior.
  Put the note about implied configuration (primitive, validation timing,
  what the type sets for the author) at the start of the type's Exercise Help
  chapter rather than in the editor form, which should stay limited to fields.
- `[ALL]` Decide whether Exercise Help opened from the editor should pre-fill
  its search with the type name (`ExerciseHelpScreen(initialQuery: ...)`) so
  the matching chapter shows directly. **ASK** if the owner did not say.
- `[ALL]` The "?" tooltip is the field `purpose`: keep it short and do not put
  the example there (the Field Help dialog has its own Example section).
- `[ALL]` Author-facing text must not contain engineering source labels (a
  test checks this).
- `[ALL]` Text conventions: keep existing wording rules, English UI text,
  sentence case, no marketing words.
- `[ALL]` Hard-coded inventories in tests must be updated (see section 10).

## 8. Audit: errors, warnings and the code list

Analyze what the type can produce, then decide what is already covered.

- `[ALL]` List every situation that should produce an Error or a Warning and
  map each to an existing `AuditCode` or to a needed new one. Present the
  result as a table (situation, code, severity, covered or new).
- `[ALL]` Add the type to `supportedTypes` (else `EXERCISE_TYPE_UNKNOWN`) and
  to the registry (else `EXERCISE_PRESET_UNKNOWN`).
- `[SELECT]` Add to `choiceTypes` to inherit: too few answers, invalid or
  unresolved correct answer, empty or duplicate options, placeholder answers,
  item ID and reference checks.
- `[ALL]` Fields the type does not use but that are populated: extend
  `EXERCISE_FIELD_UNEXPECTED` (for example prompt, hint, icons, spoken text).
- `[SELECT]` Configuration the type forbids (multiple selection, inline gaps,
  required-selection count): extend `PRESET_CANONICAL_MISMATCH`.
- `[ALL]` Required content that no existing code describes (for example a
  blank text to translate) needs a new code with severity, scope, meaning,
  trigger and creator action. Prefer a new precise code over stretching an
  unrelated one. **ASK** when reuse is also reasonable.
- `[TRANSLATION]` Course-level codes matter because generated text depends on
  them: `COURSE_LANGUAGES_REQUIRED`, `COURSE_LANGUAGES_IDENTICAL`.
- `[ALL]` Update the Scope, Trigger and Creator action text of every existing
  code whose meaning now also covers the new type.
- `[ALL]` Update counts in tests that pin the number of codes (currently the
  audit registry and branch ownership tests) and any ownership mapping.
- `[ALL]` Optional heuristic warnings (for example content identical to an
  option) are scope creep unless the owner asks. **ASK**.

## 9. Data, compatibility and persistence

- `[ALL]` No migration of existing courses. Existing types remain available
  and unchanged, including the older equivalent type.
- `[ALL]` Decide whether the Course Model version must change. New type ids
  alone normally do not require it. Courses that use the new type will not
  open correctly in older builds; record this in the plan and changelog.
- `[ALL]` Round trip: serialize and reload an exercise of the new type and
  confirm every authored field survives.
- `[ALL]` Duplication and copy remap item IDs correctly.
- `[ALL]` Search, export and import treat the new type without special cases.

## 10. Version bump and documentation

Only when the task asks for a version change.

- `[ALL]` Update `pubspec.yaml`, `lib/services/app_metadata.dart`
  (`releaseVersion`, `buildNumber`, `developmentPhase`, `correctiveRevision`,
  `publicBuildLabel`), `README.md` (banner, in-progress paragraph, Beta
  lifecycle sentence) and `CHANGELOG.md` (new heading and bullets).
- `[ALL]` Update tests that hard-code version strings, including the
  version-derived `one_time_notice_seen_welcome_<technicalVersion>` keys in
  test fixtures. Search for the previous version string.
- `[ALL]` **ASK** whether the Beta expiry date changes with this build.
- `[ALL]` Do not edit `AGENTS.md`'s release boundary list unless asked
  (existing precedent leaves it behind).

## 11. Tests

Add focused tests covering, at minimum (adapt to the type):

1. The type appears in the intended category, resolves to the intended
   primitive and appears in the picker.
2. Language roles of the content and of the options `[TRANSLATION]`.
3. The generated instruction text for each direction `[TRANSLATION]`.
4. The instruction is not an editable author field.
5. The learner sees exactly one principal instruction, in Round, Duel and
   Preview.
6. The editor-only preset name is not shown to the learner.
7. Single or multiple selection is enforced as designed `[SELECT]`.
8. Immediate evaluation, no Check or Submit button.
9. A wrong answer reveals the correct answer; a correct answer shows normal
   correct feedback.
10. Optional illustration works with and without an image `[IMAGE]`.
11. Audio rules per direction and state (no autoplay, correct language, button
    visible or greyed) `[AUDIO]`.
12. TTS disabled or unavailable does not skip the exercise and produces no
    missing-audio error `[AUDIO]`.
13. Editor: only the intended fields, helper text, tooltip, Field Help and
    Exercise Help entries exist.
14. Audit: each error and warning fires and clears as designed; the code list
    is complete.
15. Existing types remain available; existing courses are unchanged; the
    older equivalent type remains available.
16. No unrelated taxonomy or architecture change.

Known test pitfalls:

- Hard-coded per-preset inventories need updating, for example
  `test/exercise_field_help_226_02_test.dart`, `test/exercise_help_224_test.dart`,
  `test/exercise_architecture_224_test.dart`, the search tests
  (`test/qql_231_search_service_test.dart`,
  `test/exercise_help_search_226_03_r1_test.dart`) and the two Audit code
  tests.
- Shuffled options: select by text, not by position.
- Widget tests use a fixed viewport; a taller form can push the Save button
  out of view. Scroll explicitly.
- Version tests contain many literal strings; search the whole `test/` tree.

## 12. Process rules

- `[ALL]` Write the plan and get approval before implementing.
- `[ALL]` Work on a branch unless the owner chooses otherwise.
- `[ALL]` Run `dart format`, `flutter analyze` and the focused tests. Run the
  full `flutter test` suite once, at the end of all tasks, and only if the
  owner approves.
- `[ALL]` Do not commit or push unless asked.
- `[ALL]` Report honestly: if a test fails or a step was skipped, say so with
  the output.

## 13. Questions to ask yourself (from earlier reviews)

Use these as a final review prompt for any new type:

- Does the learner see one instruction, or several overlapping ones? Check
  Round, Duel and Preview separately.
- Is the editor-only name visible to the learner anywhere?
- Which fields does the author really need, and which are implied?
- Is the type clearly labelled with its primitive in the editor and in Help?
- Does every field have helper text, a tooltip and a Field Help dialog?
- Is there an Exercise Help entry, and does its wording match the field help?
- What Errors and Warnings can this type produce, and which Audit codes and
  code-list entries must change?
- If TTS is off or unavailable, is the exercise still presented and solvable,
  and is the audio control greyed out rather than hidden or erroring?
- Which text does the audio speak, is it the target language, and is playback
  automatic or manual?
- Can the same code path serve Round, Duel and Preview, or does each need its
  own branch?
- Is the illustration position right and does its absence leave no gap?
- Do the existing types still behave exactly as before?
- Was everything the owner decided (and everything still undecided) written
  down in the plan?

## 14. Worked example (Build 239, for reference)

`translation_choice_to_target` and `translation_choice_to_source`: Select
presets in the Translation category. Fixed instruction "Pick the correct
[language] translation" generated from the course language; text to translate
in `question`, empty `prompt`; immediate validation; optional illustration
between text and options; optional audio button (to source: speaks the target
language text; to target: speaks the correct answer after answering; greyed out
when audio or TTS is off); Duel eligible; one new Audit code
(`TRANSLATION_CHOICE_TEXT_REQUIRED`) plus extended
`PRESET_CANONICAL_MISMATCH` and `EXERCISE_FIELD_UNEXPECTED`; no Course Model
change; version 2.0.39 (Build 239, Revision 0) with the Beta expiry unchanged.
