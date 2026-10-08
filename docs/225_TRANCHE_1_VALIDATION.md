# QuisquisLingo 2.0.25+225 first-tranche validation

Date: 2026-09-03

Status: implementation and automated functional validation complete; manual Windows runtime validation remains outstanding.

This is the first controlled build-225 tranche, not the complete 225 release. It is limited to Course Audit correctness/report export, the Build the translation save/model/Audit/runtime path, post-save Editor dirty-state handling, and regeneration of the bundled Italian course only. No package or push is part of this tranche.

## Version and Alpha lifecycle

- Application version: `2.0.25+225` in `pubspec.yaml` and `lib/services/app_metadata.dart`.
- Alpha expiry: `2026-10-04 23:59:59` local time in `lib/services/alpha_lifecycle_service.dart`.
- Expiry tests: `test/alpha_lifecycle_test.dart` and the displayed-date expectation in `test/leaderboard_navigation_test.dart`.
- Current user-facing statements: `README.md` and `docs/COURSE_EDITOR.md`.

## Root causes and finding classification

The real bundled Italian asset started at the observed Audit baseline of 38 Errors, 27 Warnings and 60 Info findings.

1. Genuine historical bundled-course defects: 18 Gap Choice prompts lacked `___`; 18 Dialogue Response exercises had three options rather than exactly two; one Missing Word exercise had no audio/TTS prompt; and one Hint normalized to the accepted answer. Git inspection confirmed that these data defects predated the closed build-224 release.
2. Canonical migration/serialization defects: build 224 exposed Build the translation through the Arrange model, but its legacy-to-canonical constructor matched each authoring line literally. A natural `Come stai?` entry therefore failed to resolve the `Come` and `stai` Item IDs and left `evaluation.correctOrder` empty. The Editor also wrote redundant `missingWords` for Listening Spelling and omitted the required mirrored `text_match.acceptedAnswers` when saving Missing Word. The eight redundant Listening Spelling fields in the Italian asset were removed; Missing Word retains both compatible canonical views required by the model and schema validator.
3. Course Audit false positives: the stale-field checks read author-friendly `answers`, `tokens` and `icons` projections as though they were independent fields. These are projections of canonical interaction Items; empty projected icon strings are not stale icon data. Audit also treated valid Missing Word `text_match.acceptedAnswers` as incompatible even though the schema requires it. Audit now inspects independent canonical evaluation fields and permits both canonical Missing Word views while retaining warnings for genuinely incompatible stored fields.
4. Duplicate findings: every missing Gap Choice marker also triggered the “exactly one gap” Warning. The same absent marker was the sole cause of both findings. A missing marker now emits only its blocking Error; multiple markers still emit the distinct Warning.

The playability rules were not suppressed and no Italian-course allowlist was added.

## Italian regeneration

- Production asset: `assets/courses/italian_en.json`.
- Stable Course ID: `sample_it_en_it`.
- Direction preserved: English interface/source to Italian target, `it-IT` TTS.
- Existing Lesson, Round and Exercise IDs are retained wherever their semantic item remains; the new practice Rounds and exercises use deterministic new IDs.
- Only this bundled course asset changed. The other seven bundled course JSON files remain outside the diff.
- Each of the nine Lessons has 26 or 27 valid selectable Duel candidates, meeting the established requirement of 25 without question duplication or gameplay changes.
- Every Round has at least one published Audit-valid learner-playable exercise.

Audit totals:

| State | Error | Warning | Info | Total |
|---|---:|---:|---:|---:|
| Before | 38 | 27 | 60 | 125 |
| After | 0 | 0 | 42 | 42 |

The original 27 Warnings comprised 18 duplicate Gap-marker findings, 8 genuinely redundant Listening Spelling `missingWords` fields and 1 false-positive Missing Word accepted-answer finding. After the fixes, no Warning remains.

The 42 remaining findings were examined and are all Info guidance on retained historical sample content: 18 Rounds lack the recommended Listening comprehension preset, 18 Reading comprehension passages are very short, and 6 isolated words begin with a capital letter. They are exported in full, remain visible to authors, and do not change runtime validity.

## Focused evidence

- `test/course_audit_test.dart`: canonical projection, independent stale-field, Gap-marker deduplication and existing validation coverage.
- `test/course_audit_report_225_test.dart`: deterministic complete report construction/copy, real filesystem export seam, filtered-view completeness, and export success/failure UI.
- `test/course_editor_225_test.dart`: exact `How are you?` → `Come` / `stai` → `Come stai?` Editor save, canonical serialization/reload, Audit and learner evaluation path; genuine missing-block/order Errors.
- `test/unsaved_changes_224_test.dart`: no-change, unsaved leave/cancel, Draft/Publish success, failed persistence/validation and edit-after-save navigation behavior.
- `test/italian_course_audit_225_test.dart`: real production Italian asset, zero Audit Errors, every Lesson Duel-available and every Round playable.

## Final validation

- `flutter pub get`: passed; 28 newer package versions remain outside the current dependency constraints.
- Consolidated focused Flutter run: all 53 Audit/report/Editor/runtime/dirty-state/Italian/Alpha tests passed in 21 seconds.
- Final `flutter test --no-pub`: all 515 tests passed in 4 minutes 15 seconds.
- `flutter analyze --no-pub`: 0 errors attributable to this tranche. It reports the repository's 79 pre-existing `curly_braces_in_flow_control_structures` Info notices and one pre-existing `unused_element` Warning for `_tapAndSettle` at `test/guidebook_sentence_generator_test.dart:255`; that untouched helper dates to the initial baseline and was not changed or suppressed. The analyzer exits 1 on these 80 existing findings.
- `python tools/validate_courses.py`: all 8 bundled Course Model v5 files passed.
- `python tools/validate_lesson_icons.py`: 14 assets, 0 issues.
- `python tools/validate_images.py`: 113 assets, 1 pre-existing issue: missing `assets/exercise_images/hello.webp`. This untouched out-of-scope issue is the same one recorded for build 224, so the validator exits 1.
- `git diff --check`: passed; line-ending notices do not represent content errors.
- The Italian regeneration is byte-deterministic. Stable Course/Lesson/Round/Exercise IDs from the prior asset are all retained, and `git diff -- assets/courses` names only `assets/courses/italian_en.json`.

## Manual Windows check

A genuine packaged Windows runtime check is still required unless explicitly recorded in the final validation section. Automated Flutter widget/unit tests do not substitute for manually opening Course Audit, copying/exporting a report, saving the reproduced Build the translation exercise and navigating away after Draft/Publish in a real Windows build.

## Changed files

- `AGENTS.md`
- `CHANGELOG.md`
- `README.md`
- `assets/courses/italian_en.json`
- `docs/225_TRANCHE_1_VALIDATION.md`
- `docs/COURSE_EDITOR.md`
- `docs/COURSE_JSON_FORMAT.md`
- `docs/SAMPLE_COURSE.md`
- `lib/models/course_models.dart`
- `lib/screens/course_editor_screen.dart`
- `lib/services/alpha_lifecycle_service.dart`
- `lib/services/app_metadata.dart`
- `lib/services/course_audit_report_service.dart`
- `lib/services/course_audit_service.dart`
- `lib/services/report_service.dart`
- `pubspec.yaml`
- `test/alpha_lifecycle_test.dart`
- `test/course_audit_report_225_test.dart`
- `test/course_audit_test.dart`
- `test/course_editor_225_test.dart`
- `test/course_model_v5_test.dart`
- `test/italian_course_audit_225_test.dart`
- `test/leaderboard_navigation_test.dart`
- `test/unsaved_changes_224_test.dart`
- `tools/regenerate_italian_course_225.py`

Final pre-commit `git status --short`:

```text
 M AGENTS.md
 M CHANGELOG.md
 M README.md
 M assets/courses/italian_en.json
 M docs/COURSE_EDITOR.md
 M docs/COURSE_JSON_FORMAT.md
 M docs/SAMPLE_COURSE.md
 M lib/models/course_models.dart
 M lib/screens/course_editor_screen.dart
 M lib/services/alpha_lifecycle_service.dart
 M lib/services/course_audit_service.dart
 M lib/services/report_service.dart
 M pubspec.yaml
 M test/alpha_lifecycle_test.dart
 M test/course_audit_test.dart
 M test/course_model_v5_test.dart
 M test/leaderboard_navigation_test.dart
 M test/unsaved_changes_224_test.dart
?? docs/225_TRANCHE_1_VALIDATION.md
?? lib/services/app_metadata.dart
?? lib/services/course_audit_report_service.dart
?? test/course_audit_report_225_test.dart
?? test/course_editor_225_test.dart
?? test/italian_course_audit_225_test.dart
?? tools/regenerate_italian_course_225.py
```
