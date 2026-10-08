# Build 249 handoff

## Revision 0 current state

Build 249 Revision 0 is `2.0.49+249000`, Course Model v11, on branch
`claude/249-library-operations` in the owner's checkout `C:\QQL\QuisquisLingo`,
from `main` `fbdb825` (`2.0.48+248003`). The Beta expiry recalculated from this
release's own date (23 September 2026) is `2026-10-23 23:59:59` local time. The
untracked `devtools_options.yaml` is the owner's and stays untouched.

Scope: step 2 of the roadmap's Course library screen track, one owner for
Course Manager's workflow. See
[249_LIBRARY_OPERATIONS_PLAN.md](249_LIBRARY_OPERATIONS_PLAN.md) and
[249_CHANGE_SUMMARY.md](249_CHANGE_SUMMARY.md).

`CourseLibraryOperations` (`lib/services/course_library_operations.dart`) owns
what used to sit inline in `CourseProjectsScreen`: loading the listed Courses
into a `CourseManagerLibrary` snapshot, which menu actions each Course offers
(`actionsFor`), copy and merge titles, a Fork's official source, merge
composition, import review (`CourseImportReview`), export notices, the Audit
entry, deleting, Publisher removal, building the New Course and the result
texts (`CourseLibraryReports`). The screen keeps layout, dialogs, file pickers
and navigation, and still calls `CoursePackageImport` for the chosen import
action. Behaviour is identical.

### What the characterization proved

`test/course_manager_workflow_249_test.dart` (18 tests through the real
screen over the real Course store and media folder, storage failures injected
by a `CourseFileStore` subclass) was run against unchanged code: **17 passed,
1 failed**, as the plan predicted. After the extraction the same 17 pass and
the same one fails in the same way. That one — a failed Delete is reported and
the Course stays listed — is skipped in Revision 0 and is Revision 2's proof.

`test/course_library_operations_249_test.dart` (28 tests) reaches every
operation without building a widget.

### Owner decisions taken on 2026-09-23

For **Build 249**:

* **Revision 1**: Course Manager menu entries that are unavailable are shown
  greyed out with a short reason line rather than hidden. Entries that can
  never apply to that kind of Course stay hidden.
* **Revision 2**: a failed Delete is reported and the Course stays listed.

For the **later two-tab Courses screen** (roadmap track steps 3–4, **not**
Build 249), all recorded in the roadmap:

* Both tabs use the same Course row (today's Course Library row; cover image
  or else flag). Only the COURSE MANAGER tab shows the red / green Audit
  border. Same four sections in both tabs.
* One screen-wide **Sort by** and one **Show unavailable** switch above the
  tabs, the switch **on** by default. "Hide" is reserved for Hide in Learner,
  so section counts read `· S of N shown`.
* ALL COURSES 3-dot menu: Course Info, Favorite / Remove from Favorites (any
  Course), Hide / Unhide in Learner and Reset course progress (the last two
  greyed out when the Course is not in the Personal Library). A Favorites
  section comes first, in inverted black and white; a Favorite also stays in
  its own section. Favorite is a new per-learner × Course stored key, to be
  confirmed with the owner.
* COURSE MANAGER's 3-dot menu also offers Hide / Unhide in Learner. There is
  no separate "Hidden courses (n)" button; a hidden row shows a Hidden in
  Learner label.
* Top bar: Import in both tabs; New course only in COURSE MANAGER; Search
  (magnifier) only in ALL COURSES. Team Manager and Shared Images only in
  COURSE MANAGER.
* The Course Selector gets two entries, All Courses and Course Manager, each
  opening the Courses screen on its tab. While Course Manager is locked for
  the profile, the Selector's Course Manager and edit-current-Course entries
  and the COURSE MANAGER tab are greyed out; using them explains that Course
  Manager must be unlocked for this profile and how (ten taps on Version in
  Settings). The unlock stays per user profile.
* Help split: Course types and operations move to a new Course Manager Help;
  editing stays in the Editor Help; the section assignment is confirmed.
* Import (roadmap step 3): Copy / Fork greyed out with the unlock reason for
  locked profiles in the matching-ID dialog (approved); **received** Custom
  Courses can be updated by any profile to a newer version from the same
  Maintainer, via a device-local "received" flag set at import, clean cut
  (approved, option D). Returning to where Import was opened and Study now
  are proposed, not yet decided.
* Course Selector (roadmap step 3): row menu Course Info, Review, Favorite,
  Hide in Learner, Remove from my courses (no Reset there). List order:
  Current, Recent (max 3), Favorites (no max), other library Courses, then
  the links All Courses, Course Manager, Course Editor, Import. Recent and
  Favorites may repeat each other. The current Course is never repeated in
  Recent (as today), but still appears in Favorites or Other.
* Still open for that build: Import and New course while locked, the
  unreadable-files warning's tab, the screen name "Courses" and the
  empty-library link.

### Known limits

* Copy and merge titles avoid only the listed titles (the active profile's
  personal library), not every Course on the device. Duplicate titles are
  allowed, so this is recorded rather than changed.
* `CourseProjectsScreen._openUser` opens the Editor with a default
  `CourseEditorService` rather than the injected one. Unchanged.
* The inert `CourseEditorScreen.transferService` remains; Build 249 does not
  touch that file.
* Course Manager widget tests time out in parallel; run them with
  `--concurrency=1`.

### Validation

Analyzer clean, four validators pass, complete suite **2,353 passed,
1 skipped, 0 failed** at `--concurrency=1` in 29 min 19 s, `git diff --check`
clean. Two source-text tests that searched the screen for code now in the owner
were rewritten as behaviour tests. Details in
[249_VALIDATION.md](249_VALIDATION.md).

### Next step

Revision 1 (greyed-out menu entries with reasons), then Revision 2 (report a
failed Delete), each with its own version, validation, handoff and commit, in
this same task. Push, PR and merge follow the owner's direction.

---

# Revision 1 current state

Build 249 Revision 1 is `2.0.49+249001`, Course Model v11, on branch
`claude/249-library-operations`, following Revision 0 commit `df9be0b`. Beta
expiry remains `2026-10-23 23:59:59` local time. The untracked
`devtools_options.yaml` is the owner's and stays untouched.

An owner-requested behaviour change: Course Manager menu entries that depend
on rights, license, Publisher verification or admin status are shown greyed
out with a one-line reason instead of being hidden; entries that can never
apply to that kind of Course stay hidden. `CourseManagerLibrary.entriesFor`
owns the rule and the reasons; `actionsFor` still returns only usable actions.
`CourseAccessPolicy` is untouched. See
[249_CHANGE_SUMMARY.md](249_CHANGE_SUMMARY.md) for the reason table.

Three changed menu expectations failed on Revision 0's code first, then
passed. One older assertion (Fork absent on a forbidding official Course) was
updated on purpose to "greyed out with its reason".

## Validation

Analyzer clean, complete suite **2,360 passed, 1 skipped, 0 failed** at
`--concurrency=1` in 25 min 9 s, `git diff --check` clean. See
[249_VALIDATION.md](249_VALIDATION.md).

## Known limits

* The reasons are English only, like the rest of Course Manager.
* The two-tab screen will reuse this rule; its own menus (ALL COURSES, the
  Course Selector) are not built yet.

## Next step

Revision 2: report a failed Delete and keep the Course listed; unskip the
characterization test that proves it. Done; see below.

---

# Revision 2 current state — Build 249 complete

Build 249 Revision 2 is `2.0.49+249002`, Course Model v11, on branch
`claude/249-library-operations`, following Revision 1 commit `50f860e`
(Revision 0 is `df9be0b`). Beta expiry remains `2026-10-23 23:59:59` local
time. The untracked `devtools_options.yaml` is the owner's and stays
untouched.

A failed Course deletion is now reported: "Could not delete “Title”: reason",
and the list reloads to show what storage holds. The characterization test
that proved the silent failure, skipped since Revision 0, is unskipped and
passes. `CourseLibraryReports.deleteFailed` owns the text.

## Validation

Analyzer clean, complete suite **2,361 passed, 0 skipped, 0 failed** at
`--concurrency=1` in 24 min 3 s, `git diff --check` clean. See
[249_VALIDATION.md](249_VALIDATION.md).

## Known limits after Build 249

* Copy and merge titles avoid only the active profile's personal-library
  titles, not every Course on the device (recorded, unchanged).
* `CourseProjectsScreen._openUser` opens the Editor with a default
  `CourseEditorService` rather than the injected one (unchanged).
* The inert `CourseEditorScreen.transferService` remains; no Build 249
  revision touched that file.
* Course Manager widget tests time out in parallel; run them with
  `--concurrency=1`.
* Manual smoke testing and a platform release artifact are outside this
  source build.

## Smoke tests worth doing by hand

* Course Manager on another profile's Custom Course: Copy, Merge, Export and
  Delete are greyed with their reasons; Fork follows the license.
* An official Course: Fork greyed when the license forbids it; no Copy, Merge
  or Delete entries.
* A non-admin on a Publisher Course: Remove Publisher Course from device is
  greyed with its reason.

## Next boundary

Build 249 is complete: three local commits, unpushed. Push, pull request and
merge follow the owner's direction.

The next build is the **two-tab Courses screen** (roadmap track steps 3 and
4), in a **new task** from the then-current `main`. Read `AGENTS.md`,
`pubspec.yaml`, the roadmap's "Step 3 — One screen, two tabs" and "Step 4"
sections and this handoff first. Every design decision taken on 2026-09-23 is
recorded there. Still open for that build: Import and New course while
locked, which tab shows the unreadable-files warning, the screen name
"Courses", the empty-library link, and the proposed return-after-import and
Study now behaviour. The Favorite and "received" flags are new stored keys and
need the owner's confirmation of their exact keys before implementation.
