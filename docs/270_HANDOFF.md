# Build 270 handoff

Started 10 October 2026 after the read-only audit (`docs/270_AUDIT.md`), on
the branch `build-270` in the main checkout `C:\QQL\QuisquisLingo` (from
`main` at `7900f58b`, pushed). Git rule: one branch per Build; after each
revision's commit push the branch (`git push -u origin build-270`, standing
permission, a backup, no pull request); merge into `main` and push `main`
only on the owner's go. Summary: `docs/270_CHANGE_SUMMARY.md`; evidence:
`docs/270_VALIDATION.md`.

Never stage `devtools_options.yaml`, `tools/cloud_setup.sh`.

## Owner decisions (10 October 2026)

- Save the audit report as a file (done: `docs/270_AUDIT.md`) and fix in this
  order: (1) the learner-data store, (2) learner separation, (3) the Build 269
  audio hold and the DST XP bug, (4) the import side doors; then continue with
  the remaining findings by severity, one revision each, asking only where a
  design choice is needed.
- Diagnostic Log: its own file (chosen over "keep, write less").
- Threat model: "the app's security is just intended to avoid easy
  unauthorized access but do not intend to be hackerproof"; physical access
  defeats any hardening. So no required admin PIN, no PIN attempt limit, no
  lock-down of identity creation from backups or Recovery Keys. Fix only
  in-app paths that bypass a PIN that is set with ordinary taps.

## Plan

| Revision | Scope |
|---|---|
| 0 | Learner-data store (audit item 1) |
| 1 | Learner separation within the threat model: a restore never activates a PIN-protected learner without its PIN, "Replace existing" over another PIN-protected learner asks for that learner's PIN, switching learners ends the previous learner's unlocked session |
| 2 | Build 269 audio hold (Android speak future that never completes, MP3/aplay hangs; Play during a held line; stale line revealing the next; audio after leaving a Round) and the DST week-key XP bug |
| 3 | Import side doors: Course Backups read with the import gates (size, JsonLimits, media validators, no `..`), `assets/` allowlist, learner backup value types and size |
| 4+ | Remaining Medium findings, then Low (see the audit's tables) |

## Revision 0 (2.0.70+270000), learner data that survives a bad write

State: done. Code, tests and docs; version 2.0.70+270000 (Beta expiry
2026-11-09 23:59:59, unchanged: same release day). New tests 21 passed;
related files 131 passed; analyzer clean; Windows release build checked
against the owner's learner data (one instance, the Diagnostic Log moved,
the last good copy written, an emptied and a cut off file recovered with the
dialog alone, test files removed; the owner's earlier file is in the session
scratchpad `appdata_before_270`); complete suite 4,071 passed, 1 skipped
(03:18–03:52). Committed on `build-270` (hash in the next handoff update) and
the branch pushed.

Gotchas:
- Tests never install the store (they use `setMockInitialValues`); the store
  has its own file tests with real temp folders.
- `DiagnosticLogService` stays in preference mode until `initialise()`;
  tests do not call it, so their expectations on the preference hold.
- Logging a failed learner-data write to the Diagnostic Log while it is
  still a preference would loop; `LearnerDataNotices` checks
  `DiagnosticLogService.logFile` first.
- D: has about 2.6 GB free (test temp); C: about 25 GB.
