# QuisquisLingo 2.0.24+224 release validation report

Date: 3 September 2026

## Release boundary

- Version: `2.0.24+224`.
- Mandatory 30-day Alpha expiry: end of 3 October 2026.
- Canonical course format remains Course Model v5: `Course -> Lesson -> GuideBook + Round + Duel -> Content/Exercise`.
- Scope: the complete build-224 authoring specification, including the existing exercise-architecture consolidation plus three-Round audit guidance, scoped Audit, custom-Course actions, Buy a Coffee metadata, Draft/Published state, unsaved-change protection, learner Lesson presentation options, linked answer groups, structured correction feedback, managed custom Lesson icons, validation, documentation, and Windows packaging.
- XP, Weekly XP, streak, Review, Duel rules and eligibility, progression, IDDQD, learner identity, backups, flags, TTS, audio, and established course identity/persistence behavior remain unchanged.

## Read-only audit and architecture decisions

- The read-only audit completed before implementation and found no material conflict with the specification. The repository contained 17 exercise types and already used Course Model v5 throughout the bundled course set.
- Final authoring comprises 20 friendly presets grouped as Multiple choice, Translation, Text input, Matching, Ordering, and Presentation. Each preset maps to one of five canonical models: Select, Input, Arrange, Match, or Presentation. Speech remains a deliberate future model.
- Existing v5 exercise IDs, item IDs, references, answer semantics, seven-type Duel eligibility, and non-scored presentation behavior are preserved. The new publication and Lesson-presentation fields are a clean cut: canonical JSON must provide them, with no aliases or missing-field fallback.
- Contextual comprehension stores the question separately from text, audio, optional image, and structured speaker-labelled dialogue context. Text, audio, and text-and-audio modes are explicit.
- Ordered Round content remains the canonical Story-capable composition mechanism. No source-specific Story runtime type or external taxonomy was added.
- Imported source formats must normalize to a small import-only representation before canonical v5 `Exercise` creation. Source names and fields do not enter runtime or editor semantics. No complete production importer was added in this release.
- The complete inventory, canonical mappings, evidence, compatibility decisions, and interoperability matrix are recorded in `docs/EXERCISE_ARCHITECTURE_224.md`.

## Editor, answer engine, and validation

- Course Audit now uses Error, Warning, and non-blocking Info severities, reports fewer than three Rounds and missing Listening comprehension as Info, supports Lesson or friendly Exercise-type sorting, and can run at Course, Lesson, or Round scope. Only Rounds with blocking Errors receive the live pink authoring outline.
- My custom courses exposes Edit, Rename, Duplicate, Audit, Save/Publish state, Export, and the established protected Delete flow. Course duplication assigns fresh recursive IDs and deterministic copy names.
- Optional `buyACoffeeUrl` metadata is trimmed and restricted to HTTPS. It round-trips through Course JSON and appears as `Buy a Coffee` in Course Info only when present; no payment handling was introduced.
- Course, Lesson, Round, and Exercise use explicit Draft/Published state. Parent saves never publish Draft descendants; one learner projection enforces ancestor visibility and removes Draft content from navigation, execution, completion, Review, Duel, and XP while retaining it for editor preview and audit. Imports, duplicates, Wizard output, and approved GuideBook generation enter authoring as Draft with stable or fresh IDs as appropriate.
- Course, Lesson, Round, Exercise, Wizard, and generator editing use the shared exact unsaved-changes confirmation. Successful draft/publish saves clear dirty state, while independent nested editor changes are returned only through their established save boundary.
- Course authors can choose Lesson, Unit, Topic, Module, Skill, Chapter, Stage, Step, Part, custom, number-only, or no learner numbering. Published Lesson order is authoritative, untouched default `Lesson N` titles are de-duplicated presentation-only, and fallback icons are either monochrome or deterministic colored Lesson numbers in the same 84 x 84 footprint.
- Lesson theme icons may be preinstalled or imported from one PNG/JPG/JPEG/WebP. Imports are decoded within safety limits and contained into a transparent 256 x 256 PNG stored in the Course-owned managed registry; arbitrary external paths are rejected, and JSON export/import plus Course duplication preserve portable assets and references.
- The Course Editor main page now uses a compact Lessons navigation row. The linked Lesson-management subpage owns create, edit, delete, reorder, Round access, and the top-positioned Lock control while preserving the same draft `Course`, stable IDs, metadata, and save boundary.
- Lesson and Round menus provide Edit, Rename, Delete, Duplicate, and Preview. Exercise menus provide Edit and Duplicate. Rename preserves identity, while duplication recursively replaces owned IDs and remaps internal references without changing external assets or references.
- The exercise picker is grouped, searchable, and registry-driven. Author-facing Help covers every preset without exposing external product/source names.
- New authoring support includes Type the translation, Build the translation, and Contextual comprehension. Relevant fields only are shown, and Course Audit blocks errors while allowing an explicit warning override.
- Answer expressions support `{optional}`, `[a|b|c]`, scoped or whole-expression `<>` reorder groups, and two-or-more equal-cardinality `*:` linked groups. Linked groups expand by index without a cross product, compose with the existing syntax, remain deterministic and duplicate-free, and share the 128-variant safety cap.
- Acceptance and correction are separate. Structured evaluator output records the matched accepted answer, acceptance reason, and only the differences actually used. Evaluated text feedback always shows the deterministic closest correct answer for correct and incorrect submissions; normalization, missing-diacritic tolerance, bounded typo tolerance, and author-order tie-breaking never change the selected acceptance policy.
- The registry-backed Exercise Creation Wizard plans an exact configurable count using Balanced, seeded Random, category, selected-type, or repeat-pattern criteria; normal editing and preview are sequential, and cancellation returns only explicitly saved valid work.
- The GuideBook generator defaults to 6 Rounds of 8 exercises, supports 1-12 Rounds and 1-15 exercises, produces an inspectable no-object plan and editable drafts, normalizes progressive difficulty from 0.0 to 1.0, uses GuideBook-grounded preset pools and descriptive titles, and appends only after explicit approval with fresh recursive IDs.
- Responsive coverage includes 320, 375, and 430 logical px phone widths plus a 1100 px desktop layout for Audit controls, menus, dialogs, Draft controls, icon pickers, editor/Help surfaces, learner exercise feedback, the Exercise Creation Wizard, and the GuideBook generator.

## Automated validation

- `flutter pub get` passed; 28 newer package versions are incompatible with the current dependency constraints and were not adopted.
- Focused verification passed for Fill-in-the-blank validation, all Audit scopes and borders, custom-Course actions, Buy a Coffee, Draft/Published projection, unsaved changes, Lesson numbering and icons, linked answer parsing, structured correction feedback, the Wizard, the GuideBook generator, and 320/375/430/1100 px layouts.
- Final full suite: `flutter test --no-pub --reporter expanded --timeout 60s` passed **492 tests** in **3 minutes 57 seconds**.
- `flutter analyze --no-pub`: **0 errors and 0 warnings**. It reports **79** info-only `curly_braces_in_flow_control_structures` notices; none were suppressed or broadly cleaned up.
- `python tools\validate_courses.py`: all **8** bundled v5 courses passed.
- `python tools\validate_lesson_icons.py`: **14 assets, 0 issues**.
- `python tools\validate_images.py`: **113 assets, 1 issue**, solely the pre-existing missing `assets/exercise_images/hello.webp`. It is unrelated to build 224 and remains deliberately unchanged.
- `git diff --check` passed. The author-facing taxonomy scan found external interoperability names only in the engineering matrix.
- Widget-test crash-log messages are the expected persistent-storage fallback in the test environment and did not cause failures.

## Windows release artifact

- `tools\package_windows_release.ps1` completed the Windows release build, copied the required VC runtime, validated staged contents, extracted the ZIP, and matched the extracted files against staging.
- Staged directory: `build/packages/quisquislingo_alpha_224_dev_windows_x64/`.
- ZIP: `build/packages/quisquislingo_alpha_224_dev_windows_x64.zip`.
- ZIP size: **25,995,310 bytes**.
- ZIP SHA-256: `906C199C27057A7A8E9D877994B5D32605C268B777F05E5E33B7D9026862A521`.
- The build 223 staged directory and ZIP remain present as rollback copies.

## Deferred and unsupported boundaries

- `PickOneAudio` remains unsupported because its source semantics are not sufficiently known to choose a lossless canonical mapping.
- Speaking, repeat, and spoken-response exercises remain unsupported pending the future Speech model.
- Full external Story authoring is intentionally deferred; ordered canonical Round content supports presentation-plus-exercise composition without a lossy runtime type.
- The target-machine checks in `docs/WINDOWS_RELEASE_TEST.md` remain the user's final visual, audio, and hardware validation boundary.
