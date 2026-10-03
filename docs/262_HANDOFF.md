# Build 262 handoff

Branch `claude/262-publisher-courses` from `main` (`808bd69`, Build 261
Revisions 7–8 merged through PR #33). Local commits only, not pushed.
Changes: `docs/262_CHANGE_SUMMARY.md`; evidence: `docs/262_VALIDATION.md`.

Plan: `docs/PUBLISHER_COURSES_PLAN.md` (owner decisions of 2 October 2026;
it sets aside `docs/262_BUNDLED_AUTHORING_PLAN.md`). On 3 October 2026 the
owner chose for Build 262:

- Revision 0: **4.1** remove the two Piedmontese Courses from the app and
  the repository; private material to `D:\QQL_plus\Corsi_Privati`.
- Revision 1: **4.2** register the publisher QuisquisLingo Courses
  (`com.quisquislingo`): structure and tests with a **test key only**.
- Revision 2: **4.3** Export as Publisher Course (Course Studio action).

Not in Build 262: 4.4 in-app signing, 4.5 shipped Publisher ZIPs, the
owner's tasks outside the code.

## Revision 0 (2.0.62+262000, 3 October 2026; committed `5ee20a5`)

Done in the working tree: `CourseService` without `PMS`/`PMS_MIX` (IDs
still reserved in `CourseEditorService`), files moved to the private folder
and removed with `git rm`, builders moved to `tools/qql_v11_builders.py`,
`tools/validate_courses.py`, tests repointed, README, credits card,
CHANGELOG, AGENTS.md, version 2.0.62+262000 (expiry unchanged,
2026-11-02). Analyzer clean; focused tests (23 files) 282 passed;
complete suite 3589 passed, 1 skipped, 2 failed (two Course Library
counts, corrected, passing alone; the owner said not to repeat the
suite for them).
Private folder: `bundled/`, `custom/` (two importable custom Courses,
Maintainer = the owner's profile Tempesta 35932, `f2a7b4c8-…`, owner's
choice; `python make_custom_courses.py --maintainer <ID> --name <name>`),
`generators/`, `tests/`, `fixtures_v11/`, `docs/`, `LEGGIMI.txt`.

## Two private Courses (3 October 2026, outside the repository)

Owner request, before Revisions 1 and 2: two short private Courses, not
bundled, in `D:\QQL_plus\Corsi_Privati\custom`: **Viterbese per
italiani** (Italian → Viterbese, `course_99b99a4a-…`) and **Neapolitan for
English Speakers** (English → Neapolitan, `course_c2bffe3b-…`). Real Courses
of rising difficulty: three Lessons each, a GuideBook per Lesson, Rounds
Discover / Practice ×3 / Test (words, then sentences, then writing; four
choices from Lesson 2, two extra blocks in Lesson 3), Lesson and Round
label and numbering Off, GuideBook and Duels on (27 eligible questions per
Lesson). Made by `corsi_brevi/make_short_courses.py` (tables
`viterbese.py`, `napoletano.py`; `--check`), which uses this repository's
`tools/qql_v11_builders.py` and `tools/qql_course_v12.py`. Checked through
the app's custom import with a throwaway test (not committed): Audit 0
errors and 0 warnings, Duel available in every Lesson, every exercise
represented by its preset, no Round-type issue, every accepted answer
expands. Dialect answers also accept the form without apostrophes. The
texts are AI-written; `LEGGIMI.txt` there lists the points a native
speaker should check. Nothing in the repository changed for them.

Next: Revision 1 (4.2) and Revision 2 (4.3), drafted in the session's
scratchpad (code, tests, docs).

Owner decision for Revision 2 (3 October 2026): the exported Publisher
Course's official version **equals its Course version** (which rises at
every confirmed save), taken automatically; no version field.

## Gotchas

- Do not stage `devtools_options.yaml`, `tools/cloud_setup.sh` or
  `assets/lesson_plants/QQL_IT_EN_qql_demo_english_from_italian.zip`
  (untracked, not this session's).
- Never put anything from `D:\QQL_plus\Corsi_Privati` back into the repo.
