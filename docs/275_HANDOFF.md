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
| 0 | Choosing the kind of Course (Wizard, New Course, Course Info, the FAQ) | in progress |
| 1 | What learners read ("word" and "meaning") | planned |
| 2 | What authors read (preset names, forms, GuideBook) | planned |
| 3 | A test Course to import (En-En Exercise Lab) | planned |
| 4 | Several correct translations in the GuideBook | planned (display option: owner's choice pending) |

## Open points for the owner

- Closed: the FAQ's English text (the plan's draft, adjusted to the
  screens: the kind is chosen in the Wizard or in New Course's form; two
  variants of one language make a translation Course, typed by hand with
  their tags; "typing a meaning" until Revision 2 names the preset) was
  approved by the owner on 16 October 2026 ("All good").
- Revision 4's display of alternatives (options A to D of the mockup;
  A recommended).
- The FAQ describes the finished Build: until Revisions 1 and 2 a
  same-language Course's exercises and forms still say translation,
  source and target (said in the CHANGELOG).
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
- To do: commit "Build 275 Revision 0: choosing the kind of Course"; push
  `build-275`. Then Revision 1 (what learners read).
