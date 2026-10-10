# Build 270 modularization audit

Read-only audit of 10 October 2026, after Revision 10 (`db60d474`). Four
agents mapped the largest files; the claims that matter most were checked
against the code. Line numbers refer to that commit. Nothing was changed.

## The rule applied

Owner decision (10 October 2026): no physical file split unless ownership
separation comes first. Each responsibility first gets its own testable
owner (a service, controller or pure class with its own state and tests, as
in the Build 245–252 extractions: `CourseAuthoringSession`,
`ExerciseDraftBuilder`, `CourseLibraryOperations`,
`CourseEditorDeviceState`, `CourseInfoUpdateService`); only then may it move
to its own file. Never a mechanical cut (part files, moving widgets) of a
screen that keeps sharing one state class. Size alone is not a defect: a file
is judged by its different reasons to change and its coupling.

## Overall picture

- **Model and services: mostly sound.** `lib/models/course_models.dart`
  (5,757 lines) is large but mostly cohesive data classes with strict
  parsing; `primitive_capability_registry.dart` and `exercise_canonical.dart`
  are cohesive tables. The one big part with its own reasons to change is
  the **v11 compatibility layer** (about 1,450 lines: 3739–3930 and
  4390–5641), kept alive by the draft builder's older recipes, which still
  build through `Exercise.v2`/`Exercise(...)` and `convertV11`.
- **Screens: the tangle.** Business logic still sits in widgets even where a
  pure owner already exists (the Course Wizard with `course_wizard.dart`,
  Course Studio with `course_library_operations.dart`, the canonical editor
  with `canonical_exercise_draft.dart`).
- **Already separate, movable today** (they talk to the rest only through
  constructor parameters, callbacks and pop results): see "Free moves".

## Course Editor screen (`lib/screens/course_editor_screen.dart`, 14,049 lines)

Classes: `AuthoringHierarchyStatus` 118–222 (pure), `AuthoringStatusCard`
224–310, `_DraftBranchIndicator` 413–452, `CourseEditorScreen` 522–569,
`_CourseEditorScreenState` 594–3769 (about 3,180 lines, 12 fields of which
only 4 change), `LessonManagementScreen` 3771–4261, `LessonAuthoringPreviewScreen`
4262–4321, `LessonEditorScreen` 4322–5443, `GuidebookRoundGeneratorScreen`
5446–6314, `StoryWizardScreen` 6349–6939, `LessonRoundsScreen` 6940–7710,
`RoundEditorScreen` 7711–9517, shared private helpers 9518–9776,
`ExerciseCreationWizardScreen` 9780–10195, `CourseAuditScreen` 10196–10413,
`ExerciseEditorScreen` 10414–13562 (about 60 fields, 19 controllers),
`AudioLibraryScreen` 13563–14049. No `part` files; no mutable globals.

Clusters of the main State:

| Cluster | Lines | Kind |
|---|---|---|
| Session glue | 594–678 | glue (the single write path `_updateDraft`) |
| Save / leave | 680–784 | presentation over the session |
| **Course Info dialog** | **786–2348 (~1,560)** | much business logic: form derivation 861–1034, cover-credit rows 919–983, save assembly and validation 2137–2280 |
| Lessons navigation | 2350–2415 | glue |
| Mode / lock | 2417–2525 | presentation |
| Publish toggle | 2527–2577 | pure gate 2553–2575 |
| Story characters | 2582–2774 | pure: `_linesSpokenBy`, `_withSpeakers`, `_speakerSummary` |
| **Lesson Options** | **2776–3205 (~430)** | pure Course transforms; the two `_numbering*Version` fields are used only here |
| Library / history glue | 3207–3303 | glue |
| Audit | 3305–3441 | Round rebuild 3383–3411 |
| build | 3443–3768 | root presentation |

Coupling: about 15 `_updateDraft` call sites; the "Unapplied course changes"
dialog written twice (706–752, 2443–2493); the publish gate duplicated at
2558, 3977, 4651, 7415, 8001 (variants 8099, 12900, 13038); the four
hierarchy screens repeat the same adopt/receive code (3818–3835, 4380–4404,
7001–7024, 8139–8167); orphan-clip removal twice (3292–3300, 13808–13815);
services created directly with no seam (597–600, 621, 842, 849, 2327, 2334,
2559, 3307). `ExerciseCreationWizardScreen` reads
`_ExerciseEditorScreenState.labelForType` (10116).

## Learner runtime

**`round_screen.dart` (5,810 lines).** `_RoundScreenState` 178–5810 holds
about 101 fields. Business logic still in the widget:

| Cluster | Lines | Owner it could have |
|---|---|---|
| Grading (`_mark` 1625–1661, `_submit*`, `_matchingReadsAsExpected`, correct-answer text 1395–1525) | ~380 | `AnswerGrader` (pure) |
| Held Story line (fields 352–384, 1284–1385, timing in 1237–1264) | ~150 | `SpokenLineHold` state machine |
| Timed rounds (245–325, 779–792, 1627–1659, 2177–2193, 2282) | ~200 | `TimedRoundClock` |
| Attempt progression (1637–1651, 1726, 2143–2219, Test 2204–2280) | ~150 | `RoundAttempt` |
| Tap-to-place gaps/slots (2695–2805, 3077–3134, 5004–5036) | ~150 | near-duplicate arrange/select logic |

Renderers (2545–5160) are presentation and stay. Hot spots: `_advance`
2140–2502 mixes Story end, review, Test grading, preview, completion and
dialogs; `_prepareExercise` resets about 35 fields of 8 clusters; state is
written during build (`_mascotPlacement` 5473, `_exerciseMascot` 4729);
global static seams (`RoundScreen.openLink`, `lineStopwatch`,
`SpokenLinePace.shared`) can leak between tests; the Timed retry rebuilds
`RoundScreen` by copying its 16 parameters by hand (5376–5397).

**`home_screen.dart` (4,743 lines).** `_HomeScreenState` 273–2905 (50
fields): start-up notices 364–621, data reload 622–811 (writes 22 fields),
learner management 908–1342, course picker 1343–1920 (one 578-line method),
lesson access / IDDQD / locked preview 1970–2051 and 2803–2873 (with a global
set `_sessionPreviewedLockedLessons`), path scroll sync 2053–2258.
`LearnerRoundPath` and its painters (3702–4588) and `_LessonSection` with its
children are already separate owners; the shared private helpers
`_learnerMascotSeed` and `_learnerPageBackgroundOf` block a move.
`course_preview_screen.dart` is a `part` only because it uses six Home
privates.

**`duel_screen.dart` (952 lines)** is small; it duplicates the Round's voice
choice, recorded-to-TTS fallback and Report sheet.

## Other screens and services

- **Course Wizard** (`course_wizard_screen.dart`, 3,668): validation 495–512,
  the licence mapping 410–415 and 465–470, author-role normalization 108–120
  (duplicating `course_library_operations.dart:955`) and change tracking
  595–640 sit in the screen; the save → backup offer → next problem →
  remember sequence appears twice (1430–1447, 1495–1512). Step UI 1712–3545
  reads the one State's controllers.
- **Course Studio** (`course_projects_screen.dart`, 3,265): `_createCourse`
  1143–1878 is one 735-line closure (about 20 controllers, validation,
  cover media lifecycle); `CourseMergeScreen` 231–797 keeps pure selection
  logic in the widget (258–375, 578–622); `CourseImportScreen` and
  `CourseExportScreen` are stateless.
- **Canonical editor** (`primitive_editor_screen.dart`, 2,479): `_change`
  135–160 mirrors six slot lists back into the draft (two sources of truth);
  `_hasUnsavedChanges`, `_isBlank`, `_evaluationWith` and the publish gate in
  `_save` 320–418 belong with `CanonicalExerciseDraft`; the four row widgets
  1825–2479 are independent.
- **Image library** (`flat_image_library_screen.dart`, 2,442): loading
  145–256, add-to-Course with the 300 MB budget 1195–1369, removal
  1371–1513 and the filter/sort pipeline 1957–2015 are logic in the widget.
- **GuideBook module editor** (`guidebook_editor_screen.dart`): row
  validation 582–662, picture prefill 733–878 and the Module Wizard part
  machine 1492–1655 are logic; `_EntryRow` mixes controllers and state.
- **Advanced (Admin)** (`device_administration_screen.dart`): thin; the reset
  logic is in `AppResetService`.
- **`inventory_service.dart`**: one responsibility, but `load()` is one
  985-line method (175–1158) and repeats the "prefix + decode" loop four
  times; it changes whenever a store adds a key, because it copies their
  formats.
- **`profile_service.dart`** (1,094): several reasons to change — identity
  rules, registry, admin roles, Access PIN and lock (with a static session
  state gating `getActiveProfileId`), device settings, the learner key
  namespace, theme, flag background, skin and hair tones; profile deletion
  rewrites the Team registry (663–701), which belongs to `TeamService`.

## Model and authoring core

- **`course_models.dart`**: groups — provenance and governance (31–811, a
  leaf group with no code reference to Course, Lesson or Exercise), `Course`
  812–1864, GuideBook 1901–2258, Lesson/Round 2259–2678, Content 2679–3037,
  image library entries 3038–3262, `PromptElement` 3263–3570, speakers
  3571–3738, the v11 layer (above), `Exercise` 3939–4385, JSON helpers
  5666–5757. No class touches another's private members; the coupling is
  only through file-level helpers (`_requiredString`, `_optionalString`,
  `_mapList`, `_stableUuidV4`, `_FirstOrNull`), already duplicated in
  `exercise_canonical.dart` 12–75. `Course._validateMediaReferences`
  (1306–1352) walks raw exercise JSON; the media regex is copied at 823,
  1287, 1292, 3439, 3617. `LearningRound.fromJson` calls
  `RoundTypeCompatibility.audioEssential` (2553), a service that imports the
  models: an import cycle.
- **`course_audit_service.dart`** (2,629): `auditCourse` 239–1026 and
  `auditExercise` 1616–2562 are two long methods with local shared state;
  language tables 188–237 and the stop-word table 1190–~1412 are embedded;
  `auditLesson`/`auditRound` (1117–1189) audit the whole Course and keep the
  issues whose location starts with "Lesson N ·". The registry's scope
  strings already give a natural split.
- **`course_editor_service.dart`** (1,534): storage, media, backups, access,
  received Courses, Publisher IDs and duplication are delegated; what
  remains repeats one post-commit sequence about seven times (write, read
  back, align names, add to library, delete unreferenced media, publish
  events) and stamps the minimum app build in five steps (1096–1104).
- **`exercise_draft_builder.dart`**: a table of recipes; its only mixed
  concern is the two construction routes (canonical and v11).

## Ranked plan (owner first, then the file)

Low risk, clear value:

1. **Course credits and licence owner** — the licence, derivative policy,
   author roles and rights holders rules used by Course Info, New Course
   and the Course Wizard ("Other / Custom license" appears in all three;
   `course_metadata_options.dart` is a partial owner already). Then the
   Course Info dialog and the New Course dialog become widgets of their own.
2. **Lesson Options transforms and panel** (Course Editor 2776–3205).
3. **`TimedRoundClock`** (the clock seam exists; `timed_round_261_test`
   characterizes it).
4. **Media-reference owner** (one regex, no Course walk of exercise JSON).
5. **Shared JSON readers for the models** (the precondition for splitting
   model files with plain imports; keep `FormatException` texts identical).
6. **Merge selection owner**; then the Merge, Import and Export screens
   leave Course Studio.

Medium risk:

7. **`AnswerGrader`** out of the Round screen.
8. **Story cast owner**: one speakers function (the two narrator rules
   disagree, see below), `linesSpokenBy`, `speakerSummary`, the removal
   guard.
9. **One publish gate** instead of five or more copies.
10. **ProfileService split**: Access PIN and lock owner; the Team-registry
    rewrite to `TeamService`; optionally learner appearance; ProfileService
    stays a delegating facade.
11. **Audit rule sets** (after pinning the order of issues with
    `course_audit_report_225_test`), the language tables apart, and Lesson
    and Round audits that do not filter by location text.
12. **v11 compatibility library** (largest gain), after the draft builder's
    older recipes build canonically, or as an extension of `Exercise`.
13. **`SpokenLineHold`, `RoundAttempt`, Home's lesson access and data
    loading.**
14. **Course editor service**: one verified-commit step, a minimum-build
    policy, the official update as an owner of its own.

### Free moves (already separate owners)

`CourseAuditScreen`, `AudioLibraryScreen`, `LessonAuthoringPreviewScreen`,
`AuthoringHierarchyStatus` (to services), `CourseImportScreen`,
`CourseExportScreen`, `CourseMergeScreen` (with three one-line helpers), the
canonical editor's four row widgets, `LearnerRoundPath` with its painters
(after two helpers become public), `CoursePreviewScreen` (ending the `part`),
`_DuelBackdropPainter`, `_PasteListDialog` and `GuidebookSizeHint`. Moved
classes stay re-exported from their present file, since many tests import
it (103 import `course_editor_screen.dart`).

### Do not split

The exercise renderers and the Round screen's `_buildPage`; the Course
Editor's root build, its single write path and its leave flow; the Exercise
editor form (its logic is already in `ExerciseDraftBuilder`); the Course
Wizard's step UI before a form owner; the hierarchy screens before a shared
draft adopter; InventoryService into several files (break up its one method
instead); the capability registry and the canonical model; no `part` files
for `course_models.dart`.

## Found along the way (not structural)

- Every rebuild of the Course Editor's main page runs a full Course Audit
  (`AuthoringHierarchyStatus.fromCourse` in build, 3445): slow on large
  Courses.
- Lesson and Round Audits re-audit the whole Course and filter by the
  location prefix "Lesson N ·".
- The import cycle between `LearningRound.fromJson` and
  `RoundTypeCompatibility`.
- Two narrator rules: the Course Editor's Story characters (`_withSpeakers`,
  2615) always store the narrator once one is set; the Story Wizard
  (`_courseWithSpeakers`, 9635) stores it only when the Course already has
  one or it differs from the default. JSON only; learners see the same.
  Recommendation: the Story Wizard's rule (as other settings, stored only
  when not the default; opening the narrator and saving it unchanged then
  changes nothing; a stored narrator stays stored). Owner decision: land it
  now; done as Revision 10's follow-up (`_withSpeakers` builds through
  `_courseWithSpeakers`).
- The Audit flow rebuilds a Round field by field (3396–3411): every field is
  copied today, but a new Round field would be dropped there.
- The Round screen writes state during build (mascot placement).
- Global test seams can leak between tests (`RoundScreen.openLink`,
  `lineStopwatch`, `SpokenLinePace.shared`).
- Course Info disposes its controllers after a 300 ms delay (2288–2321).

## Suggested order

A modularization build (271), one owner per revision, characterizing
behaviour before moving it: Revision 0 the credits and licence owner,
Revision 1 Lesson Options, Revision 2 the timed clock and answer grading,
Revision 3 media references and the JSON readers, then the free moves.
