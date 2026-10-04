# Build 262 validation

## Revision 3 follow-up (same version, 4 October 2026): any publisher

- A complete suite started after the first part of the follow-up was stopped
  at 1306 passed, 0 failed, when the owner chose to remember the publisher;
  one complete run covers both parts.
- Remembered publisher: `dart analyze` on the six changed library files and
  the four test files: no issues. Focused
  `publisher_course_export_262_test.dart`,
  `course_library_operations_249_test.dart`,
  `app_reset_service_239_test.dart`, `inventory_239_test.dart` and
  `received_custom_course_250_test.dart`: 103 passed.
- A second complete suite, started after the remembered publisher, was
  stopped at 2269 passed, 0 failed, when the owner asked for the warning;
  one complete run covers all three parts.
- Warning: `dart analyze` on the screen, the service and the test: no issues.
  `publisher_course_export_262_test.dart` 18 passed.
- A third complete suite was stopped at 634 passed, 0 failed, when the owner
  asked for a message of its own for a revoked publisher.
- Revoked publisher: `publisher_course_export_262_test.dart` 18 passed;
  `flutter analyze` clean.
- Complete suite on the final tree (`--concurrency=1`, 4 October 2026,
  01:54–02:26): **3620 passed, 1 skipped, 0 failed**.

- `dart analyze` on the four changed files: no issues.
- Focused:
  - `publisher_course_export_262_test.dart` 13 passed. The two screen tests
    first failed because the new fields pushed the buttons out of the 600 px
    test view, so they now use a taller surface.
  - With `course_library_operations_249_test.dart`,
    `quisquislingo_courses_publisher_262_test.dart` and
    `editor_help_translation_test.dart`: 66 passed apart from those two
    before the fix.
  - `publisher_signing_help_test.dart`, `localization_catalog_test.dart`,
    `editor_help_qa_256_test.dart` and `storage_roles_255_test.dart`:
    27 passed.

## Revision 3 (2.0.62+262003, 3 October 2026): a path shape for each Lesson

- Start scan (temporary test, deleted): every candidate start with
  8 Rounds, a Duel, from the Lesson circle and from the IDDQD pill, at
  292, 347, 402, 560 and 900 px. The left-edge starts 1, 2, 6 and 12 crossed
  the first Round's label from the pill at every width; the centre starts 0,
  3, 5, 7, 8, 11, 13 and 15 crossed nothing. The eight centre starts are
  `learnerRoundPlacementStarts`.
- Focused: `test/learner_round_path_test.dart` 31 passed (new: each Lesson
  and each Course has its own path shape; the crossing test now covers every
  start from the Lesson circle and the pill); with
  `learner_round_audio_indicator_230_test.dart` and
  `leaderboard_navigation_test.dart`: 91 passed.
- `flutter analyze`: no issues.
- Complete suite (`--concurrency=1`, 4 October 2026, 00:10–00:29):
  - First run: the test shell stopped with "Out of memory" after 1594
    passed and 0 failed, inside `exercise_workflow_226_02_test.dart`. The PC
    has 8 GB; about 1.5 GB was free, with browsers open.
  - The 208 files from that one onward ran again on the same tree, in two
    batches (the command line limit): 1160 passed; then 879 passed,
    1 skipped and 2 failed.
  - The 2 failures are in `timed_round_261_test.dart` (countdown waits for
    play; on-time bonus). `_waitFor` gave up after about a second of real
    time without seeing `timed-countdown`. Run alone, the file passed 7 of 7.
    The test waits on real time and nothing in it touches the path.
  - Every other test file passed.

## Revision 2 (2.0.62+262002, 3 October 2026): Export as Publisher Course

**Tests**
- New `test/publisher_course_export_262_test.dart`: refusals (none for a
  clean published Course its Maintainer exports; each reason by itself:
  access, Course version, publication, License, Draft content, official
  Course); build (externalOfficial, every ID kept, publisher fields and
  Original Course Creator, official version = Course version, release notes,
  date and channel, no Maintainer/Team/Course version/Last Version Editor,
  not private, unsigned, checksum of its own content, JSON round trip, the
  source unchanged; a Private course exported as not private); publishers
  (QuisquisLingo Courses offered with an empty registry; one per publisher,
  revoked keys left out); export, sign, install (Quick Export writes
  `QQL_IT_EN_qql_demo_english_from_italian_publisher_v3.zip`; its
  course.json signed with a TEST ONLY key installs as a verified Publisher
  Course; version 4 installs as an update with a backup; version 3 again is
  refused; a refused Course and someone else's Course write nothing);
  Course Studio (the menu entry for the Maintainer, greyed for another
  profile, absent on an official Course; the page lists refusals and keeps
  Quick Export off; Quick Export exports for the publisher chosen).
- Updated: the Course Studio menus of a custom Course in
  `course_library_operations_249` and `course_manager_workflow_249` gain
  the entry (greyed for another profile with "Only the Maintainer or
  assigned Team can publish this Course."); `editor_help_translation_test`
  counts 15 Course Studio Help sections.
- `publisher_signing_help_test`: the signing guide still equals the English
  Help after both changed together.

**Runs**
- `flutter analyze`: No issues found (an unused import in the new page was
  removed first).
- Focused: the new test, the two menu tests, the signing guide, the Help
  catalogs, the storage names and the version pins, 118 passed.
- Complete suite (34 minutes): 3610 passed, 1 skipped, 1 failed:
  `editor_help_translation_test` pinned 14 Course Studio Help sections;
  corrected to 15 (and the new title), it passes alone. No other file
  changed after the complete suite.

## Revision 1 (2.0.62+262001, 3 October 2026): the publisher QuisquisLingo Courses

**Tests**
- New `test/quisquislingo_courses_publisher_262_test.dart` (8 tests): the
  registry entry (`com.quisquislingo`, QuisquisLingo Courses,
  `qqlc-2026-1`, a key ID the signing payload accepts, not the bundled
  publisher); `application()` holds it only with a key (Dummy still only in
  test builds); while the key is pending a signed Course is refused by the
  app's registry. With the TEST ONLY key: a signed Course verifies, imports
  through `CustomCourseTransferService` and installs through
  `installExternalOfficialUpdate`; altered (also with a recalculated
  checksum), unsigned, other-key, other-key-ID, other-name and other-ID
  Courses are refused.
- `test/support/publisher_fixtures.dart`: `signWithKey`, `dummyKeyPair`;
  `publisher_verification_test` (which uses `signFixture`) passes unchanged.
- Version pins as in Revision 0.

**Runs**
- `flutter analyze`: No issues found.
- Focused: the new test, `publisher_verification_test` and the version
  pins, 45 passed.
- Complete suite (34 minutes): 3598 passed, 1 skipped, 1 failed:
  `publisher_signing_help_test` requires `docs/PUBLISHER_SIGNING_GUIDE.md`
  to equal the English in-app Help word for word, and this revision had
  added a note to the guide alone. The note was removed (the guide is again
  as committed in Revision 0) and the test passes alone (5 tests); the note
  goes into the Help and the guide together in Revision 2. No source or test
  file changed after the complete suite.

## Revision 0 (2.0.62+262000, 3 October 2026): the Piedmontese Courses leave

**Generators and validator**
- `tools/generate_english_from_italian_260.py --check`: reproducible (the
  builders moved to `tools/qql_v11_builders.py` produce the same file);
  `generate_exercise_laboratory_254.py --check` and
  `generate_edge_case_demo_254.py --check`: OK.
- `tools/validate_courses.py`: "Validated 2 bundled Course Model v12 files."

**Private custom Courses** (outside the repository)
- A throwaway test (not kept) read both files of
  `D:\QQL_plus\Corsi_Privati\custom` through
  `CustomCourseTransferService.courseFromBytes`: both are custom Courses;
  Audit 0 errors (41 Lessons, 1 warning, the expected
  `OPPOSITE_TOO_EARLY`; 2 Lessons, 0 warnings).

**Tests**
- Corrected after the complete suite: `course_library_screen_244` and
  `course_library_view_255` counted four bundled demos (two now, plus the
  Edge Case fixture: " · 2 of 3 shown").
- New in `demo_package_roundtrip_254_test`: the removed Piedmontese
  identities stay reserved (`saveUserCourse` and
  `installImportedCustomCourse` refuse a custom Course with either ID);
  the impersonation probe is now a shared helper.
- Updated, a Piedmontese Course replaced by another bundled Course with the
  same property: `bundled_demo_registry_254`, `bundled_courses_225_02`
  (two bundled Courses; English from Italian loads through the registry),
  `course_official_provenance_225_04`, `course_service_test` (`PMS` and
  `PMS_MIX` unavailable), `demo_package_roundtrip_254` (English from
  Italian forbids Fork), `course_entry_animation_228` and
  `leaderboard_navigation_test` (English from Italian's World Flag row),
  `korean_production_discovery_225_03` (two English Courses switch),
  `course_library_operations_249`, `course_manager_workflow_249`,
  `official_course_storage_226_01`, `private_course_259`,
  `owner_review_259_revision7` (translation lines checked on the
  Laboratory and, in Italian, on English from Italian),
  `exercise_titles_261` (the dog of English from Italian:
  SCEGLI LA TRADUZIONE), `exercise_mascot_256`, `runtime_canonical_256`,
  `before_you_start_card_257` (the v11 intro from the Laboratory fixture),
  `course_model_v11_243`, `difficulty_curve_260`.
- Removed with the Courses: `piedmontais_course_254_test`,
  `piedmontese_mixed_259_test`, and the Piedmontese-only cases of
  `complete_text_and_sentence_order_259`, `listen_and_choose_259`,
  `owner_review_259_revision4`, `owner_review_260_revision3`.
- Version pins: `app_metadata_225_04`, `qql_229_revision3`,
  `qql_233_revision_platform_contract`, `course_audit_report_225`,
  `beta_lifecycle_test` (same dates: same release day).

**Runs**
- `flutter analyze`: No issues found.
- Focused: the 23 changed test files, 282 passed.
- Complete suite (`--concurrency=1`, 33 minutes): 3589 passed, 1 skipped,
  2 failed: the two Course Library counts above, then corrected; rerun
  alone they pass (17 tests). By owner decision of 3 October 2026 the
  complete suite was not repeated for these two test-only corrections.
