# Build 275 handoff

Branch `build-275` from `main` `053b8025` (Build 274 fast-forwarded into
`main` and pushed on 16 October 2026 at the owner's go; `build-274` deleted
locally and on origin). Plan: `docs/SAME_LANGUAGE_COURSES_PLAN.md`, the
owner's decisions of 16 October 2026 (Courses in the same language). Every
revision: version `2.0.75+275RRR`, Beta expiry 30 days from its release day,
`CHANGELOG.md`, `README.md`, the `AGENTS.md` release entry,
`docs/275_CHANGE_SUMMARY.md`, `docs/275_VALIDATION.md`, this file; focused
tests while working (a new widget test file is run six times or more
before the suite), an independent read-only review, `flutter analyze` and
the complete suite once on the final tree; one commit, the branch pushed.
Help EN/IT/ES wherever a screen or a rule an author reads changes; when a
learner catalog changes, `docs/LOCALIZATION_CURRENT_STATE.md` follows it.

## Revision order

| Rev | What | State |
|---|---|---|
| 0 | Choosing the kind of Course (Wizard, New Course, Course Info, the FAQ) | done, `db0bd468` |
| 1 | What learners read ("word" and "meaning") | done, `2d524fec` |
| 2 | The creator's choice of kind is stored (owner, 17 October 2026) | done, `46c494ce` |
| 3 | Meanings (Word Lookup, speakers, neutral lines), the Wizard's question (owner, 17 October 2026) | done, `cb4c7de1` |
| 4 | What authors read (preset names, forms, GuideBook), New Course's question | done, `7093393b` |
| 5 | A test Course to import (En-En Exercise Lab); the test Courses in `test_courses/` (owner) | done |
| 6 | Several correct translations in the GuideBook | moved to Build 277 (owner, 17 October 2026) |

## Open points for the owner

- Closed: the FAQ's English text (the plan's draft, adjusted to the
  screens: the kind is chosen in the Wizard or in New Course's form; two
  variants of one language make a translation Course, typed by hand with
  their tags; "typing a meaning" until Revision 4 names the preset) was
  approved by the owner on 16 October 2026 ("All good").
- Closed: Revision 6's display of alternatives, option E (every form in
  full, the translation once; owner, 17 October 2026, written into the plan
  as decision 17 by the session "Next version ideas"; renumbered from 13,
  which Revision 2 uses).
- Closed on 17 October 2026 (Revision 3): Word Lookup on meanings and a
  speaker for meanings (both yes), "word" for a sentence (neutral lines,
  titles kept); the Wizard's first step stays read-only and Continue with
  Wizard asks first; Save writes, Apply only changes the working copy
  (already so everywhere).
- Closed: New Course's Continue to Editor asks the same question as the
  Wizard (owner, 17 October 2026; Revision 4).
- Closed (owner, 17 October 2026: leave it): in a Course of synonyms
  whose GuideBook pairs both ways (glad = happy, happy = glad), looking up
  a meaning's word in Pick the word or Type the word shows the answer.
- To do in a later revision (owner, 17 October 2026): the reading-derived
  exercises dialog and the Round Wizard's findings show raw preset IDs
  ("type translation to target") in both kinds of Course; show the
  presets' names.
- The FAQ describes the finished Build: until Revisions 1 and 4 a
  same-language Course's exercises and forms still say translation,
  source and target (said in the CHANGELOG).
- Closed by Revision 2 (the kind is stored, nothing derived): the two
  points below.
- Rule edges the review found, left as the plan words them: a variant or
  extlang subtag is ignored (`de-1901`/`de-1996`, `zh-yue`/`zh` count as
  the same language), and a script on one side with a region on the other
  is the same language (`zh-Hant`/`zh-CN`). The list holds languages
  without regions, but a language typed by hand takes any tag: "Chinese
  (Traditional)" `zh-Hant` against "Chinese (Mainland)" `zh-CN` is refused
  as one language twice, while `zh-Hant`/`zh-Hans` is accepted. Owner's
  call whether a script on one side and a region on the other should make
  two languages.
- Course Info's Add the language tags from the list checks the two tags
  together: an earlier Course whose two tags would change its kind gets
  neither, even one that alone would be fine. The kind is protected;
  owner's call whether to offer the tags one at a time.

## Revision 5 (2.0.75+275005): a test Course in the same language

- Owner request of 17 October 2026: the test Courses in a new folder,
  `test_courses/`; no outside users to worry about.
- Done: the move (generators, tests, current docs), the Lab's builder
  made configurable, `tools/generate_same_language_lab_275.py` and
  `test_courses/exercise_lab_en_en.json`, the Audit's identical-languages
  warning only for a translation Course, the tests, version 275005, the
  documents.
- Done: the independent review and its corrections (content, the
  Flashcard's meaning-first line, documents).
- Done: six clean runs, `flutter analyze` clean, complete suite 4,988
  passed, 1 skipped, 1 failed (a ZIP time stamp a second apart in
  `file_dialogs_240_test`, passing alone). Committed "Build 275 Revision
  5: a test Course in the same language" and pushed `build-275`.
- **Change of plan (owner, 17 October 2026): Build 275 ends with Revision
  5.** The plan's Revision 6 (several correct translations in the
  GuideBook, to be split in two: the GuideBook syntax and alternatives,
  then the Round Wizard) and the later revision for the raw preset IDs of
  two earlier dialogs move to **Build 277**; the modularization leftovers
  (Build 273's Revisions 10 to 12) to **Build 278**. **Build 276** is the
  owner's new brief: let learners hear every target-language text a
  Course has a voice for, and keep an elision's apostrophe in the audio
  key (`AudioSegmenter.key`).

## Revision 4 (2.0.75+275004): what authors read

- Done: `nameIn` / `offeredIn` / `directionIn` and every caller, the
  planner, the forms, the GuideBook page and its field Help, the samples,
  Exercise Help, New Course's question, Help EN/IT/ES,
  `LOCALIZATION_CURRENT_STATE`, tests, the documents, version 275004, six
  clean runs, the independent review.
- Done: the review's corrections (the Story Wizard's step cards and the
  Exercise Wizard's plan, the Audit's messages and the publish gate,
  `descriptionIn` / `directionOfIn`, the GuideBook messages and Paste list,
  the form's errors, "I would like {just} an espresso" and the bills'
  pictures, a retired ID, New Course's message), their tests and documents.
- Done: the re-review (a new reader: the first reviewer could not be
  reached after the session's context was summarized) and its
  corrections: field Help, the New Course sample, the Audit's kinds and
  families, Read and answer, Exercise Help's search, the title Help, the
  Wizard's empty GuideBook line, the documents; 22 tests.
- Done: six clean runs (23 tests), `flutter analyze` clean, complete
  suite 4,981 passed, 1 skipped. Committed "Build 275 Revision 4: what
  authors read in a same-language Course" and pushed `build-275`. Next:
  Revision 5 (the En-En test Course).
- Owner's answers of 17 October 2026 (plan decisions 19 to 22): the
  sample kept; the remaining Help texts fixed in this revision (Listen
  and answer's Question, the GuideBook picture); the raw preset IDs of two
  earlier dialogs in a later revision of their own; the Word Lookup case
  of synonyms paired both ways left as it is.

## Revision 3 (2.0.75+275003): meanings, and the Wizard's first step

- Owner decisions of 17 October 2026 (the plan's decisions 14 to 16; the
  later revisions renumbered 4 to 6).
- Done: Word Lookup and the speakers on meanings (`sameLanguage` flags on
  `WordLookupScope`, `PlaybackOnRequest`, `CourseAudioUsage`,
  `ExerciseMascotRoom`), the four neutral lines in seven catalogs, the
  Wizard's question (`CourseWizardScreen.confirmsLanguages`), Help
  EN/IT/ES, tests, version 275003, the plan, CHANGELOG, README, AGENTS,
  change summary, validation, `LOCALIZATION_CURRENT_STATE`.
- Done: the independent review and its re-review (corrections in
  `docs/275_VALIDATION.md`: two speakers after an answer, the note once,
  the lookup proved with a GuideBook entry, the learner's Round with audio
  off, three lines, Help); six clean runs; `flutter analyze` clean.
- Done: complete suite 4,958 passed, 1 skipped. Committed "Build 275
  Revision 3: meanings, and the Wizard's first step" and pushed
  `build-275`. Next: Revision 4 (what authors read).

## Revision 2 (2.0.75+275002): the creator's choice is stored

- Owner decision of 17 October 2026 (the plan's decision 13; Revisions 2–4
  of the plan became 3–5).
- Done: `Course.sameLanguage` (model, JSON, validator, format document);
  the two forms store the kind; the copies keep it; `minimumAppBuild`
  275002; `identicalChoices` replaces the derivation; Course Info's tag
  check removed; the change list names the field; Help EN/IT/ES; tests;
  version 275002 (`bump.py 275001 275002`); the plan, CHANGELOG, README,
  AGENTS, change summary, validation.
- Note: `dart format lib` once reformatted eleven files outside this
  revision (lines left long by earlier commits); they were restored with
  `git checkout` so only this revision's files change. Format the files
  edited, never the whole folder.
- Done: the independent review (nothing blocking; corrections in
  `docs/275_VALIDATION.md`: the Merge refused two kinds in one order only,
  the Help's tag hint, New Course's form no longer infers a kind, the
  validator's check, the tests); focused tests pass (93 in seven files).
- Done: the re-review (corrections right; its last points corrected), six
  clean runs, `flutter analyze` clean, complete suite 4,947 passed,
  1 skipped. Committed "Build 275 Revision 2: the creator's choice of kind
  is stored" and pushed `build-275`. Next: Revision 3 (what authors read; now Revision 4),
  after the owner's answers to the open points.

## Revision 1 (2.0.75+275001): what learners read

- Done: `ExercisePresetRegistry.sameLanguageNames`, `ExerciseTitle`
  (`sameLanguage:`), `ExerciseCopyService` (`typeLabel` with features,
  `_asksMeaning`, `_sameLanguageLine`), `LearnerPanelText.sameLanguageKeys`,
  `CourseLanguagePair`'s cache; 14 exercise-copy and 6 learner-panel keys
  in the seven catalogs; the localization document; version 275001 (release
  17 October 2026, Beta expiry 2026-11-16); CHANGELOG, README, AGENTS,
  plan, change summary, validation; `test/same_language_learner_275_test.dart`.
- Owner points of this revision, not done (the plan's "to confirm"):
  Word Lookup still skips meanings (text marked as the source language)
  in a same-language Course; playback on request still offers no speaker
  for a meaning.
- Owner points the review found: "word" also labels a sentence (a Pick
  the word whose options are sentences reads "Choose the word for this
  meaning."; a Type the meaning of a sentence "Write the meaning of this
  word."; Revision 4's Type whole sentences will read TYPE THE WORD), as
  the owner's names say; the lines could be made neutral. A Flashcard
  shown meaning first says "Think of the English word…" in an English to
  English Course (harmless).
- Done: the independent review and its re-review (corrections in
  `docs/275_VALIDATION.md`); `flutter analyze` clean.
- Done: complete suite 4,944 passed, 1 skipped.
- Committed `2d524fec` "Build 275 Revision 1: what learners read in a
  same-language Course" and pushed `build-275`. Next: Revision 2 (what
  authors read), after the owner's answers to the open points above.

## Revision 0 (2.0.75+275000): choosing the kind of Course

- Done: `CourseLanguagePair` and `CourseKind`
  (`lib/services/course_language_pair.dart`); `CourseKindChoice`
  (`lib/widgets/course_kind_choice.dart`); the Course Wizard's Basics (the
  cards, one Language field, the checks, the kind shown once the Course
  exists, the explanation); `CourseWizardBasics.kind` and the same-language
  examples (`CourseWizardSample.sameLanguageBasics`, `basicsFor`,
  `aboutFor`, `lessonsFor`); New Course's form and dialog; Course Info and
  the Course Info Editor; Editor Help `courseKind` EN/IT/ES and the two
  answers that point to it; `courseInfo.sameLanguage`; the localization
  document; version 275000; CHANGELOG, README, AGENTS, plan, change
  summary, validation; `test/same_language_courses_275_test.dart`, the
  nine test files that create a Course by hand and the two that count the
  Help questions.
- Done: the independent review and two re-reviews (corrections in
  `docs/275_VALIDATION.md`), the last check found nothing; `flutter
  analyze` clean.
- Done: complete suite 4,935 passed, 1 skipped. The owner approved the
  FAQ text (16 October 2026: "All good").
- Committed `db0bd468` "Build 275 Revision 0: choosing the kind of
  Course" and pushed `build-275`. Next: Revision 1 (what learners read).
- Offered to the owner, not done: a line under the two language fields
  saying how to enter two variants (today the refusal and the Help say
  it).
