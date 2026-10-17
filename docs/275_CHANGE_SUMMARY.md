# Build 275 change summary

Courses in the same language (`docs/SAME_LANGUAGE_COURSES_PLAN.md`, the
owner's idea and decisions of 16 October 2026).

## Revision 2 (2.0.75+275002): the creator's choice of kind is stored

### Before

- QQL worked out the kind from the two languages: the same language on
  both sides (by tag, or by name for a language typed by hand) made a
  Course in the same language. Two variants of one language had to be
  typed by hand with their tags (English (UK) with en-GB) to make a
  translation Course, and Course Info refused tags that would have changed
  the kind.

### Now

- The creator's choice is kept in the Course file (`sameLanguage`) and
  decides alone. A Course made In the same language asks for this build or
  later.
- Through another language accepts any two languages, two variants of one
  language too (English (UK) and English (US)); it refuses only one
  language written twice. In the same language keeps one Language field.
- The copies (Fork, Copy as New Course, Move/Copy to another Lesson) keep
  the kind; a Merge of two kinds is refused in either order (the review
  found that the earlier comparison refused it in one order only).
- New Course's form no longer picks a kind for two prefilled languages.
- The Help says the creator decides and QQL keeps the choice.

### Owner decision (17 October 2026)

- "The creator chooses whether the course is "same language" kind or
  "through another language" kind. … it's up to creators to decide which
  pairs are "same language"." Agreed the same day: one Language field for
  In the same language; Through another language refuses only one language
  twice.

### What does not change

What learners read in each kind (Revision 1), the forms' two cards and
Which should I choose?, Course scoring, progression and learner data. An
English to English Course made before this revision without the new field
is now a translation Course (only the owner's test Courses were made with
Revisions 0 and 1).

## Revision 1 (2.0.75+275001): what learners read

### Before

- A same-language Course's exercises said "Pick the translation",
  "Translate into English." and "Correct translations:".

### Now

- They say "word" and "meaning": PICK THE WORD / "Choose the word for
  this meaning.", TYPE THE MEANING / "Write the meaning of this word.",
  BUILD THE SENTENCE, MATCH WORDS AND MEANINGS, "Correct answers:", and
  Word Lookup offers "one possible meaning". No language is named.
- In the seven learner languages; Round, Review, Duel and Preview alike.
- The Round Wizard's Build prompt reads "Build the sentence for “…”." in
  a same-language Course (it said "Build the translation of “…”."), and
  the screen reader counts "correct answers" there.

### Owner decisions (16 October 2026)

- Names change for learners (and, in Revision 2, in the Course Editor);
  the stored preset IDs never change.

### What does not change

A translation Course; what Word Lookup looks up and which texts offer a
speaker (both open points for the owner); Course files, scoring and
learner data.

## Revision 0 (2.0.75+275000): choosing the kind of Course

### Before

- New Course asked for a title and two languages. A Course could already
  have the same language on both sides, but nothing asked for it, said
  so, or helped to choose.

### Now

- The Course Wizard's first step asks **What kind of Course?** with two
  cards, neither chosen at first: **Through another language** (two
  language fields, as before) and **In the same language** (one
  **Language** field, written on both sides). Continue says what is
  missing, and refuses Through another language with one language twice.
- New Course's form (Continue by hand) has the same cards, filled in from
  the Wizard.
- **Which should I choose?** opens a new Editor Help answer: how each kind
  works and its didactic pros and cons, with advice for beginners and for
  learners from intermediate level up.
- Fill with an example follows the kind: "English at the café" for In the
  same language; the About and Lessons examples follow it.
- Once the Course exists, its first step shows its kind; Course Info and
  the Course Info Editor say "Same-language Course".

### Owner decisions (16 October 2026)

- Any language to itself, not only English.
- Two variants of one language (British to American English) are not the
  same language; a region on one side only is.
- The kind is chosen first, with a direct link to the new Help answer.
- Fill with an example follows the kind (default e).

### What does not change

The Course files (the kind is never stored, it comes from the two
languages), what learners read in the exercises (Revision 1), the names
authors read (Revision 2), scoring, progression and learner data.
