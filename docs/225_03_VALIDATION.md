# QQL 2.0.25 Build 225.03 validation record

Date: 2026-09-04

Candidate metadata: `2.0.25+22503` / display Build `225.03`

Preserved Alpha expiry: `2026-10-04 23:59:59`

Parent Build 225.02 commit: `a9994280bdc9eb9433654f28b44e4d2171c8a708`

This correction candidate preserves the committed Build 225.02 tree and addresses the two blocking failures found during its first real Windows inspection. Neither fix is marked manually passed; both require a new user retest of the Windows candidate.

## Root causes and corrections

### Korean bundled course absent

The Korean Course Model v6 asset, stable course ID, registry entry, flag painter and TTS metadata were present in Build 225.02. The user-facing Home course selector nevertheless used a separate hard-coded list containing only `IT`, `DE`, `ES`, `EN`, `CY`, `NL`, `PT` and `FI`. It never consulted the complete production registry, so `KO` could not appear in the real selector.

Build 225.03 makes Home derive its bundled list from `CourseService.courseAssets`, the same registry used by the production `rootBundle` loader. Startup also reconciles a device-local v6 bundled discovery index to that authoritative list. Reconciliation is ordered, idempotent and duplicate-free, and does not read or modify custom-course storage, learner profiles, progress, XP or any older schema.

### Repeated parent confirmations after Exercise save

The Build 225.02 route callbacks did persist a saved Exercise and propagate the result through Round, Lesson and Course baselines. The Round editor then rebuilt every exercise-backed v6 `LearningContent` wrapper with `LearningContent.fromExercise`. That simplified projection discarded untouched wrapper fields such as `required`, `sourceRefs`, role and editor-template metadata. The reconstructed current Round therefore differed structurally from its persisted baseline and activated the unchanged `PopScope` warning in Round and then its ancestors.

Build 225.03 replaces only the saved Exercise payload inside its existing v6 Content wrapper. It preserves wrapper identity, publication state, requiredness, role, template, source references and Presentation actions while reconciling the persisted child branch after storage succeeds. Independent Round, Lesson and Course edits remain outside the reconciled branch and remain dirty. Failed persistence does not advance a baseline.

## Production-path regression evidence

`test/korean_production_discovery_225_03_test.dart` starts with persisted v6 discovery state that lacks Korean, a saved custom course and saved learner progress. It launches the real `HomeScreen` and production services, opens the actual Home course selector, verifies exactly nine stable bundled tile keys, identifies Korean by `sample_ko_en_ko`, visible name and direction, verifies the South Korean flag mapping and `ko-KR`, opens a real Korean Round and Duel, restarts Home state, and verifies one Korean entry plus unchanged custom-course and learner-progress data.

`test/production_editor_hierarchical_save_225_03_test.dart` navigates the real production screens and callbacks in this order: Course Editor -> Lessons -> Lesson Editor -> Rounds -> Round Editor -> Exercise Editor. It exercises actual editor fields, Save as draft, Publish and Back controls. Draft and Publish survive service reload with zero repeated Round, Lesson or Course confirmation dialogs. Metadata-bearing untouched siblings reproduce the pre-fix structural failure. Independent Round and Lesson edits still warn; Stay preserves them; discard removes only the unsaved parent edit; the saved child survives. A failing production persistence boundary keeps the Exercise dirty, preserves it on Cancel/Stay and discards only the unsaved Exercise when explicitly confirmed.

## Files in this candidate

- `AGENTS.md`
- `CHANGELOG.md`
- `README.md`
- `docs/225_03_VALIDATION.md`
- `docs/225_TRANCHE_2_VALIDATION.md`
- `docs/COURSE_EDITOR.md`
- `docs/LOGIC.md`
- `docs/SAMPLE_COURSE.md`
- `lib/screens/course_editor_screen.dart`
- `lib/screens/home_screen.dart`
- `lib/services/app_metadata.dart`
- `lib/services/course_service.dart`
- `pubspec.yaml`
- `test/app_metadata_225_02_test.dart` (replaced by the current Build 225.03 metadata test)
- `test/app_metadata_225_03_test.dart`
- `test/course_audit_report_225_test.dart`
- `test/course_service_test.dart`
- `test/korean_production_discovery_225_03_test.dart`
- `test/leaderboard_navigation_test.dart`
- `test/learner_round_path_test.dart`
- `test/production_editor_hierarchical_save_225_03_test.dart`

No bundled course JSON, custom course, learner data or historical 225.01/225.02 release section is rewritten by this candidate. The Build 225.02 validation record retains its automated evidence and now records the two subsequent manual failures truthfully.

## Automated validation

- `flutter pub get`: passed. It reported 28 newer package versions incompatible with the current dependency constraints.
- Build 225.03 focused production-path, metadata, service, legacy hierarchy, Audit-report and bundled-course group: 29 passed.
- Build 225.02 preservation group covering dark mode, Build-the-translation answers, Audit numbering/sorting/report actions, untitled Rounds, Reading Passage Warning, removal of missing-Listening Info, strict v6 clean-cut rejection, storage/import paths and all samples: 121 passed.
- `flutter test --no-pub`: 573 passed in 5 minutes 4 seconds.
- `flutter analyze --no-pub`: exited 1 with exactly 73 findings: 72 `curly_braces_in_flow_control_structures` Info notices and one pre-existing unused `_tapAndSettle` warning in `test/guidebook_sentence_generator_test.dart` (line 255); zero analyzer Errors and no new Warnings.
- `python tools/validate_courses.py`: passed all exactly nine Course Model v6 assets. Every bundled course reported Audit Errors 0, Warnings 0 and Info 0; Round playability, Duel gates, stable IDs, references and locales passed.
- `python tools/validate_lesson_icons.py`: passed, 14 assets and zero issues.
- `python tools/validate_images.py`: exited 1 only for the known pre-existing missing `assets/exercise_images/hello.webp`; 113 Image Bank entries and no other issue. The unrelated missing file is unchanged and remains outside this correction.
- `python tools/regenerate_bundled_courses_225_02.py --check`: passed all nine source assets unchanged.
- Changed Dart formatting: passed with zero changes required.
- `git diff --check`: passed before the Windows build; it is rerun at the final pre-commit checkpoint.

## Windows test candidate

- Command: `flutter build windows --release`
- Result: passed in 232.2 seconds.
- Executable: `build/windows/x64/runner/Release/quisquislingo_app.exe`
- Compiled Korean asset: `build/windows/x64/runner/Release/data/flutter_assets/assets/courses/korean_en.json`
- Compiled/source Korean SHA-256: `11d777241ae8e355e8db27e8bfcc1687f88c82940e62952d66ced64d23e74159`
- `AssetManifest.bin` contains `assets/courses/korean_en.json`; compiled `app.so` contains that exact production loader path, `2.0.25+22503`, `Version: 2.0.25` and `Build: 225.03`.
- The Windows build was started only after the final Dart source and test change and after the full 573-test suite passed. No final ZIP or release package was created.

## Outstanding manual Windows retest

- Korean visible and openable.
- Korean remains visible after restart.
- No repeated Round confirmation after Exercise Draft save.
- No repeated Lesson confirmation after Exercise Draft save.
- No repeated Round confirmation after Exercise Publish.
- No repeated Lesson confirmation after Exercise Publish.
- Independent unsaved Round edits still warn.
- Independent unsaved Lesson edits still warn.

Nothing is staged or committed for Build 225.03. Nothing was packaged or pushed, and no GitHub release was created.
