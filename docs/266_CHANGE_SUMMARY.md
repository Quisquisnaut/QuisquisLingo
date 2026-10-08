# Build 266 change summary

Build 266 is **GuideBook Modules**: a Lesson's GuideBook becomes a list of
short modules, each with Sentences, Words & Expressions and an Overview.
The owner's decisions of 5–7 October 2026 are in
`docs/266_GUIDEBOOK_MODULES_PLAN.md`; the owner gave the go on 7 October
2026, after Build 265 was merged (PR #37, `5cfb227`). Build 267 (the
Course Wizard, `docs/267_COURSE_WIZARD_PLAN.md`) builds on it.

Decisions of 8 October 2026, at the start of implementation:

- The picture prefill (Revision 1) skips Lesson icons and one-letter
  names (Roman numerals, units) and, when no name equals the word, tries
  the name before a bracket ("baker" offers Baker (man) and Baker
  (woman)); exact names still come first, so "father" finds the Father
  scene of Build 265, not Father (family tree).
- The v11 converter puts example sentences, which have no translation,
  into the module's Overview: a Sentence needs its Source.
- The plan's Revision 0 is split in two: 266000 (below) and 266001, the
  authoring aids. The complete suite runs once, at the end of 266001.

Revisions:

- Revision 0 (266000): the format, the readers, a working editor, the
  learner screens, the Audit, the converters and the content.
- Revision 1 (266001): the authoring aids: picture prefill, Paste list,
  Fill with an example, Clear all, the Overview counter, tooltips and
  examples, field Help, two new Editor Help questions.
- Revision 2 (266002): the Round Wizard (focus module, All modules, the
  review mix, real `sourceRefs`, picture exercises).
- Revision 3 (266003): content (English from Italian in modules, the
  Lab's two-module Lesson, the Edge Case module cases).

## Revision 0 (2.0.66+266000, 8 October 2026): GuideBook modules

### Format (Course Model v12, a clean cut)

- `guidebook` is `{publicationState?, modules[]}`. A module is `{id, title,
  sentences[], words[], overview}`; an entry `{id, target, source,
  context?, picture?}`; a picture `{asset, sharedImageSource?, plural?}`,
  on Words & Expressions only (`GuidebookModule`, `GuidebookEntry`,
  `GuidebookPicture` in `lib/models/course_models.dart`).
- `GuidebookText` (`lib/models/guidebook_text.dart`): `{…}` marks words a
  target may leave out (`{io} sono stanco`): validation (only `{…}`, not
  nested, not empty, words outside it; `[`, `]`, `|`, `<>` refused), the
  two forms, the display "(io) sono stanco", the display runs.
- Strict parsing: unknown keys, a blank title, target or source, a Context
  over 40 characters, a malformed brace, a picture on a sentence or with
  an asset that is not a picture reference, a `plural` that is not a
  boolean are format errors. The earlier shape (`content`, `insights`) is
  refused with `Guidebook.earlierShapeMessage`. No old-shape reading, no
  `minimumAppBuild` stamp, no checksum special case.
- `GuidebookInsight`, `GuidebookInsightsEditorScreen`, the legacy named
  arguments and the compatibility getters (`overview`, `goals`,
  `vocabulary`, `grammar`, `expressions`, `examples`) are removed.
- `LearningRound.focusModuleId` and `supportingModuleIds` (stored only when
  set; unique, never the focus; `withModules`).
- `CourseShapeLimits`: at most 100 modules and 1,000 entries per
  GuideBook.

### Readers

- Draft status and publication: the whole GuideBook is Draft or
  Published (`CourseDraftStatus.lessonGuidebookHasDraft`,
  `PublicationService.learnerGuidebook` delivers it whole or empty,
  `ProvisionalPublicationService` needs it Published and not empty,
  `asDraftAuthoringTree`).
- Pictures: `CourseImageUsage` walks the word pictures (location `Lesson N
  › GuideBook › <module> › <target>`), so IN USE, packages, save cleanup,
  Fork, Copy and Merge count them; `CourseImageRemoval` clears a word's
  picture; the Audit's own-media check and `tools/sign_course.dart` count
  them too.
- Review vocabulary (`VocabularyReviewService`): Words & Expressions only;
  the Context joins the fingerprint (an entry without one keeps its
  fingerprint), the picture does not; the card shows the picture with the
  answer and the Context in grey after it. Review Help says Words &
  Expressions.
- Word Lookup: `WordLookupSourceEntry` and `WordLookupEntry` carry target,
  source, context and picture (the engine read a `target = source` line
  before, so it changes with the adapter); both forms of a `{…}` target are
  indexed as one entry shown "(io) sono stanco"; the card shows the
  Context as a grey label after the source and the picture beside the
  target (stacked when Plural). Sentences are never looked up.
- Copies: `AuthoringDuplicationService` gives modules and entries fresh
  IDs and remaps the Lesson's Rounds (focus, supporting, `sourceRefs`); a
  Round duplicated in its own Lesson keeps its links.
  `CourseAuthoringTransferService` counts module and entry IDs in its
  identity checks; Move or Copy to another Lesson clears a Round's links.
- The Round Wizard (`GuidebookRoundGenerator`) reads every module's Words
  & Expressions and Sentences (the form without optional words) and the
  first Overview; its behaviour is otherwise unchanged until Revision 2.

### Screens

- `lib/screens/guidebook_editor_screen.dart` (exported by
  `course_editor_screen.dart`): the **GuideBook page** lists the modules
  (`guidebook-modules-list`; empty state with the example "Al bar:
  ordering and paying"; counts "4 sentences · 12 words" with a tooltip;
  drag to reorder; Remove asking first and naming how many Rounds focus on
  the module; Add module; Save Guidebook, Save Guidebook as draft, Save;
  the GuideBook ID). The **module page**: Title, Sentences and Words &
  Expressions as rows (Target, Source, Context limited to 40 characters,
  delete, drag), a picture slot on each word row (the exercise picture
  choice in a dialog, a thumbnail, a remove control and a Plural chip; a
  replaced picture keeps its mark), Overview, Done; leaving the page
  keeps the module; a row with a Target and no Source (or the reverse) or
  a malformed brace is refused and pointed to; an empty row is dropped;
  the module's and rows' internal IDs. It fits a 360-pixel window (the
  picture controls wrap).
- `GuidebookRoundLinks` (`lib/services/guidebook_round_links.dart`): after
  a GuideBook save, Rounds lose links to removed modules and `sourceRefs`
  to removed entries; `focusCount` for Remove.
- The Lesson editor's GuideBook card counts the modules.
- The Round editor's **Focus module** menu (`round-focus-module`, None and
  the Lesson's modules, a missing one named; "Also reviews: …"; a new
  focus leaves the supporting list), shown while Use GuideBook is on.
- The learner `GuidebookScreen`: the Lesson title, then each module
  (`guidebook-module-<id>`): title, Sentences, Words & Expressions,
  Overview; *target — source* with the Context in grey, "(io)" in grey, a
  word's picture as a thumbnail (`GuidebookPictureThumbnail`, stacked when
  Plural). Open GuideBook on a Before you start card opens it at the
  Round's focus module.
- Editor Help can open at a question (`EditorHelpScreen(question:)`,
  `EditorAppBarActions(helpQuestion:)`): the GuideBook pages open
  `guidebook`.

### Audit (128 rules: 66 Errors, 47 Warnings, 15 Info)

- `GUIDEBOOK_MODULE_EMPTY` (Warning, location `Lesson N · Title ·
  Guidebook · Module m`), `GUIDEBOOK_MODULE_OVERVIEW_LONG` (Info, 500
  characters or more), `ROUND_FOCUS_MODULE_MISSING` (Warning). The module
  rules wait while Use GuideBook is off; module and entry IDs always join
  the ID checks. `LESSON_GUIDEBOOK_EMPTY` now means "no module has an
  entry". `SOURCE_REF_MISSING` resolves against entry IDs (hidden Draft
  GuideBooks included). `AuthoringHierarchyStatus` counts `· Guidebook ·`
  locations as GuideBook concerns.

### Converters and content

- `lib/services/course_model_v12_converter.dart` (`_convertGuidebook`)
  and `tools/qql_course_v12.py` (`convert_guidebook_v11`): one module
  "Module 1" per Lesson (overview, goals, grammar, Insights as Overview
  paragraphs; vocabulary split into Words & Expressions; examples and
  unsplittable lines as Overview lines); notes ask to rename it, to move
  the examples and to add the lines; Draft entries make the GuideBook
  Draft. `tools/qql_course_v12.py` also has `guidebook_entry`,
  `guidebook_module`, `guidebook`, `vocabulary_pair`, `target_problem`.
- `tools/validate_courses.py` checks modules, entries, pictures (a QQL
  picture's file exists), and that a Round's modules are its Lesson's.
- Regenerated: the Lab (`MODULE_TITLES`, one module per Lesson), the Edge
  Case demo and fixture, English from Italian (one module, "Le prime
  parole"), the future fixture; rewritten: the Korean fixture, the Italian
  demo JSON and package, the dummy Publisher fixtures, signed again with
  the test key (v1, v2, media and its package, the unsigned copy and the
  payload/signature files).

### Help (EN/IT/ES)

- Rewritten: `editorHelp.qa.guidebook`, `editorHelp.qa.roundWizard`,
  `editorHelp.qa.structure`, `editorHelp.qa.wordLookup`,
  `appInfo.guidebooks`, `appInfo.wordLookup`,
  `technical.courseModel.hierarchy`, `technical.courseModel.guidebook`,
  `technical.jsonStructure.guidebook`, `technical.jsonStructure.lessonAndRound`.
  `docs/COURSE_JSON_FORMAT.md` and AGENTS.md describe the module shape.
- Field Help, tooltips beyond the module page's own, the two new Editor
  Help questions and the Round Wizard's dialog belong to Revisions 1 and 2.

### Tests

- New: `test/guidebook_modules_266_test.dart` (23: the model and its
  strictness, Round links, limits, `{…}`, `GuidebookRoundLinks`, Move,
  the Audit rules, the converter, word pictures, the GuideBook page and
  module page, 360 pixels, the learner screen and its focus, the Word
  Lookup card, the Focus menu, Editor Help at a question).
- Helpers: `test/support/guidebook_fixtures.dart` (`testGuidebook`,
  `testEntry`), `test/support/guidebook_editor_driver.dart`
  (`addGuidebookModule`). About 40 test files moved to them;
  `test/guidebook_insights_226_04_r2_test.dart` is removed (Insights are
  gone); `test/guidebook_publication_226_02_revision4_test.dart` is
  rewritten for modules.

Unchanged: scoring, XP, progression, Review order, Laurels, the Duel and
learner data (no new persisted key).
