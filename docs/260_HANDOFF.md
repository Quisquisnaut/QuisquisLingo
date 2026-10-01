# Build 260 handoff

Branch `claude/259-instructions-and-hints` (local commits only, not
pushed). Plan: `docs/260_LANGUAGES_PLAN.md`; changes:
`docs/260_CHANGE_SUMMARY.md`; evidence: `docs/260_VALIDATION.md`.

## Revision 0 (implemented, 1 October 2026)

Course languages: the list, the New Course selector, tags, Course Info
tags and the learners' name of the language, seven instruction languages
(French added, Finnish and Welsh removed), language names in the lines.
New test `test/course_languages_260_test.dart`.

## Next

Revision 1: the learner panel's buttons and messages in the seven
instruction languages (plan point 6).

Stage with `git add -A -- . ':!devtools_options.yaml' ':!tools/cloud_setup.sh'`
after checking `git status` for files another session wrote.
