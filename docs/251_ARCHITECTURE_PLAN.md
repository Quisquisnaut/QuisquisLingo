# Build 251 architecture plan

## Baseline and boundary

Start at `main` after PR #15 (`942d8f5`), in an isolated checkout. Build 251 is
source only. Each step is one revision and one local commit, with its own handoff
entry written before the commit. Course Model v11, package format 1, persisted
keys and values, rights, navigation, scoring, progression, and the Course
Editor's top-level confirmation remain unchanged.

## Revision 0 — shared Course sections

1. Characterize both embedded tabs: category membership, Favorites, section
   keys and counts, Search and unavailable filters, sort order, empty messages,
   Expanded/Compact state, colors, rows and actions. Run the affected tests on
   the original implementation.
2. Extract `CourseLibraryCategories` for the five headings and category rule,
   `CourseLibraryFilter` for selection/filter/sort/count, and one
   `CourseLibrarySection` for layout and Expanded/Compact controls. Keep the
   section flags in each tab state so a loading spinner or Retry does not reset
   them. Preserve All Courses' load-time Draft snapshot while Studio retains
   its on-build Draft check. Keep
   `CourseLibraryPresentation` and `CourseLibraryRow` as the existing shared
   components. The tab passes its Courses and row builder, including its own
   trailing actions. Preserve the public standalone screens and their keys;
   expose the embedded bodies as `AllCoursesTab` and `CourseStudioTab`.
3. Run affected widget and service tests, analyzer and validators. Update
   version metadata to `2.0.51+251000` and recalculate Beta expiry from the
   actual release date. Write change summary, validation and handoff; check
   the diff and commit only this revision's files.

## Revision 1 — Course Editor device state

1. Characterize existing SettingsService values and legacy fallback, immediate
   mode and notice writes, the seven-day per-Course-code MP3 orphan gate,
   initialization and mark timing, and the separate manual Audit path.
2. Add one testable `CourseEditorDeviceState` owner for these three preferences
   and automatic scheduling. Retain SettingsService's keys, values and clock
   behavior. Keep orphan dialogs and working-copy mutation in the screen via a
   callback. Leave governance and duplicate-title reads where they are.
3. Run focused tests, analyzer, all asset validators and the complete Flutter
   suite on the final tree. Hold a temporary Windows execution-state request
   in the supervising PowerShell process for the complete suite and clear it
   in `finally`. Update metadata to `2.0.51+251001`, refresh release docs,
   write validation and handoff, inspect the diff and commit only task files.

The interaction between an automatic orphan prompt and a dirty Course remains
for a later behavior revision. No Windows package, push, PR or merge is part of
this plan.
