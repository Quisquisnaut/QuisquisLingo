# QQL Build 250 — Courses screen, roadmap Steps 3 and 4

Date: 2026-09-23. Baseline: `main` at merge `a412c736671d6d1616228accd7a25700eb8319b5`, app `2.0.49+249002`. The current tree is the source of truth. Preserve Course Model v11, package format 1, existing authoring rights, progression, scoring, and the top-level Course confirmation. Leave `devtools_options.yaml` untouched.

## Owner decisions carried into this build

The roadmap's Step 3 and Step 4 sections are the behavior contract. The owner confirmed the open points from `docs/249_HANDOFF.md` on 2026-09-23:

- Name the screen **Courses** and the empty-library link **All Courses**. Put unreadable-file warnings on **All Courses**.
- Keep Import available on All Courses and the Selector for a locked profile. New course appears only on the unlocked Course Manager tab.
- After successful Import, return to the opening surface. From Courses, select All Courses and scroll to and highlight the resulting Course. From the Selector, return Home with an imported-and-added message, plus **Study now** if the Course is playable or the reason it is not.
- Favorite key: learner-scoped SharedPreferences bool `learner_<profileId>_course_favorite_<Uri.encodeComponent(courseId.trim())>`; true or absent.
- Received Custom Course key: device-scoped SharedPreferences bool `quisquislingo_received_custom_course_<Uri.encodeComponent(courseId.trim())>`; true or absent. Clear it on physical deletion or local authoring. A Maintainer or assigned-Team profile appearing locally blocks the received-update exception.
- A received Custom Course update keeps the installed assigned Team ID and all immutable provenance (Original Course Creator details, original creation time, Fork and Merge lineage); the owner confirmed this safeguard on 2026-09-23.
- Hide in Learner reuses the retired `learner_<profileId>_course_hidden_<Uri.encodeComponent(courseId.trim())>` key as a clean cut. No legacy conversion is attempted because there are no released users as of Build 248; that historical reason expires silently.

## Build 250 Revision 0 implementation slices

1. **Shared presentation:** one Courses route with All Courses and Course Manager tabs; one Course row renderer and shared page-session Sort by and Show unavailable controls (on by default). Keep Expanded / Compact per section. All Courses gets Search, a Favorites shortcut section, Add / Remove and its four ordered row actions. Manager gets the same four Course sections and rows, its existing capability-driven operations and Audit border, Team Manager, Shared Images and New course. Both tabs have Import; Help follows the selected tab.
2. **Learner state:** Favorite applies to any Course and does not change membership. Hide / Unhide applies to Personal Library Courses, blocks the actively studied Course, and adds a visible Hidden in Learner label. Selector shows Current, up to three other Recent, Favorites and Other; Recent and Favorites may repeat; hidden Courses are omitted. Selector row menu is Info, Review on current only, Favorite, Hide, Remove. Manager and Editor links stay visible but greyed until this profile unlocks Course Manager via ten taps on Version in Settings.
3. **Import:** Copy and Fork are greyed with the unlock reason in matching-ID Import while locked. Received Custom Course updates require the importer's Personal Library membership, unchanged Maintainer, assigned Team ID, Original Course Creator, original creation time, and Fork/Merge provenance, a strictly newer positive integer Course version, and absence of a local Maintainer or assigned-Team profile. Recheck under the Course lock; apply the ordinary World Flag validation before mutation; keep backup, progress, media recovery, and imported version. Normal authorized Replace and signed Publisher updates retain their existing rules. Successful imports return a Course result for the opening surface; Copy and Fork do not open the Editor.
4. **Storage/reset/help:** Favorite and Hide remain learner-scoped settings across progress reset and in learner backup; profile/full reset clears them. Received flags appear in inventory and are removed with Custom Course storage/full reset. Split Course Manager Help from editing Help with EN/IT parity; add learner-mode guidance to All Courses Help. Update current release metadata and handoff after verification.

## Focused proof and release gate

Characterize the existing route and write focused checks for tab state, common row details, filtering/counts, Favorite and Hide persistence, active Course protection, Selector grouping, import return paths, received-update authorization and storage, backup/reset scope, and Help parity. Run affected widget/service tests serially (`--concurrency=1`), `flutter analyze`, validators, and the full Flutter suite once the final source tree is stable. Record commands and results in Build 250 validation. Confirm `git diff --check` and the intended-file list before a local commit. Push, PR and merge remain separate directions.

## Next revisions

- **Build 250 Revision 0 (this work):** ship roadmap Steps 3 and 4 together as the two-tab Courses screen, learner Favorite/Hide behavior, Selector changes, received Custom Course updates, import return flow and Help split. Record its validation and handoff in this task.
- **Build 250 Revision 1 (conditional):** if a defect is later proven, make only the evidenced correction, with its own failing characterization, validation, handoff and local commit. Additional corrections receive the next revision number; they are not assumed in advance.
- **Following roadmap build, Revision 0 — Step 5:** extract the Course Editor's immediately written device preferences and seven-day orphan-audio schedule into an owner, preserving their timing and dialogs. This requires a separate task and baseline check.
- **Following roadmap build, later revision only if decided:** resolve the automatic orphan prompt's interaction with a dirty Course working copy as its own behavior change, if it proves troublesome and the owner chooses a rule.
- **Separate future proposal:** signed Custom Course updates need a package-format and trust decision before implementation. Other paused architecture tracks remain outside Build 250.
