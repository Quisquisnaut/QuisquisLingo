# Build 243 validation

## Final validation of Revisions 0–2 (on the Revision 2 tree, `2.0.43+243002`)

Run on 21 September 2026 with the owner's approval, on the final working tree
of Revision 2, which contains Revisions 0 and 1.

- `flutter analyze --no-pub` (whole repository): **no issues**.
- `python tools/validate_images.py`: 111 assets, 0 issues.
- `python tools/validate_lesson_icons.py`: 14 assets, 0 issues.
- `python tools/validate_media_assets.py`: 443 files, 0 issues.
- `python tools/validate_courses.py`: 10 bundled Course Model v11 files OK.
- `git diff --check`: clean. Changed Dart files formatted; pre-existing
  formatter-unclean blocks outside the changes were deliberately left alone.
- Complete `flutter test --no-pub`, first run: **1,936 passed, 2 failed**, both
  in `test/qql_231_search_service_test.dart`. Its fixture used the invented
  image name `asset_internal_marker.png`, which the Revision 2 media rule
  correctly refuses. The marker is now a valid `media:` reference; the test
  still proves that image references are never searchable. The file then
  passed alone (7 tests).
- Complete `flutter test --no-pub`, rerun on the final tree after that fix:
  **1,938 passed, 0 failed**.

Revision 0 issues found and fixed before this run: the in-app Publisher Help
and `docs/PUBLISHER_SIGNING_GUIDE.md` had different wording for the Course
Model line (`test/publisher_signing_help_test.dart`); they are identical again.

## Revision 2 — course media (`2.0.43+243002`)

- New `test/course_media_243_test.dart` (13 tests): reference format, verified
  and deduplicated storage, limits, damaged-file replacement, copy with
  missing references, per-Course cleanup, `referencesOf`, the model rule,
  save cleanup with backup reinstatement, Course deletion, Copy as New Course
  and Fork copying media, merge copying from both sources, MP3 import and
  per-Course playback resolution, and `CourseMediaImage` for present, missing
  and device-path references.
- Updated for the new format (same intent): backup gap and restore, transaction
  backups, official backups, Publisher recordings rule, dialog MP3 import,
  audio settings and availability overrides, Inventory, reset, Device
  Administration, branding, audio import paths.
- 71 focused test files touching images, audio, backups, Fork/Copy/Merge,
  version history, reset, Inventory and the editor: **770 passed, 0 failed**;
  Help and documentation suites: **65 passed**; version suites: **27 passed**.


## Revision 1 — unreadable stored Courses (`2.0.43+243001`)

**Status: passed** — see the final validation above.

- New `test/unreadable_stored_courses_243_test.dart` (7 tests): lenient
  listing with named skipped files, duplicate IDs, strict `readAll`, `write`
  refusing unreadable and foreign files, `CourseEditorService` listing and
  import, and Course Manager loading with the notice instead of an error.
- New case in `test/managed_audio_cleanup_240_test.dart`: a confirmed save
  still works and deletes no MP3 while a stored Course file is unreadable.
- Store, editor-storage, persistence-hardening, Inventory, reset, device
  administration, transaction, ownership/profile-deletion, Course Manager,
  Publisher import, Course library, v11, Course Info and version suites:
  **206 passed, 0 failed**.
- `flutter analyze` on the 16 changed Dart files: no issues. Formatting and
  `git diff --check`: clean.


## Revision 0 — Course Model v11 (`2.0.43+243000`)

Scope: [243 change summary](243_CHANGE_SUMMARY.md).

**Status: passed** — see the final validation above; its focused evidence
follows.

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

### Still open

- Manual check on a device: not yet done.
