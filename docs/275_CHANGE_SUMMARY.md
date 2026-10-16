# Build 275 change summary

Courses in the same language (`docs/SAME_LANGUAGE_COURSES_PLAN.md`, the
owner's idea and decisions of 16 October 2026).

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
