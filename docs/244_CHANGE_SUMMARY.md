# Build 244 — change summary

Build 244 turns **Available on this device** into the **Course Library**.
Plan: [COURSE_LIBRARY_244_PLAN.md](COURSE_LIBRARY_244_PLAN.md).

## Revision 1 — shared Course Draft rule

Version **2.0.44+244001**. Beta expiry: **2026-10-21 23:59:59 local**, the
30-day policy applied to this release's own date, 21 September 2026.

Structural only; nothing visible changes. The authored-Draft rule
(unpublished Lesson, GuideBook or GuideBook content while GuideBook is on,
Round or Round content, Exercise) moves from `AuthoringHierarchyStatus` in
`course_editor_screen.dart` to `CourseDraftStatus` in
`lib/models/course_draft_status.dart`. `AuthoringHierarchyStatus` keeps its
API and delegates. The helper reads publication states only and never runs
the Course Audit, so the Course Library can evaluate every Course cheaply.

## Revision 2 — Course Library and availability switch

Version **2.0.44+244002**, same Beta expiry. Available on this device becomes **Course Library** in the page
title, its Help title and text, both Home entry points (Course Selector tile
and empty-library button), the removal dialog, and the English and Italian
Editor Help and Info content. The class name and the `available-on-device` key
stay.

A **Show unavailable or Draft Courses** switch sits at the top of the page, off
by default and kept only while the page is open. Off, it hides every Course
that is unpublished, requires Publisher verification, or contains authored
Draft content (`CourseDraftStatus.courseHasDraft`, computed once per load).
On, those Courses appear with their labels. The former single `Not published ·
Draft` label is now three independent labels: **Draft**, **Unpublished** and
**Verification required**. Membership, files, publication, verification,
authoring and Course Manager behaviour are unchanged.

## Revision 3 — Course Library sections

Version **2.0.44+244003**, same Beta expiry. The four categories are separate bordered sections (`_Band`: 2 px border
in the category colour, rounded corners, 20 px apart) with a tinted header.
Colours follow the existing title colours: on-surface for Bundled, purple for
Publisher, orange for My Local Courses and a darker orange for Other Local
Courses. My Custom Courses and Other Custom Courses are renamed My Local
Courses and Other Local Courses; Help explains that imported Custom Courses
from somebody else belong to Other Local Courses.

Headers show ` · N`, or ` · S shown · H hidden` while the availability switch
hides some. A section with Courses that are all hidden explains why and points
to the switch; an empty section still says `No courses in this section.`

Find Courses on the web is built as the first section with a full-width
button that opens the site externally (SnackBar on failure), but it renders
only when `courseWebSite` is set. The default `courseLibraryWebSite` is
`null`, so the section is hidden until the QQL Course web site exists.

## Revision 4 — Richer Course rows and covers

Version **2.0.44+244004**, same Beta expiry. Each row is a fixed artwork slot, the details column and the Add/Remove
action (trailing at 480 px and wider, below the details when narrower).

`CourseArtwork` (`lib/widgets/course_artwork.dart`) is a fixed square
(64 px here). A `coverImage` that matches `Course.coverImagePattern` is shown
through the existing `CourseMediaImage`, which reads the Course media file
into memory; the decode is bounded with `cacheWidth` = slot × device pixel
ratio, and the slot crops with `BoxFit.cover`. With no cover, a missing file or
bytes that do not decode, the slot shows `CourseFlagBadge` with the same
course-code fallback as Home. The slot size never changes, so rows stay
aligned. This is the first display of `coverImage`; the model comment is
updated.

The details are: title (colours unchanged), `source → target`, `Version:`
(Custom `courseVersion`; Bundled/Publisher `officialCourseVersion`; omitted
when empty), `Last edited:` (`modifiedAtUtc` in the app locale's short date,
or `Unknown` if it cannot be parsed), `Maintainer:`, `Duration:` (`1 hour` /
`N hours` from `estimatedStudyHours`, omitted when absent) and the status
labels. The values come from `CourseLibraryPresentation`
(`lib/services/course_library_presentation.dart`), which later sorting will
reuse. No pseudo-duration is calculated.

## Revision 5 — Sort by

Version **2.0.44+244005**, Beta expiry **2026-10-22 23:59:59 local**, the 30-day policy applied to this release's own date, 22 September 2026. A **Sort by** dropdown sits beside the availability switch (both wrap
on narrow screens). Options: Title (default, the former behaviour),
Language (target, then source), Maintainer (the displayed maintainer label),
Most recent (parsed `modifiedAtUtc`, newest first, unparsable last) and
Duration (`estimatedStudyHours`, shortest first, undeclared last). The
ordering is applied inside each section by
`CourseLibraryPresentation.sorted`; sections stay in their fixed order and a
Course never changes section. Every ordering ends with title, then courseId,
and all text uses one trimmed, case-insensitive comparison. The choice lasts
only while the page is open. The former one-time title sort in `_load` is
removed.

This release is dated 22 September 2026, so the Beta expiry moves to
**2026-10-22 23:59:59** local time under the 30-day policy
(`BetaLifecycleService.expiryDate`, lifecycle and first-run tests, README).
