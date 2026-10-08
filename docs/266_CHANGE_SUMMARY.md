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
  examples, field Help, two new Editor Help questions (below).
- Revision 2 (266002, owner decisions of 8 October 2026): resilience: the
  class of bug found in the reset buttons fixed wherever it occurs, the
  Diagnostic Log records what the Crash Log alone recorded, Open folder for
  both logs, Delete / Forget / Open folder on the Inventory's items, and
  edge-case tests over stored data this version cannot open.
- Revision 3 (266003): the Round Wizard (focus module, All modules, the
  review mix, real `sourceRefs`, picture exercises).
- Revision 4 (content: English from Italian in modules, the Lab's
  two-module Lesson, the Edge Case module cases) is not part of Build 266:
  the owner moved it to Build 267 on 8 October 2026 (option 3), where the
  Course Wizard builds a new Italian demo. The bundled Courses keep one
  module per Lesson.

## Revision 3 (2.0.66+266003, 8 October 2026): the Round Wizard over modules

Plan §7, as decided on 5–8 October 2026.

### The generator (`lib/services/guidebook_round_generator.dart`)

- `plan(guidebook, focusModuleId:, roundCount:, exercisesPerRound:)`: a
  focus module, or null for All modules, in order; `roundCount` is then
  Rounds per module and each module has its own curve (difficulty from 0 to
  1 within the module). Limits: 1–12 Rounds (per module), 1–15 exercises,
  at most 24 Rounds per run (the message says how many per module fit),
  three Words & Expressions per module (`moduleProblem`; All modules leaves
  the others out and lists them in `skippedModules`).
- `GuidebookRoundPlan`: `focusModuleId`, `reviewPositions` (round(0.3 × M)
  positions spread evenly, never the first, none when no earlier module has
  words), `opensModule` (the first Round of each module); title
  "<phase>: <module title>". `changeFocus` replans a Round for another
  module; `changeType` keeps the focus; `wordsOf` names what a Round uses.
- One resolution (`_Material.resolve` → `_Slot`: preset, the entries of its
  question and answer, review or focus) serves the plan's words and the
  drafts. A review slot takes earlier modules nearest first (a Match its
  three entries from them together); a preset they cannot fill (a
  sentence, pictures) stays a focus slot.
- Pools per phase, from the focus module's material: Foundations Pick the
  translation, Pick the missing word (a sentence containing the word),
  Listen and choose, Match the words, and with three distinct pictures
  Select the image and Match pictures to words; Practice Build the
  translation, Word order (Sentences), Listen and match, Pick the missing
  word and the two picture presets; Use in context Type the translation,
  Pick the missing word, Build the translation, Word order. FlashCard
  Rounds: Flashcard, and Picture flashcard with pictures.
- Exercises: the Context in the clue ("the bill (restaurant)"); wrong
  answers from entries that differ only by Context first, then the slot's
  module, then the Lesson, never the same Target or a synonym; typed
  answers accept every synonym's Target with `{…}`; shown text and blocks
  without optional words; Build the translation and Word order on
  Sentences with their meaning; the picture presets built through
  `ExerciseDraftBuilder` (so each preset represents its exercise, with the
  Plural marks of `pluralPictures`); one picture per exercise, Plural or
  not.
- Drafts record `focusModuleId` and `supportingModuleIds` (the earlier
  modules used, in module order); each exercise's `sourceRefs` are its
  question's and answer's entries; the Before you start card (the first
  Round of a run, or of each module with All modules; not FlashCard or
  Test) holds a copy of the focus module's Overview, or "Review the
  “<title>” module of the GuideBook before you start.", and no
  `sourceRefs`.

### The screen (`GuidebookRoundGeneratorScreen`)

- Focus module (`generator-focus-module`, tooltip): All modules, in order,
  and each module, greyed out with its reason below three entries; All by
  default when more than one module can be practised. The count is Rounds
  per module (3) or Number of Rounds (6), switching with the choice; the
  field shows the 24-Round limit; the total names the modules.
- The plan: the modules left out (`generator-skipped-modules`); per Round
  the entries it uses (`generator-round-words-<i>`) and its focus
  (`generator-round-focus-<i>`, when more than one module can be
  practised); Regenerate keeps each Round's focus and type.
- Help: the Wizard's dialog and Editor Help `roundWizard` (EN/IT/ES).

### Tests

- New: `test/round_wizard_modules_266_test.dart` (15): All modules and its
  curve, titles and cards; a focus module and the limits; review slots;
  changing a Round's focus and its words; the picture presets; drafts
  valid, represented and naming their entries; focus and supporting
  modules; the cards' Overviews; the Context; wrong answers without
  synonyms; the Context-only wrong answer; typed synonyms and `{…}`;
  Plural carried and one picture per exercise; the screen's counts, limit
  and plan.
- Updated: `guidebook_sentence_generator_test` (the card has no
  `sourceRefs`), `guidebook_vocabulary_265_test` (titles name the module;
  the English side is what the Rounds practise); the version pins.

## Revision 2 (2.0.66+266002, 8 October 2026): resilience

Owner decisions of 8 October 2026, after the reset buttons did nothing (the
fix is in Revision 1): fix the same class of bug everywhere, test the edge
cases, make the Diagnostic Log say what happened, Save&Open for both logs,
Delete / Forget / Open folder in the Inventory ("yes to all": the admin PIN,
the same rules as elsewhere, its own revision). A read-only audit of the
whole app listed where one bad stored item or an awaited call without a
catch could stop a feature; this revision fixes those.

### Stored Courses this version cannot open

- `StoredCourseReader` (`lib/services/stored_course_reader.dart`) is the one
  way QQL opens a stored custom Course entry: a Course, or an
  `UnopenableStoredCourse` with what the JSON still says (title, Maintainer,
  assigned Team, Private flag, Course ID) and the reason. Any data error of
  `Course.fromJson` counts (`isDataError`: FormatException, TypeError,
  ArgumentError, StateError, RangeError), not only FormatException: a field
  of the wrong type used to throw a TypeError that hid every Course.
  `log` writes it to the Diagnostic Log once per session (COURSE-002, with
  the file name).
- `CourseFileStore.readReadable` reports each record's file
  (`CourseStoreSnapshot.fileNames`), so the Course list names the file, not
  the ID; `SkippedCourseFile` gains `courseId` and `kind`
  (`isRemovableCustomCourse`).
- `CourseEditorService`: `listUserCourses` reads through the reader;
  `unopenableCourse(id)`; `mayRemoveUnopenable` (the JSON's Maintainer, a
  member of its Team, or an admin); `deleteUserCourse` removes such a Course
  with its media under that rule; `installImportedCustomCourse` replaces it
  (`_replaceUnopenable`) under the same rule; the Publisher update replaces
  a stored source it cannot open, when the JSON names the same publisher.
- `CourseLibraryOperations.reviewImport`: `existingUnopenable`, and Replace
  offered to those people (`replaceUnavailableReason` otherwise); Course
  Studio's Matching Course ID dialog explains it.
- Course Studio's card of stored Courses that could not be read has
  **Remove…** (`course-manager-unreadable-remove-<i>`, two confirmations as
  Delete); both cards explain how to remove or replace one.
- `CourseMaintainerGuard` (learner deletion) and `AppResetService` (the
  preview and Remove non-admin learners) count the JSON's Maintainer: a
  learner who maintains such a Course is refused, the message naming it (or
  "a Private course"). A stored file that is not readable at all still
  refuses learner deletion, now with a StateError that points to the
  Inventory.

### Buttons and first loads that failed silently

- `runReported` (`lib/widgets/reported_action.dart`): the error is written
  to the Diagnostic Log (APP-001) and shown as a SnackBar
  (`reported-action-error`, "… could not finish: …"); `readableError` drops
  the Dart type names. Used by Version History's Open backup folder, Course
  Info (opening, the name check, applying the changes), the Course Editor's
  Audit (its Audio Library check), Course Studio's Audit and Export as
  Publisher Course, the Course Selector, Make admin, Team Manager and the
  Team page (the spinner ends), Learner profiles (Advanced (Admin) and
  Profile), Shared Images delete and remove bank, Reset current course,
  Gamification's Course names.
- Version History says why backups are not listed (made before Build 266,
  or not backups).

### Logs

- `CrashLogService.recordUnhandled`: the zone, FlutterError and
  PlatformDispatcher handlers write the full report to the Crash Log and a
  short entry (the error, the first lines of the stack, "the full report is
  in the Crash Log") to the Diagnostic Log, where people look first.
- **Save&Open** (the owner's name) under each log's icons in Settings ›
  Debug, on Windows, macOS and Linux (`save-open-crash-log`,
  `save-open-diagnostic-log`): a fresh copy in the Logs folder (Quick
  Export), then that folder opened (`FolderOpener`,
  `lib/widgets/folder_opener.dart`, test seams `available` and `open`). It
  stands on its own row under the tile: a ListTile's trailing slot has a
  fixed height.

### Inventory: Delete, Forget, Open folder

- `InventoryItem.action` (`InventoryAction`: kind, target, label,
  explanation) and `folder`. Kinds (`InventoryActionKind`): deleteLearner
  (Learners), forget (Course Favorites, Received Custom Courses, Remembered
  publishers), deleteCourse (a stored custom Course; an unopenable one by
  the ID its JSON names), deletePublisherCourse, deleteFile (Export,
  Import, ToBeMerged, Logs, Backups, the earlier folders, Import staging,
  Other files, a stored file that is not a Course, Course media no stored
  Course uses), deleteDeviceImage (Imported images: record and file),
  removeImageBank. The live Crash Log and session marker have Open folder
  only; Course media a stored Course uses has none.
- `InventoryActionService` (`lib/services/inventory_action_service.dart`)
  runs them after `AdminPinGate` (`lib/services/admin_pin_gate.dart`, also
  the resets' check now), through ProfileService, CourseEditorService, the
  Shared Image Library and ImageBankService; Forget removes only the keys
  the Inventory lists; files only inside QQL's folders, never the live
  Crash Log; each action is written to the Diagnostic Log.
- `InventoryScreen`: per item `inventory-<section>-<i>-action` and
  `-open-folder` (desktops); the dialog `inventory-action-dialog` with what
  it removes, the PIN (`-pin`), `-run`, the refusal in `-error`; the list
  reloads. Refresh no longer returns a Future from setState (found by the
  new test).

### Help (EN/IT/ES)

- Debug Help: Save&Open under the Crash Log; the Diagnostic Log records the
  unhandled errors and the Courses that cannot be opened, and Save&Open.
- Advanced (Admin) Help, Inventory: bullet 8 (Delete, Forget, Open folder,
  the PIN, the rules).

### Tests

- New: `test/stored_course_edge_cases_266_test.dart` (14): the reader on
  six kinds of broken entry; the Course list beside seven kinds of bad
  stored file (earlier GuideBook shape, formatVersion 11, a field of the
  wrong type, broken JSON, empty, no Course ID, two files with one ID),
  named by file and logged once; the reset preview; Remove custom courses;
  learner deletion (refused while a file cannot be read, then by the
  Maintainer rule, then allowed); removal by Maintainer or admin with the
  media, nobody else; the import review's Replace; replacing by import;
  the Inventory's actions for every stored file and learner; the PIN, the
  folders and the forgettable keys; the Inventory dialog end to end;
  `runReported`; `recordUnhandled`; Save&Open.
- Updated: `test/unreadable_stored_courses_243_test.dart` (the file name),
  `test/reset_unreadable_course_266_test.dart` (the JSON's Maintainer
  counts); the version pins.

## Revision 1 (2.0.66+266001, 8 October 2026): authoring aids

The module page's aids (plan §5 and §10). No format change.

### Picture prefill

- `GuidebookPictureIndex` (`lib/services/guidebook_picture_match.dart`,
  pure Dart) indexes the QQL catalog (`ExerciseImageMetadataService`
  `loadCatalog`, bundled records only). `sideFor(course)`: the Target when
  the Course teaches English, the Source when its learners speak English,
  otherwise no prefill. `find(word)` tries, in order:
  1. a name equal to the word, capitals, spacing, a leading *a*, *an* or
     *the* and closing punctuation ignored ("an apple" → Apple, "the
     bill" → Bill);
  2. the word's singular by the library's rule (`imageTagKey`): "cats" →
     Cat, `plural: true`;
  3. the part of a name before its bracket, for the word, then for its
     singular: "baker" → Baker (man), Baker (woman); "Africa" → Africa
     (map).
  Exact names come first: "glasses" → Glasses, "father" → the Father
  scene, not Father (family tree). Never matched: the `characters` group,
  `lesson_icons`, one-letter names. A target's optional words are tried
  with and without them ("{to} eat": "to eat", then "eat").
- The module page reads the catalog once
  (`GuidebookModuleEditorScreen(metadataService:)`, also passed through
  `GuidebookEditorScreen`). On leaving a word's Target or Source box:
  - one match fills the picture with **Suggested** (or **Suggested,
    plural**, the picture marked Plural) and a tooltip naming why;
  - several show **N matching pictures** (`…-picture-matches`), which
    opens the image library already searched for the word; the chosen
    picture is marked Plural when the match was by the singular;
  - none does nothing.
  It never replaces a picture the author chose (a suggestion follows its
  word), never runs on a reopened GuideBook (stored words count as read),
  and a removed picture stays removed until the word changes
  (`_EntryRow.prefillWords`). Touching the picture (the dialog, Remove,
  Plural) drops the mark. Paste list and Fill with an example run it on
  their new words.
- `chooseLibraryPicture` (`lib/widgets/exercise_image_field.dart`) is
  Choose flat image as one function, used by `ExerciseImageField` and the
  matches; `FlatImageLibraryScreen(initialSearch:)` opens searched.

### The other aids

- **Paste list** (`GuidebookPasteList`, `lib/services/guidebook_paste_list.dart`):
  one entry per line, `target = source [context]` (the separators of
  `GuidebookVocabulary.parse`), blank lines skipped; a line with no pair, a
  bad `{…}`, a bracket in the Source or a Context over 40 characters is
  listed with its reason (`guidebook-module-paste-unread`) and not added.
- **Fill with an example** (`GuidebookModuleSample`,
  `lib/services/guidebook_module_sample.dart`): "Al bar", four Sentences
  (one with a Context, one with `{Io}`), six Words & Expressions (*il
  conto* twice, *per favore*, `{io} sono stanco`, *il caffè* with
  `coffee.webp`, *i gatti* with `cat.webp` marked Plural), a two-sentence
  Overview; fresh entry IDs; asks first when the page holds something.
- **Clear all** empties the page, pictures included, asking first unless it
  is empty.
- **Overview**: a character counter (`guidebook-module-overview-count`) and
  from 500 characters the hint (`guidebook-module-overview-long`); the
  limit is `GuidebookText.longOverviewLength`, which the Audit's
  `GUIDEBOOK_MODULE_OVERVIEW_LONG` now reads too.
- **Tooltips and examples**: the field Help controls carry a tooltip; the
  list descriptions give examples (*Lei è stanca?* with its Context; *il
  conto* twice; *buongiorno*); a line under each list explains `{…}` with a
  tooltip; Paste list, Fill, Clear all and the counter have tooltips.
- **Field Help** (EN/IT/ES, read in the Help Language like the Help pages;
  the exercise forms' field dialogs stay English): Title, Sentences, Words
  & Expressions, Target, Source, Context, Picture (also in the picture
  dialog), Overview, Paste list (`guidebookFieldHelpIds`,
  `guidebookHelp.field.<id>.title`/`.body`).
- **Editor Help** (86 questions): "How do I write GuideBook entries?"
  (`guidebookEntries`, opened by the module page's Help) and "How long
  should a module be?" (`moduleLength`), after the GuideBook question.
- The Paste list dialog owns its text controller (`_PasteListDialog`), so
  it is disposed after the closing animation (found by the new tests).
- **The library opened from a word is searched for it** (owner request of
  8 October 2026): the picture dialog's Choose flat image
  (`ExerciseImageField(librarySearch:)`) and N matching pictures open the
  library with the word's English side as the prefill compares it (no
  article, no closing punctuation: "an apple" → "apple", "The cats." →
  "cats"), if and only if the Course is to or from English; otherwise
  unsearched.

### Fix: the reset buttons (owner report of 8 October 2026)

- The reset buttons of Advanced (Admin) did nothing. Revision 0 made a
  stored Course whose GuideBook has the earlier shape unopenable;
  `AppResetService.preview` (and the non-admin learners reset) read every
  stored Course with `Course.fromJson`, which threw at the owner's own test
  Course (3.6 MB, the earlier shape), and `_begin` awaited the preview
  without a catch, so nothing was shown. The only in-app way to remove the
  Course (Remove custom courses) was blocked by the Course itself. The
  Crash Log had the error five times, without naming the Course; the
  Diagnostic Log had nothing.
- `_storedCustomCourses` skips a Course it cannot open, as it already
  skipped an unreadable file (such a Course names no Maintainer anyone
  could see); the full wipe and Remove custom courses delete it with the
  others.
- `_begin` catches a failing preview and shows why
  (`admin-reset-preview-error`), with nothing changed.
- `test/reset_unreadable_course_266_test.dart` (4): the preview with an
  earlier-shape Course, its removal, the button opening its explanation,
  a failing preview reported. Without the fix the preview test and the
  button test fail.

### Tests

- New: `test/guidebook_authoring_aids_266_test.dart` (26: the matcher on
  the real catalog, device pictures, the sides; Paste list; the sample;
  the shared 500 limit; the Help keys; the prefill on the page, its
  removal and reopening rules, a Course without English; Paste list,
  Fill, Clear all, the counter, field Help, 360 pixels; the library opened
  searched, from the picture dialog in the three kinds of Course and from
  the matches).
- Pins: the Editor Help count (84 → 86) in `editor_help_qa_256_test` and
  `editor_help_translation_test`; the version pins.

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
