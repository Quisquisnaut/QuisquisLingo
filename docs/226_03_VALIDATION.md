# QQL 226.03 validation — writing and character recognition

Date: 2026-09-06. Status: **226.03 implementation complete. The single final complete-suite run passed 940 tests with no failures; focused corrections and all validators pass. Analyzer retains 72 inherited findings, with no new or resolved findings.** Remaining Windows manual checks are listed below.

## Scope, baseline and metadata

The existing `main` checkout was clean at `f3a743ab52fc0cefa338c937a1d2ba7ecaa364cf` before edits. This immutable parent is the completed 226.02 revision-4 baseline. Its **851 passed / 1 failed** complete suite and subsequent **28/28** isolated `exercise_workflow_226_02_test.dart` run remain historical evidence and a documented non-reproduced baseline risk, not a green full suite. No worktree, reset, clean, discard, amend or baseline reconstruction was used.

The user explicitly authorized only sections 25–41 of the complete `qql_226_prompt.txt` (226.03, lines 891–1328), using the existing parser/normalization/similarity contracts. The attached document supplies the functional specification; current user instructions govern workflow and commit authorization. Root AGENTS.md and the code-work skill were inspected before changes.

Final metadata target: **Version 2.0.26; Phase 226.03; revision 0; technical build 226030; pubspec 2.0.26+226030**. The six-digit technical sequence remains monotonic after 226024; the human phase stays 226.03. Existing show-once revision notice behavior is retained. Alpha expiry remains **2026-10-06 23:59:59 local time**: September 6 plus the existing 30-day convention gives the same date, so no new policy or extension is introduced.

## Implemented contracts and repository evidence

1. Translation feedback expands all authored answers through `AnswerExpressionParser`, deduplicates with `AnswerEngine` normalization and ranks using its existing `_correctionScore`. Wrong responses show 1/2/3 answers or the best 3 with **Some possible translations:** when more exist. Correct responses show at most 2 alternatives, exclude the canonical answer returned by evaluation (also after typo tolerance), and omit empty sections. Stable original index resolves score ties. Ranking does not participate in correctness; normalization, conservative repeated-letter tolerance and `evaluate` remain authoritative.
2. **Expand answers** is a non-destructive selectable/copyable dialog with **Copy all**. **Use expanded answers** adds independent explicit accepted lines and reports generated/added/already-present counts. Source edits/deletion never synchronize into materialized answers. The entire candidate is validated before a controller mutation or save; overflow never persists a partial list.
3. Parser syntax remains `{optional}`, independent `[a|b]`, position-linked `[*:a|b]` groups with equal counts and at least two groups, scoped `(part <> part)`, and whole-expression `<>`. Existing capitalization/punctuation/order remain intact. Two narrow parser corrections support composition/materialization: variants that omit an optional reorder scope pass through while other variants reorder; aggregate expansion removes identical generated strings before enforcing the combined cap so an expression and its own 128 materialized answers can coexist. Per-expression intermediate expansion remains bounded at 128; no grammar redefinition or truncation is added.
4. **Type the missing word** uses canonical Input/text_match, distinct from legacy `missing_word` audio/transcript and `fill_blank`. Authors enter complete accepted words and a sentence with exactly one `___` gap. The first Unicode grapheme is derived, all alternatives must share it, and the learner types the remainder. The reconstructed complete response goes to normal Input evaluation with supported typo tolerance. The `cappuccino` example displays `c______`; incompatible initials, phrases and invalid gaps receive clear validation. Single-grapheme answers permit an empty remainder.
5. **Recognize characters** uses canonical Select/selected_items. Image to text accepts 1+ prompt images, 2+ text options, exactly 1 correct option. Text to image accepts a nonempty text prompt, 2+ image options, exactly 1 correct option. Mode, prompt media, stable options and correct IDs are inspected/edited through dedicated controls with contextual Help. Multiple fonts/handwriting images are supported. The existing learner choice engine renders these images; wrong feedback identifies the correct image or text.
6. Imported character images preserve exact PNG/JPEG/WEBP bytes in existing media asset strings, capped at 50 KB and 4096 pixels per dimension. Synchronous bounded container/dimension validation supports canonical Audit; asynchronous actual decoding gates import, Save and Preview. Absolute/traversal/remote paths and malformed image streams are rejected. Safe bundled references remain supported. The picker is explicitly read-only for this workflow; its pre-existing mutable default is preserved elsewhere. Import reads the transfer source without writing a managed file, and no source path is serialized.

## Persistence and preservation

Course Model **v6 remains unchanged**, with no added schema fields or migration. New templates reuse canonical prompt, interaction and evaluation objects. Translation materialization remains ordinary `acceptedAnswers`; Missing Word stores complete words; Script mode derives from the canonical prompt/option media. Round-trip tests cover both new presets, Draft/Published state, complete metadata and original image bytes. Existing defaults and rejected malformed/legacy fields remain explicit. Stable IDs, timestamps, prompt roles/speaker/media, feedback and unrelated evaluation metadata survive edits; script option removal/addition does not reuse removed IDs.

Official bundled/external courses still route to inspection and no-write Preview, with no new authoring/media/expansion controls. Custom-course Save remains within the existing working-copy transaction. Preview, Draft/Published behavior, Move/Copy/Rename/reorder/navigation, learner progress, licensing and provenance remain intact. Audit reuses existing applicable codes and retains **103 rules**. Bundled JSON/assets are not intentionally changed.

The known revision-4 Lessons Lock full row and absent GuideBook Internal ID are deliberately untouched. No 226.04, future Use GuideBook switch, GuideBook goals/Further Reading/exercise links, Custom Exercise Templates or Napoletano implementation was started.

## Tests and execution record

New behavioral coverage lives in `answer_contracts_226_03_test.dart`, `translation_ui_226_03_test.dart`, `first_letter_226_03_test.dart`, `portable_exercise_image_226_03_test.dart`, `script_recognition_226_03_test.dart` and `official_new_presets_226_03_test.dart`. It covers parser combinations/order/dedup/limits, atomic materialization and independent persistence, ranking ties/extra/missing/near/diacritic cases, acceptance independence, feedback counts in both themes at 320 px, first-grapheme reconstruction, Editor Save/reload/Preview, portable images, malformed input and official read-only entry.

The ordinary `flutter` wrapper produced no output or Dart process for approximately 30 seconds and was interrupted. The replacement invokes the same installed SDK directly with bounded 10-second output yields, polling the existing process:

```powershell
$env:DART_SUPPRESS_ANALYTICS='true'
$env:FLUTTER_SUPPRESS_ANALYTICS='true'
& 'C:\Users\ansa\flutter\bin\cache\dart-sdk\bin\dart.exe' --packages='C:\Users\ansa\flutter\packages\flutter_tools\.dart_tool\package_config.json' 'C:\Users\ansa\flutter\bin\cache\flutter_tools.snapshot' <arguments below>
```

SDK cache access required sandbox approval. No SDK installation or worktree was used. Test logs are retained under ignored `build/22603-*.log`; tests deliberately mock unavailable native storage/audio and some expected crash-logger diagnostics are noisy without being test failures.

Implementation runs (not cumulative totals or final-suite substitutes):

- `test --no-pub --reporter expanded --timeout 60s test/answer_engine_test.dart test/answer_contracts_226_03_test.dart test/portable_exercise_image_226_03_test.dart`: **43 passed, exit 0** before the final portable/parser additions.
- First Missing Word/architecture attempt: **5 passed / 1 load failure**, a missing required fixture language corrected; subsequent Missing Word UI failures came from offscreen Save and the exact Draft confirmation label. The final writing-UI combined run passed all **8 Missing Word** tests.
- Initial translation/Missing Word combined run: **22 passed / 6 failed**; isolated diagnosis **1 passed / 5 failed**. These new harness fixtures needed bounded scrolling, real rendered-frame alignment, snackbar timing and audio mocks. Their behavioral assertions were retained.
- A later four-file run passed **29 parser/portable tests** but two widget files failed to load because the new image gate referenced `promptData` instead of canonical `promptElements`; that production compile error was corrected before subsequent runs.
- `test --no-pub --reporter expanded --timeout 60s test/translation_ui_226_03_test.dart test/first_letter_226_03_test.dart`: **24 passed / 4 failed**. The remaining four were lazy-field visibility/tap harness failures. After correction, `test --no-pub --reporter expanded --timeout 60s test/translation_ui_226_03_test.dart --name "Expand and Copy|materialized answers survive|overflow offers"`: **4 passed, exit 0**.
- Initial `script_recognition_226_03_test.dart`: **18 passed, exit 0**. Added corrupt-image Save/Preview cases then passed **3/3** with `--name "official|corrupt embedded"`; the lowercase filter did not select the separate official-course file, so those six cases are run explicitly in the affected set.

### Final focused, analyzer, suite and validators

Focused results (fresh runs in this tranche; overlapping runs are not added into a cumulative total):

| Scope / log | Exact result | Correction or interpretation |
| --- | --- | --- |
| 25-file affected existing set, `22603-existing-focus.log` | 328 passed / 4 failed, exit 1, 3m45s | Two Help inventories needed new presets; the inserted presets displaced the original first Help entry; one 320 px fixture tapped below the visible viewport. The original first-preset ordering was restored, field Help completed, and the fixture scrolled to its existing menu. |
| `exercise_help_224_test.dart` and `exercise_responsive_224_test.dart`, `--name "Help renders\|320 logical"` | 2 passed, exit 0 | Exact affected Help/responsive cases after correction. The Lock control itself was not changed. |
| Eight-file final 226.03 + field-Help set, `22603-final-focus.log` | 124 passed / 10 failed, exit 1, 1m36s | All ten failures were in Script fixtures after adding the asynchronous image gate and direct Help: native decode futures needed bounded real-event-loop waits; dialog-title assertions included the underlying field label. All translation, Missing Word, image-service, official and legacy field-Help cases passed. |
| Script + text-entry follow-up, `22603-script-and-entry-final.log` | 30 passed / 4 failed, exit 1, 24s | Script Save and Help passed. Remaining Preview fixtures needed audio mocks and completion of the route animation before counting visible images. The existing text-entry fixture now asserts both ranked translations and the nearest first, matching the changed specification. |
| Script `--name "editor and learner Preview"`, `22603-script-preview-final.log` | 4 passed, exit 0, 8s | Real decoder completion, no unexpected image error dialog, and exactly two learner images verified in each mode/theme. |
| Script + portable images + localized copy after analyzer corrections, `22603-analyzer-corrections-focus.log` | 36 passed, exit 0, 20s | All 23 Script tests, 10 portable-image tests and 3 existing learner-copy tests passed on final production code. |

All **87 new tests** (19 parser/materialization/ranking, 21 translation UI, 8 Missing Word, 10 portable-image, 23 Script, 6 official-course) passed in their relevant focused runs after the documented corrections. The existing Help suite adds one Missing Word field-control case; Script direct controls are verified by dedicated dynamic per-option tests. No assertions were removed to hide a production failure. The known revision-4 `unsaved listening_spelling Preview preserves PublicationState.published, timestamps, JSON and preferences` case passed in the affected 28-case workflow file.

Formatting: all 31 then-changed Dart files formatted; the first pass completed its writes but exited 1 on sandbox-denied Dart telemetry. An approved `dart format --output=none --set-exit-if-changed` then reported **31 files, 0 changed, exit 0**. Subsequently corrected fixtures and four analyzer-affected production files were formatted before their focused reruns. Dependencies were not changed or re-resolved; `--no-pub` uses the existing baseline package resolution.

Initial analyzer: **83 findings, exit 1, 98.2s**. The recorded baseline has **72**. The 11 new findings comprised four post-await context checks, six brace-style infos (including two exposed by formatting existing compact copy branches) and one deprecated dropdown `value` argument. All were corrected without suppressions. The long quiet phase was checked directly: the actual Dart language-server process increased CPU time and memory, so it was allowed to finish. Final analyzer comparison is recorded below.

Validators (fresh, exit 0 each):

- `python tools/validate_courses.py`: **9 bundled Course Model v6 files validated**.
- `python tools/regenerate_bundled_courses_225_02.py --check`: **all 9 generated files and SHA-256 hashes verified**. Their release metadata correctly remains 226.02 revision 3 because bundled content has not changed.
- `python tools/validate_lesson_icons.py`: **14 assets, 0 issues**.
- `python tools/validate_images.py`: **112 Image Bank assets, 0 issues**.

Final analyzer: `analyze --no-pub` → **72 findings, exit 1, 10.7s**. Against the validated revision-4 baseline: **inherited 72, new 0, resolved 0**. This is not an analyzer pass. The set remains 71 brace-style infos (67 Audit service, 3 Image Bank screen, 1 Settings service) and the existing unused `_tapAndSettle` warning at `test/guidebook_sentence_generator_test.dart:255`. Comparison used severity/message/path/code multisets with line shifts ignored, the retained 72-finding log and revision-4's authoritative validation record; inspection confirms the corresponding baseline code remains. No worktree or copied baseline was needed. The machine-readable comparison is retained at ignored `build/22603-analyzer-comparison.json`.

Complete Flutter suite: `test --no-pub --concurrency=1 --reporter expanded --timeout 60s` → **940 passed, 0 failed, exit 0, 10m23s**, executed exactly once on final production/test content. The known revision-4 listening-spelling Published Preview failure **did not reappear**; its case and the entire workflow file passed in this complete run. This does not rewrite revision 4's historical 851/1 result or claim that its intermittent risk has been permanently eliminated.

Final read-only formatting verification: **32 Dart files, 0 changed, exit 0**. `git diff --check`: **exit 0, no output**. Final review covered the complete intended diff, including new files and shared field Help, canonical-object/image preservation, normalization/ranking separation and authoring gates. No production or test file changed after the complete suite. Only this validation record was finalized afterward.

The final intended change is suitable for the user-authorized single 226.03 commit on parent `f3a743ab52fc0cefa338c937a1d2ba7ecaa364cf`. The index was empty before intended-file staging. No revision-4 amendment, worktree, push or package/release was performed.

Exact focused file sets (all commands use the direct SDK entry above):

```text
test --no-pub --concurrency=1 --reporter expanded --timeout 60s test/official_new_presets_226_03_test.dart test/answer_engine_test.dart test/exercise_architecture_224_test.dart test/exercise_creation_planner_test.dart test/exercise_creation_wizard_test.dart test/exercise_help_224_test.dart test/exercise_field_help_226_02_test.dart test/exercise_field_help_ui_226_02_test.dart test/exercise_copy_service_test.dart test/exercise_workflow_226_02_test.dart test/exercise_responsive_224_test.dart test/exercise_dark_mode_225_02_test.dart test/course_model_v6_test.dart test/course_audit_test.dart test/course_audit_225_02_test.dart test/audit_code_registry_226_02_test.dart test/course_official_provenance_225_04_test.dart test/official_course_ui_226_01_test.dart test/official_course_storage_226_01_test.dart test/course_authoring_transfer_226_02_test.dart test/app_metadata_225_04_test.dart test/alpha_lifecycle_test.dart test/course_audit_report_225_test.dart test/learner_round_path_test.dart test/leaderboard_navigation_test.dart
test --no-pub --reporter expanded --timeout 60s test/exercise_help_224_test.dart test/exercise_responsive_224_test.dart --name "Help renders|320 logical"
test --no-pub --concurrency=1 --reporter expanded --timeout 60s test/answer_contracts_226_03_test.dart test/translation_ui_226_03_test.dart test/first_letter_226_03_test.dart test/portable_exercise_image_226_03_test.dart test/script_recognition_226_03_test.dart test/official_new_presets_226_03_test.dart test/exercise_field_help_226_02_test.dart test/exercise_field_help_ui_226_02_test.dart
test --no-pub --concurrency=1 --reporter expanded --timeout 60s test/script_recognition_226_03_test.dart test/text_entry_submission_test.dart
test --no-pub --reporter expanded --timeout 60s test/script_recognition_226_03_test.dart --name "editor and learner Preview"
test --no-pub --concurrency=1 --reporter expanded --timeout 60s test/script_recognition_226_03_test.dart test/portable_exercise_image_226_03_test.dart test/exercise_copy_service_test.dart
analyze --no-pub
test --no-pub --concurrency=1 --reporter expanded --timeout 60s
```

### Changed files

The intended diff contains 39 files:

```text
AGENTS.md
CHANGELOG.md
README.md
docs/226_03_VALIDATION.md
docs/COURSE_EDITOR.md
docs/COURSE_JSON_FORMAT.md
lib/models/course_models.dart
lib/models/exercise_authoring.dart
lib/screens/course_editor_screen.dart
lib/screens/editor_help_screen.dart
lib/screens/flat_image_library_screen.dart
lib/screens/round_screen.dart
lib/services/alpha_lifecycle_service.dart
lib/services/answer_engine.dart
lib/services/answer_materialization_service.dart
lib/services/app_metadata.dart
lib/services/course_audit_service.dart
lib/services/exercise_copy_service.dart
lib/services/exercise_field_help.dart
lib/services/first_letter_answer_service.dart
lib/services/portable_exercise_image.dart
lib/widgets/portable_exercise_image.dart
lib/widgets/script_recognition_editor.dart
pubspec.yaml
test/alpha_lifecycle_test.dart
test/answer_contracts_226_03_test.dart
test/app_metadata_225_04_test.dart
test/course_audit_report_225_test.dart
test/exercise_field_help_226_02_test.dart
test/exercise_field_help_ui_226_02_test.dart
test/exercise_responsive_224_test.dart
test/first_letter_226_03_test.dart
test/leaderboard_navigation_test.dart
test/learner_round_path_test.dart
test/official_new_presets_226_03_test.dart
test/portable_exercise_image_226_03_test.dart
test/script_recognition_226_03_test.dart
test/text_entry_submission_test.dart
test/translation_ui_226_03_test.dart
```

Formatter-only layout changes occur in previously compact sections of the changed Dart files, especially the localized exercise-copy table. No generated registrants, dependency lock/configuration changes, bundled JSON edits or new image assets are included.

## Remaining manual Windows checks and risks

- Translation expansion selection, copy/Copy all, generated counts and independent editing/deletion at desktop and narrow widths.
- Wrong feedback 1/2/3/>3 and correct feedback 0/1/2+ alternatives, typo/diacritic diagnostics and actual keyboard/IME behavior.
- Missing Word revealed grapheme and remainder input across supported scripts, Enter submission, single-grapheme words and compatible/incompatible initials.
- Both Recognize characters modes, multiple prompt images, correct/wrong feedback, image import from the transfer folder, copy/export/import after removing the source, and native image-picker navigation.
- Both themes, narrow windows, keyboard focus, scrolling, Help and meaningful image size/contrast with real character artwork.
- Draft/Published save, guarded navigation, no-write Preview and official read-only inspection with real persisted courses.
- Version 2.0.26 / Phase 226.03 revision 0 popup appearance and show-once behavior; unchanged Alpha expiry.

No manual visual/native verification is claimed. The 72 inherited analyzer findings remain. The documented revision-4 intermittent failure did not reproduce in either the affected workflow run or the final complete suite. Native imports, keyboard/IME, platform audio and real-window visual checks still require the manual pass above.
