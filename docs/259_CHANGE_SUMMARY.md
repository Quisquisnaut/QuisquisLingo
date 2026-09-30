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

## Revision 3 (2.0.59+259003, 30 September 2026): the owner's review

Owner review of 30 September 2026, points A–H, with the answers to the four
open questions: to-source line "Select the meaning of what you heard.";
title "What is in the picture?" with the line "Choose the option that fits
best."; the three typed-gap lines; "Arrange the lines in a logical order.".

**A. Type what you hear.**
- The v11 converter already stored the Audio text as a literal answer, so
  the "Missing word" box only repeated it. The box is now **Other accepted
  spellings (optional)**: another way to write the same words, one line per
  spelling, alternatives such as `alle [9|nove]`.
- A Published save needs nothing in it. The Audit's missing-answer rule
  and `tools/validate_courses.py` count a literal answer.
- Field Help and Help EN/IT/ES drop the syntax a dictation does not need
  (reordering, optional words, linked alternatives).
- The Laboratory: the variants example accepted "io sono felice" for
  "Sono felice." ("io" is never heard). It now plays "Arrivo alle otto."
  and also accepts "arrivo alle 8". The word and sentence examples, and the
  Piedmontese dictations, no longer repeat their Audio text.

**B and H. Listening lines.** `ExerciseCopyService.instructionForExercise`
picks the line from the exercise:
- a question: "Listen and answer the question." (both Listen and answer
  shapes);
- no question, answers in the language studied: "Select the sentence that
  you heard.";
- no question, answers in the source language: "Select the meaning of what
  you heard.";
- picture answers (Listen and pick the image) and gaps keep "Listen and
  choose the correct answer.".

The Instruction or context helper of Listen and choose quotes its line
(`instructionVariant`).

**C. What is in the picture.**
- A new learner kind, `selectPicture` (a Select under a `picture`),
  gives the title **WHAT IS IN THE PICTURE?** and the line "Choose the
  option that fits best.".
- A Published save needs the picture (`pictureRequired`).

**D. The feedback comes into view.**
- In a short window, the feedback panel of a tall exercise (Sort into
  groups) fell below the screen after Check. The list builds lazily, so
  the panel, with its Finish round button, was not even drawn.
- A test at 800 × 450 reproduced it: no Finish round without the change.
  Now `RoundScreen._revealFeedback` scrolls the page to the panel after an
  answer, a card result or a skipped exercise. A scrolling Story keeps its
  own scroll.

**E. Typed gaps.** "Choose the word that completes the sentence." was
wrong for a typed exercise. The kind `inputComplete` now reads:
- "Type the words that complete the sentence.";
- "Type the word that completes the sentence." with one gap or one field;
- "Type the missing letters." when the gaps are inside words
  (`ExerciseFeatures.gapsInWord`, moved from the Round screen).

**F. Complete the text with ___.**
- The text marks each gap with ___. Missing words gives one line per gap,
  in order; a line may accept several answers (`[il|un] gatto`).
- The preset has its own recipe (`_buildCompleteText`). The stored shape
  is unchanged (inline gap targets `gap_1`…, `targetAnswers`), so existing
  exercises reopen in the form.
- A Published save checks that there are gaps, that their number matches
  the lines, and that each line is a valid expression. A draft keeps its
  text even without gaps.
- The correct-answer line shows the first accepted answer ("il treno"),
  keeping the author's small letter.
- The Laboratory's `complete_text_alternatives` ("Luca prende ___ alle
  otto.", `[il|un] treno`) joins its Round in the canonical shape after
  the v11 conversion; the v11 fixture omits it.

**G. Put the sentences in order.** "Arrange the lines in a logical order."
no longer repeats the title.

**Languages and Help.** The new and changed lines are in the eight learner
languages (EN, ES, IT, DE, PT, NL, FI, CY). Help EN/IT/ES covers Type what
you hear, Complete the text and What is in the picture.

Scoring, progression, Review, the Course format and learner data are
unchanged.

## Revision 4 (2.0.59+259004, 30 September 2026): the second review

Owner review of 30 September 2026 (evening), points 1–10, with the answers
to three questions: Drag the blocks into the gaps merges into Pick the words
for the gaps, where each word fills one gap ("the drag action does not
actually work, it also picks"); the new preset is **One word fills all**
and one tap fills every gap; `_word_` replaces `{word}` in every gap
sentence, Missing letters included.

**1. Pictures required.** A Published save of Type what you see and Name
what you see needs the picture, as What is in the picture has since
Revision 3.

**2. No file paths for learners.** `ExerciseItem.value` falls back to the
picture's asset path. The Round's Match left label, the captions of
picture answers, the correct-answer line and the Duel now use the new
`ExerciseItem.label` (text, else spoken text, never a path). Match picture
to word showed the path beside every picture.

**3. Spelling lines.** `arrangeWord` without a picture reads "Build the
word you hear." (automatic audio: Spell what you hear) or "Build the word
that matches the clue." (Spell the word). With a picture it keeps "Build
the word shown in the image.".

**4–7. Piedmontese hints.**
- Name what you see: "Include the article." on the three examples.
- The evening story: "mangio = I eat; leso = I read. The last line is
  what you say before sleeping.".
- Missing letters: "An animal that meows.", "The opposite of small.",
  "Something you drink.".
- The shopping list: "Bread and water, in Piedmontese.".
- The Laboratory's Name what you see also asks for the article.

**8. Gaps written `_word_`.**
- The Sentence with gaps field reads and writes `_answer_`, and a lone
  `_` is refused (`ExerciseDraftBuilder._gapBracePattern`).
- Missing letters reads and writes `dr_ink_` (`PresetVariants.draftFor`,
  `ExerciseFeatures.markedSentence`, which replaces `bracketedSentence`).
- `{…}` and `[…]` stay for the answer syntax. Stored exercises are
  unchanged: only the form's marks change.
- Field Help, Help EN/IT/ES and the error messages follow.

**9. Pick the words for the gaps and One word fills all.**
- `gap_blocks` (an Arrange with inline gaps, each word used once) is
  renamed **Pick the words for the gaps** and takes the former preset's
  place in the catalogue.
- The Select-based `gap_choice_inline` is retired to it
  (`presetSuccessorOf`, `PRESET_SUCCESSOR`). A stored Select whose option
  fills several gaps still plays, but no preset represents it: the Course
  Editor opens it in the canonical editor, and the v11 converter (Dart and
  `tools/qql_course_v12.py`) records no preset for such a Choose.
- An Arrange with inline gaps reads "Pick a word for each gap."
  (`instruction.arrangeGaps`).
- **One word fills all** (`one_word_fills_all`, base Pick the missing
  word) is new: a Select whose question holds two or more ___
  (`LearnerExerciseKind.selectCompleteAll`), with the title ONE WORD FILLS
  ALL and the line "Choose the word that fills every gap.".
- Once answered, the chosen word appears in every gap
  (`RoundScreen._questionShown`).
- A Published save needs two gaps (`blanksTooFew`). A one-gap question
  stays Pick the missing word. It has its own form (Sentences, Answer
  words, Correct answer number, Hint), Help and Search.

**Languages and Help.** Five new lines in the eight learner languages
(`arrangeWordHeard`, `arrangeWordClue`, `arrangeGaps`, the One word fills
all title and line). Help EN/IT/ES: the merged preset, One word fills all,
the gap and Missing letters fields, the picture presets.

**Demos.**
- Laboratory: the four reusable-option gaps of the Select Lesson become two
  One word fills all examples (124 examples). The Arrange Round is named
  Pick the words for the gaps.
- Piedmontese: one Lesson each for Pick the words for the gaps and One
  word fills all (41 Lessons; Lessons 18–20 renumbered).
- Edge Case: e17–e19 fill their gaps with words; e18 offers "Was" twice.
  The Edge Case v11 converter fixture is updated for those items only; its
  checksum was already stale and is left as it was.

Scoring, progression, Review, the Course format and learner data are
unchanged.

## Revision 5 (2.0.59+259005, 30 September 2026): the third review

Owner review of 30 September 2026 (night), points 1–5, with two answers in
chat: the exported Edge Case goes to the Quick Import folder
`Import/Courses`, and the Course stays in the repository as a Course ready
to import.

**1. Match pictures to words.** The preset `picture_word_match` was "Match
picture to word". The name changes in the registry, Help EN/IT/ES, the
Audit messages and the Piedmontese demo's Lesson.

**2. At least two words.** A Published save with one word was accepted
(a Match with one pair). It is now refused with "Words: enter at least two
words, one per line." (`ExerciseDraftErrorCode.wordsTooFew`). The builder
counts the words in the `picture = word` lines the form sends. A Draft
keeps what it has.

**3. No Exercise image.** The form offered the shared Exercise image above
the pictures of the words. It is gone from the form, from the field list
and from the field Help map. The editor Help's "Which exercises use a
picture?" says Match pictures to words has one picture per word instead.

**4. Stories.**
- A scrolling Story showed "Story · N steps" above the title block, then
  "Now · step k of N" above every later step. The step count now stays
  above the title block and no "Now" line appears. An invisible anchor
  still marks the active item, which the page scrolls to the top.
- A Dialogue line showed an instruction under the bubble ("Read or listen,
  then continue.", "Read, then continue.", "Listen, then continue.",
  "Listen first; the text appears after."). No line is shown now; the
  bubble and its Continue button say what to do.

**5. The Edge Case leaves the bundle.**
- `CourseService.courseAssets` holds the Exercise Laboratory and the
  Piedmontese demo. The Edge Case's bundled identity stays reserved, as the
  earlier demos' do. Progress recorded on it stays on the device, unused.
- A bundled official Course is never imported, so the Course to import is
  a custom Course with its own identity: `demo_courses/edge_case_it_en.json`
  (Course version 1, QQL-user Maintainer, derivative works allowed, so an
  importer can Fork it). Its content is the former bundled Course's.
- The Edge Case generator writes it and the official test fixture
  `test/fixtures/v12/edge_case_it_en.json` (the former asset, moved), which
  the tests that need a bundled Course with Draft content, the shared
  English code or a third Selector row register
  (`test/support/edge_case_fixture.dart`).
- The ZIP made by the app's Course export was written to the owner's
  `Documents/QuisquisLingo/Import/Courses` for Quick Import. It is not in
  the repository.

Scoring, progression, Review, the Course format and learner data are
unchanged.
