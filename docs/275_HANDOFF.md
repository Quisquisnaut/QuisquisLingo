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
| 3 | Meanings (Word Lookup, speakers, neutral lines), the Wizard's question (owner, 17 October 2026) | done |
| 4 | What authors read (preset names, forms, GuideBook) | planned |
| 5 | A test Course to import (En-En Exercise Lab) | planned |
| 6 | Several correct translations in the GuideBook | planned (display option: owner's choice pending) |

## Open points for the owner

- Closed: the FAQ's English text (the plan's draft, adjusted to the
  screens: the kind is chosen in the Wizard or in New Course's form; two
  variants of one language make a translation Course, typed by hand with
  their tags; "typing a meaning" until Revision 4 names the preset) was
  approved by the owner on 16 October 2026 ("All good").
- Revision 6's display of alternatives (options A to D of the mockup;
  A recommended).
- Closed on 17 October 2026 (Revision 3): Word Lookup on meanings and a
  speaker for meanings (both yes), "word" for a sentence (neutral lines,
  titles kept); the Wizard's first step stays read-only and Continue with
  Wizard asks first; Save writes, Apply only changes the working copy
  (already so everywhere).
- Asked of the owner: should New Course's Continue to Editor ask the same
  question as the Wizard?
- For the owner (found by Revision 3's review): in a Course of synonyms
  whose GuideBook pairs both ways (glad = happy, happy = glad), looking up
  a meaning's word in Pick the word or Type the word shows the answer. A
  later remedy: leave the exercise's own answer out of the card.
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
