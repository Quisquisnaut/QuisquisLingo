# Handoff: portable course package, Tranches 2 and 3

Written 2026-09-21 at the end of Build 243 Revision 2 (`2.0.43+243002`).
Audience: the coding agent that resumes this work.

## Read first

1. `AGENTS.md` — binding rules. In particular: smallest correct change, no
   unrelated refactors, never commit or push unless the owner asks, focused
   tests while working, the complete suite only with the owner's approval,
   `rg`/git instead of PowerShell `Get-Content`, every new persistent key or
   folder also in `AppResetService`, `InventoryService` and
   `docs/239_RESET_STORAGE_INVENTORY.md`.
2. `docs/COURSE_PACKAGE_PLAN.md` — the owner-approved plan, in Italian.
   §1 holds the closed decisions; do not re-open them. §0 is the resume point.
   §3 describes Tranche 2 and Tranche 3 in detail.
3. `docs/243_CHANGE_SUMMARY.md` — what Revisions 0–2 actually changed and why.
4. `docs/COURSE_JSON_FORMAT.md` — "Course media references" and "Optional
   descriptive fields (v11)".

The owner speaks Italian and prefers plain, non-technical explanations. Ask
before any choice that could change behavior, persistence, compatibility or
user data. Work on `main`; one revision and one commit per tranche.

## Where things stand

| Revision | Version | Commit | Content |
|---|---|---|---|
| 0 | `2.0.43+243000` | `35090c7` | Course Model v11 (clean cut from v9/v10), optional descriptive fields, conversion tool, converted bundled/demo/Dummy Courses, storage folders `qql_courses_v2` and `Course Backups v11` |
| 1 | `2.0.43+243001` | `6bbd69a` | One unreadable stored Course no longer hides the others |
| 2 | `2.0.43+243002` | see `git log` | Tranche 1: course media (`media:<sha256>.<ext>`), one media folder per Course |

Nothing has been pushed. Validation evidence is in `docs/243_VALIDATION.md`.

## What exists that you build on

- **`CourseMediaStore`** (`lib/services/course_media_store.dart`) is the only
  authority for course media. A reference is `media:<lowercase sha256>.<ext>`
  (`mp3`, `png`, `jpg`, `jpeg`, `webp`); the file is
  `<AppSupport>/quisquislingo_course_media/course_<sha256(courseId)>/<sha256>.<ext>`.
  Use `referencesOf(course)`, `existingFile`, `addBytes` (verifies the digest
  and the 50 KB image / 50 MB MP3 limits), `copyReferences`,
  `deleteUnreferenced`, `deleteCourse`.
- **`Course.fromJson`** already refuses any media that is not bundled,
  embedded or a `media:` reference. JSON never contains media bytes.
- **Nothing is shared between Courses.** Fork, Copy as New Course and Merge
  copy the files they need; cleanup reads only the Course being saved.
- **`CustomCourseTransferService`**
  (`lib/services/custom_course_transfer_service.dart`) holds the single
  validator `courseFromBytes`, the exports `buildCourseExport`,
  `exportCourse`, `exportCourseTo`, and the dialog imports. Reuse them; do not
  add a second validator or serializer.
- **The import flow** is `_importCourse` in
  `lib/screens/course_projects_screen.dart`: Audit gate, the Publisher
  install/update dialog and the existing collision choices (Replace/update,
  Copy as New Course, Fork, Cancel). Keep it; feed it the Course from the
  package.
- **ZIP reading example:** `ImageBankService.importBankZip`
  (`lib/services/image_bank_service.dart`), package `archive` (already a
  dependency).
- To show a Course image use `CourseMediaImage`; to resolve a recording use
  `RecordedAudioService.resolveSourceForClip(clip, courseId:)`.

## Tranche 2 → Revision 3 (`2.0.43+243003`)

Package format (plan §2):

```text
qql-course-package.json   {"packageFormat": 1}
course.json               the Course, byte-for-byte as stored
media/<sha256>.<ext>      every media: file the Course uses, once
```

1. **Export** (fixed `Exports` folder and Save to…) produces only `.zip`.
   Include every referenced file. If a referenced file is missing, stop and
   say which file and where it is used; do not produce an incomplete package.
2. **Import** (fixed `Imports` folder and Open from…) accepts `.zip` and
   `.json`. A course package is recognised by `qql-course-package.json`; an
   Image Bank ZIP keeps its own route.
3. **Validate everything before writing anything:** total size ≤ 300 MB, also
   measured decompressed; only the names above (no subfolders, no `..`, no
   absolute paths, no links, nothing else); each media file's SHA-256 equals
   its name and respects the size and type limits; every reference the Course
   uses is present; extra files are ignored and not copied; `course.json`
   passes `courseFromBytes` (signature and Audit included). Validate the
   cover image here: square 512 × 512, PNG/JPEG/WEBP, ≤ 100 KB.
4. Only after the Course is accepted (including the collision choice), copy
   its media into the target Course's folder. Copy as New Course and Fork
   from an import create a new Course ID: the media must land in the new
   folder. If saving fails, remove what was copied.
5. **Merge From…** accepts a package as well.
6. Android and iOS have no system dialog: the fixed folders must work there.
7. Add `demo_courses/italian_demo_2_pick_the_translation.zip` next to the
   `.json`.
8. Update Editor Help (English and Italian: the export text still says "Export
   Course JSON" and "bytes are not embedded"), `docs/COURSE_EDITOR.md`,
   `docs/COURSE_JSON_FORMAT.md` and the README.

Tests to add at least: round trip, altered file, missing file, dangerous
name, extra file, over-limit (compressed and decompressed), a ZIP that is not
a course, collision choices carrying media, cover checks, `.json` import still
working.

## Tranche 3 → Revision 4 (`2.0.43+243004`)

1. Remove `CustomCourseTransferService.rejectUnreachablePublisherRecordings`
   and rewrite `test/publisher_recorded_audio_test.dart`: a Publisher Course
   with media now arrives inside the package.
2. Publisher install and update
   (`CourseEditorService.installExternalOfficialUpdate`) copy the package media
   into the Course folder; an update removes files the new version no longer
   uses. Uninstall keeps media, as today.
3. `tools/sign_course.dart` produces the signed ZIP. Because references are
   content addresses inside the signed JSON, the signature also pins the media.
   Add a signed Dummy fixture with media (the Dummy private key is test data in
   `test/fixtures/publishers/`; OpenSSL 3 is installed).
4. Documentation: `docs/PUBLISHER_SIGNING_GUIDE.md` and the in-app
   `lib/screens/publisher_signing_help_content.dart` must stay word-for-word
   identical (`test/publisher_signing_help_test.dart` enforces it);
   `docs/AUDIO_PACKS.md` marked superseded (its download model conflicts with
   offline-first); `docs/MEDIA_LIBRARIES_PLAN.md` §7 updated.

## Per revision

- `pubspec.yaml`, `lib/services/app_metadata.dart` (build number and
  `correctiveRevision`) and the version tests
  (`app_metadata_225_04`, `qql_233_revision_platform_contract`,
  `qql_229_revision3`, `course_audit_report_225`).
- Beta expiry: 30 days from the release date
  (`lib/services/beta_lifecycle_service.dart`, `test/beta_lifecycle_test.dart`,
  README). Released on 21 September 2026 it stays 2026-10-21; on a later date
  it moves.
- CHANGELOG, `docs/243_CHANGE_SUMMARY.md`, `docs/243_VALIDATION.md`,
  `AGENTS.md` release boundary, README, plan §0.

## Lessons from Revisions 0–2

- **Run every test that reads a text you change.** Revision 0 changed the
  Publisher Help and the signing guide differently; the test comparing them
  was not in the focused set and the slip reached a commit. Before committing,
  `rg` the tests for the files and strings you touched.
- **Help strings are single-quoted Dart.** An English apostrophe breaks
  compilation; use `’`, as the Italian texts do. Analyze `lib` after editing
  Help.
- **Do not `dart format` whole legacy files.** Several are not
  formatter-clean; formatting them rewrites lines you did not touch. Format
  only your own code and check the diff.
- **Widget tests and real files:** use `pumpUntilFileIoState`
  (`test/support/pump_file_io.dart`); a fixed number of pumps is not enough.
  Do not show course images with `Image.file`: it memory-maps the file, and on
  Windows the file then cannot be deleted.
- **Shell:** long Python heredocs in Bash fail on this machine. Write the
  script to the scratchpad and run it. Files use a mix of LF and CRLF;
  preserve each file's line endings.
- **Known remaining gap, not in scope:** the Course Selector shows no notice
  for unreadable stored Courses (Course Manager and Inventory do).
