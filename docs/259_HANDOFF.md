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
- **Revision 2** (plan §6): the Listen and answer split.

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

## Next

1. Revision 2 (plan §6): the Listen and answer split.

Stage with `git add -A -- . ':!devtools_options.yaml' ':!tools/cloud_setup.sh'`
after checking `git status` for files another session wrote.
