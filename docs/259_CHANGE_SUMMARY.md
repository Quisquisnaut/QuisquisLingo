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
