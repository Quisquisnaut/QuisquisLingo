# QuisquisLingo agent instructions

## Purpose

These are persistent instructions for Codex when working on QuisquisLingo.

- Treat the current repository tree as the source of truth unless the user explicitly supplies a newer baseline.
- Do not rebuild work from older LingoGrow archives.
- Read `pubspec.yaml` for the current app version/build. Do not hardcode a permanent version assumption in this file.
- Preserve existing behavior outside the requested change.
- Everything not required by the current task is out of scope. Treat the requested scope as the permitted scope.
- Do not replace working features with stubs, simplified rewrites, broad refactors, or unrelated cleanup.
- Make the smallest change that correctly satisfies the request.
- If a requirement is ambiguous and the ambiguity could change behavior, persistence, compatibility, scoring, or user data, ask before choosing a design.
- Separate structural refactoring from behavior changes whenever practical.
- Do not implement future roadmap items merely because they are mentioned in documentation or architectural notes. Follow the user's explicit current task.

## Current release boundary

- `2.0.6+206` is the completed Phase 1 characterization-test release. It strengthens behavior-level coverage for Round completion/XP and Course Editor Guidebook generation without changing production behavior.
- `2.0.7+207` is the conservative display-rebranding release from LingoGrow to QuisquisLingo.
- Build 207 changes user-visible branding, user-facing filesystem paths and filenames, display-only window and descriptive metadata, and current documentation while preserving repository URLs, application/package/bundle IDs, executable names, SharedPreferences keys, serialization tokens, course namespaces, environment variables and internal symbols.
- `2.0.8+208` completes the technical rebrand of application-owned identifiers and update infrastructure without legacy LingoGrow compatibility machinery.
- `2.0.9+209` completes Phase 2A modularization by extracting Round completion orchestration into `LearningCompletionService`.
- `2.0.10+210` completes Modularization Phase 2B by extracting learning activity, streak, and study-day logic into `LearningActivityService` behind the existing `ProgressService` public facade.
- `2.0.11+211` adds the learner status bar while consuming the existing service boundaries rather than moving responsibilities back into `ProgressService` or UI screens.
- Future build 212 Streak Celebration, build 213 `XpCalculator` extraction, and build 214 XP formula changes are separate phases that require explicit user requests and must keep characterization tests green.

## Architecture and service boundaries

QuisquisLingo is a single-package Flutter application. Prefer incremental internal modularization rather than package-level fragmentation unless explicitly requested.

UI screens should primarily handle presentation and interaction. Business rules, persistence, scoring, and completion logic should remain independently testable outside the UI where practical.

### ProgressService

`ProgressService` remains the compatibility-facing progress service and currently owns or coordinates non-XP learner progress concerns, including where applicable:

- completed Rounds
- completed Topics
- laurels and perfect-completion state
- TTS-skipped perfect state
- Review history
- Duel state
- course reset behavior
- local leaderboard participation preference

`ProgressService` retains the public learning-activity facade and delegates its activity, streak, and study-day APIs to `LearningActivityService`.

Do not move unrelated responsibilities into or out of `ProgressService` during a narrowly scoped change.

Existing public `ProgressService` APIs may temporarily delegate to more specialized services to preserve screen and caller compatibility.

### LearningActivityService

`LearningActivityService` owns learning activity, streak, and study-day implementation, including:

- the activity-specific injected clock
- activity persistence key handling
- activity-specific language normalization
- date formatting and parsing
- language-scoped study-day reads
- profile-global study-day reads
- days-studied and streak calculations
- learning-activity registration

Preserve the existing `ProgressService` public facade, persistence keys and formats, clock semantics, and activity ordering unless an explicit behavior or migration request says otherwise. Keep completed Rounds, completed Topics, won Duels, Review history and timestamps, course reset, Guidebook state, leaderboard participation, completion orchestration, and XP outside `LearningActivityService`.

### XpService

`XpService` owns XP persistence and XP accounting, including where applicable:

- language XP totals
- learner-global Weekly XP
- per-course Weekly XP breakdowns
- current-week and previous-week XP state
- Sunday weekly rollover
- skipped-week handling
- last-week XP
- XP data used to derive the local leaderboard
- weekly-goal celebration state
- XP persistence validation and integer clamping

Weekly XP remains learner-global across all courses and languages.

A per-course Weekly XP breakdown is keyed by `courseId`.

Local leaderboard participation is not an XP-accounting concern. Keep the participation preference outside `XpService` unless a future explicit architectural change says otherwise.

Preserve exact existing `SharedPreferences` keys and stored formats during structural refactors unless an explicit migration is requested and reviewed.

### XP calculation

XP reward formulas are business logic and should not remain permanently embedded in UI screens.

When XP calculation is extracted or changed:

- Prefer a small pure `XpCalculator` or equivalent testable component.
- The calculator must not read or write `SharedPreferences`.
- The calculator must not depend on Flutter UI state.
- `XpService` persists/accounts for XP; it should not become a container for unrelated Round-completion orchestration.
- Screens should not duplicate XP formulas implemented elsewhere.
- Keep calculation, persistence, and completion orchestration as separate concerns.
- Add direct behavior-level tests for scoring formulas.

Do not introduce new XP rules during a structural extraction unless the user explicitly asks for scoring changes.

### Time-dependent behavior

Weekly rollover, streaks, activity timestamps, Review timestamps, and other time-sensitive logic must remain deterministically testable.

- Preserve injectable clock seams where they exist.
- Production defaults may use local `DateTime.now`.
- Tests should use controlled clocks rather than depending on the actual current date.
- Do not introduce direct `DateTime.now()` calls into logic that already has an injectable clock.

## Versioning and release hygiene

- Every delivered app update must increment the app version/build in `pubspec.yaml`.
- Every app-version update must also refresh the Alpha expiry date in `lib/services/alpha_lifecycle_service.dart`, its tests, README, and current documentation where the current expiry/version is stated.
- Do not accidentally carry forward the previous release's Alpha expiry.
- Unless the user explicitly changes the policy, preserve the project's current Alpha lifetime policy.
- Update `CHANGELOG.md` and current validation/release documentation for each delivered version when those files are part of the release process.
- Preserve existing source comments unless a comment has become factually wrong because of the requested change.
- Source ZIPs must contain `pubspec.yaml`, `lib/`, `assets/`, `test/`, `tools/`, and other project files directly at archive root. Never add an extra wrapper directory.
- Package naming:
  - release/package: `quisquislingo_alpha_<buildnumber>`
  - source folder/archive: `quisquislingo_alpha_<buildnumber>_source`
- Use the numeric build number without dots in package names.
- Keep the previous packaged release as a rollback copy until the new release has been tested successfully.

## Course Model v3 invariants

- Canonical course format is `formatVersion: 3`.
- Hierarchy: Course > Chapter > Topic > Guidebook + Rounds > Content/Exercise.
- Guidebooks belong to learning Topics. Chapters do not own Guidebooks.
- Topic Guidebook content may be used to propose or generate exercises or Rounds, but generated content requires preview/review and explicit approval before creation.
- A newly created custom course starts with 5 placeholder Chapters and 3 learning Topics per Chapter, with no automatic Rounds.
- A manually created Round starts with 3 editable dummy exercises.
- Preserve stable Item IDs and valid references.
- Canonical v3 text-match exports use `acceptedAnswers`; legacy `accepted` remains import-compatible.
- Imported/custom courses remain custom even when selected. Do not infer bundled/custom origin from title alone.

## Course identity and collision handling

- Every course has an immutable, globally unique `courseId`.
- New courses must receive their ID through the centralized course-ID generator, currently `Course.newCourseId()`.
- Never derive course identity only from language code, title, timestamp text, filename, or display name.
- A derived/forked course must receive a new `courseId`.
- A derived/forked course should preserve lineage through `parentCourseId` and `derivedFromVersion` where supported by the model.
- Importing a course with the same `courseId` means it represents the same course identity.
- Same-ID import handling must offer the established choices:
  - Replace/update
  - Separate copy
  - Cancel
- Separate copy must create a genuinely new `courseId`.
- A separate copy must not silently share course-owned progress with the original.
- Do not change course-ID collision behavior without updating the relevant technical Help/documentation and tests.

## Progress and access invariants

Course-owned state is keyed by `courseId`, including where applicable:

- completed Rounds
- Review state/history
- laurels
- Topic completion
- Duels
- Guidebook learner state
- course-specific progression
- course reset state

Language-scoped state remains language-scoped:

- language XP
- streak
- study days

Weekly XP rules:

- Weekly XP is learner-global across all courses and all languages.
- If a per-course Weekly XP breakdown is stored or displayed, key that breakdown by `courseId`.
- Do not redefine global Weekly XP as a per-language or per-course total.

Reset rules:

- `resetCourse(courseId)` clears only that course's course-owned progress.
- It must not erase language-wide XP already earned.
- It must not erase Weekly XP already earned.
- It must not erase another course's state.
- It must not reset unrelated learner data.
- After course progress is reset, a Round may again qualify for the normal first-completion XP rules if that is the established scoring behavior.

Chapter access rules:

- Chapter unlocks are earned by normal completion rules or a Language Duel win.
- `IDDQD Mode (you can walk through locks)` is stored per user and per course.
- IDDQD grants temporary access without changing genuine unlock state.
- While IDDQD is active, genuine progress and genuine unlocks must continue to be recorded.
- Lock icons always show genuine lock state.
- Never reset learner progress, XP, streaks, laurels, course selection, or user data as a side effect of an unrelated feature.

## Round XP compatibility rules

Until the user explicitly replaces the scoring system, preserve the established scoring behavior.

- Preserve the established first-pass scoring logic for non-perfect Rounds.
- Preserve the established 5 XP per first-pass-correct exercise unless the user explicitly changes the scoring system.
- Preserve the established behavior for first perfect completion.
- Preserve the established behavior for perfect repeats of already completed Rounds.
- Preserve reset-related scoring eligibility.
- Preserve existing Topic and Duel XP behavior unless explicitly changed.
- Do not introduce new completion bonuses, multipliers, penalties, or reward types implicitly.
- The finish UI should show the relevant potential/awarded XP clearly.
- Do not alter XP semantics during structural refactoring.
- Any deliberate scoring-system change must update direct scoring tests and relevant regression tests.

When a new XP system is explicitly introduced, update this section to describe the new authoritative rules rather than leaving obsolete scoring rules in `AGENTS.md`.

## Course Editor invariants

- Keep exercise type names friendly and concrete in the editor. Do not replace them with abstract/internal taxonomy.
- Guidebooks belong to Topics, not Chapters.
- Topic Guidebook content may be used to generate draft exercises/Rounds.
- Guidebook-generated exercises/Rounds must still be reviewed and explicitly approved before creation.
- Course Info contributor roles include `Illustrator`.
- Preserve existing contributor roles unless explicitly changed.
- User-created courses may be deleted only through the established double-confirmation flow.
- Remember the last selected course across app restarts.
- The Course Editor main page should retain access to Help.
- Chapter numbering should appear before the Chapter title where the established UI uses numbered Chapters.

## Exercise-content rules

- Word/letter block exercises may have 0, 1, or at most 2 distractor blocks.
- Prefer fewer distractors in early Rounds of a Topic and more in later Rounds.
- A hint must not simply reveal the solution.
- Do not change content-generation rules unless explicitly requested.

## Settings invariants

- Keep the switch label exactly:
  `IDDQD Mode (you can walk through locks)`
- Keep its existing descriptive text unchanged unless the user explicitly asks to edit it.

## Security and robustness

- Course import is data-only. Never execute imported course content.
- Keep existing import size/format validation and Course Audit gates unless a deliberate migration requires a reviewed change.
- The GitHub update checker may check official releases, but must not automatically download, install, or execute software.
- Avoid adding network dependencies for learner/course functionality. QuisquisLingo remains offline-first.
- Do not weaken validation merely to make an import pass.
- Do not silently discard unknown or unsupported course data without a deliberate compatibility decision.

## Change discipline

- Inspect the relevant code, call sites, tests, persistence keys, and documentation before editing.
- Before removing a symbol that appears unused, search for indirect, semantic, compatibility, or UI dependencies.
- Do not add unrelated refactors, renames, UI changes, formatting changes, or cleanup.
- Discovering an unrelated issue does not expand the task scope. Report it separately instead of fixing it unless the user explicitly adds it to the task.
- Do not replace or rewrite an entire file when a smaller targeted change is sufficient.
- Never suppress analyzer findings merely to obtain a clean result.
- Do not perform broad legacy lint cleanup unless explicitly requested.
- Do not change working app behavior merely to make a brittle regression test pass.
- If app behavior is correct and a test is coupled to source formatting, fix the test so it checks behavior or structure robustly.
- Prefer behavior-level tests over source-text tests.
- If a source-structure regression test is necessary, make it tolerant of LF/CRLF and harmless Dart formatting while preserving what it actually verifies.
- Avoid waits or test patterns that can hang indefinitely.
- Characterize important existing behavior before moving or rewriting it.
- When extracting an existing responsibility, move one authoritative implementation rather than creating two independent copies.
- Preserve compatibility through temporary delegation when that reduces the risk of a large caller migration.

## Git and repository discipline

- Do not commit unless the user explicitly asks for a commit.
- Do not push unless the user explicitly asks for a push.
- Do not stage unrelated files.
- Do not include unrelated generated files in a commit.
- Do not delete untracked user files merely because they are outside the requested scope.
- Do not use destructive Git commands such as broad `reset`, `clean`, `checkout`, or `restore` against user work without explicit approval and a clear reason.
- Before reverting a suspicious file, determine whether it contains genuine user changes.
- After Flutter commands, generated platform registrant files may appear modified because of metadata or line-ending normalization. Verify their actual content before treating them as code changes.
- LF/CRLF warnings alone are not evidence of a functional code change.
- If a generated file is byte-identical to `HEAD`, do not include it as a meaningful project change.
- Review `git status --short` and the final diff before reporting completion.
- Verify that every changed line is necessary for the requested task. If a changed line cannot be justified by the task, revert that change before reporting completion.

Do not modify Codex's global approval policy, sandbox policy, or user-level command rules as part of normal repository work unless the user explicitly requests that configuration change.

## Validation before delivery

Run, when the environment provides Flutter/Dart:

```bash
flutter pub get
flutter analyze
flutter test
