# Build 266 validation

## Revision 2 (2.0.66+266002, 8 October 2026): resilience

- A read-only audit of the whole app (stored-data readers that parse each
  item without a per-item catch; awaited calls in button handlers without
  one) gave the list this revision fixes; the places it found already
  correct were left alone.
- `test/stored_course_edge_cases_266_test.dart`: **14 passed**. Its first
  runs found two more defects, both fixed: the Inventory's reload (and its
  existing Refresh) returned a Future from `setState`, and Save&Open inside
  a ListTile's trailing slot overflowed by 40 pixels (it now stands on its
  own row under the tile).
- Focused batch of 85 test files (Course storage, imports, Publisher
  installs and updates, the resets, Advanced (Admin), Inventory, Debug, the
  Crash Log, Course Studio, All Courses, Team Manager, Version History,
  User Data, Gamification, the Shared Image Library, learner profiles;
  `--concurrency=2`, `TEMP`/`TMP` on `D:\QQL_test_temp`): **841 passed,
  2 failed**, both expected: a 225.02 test reads the words "unsupported
  course format" (kept in the new message) and the Revision 1 reset test
  pinned the old Maintainer rule (updated: the JSON's Maintainer counts).
- Rerun with the Help, localization, Debug, Inventory, version pin and
  admin tests: **152 passed**.
- `flutter analyze` on the whole project: **no issues**.
- `dart format` on the changed Dart files only.
- **Complete suite** (`flutter test --concurrency=1`): **3,924 passed, 1
  skipped** (the POSIX symlink test), 0 failed, in 36 minutes.

## Revision 1 (2.0.66+266001, 8 October 2026): authoring aids

- `test/guidebook_authoring_aids_266_test.dart`: **22 passed** (the first
  run found the Paste list dialog disposing its text controller while the
  dialog was still closing: the dialog now owns it, `_PasteListDialog`).
- Focused batch (`--concurrency=2`, `TEMP`/`TMP` on `D:\QQL_test_temp`):
  the GuideBook editor and module tests, the image field and every image
  library test, the Help and localization tests, the Audit registry, the
  version pins and the lifecycle test, the Course Editor flows that write a
  GuideBook (47 files): **436 passed**.
- `flutter analyze` on the whole project: **no issues**.
- `python tools/validate_courses.py`: both bundled Courses OK;
  `python tools/validate_images.py`: 4,334 records, 0 issues.
- `dart format` on the changed Dart files only.
- **Complete suite** (`flutter test --concurrency=1`, the owner's decision
  of 8 October: once, at the end of 266001, covering Revisions 0 and 1):
  **3,902 passed, 1 skipped** (`qql_tools_settings_test`: the POSIX
  symlink test, skipped on Windows by design), 0 failed, in 34 minutes.
  Free memory before the run 2.7 GB; `ES_CONTINUOUS | ES_SYSTEM_REQUIRED`
  held by the supervising PowerShell and cleared at the end.
- Then, the same day, two additions on the owner's word: the library opened
  from a word is searched for its English side, and the reset buttons fix.
  `test/reset_unreadable_course_266_test.dart`: **4 passed**; without the
  service fix its preview test and its button test fail (checked by
  reverting `app_reset_service.dart` and running it). The authoring aids
  test: **26 passed** (4 new: the picture dialog's search in a Course from
  English, to English and without English, and N matching pictures without
  the article). Focused batch (the admin screen, Private courses, the image
  field and library, plural pictures, Recognize characters, the GuideBook
  tests): **131 passed**. `flutter analyze`: **no issues**.
- **Complete suite again** on the final tree: **3,910 passed, 1 skipped**
  (the same POSIX symlink test), 0 failed, in 39 minutes.

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
- Complete suite: not run in this revision (owner's decision); it ran at
  the end of Revision 1 and covers this revision (above).
