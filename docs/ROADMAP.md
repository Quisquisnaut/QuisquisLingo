# QuisquisLingo Roadmap

This roadmap describes planned work after build 204.

Version numbers are provisional. If a task requires more than one build, later items may move forward rather than being compressed into an unsafe release.

## QQL 232 complete: Integrated Vocabulary Reinforcement in Review

`2.0.32+232` is Build 232 revision 0 on the completed QQL 231 baseline. Review is now an automatic page for the active Course, ordered by descending errors and oldest attempt on ties, with session-local Next Review exclusion. Published GuideBook Vocabulary is integrated before a Round and, only for requested words, once after it; known/difficult memory is versioned and isolated per learner, Course, Lesson and authored entry. Reset Word List clears only that vocabulary memory. IDDQD, Course Model v7, course JSON, bundled checksums and all vocabulary-independent scoring/progression remain unchanged. Release evidence is recorded in [232 validation](232_VALIDATION.md).

## QQL 231 complete: Course Editor Search & Access

`2.0.31+2311` is Build 231.1 revision 1 on the completed QQL 231 revision-0 baseline. It makes the Course Editor root states Locked, View only, Inspection mode and Edit; reuses the normal 22-preset Exercise form in completely read-only View; makes technical Exercise inspection an explicit state; and adds a local Inspection presentation toggle that preserves access, authorization, unsaved values and dirty state. Search remains absent while Locked and opens the state-appropriate Exercise presentation otherwise. Course Model v7, the authoritative Search inventory, JSON/checksums, scoring and learner progression remain unchanged. Release evidence is recorded in [231 validation](231_VALIDATION.md).

`2.0.31+231` is Build 231 revision 0 on the completed QQL 230 baseline. It adds an authoritative searchable-field inventory for all 22 Exercise presets, scoped Course Editor Search, a single three-state root Lock with ownership-safe Edit availability, a per-user × Course View notice and normalized Lesson/Round app-bar and page actions. View unlocked preserves Search, Help, IDs, Preview and Audit without working-copy mutation. Course Model v7, JSON/checksums, scoring, learner progression and the QQL 230 robustness boundaries remain unchanged. Release evidence is recorded in [231 validation](231_VALIDATION.md) and the [Exercise Type inventory](EXERCISE_TYPE_INVENTORY_231.md).

## QQL 230 complete: Robustness & Modularity

`2.0.30+230` is Build 230 revision 0 on the completed QQL 229 baseline. It adds no new feature family and changes no Course Model v7 or scoring rule. The release hardens learner completion against re-entry, makes Audio Exercises Off authoritative through one effective Duel-eligibility calculation shared by Home and Duel entry, makes learner restore and custom-Course replacement rollback-safe, protects official/custom Course identity and individual ownership, bounds diagnostic persistence, corrects QQL build comparison, improves multilingual audio boundaries, applies targeted evidence-driven modularization, and clears the inherited analyzer backlog. Release evidence and deferred design decisions are recorded in [230 validation](230_VALIDATION.md).

## QQL 229 complete: Course Actions & Learner Panel Refinements

`2.0.29+2293` is Build 229 revision 3 on the completed QQL 228 baseline and revision-1 ownership implementation. Course Manager remains the lifecycle hub and presents actions through one ownership/license policy. Duplicate is reserved for an individual Owner or owning-Team member; outsider and official derivatives use Fork only when allowed. Delete remains manager-only. Official and custom courses share the same capability-driven Course Editor hierarchy, with official and outsider originals read-only and owned/Team-owned custom courses editable.

Every Course Selector row now provides Course Info and per-learner Hide without selecting the row. The active Course cannot be hidden; hidden Courses remain installed and unchanged, appear under `Hidden courses (n)`, and can be restored immediately. The Learner Panel adds the per-learner × Course Expanded / Collapse completed / Focused Lesson display cycle, with authoritative completion, Lesson unlock and IDDQD access rules and no Section collapsing. Release evidence is recorded in [229 validation](229_VALIDATION.md).

Revision 1 introduces the clean Course Model v7 custom ownership boundary: every custom Course JSON has an immutable Creator profile ID and an Owner containing a stable individual profile ID or Team ID. Credits do not grant authorization, license governs outsider derivative rights, and no older custom course is inferred or migrated. The separate offline Team Manager stores stable local profile membership and one-or-more-Lead administration outside Course JSON. New Course restores the historical licenses/credits and offers Team ownership only when meaningful. Bundled JSON and checksums advance to v7; progression, XP, Review, Duel, activity, Hide/Unhide and Lesson-expansion data do not change.

Revision 2 corrects metadata and authoring access without reopening the v7 boundary. Bundled/custom language metadata now resolves identically for Test Voice and Course Info, Course flag choice uses one shared Automatic/Explicit resolution path, Team names remain live registry data, date/model/Internal-ID presentation is complete, redundant Manager/Audit controls are removed, and the ten-tap developer unlock is isolated per opaque learner profile. Duplicate/Fork clean-state behavior and authorization remain unchanged.

Revision 3 adds confirmed ordinary-member Team departure through the existing registry, leaving Team courses and learner data untouched while membership immediately controls authorization. Temporary Sample guidance moves from the main Editor into Course Info without changing its v7 field or export, and Course Manager presents authored Draft and Course Unpublished states as independent blue badges.

## QQL 228 complete: Settings, Statistics, Debug and Audio

`2.0.28+2281` is QQL 228 revision 1 on the closed QQL 227 baseline. Settings and Profile retain their existing presentation while their destinations are reordered; Profile gains Statistics and owns User Data; Course Manager stays in the learner Course Selector; and the Flag Game hint gains its exact tooltip and hover wave. Statistics derives its totals and canonical per-language records from the established learner activity history. Debug owns both existing log tools and both exported files share `Documents/QuisquisLingo/Logs`. Learner Audio Settings are applied before Round/Duel source and player initialization, while authoring Preview remains independent and no-write. Revision 1 adds the established course-code fallback to Course Entry Animation when Course JSON declares no flag, starts the two-second transition only after the Course Selector and destination reload finish, makes Show one-time notices again a one-shot action, and distinguishes published source from packaged GitHub Releases in Update status. Release evidence is recorded in [228 validation](228_VALIDATION.md).

Audio Settings uses a clean per-profile namespace: `audio_exercises_enabled` and `tts_enabled` initialize Off, while `tts_voice_preference` initializes System. Previous device-level TTS/voice values and negative skip values remain untouched and unread; there is no migration or conversion. No Course Model, course JSON, checksum, XP or progression migration is introduced.

## QQL 227 closed: Phase 227.04

`2.0.27+227040` (revision 0) closes QQL 227. Its implementation parent is `8badf79dda864cc40098f4df262628029bf68df1`, the completed `2.0.27+227030` Phase 227.03 revision-0 baseline. Release evidence is recorded in [227.01 validation](227_01_VALIDATION.md), [227.02 validation](227_02_VALIDATION.md), [227.03 validation](227_03_VALIDATION.md) and [227.04 validation](227_04_VALIDATION.md).

IDDQD is **Off / On / View Only** per learner × Course and initialized Off. Off applies genuine locks. On bypasses them and records normal study. View Only bypasses them and permits interaction without learner-state writes. Its compact control gives exact explanations through its tooltip and accessibility label, without permanent helper text below the buttons. A genuinely locked Lesson retains its lock marker and shows `Accessible with IDDQD` for On or `Preview with IDDQD` for View Only. Published GuideBooks, Rounds and eligible Duels continue through the established Lesson gate; unavailable child features remain unavailable. The existing three-tap session preview remains separate.

Flag Background remains **Small / Off / Extended / Tinted / Inspired**, stored per learner × Course and initialized Off through the existing clean cut. Small retains contain rendering; Extended retains cover rendering; Off retains the unadorned learner page. Tinted remains a restrained uniform derived color. Inspired retains up to three broad, stronger representative flag-color zones and the compatible `soft_inspired` storage value. Theme is **Light / Dark / System / Day/Night** per learner. System retains the former `default` storage value and live platform behavior. Day/Night resolves device-local time as Light during 07:00–19:00 and Dark during 19:00–07:00, updates at boundaries and re-evaluates on resume.

No 227.05 tranche is planned. QQL 227 remains closed; the separate QQL 228 release above does not reopen or alter its delivered learner-control behavior.

## General principles

For every planned version:

- Start from the latest clean, committed baseline.
- Increment the app version/build for every delivered app update.
- Refresh the Alpha expiry according to the established project policy whenever the app version changes.
- Keep structural refactoring separate from behavior changes whenever practical.
- Characterize important existing behavior with tests before moving or rewriting it.
- Prefer business logic outside UI screens.
- Prefer behavior-level tests over source-text tests.
- Do not weaken validation merely to make tests pass.
- Do not treat a filtered test run or a successful compilation alone as release readiness.
- Update relevant Help, technical documentation, and CHANGELOG when architecture, persistence, import behavior, XP semantics, or user-facing behavior changes.

Required validation for meaningful Dart changes:

```text
dart format <touched Dart files>
focused tests
flutter test
flutter analyze
python tools/validate_courses.py
python tools/validate_images.py
git diff --check
git status --short
```

Before calling a Windows release ready, also perform the established manual Windows Release checks.

---

# 2.0.5+205
## Robustness, modularity, regression hardening, course identity, Windows Sandbox diagnostics

### Code robustness and modularity

- [ ] Continue incremental modularization.
- [ ] Identify business logic still embedded directly in screens.
- [ ] Keep UI primarily responsible for presentation and interaction.
- [x] Extract the current XP formulas into a pure `XpCalculator` without changing scoring.
- [ ] Consider later extraction of completion orchestration and learning-activity logic where justified.
- [ ] Avoid broad refactors.
- [ ] Replace brittle source-text tests with behavior-level tests where practical.
- [ ] Make remaining source-structure tests tolerant of harmless LF/CRLF and formatter differences.
- [ ] Preserve injectable clocks for time-dependent behavior.

### Course ID collision regression suite

Add direct automated coverage for the collision behavior already implemented.

- [ ] Same `courseId`, same title -> collision detected.
- [ ] Same `courseId`, different title -> collision detected.
- [ ] Same title, different `courseId` -> no identity collision.
- [ ] `Separate copy` generates a genuinely new `courseId`.
- [ ] `Separate copy` uses the centralized course-ID generator.
- [ ] `Separate copy` preserves lineage through `parentCourseId`.
- [ ] `Separate copy` preserves `derivedFromVersion` where available.
- [ ] `Separate copy` does not share course-owned progress with the original.
- [ ] `Replace/update` preserves the existing course identity.
- [ ] `Replace/update` preserves existing course-owned progress.
- [ ] `Cancel` changes nothing.

### Bundled-course collisions

Current collision handling is known to operate against custom courses.

- [ ] Decide what should happen if an imported JSON uses the same `courseId` as a bundled course.
- [ ] Prevent an imported course from accidentally appropriating a bundled course identity.
- [ ] Add direct regression tests for the chosen behavior.

### Replace/update and orphaned progress

- [ ] Study what happens when an update with the same `courseId` removes or changes existing Round or Lesson IDs.
- [ ] Decide whether obsolete course-owned progress should be preserved, migrated, ignored, or cleaned up.
- [ ] Do not introduce automatic migration without an explicit compatibility policy and tests.

### Windows Sandbox startup investigation

Investigate why the Windows standalone QuisquisLingo app may fail to launch or may terminate immediately inside Windows Sandbox while working on the host/development machine.

Do not assume WebView2 is involved. The previously discussed WebView2 issue belonged to another application.

- [ ] Reproduce the issue with a clean Windows Sandbox.
- [ ] Test the full Flutter Windows Release directory, not the `.exe` alone.
- [ ] Create a temporary diagnostic Release build if necessary.
- [ ] Add native Windows startup checkpoints.
- [ ] Add Dart startup checkpoints.
- [ ] Flush every diagnostic log entry immediately.
- [ ] Capture timestamps.
- [ ] Capture Flutter framework errors.
- [ ] Capture uncaught asynchronous / Dart / platform errors where possible.
- [ ] Record stack traces where available.
- [ ] Identify whether execution reaches native `main`.
- [ ] Identify whether the Flutter engine/window initializes.
- [ ] Identify whether Dart `main()` is reached.
- [ ] Trace meaningful initialization stages before the first visible screen.
- [ ] Inspect plugin registration and runtime dependencies.
- [ ] Inspect DLL/plugin loading.
- [ ] Inspect assets and `data` directory availability.
- [ ] Inspect Windows Event Viewer / Application Error information after termination.
- [ ] Compare the identical Release build on the host and in Sandbox.
- [ ] If useful, add a controlled diagnostic mode that can disable non-essential startup components one at a time.
- [ ] Remove or disable temporary diagnostic instrumentation after the cause is identified.

Possible diagnostic checkpoint categories:

```text
NATIVE_PROCESS_START
NATIVE_FLUTTER_WINDOW_CREATE_BEGIN
NATIVE_FLUTTER_WINDOW_CREATE_OK
NATIVE_RUN_LOOP_ENTER
DART_MAIN_ENTER
DART_BINDING_OK
DART_ERROR_HANDLERS_OK
DART_PROFILE_OK
DART_SETTINGS_OK
DART_COURSES_OK
DART_TTS_OK
DART_RUNAPP
FIRST_VISIBLE_SCREEN
```

Actual checkpoints must follow the real code path rather than assuming these exact stages exist.

### Exit criterion for 205

The codebase should be better protected against regressions, course identity behavior should be directly tested, and the Windows Sandbox startup problem should be understood or reduced to a clearly identified failing stage.

No new XP scoring system should be introduced in 205.

---

# 2.0.6+206
## Phase 1: behavior-level characterization tests

- [x] Replace the brittle Round completion/XP source-text assertions with widget tests that drive the real `RoundScreen` completion flow.
- [x] Characterize imperfect first completion, perfect first completion, perfect repeat, TTS-skipped perfect completion and preview completion with no learner writes.
- [x] Verify Round completion, laurels, Review history, language XP and learner-global Weekly XP through compatibility-facing services.
- [x] Replace Guidebook generator source-text assertions with widget tests for cancellation, explicit approval and generated Round contents.
- [x] Verify that Course, Chapter and Topic identity remain stable and that generator preview/cancellation does not write learner progress or preferences.
- [x] Keep the change test-only; do not move or modify production code in Phase 1.

### Exit criterion for 206

Critical Round completion/XP and Course Editor generation behavior is protected by direct behavior-level tests before structural modularization begins. Production behavior and persistence semantics are unchanged.

---

# 2.0.7+207
## Phase 2: incremental behavior-preserving modularization

Do not start Phase 2 without an explicit user request after build 206 is released.

- [ ] Make one small structural extraction at a time and review its diff independently.
- [ ] Keep one authoritative implementation; use compatibility delegation where moving every caller at once would increase risk.
- [ ] Keep UI presentation separate from independently testable business rules where practical.
- [ ] Preserve public APIs, async ordering, navigation results, course IDs, persistence keys, stored formats, progress ownership and all established XP formulas.
- [ ] Keep the build 206 characterization tests green before and after every extraction.
- [ ] Run focused tests, the complete Flutter suite and analyzer checks for each delivered step.
- [ ] Do not combine structural moves with new scoring, UI, persistence, import, collision or course-content behavior.

### Exit criterion for 207

Selected responsibilities are moved in small, reviewable steps, with direct regression evidence that learner and editor behavior remains unchanged.

### Deferred XP work

The previously proposed new XP engine, scoring-table changes, duplicate-award policy changes and XP UI remain deferred. They require a separate explicit behavior-change specification and are not part of build 207's modularization scope.

---

# 2.0.8+208
## Technical rebranding

- [x] Rename application-owned Dart, Flutter package and Windows TTS shim identifiers to QuisquisLingo.
- [x] Rename Windows and Linux executable/application metadata that used the former app name.
- [x] Rename branded SharedPreferences keys, serialization markers, course-extension namespaces and diagnostic environment variables without compatibility aliases.
- [x] Update packaging scripts, tests, Help and current technical documentation.
- [x] Move the update checker and release trust boundary to `Quisquisnaut/QuisquisLingo` without an old-repository fallback.
- [x] Keep learner behavior, course behavior, XP/scoring rules, wallpaper/settings behavior and Course Editor structure unchanged.

Profile avatars and milestone infrastructure remain deferred and have not been assigned a replacement release number.

---

# 2.0.9+209
## Celebrations and personal statistics

### Celebrations

- [ ] Celebrate meaningful Streak milestones.
- [ ] Celebrate Studied Days milestones.
- [ ] Celebrate XP milestones.
- [ ] Do not repeatedly show an already acknowledged milestone.
- [ ] Do not block learning flow unnecessarily.
- [ ] Keep all milestone logic offline.

Potential thresholds should be explicitly designed before implementation.

### Personal statistics

Consider:

- [ ] longest streak;
- [ ] best week;
- [ ] total studied days;
- [ ] total XP;
- [ ] perfect Rounds;
- [ ] laurels/crowns.

---

# 2.0.10+210
## Duel/TTS verification and contributor roles

### Duel and TTS

When TTS exercises are disabled:

- [ ] Verify Duel does not select TTS-dependent exercises.
- [ ] Verify Duel generation does not introduce TTS-dependent exercises.
- [ ] Define fallback behavior if too few eligible exercises remain.
- [ ] Add direct automated tests.

### Contributor roles

Verify end-to-end support for:

- [ ] `Author`;
- [ ] `Illustrator`.

Check:

- [ ] Course Model;
- [ ] Course Editor;
- [ ] JSON serialization;
- [ ] import;
- [ ] export;
- [ ] display;
- [ ] backward compatibility.

Implement missing pieces only where verification shows a real gap.

---

# 2.0.11+211
## Safe YouTube links in Guidebooks

- [ ] Allow safe YouTube links in Lesson Guidebooks.
- [ ] Support at least `youtube.com` and `youtu.be`.
- [ ] Validate URL schemes and hosts.
- [ ] Keep course import data-only.
- [ ] Never execute imported HTML or scripts.
- [ ] Open external video links only through an explicit safe mechanism.
- [ ] Define sensible offline behavior.
- [ ] Keep the Guidebook useful when the linked video is unavailable.
- [ ] Represent links in a portable Course Model form rather than a Flutter-specific UI structure.
- [ ] Add validation and regression tests.

---

# 2.0.12+212
## Pure XpCalculator extraction

- [x] Characterize current Round, repeat, perfect, Topic and Duel XP behavior before extraction.
- [x] Extract reward calculations into a pure, deterministic `XpCalculator`.
- [x] Keep XP persistence, Weekly XP aggregation, rollover and leaderboard data in `XpService`.
- [x] Preserve the current potential-XP display and its known disagreement with imperfect-repeat awards.
- [x] Defer scoring corrections and repeated-award policy changes to the next explicitly requested XP stabilization release.

---

# 2.0.13+213
## XP verification and stabilization

- [x] Make `XpCalculator` the single pure authority for Round XP breakdowns and Topic/Duel awards.
- [x] Apply first/repeat answer rates, repeatable perfect bonuses and one-time Laurel bonuses.
- [x] Make Topic XP one-time and Duel XP 50 on first victory then 10 on repeats.
- [x] Keep Topic completion and Duel victory independent.
- [x] Display the same actual award result that is persisted to language and Weekly XP.
- [x] Cover Review, incomplete Rounds and non-evaluable Flashcard/Info content.

---

# 2.0.14+214
## Bugfix and UI refinement release

- [x] Communicate first Topic completion XP in the final Round popup without a second Topic-page award.
- [x] Show first-attempt-correct evaluable answers as X/Y and exclude Flashcard/Info/Guide content from Y.
- [x] Make Enter and Check share guarded text-entry submission behavior.
- [x] Apply only the requested XP-icon and streak-flame spacing refinements.
- [x] Open Gamification from Home through Leaderboard and remove its Settings entry.
- [x] Preserve desktop resizing with a minimum safe size only.

---

# Future release
## Full Course Editor QA and hardening

Run a dedicated Course Editor campaign covering:

- [ ] new custom course creation;
- [ ] 3 initial placeholder Topics;
- [ ] Topics;
- [ ] Guidebooks;
- [ ] manually created Rounds;
- [ ] dummy exercises;
- [ ] every supported exercise type;
- [ ] images;
- [ ] contributors;
- [ ] Author/Illustrator;
- [ ] import;
- [ ] export;
- [ ] collision handling;
- [ ] Separate copy;
- [ ] Replace/update;
- [ ] Course Audit;
- [ ] double-confirmation course deletion;
- [ ] Help;
- [ ] remembered selected course;
- [ ] restart persistence;
- [ ] custom/imported course identity;
- [ ] Course Model v4 validation;
- [ ] JSON round-trip.

Every confirmed bug should receive regression coverage.

---

# Future release — Course portability and interoperability
## Course portability and interoperability

Guiding principle:

> The course belongs to the format and its creator, not to the application/editor that created it.

### Interchange specification

- [ ] Formalize Course Model v4 as a portable interchange specification.
- [ ] Document required fields.
- [ ] Document optional fields.
- [ ] Document stable IDs and references.
- [ ] Document media handling.
- [ ] Document contributor/licensing metadata.
- [ ] Document Guidebook external links.
- [ ] Document exercise capabilities.

### Capabilities

Evaluate a capabilities declaration so another player/editor can determine compatibility before opening a course.

Example concept:

```text
requiredCapabilities:
  listening
  images
  blocks
  externalLinks
```

### Import Compatibility Report

Consider reporting imported features as:

- fully supported;
- converted;
- unsupported;
- ignored but preserved;
- ignored and not preserved.

### Round-trip safety

- [ ] Evaluate preserving unknown fields during import -> edit -> export.
- [ ] Avoid silently destroying extensions belonging to other editors.
- [ ] Consider vendor namespaces.
- [ ] Prefer deterministic exports useful for Git/diff workflows.
- [ ] Avoid absolute filesystem paths.

### External tooling

- [ ] standalone validator;
- [ ] minimal example course;
- [ ] complete example course;
- [ ] optional conformance test suite;
- [ ] converters/adapters for external course formats where appropriate.

---

# 2.0.14+214
## Advanced offline gamification

Consider:

- [ ] Personal Best per Round;
- [ ] Lesson mastery;
- [ ] perfect streaks;
- [ ] local achievements;
- [ ] unlockable cosmetic badges;
- [ ] unlockable avatars;
- [ ] weekly recap;
- [ ] locally generated Daily Challenges;
- [ ] locally generated Weekly Challenges;
- [ ] customizable personal goals;
- [ ] statistics/history;
- [ ] local profile-vs-profile challenges;
- [ ] Lesson-completion achievements;
- [ ] laurel achievements.

Keep gamification offline-first.

Avoid mandatory servers, artificial purchase economies, lives, or monetization-dependent reward systems.

---

# 2.0.15+215
## Chapter-free architecture and Unified Learner

- [x] Promote Course Model v4 with the direct Course → Topic → Round/content hierarchy.
- [x] Make the schema change a clean cut with no Chapter reader, fallback, migration or old progress-key migration.
- [x] Replace standalone Chapter navigation with the unified learner page and learner-facing Lesson terminology.
- [x] Keep active Course, one current Lesson, GuideBook, Rounds, progress, Duel and the existing status bar in one learner hub.
- [x] Keep Home Leaderboard routed to the existing Gamification page and keep Gamification out of Settings.
- [x] Scope Duel to the selected Topic and determine availability from its actual eligible exercise pool at runtime.
- [x] Treat insufficient eligible Duel content as normal unavailable behavior without changing question count, lives, pass behavior, eligibility or XP.
- [x] Document six Rounds (often roughly 48 exercises) as author guidance only.
- [x] Update Course Editor to Course → Topic → Round/content and start new courses with 3 placeholder Topics.
- [x] Convert all bundled courses to deterministic v4 Topic ordering.
- [x] Preserve build-214 Topic completion XP, text-entry, Leaderboard, status-bar and desktop-resize behavior.

---

# 2.0.19+219
## Unified learner central Round path

- [x] Replace the regular Round grid with smaller deterministic left/right cards and occasional same-side pairs.
- [x] Keep clear vertical spacing and draw a visible 2 px, round-ended, 50%-opaque curved connector behind the Round content.
- [x] Discover and decode-validate all PNG mascots from the bundled asset manifest and place them intermittently opposite nearby Rounds with a stable course-specific Fisher-Yates shuffle, one sequence across Lessons, full-set use before reuse, 50%-transparent light/dark surfaces and graceful failure.
- [x] Remove the previous between-Round Lesson imagery from the learner path.
- [x] Mark persisted completed Rounds with a bright yellow-orange icon and the existing perfect/Laurel state with a distinct bright-green icon, without changing completion or scoring rules.
- [x] Use 75%-opaque Round, GuideBook and Duel surfaces, enlarge the Laurel reward frame, keep smaller GuideBook/Duel cards centered and add a theme-neutral 18% dark-mode flag veil.
- [x] Preserve the surrounding learner interface, continuous Lesson flow, locks, navigation, Duel behavior and persistence formats.

---

# 2.0.24+224

## Exercise model, answer engine and authoring navigation

- [x] Inventory and retain all 17 build-223 exercise types, add three focused presets, and map the final 20 presets to Select, Input, Arrange, Match and Presentation without changing Course Model v5.
- [x] Add grouped searchable authoring presets, complete registry-backed Exercise Help, Type the translation and contextual comprehension with text/audio modes and structured dialogue.
- [x] Add deterministic accepted-answer expression expansion, bounded Type-translation typo tolerance and independently scored closest-correction selection.
- [x] Keep terminal punctuation terminal through reorder expansion, normalize structural capitalization and use graded token spelling similarity for closest-correction display without broadening acceptance.
- [x] Formalize the normalized import boundary, engineering interoperability matrix, future Speech seam and ordered content-sequence approach for Story-like material without production external importers.
- [x] Move the Course Editor Lesson list and unchanged authoritative Lock control to one dedicated management page while preserving draft state, operations and stable IDs.
- [x] Add complete Lesson/Round context menus and Exercise duplication with recursive fresh identities and internal-reference remapping.
- [x] Add the registry-backed Exercise Creation Wizard with five selection criteria, no-object plan preview, sequential authoritative editing and confirmed partial-save cancellation.
- [x] Replace fixed GuideBook generation with configurable 6×8-default progressive planning, editable/audited drafts and explicit fresh-ID append approval.
- [x] Add Course/Lesson/Round/Exercise Draft and Published states with strict publication, ancestor-aware learner visibility, badges/actions and unchanged stable IDs/progress.
- [x] Apply one exact unsaved-change guard through nested authoring and protect generated drafts until approval.
- [x] Expand Course Audit with Info, scoped Course/Lesson/Round entry points, stable sorting and error-only pink Round outlines.
- [x] Complete custom Course Edit/Rename/Duplicate/Audit actions and canonical optional Buy a Coffee metadata.
- [x] Add Course-level Lesson prefix and fallback-icon presentation, exact default-title de-duplication, Published-only numbering and portable managed custom Lesson icons.
- [x] Add index-linked `*:` answer groups and structured Correct-answer diagnostics without changing nearest incorrect correction behavior.
- [x] Preserve Review, Duel, XP, Round completion, learner identity, progression, IDDQD, Flag Game and all other out-of-scope behavior.

---

# 2.0.23+223

## Lesson normalization, Sections and theme icons

- [x] Make Lesson canonical in Course Model v5, active Dart architecture, authoring, course JSON and Lesson-semantic learner persistence without v4 compatibility aliases or fallback parsing.
- [x] Keep learner backup schema v2 because it remains an opaque profile-key/value envelope with no structured Topic field.
- [x] Add optional consecutive-order Section metadata without a Section hierarchy, identity, state, navigation, progress or persisted relative numbering.
- [x] Replace the Lesson selector with a Section-block selector when real Sections exist, including UI-only `Other lessons` blocks and deterministic scroll synchronization without Section persistence.
- [x] Expand the canonical controlled Lesson icon family to 14 labeled 256 × 256 transparent PNG assets and expose all of them in the responsive visual editor picker.
- [x] Refocus the Lesson editor on metadata and move the authoritative Round list/create/edit/delete/reorder flow to one linked draft-preserving subpage without regenerating stable IDs.
- [x] Remove the obsolete decorative Lesson image field/control and keep Exercise images separate.
- [x] Standardize themed and fallback GuideBook icons at 84 × 84, permit three title lines, remove the lower label row and add the direct right-side GuideBook action.
- [x] Keep Profile primary, compact Review and Course Info, and move the existing learner/course-scoped IDDQD toggle from Settings into the fixed learner bottom area.
- [x] Regenerate every bundled v5 Lesson with valid Section/icon metadata and representative meaningful Round titles while preserving opaque IDs, references, exercise content and gameplay behavior.

---

# 2.0.22+222
## Stable learner identity and Flag Game

- [x] Make opaque generated learner IDs authoritative and allow duplicate display names without persistence collisions.
- [x] Use an intentional clean cut from the former name-based registry and namespaces, with no migration or fallback.
- [x] Version learner backups and provide preserve-ID, replace-existing and independent separate-copy flows.
- [x] Add one independent licensed 266-entity world-flag manifest with 193 UN Members, all 249 ISO entities, an eight-item Shortlist and nine language-related community/regional flags.
- [x] Keep all established course-flag rendering and identity semantics untouched.
- [x] Add the five-rapid-tap Settings Flag Game with four cumulative pools, 12 questions, five options, sound feedback and responsive light/dark presentation.
- [x] Derive four read-only reference browsers and four device-local Top 5 scorecards from stable dataset/mode identities.
- [x] Keep Flag Game completely separate from XP, streak, Laurel, Review, Duel and course progress.

---

# 2.0.21+221
## Learner panel refinement and locked-Lesson preview

- [x] Contain course-flag backgrounds at the correct built-in or custom-image aspect ratio instead of stretching or aggressively cropping them.
- [x] Use one theme-neutral veil above the flag and below learner content at 25% in dark mode and 10% in light mode.
- [x] Remove every standalone in-flow Lesson heading and move the correct two-line/ellipsized mixed-weight `Lesson <number>: <title>` identity into each Guidebook while preserving the fixed Lesson selector.
- [x] Keep the redundant GuideBook roadmap line absent, retain the avatar, and place the distinctly styled `Guidebook` and `Start Here` elements on one compact row below the integrated Lesson identity.
- [x] Reduce only the Round-card maximum width from approximately 276 to 244 logical pixels while preserving its height, internals, states, Laurel, routing, vertical spacing and interaction.
- [x] Keep Round surfaces at 75% opacity, set GuideBook and Duel surfaces to 70%, keep the connector's 2 px main stroke at 55% above a subtle theme-aware contrast-support stroke, and set mascot-container surfaces to 10%, while leaving foreground content fully opaque.
- [x] Keep GuideBook centered while narrowing it responsively to 78% within the existing 400 logical-pixel cap; preserve Duel width and content-driven GuideBook height.
- [x] Increase only the external Duel-to-next-Guidebook pre-divider spacer from 20 to 32 logical pixels while preserving Duel internals, Round spacing, ordering and navigation.
- [x] Add a structurally secondary learner-bottom control after Profile, Review and Course Info that cycles Default, Light and Dark immediately and persists the choice per real learner profile without changing the 68 px bar height.
- [x] Add a separate far-right Flag background utility that persists per learner and cycles Small → Off → Extended → Small, retaining the current veil for flag modes and omitting it when the flag is Off.
- [x] Keep the learner bottom controls outside the scroll layer and retain the 112 logical-pixel content inset so the final learner element can clear them at 320/375/430 px without changing the 68 px control height.
- [x] Attribute coarse Windows touchpad wheel steps to Flutter's legacy pointer-wheel handling and add no local interpolation, pointer interception or shared ScrollPhysics workaround.
- [x] Reveal a locked Lesson after three same-lock taps as a clearly labelled, non-persistent view-only preview retained for the running app session; allow multiple specifically activated Lessons and clear them only on restart.
- [x] Keep previewed GuideBook, Round and Duel actions disabled while preserving genuine locks, normal unlocks, XP, progress, Review and IDDQD behavior.
- [x] Cover the 320, 375 and 430 logical-pixel learner widths in both light and dark themes.

---

# 2.0.20+220
## Profile navigation and learner bottom area

- [x] Make Profile the central learner identity and personalization page with the active avatar and learner name.
- [x] Route Avatar, learner-profile management and Gamification through Profile with natural back navigation.
- [x] Replace the learner-bottom Leaderboard action with the active learner Profile representation.
- [x] Keep exactly Profile, Review and Course Info in the fixed learner bottom area.
- [x] Move Buy a coffee into Course Info without changing its external support behavior.
- [x] Replace direct Settings Avatar and Learner profiles entries with one Profile entry.
- [x] Add confirmed local-only logout that clears only the active-profile reference and returns to learner selection/create.
- [x] Preserve the build-219 Round path, Review, Duel, XP, course model and learner persistence formats.

---

# 2.0.18+218
## Unified learner Top Bar

- [x] Replace the separate User Bar and Status Bar with one fixed, single-row Top Bar.
- [x] Keep compact Language/Course flag selector, Streak, Laurel progress, Weekly XP, clickable cat mark and Settings visible in that order.
- [x] Keep Streak language-scoped, Laurel progress current-course-scoped and Weekly XP learner-global.
- [x] Keep Streak on one line, show Laurel and Weekly XP as vertical current/max metrics, and explain all three when activated.
- [x] Open the existing full-size course picker from the compact flag, keep the Lesson selector separate, and move learner-profile management into Settings.
- [x] Make the unchanged cat mark open App Info and retain the complete unchanged QuisquisLingo logo above its existing content.
- [x] Preserve the continuous Lesson flow and fixed bottom controls.

---

# 2.0.17+217
## Continuous Lesson flow

- [x] Keep the complete four-zone Learner Header and bottom controls fixed.
- [x] Render the selected Lesson and all subsequent Lessons as one lazy vertical course flow.
- [x] Preserve direct Lesson-picker jumps and last-visited-Lesson persistence.
- [x] Synchronize the fixed Lesson selector to the primary visible Lesson after scrolling.
- [x] Preserve genuine Lesson locks, IDDQD access and Topic-scoped Duel behavior.
- [x] Retain enough bottom clearance for the final Lesson content above fixed controls.

---

# 2.0.16+216
## Stabilization and compatibility release

This version should intentionally prioritize stability over new features.

Audit:

- [ ] persistence;
- [ ] migrations;
- [ ] import/export;
- [ ] Course Model compatibility;
- [ ] course identity;
- [ ] XP;
- [ ] reset behavior;
- [ ] profiles;
- [ ] streak/study days;
- [ ] TTS;
- [ ] Duel;
- [ ] Guidebook external links;
- [ ] Course Editor;
- [ ] Windows standalone startup;
- [ ] Windows Release TTS;
- [ ] backup/restore;
- [ ] restart persistence;
- [ ] performance;
- [ ] regression suite.

If sufficiently mature, this may become a candidate for a wider beta.

---

# Release validation checklist

For every delivered version:

## Version and documentation

- [ ] Increment `pubspec.yaml` version/build.
- [ ] Refresh Alpha expiry according to the established policy.
- [ ] Update Alpha lifecycle tests.
- [ ] Update README where the current version/expiry is stated.
- [ ] Update CHANGELOG.
- [ ] Update relevant technical/user documentation.
- [ ] Verify package naming.

## Automated validation

- [ ] Run `dart format` on touched Dart files.
- [ ] Run focused tests.
- [ ] Run complete `flutter test`.
- [ ] Run `flutter analyze`.
- [ ] Run `python tools/validate_courses.py`.
- [ ] Run `python tools/validate_images.py`.
- [ ] Run `git diff --check`.
- [ ] Review `git diff`.
- [ ] Review `git status --short`.

Never describe a filtered test run as a passing full suite.

## Manual regression coverage

- [ ] Exercise preview and Round preview do not persist learner progress.
- [ ] Alpha expiry blocks learner routes without deleting learner or course data, while Course Editor previews remain usable.
- [ ] System TTS, recorded audio and hybrid fallback behave correctly when voices or recordings are unavailable.
- [ ] Course and media imports reject malformed, oversized and path-traversal inputs without partial registration.
- [ ] Destructive Course Editor actions require the established confirmations.
- [ ] Home, learner flows, Settings and Course Editor remain usable at narrow widths and enlarged system text without clipped primary actions.
- [ ] Windows, Android and Linux are smoke-tested on intended targets; iOS/macOS support is claimed only after macOS/Xcode testing, and Web remains experimental until native-file workflows are adapted.

## Windows Release validation

A successful build alone is not sufficient.

Verify at least:

- [ ] standalone startup from the complete Release directory;
- [ ] startup without Flutter or VS Code installed;
- [ ] Windows Sandbox behavior;
- [ ] Windows TTS in Release mode;
- [ ] installed voice detection;
- [ ] locale fallback;
- [ ] missing-voice handling;
- [ ] critical progress persistence;
- [ ] language XP persistence;
- [ ] learner-global Weekly XP persistence;
- [ ] per-course Weekly XP breakdown persistence;
- [ ] Course Editor startup;
- [ ] course import/opening;
- [ ] at least one playable Round;
- [ ] restart persistence;
- [ ] settings persistence;
- [ ] selected-course persistence.

## Packaging

- [ ] Windows release package uses `quisquislingo_windows_alpha_<buildnumber>`.
- [ ] Source package uses `quisquislingo_alpha_<buildnumber>_source`.
- [ ] Source archive contains project files directly at archive root.
- [ ] No extra wrapper directory.
- [ ] Keep the previous known-good release available for rollback until the new release is verified.
