# QQL Round Types Redesign Plan

Date: 2 October 2026

## Objective

Diversify Round behavior and Learner Path presentation while preserving the QQL v12 principle that exercises are authoritatively defined by primitive + options + content, and presets remain authoring conveniences.

The redesign introduces explicit Round types, centralizes Round creation in the Rounds screen, removes duplicated Story and sequence controls, makes preset selection and validation aware of the selected Round type, and adds optional learner-facing Round numbering controlled from Lesson Options.

---

## 1. Authoritative Round type

Add an authoritative Round type field distinct from the old `visualType`.

Proposed values:

```text
roundType:
  discover
  practice
  sequence
  listening
  reading
  story
  flashcard
  test
  speak
```

Learner-facing labels:

```text
discover   -> Discover
practice   -> Practice
sequence   -> Sequence
listening  -> Listen
reading    -> Read
story      -> Story
flashcard  -> FlashCard
test       -> Test
speak      -> Speak
```

`visualType` must not remain the source of semantic behavior.

The Learner Path icon is derived from `roundType`.

Each Round has one Round type. There is no separate pedagogical-role layer.

---

## 2. Change New Round behavior

In the Rounds screen, `New Round` no longer creates a Round immediately.

It opens a selector with:

```text
Discover
Practice
Sequence
Listen
Read
Story
FlashCard
Test
Speak
```

`Speak` is shown at the bottom, greyed out and unavailable for now.

Each choice must show:

- name;
- dedicated icon;
- short explanation;
- important authoring consequences.

There is no generic learner-facing `Round` label anymore. The learner sees the actual type name.

---

## 3. Keep Round Wizard in the Rounds screen

`Round Wizard` remains in the Rounds screen, next to `New Round`, because it creates multiple Rounds.

It must not be moved into the single Round Editor.

The Wizard becomes `roundType`-aware:

- every proposed Round has a type;
- the generated plan shows the type of every Round;
- the author can change the type before final generation;
- generated Rounds follow the same validation and compatibility rules as manually created Rounds.

Example plan:

```text
1. Discover
2. Practice
3. Listen
4. Read
5. Sequence
6. Test
```

The Wizard must preserve its existing multi-Round generation role.

---

## 4. Remove duplicated controls

Remove from the single Round Editor:

- the current `Play as sequence` switch;
- the separate `Story` creation button where it duplicates the new Round-type selector.

These are replaced by explicit Round types selected through `New Round`.

Sequence-specific options appear only in `roundType: sequence`.

Story-specific options appear only in `roundType: story`.

---

## 5. Discover

`roundType: discover`

Purpose:

- introduce new words;
- introduce new concepts;
- introduce structures, examples or explanations;
- optionally combine explanation and first guided exercises.

The creator decides what to include.

Do not enforce a rigid content recipe.

Discover may contain:

- Presentation;
- examples;
- vocabulary;
- exercises;
- mixed instructional content.

Learner Path label:

```text
Discover
```

Learner Path icon:

- dedicated discovery/new-material icon;
- for example a lightbulb, spark or equivalent;
- must be distinct from every other Round type.

---

## 6. Practice

`roundType: practice`

Purpose:

- practise material already introduced;
- normal general-purpose exercise Round.

Behavior:

- exercises normally randomized;
- normal immediate feedback;
- normal mistake review;
- all compatible presets available;
- Canonical Editor available.

This replaces the old generic learner-facing `Round` concept.

Learner Path label:

```text
Practice
```

Learner Path icon:

- dedicated practice icon;
- must remain distinct from Discover and Sequence.

---

## 7. Sequence

`roundType: sequence`

Purpose:

- play exercises and content in the exact order defined by the author.

Behavior:

- no shuffle;
- authored order is authoritative;
- uses the existing linear ContentFlow infrastructure;
- sequence-related options are shown only for this type.

Sequence and Story may reuse the same underlying flow engine but remain semantically distinct.

Learner Path label:

```text
Sequence
```

Learner Path icon:

- three connected nodes/blocks in order, or equivalent;
- avoid circular arrows because they may suggest Review or Repeat.

---

## 8. Listen

`roundType: listening`

Semantic rule:

```text
audio present != audio essential
```

Every required exercise must genuinely require audio to be completed.

Preset picker:

- show only presets classified as audio-essential;
- always show Canonical Editor.

Preset filtering must be capability-driven, not based on hard-coded preset IDs.

Add:

- immediate warning in Canonical Editor if the exercise does not actually require audio;
- Course Audit validation;
- publication block if a Listen Round contains incompatible required exercises.

Learner Path label:

```text
Listen
```

Learner Path icon:

- headphones.

---

## 9. Read

`roundType: reading`

Semantic rule:

```text
text present != reading essential
```

Every required exercise must genuinely require the learner to read the provided content.

Preset picker:

- show only reading-essential presets;
- always show Canonical Editor.

Add:

- immediate warning in Canonical Editor for incompatible exercises;
- Course Audit validation;
- publication block for invalid Read Rounds.

Learner Path label:

```text
Read
```

Learner Path icon:

- page/document with lines.

Do not use a book icon because that visual is already used elsewhere.

---

## 10. Story

`roundType: story`

Story creation now starts from:

```text
New Round
→ Story
```

Behavior:

- creates a Round with an authored narrative flow;
- ordered content and exercises;
- supports dialogue, narration, Presentation and comprehension exercises;
- no ordinary shuffle;
- Story-specific authoring UI only for this Round type.

Learner Path label:

```text
Story
```

Learner Path icon:

- speech bubbles / comic-style dialogue icon.

Do not use a book icon.

---

## 11. FlashCard

`roundType: flashcard`

Purpose:

- a dedicated Round containing only Flashcard-style content.

Allowed content:

- Flashcard preset;
- Picture Flashcard preset;
- equivalent canonical configurations only if they are semantically valid Flashcards.

Disallow unrelated exercise types.

Preset picker:

- show only Flashcard;
- show Picture Flashcard;
- Canonical Editor only if it can create a configuration that satisfies FlashCard Round validation.

Behavior:

- card-by-card progression;
- no unrelated exercise types;
- no normal mixed-practice behavior.

Learner Path label:

```text
FlashCard
```

Learner Path icon:

- a single card or stacked cards;
- must be visually distinct from Story, Read and Practice.

Course Audit must reject incompatible content in a FlashCard Round.

---

## 12. Test

`roundType: test`

Test must be behaviorally distinct, not only visually distinct.

Core behavior:

- only evaluatable exercises;
- no immediate correctness feedback;
- learner answers all questions before seeing results;
- results shown at the end;
- no normal mistake review during the attempt;
- optional passing threshold;
- optional fixed or randomized question order;
- repeat allowed according to existing progress rules unless separately changed.

Preset picker:

- generally broad;
- exclude non-evaluatable configurations such as pure Presentation.

Selector explanation:

> Learners answer all questions before seeing the results. Feedback is shown when the Test is complete.

Learner Path label:

```text
Test
```

Learner Path icon:

- clipboard/check.

---

## 13. Speak

`roundType: speak`

Purpose:

- future Round type for activities in which spoken production is essential.

Current state:

- show at the bottom of the New Round selector;
- greyed out;
- not selectable;
- label as `Coming soon` or equivalent;
- do not create incomplete Speak Rounds yet.

Future behavior:

- only speech-essential exercises;
- Speak primitive and compatible configurations;
- capability-based preset filtering;
- speech-specific validation.

Learner Path label when implemented:

```text
Speak
```

Learner Path icon:

- microphone.

---

## 14. Preset capability model

Extend the preset catalogue with semantic compatibility information.

Conceptually:

```text
audioDependency
readingDependency
isEvaluatable
flashCardCompatible
speechDependency
```

or equivalent capability metadata.

The preset picker asks the registry which presets are compatible with the active `roundType`.

Avoid scattered logic such as:

```text
if presetId == ...
```

Compatibility must be centralized.

---

## 15. Canonical Editor

Canonical Editor remains available where semantically appropriate.

It must support advanced configurations and imported exercises without relying on presets.

Canonical Editor receives the active `roundType` as context and reports compatibility issues immediately.

Examples:

```text
This exercise does not require audio.
This exercise does not require reading.
This exercise cannot be used in a Test because it is not evaluatable.
This exercise is not compatible with a FlashCard Round.
```

Draft saving remains allowed.

Publication remains subject to Round-type validation.

For Round types with very narrow semantics, such as FlashCard, Canonical Editor may be hidden if it cannot create a valid configuration for that Round type.

---

## 16. Course Audit

Add Round-type-specific validation.

At minimum:

```text
Listen Round contains non-audio-essential exercise
Read Round contains non-reading-essential exercise
Test contains non-evaluatable exercise
FlashCard Round contains incompatible content
Story/Sequence flow invalid
Story/Sequence flow contains unreachable node
Round type and flow configuration inconsistent
```

Audit must inspect canonical exercise data, not preset IDs.

---

## 17. Learner Path identity

Every Round type has a stable learner-facing label and icon.

Suggested mapping:

```text
Discover   -> discovery/lightbulb/spark icon
Practice   -> dedicated practice icon
Sequence   -> connected ordered nodes
Listen     -> headphones
Read       -> page with lines
Story      -> speech bubbles/comic dialogue
FlashCard  -> card / stacked cards
Test       -> clipboard/check
Speak      -> microphone
```

Completion, Laurel, locked/unlocked and other state indicators must not erase the Round-type identity.

The generic label `Round` is not shown as the primary learner-facing type label.

---

## 18. Round numbering in Lesson Options

Add a `Round numbering` selector to Lesson Options, analogous to the existing Lesson numbering option.

Default:

```text
Off
```

Available values:

```text
Off
Round + number
Number only
Custom + number
```

### Off

Learner Path shows only the Round type:

```text
Discover
Practice
Listen
Story
```

### Round + number

Examples:

```text
Round 1 · Discover
Round 2 · Practice
Round 3 · Listen
```

### Number only

Examples:

```text
1 · Discover
2 · Practice
3 · Listen
```

### Custom + number

The creator supplies a custom prefix, for example:

```text
Step
Stage
Part
```

Examples:

```text
Step 1 · Discover
Step 2 · Practice
Step 3 · Story
```

The custom prefix belongs to the Lesson numbering presentation configuration, not to Round identity.

---

## 19. Round numbering rules

Learner-facing Round numbering is a presentation option only.

The number:

- is derived from the Round's current position in the Lesson;
- is not stored as Round identity;
- updates automatically after add/delete/reorder;
- does not replace `roundId`;
- does not affect progress identity.

In the Course Editor, Round order numbers are always visible regardless of Lesson Options.

Examples:

```text
1. Discover
2. Practice
3. Listen
4. Sequence
5. FlashCard
6. Test
```

This editor numbering:

- is always shown;
- is not configurable;
- reflects current Round order;
- updates automatically after reordering;
- exists for author clarity only.

---

## 20. Existing Round migration

Migration rules must distinguish certain structural information from old visual hints.

Suggested rules:

- ordinary randomized Round -> `practice`;
- existing `Play as sequence` Round -> `sequence`;
- existing Story flow -> `story`;
- old `visualType: listening` must not automatically become semantic `listening` without validating its exercises;
- old `visualType: test` must not automatically become semantic `test` without validating its behavior/content;
- do not infer `discover` from content automatically;
- do not infer `flashcard` from one or two Flashcards inside an otherwise mixed Round.

Do not infer semantic Round type from visual metadata alone when the conversion is uncertain.

---

## 21. Round Wizard integration

Update Round Wizard preview so every generated Round visibly shows:

- order number;
- Round type;
- title or generated summary where applicable.

Example:

```text
1. Discover
2. Practice
3. Listen
4. Read
5. Sequence
6. Test
```

The Wizard must:

- assign a type to every proposed Round;
- allow changing proposed Round types before generation;
- apply the same preset compatibility rules;
- apply the same Audit rules;
- generate appropriate flow/configuration for Sequence, Story and Test;
- preserve the existing multi-Round generation role.

---

## 22. Author-facing explanations

The New Round selector must explain each choice in simple language.

Suggested copy:

### Discover
Introduce new words, concepts, structures or examples. You decide how to combine explanations and exercises.

### Practice
Practise material the learner has already met. Exercises are normally played in random order.

### Sequence
Exercises and content are played in the order you define. Use this when order matters.

### Listen
Listening is essential. Only audio-essential presets are shown, plus the Canonical Editor.

### Read
Reading is essential. Only reading-essential presets are shown, plus the Canonical Editor.

### Story
An ordered narrative sequence of content and exercises. Best for dialogue, narration and comprehension activities.

### FlashCard
Use only Flashcard and Picture Flashcard activities.

### Test
Learners answer all questions before seeing the results. Feedback is shown when the Test is complete.

### Speak
Coming soon. Spoken production will be essential in this Round type.

---

## 23. Tests to add

Add coverage for at least:

- creation of all implemented Round types;
- Speak shown disabled and greyed out;
- no generic learner-facing `Round` label as the main type label;
- removal of old Play as sequence switch;
- removal of old separate Story creation button;
- Listen preset filtering;
- Read preset filtering;
- FlashCard preset filtering;
- Test exclusion of non-evaluatable content;
- Canonical Editor compatibility behavior;
- Draft allowed but Publish blocked when invalid;
- correct Learner Path icon for each type;
- Sequence preserves authored order;
- Practice continues random play;
- Story preserves flow;
- Test defers feedback until completion;
- FlashCard rejects incompatible content;
- Round Wizard supports multiple `roundType` values;
- Round numbering defaults to Off;
- Round + number rendering;
- Number only rendering;
- Custom + number rendering;
- Round numbers update after add/delete/reorder;
- editor order numbers are always visible;
- display numbers never affect stable Round identity;
- existing Rounds preserve expected behavior after migration.

---

## 24. Recommended implementation order

```text
1. roundType model + serialization
2. learner-facing labels + icon mapping
3. New Round selector
4. editor order numbering
5. Lesson Options Round numbering
6. Sequence migration + remove old switch
7. Story migration + remove old button
8. Discover and Practice behavior
9. Listen + preset filtering + Audit
10. Read + preset filtering + Audit
11. FlashCard + filtering + Audit
12. Test runtime behavior
13. Speak disabled placeholder
14. Round Wizard integration
15. existing-data migration
16. full regression + documentation
```

---

## Architectural principle

```text
roundType
= authoring contract
+ runtime behavior where applicable
+ validation rules
+ Learner Path identity

preset
= convenient authoring recipe

primitive + options + content
= authoritative exercise representation
```

The redesign should enrich the Learner Path and authoring experience without weakening the Course Model v12 rule that presets are optional authoring metadata and canonical exercise data remains authoritative.
