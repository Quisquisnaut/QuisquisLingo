# QQL 241 validation status

Target: `2.0.41+241002`, **Build 241, Revision 2**.
Beta expiry: **2026-10-20 23:59:59 local time**, following the 30-day policy
from September 20, 2026.

**Final validation passed. Commit, push and merge to main are authorized.**
The Revision 2 results are recorded at the end of this document. Earlier
sections retain the diagnostic history and the approval status at that time.
No platform executable or package has been generated.

## Completed scope

- Resume WIP commit `15da081ef7871831e9def7c8310b4add8ad5d4d7` on
  `feature/claude-file-store-broken-tests`.
- Replace the five obsolete `CourseEditorService.preferenceWriter` constructor
  uses in four test files with real file-store failure injection. The separate
  `LearnerBackupService.preferenceWriter` API is retained.
- Seed/read course fixtures through `CourseFileStore`; preserve byte-for-byte
  checks for failed replacement and malformed files. Legacy preferences remain
  unread and are not migrated.
- Provide a fresh application-support directory per test, while preserving
  explicitly installed platform mocks.
- Use `tester.runAsync` for awaited storage operations and explicit UI-state
  predicates for filesystem-driven transitions. Home readiness includes its
  status controller when that controller is also reading course files. No
  blanket settling calls, increased test timeouts, or skipped assertions.
- Align `AppResetService`, `InventoryService` and
  `239_RESET_STORAGE_INVENTORY.md` with the physical course store.
- Update version metadata, expiry boundary tests, README and changelog.
- Add `PUBLISHER_SIGNING_GUIDE.md` and the English technical page linked from
  Editor Help. Subsequent owner authorization added the Ed25519 verifier,
  trusted registry, developer signing tool, Dummy fixtures/configuration and
  current operational instructions. Course Types now has three types and a
  four-column 12-point table in English and Italian.

## Diagnostic evidence before the version update

These checks ran on the developing tree; subsequent changes prevent treating
them as final validation of Build 241.

| Check | Observed result |
|---|---|
| Intermediate `flutter analyze --no-pub` | No issues found |
| Reset and inventory focused files | 27 tests passed |
| Editor layout, official-course UI, persisted learner delivery, provisional workflow and production transaction files | 38 tests passed |
| Initial complete-suite diagnostic attempt | Interrupted at 974 passed and 16 failed after locating a widget helper blocked on a direct filesystem await |
| Focused corrections for diagnostics, Home navigation and audio-state refresh | 64 tests passed |
| Remaining 90 diagnostic test files | 832 passed, one metadata-dialog synchronization failure |
| The remaining Temporary Sample metadata-dialog case after correction | Passed in isolation |

The earlier failures in hierarchy indicators, draft-container visibility,
Course Info wording, Guidebook delivery and MP3 Help also passed their focused
reruns. The MP3 Help test now reads the actual content provider instead of
searching the obsolete screen source file.

## Focused checks after the version update

- Metadata, Beta lifecycle, audit report, platform-version contract and
  revision-3 editor tests: **27 passed**.
- Welcome and Beta-expiry dialog tests: **2 passed**.
- Publisher-signing Help and existing Help translation tests: **11 passed**,
  including English/Italian navigation, document/content agreement and selectable
  commands on 320 px light/dark layouts. No test timeout increases.
- Targeted Dart analysis of the five Help source/test files: no issues found.
- OpenSSL 3.5.7 smoke check with disposable keys: encrypted Ed25519 key creation,
  public export, DER fingerprint, nonce and challenge signing/verification passed;
  tampered challenge rejected. Temporary keys were removed. This does not test
  QQL course signing; the later integration evidence is recorded below.
- `git diff --check`: no whitespace errors.

These are targeted checks of the update, not the final complete-suite run.

## Earlier final-validation plan (now authorized)

The owner has now authorized this plan: run the final analyzer and complete Flutter suite on the
unchanged Build 241 tree. Diagnose any new failure without weakening the tested
contract. Platform build or packaging checks require their requested release
scope; none have been performed for Build 241.

The historical Build 240 validation document describes its own earlier tree
and is not evidence of Build 241 release readiness.

## Publisher verification implementation (subsequent authorized scope)

- Protocol `qql-ed25519-v1` authenticates the model-normalized official checksum,
  publisherId and keyId with Ed25519; Course Model v9/v10 is unchanged.
- Transfer parsing and storage both verify signatures. Stored external sources
  and backups derive authenticity on read; unverifiable source files/progress
  are preserved. Learner delivery excludes unverified external sources.
- A newer signed replacement of an unverified source requires explicit
  association. Normal course identity, publisher and provenance checks remain.
- Dummy is absent from normal trust. The explicit test flag enables it in
  debug/profile/release-mode test builds and adds a TEST ONLY banner. No public
  release build has been created. No real publisher has been approved.
- The signature covers JSON, including embedded data, but not bytes of separate
  media files. Revocation becomes effective when the app registry is updated.
- Developer tool `tools/sign_course.dart` prepares canonical bytes and attaches
  an independently checked OpenSSL signature without reading private keys.
- OpenSSL-signed Dummy fixtures v1/v2 were accepted by the Dart verifier; a
  changed challenge and altered course payload were rejected in focused checks.
- The initial missing-signature test failed because the old service accepted
  the unsigned course; it passed after the verifier was connected.
- Regression group (transactions, official storage/UI, forks, authoring transfer
  and persistence hardening): **90 passed**.
- Integration group (signature/UI, Help, native dialogs, transfer, publication
  and persisted learner delivery): **48 passed** before the final small guide
  and parser refinements.
- Explicit Dummy-enabled configuration: **9 verifier tests passed**.

These are focused development checks, not the withheld full-suite validation.

### Latest focused evidence

- Final focused group after guide/parser/UI refinements: **40 passed** (verifier,
  import UI, Help, backup clean cut, lineage, all ten bundled source checks and
  metadata wording).
- Added a dedicated rotation case with a genuinely different Ed25519 key pair:
  latest verifier run **10 passed**, including rotation and old-key revocation.
- Targeted analysis of all 26 changed/new implementation and test files:
  **No issues found**. The subsequently added rotation test file was analyzed
  again: **No issues found**.
- `git diff --check`: no whitespace errors (only existing CRLF notices).
- No complete-suite run, release build, commit or push was performed for this
  signature tranche. That checkpoint was Build 241 Revision 0, expiry 2026-10-20 23:59:59 local.

## Revision 1 metadata update

The owner requested Build 241 Revision 1 before final validation. The platform
version is now `2.0.41+241001`; App Info/Settings and report expectations use
Build 241, Revision 1. The Beta expiry is recalculated under the existing 30-day
policy from September 20, 2026, so it remains October 20, 2026 at 23:59:59 local.

Earlier focused results above describe their respective implementation checkpoints.
They do not constitute final validation of Revision 1. The manual inspection
checklist is `241_REVISION_2_VISUAL_CHECKLIST_IT.md`.

Revision 1 focused metadata checks: **27 passed** across metadata, Beta lifecycle,
platform version contract, revision-3 UI and audit-report tests. No source/test
reference still expects 241000 or Build 241 Revision 0. Historical Revision 0
checkpoint notes are retained explicitly as history. `git diff --check` passed.
No executable was built and final complete-suite validation was not started.

Targeted analysis of the seven Revision 1 metadata/lifecycle source and test files: **No issues found**.


## Personal course libraries — implementation follow-up

Implemented per-profile membership, Add/Remove from my courses, optional active-profile course-progress reset, and Available on this device with four sections and dedicated Help. Selector and Manager filter membership independently of Hide. Publisher uninstall requires the active admin and is blocked by any other profile membership, including hidden courses. No course schema or signature changes. Existing version metadata remains Build 241 Revision 1.

Membership storage/reset behavior is documented in 239_RESET_STORAGE_INVENTORY.md. English/Italian Editor Help and the visual checklist include the new flows. Membership does not change authoring rights. Existing learner progress can preserve a pre-library association; that association is recorded so a later progress reset does not remove membership.

Focused verification: 38 UI/help/creation/admin-navigation tests passed; 19 menu/layout regression tests passed and the remaining return-to-Manager test passed in isolation after changing its offscreen-row wait to a loaded-page predicate. Targeted Dart analysis of 18 changed source/test files was clean. Test asset caches are cleared per test to prevent futures crossing fake-async zones; no timeout increases or blanket pumpAndSettle additions.

The complete test suite, final release validation and executable build have NOT been run; they remain pending the owner's OK. See the current focused-run evidence added below.


Final focused evidence for personal libraries:
- 50 tests passed: course_library_test (six service/UI cases), persisted_learner_delivery_226_04_r1, app_reset_service_239, inventory_239, qql_229_revision2.
- 12 tests passed: publisher_import_ui and publisher_verification, including refreshed Publisher Course wording.
- Final targeted analysis: 19 source/test files, no issues. git diff --check: no whitespace errors (existing LF/CRLF warnings only).
- Prior targeted UI group: 38 passed; menu/layout group: 19 passed plus the sole corrected test passed on its focused rerun. Counts overlap and must not be summed into a unique suite total.
- Visual checks and full-suite/release validation remain pending owner approval. No commit, push or release executable was produced.


## Device-list refinements and removal of Hide

- Added a Maintainer line to every device-list course (local Custom maintainer name, publisher for Bundled/Publisher, explicit missing-profile fallback).
- Added Added · Remove with the same cancellation/progress-reset confirmation; alphabetic ordering within each section.
- Removed Selector Hide/Unhide, retired their settings API and removed course-visibility references from English/Italian Help and App Info. Stored legacy visibility keys are ignored, not converted into membership removals.
- Added direct Selector Import Course navigation. The import-only route returns to Home, never exposes Course Manager, and does not enable its per-profile unlock. Copy/Fork authoring options remain gated when entering this way. Import collisions inspect all installed courses, including courses outside the personal library.
- Missing-signature error now says: Publisher signature missing. This file cannot be imported as a Publisher Course.

Evidence: 25 focused library/import/organization/translation tests passed; the direct-import/retired-visibility navigation regression passed; final 16 library/signature tests passed (groups overlap). Targeted analysis of 12 changed source/test files passed; git diff --check passed. No timeout increases. Final complete validation and executable generation still await the owner's OK.


## Revision 2 final validation

Owner authorized full validation, commit, push and merge to main. Version: 2.0.41+241002. Beta expiry remains 2026-10-20 23:59:59 local (same release date, 30 days). Results will be recorded below.

Initial Revision 2 full-suite attempt: 1,868 passed, nine failed. Failures were localized to an unsaved Course Manager fixture, an obsolete source-structure assertion, and filesystem-dependent Home/profile/widget transitions. Corrections preserve the assertions and use observable completion states; no test timeout was increased. The device-name UI now reflects the saved name before course reloading completes.

The owner requested clearer removal/reset wording during validation. Confirmation and English/Italian Help now explicitly preserve all XP (including Weekly XP and XP earned from the removed course), total/per-language study days and streak. The membership regression test also verifies this preservation.

During validation the owner also requested that the empty-library screen retain Settings and Course Manager when activated. Settings/Profile/User Data/Audio/Admin routes now accept no current course; only course-specific reset and voice testing require a selected course. The manager can open with no current course, and removed courses are not silently re-added. The regression traverses empty Home, Settings, Audio, Profile, User Data, conditional Manager and device discovery.

The next full-suite run was intentionally stopped after 349 passing tests (about three minutes) to include the owner-requested blue outlined unavailability labels. Its connection-closed error was caused by termination and is not a product failure. The device-list regression now checks both blocking labels at 320 px in light and dark themes.

Device-list titles are bold with the final owner-selected colors: Bundled black, Publisher purple, Custom orange. Bundled titles are white on black in dark mode, as requested by the owner. At narrow widths Add/Remove moves below the information; the 320 px light/dark regression checks title colors, borders and absence of layout exceptions.

A further early full-suite attempt was intentionally stopped to include the requested 12 px spacing between device discovery and the enabled Course Manager button on empty Home. Final results below supersede interrupted attempts.

After the successful 1,879-test full run, the owner explicitly requested only the Publisher title color change from pink to purple, with focused tests and no repeat full run. This overrides the usual repeat-suite rule for this final presentation-only change. The source/test/tool hash snapshot confirmed no changes occurred during the successful full run.

## Final result — Build 241 Revision 2

- Complete Flutter suite: **1,879 passed, zero failures**, 21 min 02 sec; exit 0.
- Final Publisher purple change: **8 focused course-library tests passed**, including narrow light/dark layouts, empty-library navigation and XP/activity preservation; exit 0. No repeat full run, explicitly requested by the owner.
- Final complete static analysis after the purple change: **No issues found**, exit 0.
- Bundled course validator: **10 courses valid**. Image Bank: **111 assets, zero issues**. Media integrity: **443 files, 19 locked audio files, 281 flags, 22 static references, zero issues**. Lesson icons: **14 assets, zero issues**.
- Dependency resolution and whitespace checks passed. The explicitly enabled Dummy configuration also passed its focused verification run (28 overlapping tests); normal full-suite configuration excludes Dummy.
- Beta expiry: **October 20, 2026, 23:59:59 local**. Source version: **2.0.41+241002**.
- No platform release executable, installer or package was generated. Manual device checks remain a checklist, not claimed as executed; see 241_REVISION_2_VISUAL_CHECKLIST_IT.md.

Git attributes explicitly disable text conversion for the binary publisher fixtures. Staged bytes match working-tree bytes; independent OpenSSL verification of the checked-in payload/signature succeeded. This packaging safeguard does not change runtime code.
