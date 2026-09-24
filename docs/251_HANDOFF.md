# Build 251 handoff

## Revision 0 source state

Build 251 Revision 0 is `2.0.51+251000`, dated 2026-09-24, on
`codex/build-251-architecture` from `main` after PR #15 (`942d8f5`).
`CoursesScreen` owns shared Sort, Search and Show unavailable controls and
hosts `AllCoursesTab` and `CourseStudioTab`. The embedded tab bodies retain
their data loading and Course actions. `CourseLibraryCategories` owns section
membership and labels, `CourseLibraryFilter` owns Search, unavailable and
sort selection, and `CourseLibrarySection` owns the five section presentations
and each section's Expanded/Compact state. The existing
`CourseLibraryPresentation` and `CourseLibraryRow` remain shared. The public
standalone screen constructors and existing widget keys remain available.

This is a source-only architectural extraction. Course Model v11, package
format 1, stored keys, membership, authoring rights, import, progression,
scoring, Audit and the Course Editor's top-level confirmation are unchanged.
Beta expiry is `2026-10-24 23:59:59` local time, recalculated for a
24 September release. No Windows package was built.

## Tested state

The pre-extraction baseline passed 26/26 affected tests; the new owner test
first failed against the old tree. A further test reproduced a Compact state
regression during reload and passed after correction. The settled focused run
passed 40/40.
Version metadata assertions also passed after their red/green cycle.
`flutter analyze --no-pub` found no issues. The bundled Course, image,
Lesson icon and media asset validators passed with 0 issues. An independent
read-only review found no actionable behavior difference. Exact commands and
counts are in [251_VALIDATION.md](251_VALIDATION.md). The complete Flutter
suite remains for the final Build 251 release gate after Revision 1.

## Known limits and next revision

The existing prompt for automatically found orphan MP3s can make a Course
working copy dirty; changing that interaction is outside this extraction.
Build 251 Revision 1 is the next step: characterize and extract the Course
Editor's immediately written per-device preferences and seven-day automatic
orphan MP3 schedule into one owner. Preserve its SettingsService keys and
values, due-date timing, dialogs and manual Audit path. Leave governance
lookups and duplicate-title reads in place. Update revision metadata, run the
complete Flutter suite with temporary Windows suspension protection, write
validation and handoff, and make a second local commit. Do not push, create a
PR, merge or build a Windows package without a later request.

The Revision 0 commit contains only the Course section extraction, focused
tests, Build 251 version metadata and tests, and this build's plan, change
summary, validation and handoff. The original checkout's pre-existing
`devtools_options.yaml` remains untouched.
