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

## Next

Revision 1: the learner panel's buttons and messages in the seven
instruction languages (plan point 6).

Draft in progress: about 100 strings (buttons, feedback, the end-of-Round
summary, Before you start, the Duel, the Review page) in a new catalog
per language (`lib/localization/learner_panel/`), following the same
instruction language as the exercise lines. Error, audio-setup, version
and author Preview messages and Report a problem stay in English.

Stage with `git add -A -- . ':!devtools_options.yaml' ':!tools/cloud_setup.sh'`
after checking `git status` for files another session wrote.
