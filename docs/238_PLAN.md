# QQL Build 238, Revision 1 — Working Plan / Handoff Notes

Status as of this document: **Phases 1 and 2 both complete; version bumped to
Build 238, Revision 1; awaiting user direction on next steps (see "Next steps
when resumed" at the end).** This file exists so a coding agent picking this
branch back up in a later session has full context without re-deriving it.

Current version in `pubspec.yaml`: `2.0.38+238001` (already bumped). Beta
expiry is unchanged at `2026-10-17 23:59:59` local time (the user explicitly
asked not to change it when requesting this bump).

Note on a prior session's confusion: an earlier commit on this branch
(`238a04b`, "feat: complete phases 1 & 2 foundations and persist active md
plan") has a misleading message — despite mentioning "phases 1 & 2", it only
committed Phase 1 plus generic model/duplication-service plumbing
(`ExerciseInteraction.minSelections`/`maxSelections`, the shared
`layout`/`gapAssignments` fields, and `AuthoringDuplicationService` already
copying them generically). No `Select`-specific round-screen, editor or audit
code existed yet at that point. The session that reopened this branch
verified this by grepping the codebase before starting, then implemented the
actual Phase 2 work described below.

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

### Phase 2 — Extend `Select` only (COMPLETE)

Extend the existing `Select` primitive. Do **not** add a new primitive.

Added support for:
- single-selection mode (default, unchanged for every existing exercise);
- multiple-selection mode;
- optional required-selection count;
- set-based correctness for multiple selection (the answer is correct only when
  the selected set exactly matches the correct set);
- linked-gap answer sets (one `Select` option may be the required answer for
  more than one gap; selecting that option fills every linked gap at once).

Constraints honored:
- Existing `Select` exercises continue to work unchanged (single-select,
  immediate-answer-on-tap behavior is byte-for-byte the same code path when
  `maxSelections <= 1` and there are no inline gaps).
- No new presets were added. Editor authoring for the new capabilities was
  scoped to the general-purpose `choice` preset only (not `gap_choice`,
  `icon_choice`, `listening_choice`, `script_recognition`,
  `contextual_comprehension`, `reading_comprehension`, `dialogue_response`,
  or `listening_comprehension` — those keep their original single "Correct
  answer number" authoring UI unchanged). The underlying model/round-screen
  primitives are generic, so any of those types would also work if a future
  session decides to expose the toggles for them; that is an explicit,
  separate decision, not something this phase did silently.
- Focused tests were added for the new capabilities (see below).
- `dart format`, focused tests, and `flutter analyze` were run and are clean.
  The full `flutter test` suite was deliberately **not** run yet, per the
  original instruction to defer it to the end of all tasks.

What was actually implemented (by file):
- `lib/models/course_models.dart`: new `Exercise` getters —
  `isMultiSelect`, `requiredSelectionCount`, `maxSelectionCount`,
  `correctItemIdSet`, `hasSelectGaps`. These are read-only projections over
  the `ExerciseInteraction.minSelections`/`maxSelections`/`layout` and
  `ExerciseEvaluation.correctItemIds`/`gapAssignments` fields that a prior
  session had already added generically (see the note above) — no new model
  fields were needed for Phase 2 itself. `hasSelectGaps` deliberately reuses
  the same `arrangeLayout`/`arrangeGapAssignments` getters Arrange gap-fill
  uses, since both primitives share the identical layout/gapAssignments
  shape by design.
- `lib/screens/round_screen.dart`: `_choiceExercise` now branches to a new
  multi-select widget (checkboxes + a "Check" button, gated on
  `requiredSelectionCount`, set-based exact-match correctness) or a new
  linked-gap widget (a read-only gap layout plus toggle chips per option;
  toggling an option fills every gap whose required answer is that option)
  before falling through to the original single-tap-to-answer button list
  unchanged. New state: `_multiSelected` (Set<int>), `_selectGapPicks`
  (Set<String>), both reset in `_prepareExercise`. `_ChoiceOption` now always
  carries its backing `ExerciseItem` (previously only for
  `script_recognition`) and its `correct` flag is computed via
  `correctItemIdSet.contains(item.id)` instead of a single-index comparison
  — behaviorally identical for every existing single-correct-answer exercise.
- `lib/screens/course_editor_screen.dart`: the `choice` preset gained two
  independent `SwitchListTile` toggles — "Inline gaps" (reuses the existing
  `_gapLayout`/`_tokens` controllers and the same `{answer}` brace syntax and
  `_gapBracePattern`/`_gapBraceCountsBalance` helpers Arrange gap-fill uses,
  via a new `_buildSelectGapCandidate`; unlike Arrange, answer text is
  deduplicated into one shared option so the same option can be required by
  more than one gap) and "Multiple correct answers" (a new
  `_requiredSelections` controller plus a comma-separated "Correct answer
  numbers" reading of the existing `_correct` controller, via a new
  `_buildSelectMultiCandidate`). Both toggles reset to off when switching to
  or from a different exercise type (except the pre-existing
  word_order/build_translation pair, whose own toggle-sharing behavior is
  unchanged) to avoid an incoherent combination bleeding across types.
- `lib/services/exercise_field_help.dart`: added the `requiredSelections`
  field key (new `ExerciseAuthoringField.selectRequiredSelections` help
  entry) and `choice`-specific Help overrides for `correct`, `gapLayout` and
  `tokens` so their wording matches Select's option-based gap-fill instead of
  Arrange's tile-based wording. `editorFieldKeys('choice')` was extended to
  list the new fields.
- `lib/services/course_audit_service.dart`: a linked-gap `choice` exercise is
  now routed to a new `_auditSelectGapFill` (mirrors `_auditArrangeGapFill`
  exactly, reusing the same `AuditCode` values) instead of the normal
  choice-family "at least two answers / one correct answer" checks, which do
  not apply in gap mode. A multi-select `choice` exercise is additionally
  checked for a non-empty `correctItemIds` and an in-range
  `requiredSelectionCount`.
- `lib/services/authoring_duplication_service.dart`: **not modified** — it
  already copied `minSelections`/`maxSelections`/`layout`/`gapAssignments`
  generically with correct item-ID remapping (part of the prior session's
  "foundations" work), and this was verified with a dedicated test rather
  than assumed.
- Tests added: `test/select_multi_238_test.dart` (model round-trip, audit,
  learner-UI multi-select flow), `test/select_gap_fill_238_test.dart` (same,
  for linked-gap Select), `test/select_editor_238_test.dart` (Course Editor
  authoring for both new `choice` toggles, plus duplication). Also updated
  `test/exercise_field_help_226_02_test.dart`'s hardcoded per-preset field
  inventory (a separate literal list from the source's own
  `editorFieldKeys`, used only to assert Help-text coverage) to include the
  new `choice` fields — otherwise that test's coverage assertion would fail
  since it could never reach the new `selectRequiredSelections` enum value.

Known test-writing pitfall documented for future sessions: `_choiceOptions`
(and therefore any exercise using the shared `_choiceExercise` widget,
multi-select included) is shuffled per attempt via
`_shuffleDifferentChoices`. A widget test must select options by their
visible text (e.g. `find.text('Apple')`) or by an ID that is not
shuffle-derived (linked-gap options use `select-gap-option-<itemId>` keys,
which are stable since that widget iterates `ex.interaction.items` directly,
not the shuffled `_choiceOptions`), never by a fixed pre-shuffle
`multi-select-option-<index>` position — an earlier draft of
`select_multi_238_test.dart` was intermittently flaky for exactly this
reason before being fixed to select by text.

## Follow-up work already completed (during Phase 2 manual review)

The user manually reviewed Phase 2 in the running app (Course Editor +
Preview) after the automated implementation above and reported issues; all
are already fixed and validated:

1. **Linked-gap Select correctness bug, fixed in two passes (real, not
   cosmetic)**:
   - *First pass*: as originally shipped, a gap could only ever be filled by
     tapping the option that was *actually correct* for it —
     `evaluation.gapAssignments` was read as "the only option allowed to
     occupy this gap" rather than as an answer key. Tapping a distractor had
     no visible effect on the sentence at all, so the Check button only ever
     became enabled once the learner had already picked the right answer —
     there was no way to submit a wrong answer and see "Incorrect". Fixed by
     making gap-fill state genuine placement state
     (`Map<String, String?>` gapId -> occupying itemId) instead of a
     correctness-filtered derived set, with an option that already occupies
     a gap freeing it on a second tap, otherwise auto-filling every
     currently-*correct*-and-empty gap for that option, and falling back to
     the first empty gap for a genuine distractor.
   - *Second pass* (this session, after the user tried it in Preview and
     reported: "the first selected block must go into the first available
     blank, not necessarily in the correct position"): the first pass's
     "auto-fill every gap this option is correct for" behavior was itself
     wrong — placement must never depend on correctness, only Check-time
     grading should. Redesigned `round_screen.dart` to mirror gap-based
     Arrange's proven interaction model exactly: `_onSelectGapOptionTap`
     fills an armed gap if one is armed, otherwise the first remaining empty
     gap in layout order, full stop, regardless of whether that option is
     actually correct there. `_onSelectGapSlotTap` (tap a gap to arm it, or
     to move/swap an already-armed gap's option into it) and
     `_removeSelectGapFill` (an explicit remove-✕ control per filled gap,
     via a now-interactive `_selectGapSlot` reusing Arrange's `_gapSlot`
     visual pattern with its own `select-gap-slot-<id>`/
     `select-gap-remove-<id>` keys) round out the parity. An option is never
     consumed from the option list (unlike Arrange tiles), so the same
     option can be tapped again to fill a *later* gap that also needs it —
     this is now the only way to fill more than one gap with one option;
     there is no more single-tap "fills every matching gap at once" magic.
     The user separately confirmed the resulting semantics: "it can still be
     an incorrect answer if multiple blanks are filled in an incorrect
     order" — `_submitSelectGaps` already compared each gap's filled item to
     its own required item individually, so right answers placed in the
     wrong blanks were already correctly graded incorrect; only placement
     needed the fix.
   - Both passes updated `select_gap_fill_238_test.dart` accordingly (a test
     literally named "selecting the wrong option leaves gaps unfilled" had
     been asserting the first bug as if it were correct behavior; a later
     test asserting one-tap-fills-both-linked-gaps had to be rewritten to
     tap the option twice instead) and added: a single-gap distractor case
     matching the user's exact manual repro (`Un {gatto}` with
     `cane`/`passero` distractors), a two-different-answers case
     (`I {am} going {to} London`-shaped) proving right-answers-wrong-blanks
     is graded incorrect, and an explicit-arming case proving a gap can be
     targeted out of order.
   - Editor copy (the "Inline gaps" switch subtitle, the `_gapLayout` field
     helper, the `_buildSelectGapCandidate` doc comment, and the
     `('choice','gapLayout')` Help entry in `exercise_field_help.dart`) was
     updated to describe the final tap-fills-first-empty-blank mechanic
     instead of the superseded auto-link-everything description.
2. **Editor field label**: `choice` Inline Gaps' distractor field renamed
   from "Extra distractor options (optional)" to "Distractor options
   (optional)" (field label, Help dialog title, error/help text, tests).
3. **Editor field label + copy**: `choice` Inline Gaps' `_gapLayout` field
   renamed from "Question with gaps" to "Sentence with gaps" (field label,
   Help dialog title, the three Save-time error message prefixes, tests),
   and its helper/entry-rules text now leads with the plain
   `I {am} going {to} London.` example (matching Arrange's established
   phrasing) before explaining the linked-gap case.
4. **Version bump to Build 238, Revision 1**, requested by the user once the
   fixes above were in: `pubspec.yaml`, `lib/services/app_metadata.dart`
   (`buildNumber` `238000` → `238001`, `correctiveRevision` `0` → `1`,
   `publicBuildLabel` "Revision 0" → "Revision 1"; `releaseVersion` stays
   `2.0.38` — only the build/revision changes within a build, matching the
   `237004`-style precedent from Build 237's revisions), `README.md` (banner,
   the QQL 238 in-progress paragraph rewritten to describe both phases as
   done, the Beta lifecycle sentence) and `CHANGELOG.md` (new "Revision 1"
   bullets appended under the existing `# 2.0.38 (Build 238, Revision 1)`
   heading, Revision 0's own bullets left verbatim as history — same pattern
   Build 237's changelog entry uses for its 4 revisions), plus the 7 test
   files that asserted the old `238000` / "Build 238, Revision 0" /
   `correctiveRevision: 0` strings (`app_metadata_225_04_test.dart`,
   `course_audit_report_225_test.dart`, `course_entry_animation_228_test.dart`,
   `leaderboard_navigation_test.dart`, `learner_round_path_test.dart`,
   `qql_229_revision3_test.dart`, `qql_233_revision_platform_contract_test.dart`)
   and the version-derived `one_time_notice_seen_welcome_<technicalVersion>`
   SharedPreferences fixture keys inside three of them. The Beta expiry date
   in `lib/services/beta_lifecycle_service.dart` was deliberately **not**
   touched, per the user's explicit "Do not change expire date" instruction
   — it is a hardcoded constant unrelated to the version/build strings, so
   nothing else needed to change to leave it alone.
5. **Renamed the `choice` preset's displayed name** from "How do you say" to
   "Choose" (`lib/models/exercise_authoring.dart`'s `ExercisePresetRegistry`
   entry) to match the title users actually see. Every UI surface that shows
   preset names (`labelForType`, the type picker, Exercise Help) reads this
   registry field dynamically, so no other source code needed changing.
   Updated `test/exercise_help_224_test.dart` (asserted the old label
   literally), plus the two currently-maintained living docs that name the
   preset in prose — `AGENTS.md`'s New-Course-scaffolding bullets and
   `docs/COURSE_EDITOR.md`'s preset list/field-role paragraph — and the
   equivalent sentence in the in-app `lib/screens/editor_help_screen.dart`
   New Course Help text. Left untouched, as genuinely historical per-build
   records rather than living documentation (matching this session's
   existing CHANGELOG precedent): `CHANGELOG.md`,
   `docs/226_03_VALIDATION.md`, `docs/226_04_VALIDATION.md`,
   `docs/EXERCISE_ARCHITECTURE_224.md`, `docs/EXERCISE_TYPE_INVENTORY_231.md`.
   Also left untouched: every occurrence of "How do you say" that is
   actually example *content* rather than the preset title — e.g. the
   Prompt field's "How do you say this in Italian?" example in
   `exercise_field_help.dart` and its tests, and
   `guidebook_round_generator.dart`'s generated prompt text — none of which
   describe the preset's name.

All of the above were re-verified with `dart format`, `flutter analyze`
(clean, whole project) and a regression batch covering Phase 2, Phase 1
Arrange, editor/Help, the preset-picker/Exercise-Help tests and all 7
version-string test files — all green (see individual commands in this
session's history if re-verification is ever needed; not reproduced here to
avoid this document going stale the next time a file is touched).

Manual visual QA in the running app is still in progress (user-driven); no
other issues have been reported since the fixes above. See the "Next steps
when resumed" section for what still needs to happen before this is
release-ready.

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

## Current git status (uncommitted working tree, as of Phase 2 completion)

Everything described in "Phase 1" and the pre-existing follow-up work below
(the SVG cleanup, the original Revision 0 version bump, etc.) was committed
in `238a04b` and is on this branch's HEAD. Nothing here has been committed or
pushed this session (per project policy: do not commit/push without explicit
user request). `git status --short` now shows this session's Phase 2 work,
the Revision 1 version bump, and the `choice`→"Choose" preset rename:

```
 M AGENTS.md
 M CHANGELOG.md
 M README.md
 M docs/238_PLAN.md
 M docs/COURSE_EDITOR.md
 M lib/models/course_models.dart
 M lib/models/exercise_authoring.dart
 M lib/screens/course_editor_screen.dart
 M lib/screens/editor_help_screen.dart
 M lib/screens/round_screen.dart
 M lib/services/app_metadata.dart
 M lib/services/course_audit_service.dart
 M lib/services/exercise_field_help.dart
 M pubspec.yaml
 M test/app_metadata_225_04_test.dart
 M test/course_audit_report_225_test.dart
 M test/course_entry_animation_228_test.dart
 M test/exercise_field_help_226_02_test.dart
 M test/exercise_help_224_test.dart
 M test/leaderboard_navigation_test.dart
 M test/learner_round_path_test.dart
 M test/qql_229_revision3_test.dart
 M test/qql_233_revision_platform_contract_test.dart
?? test/select_editor_238_test.dart
?? test/select_gap_fill_238_test.dart
?? test/select_multi_238_test.dart
```

`lib/services/authoring_duplication_service.dart` and
`lib/services/beta_lifecycle_service.dart` are **not** in this list — the
former needed no changes for Phase 2 (see above), the latter was
deliberately left untouched per the user's "do not change expire date"
instruction on the version bump. Always re-run `git status --short` and
`git diff --stat` at the start of the next session rather than trusting this
snapshot blindly, in case anything changed underneath.

## Next steps when resumed

1. Re-orient: run `git status --short`, `git diff --stat`, and re-read this
   file plus `AGENTS.md`'s "Current release boundary" section before making
   any change.
2. Both Phase 1 and Phase 2 are now implemented and validated (`dart format`,
   focused/new tests, and `flutter analyze` all clean; see the Phase 2
   section above for exactly what changed and why). Confirm with the user
   whether to now:
   - run the deferred full `flutter test` suite once, covering both phases
     and the earlier follow-up fixes/SVG cleanup, per the user's original
     instruction to defer it to the end of all tasks; and/or
   - commit this work (do not commit or push until the user explicitly
     asks); and/or
   - start additional interim work first.
3. If the full suite surfaces failures, fix them before treating the release
   as ready — do not silently narrow or skip a failing test to make the
   suite pass.
