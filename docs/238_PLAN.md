# QQL Build 238, Revision 0 — Working Plan / Handoff Notes

Status as of this document: **paused mid-release, awaiting user resume instruction.**
This file exists so a coding agent picking this branch back up in a later session
has full context without re-deriving it. Do not resume work automatically — wait
for explicit user direction, per this session's pause request.

Current version in `pubspec.yaml`: `2.0.38+238000` (already bumped).

## Original scope (approved by user)

Two phases, explicitly sequential, each ending with focused validation and a stop
for user review before continuing:

### Phase 1 — Extend `Arrange` only (COMPLETE)

Extend the existing `Arrange` primitive (used by `word_order` and
`build_translation` exercise types). Do **not** add a new primitive.

Added support for:
- inline gaps inside fixed text;
- word tiles;
- multi-word phrase tiles;
- optional distractor tiles;
- removing a placed tile before submission;
- moving a tile from one gap to another;
- audio prompts using the existing QQL audio/TTS system.

Constraints honored:
- Existing Arrange exercises continue to work unchanged.
- No new presets were added.
- Focused tests were added for the new capabilities.
- `dart format`, focused tests, and `flutter analyze` were run and are clean.

Design actually shipped: inline-gap authoring uses direct `{answer}` brace syntax
in the sentence text (e.g. `I {am} going {to} London`), rather than a
`{gap}` placeholder plus a separate answer list. This was an explicit user
decision made mid-Phase-1 (see "Follow-up work already completed" below).

### Phase 2 — Extend `Select` only (NOT STARTED)

Extend the existing `Select` primitive. Do **not** add a new primitive.

Add:
- single-selection mode;
- multiple-selection mode;
- optional required-selection count;
- set-based correctness for multiple selection (the answer is correct only when
  the selected set exactly matches the correct set);
- linked-gap answer sets (one `Select` option may contain the values for several
  gaps; selecting that option fills all linked gaps).

Constraints to honor:
- Existing `Select` exercises must remain single-select by default and continue
  to work unchanged.
- Do not add new presets yet.
- Add focused tests for the new capabilities.
- Run `dart format`, focused tests, and `flutter analyze` — do **not** run the
  full suite (deferred to the end of all tasks, per original user instruction).
- Stop after this phase and report the result.

Phase 2 has **not been started**. No `Select`-model/editor/round-screen code has
been touched yet for this phase. Start here when resuming.

## Follow-up work already completed (between/after Phase 1)

These were interactive follow-ups from the user during and after Phase 1, all
already implemented and validated:

1. **Editor Preview bug**: creating a Word Order exercise with "Inline Gaps" ON
   and text like `Per favore {dammi} {del} sapone` triggered "Add at least one
   {gap} marker" in Preview. Root cause and fix already applied (see git log /
   diff on `lib/models/course_models.dart`, `lib/screens/round_screen.dart`,
   course editor screens, and `lib/services/course_audit_service.dart` /
   `lib/services/authoring_duplication_service.dart` for the underlying model
   change — the exercise now uses direct `{answer}` braces instead of a
   `{gap}` placeholder + separate list).
2. **Help text updates**:
   - Added clarification in the exercise Help about the `{answer}` inline-gap
     brace syntax (replacing the older `{gap}` + external answer list idea).
   - Changed the Prompt Help example from "Translate sentence to Italian" to
     something like "Build the sentence".
   - Changed the shared "Target Sentence with Gaps" Help example (used by all
     Arrange presets that reference it) from `I {go} {to} school` to
     `I {am} going {to} London` — this was an explicit, deliberate wording
     change requested by the user; do not revert it.
   - `build_translation` was fixed to match the same inline `{answer}` brace
     approach as `word_order` (user explicitly asked "fix build_translation
     too").
3. **Version bump to `2.0.38+238000` / "Build 238, Revision 0"**: applied across
   `pubspec.yaml`, `lib/services/app_metadata.dart` (or equivalent), `README.md`
   (banner + in-progress QQL 238 section + Beta lifecycle section), and
   `CHANGELOG.md` (new entry: "2.0.38 (Build 238, Revision 0) - Arrange
   gap-fill authoring (in progress)"), plus 8 test files that referenced the
   old `2.0.37+237004` / "Build 237, Revision 4" strings and the
   version-derived welcome-notice `SharedPreferences` key.
   - Deliberately did **not** add a Build 238 bullet to `AGENTS.md`'s "Current
     release boundary" list — that list already stops at Build 236 in the
     actual repo (Build 237 was never added there either), so omitting 238 too
     is consistent with existing precedent, not an oversight. If a future
     session decides `AGENTS.md` should be brought current, that is a
     separate, explicit decision — do not silently do it as part of Phase 2.
4. **Test regression fix** (`test/course_editor_225_test.dart`): the new
   unconditional "Inline gaps" `SwitchListTile` toggle (added to both
   word_order and build_translation forms) increased form height, pushing the
   "Save draft" button a few px past the fixed 1200×1400 test viewport even
   after `scrollUntilVisible`. Fixed by adding an explicit
   `tester.drag(..., Offset(0, -600))` + `pumpAndSettle()` before the tap in
   the "Build the translation saves natural punctuation through reload and
   Audit" test. 7/7 tests passing after the fix.
   - Technical note for future similar issues: `dragUntilVisible`/
     `scrollUntilVisible` only checks that the target exists in the widget
     tree, not that it's fully within the viewport. For non-lazy scrollables
     (`Column`/`SingleChildScrollView`), the widget is already present before
     scrolling, so the loop can exit without actually scrolling far enough.
5. **Crash-logger test noise hardening** (`lib/services/crash_log_service.dart`):
   added a cached `_initialisationFailed` boolean; once `initialise()` fails
   once, subsequent calls short-circuit instead of retrying and re-logging.
   A blanket `FLUTTER_TEST` env-var skip was considered and rejected because
   `test/debug_logs_228_03_test.dart` legitimately mocks `path_provider` to
   succeed under test and asserts a real crash-log file gets written; a
   blanket skip would have broken that test. The cache-on-failure approach
   preserves that test while eliminating repeated noise elsewhere.
6. **Pre-existing formatting drift cleanup** (unrelated to this session's
   logic changes, confirmed via `git log`/`git diff -w` to be pure
   re-wrap/reindent with no behavior change): reformatted 9 files —
   `lib/screens/gamification_settings_screen.dart`,
   `lib/services/app_errors.dart`, `lib/services/error_presenter.dart`,
   `lib/services/exercise_image_service.dart`, `lib/services/window_setup.dart`,
   `test/missing_word_test.dart`, `test/package_naming_regression_test.dart`,
   `test/qql_229_revision2_test.dart`,
   `test/unified_learner_layout_regression_test.dart`. Also removed a stray
   untracked `test_report.json` artifact.
7. **SVG editor-cruft cleanup** (triggered by runtime warnings `unhandled
   element <defs/>; Picture key: Svg loader` and `unhandled element
   <sodipodi:namedview/>; Picture key: Svg loader`), **COMPLETE**:
   - Cleaned Inkscape/Illustrator-exported cruft (`<metadata>` RDF blocks,
     `<sodipodi:namedview>`, empty/self-closing `<defs/>`) from
     `assets/world_flags/flags/mirandese.svg`, `romansh.svg`, `sardinian.svg`,
     `venetian.svg`. Real visual content (paths, and `venetian.svg`'s large
     legitimate gradient `<defs>`) was preserved untouched.
   - Followed the existing QQL 234 "renderer-normalized flag" precedent in
     `tools/validate_media_assets.py`:
     - Added `QQL238_RENDERER_NORMALIZED_FLAG_IDS = frozenset({"mirandese",
       "romansh", "sardinian", "venetian"})` alongside the existing
       `QQL234_RENDERER_NORMALIZED_FLAG_IDS` set.
     - Updated the incompatible-markup check to test membership in the union
       of both sets, and generalized the issue message (no longer says
       "QQL 234" specifically).
   - Updated `assets/world_flags/manifest.json`: added `artworkSourceSha1`
     (the original pre-cleanup hash) and updated `artworkSha1` (new
     post-cleanup hash) for all 4 flag entities.
   - Updated `assets/world_flags/LICENSE-language-related-flags.md`: converted
     all 4 flags' notices to the dual-hash "source SHA-1 ...; renderer-normalized
     bundled SHA-1 ..." format, and bumped the "N SVGs are renderer-normalized"
     count from 5 to 9.
   - Updated `test/world_flag_dataset_test.dart`'s `normalizedAssetSha1` map to
     include the 4 new entries (new bundled SHA-1 values) so the provenance
     test continues to pass.
   - Verified: `python tools/validate_media_assets.py` → 0 issues; 29/29
     focused tests across `test/world_flag_dataset_test.dart`,
     `test/qql_language_worldflag_associations_235_test.dart`,
     `test/flag_background_palette_227_02_test.dart` pass; `flutter analyze`
     clean (0 issues); `dart format` clean on the touched Dart test file
     (the `.py` validator script is not a Dart file, so `dart format` cannot
     and should not be run on it).

   New/updated SHA-1 values for reference (already applied, listed here in
   case of merge conflicts or re-verification):
   - mirandese: source `127ea565360ccb2a5c901cdd234a8c833ea54107` → bundled
     `9105681c62f43ea80d4c7b24a00118cf47ad3ff9`
   - romansh: source `e3a0435656a048515bd1ae175e0a7a18f1c2329f` → bundled
     `f8155f5694bb08239c344f9ae1f7eb0e17f11c09`
   - sardinian: source `593068e1d9b8b1a96010d21ee2be2ba2483a15e9` → bundled
     `112ea2aae498ddde2bfe7b124958ce38d8c3adaf`
   - venetian: source `28ba1cbb86ea051324975702bb3aeb8979f75925` → bundled
     `06058557d4abb46ca40f7d9314510b3689b7d457`

## Current git status (uncommitted working tree, at pause time)

Nothing has been committed or pushed this session (per project policy: do not
commit/push without explicit user request). `git status --short` shows:

```
 M assets/world_flags/LICENSE-language-related-flags.md
 M assets/world_flags/flags/mirandese.svg
 M assets/world_flags/flags/romansh.svg
 M assets/world_flags/flags/sardinian.svg
 M assets/world_flags/flags/venetian.svg
 M assets/world_flags/manifest.json
 M lib/models/course_models.dart
 M lib/screens/gamification_settings_screen.dart
 M lib/screens/round_screen.dart
 M lib/services/app_errors.dart
 M lib/services/authoring_duplication_service.dart
 M lib/services/course_audit_service.dart
 M lib/services/crash_log_service.dart
 M lib/services/error_presenter.dart
 M lib/services/exercise_image_service.dart
 M lib/services/window_setup.dart
 M macos/Flutter/GeneratedPluginRegistrant.swift
 M test/course_editor_225_test.dart
 M test/missing_word_test.dart
 M test/package_naming_regression_test.dart
 M test/qql_229_revision2_test.dart
 M test/unified_learner_layout_regression_test.dart
 M test/world_flag_dataset_test.dart
 M tools/validate_media_assets.py
 M windows/flutter/generated_plugin_registrant.cc
 M windows/flutter/generated_plugin_registrant.h
 M windows/flutter/generated_plugins.cmake
```

Notes on this list for the next session:
- `macos/Flutter/GeneratedPluginRegistrant.swift` and the two
  `windows/flutter/generated_plugin*.{cc,h,cmake}` files are Flutter-generated
  registrant files. Per `AGENTS.md`, verify their actual content against
  `HEAD` before treating them as meaningful changes — they may just be
  metadata/line-ending normalization from running Flutter commands, not real
  code changes. Do not include them in a commit if they are byte-identical to
  `HEAD` in substance.
- There is likely also a set of course-editor / Course Model files touched by
  Phase 1's `{answer}`-brace redesign not all listed above by name in this
  document — always re-run `git status --short` and `git diff --stat` at the
  start of the next session rather than trusting this snapshot blindly, in
  case anything changed underneath.
- Nothing here has been committed. The next session should decide, with the
  user, when to commit (likely: after Phase 2 is also done and the full test
  suite has been run once, per the user's original instruction to defer the
  full suite to the end of all tasks — though the user may also want an
  earlier interim commit; ask rather than assume).

## Next steps when resumed

1. Re-orient: run `git status --short`, `git diff --stat`, and re-read this
   file plus `AGENTS.md`'s "Current release boundary" section before making
   any change.
2. Confirm with the user whether to now start **Phase 2 (extend `Select`)**,
   or whether there is other interim work first.
3. When implementing Phase 2, follow the same discipline as Phase 1:
   - Extend the existing `Select` primitive only; do not add a new primitive.
   - Preserve default single-select behavior for all existing `Select`
     exercises unchanged.
   - Implement: single-selection mode (default/existing), multiple-selection
     mode, optional required-selection count, set-based exact-match
     correctness for multiple selection, and linked-gap answer sets (one
     option fills several gaps at once when selected).
   - Do not add new presets yet.
   - Add focused tests for each new capability.
   - Run `dart format`, the focused/new tests, and `flutter analyze` only —
     do **not** run the full suite yet.
   - Stop after Phase 2 and report results, per the user's original
     instruction, before doing anything else (including the deferred full
     suite run).
4. Only after the user confirms Phase 2 is accepted should the deferred full
   `flutter test` suite be run once, covering both Phase 1 and Phase 2 (and
   the follow-up fixes/SVG cleanup already completed in this document).
5. Do not commit or push until the user explicitly asks.
