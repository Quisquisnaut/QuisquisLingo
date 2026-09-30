# Build 259 change summary

Build 259 delivers the plan `CONTEXT_AND_HINT_PLAN.md` (owner decisions of
29 September 2026; go-ahead on 30 September): clear prompt and question
fields, an authored instruction in place of the standard line, hints and
instructions for Complete the text and Put the sentences in order, and the
Listen and answer split. Evidence: `259_VALIDATION.md`; handoff:
`259_HANDOFF.md`.

## Revision 0 (2.0.59+259000, 30 September 2026): instructions and questions

Owner decisions: plan §2, decisions 2–4, 7, 8, 11 and 12.

**Why.** The Piedmontese Lessons 18 and 21 showed learners exercises
whose answer could not be worked out. Their forms mixed two kinds of
text: labels such as "Translation prompt / instruction" or
"Question / instruction", and Type what you hear's "Passage transcript",
which is shown to the learner. The learner screen repeated the exercise
type three times: heading, standard line, authored instruction.

**The rule.**
- `ExerciseFeatures.displayedPrompt` and `authoredInstruction` are the
  model side: the primary text, else the clue, and that text only when it
  states no language.
- `RoundScreen._promptAsInstruction` now holds for every executable
  exercise whose authored prompt has no language: the prompt takes the
  place of the standard instruction line. Until now only Choose and Match
  did so. A prompt with a language (a text to translate, a spelling clue)
  keeps its own line (`_promptShown`), and Pick the translation keeps its
  own instruction.
- Spell the word in the picture no longer draws its instruction in its
  body as well; Spell the word's clue stays there.
- Type what you see draws no empty question line.

**Fields that change kind.** The optional questions of What is in the
picture, Type what you see, Name what you see, Listen and pick the
image, Sort into groups and Fill the slots were instructions. They become
the Instruction or context field, stored as a `primary` text with no
language:
- `PresetVariants.draftFor` / `_questionAsInstruction` for the recipes
  built through the v11 shape;
- the builders of the canonical-only presets.

Before this change, the Round screen never drew the question of an
Assign or of Name what you see, so learners did not see it. It now
appears as the instruction line.

**Choose the answer (to source).** Its recipe no longer marks the
instruction as source language, only the question and the answers. A
language on the instruction would keep it off the instruction line.

**Required questions and sentences.**
- `ExerciseDraftBuilder.requiredTexts` names, per preset, the form field
  and label of its question or sentence; a Published save (or a Preview
  that needs a valid answer) refuses it empty.
- `ExerciseDraftErrorCode.textRequired`, `ExerciseDraftField.question`
  and `prompt` are new.
- The presets that require one: Choose the answer, Select the image, Pick
  the missing word, True or false, Pick the translation, Read and answer,
  Type the missing word, Type and Build the translation, and Spell the
  word.

**Recognize characters.** In text-to-image mode the text is stored as the
question, so it stays in the body; its Audit rule reads the question.

**Forms.**
- `_instructionField()` gives every Instruction or context field the same
  label, **Instruction or context (optional)**, and a helper quoting the
  standard line it replaces (`ExerciseCopyService.instruction` for the
  preset's first learner kind; `PresetRecipes.kinds` puts Put the
  sentences in order's lines and Match picture to word's plain match
  first).
- The questions and sentences are labelled **Question or sentence**
  (Choose the answer, Select the image, Recognize characters),
  **Sentence** (Pick the missing word, Type the missing word, True or
  false, Type, Build and Pick the translation) or **Question** (Read and
  answer).
- Spell the word's clue is **Clue (source language)**.
- Match by meaning's instruction is in the learners' language (it asked
  for the target language by mistake).
- Reading and listening material is unchanged: labels, whether it is
  required, and skipping.

**Field Help.**
- `ExerciseFieldHelpRegistry` has new field lists (`prompt` instead of
  `question` for the six presets), titles and the shared Instruction or
  context text. `ExerciseAuthoringField.listeningTranscript` is gone.
- Help EN/IT/ES: one shared body `exerciseHelp.field.instruction.body`
  for every Instruction or context field. Four retired bodies:
  `choice.prompt`, `listening_spelling.prompt`,
  `sort_into_groups.question`, `fill_the_slots.question`. The field map
  is updated, as are the preset texts that named "Prompt",
  "Match type / instruction" or an optional question, and the Recognize
  characters text.

**Duel.** "Listen and choose the meaning." only shows for an exercise with
audio; a picture exercise asks through its instruction.

**Demo content.**
- Regenerated, with the v11 converter fixtures written from `course_v11()`
  / `build_course_v11()` with their checksum.
- Laboratory: the Choose examples keep their questions in the question,
  Recognize characters text-to-image asks in its question, the picture
  presets and Assign examples carry an instruction, and Match by meaning
  is in English.
- Piedmontese demo: the Choose and Select the image questions are in the
  question, and the picture presets carry an instruction.

**Also fixed.** `tools/validate_courses.py` expected 7 Laboratory Lessons
since Build 258 Revision 3 added the eighth, so it failed on `main` too.

Scoring, progression, Review, the Course format and learner data are
unchanged.

## Revision 1 (2.0.59+259001, 30 September 2026): Complete the text and Put the sentences in order

Owner decisions: plan §2, decisions 1, 2, 5, 6 and 9; plan §5.

**Why.** Piedmontese Lesson 18's Complete the text exercises and Lesson
21's Put the sentences in order exercises could not be worked out: the
missing word was only in the audio, which a text exercise does not have,
and several orders were equally plausible. Complete the text also drew a
greyed Play audio button, so it looked like a listening exercise. Put the
sentences in order asked for the same lines twice, in "Sentences or
lines" and in "Correct order".

**Complete the text.**
- Form: Instruction or context (optional) first, then the text, the
  missing words and **Hint (optional)**.
- The instruction is the form's `question` value
  (`_instructionField(controller: _question)`). `PresetVariants.finish`
  writes it as a `clue` text with no language (`_withInstruction`),
  because the Listen-for-missing-words recipe reads its `primary` text as
  the passage; `decompose` reads it back through `authoredInstruction`.
- In the Round the instruction replaces the standard line (Revision 0's
  rule) and the hint shows under the gapped text.

**Put the sentences in order.**
- Form: Instruction or context (optional), **Lines, in the correct
  order**, **Extra lines (optional)** (0, 1 or at most 2) and **Hint
  (optional)**. "Sentences or lines" and "Correct order" are gone.
- Recipe: the preset joins `PresetRecipes.canonicalOnly`, built by
  `ExerciseDraftBuilder._buildSentenceOrder`:
  - the `clue` instruction;
  - one item per line and extra line, IDs kept by text;
  - the stored item order kept, new lines at the end, so an unchanged
    exercise rebuilds equal to itself (the runtime shuffles anyway);
  - one `exactOrder` correct order of the lines;
  - the hint.
- `decompose` fills `order` from the correct order and `extraWords` from
  the items outside it, as for Name what you see.
- `PresetRecipes.rebuild` gives this preset the stored items, so an
  exercise whose lines were stored out of order (the former "in any
  order" field allowed it) is still represented by its form.
- A Published save needs at least two lines
  (`ExerciseDraftErrorCode.linesRequired`).

**Learner screens.**
- `RoundScreen._hintPanel` draws the hint as Type the missing word draws
  its own: under the gapped text (`gap-fields-hint`) and above the blocks
  (`order-hint`). Missing letters' and Name what you see's hints, which
  learners never saw, show too. An empty hint draws nothing.
- A gap exercise draws Play audio only when it has audio.

**Field Help and Help EN/IT/ES.**
- Field lists: `question, prompt, missingWords, hint` for Complete the
  text; `prompt, order, extraWords, hint` for Put the sentences in order.
- `ExerciseAuthoringField.extraLines` replaces `lines`; `correctLineOrder`
  is retitled **Lines, in the correct order**.
- Help: the two preset bodies and descriptions, `sentence_order.order`
  rewritten, `sentence_order.extraWords` new, `sentence_order.tokens`
  retired; the hints share the Pick the missing word hint body.

**Search.** Both presets search their hint.

**Demo content.**
- Piedmontese Lesson 18: hints "One meows, one barks.", "Something to
  eat and something to drink.", "Something you read." and the instruction
  "You are at home, on the sofa.".
- Piedmontese Lesson 21: the instructions give the situation ("Tòni
  meets Anna in the street and greets her first.", "Anna goes to the
  market in the morning and is home by noon.", "In the evening you have
  dinner, then you read in bed.") and the last has the hint "The last
  line is what you say before sleeping.".
- Laboratory: Complete the text has the instruction "Anna's morning
  before work." and a hint; the story sets the scene; the dialogue has an
  instruction, the extra line "Il treno parte alle nove." and a hint.

Scoring, progression, Review, the Course format and learner data are
unchanged.

## Revision 2 (2.0.59+259002, 30 September 2026): the Listen and answer split

Owner decisions: plan §2, decisions 2, 3 and 9; plan §6.

**Why.** Listen and answer's optional question did two jobs. In the demos
it was sometimes an instruction ("Choose the greeting you hear.", "What
did you hear?") and sometimes a real question ("Dove fa la spesa
Maria?"). By decision 3 a preset that needs instances with and without a
question splits in two.

**The presets.**
- **Listen and choose (to target)** `listening_choose_target` and **(to
  source)** `listening_choose_source`, new, first in the Listening group:
  - the learner hears a word or a sentence and picks what was heard, or
    its meaning;
  - no question; an optional Instruction or context, stored as a
    `primary` text with no language. `PresetVariants.draftFor` gives the
    form's prompt to the What do you hear recipe's question, and `_shape`
    turns it into the instruction (`_questionAsInstruction`), as for
    Listen and pick the image; the source twin marks only its answers;
  - base `listening_choice` (`presetRecipeBaseOf`, `PRESET_BASE`), kinds
    `{selectListen}`, twins of each other.
- **Listen and answer (to target / to source)** keep their IDs. The
  **Question** is required (`ExerciseDraftBuilder.requiredTexts`, label
  Question): a Published save refuses it empty. A new one asks about the
  passage (`listening_comprehension`); a stored primary-audio exercise
  keeps its shape.
- The recording is unchanged in both.
- Recognition follows the registry order, so an exercise without a
  question and without a recorded preset is Listen and choose; one with a
  question is Listen and answer.
- The v11 successors are unchanged: a v11 `listening_choice` still
  converts to `listening_answer_target` (old exercises are not a concern,
  decision 9).

**Forms.** The listening form shows Instruction or context (optional)
for Listen and choose and **Question** for Listen and answer
("What the learner answers about what they hear…"). Its old label was
"Question (optional)".

**Also following the split.**
- The Round Wizard's listening exercise (the GuideBook Round generator)
  is a Listen and choose. Its "What do you hear?" was an instruction, not
  a question, and the standard line already says it.
- The Story Wizard offers both new presets.
- The four interoperability patterns that tap what was heard ("Listen &
  Tap", "tap what you hear", "listen and choose", "SpellingPick") hint
  Listen and choose.
- The Audit's listening checks and mismatch hint cover the new presets.

**Field Help, Help EN/IT/ES, Search.**
- Field lists: `tts, prompt, answers, correct` for Listen and choose.
- Listen and answer's question has its own Help: the inline override and
  `exerciseHelp.field.listening_answer.question.body`. It borrowed Select
  the image's and Choose the answer (to source)'s before.
- Preset descriptions and bodies for the two new presets. Listen and
  answer's no longer call the question optional.
- Search covers the new presets.

**Demo content.**
- Laboratory: the greeting example (`select_listening_word`) is Listen and
  choose (to target) with the instruction "Choose the greeting you hear.";
  `listening_source` is Listen and choose (to source) with the instruction
  "What did you hear?". A new `listening_source_question` asks "When does
  the train leave?" about "Il treno per Roma parte alle nove.", a Listen
  and answer (to source). 125 examples.
- Piedmontese: one Lesson per preset. "Hear a greeting" becomes Listen and
  choose (to target), plus two new Lessons: "Hear the meaning" (Listen and
  choose (to source)) and "Listen and answer" (Listen and answer (to
  target), English questions about Piedmontese passages, Piedmontese
  answers). 41 Lessons, 123 examples. The Story Lesson is numbered after
  the preset Lessons instead of a fixed 39.
- The registry holds 46 presets.

Scoring, progression, Review, the Course format and learner data are
unchanged.
