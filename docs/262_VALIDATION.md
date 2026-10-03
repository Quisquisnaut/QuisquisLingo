# Build 262 validation

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
