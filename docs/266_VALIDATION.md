# Build 266 validation

## Revision 0 (2.0.66+266000, 8 October 2026): GuideBook modules

By the owner's decision of 8 October 2026 the complete suite runs once, at
the end of Revision 1 (266001); this revision is checked with the analyzer,
focused tests and the validators.

- `flutter analyze` on the whole project: **no issues**.
- `test/guidebook_modules_266_test.dart`: **23 passed** (the first run
  found the module page's word row 118 pixels too wide at 360 pixels: the
  picture controls now wrap).
- Focused batches (`--concurrency=2`, `TEMP`/`TMP` on `D:\QQL_test_temp`):
  - GuideBook services (publication, Review vocabulary, Word Lookup
    sources and rules, image usage and removal, duplication, the Audit
    registry and branch ownership, provisional publication, the Round
    Wizard, optional paths, forks, transfers, Edge Case, English from
    Italian, the vocabulary tests): 202 tests, 2 failed (a test helper
    that assumed every line parses; a test reading `.single` Lesson of a
    two-Lesson demo), both fixed and passing.
  - Converters, bundled Courses, the Publisher fixtures and the Lab
    (`course_model_v11_243_test`, `course_model_v12_256_test`, bundled
    courses, demo package round trip, flashcard usage, official
    provenance, the Laboratory, the future fixture, the bundled registry
    and source, Korean discovery, the Publisher import, package, recorded
    audio, verification and QuisquisLingo Courses tests, media
    attribution, package import, Course options, persisted delivery, the
    preview, the v6 refusal): 446 tests, 1 failed (the converter parity
    test expected no notes; it now expects only the "Module 1" rename
    notes), fixed and passing.
  - Editor and learner workflows (GuideBook status, Lesson controls, the
    production transaction, the provisional workflows, Word Lookup on
    screen, the Review flow, Before you start, GuideBook delivery, the
    Wizard UI, responsive layout, the hierarchy routes, internal IDs,
    indicators, transfers, Audit propagation, Draft promotion, Course
    metadata, Editor Help, localization, optional paths): **236 passed**.
  - Every other test file that mentions the GuideBook, Review vocabulary,
    Word Lookup or image usage (39 files): **520 passed**.
  - The version pins, the lifecycle test and the Help tests after the
    last edits: 37 and 68 passed.
- `python tools/validate_courses.py`: both bundled Courses OK.
- `generate_exercise_laboratory_254.py --check`, `generate_edge_case_demo_254.py
  --check`, `generate_english_from_italian_260.py --check`: up to date.
- The dummy Publisher fixtures were signed again with
  `tools/sign_course.dart prepare`/`attach` and OpenSSL (test key
  `test/fixtures/publishers/dummy-private.pem`), the media package with
  `package`; the Publisher tests verify them.
- `dart format` on the changed Dart files only.
- Complete suite: not run in this revision (owner's decision); it runs at
  the end of Revision 1.
