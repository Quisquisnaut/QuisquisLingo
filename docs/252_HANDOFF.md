# Build 252 handoff

## Revision 0 source state

Build 252 Revision 0 is `2.0.52+252000`, dated 2026-09-24, on
`codex/build-252-exercise-authoring`. The isolated checkout started from
merged `main` at `7de16ea`; its final parent is `0bedcb3`, which adds only
documentation after that starting point.
`ExerciseDraftBuilder` owns the former screen-side Exercise construction
rules as one pure draft-values-in, candidate-or-typed-field-error-out
contract. `ExerciseEditorScreen` takes a detached form snapshot and retains
controllers, dialogs, navigation and feedback. The existing
`ScriptRecognitionController` still builds script Select content and keeps
its option identities. The builder attaches selected shared-image
provenance for Save; Preview keeps the raw candidate. Neither path writes
the Course. `CourseAuthoringSession` remains the only final Course update
owner.

This is a source-only architectural extraction. Exercise and Course
JSON v11, stable IDs, Draft/Published rules, image provenance and
Preview/Save/Cancel behavior are preserved. Course Model v11, package
format 1, stored data and keys, authoring rights, signatures, scoring,
progression and top-level Course confirmation remain unchanged. Beta
expiry is `2026-10-24 23:59:59` local time, 30 days from the actual
24 September release date. No Windows package was built.

## Tested state

The old editor passed 146 existing affected tests and 14 new
characterization tests before extraction. The builder contract test
failed before the owner existed and passed after implementation. The
integrated focused run passed 218/218. The affected characterization
test passed 14/14 after an analyzer-only string correction; the final
analyzer reported no issues. All four bundled asset validators passed
with zero issues. The complete Flutter suite passed **2452/2452** with
exit code 0 while PowerShell held and then released a temporary Windows
execution-state request. The commands and evidence are recorded in
[252_VALIDATION.md](252_VALIDATION.md).

## Known limits and next step

The automatic orphan-MP3 prompt and Course dirty interaction is still
outside this revision. Script recognition keeps its existing controller
owner for its canonical Select fields; the new builder receives that
controller's candidate as a detached input. The next approved roadmap
step is **Round Attempt**, to begin only after this Exercise Authoring
step is reviewed and merged into `main`.

The task is one local commit containing only the builder extraction,
characterization and contract tests, Build 252 metadata, plan, change
summary, validation and this handoff. The original main checkout's
pre-existing `devtools_options.yaml` and the user's concurrent edit to
`docs/251_CHANGE_SUMMARY.md` are untouched. No push, PR or merge is part
of this task.
