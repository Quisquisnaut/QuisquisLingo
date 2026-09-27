# Build 256 handoff — exercise architecture redesign (Course Model v12)

Resume from this file alone. Plan: `docs/256_EXERCISE_ARCHITECTURE_PLAN.md`
(Part A decisions, Part B sessions, Part C verified audit notes, Part D
condensed specification). Working rules: Part A.1 of the plan. Reference:
`docs/EXERCISE_ARCHITECTURE_V12.md` (its "Course Model v12 JSON" section is
the Session 2 design). Summary: `docs/256_CHANGE_SUMMARY.md`. Evidence:
`docs/256_VALIDATION.md`.

## State (27 September 2026, 07:15)

- Branch `claude/256-exercise-architecture`, created from `main` at
  `611a1a1` (Build 255 handoff; version `2.0.55+255007`).
- Commits: `507be89` Build 256 Revision 0 (canonical definitions;
  `2.0.56+256000`; suite 2,813 passed, 1 skipped); `4e19353` handoff.
- **Session 2 (Revision 1, `2.0.56+256001`) is complete in the working
  tree and waiting for the complete suite**, started at 07:14 through the
  keep-awake wrapper (log: scratchpad `full_rev1.log`). `dart format` on
  the 63 changed Dart files changed nothing; `flutter analyze`: no issues;
  the focused batch of 45 test files (688 tests) passes after two fixes
  (`course_model_v6_test` still expected `formatVersion` 11; the Publisher
  conversion test lacked the official provenance the v12 constructor
  requires).
- When the suite passes: write the Revision 1 section of
  `docs/256_VALIDATION.md` (numbers above plus the suite result), commit
  everything except the owner's untracked `devtools_options.yaml` and
  `tools/cloud_setup.sh` as "Build 256 Revision 1: Course Model v12", write
  this handoff again and commit it, then start Session 3 at once (plan
  Part B, Session 3). If the suite fails: rerun the failing file alone; any
  fix means rerunning that file and the complete suite before the commit
  (plan A.1).
- Untracked files that are the owner's and stay untouched:
  `devtools_options.yaml`, `tools/cloud_setup.sh`.
- Auto-resume: an in-session hourly cron (`CronCreate` job `6dfcb607`, at
  :23) re-enters the work from this handoff if the session stopped, until it
  expires after 7 days or all six sessions are committed (then delete it with
  `CronDelete`). It cannot survive the desktop app closing.

## Session 2 status

Everything in the plan's Session 2 list is in the working tree:

- Model (`lib/models/exercise_canonical.dart`, `course_models.dart`,
  `content_flow.dart` JSON), converter library, `tools/convert_course_to_v12.dart`,
  `tools/convert_stored_courses_256.dart`, `tools/qql_course_v12.py`, the
  three generators and `tools/validate_courses.py` (every `--check` and the
  validator pass); `tools/convert_course_to_v11.dart` retired.
- Storage cut: `QQL_Courses_v12`, retired `QQL_Courses`
  (`QqlEarlierPrivateFolders.coursesV11`), backup manifest format 12.
- Data: four bundled Courses, demo package JSON + ZIP, Publisher fixtures
  re-signed, `test/fixtures/v11/` originals with a README.
- Call sites on `layout`/`targetAssignments`; editor publication and
  shared-image changes copy the canonical exercise (`withPublicationState`,
  `copyWith`); Search indexes the inline sentence.
- Help EN/IT/ES, `COURSE_JSON_FORMAT.md` (format 12),
  `239_RESET_STORAGE_INVENTORY.md`, AGENTS.md (invariants rewritten for v12
  plus the boundary entry), README, CHANGELOG, `256_CHANGE_SUMMARY.md`,
  `EXERCISE_ARCHITECTURE_V12.md` status; version `2.0.56+256001` (Beta
  expiry stays 27 October 2026, same release day).
- Still to write: the Revision 1 section of `256_VALIDATION.md` (after the
  suite) and the six-part session report.

Session 3 starting points (plan Part B Session 3; A.5, A.6, A.7, A.10,
A.11):

- The runtime reads the canonical fields (`primitive`, `options`, `layout`,
  `targets`, `evaluation`, `feedback`) instead of the v11 views on
  `Exercise`; delete each view when it loses its last reader
  (`interaction`, `evaluation`, `type`, `prompt`, `answers`,
  `inlineSentence`, `targetAssignments`, …). 72 test files build exercises
  with `Exercise(...)`: keep that constructor as a test helper.
- Executability from `PrimitiveCapabilityRegistry.runtimeSupport`: a
  readable-but-not-executable exercise is skipped by delivery and reported
  by the Audit with the plan's severities (A.5, A.6).
- The Audit checks canonical data: registry option and pairing rules, the
  preset-versus-content check through `authoringMetadata.presetId`.
- Duel pool by capability (A.10): every single-answer Select is eligible;
  multiple-answer Choose leaves the pool (report the availability change in
  the CHANGELOG and the session report).
- Inline-gap Arrange grades block content, not block IDs (A.11; the
  Laboratory's `arrange_gap_repeat`).
- Linear flows play (A.7); a Round with branch transitions is "can't run
  yet" at Round level.

## Sessions

| Session | Revision | Version | State |
| --- | --- | --- | --- |
| 1 Canonical definitions | 0 | 2.0.56+256000 | committed `507be89` |
| 2 Course Model v12 | 1 | 2.0.56+256001 | complete in the working tree; suite running |
| 3 Runtime and Audit | 2 | 2.0.56+256002 | not started |
| 4 Presets and Generic Primitive Editor | 3 | 2.0.56+256003 | not started |
| 5 Interoperability | 4 | 2.0.56+256004 | not started |
| 6 Laboratory, Assign, final verification | 5 | 2.0.56+256005 | not started |

## Decisions in flight

- None new. Applied so far in Session 2 without asking (all within the
  plan): `tools/convert_course_to_v11.dart` is retired because it can no
  longer load v11 (the v12 converter takes v11 only; v9/v10 files need the
  Build 255 tool first); a Presentation given as the v11 shape without a
  timestamp gets the Round's `updatedAt` in files and the epoch in memory;
  custom presentation action lists become the standard completion mode.

## Gotchas

- Full suite: `flutter test --no-pub --concurrency=1` (about 22 minutes) run
  through the keep-awake wrapper (scratchpad `run_awake.ps1`). Always the
  path spelling `C:\QQL\QuisquisLingo`. Never run two Flutter commands at once.
- The Bash tool mangles some inline heredocs (quotes/backslashes): put edit
  scripts in the scratchpad with the file tool and run them by path.
- A Dart `library;` directive must precede imports.
- Audit code count is pinned at 104 in
  `test/audit_branch_ownership_226_02_revision4_test.dart` line 212.
- Never `dart format` whole directories: 61 files predate Build 256
  unformatted. Format only the files `git status` lists; on 27 September
  at 07:00 a tree-wide run had to be undone with `git checkout --` on 53
  formatter-only files.
- Committing: stage with a pathspec that excludes `devtools_options.yaml`
  and `tools/cloud_setup.sh` (`git add -A -- . ':!devtools_options.yaml'
  ':!tools/cloud_setup.sh'`).
