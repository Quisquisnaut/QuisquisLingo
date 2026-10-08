# Build 253 validation

## Revision 1: QQL Guide

Build 253 Revision 1 is `2.0.53+253001`, dated 2026-09-24
(Europe/Rome). The beta expiry remains `2026-10-24 23:59:59` local time.
The revision moves the Locale and App Info entries into QQL Guide after Do
Not Disturb and labels the shared selector **Help Language**. The Guide lists
the standalone Help destinations in alphabetic order by their localized
titles. Both All Courses Help and Course Library Help are separate links; the
Audit Codes registry remains English-only. Inline Help and the rest of the app
UI remain outside localization scope.

The focused Guide, Settings, Locale synchronization and version tests passed
**37/37**. The affected Help, App Info, Course Info and catalog tests passed
**45/45**. The new Guide test opens all 12 registered destinations and checks
EN/IT/ES title order, the English-only Audit Codes link and Locale storage.
`flutter analyze --no-pub` reported **0 issues** in 78.2 seconds. The final
serial `flutter test --no-pub --concurrency=1 --reporter expanded` passed
**2469/2469** in 24 minutes 9 seconds (exit code 0).

`flutter build windows --release --no-pub` from the consistently spelled
`C:\QQL\QuisquisLingo` path passed in 137.4 seconds. Both Windows executable
version fields report `2.0.53+253001`. The Windows computer-use helper failed
to initialize twice with `failed to write kernel assets` (OS error 3), so an
interactive native click-through could not be completed. Windows-host widget
tests covered the Guide, all destination routes and Locale changes; the
owner's native smoke test remains pending. Long test and build runs held a
temporary `ES_CONTINUOUS | ES_SYSTEM_REQUIRED` execution-state request in the
supervising PowerShell process and cleared it in `finally`. No full suite
rerun was needed after this documentation-only update.

The later Italian wording correction changed five Exercise primitives Help
strings from “primitivi” to “primitive”. The focused catalog, Editor Help and
Guide tests passed **16/16**. This Help text correction did not require another
complete suite run under the owner's documentation-only rerun guidance.

---

## Revision 0: scope and release state

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

## Windows Release build recovery

A later Release build reported C1083 for missing generated
`windows/flutter/ephemeral/cpp_client_wrapper` sources. The Debug build cache
recorded outputs under `C:\QQL\QuisquisLingo`, while the failed Release build
recorded the same directory under `C:\qql\QuisquisLingo`. Flutter's local
`trackSharedBuildDirectory` cleanup compares those output path strings case
sensitively and removed the just-generated files. The engine cache copies and
QQL source files were intact.

With no other build running, `flutter clean` and `flutter pub get` followed by
`flutter build windows --release --no-pub` from `C:\QQL\QuisquisLingo` passed
in 254.6 seconds. A second Release build from that same path passed without
cleaning in 26.5 seconds. The executable reports `2.0.53+253000`. This was a
generated build-cache issue; the documentation fix needs no test rerun.
