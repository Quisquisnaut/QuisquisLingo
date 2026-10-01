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

## Revision 1 (implemented, 1 October 2026)

The learner panel's buttons and messages (plan point 6): 107 keys in
seven languages (`lib/localization/learner_panel/`, `LearnerPanelText`),
used by the Round, the Duel and the Review page; error, audio-setup,
version and author Preview messages, Report a problem, Reset Word List and
Review Help stay in English. New test `test/learner_panel_260_test.dart`.

## Next

Revision 2 (owner request of 1 October 2026): a bundled **QQL Demo:
English from Italian**, one Lesson with a GuideBook: three ordinary
Rounds of six exercises (types mixed at random), a Story, three more
Rounds, a second Story at the end.

Then the owner's review of Build 260 (the AI-written translations and
names await native review).

Stage with `git add -A -- . ':!devtools_options.yaml' ':!tools/cloud_setup.sh'`
after checking `git status` for files another session wrote.
