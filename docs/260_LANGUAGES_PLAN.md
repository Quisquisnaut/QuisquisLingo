# Build 260: Course languages and learner localization (plan)

Owner decisions of 1 October 2026, taken in chat after a discussion of
pros and cons.

## Decisions

1. **Language selector.** New Course no longer takes free text for the
   Source and Target language. Each field lists the languages by their
   English name, with a search; a language that is not in the list is
   typed by hand, with an optional tag. The Course stores the name and the
   tag.
2. **The list.** Every two-letter ISO 639-1 language and a curated set of
   three-letter ISO 639-3 regional and minority languages (nap, pms, vec,
   lmo, lij, scn, fur, lld, egl, rgn, ast, mwl, …): 227 languages.
3. **Earlier Courses.** Course Info may add the tag of a language an
   earlier Course wrote by name. It may not change the language: a stored
   tag stays, a base language QQL recognizes takes only its own tag, and a
   learning language tag must keep the language code of XP and streaks.
4. **Instruction language.** The learner panel's lines are in the Course's
   base language (not the learner's Help Language). The instruction
   languages are English, Spanish, Italian, German, Portuguese, Dutch and
   French; Finnish and Welsh, reviewed one by one, are removed; any other
   base language gets English.
5. **Language names in the lines** ("Translate into …"): a table names
   about 60 common languages in the seven instruction languages; any other
   language keeps its English name; a Course may give its learners' own
   name for the learning language (Course Info, "Learning language name
   for learners").
6. **Phases.** Revision 0: the list, the selector, the tags, Course Info,
   the seven instruction languages with French, the names, the structure
   (one file per catalog, English fallback per key, a completeness test).
   Revision 1: the learner panel's buttons and messages (Check, Continue,
   Hint, Correct answer, Before you start, the end-of-Round summary, the
   Duel, Review) in the seven languages.
7. New translations are AI-written, pending native review.
8. **Three independent language settings** (owner clarification): QQL's
   own interface is in English; Help and Course Info follow each learner's
   Help Language (English, Spanish or Italian); a Course's learner panel
   follows the Course's source language when it is one of the seven,
   otherwise English. Help EN/IT/ES and the QQL Guide say so.
