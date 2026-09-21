# Build 243 validation

## Revision 14 — safer archives and structured files (`2.0.43+243014`)

Validation on 21 September 2026, before the Revision 14 commit.

- New `import_archives_tranche4_test.dart` (25), all passing:
  - `BoundedZipReader`: reads files and skips folders; refuses unsafe names
    (absolute, drive letter, `..`, `.`, empty segment, control character),
    case and slash collisions, symlink/device/FIFO/socket modes, encrypted
    entries, bzip2 compression, nested archives, too many entries, a
    declared total over the limit, a local name that differs, and a wrong
    CRC; `read(limit:)` refuses a larger entry;
  - Image Banks: images in folders, object manifest with default credit
    (an entry's own wins) and `name`; an extra `CREDITS.txt` refused with the
    `attribution` hint; id, label, tag, category, name and attribution bounds;
    a manifest nested 65 deep refused before decoding;
  - Shared Image Library: new categories added on **Add them**, mapped to
    `other` on **Put these images under Other**, nothing written on
    **Cancel**, more than 16 refused before asking, a failure after writing
    removes the bank and its categories, no keywords refused before writing,
    non-Admin refused; the dialog in the Image Library;
  - JSON: depth, string and list limits (text inside strings and object
    members not counted); a Course refused for depth, 501 Lessons, 101
    Rounds and a NUL `courseId`; learner backup and Recovery Key refused for
    depth, learner backup for a NUL id; all bundled and demo Courses fit.
- Tranche 0 and Image Bank tests updated to the reader's messages;
  `readBoundedEntry`'s test now exercises `BoundedZipReader.read`.
- The 370 tests of every file touching Image Banks, packages, backups,
  Recovery Keys and Course transfer passed before the full run.
- Complete suite in two halves covering all 234 test files once:
  **1,003 + 1,098 = 2,101 passed, 0 failed** (both halves exit 0).
- `flutter analyze` on the repository: **no issues**.
- The four `tools/validate_*.py` validators: 0 issues.
- `git diff --check`: clean. The untracked `devtools_options.yaml` is excluded.

## Revision 13 — real MP3 validation (`2.0.43+243013`)

Validation on 21 September 2026, before the Revision 13 commit.

- `Mp3Validator` accepted all 16 bundled `assets/audio/*/sample_*.mp3`
  recordings (25–39 frames each) before it was wired in.
- New `mp3_validation_tranche3_test.dart` (21), all passing. It covers
  constant and variable bit rate, ID3v2/ID3v1/APEv2 tags, the bundled
  samples, the isolate path, and refusal of: empty, over 50 MB, a renamed
  ZIP, a renamed image, an ID3 header with no audio, a corrupt synchsafe
  size, an overlong tag, a damaged ID3 frame, more than 2 MB of metadata,
  `APIC` artwork, a truncated frame, trailing junk, a single fake sync
  marker, fewer than four frames, bad bit rate, free format, reserved sample
  rate, Layer II, and a sample-rate change. Also the routes: multi-file Open
  from… (per-file results, duplicates skipped, nothing stored for refused
  files), a cancelled dialog, single Open from…, and the fixed folder storing
  nothing when one file is bad.
- `course_package_243_test`: a correctly hashed recording that is not an MP3
  is refused on Course ZIP import, with nothing installed.
- Tests that used placeholder MP3 bytes now use `syntheticMp3()`. The signed
  Dummy media fixture was re-signed with the Dummy test key; only its
  recording reference, checksum and signature changed.
- Found in review before the run: the fixed-folder import first held every
  checked file in memory; it now keeps the checked copies in staging. An
  unescaped apostrophe in the new English Help text broke compilation; the
  first suite run was stopped and discarded.
- Complete suite in two halves covering all 233 test files once:
  **1,003 + 1,073 = 2,076 passed, 0 failed** (both halves exit 0).
- `flutter analyze` on the repository: **no issues**.
- The four `tools/validate_*.py` validators: 0 issues.
- `git diff --check`: clean. The untracked `devtools_options.yaml` is excluded.

## Revision 12 — add images and Image Banks to a Course (`2.0.43+243012`)

Validation on 21 September 2026, before the Revision 12 commit.

- New `course_image_library_import_test.dart` (5), all passing:
  - entry metadata round-trips and is omitted when empty;
  - label, category, tag and control-character limits are enforced;
  - **Open image files from…** into a Course: two valid images are added,
    unused and stored in the Course folder; a duplicate is skipped; a text
    file is refused; the summary counts are right; nothing reaches the Shared
    Image Library;
  - **Open Image Bank ZIP from…** into a Course keeps the label, category
    (`food` mapped to `food_drinks`), tags and credit, and creates no
    `image_banks` folder;
  - a Course folder 100 bytes under 300 MB refuses the import before any
    write.
- The existing Image Bank tests (25) pass unchanged after the split into
  `readBank` and `importBankZip`.
- Two defects in the new test itself were fixed before this run. The 300 MB
  case first left 1,024 bytes free for a 560-byte image, so it rightly
  imported. An escape written as `\u0000` had been saved as a raw NUL byte. A
  scan of `lib/` and `test/` finds no raw control bytes.
- Complete suite in two halves covering all 232 test files once:
  **990 + 1,064 = 2,054 passed, 0 failed**.
- `flutter analyze` on the repository: **no issues**.
- The four `tools/validate_*.py` validators: 0 issues.
- `git diff --check`: clean. The untracked `devtools_options.yaml` is excluded.

## Revision 11 — one image check for every image import (`2.0.43+243011`)

Validation on 21 September 2026, before the Revision 11 commit.

- A probe before routing any importer: `ImageValidator.inspect` accepted all
  128 real images (bundled exercise images, Lesson icons and the example
  Image Bank). No false rejections.
- New `image_validator_tranche2_test.dart` (12), all passing:
  - bundled images pass;
  - text, and a program header, under an image name are refused;
  - empty, truncated and CRC-tampered PNG and WebP files are refused;
  - a sub-50 KB PNG declaring 30,000² is refused, as is 4,097 px;
  - APNG and animated WebP are refused;
  - over-budget metadata and an oversized ICC profile are refused;
  - a zero-height JPEG frame is refused;
  - a profile's format restriction is enforced;
  - a WebP named `.png` is accepted as WebP and stored with a `.webp`
    Course media reference;
  - an Admin's Shared Library import is stored as `image_local_<µs>.png`;
  - a non-Admin writes nothing;
  - a failed metadata record leaves no file.
- Updated because they fed placeholder bytes as images, which the validator
  now correctly refuses: `course_package_243_test` and `image_bank_service_test`
  now use real bundled images. The Tranche 0 APNG fixture now carries a
  correct chunk CRC. `file_dialogs_240_features_test` pinned the old
  write-on-pick behaviour (N6/N7) and now pins "checked, nothing stored until
  commit".
- Focused run across 47 image, bank, package, icon, flag, portable,
  Recognize Characters, dialog and Publisher files: all passed after those
  updates.
- Complete suite in two halves covering all 231 test files once:
  **997 + 1,052 = 2,049 passed, 0 failed**.
- `flutter analyze` on the repository: **no issues**.
- The four `tools/validate_*.py` validators: 0 issues.
- `git diff --check`: clean. The untracked `devtools_options.yaml` is excluded.

## Revision 10 — safe import foundation (`2.0.43+243010`)

Validation on 21 September 2026, before the Revision 10 commit.

- New `import_foundation_tranche1_test.dart` (17), all passing:
  - safe display names;
  - ordinary files only: a folder, a missing file and a symbolic link are
    refused. The symlink tests ran; this machine allows creating links;
  - a fixed-name `import.json` link refused;
  - staging:
    - actual bytes counted, with the reported size deliberately wrong;
    - SHA-256 computed while reading;
    - one byte over the limit stops reading;
    - empty files, and a provider failing part-way;
    - cancellation mid-file;
    - leftover removal;
    - no staging file left behind in any case;
  - batches: 101 files, the batch byte limit, mixed valid, empty and
    too-large files with summary lines, and cancel halfway;
  - `FileDialogService`: too large, within the limit, multiple files, and
    cancel.
- Existing tests unchanged apart from passing a temporary-folder stager
  (`testImportStager()`), including every dialog test that checks each
  service's own too-large message: 61 dialog tests passed.
- Focused run across 24 reset, inventory, Course media, backup, Recovery Key,
  flag, Lesson icon and transfer test files: **207 passed, 0 failed**.
- Complete suite in two halves covering all 230 test files once:
  **985 + 1,052 = 2,037 passed, 0 failed**.
- `flutter analyze` on the repository: **no issues**.
- The four `tools/validate_*.py` validators: 0 issues.
- `git diff --check`: clean. The untracked `devtools_options.yaml` is excluded.

## Revision 9 — QQL image metadata read-only; Local words; device categories (`2.0.43+243009`)

Validation on 21 September 2026, before the Revision 9 commit.

- New tests, all passing:
  - `exercise_image_metadata_0b_test.dart` (10): the one-time conversion
    (added tags become Local words, removed tags and category return, device
    records kept, unknown bundled records dropped), a snapshot missing a QQL
    image no longer failing, Local words for an image no longer shipped
    ignored, device categories (add/use/rename/remove, name rules, the
    64-category limit, QQL categories immutable), Local-word limits and
    QQL-only scope, tile line and search;
  - `exercise_image_metadata_0b_ui_test.dart` (2): Manage device categories;
    a QQL image offering Local words, not tag editing.
- Updated to the owner's decision: `exercise_image_metadata_234_revision_test`
  and `exercise_image_metadata_admin_ui_234_revision_test`, which had pinned
  "an Admin edits a QQL image's tags".
- Focused run across 20 metadata and library files: **161 passed, 0 failed**.
- Complete suite in two halves covering every test file once:
  **985 + 1,035 = 2,020 passed, 0 failed**.
- `flutter analyze` on the repository: **no issues**.
- The four `tools/validate_*.py` validators: 0 issues.
- `git diff --check`: clean. The untracked `devtools_options.yaml` is excluded.

## Revision 8 — remove an image from a Course; badge order (`2.0.43+243008`)

Validation on 21 September 2026, before the Revision 8 commit. The tree
contains Revision 7 (committed as `4230d94`) plus Revision 8, so this run also
completes the validation of Revision 7, whose own full run was interrupted.

- New tests, all passing:
  - `course_image_removal_test.dart` (5): Draft only for exercises made
    invalid, reconcile never republishes, presentation, GuideBook and cover
    uses, unused assets, content already Draft;
  - `course_image_library_model_test.dart` (6): omitted when empty,
    round-trip, invalid entries refused, kept by `referencesOf`,
    `updateLibrary`, Copy as New Course;
  - `flat_image_library_removal_test.dart` (6): IN USE above the source
    badge, no removal without Course editing, a used QQL image with Cancel,
    Keep in library after removing uses, removing a library entry keeps the
    file until the confirmed save, a leftover is deleted at once.
- Focused run across 30 related files (model, Merge, packages, duplication,
  transfer, Course media, image library, backups, editor transaction):
  **229 passed, 0 failed**.
- Complete suite, run in two halves that together cover every test file
  once: **985 + 1,023 = 2,008 passed, 0 failed**.
- `flutter analyze` on the repository: **no issues**.
- `python tools/validate_images.py`: 111 assets, 0 issues.
- `python tools/validate_lesson_icons.py`: 14 assets, 0 issues.
- `python tools/validate_media_assets.py`: 443 files, 0 issues.
- `python tools/validate_courses.py`: all 10 bundled Course Model v11 files OK.
- `git diff --check`: clean. The untracked `devtools_options.yaml` is excluded.

## Revision 7 — image library tidy-up (`2.0.43+243007`)

Validation on 21 September 2026, before the Revision 7 commit.

- Focused runs, all passed:
  - the new `course_image_usage_test.dart` (5), `image_library_rules_test.dart`
    (10) and `exercise_image_field_test.dart` (4);
  - 13 files that depend on Course media references (packages, backups,
    cleanup, Publisher): 133 passed;
  - 26 files covering the Exercise editor and image flows, plus the new
    tests: 336 passed.

  Existing tests were not changed.
- `course_image_usage_test.dart` keeps the previous whole-JSON search as a
  reference. `CourseMediaStore.referencesOf` returns the identical set for
  every bundled and demo Course, and for a Course with an image in every
  possible place.
- Complete `flutter test --no-pub`: **interrupted** at 1,893 passed and
  0 failed, with no failure reported, before the run finished (exit code 4
  from the interruption, not from a test). By the owner's instruction it was
  not re-run separately. The complete suite runs on the combined Revision 7
  and 8 tree before the Revision 8 commit; see that section.
- `flutter analyze` on the repository: **no issues**.
- The four `tools/validate_*.py` validators: 0 issues.
- `git diff --check`: clean.

## Revision 6 — import memory-safety fixes (`2.0.43+243006`)

Validation on 21 September 2026, before the Revision 6 commit.

- Focused run: the new `import_hardening_tranche0_test.dart`, plus the Image
  Bank, example bank, Course package, Publisher package, custom Lesson icon,
  World flag, portable image and Recognize Characters test files. All passed
  after two expected corrections:
  - The understated-entry test now patches only the bomb entry. Every entry,
    including the manifest, must match its declared size.
  - An empty ZIP directory is reported as unreadable.
- `import_hardening_tranche0_test.dart` covers:
  - the limited stream;
  - an entry that understates its size;
  - more than 50 MB declared across all entries, from an unreferenced entry;
  - a symlink entry;
  - 5,001 entries;
  - non-ZIP bytes;
  - a cover declaring 30,000²;
  - a 4,097-pixel icon and flag;
  - an APNG;
  - an animated WebP, by its flag and by an `ANIM` chunk.
- Complete `flutter test --no-pub` on the final code tree: **1,973 passed,
  0 failed**.
- `flutter analyze` on the repository: **no issues**.
- `python tools/validate_images.py`: 111 assets, 0 issues.
- `python tools/validate_lesson_icons.py`: 14 assets, 0 issues.
- `python tools/validate_media_assets.py`: 443 files, 0 issues.
- `python tools/validate_courses.py`: all 10 bundled Course Model v11 files OK.
- `git diff --check`: clean. The untracked `devtools_options.yaml` is excluded.

## Revision 5 — Image Library usability (`2.0.43+243005`)

Validation on 21 September 2026, before the Revision 5 commit.

- Focused run across the Image Library, Shared Image Library metadata, Admin
  and non-Admin metadata UI and Recognize Characters test files: **42 passed,
  0 failed**. This includes the new `flat_image_library_sort_test.dart`, which
  covers name, newest, oldest, largest and smallest ordering and the corner
  position of the badges and the delete control. It also includes the
  single-tile case for a Shared Image Library image and its Course copy,
  including a deleted original and a missing original file.
- Complete `flutter test --no-pub` on the final code tree: **1,962 passed,
  0 failed**.
- `flutter analyze` on the repository: **no issues**.
- `python tools/validate_images.py`: 111 assets, 0 issues.
- `python tools/validate_lesson_icons.py`: 14 assets, 0 issues.
- `python tools/validate_media_assets.py`: 443 files, 0 issues.
- `python tools/validate_courses.py`: all 10 bundled Course Model v11 files OK.
- `git diff --check`: clean. The pre-existing untracked
  `devtools_options.yaml` is excluded from the commit.

## Revision 4 — signed Publisher media and Image Library (`2.0.43+243004`)

Validation on 21 September 2026, before the Revision 4 commit and push.

- Focused run across 17 Publisher package, signature, import, Course ZIP,
  Image Library, attribution, Editor, version and file-dialog test files:
  **101 passed, 0 failed**. This includes the signed Dummy media ZIP,
  installation and update with backup and cleanup, the Publisher packaging
  tool, Course-owned images in the Editor library, and `USED` on QQL and
  DEVICE images in exercise prompts and answer options.
- Complete `flutter test --no-pub --reporter expanded` on the final code tree:
  **1,960 passed, 0 failed**.
- After a formatting-only adjustment to the Image Library screen, its three
  focused suites were rerun: **7 passed, 0 failed**.
- `flutter analyze --no-pub` on the repository: **no issues**.
- `python tools/validate_images.py`: 111 assets, 0 issues.
- `python tools/validate_lesson_icons.py`: 14 assets, 0 issues.
- `python tools/validate_media_assets.py`: 443 files, 0 issues.
- `python tools/validate_courses.py`: all 10 bundled Course Model v11 files OK.
- `git diff --check`: clean. The pre-existing untracked
  `devtools_options.yaml` is excluded from the commit.

## Revision 3 — portable Course ZIP (`2.0.43+243003`)

Validation on 21 September 2026. The owner requested focused tests after the
remaining test expectation was corrected, without another complete-suite run.

- `test/course_package_243_test.dart` (12 tests): package round trip, dependency-only
  image export and shared-image provenance, checked-in demo ZIP, damaged and
  missing media, unsafe ZIP names, rollback, ZIP and media-free JSON import,
  Copy/Fork staging, extra files, size limits, and cover checks: 12 passed.
- `test/flat_image_library_243_source_test.dart` (2 tests): the Shared Image
  Library shows only `QQL`/`DEVICE` source labels and preserves the selected
  device image identity; the Course Editor combines `QQL` or `DEVICE` with
  `USED`, and adds `COURSE` only for a Course media reference.
- Package, file-dialog, merge, import/export, audio-path, version, Editor Help
  and image-library focused suites after the provenance addition: **78 passed**.
- Model v11, authoring duplication, Course media, Publisher import and app
  metadata focused suites: **43 passed**. The Editor layout suite passed after
  updating its fixed-folder ZIP expectation; documentation/Help tests passed.
- `flutter analyze --no-pub` on all 25 changed/new Dart files: **no issues**.
  After the label refinement, analysis of the 3 affected Dart files found no
  issues. The library/package/editor-layout run passed 26 tests.
- After adding optional per-image attribution, the focused package, metadata,
  Admin UI, Image Bank and source-label suites passed 37 tests. Analysis of
  the 13 affected Dart files found no issues.
- One complete `flutter test --no-pub` run on the pre-attribution Revision 3
  tree: **1,951 passed, 1 failed**. The failing
  `test/file_dialog_feedback_240_test.dart` still expected the old fixed-folder
  `import.json` wording. Revision 3 correctly directs ZIP imports to
  `import.zip` and media-free JSON imports to `import.json`; the expectation
  was corrected and the isolated test passed. At the owner's request, the
  complete suite was not repeated after this correction.
- Final focused run across 21 affected test files (package, labels,
  attribution, Image Bank, file dialogs, Help, Editor, transfer and version):
  **152 passed, 0 failed**.

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
