# QQL 235 validation

Validation target: QuisquisLingo `2.0.35+235000`, displayed as **Build 235,
Revision 0**. QQL 235 is the first Beta release. Course Model v9, authored
Course JSON, learner persistence, progression, XP, Review and Duel behavior
remain unchanged.

## Beta lifecycle

- The transparent pre-release gate remains time-limited through
  `2026-10-15 23:59:59` local time.
- Expiry continues to block learner exercises, Review and Duels without
  deleting learner profiles, progress, courses, edits or settings. Course
  Editor remains available for recovery/export.
- The active lifecycle service, UI prompts, startup diagnostics and package
  conventions use Beta terminology. The release does not retain a
  compatibility alias for the former release channel.

## Static-analysis assessment

- `analysis_options.yaml` includes the standard
  `package:flutter_lints/flutter.yaml` rules.
- No lint rules are disabled and no Dart source uses analyzer-ignore
  directives.
- Baseline `flutter analyze` result before the QQL 235 release change:
  **0 errors, 0 warnings, 0 lints and 0 deprecations**.

## Final release gate

- `flutter pub get` — PASS
- `dart format --set-exit-if-changed <touched Dart files>`
- focused lifecycle, metadata, startup, package naming and update tests —
  PASS (45 tests)
- `flutter analyze` — PASS (0 issues)
- `flutter test`
- `git diff --check`

The complete suite remains blocked by nine unrelated pre-existing fixture
failures: one stale bundled-Course count and eight Course v9 provenance
fixtures that save custom Courses without required immutable provenance.
