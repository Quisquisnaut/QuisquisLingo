# QuisquisLingo 2.0.24+224 release validation report

Date: 3 September 2026

## Release boundary

- Version: `2.0.24+224`.
- Mandatory 30-day Alpha expiry: end of 3 October 2026.
- Canonical course format remains Course Model v5: `Course -> Lesson -> GuideBook + Round + Duel -> Content/Exercise`.
- Scope: the exercise architecture and authoring-system consolidation specified for build 224, including the dedicated Lesson manager, canonical interaction models, new authoring presets, contextual comprehension, answer-expression engine, import normalization boundary, registry-backed Help, validation, documentation, and Windows package.
- XP, Weekly XP, streak, Review, Duel rules and eligibility, progression, IDDQD, learner identity, backups, flags, TTS, audio, and established course identity/persistence behavior remain unchanged.

## Read-only audit and architecture decisions

- The audit completed before implementation and found no material conflict with the specification. The repository contained 17 exercise types and already used Course Model v5 throughout the bundled course set.
- Final authoring comprises 20 friendly presets grouped as Multiple choice, Translation, Text input, Matching, Ordering, and Presentation. Each preset maps to one of five canonical models: Select, Input, Arrange, Match, or Presentation. Speech remains a deliberate future model.
- Existing v5 exercise IDs, item IDs, references, answer semantics, seven-type Duel eligibility, and non-scored presentation behavior are preserved. Older v5 editor-template aliases fall back to the authoritative runtime type rather than becoming a migration layer.
- Contextual comprehension stores the question separately from text, audio, optional image, and structured speaker-labelled dialogue context. Text, audio, and text-and-audio modes are explicit.
- Ordered Round content remains the canonical Story-capable composition mechanism. No source-specific Story runtime type or external taxonomy was added.
- Imported source formats must normalize to a small import-only representation before canonical v5 `Exercise` creation. Source names and fields do not enter runtime or editor semantics. No complete production importer was added in this release.
- The complete inventory, canonical mappings, evidence, compatibility decisions, and interoperability matrix are recorded in `docs/EXERCISE_ARCHITECTURE_224.md`.

## Editor, answer engine, and validation

- The Course Editor main page now uses a compact Lessons navigation row. The linked Lesson-management subpage owns create, edit, delete, reorder, Round access, and the top-positioned Lock control while preserving the same draft `Course`, stable IDs, metadata, and save boundary.
- The exercise picker is grouped, searchable, and registry-driven. Author-facing Help covers every preset without exposing external product/source names.
- New authoring support includes Type the translation, Build the translation, and Contextual comprehension. Relevant fields only are shown, and Course Audit blocks errors while allowing an explicit warning override.
- Answer expressions support `{optional}`, `[a|b|c]`, and scoped or whole-expression `<>` reorder groups. Expansion is deterministic, duplicate-free, structurally validated, and capped at 128 variants.
- Acceptance and correction are separate. Normalization is Unicode-aware, whitespace/case/punctuation tolerant, apostrophe-preserving, and accent-aware. Optional typo acceptance is restricted to one omitted or duplicated repeated letter in one sufficiently long token; it does not accept tense/person substitutions. Closest-correction selection is deterministic and never changes correctness.
- Responsive coverage includes 320, 375, and 430 logical px phone widths and desktop layouts for the affected editor, Help, and exercise surfaces.

## Automated validation

- `flutter pub get` passed; 28 newer package versions are incompatible with the current dependency constraints and were not adopted.
- Final focused verification passed **47 tests** covering the answer engine, contextual comprehension, Lesson management, picker/Help, Course Model v5, and localized exercise copy.
- Final full suite: `flutter test --no-pub --reporter compact --timeout 60s` passed **441 tests** in **3 minutes**.
- `flutter analyze --no-pub`: **0 errors and 0 warnings**. It reports the same **81** info-only `curly_braces_in_flow_control_structures` notices; none were suppressed or broadly cleaned up.
- `python tools\validate_courses.py`: all **8** bundled v5 courses passed.
- `python tools\validate_lesson_icons.py`: **14 assets, 0 issues**.
- `python tools\validate_images.py`: **113 assets, 1 issue**, solely the pre-existing missing `assets/exercise_images/hello.webp`. It is unrelated to build 224 and remains deliberately unchanged.
- `git diff --check` passed. The author-facing taxonomy scan found external interoperability names only in the engineering matrix.
- Widget-test crash-log messages are the expected persistent-storage fallback in the test environment and did not cause failures.

## Windows release artifact

- `tools\package_windows_release.ps1` completed the Windows release build, copied the required VC runtime, validated staged contents, extracted the ZIP, and matched the extracted files against staging.
- Staged directory: `build/packages/quisquislingo_alpha_224_dev_windows_x64/`.
- ZIP: `build/packages/quisquislingo_alpha_224_dev_windows_x64.zip`.
- ZIP size: **25,915,203 bytes**.
- ZIP SHA-256: `5918EC660DE2183D826FC4C42340420CD7D45EBC622501D22478FA1E31E86B94`.
- The build 223 staged directory and ZIP remain present as rollback copies.

## Deferred and unsupported boundaries

- `PickOneAudio` remains unsupported because its source semantics are not sufficiently known to choose a lossless canonical mapping.
- Speaking, repeat, and spoken-response exercises remain unsupported pending the future Speech model.
- Full external Story authoring is intentionally deferred; ordered canonical Round content supports presentation-plus-exercise composition without a lossy runtime type.
- The target-machine checks in `docs/WINDOWS_RELEASE_TEST.md` remain the user's final visual, audio, and hardware validation boundary.
