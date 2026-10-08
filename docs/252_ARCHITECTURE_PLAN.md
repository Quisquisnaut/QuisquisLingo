# Build 252 architecture plan

## Baseline and scope

Start from merged `main` at `7de16ea` in the isolated
`codex/build-252-exercise-authoring` checkout. Build 252 Revision 0 is a
source-only Exercise Authoring extraction. Course Model v11, package format 1,
persisted data and keys, signatures, rights, scoring, progression, and the
single confirmed Course save remain unchanged. The automatic orphan-MP3 prompt
and Course dirty interaction is outside this step.

## Revision 0 — pure Exercise draft builder

1. Characterize the current editor before changing production code: v11
   LearningContent JSON, stable option and gap IDs, Draft versus Published
   validation, image provenance, and Preview, Save, and Cancel for ordinary,
   inline-gap, multi-select, contextual, text, and script templates.
2. Give the screen-owned `_buildCandidate` rules one pure input/output boundary:
   an immutable snapshot of draft field values plus the original Exercise and
   requested publication state enters; a candidate Exercise or a typed field
   error leaves. Keep the existing script-recognition controller's independent
   canonical Select construction and stable-ID behavior, passing its candidate
   through the same result boundary. The widget retains controllers, error
   presentation, image validation, Audit dialogs, navigation, and the existing
   Preview versus Save provenance handling. `CourseAuthoringSession` remains
   the only final Course update owner.
3. Run focused tests, analyzer, all four asset validators, and the full Flutter
   suite on the settled tree. Hold a temporary Windows execution-state request
   in the supervising PowerShell process for the suite and clear it in
   `finally`. Bump to `2.0.52+252000`, calculate the 30-day Beta expiry from
   the actual release date, update release notes and tests, write validation
   and handoff before one task-only local commit. Do not build a Windows
   package, push, open a PR, or merge.
