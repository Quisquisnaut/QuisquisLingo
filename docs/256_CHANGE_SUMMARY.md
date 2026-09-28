# Build 256 change summary

Build 256 is the exercise architecture redesign (Course Model v12). Its six
sessions are Revisions 0–5. Plan: `256_EXERCISE_ARCHITECTURE_PLAN.md`;
reference: `EXERCISE_ARCHITECTURE_V12.md`; evidence: `256_VALIDATION.md`.

## Revision 5 (2.0.56+256005, 28 September 2026): Stories

Session 6. The Stories decided with the owner on 28 September 2026
(`docs/256_STORY_PLAN.md` §0): reusable narrator and characters, dialogue
lines and covers, the Story options, the Story Wizard, Story exercises out
of the Duel, lines never skipped. Course files stay Course Model v12.

### Files

- `lib/models/canonical/content_flow.dart`: `ContentFlow.title`, `log`
  (`FlowLog` all | dialogue), `readAloud` (`FlowReadAloud` automatic |
  manual), `audioDependentContentIds`; `FlowNode.requiresAudio` (scorable
  exercise nodes only; JSON `requiresAudio: true`); defaults omitted in
  JSON.
- `lib/services/round_flow_authoring.dart`: `linearFor(..., title, log,
  readAloud, requiresAudio)`, `withStoryOptions`, `withAudioDependence(flow,
  LearningContent, requiresAudio:)`; `forContent` and `remapped` carry the
  new fields.
- `lib/models/course_models.dart`: `StoryVoice`, `StorySpeaker` (id, name,
  avatar `assets/avatars/<name>.png` or `media:…`, language, voice;
  `defaultNarrator`, `avatarPattern`, strict parsing), `Course.storyNarrator`
  / `storyCharacters` / `narrator` / `speakerOf`; `PromptElement.speakerId`.
  `Presentation.fromExercise` gives a null completion `['continue']`.
- `lib/models/canonical/primitive_options.dart`,
  `primitive_capability_registry.dart`: `OptionKey.textReveal` (`TextReveal`
  immediate | afterAudio, presentation only).
- `lib/models/exercise_authoring.dart`: presets `dialogue_line` and
  `story_cover` (Cards and notes, presentation, no direction), `helpByPreset`.
- `lib/services/preset_recipes.dart` (`kinds`, decompose of the line
  fields, `canonicalOnly`), `preset_variants.dart` (`ownForms`, `fits`),
  `exercise_draft_builder.dart` (`ExerciseDraftValues.speakerId`,
  `lineMode`, `lineReadAloud`, `lineTextReveal`, `lineLanguage`;
  `_buildDialogueLine`, `_buildStoryCover`, canonical).
- `lib/models/exercise_features.dart`: `LearnerExerciseKind.dialogueLine`,
  `storyCover`; `lineElements`, `lineText`, `lineAudio`, `lineMode`,
  `speakerId`, `lineReadAloud`, `lineLanguage`, `textReveal`, `coverTitle`;
  `illustrationImages` skips avatars.
- `lib/services/exercise_copy_service.dart` (eight languages),
  `exercise_field_help.dart` (speaker, dialogueLine, lineMode,
  lineReadAloud, lineTextReveal, lineLanguage, coverTitle, coverImage;
  `editorFieldKeys`), `exercise_search_service.dart`,
  `course_image_usage.dart` (avatars), `authoring_duplication_service.dart`
  and `course_authoring_transfer_service.dart` (speakers carried),
  `course_cover_service.dart` (`storeAvatar`: the chosen square as a PNG
  halved from 256 px until it fits the 50 KB image limit).
- `lib/services/course_audit_service.dart`, `audit_code_registry.dart`:
  `STORY_TITLE_MISSING`, `STORY_WITHOUT_DIALOGUE`, `STORY_SPEAKER_UNKNOWN`,
  `DIALOGUE_LINE_EMPTY`, `DIALOGUE_LINE_OUTSIDE_STORY`; `kindLabel` and
  `_mismatchHint` for the two presets; 103 rules.
- `lib/screens/round_screen.dart`: the Story queue (lines and covers never
  skipped, `requiresAudio` nodes skipped with the audio exercises),
  `_dialogueLineExercise` (`story-line-bubble`, `-narrator`, `-play`,
  `-continue`, `-audio-note`), `_storyCoverExercise` (`story-cover-title`,
  `-continue`; the shared illustration stays out and a title line equal to
  the Story title shows once), `_automaticAudioOf`, `_lineSpeaker`,
  `_lineLanguage`, `_playCourseAudio(voice:)`, the filtered scroll log.
  `lib/services/tts_cache_service.dart`: `speak(voicePreference:)`.
  `lib/services/duel_eligibility_service.dart`: Story Rounds skipped.
- `lib/screens/course_editor_screen.dart`: the Dialogue line and Story
  cover forms (`_choiceField`, keys `exercise-choice-<field>`), Round editor
  `round-story-title` / `-log` / `-read-aloud` and the `audio` menu item,
  Course editor `course-story-characters` (`story-narrator`,
  `story-character-<id>`, `story-character-add`, removal refused with the
  line count), `StoryWizardScreen` (`StoryWizardResult`,
  `storyWizardPresets`, keys `story-wizard-*`), `lesson-story-wizard`,
  `_courseWithSpeakers`, `_blankExerciseForPreset` for canonical-only
  presets.
- `lib/widgets/story_speaker_dialog.dart` (new: `StoryAvatar`,
  `showStorySpeakerDialog`, bundled avatars, None, Choose image / Quick
  Import / Open from… through the cover crop dialog),
  `lib/widgets/story_line_dialog.dart` (new: `showStoryLineDialog`).
- `lib/localization/help/help_structure.dart`, `help_en.dart`,
  `help_it.dart`, `help_es.dart`: the presets' descriptions and field help,
  `storiesAndStoryWizard` in the Editor Help, the Stories section of the
  Exercise primitives page.
- `lib/services/course_service.dart`, `home_screen.dart`,
  `available_courses_screen.dart`, `gamification_settings_screen.dart`,
  `course_library_operations.dart`: `courseAssets` without `KO`;
  `bundledAssets`, `debugExtraAssets`, `debugAssetReader` (test seams);
  `test/support/korean_fixture.dart`, `test/fixtures/v12/korean_en.json`.
- `tools/make_avatars.ps1` → `assets/avatars/{cat,dog,kid,monkey,robot}.png`
  (`pubspec.yaml`); `tools/qql_course_v12.py` (`textReveal`, canonical
  content passthrough, `story_line`, `story_cover`, `story_flow`); the three
  generators (Story Lessons after conversion; the Laboratory's coverage
  document), `tools/validate_courses.py` (6 / 6 / 40 Lessons);
  `assets/courses/*.json` and `test/fixtures/v11/*` regenerated.
- Tests: `test/story_model_256_test.dart` (14), `story_presets_256_test.dart`
  (7), `story_runtime_256_test.dart` (5), `story_editor_256_test.dart` (10),
  `story_wizard_256_test.dart` (3); the Laboratory test (Story Lesson,
  lines and covers in `_answer` and `_author`, the source-language voice),
  the presentation baseline re-recorded (116 records, 9 new, none changed),
  the converter parity test skipping Story Lessons, the demo pins, the
  registry pins (103 / 58 / 39), the version pins.

### Architecture decisions implemented

- Plan §0 (owner): reusable narrator and characters at Course level; voice
  preference any / male / female with per-line read-aloud override; lines
  never skipped, audio-dependent exercises skipped; any exercise markable
  as needing the Story's audio; text immediately or after listening; the
  Story Wizard's Step E opens the normal form and returns to the builder;
  Story exercises out of the Duel; one whole-figure avatar per mascot;
  existing Stories keep their stored presentation.
- Plan §12 (mine): allowed Wizard presets; the Round title prefix `Story: `
  with the cover as a separate first node; a Dialogue line outside a Story
  is a Warning; removing a referenced character is refused; the character's
  voice preference wins over the learner's; an audio-only line shows its
  transcript only without audio and in the log.
- A canonical-only preset's blank exercise is what its recipe builds from
  empty fields (`PresetRecipes.canonicalOnly`), so it is a presentation
  from the start.
- The Wizard's cover always carries the Story title as its title line, so
  it is a Story cover with or without a picture; the cover card shows it
  once.
- The bundled Story Lessons are appended after the v11 conversion in the
  generators, so the v11 fixtures and the Dart converter never see content
  without a v11 shape; the parity test checks that every shipped content
  the fixture lacks belongs to a Story Round or carries a canonical-only
  preset.

### Follow-up in the same version (owner review, 28 September 2026)

- `lib/screens/round_screen.dart`, `lib/screens/duel_screen.dart`: the
  post-answer button reads Continue (Round, Story, Duel); Finish story and
  "Finishing story…" on a Story's last step; the completion dialog of a
  Round without evaluable exercises ("Story completed" / "Round completed",
  `round-completed-unscored`, no XP lines); `_scrollStoryToEnd` leaves
  `storyScrollMargin` (a fifth of the viewport, at most 120 px) above the
  active item through `RenderAbstractViewport.getOffsetToReveal`; the
  Review context and the Round screen use the derived Story label.
- `lib/services/exercise_copy_service.dart`: `instructionForExercise`
  chooses `instruction.dialogueLine`, `dialogueLineText`,
  `dialogueLineAudio` or `dialogueLineAfterAudio` from the line's mode and
  `textReveal`; the three new keys in EN, ES, IT, DE, PT, NL, FI, CY.
- `lib/services/xp_calculator.dart` (`RoundXpAwardContext.evaluableExerciseCount`,
  zero awards nothing), `lib/services/learning_completion_service.dart`
  (no Laurel and no perfect mark without evaluable exercises),
  `lib/services/round_playability_service.dart` (`laurelEligibleRoundIds`
  needs a scored playable exercise): the scoring rule "no exercise, no
  XP"; AGENTS' Round XP rules updated; App Info Help (EN/IT/ES) states it.
- `lib/models/course_models.dart`: `LearningRound.isStory`, `storyTitle`,
  `withoutStoryPrefix`, `storyTitlePrefix`; `displayTitle` derives
  "Story: <title>" for a Story. `lib/screens/home_screen.dart`,
  `review_screen.dart`, `course_editor_search_screen.dart` and the Round
  editor's app bar use it; `_setStoryTitle` only writes the flow title; a
  Story switched on over a named Round is named after it; the Wizard's
  Round title is the Story title without the prefix.
- `lib/services/portable_exercise_image.dart`: `assets/avatars/<name>.png`
  is a bundled asset to the decoder (avatars were drawn as broken images).
- Generators: the Laboratory Story Lesson holds "A morning in Turin"
  (cover, lines and questions alternating, 9 examples) and "The same
  morning, line by line" (the four line options, nothing to score, 6
  examples): 122 examples, presentation baseline re-recorded; the
  Piedmontese demo has 39 Lessons (no Story cover Lesson) and reads every
  line at once (117 examples); the Edge Case demo's Story alternates its
  question with the lines and gains "Tre copertine", a Story of covers
  alone whose `STORY_WITHOUT_DIALOGUE` is its third intentional warning
  (12 Rounds, 39 exercises); `tools/validate_courses.py` expects 39
  Piedmontese Lessons.
- Second follow-up (same version, 28 September, evening):
  `lib/screens/round_screen.dart` draws no heading for a Dialogue line (the
  DIALOGUE label is gone; the instruction stays); the Laboratory
  presentation baseline re-recorded for the ten line examples (heading
  null), no other record changed; `story_runtime_256_test` pins it.
- Third follow-up (same version, 28 September, night; owner requests of
  21:10 and 21:25): `lib/screens/course_editor_screen.dart`: the Lesson
  editor loses `_openGuidebookRoundGenerator`, `_openStoryWizard` and its
  two wizard buttons; the Rounds page (`_LessonRoundsScreenState`) gains
  them as a bottom bar (`rounds-round-wizard` with the Use GuideBook
  tooltip, `rounds-new-story`; the Round Wizard appends through
  `_updateRounds`, New Story through `_courseWithSpeakers` +
  `ReplaceRounds`); the Wizard's app bar reads "New Story · …"; the Round
  editor of a Story shows `round-add-step` instead of the three exercise
  buttons (`_addStoryStep`: the sheet `story-step-title` /
  `story-step-line` / `story-step-exercise`; `_insertPreset(first:)` puts
  a title block first through `_acceptFirst`; `_insertLine` uses
  `showStoryLineDialog` and the shared `_dialogueLineExercise`, which the
  Wizard's `_lineExercise` uses too; `_chooseStoryPreset` is the Story
  presets sheet shared with the Wizard), `Duplicate` greyed out for a
  Story's title block, `round-story-steps` (`_storyStepsSummary`) under the
  Story options, whose "Lines are never skipped" sentence is gone. Help
  (EN/IT/ES: the Round Wizard, Exercise Wizard and Stories sections, the
  Stories title "Stories and New Story"), the `STORY_WITHOUT_DIALOGUE`
  hint, the Story cover preset text and README name New Story and the
  Rounds page. Tests: `story_add_step_256_test.dart` (five tests);
  `story_wizard_256_test`, `revision3_followup_256_test`,
  `guidebook_sentence_generator_test`,
  `production_course_transaction_225_04_test` and
  `qql_231_course_editor_ui_test` reach the wizards on the Rounds page.
- Tests: `xp_calculator_test` (a Round without evaluable exercises awards
  nothing), `learning_completion_service_test` (no Laurel, no XP; facts
  state their counts), `round_playability_service_test` (cards and texts
  alone are not Laurel-eligible), `round_xp_completion_regression_test` (a
  Round of cards only completes without XP, bonus or Laurel; Continue),
  the seven files that pressed Next, `story_runtime_256_test` (per-mode
  instruction, the avatar drawn as its asset, Finish story),
  `story_editor_256_test` (`displayTitle` rules, the Round keeps its name),
  `story_wizard_256_test`, the demo pins.

### Known limitations and deferrals

- Branching flows are still not playable (Revision 6); the Story Wizard
  builds linear Stories only.
- The Wizard adds and edits characters but does not remove them (removal,
  with the reference check, lives in the Course Editor).
- A custom avatar is a PNG of at most 50 KB (the ordinary image limit), so
  a detailed photo is scaled down to 128 or 64 pixels.
- The save guard on example content (Revision 4) is still not implemented.

## Revision 4 (2.0.56+256004, 27 September 2026): the preset catalogue

Session 5. The catalogue decided in `docs/256_PRESET_CATALOGUE_PLAN.md`:
38 presets in six skill groups, twins where the direction matters, seven
greyed presets, pictures on answers, and the runtime the new presets need.
Course files stay Course Model v12.

### Files

- `lib/models/exercise_authoring.dart`: `ExerciseCategory` (vocabulary,
  grammarAndSentences, listening, readingAndDialogue,
  picturesAndCharacters, cardsAndNotes, comingLater), `PresetDirection`,
  `ExercisePreset.direction`/`base`/`twin`/`action`, the 38 presets,
  `ComingLaterPreset` and `ExercisePresetRegistry.comingLater`,
  `successorOf`/`currentIdFor`, `helpByPreset`.
- `lib/models/preset_successors.dart` (new, plain Dart): `presetSuccessorOf`
  (retired ID → successor) and `presetRecipeBaseOf` (catalogue preset →
  the older recipe it is built on); mirrored by `PRESET_SUCCESSOR` and
  `PRESET_BASE` in `tools/qql_course_v12.py`.
- `lib/services/preset_variants.dart` (new): `baseFor` (the recipe the
  builder runs, following the shape hints), `formBase`/`formFor`/`ownForms`,
  `draftFor` (inline flags forced per preset, Missing letters brackets →
  gaps, Note card), `finish` (`toSource` marks a "to source" twin's
  question, items or clue; `_shape` adds True or false answers in the
  source language, Spell the word's clue language, a Picture flashcard's
  optional audio, Match picture to word's pictures), `isImageReference`,
  `fits`/`hasInWordGap` (the shape that tells the presets of one recipe
  apart, asked before rebuilding: an in-word gap is Missing letters, a
  picture Spell the word in the picture, automatic audio Spell what you
  hear, neither Spell the word).
- `lib/services/exercise_draft_builder.dart`: `ExerciseDraftValues.
  revealFirstLetter`, `textRole`, `audioRole`, `matchSides`, a wider
  `copyWith`; `build` runs the base recipe then `PresetVariants.finish`;
  spoken text kept for Select the image, Spell the word in the picture and
  Choose (True or false); Missing letters keeps its hint.
- `lib/services/preset_recipes.dart`: `kinds` as sets per preset,
  `defaultPresetFor` on catalogue IDs, `presetToEdit` through the successor,
  decompose records the shape hints, the bracketed sentence and picture
  items; `rebuild`'s blank carries the recipe's base type.
- `lib/models/course_models.dart`: the converter records successor IDs
  (`_givenMetadata`, `convertV11`), `_legacyTypeFromTemplate` resolves a
  catalogue preset to its base recipe, an explicit `language` attribute
  wins over the preset-implied one, `media:`/`data:` icon keys become image
  elements, Select the image and Spell the word in the picture audio play
  automatically; `Presentation.fromExercise` reads an omitted completion
  mode as the registry default, `proceed` (`['continue']`), as the runtime
  does (it used to answer understood/review). `lib/services/
  course_model_v12_converter.dart` records successors too and no longer
  notes a `["continue"]` card (the proceed mode itself, nothing unmapped;
  any other non-standard action list is still noted).
- `lib/models/exercise_features.dart`: input kinds (`inputComplete` for a
  gap without reveal), `isTranslationClue`, `answerLanguage`,
  `primaryAudioLanguage`, `audioLanguageOf`, `bracketedSentence`,
  `isLineOrder` and `LearnerExerciseKind.arrangeLines`.
- `lib/services/exercise_copy_service.dart`: `arrangeLines` heading and
  instruction in EN, ES, IT, DE, PT, NL, FI, CY.
- `lib/screens/round_screen.dart`: `_voiceFor` (source voice), captioned
  picture answers in the grid, `_itemImage` (Course media through
  `CourseMediaImage`, bundled and portable pictures as before), Match left
  pictures (`_matchLeftContent`), within-word gap underscores.
  `lib/screens/duel_screen.dart`: `_voiceFor`, Course media on answers.
- `lib/screens/course_editor_screen.dart`: the picker (groups,
  `_PresetActionChip`, `exercise-preset-direction`, `exercise-preset-<id>`,
  `exercise-preset-later-<id>`), `formFor` switch and the 13 own forms, the
  merged Listen and answer and Read and answer forms (`Spoken text`,
  `Question (optional)`, `Text to read`, `Spoken text (optional)`, `Dialogue
  lines (optional)`), direction labels on the translation twins,
  `type-missing-word-reveal`, `_answerPictures` (one `ExerciseImageField`
  per answer), Match picture to word as words + pictures, inline switches
  removed, True or false prefilled (`_trueFalseAnswers`), the shape hints
  carried through the form.
- `lib/services/course_audit_service.dart`: `currentIdFor`, kind sets,
  Read and answer / Listen and answer / True or false / picture / Match
  picture to word rules, `_mismatchHint`, the widened spelling rule,
  `kindLabel` for `arrangeLines`. `lib/services/audit_code_registry.dart`:
  four codes retired (98 rules), areas renamed. `FLASHCARD_EXAMPLE_EMPTY`
  and `FLASHCARD_AUDIO_EMPTY` apply to vocabulary flashcards only (reviewed
  later, no picture): a Note card and a Picture flashcard carry optional
  usage and pronunciation; `ROUND_DUPLICATE_CONTENT` counts the prompt's
  pictures, so three "What is this?" pictures are three exercises.
- Exercise Wizard: `_blankExerciseForPreset` builds the planned exercise
  with the recipe's base type and the preset as editor template. It used
  the preset ID as the v11 type, which for a catalogue twin (Type the
  translation (to target)) is no v11 type and fell back to a Select
  interaction: the Wizard then saved a Select without items and lost the
  accepted translations (found by the complete suite).
- `lib/services/exercise_field_help.dart`: `editorFieldKeys`/`fieldForEditor`
  for the 38 presets, 12 new `ExerciseAuthoringField` values, seven dead
  ones removed, to-source help; `lib/localization/help/help_structure.dart`
  and the EN/IT/ES catalogs (every preset's description and body, the new
  field bodies, the Read and answer example); `lib/services/
  exercise_search_service.dart` definitions; `lib/services/
  exercise_creation_planner.dart` skips empty groups;
  `lib/screens/editor_help_screen.dart` Coming later section;
  `lib/services/guidebook_round_generator.dart` and
  `lib/models/exercise_interoperability.dart` on catalogue IDs.
- Generators and Courses: `tools/generate_exercise_laboratory_254.py`
  (languages, optional audio, pictures on answers and Match items, cards;
  107 examples; `course_v11()`), `tools/generate_piedmontais_demo_254.py`
  (one Lesson per preset in registry order, `gaps()`, `picture_card()`,
  `note()`, version 1.2.0; `build_course_v11()`), `tools/qql_course_v12.py`
  (successors, bases, explicit languages, automatic audio);
  `assets/courses/*.json` regenerated; `test/fixtures/v11/` Laboratory and
  Piedmontese originals regenerated; `docs/254_LABORATORY_COVERAGE.md`.
- Tests: `test/preset_catalogue_256_test.dart` (new); the Laboratory
  presentation baseline re-recorded (`test/support/laboratory_presentation_254.dart`,
  107 records); pins moved in the editor, Help, Audit, runtime, recipe,
  converter, Laboratory and Piedmontese tests.

### Architecture decisions implemented

- Presets stay metadata (plan A.3): the runtime, the Duel and the Audit
  read canonical data; a preset never changes behavior. The catalogue is
  the authoring vocabulary: recipes over the same canonical fields.
- A retired preset is read as its successor everywhere and the successor's
  form keeps an opened exercise's shape (shape hints), so no stored
  exercise changes meaning when it is reopened and saved unchanged.
- A "to source" twin is the same recipe with the source-language side
  stated on the elements (`language`); an explicit language wins over the
  language a v11 preset implied.
- Inline gaps are presets of their own; the Choose, Word order and Build
  the translation forms have no switches for them.
- Pictures on answers are image elements on items; the Round and the Duel
  draw Course media through `CourseMediaImage`, bundled and portable
  pictures as before.

### Known limitations and deferrals

- The save guard on example content (refusing Save while a required field
  still holds its example) is not implemented: the forms do not prefill
  examples, so there is nothing to refuse yet.
- Match picture to word keeps the dropdown Match layout; Match picture to
  sound stays greyed (it needs a tap-to-pair layout).
- The Piedmontese demo is an AI-generated sample: its new Lessons are not
  linguistically reviewed.
- Interoperability (Revision 5) and the Laboratory by primitive and option
  with the Assign runtime (Revision 6) follow.

## Revision 3 (2.0.56+256003, 27 September 2026): presets as recipes and the Generic Primitive Editor

Session 4. Course files stay Course Model v12; presets become recipes,
every canonical field is editable, Stories keep their flow through
authoring, and the creator-side code reads canonical data.

### Files

- `lib/services/preset_recipes.dart` (new): `PresetRecipes.kinds`,
  `defaultPresetFor`, `presetToEdit`, `decompose`, `rebuild`, `represents`
  (decompose → rebuild → semantic comparison in a normalized form: positional
  item IDs, stable element order by role and type, blank image captions)
  and `recognize` (own preset first, then same-kind presets).
- `lib/services/canonical_exercise_draft.dart` (new): the pure, mutable
  draft behind the Generic Primitive Editor; `toExercise` applies plan A.13
  (metadata kept only while semantically unchanged, preset by recognition);
  `blankExercise`; registry `violations`; `audit`.
- `lib/screens/primitive_editor_screen.dart` (new): the Generic Primitive
  Editor (keys `primitive-editor`, `primitive-editor-primitive`,
  `primitive-option-<key>`, `primitive-prompt-add-*`, `primitive-item-add`,
  `primitive-target-add`, `primitive-layout-add-*`,
  `primitive-evaluation-mode`, `primitive-correct-<item>`,
  `primitive-support-state`, `primitive-violations`, `primitive-preview`,
  `primitive-inspection-toggle`, `primitive-save-draft`, `primitive-save`).
- `lib/widgets/editor_dialogs.dart` (new): the shared `confirmMoveToDraft`.
- `lib/services/round_flow_authoring.dart` (new): `linearFor`,
  `forContent`, `remapped`.
- `lib/screens/course_editor_screen.dart`: the exercise editor decomposes
  through the recipe (init and Previous/Next), `_exerciseEditorFor` routes
  to the canonical editor when no preset represents a stored exercise,
  `exercise-unrepresentable-notice` + `exercise-open-canonical`, the preset
  sheet's `exercise-preset-canonical` entry, the Round editor's
  `new-canonical-exercise` button and `round-story-switch`, `_flow` carried
  through `_editedRound`, Rename, Search saves and GuideBook references;
  canonical reads (`_exerciseKindName`, `_exerciseTypeLabel`,
  `_exerciseSummary`, `ExerciseFeatures` in the wizard and validation).
- `lib/services/exercise_search_service.dart`,
  `course_hierarchy_update_service.dart`,
  `lib/widgets/script_recognition_editor.dart`,
  `lib/services/course_authoring_transfer_service.dart`,
  `authoring_duplication_service.dart`, `course_audit_service.dart`
  (`kindLabel` public, `presetKinds` = `PresetRecipes.kinds`).
- Help: `lib/localization/help/help_{en,it,es}.dart` (Exercise primitives
  sections `primitives`, `primitiveOptions`, `layouts`, `evaluationModes`,
  `presets`, `canonicalEditor`, `stories`; supplement `canonicalEditor`),
  `help_structure.dart`.
- Docs: `docs/256_PRESET_CATALOGUE_PLAN.md` (new, the owner's decisions and
  the proposed catalogue for Revision 4), the plan's Part B (session 5
  inserted), `docs/EXERCISE_ARCHITECTURE_V12.md` status.
- Tests: `test/preset_recipes_256_test.dart`,
  `test/primitive_editor_256_test.dart`,
  `test/round_flow_authoring_256_test.dart` (new).

### Architecture decisions implemented

- Plan A.12 (Help chapters), A.13 (exact recognition, metadata clearing,
  primitive locked, defaults from the registry), Part B Session 4 (new
  files, controls from the registry, View only and Inspection on canonical
  data, Story order in the Round editor).
- Decision: `ExerciseDraftBuilder` keeps constructing candidates through
  `Exercise.v2`/`Exercise(...)` (converter input) while every read is
  canonical; Revision 4 rewrites the recipes with the new catalogue.
- Defect found and fixed: Rounds lost their `flow` on every rebuild.

### Follow-up in the same version (27 September 2026, afternoon)

The owner's review of the Windows build: `lib/models/canonical/content_flow.dart`
(`FlowPresentation`, `flow.presentation`), `lib/services/round_flow_authoring.dart`
(`linearFor(presentation:)`, `withPresentation`, kept through `forContent` and
`remapped`), `lib/screens/round_screen.dart` (scrolling Story: `_storyLog`,
`story-entry-N`, auto-scroll), `lib/screens/course_editor_screen.dart`
(`round-story-presentation`, the two New exercise buttons,
`round-draft-exercises-notice`, `_formSnapshot` change detection, the
intro hook), `lib/screens/primitive_editor_screen.dart` (`_hasUnsavedChanges`
by semantic comparison, the intro hook), `lib/services/canonical_exercise_draft.dart`
(`requiredOptionDefaults`), `lib/widgets/exercise_editor_intro.dart` (new),
`test/flutter_test_config.dart` (intro off in tests), the Help catalogs
(wizard names, the two buttons, presets versus canonical, scrolling
Stories), `windows/runner/win32_window.cpp` (window inside the work area),
`docs/256_PRESET_CATALOGUE_PLAN.md` (direction decisions). Tests:
`test/revision3_followup_256_test.dart`. Second follow-up (owner's visual
inspection): the Round editor's New exercise / New canonical buttons and
`_compactButtonStyle`, the type-choice snapshot reset for new exercises,
the Round Wizard tooltip and disabled state without GuideBooks, the
scrolling Story's `story-now` marker, top-aligned scroll and debug event;
two more tests in the same file.

### Known limitations and deferrals

- The canonical editor edits image assets by reference or from the Image
  Library (portable copies, as Recognize characters does); the Course media
  picker of the preset forms is not embedded in it yet.
- The v11-shaped views on `Exercise` still exist for the draft builder and
  tests; they go with the Revision 4 recipes.
- The preset catalogue itself (merges, renames, new presets, pairs, filter,
  save guard) is Revision 4.

## Revision 2 (2.0.56+256002, 27 September 2026): runtime and Audit on canonical data

Session 3. Course files stay Course Model v12; the learner runtime, the
Duel and the Audit stop reading preset IDs.

### Files

- `lib/models/exercise_features.dart` (new): `ExerciseFeatures` (roles,
  attributes, options, layout, evaluation and feedback of one exercise) and
  `LearnerExerciseKind` (the derived kind that keys headings).
- `lib/widgets/exercise_prompt_panels.dart` (new): the Select panels shared
  by the Round and Duel screens.
- `lib/screens/round_screen.dart`: dispatch by primitive and features,
  grading from the evaluation (literal answers, typo tolerance, ranked
  alternatives, joiner, content-based gap grading), flows, keys
  `exercise-heading`, `exercise-instruction`, `exercise-prompt-text`,
  `exercise-passage`, `exercise-image`, `exercise-renderer-<primitive>`.
- `lib/screens/duel_screen.dart`: choices from items, panels, image
  answers, translation Select from features.
- `lib/services/exercise_copy_service.dart` (keyed by kind, eight
  languages), `translation_choice_service.dart` (`instructionFor`,
  `spokenTextFor`), `duel_eligibility_service.dart` (`isEligible`),
  `audio_exercise_availability_service.dart` (required audio),
  `round_playability_service.dart` (branching flows not playable).
- `lib/services/course_audit_service.dart`: `auditExercise` rewritten on
  canonical data with the capability registry; `presetKinds`;
  `lib/services/audit_code_registry.dart`: five codes added, seven retired,
  preset rules as Warnings, unknown preset as Info (102 rules).
- Converter (`Exercise.convertV11`, `tools/qql_course_v12.py`): `situation`
  and `character` roles, Match side languages, `clue` text languages,
  optional translation audio; `assets/courses/*.json` regenerated.
- Tests: `test/runtime_canonical_256_test.dart` (new),
  `test/support/laboratory_presentation_254.dart` (new baseline) with the
  recorder in `exercise_laboratory_254_test.dart`, and the updated Audit,
  Duel, copy and renderer-key tests.

### Architecture decisions implemented

- Plan §A.3 (no preset-dependent runtime branch: the report lists none),
  §A.5, §A.7 (linear Stories), §A.10, §A.11, §A.13 (learner labels from
  features; merged labels reported).
- Deliberate learner-visible changes: Match the words' instruction, the
  Dialogue response situation shown once, the Duel pool (A.10), repeated
  blocks in inline-gap Arrange (A.11).

### Known limitations and deferrals

- The editor, the draft builder, Search and the copy/duplication services
  still read the v11-shaped views on `Exercise`; Session 4 moves them and
  deletes the views.
- Readable-but-not-executable exercises are kept by the Audit and skipped
  nowhere yet (Session 5, A.6); branching Stories are simply not playable.
- Exact preset recognition and metadata clearing: Session 4.

## Revision 1 (2.0.56+256001, 27 September 2026): Course Model v12

Session 2. Course files change format (clean cut); learner, Audit and
editor behavior do not, apart from one editor fix.

### Files

- `lib/models/exercise_canonical.dart` (new): `ExerciseTarget`,
  `LayoutElement`, `CanonicalEvaluation`, `ExerciseFeedback`,
  `OrderedAnswer`, the element attribute enums, strict JSON parsing
  (unknown keys are format errors).
- `lib/models/course_models.dart`: `Course.currentFormatVersion = 12`;
  `LearningRound.flow`; `LearningContent` with `authoringMetadata` and the
  derived views `kind`, `exercise`, `editorTemplate`, `presentation`;
  `PromptElement.language/playback/required`; `ExerciseItem.side`;
  `Exercise` rebuilt on the canonical fields (`Exercise.canonical`,
  `toJson`/`fromJson`, `effectiveOptions`, `semanticJson`,
  `semanticallyEquals`, `copyWith`, `withPublicationState`,
  `withAuthoringMetadata`), `Exercise.convertV11` as the one v11 → v12
  mapping (used by `Exercise.v2` and the legacy constructor), and the
  v11-shaped read-only views kept for the runtime, Audit and editor until
  Sessions 3–4.
- `lib/models/canonical/content_flow.dart`: JSON for flows, nodes,
  transitions and conditions.
- `lib/services/course_model_v12_converter.dart` (new, no Flutter imports):
  `convertCourseJsonToV12` with plain-language notes.
- `tools/convert_course_to_v12.dart` (new: JSON or ZIP, `--overwrite`),
  `tools/convert_stored_courses_256.dart` (new, one-off device
  conversion), `tools/qql_course_v12.py` (new Python mirror),
  `tools/validate_courses.py` (v12), the three `tools/generate_*_254.py`
  generators (emit v12); `tools/convert_course_to_v11.dart` retired.
- Storage: `CourseFileStore.rootDirectoryName = 'QQL_Courses_v12'`;
  `QqlEarlierPrivateFolders.coursesV11` (retired `QQL_Courses`);
  `CourseBackupService.backupFormat` 12 with `earlierBackupFormat`;
  `InventoryService` label.
- Call sites moved from `arrangeLayout`/`arrangeGapAssignments` to
  `layout`/`targetAssignments`: `round_screen`, `course_editor_screen`,
  `course_audit_service`, `course_image_usage`,
  `authoring_duplication_service` (deep-copies answers),
  `exercise_draft_builder`; `exercise_search_service` indexes
  `inlineSentence`.
- Editor: `_withExercisePublication` and `_withSelectedSharedSource` copy
  the canonical exercise instead of rebuilding it through the v11 views.
- `lib/services/course_image_removal.dart` clears image uses from the v12
  `items` JSON (it still read the v11 `interaction`; found by the
  complete suite).
- Data: `assets/courses/*.json` (four bundled Courses), the demo package
  JSON and ZIP, the Publisher fixtures (`dummy-*.json`, re-signed with the
  test key; `dummy-signed-media.zip` rebuilt); `test/fixtures/v11/` holds
  the v11 originals.
- Help EN/IT/ES: every line that named the format or the converter.
- Docs: `COURSE_JSON_FORMAT.md` (format 12), `239_RESET_STORAGE_INVENTORY.md`,
  `EXERCISE_ARCHITECTURE_V12.md` (status, JSON section), AGENTS.md
  (invariants rewritten for v12, boundary entry), README, CHANGELOG.
- Tests: `test/course_model_v12_256_test.dart` (new) and the updated v11
  suites listed in `256_VALIDATION.md`.

### Architecture decisions implemented

- Plan §A.4 (extra canonical fields), §A.8 and §A.14 (clean cut, storage
  Option 2, one-off tool), §A.13 (semantic equality; v11 shapes as helpers
  only), §B Session 2.
- One mapping, three homes: `Exercise.convertV11` (memory),
  `convertCourseJsonToV12` (files), `qql_course_v12.py` (generators); the
  parity test in `course_model_v11_243_test.dart` compares Dart and Python
  output on every bundled Course.
- The runtime is not moved yet: the v11 views on `Exercise` exist so that
  Session 2 changes the format without changing behavior; Sessions 3–4
  remove them.

### Known limitations and deferrals

- Options, flows and executability are stored and validated but not yet
  read by the runtime or the Audit (Session 3); presets still act as
  templates in the editor (Session 4).
- A Presentation converted from a v11 file gets its Round's `updatedAt`
  (v11 presentations had none).
- The package manifest keeps `packageFormat: 1`; Publisher Courses must be
  re-signed after conversion.

## Revision 0 (2.0.56+256000, 27 September 2026): canonical definitions

Session 1. No Course JSON, learner, Audit or editor behavior changes.

### Files

- New `lib/models/canonical/`: `exercise_primitive.dart`,
  `evaluation_mode.dart`, `primitive_options.dart`,
  `primitive_capability_registry.dart`, `content_flow.dart` and the barrel
  `canonical.dart`.
- `lib/models/exercise_authoring.dart`: `ExercisePreset.primitive`
  (`ExercisePrimitive`) replaces `model` (`CanonicalExerciseModel`, removed).
- `lib/services/course_audit_service.dart`: the preset-versus-response check
  reads `preset.primitive.serialized`.
- Tests: new `canonical_primitives_256_test.dart`,
  `capability_registry_256_test.dart`, `content_flow_256_test.dart`; updated
  `exercise_architecture_224_test.dart`, `translation_choice_239_test.dart`,
  `exercise_laboratory_254_test.dart` (field rename) and the version tests.
- Docs: new `EXERCISE_ARCHITECTURE_V12.md`, `256_EXERCISE_ARCHITECTURE_PLAN.md`,
  `256_HANDOFF.md`, this file and `256_VALIDATION.md`;
  `EXERCISE_ARCHITECTURE_224.md` marked historical; README, CHANGELOG,
  AGENTS.md release boundary.
- Version `2.0.56+256000`; Beta expiry 27 October 2026 (unchanged date; the
  comment and the test title now name Build 256 Revision 0).

### Architecture decisions implemented

- Exactly nine primitives with strict lowercase identifiers; `executableToday`
  is documentation only, executability is decided per exercise.
- One option vocabulary: `OptionKey` (stable JSON name, value kind, union
  vocabulary), closed `OptionEnumValue` enums, `OptionValue` (enum, bool,
  int, language tag) with a parser that never coerces, `PrimitiveOptions`
  storing only what was given.
- `PrimitiveCapabilityRegistry`: per-primitive `OptionDefinition`s (legal
  subset, default, required, minimum), evaluation modes with a default,
  coded rules (`OptionImplication`, `OptionRequiresIntegers`,
  `EvaluationImplication`, `OptionEvaluationImplication`,
  `IntegerOrderRule`), `checkSelectionLimits`, `parseOptions`,
  `effectiveOptions`, `validate`, and the `runtimeSupportTable` of
  `SupportedConfiguration`s behind `runtimeSupport` (states executable,
  readableButNotExecutable, invalid; unsupportedModelVersion reserved for
  the Course level).
- `ContentFlow`: `FlowNode` (content or exercise, contentId),
  `FlowTransition` (next, onCorrect, onIncorrect, onChoice with
  choiceItemId, conditional with a `FlowCondition`), structural checks,
  `isLinear` and `linearNodeIds`, `ContentFlow.linear`.
- Final names for the plan's A.4 fields and the converter's list of
  behaviors that do not map cleanly are in `EXERCISE_ARCHITECTURE_V12.md`.

### Known limitations and deferrals

- Nothing is serialized yet: options, flows and the A.4 element attributes
  get their JSON form in Session 2.
- The runtime-support table describes today's behaviors; Session 3 makes the
  runtime read it, Session 6 adds Assign.
- Speak, Ink, Submit and Assign have definitions only.
