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
- `2.0.12+212` extracts the existing XP formulas into a pure `XpCalculator` without changing behavior.
- `2.0.13+213` stabilizes the authoritative Round, Review, Topic and Duel XP rules and makes displayed and persisted awards share one calculation result.
- `2.0.14+214` communicates first Topic completion in the Round XP breakdown, unifies guarded text-entry submission, promotes Leaderboard navigation to Home, and applies narrow status-bar and desktop-resize refinements.
- `2.0.15+215` removes Chapter through a clean Course Model v4 cut, introduces the unified Course → Lesson → Round learner page, and makes Duel Topic-scoped with actual-pool availability.
- `2.0.16+216` corrects the Welcome-dialog contrast, uses the selected-course flag as the learner background, places the protected learner strip above the unchanged status bar, removes the redundant Browse All Lessons button while retaining the Lesson selector, and preserves the established recent-course presentation.
- `2.0.17+217` keeps the approved fixed Learner Header and bottom controls while making the central learner content a continuous lazy flow from the selected Lesson through the remaining Lessons in course order, with direct selector jumps, stable scroll-driven selector synchronization and unchanged lock/Duel rules.
- `2.0.18+218` replaces the separate learner User Bar and Status Bar with one theme-aware unified Top Bar ordered as compact Language/Course flag selector, one-line Streak, vertical Laurel progress, vertical Weekly XP, clickable cat mark and Settings; learner-profile management moves to Settings, the cat opens App Info, and the Lesson selector, full-size course picker, continuous Lesson flow and bottom controls remain preserved.
- `2.0.19+219` redesigns the central learner Round path with smaller deterministic left/right cards, intermittent opposite-side QuisquisLingo mascots in a stable course-specific order, a following connector and persisted completed-Round icon accents while preserving surrounding learner behavior.
- `2.0.20+220` centralizes local learner identity, avatar, profile management and Gamification behind Profile, simplifies the learner bottom area to Profile, Review and Course Info, moves Buy a coffee into Course Info, and adds non-destructive local logout.
- `2.0.21+221` refines contained course-flag backgrounds, light/dark veils, Guidebook-integrated mixed-weight Lesson identities, 244 px maximum Round cards, a narrower 70%-opaque GuideBook, 70%-opaque Duel, roomier Duel-to-next-Lesson transitions, a 55%-opaque main connector with subtle theme-aware contrast support, 10%-opaque mascot containers and subtly arched Laurel artwork; keeps fixed learner-bottom controls with a persisted per-profile Default/Light/Dark utility; and adds session-long view-only three-tap previews for specifically activated locked Lessons without altering progression or persistence.
- `2.0.22+222` makes opaque UUIDv4 learner IDs authoritative through a clean persistence cut and backup-v2 restore/copy workflow; adds a separately licensed 266-entity world-flags manifest; and adds the five-tap Settings Flag Game with four cumulative pools, searchable read-only references and ID-keyed device-local scorecards with best-result dates, without changing course flags or learner progression.
- `2.0.23+223` makes Lesson canonical through a clean Course Model v5 cut; adds consecutive-order Section navigation and a controlled 14-icon 256 px Lesson theme library; moves Round management to a draft-preserving editor subpage; standardizes the GuideBook icon/action layout; and moves learner/course-scoped IDDQD into the fixed learner controls while preserving progression, scoring, Duel, Review, learner identity and backup-v2 behavior.
- `2.0.24+224` rationalizes exercises behind Select, Input, Arrange, Match and Presentation models; adds grouped presets, Type the translation, contextual comprehension, linked answer variants and diagnostic Correct feedback; expands scoped Audit with Info guidance; adds explicit Draft/Published authoring, unsaved-change guards, Course-level Lesson numbering/fallback styles and portable managed custom Lesson icons; completes custom-Course duplication/audit and Buy a Coffee metadata; retains Course Model v5, progression, XP, Review, Duel, identity and existing stable IDs.
- `2.0.25+22503` is the Build 225.03 correction candidate. It preserves Build 225.02 while making the authoritative nine-course bundled registry drive and reconcile real UI discovery, and preserving full v6 Content metadata when successful Exercise saves reconcile Round, Lesson and Course baselines. Unrelated planned features remain deferred.
- `2.0.25+22504` replaces nested Course Editor persistence with one course-level working-copy transaction, verified version backups, explicit origin/provenance and a single top-level confirm-or-cancel boundary. Build 225.03 remains its immutable parent.

- `2.0.26+22601` makes bundled/external official courses locally read-only and introduces explicitly licensed independent custom forks with permanent original authorship/provenance and a separate fork creator. The pushed `ede21f813a235e8455d2691da4cf3bb43162a39a` Build 225.04 plus 226.00 documentation correction is its immutable parent. Later Build 226 tranches remain deferred.
- `2.0.26+22602` adds unsaved Exercise Preview, guarded Previous/Next navigation, breadcrumbs, working-copy Move/Copy destinations, shared field help, Draft indicators/counts and the shared Audit Code Registry. Missing Reading-comprehension guidance is removed without changing remaining severities. The pushed `45cf258d707c89d512f7663d9f2fa317adbe5ef0` is its immutable parent; 226.03 and later remain deferred.
- `2.0.26+226023` completes the 226.02 workflow and diagnostics corrections: shared Help and device-local internal-ID controls throughout Course Manager and its editor hierarchy, hierarchy-wide red/green Audit status with one independent blue Draft badge, explicit AI-generated sample labels, observable Lesson fallback-icon selection and explicit Version/Phase/revision display. Course Model v6, persistence and 226.01 boundaries remain unchanged, and 226.03 remains deferred.
- `2.0.26+226024` is Phase 226.02 revision 4: actual Course titles throughout the learner selector; Lessons-page fallback lesson number icons labeled Theme-colored circle and Four-color circle with unchanged stored behaviors; current canonical Audit findings and shared live ancestor refresh; passive Lesson/Round/Exercise IDs after actionable lines; and explicit GuideBook Draft/Audit status inherited by Lesson and Lessons independently of Rounds. The Audit registry remains at 103 rules, Alpha expiry remains `2026-10-06 23:59:59` local time, and 226.03, GuideBook roadmap, Custom Exercise Templates and Napoletano remain deferred.
- `2.0.26+226030` is Phase 226.03 revision 0: authoritative 128-variant answer expansion and independent materialization, deterministic similarity-ranked translation feedback, Unicode-first-grapheme Type the missing word, and portable Image to text/Text to image Recognize characters on the existing Input/Select models. Course Model v6 and existing normalization/correctness remain unchanged. Alpha expiry remains `2026-10-06 23:59:59` local time. The known revision-4 Lock-row and GuideBook-ID omissions remain outside this tranche; 226.04, Custom Exercise Templates, future GuideBook work and Napoletano remain deferred.
- `2.0.26+226040` is Phase 226.04 revision 0: one-time new-course Lesson/Round scaffolding, reusable Section names, consistent Lesson naming, optional Duel and GuideBook paths, authoritative World Flags selection, the upper Lessons Lock icon and passive GuideBook Internal IDs. Course Model remains v6 with explicit backward-compatible defaults; the Audit registry remains at 103 rules. Alpha expiry remains `2026-10-06 23:59:59` local time. Custom Exercise Templates, Napoletano, future GuideBook content and release 227 remain deferred.
- `2.0.26+226042` is Phase 226.04 revision 2: one theme-colored fallback Lesson-number icon, dedicated Course Import navigation and learner-selector Editor actions, shared single-sample Round scaffolding, Final Duel presentation, ordered optional GuideBook Insights, emphasized Publish actions and explicit locked-Lesson guidance. Course Model remains v6 and the Audit Registry remains at 102 rules.
- `2.0.27+227010` is Phase 227.01 revision 0: Learner Panel controls audit and characterization, plus the explicitly requested clean cut to per-learner × Course Flag Background initialized Off. Old shared Flag Background values remain untouched and unread. Small / Off / Extended rendering, Default / Light / Dark Theme, Off / On IDDQD, progression and Course Model v6 remain preserved. The new-version 30-day Alpha expiry is `2026-10-07 23:59:59` local time. Later 227 features remain deferred; see `docs/227_01_VALIDATION.md`.
- `2.0.27+227020` is Phase 227.02 revision 0: Flag Background adds Tinted and Soft Inspired after Small / Off / Extended through one deterministic, theme-adaptive color derivation path for World Flag SVGs, portable custom raster flags and built-in flag colors. Persistence remains per learner × Course, defaults Off and ignores the untouched obsolete shared value. Theme, IDDQD, progression, XP, Course Model v6, course JSON and checksums remain unchanged. Alpha expiry remains `2026-10-07 23:59:59` local time; see `docs/227_02_VALIDATION.md`.
- `2.0.27+227021` is Phase 227.02 revision 1: the learner-facing Soft Inspired name becomes Inspired while its `soft_inspired` persisted value remains compatible, and its static surface now exposes up to three broader, stronger flag-derived color zones. Tinted retains its restrained single-color treatment. Persistence, Theme, IDDQD, progression, XP, Course Model v6, course JSON, checksums and the `2026-10-07 23:59:59` Alpha expiry remain unchanged; see `docs/227_02_VALIDATION.md`.
- `2.0.27+227030` is Phase 227.03 revision 0: the existing learner IDDQD control explains Off as normal progression locks and On as access through locks with genuine progression preserved. Genuinely locked Lesson sections keep their lock state and show `Accessible with IDDQD` while the established Lesson gate exposes only the published GuideBook, Rounds and eligible Duel. IDDQD remains Off / On per learner × Course and initialized Off; toggling alone changes no progression or XP, while actual study records normal results. Flag Background, Theme, Course Model v6, course JSON, checksums and the `2026-10-07 23:59:59` Alpha expiry remain unchanged; see `docs/227_03_VALIDATION.md`.
- `2.0.27+227040` is Phase 227.04 revision 0 and closes QQL 227. IDDQD adds View Only after the unchanged Off/On modes: it bypasses the established Lesson lock gate while Round, Review and Duel interaction writes no learner progress, XP, activity, Laurel, Review or Duel state; the selected mode persists per learner × Course. Theme is Light / Dark / System / Day/Night per learner, with compatible `default` System storage and local 07:00/19:00 live Day/Night boundaries. The bottom controls remain compact without permanent IDDQD helper text. Flag Background, Course Model v6, Course JSON, checksums and the `2026-10-07 23:59:59` Alpha expiry remain unchanged; see `docs/227_04_VALIDATION.md`.
- `2.0.28+2281` is QQL 228 revision 1. It retains the completed Settings/Profile, Statistics, Debug/logging and clean per-learner Audio Settings release. Test Voice speaks only nonblank user-entered text while retaining selected-Course language resolution, and listening audio prepared behind `Before you start` remains silent until Continue makes it active. Actual switches to a different Course show a restrained two-second entry fade, started only after the Course Selector closes and the destination learner state reloads, when Animations are enabled and reduced motion is absent: an explicit valid Course JSON flag remains authoritative, while a Course with no declared flag uses the established course-code fallback; invalid declared flag data still produces no entry overlay. Show one-time notices again is an action rather than a switch. Update checking continues to use GitHub Releases for packaged applications and accurately distinguishes the published source repository from the absence of a packaged GitHub Release. Authoring Preview remains setting-independent and no-write. Course Model v6, course JSON, persistence, checksums, XP and progression remain unchanged. The QQL 228 Alpha expiry remains `2026-10-08 23:59:59` local time; see `docs/228_VALIDATION.md`.
- `2.0.29+229` is QQL Build 229, Revision 0. Course Manager consistently exposes read-only inspection, licensed Fork, Audit and supported Export for official Courses, and Edit, independent Duplicate, Audit, Export and manager-only Delete for custom Courses. Eligible official inspection retains Fork; custom Course Editor adds Duplicate without Delete or another top-area Audit. Every Course Selector row provides Course Info and per-learner × Course Hide, with active-course protection and reversible `Hidden courses (n)` management. The Learner Panel adds Expanded / Collapse completed / Focused Lesson display per learner × Course, using authoritative completion, Lesson unlock, IDDQD access and existing last-visited behavior without Section collapsing. Course Model v6, Course JSON, checksums, identity, provenance, progression, XP, activity and authoring data remain unchanged. The Alpha expiry is `2026-10-09 23:59:59` local time; see `docs/229_VALIDATION.md`.
- `2.0.29+2291` is QQL Build 229, Revision 1. It retains revision-0 action consistency, learner-specific Hide/Unhide and Expanded / Collapse completed / Focused Lesson display. Course Model v7 requires explicit stable Creator and individual/Team Owner identities for every custom course. The centralized access policy grants full authoring and Duplicate rights to an individual Owner or every member of an owning Team regardless of license; outsiders remain read-only and can Fork only when derivatives are allowed. Credits never grant authorization. Team Manager provides offline stable-ID membership and multiple Leads with a mandatory last-Lead invariant. Bundled, owned custom, Team-owned and outsider custom courses use the same capability-driven Editor hierarchy while official originals remain immutable. The Alpha expiry remains `2026-10-09 23:59:59` local time; see `docs/229_VALIDATION.md`.
- `2.0.29+2292` is QQL 229 Build 229 revision 2. It corrects version wording, custom-course language/TTS resolution, Course Info language/date/Team/model presentation, shared Course flag selection, duplicate Manager/Editor controls, Team/User Internal IDs and the final-Lead wording while making the developer unlock an ordinary per-profile setting. Revision-1 ownership, Team authorization and Duplicate/Fork clean-state behavior remain authoritative. Course Model stays v7 and the Alpha expiry remains `2026-10-09 23:59:59` local time; see `docs/229_VALIDATION.md`.
- `2.0.29+2293` is QQL Build 229, Revision 3. Ordinary Team members may leave their Team through a confirmed self-service action without altering Team-owned courses or learner data; authorization updates through current membership while Team Leads remain governed by the last-Lead invariant. Temporary Sample guidance lives in Course Info rather than the main Course Editor, with metadata/export preservation. Course Manager adds an independent blue Unpublished badge alongside the existing Draft badge. Revision-2 language, flag, metadata, Internal-ID and per-user unlock corrections remain authoritative. Course Model stays v7 and the Alpha expiry remains `2026-10-09 23:59:59` local time; see `docs/229_VALIDATION.md`.
- `2.0.30+230` is QQL Build 230, Revision 0. It is a robustness release with targeted, evidence-driven modularization and no new feature family: learner completion rejects duplicate dispatch, Audio Exercises Off is authoritative through one effective Duel-eligibility calculation shared by Home and Duel entry, learner and Course replacement persistence gains verified rollback boundaries, Course identity/ownership deletion invariants are protected, diagnostic logs are bounded, update and multilingual audio boundaries are corrected, and the analyzer baseline is clean. Course Model stays v7; course JSON, checksums, scoring, progression, Review and QQL 229 behavior remain compatible. The Alpha expiry is `2026-10-11 23:59:59` local time; see `docs/230_VALIDATION.md`.
- `2.0.31+231` is QQL Build 231, Revision 0. It adds the authoritative 22-preset searchable-text inventory and scoped Course Editor Search; centralizes Locked / View unlocked / Edit unlocked at the Course Editor root without granting authorization; adds the per-user × Course View notice; and normalizes Lesson/Round top icons, Rename and Preview placement. View remains no-write while preserving Search, Help, IDs, Preview and Audit. Course Model stays v7; course JSON/checksums, ownership, progression, XP, Review, Duel and QQL 230 robustness behavior remain compatible. The Alpha expiry is `2026-10-12 23:59:59` local time; see `docs/231_VALIDATION.md`.
- `2.0.31+2311` is QQL Build 231.1, Revision 1. It replaces the root access modes with Locked / View only / Inspection mode / Edit; makes View only the ordinary 22-preset Exercise form with all mutation paths disabled; makes the former technical representation explicit Inspection mode; and adds the local Exercise Inspection presentation toggle without changing authorization or dirty state. Search opens the state-appropriate presentation and remains unavailable while Locked. The Create Duels wording is corrected without behavior change. Course Model stays v7; the Alpha expiry is `2026-10-13 23:59:59` local time; see `docs/231_VALIDATION.md`.
- `2.0.32+232` is QQL Build 232, Revision 0. Review is a dedicated automatic page for the active Course, reachable from the Learner Panel bottom action and only the Current course row menu. It selects genuine completed-Round records by descending errors and oldest latest attempt on ties, refreshes the reviewed record through ordinary completion, excludes completed Round IDs only for the current Review visit, and ends with Next Review or Back to course. Published GuideBook Vocabulary is integrated before the Round and requested reinforcement once after it, with immediate versioned learner × Course × Lesson × entry memory and an isolated Reset Word List action. Review ignores IDDQD View Only; vocabulary adds no independent XP or progression. Course Model stays v7, course JSON/checksums are unchanged, and the Alpha expiry remains `2026-10-13 23:59:59` local time; see `docs/232_VALIDATION.md`.
- `2.0.33+233030` is QQL Phase 233.3, revision 0, and closes the three planned QQL 233 phases. Phase 233.1 fixes generic Linux release-package selection while preserving Windows and GitHub Releases policy. Phase 233.2 adds the two-step Learner profile/avatar flow, optional display-only Discord handle, new-profile-only random skin/hair initialization and the authoritative ten-level Status-derived vivid T-shirt presentation. Phase 233.3 makes every Course Owner an individual, separates optional Team assignment and Team governance, adds warning-gated Owner controls and experimental-model Help, corrects identity/Internal-ID presentation, and confines the learner status bar to the Learner Panel. Course Model v8 is a clean cut; older custom namespaces remain untouched and unread. The Alpha expiry is `2026-10-14 23:59:59` local time; see `docs/233_VALIDATION.md`.
- Do not read, apply, migrate or automatically convert Build 225 official local overrides. Leave stored remnants untouched. Official history contains publisher sources only. QQL 233.3 uses the clean Course Model v8 custom-course namespace; older custom formats and namespaces remain untouched and unsupported. An explicit derivatives-allowed policy is required for any outsider or official fork.

## Architecture and service boundaries

QuisquisLingo is a single-package Flutter application. Prefer incremental internal modularization rather than package-level fragmentation unless explicitly requested.

UI screens should primarily handle presentation and interaction. Business rules, persistence, scoring, and completion logic should remain independently testable outside the UI where practical.

### ProgressService

`ProgressService` remains the compatibility-facing progress service and currently owns or coordinates non-XP learner progress concerns, including where applicable:

- completed Rounds
- completed Lessons
- laurels and perfect-completion state
- TTS-skipped perfect state
- Review history
- Duel state
- course reset behavior
- local leaderboard participation preference

`ProgressService` retains the public learning-activity facade and delegates its activity, streak, and study-day APIs to `LearningActivityService`.

Do not move unrelated responsibilities into or out of `ProgressService` during a narrowly scoped change.

Existing public `ProgressService` APIs may temporarily delegate to more specialized services to preserve screen and caller compatibility.

### Review vocabulary reinforcement

`ProgressService.getRecentRounds` is authoritative for Review ordering: descending latest-attempt errors, then oldest latest-attempt timestamp. `ReviewRoundResolver` resolves those records against the active Course and applies only the current Review page's excluded Round IDs. Do not duplicate sorting in widgets.

`VocabularyReviewService` owns learner-safe GuideBook vocabulary parsing and learner × Course × Lesson × entry state. It consumes only published `kind: vocabulary` Content from enabled GuideBooks, preserves authored occurrences/order, uses stable Content IDs plus deterministic duplicate occurrence identity and fingerprints the displayed prompt/answer. State stores only fingerprint, `encountered` and `needsReinforcement`; reset removes only the active learner's selected-Course vocabulary document. Keep this state out of authored Course JSON, `ProgressService`, `LearningActivityService` and `XpService`.

Vocabulary cards never independently award XP or alter completion, activity, streak, Laurel, Duel, unlocking or Review ordering. Review must remain independent of learner IDDQD mode and must operate through ordinary Round completion for genuinely completed Review records.

### LearningActivityService

`LearningActivityService` owns learning activity, streak, and study-day implementation, including:

- the activity-specific injected clock
- activity persistence key handling
- activity-specific language normalization
- date formatting and parsing
- language-scoped study-day reads
- profile-global study-day reads
- days-studied and streak calculations
- read-only total/per-language Statistics projections, including historical maximum streak
- learning-activity registration

Preserve the existing `ProgressService` public facade, persistence keys and formats, clock semantics, and activity ordering unless an explicit behavior or migration request says otherwise. Keep completed Rounds, completed Lessons, won Duels, Review history and timestamps, course reset, Guidebook state, leaderboard participation, completion orchestration, and XP outside `LearningActivityService`.

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
  - Windows release/package: `quisquislingo_windows_alpha_<buildnumber>`
  - Linux release/package: `quisquislingo_linux_alpha_<buildnumber>`
  - source folder/archive: `quisquislingo_alpha_<buildnumber>_source`
- Use the numeric build number without dots in package names.
- Keep the previous packaged release as a rollback copy until the new release has been tested successfully.

## Course Model v8 invariants

- Canonical course format is `formatVersion: 8`.
- Hierarchy: Course > Lesson > GuideBook + Rounds + Duel > Content/Exercise.
- Chapter is not part of the production model, learner navigation, editor or persistence. Chapter-based course formats are unsupported and are not read, migrated or converted.
- Lesson is canonical in the model, JSON, services, persistence, editor and learner UI. Do not add Topic compatibility aliases or v4 parsing fallbacks.
- GuideBooks and Duels belong to Lessons.
- Lesson Guidebook content may be used to propose or generate exercises or Rounds, but generated content requires preview/review and explicit approval before creation.
- New Course asks for `Number of Lessons` (default 3, whole numbers 1–100) and `Rounds per Lesson` (default 1, whole numbers 1–20). It atomically creates the requested Lessons and Rounds with fresh stable IDs and exactly one Draft How do you say? sample Exercise in each scaffolded Round. Samples use source/learning-language-labelled placeholders and the literal Wrong Answer distractor. These limits apply only to initial scaffolding; the counts are not settings, and they impose no Course Model, import or later-editing limits.
- A manually created Round starts with the same single Draft How do you say? sample Exercise used by New Course scaffolding.
- New Lessons and manually created Rounds may carry the optional `provisionalDraft` marker retained from v6. Ready marked parents reconcile to non-Draft through canonical authoring changes without redundant parent saves. Explicit Save Draft clears this eligibility; unmarked Drafts, intentional copies/forks and imports converted to Draft remain Draft until explicitly saved. Course delivery stays an independent explicit choice.
- Round `visualType` is one of `listening`, `story`, `generic` or `test` and is independent of exercise type.
- A Lesson should normally contain at least 6 Rounds, often roughly 48 exercises, but this is guidance only and never a validity or Duel-availability rule.
- Duel availability is calculated at runtime from the actual Lesson-local pool after applying the established structural rules, the active learner's Audio Exercises setting, and runtime audio availability. Audio Exercises Off is authoritative. Home and Duel entry must consume the same `DuelEligibilityService` effective result; fewer than 25 effective eligible exercises makes the Duel unavailable without duplicating questions or changing gameplay rules.
- Preserve stable Item IDs and valid references.
- Optional `section` and `sectionName` are presentational Lesson metadata only. Section has no ID, progress, unlock, XP, Duel, Guidebook, Review or navigation state, and consecutive grouping/relative numbering derive from Lesson order.
- Optional `themeIconAsset` must reference an approved 256 × 256 transparent PNG under `assets/lesson_icons/`; JSON stores only the asset path.
- Canonical v8 text-match exports use `acceptedAnswers`; the legacy `accepted` field is rejected.
- Lesson, Round and Exercise JSON requires a canonical UTC `updatedAt` timestamp. Bundled timestamps are deterministic; authoring timestamps come from the injected/current authoring clock.
- Build the translation serializes one or more literal answers as `evaluation.correctOrders`, each with answer text and stable ordered Item IDs. The legacy single `correctOrder` field is rejected without adaptation.
- Imported/custom courses remain custom even when selected. Do not infer bundled/custom origin from title alone.

## Course ownership, license and Teams

- Every v8 custom course requires `creatorProfileId` and `ownership`. Ownership is exactly one stable individual profile ID. Optional `assignedTeamId` separately grants Team management access. Official courses must not declare local ownership or Team assignment.
- Creator is immutable provenance. The individual Owner controls ownership transfer and Team assignment. Author, contributors, illustrators and all other visible credits are descriptive only and never grant authorization.
- The individual Owner and every member of an assigned Team can edit and Duplicate the original regardless of license. Only the Owner may transfer ownership or assign/revoke a Team. Team Leader status governs Team administration only.
- An outsider cannot edit or Duplicate another Owner's original. They may Fork only when derivative works are allowed. A permissive license never grants mutation of the original.
- Teams are device-local user-management data keyed by stable Team and opaque profile IDs. A Team has one or more Team Leaders; no operation may leave it with zero Team Leaders. Renaming a Team does not change a Course assignment. Team governance is independent from Course ownership.
- Duplicate is restricted to users already authorized to edit and preserves individual ownership plus optional Team assignment. Fork is an outsider derivative operation, preserves source provenance and credits, creates fresh IDs, and receives explicit local individual ownership without automatic Team assignment.
- No legacy custom-course ownership or Team-assignment inference or migration is permitted. Do not use visible names, Discord handles, credits, filenames or titles as fallback identity.

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
- Lesson completion
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

Lesson access rules:

- The first Lesson is unlocked. Each later Lesson unlocks when the immediately preceding Lesson is completed or its Lesson-scoped Duel is won.
- `IDDQD Mode (you can walk through locks)` is stored per user and per course.
- IDDQD On and View Only grant temporary access without changing genuine unlock state.
- IDDQD On records genuine study progress and unlocks normally. View Only records no learner progress, rewards, activity, Review or Duel state.
- Lock icons always show genuine lock state.
- Never reset learner progress, XP, streaks, laurels, course selection, or user data as a side effect of an unrelated feature.

## Round XP compatibility rules

Until the user explicitly replaces the scoring system, preserve the build-213 scoring behavior.

- A completed Round awards 5 XP per first-attempt-correct evaluable exercise on first completion, or 2 XP on repeats and in Review.
- Every zero-error completed Round receives a repeatable 5 XP perfect bonus.
- The first Laurel for a Round receives a one-time 25 XP bonus, including when first earned on a repeat or in Review.
- Flashcard and informational/guide content awards no base XP, counts as neither correct nor erroneous, and does not block perfect completion or Laurel eligibility.
- An incomplete or abandoned Round awards no XP or completion bonuses.
- First Lesson completion awards 25 XP once; Lesson completion is independent of Duel victory.
- A Duel awards 50 XP on its first victory and 10 XP on every later victory; Duel victory does not complete the Lesson.
- Preserve reset-related scoring eligibility.
- Do not introduce new completion bonuses, multipliers, penalties, or reward types implicitly.
- The completion UI must show the actual persisted XP breakdown, never theoretical potential XP.
- Do not alter XP semantics during structural refactoring.
- Any deliberate scoring-system change must update direct scoring tests and relevant regression tests.

When a new XP system is explicitly introduced, update this section to describe the new authoritative rules rather than leaving obsolete scoring rules in `AGENTS.md`.

## Course Editor invariants

- Keep exercise type names friendly and concrete in the editor. Do not replace them with abstract/internal taxonomy.
- GuideBooks belong to Lessons.
- Lesson Guidebook content may be used to generate draft exercises/Rounds.
- Guidebook-generated exercises/Rounds must still be reviewed and explicitly approved before creation.
- Course Info contributor roles include `Illustrator`.
- Preserve existing contributor roles unless explicitly changed.
- User-created courses may be deleted only through the established double-confirmation flow.
- Remember the last selected course across app restarts.
- The Course Editor main page should retain access to Help.

## Exercise-content rules

- Word/letter block exercises may have 0, 1, or at most 2 distractor blocks.
- Prefer fewer distractors in early Rounds of a Lesson and more in later Rounds.
- A hint must not simply reveal the solution.
- Do not change content-generation rules unless explicitly requested.

## Settings invariants

- Learner Flag Background is Small / Off / Extended / Tinted / Inspired, per opaque learner ID × immutable Course ID, initialized Off. Inspired retains the `soft_inspired` storage value introduced in 227.02 revision 0. Preserve the clean cut: do not read, migrate or convert the old shared per-learner value. IDDQD is Off / On / View Only per learner × Course, initialized Off. Its compact control uses tooltip and accessibility explanations without permanent helper text. A genuinely locked Lesson keeps its lock and shows `Accessible with IDDQD` for On or `Preview with IDDQD` for View Only. Theme is Light / Dark / System / Day/Night per learner across Courses; compatible `default` storage displays as System, and Day/Night uses local 07:00/19:00 boundaries.
- Course Selector Hide is a per opaque learner ID × immutable Course ID visibility preference. It initializes visible, cannot hide the active Course, and must never delete/uninstall a Course or change Course JSON, metadata, identity, learner state or authoring data. Lesson display is Expanded / Collapse completed / Focused per learner × Course and initializes Expanded. It operates only on Lesson path visibility, uses authoritative completion/unlock plus IDDQD access, preserves current/last-visited Lesson behavior and never collapses Sections.
- Settings order is Profile, App Info, Audio Settings, Do Not Disturb, Debug, Version and Build, Update. Profile order is Avatar, Learner profiles, Gamification, Statistics, User Data, then Log out. Course Manager is opened from the learner Course Selector.
- Audio Settings is a clean per-learner boundary across Courses. Enable Audio Exercises uses `audio_exercises_enabled` and initializes Off; Off removes audio exercises from effective Round and Duel pools and cannot be bypassed by Duel. Text-to-speech uses `tts_enabled` and initializes Off; TTS voice uses `tts_voice_preference` and initializes System. All three keys live only below the active opaque learner prefix. Do not read, migrate, convert or delete the previous device-level `tts_enabled` / `tts_voice_preference`, device-level `skip_tts_exercises`, or per-profile negative `skip_all_audio_exercises` values. Audio Settings contains Enable Audio Exercises, Text-to-speech and the TTS voice selector with Test Voice in that order. Authoring Preview ignores learner Audio Settings and remains no-write.
- Preparing the first learner exercise may resolve its audio eligibility while `Before you start` remains visible, but TTS or recorded playback must not start until Continue makes the exercise active. Rounds without an introduction, Duel audio and Editor Preview retain their established timing.

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

## Test execution efficiency

- During implementation, run the smallest relevant focused tests for rapid feedback.
- Once the implementation is final, run the analyzer and the complete Flutter test suite exactly once on the final working tree.
- Do not rerun focused test groups solely for reporting when they have already passed and are included in the complete suite.
- Continue running validators or checks not included in the Flutter suite.
- If source or test files change after the complete suite, rerun the affected focused tests and then rerun the complete suite before committing.
- A failed full-suite test may be rerun in isolation for diagnosis.

## Workflow efficiency

### Repository text inspection on Windows

- Use `rg` as the primary tool for locating files, searching text and reading relevant sections of repository text files.
- Do not use PowerShell `Get-Content` in this repository. It has repeatedly hung even on small regular Markdown files.
- Do not use `Get-Content -Wait`.
- Use targeted `rg -n` searches instead of dumping entire large files.
- When comparison with Git is sufficient, prefer `git diff`, `git show`, `git status` and `git ls-files`.
- If `rg` is unexpectedly unavailable, open a fresh shell once to refresh `PATH`. If it remains unavailable, use `Select-String` or `[System.IO.File]::ReadLines(...)`. Do not fall back to `Get-Content`.
- Do not install or reinstall command-line tools during a task unless the user explicitly requests it.

### Bounded command waiting

- Match the waiting period to the command type.
- Repository metadata and text-inspection commands such as `git status`, `git diff`, `rg`, `Select-String` and file metadata reads should normally respond quickly.
- If a read-only inspection command produces no output or completion for 15 seconds, interrupt it and use a different inspection method.
- Do not retry the identical command after it hangs.
- Do not wait silently for several minutes on a normally immediate command.
- Long-running analyzers, builds, validators and test suites may continue while they are producing progress or consuming resources normally.
- Run long commands with bounded output-yield intervals so control returns at least every 30 to 60 seconds.
- When a long command remains active, poll the existing process instead of starting duplicate commands.
- Provide a concise progress update at least once per minute during a long-running command.
- If a long command produces no progress, inspect its process state and distinguish a normal quiet phase from a real hang before terminating it.
- Never classify a generic terminal read failure as a Flutter SDK lock, repository deadlock or test deadlock without direct evidence.
- After interrupting a hung command, report the exact command, elapsed time and replacement method, then continue the task.

### Worktree policy

- For ordinary QQL work, continue in the user's existing local checkout.
- Do not create, switch to or spend time evaluating a Git worktree unless the user explicitly requests one or the task demonstrably requires isolation that cannot be achieved safely in the current checkout.
- If isolation would materially change the workflow, ask the user before creating a worktree.
- Do not create a worktree solely to inspect a parent commit, compare documentation or calculate analyzer deltas.
- Use `git diff`, `git show` and recorded validated baselines for those comparisons.
- Never allow worktree evaluation to block the task or prevent queued user messages from being processed.

### Efficient Flutter validation

- During implementation, run the smallest relevant focused tests for rapid feedback.
- After a failure, rerun only the affected focused tests until the correction is stable.
- Once implementation is final, run `flutter analyze` and the complete Flutter test suite exactly once on the final working tree.
- Do not rerun overlapping focused groups solely to produce separate final-report totals when those tests have already passed and are included in the complete suite.
- Continue to run validators and checks that are not included in the Flutter suite.
- If any production or test file changes after the complete suite, rerun the affected focused tests and then rerun the complete suite before committing.
- A failing test from the complete suite may be rerun in isolation for diagnosis.
- Do not start the complete suite while known focused failures or newly introduced analyzer findings remain.
- Do not run multiple Flutter commands concurrently when they share the same SDK lock, build directory or cache.

### Recovery and user control

- Keep tool calls bounded so the agent can receive queued user instructions between operations.
- Do not remain inside an unresponsive tool call indefinitely.
- If the user asks to stop or redirect work, yield control at the next safe command boundary.
- Preserve all already-written working-tree changes after an interruption.
- Resume by inspecting the existing status and diff. Do not restart the implementation from scratch.
- Never run destructive Git recovery commands unless the user explicitly authorizes them.

## Validation before delivery

Run, when the environment provides Flutter/Dart:

```bash
flutter pub get
flutter analyze
flutter test
