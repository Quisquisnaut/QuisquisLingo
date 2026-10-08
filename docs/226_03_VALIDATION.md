# QQL 226.03 revision 1 — corrective completion

Date: 2026-09-06. Status: **revision-1 implementation and automated validation complete: 1,009 full-suite tests passed, 0 failed; analyzer 72 inherited, 0 new, 0 resolved; all four repository validators passed.** This section records fresh revision-1 evidence. The revision-0 record below remains historical and is not claimed as current validation.

## Baseline and metadata

The existing `main` checkout was clean at `dd2119868dcd2bb79808915bb873e147f1ece560`, parent `f3a743ab52fc0cefa338c937a1d2ba7ecaa364cf`. Baseline metadata was `2.0.26+226030`; its recorded full suite was **940 passed, 0 failed**, with **72 inherited analyzer findings**. No old suite was rerun before implementation. Root AGENTS.md and the code-work skill were read; independent file owners assisted with TTS, Help and tests, and the coordinator runs integrated verification serially. No worktree or destructive recovery was used.

Revision-1 metadata is **Version 2.0.26, Phase 226.03, revision 1, technical build 226031, pubspec 2.0.26+226031**. The existing show-once notice renders `Version 2.0.26` and `Phase 226.03, revision 1`. Alpha expiry remains **2026-10-06 23:59:59 local time**, as explicitly requested; no lifecycle policy or expiry extension is introduced.

## Reported defects, causes and corrections

1. **Nullable reorder operands.** `_reorder` rejected empty expanded phrase parts, conflating absence of source syntax with an optional branch's empty result. Source structure now validates operand presence before expansion; runtime permutations permit nullable operands. A materially absent operand produces `<> requires an expression on both sides.`
2. **Optional linked members.** Optional expansion removed an entire linked member before linkage validation, leaving a rejected singleton and losing the original association. Original group count/cardinality and nonempty source columns are validated first; raw operand validation uses an iterative scope stack, with a 10,000-level nesting regression to prevent recursive stack overflow; derived branches retain column positions and may omit members or contain empty generated columns. All surviving members use the same column index. For optional linked members with inversion, retained normal forms precede omitted normal forms, then inverted forms; legacy ordering outside this newly supported combination is preserved.
3. **Empty final answers and punctuation.** Final whitespace-normalized empty branches are excluded from display, accepted answers and materialization. `{io}{no}` yields `No`, `Io`, `Iono`, never an empty row. The existing no-usable-answer diagnostic remains when no usable answer exists. Terminal punctuation is detached before optional/link/reorder expansion and appended only after nonempty normalization/deduplication. It cannot turn an empty branch into a punctuation-only answer. The **128 intermediate-variant cap is unchanged**, including branches later removed or deduplicated; aggregate materialization still counts distinct accepted answers and rejects overflow atomically. No partial results are persisted.
4. **Lowercase guidance.** The generated-answer field and searchable Exercise Help say exactly **Use lowercase except for proper names.** This is advice, not validation or a data transformation; expressions, proper names, acronyms and established sentence formatting remain intact.
5. **Missing Word complete input.** The former `FirstLetterAnswerService.response` prepended the hinted grapheme to a suffix. Submission now evaluates the complete trimmed word entered, with unchanged authoritative normalization/typo rules, and displays the completed sentence after checking. The sentence retains a full Unicode-grapheme hint. The learner instruction is **Enter the complete missing word. The first letter shown is a hint.** `école` succeeds for `é______`; `cole` does not. Empty Check is disabled even for a one-grapheme answer. Existing complete accepted-answer persistence and Draft/Published behavior are unchanged.
6. **Recognize characters explanations.** The actual Select renderer already uses prompt images with text choices or a text prompt with image choices. Editor and Help now explain each pairing, both directions and valid identifying labels (name/sound/pronunciation/transliteration/other label). The exact one-sentence direction description updates immediately; no exercise semantics or image storage change.
7. **Concrete contextual examples.** How do you say Prompt is the instruction (“How do you say this in Italian?”), while Question is the translated phrase (“Good morning”). In Contextual comprehension, inspection proved **Text is the presentation-mode choice**, not a second independent passage field. **Context text** contains the actual passage and any background. Help accurately uses Marta's daily-routine/train examples without swapping field roles or changing learner rendering. Hover tooltips contain the concrete examples.
8. **Exercise Help search.** A visible top **Search Exercise Help** field immediately filters names, fields, descriptions and examples without regard to case. Clear restores the original list/scroll position; no-match text, keyboard focus/scrolling and narrow light/dark layouts are covered. Audit Code search remains separate. New exercise guidance is included through the shared registry.
9. **What do you hear? audio source.** The existing `Audio text` controller saves the text of the canonical audio prompt element, not a path or a per-exercise recording ID. The new label is **Spoken text**, because this requested utterance drives three actual modes: System TTS sends it to the native engine; Recorded MP3 requires a complete Course Audio Library sequence; Hybrid tries recordings first and falls back to TTS. Inline text describes the current Course mode. Help gives `Buongiorno, come stai?` and the actual workflow: **Course Editor > Audio Library**, files in `Documents/QuisquisLingo/Imports/Audio`, **Import MP3**, **Associate recording > Word or expression**, then Recorded MP3 only or Hybrid. No per-exercise file picker is invented. Recorded-only failures now refer to mappings/files rather than telling the learner to install TTS.
10. **Italian TTS diagnosis.** Custom creation (`course_projects_screen.dart`) stores `ttsLanguage: und` even when learning/target language is Italian; bundled Italian JSON stores `it-IT`. Existing Round/Preview/Duel/TTS settings passed only `ttsLanguage`, causing Windows to seek `und` and misleadingly blame installed voices. Fresh read-only System.Speech enumeration confirmed enabled Elsa/Cosimo `it-IT` voices (and Zira `en-US`). This proves the repository creation-path cause; the user's specific stored custom course was not accessed. One shared resolver now normalizes case and `_`/`-`, preserves a valid explicit locale, and resolves unambiguous legacy learning/target names through the existing language mapping. Exact installed locale wins, then the same complete base language only; English never falls back to Italian. Missing/conflicting metadata has a specific message. Windows already enumerated freshly per request; this remains true, and plugin absence also triggers fresh enumeration. Diagnostics distinguish raw requested metadata, resolved locale and installed voice locales. Stored courses are not rewritten.
11. **JSON import directory.** Import and export formerly shared `transferDirectory()` pointing at Exports. Import now has a separate Imports directory while export retains Exports and the same QuisquisLingo root. Inspection found the existing production workflow reads fixed `import.json` **without a native file chooser**. This supported behavior remains; no unsupported picker is claimed. Tests exercise default document paths and an actual export/copy/import round trip without changing source JSON/MP3 files.

## Exact parser examples confirmed by the user

Every erroneous `[:tu|voi]` in the corrective prompt was explicitly corrected by the user to existing `[*:tu|voi]`; no new follower syntax is implemented. The accidentally truncated expression was clarified before dependent edits.

`come stai <> {tu}`:

```text
Come stai
Come stai tu
Tu come stai
```

`come [*:stai|state] {[*:tu|voi]}`:

```text
Come stai
Come state
Come stai tu
Come state voi
```

`come [*:stai|state] <> {[*:tu|voi]}`:

```text
Come stai tu
Come state voi
Come stai
Come state
Tu come stai
Voi come state
```

Appending `?` to each expression gives the identical ordered list with exactly one terminal `?` on each line, without a preceding space or duplicated question mark. Tests also cover optional first/middle/last members of three linked components, optional column contents, supported nested combinations, forbidden cross-pairings, raw absent operands and unchanged limit/atomicity boundaries.

## Persistence, media and excluded scope

Course Model **v6**, all canonical fields and IDs, 103-rule Audit Registry, authoring transactions, official read-only/licensed forks, Preview no-write behavior, Draft/Published saves, Move/Copy/Rename/reorder, Audit/Draft hierarchy, learner progress and scoring remain unchanged. Physical MP3 storage remains grouped by learning language; Course-owned metadata/reference lists drive matching. Verified Course backups copy and checksum referenced recordings. Course JSON includes metadata/local paths, **not MP3 bytes**; JSON alone and learner data exports do not transfer recordings. No audio storage redesign or course-content modification was made.

The two known revision-4 omissions—Lessons Lock remains a full row, and GuideBook Internal ID is absent—remain untouched and deferred to the 226.04 work touching Lessons/GuideBook. **No 226.04, Custom Exercise Templates, future Use GuideBook switch, GuideBook goals/Further Reading/exercise links, or Napoletano work was started.**

## Fresh commands and results

### Execution method and focused runs

All Flutter checks use the existing installed SDK directly because its ordinary wrapper previously stalled. No dependencies changed; checks use the existing lockfile/package resolution with `--no-pub`, and Flutter commands run serially. The exact PowerShell prefix is:

```powershell
$env:DART_SUPPRESS_ANALYTICS='true'; $env:FLUTTER_SUPPRESS_ANALYTICS='true'; & 'C:\Users\ansa\flutter\bin\cache\dart-sdk\bin\dart.exe' --packages='C:\Users\ansa\flutter\packages\flutter_tools\.dart_tool\package_config.json' 'C:\Users\ansa\flutter\bin\cache\flutter_tools.snapshot'
```

Each test invocation appends `test --no-pub --concurrency=1 --reporter expanded --timeout 60s`, the file/selection arguments below, and `2>&1 | Tee-Object -FilePath build/<log>.log`. Bounded 10-second yields return control; the same process is polled. Format command: the installed `dart.exe format` over the Git-reported modified/untracked Dart files (33 files). Final formatting covered all 33 intended changed Dart files; the last targeted test formatting made no further changes. The final no-write `dart format --output=none --set-exit-if-changed` check returned exit 0: **33 files, 0 changed**.

| Log | Files / selection | Fresh result |
| --- | --- | --- |
| `226031-focused-core` | `parser_nullable_226_03_r1_test.dart answer_engine_test.dart answer_contracts_226_03_test.dart tts_language_resolution_226_03_test.dart tts_platform_boundary_test.dart exercise_help_search_226_03_r1_test.dart script_direction_help_226_03_r1_test.dart audio_import_paths_226_03_r1_test.dart` (all under `test/`) | 88 passed, 2 failed: new TTS test incorrectly expected a map instead of the plugin's String speech argument; new audio test used the wrong package import/const constructor. Test defects, not production failures. |
| `226031-focused-input-paths` | `tts_language_resolution_226_03_test.dart audio_import_paths_226_03_r1_test.dart first_letter_226_03_test.dart app_metadata_225_04_test.dart alpha_lifecycle_test.dart course_audit_report_225_test.dart` | 34 passed, 6 failed: TTS assertion had not yet been corrected; five Missing Word tests tapped before the text-change frame enabled Check. Corrected with explicit pump/enabled assertions; full-input production behavior retained. Audio/path tests: 6/6; metadata 2/2; Alpha 3/3; Audit report 7/7. |
| `226031-focused-regression` | `field_guidance_226_03_r1_test.dart exercise_field_help_226_02_test.dart exercise_field_help_ui_226_02_test.dart exercise_help_224_test.dart translation_ui_226_03_test.dart script_recognition_226_03_test.dart official_new_presets_226_03_test.dart portable_exercise_image_226_03_test.dart exercise_workflow_226_02_test.dart course_authoring_transfer_226_02_test.dart course_transfer_v6_225_02_test.dart course_editor_transaction_225_04_test.dart production_course_transaction_225_04_test.dart recorded_audio_service_test.dart text_entry_submission_test.dart audit_code_registry_226_02_test.dart` | 222 passed, 4 failed: one Help test assumed a single Scrollable before search was added; three corrupt-image tests tapped offscreen controls after longer direction guidance. Fixtures corrected without weakening image/no-write checks. |
| `226031-focused-corrections` | `parser_nullable_226_03_r1_test.dart answer_engine_test.dart answer_contracts_226_03_test.dart first_letter_226_03_test.dart tts_language_resolution_226_03_test.dart field_guidance_226_03_r1_test.dart` | **92 passed, 0 failed**, including 10,000-level bounded parser validation, all exact confirmed nullable/punctuation orders, full-word/Unicode/Preview/Save, TTS and concrete guidance. |
| `226031-focused-layout-fixes` | `exercise_help_224_test.dart script_recognition_226_03_test.dart --name 'Help renders every preset|corrupt embedded character image'` | 1 passed, 3 failed: Help corrected; image fixtures needed lazy-child discovery before ensureVisible. |
| `226031-focused-corrupt-images` | `script_recognition_226_03_test.dart --plain-name 'corrupt embedded character image'` | **3 passed, 0 failed** after bounded discovery/layout/hit-test correction. |
| `226031-focused-tts-final` | `tts_language_resolution_226_03_test.dart` | **10 passed, 0 failed** after final formatting/braces. |
| `226031-focused-tts-lint-fix` | `tts_language_resolution_226_03_test.dart` | **10 passed, 0 failed** after correcting relative-import and brace findings in the test. |

The original Help purpose/example fixtures encoded old wording and were updated to the requested concrete meanings. These are distinguished from the actual parser and Missing Word production corrections. Expected mocked CrashLogService/path-provider diagnostics appear in widget logs and are not test failures. No focused groups were rerun merely to inflate totals.

### Independent validators

- `python tools/validate_courses.py`: exit 0, **9 bundled Course Model v6 files valid**.
- `python tools/regenerate_bundled_courses_225_02.py --check`: exit 0, **all nine generator/checksum records verified**. Its output correctly refers to unchanged bundled-content revision 226.02r3; content has not been regenerated or renamed in revision 1.
- `python tools/validate_lesson_icons.py`: exit 0, **14 assets, 0 issues**.
- `python tools/validate_images.py`: exit 0, **112 assets, 0 issues**.
- `git diff --check`: **passed, exit 0**, including final documentation closure.

### Exact intended changed-file inventory

- `lib/services/tts_language_resolver.dart`
- `test/audio_import_paths_226_03_r1_test.dart`
- `test/exercise_help_search_226_03_r1_test.dart`
- `test/field_guidance_226_03_r1_test.dart`
- `test/parser_nullable_226_03_r1_test.dart`
- `test/script_direction_help_226_03_r1_test.dart`
- `test/tts_language_resolution_226_03_test.dart`
- `CHANGELOG.md`
- `README.md`
- `docs/226_03_VALIDATION.md`
- `docs/AUDIO_LIBRARY.md`
- `docs/COURSE_EDITOR.md`
- `docs/COURSE_JSON_FORMAT.md`
- `lib/models/exercise_authoring.dart`
- `lib/screens/course_editor_screen.dart`
- `lib/screens/course_projects_screen.dart`
- `lib/screens/duel_screen.dart`
- `lib/screens/editor_help_screen.dart`
- `lib/screens/round_screen.dart`
- `lib/screens/tts_settings_screen.dart`
- `lib/services/answer_engine.dart`
- `lib/services/app_metadata.dart`
- `lib/services/custom_course_transfer_service.dart`
- `lib/services/exercise_copy_service.dart`
- `lib/services/exercise_field_help.dart`
- `lib/services/first_letter_answer_service.dart`
- `lib/services/tts_cache_service.dart`
- `lib/services/tts_windows_backend_io.dart`
- `lib/services/tts_windows_backend_stub.dart`
- `lib/widgets/script_recognition_editor.dart`
- `pubspec.yaml`
- `test/app_metadata_225_04_test.dart`
- `test/course_audit_report_225_test.dart`
- `test/exercise_field_help_226_02_test.dart`
- `test/exercise_field_help_ui_226_02_test.dart`
- `test/exercise_help_224_test.dart`
- `test/first_letter_226_03_test.dart`
- `test/leaderboard_navigation_test.dart`
- `test/learner_round_path_test.dart`
- `test/script_recognition_226_03_test.dart`

### Analyzer and complete suite

The first `analyze --no-pub` invocation (`226031-analyze-final.log`) returned exit 1 with **76 findings**: 72 inherited and four new style findings in the TTS test (three relative-lib imports and one brace). Those four findings were corrected, the affected test passed 10/10, and a necessary analyzer rerun (`226031-analyze-verified.log`) returned exit 1 with **72 findings: 72 inherited, 0 new, 0 resolved**. No lint suppression or unrelated cleanup was used.

A Python Counter comparison of the revision-0 recorded `build/22603-analyze-final.log` and current log retains severity, message, file and code while ignoring shifted line/column positions; result is saved in `build/226031-analyzer-comparison.json`. The inherited set is 71 brace-style Infos (67 Course Audit service, three flat-image library, one Settings service) and one unused `_tapAndSettle` warning in `test/guidebook_sentence_generator_test.dart`. Baseline source/results were not reconstructed in a worktree. Analyzer exit 1 is explicitly reported; the repository is not claimed lint-clean.

The complete suite ran **once** on the final source/test tree using the same SDK prefix plus `test --no-pub --concurrency=1 --reporter expanded --timeout 60s`, logged through Tee-Object to `build/226031-full-suite.log`: **1,009 passed, 0 failed**, exit **0**, reported duration **11:32**. The documented revision-4 `exercise_workflow_226_02_test.dart` flaky risk did not reappear; its full-run cases passed. No production or test files were changed after this suite.

Six new test files add 65 tests (nullable parser 28, Help search 11, contextual field guidance 7, character direction 3, audio/import paths 6, TTS resolution 10); the existing Missing Word file grows by four tests, giving 69 additional tests over the 940-test baseline. Existing Help, image-gate and metadata fixtures were updated without removing their behavioral assertions.

Final independent review confirmed all 40 intended files, no changes to canonical Course Model/Audit registry/Alpha implementation/bundled assets/dependency lockfile, no unrelated work, and no excluded future features. `git diff --check` passed with exit 0. Only documentation was completed after the full suite. The requested single revision-1 commit follows final status/diff inspection; its hash and final clean status are reported in the handoff.


## Remaining Windows manual checks and risks

- Check generated-answer display/copy/materialization for each exact example, omitted operands and terminal question marks; confirm proper names remain intact.
- Enter a complete Missing Word (including combined Unicode graphemes), reject the suffix alone, and verify completed feedback sentences in learner and unsaved Preview.
- Exercise Help search/clear/no-results, keyboard focus and scrolling, hover examples and long/narrow light/dark layouts.
- Both Recognize characters directions and explanatory text, explicit images and Preview.
- What do you hear? Spoken text and effective System TTS/Recorded/Hybrid source; real MP3 import, association, replay, missing-file diagnostics and verified backup restore. Native speech playback itself has not been manually verified by this task.
- Reopen the user's specific custom Italian course and test Elsa/Cosimo playback against bundled Italian; examine raw/resolved language and installed-voice diagnostics if it fails. Specific user storage was not inspected or modified.
- Import JSON from Imports/import.json and export into Exports; retain source files and existing collision/official-course decisions.
- First-run revision-1 popup, light/dark appearance, show-once persistence and unchanged Alpha expiry.

---

## Historical 226.03 revision 0 record

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
