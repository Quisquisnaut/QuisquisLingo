# QQL architecture roadmap after Build 245

Status: **proposed roadmap, not implementation approval**. Written against
`main` after merged PR #9, `2.0.45+245004` (Build 245, Revision 4).
Read `pubspec.yaml`, `AGENTS.md`, and the preceding handoff again at the
start of every future step. Build 246 Revision 0 has its own plan in the
separate Merge task; that plan controls its detailed implementation.

## Purpose and boundaries

Build 245 established one Course authoring session, typed hierarchy updates,
and per-Course storage commands. The following builds address other owners.
Each change must put a rule, state transition, or media lifetime under one
defined contract. Moving an unchanged screen class to another file does not
complete a step. Preserve Course Model v11, stored data and keys, authoring
rights, scoring, progression, package/signature compatibility, and the single
top-level confirmed Course save unless a later approved plan explicitly
changes one of them.

The numbers below are **proposed slots**. Start each numbered build from the
then-current merged `main`; do not implement the whole roadmap at once.
Every build starts at Revision 0. Add Revision 1 or later only for a separately
reviewable correction or follow-up proven necessary by that build's tests.
Never make an empty revision merely to fill a reserved number. The
`+<build><revision>` suffix (for example, `+247000`) is a proposal; derive
the full package version and Beta expiry from the live release state and
actual release date at execution time.

## Build, revision, and session schedule

| Order | Build / revision | Session | Owner to establish | First proof and boundary |
| --- | --- | --- | --- | --- |
| 0 | **246, Revision 0** | **Existing separate Merge task** | One Merge workflow owns copied media, Course confirmation, and cleanup decisions. | Test partial copy and post-commit failure; retain media if the stored Course needs it. The Merge task's detailed plan is authoritative. |
| 1 | **247, Revision 0** | **New Package Import session** | One import workflow owns a Course package's staging lifetime, installation, confirmation, and recovery. | Characterize all import routes and failures. Prove whether the manifest misses shared-image provenance outside Exercise prompts before changing its format or behavior. |
| 2 | **248, Revision 0** | **New Audio Library session** | A Course authoring media-lifetime owner tracks newly imported recordings through nested Save, top-level Cancel, Confirm, and uncertain failure. | Test Cancel after import, partial valid batch write, and post-commit failure. Keep MP3 validation/storage in `RecordedAudioService`, playback and controls in the widget. |
| 3 | **249, Revision 0** | **New Exercise Authoring session** | A pure draft builder owns Exercise candidate construction and typed field errors. | Compare v11 JSON, stable IDs, Draft versus Published rules, image provenance, Preview, Save, and Cancel across templates. Keep controllers and dialogs in the screen. |
| 4 | **250, Revision 0** | **New Round Attempt session** | A pure attempt owner controls answer, first-pass error, review-queue, and finish transitions. | Preserve flashcard requeue, first-pass XP facts, Preview/view-only no-write, audio filtering, and completion failure timing. `LearningCompletionService` keeps persistence and awards. |
| 5 | **251, Revision 0** | **New Home/Learner session** | One generation-guarded snapshot owns learner and Course loading/switching. | Preserve empty-library and saved-Course fallback, locks, profile-scoped progress, and both visible and persisted selection when a slow switch loses to a newer one. Keep scrolling, animation, and dialogs in Home. |
| 6 | **252, Revision 0** | **New Audit Ownership session** | A typed projection owns Course/Lesson/Round/Exercise/GuideBook concern status; widgets only render it. | Preserve codes, severity thresholds, issue order/location, GuideBook-off neutrality, scoped results, report content, and navigation. Characterize Audit media-use coverage before any behavior correction. |
| 7 | **253, Revision 0 (reserved)** | **New Model Policy session, only after contract approval** | App-build compatibility policy moves to an application boundary while Course v11 values and codecs remain canonical. | Map every load/import route and exact errors before changing the `Course` constructor's build check. Do not run this slot solely to shorten `course_models.dart`. |

The sessions are separate because each row has a different failure boundary and
review contract. Revisions added within one build may stay in that build's
session, but each revision still ends with its own version, validation,
handoff, and commit. Merge Build 246 before starting Package Build 247; then
use the same rule for each following build. This keeps media ownership
changes from competing across worktrees.

## Scope for the next sessions

### Build 247 — Package Import

Entry points are `CourseProjectsScreen`'s package import paths and
`CoursePackage.withInstalledMedia`/`discard`. A screen can choose a file
and show a result; the workflow should decide when staged media becomes
owned by a saved Course and when it may be deleted. The package manifest's
`_sharedImageSources` currently visits Exercise prompt elements, while
`CourseImageUsage` covers GuideBooks, presentations, answer items, layouts,
and covers. Establish the actual manifest behavior with a fixture. If the
fixture proves a behavior defect, record the correction as a separate
revision with its own compatibility decision, handoff, and commit. If the
defect blocks safe extraction, amend the detailed plan and put the correction
first rather than forcing the proposed Revision 0 order.

### Build 248 — Audio Library

`AudioLibraryScreen` has a local Course draft and uses
`RecordedAudioService` to write MP3 media before the top-level Course
confirmation. Extract the ownership of newly created media and its cleanup,
not the MP3 validator, player, dialogs, or the whole screen class. The
existing orphan check concerns clips without a word; it is not a disk-file
cleanup contract. Test whether Cancel or partial storage failure leaves
unreferenced files before changing that behavior. A failed read of persisted
state must retain media for recovery rather than guess that saving failed.

### Build 249 — Exercise Authoring

`ExerciseEditorScreen._buildCandidate` currently combines UI feedback with
template rules and v11 model construction. Give those rules one pure
input/output contract: draft field values in, candidate or typed field
errors out. The widget retains interaction state, navigation, and feedback;
`CourseAuthoringSession` retains the final Course update. Do not create
another mutable Course copy or publication authority.

### Build 250 — Round Attempt

`RoundScreen` still owns queue and review transitions alongside audio and
rendering. Move only the pure attempt transitions. Completion service reads
attempt facts at multiple await points today; characterize that timing
before passing snapshots across the boundary. Preserve the established
Round/Review/Topic/Duel XP rules and no-write preview modes.

### Build 251 — Learner Session

`HomeScreen._reload` and Course switches use generation tokens to prevent
stale async results from replacing a newer selection. A new session owner
must publish one coherent learner/Course snapshot and guard both displayed
and persisted selection. Keep profile administration, PIN prompts, learner
path painting, and scroll synchronization in the UI.

### Build 252 — Audit Ownership

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

### Build 253 — Model Policy (reserved)

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

This document is a roadmap. The separate Build 246 Revision 0 Merge plan is
the next detailed implementation plan; later rows each require their own
concrete, approved plan before source changes.
