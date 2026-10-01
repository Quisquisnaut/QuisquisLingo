# Build 260 handoff

Branch `claude/259-instructions-and-hints` (local commits only, not
pushed). Plan: `docs/260_LANGUAGES_PLAN.md`; changes:
`docs/260_CHANGE_SUMMARY.md`; evidence: `docs/260_VALIDATION.md`.

## Revision 0 (committed `5128f53`, 1 October 2026)

Course languages: the list, the New Course selector, tags, Course Info
tags and the learners' name of the language, seven instruction languages
(French added, Finnish and Welsh removed), language names in the lines.
New test `test/course_languages_260_test.dart`.
Complete suite: 3481 passed, 1 skipped.

## Revision 1 (committed `05c2319`, 1 October 2026)

The learner panel's buttons and messages (plan point 6): 107 keys in
seven languages (`lib/localization/learner_panel/`, `LearnerPanelText`),
used by the Round, the Duel and the Review page; error, audio-setup,
version and author Preview messages, Report a problem, Reset Word List and
Review Help stay in English. New test `test/learner_panel_260_test.dart`.
Complete suite: 3486 passed, 1 skipped.

## Revision 2 (committed `02f12d3`, 1 October 2026)

QQL Demo: English from Italian (owner request): a fourth bundled Course
(code `EN_IT`), one Lesson with a GuideBook, Pratica 1–3, Story "Al bar",
Pratica 4–6, Story "Alla stazione"; 36 exercises of 36 types mixed at
random. Generator `tools/generate_english_from_italian_260.py`, test
`test/english_from_italian_260_test.dart`.
Complete suite: 3493 passed, 1 skipped.

Reported to the owner, not changed: nine exercises of the Piedmontese
demo (Lessons 13, 25, 34) are not represented by their preset and open
in the canonical editor.

## Revision 3 (committed `ad13f3f`, 1 October 2026)

Owner review: Pick the missing word and One word fills all have an
Instruction or context; the Piedmontese demo (and QQL Demo: Piedmontese)
has every exercise represented by its preset again (Lessons 13, 25, 34);
the QQL Demo Courses keep the Before you start card on each Lesson's first
Round only. Test `test/owner_review_260_revision3_test.dart`.
Complete suite: 3500 passed, 1 skipped.

## Revision 4 (implemented, 1 October 2026)

QQL Demo titles: QQL Demo: Exercise Laboratory, QQL Demo: Piedmontese
(sorted by exercise type).

## Next (owner decisions of 1 October 2026)

- Revision 5: a computed difficulty level 0–4 per exercise (present,
  recognize meaning, recognize in the target language, build with blocks,
  type), from canonical data, never stored; a badge in the Round editor and
  a curve per Lesson.
- Revision 6: Difficulty bonus XP, 1 XP per level for each exercise answered
  correctly at the first attempt, on a Round's first completion only; a
  line in the end-of-Round summary (seven languages); XpCalculator.
- Revision 7: the QQL Demo Courses regenerated with a curve: a larger share
  of harder types in later Rounds, variety kept, picture exercises
  preferred.

The owner's review of Build 260 (the AI-written translations and
names await native review).

Stage with `git add -A -- . ':!devtools_options.yaml' ':!tools/cloud_setup.sh'`
after checking `git status` for files another session wrote.
