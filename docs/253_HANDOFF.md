# Build 253 handoff

## Revision 1: QQL Guide

Build 253 Revision 1 is `2.0.53+253001`, dated 2026-09-24. Settings places
**QQL Guide** immediately after Do Not Disturb. The Guide shows the existing
per-learner Locale selector and description as **Help Language**, followed by
the existing App Info link and description. App Settings no longer shows those
two entries directly. The Locale ID and storage key are unchanged, so Help,
Course Info, App Info and QQL Guide continue to observe the same preference.
Only an explicit selector change writes it; fallback reads leave it intact.

The Guide links to the standalone Help screens, ordered alphabetically by
their current title in the selected language. It includes distinct All
Courses Help and Course Library Help links, even though they share Help body
text. A central destination list resolves titles through the shared Help
catalog and opens the corresponding screens; adding a Help page or renaming a
localized title does not require maintaining three separate navigation lists.
The Audit Codes registry is included as an English-only destination by owner
choice. The existing Help page selectors and the technical reference pages
retain their own content and behavior. Inline Help and the rest of the app UI
remain outside localization scope.

No stored data, Course Model v11, package format 1, rights, scoring,
progression or beta-expiry change accompanies this revision. Its verification
record is in [253_VALIDATION.md](253_VALIDATION.md): 2469/2469 Flutter tests,
0 analyzer issues and a successful Windows Release build. Native UI automation
could not initialize on this host, so the interactive smoke test remains
pending.

## Revision 0 source state

Build 253 Revision 0 is `2.0.53+253000`, dated 2026-09-24. This source
release adds EN, IT and ES to the standalone Editor, Course Studio, Exercise,
All Courses/Course Library, Publisher signing, Device Administration and Debug
Help pages, their three technical reference pages, App Info and Course Info.
App Settings also has the shared Locale control. Inline Help dialogs and the
rest of the app interface remain English. The linked Audit Codes screen is an
English technical registry: its production rule definitions and search are
outside this slice. No Windows package is part of this release.

`LocaleService` owns one `EN`, `IT` or `ES` preference for the active learner.
App Settings, Help and Course Info use the same value, update mounted readers
when a selector changes it, and read it again after restart or a learner
switch. English is the default. A missing or empty translated leaf falls back
to its English leaf without changing the selected or stored Locale. Reads do
not write; only an explicit selector change stores a Locale. Each keyed value
is one fallback unit, so a body containing several paragraphs falls back as
one body.

`LocalizedText` is reusable for later app areas without migrating their UI
strings in this build. The first slice keeps shared stable keys and ordering
separate from one text-only file per language:
`lib/localization/help/help_en.dart`, `help_it.dart` and `help_es.dart`.
Existing Italian Editor Help and Course Info wording guided the Italian
catalog. Names of QQL commands, menu items, buttons, settings and modes
mentioned in Help and Course Info remain canonical English. Course content,
profile names and other user-provided values are displayed verbatim.

## Data and compatibility

Locale is a profile-scoped setting and follows the existing learner backup
and restore path. Progress, Course and media resets retain it; profile
deletion and full wipe remove it. An older backup without a Locale key yields
the English default under the existing replace-profile restore behavior.
Unsupported stored IDs also read as English without silently rewriting the
stored value. No backup schema or Course format migration is needed.

Course Model v11, package format 1, Course data, rights, signatures, scoring,
progression and the Course Editor confirmation remain unchanged. Beta expiry
remains `2026-10-24 23:59:59` local time.

## Validation and owner handoff

The tests exercise Settings ↔ Help ↔ Course Info synchronization, learner
switches and preference persistence, learner backup/restore, progress-reset
retention, leaf-level fallback without a storage write, EN/IT/ES catalog
parity, and canonical English QQL command names. Course and media reset tests
seed `IT` and check that Locale survives; the full-wipe test seeds `ES` and
checks that Locale is removed. Profile deletion follows the existing
profile-key namespace removal, reviewed in source without a new Locale-specific
deletion test. Focused and integrated results belong in
[253_VALIDATION.md](253_VALIDATION.md). Flutter analysis reported 0 issues,
all four asset validators passed, and the final serial Flutter suite passed
2467/2467.

A post-commit Windows debug build passed for `2.0.53+253000`, along with 21/21
focused Windows-host widget UI checks. The interactive native click-through is
still pending because the UI automation helpers failed to initialize. See the
post-commit note in [253_VALIDATION.md](253_VALIDATION.md).

A later clean Windows Release build and a same-path repeat build passed. Keep
the repository path spelling consistent between Flutter commands; the
recovery and evidence are in [253_VALIDATION.md](253_VALIDATION.md).

The owner's interactive smoke test remains pending. The remaining app UI and
inline Help are outside this slice. Future language or full-app work can reuse
the Locale owner and lookup with new catalogs after separate approval.
