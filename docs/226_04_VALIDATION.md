# QQL 226.04 validation

## Phase 226.04 revision 0 — closure evidence

The user's subsequent clarification supersedes the section-51 question wording and supplies the missing creation contract. **Number of Lessons** defaults to **3**, with whole numbers **1–100**; **Rounds per Lesson** defaults to **1**, with whole numbers **1–20**. The old checkpoint below is historical development evidence, not the final state.

### Requirements and final behavior

1. **Initial structure:** both fields are present before Create. Missing, non-numeric, fractional, negative, zero, oversized and overflowing integer strings display inline errors and disable Create. The new pure `NewCourseStructure` builder validates both counts before allocating IDs, then returns the entire ordered hierarchy. Defaults produce 3 Lessons, 3 empty untitled Rounds and 0 Exercises; 12 × 6 produces 72 Rounds, and 100 × 20 produces 2,000. The dialog passes a complete Course to the existing unpersisted authoring transaction; only final confirmation stores it. Course/Lessons retain the established Draft starting state. Empty Rounds use the ordinary Published default under their Draft parent: emptiness alone adds no Draft badge, while canonical `ROUND_CONTENT_EMPTY` remains red and propagates. No scaffold count is persisted, and no model/import/edit limits are added. Real import of 101 Lessons with 21 Rounds and real UI addition of Lesson 102/Round 22 are covered.
2. **Sections:** the course name catalog and existing assignments populate No section / existing names / Add new section... / Manage sections.... Names are trimmed and deduplicated; used-name removal reports its exact Lesson count and is blocked. New Lessons inherit the immediately preceding Lesson's assignment. Canonical Move/Copy/reorder/Save retain metadata and pending imported icons. Sections acquire no identity, hierarchy or learner state.
3. **Lesson names:** Lesson + number, Number only and Title only reuse stored values `lesson`, `numberOnly`, `none`; other existing prefixes remain. Greetings renders as Lesson 1: Greetings / 1: Greetings / Greetings. The automatic title Lesson 1 renders as Lesson 1 / 1 / Lesson 1, without modifying the stored title or identity. Actual Course Info, Save, learner presentation, 320px Preview and reload paths are covered.
4. **Duel:** Create Duels is default ON. One canonical eligibility service still applies the actual deduplicated 25-Exercise threshold. OFF or insufficient pools render no learner card or reserved Duel connector. Only the existing insufficient-Duel Info finding is suppressed when OFF. v6 requires a Duel object, so its stable identity and historical wins/XP remain; no destructive migration or learner-progress changes occur.
5. **Flags:** Automatic, Existing QQL course flags, World Flags and Custom uploaded flag use their verified existing contracts. World selection reuses the authoritative 266-entry registry, aliases/ISO metadata, categories and SVG renderer. `worldFlagId` is separate from legacy CY/EN flag codes. Shared course widgets handle selector, Top Bar, background and Editor preview. Unknown IDs remain intact, display neutrally and produce explicit validation at import, confirmation and Audit entry points. Custom PNG/JPEG input remains in Documents/QuisquisLingo/Exports, at most 2 MB and 64×40–8192px source dimensions, proportionally converted to PNG of at most 256px longest edge and embedded for portability. No folders or bundled assets are reorganized.
6. **GuideBook:** Use GuideBook is default ON; OFF preserves all content/publication state and suppresses only `LESSON_GUIDEBOOK_EMPTY`. Other findings and independent Draft badges remain. Learner artwork retains the same dimensions and effective theme tint even when Draft or locked, using the same IconButton rendering inside pointer/focus/semantics exclusion. OFF exposes no GuideBook tooltip or actionable interaction. Reenabling restores canonical evaluation and access under existing publication/lock rules. A real navigation-stack test proves the still-mounted Course Editor Lessons indicator changes red → green → red immediately, without reopening or saving.
7. **Lock:** the former full row is absent; the upper AppBar icon retains exactly `Prevents accidental course edits. Stored separately for each course.` as tooltip and the same per-course device preference and protections. Narrow-layout/Help/ID actions and existing edit navigation are covered.
8. **GuideBook ID:** no aggregate GuideBook ID existed. The smallest non-mutating identity is now `${lessonId}_guidebook`, derived from stable ownership, with no added JSON field. It survives Rename/Move/reorder, changes appropriately when a Lesson is copied, and displays on official inspection without a write. Shared global IDs expose selectable monospaced passive text with full tooltip after all relevant GuideBook actions, including the GuideBook editor's Save actions.

### Persistence, release and exclusions

Course Model remains **v6**. New optional `createDuels` and `useGuidebook` fields default true; `sectionNames` defaults empty and `worldFlagId` defaults empty. Canonical JSON omits defaults, preserving the nine bundled courses/checksums. Invalid explicit types are rejected; supported legacy v6 courses load with compatible behavior. Complete canonical copy/fork/transfer, transaction, export/import, history and backup paths preserve the new fields. Unsupported pre-v6 formats remain unsupported; no migration is introduced.

Version **2.0.26**, Phase **226.04**, revision **0**, build **226040** (`2.0.26+226040`). Popup: `Version 2.0.26` / `Phase 226.04, revision 0`, with existing show-once behavior. Alpha expiry remains **2026-10-06 23:59:59 local time**: the master plan does not specify an extension for this tranche, and the current instruction forbids inventing one. The lifecycle service is unchanged. The canonical Audit Registry remains **103 rules**. No Templates/template transfer, Napoletano, GuideBook goals/Further Reading/exercise links, release 227 or unrelated learner/XP/Review/Profile work was started.

### Fresh completion-stage commands and findings

All Flutter commands use the exact installed-SDK prefix recorded below; tests append `test --no-pub --concurrency=1 --reporter expanded --timeout 60s`. All processes run serially, with bounded output yields. No full-suite result is borrowed from baseline 226031 (1,009 passed) or earlier tranches.

| Files/filter | Fresh result / log |
| --- | --- |
| `test/new_course_structure_226_04_test.dart test/course_editor_layout_regression_test.dart` | 4 passed; one test-file compilation failure because the new fixture omitted required language metadata. Corrected the fixture; existing creation/confirmation test passed. `226040-scaffolding-focused.log` |
| `test/new_course_structure_226_04_test.dart test/course_creation_flags_226_04_test.dart` | 18 passed, 1 failed: later-editing fixture expected Create instead of the existing New Round dialog's Save button. All 11 other scaffold cases and all 7 flag cases passed. `226040-scaffolding-flags-focused.log` |
| `test/new_course_structure_226_04_test.dart test/optional_learning_paths_226_04_test.dart --name 'later editing can add\|disabled GuideBook'` | 4 passed, 4 failed. Later editing passed; four new tint tests failed only at teardown due to a SemanticsHandle disposed too late. `226040-editing-guidebook-focused.log` |
| `test/optional_learning_paths_226_04_test.dart --name 'icon tint\|still-mounted Course'` | 5 passed, 0 failed after try/finally semantics cleanup; includes the actual mounted-ancestor test. `226040-guidebook-tint-ancestor-focused.log` |

Review found and corrected a real OFF-state tint mismatch: rendering a plain icon used full-strength color while the original IconButton had disabled tint for Draft/locked Lessons. Production now reuses the original rendering with input/focus/semantics excluded. No border-painting workaround or Audit rule change was used. Earlier focused failures/corrections remain documented in the development evidence below rather than hidden or counted as passing runs.

The installed environment reports Flutter **3.47.2 stable**, framework `d3b14c876900e553bc736ca19295fc09e3853e8e`, Dart **3.13.2**. `flutter pub get --offline` exited 0 (`226040-pub-get.log`); this SDK resolves cached matcher 0.12.20, meta 1.19.0, test_api 0.7.12 and vector_math 2.4.2 instead of the repository lock's 0.12.19/1.18.0/0.7.11/2.2.0. It also inserted generated analyzer exclusions. Those incidental tracked edits were removed with targeted patches, preserving `pubspec.lock` and `analysis_options.yaml` byte content and lint scope. Final `--no-pub` checks use the installed SDK's resolved package configuration; this environment difference is explicit, not a claimed application dependency upgrade. No SDK/tool installation or global configuration change was made.

### Final automated checks

- Final formatting: installed `dart format` over all 38 then-changed Dart files, **0 changes**, exit 0. The subsequent two analyzer-cleanup files and the later Korean fixture were individually formatted, **0 changes**; all **39** final changed Dart files have been formatted.
- Remaining focused boundaries: `test/production_course_transaction_225_04_test.dart test/official_course_ui_226_01_test.dart test/official_course_storage_226_01_test.dart test/course_transfer_v6_225_02_test.dart test/course_authoring_transfer_226_02_test.dart test/authoring_transfer_ui_226_02_test.dart test/exercise_workflow_226_02_test.dart test/exercise_help_224_test.dart test/exercise_help_search_226_03_r1_test.dart test/audio_import_paths_226_03_r1_test.dart` with the documented test flags: **133 passed, 0 failed**, exit 0, `build/226040-existing-boundaries-focused.log`.
- First `flutter analyze --no-pub`: **74 findings**, exit 1: all 72 baseline findings plus a redundant null assertion in Lesson naming and an unnecessary test import. Both new findings were corrected, and the affected `Lesson numbering modes|creation offers all sources` focused cases passed **2/2**, exit 0 (`226040-analyzer-correction-focused.log`).
- Verified `flutter analyze --no-pub`: **72 findings**, exit 1 solely for inherited findings (`build/226040-analyze-verified.log`). Counter comparison with `build/226031-analyze-verified.log` uses severity, message, normalized path and diagnostic code, ignoring shifted line/column positions: **72 inherited, 0 new, 0 resolved** (`226040-analyzer-comparison.json`). Inherited findings are 71 brace-style Infos (67 Course Audit, 3 Image Library, 1 Settings) and the existing unused `_tapAndSettle` test-helper Warning. No suppression or unrelated lint cleanup was added. After the Korean fixture correction, analysis on the exact handoff tree again reported **72 inherited, 0 new, 0 resolved**, exit 1 (`226040-analyze-handoff.log`, `226040-analyzer-handoff-comparison.json`); this final repeat was justified by the changed test file.
- Fresh `python -X utf8 tools/validate_courses.py`: **9 bundled v6 courses valid**.
- Fresh `python -X utf8 tools/regenerate_bundled_courses_225_02.py --check`: **all 9 generated courses/checksums match**. Existing sample titles/content/identities and revision-3 content metadata are unchanged.
- Fresh `python -X utf8 tools/validate_lesson_icons.py`: **14 assets, 0 issues**.
- Fresh `python -X utf8 tools/validate_images.py`: **112 assets, 0 issues**. The validator command group exited 0; the earlier independent validator runs also each exited 0.
- Final `git diff --check`: **exit 0**. The complete intended diff was reviewed for canonical model preservation, unchanged persistence boundaries, official protections and excluded roadmap work. All 46 changed files belong to 226.04; nothing was staged before final verification.
- First complete suite: **1,101 passed, 1 failed**, exit 1 in 14:38 (`build/226040-full-suite.log`). The sole failure was the pre-existing Korean selector fixture expecting `FlagBadge.code == KO`. The course-aware badge correctly uses the unchanged persisted `flagCode: KR`; both KO and KR resolve through the same painter branch. Its registry/route key remains KO. This is a concrete stale fixture correction caused by the requested course-aware flag path, not a flaky-baseline excuse or a bundled-content modification. Only that expectation and its explanatory comment changed after the run. A 241-file SHA-256 comparison confirms it was the sole code/test change. The isolated `test/korean_production_discovery_225_03_test.dart --plain-name 'existing v6 installation discovers'` workflow passed **1/1**, exit 0 in 00:13 (`226040-korean-fixture-focused.log`), including Round, Duel and restart behavior. The required final-tree complete-suite rerun passed **1,102 tests, 0 failed**, exit 0 in **14:22** (`build/226040-full-suite-verified.log`), using the same serial command. This includes all 12 scaffold cases, the corrected Korean workflow and all 226.04 feature tests. No flaky-test failure appeared. The 241-file SHA-256 check after completion found **no code/config changes** since the final snapshot. No production or test file was changed after this final suite.

### Final feature test coverage

Seven new focused test files contribute 91 cases; two additional imported-icon preservation cases were added to `lesson_metadata_and_icon_test.dart`, for **93 additional cases** over the 1,009-case baseline. Development command outcomes, including failures and isolated corrections, are listed explicitly above/below; these per-file counts are not extra reruns or cumulative passing-command totals.

| New focused file | Final complete-suite cases passed | Contract |
| --- | ---: | --- |
| `new_course_structure_226_04_test.dart` | 12 | Defaults, min/normal/max counts, whole-number errors, atomic failure/cancel, IDs/order, canonical empty Audit, roundtrip, 101/21 import and 102/22 real editing |
| `course_options_226_04_test.dart` | 18 | Defaults, strict types, v6 roundtrip, catalogs, copy/fork/transfer, transaction/history/backup, derived GuideBook identity |
| `lesson_controls_226_04_test.dart` | 16 | Sections, inheritance/deletion protection, upper Lock, passive global IDs, switches and narrow layout |
| `lesson_naming_226_04_test.dart` | 5 | Real Course Info choice/Save/Preview/reload and preserved Unit/custom behavior |
| `optional_learning_paths_226_04_test.dart` | 23 | Duel matrix, GuideBook rule isolation, live mounted ancestors, themes/tint/geometry, noninteractive semantics, Preview and historical state |
| `course_creation_flags_226_04_test.dart` | 7 | All four flag-source dialog paths, cancellation, unavailable-ID import and confirmation boundaries |
| `world_flag_course_226_04_test.dart` | 10 | Authoritative registry/search/categories, picker, SVG course widgets, unavailable references and PNG/JPEG conversion |

Native Windows visual/interaction checks remain explicitly deferred in the checklist below. No manual screenshots or native visual verification are claimed. The installed-SDK package-resolution difference described above remains an environment/reproducibility consideration; repository dependency declarations and lock content remain unchanged.

### Commit boundary

The single 226.04 commit uses `Complete QQL 226.04 course structure and optional learning paths`, with immutable parent `ef668dd8c0fab070613c5c0dc925619da7d79443`. Only the 46 reviewed intended files are included. No amend, reset, clean, worktree, destructive migration or push is part of delivery. The resulting commit hash and post-commit `git status --short` are reported after commit creation; the commit cannot embed its own hash in this report.

### Intended final file inventory

46 files (36 modified tracked, 10 new). No bundled JSON, image assets, registrants, dependency lock, analyzer configuration or unrelated files are included. The new tests cover scaffold inputs/atomicity/import/editing, model options and copies/forks/backups, Section/Lock/ID controls, learner naming/Preview, optional learning paths and World Flags. Existing tests were updated only for changed current metadata, Section controls, Lock shape, requested naming and initial structure.

```text
AGENTS.md
CHANGELOG.md
README.md
docs/226_04_VALIDATION.md (new)
docs/COURSE_EDITOR.md
docs/COURSE_JSON_FORMAT.md
lib/models/course_models.dart
lib/screens/course_editor_screen.dart
lib/screens/course_projects_screen.dart
lib/screens/editor_help_screen.dart
lib/screens/home_screen.dart
lib/screens/official_course_inspection_screen.dart
lib/screens/round_screen.dart
lib/services/app_metadata.dart
lib/services/authoring_duplication_service.dart
lib/services/course_audit_service.dart
lib/services/course_authoring_transfer_service.dart
lib/services/course_editor_service.dart
lib/services/course_flag_service.dart
lib/services/custom_course_transfer_service.dart
lib/services/lesson_presentation_service.dart
lib/services/new_course_structure.dart (new)
lib/services/world_flag_repository.dart
lib/widgets/flag_art.dart
lib/widgets/world_flag_art.dart
lib/widgets/world_flag_picker.dart (new)
pubspec.yaml
test/alpha_lifecycle_test.dart
test/app_metadata_225_04_test.dart
test/authoring_hierarchy_indicators_226_02_test.dart
test/course_audit_report_225_test.dart
test/course_creation_flags_226_04_test.dart (new)
test/course_editor_224_test.dart
test/course_editor_layout_regression_test.dart
test/course_options_226_04_test.dart (new)
test/guidebook_status_workflow_226_02_test.dart
test/korean_production_discovery_225_03_test.dart
test/leaderboard_navigation_test.dart
test/learner_round_path_test.dart
test/lesson_controls_226_04_test.dart (new)
test/lesson_metadata_and_icon_test.dart
test/lesson_naming_226_04_test.dart (new)
test/new_course_structure_226_04_test.dart (new)
test/optional_learning_paths_226_04_test.dart (new)
test/publication_and_presentation_224_test.dart
test/world_flag_course_226_04_test.dart (new)
```

## Development evidence — historical checkpoint before count clarification

Baseline: `ef668dd8c0fab070613c5c0dc925619da7d79443`, parent `dd2119868dcd2bb79808915bb873e147f1ece560`. Initial checkout was clean on `main`; the local `origin/main` reference matched HEAD (0 ahead, 0 behind). No fetch or push was performed. Historical baseline evidence is 1,009 tests passed and 72 inherited analyzer findings; it is not fresh 226.04 validation.

Target metadata: Version `2.0.26`, Phase `226.04`, revision `0`, technical build `226040`, pubspec `2.0.26+226040`. Alpha expiry remains `2026-10-06 23:59:59` local time. The master prompt's metadata instructions (lines 90–94) require the established policy and actual release timing, and do not mandate a new expiry for this tranche; the current user request forbids inventing one.

### Specification and compatibility decisions

- Master prompt sections 42–57 govern this tranche. Section 51 gives a 12 × 6 example and the exact two count questions, but supplies no defaults or minimum/maximum counts. These values were requested from the user; initial-scaffolding implementation remains pending that answer.
- Course Model remains v6. Optional `createDuels` and `useGuidebook` default to `true`; `sectionNames` defaults to an empty catalog and `worldFlagId` to an empty string. Default values are omitted from JSON so existing bundled course JSON/checksums do not change. Supplied invalid types are rejected. Existing supported v6 import behavior remains; unsupported earlier model versions are not migrated.
- The Section catalog is trimmed, deduplicated and immutable. Available choices include legacy Lesson assignments without inserting catalog fields during loading. Sections remain Lesson metadata; they have no independent identity or learner state.
- GuideBook had no aggregate stored ID. `Lesson.guidebookId` now explicitly defines the Lesson-owned identity as `${lessonId}_guidebook`. This is a newly defined derived identity, not a claimed pre-existing JSON field or Content ID. Rename, reorder and Move retain it; copied Lessons receive a fresh corresponding identity. Display requires no mutation, including for official courses.
- v6 requires a non-null Duel object, creates its identity from Lesson ID, and rejects a missing Duel object. This correction retains that format contract, as master section 43 qualifies true absence by what the canonical model permits. Disabling Duels suppresses availability/display and insufficient-pool guidance, not stored identities or historical wins/XP.
- World Flags use the authoritative 266-entity repository and SVG assets through shared course-aware widgets. `worldFlagId` is separate from legacy `flagCode`, including CY=Wales and EN=English/UK. Unknown World Flag IDs retain their data, display neutrally, and produce explicit validation at import/confirmation and user-invoked Audit entry points. No new Audit code is required; the canonical registry stays at 103.

### Implemented paths awaiting final closure

- Lessons-page `Use GuideBook` and `Create Duels` switches use the shared immutable `onCourseChanged` working-copy path and respect the existing Lock protection.
- GuideBook OFF suppresses only `LESSON_GUIDEBOOK_EMPTY`; malformed-content findings remain active. Learner book geometry is retained without tooltip, tap handler or actionable semantics. Re-enabling restores interaction and canonical warning propagation. Round introduction and unsaved Preview respect the course choice.
- Duel ON uses the existing authoritative eligibility service. Disabled or ineligible Duel cards and their preceding connector are absent; normal Lesson boundaries and historical learner data remain.
- Lesson naming exposes `Lesson + number`, `Number only`, and `Title only`, retaining other existing prefixes. The common automatic title is deduplicated without changing stored titles or IDs. Lesson authoring Preview uses the same presentation service.
- Section picker supports No section, existing names, Add new section and Manage sections. Used names report their exact Lesson usage count and cannot be removed. New Lessons inherit the immediately previous Lesson's assignment. Catalog mutations preserve pending imported Lesson icons.
- Lock is an AppBar icon; its unchanged description is the tooltip: `Prevents accidental course edits. Stored separately for each course.` GuideBook IDs follow their actionable content and reuse the global selectable/monospaced/full-tooltip ID widget.
- New-course flag selection exposes Automatic, Existing QQL course flags, World Flags and Custom uploaded flag. The World Flag picker searches names, aliases, IDs and ISO/subdivision metadata and reuses reference categories. PNG/JPEG import keeps the existing directory, validation, proportional PNG conversion and embedded-byte portability contract.

### Fresh focused evidence so far

These earlier focused commands used the installed Flutter tool snapshot through its existing Dart SDK, with `--no-pub --concurrency=1 --reporter expanded`. This avoids the previously documented wrapper startup problem. The later offline dependency refresh and its SDK-specific resolution are recorded in the closure section.

| Command arguments after the Flutter tool prefix | Result |
| --- | --- |
| `test test/course_options_226_04_test.dart` | 18 passed, 0 failed |
| `test test/optional_learning_paths_226_04_test.dart` | 16 passed, 2 failed initially |
| `test --timeout 60s test/optional_learning_paths_226_04_test.dart --name 'Use GuideBook suppresses\|Lessons toggle immediately'` | 2 passed after fixture correction |
| `test test/world_flag_course_226_04_test.dart` | First 8 passed; interrupted at native image conversion awaiting fake-async work |
| `test --timeout 60s test/world_flag_course_226_04_test.dart --plain-name 'custom PNG and JPEG validation'` | 2 passed after using `tester.runAsync` for native image work |

The two Audit fixture failures were genuine canonical `ROUND_CONTENT_LONG` Warnings: their fixture put 26 Content items in one Round. Only the two isolated GuideBook transition fixtures were reduced to three Exercises, with an assertion that `LESSON_GUIDEBOOK_EMPTY` is the sole non-Info finding. Production did not force a branch green or weaken any rule.

The flag-test log began at 19:04:50 local and last advanced at 19:05:01 before interruption during inspection; the corrected isolated image run completed at approximately 19:08. No duplicate Flutter process was launched. Native image encoding/decoding needed the real asynchronous test zone; production conversion was unchanged.

Final analyzer, complete suite, complete diff review and commit have **not** yet been run for this intended final tree. Fresh validator results are recorded below. Focused logs are under `build/226040-*.log`. This record must be completed before claiming delivery.

### Continuation checkpoint

Checkpoint verification: the affected existing `course_editor_224_test.dart` case, selected with `--plain-name 'Lessons subpage exposes upper Lock and preserves Lesson IDs'`, passed **1/1**, exit 0 (`build/226040-lock-existing-focused.log`). Formatting all 35 changed/untracked Dart files completed with **0 changes**, exit 0. Two preceding sandboxed formatting invocations finished formatting but exited 1 when Dart attempted to update its existing telemetry session file outside the checkout; the authorized SDK-access run resolved that tooling permission issue. `git diff --check` passed, exit 0. HEAD remains `ef668dd8c0fab070613c5c0dc925619da7d79443` on `main`; nothing is staged, committed or pushed. These are checkpoint checks, not final-tranche validation.

Exact checkpoint file inventory (32 modified tracked files and 8 new files; all changes remain unstaged):

```text
README.md
docs/COURSE_EDITOR.md
docs/COURSE_JSON_FORMAT.md
docs/226_04_VALIDATION.md (new)
lib/models/course_models.dart
lib/screens/course_editor_screen.dart
lib/screens/course_projects_screen.dart
lib/screens/editor_help_screen.dart
lib/screens/home_screen.dart
lib/screens/official_course_inspection_screen.dart
lib/screens/round_screen.dart
lib/services/app_metadata.dart
lib/services/authoring_duplication_service.dart
lib/services/course_audit_service.dart
lib/services/course_authoring_transfer_service.dart
lib/services/course_editor_service.dart
lib/services/course_flag_service.dart
lib/services/custom_course_transfer_service.dart
lib/services/lesson_presentation_service.dart
lib/services/world_flag_repository.dart
lib/widgets/flag_art.dart
lib/widgets/world_flag_art.dart
lib/widgets/world_flag_picker.dart (new)
pubspec.yaml
test/alpha_lifecycle_test.dart
test/app_metadata_225_04_test.dart
test/authoring_hierarchy_indicators_226_02_test.dart
test/course_audit_report_225_test.dart
test/course_editor_224_test.dart
test/guidebook_status_workflow_226_02_test.dart
test/leaderboard_navigation_test.dart
test/learner_round_path_test.dart
test/lesson_metadata_and_icon_test.dart
test/publication_and_presentation_224_test.dart
test/course_creation_flags_226_04_test.dart (new)
test/course_options_226_04_test.dart (new)
test/lesson_controls_226_04_test.dart (new)
test/lesson_naming_226_04_test.dart (new)
test/optional_learning_paths_226_04_test.dart (new)
test/world_flag_course_226_04_test.dart (new)
```

The independent 226.04 work is preserved **uncommitted**. Initial course scaffolding is not implemented: the old three-placeholder-Lesson code remains until the author specifies the default, minimum and maximum for both requested counts. The new-course flag UI is implemented independently. The documentation describes the intended scaffolding contract, not completed evidence. Changelog/release-boundary closure, final analyzer/delta, complete suite and commit remain pending completion. No analyzer or full-suite run was started prematurely.

Additional fresh commands used the following exact prefix (followed by `test --no-pub --concurrency=1 --reporter expanded --timeout 60s` and the file/filter arguments below):

```powershell
$env:DART_SUPPRESS_ANALYTICS='true'; $env:FLUTTER_SUPPRESS_ANALYTICS='true'; & 'C:\Users\ansa\flutter\bin\cache\dart-sdk\bin\dart.exe' --packages='C:\Users\ansa\flutter\packages\flutter_tools\.dart_tool\package_config.json' 'C:\Users\ansa\flutter\bin\cache\flutter_tools.snapshot'
```

| Files/filter after those arguments | Fresh result / log |
| --- | --- |
| `test/lesson_controls_226_04_test.dart test/lesson_metadata_and_icon_test.dart test/course_creation_flags_226_04_test.dart` | 30 passed, 2 failed: World picker settling and subsequent manifest import timeout; `226040-editor-focused.log` |
| `test/publication_and_presentation_224_test.dart test/lesson_section_widget_test.dart test/duel_eligibility_service_test.dart test/course_model_v6_test.dart test/audit_code_registry_226_02_test.dart test/authoring_hierarchy_indicators_226_02_test.dart test/guidebook_publication_226_02_revision4_test.dart test/custom_hierarchy_id_order_226_02_revision4_test.dart test/official_hierarchy_id_order_226_02_test.dart test/world_flag_dataset_test.dart test/flag_backdrop_test.dart test/lesson_fallback_number_icon_226_02_test.dart test/course_editor_layout_regression_test.dart` | 105 passed, 2 failed: naming overreach and obsolete Lock fixture cast; `226040-existing-focused.log` |
| `test/publication_and_presentation_224_test.dart test/authoring_hierarchy_indicators_226_02_test.dart --name 'Lesson numbering modes\|accepted Exercise saves'` | Live Exercise-save ancestor test passed; numbering test reached the obsolete `1: Lesson 1` expectation and failed: 1 passed, 1 failed; `226040-existing-corrected-focused.log` |
| `test/course_creation_flags_226_04_test.dart --name 'World Flags selection\|course JSON import rejects\|confirmation rejects'` | Import and zero-write confirmation boundaries passed; picker still timed out: 2 passed, 1 failed; `226040-flag-boundaries-focused.log` |
| `test/course_creation_flags_226_04_test.dart test/publication_and_presentation_224_test.dart --name 'World Flags selection\|Lesson numbering modes'` | Corrected naming passed; picker loading boundary still failed: 1 passed, 1 failed; `226040-picker-naming-corrected.log` |
| `test/course_creation_flags_226_04_test.dart --plain-name 'World Flags selection'` | Diagnostic and partial real-async fixture attempts each failed once (`226040-picker-diagnostic.log`, `226040-picker-real-async.log`); final correction passed 1/1 (`226040-picker-complete-async.log`) |
| `test/lesson_naming_226_04_test.dart test/guidebook_status_workflow_226_02_test.dart test/app_metadata_225_04_test.dart test/course_audit_report_225_test.dart` | 18 passed, 1 failed: old Build 226.03 expectation in report fixture; all five real naming/Preview tests, five GuideBook workflow tests and both metadata tests passed; `226040-naming-guidebook-metadata.log` |
| `test/course_audit_report_225_test.dart --plain-name 'complete report includes metadata'` | 1 passed after current-build fixture correction; `226040-report-metadata-corrected.log` |
| `test/alpha_lifecycle_test.dart test/leaderboard_navigation_test.dart --name 'expiry\|Welcome'` | 3 passed: unchanged expiry, welcome/show-once controls, dark-theme popup; `226040-welcome-expiry-focused.log` |

The World picker fixture initially awaited a large manifest and animated SVG-loading widgets through `pumpAndSettle` in a fake async clock. Preloading alone did not complete callbacks that crossed real/fake zones. Diagnostic widget text proved the picker itself opened but its manifest-backed body was pending. The final fixture executes opening, selection-return and editor-navigation callbacks with their asset futures inside `tester.runAsync`, then uses bounded route-transition pumps and explicit target assertions. The production picker was not rewritten to make the fixture pass. Native Windows visual verification remains outstanding.

The naming implementation initially deduplicated `Lesson 1` under every prefix, changing the existing `Unit 1: Lesson 1` behavior. It now deduplicates an exact matching prefix and the master-specified `Number only`/`Lesson 1` combination, preserving Unit/custom-prefix behavior. The old Number-only fixture was separately updated to the explicitly required `1`. Old Lock fixtures were adapted from `SwitchListTile.value` to `IconButton.isSelected`; no Lock authorization or stored preference changed.

Review also found that Section catalog edits could replace a pending imported Lesson-icon asset list with the older Course list. Both catalog mutation paths now serialize `_courseWithIcons`; two real import → Add/Manage Section → Draft Save tests passed with PNG bytes and canonical references preserved through roundtrip.

Repository validators were run freshly and all exited 0:

- `python -X utf8 tools/validate_courses.py`: 9 bundled v6 courses valid.
- `python -X utf8 tools/regenerate_bundled_courses_225_02.py --check`: all 9 existing generated courses and SHA-256 values match; their intentional revision-3 content metadata is unchanged.
- `python -X utf8 tools/validate_lesson_icons.py`: 14 assets, 0 issues.
- `python -X utf8 tools/validate_images.py`: 112 assets, 0 issues.

All changed Dart files were formatted using the installed SDK. `git diff --check` has passed during this working pass; a final check is required after the remaining implementation. Analyzer comparison remains **not run**, with 72 findings recorded only as the supplied baseline. Full-suite result remains **not run** for 226.04. No commit or push was created.

### Remaining native Windows checks

- New-course counts, validation, cancellation and large planned hierarchy responsiveness.
- Section selection/add/delete protection, inheritance and pending-icon preservation through nested navigation.
- All Lesson label modes, long titles and narrow Learner/Preview layouts.
- Duel ON/OFF and eligibility transitions without placeholder spacing or historical-data changes.
- GuideBook ON/OFF book appearance, tooltip/interaction/accessibility, selective red/green propagation and independent blue Draft badge.
- Upper Lock action, unchanged tooltip, keyboard behavior and Help/ID actions at narrow widths.
- GuideBook ID selection, copying, complete tooltip, passive ordering and immediate global toggle.
- All four flag sources, SVG previews/background/top bar/selector, PNG/JPEG conversion and unavailable-reference diagnostics.
- Revision-0 welcome popup/show-once behavior, light and dark themes.

No Custom Exercise Templates, template import/export, Napoletano, GuideBook goals/Further Reading/exercise links, release 227, or unrelated learner/XP/Review/Profile work is included.
