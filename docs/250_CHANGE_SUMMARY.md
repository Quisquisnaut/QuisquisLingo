# Build 250 change summary

## Revision 1 — Courses layout

`2.0.50+250001`, dated 2026-09-24. The Course Manager tab is named **Course
Studio** in user-facing labels and Help, with internal class and key names
preserved. The three-dot Course actions menu stays at the right edge of each
row, including narrow layouts. Sort by and Show unavailable share one line;
the switch label is **Show unavailable**. The Search icon is available in both
tabs and opens a field below Sort. Each tab has its own adjacent Help icon;
New course remains on Course Studio only.

Other Local Courses has a neutral gray section border in both tabs, clearly
separate from red Audit errors, green ready and blue Draft/Unpublished Course
states. Each Course Studio three-dot Course menu includes **Course Info**.
Tapping the displayed cover or flag in either tab opens a popup showing that
image enlarged.

Favorites use a soft amber section accent and normal row text/background
colors. Course Studio has a Favorites section for Courses in the active
learner's Personal Library. It uses the existing learner-scoped Favorite flag,
the same Manager Course actions, shared sort and availability filter, and an
independent Expanded / Compact state. No favorite key or membership rule
changed. Course Model v11, package format 1, authoring rights, import,
progression, scoring and the Course Editor confirmation stay unchanged. Beta
expiry is `2026-10-24 23:59:59` local time. Exact verification is in
[250_VALIDATION.md](250_VALIDATION.md). Revision 1 is a source release; no
Windows package is created for this revision.

## Revision 0 — Courses screen and learner visibility

`2.0.50+250000`, Course Model v11. Plan:
[250_COURSES_SCREEN_PLAN.md](250_COURSES_SCREEN_PLAN.md). Validation results
are recorded in [250_VALIDATION.md](250_VALIDATION.md).

### One Courses screen

**Courses** has **ALL COURSES** and **COURSE MANAGER** tabs. Both use the same
Course row, four Course categories, and page-session Sort by and Show
unavailable controls; the latter starts on. Each section keeps its own
Expanded / Compact view. ALL COURSES adds title/language Search, a Favorites
shortcut section, Add / Remove membership, and Course Info, Favorite, Hide in
Learner and Reset progress actions. COURSE MANAGER keeps its rights-based
operations, Audit border, Team Manager, Shared Images and New course. Import
is available in both tabs; Help follows the selected tab. Unreadable-file
warnings appear on ALL COURSES.

The empty-library link reads **All Courses**. The learner Course Selector
links to each tab and keeps Course Manager and edit-current-Course visible but
greyed out while the profile is locked. Their explanation says to tap
**Version** in Settings ten times. The Selector lists Current, up to three
other Recent Courses, Favorites, and Other Courses, then All Courses, Course
Manager, Course Editor and Import. Recent and Favorites may repeat each
other; Current can also appear in Favorites or Other. The row menu is Course
Info, Review for the current Course, Favorite, Hide in Learner, and Remove
from my courses.

### Learner preferences

Favorite is a per-learner Course shortcut, including for Courses outside that
learner's Personal Library; it never changes membership. Hide in Learner
keeps membership and Course Manager access but removes the Course from the
learner Selector. Both tabs show hidden Courses with a **Hidden in Learner**
label and offer Unhide; the active Course cannot be hidden. ALL COURSES shows
the unavailable reason when a Course must first be added to the Personal
Library. The flags use learner-scoped `course_favorite_` and `course_hidden_`
keys, survive progress reset and travel in learner backup, and leave with
profile or full reset. Reusing the retired hidden key is a clean cut with no
legacy conversion, as decided while there were no released users.

### Import and received Custom Courses

Import stays available to locked profiles. Copy as New Course and Fork are
greyed out with the unlock reason in a matching-ID import; Replace / update
and Cancel retain their normal rules. Successful imports return the resulting
Course to the opening surface. Courses switches to ALL COURSES and highlights
it; the Selector returns Home with an imported-and-added notice and **Study
now** when playable, or a reason it cannot yet be studied. Copy and Fork no
longer open the Editor after import.

`CourseReceivedService` records a device-local flag for a Custom Course
received by import when no local profile has its authoring rights. A learner
who includes that Course in their Personal Library can update it from a file
with the same Course ID, Maintainer, assigned Team ID, Original Course Creator,
original creation time and Fork/Merge provenance, and a strictly newer Course
version expressed as a positive integer. The installed Team ID cannot change
through this update path. The exception is blocked if a local Maintainer or
assigned-Team member exists, and is checked again at the storage mutation.
The update runs the ordinary World Flag validation before backup and write.
Existing locally authored replacement rights, signed Publisher updates,
backups, progress and media recovery remain in place. The flag is cleared on
physical deletion or local authoring and appears in inventory and reset
handling.

### Help and preserved boundaries

Course Manager operations have their own English/Italian Help; Course Editor
Help keeps editing guidance. ALL COURSES Help explains Courses in learner
mode. Course Model v11, package format 1, Publisher signatures, scoring,
progression and the Course Editor's single confirmed save are unchanged.

### Known limits

* Received Custom Course updates have no signature. A crafted file can
  impersonate a friend's newer version through the user's own import; the
  exception is limited to flagged received Courses, membership, matching
  identities and a newer version, with the previous version backed up.
  Signed Custom Courses need a separate format and trust decision.
* Courses stored before this build are not inferred as received. The reused
  hidden key is not migrated from the retired Build 241 behavior.
* Copy and merge titles still avoid only titles in the active profile's
  Personal Library. Duplicate titles remain allowed.

Validation status, exact commands and outcomes belong in
[250_VALIDATION.md](250_VALIDATION.md).
