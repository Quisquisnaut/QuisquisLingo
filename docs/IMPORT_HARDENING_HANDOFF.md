# Import hardening and Image Library — handoff

Keep this file current at the end of **every** revision, so that work can
resume after a pause or with another agent. Plan and decisions:
[IMPORT_HARDENING_PLAN.md](IMPORT_HARDENING_PLAN.md). Rules: `AGENTS.md`.

## Where things stand (updated 2026-09-21, Revision 7)

| Revision | Version | Commit | Content |
|---|---|---|---|
| 5 | `2.0.43+243005` | `86ae4d2` | Image Library usability: IN USE badge, badge overlay/filter, sorting, merged device/Course tile, compact tiles and chips |
| 6 | `2.0.43+243006` | `0976ed0` | Tranche 0 memory-safety fixes: cover header check, Image Bank pre-scan and bounded inflation, 4096 px icons/flags, animated images refused on import |
| 7 | `2.0.43+243007` | *pending* | Image library tidy-up: `CourseImageUsage` single usage rule (presentations and GuideBooks now count), `image_library_rules.dart`, `ExerciseImageField` |

Nothing is pushed; all commits are local on `main`. The untracked
`devtools_options.yaml` predates this work: never commit or delete it.

## Next steps, in order (plan §6a)

1. **Revision 8 — badge order and removal** (plan §6b). Build on the
   Revision 7 pieces:
   - **Badge order:** change `imageBadgeOrder` and `imageBadgesOf` in
     `lib/services/image_library_rules.dart` (IN USE first, then QQL, DEVICE,
     COURSE) and the badge list in `lib/widgets/exercise_image_field.dart`.
     Update `image_library_rules_test.dart`, whose first test pins today's
     order on purpose.
   - **Removal:** find every use with `CourseImageUsage.uses(course)`. Its
     `location` strings are ready for the confirmation dialog. Clear the uses
     in the `CourseEditorTransaction` working copy. Then run the canonical
     Audit and make Draft every affected exercise it reports invalid. Files go
     only through the existing `deleteUnreferenced` after a confirmed save.
     Presentation and GuideBook uses count too.
   - Add the bin (tooltip "Remove from this Course") to the library tile when
     the viewer can edit the Course. A QQL or DEVICE image the Course does not
     use gets no bin.
2. **Tranches 0b, 1, 2, 2b, 3, 4, 5** in that order (plan §4, §6).

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
- `sed -i` with `^…$` anchors sometimes fails to match on this checkout. For
  line removals, use Python working on bytes (see the Revision 7 import
  cleanup).
- `round.exercises` is a lossy view: it skips the Lesson introduction and
  turns presentations into old-style flashcards without their images. Use
  `LearningContent` (`round.content`, `lesson.guidebook.content`) whenever
  completeness matters.
