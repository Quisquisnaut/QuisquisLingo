# QQL Build 225.04 validation

## Candidate

- Version: `2.0.25`
- Display Build: `225.04`
- Technical version: `2.0.25+22504`
- Alpha expiry: `2026-10-04 23:59:59`
- Immutable parent: Build 225.03, commit `94a7c008d35e010cc48c43a3525a7f35f610c206`
- `origin/main` at preflight: `c58e6c9d0d17bccb752a40c12c6f313d4747aa9b`

Build 225.03 and its Build 225.02 parent were not amended, rewritten, squashed, or reverted.

## Root cause and correction

The earlier editor used several independently persisted screen models and several
independent dirty baselines. A nested save could write a child branch while a parent
route still compared a stale hierarchy snapshot, and other mutations could update a
different screen-local copy. Screen-specific PopScope reconciliation therefore could
not provide one authoritative answer to whether the complete course had unapplied
changes.

Build 225.04 replaces that boundary with one course-level transaction:

```text
persisted course
-> immutable original snapshot
-> editable working copy
-> one top-level course transaction
```

All nested editors stage only into the working copy. Nested actions are `Save` and,
where Draft is supported, `Save as draft`; nested `Publish` terminology is removed.
Back from a nested form discards only that form's unstaged input without a confirmation.
Canonical semantic comparison ignores transient UI state and becomes clean again when
the author restores the original course content.

Only leaving the top-level Course Editor can offer `Confirm course changes` or
`Cancel course changes`. Confirmation validates the final v6 course, requires the
active local QQL profile for the author snapshot, creates and verifies a complete
pre-change backup when a persisted course exists, increments the applicable local
course version exactly once, atomically replaces and verifies persistence, and exits
only after success. Cancellation discards the whole working copy without a backup or
version increment. Backup or persistence failure preserves both the original live
course and the working copy and keeps the editor open.

## Versioning, provenance, backup, and history

- Custom courses use a monotonic integer `courseVersion`; the first confirmed new
  course is version 1 and has no fictitious pre-change backup.
- Bundled and external official courses retain publisher identity, official version,
  release timestamp, canonical SHA-256 checksum, channel, release notes, and explicit
  verification status. Local edits use a separate monotonic local version.
- Bundled sources are immutable. A local official variant records the exact official
  base identity/checksum. A newer official source archives the active local course and
  activates the exact new official source without a silent merge.
- External official imports are visibly unverified unless a supported verification
  result says otherwise. Same-course publisher collisions are rejected; a separate
  custom copy receives a new course ID.
- Backups are stored below
  `Documents/QuisquisLingo/Exports/Course Backups/<sanitized-course-id>/` with canonical
  Course Model v6 JSON, a manifest, checksums, complete course-owned audio, UTC author
  and time metadata, reason, and optional version notes. Backup validation rejects
  corruption, missing assets, and wrong-course archives.
- Version history is newest first, exposes the resolved backup folder and Open-folder
  action, preserves historical notes, and restores a compatible snapshot into the
  working copy. A later confirmation always advances from the active version rather
  than reusing the historical number. An incompatible historical official base may be
  inspected/exported or forked as a new custom course, but cannot overwrite the active
  official lineage.
- Stored timestamps remain UTC and Course Info/history display local date and time.
  Official release notes and local work notes remain separate.

## Production-path coverage

The Build 225.04 tests exercise the actual production screens and callbacks rather
than only mutating models:

- Course -> Lesson -> Round -> Exercise Draft and normal Save flows stage in one
  working copy, produce no nested confirmation, confirm once at Course level, and
  survive full service reload.
- Course Info, Lesson/Round/Exercise create, edit/rename, delete and reorder,
  GuideBook edits, generated-content acceptance, Audit of the working copy, semantic
  revert-to-clean, mixed confirmation, complete cancellation, optional notes, no-change
  exit, and failed persistence are covered.
- Transaction service tests cover new/existing custom versions, missing profile,
  author/time data, backups and course-owned audio, collision-safe paths, corrupt and
  wrong-course backups, backup/persistence failure, official/local versions, bundled
  and external official updates, duplicate publisher identity, restore monotonicity,
  and custom forks.
- The real Korean selector regression starts from existing v6 state without Korean,
  opens the production selector, verifies all nine courses and the Korean flag/name,
  opens Korean and a playable Round, restarts state, and verifies one persistent Korean
  entry without changing custom or learner data.
- All nine bundled source assets are loaded through the production loader and verify
  their official provenance and canonical checksums. The aggregate Audit gate reports
  0 Errors, 0 Warnings, and 0 Info.

## Automated results

- `flutter pub get`: passed. It reported 25 newer versions incompatible with current
  constraints. Four unrelated transient resolution upgrades and Flutter's unsolicited
  `analysis_options.yaml` rewrite were not retained; only the direct `crypto` dependency
  classification is proposed.
- Focused Build 225.04 suites: passed, including transaction, production multi-screen,
  history, provenance, Korean production discovery, metadata/ten-tap, navigation order,
  v6 storage rejection, and Creation Wizard nested-back behavior.
- `flutter test --no-pub --concurrency=1`: passed, 579 tests, 8m24s. Serial execution is
  used because multiple legacy widget files replace process-global platform-channel and
  SharedPreferences mocks; default cross-file parallelism produces mock-state races.
- `flutter analyze --no-pub`: exited 1 with exactly 73 pre-existing findings: 72
  `curly_braces_in_flow_control_structures` Info notices in untouched files and one
  `unused_element` warning for `_tapAndSettle` in
  `test/guidebook_sentence_generator_test.dart:255`. No Build 225.04 file has an
  analyzer finding. These unrelated findings were not changed or suppressed.
- `python tools/validate_courses.py`: passed; 9 bundled Course Model v6 files.
- `python tools/validate_lesson_icons.py`: passed; 14 assets, 0 issues.
- `python tools/validate_images.py`: exited 1; 113 entries, one known pre-existing issue:
  missing `assets/exercise_images/hello.webp`. Its intentional absence is covered by an
  existing regression and is unrelated to Build 225.04.
- Two consecutive `python tools/regenerate_bundled_courses_225_02.py --check` runs:
  passed byte-for-byte for all nine assets with identical per-course SHA-256 values.
- `git diff --check`: passed. Git emitted only working-tree LF/CRLF conversion
  notices and no whitespace error.
- `flutter build windows --release`: passed. Flutter reported 329.0s for the
  application build after 117.3s of one-time Windows SDK preparation (about 7m26s
  total). The test executable is
  `build/windows/x64/runner/Release/quisquislingo_app.exe`; Windows file and product
  versions are both `2.0.25+22504`, while Settings uses the centralized display
  values `Version: 2.0.25` and `Build: 225.04`.
- The compiled Korean asset is
  `build/windows/x64/runner/Release/data/flutter_assets/assets/courses/korean_en.json`.
  It is byte-identical to the validated source asset with SHA-256
  `afa6e10c91d78fa857a94ae50e7e14297d80174802d7761c0b0db754f740ac43`, and
  the production `CourseService` registry loads that exact asset path.

## Outstanding manual Windows checks

None of these checks is marked passed. They remain for user validation of the test
candidate:

- [ ] Version and Build display
- [ ] Lesson-list position
- [ ] Round-list position
- [ ] Nested Save
- [ ] Nested Save as draft
- [ ] Course Info change
- [ ] Lesson creation
- [ ] Lesson rename
- [ ] Lesson deletion
- [ ] Round creation
- [ ] Round rename
- [ ] Round deletion
- [ ] Exercise creation
- [ ] Exercise editing
- [ ] Exercise deletion
- [ ] One top-level confirmation
- [ ] Complete cancellation
- [ ] Optional notes
- [ ] Course version display
- [ ] Author display
- [ ] Date and time
- [ ] Backup folder
- [ ] Open backup folder
- [ ] Version history
- [ ] Historical notes
- [ ] Restore into working copy
- [ ] Monotonic restore version
- [ ] Bundled official version display
- [ ] External official version display
- [ ] Official update resetting active local changes
- [ ] Archived local history
- [ ] Korean visibility
- [ ] No-change exit without dialog
- [ ] Dark mode
- [ ] Persistence after restart
