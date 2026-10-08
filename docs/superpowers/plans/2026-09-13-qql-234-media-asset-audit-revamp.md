# QQL 234 Media Asset Audit and Final Alpha Cleanup — Implementation Plan

> **Scope:** Implement the approved QQL `2.0.34+234000` design in the current
> checkout. Do not create a worktree, stage, commit, push, package, tag, reset,
> clean or modify unrelated behavior. Course Model v9 and its existing storage
> namespaces remain unchanged.

## Release constraints

- QQL 234 remains Alpha, with local expiry `2026-10-13 23:59:59`.
- Work test-first in focused slices and preserve existing public behavior.
- Never run two Flutter commands concurrently.
- Run the complete Flutter suite exactly once, at the end, with
  `flutter test --no-pub --concurrency=1`.
- Do not generate the remaining 86 contaminated exercise images until the user
  approves the six-image pilot.
- Tags are Course Editor Media Library metadata only and never learner-facing.
- Keep all 19 existing audio files byte-for-byte unchanged.

## Task 1: Lock image metadata and editor-only search behavior with tests

**Files:**

- Modify: `test/flat_image_library_test.dart` (or the closest existing focused
  Media Library widget test)
- Modify: `test/script_recognition_226_03_test.dart` only if its existing
  contract needs an additive assertion
- Add: `test/exercise_image_manifest_234_test.dart`

**Steps:**

1. Add failing manifest assertions for 111 unique IDs, labels and paths, file
   existence, at least two lowercase/trimmed/unique tags per record, and
   semantic equivalence of all three manifests.
2. Add exact failing assertions for `people_family_man` → `Uomo` with
   `uomo`/`amico`, and `actions_jump` → `Saltare` with `saltare`/`salto`.
3. Add widget assertions that tags render on each editor library card and that
   searches by `amico`, `people_family_man`, `people family` and `Saltare`
   resolve the expected card.
4. Add an explicit negative assertion that learner exercise cards do not
   expose Media Library tags.

## Task 2: Apply the 111-entry bilingual taxonomy and Media Library UI

**Files:**

- Modify: `assets/exercise_images/manifest.json`
- Modify: `assets/exercise_images/image_bank_manifest.json`
- Modify: `assets/exercise_images/manifest_external.json`
- Modify: `lib/screens/flat_image_library_screen.dart`

**Steps:**

1. Apply the reviewed 111-entry tag mapping without changing stable IDs,
   paths or categories.
2. Apply the `Uomo` and `Saltare` display labels; confirm no current collision,
   so no suffix is required.
3. Normalize Media Library search consistently across label, tags, ID and
   category (`trim`, lowercase, underscores treated as spaces).
4. Render `Tags: …` beneath every Course Editor library card label with a
   tooltip for clipped text; rename preview `Keywords` to `Tags` and make the
   full list accessible.
5. Run the focused tests from Task 1.

## Task 3: Extend the World Flag dataset and language suggestions

**Files:**

- Modify: `tools/generate_world_flags.py`
- Add: ten SVGs under `assets/world_flags/flags/`
- Modify: `assets/world_flags/manifest.json`
- Modify: `assets/world_flags/LICENSE-language-related-flags.md`
- Modify: `lib/models/world_flag_entity.dart`
- Modify: `lib/services/world_flag_repository.dart`
- Modify: `test/world_flag_dataset_test.dart`

**Steps:**

1. Add failing tests for 276 total entities, 19 language-related entities,
   exact physical/manifest coverage and valid ordered suggestion references.
2. Add explicit suggestion tests for `fy`/`fy-NL`, `pms`/`pms-IT` and
   `nap`/`nap-IT`.
3. Acquire the ten approved Commons SVGs, verify pinned SHA-1/source/author/
   license facts, and document regional/community status accurately.
4. Add typed optional `languageSuggestions` parsing with full-tag-before-base-
   tag normalization and no fabricated fallback.
5. Regenerate/check the manifest deterministically and run the focused dataset
   test plus SVG integrity checks.

## Task 4: Build one searchable, portable Course flag chooser

**Files:**

- Add: `lib/models/course_flag_selection.dart`
- Add: `lib/services/course_flag_catalog_service.dart`
- Add: `lib/widgets/course_flag_picker.dart`
- Modify: `lib/widgets/world_flag_picker.dart`
- Modify: `lib/screens/course_projects_screen.dart`
- Modify: `lib/screens/course_editor_screen.dart`
- Modify: `lib/screens/editor_help_screen.dart`
- Add: `test/course_flag_catalog_234_test.dart`
- Add: `test/course_flag_picker_234_test.dart`
- Modify: existing creation/Course Info flag tests as required

**Steps:**

1. Add failing pure-service tests for language ranking, stable deduplication,
   invalid raster rejection, raster authorization and copied-value independence
   after a source Course disappears.
2. Add failing widget tests for search, suggestion/installed/world sections,
   cancellation without mutation and explicit selection.
3. Implement portable Model v9 selection conversion and a catalog that copies
   values rather than retaining source-Course dependencies.
4. Offer installed custom rasters only when the active profile already has
   Copy-as-new authority; do not change authorization.
5. Replace both duplicated source dropdowns with the shared chooser and run
   the focused tests.

## Task 5: Add the real bundled Italian-to-Neapolitan AI-Slop Demo

**Files:**

- Modify: `tools/regenerate_bundled_courses_225_02.py`
- Add: `assets/courses/neapolitan_it.json`
- Modify: `lib/services/course_service.dart`
- Modify: `lib/services/course_editor_service.dart`
- Modify: `lib/services/learning_language_identity.dart`
- Modify: `tools/validate_courses.py`
- Modify: bundled discovery, provenance, sample and language identity tests

**Steps:**

1. Add failing tests for unique `NAP` discovery, immutable official status,
   v9 provenance/checksum, `nap-IT` identity, Neapolitan flag and course audit.
2. Add the narrow valid two-or-three-letter learner-code behavior without
   changing existing two-letter persistence.
3. Generate only the new deterministic `sample_nap_it_nap` Course: nine
   Lessons, 36 Rounds, approximate existing demo depth, Italian source and
   a documented simplified contemporary urban Neapolitan register.
4. Use the six approved pilot image paths in genuine published exercises and
   keep a non-audio effective Duel pool of at least 25 exercises per Lesson.
5. Keep `ttsLanguage: nap-IT`; never substitute Italian TTS and add no audio.
6. Prove the pre-existing nine bundled course files are byte-identical before
   and after the generation step.

## Task 6: Replace startup artwork and fix the Extended-frame race

**Files:**

- Modify: `lib/main.dart`
- Modify: `lib/screens/home_screen.dart`
- Modify: `test/startup_profile_gate_test.dart`
- Modify: `test/course_entry_animation_228_test.dart`
- Remove after reference proof: `assets/olive_tree.png`
- Modify current credits/docs that list the removed olive

**Steps:**

1. Add failing startup tests for the canonical logo, absence of the olive/
   flying flags/separate word mark, 600 ms fade/scale and static reduced-motion
   state within the unchanged 1800 ms gate.
2. Add a deterministic failing regression test that holds Extended source →
   Off destination reload in flight and inspects every relevant frame.
3. Replace startup with the canonical logo and remove now-dead olive code and
   credit only after proving no remaining consumer.
4. Make Course, destination background mode and optional entry overlay one
   atomic `_reload` state commit; retain the existing selector-dismissal delay
   and introduce no Android branch or masking delay.
5. Run both focused widget-test files serially.

## Task 7: Approve and roll out the exercise artwork

**Files:**

- Pilot: `airplane.webp`, `carrot.webp`, `horse.webp`, `man.webp`,
  `jump.webp`, `table.webp`
- Then, only after approval: the other 86 audited contaminated WebPs
- Modify: `tools/validate_images.py`

**Steps:**

1. Normalize the six independently generated pilot assets to true-alpha,
   256×256 lossless VP8L WebP with transparent padding and ≤50 KiB.
2. Inspect each against transparent/light/dark backgrounds and at 64×64;
   present a labeled contact sheet and wait for explicit user approval.
3. After approval only, replace the six files in place, then generate and QA
   the remaining 86 using the approved one-subject flat style.
4. Extend the validator to exact manifest/file equality, case-correct paths,
   lossless VP8L, dimensions, alpha, border/padding and size cap.
5. Run the image validator and manifest tests.

## Task 8: Make all retained audio bundle-visible and hash-locked

**Files:**

- Modify: `pubspec.yaml`
- Add: `test/media_asset_integrity_234_test.dart`
- Add: `tools/validate_media_assets.py`
- Modify: `tools/validate_release.ps1`

**Steps:**

1. Record SHA-256 for the three WAVs and sixteen MP3s before editing anything.
2. Add failing `rootBundle.load` coverage for all 19 logical asset paths and
   assert the allowlisted hashes; assert no Neapolitan sample audio exists.
3. Declare the eight nested sample directories explicitly in `pubspec.yaml`.
4. Add a repository validator for references, byte duplicates, flags/licenses,
   startup assets, Course image references and the audio hash allowlist.
5. Recompute hashes and prove all 19 bytes are unchanged.

## Task 9: Remove analyzer debt at the source

**Files:**

- Modify: `analysis_options.yaml`
- Modify: `test/bundled_courses_225_02_test.dart`
- Modify: `test/italian_course_audit_225_test.dart`
- Modify only newly exposed sources needed to satisfy the same lint rules

**Steps:**

1. Remove the broad platform-directory analyzer exclusion.
2. Replace the three suppressed diagnostic `print` calls with assertion
   reasons that retain useful failures.
3. Run full `flutter analyze --no-pub`; fix each real issue at source without
   adding ignores, exclusions or downgraded lint rules.

## Task 10: Version, document and verify the final Alpha

**Files:**

- Modify: `pubspec.yaml`, `lib/services/app_metadata.dart`,
  `lib/services/alpha_lifecycle_service.dart` and focused tests
- Modify: `README.md`, `CHANGELOG.md`, `AGENTS.md` and current release/editor/
  media/flag documentation only
- Add: `docs/234_MEDIA_AUDIT.md`
- Add: `docs/234_VALIDATION.md`

**Steps:**

1. Set `2.0.34+234000`, display Build 234 Revision 0 and Alpha expiry
   `2026-10-13 23:59:59`; do not rename v9 storage keys.
2. Record the final inventory, the 92/19 image classification, tag taxonomy,
   all retained/removed assets, flag sources/licenses, unchanged audio hashes,
   analyzer cleanup and the exact release boundary.
3. Run focused tests and deterministic Python validators; format changed Dart.
4. Run `flutter analyze --no-pub` and capture fresh clean evidence.
5. Freeze the production/test tree, then run exactly once:

   ```text
   flutter test --no-pub --concurrency=1
   ```

6. After the full suite, change only validation documentation; run non-Flutter
   textual checks, `git diff --check` and final status/scope inspection.
7. Report QQL 234 as Alpha and state whether evidence supports making the next
   release the first Beta; do not label QQL 234 itself Beta.
