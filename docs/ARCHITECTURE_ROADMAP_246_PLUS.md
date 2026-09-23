# QQL architecture roadmap after Build 245

Status: **approved by the owner for staged implementation on 2026-09-22.**
The first three scopes are **delivered and merged**; the rest are **paused**
while other feature work takes priority, and are resumed from wherever `main`
stands at that time.

| Delivered | Build | What it established |
| --- | --- | --- |
| ✅ | 246 | One Merge workflow owns copied media, Course confirmation and cleanup. |
| ✅ | 247 | One import attempt owns a Course package from reading until the attempt ends. |
| ✅ | 248 | One authoring media-lifetime owner; plus owner-requested Course Editor layout work and the removal of export/copy from the Editor. |

**Build numbers are no longer reserved.** The earlier slots 249–253 are
withdrawn: the remaining work is a numbered list of **steps**, and each step
takes whatever build number is current when it is actually started. Steps stay
in this order because each depends on the boundaries the earlier ones settled,
but nothing reserves a number in advance, and unrelated feature builds may take
any number in between.

Read `pubspec.yaml`, `AGENTS.md` and the latest handoff again at the start of
every step. Derive the package version and the 30-day Beta expiry from the live
release state and the actual release date at execution time.

## Purpose and boundaries

Build 245 established one Course authoring session, typed hierarchy updates,
and per-Course storage commands. The following builds address other owners.
Each change must put a rule, state transition, or media lifetime under one
defined contract. Moving an unchanged screen class to another file does not
complete a step. Preserve Course Model v11, stored data and keys, authoring
rights, scoring, progression, package/signature compatibility, and the single
top-level confirmed Course save unless a later approved plan explicitly
changes one of them.

Start each step from the then-current merged `main`; do not implement the
remaining roadmap at once. Every build starts at Revision 0. Add Revision 1 or
later only for a separately reviewable correction or follow-up proven necessary
by that build's own tests — Build 248 shows what happens otherwise: its
Revisions 1 and 2 were owner-requested scope extensions rather than
corrections, and had to be recorded as such so the history explained itself.

## Remaining steps

| Step | Session | Owner to establish | First proof and boundary |
| --- | --- | --- | --- |
| **1** | **Exercise Authoring** | A pure draft builder owns Exercise candidate construction and typed field errors. | Compare v11 JSON, stable IDs, Draft versus Published rules, image provenance, Preview, Save, and Cancel across templates. Keep controllers and dialogs in the screen. |
| **2** | **Round Attempt** | A pure attempt owner controls answer, first-pass error, review-queue, and finish transitions. | Preserve flashcard requeue, first-pass XP facts, Preview/view-only no-write, audio filtering, and completion failure timing. `LearningCompletionService` keeps persistence and awards. |
| **3** | **Home/Learner session** | One generation-guarded snapshot owns learner and Course loading/switching. | Preserve empty-library and saved-Course fallback, locks, profile-scoped progress, and both visible and persisted selection when a slow switch loses to a newer one. Keep scrolling, animation, and dialogs in Home. |
| **4** | **Audit Ownership** | A typed projection owns Course/Lesson/Round/Exercise/GuideBook concern status; widgets only render it. | Preserve codes, severity thresholds, issue order/location, GuideBook-off neutrality, scoped results, report content, and navigation. Characterize Audit media-use coverage before any behavior correction. |
| **5** | **Model Policy**, only after contract approval | App-build compatibility policy moves to an application boundary while Course v11 values and codecs remain canonical. | Map every load/import route and exact errors before changing the `Course` constructor's build check. Do not run this step solely to shorten `course_models.dart`. |

Each step is its own session because each has a different failure boundary and
review contract. Revisions within one build may stay in that build's session,
but each revision still ends with its own version, validation, handoff and
commit. **Merge one step before starting the next**, so ownership changes never
compete across branches.

## Scope for the remaining steps

### Step 1 — Exercise Authoring

`ExerciseEditorScreen._buildCandidate` currently combines UI feedback with
template rules and v11 model construction. Give those rules one pure
input/output contract: draft field values in, candidate or typed field
errors out. The widget retains interaction state, navigation, and feedback;
`CourseAuthoringSession` retains the final Course update. Do not create
another mutable Course copy or publication authority.

### Step 2 — Round Attempt

`RoundScreen` still owns queue and review transitions alongside audio and
rendering. Move only the pure attempt transitions. Completion service reads
attempt facts at multiple await points today; characterize that timing
before passing snapshots across the boundary. Preserve the established
Round/Review/Topic/Duel XP rules and no-write preview modes.

### Step 3 — Learner Session

`HomeScreen._reload` and Course switches use generation tokens to prevent
stale async results from replacing a newer selection. A new session owner
must publish one coherent learner/Course snapshot and guard both displayed
and persisted selection. Keep profile administration, PIN prompts, learner
path painting, and scroll synchronization in the UI.

### Step 4 — Audit Ownership

`CourseAuditScreen` already delegates numbering/sort/filter to
`CourseAuditResult` and report copy/export to
`CourseAuditReportService`. Moving that screen alone would be a physical
split and is **not** a roadmap step. The genuine seam is
`AuthoringHierarchyStatus`, which derives branch concern status from Audit
issues in the screen source. Keep `CourseAuditService` and the code registry
as the public Audit authorities. Separately test whether its own media-use
walk misses cover, GuideBook, presentation, or layout images; if correction
is needed, use a separate revision rather than hiding a behavior change
inside the projection extraction. If it blocks extraction, correct it first
and update the proposed revision order. Grouping internal Audit rules is a later
candidate only if it yields independently testable rule contracts.

### Step 5 — Model Policy, contract approval first

`Course` currently reads `AppMetadata.buildNumber` while validating
`minimumAppBuild`. Moving that gate can change which stored/imported
Courses are accepted, so this slot needs a route-by-route compatibility
decision before implementation. The small dependency from
`CourseFileStore` to `CourseBackupService.sanitizedCourseId` should be
handled with future storage/path work, preserving exact names and collision
rules; it does not justify its own build now.

## Every implementation revision ends the same way

1. Read current `AGENTS.md`, `pubspec.yaml`, the relevant detailed plan,
   and the previous handoff. Use the current tree as the baseline. Start a
   clean, isolated checkout; leave unrelated files such as the existing
   untracked `devtools_options.yaml` alone.
2. Write a behavioral characterization or failure test at the actual
   boundary. Record what fails before changing code. Keep deliberate behavior
   corrections separate from structural extraction when practical.
3. Implement one owner and keep public routes/facades compatible. Verify
   affected tests, relevant integration routes and failure recovery,
   `flutter analyze`, validators, and a full suite at the release gate.
   Replace source-location tests with behavior tests before moving a class
   they pin to a file.
4. Bump the build/revision in `pubspec.yaml`, AppMetadata, and version tests;
   recalculate the 30-day Beta expiry from the actual release date. Update
   AGENTS, README, CHANGELOG, and that build's change summary and validation.
5. **Write the handoff before committing.** It must state the tested state,
   known limits, exact next step, current version, and files/commit context.
   Run `git diff --check`, stage only intended files, and make **one local
   commit for that revision**. Do not begin the next revision until this
   handoff and commit exist. Push, PR, and merge follow the user's direction.

## Second track: one Course library screen

Approved in discussion on 2026-09-23. Independent of the paused architecture
steps above and orderable against them freely, but **internally ordered**: each
step makes the next smaller.

**Target.** One screen with two tabs. **ALL COURSES** lists every Course on the
device and offers Add / Remove to the Personal Library, for learning or for
editing. **COURSE MANAGER** offers operations on the Courses in that Personal
Library. Personal Library membership also decides what appears in the learner
Course Selector.

That last rule is **not new**: `CourseLibraryService` (`contains`/`add`/
`remove`) already drives all three surfaces, and `AGENTS.md` already states
that Add/Remove controls both Selector and Manager. The two tabs make an
existing invisible rule visible, so there is no migration and no new key.

The merge also fixes a real dead end: today, removing a Course from the
Personal Library makes it vanish from Course Manager, and it can only be
recovered from a different screen. With ALL COURSES one tab away, it cannot.

| Step | What | Note |
| --- | --- | --- |
| ✅ **1** | Course Editor working-copy boundary rule in `AGENTS.md` | Done 2026-09-23. |
| ~~2~~ | ~~Remove the Editor's `listUserCourses` duplicate-title check~~ | **Withdrawn.** It is a read that powers a duplicate-name warning while typing, not a library operation, and the sharpened rule explicitly allows it. Removing it would lose the warning or defer the clash to confirm time. |
| **2** | **Course library operations owner** | The real build. See below. |
| **3** | Merge into one screen, two tabs, capability-driven | Small once 2 is done; reuse the Build 229 "unified surface is capability-driven" pattern. |
| **4** | Hide / Unhide, per learner × Course | Clutter control. See below. |
| **5** | Editor device-state owner | Independent of this track; see below. |

### Step 2 — Course library operations owner

Course Library is already presentation over `CourseLibraryService` and
`CourseLibraryPresentation`, which is why it is 662 lines. Course Manager is
2,677 lines with its operations inline.

The **storage** operations already have owners: `CoursePackageImport`
(Build 247), `confirmMergedCourse` (Build 246), and `createFork`,
`createCopyAsNewCourse`, `deleteUserCourse` on `CourseEditorService`. What is
unowned is the **workflow around them** — copy-title generation, confirmation
dialogs, result reporting, reload, and which action is offered for which
Course. That is the extraction; it is smaller than the line count suggests.

**Do this before the merge.** Merging first produces a ~3,300-line screen with
half its logic unowned, which is exactly how `course_editor_screen.dart`
reached 10,659 lines: screens absorbed each other faster than their rules got
owners.

**Proof:** every operation reachable in a test without the screen; the screen
reduced to presentation and confirmation.

### Step 4 — Hide / Unhide

Considered and rejected: splitting membership into "studying" and "authoring".
A maintainer's normal loop is edit, then check the result in the learner view,
so a second intent flag would have to be added and removed constantly. Hide
keeps one membership concept and makes unhiding a single tap.

**Clean cut on `course_hidden_`, reusing the retired key**, agreed on
2026-09-23 because there are **no released users as of Build 248**. Record that
reason with the change: it is true now and expires silently. Build 241
Revision 2 retired those values as ignored-never-converted, and that decision
still constrains work three builds later.

Recover the Build 229 Revision 0 design rather than reinventing it: it had
**active-course protection** and a reversible **`Hidden courses (n)`**
management entry. `AGENTS.md` currently states Hide/Unhide was removed; that
line becomes wrong and must be rewritten. The retired key appears to be swept
by the `learner_<UUID>_` prefix reset rather than named individually in
`AppResetService` — confirm that when building, and update
`docs/239_RESET_STORAGE_INVENTORY.md` either way.

### Step 5 — Editor device-state owner

An audit of the Course Editor root on 2026-09-23 found four kinds of
responsibility that are not editing the open Course:

1. **Six `SettingsService` calls** for per-device editor preferences — access
   mode, the one-time View-only notice, the orphan-check due date — written
   immediately, outside the confirmation the Editor otherwise defends.
2. **A background maintenance job**: `_checkOrphanAudio` runs automatically in
   `initState` when due, with its own due-date bookkeeping.
3. **Identity and governance lookups** (`getProfileRecords`, `listTeams`,
   `getActiveProfileId`, `CourseGovernanceResolver`) to populate Course Info.
4. The duplicate-title read, which the boundary rule now explicitly allows.

Give 1 and 2 one owner, so "written immediately" becomes a deliberate property
of that owner rather than an accident of where the code sits.

### Open questions

* **Is `_checkOrphanAudio` running automatically on Editor open deliberate
  design or historical drift?** This decides whether step 5 is an extraction or
  a behaviour correction, and those must not be mixed.
* **Does Hide ship with the merge or after it?** The merge is what makes people
  add more Courses, so it is what creates the clutter Hide solves.

## Findings carried out of the delivered builds

These are open items the delivered work uncovered. They are **not** steps above
and need no particular order; take each with whatever build next touches that
area, or on its own.

* **The Course Editor's Fork still acts on the unconfirmed working copy.**
  `_forkCourse` calls `createFork(source: _course)`, where `_course` is the
  working copy — the same defect Build 248 Revision 2 removed from export and
  Copy as New Course, and it was missed because only the two named actions were
  removed. Fork **persists** a new Course, so a fork can be created from edits
  that are then cancelled, leaving provenance pointing at a source version that
  never existed. Course Manager's Fork passes the stored Course and is correct.
  Fix: remove `course-editor-fork-course` and `_forkCourse` (about 15 lines),
  leaving Course Manager as the only route — but first confirm Course Manager's
  Fork covers every case the Editor's does, particularly official Courses.
* **`CourseEditorScreen.transferService` is inert.** Six lines of wiring that
  nothing reads, kept so its seven callers keep compiling. Remove it with those
  call sites when something next touches that file.
* **Images added while editing** are cleaned up as of Build 248 Revision 1;
  the earlier known limit is closed.
* **`guidebook_status_workflow_226_02_test.dart` was intermittently slow.** Its
  two hand-rolled ~3 s waits now use the shared 10 s `pumpUntilFileIoState`.
  Whether Build 248 contributed was never established: both failures came from
  one heavily loaded session and all later runs were clean. If it fails again,
  treat that as new evidence rather than noise.
* **A test can protect a defect.** Build 248 Revision 2 found a regression test
  that edited Course Info, left it unconfirmed, copied, and asserted the copy
  carried the unsaved edits. When a test blocks a correction, read what it
  actually pins before assuming the code is wrong.

## Not scheduled as architecture extractions

* A standalone move of `AudioLibraryScreen`, `CourseAuditScreen`, or other
  large widgets to new files. Route/module moves may follow a proved owner
  boundary and behavioral tests, but file length is not the acceptance test.
* Cross-process Course storage or an index for duplicate IDs. Build 245's
  in-isolate lock, narrow external-writer race, and linear duplicate-ID scan
  are documented limits. Revisit only if QQL needs concurrent external
  writers or the Course library becomes large enough for the scan to matter.
* New Course Model wire versions, changed signature/package formats, or
  altered scoring/XP. Those require their own product decision and plan.

This document is the approved roadmap. Builds 246, 247 and 248 are delivered;
their detailed plans, evidence and handoffs live in `docs/246_*`, `docs/247_*`
and `docs/248_*`. Each remaining step still requires its own concrete plan
before any source change. A newly discovered behavior,
persistence, or compatibility change must be characterized and handled
explicitly rather than silently folded into an extraction.
