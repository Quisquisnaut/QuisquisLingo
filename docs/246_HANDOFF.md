# Build 246 handoff

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

## Validation and limits

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

Merge this validated Build 246 commit before starting Build 247. Begin Build
247 Revision 0 in a new Package Import session from the then-current `main`.
Read `AGENTS.md`, `pubspec.yaml`, this handoff and the
[approved architecture roadmap](ARCHITECTURE_ROADMAP_246_PLUS.md) again, then
write the detailed Package Import contract and characterization tests before
moving its staging/installation/confirmation lifetime. Build 247 must not be
folded into this Merge revision. The manifest shared-image coverage question
in the roadmap needs a fixture before any format or behavior decision.

This handoff accompanies the one Build 246 Revision 0 commit on
`codex/246-merge`. The implementation is in
`lib/services/course_editor_service.dart`,
`lib/services/course_merge_service.dart` and
`lib/screens/course_projects_screen.dart`; the new behavior tests are
`test/course_merge_media_workflow_246_test.dart` and
`test/course_merge_submission_246_test.dart`. Release metadata and notes are
in `pubspec.yaml`, `lib/services/app_metadata.dart`, `AGENTS.md`, `README.md`,
`CHANGELOG.md`, `docs/246_MERGE_PLAN.md`, `docs/246_CHANGE_SUMMARY.md` and
`docs/246_VALIDATION.md`.
