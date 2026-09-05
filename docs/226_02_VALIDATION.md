# QQL 226.02 pre-commit validation report

Status: **PASS — 226.02 implementation, final review corrections and required automated validation are complete and approved for a local commit.** Native/manual checks and inherited analyzer findings remain disclosed below.

## Contract and immutable baseline

Only **226.02: Editor workflow, navigation, field help and Audit UX** is implemented, under the complete controlling `qql_226_prompt.txt` and the user's explicit 226.02 instructions. The clean baseline was checked before editing:

```text
git status --short       (no output)
git rev-parse HEAD       45cf258d707c89d512f7663d9f2fa317adbe5ef0
git rev-parse origin/main 45cf258d707c89d512f7663d9f2fa317adbe5ef0
git diff --check         (no output; exit 0)
```

No baseline reset, stash, amend or reconstruction occurred. The current HEAD and origin/main remain that parent; the index contains no staged content. No push, package, Windows release build or release was created. **226.03 remains unstarted.**

Candidate metadata is **Version 2.0.26 / Build 226.02 / `2.0.26+22602`**. Alpha expiry remains **2026-10-05 at 23:59:59 local time**, following the existing thirty-day policy from the same September 5 candidate date. The Alpha implementation's date is unchanged; its comment and test label identify the current tranche.

## Final independent-review corrections

All four low-severity findings from the independent read-only review were corrected before commit:

- **Lesson breadcrumb after Rename:** the Lesson editor replaces the corresponding Course snapshot Lesson by stable `lessonId` before building breadcrumbs. The renamed title now appears immediately. The regression uses duplicate Lesson titles and verifies the intended Lesson by ID, without weakening the dirty-state guard.
- **Singular Draft wording:** one shared label helper now renders `1 Draft Exercise` and pluralizes every other count. All five newly introduced Course/Lesson/Round count presentations use it; their calculations, live refresh, colors and placement are unchanged.
- **MP3 importer documentation:** Help and Course Editor documentation now state that physical MP3 files are grouped by `learningLanguage`; metadata and references belong to the Course; verified backups copy referenced recordings; and Course JSON stores metadata/local paths rather than MP3 bytes. Import and storage code are unchanged.
- **Audit pair trigger descriptions:** `AUDIO_MATCH_PAIR_EMPTY` and `MATCH_PAIR_EMPTY` now document exactly what their predicates see: a blank value in a surviving two-entry pair. Their predicates, model getters, codes and severities are unchanged, and Help consumes the corrected registry text.

## Implementation by requirement

| Requirement | Result and boundary |
|---|---|
| Unsaved Exercise Preview | One `_buildCandidate` path supplies Save, Draft and Preview for every preset. Preview reads current controllers, contextual mode, correct-translation entries and image selection without calling Save. It retains the original publication state/timestamp, audits runtime validity and pushes detached Course/Lesson/Round objects to `RoundScreen(previewMode: true)`. New, Draft, Published, Wizard and generated normal-editor entry points provide the same runtime context. |
| Previous / Next | IDs locate the active Exercise in the current Round's ordered snapshot. End buttons are disabled; new unsaved or not-yet-in-Round candidates have no misleading destination. Save updates sibling values in the same parent working copy. Back and navigation share Keep editing / Discard changes / Save as draft / Save protection. Cursor selection changes alone are not edits. |
| Breadcrumbs | `EditorBreadcrumbs` derives labels and ordinals from current Course data and stable IDs. A renamed Lesson is merged into the supplied Course snapshot by `lessonId`, so its label refreshes immediately and duplicate titles remain safe. Wrap handles narrow layouts. A parent link is enabled only when that route actually returns to the labelled parent; other levels remain readable context. Exercise links use the unsaved guard. |
| Move / Copy | Explicit destinations select Course > Lesson > Round for Exercises and Course > Lesson for Rounds, within the current custom course. Move preserves identity, content, metadata and state. Copy delegates to the existing duplication/remapping implementation and creates fresh Draft subtrees. No destination is applied until confirmation in the chooser. |
| Field Help | A central 38-meaning registry covers all 20 current presets. Every applicable field, including contextual mode, dynamic correct-translation rows and image controls, has a tooltip and direct Help action. Shared text explains purpose, entry shape, syntax, limits and examples. Broad Help and the existing Type the translation syntax page remain. |
| Validation clarity | Known Audit messages identify the field and action without changing their existing conditions or severities. Correct-answer indices and duplicate literal translations have actionable messages. A malformed matching-pair line is identified and retained in the form, rather than silently omitted from Preview/Save. |
| Importer instructions | Documentation was checked against LessonIconService, FlagService, ExerciseImageService, ImageBankService, RecordedAudioService, CourseEditorService and course backups. It distinguishes portable embedded flags/Lesson icons from local exercise image/audio paths and explains actual formats, limits, transformation and errors. Physical MP3 storage is correctly described as grouped by learning language, while Course metadata/references and verified backup copying remain Course-specific. No import behavior changed. |
| Untitled Rounds | Create and Rename accept an empty title, show “Press Enter to keep this Round untitled.”, and submit that empty value on Enter. Round N remains a display fallback; no fake stored title is introduced. |
| Draft indicators | Orange is derived from current Draft Exercise content, independently of the existing pink Audit Error Card border. Concentric borders, a tooltip and legend distinguish both conditions. |
| Draft counts | Course total and Lesson counts are calculated from the same working-copy content; they are not persisted or independently cached. A shared formatter renders `1 Draft Exercise` and pluralizes zero and all other values across all five presentations. Add, delete, Save/Draft, publish, duplicate, Move and Copy flow through the existing state updates. |
| Audit Codes | Searchable Course Help technical reference uses the same immutable 103-rule registry as CourseAuditService. Each definition includes code, severity, scope, meaning, trigger, creator action and blocking status. Known findings cannot routinely use GENERAL. |
| Missing Reading guidance | The entire `readingCount == 0` finding block is deleted. There is no downgraded Info equivalent. Actual malformed Reading and Listening findings remain, and missing Listening guidance remains absent. |

The all-preset Preview contract exposed two narrowly related existing problems: Listening Spelling's saved accepted answers were loaded into the wrong field, and the shared Preview runtime applied learner TTS skipping / read learner completion. Hydration now uses accepted answers for that preset on initial entry and sibling navigation. Preview bypasses learner skipping and completion reads; normal learner paths retain their existing behavior.

## Architecture, persistence and clean-cut implications

`CourseAuthoringTransferService` is a synchronous, testable authoring transformation returning a replacement Course. It rejects official courses, missing or ambiguous source/destination IDs, same-source moves and copy ID collisions. It imports no storage, preferences, learner-progress or UI service. `AuthoringDuplicationService.duplicateContent` reuses the existing allocation/remapping implementation and retains v6 wrapper metadata. Nested normalization data are detached so editing a copy cannot mutate its source.

The existing nested editor route stack carries an updated Course callback solely to propagate destination changes across Lesson boundaries. Top-level `CourseEditorTransaction` remains the only persistence/confirmation boundary. Cancelling the course discards all pending transfers; successful confirmation retains the existing single version increment and verified backup semantics. Imported Lesson icon assets and other destination changes survive every parent return. Unchanged text, lesson-intro and Presentation content retain original order, metadata and media; source Round timestamps survive transfer return.

The obsolete pending Exercise clipboard UI and its now-unreferenced `exercise_transfer_service.dart` are removed. No cross-course clipboard or learner movement state replaces them. Shared immutable artwork/audio references remain references.

**No Course Model change:** formatVersion remains 6; no new JSON fields, persistence keys, migrations, storage namespaces, backup formats or dependencies are introduced. Learner backup remains v2. No XP, streak, Weekly XP, Laurel, Review, completion, Duel, progression or learner-identity write is added. Course-level Cancel does not erase existing learner state.

The 226.01 official read-only/licensed-fork clean cut is unchanged. No official override loader, migration, conversion or local editing route is reintroduced. Transfer service guards also reject official sources. Original fork authorship/provenance, explicit derivative policy and official-update independence retain their existing implementation and regression coverage. The two accepted 226.01 low-severity observations remain untouched: duplicate current official release presentation in Version History and the unreachable obsolete official conditional in `Course.fork()`.

No 226.03 answer-expansion UI/feedback, new presets, optional Duels, Section management, Lesson style change, scaffolding, World Flag selector, templates, Course Issues or Neapolitan sample is included.

## Focused coverage and automated evidence

| Tests | High-risk coverage |
|---|---|
| `exercise_workflow_226_02_test.dart` | New unsaved Preview; Draft/Published and every canonical model; contextual/Build translation/listening; unsaved values and publication; exact Course JSON and all preferences unchanged; no authoring clock/save callback; completion with zero learner writes; no-active-profile audio Preview despite TTS skipping; navigation order/boundaries/save/discard; breadcrumb guard; immediate renamed-Lesson refresh with duplicate-title stable-ID resolution; malformed pair diagnostics; empty Round Enter. |
| `course_authoring_transfer_226_02_test.dart` | Move/copy for canonical models and Presentation/text; IDs, references, metadata, nested copy independence, custom-only guard, collisions, source immutability; real transaction Cancel and one final Confirm with version/backup. |
| `authoring_transfer_ui_226_02_test.dart` | Actual destination menus within/across Lessons; cancelled chooser; destination reset; multiple transfers through nested return stack; text/intro/Presentation metadata/order; returned timestamp; Round Move/Copy; live singular/plural counts and simultaneous orange/pink. |
| `exercise_field_help_226_02_test.dart` | All semantic definitions, shared canonical meanings, accepted-answer parser examples and distinctions from literal Arrange/missing-word lists; importer documentation contract for language-grouped MP3 files, Course-owned references, verified backup copying and non-embedded bytes. |
| `exercise_field_help_ui_226_02_test.dart` | All 20 actual preset forms and every mounted field; context conditional fields; dynamic translation rows; syntax Help; Light/Dark at 320/375/430/1100 px. |
| `audit_code_registry_226_02_test.dart` | Complete known rule inventory, specific identities/severities, no routine GENERAL, exact matching-pair trigger descriptions, search, missing Reading/Listening absence and malformed existing comprehension validation. |
| `audit_codes_screen_226_02_test.dart` | Every definition rendered from the registry, search by code/text and Light/Dark reference layouts at 320/375/430/1280 px. |
| Existing regressions | Custom course transactions, confirm/cancel/backups, Course Model v6, duplication, official storage/forks/UI, Wizard/generator/editor, Lesson icons, responsive learner rendering, XP/progress, metadata and Alpha policy. |

The new seven test files contain **141 cases**. Existing test changes follow deliberate UI contracts: the guarded Exercise Back decision, singular/plural Draft counts, independent nested borders, lazy list scrolling, shared syntax Help and current tranche metadata. They do not weaken validation or alter working production behavior to satisfy tests.

Final correction-focused results: **67 cases passed (exit 0, 41s)** across the workflow, transfer UI, Audit registry and field Help/documentation suites. The complete 226.02 focused set then passed **144 cases (exit 0, 2m00s)**, and the complete Flutter suite passed **753 cases (exit 0, 6m56s)**. The complete focused run includes every new 226.02 test plus the existing Wizard suite. Formatting reports all 31 touched Dart files clean (exit 0); dependency resolution exits 0. **No test failure remains.**

Final focused command:

```text
flutter test --no-pub --concurrency=1 --reporter expanded --timeout 60s test/audit_code_registry_226_02_test.dart test/audit_codes_screen_226_02_test.dart test/authoring_transfer_ui_226_02_test.dart test/course_authoring_transfer_226_02_test.dart test/exercise_field_help_226_02_test.dart test/exercise_field_help_ui_226_02_test.dart test/exercise_workflow_226_02_test.dart test/exercise_creation_wizard_test.dart
```

Required command forms:

```text
dart --suppress-analytics format <all 31 touched existing/new Dart files>
flutter pub get
flutter analyze --no-pub
flutter test --no-pub --concurrency=1 --reporter compact --timeout 60s
python tools/validate_courses.py
python tools/validate_lesson_icons.py
python tools/validate_images.py
git diff --check
git status --short
```

Executables: `C:\Users\ansa\flutter\bin\flutter.bat`, `C:\Users\ansa\flutter\bin\cache\dart-sdk\bin\dart.exe`, and the environment's Python 3.14. Direct Dart formatting uses `--suppress-analytics` so validation does not require a telemetry timestamp write outside the workspace.

## Analyzer comparison against the actual clean parent

The untouched repository's initial analyzer produced 73 findings (exit 1). For an independent same-environment comparison, every tracked blob of parent `45cf258d707c89d512f7663d9f2fa317adbe5ef0` was copied to a separate temporary directory and verified against its Git blob SHA-1. Only ignored package configuration was supplied, matching current resolved dependencies. Running `flutter analyze --no-pub` there again produced **73 findings, exit 1**. No parent commit or original workspace file was changed by this comparison.

Current analyzer: **72 findings, exit 1**. It is **not passing**.

| Category/file | Parent | Current |
|---|---:|---:|
| `lib/services/course_audit_service.dart` / curly braces Info | 68 | 67 |
| `lib/screens/flat_image_library_screen.dart` / curly braces Info | 3 | 3 |
| `lib/services/settings_service.dart` / curly braces Info | 1 | 1 |
| `test/guidebook_sentence_generator_test.dart` / unused `_tapAndSettle` Warning | 1 | 1 |
| Total | **73** | **72** |

**New: 0. Resolved: 1.** The resolved Info is the unbraced missing-Reading finding at parent `course_audit_service.dart:571`, removed with the obsolete rule. Findings were compared by severity/message/file/code with line shifts accounted for, not by remembering a prior count. Of the current findings, 67 are in a changed file (the Audit service); all 67 are inherited findings. No analyzer exclusions or lint suppressions are delivered.

`flutter pub get` completed successfully. The installed SDK automatically changed `matcher`, `meta`, `test_api` and `vector_math` lock entries and added analyzer exclusions. Those verified automatic tracked changes were removed as out of scope; `pubspec.lock` and `analysis_options.yaml` match the parent. The ignored resolution used for both the fresh parent analysis and final validation contains matcher 0.12.20, meta 1.19.0, test_api 0.7.12 and vector_math 2.4.2. This environment/reproducibility detail is disclosed; no dependency upgrade is proposed by this tranche.

## Validators and Audit evidence

- Course validator: **9 bundled Course Model v6 files, all OK, exit 0**.
- Lesson icon validator: **14 assets, 0 issues, exit 0**.
- Image validator: **112 assets, 0 issues, exit 0**. No asset or manifest changed; `hello.webp` remains absent.
- Real bundled Course Audit: **9 courses, aggregate 0 Errors / 0 Warnings / 0 Info** through the existing production bundled-course regression.
- Registry: **103 rules: 70 Error / 27 Warning / 6 Info**; baseline comparison confirms unchanged severities and conditions except deletion of missing Reading coverage. Each known emission references its registry definition; Help renders those same definitions. GENERAL remains only a defensive constructor default/copy fallback.
- No production `Round has no Reading comprehension exercise`, `readingCount` absence branch or replacement missing-Reading finding remains. Tests explicitly cover absence and malformed actual Reading/Listening.
- `git diff --check`: **exit 0; no whitespace errors**.

Ignored `build/22602/` retains the earlier implementation-run logs: initial and repeated parent analyzer logs, analyzer/JSON comparison, focused logs, the earlier 750-case full-suite log, formatting, dependency resolution, validators and repository-state capture. The post-review correction runs and exact 67/144/753-case results are recorded directly in this closure report and task output; the earlier full-suite log is not presented as the final correction run. Intermediate failures remain transparent: expected initial missing-Preview characterization, integration/test-scrolling fixes, and the first full run (**741 passed / 9 failed**) with stale structure/count/title/scroll assumptions. Only the latest successful results above establish completion.

## Complete changed-file list and file-by-file summary

**38 files: 23 modified tracked files, 1 deleted tracked file and 14 new files.**

| Status | File | Change |
|---|---|---|
| M | `AGENTS.md` | Records the 226.02 boundary and immutable parent; later tranches remain deferred. |
| M | `CHANGELOG.md` | 226.02 candidate entry, workflow/Audit changes, metadata and unchanged thirty-day expiry date. |
| M | `README.md` | Current Build 226.02 metadata and concise workflow scope; preserves the official-fork explanation. |
| ?? | `docs/226_02_VALIDATION.md` | This complete pre-commit report, command evidence, scope review and remaining manual risks. |
| M | `docs/COURSE_EDITOR.md` | Unsaved Preview/navigation, transactional transfers, Draft indicators/counts, Audit reference and verified artwork/import instructions. |
| ?? | `lib/screens/audit_codes_screen.dart` | Searchable responsive reference rendering every registry definition. |
| M | `lib/screens/course_editor_screen.dart` | Shared unsaved candidate/Preview, guarded sibling navigation and breadcrumbs; atomic destination integration; full content/timestamp propagation; contextual field Help, clear validation, untitled Round guidance and live Draft visuals/counts. |
| M | `lib/screens/editor_help_screen.dart` | Actual importer/portability guidance, current workflow and Draft-copy policy, existing broad syntax Help plus Audit Codes navigation. |
| M | `lib/screens/round_screen.dart` | Preview-only bypass of learner TTS skipping and completion reads; normal learner initialization/completion remains unchanged. |
| M | `lib/services/alpha_lifecycle_service.dart` | Updates only the candidate-build comment; actual expiry DateTime is unchanged. |
| M | `lib/services/app_metadata.dart` | Build label 226.02 and technical build 22602; release version remains 2.0.26. |
| ?? | `lib/services/audit_code_registry.dart` | Authoritative immutable 103-rule code/severity/scope/trigger/action/blocking registry and shared search. |
| M | `lib/services/authoring_duplication_service.dart` | Adds canonical Content-wrapper duplication using existing remapping; detaches nested normalization metadata. |
| M | `lib/services/course_audit_service.dart` | Definition-backed known rule identities and unchanged severities; removes Reading absence; eleven existing messages are actionable. |
| ?? | `lib/services/course_authoring_transfer_service.dart` | Pure custom-course Move/Copy transformations with stable/fresh IDs, canonical metadata, lookup/collision guards and no persistence. |
| ?? | `lib/services/exercise_field_help.dart` | Shared 38 field meanings and exact syntax/entry/validation examples for all current presets. |
| D | `lib/services/exercise_transfer_service.dart` | Deleted the unreferenced pending transfer clipboard implementation after replacing its editor paths. |
| ?? | `lib/widgets/authoring_destination_dialog.dart` | Explicit current-course destination selection; Cancel returns no mutation, and changing Lesson clears the Round selection. |
| ?? | `lib/widgets/editor_breadcrumbs.dart` | One ID-derived responsive hierarchy presentation with optional safe immediate-parent link. |
| M | `pubspec.yaml` | Technical version advances to 2.0.26+22602; no dependency constraints change. |
| M | `test/alpha_lifecycle_test.dart` | Updates the tranche label while preserving actual expiry boundary tests. |
| M | `test/app_metadata_225_04_test.dart` | Checks release/build/technical labels for 226.02. |
| ?? | `test/audit_code_registry_226_02_test.dart` | 9 new registry, exact pair-trigger, known emission, search and comprehension presence/malformed-content regressions. |
| ?? | `test/audit_codes_screen_226_02_test.dart` | 10 new full reference, search and responsive Light/Dark regressions. |
| M | `test/authoring_audit_ui_224_test.dart` | Retains the pink Error-only assertion while locating its Card inside the new independent Draft indicator. |
| ?? | `test/authoring_transfer_ui_226_02_test.dart` | 20 new real destination, cancellation, nested propagation, v6 preservation and Draft visual/count regressions. |
| M | `test/course_audit_report_225_test.dart` | Checks current build labels in Audit reports. |
| ?? | `test/course_authoring_transfer_226_02_test.dart` | 33 new pure transfer, all-model IDs/metadata, deep copy, guards and real transaction/version/backup regressions. |
| M | `test/course_editor_224_test.dart` | Checks the compact Course Lessons row including its current Draft Exercise count. |
| M | `test/course_editor_225_test.dart` | Checks the clearer duplicate-translation error without weakening duplicate validation. |
| M | `test/exercise_creation_wizard_test.dart` | Preserves Wizard Save/Preview/Finish checks using labelled fields and settled lazy-list scrolling. |
| ?? | `test/exercise_field_help_226_02_test.dart` | 12 new central semantics, accepted-answer syntax and MP3 documentation-contract regressions. |
| ?? | `test/exercise_field_help_ui_226_02_test.dart` | 31 new all-preset field-control and responsive Help regressions. |
| ?? | `test/exercise_workflow_226_02_test.dart` | 26 new unsaved Preview/no-write, navigation/guards, renamed-Lesson/stable-ID breadcrumb, empty Round and validation regressions. |
| M | `test/leaderboard_navigation_test.dart` | Updates the already-seen Welcome notice fixture for the new technical version. |
| M | `test/learner_round_path_test.dart` | Updates the already-seen Welcome notice fixture for the new technical version. |
| M | `test/lesson_metadata_and_icon_test.dart` | Uses the actual icon-field destination instead of a fixed scroll offset after breadcrumb/count insertion. |
| M | `test/production_course_transaction_225_04_test.dart` | Requires an explicit discard decision on Exercise Back while retaining the full transaction/save/backup assertions. |

## Exact diff stat

The following is literal `git diff --stat` output. Git excludes untracked additions from this command; every new file is included in the complete table and status below, and is part of the reviewed tranche.

```text
 AGENTS.md                                          |    1 +
 CHANGELOG.md                                       |    9 +
 README.md                                          |    6 +-
 docs/COURSE_EDITOR.md                              |   37 +-
 lib/screens/course_editor_screen.dart              | 1013 ++++++++++++++++----
 lib/screens/editor_help_screen.dart                |   43 +-
 lib/screens/round_screen.dart                      |   13 +-
 lib/services/alpha_lifecycle_service.dart          |    2 +-
 lib/services/app_metadata.dart                     |    4 +-
 lib/services/authoring_duplication_service.dart    |   11 +-
 lib/services/course_audit_service.dart             |  425 ++++-----
 lib/services/exercise_transfer_service.dart        |   42 -
 pubspec.yaml                                       |    2 +-
 test/alpha_lifecycle_test.dart                     |    2 +-
 test/app_metadata_225_04_test.dart                 |    8 +-
 test/authoring_audit_ui_224_test.dart              |   14 +-
 test/course_audit_report_225_test.dart             |    4 +-
 test/course_editor_224_test.dart                   |    2 +-
 test/course_editor_225_test.dart                   |    2 +-
 test/exercise_creation_wizard_test.dart            |   36 +-
 test/leaderboard_navigation_test.dart              |    2 +-
 test/learner_round_path_test.dart                  |    2 +-
 test/lesson_metadata_and_icon_test.dart            |    7 +-
 .../production_course_transaction_225_04_test.dart |    6 +-
 24 files changed, 1176 insertions(+), 517 deletions(-)
```

## Manual checks, review and risks

The complete production/documentation/test diff was inspected for requirement scope, obsolete branches, comments, metadata and generated/debug artifacts. Transfer order, wrapper/media preservation, nested destination propagation, Preview and unsaved guards received independent read-only reviews. The four reported low-severity findings were corrected and covered as listed above. New registries and helpers remain bounded to the authoring workflow. No generated files, temporary logs, baseline copies, debug code, broad reformatting, analyzer-policy edits or unrelated assets are included. The two automatically changed tracked Flutter files were content-verified and restored; no content was staged.

**Native manual checks actually performed: none.** Automated widget/layout interactions are not described as manual device testing. Still recommended before release: Windows keyboard/Back and 320 px/light/dark review with long real course titles; actual TTS/recorded-audio/image Preview and return; real importer error/portability paths; and a device course-confirm/cancel/restart/export smoke check after cross-Lesson transfers. No Windows executable was built in this tranche.

Known remaining risks are the inherited 72 analyzer findings, platform/media behavior not manually exercised, and the installed SDK's dependency-resolution drift described above. The explicitly accepted 226.01 low-severity observations remain. Native media coverage is partly mocked; automated structural and no-write evidence does not substitute for listening to actual recordings. There is no known unresolved 226.02 implementation defect or design question at delivery.

## Exact repository state before local commit

```text
 M AGENTS.md
 M CHANGELOG.md
 M README.md
 M docs/COURSE_EDITOR.md
 M lib/screens/course_editor_screen.dart
 M lib/screens/editor_help_screen.dart
 M lib/screens/round_screen.dart
 M lib/services/alpha_lifecycle_service.dart
 M lib/services/app_metadata.dart
 M lib/services/authoring_duplication_service.dart
 M lib/services/course_audit_service.dart
 D lib/services/exercise_transfer_service.dart
 M pubspec.yaml
 M test/alpha_lifecycle_test.dart
 M test/app_metadata_225_04_test.dart
 M test/authoring_audit_ui_224_test.dart
 M test/course_audit_report_225_test.dart
 M test/course_editor_224_test.dart
 M test/course_editor_225_test.dart
 M test/exercise_creation_wizard_test.dart
 M test/leaderboard_navigation_test.dart
 M test/learner_round_path_test.dart
 M test/lesson_metadata_and_icon_test.dart
 M test/production_course_transaction_225_04_test.dart
?? docs/226_02_VALIDATION.md
?? lib/screens/audit_codes_screen.dart
?? lib/services/audit_code_registry.dart
?? lib/services/course_authoring_transfer_service.dart
?? lib/services/exercise_field_help.dart
?? lib/widgets/authoring_destination_dialog.dart
?? lib/widgets/editor_breadcrumbs.dart
?? test/audit_code_registry_226_02_test.dart
?? test/audit_codes_screen_226_02_test.dart
?? test/authoring_transfer_ui_226_02_test.dart
?? test/course_authoring_transfer_226_02_test.dart
?? test/exercise_field_help_226_02_test.dart
?? test/exercise_field_help_ui_226_02_test.dart
?? test/exercise_workflow_226_02_test.dart
```

HEAD and origin/main: `45cf258d707c89d512f7663d9f2fa317adbe5ef0`.

The working tree intentionally contains this approved uncommitted tranche. The index is empty before the authorized staging step. Nothing has been pushed, packaged or released. **226.03 remains unstarted.**
