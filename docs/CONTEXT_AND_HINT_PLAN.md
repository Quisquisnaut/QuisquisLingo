# Instructions, questions and hints in exercises (plan)

Status: **plan only, not scheduled.** Written on 29 September 2026 from a
read-only discussion with the owner. Every decision below is the owner's.
Nothing is implemented. The owner picks the builds and revisions and
gives the go-ahead; **nothing is to be done before the owner approves**.
No points are open (§7).

## 1. Why

**Piedmontese Lesson 18, Complete the text.** The three exercises can't
be answered, with audio on or off.

| Exercise | The learner sees | Expected |
|---|---|---|
| `l18_r01_e01` | I l'hai un ___ e un ___. | gat, can |
| `l18_r01_e02` | La lista: ___, ___ e tre pom. | pan, eva |
| `l18_r01_e03` | Mi i son a ca. I l'hai un ___. | lìber |

- They have no audio; Complete the text is text only by design.
- Any noun fits each gap, and nothing in the exercise decides the word.
- A greyed **Play audio** button on the gap screen
  (`RoundScreen._missingWordExercise`) made the answer look like it was
  in the audio.

**Piedmontese Lesson 21, Put the sentences in order.** The order isn't
always recoverable: "I mangio." and "I leso un lìber." can go either
way. Each Instruction only repeats the exercise type, so the learner
reads three lines that say the same thing:
- the heading, PUT THE SENTENCES IN ORDER;
- the standard line, "Put the sentences in the correct order.";
- the Instruction, "Put the shopping story in order.".

The form also asks for every line twice ("Sentences or lines", then
"Correct order"). If one copy doesn't match, the Audit reports
`WORD_BLOCK_DATA_REQUIRED` without naming the line.

**Across the forms, prompt and question fields are ambiguous.**
- Some labels mix kinds: "Translation prompt / instruction", "Question /
  instruction", "Match type / instruction".
- Type what you hear's "Passage transcript" is shown to the learner, so
  following its label gives the answer away.
- Optional "questions" that are really instructions sit next to
  standard lines that say the same thing.

## 2. Owner decisions (29 September 2026)

1. **Hints.** A hint is visible from the start, in the "Hint: …" panel
   Type the missing word uses. There is one hint per exercise, using the
   existing `hint` field. Demo hints are clues, not the meaning of the
   words.
2. **Instruction or context.** Every optional prompt written in the
   learners' language is labelled **"Instruction or context
   (optional)"**.
   - It is stored as a `primary` or `clue` text **with no language**. The
     label and helper say "in the learners' language". Storing
     `language: source` there would make Arrange and single-field Input
     exercises play as Build or Type the translation.
   - In the learner screen it **replaces the standard instruction line**,
     in every exercise. The helper tells creators so, and quotes the line
     it replaces.
3. **Questions and sentences are never optional** and never replace the
   standard line. Labels: "Question", "Sentence" or "Question or
   sentence", as the case needs. If a preset needs some instances with a
   question and some without, it is split into two presets.
4. **Reading and listening material is not changed:** not its labels,
   not whether it is required, not when an exercise is skipped.
5. **Put the sentences in order.** Its Instruction becomes Instruction or
   context; there is no separate Context field. The lines are entered
   once, in order, plus a box for extra lines.
6. **Complete the text** gets Instruction or context (optional) and Hint
   (optional).
7. **Match by meaning's** target-language instruction was a mistake. It
   moves to the learners' language.
8. **Two texts are stored with a language, so they are not Instruction or
   context** and stay as they are: Read and answer's "Text to read
   (source language)" (a panel) and Spell the word's "Clue".
9. **No migration.** Old exercises are not a concern; the bundled Courses
   are regenerated.
10. **Order of work:** three revisions, as in §4–§6.
11. **The text to translate is a "Sentence"** (Type, Build and Pick the
    translation), required. Its helper names the language. Spell the
    word's clue is labelled "Clue (source language)".
12. **Recognize characters' "Text prompt"** (text-to-image mode) names the
    character to find, so it becomes "Question or sentence", required, as
    for Select the image.

## 3. What already exists

- `Exercise.hint` is a canonical field. The Audit's `HINT_REVEALS_ANSWER`
  and `HINT_REPEATS_PROMPT` already cover inline gaps and orders.
- For Choose and Match, an authored prompt already replaces the standard
  line (`RoundScreen._promptAsInstruction`).
- The learner screen reads the authored prompt as `primary`, else `clue`
  (`_displayedPrompt`). `ExerciseFeatures.promptLanguage` reads only
  those two roles.
- Name what you see already has the lines-in-order + extra-items shape:
  `_buildPictureBlocks`, a canonical-only recipe, with item IDs kept by
  text.
- Element roles are free text, not a fixed list.

In the Laboratory, 43 examples show an authored prompt:
- **26 are instructions** with no language, for example "Put the dialogue
  in order.", "Select the character shown." and "Complete the sentence.".
  Some are meanings, such as "Anna reads a book." (owner: that is
  context).
- **17 are material to translate or spell**, stored with a language:
  Type and Build the translation, and Spell the word's clue. They stay
  where they are.

## 4. Revision 1: the rule and the labels

### 4.1 The learner screen

- **The rule.** An authored prompt with no language replaces the
  standard line. `_promptAsInstruction` stops listing kinds and asks
  whether the displayed prompt has a language (a feature such as
  `ExerciseFeatures.authoredInstruction`).
  - Kinds without the line are unchanged: Page, Dialogue line, and
    Pick the translation, which has its own instruction.
  - A prompt with a language (text to translate, a clue) stays where it
    is today.
- **Spelling exercises** (`arrangeWord`) draw the prompt inside their
  body today (`_imageWordExercise`).
  - Spell the word in the picture has an instruction with no language.
    It moves to the line and leaves the body.
  - Spell the word's clue has a language and stays in the body.
- **Empty questions.** Where a question moves to Instruction or context
  (§4.2), the body stops drawing an empty question line. `_fillBlankExercise`
  and the Select and Assign bodies draw `questionText` today.
- **The Duel.** It shows the authored prompt above the question (today's
  behaviour). When there is no question, it currently falls back to
  "Listen and choose the meaning." (`duel_screen.dart`). After What is in
  the picture moves its question, that fallback would appear on a picture
  exercise. It must show only when the exercise has audio.
- **Unchanged:**
  - Old stock instructions stay hidden (`isLegacyInstruction`).
  - Mascots: lines to order and spelling never show one, and Choose
    already works this way.
  - Reading and listening material.

### 4.2 The labels

**Instruction or context (optional).** Helper: "Optional. Write it in the
learners' language. The learner sees it instead of the standard line:
“…”." The quoted line comes from `ExerciseCopyService`, the same place
the learner screen uses. Each is stored `primary` or `clue` with no
language.

| Preset | Label today | Stored today |
|---|---|---|
| Choose the answer (both) | Prompt (optional) | primary |
| Word order | Translation prompt / instruction | clue |
| Pick the words for the gaps | Instruction (optional) | primary |
| Drag the blocks into the gaps | Instruction (optional) | clue |
| Put the sentences in order | Instruction | clue |
| Spell the word in the picture | Instruction | clue |
| Match the words, Match picture to word, Listen and match | Instruction | primary |
| Match by meaning | Match type / instruction (helper asks for the target language) | primary |
| Type what you hear | Passage transcript | primary |
| Listen and pick the image | Question (optional) | question → primary |
| Name what you see | Question (optional) | question → primary |
| Type what you see | Question / instruction | question → primary |
| What is in the picture | Question | question → primary |
| Sort into groups | Question | question → primary |
| Fill the slots | Question | question → primary |

Where a field moves from `question` to `primary`, the recipe writes
`primary`: in `PresetVariants.finish` for the recipes built through the
v11 shape, and in the builder for the canonical-only recipes (Name what
you see, Sort into groups, Fill the slots).

**Question or sentence (required).** It stays in the body and never
replaces the line. Save refuses it empty.

| Preset | Label today | Proposed |
|---|---|---|
| Choose the answer | Question or sentence to complete | Question or sentence |
| Pick the missing word | Target-language sentence with one gap | Sentence |
| Type the missing word | Sentence with one ___ gap | Sentence |
| True or false | Statement | Sentence |
| Read and answer | Question | Question |
| Select the image | Question | Question or sentence (it names the word to find) |
| Recognize characters (text-to-image) | Text prompt | Question or sentence (it names the character to find) |

**Prompts that hold the material to translate or spell** (required,
stored with a language, decision 11). Their place in the learner screen
doesn't change.

| Preset | Label today | Proposed |
|---|---|---|
| Type the translation | Source text / Text to translate | Sentence (the helper names the source or target language) |
| Build the translation | Source sentence / Sentence to translate | Sentence (the helper names the language) |
| Pick the translation | Text to translate | Sentence (the helper names the language) |
| Spell the word | Clue | Clue (source language) |

**Unchanged:**
- the reading and listening material (Spoken text, Audio text, Spoken
  word, Listen and fill the gaps' Passage transcript, Read and answer's
  Text to read and Dialogue lines, the optional spoken texts);
- card and story fields;
- answers, blocks, missing words and hints.

### 4.3 Texts, content and tests

- **Help (EN/IT/ES):** the field Help of every renamed field; the preset
  bodies and the Editor Help answers that quote an old label (for example
  "Prompt (optional)" and "Passage transcript"); the Match by meaning
  helper and Help.
- **Content.**
  - The Laboratory's Match by meaning instructions are rewritten in
    English (for example "Abbina ogni parola al suo sinonimo." becomes
    "Match each word with its synonym.").
  - Demo questions that move to Instruction or context are regenerated
    through the generators.
  - Regenerate the v12 assets, the v11 fixtures (`course_v11()`) and the
    Laboratory presentation baseline (`QQL_RECORD_PRESENTATION`), and
    list every deliberate change in the validation document.
  - Run `tools/validate_courses.py`.
- **Tests:**
  - An authored prompt with no language replaces the line; one with a
    language doesn't; without one the standard line shows.
  - Spell the word in the picture versus Spell the word.
  - The Duel's fallback line appears only with audio.
  - No empty question line.
  - Field labels and field lists (`exercise_field_help_*`).
  - Save refuses an empty Question or sentence.
  - Recipes still represent every regenerated demo exercise.

## 5. Revision 2: Complete the text and Put the sentences in order

**Complete the text**
- Form:
  - Instruction or context (optional), first;
  - Text with the words to hide;
  - Missing words;
  - **Hint (optional)**.
- Recipe:
  - the instruction is written as a `clue` text with no language in
    `PresetVariants.finish`, because the `missing_word` recipe consumes
    its `primary` text as the passage;
  - `decompose` reads it back;
  - the hint already survives this recipe.
- Help EN/IT/ES: the preset body and description mention both new
  fields.
- Missing letters doesn't get an instruction field.

**Put the sentences in order**
- Form:
  - Instruction or context (optional);
  - **Lines, in the correct order** ("One line per line, in the order the
    learner must find. They are shuffled for the learner.");
  - **Extra lines (optional)** ("0, 1 or at most 2", advice as today);
  - **Hint (optional)**.

  "Sentences or lines" and "Correct order" are gone.
- Recipe: it joins `PresetRecipes.canonicalOnly` with
  `_buildSentenceOrder`, modelled on `_buildPictureBlocks`.
  - The `clue` Instruction.
  - Items with role `primary`, IDs kept by text.
  - **The stored item order is kept** (new lines at the end), so the
    regenerated demos match exactly. The runtime shuffles anyway.
  - One `exactOrder` correct order, as today.
  - The hint.

  `decompose` fills `order` and `extraWords` as it does for Name what you
  see.
- Help EN/IT/ES:
  - rewrite `sentence_order.order`;
  - add `sentence_order.extraWords`;
  - give `sentence_order.prompt` its own text (it borrowed Match's Help);
  - retire `sentence_order.tokens`.

**Learner screens**
- `_missingWordExercise` shows the hint under the gapped text (key
  `gap-fields-hint`). Missing letters' Hint, which learners have never
  seen, shows too.
- It draws Play audio only when the exercise has audio (finding A). The
  audio itself is unchanged.
- `_wordOrderExercise` shows the hint above the blocks (key
  `order-hint`), which also delivers Name what you see's Hint
  (finding B).

**Search:** add `_hint` to both presets' definitions.

**Content**
- **Piedmontese Lesson 18**, hints:
  - e01 "One meows, one barks."
  - e02 "Something to eat and something to drink."
  - e03 "Something you read.", plus the instruction "You are at home, on
    the sofa."
- **Piedmontese Lesson 21**, Instructions as context:
  - e01 "Tòni meets Anna in the street and greets her first."
  - e02 "Anna goes to the market in the morning and is home by noon."
  - e03 "In the evening you have dinner, then you read in bed.", plus
    the hint "The last line is what you say before sleeping."
- **Laboratory:**
  - Complete the text: the instruction "Anna's morning before work." and
    the hint "A drink, then a way to travel."
  - Put the sentences in order, the story: "Anna stops at the bar for a
    coffee."
  - Put the sentences in order, the dialogue: "At the bar: a customer
    orders a coffee.", plus one extra line and a hint.

**Tests**
- Recipes, including item IDs kept by text when lines are reordered or
  edited.
- The hint panels, and their absence when empty.
- No Play audio without audio.
- `HINT_REVEALS_ANSWER` for a gap answer.
- The regenerated demos.

## 6. Revision 3: the Listen and answer split

Listen and answer's optional Question does two jobs in the demos:
- an instruction: "Choose the greeting you hear.", "What did you hear?";
- a real question: "Dove fa la spesa Maria?", "What does the speaker
  have?".

By decision 3 it splits:

- **Listen and choose** (to target, to source), new IDs such as
  `listening_choose_target` / `listening_choose_source`: no question and
  an optional Instruction or context.
- **Listen and answer** (to target, to source), keeping the existing
  IDs: a **required** Question.

The recording is unchanged in both.

Work:
- registry entries (Listening group, twins, directions, `base`);
- `PresetRecipes.kinds`;
- the field lists, forms and search definitions;
- Help EN/IT/ES for the two new presets and the changed fields;
- `tools/qql_course_v12.py`'s preset maps;
- the Laboratory and Piedmontese generators (the Piedmontese demo keeps
  one Lesson per preset) and the regenerated Courses and baseline;
- tests.

Listen and pick the image is not split: its optional question becomes
Instruction or context in Revision 1.

## 7. Open points

None. Both were resolved on 29 September 2026:
- Recognize characters' "Text prompt" becomes Question or sentence
  (decision 12). Its image-to-text instruction stored with no language
  ("Select the character shown.") follows the rule in §4.1.
- The prompts that hold material are in scope, labelled "Sentence" and
  "Clue (source language)" (decision 11).

## 8. Separate findings (not in this plan)

- **C.** Missing letters' "optional" spoken text is stored as required
  audio. With Audio Exercises off, the whole exercise is skipped
  (reading and listening material, decision 4).
- **D.** The standard line for typed gaps reads "Choose the word that
  completes the sentence." in all eight languages. An authored
  instruction now replaces it, but it stays wrong when none is written.
- **E.** Whether an Arrange counts as lines (`isLineOrder`) is guessed
  from the text. A short line such as "Ciao Anna" makes a Put the
  sentences in order play under PUT THE WORDS IN ORDER.
- **F.** Spell the word and Spell what you hear show the standard line
  "Build the word shown in the image.", but they have no image.

## 9. Every revision

- Version and Beta expiry (the pinned files in the version-bump list).
- `CHANGELOG.md`, validation and handoff documents, and the `AGENTS.md`
  release entry.
- The complete suite once, on the final tree.

Scoring, progression, Review, the Course format and learner data are
unchanged throughout.
