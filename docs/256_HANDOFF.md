# Build 256 handoff — exercise architecture redesign (Course Model v12)

Resume from this file alone. Plan: `docs/256_EXERCISE_ARCHITECTURE_PLAN.md`
(Part A decisions, Part B session plan, Part C verified audit notes, Part D
condensed specification). Catalogue: `docs/256_PRESET_CATALOGUE_PLAN.md`.
Reference: `docs/EXERCISE_ARCHITECTURE_V12.md`. Summary per revision:
`docs/256_CHANGE_SUMMARY.md`. Evidence per revision: `docs/256_VALIDATION.md`.
Working rules: plan Part A.1 and `AGENTS.md` (its "Current release boundary"
entry for `2.0.56+256004` is the authoritative description of Revision 4).

Compacted on 28 September 2026 at the owner's request: the stage-by-stage
narrative of Revision 4 is gone (the evidence lives in
`docs/256_VALIDATION.md`); what follows is state, decisions, requirements,
open problems and the next step.

## State (28 September 2026, 02:10)

- **WAITING FOR THE OWNER'S APPROVAL BEFORE REVISION 5.** Owner, 27
  September 20:04: "At the end of task, commit, handoff, and push. Then pause
  and wait for my approval before going on with next revision." Do not start
  Revision 5 (Interoperability) or Revision 6 (Laboratory, Assign, final
  verification) until the owner says so. An auto-resume run reads this line
  and replies with one line of status only.
- **Revision 4 (the preset catalogue, `2.0.56+256004`) is committed and
  pushed:** `eca0cd0` Build 256 Revision 4 (86 files) plus the handoff
  commits `f2e692a` and the compaction commit after it, on
  `origin/claude/256-exercise-architecture` (upstream set). Working tree
  clean apart from the owner's two untracked files (`devtools_options.yaml`,
  `tools/cloud_setup.sh`, never staged).
- Complete suite on the final tree (01:26–01:52): **3053 passed, 1 skipped,
  0 failed**; `flutter analyze` clean; `dart format` clean on every changed
  file; the three generators' `--check` pass; `tools/validate_courses.py`
  validates the four bundled v12 Courses.
- No APK for Revision 4 (owner: "Do not build the apk, unless you already
  did"); the end-of-revision sound played. The revision keeps the 27
  September date and Beta expiry `2026-10-27 23:59:59` although the commit
  landed at 01:53 on 28 September (same policy as Revisions 0–3, all dated
  27 September); the owner may ask for a same-version follow-up moving the
  expiry to 10-28.
- No in-session cron exists any more (`CronList` empty); the hourly
  auto-resume messages come from the owner's scheduled task and must obey
  the first bullet.

## Sessions

| Session | Revision | Version | State |
| --- | --- | --- | --- |
| 1 Canonical definitions | 0 | 2.0.56+256000 | committed `507be89` |
| 2 Course Model v12 | 1 | 2.0.56+256001 | committed `e850cc2` |
| 3 Runtime and Audit | 2 | 2.0.56+256002 | committed `41dd91a` (suite 2,840/1/0) |
| 4 Presets and Generic Primitive Editor | 3 | 2.0.56+256003 | committed `974f700`, follow-ups `1068fa4`, `02a4aa5` (suite 2,951/1/0) |
| 5 Preset catalogue | 4 | 2.0.56+256004 | committed `eca0cd0` (suite 3053/1/0), pushed |
| 6 Interoperability | 5 | 2.0.56+256005 | **not started: waits for the owner's approval** |
| 7 Laboratory, Assign, final verification | 6 | 2.0.56+256006 | not started |

Branch `claude/256-exercise-architecture`, created from `main` at `611a1a1`
(Build 255 handoff, `2.0.55+255007`).

## What Revision 4 delivered (where to look)

- Registry (`lib/models/exercise_authoring.dart`): 38 presets in six skill
  groups (`ExerciseCategory`: vocabulary, grammarAndSentences, listening,
  readingAndDialogue, picturesAndCharacters, cardsAndNotes) with
  `direction`, `base` (the recipe a preset is built on), `twin`, `action`;
  `ExercisePresetRegistry.comingLater` (seven greyed presets no Course
  records); `currentIdFor` resolves a stored retired ID. Retired IDs and
  bases: `lib/models/preset_successors.dart` (`presetSuccessorOf`,
  `presetRecipeBaseOf`), mirrored by `PRESET_SUCCESSOR`/`PRESET_BASE` in
  `tools/qql_course_v12.py`.
- Recipe variants (`lib/services/preset_variants.dart`): `baseFor` (shape
  hints `textRole`, `audioRole`, `matchSides`, `revealFirstLetter` on
  `ExerciseDraftValues`), `draftFor`, `finish`/`toSource`/`_shape`,
  `formFor`/`ownForms`, `isImageReference`, `fits`/`hasInWordGap` (asked by
  `PresetRecipes.represents` before rebuilding: an in-word gap is Missing
  letters, a picture Spell the word in the picture, automatic audio Spell
  what you hear, neither Spell the word).
- Recipes (`lib/services/preset_recipes.dart`): `kinds` per preset,
  decompose with shape hints, `bracketedSentence`, picture items, `rebuild`
  blank on `preset.base`, `presetToEdit` through the successor.
- Editor (`lib/screens/course_editor_screen.dart`): picker groups, action
  chips, To target / To source filter, greyed tiles; merged Listen and
  answer and Read and answer forms; 13 own forms; inline gaps are the
  presets `gap_choice_inline` and `gap_blocks` (no switches); one
  `ExerciseImageField` per answer (`_answerPictures`); `type-missing-word-reveal`;
  the Wizard's `_blankExerciseForPreset` builds on the recipe's base type
  with the preset as editor template.
- Runtime (`lib/models/exercise_features.dart`, `round_screen.dart`,
  `duel_screen.dart`): captioned picture answers and Match left pictures
  (`media:` through `CourseMediaImage`, bundled/portable as before),
  within-word gap underscores, the source voice
  (`primaryAudioLanguage`/`audioLanguageOf`, `_voiceFor`),
  `LearnerExerciseKind.arrangeLines` (copy in eight languages),
  `completionMode` (default `proceed`).
- Converters (`Exercise.convertV11`, `lib/services/course_model_v12_converter.dart`,
  `tools/qql_course_v12.py`): successors recorded; an inline v11 Choose /
  Word order / Build the translation becomes `gap_choice_inline` /
  `gap_blocks`; an explicit `language` wins over the preset-implied one;
  `media:`/`data:` icon keys become image elements, bundled `assets/` keys
  stay icon keys; `icon_choice`/`image_word` audio automatic; a v11 Image
  Word prompt text converts as a `clue`; a `["continue"]` card is the
  proceed mode and is not noted; `Presentation.fromExercise` reads an
  omitted completion mode as `proceed`.
- Audit (`lib/services/course_audit_service.dart`, `audit_code_registry.dart`):
  98 rules (`DIALOGUE_RESPONSE_OPTION_COUNT`, `DIALOGUE_CONTEXT_REQUIRED`,
  `DIALOGUE_QUESTION_REQUIRED`, `CONTEXT_REQUIRED` retired), catalogue
  rules and areas, `_mismatchHint`; `IMAGE_WORD_IMAGE_REQUIRED` = a
  picture, a spoken word or a clue; `FLASHCARD_EXAMPLE_EMPTY`/
  `FLASHCARD_AUDIO_EMPTY` only for vocabulary flashcards (understood/review
  completion, no picture); `ROUND_DUPLICATE_CONTENT` counts the prompt's
  pictures. Pinned counts: `AuditCode.values` 98
  (`audit_branch_ownership_226_02_revision4_test.dart`,
  `audit_code_registry_226_02_test.dart`).
- Help EN/IT/ES (`lib/localization/help/help_{en,it,es}.dart`,
  `help_structure.dart`), field help (`lib/services/exercise_field_help.dart`,
  12 new `ExerciseAuthoringField` values), Search definitions, GuideBook
  Round generator and the interoperability catalog on catalogue IDs.
- Bundled Courses: Exercise Laboratory (5 Lessons, 24 Rounds, 107
  examples, every preset; `tools/generate_exercise_laboratory_254.py`),
  Piedmontese (38 Lessons in registry order, 114 examples;
  `tools/generate_piedmontais_demo_254.py`), Edge Case
  (`tools/generate_edge_case_demo_254.py`, inline-gap presets), Korean
  (converted from `test/fixtures/v11/korean_en.json`). Every generator has
  `--check`; `tools/validate_courses.py` expects 38 Piedmontese Lessons.
  The v11 converter fixtures `test/fixtures/v11/{exercise_laboratory_en_it,piedmontais_en}.json`
  come from the generators' `course_v11()`/`build_course_v11()` dumped
  with an `officialChecksum` (SHA-256 of the canonical JSON without the
  signature keys). The Laboratory presentation baseline
  `test/support/laboratory_presentation_254.dart` holds 107 records
  (record mode: `QQL_RECORD_PRESENTATION=<dir>` while running
  `exercise_laboratory_254_test.dart`; the rebuild script's diff falsely
  reports `true`/`false` inside old keys as renames).
- New tests: `test/preset_catalogue_256_test.dart`; the `fits` test in
  `preset_recipes_256_test.dart`; every catalogue pin moved (see
  `docs/256_VALIDATION.md`, Revision 4).

## Decisions in force (beyond AGENTS.md)

- Catalogue (owner, 27 September; `docs/256_PRESET_CATALOGUE_PLAN.md` §1,
  §5): merges and renames as listed there; pairs to target / to source only
  where the direction matters, brackets only on the twins; Pick the
  translation presets untouched; Choose the answer is generic (grammar,
  culture, meaning); inline gaps are own presets; the new presets Missing
  letters, Complete the text, True or false, Put the sentences in order,
  Note card, What is in the picture, Name what you see, Listen and pick the
  image, Picture flashcard (usage example and read-aloud optional, never an
  audio exercise), Spell what you hear, Spell the word, letter/syllable
  tiles, image-to-text and image-to-sound pairs; greyed presets for later.
  Delivered with the differences recorded at the top of the catalogue plan
  (Listen and answer paired too: 38 active presets; Type the missing word
  absorbs Fill in the blank through the first-letter switch; Match the
  words keeps an existing exercise's Matching shape).
- A Note card completes with `proceed` (Continue); a vocabulary flashcard
  with understood/review. A Picture flashcard's usage and pronunciation are
  optional.
- Recognition order: own preset first, then registry order among same-kind
  presets, each gated by `PresetVariants.fits`; a stored Type the missing
  word with an in-word gap opens as Missing letters (by design).
- The v11 shapes (`Exercise(...)`, `Exercise.v2`) remain converter input
  and test helpers; a blank for a catalogue-only ID must carry the recipe's
  base as `type` and the preset as `editorTemplate` (a twin ID is no v11
  type and falls back to a Select interaction otherwise).
- Beta expiry is 30 days from the revision's release day; Revisions 0–4 are
  all 27 September → `2026-10-27`.

## Requirements and process (every session)

- One delivered revision per session: version bump in `pubspec.yaml`,
  `lib/services/app_metadata.dart` (`buildNumber`, `correctiveRevision`,
  label), `lib/services/beta_lifecycle_service.dart` and its tests,
  `test/app_metadata_225_04_test.dart`, `test/beta_lifecycle_test.dart`,
  `test/qql_229_revision3_test.dart`, `test/qql_233_revision_platform_contract_test.dart`,
  README (version line and intro), CHANGELOG, `docs/256_CHANGE_SUMMARY.md`,
  `docs/256_VALIDATION.md`, AGENTS boundary entry,
  `docs/EXERCISE_ARCHITECTURE_V12.md` status table, the plan's status;
  grep the old build number before the suite.
- `dart format` on the `git status` Dart files only (never whole
  directories: 61 files predate Build 256 unformatted); `flutter analyze
  --no-pub`; focused batches (include `bundled_courses_225_02_test.dart`,
  `demo_package_roundtrip_254_test.dart`, `flashcard_usage_254_test.dart`
  and the converter parity test whenever bundled Courses, presets or cards
  change); run every generator's `--check` and `tools/validate_courses.py`
  after any converter or generator change (a stale asset passes every test
  that reads it); the complete suite exactly once on the final tree
  (`flutter test --no-pub --concurrency=1 --reporter compact`, about 25
  minutes, under a keep-awake wrapper holding
  `ES_CONTINUOUS | ES_SYSTEM_REQUIRED`; path spelling `C:\QQL\QuisquisLingo`;
  never two Flutter commands at once); its `Tee-Object` log is UTF-16 (read
  with Python).
- Six-part report (delivered, validation, issues fixed, known limits,
  repository state, next), handoff update after every commit and at least
  every 30 minutes with the real clock (`date "+%H:%M"`), one local commit
  "Build 256 Revision N: …" with `Co-Authored-By: Claude Fable 5.1
  <noreply@anthropic.com>`, staged with
  `git add -A -- . ':!devtools_options.yaml' ':!tools/cloud_setup.sh'`.
  Push only when the owner asks (asked for Revision 4). Sound at the end
  of a revision (`C:\Windows\Media\tada.wav`); APK only when the owner asks.
- Ask the owner only when a choice would change behavior, saved data,
  scoring or compatibility; otherwise decide, record the decision here and
  in the plan, and continue.
- Tooling of the last session lives in
  `C:\Users\Domenico\AppData\Local\Temp\claude\C--QQL-QuisquisLingo\0c168953-8214-49cd-9d21-7ed1f40fd1ee\scratchpad`
  (`run_awake.ps1` keep-awake wrapper, `s44_suite_summary.py` UTF-16 log
  summary, `s45_suite_failures.py`, `s34_baseline.py` baseline rebuild,
  `record/` with the 107 presentation records, `apk_and_sound.ps1`); a new
  session has its own scratchpad and may copy them from there.

## Open problems and known limits

- Not implemented from the catalogue plan: the save guard that refuses a
  save while a required field still equals its example (no form prefills
  examples). Candidate for a Revision 4 follow-up or Revision 5.
- A converted v11 Image Word whose prompt text is an instruction (e.g.
  "Build the word") now carries that text as a `clue`, so
  `IMAGE_WORD_IMAGE_REQUIRED` no longer fires for it without its picture
  (the clue counts). Consequence of the owner-approved rule; mention if the
  owner reviews Audit behavior on old Courses.
- Revision 4's Beta expiry versus the after-midnight commit (see State).
- The interoperability catalog (`lib/models/exercise_interoperability.dart`)
  only carries catalogue preset IDs as hints; the real mappings, support
  states (A.6) and the flow engine are Revision 5's scope.
- Speak, Ink, Submit and Assign remain definitions only (A.2); Assign
  becomes playable in Revision 6.

## Next step

1. Wait for the owner's approval (reply with one line of status if a run
   arrives before it).
2. Revision 5, **Interoperability** (`2.0.56+256005`; plan Part B item 6):
   canonical import and interoperability mappings with the preset only as a
   hint; the four support states and A.6 (readable-but-not-executable
   exercises stay in the file, `runtimeSupport` computed, never stored);
   conditional transitions and the flow engine (branching Stories become
   playable per A.7 rules decided then); the service sweep from Part D; the
   capability JSON tool; end-to-end tests. Start by reading Part B item 6,
   Part D and `docs/EXERCISE_ARCHITECTURE_V12.md`, then write the plan of
   the session into this file before editing.
3. Revision 6, **Laboratory, Assign, final verification**
   (`2.0.56+256006`; Part B item 7): Laboratory by primitive and options
   plus the test-only fixture Course; Assign runtime with Generic Primitive
   Editor support; Story tests; semantic-equality tests; the final
   verification list (Part D "Final acceptance scenario").

## Gotchas

- Bash heredocs mangle backslashes and long scripts: write edit scripts
  with the file tool into the scratchpad and run them by path; `re.sub`
  templates turn `\n` into newlines, use `str.replace` for Dart strings.
- Never estimate the clock: run `date "+%H:%M"` before writing a stamp.
- A Dart `library;` directive must precede imports.
- The formatter may put an `if` body on its own line without braces; the
  analyzer then reports `curly_braces_in_flow_control_structures`: add the
  braces.
- Recorded presentation files live on a case-insensitive disk; the baseline
  rebuild's "no longer in the Laboratory / new example" lines for
  `true`/`false` IDs are its own parse artifact.
- `flutter test` compiles each test file when it reaches it: a fix made
  during a run applies to files not yet loaded.
