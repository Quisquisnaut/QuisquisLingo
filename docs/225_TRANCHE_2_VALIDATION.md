# QuisquisLingo 2.0.25 Build 225.02 validation

Validated on 2026-09-04 from preserved first-tranche commit `563aad13bb259512bbcae67d5dd92eee39bc7105`. This second tranche remains uncommitted pending explicit approval. Nothing was packaged or pushed.

## Release boundary

- Display version: `2.0.25`
- Display build: `225.02`
- Platform-compatible technical version: `2.0.25+22502`
- Alpha expiry: unchanged at `2026-10-04 23:59:59`
- Canonical course format: Course Model v6 only
- Course Editor v6 storage is isolated from earlier namespaces. Old formats are rejected clearly without migration, partial loading or deletion.

Build 225.02 requires canonical UTC `updatedAt` values on Lesson, Round and Exercise objects. A successful editor save changes only the explicitly saved object's timestamp; child saves do not change parent timestamps. Duplication preserves source timestamps, while newly generated content receives an explicit creation timestamp. Load, view, Audit, copy, import/export round-trip and formatting do not rewrite timestamps.

## Functional result

- Removed only the missing-Listening-comprehension Info classification. Malformed listening content remains invalid.
- Reading Comprehension now reports an Error for no lexical words, `READING_PASSAGE_TOO_SHORT` Warning for one or two Unicode/apostrophe-aware words, and no short-passage finding for three or more.
- Hint repetition produces `HINT_REPEATS_PROMPT`; revealing a canonical correct answer remains an Error.
- Exercise saves persist transactionally through Round, Lesson and Course storage, reconcile only the saved child baselines and leave independent parent edits dirty. Persistence failure clears no dirty state.
- Exercise and feedback renderers use semantic Light/Dark theme surfaces.
- Empty Round titles are valid and display as the current position-derived `Round N` on learner, editor, Review, Audit and report surfaces without changing identity.
- Audit supports deterministic recently-modified ordering and severity-local progressive numbering in UI, copy and export.
- Build the translation stores and evaluates one or more literal `correctOrders` in author order, validates exact block occurrences, and shows all configured translations after correct or incorrect responses. Type-the-translation expression syntax, similarity and typo tolerance are deliberately excluded.

## Bundled course registry

Before this tranche:

| File | Course ID | Direction | Schema | TTS |
| --- | --- | --- | --- | --- |
| `dutch_en.json` | `sample_nl_en_nl` | English → Dutch | v5 | `nl-NL` |
| `english_es.json` | `sample_en_es_en` | Spanish → English | v5 | `en-GB` |
| `finnish_en.json` | `sample_fi_en_fi` | English → Finnish | v5 | `fi-FI` |
| `german_en.json` | `sample_de_en_de` | English → German | v5 | `de-DE` |
| `italian_en.json` | `sample_it_en_it` | English → Italian | v5 | `it-IT` |
| `portuguese_en.json` | `sample_pt_en_pt` | English → Portuguese | v5 | `pt-PT` |
| `spanish_en.json` | `sample_es_en_es` | English → Spanish | v5 | `es-ES` |
| `welsh_en.json` | `sample_cy_en_cy` | English → Welsh | v5 | `cy-GB` |

After this tranche, the same eight course identities and directions use v6, and the registry adds:

| File | Course ID | Direction | Schema | TTS |
| --- | --- | --- | --- | --- |
| `korean_en.json` | `sample_ko_en_ko` | English → Korean | v6 | `ko-KR` |

The exact production registry now contains nine bundled courses. All use four playable Rounds per Lesson, at least 25 actual Duel-eligible Exercises per Lesson, existing registered Lesson icons, globally unique IDs and valid references. Korean uses the South Korean flag and polite beginner Hangul content.

## Audit totals

| Course | Before Errors | Before Warnings | Before Info | After Errors | After Warnings | After Info |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Dutch | 39 | 8 | 60 | 0 | 0 | 0 |
| English from Spanish | 38 | 8 | 60 | 0 | 0 | 0 |
| Finnish | 37 | 8 | 60 | 0 | 0 | 0 |
| German | 38 | 8 | 149 | 0 | 0 | 0 |
| Italian | 0 | 0 | 42 | 0 | 0 | 0 |
| Portuguese | 39 | 8 | 60 | 0 | 0 | 0 |
| Spanish | 38 | 8 | 59 | 0 | 0 | 0 |
| Welsh | 38 | 8 | 60 | 0 | 0 | 0 |
| Korean | n/a | n/a | n/a | 0 | 0 | 0 |
| **Aggregate** | **267** | **56** | **550** | **0** | **0** | **0** |

No Info classifications remain in the final nine production assets. The general Info severity and genuinely non-blocking rules remain available for custom authoring content.

## Deterministic generation evidence

Two consecutive regeneration runs produced the same asset bytes, and final `--check` reproduced these SHA-256 values:

| Asset | SHA-256 |
| --- | --- |
| `dutch_en.json` | `2571ffe0fc46fe4468b5e125d5898d1fb2553340e276c04b782d2f6313f1a327` |
| `english_es.json` | `8501eb69fb2852d2faaa961e386b9a44b82dc1e4b87ceebc4ac753a6898ab96f` |
| `finnish_en.json` | `f280b1fdeedac8b3468da620888695b1d2f98e7eb792b92ac45ce33a140dc7f8` |
| `german_en.json` | `96ab44e8d665a96fde5dd3c0d1c275d6faa3160ea22dabbaac88490efa8b9034` |
| `italian_en.json` | `4a55e485caebfed8e5766e9b52af2844dee38bca9a8f980059a49ec90c6f649f` |
| `portuguese_en.json` | `f7672f1653d185f41dd1f98eb80c3c9234353b25d33497d0741daf38958fddfd` |
| `spanish_en.json` | `fb40ffd69ee364d52d694625a334ed3a68216f5ab79ba84b1dda2f6ef53f2454` |
| `welsh_en.json` | `adb725e3d500f1b0051db496a9ee73bc38016974350555f2e476386494c640ec` |
| `korean_en.json` | `11d777241ae8e355e8db27e8bfcc1687f88c82940e62952d66ced64d23e74159` |

These equal hashes compare two consecutive regenerated outputs. They do not claim that an original pre-regeneration asset was identical to its regenerated replacement.

## Automated validation

- `flutter pub get`: passed. It reported 28 newer package versions incompatible with current constraints.
- Focused authoring Audit/UI/sample/bundled tests: 27 passed.
- Focused Audit and Guidebook tests: 34 passed.
- Focused schema/storage/import tests: 54 passed.
- Focused expiry/welcome and text-entry refocus regressions: passed.
- Final timestamp-copy plus generator/hierarchical-save group: 15 passed.
- `flutter test --no-pub`: 565 passed in 4 minutes 49 seconds.
- `flutter analyze --no-pub`: exited 1 with 73 findings: 72 `curly_braces_in_flow_control_structures` Info notices and one pre-existing unused `_tapAndSettle` warning in `test/guidebook_sentence_generator_test.dart`; zero analyzer Errors and no new Warnings.
- `python tools/validate_courses.py`: passed all exactly nine Course Model v6 assets.
- `python tools/validate_lesson_icons.py`: passed, 14 assets and zero issues.
- `python tools/validate_images.py`: exited 1 for the known pre-existing missing `assets/exercise_images/hello.webp`; 113 Image Bank entries and no other issue. The missing file is referenced by the pre-existing Image Bank manifest, not by any bundled course, production Dart file or `pubspec.yaml`, so it remains outside this tranche.
- Changed/untracked Dart formatting check: passed, 47 files examined and zero changes required.
- `python tools/regenerate_bundled_courses_225_02.py --check`: passed all nine assets with the hashes above.
- Incompatible-format rejection: v5, timestamp-free, legacy `correctOrder`, legacy evaluation flags, corrupt current storage and old import paths are covered by passing model/storage/transfer tests. Source data remains intact.
- `git diff --check`: passed. All untracked proposed files also passed equivalent no-index whitespace checks.
- Windows release-mode test build: passed in 203.8 seconds. Candidate executable: `build/windows/x64/runner/Release/quisquislingo_app.exe`. No ZIP or distributable package was created.

## Outstanding manual Windows checks

The following runtime/UI checks remain outstanding:

1. Settings Version and Build.
2. Ten-tap activation.
3. Dark mode legibility.
4. Light mode regression.
5. Build the translation with multiple answers.
6. Display of all answers after correct and incorrect responses.
7. Hierarchical saving.
8. Unsaved-change behavior.
9. Untitled Round fallback.
10. Reading passage Warning.
11. Absence of missing-Listening Info.
12. Audit numbering.
13. Recently modified sorting.
14. Copy report.
15. Export report.
16. Aggregate nine-course Audit.
17. Korean course visibility, flag, TTS, Rounds and Duel.
18. Representative playability for every bundled course.
19. Clear rejection of an incompatible old-format import without data deletion.

## Proposed commit files and summaries

1. `AGENTS.md` — advances the repository boundary and invariants to Build 225.02 and Course Model v6.
2. `CHANGELOG.md` — records the complete second-tranche release changes while retaining Build 225.01 history.
3. `README.md` — updates current build/schema and nine-course overview.
4. `assets/courses/dutch_en.json` — deterministic Dutch v6 regeneration.
5. `assets/courses/english_es.json` — deterministic Spanish-to-English v6 regeneration.
6. `assets/courses/finnish_en.json` — deterministic Finnish v6 regeneration.
7. `assets/courses/german_en.json` — deterministic German v6 regeneration.
8. `assets/courses/italian_en.json` — deterministic Italian v6 regeneration through the unified pipeline.
9. `assets/courses/korean_en.json` — new deterministic Korean-from-English v6 bundled course.
10. `assets/courses/portuguese_en.json` — deterministic Portuguese v6 regeneration.
11. `assets/courses/spanish_en.json` — deterministic Spanish v6 regeneration.
12. `assets/courses/welsh_en.json` — deterministic Welsh v6 regeneration.
13. `docs/225_TRANCHE_2_VALIDATION.md` — this complete implementation and validation record.
14. `docs/COURSE_EDITOR.md` — documents v6 authoring, nested saves, Audit changes, hints, optional titles and literal translations.
15. `docs/COURSE_JSON_FORMAT.md` — defines strict v6 timestamps, `correctOrders`, optional Round titles and rejection boundary.
16. `docs/LOGIC.md` — documents v6 storage and transactional editor behavior.
17. `docs/SAMPLE_COURSE.md` — documents deterministic regeneration and the nine-course registry.
18. `lib/main.dart` — uses authoritative metadata for updates and includes Korean startup flag art.
19. `lib/models/course_models.dart` — implements the strict v6 model, timestamps, optional titles and multiple ordered answers.
20. `lib/models/exercise_authoring.dart` — updates Build-the-translation authoring guidance.
21. `lib/models/normalized_import_exercise.dart` — requires timestamps when normalized imports become Exercises.
22. `lib/screens/course_editor_screen.dart` — implements nested persistence, timestamped mutation, Audit UI changes and multiple-answer authoring.
23. `lib/screens/course_projects_screen.dart` — creates timestamped v6 projects and updates schema labels.
24. `lib/screens/credits_screen.dart` — includes Korean course credits.
25. `lib/screens/editor_help_screen.dart` — updates in-app help for all v6 and Audit/editor behavior.
26. `lib/screens/home_screen.dart` — uses the authoritative technical version for welcome state.
27. `lib/screens/info_screen.dart` — displays Version and Build and updates metadata wording.
28. `lib/screens/review_screen.dart` — uses the canonical optional-Round-title fallback.
29. `lib/screens/round_screen.dart` — adds semantic theme surfaces, multiple literal answer runtime/feedback and text-entry refocus.
30. `lib/screens/settings_screen.dart` — displays authoritative Version/Build and retains the full-row ten-tap target.
31. `lib/screens/update_settings_screen.dart` — uses authoritative technical version metadata for checks.
32. `lib/services/app_metadata.dart` — centralizes release, display build and platform-compatible version values.
33. `lib/services/authoring_duplication_service.dart` — remaps `correctOrders` and preserves timestamps while duplicating.
34. `lib/services/course_audit_report_service.dart` — exports metadata, timestamps, numbering, recent sort and fallback titles.
35. `lib/services/course_audit_service.dart` — implements revised coverage, Reading, Hint, ordering, numbering and Build rules.
36. `lib/services/course_editor_service.dart` — introduces isolated v6 storage and safe failure without deleting invalid data.
37. `lib/services/course_service.dart` — registers Korean and loads v6 assets.
38. `lib/services/crash_log_service.dart` — records the centralized technical version.
39. `lib/services/custom_course_transfer_service.dart` — adds a deterministic transfer-directory seam for v6 round-trip tests.
40. `lib/services/guidebook_round_generator.dart` — creates timestamped v6 drafts and canonical Build answers.
41. `lib/services/report_service.dart` — applies optional Round-title fallback to learner reports.
42. `lib/services/startup_diagnostic_backend_io.dart` — uses authoritative technical metadata for startup diagnostics.
43. `lib/widgets/flag_art.dart` — renders the bundled South Korean flag.
44. `pubspec.yaml` — sets platform-compatible version `2.0.25+22502`.
45. `test/app_metadata_225_02_test.dart` — covers metadata synchronization and the full-row ten-tap target.
46. `test/authoring_audit_ui_224_test.dart` — extends scoped Audit UI coverage for recent sort and numbering.
47. `test/authoring_duplication_service_test.dart` — verifies duplication preserves timestamps.
48. `test/bundled_courses_225_02_test.dart` — enforces all nine production Audit/playability/Duel/TTS/flag gates.
49. `test/contextual_comprehension_224_test.dart` — updates the schema description to v6.
50. `test/course_audit_225_02_test.dart` — covers Reading, Hints, removed Listening Info, timestamps, ordering, numbering and titles.
51. `test/course_audit_report_225_test.dart` — updates report metadata and numbering expectations.
52. `test/course_audit_test.dart` — updates canonical ordered-answer fixtures and Listening expectations.
53. `test/course_author_metadata_test.dart` — verifies the isolated v6 storage namespace.
54. `test/course_editor_225_test.dart` — covers Build translation CRUD, literal answers, validation, reload and runtime.
55. `test/course_editor_storage_v6_225_02_test.dart` — covers safe v6 storage and corrupt-data preservation.
56. `test/course_model_v5_test.dart` — removes the obsolete v5 model suite.
57. `test/course_model_v6_test.dart` — adds strict v6 schema, timestamp, title and `correctOrders` coverage.
58. `test/course_transfer_v6_225_02_test.dart` — covers v6 import/export and safe old-format rejection.
59. `test/exercise_architecture_224_test.dart` — updates canonical v6 evaluation fixtures.
60. `test/exercise_dark_mode_225_02_test.dart` — covers Light/Dark renderer families, feedback and widths.
61. `test/hierarchical_editor_save_225_02_test.dart` — covers transactional child saves and dirty-state reconciliation.
62. `test/imported_course_v5_regression_test.dart` — removes the obsolete v5 import regression suite.
63. `test/imported_course_v6_regression_test.dart` — adds strict v6 import regression coverage.
64. `test/info_screen_test.dart` — verifies Version and Build in App Info.
65. `test/leaderboard_navigation_test.dart` — updates welcome metadata and Round fallback expectations.
66. `test/learner_round_path_test.dart` — updates welcome-state metadata for Build 225.02.
67. `test/sample_courses_test.dart` — expands schema/content expectations to all nine courses.
68. `tools/regenerate_bundled_courses_225_02.py` — adds the authoritative deterministic nine-course generator and check mode.
69. `tools/regenerate_italian_course_225.py` — delegates the historical entry point to the unified v6 generator.
70. `tools/regenerate_sample_courses_v5.py` — prevents obsolete v5 generation by delegating to the v6 pipeline.
71. `tools/validate_courses.py` — validates the exact nine-file v6 registry, timestamps, IDs, references, playability, Duels and locales.

Nothing is staged. No Build 225.02 commit, package or push has been created.
