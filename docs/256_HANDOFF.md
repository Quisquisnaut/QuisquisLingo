# Build 256 handoff — exercise architecture redesign (Course Model v12)

Resume from this file alone. Plan: `docs/256_EXERCISE_ARCHITECTURE_PLAN.md`
(Part A decisions, Part B sessions, Part C verified audit notes, Part D
condensed specification). Working rules: Part A.1 of the plan. Reference:
`docs/EXERCISE_ARCHITECTURE_V12.md`. Summary: `docs/256_CHANGE_SUMMARY.md`.
Evidence: `docs/256_VALIDATION.md`.

## State (27 September 2026)

- Branch `claude/256-exercise-architecture`, created from `main` at
  `611a1a1` (Build 255 handoff; version `2.0.55+255007`).
- Last commit on the branch: none yet. Session 1 (Revision 0,
  `2.0.56+256000`) is implemented in the working tree; the analyzer is clean
  and the focused tests pass; the complete suite is the next step, then the
  session report, this handoff and the Revision 0 commit.
- Untracked files that are the owner's and stay untouched:
  `devtools_options.yaml`, `tools/cloud_setup.sh`.
- Auto-resume: an in-session hourly cron (`CronCreate` job `6dfcb607`, at
  :23) re-enters the work from this handoff if the session stopped, until it
  expires after 7 days or all six sessions are committed (then delete it with
  `CronDelete`). It cannot survive the desktop app closing.

## Sessions

| Session | Revision | Version | State |
| --- | --- | --- | --- |
| 1 Canonical definitions | 0 | 2.0.56+256000 | implemented; full suite and commit pending |
| 2 Course Model v12 | 1 | 2.0.56+256001 | not started |
| 3 Runtime and Audit | 2 | 2.0.56+256002 | not started |
| 4 Presets and Generic Primitive Editor | 3 | 2.0.56+256003 | not started |
| 5 Interoperability | 4 | 2.0.56+256004 | not started |
| 6 Laboratory, Assign, final verification | 5 | 2.0.56+256005 | not started |

## What Session 1 wrote

- `lib/models/canonical/` (`exercise_primitive.dart`, `evaluation_mode.dart`,
  `primitive_options.dart`, `primitive_capability_registry.dart`,
  `content_flow.dart`, barrel `canonical.dart`).
- `ExercisePreset.primitive` replaces `CanonicalExerciseModel` (call sites:
  `course_audit_service.dart`, `exercise_architecture_224_test.dart`,
  `translation_choice_239_test.dart`, `exercise_laboratory_254_test.dart`).
- Tests `canonical_primitives_256_test.dart`,
  `capability_registry_256_test.dart`, `content_flow_256_test.dart`.
- Version bump touchpoints: `pubspec.yaml`, `app_metadata.dart`, README
  banner and new paragraph, CHANGELOG entry, `beta_lifecycle_service.dart`
  comment, `beta_lifecycle_test.dart` title, the four version tests (note:
  they also pin `AppMetadata.build`, which is the development phase), AGENTS.md
  release-boundary entry, `EXERCISE_ARCHITECTURE_224.md` historical note.

## Session 2 starting points (next)

- Serialization design is fixed by `EXERCISE_ARCHITECTURE_V12.md` (options as
  a JSON object keyed by `OptionKey.serialized`; `authoringMetadata.presetId`
  replaces Content `editorTemplate`; element attributes `playback`,
  `required`, `language`; item attribute `side`; target attributes `reveal`,
  `region`; `feedback.showAlternatives`; Input `literalAnswers`; Arrange
  `joiner`).
- Storage per plan §A.14: private `QQL_Courses_v12/Custom|Publisher`;
  backups stay in `Backups/Courses` with manifest format v12 and v11 versions
  listed as unreadable; add the earlier folder to `QqlEarlierPrivateFolders`,
  `AppResetService`, `InventoryService`, `docs/239_RESET_STORAGE_INVENTORY.md`.
- Converter library in `lib/` without Flutter imports; tools
  `convert_course_to_v12.dart` (JSON or ZIP, regenerates the manifest,
  strips signatures) and `convert_stored_courses_256.dart` (owner's stored
  custom Courses, never overwriting).
- Bundled Courses to convert: the 4 in `assets/courses` (new official
  checksums); update `tools/generate_*_254.py`, `tools/validate_courses.py`,
  the Publisher fixtures (re-sign with the dummy key), `docs/COURSE_JSON_FORMAT.md`,
  EN/IT/ES Help naming the format; AGENTS.md "Course Model v11 invariants"
  section rewritten for v12 (plan §A.9).
- Conversion traps: plan Part C and the 16-point list at the end of
  `EXERCISE_ARCHITECTURE_V12.md`.

## Decisions in flight

- None. The two start questions are answered in plan §A.14 (storage Option 2;
  one-off `tools/convert_stored_courses_256.dart`).

## Gotchas

- Full suite: `flutter test --no-pub --concurrency=1` (about 22 minutes) run
  through the keep-awake wrapper (scratchpad `run_awake.ps1`, which holds
  `ES_CONTINUOUS | ES_SYSTEM_REQUIRED` and clears it in `finally`). Always the
  path spelling `C:\QQL\QuisquisLingo`. Never run two Flutter commands at once.
- Large edits: Bash heredocs above roughly 20 KB fail with ENAMETOOLONG and
  a bash parse error swallows a whole multi-command heredoc; write big files
  and edit scripts with the file tool (scratchpad) and run them.
- A Dart `library;` directive must precede imports.
- Audit code count is pinned at 104 in
  `test/audit_branch_ownership_226_02_revision4_test.dart` line 212.
