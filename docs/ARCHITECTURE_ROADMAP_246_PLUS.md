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
| ✅ **2** | **Course library operations owner** | Build 249 Revision 0: `CourseLibraryOperations`. See below and `docs/249_HANDOFF.md`. |
| **3** | Merge into one screen, two tabs, capability-driven | Small once 2 is done; reuse the Build 229 "unified surface is capability-driven" pattern. |
| **4** | **Hide in Learner** / **Unhide in Learner**, per learner × Course | Ships **with** step 3. See below. |
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

### Step 3 — One screen, two tabs: shared Course rows

Owner decisions, 2026-09-23. **Both tabs use the same Course row**: today's
Course Library row, with its artwork, languages, Version, Last edited,
Maintainer, Duration and blue status labels (Draft, Unpublished, Verification
required), plus Sort by and Expanded / Compact. The artwork is the Course
**cover image when there is one, otherwise the flag**, in both tabs; this is
what `CourseArtwork` already does.

**Both tabs have Sort by and a Show unavailable switch, on by default**, so
every Course is shown until it is turned off. There is **one** Sort by
and **one** Show unavailable switch for the whole screen, above the tabs, and
they apply to both; switching tabs never changes the order or what is
filtered. Expanded / Compact stays per section. "Unavailable" keeps today's
Course Library meaning: unpublished, awaiting Publisher verification, or
containing Draft content. This **changes today's Course Library default**,
where *Show unavailable or Draft Courses* starts off. The page-session scope,
and the switch never changing Course state, stay as they are.

**The word "hide" is reserved for Hide in Learner** (step 4). Nothing else on
this screen may use it, so two different things never share a name. That
applies to the switch above and to the section counts: today's
`· S shown · H hidden` becomes **`· S of N shown`** (for example
`My Local Courses · 2 of 3 shown`), and a section with nothing filtered keeps
its plain `· N`.

The rows differ only in **colour and trailing controls**. The COURSE MANAGER
tab alone keeps the **red / green Audit border** that Course Manager cards
show today; ALL COURSES rows have no Audit colour. ALL COURSES keeps
Add / Remove and gains the 3-dot menu of step 4; COURSE MANAGER keeps its
3-dot operations menu, with unavailable entries greyed out with a reason
(Build 249 Revision 1).

**ALL COURSES 3-dot menu** (owner decisions, 2026-09-23), in this order:

1. **Course Info** — the existing Course Info dialog the learner Course
   Selector already offers on every row (Build 229). Always available.
2. **Favorite** / **Remove from Favorites** — for **any** Course, whether or
   not it is in the Personal Library. Favorite never changes membership.
3. **Hide in Learner** / **Unhide in Learner** (step 4). Greyed out with
   "Add it to your courses first" when not in the Personal Library.
4. **Reset course progress** — the active learner's progress for this Course
   only, through the existing `ProgressService.resetCourse` and the existing
   reset confirmation wording (XP, Weekly XP, study days and streak are kept).
   Greyed out with "Add it to your courses first" when not in the Personal
   Library. Known consequence: progress kept after *Remove from my courses*
   can then be reset only by adding the Course back, or by choosing the reset
   option while removing it, which is unchanged.

Operations that change or derive from a Course (Edit, Fork, Copy, Merge,
Export, Delete) stay in the COURSE MANAGER tab.

**Favorites section.** ALL COURSES gains a **Favorites** section **first**,
above Bundled Courses. A Favorite Course **also stays in its own section**:
Favorites is a shortcut list, so section counts and places stay as people
expect. The Favorites section is drawn in **inverted black and white** — a
black band with white text in Light mode, a white band with black text in Dark
mode — so it reads as different from the Bundled section below it.
Favorites appear only in ALL COURSES.

**Entry from the Course Selector** (owner decisions, 2026-09-23). The learner
Course Selector has **two distinct entries**, **All Courses** and **Course
Manager**, each opening the one Courses screen with **its tab already
selected**. All Courses replaces today's *Course Library* entry.

**Locked Course Manager.** Today, while Course Manager is locked for the
profile, the Selector's Course Manager entry and its edit-current-Course entry
are hidden. Instead:

* the Selector's **Course Manager** entry and its **edit-current-Course**
  entry are shown **greyed out**;
* the Courses screen's **COURSE MANAGER tab** is shown **greyed out**;
* using any of them shows one message that says Course Manager must be
  unlocked **for this profile** to edit Courses and use Course operations,
  **and how to unlock it**: tap **Version** in Settings ten times. The owner
  chose to state the method.

The unlock stays **per user profile**: each profile activates Course Manager
for itself, exactly as today. The unlock itself and today's import-only rules
for a locked profile are unchanged. Help texts that say Course Manager is
available "when activated for your profile" stay correct; they only gain a
sentence saying the entries are shown greyed out until then.

**Help split** (owner decision, 2026-09-23; section assignment confirmed by
the owner the same day). Course Manager today opens the full
Course Editor Help (`lib/screens/editor_help_content.dart`, 33 EN/IT sections
plus the Course types card and the Technical reference). It is split so that
**Course types and Course operations** move to a new **Course Manager Help**,
while **editing** stays in the **Course Editor Help**. Some overlap is allowed
where both screens need it. Proposed assignment:

* **Course Manager Help**: the Course types card; Course origin; Official
  course updates; Create a new course; Course creation rules; Import a custom
  course; Export a custom course; Course responsibility, permissions and Teams;
  Android device backup (technical); and a **new** section on Copy as New
  Course, Fork, Merge, Delete and Remove Publisher Course, which have no
  section today (the Merge screen keeps its own Help too).
* **Both** (allowed overlap): Course Audit; Audit severity and codes; Local
  course edits and backups; Course Info Editor and license.
* **Course Editor Help**: every other editing section, and the Technical
  reference.
* **All courses Help** (today's `availableCoursesHelp`): gains *Courses in
  learner mode*.

On the Courses screen the Help button opens the Help of the selected tab. The
Course Manager Help keeps the EN/IT toggle and the rule that the two language
lists stay the same length.

**Screen layout details** (confirmed by the owner, 2026-09-23). Both tabs use
the same four sections (Bundled, Publisher, My Local, Other Local; ALL COURSES
adds Favorites first). Team Manager and Shared Images appear only in the
COURSE MANAGER tab. The Import icon is in the top bar of both tabs. The **New
course** icon appears **only in the COURSE MANAGER tab**, because it leads to
creating and then editing a Course. ALL COURSES gets a third top-bar icon of
its own instead: **Search** (a magnifier), confirmed by the owner. It opens a
filter field under the top bar that narrows every section, Favorites
included, by Course title or language as the user types. It is page-session
only, stores nothing and never changes a Course; filtered sections use the
same `· S of N shown` count as Show unavailable.

**Course Selector row menu** (owner decisions, 2026-09-23). Today it offers
Remove from my courses, Review (current Course only) and Course Info. It
becomes, in this order: **Course Info**; **Review** (current Course only);
**Hide in Learner**, greyed out on the Course being studied ("You're studying
this Course"), with no Unhide here because hidden Courses are not listed;
**Remove from my courses**, last. **Reset course progress is not offered in
the Selector**; it stays in ALL COURSES. The owner confirmed that Hide in
Learner and Remove from my courses are clear enough side by side.

**Favorites in the Course Selector** (owner decision, 2026-09-23, option B).
The Selector's row menu also offers **Favorite / Remove from Favorites**, after
Review, so the menu reads: Course Info, Review, Favorite, Hide in Learner,
Remove from my courses. The Selector lists, **top to bottom**:

1. **Current** Course;
2. **Recent** Courses, at most 3, as today;
3. **Favorites**, no maximum: favorite Courses in the Personal Library that
   are not hidden in Learner;
4. the **other** Courses in the Personal Library;
5. the links **All Courses**, **Course Manager**, **Course Editor** (the
   current Course) and **Import**, in that order; Course Manager and Course
   Editor are greyed out with the unlock message while locked.

**Recent and Favorites do not skip each other**: a Course that is both recent
and a favorite appears in both groups (owner's choice). The **current Course
is never repeated in Recent**, as today: Recent holds up to 3 *other* recently
studied Courses. Apart from Recent, being current removes a Course from no
group: it also appears in Favorites when it is a favorite, or in Other when it
is neither recent nor a favorite. "Other" lists the library Courses that are
in neither Recent nor Favorites.

**Import: locked profiles and received updates** (discussed 2026-09-23).

* **Approved:** in the *Matching Course ID* dialog, a profile with Course
  Manager locked sees **Copy as New Course** and **Fork greyed out** with the
  reason "Unlock Course Manager for this profile to create your own copy (tap
  Version ten times in Settings)". Replace / update and Cancel are unchanged.
  Copy and Fork stay unavailable while locked: they create a Course whose only
  purpose is editing.
* **Approved: received Custom Courses can be updated (option D, clean cut).**
  Today a learner can never take a friend's newer version of a Custom Course:
  Replace needs Maintainer or Team rights, which belong to the friend.
  Publisher Courses do not have this gap, because a trusted signature, the same
  publisher and a newer version authorise any profile. Custom Courses carry no
  signature, and the device holds **one shared copy** of each Course, so the
  rule must never let an unrelated profile overwrite a Course someone authors
  on this device. The rule:
  * When a Custom Course is **installed by import** and no profile on this
    device is its Maintainer or a member of its assigned Team, the device
    records it as **received**: a device-local flag keyed by Course ID, never
    written into the Course file.
  * For a **received** Course, any profile that has it in its Personal Library
    may **Update to version N** from a file naming the **same Maintainer and
    Original Course Creator** with a **newer Course version**. The previous
    version is backed up and learner progress is kept, as for Publisher
    updates.
  * A Course authored here (not received) keeps today's rule: only its
    Maintainer or Team may replace it; others see Update greyed out with the
    reason that it is authored on this device.
  * **Clean cut, no legacy inference** (owner decision): Courses stored before
    this ships carry no flag and are not received. Recorded reason: **there
    are no released users as of Build 249**; that reason expires silently.
  * The flag is new stored data: add it to `AppResetService`,
    `InventoryService` and `docs/239_RESET_STORAGE_INVENTORY.md`, and write
    the exact key and the edge cases (for example, the Maintainer's profile
    later appearing on the device) into that build's plan first.
  * Remaining risk, accepted for now: without a signature, a crafted file can
    still impersonate a friend's update, but only for a received Course, only
    through the user's own import, and with the old version backed up. Signed
    Custom Courses (option C) would close it and are a separate format
    decision.
* **Proposed, awaiting the owner's decision:** after any successful import,
  return to where Import was opened, with no Editor opened for Copy or Fork.
  From the Courses screen, land on ALL COURSES with the new Course scrolled to
  and highlighted. From the Course Selector, return to Home with "Imported …
  and added to your courses", plus **Study now** when the Course is playable,
  or the reason it cannot be studied yet. Imports keep adding the Course to
  the importing profile's Personal Library, as today.

**Favorite is new stored data**: one per-learner × Course flag under the
learner prefix. Following the change discipline, the key must be added to
`AppResetService`, `InventoryService` and
`docs/239_RESET_STORAGE_INVENTORY.md`, and confirmed with the owner before it
ships, as any new stored key is.

### Step 4 — Hide in Learner / Unhide in Learner, shipped with the merge

Considered and rejected: splitting membership into "studying" and "authoring".
A maintainer's normal loop is edit, then check the result in the learner view,
so a second intent flag would have to be added and removed constantly. Hide
keeps one membership concept and makes unhiding a single tap.

**Clean cut on `course_hidden_`, reusing the retired key**, agreed on
2026-09-23 because there are **no released users as of Build 248**. Record that
reason with the change: it is true now and expires silently. Build 241
Revision 2 retired those values as ignored-never-converted, and that decision
still constrains work three builds later.

**Both tabs offer it in their 3-dot menus** (owner decisions, 2026-09-23).
The entry reads **Hide in Learner**, or **Unhide in Learner** once hidden.
ALL COURSES gains a 3-dot menu per row for it; for a Course not in the
Personal Library the entry is shown **greyed out with a short reason** ("Add
it to your courses first"), following the Build 249 Revision 1 rule that
unavailable entries are greyed with a reason rather than hidden. The COURSE
MANAGER tab's existing 3-dot menu gains the same entry; every Course there is
already in the Personal Library, so only active-course protection can grey it
out.

Recover the Build 229 Revision 0 design's **active-course protection**, but
**not** its separate **`Hidden courses (n)`** management entry: the owner
dropped it on 2026-09-23. Unhide in Learner sits in the same row menu as Hide,
in either tab, so hiding stays reversible without a dedicated screen. A hidden
Course's row should carry a visible **Hidden in Learner** label, so it can be
found to unhide. `AGENTS.md` currently states Hide/Unhide was removed; that
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

### Both open questions are answered

**`_checkOrphanAudio` is deliberate.** `SettingsService.isAudioOrphanCheckDue`
is a **7-day throttle per Course code**, persisted, and the run is additionally
gated on `canEditOriginal` and Edit mode. A weekly scheduler is not something
that accumulates by accident. Step 5 is therefore a **pure extraction**: move
the schedule and the per-device settings to an owner without changing when the
check runs or what it offers.

One interaction is worth knowing but must **not** be folded into that
extraction. The dialog removes clip references from the working copy, which
makes the Course dirty, so accepting an automatic prompt and then leaving now
produces the "Unapplied course changes" confirmation for something the author
did not initiate. If that proves annoying, change it in its own revision with
its own decision, keeping behaviour corrections separate from structural
extraction as `AGENTS.md` requires.

**Hide ships with the merge** (step 3), not after it. The merge is what leads
people to add more Courses, so it creates the clutter Hide solves; shipping
them together means the problem never appears.

The action is labelled **Hide in Learner** / **Unhide in Learner**, not plain
Hide. The
merged screen puts two removals within a few pixels of each other — Remove
(leaves the Personal Library, so it disappears from the Manager tab too) and
Hide (stays in the library, absent only from the learner Course Selector).
Naming the *place* in the action is what keeps them apart.

## Findings carried out of the delivered builds

These are open items the delivered work uncovered. They are **not** steps above
and need no particular order; take each with whatever build next touches that
area, or on its own.

* ~~**The Course Editor's Fork still acts on the unconfirmed working copy.**~~
  **Closed by Build 248 Revision 3**, which removed `course-editor-fork-course`
  and `_forkCourse`; Course Manager is the only Fork route.
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
