# Round Types Redesign Implementation Plan

> **Implementation authorized:** The owner approved execution and commit on 3 October 2026. The remaining playback and Wizard choices below use the documented implementation defaults. Build 261, Revision 7 is the requested release identifier.

**Goal:** Give every Round an explicit type that controls authoring, compatible content, playback where specified, and learner identity; move Story guidance from Exercise Primitives Help into a new Round Types topic in Editor Help.

**Architecture:** `LearningRound.roundType` is the semantic contract. A central compatibility service evaluates canonical exercises and supplies both authoring filters and Audit results. Presentation reads the same type for labels and icons. Existing flow data continues to carry Story and Sequence order and presentation options.

**Tech stack:** Flutter/Dart, Course Model v12 JSON, Python bundled-Course generators and validator, Flutter tests.

**Spec:** `docs/QQL_Round_Types_Redesign_Plan.md` (owner-supplied proposal dated 2 October 2026). Its text is design input; this plan does not authorize implementing every suggestion without the decisions below.

## Analysis of the current app

- `lib/models/course_models.dart` stores `visualType` and optional `flow`; `isStory` and `isSequence` derive from those fields. No `roundType` exists. Missing-field handling is therefore a migration requirement for existing v12 Courses.
- `lib/screens/course_editor_screen.dart` has separate New Round, Round Wizard, and New Story actions. New Round immediately makes a provisional Draft with a sample exercise. The Round editor has Play as a sequence. The Story wizard builds a single Round and also edits Course characters.
- `lib/screens/round_screen.dart` shuffles when there is no flow and uses flow order otherwise. Immediate feedback and a mistake-review phase are the default. Test requires a separate attempt/results path; changing only the icon would not satisfy the proposal.
- `lib/screens/home_screen.dart` chooses a path icon from `visualType` and prints Round/Story/Sequence prefixes. `Lesson Options` is Course-level UI, so its proposed Round-numbering setting would be stored on the Course, while each displayed number comes from the Round's position within its Lesson.
- `lib/services/guidebook_round_generator.dart` plans preset IDs and titles without a Round type. The Wizard's current GuideBook dependency and multi-Round role should remain.
- `lib/localization/help/help_structure.dart` puts `stories` in Exercise Primitives Help. Editor Help already has Story and Sequence questions in `lessonsAndRounds`. A new `roundTypes` topic can own all Round-type explanations without a new standalone Help route.
- Canonical data describes media and evaluation, but the presence of audio or text alone cannot prove it is needed to answer. Listen and Read need a defined, testable eligibility rule before their filters and publication errors can be reliable.

## Decisions and remaining design points

The owner confirmed on 3 October 2026:

1. **Old visual labels:** Assign Practice unless the old Round validates for another new type. Structural Story/Sequence flow takes precedence. An old Test icon cannot prove deferred-feedback behavior, so it becomes Practice. An old Listen icon can become Listen only if it has at least one required exercise and all required exercises meet the new structural rule.
2. **Essential capabilities:** Accept only canonical configurations whose required audio or reading dependency can be verified structurally. Do not add a persisted author declaration. `ExerciseFeatures.requiresAudio` by itself does not prove dependency when visible content provides another answer path. The classifier must use positive, testable canonical shapes; ambiguous free-form configurations remain available in other Round types.
3. **Test threshold:** It changes the result label only. A failed threshold still follows normal completion, XP, unlock, and Laurel rules. No threshold means no pass/fail label; an empty Test remains invalid under the existing empty-Round rule.
4. **Learner title:** Numbering Off shows the type and a nonempty author-written title, for example `Practice · Greetings`. The other modes prepend their number, for example `Round 1 · Practice · Greetings`. Apply the same identity in Review and previews.

**Playback default:** Discover, Listen, and Read use Practice's immediate feedback and mistake review; their distinction is instructional purpose and compatibility. FlashCard uses card-by-card Presentation progression, with no correctness feedback or mistake review because its cards are non-evaluatable. The owner had no preference on this point, so this implementation leaves unrelated progression behavior intact.

**Wizard design point:** When an author changes a proposed Round type, retain the visible GuideBook source and regenerate that Round's candidate exercises for the chosen type before generating Drafts. If the GuideBook cannot produce compatible candidates, explain why and disable Generate for that plan item. Never silently substitute a different type or delete authored GuideBook material.

**Path progress wording:** A completed non-perfect Round says “Completed” below its type/title; a perfect Round still says “Perfect.” The owner confirmed this on 3 October 2026 to avoid repeating “Practice” as both type and completion action.

## Global constraints

- Keep the current repository as baseline. Read `pubspec.yaml` when implementation starts; this plan makes no version or build-number assumption.
- Preserve v12 exercise authority: primitive, options, and content determine runtime behavior; preset IDs remain optional authoring metadata.
- Existing Course imports, progress identity, Round IDs, scoring, and learner records must remain intact unless an owner decision above explicitly changes a rule.
- Drafts may contain incompatible Round content; publishing must use blocking Audit findings for the type rules specified in the proposal.
- Speak is visible last in New Round, disabled and marked Coming soon; no new Speak Round can be authored.
- Editor Help and Exercise Primitives Help have complete English, Italian, and Spanish catalogs. Learner-panel wording must follow the existing language catalogs where needed.
- Run long Windows Flutter test/build commands with the temporary PowerShell execution-state guard specified in `AGENTS.md`, and use the repository path spelling `C:\QQL\QuisquisLingo` consistently.

## Review focus

1. A legacy v12 Round without `roundType` must load and write without changing its ID or playback order; cover in Task 1.
2. A preset whose default sample is compatible but whose edited canonical content is not must be rejected on publication; cover in Task 4.
3. Optional audio, a visible transcript, or answer text that leaks the answer must not falsely qualify a Listen/Read exercise under the structural-only rule; cover in Task 4.
4. Exiting or previewing a Test before the last answer must not record completion or reveal deferred feedback; cover in Task 6.
5. Reordering or copying Rounds must not store display numbers as identity, and the type must survive copy/move; cover in Tasks 1 and 2.

---

### Task 1: Persist the Round type and migrate existing v12 Rounds

**Files:** `lib/models/course_models.dart`; `lib/services/authoring_duplication_service.dart`; `lib/services/course_authoring_transfer_service.dart`; Round reconstruction sites in `lib/screens/course_editor_screen.dart`, `lib/screens/primitive_editor_screen.dart`, and `lib/services/guidebook_round_generator.dart`; create `test/round_type_model_test.dart`; extend `test/authoring_duplication_service_test.dart`.

**Interface:** Define a closed `RoundType` with serialized values `discover`, `practice`, `sequence`, `listening`, `reading`, `story`, `flashcard`, `test`, `speak`. Add `LearningRound.roundType`, serialize it, and make `isStory`/`isSequence` follow it. Keep `visualType` readable during migration, but never use it for new semantic decisions. Initially, the missing-field migration classifies structural Story/Sequence flow, then assigns Practice to other Rounds. Task 4 adds the structural check that upgrades qualifying old Listen Rounds to Listen in that same migration path. An old Test icon always becomes Practice. Reject unknown explicit type values. Parse a Story/Sequence with missing or conflicting flow safely; Task 4 blocks publication through Audit, and no flow consumer may assume `flow!` solely from the type.

- [ ] Write model tests for every serialized value, missing-field migration, unknown values, Story/Sequence flow, and copy/move preserving type and IDs where appropriate.
- [ ] Run the focused model tests and confirm the new cases fail.
- [ ] Add the field and migration, then pass type through every Round reconstruction path.
- [ ] Run `flutter test test/round_type_model_test.dart test/authoring_duplication_service_test.dart` and `python tools/validate_courses.py`; confirm old bundled v12 Courses still load.

### Task 2: Add Round presentation and numbering

**Files:** `lib/models/course_models.dart`; create `lib/services/round_type_presentation.dart`; `lib/screens/home_screen.dart`; `lib/screens/course_editor_screen.dart`; `lib/services/lesson_presentation_service.dart` only if its Course-option pattern is reused; create `test/round_type_presentation_test.dart`; extend `test/learner_round_path_test.dart`.

**Interface:** Centralize the nine exact labels from the proposal and one distinct icon per type. Add Course-level `roundNumberingMode` (`off`, `roundAndNumber`, `numberOnly`, `customAndNumber`) and a custom prefix only for the last mode. Default missing values to Off for existing Courses. Derive numbers from the Round's current one-based index within its Lesson; never store them on `LearningRound`. Render type plus nonempty author title, with the number prefix selected in Lesson Options. Keep an always-visible order number on the editor's Rounds page.

- [ ] Write tests for default Off, all four formats, empty or invalid custom prefix, add/delete/reorder, copy/move, type icons, and editor numbering.
- [ ] Run the focused tests and confirm failure.
- [ ] Implement the model option, Lesson Options controls, shared formatter, learner path, and editor numbering.
- [ ] Run `flutter test test/round_type_presentation_test.dart test/learner_round_path_test.dart` and inspect a narrow learner path and Rounds page for title wrapping and icon/state overlays.

### Task 3: Put creation behind New Round and type-aware editing

**Files:** `lib/screens/course_editor_screen.dart`; optional small selector widget under `lib/widgets/`; create `test/round_type_authoring_test.dart`.

**Interface:** New Round opens a selector showing every type's label, icon, purpose, and consequences; Speak is disabled. Selecting Story opens the existing single-Story wizard and preserves its Course-character updates. Practice, Discover, and Sequence may retain the current provisional sample, with a flow added for Sequence; Listen, Read, FlashCard, and Test start as empty provisional Drafts so a wrong sample does not appear as compatible content. Round Wizard remains beside New Round. Remove the separate New Story action and the Play as a sequence switch; show Sequence and Story options only for those types. The proposal requires changing a *Wizard proposal's* type, not adding type conversion to already saved Rounds.

- [ ] Write widget tests for cancel-without-creation, each enabled selection, disabled Speak, Story wizard handoff, and removal of duplicated controls.
- [ ] Run them and confirm failure.
- [ ] Implement selector and editor routing with the existing working-copy/session pattern.
- [ ] Run `flutter test test/round_type_authoring_test.dart`, including read-only mode and unsaved Course changes.

### Task 4: Centralize compatibility and Audit

**Files:** `lib/models/exercise_authoring.dart`; `lib/models/exercise_features.dart`; create `lib/services/round_type_compatibility.dart`; `lib/services/course_audit_service.dart`; `lib/services/audit_code_registry.dart`; `lib/screens/primitive_editor_screen.dart`; preset-picker path in `lib/screens/course_editor_screen.dart`; create `test/round_type_compatibility_test.dart`; extend `test/course_audit_test.dart`.

**Interface:** One service answers both `canOfferPreset(roundType, preset)` for the picker and `issuesForExercise(roundType, canonicalExercise)` for an actual exercise. A preset is offered if its recipe can produce at least one valid configuration; the final canonical instance is always checked separately. Implement Listen and Read using positive structural shapes derived from canonical roles, media requirement, visible text, and evaluation; reject ambiguous content from those types. Listen and Read apply their dependency rule to required exercises. Use the same predicate for legacy Listen migration in Task 1. FlashCard excludes unrelated content and Test excludes non-evaluatable content, including optional cards. An explicitly imported Speak Round is readable as data but unplayable and blocked from publication. Show immediate compatibility guidance in the Canonical Editor, allow Draft saves, and register blocking Audit codes for incompatible Published content. Validate Story/Sequence flow consistency and reachability through the existing `ContentFlow` checks.

- [ ] Write table tests covering compatible/incompatible canonical examples, optional audio and text, optional versus required content, preset filters, Canonical Editor warnings, and publish blocking.
- [ ] Run them and confirm failure.
- [ ] Implement the centralized classifier and connect picker, editor, Audit, and code registry to it.
- [ ] Run `flutter test test/round_type_compatibility_test.dart test/course_audit_test.dart`; verify canonical data rather than preset IDs drives the result.

### Task 5: Route ordinary and ordered playback by Round type

**Files:** `lib/screens/round_screen.dart`; `lib/services/round_playability_service.dart`; `lib/services/duel_eligibility_service.dart` if Story inclusion logic changes; learner-panel catalogs; create `test/round_type_playback_test.dart`; extend `test/sequence_round_256_test.dart`.

**Interface:** Practice keeps its existing randomized order, immediate feedback, and mistake review. Sequence and Story keep authored `ContentFlow` order, their existing presentation options, and current Duel distinction. Implement the recommended playback default above for Discover, Listen, Read, and FlashCard after plan review. FlashCard remains card by card and excludes unrelated content through Task 4. Use `roundType` for nouns in the learner panel and for Story-only behavior. Do not change completion/XP rules merely to rename a type.

- [ ] Write regression tests for Practice shuffle, Sequence and Story order, Story scrolling, Duel eligibility, review, and chosen behavior for the four new types.
- [ ] Run them and confirm the new type cases fail.
- [ ] Replace semantic `visualType`/flow checks with type-aware dispatch while preserving flow storage.
- [ ] Run `flutter test test/round_type_playback_test.dart test/sequence_round_256_test.dart test/round_xp_completion_regression_test.dart`.

### Task 6: Implement Test as an attempt with deferred results

**Files:** `lib/screens/round_screen.dart` or a focused Test attempt component; `lib/models/course_models.dart` for optional Test settings; create `test/test_round_attempt_test.dart`; extend `test/round_xp_completion_regression_test.dart`.

**Interface:** A Test contains evaluatable exercises only (Task 4). During an attempt, collect answers without displaying correctness, correction, or ordinary mistake review. Show all results after the final answer. Support optional order mode and passing threshold. A failed threshold changes the result label but still completes and awards XP under existing rules; repeats follow existing progress rules. Ensure preview and early exit write no learner result.

- [ ] Write tests for no feedback before completion, complete results, fixed/random order, threshold boundaries, early exit, preview, repeat, XP, and unlocks.
- [ ] Run them and confirm failure.
- [ ] Implement the Test attempt/results path and its Round settings.
- [ ] Run `flutter test test/test_round_attempt_test.dart test/round_xp_completion_regression_test.dart`, then a real widget attempt.

### Task 7: Make the multi-Round Wizard type-aware

**Files:** `lib/services/guidebook_round_generator.dart`; `GuidebookRoundGeneratorScreen` in `lib/screens/course_editor_screen.dart`; create `test/round_type_wizard_test.dart`; extend `test/guidebook_round_generator_224_test.dart`.

**Interface:** Add a type to each `GuidebookRoundPlan`, show it with order and title, allow changing it before generation, and use Task 4 compatibility to prevent incompatible generated Rounds. Replan candidate exercises from the same GuideBook material when a type changes; explain and block an unsupported combination. Generate Story/Sequence flow and Test settings where those types are supported; do not create a published invalid Round. Keep the GuideBook prerequisite and multi-Round role.

- [ ] Write generator/UI tests for multiple types, edits before generation, incompatible plans, Story/Sequence flow, Test settings, and unchanged default GuideBook generation.
- [ ] Run them and confirm failure.
- [ ] Implement plan editing and generation through the shared type contract.
- [ ] Run `flutter test test/round_type_wizard_test.dart test/guidebook_round_generator_224_test.dart` and preview generated Draft Rounds.

### Task 8: Put Round Types in Editor Help and remove Stories from Primitives Help

**Files:** `lib/localization/help/help_structure.dart`; `help_en.dart`, `help_it.dart`, `help_es.dart`; `lib/screens/editor_help_content.dart` only if topic assembly needs changing; `test/editor_help_qa_256_test.dart`; `test/localization_catalog_test.dart`; `test/revision3_followup_256_test.dart`.

**Interface:** Add `roundTypes` to `editorHelpQuestionsByTopic` after `lessonsAndRounds`. Give it searchable questions for the Round-type contract, Discover, Practice, Sequence, Listen, Read, Story, FlashCard, Test, disabled Speak, compatibility/publication, and numbering. Move the existing `sequence`, `story`, `newStory`, and `editStory` questions there and update their copy to the final UI. Keep procedural New Round and Round Wizard questions in `lessonsAndRounds` and update their instructions. Remove `stories` from `exercisePrimitivesHelpSectionIds` and remove `technical.exercisePrimitives.stories.title/body` from all three catalogs. Keep primitive Presentation and Flashcard exercise explanations there because those describe exercises, not Round behavior. Update any Course Model/JSON Help and cross-references that still claim `visualType` controls Story or mention New Story / Play as a sequence.

- [ ] Update Help tests first: new topic and question order, EN/IT/ES key parity, search, no Primitives `stories` section/key, and no stale UI instructions.
- [ ] Run focused Help tests and confirm failure.
- [ ] Write the three-language copy and make the structure change.
- [ ] Run `flutter test test/editor_help_qa_256_test.dart test/localization_catalog_test.dart test/revision3_followup_256_test.dart` and inspect the Editor Help topic plus the Primitives page in all three languages.

### Task 9: Update bundled Courses, validators, and release evidence

**Files:** `tools/validate_courses.py`; current bundled-Course generators under `tools/`; `assets/courses/*.json`; relevant fixtures and checksum tests; release validation/handoff docs for the implementation's actual build.

**Interface:** Write explicit `roundType` and Course Round-numbering defaults in newly generated v12 data. Keep Course IDs, Round IDs, exercise canonical content, and ordering unchanged unless a reviewed type conversion requires a change. Update generator `--check` outputs and validator rules together. Run model and audit checks over all bundled Courses; investigate every newly blocking finding before publishing.

- [ ] Add fixture/generator assertions for type persistence and stable IDs, then run them to see the needed changes.
- [ ] Update the generators, data, and validator in one reviewable change.
- [ ] Run generator checks, `tools/validate_courses.py`, focused Flutter model/authoring/Help/runtime tests, then the required full Flutter test suite with the Windows execution-state guard.
- [ ] Record the actual build version, validation evidence, and any approved migration decisions in the release documentation.

## Completion check

Cross-check each of the proposal's 24 sections against Tasks 1–9. Confirm the four authoring entry points (manual Round, Story wizard, Round Wizard, imported v12 data) produce the same type contract; the learner path, Round screen, Review, preview, Duel, and Audit read that contract; and Help explains the behavior actually shipped. Review the playback and Wizard recommendations with the owner before those tasks are implemented.

## Owner extension: Timed Rounds (3 October 2026)

After the original plan, the owner added Timed as a playable Round type. New Round offers it with `Icons.timer_outlined`. The editor accepts an ordered list of distinct limits from 30 to 600 seconds and offers 30, 60, 90, 120, 180 and 300 second presets plus Custom. Lesson Options holds optional Course-level defaults; a new Timed Round copies them, and later default edits do not change existing Rounds. Timed authoring filters presets to automatically evaluatable, non-audio-dependent exercises, keeps Canonical Editor available, and warns or blocks incompatible canonical content. Audit blocks absent or invalid limits, no playable required activity, incompatible content and indeterminate play.

Countdown begins when the first playable activity starts, after any Before you start card. Timeout locks input, credits the attempt's first-pass correct-answer XP, leaves the Round incomplete and permits retry. Completing before zero follows normal Round scoring and progression. A timely completion unlocks the next authored limit; the central `XpCalculator` grants an additional 10 XP on the first timely completion of each limit for a learner, Course and Round. The completion breakdown shows that bonus separately. Tests cover authoring, timeout, retry, persistence, unlocks and the one-time bonus. Run the full suite after Timed implementation, then commit Revision 7.
