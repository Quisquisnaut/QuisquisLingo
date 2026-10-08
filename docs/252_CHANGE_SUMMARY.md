# Build 252 change summary

## Revision 0 — Exercise Authoring

`2.0.52+252000`, dated 2026-09-24. A pure draft builder takes Exercise
field values and returns either the candidate `Exercise` or typed field
errors. `ExerciseEditorScreen` retains controllers, dialogs, navigation and
feedback. `CourseAuthoringSession` remains the single owner of the final
Course update; the extraction adds no mutable Course copy or publication
authority.

Exercise JSON v11, stable IDs, Draft and Published rules, image provenance,
and Preview, Save and Cancel paths keep their established behavior across the
affected templates. Course Model v11, package format 1, stored data and keys,
rights, signatures, scoring, progression and the final Course confirmation
remain unchanged. The automatic orphan MP3 prompt and Course dirty
interaction belongs to a later behavior revision.

The Beta expiry is `2026-10-24 23:59:59` local time, 30 days from this
revision's release date. This is a source release without a Windows package.
See [252_VALIDATION.md](252_VALIDATION.md) for verification evidence and
[252_HANDOFF.md](252_HANDOFF.md) for the release handoff.
