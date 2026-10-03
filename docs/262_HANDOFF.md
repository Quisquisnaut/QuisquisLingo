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
expands. Dialect answers also accept the form without apostrophes.
Owner review the same evening ("in the first Viterbese Round the same
words come back several times"): Discover Rounds are shuffled, so the
Discover Round now shows only its six flashcards; no word or sentence is
asked twice in a Round, no option is shown more than twice in a Round
and no two questions share more than one option: the generator chooses the
wrong answers with what the Round already shows and stops on a broken rule
(owner: "fix the generator itself"); 26 Duel questions per Lesson. The
texts are AI-written; `LEGGIMI.txt` there lists the points a native
speaker should check. Nothing in the repository changed for them.

## Revision 1 (2.0.62+262001, 3 October 2026; committed `b7e9ef6`)

`TrustedPublishers.quisquisLingoCourses` (`com.quisquislingo`, QuisquisLingo
Courses, `qqlc-2026-1`) with an empty public key; `application()` adds it
only once the key is set. `test/quisquislingo_courses_publisher_262_test.dart`
with a TEST ONLY key; `signWithKey` / `dummyKeyPair` in the publisher test
support. Complete suite 3598 passed, 1 skipped, 1 failed (the signing guide
must equal the English Help: the guide note was removed, the test passes
alone).

## Revision 2 (2.0.62+262002, 3 October 2026; committed `66ed376`)

Export as Publisher Course: `CourseManagerAction.exportAsPublisherCourse`,
`PublisherCourseExportScreen`, `PublisherCourseExport` (publishers,
refusals, build; official version = Course version, owner decision),
`CourseLibraryOperations.exportAsPublisherCourse` / `savePublisherCourseTo`,
`exportBaseName(publisherVersion:)`; Course Studio Help section and the
signing Help + guide (EN/IT/ES). Complete suite 3610 passed, 1 skipped,
1 failed (a Help section count, corrected, passing alone).

## The private Courses, owner review of the evening (3 October 2026)

Generator `D:\QQL_plus\Corsi_Privati\corsi_brevi\make_short_courses.py`:
six Rounds per Lesson (Discover, Recognize, Nouns and adjectives,
Sentences, Write, Check); six nouns with a picture of QQL's Image Library
and three adjectives per Lesson; picture flashcards, What is in the
picture, Select the image, Match pictures to words, Type what you see;
per Round: nothing asked twice, no option shown more than twice, no two
questions (matching included) sharing more than one option; gap wrong
answers only from the tables, checked never to fit (owner: «Ndo' annamo
mo'?» was right too); the same exercise never twice in a Lesson. Owner
review of the night: a Course from Italian (`AVOID_ITALIAN`) teaches no
word that is Italian too or almost the same (`corsi_brevi/italian_check.py`:
LibreOffice's Hunspell it_IT dictionary plus similarity .90, the wider
check the owner chose; similarity on the words without articles). The
owner then gave a Viterbese dictionary (F. Nappo, V. Galeotti, "Dizionario
italiano - viterbese", his `Downloads/VITERBO.pdf`): Viterbese is rebuilt
in 3 Lessons with its words and spellings (city forms; local variants and
coarse words left out; sentences written for the Course), 176 exercises,
Duel 33-35/25; `ALSO_MEANS` keeps a word's other true meanings out of its
wrong answers. Neapolitan (for English speakers) keeps 3 Lessons (177
exercises, Duel 34/25 each), modern Neapolitan checked against P. P. Volpe,
"Vocabolario napoletano-italiano tascabile" (1869, archive.org text) by
owner decision: Volpe's forms where still alive (peccerillo, portuallo,
doce), `corsi_brevi/fonti/volpe_report.py` lists the 24 words Volpe does
not show, for review. Audit 0/0 for both. Sources and lookup tools are in
`corsi_brevi/fonti/` (private).

Next: Build 262 is complete (Revisions 0–2). Not pushed. The owner reviews
the private Courses (`LEGGIMI.txt` lists the words to check).

Owner decision for Revision 2 (3 October 2026): the exported Publisher
Course's official version **equals its Course version** (which rises at
every confirmed save), taken automatically; no version field.

## Gotchas

- Do not stage `devtools_options.yaml`, `tools/cloud_setup.sh` or
  `assets/lesson_plants/QQL_IT_EN_qql_demo_english_from_italian.zip`
  (untracked, not this session's).
- Never put anything from `D:\QQL_plus\Corsi_Privati` back into the repo.
