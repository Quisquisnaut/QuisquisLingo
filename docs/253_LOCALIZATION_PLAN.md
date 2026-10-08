# Build 253 localization first slice

## Boundary

Start from `2.0.52+252000` in the current repository. This source release adds
EN, IT and ES only to standalone Help screens, the shared All Courses/Course
Library Help view, App Info, Course Info, and the Locale control in App Settings.
Standalone Help includes Editor, Course Studio, Exercise Help, the three
technical reference pages, Publisher signing, Device Administration and Debug.
The linked Audit Codes screen remains an English technical registry: its 104
production rule definitions and search belong to a separately approved
localization slice. Inline Help dialogs and the rest of the app interface
remain English. Course content and other author-provided values are shown
verbatim.

## Locale owner and fallback

- `LocaleService` is the single owner of the active learner's Locale. Store
  `EN`, `IT` or `ES` as `learner_<profile-id>_locale`, using
  `ProfileService.keyForProfileId`. With no active learner, no key, or an
  unsupported stored value, the effective Locale is EN. Reading never writes.
- A change in App Settings, Help or Course Info writes the same preference and
  notifies mounted readers. Switching learner reloads that learner's value.
  Only a deliberate selector change writes through `LocaleService`; learner
  backup restore follows its existing whole-profile restore behavior.
- `LocalizedText` resolves each stable leaf key separately: requested-language
  nonempty value, then English. A missing ES body therefore falls back to the
  English body without changing its ES title or the stored `ES` preference.
  A body key may contain several paragraphs; in that case the whole body is
  one fallback unit. Separately keyed labels and table cells fall back on
  their own. English is the required source catalog; an unknown English key is
  a defect.
  Dynamic values are inserted after lookup, never translated as data.
- Shipped EN, IT and ES catalogs must have the same key set. A deliberately
  partial injected test catalog exercises the fallback path. Locale IDs in all
  selectors are exactly EN, IT and ES.

## Text mapping

`lib/localization/help/help_en.dart`, `help_it.dart` and `help_es.dart` each
contain a text-only map using the same semantic keys. Shared ordering and
lookup logic live outside those files. Existing parallel English/Italian
sections in `editor_help_content.dart` move to stable
`editorHelp.<topic>.title/body` keys. Editor Help and Course Studio Help keep
their separate ordered topic lists, including Course Studio's finding and
operations topics; selection no longer depends on English titles or list
positions. The existing App Info pairs move to `appInfo.<topic>.title/body`.
The Course types card uses leaf keys for its title, intro, each type, table
cell, note and contact. Exercise Help keys use stable preset IDs and
`<preset-id>/<field-id>` for field details, without changing the shared
Exercise Editor registries. The remaining Help pages use section IDs with
title/body leaves. Course Info uses leaf keys for each card title, displayed
metadata label, explanatory sentence, action result and provenance label;
its Italian wording follows the existing Course Info sections of Editor Help.

Names of QQL commands, menu items, buttons, settings and modes mentioned in
translated prose stay in canonical English, as do technical identifiers,
code and user-entered Course metadata. Future UI localization can register
additional catalogs with the same Locale owner and lookup without migrating
other UI strings in this build.

## Backup and reset

The profile-scoped key is automatically included in learner backup and
restored with the profile. An older backup with no Locale key restores the
default EN state under the existing replace-profile semantics. Progress,
Course and media resets keep Locale; profile deletion and full device wipe
remove it. Invalid stored values stay untouched until an explicit selector
change. No backup schema or Course format change is needed.

## Verification and handoff

Write focused tests before implementation for per-profile persistence and
restart, mounted Settings ↔ Help ↔ Course Info synchronization, fallback
without state mutation, EN/IT/ES key parity, and preserved English command
names. Retain existing Help and Course Info behavior checks. Run focused tests,
Flutter analysis and the affected suite, then the full suite if practical.
For long Windows runs, the supervising PowerShell process requests
`ES_CONTINUOUS | ES_SYSTEM_REQUIRED` and clears it in `finally`. Bump to
`2.0.53+253000`, update `AGENTS.md`, validation and handoff, make one
task-scoped local commit, then await the owner's smoke test.
