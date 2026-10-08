# Build 262 plan: authoring the bundled Courses inside the app

Status: **set aside** (2 October 2026, evening): replaced by
`docs/PUBLISHER_COURSES_PLAN.md`, which Build 262 implements in part. Kept
as a record. Owner request and decisions of 2 October 2026 (point 3 of the
owner review that became Build 261 Revision 5).

## 1. The need

As the author of QuisquisLingo, the owner needs to edit the bundled
Courses (the QQL Demo Courses shipped inside the app) **inside the app**,
and to produce new Courses that become bundled, so that the next version
of the app distributes them.

## 2. Today

- Bundled Courses are official and read-only in the Course Editor.
- Fork exists only when the Course's license allows derivative works: the
  Exercise Laboratory allows it; QQL Demo: Piedmontese (sorted by
  exercise type), QQL Demo: Piedmontese and QQL Demo: English from
  Italian forbid it.
- Fork and Copy as New Course create a Custom Course with **new IDs**
  (Course, Lessons, Rounds). Learner progress is keyed by those IDs, so a
  forked Course that replaced a bundled one would start every learner
  from zero.
- A Course becomes bundled only through a new build: it is an app asset
  (`assets/courses/*.json`, registered in `CourseService.courseAssets`).
  An installed app cannot change its own assets.
- The four bundled Courses are written by Python generators in `tools/`
  (`generate_exercise_laboratory_254.py`, `generate_piedmontais_demo_254.py`,
  `generate_piedmontese_mixed_259.py`, `generate_english_from_italian_260.py`),
  checked by `--check` and by tests. Regenerating a Course rewrites its
  file from scratch.

## 3. Decisions of 2 October 2026

1. **Edit as author.** On a bundled Course, the author opens a copy that
   **keeps every ID** (Course, Lessons, Rounds, exercises, content) and
   remembers which bundled Course it comes from. The bundled original is
   untouched until a new build replaces it. Learner progress stays valid
   when the edited Course is shipped.
2. **Reserved to the app author.** Not to every Course author, not to
   every admin.
3. **Secret, undocumented author mode.** 20 taps on a hidden spot open a
   code prompt; on first use the author chooses the code, stored on the
   device only as a hash. Nothing in Help or in any menu. (The source is
   public on GitHub, so "secret" means hidden, not protected; acceptable
   because what the author exports reaches learners only through a build
   the developer makes.)
4. **Export as bundled.** For the author's copies and also for new Courses
   the author made: a Course Studio action that writes a file already in
   the bundled format (QQL as publisher, official version raised, no
   Maintainer and no Team, not private) into `Export/Courses`.
5. **Shipping.** The author gives the developer the exported file; the
   developer puts it in `assets/courses` (replacing the old file, or adding
   a new Course and registering it), runs the validators and the suite, and
   builds the next version. Everyone who installs that version receives
   the updated Course with their progress intact.
6. **Generators.** Until a Course is exported by the author, the developer
   keeps correcting it through its generator. After the author's first
   export of a Course, its generator is retired: the exported file becomes
   the source, otherwise the next regeneration would erase the author's
   edits. (No decision needed from the owner; explained in plain words.)

## 4. Workflow, step by step

1. Unlock author mode: 20 taps, then the author's code.
2. On a bundled Course choose **Edit as author**: the author's copy opens
   in the Course Editor, same IDs.
3. Edit it like any Course: Drafts, Preview, Audit, the Course preview.
4. **Export as bundled**: the file lands in `Export/Courses`.
5. Hand the file to the developer, who ships it in the next build.

## 5. Technical outline (to confirm at kickoff)

- **Author mode state**: a device-level (not learner) flag plus the code
  hash; a new persisted key goes to `AppResetService`, `InventoryService`
  and `docs/239_RESET_STORAGE_INVENTORY.md` (Inventory may list it without
  saying what it is). Wipe everything removes it.
- **Author copy**: a Custom Course whose identity equals the bundled
  Course's (same `courseId`) cannot coexist with the bundled one in the
  library as things stand (same-ID rules). Options to evaluate: a
  dedicated author store/namespace for author copies, or a copy with a
  marker and its own storage ID that maps back to the bundled IDs on
  export. The learner side must never see the author copy as a second
  playable Course with the same ID.
- **Export as bundled**: `originType: bundledOfficial`, publisher
  `org.quisquislingo` verified, `officialCourseVersion` raised,
  `officialChecksum` computed as `CourseBackupService.officialContentChecksum`
  (the app's own JSON, so it matches what `CourseService.loadBundledCourse`
  verifies), no `maintainer` / `assignedTeamId`, `temporarySample: false`,
  Audit errors refuse the export. File name in the `QQL_` pattern.
- **Developer side**: a tool (or checklist) to drop an exported file into
  `assets/courses`, register a new code in `CourseService.courseAssets`
  and `tools/validate_courses.py`, and retire the Course's generator and
  its `--check` and parity tests.
- **Tests**: author mode hidden and refused without the code; Edit as
  author keeps every ID; the exported file loads through
  `CourseService.loadBundledCourse` (provenance and checksum); export
  refused with Audit errors; nothing of this appears to other profiles.

## 6. Open points for the kickoff

- Where the 20 taps go (for example the logo in App Info).
- Official version numbering of an exported Course (raise the minor
  version? the owner chooses at export?).
- Replacing an existing bundled Course versus adding a new one: how the
  export says which (a new Course needs a new bundled code and ID).
- What happens to the author's copy after the new build ships the Course
  (keep, discard, refresh from the shipped one).
- Whether author copies may exist for several bundled Courses at once.

## 7. Not in Build 262

- Signing or distributing Courses outside the app build.
- Any change to how learners receive bundled Courses.
