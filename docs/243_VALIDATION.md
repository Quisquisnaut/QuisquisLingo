# Build 243 validation

## Revision 0 — Course Model v11 (`2.0.43+243000`)

Scope: [243 change summary](243_CHANGE_SUMMARY.md).

**Status: focused validation passed. Final checks not yet run.** The owner
approves the complete Flutter suite (about 1,900 tests), the full-repository
`flutter analyze` and the four Python validators separately, because of their
duration. They will be recorded here when run.

### Focused evidence (final working tree of Revision 0)

- New tests:
  - `test/course_model_v11_243_test.dart`: clean cut; optional merge provenance;
    storage folders; every new field valid, invalid and round-tripped; Fork,
    Copy, transfer and merge carrying; bundled IDs and checksums; Dummy
    fixtures verified and tampering refused; the conversion tool.
  - `test/course_info_v11_fields_243_test.dart`: Course Info Editor saves,
    clears and refuses the fields; Course Info shows them.
- 26 changed test files plus the file-store, publisher verification, import
  UI, recorded-audio, media-attribution, Course library and metadata-UI suites:
  **328 passed, 0 failed**.
- After the last formatting-only edits: the v11, merge and Course Info suites,
  **31 passed, 0 failed**.
- `flutter analyze` on the 43 changed and new Dart files: no issues.
- `python tools/validate_courses.py`: 10 bundled Course Model v11 files OK,
  including checksum agreement with the Dart model.
- Re-signed Dummy fixtures: `tools/sign_course.dart attach` verified each
  signature against `dummy-public.der` before writing.
- `git diff --check`: clean.

### Pending, on owner approval

- `flutter analyze --no-pub` (whole repository).
- Complete `flutter test --no-pub`.
- `tools/validate_images.py`, `validate_lesson_icons.py`,
  `validate_media_assets.py`, `validate_courses.py`.
- Manual check: see the Italian checklist that will accompany the release.
