# QQL 226.04 validation

## Revision-1 corrective completion — first-Save publication reconciliation

This follow-up starts from `782bc26ed52b0afe5a66f42e194abb64e1092320`, whose parent is `50a52988872e8d6bb3b7be5e3e261eb2741a60c7`. The user's later product clarification supersedes the independent-parent-Save policy in the historical closure below. The confirmed MyTest workflow **edits and saves the existing scaffolded sample Exercise**, without adding a second Exercise. Prior results of 1,136 passing tests and 71 inherited analyzer findings belong to that committed baseline; they are not fresh evidence for this follow-up.

### Separate causes and corrections

1. **Missing own-state Draft indicator:** the committed revision-1 fix already includes a Lesson's/Round's own state and canonical descendants in the independent blue Draft badge. A green Audit does not prove non-Draft status. That fix is retained; badge tooltips now distinguish provisional parents from explicit Drafts.
2. **First Save and canonical snapshots:** Exercise Save constructs a Published candidate and invokes `onExerciseSaved` before returning. Round acceptance replaces the Exercise by stable ID, rebuilds complete canonical Content and calls `onCourseChanged`. GuideBook Save similarly replaces the current Lesson's GuideBook before propagating the Course. No separate lost first Exercise Save was found. However, the Rounds page rebuilt its returning Lesson from the original `widget.lesson`; that stale source could restore a former parent publication state after a descendant callback. It now uses the latest stable-ID-resolved Lesson. Returned Round replacements also resolve by ID, and Save returns the latest reconciled entity. The current Round state controls Published-to-Draft confirmation, including after automatic reconciliation in the same route.
3. **Provisional parent readiness:** the prior model could not distinguish scaffolding from deliberate Draft. New Lessons and manually created Rounds now carry optional `provisionalDraft: true`. One shared service, used by the immutable authoring adoption path, reconciles ready marked Draft parents bottom-up after saves and other readiness-changing authoring mutations. A Round needs valid nonempty learner content, non-Draft Exercises and non-Draft required Content. A Lesson needs nonempty, ready, non-Draft Rounds, valid required metadata, and a non-Draft usable GuideBook with non-Draft required Content when GuideBooks are enabled. Disabling GuideBooks bypasses that required-GuideBook readiness condition. The service follows canonical normal-Save Error checks and the existing empty-GuideBook rule; it does not substitute border colors for validation or make Info guidance blocking.
4. **Explicit Save Draft:** explicit Lesson/Round Save Draft clears automatic eligibility and remains Draft until its own non-Draft Save. Exercise Save Draft stays Draft and blocks provisional parent readiness. Legacy unmarked Draft parents remain Draft because their original intent cannot be recovered safely. Imports converted to Draft, duplicates and licensed forks also retain their intentional review boundary. The Course's Published/Not published choice is never changed automatically.

### Persistence and first-Save trace

Course Model remains **v6**. Only Lesson and Round gain the optional boolean `provisionalDraft`; missing values default to false, false is omitted from canonical output, and malformed present values are rejected. There is no destructive migration, title/ID heuristic, user-record rewrite or new publication-state token. Moves and ordinary edits preserve the marker; explicit parent Save choices clear it. Complete canonical JSON snapshots preserve IDs, Content metadata, Section, GuideBook, Duel, provenance and unrelated supported fields. No bundled JSON is rewritten.

The reconciliation service audits one temporary complete-parent-Published learner projection against the original source-reference Course. This validation view is never adopted or persisted. Actual replacements use the original complete source objects; only promoted parents change state, marker and `updatedAt`. Optional Draft content stays stored while ordinary learner filtering omits it. Required Draft content prevents provisional readiness.

The tested path is candidate → current Exercise → stable-ID Round replacement → `onCourseChanged` → canonical Lesson/Course → one top-level Course confirmation → raw SharedPreferences envelope → decoded same-ID Course → persisted selection → learner projection → Home/restart. Nested saves remain working-copy operations and do not write user storage. New Course still creates 3 Lessons × 1 Round by default, with exactly one Draft sample per Round. Scaffolded Rounds retain their established non-Draft state; incomplete sibling Lessons remain provisional Drafts.

### Fresh verification

Commands use the installed Flutter SDK invocation recorded below, with `test --no-pub --concurrency=1 --reporter expanded --timeout 60s`; logs are ignored local `build/` evidence. Flutter commands run serially. The requested corrective metadata stays **2.0.26+226041 / Phase 226.04 / revision 1**, including `Version 2.0.26` and `Phase 226.04, revision 1` in the show-once popup.

| Fresh command / arguments | Result |
| --- | --- |
| `dart format --output=none --set-exit-if-changed` on all 11 changed/new Dart files | **11 files, 0 changes**, exit 0. |
| `test/provisional_draft_model_test.dart` | **9 passed / 0 failed**, 00:02, exit 0; missing/false/true/malformed marker compatibility and round trips. `provisional-model.log`. |
| `test/provisional_publication_service_test.dart test/provisional_parent_save_ui_test.dart test/provisional_mytest_workflow_test.dart` | **31 passed / 2 failed**, 01:10, exit 1. Both failures were new official-course fixtures missing required provenance, before the service could run. The six parent navigation tests and exact MyTest test passed. `provisional-behavior.log`. |
| `test/provisional_publication_service_test.dart --name 'official Courses are returned\|licensed official fork'` | **2 passed / 0 failed**, 00:00, exit 0 after supplying complete required official provenance in the two fixtures. Production protections were unchanged. `provisional-official-fixtures.log`. |
| `test/provisional_publication_service_test.dart` after the test-helper analyzer correction | **26 passed / 0 failed**, 00:00, exit 0; all reconciliation and transfer/import/copy/fork cases on the final source. `provisional-service-final.log`. |
| Affected existing set listed below | **202 passed / 0 failed**, 04:59, exit 0. `provisional-affected.log`. |
| First `flutter analyze --no-pub` | **72 findings**, exit 1, 58.1s: 71 inherited plus one new brace-style Info in a new test helper. The helper was corrected without production changes or lint suppression. `provisional-analyze.log`, `provisional-analyzer-initial-delta.json`. |
| Final `flutter analyze --no-pub` | **71 inherited / 0 new / 0 resolved**, exit 1 solely for inherited findings, 9.5s. Compared with committed baseline `782bc26` using severity, message, normalized file path and code, ignoring shifted line/column positions. Against original revision-0's 72 findings, the earlier committed resolution remains historical: 71 inherited / 0 new / 1 resolved overall. `provisional-analyze-final.log`, `provisional-analyzer-final-delta.json`. |
| Complete Flutter suite on the final tree | **1,178 passed / 0 failed**, exit 0, **17:40**. One complete run; no flaky failure appeared. `provisional-full-suite.log`. All 250 source/test/config SHA-256 values matched after completion. No source or test file changed after this run. |
| `python -X utf8 tools/validate_courses.py` | **9 bundled v6 Courses valid**, exit 0. |
| `python -X utf8 tools/regenerate_bundled_courses_225_02.py --check` | **All 9 generated Courses/checksums match**, exit 0. |
| `python -X utf8 tools/validate_lesson_icons.py` | **14 assets / 0 issues**, exit 0. |
| `python -X utf8 tools/validate_images.py` | **112 assets / 0 issues**, exit 0. |
| `git diff --check` | Passed, exit 0; final status contains only the 17 intended follow-up files. |

The 202-test command used these exact file arguments: `test/new_course_structure_226_04_test.dart test/course_model_v6_test.dart test/publication_and_presentation_224_test.dart test/course_authoring_transfer_226_02_test.dart test/authoring_transfer_ui_226_02_test.dart test/guidebook_publication_226_02_revision4_test.dart test/optional_learning_paths_226_04_test.dart test/draft_container_visibility_226_04_r1_test.dart test/authoring_hierarchy_indicators_226_02_test.dart test/course_editor_transaction_225_04_test.dart test/production_course_transaction_225_04_test.dart test/official_course_ui_226_01_test.dart test/persisted_learner_delivery_226_04_r1_test.dart test/app_metadata_225_04_test.dart test/alpha_lifecycle_test.dart`.

The four new test files contain **42 distinct regressions**, all included in the completed final suite: 9 model contracts, 26 reconciliation/compatibility cases, 6 actual parent-navigation cases and 1 full MyTest creation/apply/restart workflow. This inventory is not an additional test run or a sum of overlapping final-report groups. The previous baseline's 1,136 tests plus these 42 cases account for the final 1,178.

### Follow-up file inventory

Seventeen intended files: `AGENTS.md`, `CHANGELOG.md`, `README.md`, `docs/226_04_VALIDATION.md`, `docs/COURSE_EDITOR.md`, `docs/COURSE_JSON_FORMAT.md`, `lib/models/course_models.dart`, `lib/screens/course_editor_screen.dart`, `lib/screens/editor_help_screen.dart`, `lib/services/course_authoring_transfer_service.dart`, `lib/services/new_course_structure.dart`, `lib/services/publication_service.dart`, new `lib/services/provisional_publication_service.dart`, and the four new `test/provisional_*_test.dart` files listed above. Version, Alpha lifecycle, Audit Registry, bundled Courses, flags, audio and learner scoring code are unchanged in this follow-up. The registry remains **102 rules**.

### Remaining native checks and exclusions

Repeat MyTest on Windows using the existing sample, one Exercise Save, one GuideBook Save, no Round/Lesson Save, and one final Course apply; select it and restart. Verify only the completed first Lesson is available, deliberate Save Draft remains unavailable, blue badges refresh independently from Audit, and conversion back to Draft still asks for confirmation. Check GuideBook ON/OFF, narrow layouts and the revision popup. Check responsiveness on a maximum-size scaffold: ancestor adoption callbacks may repeat a complete canonical Audit while other provisional siblings remain incomplete. Existing Exercise callback-plus-route-result acceptance is idempotent by stable ID; tests prove no duplication, but do not measure callback count. Automated widget tests do not constitute native visual verification.

The requested scope remains corrective completion of 226.04 revision 1. Revision-2 flag/language work, Templates, Napoletano, future GuideBook content, release 227, release-228 Audio Settings/log diagnostics and release-230 generated/saved TTS audio are excluded. Alpha expiry remains exactly **2026-10-06 23:59:59 local time**. Nothing is pushed.

### Corrective-completion commit boundary

One new commit, **`Reconcile QQL 226.04 publication after one Save`**, follows immutable parent `782bc26ed52b0afe5a66f42e194abb64e1092320`; it does not amend either earlier revision-1 work or revision 0. It contains only the 17 files above. Final analyzer findings are entirely inherited; all required automated behavior and asset checks passed. The resulting commit hash and post-commit short status are reported after creation. No push, worktree, destructive recovery or actual user-Course migration/publication was performed.

## Phase 226.04 revision 1 — closure evidence

This section records fresh revision-1 work against `50a52988872e8d6bb3b7be5e3e261eb2741a60c7` (`Complete QQL 226.04 course structure and optional learning paths`). The revision-0 records below remain historical evidence. Correction 1 has a reproduced Editor-state root cause, and all affected focused tests and the final analyzer comparison are complete. The complete-suite result and commit boundary are recorded below; revision-0 evidence is not reused as revision-1 validation.

### Reported defects, diagnosis and current correction

1. **Persisted custom Course shows no learner Lessons.** The user's report was correct: the Editor could display no Draft badge anywhere even though the selected Course's only Lesson was persisted as Draft. A read-only real-record widget diagnostic proved that raw JSON, `CourseEditorService` decoding, the actual Lessons Editor object and learner projection all used the same stable Course ID. Raw/decoded/Editor Lesson state was `draft`, but `AuthoringStatusCard.hasDraft` was **false**, canonical Audit was **0 Errors / 0 Warnings**, and learner projection correctly removed the Draft Lesson. The shared `AuthoringHierarchyStatus` omitted each Lesson's and Round's own publication state; it considered only descendant Exercises/GuideBook. This is an **Editor state-presentation defect**, not empty-state wording, a decoder conversion, lost JSON, title/topic selection, or a required change to Draft filtering. The correction includes own Lesson/Round states and canonical Content in shared Draft propagation, plus an own-container blue badge beside Save with an explanatory tooltip. Published child branches remain independently clean. Course delivery remains separate. Explicit Lesson Save and final Course confirmation publish through the existing complete-object transaction; no automatic publication is introduced. Raw-persistence → decode → Editor → stable-ID selector → Home/restart coverage uses a synthetic raw v6 fixture and a same-title/different-ID Course, independently of scaffolding.

   **Metadata-only live evidence:** storage category is the Windows Roaming Application Support SharedPreferences custom-course envelope (`flutter.quisquislingo_user_courses_v6_225`, entry `{course,savedAt}`); the exact per-profile selection was `custom:course_bc07f6a0-da55-46c8-b4ce-d2380fba2979`. Course `course_bc07f6a0-da55-46c8-b4ce-d2380fba2979` was custom, format 6, version 5, explicitly `published`; Lesson `custom_lesson_1788754105106466_0` explicitly `draft`; Round `custom_round_1788754105106466_1` explicitly `published`; Content/Exercise IDs `custom_exercise_1788754144123883_0` and `custom_exercise_1788755463132143_0` explicitly `published`. Nested Exercise objects inherit the canonical Content state. GuideBook's missing state uses the established Published compatibility default, and its Content was Published. All seven custom records had matching map/internal Course IDs and zero duplicated Course IDs; the affected title had one record. `Normal` was old presentation wording for Published, not a persisted enum value. Course/Lesson/Round/Content parsing requires explicit `draft`/`published`; no default changed this Lesson. The inactive legacy global selection was not the active profile's selection.

   The first actual-record run (`226041-actual-editor-before.log`) passed **2/2** and captured the concealed state. During a subsequent read-only probe, the external live record changed: the same Lesson was now Published and projection returned one Lesson. No task code wrote the user's preferences or published any content; UI checks use mocked storage, and byte comparisons guard the live read. The later state change is not attributed to an actor or claimed as the implementation fix. The first probe remains the pre-correction evidence; stable synthetic regression fixtures avoid depending on mutable live application data. No Lesson content is reproduced in this report.
2. **Initial sample Exercise.** `NewCourseStructure` now builds exactly one canonical `How do you say?`/`choice` Exercise per generated Round, including fresh Exercise and answer-item IDs. It validates counts and nonempty languages before generation and returns the entire hierarchy atomically. The source and learning languages supply explicit editable placeholders: instruction `Write a <source> instruction to translate into <learning>.`, question `Text in <source>`, correct answer `Translation in <learning>`, and literal distractor `Wrong Answer`. These are language-labelled authoring placeholders, not claims of translated teaching content. Every sample Exercise is Draft; the existing Course/Lesson starting states remain intact. Defaults remain 3 Lessons × 1 Round. Generation is confined to New Course; later opening/editing does not add samples. New Course displays exactly **`Each Round starts with a sample exercise.`** Counts remain one-time scaffolding inputs, not persisted settings or model/import/edit limits.
3. **Sample-comparison Audit Info.** Removed **`ROUND_CONTENT_SHORT`**, its 1–7-item producer and its registry/Help entry. It was the sole Info rule whose purpose was comparison with standard sample structure. The canonical registry is now **102 rules: 70 Error / 27 Warning / 5 Info**. `ROUND_CONTENT_LONG` remains the existing **Warning** for more than 10 Content items; its predicate/severity are unchanged and its message/Help now describe pacing without a sample comparison. Genuine `ROUND_CONTENT_EMPTY`, `LESSON_ROUNDS_EMPTY`, `LESSON_ROUND_GUIDANCE`, integrity checks and other Error/Warning behavior remain. Registry search, Help counts and filters all consume the same definitions. The unrelated obsolete sample-length assertion in general Editor Help is removed.
4. **Delivery wording.** Course delivery status displays exactly **Published** or **Not published**, with Publish/Unpublish actions. Unpublishing asks **`Set Course to Not published?`** and explains that individual authoring Draft states and content are preserved. Course delivery changes retain the existing underlying `publicationState` contract; they do not publish or unpublish descendants. The existing top-level confirmation remains the persistence boundary.
5. **Authoring metadata naming.** The editable navigation entry and metadata dialog use **Course Info Editor**. Authoring Help/documentation use that name. The learner-facing **Course Info** page and official read-only information retain their existing names and navigation.
6. **Lesson numbering.** The existing control and all stored choices move from Course Info Editor to **Lessons → Lesson appearance**. Editor list labels, individual Lesson AppBars, breadcrumbs and learner/Preview identities share the existing presentation service. Module produces **Module 1**, **Module 2**, etc.; automatic `Lesson N` titles are deduplicated for the selected term without changing stored titles or IDs. Lesson + number, Number only and Title only retain their stored values and semantics. Custom-label cancellation restores the unchanged canonical selection. Selection persists through the existing Course working-copy/save/reload path; no new field or migration is introduced. Equivalent Rounds-title and learner lock-accessibility labels also use the selected presentation.
7. **Fill in the Blank Hint.** The friendly Fill in the Blank preset is canonical `gap_choice`. Inspection showed that Hint already survived field mapping, unsaved candidate construction and v6 persistence; the shared choice renderer omitted it. The shared RoundScreen now renders a nonempty configured Hint before the answer choices, for both ordinary learner delivery and unsaved Preview. Whitespace-only Hint remains absent. The renderer does not derive or reveal an answer, and existing Hint validation/correctness rules remain. Editor guidance says exactly **`Use ___ (3 underscores)`**; contextual Help uses the same instruction. Tests cover Preview before Save and after Draft/Published Save plus Course round trip and reopen.

### Metadata, persistence and preserved boundaries

Target metadata is **Version 2.0.26 / Phase 226.04 / revision 1 / technical build 226041**, pubspec **`2.0.26+226041`**. The first-run popup uses `Version 2.0.26` and `Phase 226.04, revision 1`, preserving the existing show-once mechanism. Alpha expiry remains exactly **2026-10-06 23:59:59 local time**, as explicitly required; no expiry policy or lifecycle change is introduced.

Course Model remains **v6**, using the existing fields and backward-compatible defaults. There is no migration, destructive rewrite, bundled JSON/default-field insertion or new publication state. Stable identities, complete canonical objects, Sections, optional Duel/GuideBook behavior, upper Lock icon, GuideBook IDs, official/fork protections, independent Draft/Audit hierarchy and unsaved Preview's no-write boundary remain in scope for regression protection. Imports and Exports retain their established directories.

### Fresh commands and results

Commands use the installed Flutter SDK invocation recorded in the revision-0 command convention below, with `test --no-pub --concurrency=1 --reporter expanded --timeout 60s` and the file arguments listed here. Flutter commands run serially. Logs are ignored local `build/` evidence; totals from overlapping development groups are not added together or presented as final-suite totals.

| File arguments / command | Exact current evidence |
| --- | --- |
| `test/fill_blank_hint_226_04_r1_test.dart test/new_course_structure_226_04_test.dart test/audit_code_registry_226_02_test.dart` | **23 passed; 1 test-file compilation failure**, 00:21. New Course's language argument referred to undefined `sr` instead of the existing source variable; production typo corrected. Hint and registry tests passed. `build/226041-initial-focused.log`. |
| `test/new_course_structure_226_04_test.dart test/lesson_naming_226_04_test.dart test/course_metadata_wording_226_04_r1_test.dart test/course_editor_layout_regression_test.dart` | **23 passed / 7 failed**, 00:50. One check expected the new creation guidance as a separate exact Text; the guidance now renders as that standalone sentence. Six naming fixtures attempted to locate lazily built list targets before scrolling; their traversal was corrected. Metadata wording tests passed. `build/226041-editor-focused.log`. |
| `test/new_course_structure_226_04_test.dart test/lesson_naming_226_04_test.dart test/persisted_learner_delivery_226_04_r1_test.dart` | **23 passed / 1 failed before interruption**, not a completed passing run. One Number-only naming finder was corrected. The subsequent real-backup delivery fixture awaited filesystem work inside fake async and stopped making progress; interrupted after approximately four minutes, including approximately three quiet minutes. The harness was corrected to use `tester.runAsync` for the real filesystem operation. `build/226041-delivery-naming-focused.log`. |
| `test/lesson_naming_226_04_test.dart build/226041_actual_delivery_diagnostic_test.dart` | **7 passed / 0 failed**, 00:32: six naming scenarios plus the read-only actual selected-Course publication diagnosis. This diagnostic is not a substitute for the still-required final persisted-delivery regression. `build/226041-naming-diagnostic-focused.log`. |
| `test/persisted_learner_delivery_226_04_r1_test.dart test/audit_codes_screen_226_02_test.dart test/audit_branch_ownership_226_02_revision4_test.dart test/publication_and_presentation_224_test.dart test/lesson_controls_226_04_test.dart test/lesson_metadata_and_icon_test.dart test/optional_learning_paths_226_04_test.dart test/course_options_226_04_test.dart test/production_course_transaction_225_04_test.dart test/official_course_ui_226_01_test.dart test/exercise_workflow_226_02_test.dart test/course_creation_flags_226_04_test.dart test/app_metadata_225_04_test.dart test/course_audit_report_225_test.dart test/alpha_lifecycle_test.dart` | **173 passed / 1 failed**, 02:49, exit 1. Both persisted-delivery regressions passed. The sole failure expected the old Rounds heading without its Lesson numbering prefix; the stale fixture was corrected. `build/226041-affected-focused.log`. |
| `test/lesson_metadata_and_icon_test.dart test/leaderboard_navigation_test.dart --name 'draft-preserving Round management\|Welcome'` | **3 passed / 0 failed**, 00:24, exit 0: corrected Rounds heading and both welcome palette/metadata/show-once checks. `build/226041-heading-welcome-focused.log`. |
| `test/lesson_naming_226_04_test.dart --name Module` | **1 passed / 0 failed**, 00:09, exit 0 after preserving standalone Lesson-editor labels when no matching Course index exists. `build/226041-module-final-focused.log`. |
| `test/exercise_help_224_test.dart test/exercise_help_search_226_03_r1_test.dart test/exercise_field_help_ui_226_02_test.dart test/course_editor_224_test.dart` | **53 passed / 0 failed**, 01:00, exit 0; Help content/search, contextual fields, existing Editor navigation/Lock/IDs and 320px layout. `build/226041-help-editor-focused.log`. |
| `python -X utf8 tools/validate_courses.py` | **9 bundled Courses valid, 0 failures**. |
| `python -X utf8 tools/regenerate_bundled_courses_225_02.py --check` | **All 9 bundled checksums unchanged**. |
| `python -X utf8 tools/validate_lesson_icons.py` | **14 assets, 0 issues**. |
| `python -X utf8 tools/validate_images.py` | **112 assets, 0 issues**. |
| `build/226041_actual_delivery_diagnostic_test.dart` | **2 passed / 0 failed**, 00:04, exit 0 before production correction. Same selected/raw/decoded/Editor/projected ID; Draft Lesson, absent Editor badge, green Audit, zero learner Lessons. Live file bytes unchanged during the probe. `build/226041-actual-editor-before.log`. |
| `test/draft_container_visibility_226_04_r1_test.dart build/226041_actual_delivery_diagnostic_test.dart` | **7 passed / 3 failed**, 00:10, exit 1. Two new Manager assertions incorrectly assumed a stable-ID card rendered only once (current/local groups may both render it); fixed to inspect every matching card independently. The live probe's old Draft assertion failed because the external Course had since been saved as version 6 with its same Lesson Published (savedAt `2026-09-07T07:04:50.1384640Z`); this is mutable live evidence, not a production regression. `build/226041-container-draft-focused.log`. |
| `test/draft_container_visibility_226_04_r1_test.dart test/persisted_learner_delivery_226_04_r1_test.dart` | **9 passed / 1 failed**, 00:13, exit 1. All eight container-state cases and Published restart case passed. The new raw-storage workflow tapped the selector before the sheet's opening animation completed; added a bounded settle before scrolling/tapping. `build/226041-delivery-correction-focused.log`. |
| `test/persisted_learner_delivery_226_04_r1_test.dart --plain-name 'raw all-green Course'` | **1 passed / 0 failed**, 00:08, exit 0. Raw v6 envelope → decoded same-ID Editor → real Lesson Save → confirmed persistence → selector/Home/restart, with duplicate-title identity isolation and nested no-write assertion. `build/226041-raw-delivery-focused.log`. |
| `test/authoring_hierarchy_indicators_226_02_test.dart test/audit_branch_ownership_226_02_revision4_test.dart test/publication_and_presentation_224_test.dart test/optional_learning_paths_226_04_test.dart test/official_course_ui_226_01_test.dart` | **65 passed / 0 failed**, 00:52, exit 0. Existing live hierarchy, Draft/Audit independence, empty-state, optional-path and official read-only regressions after the shared container-state correction. `build/226041-final-hierarchy-focused.log`. |
| First `flutter analyze --no-pub` | **75 findings**, exit 1, 95.2s: **71 inherited**, one inherited brace-style Info resolved with removal of `ROUND_CONTENT_SHORT`, plus four findings solely in the ignored temporary live-record diagnostic under `build/`. Its source was preserved as `build/226041_actual_delivery_diagnostic_test.dart.txt` after use so it is evidence rather than application analyzer input. No application/test edits, lint suppression or configuration change followed. `226041-analyze.log`, `226041-analyzer-initial-comparison.json`. |
| Verified `flutter analyze --no-pub` | **71 findings**, exit 1 solely for inherited findings: **71 inherited / 0 new / 1 resolved** against parent 72. Counter comparison uses severity, message, normalized path and diagnostic code rather than shifted line positions. The resolved finding is the brace-style Info in the removed short-Round producer. `226041-analyze-final.log` (12.2s) and, after the final Help correction, `226041-analyze-handoff.log` (10.9s), with their comparison JSON files. No suppression or unrelated cleanup. |
| `test/exercise_help_224_test.dart test/exercise_help_search_226_03_r1_test.dart` | **14 passed / 0 failed**, 00:09, exit 0 after final Help wording correction. `226041-final-help-focused.log`. |
| Initial complete-suite launch | Interrupted deliberately after **38 passed, 0 failures**, 00:06 test elapsed, exit 1, when independent review reported stale in-app Help wording. The concrete correction makes Help include own-container Draft states and consistently calls Course delivery Not published. This was not a completed suite and is not passing closure evidence. `226041-full-suite.log`. A fresh full run follows the affected Help check and final analyzer. |
| Final complete Flutter suite | **1,136 passed / 0 failed**, exit 0, **16:51**, with `test --no-pub --concurrency=1 --reporter expanded --timeout 60s`. `build/226041-full-suite-final.log`. No flaky failure appeared. This is the completed final-tree run; the earlier 38-test interrupted launch is recorded separately above. All **245 source/test/config SHA-256 values** matched the snapshot after completion. No production or test file changed after this run. |
| `git diff --check` | Final **exit 0**. The complete intended diff was reviewed for unchanged Course Model v6, persistence, official protections and excluded scope; no revision-2 flag/language or unrelated implementation changes were found. |

Final installed `dart format` covered all **30 changed Dart files**, **0 further changes**, exit 0, after the targeted implementation/test formatting. No dependency or SDK changes were made.

New tests include `course_metadata_wording_226_04_r1_test.dart`, `draft_container_visibility_226_04_r1_test.dart`, `fill_blank_hint_226_04_r1_test.dart` and `persisted_learner_delivery_226_04_r1_test.dart`. Updated tests cover sample counts/languages/IDs/Draft policy/atomic failure, canonical Audit registry and Help search, naming/Preview/restart, publication and affected metadata/UI fixtures. Initial failures above distinguish the corrected production compilation typo from stale fixture assumptions and the real/fake async test-harness boundary.

### Final regression coverage

These are cases from the completed final suite, not additional test commands or summed overlapping development runs. The four new files add 20 cases; affected existing files add 14 cases, giving **34 additional tests** over revision 0's 1,102.

| Test file | Final cases passed |
| --- | ---: |
| `persisted_learner_delivery_226_04_r1_test.dart` | **2** |
| `draft_container_visibility_226_04_r1_test.dart` | **8** |
| `new_course_structure_226_04_test.dart` | **17** |
| `course_metadata_wording_226_04_r1_test.dart` | **3** |
| `lesson_naming_226_04_test.dart` | **6** |
| `fill_blank_hint_226_04_r1_test.dart` | **7** |
| `audit_code_registry_226_02_test.dart` | **16** |
| `audit_codes_screen_226_02_test.dart` | **17** |

### Intended final file inventory

The revision contains **37 intended files: 33 modified tracked files and 4 new test files**. No unrelated/generated files are included. HEAD remains `50a52988872e8d6bb3b7be5e3e261eb2741a60c7`, parent `ef668dd8c0fab070613c5c0dc925619da7d79443`. The final status is reconciled against this inventory before staging. Local `build/` logs and the actual-user diagnostic are excluded.

```text
AGENTS.md
CHANGELOG.md
README.md
docs/226_04_VALIDATION.md
docs/COURSE_EDITOR.md
docs/COURSE_JSON_FORMAT.md
lib/screens/course_editor_screen.dart
lib/screens/course_projects_screen.dart
lib/screens/editor_help_screen.dart
lib/screens/home_screen.dart
lib/screens/round_screen.dart
lib/services/app_metadata.dart
lib/services/audit_code_registry.dart
lib/services/course_audit_service.dart
lib/services/exercise_field_help.dart
lib/services/lesson_presentation_service.dart
lib/services/new_course_structure.dart
lib/widgets/editor_breadcrumbs.dart
pubspec.yaml
test/app_metadata_225_04_test.dart
test/audit_branch_ownership_226_02_revision4_test.dart
test/audit_code_registry_226_02_test.dart
test/audit_codes_screen_226_02_test.dart
test/course_audit_report_225_test.dart
test/course_editor_layout_regression_test.dart
test/course_metadata_wording_226_04_r1_test.dart
test/draft_container_visibility_226_04_r1_test.dart
test/fill_blank_hint_226_04_r1_test.dart
test/leaderboard_navigation_test.dart
test/learner_round_path_test.dart
test/lesson_metadata_and_icon_test.dart
test/lesson_naming_226_04_test.dart
test/new_course_structure_226_04_test.dart
test/official_course_ui_226_01_test.dart
test/persisted_learner_delivery_226_04_r1_test.dart
test/production_course_transaction_225_04_test.dart
test/publication_and_presentation_224_test.dart
```

### Remaining Windows checks and exclusions

- Verify on Windows that an explicitly Draft Lesson/Round is visibly marked even when all children are Published and Audit is green; explicitly Save and confirm a Course, then verify learner delivery after restart. The reported Course is never automatically modified by this correction.
- Native Windows manual checks remain for new-course defaults/custom counts and sample placeholders across language pairs; sample Draft visibility; Course Info Editor versus learner Course Info; Published/Not published confirmation; Module/other numbering in narrow Editor, breadcrumbs and learner layouts after restart; and unsaved/saved Fill in the Blank Hint readability without an answer-revealing Hint.
- Recheck first-run revision-1 popup/show-once behavior and unchanged Alpha expiry, plus the affected official read-only and Draft/Audit presentation on Windows. No native visual verification is claimed.
- **226.04 revision-2 flag/language work has not started.** No Learning language code/BCP 47 UI, flag suggestions/reuse/deduplication or 266-flag registry changes are part of this revision. No Templates, Napoletano, future GuideBook content, release 227, release-228 App Audio Settings/log diagnostics or release-230 generated/saved TTS audio has started. Nothing has been pushed.

### Revision-1 commit boundary

One commit uses **`Correct QQL 226.04 learner delivery and editor behavior`**, with immutable parent **`50a52988872e8d6bb3b7be5e3e261eb2741a60c7`**. It includes only the 37 reviewed files above. The commit hash and final `git status --short` are reported after creation; this document cannot include its own resulting commit hash. No amend, worktree, reset, revert, clean, destructive migration or push was performed. Final automation passed with the explicitly inherited analyzer findings above. Native Windows visual checks remain deferred; no manual visual verification is claimed.

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
