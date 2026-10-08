# Course Library (QQL Build 244) — plan

Status: **done** in Build 244 Revisions 1–7 (see [COURSE_LIBRARY_244_HANDOFF.md](COURSE_LIBRARY_244_HANDOFF.md)). Written 2026-09-21 against QQL Build 243 Revision 19
(`2.0.43+243019`, commit `9b9647c`).

Read `AGENTS.md` first. Its rules apply: smallest correct change, no unrelated
refactors, no commit or push without a request, focused tests during work and
analyzer plus the full suite once at the end.

**The rule for the whole build:** this is a presentation and read-model change.
The new switch, sort control and compact states filter or arrange what is
drawn. They never change Course membership, files on the device, publication
state, Publisher verification, authoring state, ownership or Course Manager
behavior.

No changes to: Course Model v11, the Course package format, membership
persistence, Publisher signatures, authoring authorization, learner progress,
Course import/export, publication semantics. No new preference keys (all new
state is page-session state), so `AppResetService`, `InventoryService` and
`docs/239_RESET_STORAGE_INVENTORY.md` are untouched.

---

## 1. What exists today

| Item | Where | Notes |
|---|---|---|
| The page | `lib/screens/available_courses_screen.dart` (357 lines) | One `ListView`, four sections by `_section()`, title-sorted, `ListTile` rows, `_BlockingStatusBadge`, `removeFromMyCourses` dialog. |
| Entry points | `home_screen.dart:1554` (Selector tile, key `available-on-device`), `home_screen.dart:2062` (empty-library button) | Both labelled "Available on this device". |
| Other mentions of the name | `available_courses_screen.dart:9,139,297`; `editor_help_content.dart:40` (EN) and `:229` (IT); `info_screen_content.dart:29` (EN) and `:129` (IT) | All need the new name. |
| Draft calculation | `AuthoringHierarchyStatus` in `course_editor_screen.dart:73-184` | `courseHasDraft` is the authoritative hierarchy rule (unpublished Lesson, Guidebook only while `useGuidebook`, Round, Round content, Exercise). **But `fromCourse` also runs a full `CourseAuditService().auditCourse`**, which is too expensive per row, and the class lives in a UI file. |
| Verification | `PublicationService.requiresPublisherVerification(course)` | Use as is. |
| Cover | `Course.coverImage` (`course_models.dart:867`), `media:<sha256>.<png|jpg|jpeg|webp>` | "Stored and validated only; the application does not display it yet." |
| Media rendering | `CourseMediaImage` (`lib/widgets/course_media_image.dart`) | Resolves `media:` through `CourseMediaStore.existingFile(courseId, …)`, reads bytes (≤50 KB), `Image.memory` with `cacheWidth/cacheHeight`, `missing:` fallback on missing file and on decode error. Exactly the bounded path needed. |
| Flag | `CourseFlagBadge(course:, fallbackCode:, width: 44, height: 31)` in `flag_art.dart:317` | Home uses `fallbackCode: CourseService.codeForCourse(course)`. |
| Version | `courseVersion` (Custom, positive integer string, may be empty) and `officialCourseVersion` (official, e.g. `1.7.0`) | |
| Last edited | `modifiedAtUtc` | Defaults to `officialReleaseDateUtc` for official Courses. |
| Duration | `estimatedStudyHours` (`int?`, 1–1000) | |
| External links | `url_launcher` already a dependency; pattern in `course_info_screen.dart:43` | |

---

## 2. Design decisions

### 2.1 Name

The page, its AppBar, its Help title, both Home entry points, the removal
dialog text and the EN/IT Editor Help and Info content all say **Course
Library**. The widget key `available-on-device` and the class name
`AvailableCoursesScreen` stay, so tests and navigation code do not churn.

### 2.2 Page layout — five stacked bands (four visible for now)

```text
Course Library                                        [?]

(Find Courses on the web band — built, hidden until the site exists)
[ ] Show unavailable or Draft Courses      Sort by: [Title ▼]

┌ Bundled Courses · 10 ────────────────────── [Compact] ┐
│ rows…                                                  │
└────────────────────────────────────────────────────────┘
┌ Publisher Courses · 2 shown · 1 hidden ──── [Compact] ┐
…
┌ My Local Courses · 4 ────────────────────── [Compact] ┐
…
┌ Other Local Courses · 7 ─────────────────── [Compact] ┐
…
```

* Each band is its own full-width container: rounded border, a lightly tinted
  surface and a header strip in the category's existing colour (black/white
  for Bundled, purple for Publisher, orange for both local bands), with clear
  vertical spacing between bands. Title colours inside rows stay as today.
* The switch and sort control sit between the web band and the category bands
  because they only affect the category bands. On narrow widths they wrap onto
  two lines.
* The web band is built but **not rendered** while
  `const Uri? courseLibraryWebSite = null;`. When the site exists, set that
  constant to its address and the band shows a `FilledButton.icon` (globe icon)
  that opens it with `launchUrl(…, mode: LaunchMode.externalApplication)`; a
  failed launch shows a SnackBar. Caption under the button: "Free and paid
  Courses from QuisquisLingo and publishers. Downloaded Courses are imported
  as QQL Course packages."

### 2.3 Availability filter

New pure helper, outside the Editor UI:

```dart
// lib/models/course_draft_status.dart
bool courseHasAuthoredDraft(Course course);   // same rule as today's courseHasDraft
bool lessonHasDraft(Course course, Lesson lesson);
…
```

`AuthoringHierarchyStatus` keeps its API and **delegates** its draft getters to
these functions, so there is one authoritative calculation and no audit is run
for the Course Library. This extraction is its own revision with no behaviour
change (AGENTS.md: separate structural refactors).

A Course is *unavailable or Draft* when any of:

* `!course.publicationState.isPublished`
* `PublicationService.requiresPublisherVerification(course)`
* `courseHasAuthoredDraft(course)`

Switch **Off** (default, page-session): such Courses are removed before the
bands are built. Switch **On**: shown with their badges.

Draft status is computed once per load (in `_load`), not per build.

### 2.4 Status badges

Today one badge says "Not published · Draft", which conflates two states. It
becomes three independent badges, same blue outlined style:

* **Draft** — `courseHasAuthoredDraft`
* **Unpublished** — `!publicationState.isPublished`
* **Verification required** — `requiresPublisherVerification`

Badges stay visible in compact rows.

### 2.5 Counts

Header text: `Bundled Courses · 10`. When the switch is Off and the band hides
anything: `Publisher Courses · 2 shown · 1 hidden`. With the switch On, hidden
is always 0 and only the total shows.

Empty band: "No Courses in this section." If everything in it is hidden:
"All N Courses here are unavailable or Draft. Turn on Show unavailable or
Draft Courses to see them."

### 2.6 Richer row

```text
[ artwork ]  Course title
 64 × 64     English → Italian
             Version: 4
             Last edited: 20 Sep 2026
             Maintainer: Alice
             Duration: 12 hours
             [Draft] [Unpublished] [Verification required]
                                             Add to my courses
```

A custom row widget replaces `ListTile` (ListTile's `leading` is limited in
height and does not suit a 64×64 slot plus seven lines).

* **Version:** Custom → `courseVersion`; Bundled/Publisher →
  `officialCourseVersion`. Empty after trim → line omitted. Shown verbatim;
  no unified `version` field.
* **Last edited:** `DateTime.tryParse(modifiedAtUtc)`; valid → `.toLocal()`
  formatted with `MaterialLocalizations.of(context).formatShortDate` (the
  app's locale, e.g. `Sep 20, 2026`; `formatMediumDate` has no year; no `intl`
  dependency is added). Invalid or empty → `Last
  edited: Unknown`.
* **Maintainer:** existing `_maintainer()` unchanged.
* **Duration:** `1 hour` / `N hours`; absent → omitted in both modes.
* **Action:** existing `_membershipButton()` unchanged; trailing at width ≥ 480,
  below the metadata when narrower (as today).

### 2.7 Artwork slot

New reusable widget `lib/widgets/course_artwork.dart`:

```dart
class CourseArtwork extends StatelessWidget {
  const CourseArtwork({required this.course, this.size = 64, this.mediaStore});
}
```

* Always a fixed `SizedBox(size, size)`, rounded clip.
* `coverImage` matches `Course.coverImagePattern` → `CourseMediaImage(courseId:
  course.courseId, asset: course.coverImage, fit: BoxFit.cover, cacheWidth /
  cacheHeight: (size × devicePixelRatio).round(), missing: <flag>)`.
* Otherwise, or on missing file / unreadable bytes / decode error →
  `CourseFlagBadge(course:, fallbackCode: CourseService.codeForCourse(course))`
  centred in the slot.
* While the cover bytes load, the slot is empty but keeps its size, so rows do
  not shift.

This is QQL's first display of `coverImage`; the model comment "the
application does not display it yet" is updated.

### 2.8 Sorting

`Sort by: Title | Language | Maintainer | Most recent | Duration`, default
Title, page-session. Applied inside each band; bands never reorder and a
Course never changes band.

| Sort | Keys |
|---|---|
| Title | title → courseId |
| Language | targetLanguage → sourceLanguage → title → courseId |
| Maintainer | maintainer label → title → courseId |
| Most recent | parsed `modifiedAtUtc` newest first, invalid last → title → courseId |
| Duration | `estimatedStudyHours` ascending, absent last → title → courseId |

All text keys use one helper, `compareCourseText(a, b)` (trim +
`toLowerCase()`, the policy the page already uses). Sorting is a pure function
`sortCoursesForLibrary(List<Course>, CourseLibrarySort, {maintainerOf})` so it
can be unit-tested without widgets.

### 2.9 Compact / expanded per band

Each band header has a toggle (icon button with tooltip "Compact" /
"Expanded"). Four independent page-session booleans, all Expanded by default.

Compact row: artwork (smaller slot, e.g. 40 × 40), title, language pair,
status badges, action. Version, Last edited, Maintainer and Duration disappear.

### 2.10 Add / Remove

Unchanged: `_add`, `_remove`, `removeFromMyCourses`, keys `add-course-<id>` and
`remove-course-<id>`. Hidden Courses can still be in the learner's library;
they are simply not drawn until the switch is On.

### 2.11 Help

Rewritten `availableCoursesHelp`, in this order: *Courses on this device*
(opening sentence: "Course Library shows all Courses installed or stored on
this QQL device, not only the Courses in your personal library."; friend-sends-
you-a-Course example; "a publisher may distribute or sell you a Course"),
*Categories* (no mention of the web site while its band is hidden), *Availability* (switch; showing does
not make a Course playable or verified; the three badges), *Sorting and
compact view*, *Personal library* (existing Add/Remove/reset text kept),
*Importing*, *Removing a Publisher Course from the device* (existing admin
text kept). No wording that implies QQL itself sells or licenses Courses.

EN and IT Editor Help and Info content: rename plus one short sentence about
the switch, sort and compact view.

---

## 3. Revisions

Each revision: focused tests, then analyzer and full suite at the end of the
build; handoff doc updated after every commit.

| Rev | Content | Main files |
|---|---|---|
| 244001 | **Structural only.** Extract draft predicates to `lib/models/course_draft_status.dart`; `AuthoringHierarchyStatus` delegates. No behaviour change. | `course_editor_screen.dart`, new model file |
| 244002 | Rename to Course Library everywhere (page, Help title, Home ×2, removal dialog, EN/IT help/info). Availability switch, filter, three badges. | `available_courses_screen.dart`, `home_screen.dart`, help/info content |
| 244003 | Web band (hidden while `courseLibraryWebSite` is null), separated category bands, header counts, empty/hidden messages. | `available_courses_screen.dart` |
| 244004 | Richer row, `CourseArtwork` (cover → flag), version/date/duration formatting. | new `course_artwork.dart`, screen, `course_models.dart` comment |
| 244005 | Sort control and pure sort function. | screen (+ small helper file if the screen grows too large) |
| 244006 | Compact/expanded per band. | screen |
| 244007 | Help rewrite, `AGENTS.md` release boundary, final full suite. | screen, `AGENTS.md` |

---

## 4. Tests

New `test/course_library_screen_test.dart` (widget) and
`test/course_library_sort_test.dart` (pure). Existing
`test/course_library_test.dart` finds "Available on this device" and must be
updated; any existing test that expects an unpublished Course row on this page
must first turn the switch on.

* Draft extraction: existing Editor/Course Manager draft-indicator tests pass
  unchanged; new unit tests for each hierarchy level including Guidebook
  ignored while `useGuidebook` is false.
* Default switch hides: unpublished; verification-required Publisher Course;
  Course with Draft authored content. Switch reveals each. Published, verified,
  draft-free Course visible either way.
* Counts: `N` and `N shown · M hidden`; all-hidden band message.
* The four categories stay correct (Bundled, Publisher, own Custom, other
  profile's/imported Custom).
* Sort Title, Language, Maintainer, Most recent (newest first, malformed last),
  Duration (absent last); ties by title then courseId; no Course changes band.
* Artwork: valid cover shown; absent cover → flag; missing media file → flag;
  corrupt bytes → flag; slot size identical in all three cases; decode bounded
  (`cacheWidth` set).
* Version: Custom `courseVersion`; official `officialCourseVersion`; empty →
  line absent. Last edited valid/Unknown. Duration singular/plural/absent.
* Compact/expanded independent per band; badges visible in compact rows.
* Narrow layout (e.g. 320 px) with all badges and long title: no overflow.
* Web band absent while `courseLibraryWebSite` is null (no "Find Courses
  on the web" text, no globe button).
* Help contains the friend/import example and the publisher distribute/sell
  wording.
* Add / Remove / reset confirmation unchanged (existing tests keep passing).

---

## 5. Owner decisions (2026-09-21)

1. **Web site:** no URL yet. The web band is **hidden entirely** (not a
   disabled button, not "Coming soon") behind one constant; no launcher call
   and no URL constant until the site exists. Help does not mention it.
2. **Band headings:** long form — Bundled Courses, Publisher Courses, My
   Local Courses, Other Local Courses.
3. **Date style:** the app locale's short date (`formatShortDate`, e.g.
   `Sep 20, 2026` in US English) is accepted.
4. **Duration sort:** shortest first, unknown last.
