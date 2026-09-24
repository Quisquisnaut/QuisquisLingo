# Build 251 handoff

## Revision 1 source state

Build 251 Revision 1 is `2.0.51+251001`, dated 2026-09-24, on
`codex/build-251-architecture`. It follows the Revision 0 local commit
`927dccb` and remains based on `main` after PR #15 (`942d8f5`).
`CourseEditorDeviceState` owns the Course Editor's immediately persisted
access mode and one-time View-only notice, plus the seven-day automatic
orphan MP3 check by Course code. It delegates persistence to the existing
`SettingsService`, preserving the keys, values and legacy fallback. The
screen still shows the dialogs and runs manual Audit; its governance lookups,
duplicate-title reads and Course working-copy transaction remain in place.

The automatic check still runs after the opening frame only with
`canEditOriginal` and Edit mode. Its date is written after the check returns,
including when the user keeps the files or none are found. Mode and notice
preferences still write immediately, outside Course confirmation. Course
Model v11, package format 1, rights, import, progression and scoring are
unchanged. Beta expiry is `2026-10-24 23:59:59` local time, recalculated for
this revision's 24 September release.

The existing interaction between an automatic orphan prompt and a Course
working copy becoming dirty belongs to a later revision. No behavioral
change to that interaction was made here. See
[251_VALIDATION.md](251_VALIDATION.md) for the characterization and final
release-gate results. This task does not push, open a PR, merge or create a
Windows package. The original main checkout's pre-existing
`devtools_options.yaml` remains untouched.

## Revision 1 tested state

The pre-extraction characterization passed 15/15, the new owner contract
failed before implementation and then passed, and the settled focused run
passed 18/18. The full Flutter suite passed **2,430/2,430** with exit code 0;
the supervising PowerShell process held the requested Windows execution
state for the run and cleared it in `finally`. `flutter analyze --no-pub`
found no issues. The bundled Course, image, Lesson icon and media validators
all passed with zero issues. An independent read-only review found no
concrete behavior difference in the extracted Editor state. Commands and
counts are in [251_VALIDATION.md](251_VALIDATION.md).

## Revision 0 source state

Build 251 Revision 0 is `2.0.51+251000`, dated 2026-09-24, on
`codex/build-251-architecture` from `main` after PR #15 (`942d8f5`).
`CoursesScreen` owns shared Sort, Search and Show unavailable controls and
hosts `AllCoursesTab` and `CourseStudioTab`. The embedded tab bodies retain
their data loading and Course actions. `CourseLibraryCategories` owns section
membership and labels, `CourseLibraryFilter` owns Search, unavailable and
sort selection, and `CourseLibrarySection` owns the five section presentations.
The tab screen states retain each section's Expanded/Compact flag. The existing
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
suite was deferred to the Revision 1 release gate recorded above.

## Revision 0 carry-forward

The existing prompt for automatically found orphan MP3s can make a Course
working copy dirty; changing that interaction is outside both architectural
revisions. The device-state extraction scheduled at this handoff was
completed in Revision 1 above.

The Revision 0 commit contains only the Course section extraction, focused
tests, Build 251 version metadata and tests, and this build's plan, change
summary, validation and handoff. The original checkout's pre-existing
`devtools_options.yaml` remains untouched.
