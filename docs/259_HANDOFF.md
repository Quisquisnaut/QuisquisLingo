# Build 259 handoff

Plan: `docs/CONTEXT_AND_HINT_PLAN.md` (owner decisions of 29 September
2026, approved with "Let's go on with the Context and Hint Plan" on
30 September 2026). Branch `claude/259-instructions-and-hints`, from
`main` at `a3cbe3c` (Build 258 merged through PR #29).

Build 259 has three revisions, one per plan section:

- **Revision 0** (plan §4): an authored Instruction or context replaces
  the standard line; the prompt and question labels. *Committed as
  `474a313`; complete suite 3379 passed, 1 skipped, 0 failed.*
- **Revision 1** (plan §5): Complete the text and Put the sentences in
  order (instruction, hint, lines entered once). *Committed as
  `b6543a7` (`2.0.59+259001`); complete suite 3395 passed, 1 skipped,
  0 failed.*
- **Revision 2** (plan §6): the Listen and answer split. *Committed as
  `684d29e` (`2.0.59+259002`); complete suite 3415 passed, 1 skipped, 0 failed.*

## Revision 0 (committed `474a313`, 11:35, 30 September 2026)

Everything in `docs/259_CHANGE_SUMMARY.md` (Revision 0) is done:

- model, runtime, Duel;
- recipes, builder, Recognize characters, Audit;
- forms, field Help, Help EN/IT/ES;
- generators, Courses and fixtures, Laboratory baseline;
- the new test file and the test updates;
- version `2.0.59+259000` (expiry unchanged, `2026-10-30 23:59:59`);
- README, CHANGELOG, AGENTS, and `259_VALIDATION.md` (suite result
  pending).

`flutter analyze --no-pub`: no issues.

Gotchas found:
- `test/qql_229_revision3_test.dart` also pins `AppMetadata.build`.
- The v11 fixtures are not written by the generators: write them from
  `course_v11(laboratory())` / `build_course_v11()` and add
  `officialChecksum` (SHA-256 of the sorted, compact JSON without the
  checksum and signature keys).
- The Laboratory baseline rebuild: record with `QQL_RECORD_PRESENTATION`,
  render each record as a Dart literal (empty lists `<String>[]`, strings
  single-quoted with `\'`, `$` escaped), then `dart format`; unchanged
  records come out byte-identical.

## Revision 1 (committed `b6543a7`, 12:35, 30 September 2026)

Everything in `docs/259_CHANGE_SUMMARY.md` (Revision 1) is in the working
tree: recipes and builder (`_buildSentenceOrder`, `_withInstruction`,
`rebuild` borrowing the stored items), forms, field Help, Help EN/IT/ES,
Search, the Round's hint panels and Play audio rule, the demo content,
regenerated Courses and fixtures, the re-recorded Laboratory baseline
(4 records changed, all deliberate), the new test file
`test/complete_text_and_sentence_order_259_test.dart`, version
`2.0.59+259001`, README, CHANGELOG and AGENTS. `flutter analyze --no-pub`:
no issues. Complete suite 3395 passed, 1 skipped, 0 failed (12:25).

Gotcha: the keep-awake wrapper needs `[uint32]2147483648`, not
`[uint32]0x80000000` (PowerShell 5.1 reads the hex literal as a negative
Int32 and the cast fails).

## Revision 2 (committed `684d29e`, 13:10, 30 September 2026)

Everything in `docs/259_CHANGE_SUMMARY.md` (Revision 2) is in the working
tree: the two Listen and choose presets, Listen and answer's required
Question, forms, field Help, Help EN/IT/ES, Search, the Audit's listening
cases, the Round Wizard, the Story Wizard, the interoperability hints, the
demos (Laboratory 125 examples, Piedmontese 41 Lessons), the v11 fixtures,
the Laboratory baseline (1 new record, 2 deliberate changes), the new test
`test/listen_and_choose_259_test.dart`, the test pins (registry 46
presets, field Help tables, mascot and runtime tables, generator pools),
version `2.0.59+259002`, README, CHANGELOG and AGENTS. `flutter analyze
--no-pub`: no issues. Complete suite 3415 passed, 1 skipped, 0 failed
(13:08).

Note: the Piedmontese Lessons after the Listening group are renumbered
(`l22`… shift by two), because the demo's Lessons follow the registry
order; demo progress on those Lessons starts over.

## Revision 3 (committed `f64be87`, 16:50, 30 September 2026)

The owner's review points A–H (plan and answers in chat, 30 September
2026), in the working tree as `2.0.59+259003`: see
`docs/259_CHANGE_SUMMARY.md` (Revision 3). New test
`test/owner_review_259_revision3_test.dart`; Laboratory baseline 1 new and
10 deliberate records. `flutter analyze --no-pub`: no issues. Complete
suite 3435 passed, 1 skipped, 0 failed (16:44).

## Revision 4 (committed `a1d8f4f`, 20:30, 30 September 2026)

The owner's second review, points 1–10 (answers to three questions in chat),
in the working tree as `2.0.59+259004`: see `docs/259_CHANGE_SUMMARY.md`
(Revision 4). New test `test/owner_review_259_revision4_test.dart`;
Laboratory baseline 2 added, 4 removed, 5 deliberate changes. `flutter
analyze --no-pub`: no issues. Second complete suite 3445 passed, 1
skipped, 0 failed (20:22), after a converter fix found by the first.

## Revision 5 (committed `6621c51`, 23:20, 30 September 2026)

The owner's third review, points 1–5 (two answers in chat: the exported Edge
Case goes to `Import/Courses`; the Course stays in the repository as a
Course to import), in the working tree as `2.0.59+259005`: see
`docs/259_CHANGE_SUMMARY.md` (Revision 5). New tests
`test/owner_review_259_revision5_test.dart` and the import test in
`edge_case_course_254_test.dart`; new helper
`test/support/edge_case_fixture.dart`; Laboratory baseline: the ten Dialogue
lines re-recorded. `flutter analyze --no-pub`: no issues. The ZIP made by
the app's export is in `Documents/QuisquisLingo/Import/Courses` (not
committed). Complete suite 3451 passed, 1 skipped, 0 failed (23:12).

## Revision 6 (committed `e44d829`, 02:50, 1 October 2026)

QQL Demo: Piedmontese, the Piedmontese demo renamed, the Temporary Sample
Help question removed, in the working tree as `2.0.59+259006`: see
`docs/259_CHANGE_SUMMARY.md` (Revision 6). New generator
`tools/generate_piedmontese_mixed_259.py`, new test
`test/piedmontese_mixed_259_test.dart`. Open point for the owner: keep or
remove Course Info's "Temporary Sample" box. Complete suite 3455 passed,
1 skipped, 0 failed (02:42).

## Next

Build 259 is complete after Revision 6. The plan's separate findings C and
E are not in this build.

Stage with `git add -A -- . ':!devtools_options.yaml' ':!tools/cloud_setup.sh'`
after checking `git status` for files another session wrote.
