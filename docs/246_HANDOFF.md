# Build 246 handoff

## Revision 1 current state

Build 246 Revision 1 is `2.0.46+246001`, following Revision 0 commit
`5d6723e` on `codex/246-merge`. The Beta expiry remains
`2026-10-22 23:59:59` local time. Course package Import and Merge now accept
one enclosing folder only when it exactly matches the ZIP filename stem.
Root-level packages retain their existing path; other unexpected, mixed,
nested or unsafe layouts remain rejected. The UI shows a nonblocking warning
for an accepted matching folder. Import and Merge Help describe the rule, and
Merge Help states the existing same-ID Course version or Modified timestamp
condition accurately. Course Model v11, stored formats and keys, package
manifest and signatures, authoring rights, scoring and the single top-level
save boundary remain unchanged.

The focused package and Merge tests passed 14/14, the analyzer found no
issues, all four asset validators passed, and the complete Flutter suite
passed 2,274/2,274 tests. The final staged diff check is recorded in
[246_VALIDATION.md](246_VALIDATION.md). Revision 1 source changes are in
`lib/services/course_package_service.dart`,
`lib/services/custom_course_transfer_service.dart` and
`lib/services/file_dialog_service.dart`,
`lib/services/import/selected_external_file.dart`,
`lib/screens/course_projects_screen.dart` and
`lib/screens/editor_help_content.dart`, with behavior tests in
`test/course_package_on_disk_tranche4b_test.dart` and
`test/course_merge_submission_246_test.dart`. Release metadata and notes are
recorded in `pubspec.yaml`, `lib/services/app_metadata.dart`, their
version tests, `AGENTS.md`, `README.md`, `CHANGELOG.md`,
`docs/COURSE_JSON_FORMAT.md`, `docs/246_CHANGE_SUMMARY.md` and
`docs/246_VALIDATION.md`.

## Revision 0 state

Build 246 Revision 0 is `2.0.46+246000`, Course Model v11. It starts from
`main` commit `badaf85b5d1287d363621ee171bc1e4afb029167` in the isolated
`codex/246-merge` branch. The Beta expiry is `2026-10-22 23:59:59` local time.

The Merge candidate still comes from `CourseMergeService`; the Merge screen
still owns selections, Audit feedback and package staging. The new
`CourseEditorService.confirmMergedCourse` owns the destination media copy,
single top-level confirmation and recovery cleanup under its Course lock.
The screen freezes the choices and permits one in-flight submission through
package cleanup. No Course Model version, stored format/key, package or
signature, authoring right, or learner scoring/progression rule changed.

## Revision 0 validation and limits

The focused Merge suite passed 27/27 after the final same-frame guard; the
earlier storage, transaction, version and Audit group passed 47/47. The final
analyzer found no issues, and the four asset validators found no issues. The
complete Flutter suite and final diff check are recorded in
[246_VALIDATION.md](246_VALIDATION.md).

The existing nonblocking behavior for media missing from both source folders
remains. An in-isolate per-Course lock does not coordinate external writers;
this remains the documented Build 245 storage limit. Manual device smoke
testing and a platform release artifact remain outside this source handoff.

## Next boundary

Merge Build 246 before starting Build 247. Begin Build 247 Revision 0 in a
new Package Import session from the then-current `main`.
Read `AGENTS.md`, `pubspec.yaml`, this handoff and the
[approved architecture roadmap](ARCHITECTURE_ROADMAP_246_PLUS.md) again, then
write the detailed Package Import contract and characterization tests before
moving its staging/installation/confirmation lifetime. Build 247 must not be
folded into this Merge revision. The manifest shared-image coverage question
in the roadmap needs a fixture before any format or behavior decision.

Revision 0 is commit `5d6723e` on `codex/246-merge`. Its implementation is in
`lib/services/course_editor_service.dart`,
`lib/services/course_merge_service.dart` and
`lib/screens/course_projects_screen.dart`; the new behavior tests are
`test/course_merge_media_workflow_246_test.dart` and
`test/course_merge_submission_246_test.dart`. Release metadata and notes are
in `pubspec.yaml`, `lib/services/app_metadata.dart`, `AGENTS.md`, `README.md`,
`CHANGELOG.md`, `docs/246_MERGE_PLAN.md`, `docs/246_CHANGE_SUMMARY.md` and
`docs/246_VALIDATION.md`.
