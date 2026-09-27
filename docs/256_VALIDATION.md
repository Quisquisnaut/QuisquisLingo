# Build 256 validation

Evidence per revision. Commands run from `C:\QQL\QuisquisLingo` (that
spelling) with Flutter 3.47.4 / Dart 3.13.3 on Windows 10, the complete
suite through the keep-awake wrapper (`ES_CONTINUOUS | ES_SYSTEM_REQUIRED`
held for the run and cleared afterwards).

## Revision 0 (2.0.56+256000): canonical definitions, 27 September 2026

- `dart format` on every changed Dart file: clean (12 files formatted, 4
  changed by the formatter on first pass, then stable).
- `flutter analyze --no-pub`: **No issues found** (after two fixes during
  the session: the `library;` directive had to precede the imports of the
  registry file, and `exercise_laboratory_254_test.dart` still read
  `preset.model`).
- Focused tests, first pass (`canonical_primitives_256_test`,
  `capability_registry_256_test`, `content_flow_256_test`,
  `exercise_architecture_224_test`, `translation_choice_239_test`,
  `exercise_laboratory_254_test`, `app_metadata_225_04_test`,
  `course_audit_report_225_test`, `qql_229_revision3_test`,
  `qql_233_revision_platform_contract_test`, `beta_lifecycle_test`,
  `localization_catalog_test`): 278 tests, **276 passed, 2 failed**, both on
  `expect(AppMetadata.build, '255')`, an expectation the version bump had
  not covered.
- Focused tests, second pass after that fix (`app_metadata_225_04_test`,
  `qql_229_revision3_test`, `qql_233_revision_platform_contract_test`,
  `course_audit_report_225_test`): **23 passed**.
- New tests: 7 in `canonical_primitives_256_test` (nine primitives in order,
  strict parsing, strict evaluation-mode parsing, unique option names,
  invalid values never canonical, immutable value semantics, presets
  configure only executable primitives); 11 in
  `capability_registry_256_test` (registry consistency, the evaluation
  matrix, the option inventory, every supported configuration lists every
  enumeration option, parsing drops illegal entries, defaults, legal
  configurations, coded illegal combinations, selection limits, executable
  set, readable-not-executable set, invalid state); 8 in
  `content_flow_256_test` (linear Story, strict identifiers, correctness
  branch, choice branch, conditional transition, every structural issue
  code, cycles).
- Complete suite (`flutter test --no-pub --concurrency=1`, 27 September 2026,
  05:27–05:48): **2,813 passed, 1 skipped, 0 failed** (`All tests passed!`
  after 21 minutes 30 seconds).
- Tree-wide `dart format --set-exit-if-changed lib test tools` reports 61
  files that predate Build 256 (for example `test/storage_roles_255_test.dart`
  and `tools/move_private_storage_255.dart`); they are left untouched, as
  unrelated formatting changes are out of scope. Every file this revision
  changed is formatted.
