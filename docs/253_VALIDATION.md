# Build 253 validation

## Scope and release state

Build 253 Revision 0 is `2.0.53+253000`, dated 2026-09-24
(Europe/Rome). It is a source release without a Windows package. Beta expiry
remains `2026-10-24 23:59:59` local time.

This first slice covers the standalone Help pages, App Info, Course Info and
the App Settings Locale selector in EN, IT and ES. All other app UI and inline
Help remain outside the localization scope. The linked Audit Codes screen
also remains an English technical registry; its rule definitions and search
are not translated. The catalog is split into one text-only file per language,
with shared semantic keys, ordering and lookup.
Each keyed value falls back separately to English. A body key can contain
several paragraphs, which then fall back together; separately keyed titles,
labels and table cells retain their selected-language text. Fallback and reads
do not write Locale.

## Contract checks

| Requirement | Verification target | Status |
| --- | --- | --- |
| Settings ↔ Help ↔ Course Info | A selector change updates other mounted surfaces for the active learner | Focused test passed |
| Persistence and learner isolation | EN/IT/ES survive restart and each learner retains a separate choice | Focused test passed |
| Fallback without mutation | A missing IT/ES leaf uses English while the stored Locale stays unchanged | Focused tests passed |
| Catalog parity | Shipped EN, IT and ES have identical stable key sets and nonempty text | Focused test passed |
| Canonical QQL names | Help and Course Info keep English command, menu, button, setting and mode names | Focused tests passed, including Exercise category and current menu labels |
| Backup and older backup | Export/import carries Locale; an older backup without it defaults to EN | Focused test passed |
| Progress reset | A learner progress reset keeps a seeded `ES` Locale | Focused test passed |
| Other reset scope | Course/media resets retain a seeded admin Locale; full wipe removes a seeded Locale | Focused tests passed; profile deletion follows reviewed namespace removal |
| Existing behavior | Help navigation and search, Course Info actions, Course Library routes and settings retain their prior behavior | Focused tests and full serial suite passed |

## Release gate

The final Flutter analyzer reported **0 issues** in 68.1 seconds. All four bundled
asset validators exited 0:

| Command | Result |
| --- | --- |
| `python tools/validate_courses.py` | 10 bundled Course Model v11 files |
| `python tools/validate_images.py` | 111 assets, 0 issues |
| `python tools/validate_lesson_icons.py` | 14 assets, 0 issues |
| `python tools/validate_media_assets.py` | 443 media files, 0 issues |

The focused Locale, catalog and reset run passed **33/33**. After the
Course Library Help title was localized, the focused Course Library,
catalog and Courses screen run passed **14/14**. The isolated
leaderboard navigation test passed after a 10-second filesystem UI wait timed
out under a parallel full-suite run. Two tests added while that same process
was running used pre-edit production snapshots; both pass in the fresh focused
run. The first complete serial run then passed **2466** tests and failed one
existing zero-user startup test: it advanced a fixed 600 ms of test time
before the logo image had finished loading, while production deliberately
waits for that image. The separate image-ready test already checks exact
animation frames. The first-run test now waits for the startup gate to finish;
the startup file passed **6/6** after this test-only correction. The final
serial full suite passed **2467/2467** in 38 minutes 6 seconds, with exit code
0. `git diff --check` also exited 0. For a long Windows
test run, the supervising PowerShell process requests
`ES_CONTINUOUS | ES_SYSTEM_REQUIRED` through `SetThreadExecutionState` and
clears it in `finally`; it does not change persistent power settings.

The updated full-wipe test seeds `ES` and verifies that all preferences are
removed. Non-everything reset tests seed `IT` and verify it survives each
scope. Profile deletion's prefix removal was reviewed in source; no new
Locale-specific deletion test was added.

## Post-commit Windows check

Editor Help's EN, IT and ES Audit Codes text no longer states the stale
102-rule count; the current registry has 104 rules. The focused catalog test
passed **4/4**. After an initial incremental Windows build found missing
generated Flutter C++ wrapper files, `flutter clean` regenerated them and
`flutter build windows --debug` passed in 181.0 seconds. The debug executable
reports `2.0.53+253000` in both Windows version fields.

The focused Windows-host widget UI run passed **21/21** across Settings, Help,
Course Info, Locale persistence and the EN/IT/ES selectors. An interactive
native click-through is still pending: both available UI automation helpers
failed before initialization with `failed to write kernel assets` (OS error 3).
The host account also contains existing QQL learner data, so no app session
was opened against that data. No full suite rerun was needed for these text and
documentation corrections.

The owner's interactive smoke test is still pending.
