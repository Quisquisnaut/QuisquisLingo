# Import hardening and Image Library — handoff

Keep this file current at the end of **every** revision, so that work can
resume after a pause or with another agent. Plan and decisions:
[IMPORT_HARDENING_PLAN.md](IMPORT_HARDENING_PLAN.md). Rules: `AGENTS.md`.

## Where things stand (updated 2026-09-21, Revision 17 committed)

| Revision | Version | Commit | Content |
|---|---|---|---|
| 5 | `2.0.43+243005` | `86ae4d2` | Image Library usability: IN USE badge, badge overlay/filter, sorting, merged device/Course tile, compact tiles and chips |
| 6 | `2.0.43+243006` | `0976ed0` | Tranche 0 memory-safety fixes: cover header check, Image Bank pre-scan and bounded inflation, 4096 px icons/flags, animated images refused on import |
| 7 | `2.0.43+243007` | `4230d94` | Image library tidy-up: `CourseImageUsage` single usage rule (presentations and GuideBooks now count), `image_library_rules.dart`, `ExerciseImageField` |
| 8 | `2.0.43+243008` | `8a27dfe` | Badge order IN USE first; Remove from this Course (`CourseImageRemoval`, Draft on Audit error); `imageLibrary` with Keep in library; bin on every Course-stored image |
| 9 | `2.0.43+243009` | `c34aa60` | Tranche 0b: QQL image metadata read-only; Local words; device categories; schema-2 metadata document (fixes the snapshot failure) |
| 10 | `2.0.43+243010` | `b2b7d7d` | Tranche 1: safe import foundation (streamed staging under real limits, ordinary files only, per-file batch results, cancellation) |
| 11 | `2.0.43+243011` | `3ed36fa` | Tranche 2: one image validator for every image import; Shared Library multi-file import with summary; N6/N7 fixed |
| 12 | `2.0.43+243012` | `a40999d` | Tranche 2b: add images and Image Banks to a Course's own library; readBank split; entry metadata |
| 13 | `2.0.43+243013` | `da9a3a3` | Tranche 3: `Mp3Validator` on every MP3 route; multi-file Audio Library Open from… with summary; duplicate clips skipped; Dummy media fixture re-signed |
| 14 | `2.0.43+243014` | `eb0857a` | Tranche 4 part 1: `BoundedZipReader` for banks and packages; bank allowlist, object manifest, field bounds, Admin choice on new categories; `JsonLimits`/`CourseShapeLimits` |
| 15 | `2.0.43+243015` | `a188613` | Tranche 4 part 2: Course packages parsed from disk; referenced media staged one at a time; `CoursePackage.mediaReferences`/`mediaBytes`/`discard()` |
| 16 | `2.0.43+243016` | `21bf653` | Tranche 5 part 1: content duplicates skipped; bank ID conflicts Skip/Replace/Keep both + Apply to all; `ImageProvenance`; date sort; screen renamed Shared Images; web page saved as `.mp3` explained |
| 17 | `2.0.43+243017` | `2959fff` | Clearer media errors and wrong-file identification; Image Bank manifest creation guidance in errors and Help; On-Device TTS label and mode-specific Audio Library text/actions |

Revisions 5–16 are pushed to `origin/main`; Revision 17 is committed locally.
The untracked `devtools_options.yaml` and `assets/lesson_plants/plant_1.zip`
predate this work: never commit or delete them.

## Next steps, in order (plan §6a)

1. **Revision 18 (owner decision 2026-09-21):** in the full-size preview
   (`FlatImageLibraryScreen._preview`, both Shared Images and the Course
   Editor's Image Library), a tooltip on the picture: hover on desktop,
   long-press on phones, none on tiles. Content: file name (QQL asset name;
   the recorded original name from Revision 16 on; the stored name for older
   imports; "Course file (named by content)" for `media:` files), approximate
   size, pixel dimensions, format, added date (recorded, else derived; QQL
   images "Included with QQL"), bank name for bank images, attribution;
   "File missing" when the file is gone; merged tiles add "Also stored in
   this Course". Owner: "Yes to all. Only English": format and bank
   name in, importing Admin's name out (as proposed; one line to add if the
   owner wants it), Help text in English only.
2. **Phase 20 route-matrix adversarial suite**: Revision 19.

## Owner decisions already taken

All recorded in plan §6, §6a–§6c and Tranche 0b/2b. The most consequential:

- Validators apply to new imports only; stored media is never revalidated.
- QQL image metadata is read-only. Admins add Local words (label "Local:")
  and device categories.
- An MP3 containing ID3 artwork is rejected.
- An Image Bank may contain only the manifest plus the images it references.
  It may declare a bank-wide default attribution.
- Course Image Library (Tranche 2b): new optional v11 `imageLibrary`. Unused
  library images travel in the ZIP and backups. No image-count limit beyond
  the 300 MB package limit.
- Android SAF is out of scope. The Course package limit stays 300 MB.
- One rule for image usage, counting everywhere in the Course
  (`CourseImageUsage`). Never add a second walker; extend that one.
- Splitting `course_editor_screen.dart` into separate screens is deferred.
  Revision 7 extracted only the image section.
- Removing an image from a Course clears every use and makes Draft whatever
  the Audit then rejects (`CourseImageRemoval`). A Course-stored image the
  Course does not use has no bin until Tranche 2b's `imageLibrary`.

## Release checklist per revision

1. Bump `pubspec.yaml`, `lib/services/app_metadata.dart` (`buildNumber`,
   `correctiveRevision`, `publicBuildLabel`) and the four version tests
   (`app_metadata_225_04`, `course_audit_report_225`, `qql_229_revision3`,
   `qql_233_revision_platform_contract`).
2. Beta expiry: 30 days from the release date
   (`lib/services/beta_lifecycle_service.dart`). For releases dated
   2026-09-21 it stays `2026-10-21 23:59:59`.
3. Update README (version line, Beta paragraph, the Build 243 paragraph),
   CHANGELOG, the `AGENTS.md` release-boundary line, and
   `docs/243_CHANGE_SUMMARY.md` and `docs/243_VALIDATION.md` (or the next
   build's equivalents).
4. Run `flutter analyze`, the full `flutter test --no-pub` once (about 14
   minutes, about 1,970 tests), the four `tools/validate_*.py` validators and
   `git diff --check`.
5. Commit only the revision's files, then update **this handoff**.

## Gotchas learned in this work

- `dart format` on a whole file reflows unrelated pre-existing lines. Keep
  only the formatting of lines you changed, and revert the rest.
- On Windows, pass non-ASCII text such as `·` or `×` to Python edits through
  a UTF-8 script file (`PYTHONUTF8=1 python script.py`), not a heredoc. The
  console code page corrupts it.
- Widget tests that render Course media from a temporary folder must wait for
  the image to load before disposing. Otherwise Windows keeps the file open
  and the temporary folder cannot be deleted (see
  `flat_image_library_243_source_test.dart`).
- `archive` 4.0.9: `ZipDecoder.decodeBytes` eagerly inflates Unix symlink
  entries. Always pre-scan with `ZipDirectory` first. `ArchiveFile.readBytes()`
  inflates the whole entry, so use `readBoundedEntry`.
- `PortableExerciseImageService.decode` and `validate` run on stored Courses
  (render, Audit, exercise save). Import-only rules belong in `fromBytes`.
- Every confirmed Course save deletes unreferenced files from the Course
  folder (`CourseEditorService`, `deleteUnreferenced`). Anything a Course must
  keep has to be referenced from the Course JSON.
- Use `rg`/git, never PowerShell `Get-Content` (`AGENTS.md`).
- A full `flutter test` run can be interrupted before its summary (Revision 7:
  exit code 4 at 1,893 passed, 0 failed). Look for `[E]` markers before
  treating it as red, and do not re-run it without asking the owner.
- Test media references must be real hex: `media:` plus 64 of `0-9a-f`.
  `Course.fromJson` rejects anything else.
- `sed -i` with `^…$` anchors sometimes fails to match on this checkout. For
  line removals, use Python working on bytes (see the Revision 7 import
  cleanup).
- Test MP3s must be real: use `syntheticMp3(seed:)` from
  `test/support/synthetic_mp3.dart`. The signed Dummy media fixture is
  re-signed with the Dummy test key (steps in
  `test/fixtures/publishers/README.md`).
- Stopping a background suite with TaskStop does not stop its
  `flutter test` child: it keeps writing into the same log. Wait for it to
  exit or use a fresh log name before re-running.
- `round.exercises` is a lossy view: it skips the Lesson introduction and
  turns presentations into old-style flashcards without their images. Use
  `LearningContent` (`round.content`, `lesson.guidebook.content`) whenever
  completeness matters.
