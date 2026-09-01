# 2.0.20 (build 220) - 2026-09-01

- Replaced the fixed learner-bottom Leaderboard action with Profile, rendered from the active learner's existing avatar appearance with name and standard-person fallbacks, full-name tooltip and Profile-aware accessibility semantics.
- Simplified the fixed learner bottom area to exactly Profile, Review and Course Info with the existing 68 px height, responsive spacing and unchanged Review/Course Info destinations.
- Added a central Profile page with the larger active learner avatar/name and links to Avatar customization, local learner-profile management and Gamification, all returning naturally to Profile.
- Replaced the direct Settings Avatar and Learner profiles entries with one Profile entry.
- Added confirmed local-only logout that removes only the `active_learner` selection, preserves profiles, avatar, progress, XP, streaks and course data, and returns to the existing learner selection/create flow.
- Moved Buy a coffee from the learner bottom area into the lower support area of Course Info while preserving HTTPS validation, external launching and existing failure messages.
- Preserved the build-219 Round path, mascots, connector, Laurel/completion accents, GuideBook/Duel presentation, XP, Review, Duel, TTS and Course Model v4 behavior.
- Refreshed the 30-day Alpha lifetime through the end of **2026-10-01**.

# 2.0.19 (build 219) - 2026-08-31

- Replaced the Unified Learner Page's large regular Round grid with smaller side-aligned cards following a deterministic balanced path that includes occasional consecutive same-side Rounds and consistent vertical whitespace.
- Adapted the connector into a curved 2 px, round-ended, 50%-opaque behind-content journey through every Round position, including same-side pairs and arbitrary Lesson lengths.
- Added intermittent, noninteractive QuisquisLingo mascot decorations discovered and decode-validated from Flutter's `assets/mascots/` manifest on the side opposite nearby Rounds, with a stable course-ID Fisher-Yates shuffle, one course-wide sequence across Lesson paths, full-set use before reuse, padded `BoxFit.contain` artwork, 50%-transparent theme surfaces, empty failed-image handling and narrow-layout priority for the core path.
- Removed the former between-Round Lesson image presentation from the learner path and retained the intentional deletion of `assets/exercise_images/hello.webp`; course data and editor image support remain unchanged.
- Made the Round icon background bright yellow-orange whenever the existing course-scoped persisted completed-Round state contains that Round, including completion with errors, while the existing authoritative perfect/Laurel state now uses a distinct bright-green icon.
- Enlarged the perfect-Round Laurel frame and leaves without changing eligibility, reduced and centered GuideBook and Duel cards, and applied 75% opacity to Round, GuideBook and Duel surfaces without fading their content.
- Added a continuous theme-neutral 18% veil between the course flag and learner content in dark mode only.
- Added focused deterministic-layout, persistence, decoration, interaction, theme and responsive coverage, plus actual Flutter web visual checks at 320, 375 and 390 logical pixels in light and dark modes.
- Refreshed the 30-day Alpha lifetime through the end of **2026-09-30**.

# 2.0.18 (build 218) - 2026-08-30

- Replaced the separate learner User Bar and Status Bar with one fixed, single-row Top Bar ordered as compact Language/Course flag selector, Streak, Laurel progress, Weekly XP, QuisquisLingo cat mark and Settings.
- Kept Streak language-scoped, Laurel progress current-course-scoped and Weekly XP learner-global without changing their calculation, persistence or update rules.
- Presented Laurel and Weekly XP as compact vertical current/max metrics, kept Streak on one line, and added concise explanatory dialogs for all three metrics.
- Clarified in the Streak and Laurel dialogs that Streak is language-scoped with cross-language study-day freezing, while Laurels remain specific to the course in which they were earned.
- Slightly enlarged the three metric icons and added standard informational tooltips to the course flag, Streak, Laurels, Weekly XP and App Info mark without changing their actions or the Top Bar height.
- Kept the existing full-size Language/Course picker behind the compact flag, moved learner-profile management into Settings, and kept the Lesson selector separate.
- Used the graphical portion of the existing branding asset in the Top Bar without changing the source image; the cat opens the existing App Info screen, whose complete logo remains unchanged.
- Added responsive spacing, white/near-black surface and narrow-layout coverage while preserving the course-flag background, continuous Lesson flow and fixed bottom controls.
- Retained the Alpha expiry at the end of **2026-09-29** because build 218 was prepared on the same date as build 217.

# 2.0.17 (build 217) - 2026-08-30

- Replaced the learner page's single-Lesson central content with a lazy continuous vertical flow from the selected Lesson through every subsequent Lesson in authoritative course order.
- Kept the complete four-zone Learner Header and icon-only bottom controls fixed while Lesson content scrolls beneath them with retained bottom clearance.
- Retained the existing Lesson picker and persistence; direct selection now restarts the flow at that Lesson, while stable visible-area synchronization updates the selector after scrolling into another Lesson.
- Preserved genuine Lesson locks and IDDQD access, kept locked Lesson content inaccessible without permission, and left Topic-scoped Duel eligibility, gameplay and XP unchanged.
- Added focused learner regressions for ordered flow, no duplication, lazy construction, selector jumps, scroll synchronization, fixed controls, final-content reachability and locked-Lesson gating.
- Refreshed the 30-day Alpha lifecycle; build 217 expires at the end of **2026-09-29**.

# 2.0.16 (build 216) - 2026-08-29

- Corrected the dark Welcome dialog's text contrast without changing its structure, controls, persistence or action styling.
- Replaced the unified learner page's decorative olive-tree background and tint with the selected course's existing flag rendering in light and dark appearances.
- Reordered the existing learner header and status bar so the protected user/logo/Settings strip appears first and the unchanged status bar appears directly below it.
- Removed the redundant standalone **Browse All Lessons** button while retaining the existing Lesson selector, picker, navigation and persistence behavior.
- Verified that the existing course picker already shows up to three newest other recent courses between the current course and complete course list; no recent-course persistence or presentation rewrite was required.
- Refreshed the 30-day Alpha lifecycle; build 216 expires at the end of **2026-09-28**.

# 2.0.15 (build 215) - 2026-08-28

- Removed Chapter from the production domain and learner navigation. Course Model v4 (`formatVersion: 4`) now stores ordered Topics directly under Course; old Chapter-based course structures are rejected without migration or compatibility fallback.
- Replaced the standalone Chapters/Chapter/Topic learner path with a unified Course → Lesson → Round page containing the course and Lesson selectors, GuideBook, responsive Round path, Topic-scoped Duel and the established Leaderboard/Review/Buy a coffee/Course Info actions.
- Added Chapter-free v4 progress namespaces, Topic-aware Review entries and Topic unlock progression while preserving course isolation, learner isolation, reset behavior, Laurels and the build-214 final-Round + first-Topic XP popup flow.
- Made Duel selection and availability use the actual eligible exercise pool of the current Topic. The 25-question, four-life, existing-eligibility and XP rules are unchanged; an insufficient pool is normal unavailable behavior rather than an error.
- Added non-blocking Course Editor guidance that Topics should normally contain at least six Rounds; this guidance does not validate Duel availability. New custom courses start with 3 placeholder Topics and no Chapters or automatic Rounds.
- Converted all eight bundled courses to native v4 Course → Topic data while preserving deterministic Topic/Round/content ordering and stable IDs.
- Preserved the 214 text-entry submission fix, authoritative XP formulas, Home Leaderboard route, reactive learner status bar and desktop resize behavior.
- Refreshed the 30-day Alpha lifecycle for build 215; because it is prepared on the same date as build 214, expiry remains at the end of **2026-09-27**.

# 2.0.14 (build 214) - 2026-08-28

- Included the one-time 25 XP Topic completion award in the final Round popup and total, with the same language and Weekly XP persistence and no second Topic-page award notice.
- Added first-attempt-correct X/Y communication using only evaluable exercises; Flashcard and informational/Guide content remains excluded from both base XP and the denominator.
- Made Enter and Check share the same guarded submission path for fill-in, listening-spelling and Missing Word text entry, with empty input disabled and ignored.
- Refined only the requested learner status-bar spacing: a one-pixel compact left inset for the streak flame and a one-pixel XP icon-to-value gap.
- Replaced Home's Chapters quick action with Leaderboard using the Material trophy icon, routed it directly to Gamification, and removed Gamification from Settings.
- Preserved desktop resizing on Windows, Linux and macOS while adding a 320×600 minimum supported window size and no maximum size.
- Retained the 30-day Alpha expiry at the end of **2026-09-27** because build 214 is prepared on the same date as builds 211–213.

# 2.0.13 (build 213) - 2026-08-28

- Stabilized completed-Round XP at 5 XP per first-attempt-correct evaluable exercise on first completion and 2 XP on repeats and in Review; incomplete Rounds award 0 XP.
- Added the repeatable 5 XP zero-error bonus and one-time 25 XP first-Laurel bonus, including Laurels first earned on repeats or in Review.
- Made Flashcards and informational/Guidebook-derived content contribute no base XP or errors while preserving perfect and Laurel eligibility.
- Replaced theoretical Round potential text with an actual persisted XP breakdown produced by the pure `XpCalculator` result.
- Made first Topic completion award 25 XP once, and Duel victories award 50 XP first then 10 XP on repeats, while keeping Topic and Duel state independent.
- Preserved the existing XP persistence keys, language XP, learner-global Weekly XP, per-course breakdowns, profile isolation, rollover, leaderboard aggregation and status-bar layout.
- Retained the 30-day Alpha expiry at the end of **2026-09-27** because build 213 is prepared on the same date as builds 211 and 212.

# 2.0.12 (build 212) - 2026-08-28

- Extracted the current Round, Topic, Duel and perfect-potential XP formulas into a pure `XpCalculator` with direct deterministic unit tests.
- Preserved current production scoring exactly, including first-pass-correct imperfect scoring, the floored perfect-repeat cap, repeated Topic and Duel awards, and the existing potential-XP display behavior.
- Characterized the observed six-exercise repeat sequence where the UI displays a 15 XP perfect-repeat potential, the imperfect Round awards 25 XP, and an already-completed Topic awards another 25 XP.
- Kept `XpService` responsible for language XP persistence, learner-global Weekly XP, per-course Weekly XP breakdowns, rollover, leaderboard data, celebration state, validation and clamping without changing keys or formats.
- Retained the 30-day Alpha expiry at the end of **2026-09-27** because build 212 is prepared on the same date as build 211.

# 2.0.11 (build 211) - 2026-08-28

- Added a persistent, reactive learner status bar to Home, Chapters, Chapter, Topic and Review navigation while keeping normal Round exercises outside the shared shell.
- Added authoritative course-title, language-streak, Laurel and learner-global Weekly XP status with responsive layout, adaptive foreground contrast, accessibility semantics and contextual explanations.
- Preserved all existing XP, streak, Laurel, Topic bonus, progress, navigation and persistence rules.
- Refreshed the 30-day Alpha lifecycle; build 211 expires at the end of **2026-09-27**.

# 2.0.10 (build 210) - 2026-08-27

- Completed Modularization Phase 2B by extracting learning-activity, streak, and study-day logic into `LearningActivityService` while retaining the public `ProgressService` facade.
- Preserved the existing activity persistence keys and formats, injected-clock semantics, activity registration ordering, and all established streak and study-day behavior.
- Added characterization coverage before extraction for persistence compatibility, temporal edge cases, cross-language behavior, reset/profile behavior, and completion activity side effects.
- Preserved all learner-facing XP and streak rules; build 210 contains no scoring or other learner-behavior change.
- Retained the existing Alpha expiry at the end of **2026-09-25**.

# 2.0.9 (build 209) - 2026-08-26

- Completed Phase 2A modularization by extracting Round completion orchestration into `LearningCompletionService`.
- Extracted completed-Round persistence, recent-Round error recording, permanent laurel vs provisional TTS-skipped state determination, XP calculation (first-pass correct and repeat-cap scoring), learner-global Weekly XP reads/accounting, second learning-activity registration, and atomic weekly goal celebration claiming.
- Retained UI presentation, exercise attempt state tracking, user input handling, mistake-review flow, preview-mode dialog, victory sound playback, mounted-lifecycle checks, weekly goal celebration dialog, and route navigation in `RoundScreen`.
- Preserved exact sequential, non-transactional persistence ordering and interleaving behavior, including laurel persistence -> victory sound -> XP calculation -> XP persistence -> second activity registration.
- Added comprehensive behavior and characterization test coverage in `test/learning_completion_service_test.dart`, `test/round_xp_completion_regression_test.dart`, and `test/topic_completion_regression_test.dart`.
- Preserved all learner behavior, course behavior, progress, Topic completion rules, Duel rules, Course Model v3, and persistence keys/formats; no scoring or compatibility changes.
- Refreshed the 30-day Alpha lifecycle; build 209 expires at the end of **2026-09-25**.

# 2.0.8 (build 208) - 2026-08-23

- Completed the technical rebrand of application-owned Dart/package/plugin symbols, Windows and Linux executable/application identifiers, SharedPreferences keys, serialization markers, bundled-course extension namespaces and diagnostic environment variables from LingoGrow to QuisquisLingo.
- Renamed the Windows-only TTS shim package and source path, project module file, Windows executable metadata and packaging checks without legacy aliases, migrations or fallback identifiers.
- Updated the update checker, release URL trust boundary, scripts, tests, Help and technical documentation for the new `Quisquisnaut/QuisquisLingo` repository.
- Refreshed the 30-day Alpha lifecycle; build 208 expires at the end of **2026-09-22**.
- Preserved learner behavior, course behavior, progress, XP/scoring rules and Course Editor structure; Phase 2 modularization remains out of scope.

# 2.0.7 (build 207) - 2026-08-22

- Rebranded user-visible application text from LingoGrow to QuisquisLingo, including display-only desktop window and descriptive metadata.
- Updated current Help, About, README and licensing documentation while preserving historical release documentation under the LingoGrow name.
- Preserved the then-current repository URL, application/package/bundle IDs, executable names, SharedPreferences keys, serialization tokens, course extension namespace, environment variables and internal symbols.
- Renamed user-facing filesystem locations and filenames from LingoGrow to QuisquisLingo, including Documents transfer/import folders, exported course and learner-backup filenames, application-owned recorded-audio storage, temporary TTS storage, crash logs, startup traces and Diagnostic Log exports. No legacy-path migration, alias or fallback is included because build 207 has no existing installations to migrate.
- Renamed release and source artifact conventions to `quisquislingo_alpha_<buildnumber>` and `quisquislingo_alpha_<buildnumber>_source`; Windows development bundles use the corresponding `quisquislingo_alpha_<buildnumber>_dev_windows_x64` name.
- Refreshed the 30-day Alpha lifecycle; build 207 expires at the end of **2026-09-21**.
- Kept Phase 2 modularization out of build 207.

# 2.0.6 (build 206) - 2026-08-20

- Replaced brittle source-text assertions with behavior-level widget characterization tests for Round completion/XP and Course Editor Guidebook generation.
- Added direct coverage for imperfect first completion, perfect first completion, perfect repeats, TTS-skipped perfect completion, preview completion with no learner writes, generator cancellation and explicit generator approval.
- Verified persisted Round completion, laurels, Review history, language XP, learner-global Weekly XP, stable Course/Chapter/Topic identity and absence of unintended preference/progress writes through public behavior.
- Removed the redundant Guidebook vocabulary source-text test after its requirements were covered by the generator behavior tests.
- Preserved all production behavior, course-ID/import/replacement/copy semantics, persistence formats and XP rules; build 206 contains no production feature or scoring change.
- Reserved build 207 for Phase 2 modularization in small, independently validated steps with no intentional behavior changes. Phase 2 is not part of build 206.
- Refreshed the 30-day Alpha lifecycle for the 20 August 2026 release; build 206 expires at the end of **2026-09-19**.

# 2.0.5 (build 205) - development

- Promoted the native Windows and Dart/Flutter startup trace into a permanent Alpha diagnostic subsystem with concise normal tracing and opt-in verbose tracing through `LINGOGROW_STARTUP_DIAGNOSTICS=verbose`.
- Added privacy-safe session headers, bounded diagnostic messages and approximately 1 MiB active-log rotation with two retained generations. Startup logs no longer record raw command lines, usernames, full executable/working-directory paths, profile names, course content or learner answers.
- Preserved startup order, UI behavior, persistence, course behavior, XP/progress behavior and TTS behavior while making diagnostics fail-safe and suitable for ongoing Alpha support.
- Refreshed the 30-day Alpha lifecycle for the 19 August 2026 development build; the expiry remains **2026-09-18** because build 205 development begins on the same date as build 204.

# 2.0.4 (build 204)

- Added deterministic injected-clock coverage for Weekly XP rollover, previous-week and skipped-week XP, per-course Weekly XP, streaks, study days, repeated same-day activity, Review timestamps and learner-profile isolation. Normal application callers still use the real current local time by default.
- Extracted language XP, learner-global Weekly XP, per-course current/last-week XP breakdowns, rollover, leaderboard XP calculation and weekly-goal celebration persistence into `XpService`, preserving all existing `ProgressService` XP-facing APIs through delegation.
- Kept local leaderboard participation preference and filtering in `ProgressService`; participation is not owned by `XpService`.
- Made the listening-spelling renderer regression assertion work with both LF and CRLF source files while preserving its source-structure check.
- Updated `AGENTS.md` with the current `ProgressService`/`XpService` responsibility boundary, deterministic-time guidance, persistence scope, XP compatibility rules and validation discipline.
- Preserved existing 203 behavior: build 204 does not change Round, Topic or Duel XP formulas, does not add scoring multipliers, does not change UI behavior or Course Model v3, and does not change any SharedPreferences key or stored format.
- Refreshed the 30-day Alpha lifecycle for the 19 August 2026 release; the expiry remains **2026-09-18** because build 204 is prepared on the same date as build 203.

# 2.0.3 (build 203)

- Resolved all 50 analyzer findings present in build 202: added braces to single-statement conditionals, guarded asynchronous navigation contexts, and normalized Image Bank test fixture identifiers.
- Preserved existing learner, Course Editor, course data, progress, XP, persistence, and navigation behavior.
- Refreshed the 30-day Alpha lifecycle for the 19 August 2026 release; the expiry remains **2026-09-18** because this release was prepared on the same date as build 202.

# 2.0.0 (build 200)

- Established **2.0.0+200** as the reference baseline for Course Model v3 and future Codex-assisted development.
- Added repository-level `AGENTS.md` and `docs/CODEX_BASELINE_200.md` so future coding work starts from the correct architecture, validation rules and packaging conventions.
- Preserved the Course Model v3 learner/editor functionality and bundled course data from the baseline source; this version jump does not intentionally remove or reset existing features or learner data.
- Refreshed the Alpha expiry to **2026-09-17**.

# 1.5.9 (build 159)

- Promoted the native course structure to Course Model v3 (`formatVersion: 3`): Guidebooks now belong to learning Topics and Chapters no longer contain Guidebooks. Course Model v2 remains importable through deterministic compatibility migration.
- Regenerated all eight bundled sample courses for Topic Guidebooks. Round 1 of every learning Topic starts with a short non-exercise `topic_intro` drawn from that Topic Guidebook and pointing learners to the full Topic Guidebook.
- Added the learner **OPEN TOPIC GUIDEBOOK** action to Topic pages and removed the Chapter-level Guidebook action. Updated learner notices, Info, Editor Help, JSON reference, sample-course documentation and validation rules.
- Added **Generate 3 Rounds from Guidebook** to the Topic Editor. It uses Topic Guidebook vocabulary and examples, randomizes suitable material, builds progressively harder drafts, avoids exact duplicate exercise prompts, previews/audits all three Rounds, and creates them only after explicit approval. Round 1 includes the Guidebook-derived intro Content.
- New custom courses continue to start with five placeholder Chapters and three placeholder learning Topics per Chapter, but no automatic Rounds. Manually created Rounds still start with three editable dummy exercises.
- Renamed the per-learner/per-course switch to **IDDQD Mode (you can walk through locks)** while preserving its description and temporary-access semantics. Lock icons continue to show the genuine unlock state.
- Fixed Course Editor classification so a selected imported/user-created course remains under **My custom courses** and is not duplicated under **Current bundled course**. Origin is taken from the persisted `custom:<courseId>` selection reference rather than inferred from title or ID.
- Fixed imported Course Model v3 `listening_spelling` exercises with `interaction.kind: input`: learner UI now shows a typed **Your answer** field and evaluates `text_match` answers. The parser accepts v3 `acceptedAnswers` and the legacy `accepted` key; exports write `acceptedAnswers`.
- Fixed incorrect-answer feedback for selection exercises so **Correct answer** resolves the stable `correctItemIds` Item instead of repeating the exercise prompt. Course Audit now reports unresolved correct Item IDs.
- Added a Course Audit warning for the generated Reading pattern where the declared correct vocabulary option does not occur in the passage, helping surface semantically inconsistent imported/generated exercises for human review rather than silently rewriting them.
- Updated the Alpha expiry for this release to **2026-09-16**.

# 1.5.8 (build 158)

- New custom courses now start with five placeholder Chapters instead of three.
- Each generated Chapter starts with three placeholder learning Topics plus its Language Duel assessment.
- Course creation does not generate any Rounds automatically. Rounds are added explicitly later by the course author.
- Updated Course Editor help to describe the new-course bootstrap accurately.

# 1.5.7 (build 157)

- Each learning Topic now shows the number of completed Rounds out of its total Rounds.
- Strengthened the global desktop mouse-hover feedback for buttons and other Material button controls without changing their actions.
- IDDQD Mode still grants temporary access to every Chapter in the current course, but Chapter lock icons now always show the learner’s genuine unlock state. A Chapter that is accessible only through IDDQD therefore keeps its lock icon until it is genuinely unlocked through normal progression or a Duel win.

# 1.5.6 (build 156)

- Regenerated all eight bundled sample courses. In every learning Topic, the first Content item of Round 1 is now a short non-evaluated explanation derived from that Chapter Guidebook, with an explicit invitation to read the Guidebook for more.
- Topic-intro Content is displayed before the runnable Round exercises and does not count as an exercise, XP opportunity, Duel item, completion requirement or laurel condition.
- Added **IDDQD Mode (temporary unlocks all chapters in the current course)** to Settings. The setting is stored per learner profile and per course. It only overrides access; genuine Topic completion and Duel wins continue to be recorded normally, and disabling IDDQD immediately restores the true unlock state.
- Course Editor now creates three placeholder Chapters for a new course. A newly created Chapter starts with three placeholder learning Topics, and a newly created Round starts with three editable dummy exercises.
- Kept the standard Language Duel assessment separate from the three learning Topics.

# 1.5.5 (build 155)

- Added **Current version** followed by **Update** at the bottom of Settings.
- Added a dedicated **Settings > Update** page for the official repository `https://github.com/Quisquisnaut/QuisquisLingo`.
- Added manual GitHub Release checks and an optional **Check automatically at startup** switch, disabled by default.
- A newer published release can show release notes, open only the validated official GitHub release page, and display fixed-order installation guidance for Windows, macOS, Linux antiX, Android, iOS and Web.
- Platforms without a matching published release asset are explicitly marked as not currently available.
- Hardened update checking: fixed HTTPS API endpoint, no credentials or learner/course payloads, bounded response size, redirect rejection, strict release-URL validation, timeouts, no automatic download/install/execution, and silent startup failure when offline.
- Added regression tests for version comparison, trusted release URLs and conservative platform-asset detection.
- Updated security, Info, README and third-party documentation; removed the stale `file_picker` notice and added `url_launcher`.
- No changes to course content, Course Model, progress, Duel rules, TTS, import/export, or learner navigation.

# 1.5.4 (build 154)

- Chapter titles may now wrap onto two lines in the learner Chapter app bar.
- Chapter titles in the Chapters list are also explicitly allowed up to two lines before ellipsis.
- No changes to Chapter navigation, course content, progress, or Language Duel rules.

# 1.5.3 (build 153)

- Distinguishes the automatic Crash Log from the internal Diagnostic Log throughout the UI.
- Settings now shows the actual Crash Log path and the fixed Diagnostic Log export location.
- Adds Export Diagnostic Log, now written to `Documents/QuisquisLingo/Logs/quisquislingo_diagnostic_log.txt`.
- Startup Alpha tester instructions now refer to the Crash Log, not the Diagnostic Log.
- Chapter freedom notice is shortened to `Jump freely around the tree`.
- Duel gate text is shortened to `Win the duel to test out to next chapter`.
- Compact Status labels now use the requested form, for example `Apprentice (lev. 0)`.
- Includes the regenerated bundled sample exercises from 1.5.2, based on each Chapter Guidebook vocabulary and the available exercise primitives.

# LingoGrow 1.5.1

- Reduced the Home app bar height slightly to make the main screen more compact vertically while preserving the learner name and existing actions.
- No changes to Home navigation, course selection, progress logic, or course content.

# LingoGrow 1.5.0

- Removed the visible “Quick actions” heading from the Home screen to reduce vertical height.
- Made the “Change course” control slightly more prominent with stronger text weight, a subtle tinted background, and a clearer icon while keeping “Go to course” as the primary action.
- No changes to course navigation, Course Model, bundled course content, or progress logic.

# LingoGrow 1.4.9

- Added a third learning Topic to every Chapter in all eight bundled sample courses.
- Each new sample Topic contains two Rounds with eight choice exercises, bringing every bundled Chapter to at least 28 exercises eligible for a 25-question Language Duel.
- Updated `requiredTopics` from 2 to 3 for bundled sample Chapters.
- DUEL-001 now tells the learner directly: “This Chapter does not contain enough exercises for a Language Duel.”
- Updated bundled-sample and error-code documentation.

# LingoGrow 1.4.8

- Replaced deprecated `PopScope.onPopInvoked` with `onPopInvokedWithResult` in Chapter navigation.
- Preserved the rule that Back from a Chapter always opens that course's Chapter list when the Chapter was entered directly.
- Packaging fixed: the source archive now contains the project files at the archive root, without an extra `lg*_work` directory.
- No changes to Gamification, Course Model, course content, or navigation behavior.

# LingoGrow 1.4.7

- Fixed typed loading in TTS, Do Not Disturb, Avatar, and main Settings screens.
- Fixed Image Bank ZIP byte-size accounting with archive 4.x numeric sizes.
- Replaced deprecated WillPopScope in Chapter navigation with PopScope.
- No changes to Gamification scoring, Course Model, or course content.

# Changelog

## 2.0.2+202

- Corrected the **Reset current course progress** confirmation: it now names only course-owned progress that is reset. Language XP, streak, study days and Status remain because they are shared by courses in the same language.
- Confirmed Round XP is persisted only after the learner finishes the Round. Abandoning or exiting before **Finish round** awards no XP; completed Rounds with first-pass errors still receive the lower first-pass-correct award.
- Refreshed the 30-day Alpha expiry to **2026-09-18**.

## 2.0.1+201

- Course-owned progress now uses immutable globally unique Course IDs, preventing collisions between courses that teach the same language. Language XP, streaks and study days remain language-scoped; Week XP remains learner-wide across all languages.
- Same-ID course imports now offer replace/update, separate derived copy, or cancel. Derived copies receive a new Course ID and retain optional lineage metadata.
- Added repeat-perfect Round XP cap: a repeat perfect completion earns at most half the Round's full XP value. The completion screen states the potential award.
- Added Illustrator as a course information role.
- Refreshed the 30-day Alpha expiry to **2026-09-17**.

## 1.4.6+146

- Fixed an analyzer/compiler compatibility error in `ReviewScreen` caused by two parameters using the same `_` identifier on older Dart toolchains.
- Removed unnecessary boolean casts in Settings subpages.
- Removed an unused `firstOrNull` helper from `duel_screen.dart`.
- No functional changes to Gamification, courses, navigation, or the Language Duel.
- Dependency declarations are unchanged from 1.4.5; run `flutter pub get` after extracting the source before `flutter analyze` or `flutter run`.

## 1.4.5+145 - 2026-08-16

- Added a dedicated **Gamification** subpage under Settings.
- Moved **Weekly XP Target** into Gamification and clarified that the target is based on XP earned across all courses.
- Added **Last Week XP · All courses** for the previous completed week. Tapping the learner's score opens a per-course XP breakdown.
- Added a **Local leaderboard · All courses** ranking participating local learner profiles by their total XP across all courses during the previous completed week.
- Added a per-profile switch to opt out of the local leaderboard without deleting XP history.
- Added per-course weekly XP bookkeeping so future completed weeks can show an exact course-by-course breakdown, including custom courses.
- Updated Info and README to document the scope and privacy of local gamification data.

## 1.4.4+144 - 2026-08-16

- Added a dedicated **Avatar** subpage under Settings.
- Moved **Avatar skin color** and **Avatar hair color** into the new subpage without changing profile storage or avatar behavior.
- Kept the main Settings page more compact by replacing the inline avatar controls with a single Avatar entry.
- Updated current in-app Info to point to Settings > Avatar.

## 1.4.3+143 - 2026-08-16

- Added a dedicated **User Data** subpage under Settings.
- Moved **Export my data**, **Import my data**, and **Reset current course progress** into the new subpage without changing the existing backup/import storage paths.
- Kept the main Settings page more compact by replacing those three controls with a single User Data entry.
- Updated current in-app documentation to use the new Settings > User Data paths.

## 1.4.2+142 - 2026-08-16

- Added a dedicated **Do Not Disturb** subpage under Settings.
- Moved **Sound effects**, **Animations**, and **Show one-time notices again** into the new subpage without changing their stored preferences or behavior.
- Kept Settings more compact by replacing the three switches with a single Do Not Disturb entry.
- Updated current internal documentation to use the new Settings paths.

## 1.4.1 - 2026-08-16

- Added a dedicated **TTS Settings** subpage under Settings.
- Moved Text-to-speech, Skip all TTS exercises, TTS voice, and Test Voice into the new subpage without changing their stored preferences or behavior.

## 1.4.0+140 - 2026-08-16
- Home > Current course now shows the last Chapter actually opened for the active learner and selected course.
- The Chapter number and title refresh immediately when returning to Home.
- The displayed Chapter uses the same per-profile, per-course memory as Go to course; first use falls back to Chapter 1.

## 1.3.9+139 - 2026-08-16
- Chapter back navigation now always returns to the selected course's Chapter list, including when Go to course opened the Chapter directly from Home.
- Preserved the existing flag transition animation before direct course entry.
- Updated in-app Help and current documentation for the navigation rule.

## 1.3.8
- Language Duel now uses 25 questions and 4 lives.
- Removed Duel score and pass threshold. A Duel is won by completing all 25 questions before all four lives are lost.
- Updated Course Model v2 assessment defaults, bundled courses, validation, tests, Help, Info and documentation for the new Duel rules.

## 1.3.7+137 - 2026-08-16

- Home: placed all four Quick actions on a single horizontal row to reduce vertical height, including on phone-width layouts.
- Reduced Quick action internal padding and icon size slightly, while preserving all four destinations and touch targets.
- No navigation, course, progress, or Course Model changes.

## 1.3.6 - 2026-08-16

- Course Editor > Course info is now always accessible, including while course content is locked.
- Course info now clearly advertises that the visible course name, authors, license and metadata can be edited.
- Lock continues to protect structural/content editing but no longer blocks metadata editing.
- Renaming a course still preserves its stable `courseId`.

# Changelog

## 1.3.5+135

- Moved the Alpha expiry notice out of the Home page and into a non-dismissible popup shown on every app launch.
- The popup always states the current Alpha expiry date and remaining days, or the expired state after the deadline.
- Removed the Alpha expiry card from Home to reduce vertical height.

# LingoGrow 1.3.4

- Home: removed the two-line footer to reduce vertical height.
- Home course selector continues to include bundled courses and all custom courses, whether created locally or imported from JSON.
- Go to course now opens the last Chapter opened by the active learner in the selected course; first use opens Chapter 1.
- Quick actions > Chapters remains the explicit route to the complete Chapter list for the selected course.

# 1.3.3

- Expanded in-app Help for bundled vs custom courses, Home course selection, Go to course vs Chapters, custom-course import/export, Copy edits as JSON, Course ID/name behavior, learner backup and fixed media-import folders.
- Go to course now resumes the active learner at the last Topic visited in the selected course; first use opens the first learning Topic of Chapter 1. Chapters continues to open the full Chapter list.
- Status presentation explicitly shows the level number.
- Corrected current Duel documentation to the Course Model v2 standard: 10 selected exercises, 3 lives, 7/10 threshold.
- Reconciled current README, Course Editor, sample-course and Course Model documentation with the current app behavior.

## 1.3.2+132 - 2026-08-16

- Home course selector now lists both included courses and all locally stored custom courses.
- User-created and imported Course Model v2 courses appear under `My custom courses` in the same selector.
- Selecting a custom course makes it the current Home course and persists that selection across app restarts.
- Preserved custom `courseId` casing in the stored last-selected-course reference so imported course IDs remain stable.
- No Course Model changes.

## 1.3.1+131 - 2026-08-16

- Course Editor > Course info: the visible Course name can now be edited.
- Course ID remains read-only and unchanged when the course is renamed, preserving the course's technical identity.
- Course Editor Help now explains the distinction between Course name and Course ID.
- No other functional changes.

## 1.3.0+130 - 2026-08-16

- Restored an explicit `Change course` control on the Home current-course card.
- The course picker was still present in 1.2.9 but was discoverable only by tapping the `CURRENT COURSE` badge; the new control makes course selection visible again.
- Kept the existing course picker logic and all 1.2.9 behavior unchanged.

## 1.2.9+129 - 2026-08-16

- Doubled the display time of all bottom SnackBar messages to 8 seconds, including informational and error messages, so users have more time to read them.
- No other functional or visual changes.

## 1.2.8+128

- Restored the pre-redesign Home progress presentation for clearer scope and less duplication.
- Removed the duplicate total XP value from the Progress header.
- Restored the explicit `Week XP · All courses` label for the global weekly XP metric.
- Restored course-specific wording for streak, laurels, and total days, including the selected course language where appropriate.
- Kept the 1.2.7 compact Home header and current-course/quick-action layout unchanged.

## 1.2.7+127

- Removed the Home welcome card to reduce vertical height, especially on phones.
- Restored the active learner name to the left side of the Home app bar.

## 1.2.6+126

- Home: restored the lighter transparency used before the 1.2.4 redesign so the olive-tree background remains clearly visible.
- Home: removed the duplicate streak indicator from the welcome panel; streak remains in Progress.
- Home: slightly reduced vertical padding and spacing while preserving the 1.2.4/1.2.5 information hierarchy and navigation.

## 1.2.5+125 - 2026-08-16
- Fixed the Home screen build failure caused by three invalid `FontWeight.w650` values.
- Replaced them with the supported Flutter weight `FontWeight.w600`.
- No other functional or visual changes.

## 1.2.4+124 - 2026-08-16
- Refreshed the Home screen visual design with an olive-inspired translucent dashboard.
- Added a clearer welcome panel, current-course card, progress dashboard and overflow-safe quick actions.
- Kept existing Home navigation and learner/course logic unchanged.

## 1.2.3+123 - 2026-08-16

- Refined the Home screen visual hierarchy without changing navigation or learning logic.
- Added a translucent welcome header, a more prominent current-course card, and softer separation from the olive-tree background.
- Restyled the primary Go to course action, progress card, status presentation, and four progress metrics for clearer scanning.
- Kept the Home layout scroll-safe and suitable for narrow desktop windows.
- No course-model or course-content changes.

## 1.2.2+122 - 2026-08-16

- Removed obsolete LingoGrow 1.0.0/1.0.1 version references from the Course Model v2 runtime error and technical Help.
- Course Model v2 wording is now release-independent so it does not become stale on future app versions.
- No functional course-model changes.

## 1.2.1+121 - 2026-08-16

- Added deliberately fictitious placeholder author names to all bundled sample courses for UI testing.
- Chapters now shows `Course by ...` below the course title, using Course Model v2 `authors` metadata and falling back to the legacy `author` field when needed.
- No other functional changes.

## 1.2.0+120 - 2026-08-16

- Fixed the remaining horizontal RenderFlex overflow in Chapter Topic cards on narrow Linux desktop windows.
- Replaced the outer Topic Row/SizedBox width calculation with an aligned FractionallySizedBox constrained to 72% of the actual parent width.
- Topic titles are now capped at two lines with ellipsis, while the round count and navigation chevron remain inside the card bounds.
- Updated the Topic layout regression test to protect the new constrained structure.
- Based directly on 1.1.9+119 with no unrelated functional changes.

## 1.1.8+118 - 2026-08-16

- Image Bank single-image import no longer opens a file picker. It reads exactly one PNG/JPG/JPEG/WEBP file from `Documents/QuisquisLingo/Imports/Images`.
- Image Bank ZIP import no longer opens a file picker. It reads exactly one ZIP from the same fixed Images import folder.
- Topic/exercise custom-image imports use the same fixed Images folder.
- Audio Library MP3 import no longer opens a file picker. It imports all MP3 files found in `Documents/QuisquisLingo/Imports/Audio`.
- Image Bank, Audio Library and Course Editor Help now show immediate fixed-folder import instructions.
- Source files are left in the import folders; the UI warns creators to move/remove MP3 sources after successful import to avoid duplicates.
- Based directly on 1.1.7+117 with no unrelated functional changes.

## 1.1.7 - 2026-08-16

- Settings learner-data export no longer opens Save As or any file picker. Backups are written directly to `Documents/QuisquisLingo/Exports`, with numeric suffixes when needed to avoid overwriting an existing file.
- Settings learner-data import no longer opens a file picker. It reads `Documents/QuisquisLingo/Exports/learner_import.json`.
- Settings and Info now show immediate learner backup import/export instructions and the fixed paths.

## 1.1.6+116

- Reworked Course Editor Help with separate step-by-step instructions for importing custom courses, exporting custom courses, and importing custom flags.
- Help now states the fixed transfer path `Documents/QuisquisLingo/Exports`, the required `import.json` filename, and accepted custom-flag filenames.
- Clarified that temporary sample material refers to bundled courses included with early LingoGrow versions, not user-created custom courses.
- Based directly on 1.1.5+115 with no other functional changes.

## 1.1.5+115

- Removed the sample-material explanation from the Create new course dialog.
- The dialog now only states that a basic Course Model v2 structure will be created; the sample-material explanation remains in Help.
- Based directly on 1.1.4+114 with no other functional changes.

## 1.1.4

- Removed the desktop file picker from custom course flag import.
- Custom flags are now imported from `Documents/QuisquisLingo/Exports/flag.png`, `flag.jpg`, or `flag.jpeg`.
- Added immediate flag-import instructions to the Create new course dialog.
- Missing flag files now produce an actionable in-app message instead of exposing a Linux desktop portal error.

## 1.1.3+113

- Custom-course JSON import no longer opens a file picker.
- Import always reads `Documents/QuisquisLingo/Exports/import.json`, the same fixed transfer directory used by course export.
- Course Editor shows immediate import instructions beside the import action and states that imported courses appear under **My custom courses**.
- Missing or invalid `import.json` produces an actionable message with the expected location.
- The import source file is left in place after a successful import.
- Based directly on 1.1.2+112.

## 1.1.2+112

- Custom-course JSON export no longer opens a Save As dialog or depends on desktop portal services.
- Exports are written directly to the fixed `QuisquisLingo/Exports` folder inside the user documents directory.
- Existing exports are never silently overwritten; duplicate filenames receive `_2`, `_3`, and later numeric suffixes.
- Course Editor Help documents the fixed export location.
- Based directly on the regression-checked 1.1.1 source derived from 1.0.8.

## 1.1.1+111

- Rebased all post-1.0.8 work directly on the verified 1.0.8 Course Model v2 source to avoid regressions.
- Preserved the 1.0.5-1.0.8 matching fixes, stable Item-ID learner logic, double-confirmation custom-course deletion, last selected bundled course restoration and Course Editor Help shortcut.
- Course Editor now labels the user section **My custom courses** and the bundled section **Current bundled course**.
- Added portable Course Model v2 JSON import/export for custom courses, with UTF-8/size/schema validation and replacement confirmation for duplicate course IDs.
- New custom courses can choose a built-in flag or import a PNG/JPEG flag. Imported flags are size/resolution checked, safely resized with preserved proportions and stored in the course JSON.
- Course Editor app bar now puts the course name on a separate readable line under **Course Editor**.
- Chapters screen now shows the course name instead of the generic **Chapters** heading.
- Topic title cards use a transparent background.
- Regenerated sample presentation data on top of Course Model v2: Chapter and Topic titles use the source language, each Chapter Guidebook contains at least 12 vocabulary entries, and learning Topics contain more image-supported exercises.
- Removed normalized duplicate sample answer choices such as `hallo` / `Hallo!`.
- Help explains that new courses may initially contain sample material which course creators progressively replace with the real course content.

## 1.0.8+108

- Removed the unused `_shuffleDifferentStrings` helper from `RoundScreen` after matching was migrated to stable Item IDs.
- No learner behavior changed.
- Target: `flutter analyze` reports `No issues found!`.

## 1.0.7+107

- User-created courses can be deleted only after two consecutive confirmation dialogs; bundled sample courses remain non-deletable.
- Home now remembers the last selected bundled course and restores it on the next app start.
- Added a Course Editor Help shortcut to the main Course Editor projects page.
- Chapter labels now show the generated chapter number before the title in learner/editor locations, without storing the number inside the Chapter title.

## 1.0.6+106

- Fixed a learner crash in matching exercises when two displayed right-side choices have the same text.
- Matching DropdownButton values now use stable Course Model v2 Item IDs instead of visible labels.
- Matching correctness also compares Item IDs, so duplicate labels are safe at runtime even though Course Audit can still reject semantically duplicate sample content.
- Applied the same ID-based selection logic to audio matching.

## 1.0.5+105

- Rebuilt bundled sample Word Match exercises with three genuinely distinct source/target pairs.
- Rebuilt bundled sample Audio Match exercises with three distinct target-language sounds and three distinct visible matches.
- Removed generated sample Super Match items that used duplicate/weak pairs; sample coverage now uses reliable translation matching while Super Match remains available in the editor and model.
- Course Audit now rejects match exercises whose left or right items collapse to duplicates after case and punctuation normalization.

## 1.0.4+104

- Fixed sample translation-choice prompts so the source word/expression is explicitly shown.
- Replaced `xyz` and source-language placeholder options with real target-language distractors across all bundled sample courses.
- Course Audit now reports `PLACEHOLDER_ANSWER` for known placeholder options.
- Course Audit now reports `TRANSLATION_PROMPT_MISSING_SOURCE` when a translation task does not identify what must be translated.

# 1.0.1

- Fixed `flutter analyze` error in `course_editor_screen.dart`: the friendly exercise-label helper is now referenced from `_ExerciseEditorScreenState`, where it is defined.
- No Course Model v2 schema or sample-course behavior changes.

# 1.0.0

- Replaced the legacy course structure with Course Model v2 (`formatVersion: 2`).
- Rounds now serialize `content[]`; Exercise is one Content kind.
- Added primitive Exercise representation: Prompt + Interaction + Evaluation.
- Added stable Item IDs for choice, arrange and match correctness.
- Converted Flashcard to interactive Presentation Content with `understood` and `review_later`.
- Structured Chapter Guidebooks as `content[]`.
- Represented Language Duel as an assessment Topic / skip test; default sample Duel is 10 questions, 3 lives, pass at 7/10.
- Kept friendly exercise/template names in Course Editor while primitives remain internal.
- Added independent user-created Course Model v2 projects to Course Editor.
- Reorganized Editor Help: practical page plus separate Course Model v2, Exercise primitives and JSON data structure pages.
- Regenerated all bundled samples natively in v2 with meaningful Topic titles and Topic images.
- Updated bundled-course validation for Course Model v2.

# 0.8.9

- Added `readme_windows.txt` documenting Windows release dependencies, Microsoft Visual C++ Runtime requirements, TTS, diagnostic logging and troubleshooting.
- Added `tools/package_windows_release.ps1`: it builds the Windows release and automatically copies the documentation into the Release folder as `readme.txt`, beside the executable.
- The complete Release folder remains the distribution unit; the executable must not be distributed alone.
- No learner, editor or course-data behavior changed.

# 0.8.8

- Added a separate automatic generator for sentence exercises based on the current Chapter Guidebook example sentences.
- The generator can propose Sentence Word Order, Missing Word, Listening Spelling and Gap Choice exercises.
- Sentence generation uses only author-written Guidebook examples and does not invent sentences or translations.
- Sentence Word Order drafts are created without distractors by default; authors can add distractors manually later.
- Gap Choice is generated only when two safe target-language distractors can be found from known course vocabulary.
- Generated sentence exercises are reviewed, individually selectable and audited before insertion.
- Added Editor Help documentation and a Guidebook Examples field hint.

# 0.8.7

- Reorganized Course Editor Help so the complete JSON course-file reference is separated from normal editor guidance and placed at the end.
- Added a short introductory section before the JSON technical reference.
- No JSON schema, parser, course content or learner behavior changed.

# 0.8.6

- Fixed the Guidebook editor helper-text parameter introduced with Guidebook vocabulary exercise generation.
- Fixed a Dart string-literal syntax error in the JSON portability section of Course Editor Help.
- No learner behavior or course content changed.

# 0.8.5

- Added `Generate exercises from Guidebook vocabulary` to the Round Editor.
- Guidebook Vocabulary entries can be parsed as target/source pairs such as `casa = house`.
- The generator can propose Flashcards, Word Match, translation choices and Audio Match exercises.
- Generation uses only author-supplied vocabulary pairs and does not invent translations.
- Generated drafts are reviewed and individually selected before insertion, with Course Audit run on the proposals.
- Added Editor Help documentation and a discoverable Vocabulary field hint.
- No learner progress is changed by generation or preview.

# 0.8.4

- Removed references to specific external course editors from Course Editor Help and JSON-format documentation.
- Kept portability guidance generic for future interoperability with external course editors and learning applications.
- No course format, parser or learner behavior changed.

# 0.8.3

- Added an extensive Course Editor Help section documenting the current JSON course-data structure.
- Documented root Course metadata, authors, audioLibrary, Chapters, Guidebooks, Topics, Rounds, Exercises, type-specific field use, parser rules, stable IDs and versioning.
- Added a minimal structural JSON example and guidance for safe external JSON editing.
- Added forward-looking portability guidance for future interoperability with external course editors and learning applications.
- No learner behavior or course-data parser behavior was changed.

# 0.8.2

- Removed the persistently timing-out automated widget test `Image Bank opens a preview before selection`.
- The working Image Bank preview implementation is unchanged and should be verified manually.
- Image Bank asset validation remains in place.

# 0.8.1

- Fixed the Alpha tester startup notice so it is shown in standalone release builds as well as debug builds.
- Crash/diagnostic logging now starts on every non-web application launch, including Windows release builds.
- Every session writes a startup header containing timestamp, app version, operating system, architecture, locale, Dart runtime and build mode (`debug`, `profile` or `release`).
- Windows Alpha builds now maintain an easy-to-find diagnostic copy at `Documents\\QuisquisLingo Logs\\quisquislingo_crash.log` in both debug and release.
- Diagnostic files are written with append mode; if a tester deletes a log, the next app start or diagnostic write recreates it automatically.
- Detailed action breadcrumbs remain debug-only to keep release logs concise.
- Added regression checks for release startup notice visibility and always-on session logging.

# 0.8.0

- Fixed the Flutter/Dart `Zone mismatch` introduced by debug crash logging by keeping binding initialization and `runApp` inside the same guarded zone.
- Preserved global Flutter/Dart crash capture and Windows debug system logging.
- Changed the startup tester instructions to show the portable crash-log path without a Windows username; it is now `Documents\QuisquisLingo Logs\quisquislingo_crash.log`.
- Fixed Round startup ordering so the first exercise, including choice options, is fully prepared before the learner UI is marked ready; added a defensive rebuild for unexpectedly empty choice options.
- Removed the unnecessary `package:flutter/widgets.dart` import reported by `flutter analyze`.
- Updated the Image Bank preview widget test to use an image from the current manifest instead of the removed `transport_airplane` test fixture; the working preview implementation itself is unchanged.

# 0.7.9

- Debug builds now show tester instructions automatically at startup, including the exact crash-log path and how to send the complete log file.
- Debug logs now record a system snapshot at session start, including OS/version, architecture, logical processor count, locale and Dart runtime, and repeat key system details in crash reports.
- The diagnostic notice states what is and is not intentionally recorded.

# 0.7.8

- Added a Windows debug diagnostic build path with immediate navigation breadcrumbs and a tester-friendly crash-log copy, now stored in `Documents\QuisquisLingo Logs\quisquislingo_crash.log`.
- Moved and strongly emphasized the Home `GO TO COURSE` button so the primary action appears before progress details.
- Made the Chapter `OPEN GUIDEBOOK` action a large full-width primary button.
- Changed first Chapter entry so it always opens the normal Topic view. A one-time learner notice now explains that every Chapter also has a Guidebook.
- Updated Guidebook help text and removed the obsolete automatic-Guidebook behavior.

# 0.7.7

- Hardened Windows crash prevention around Settings and Round initialization: failures are logged and the UI falls back instead of leaving an uncaught initialization future.
- Made `flutter_tts` lazy so Windows and Linux do not instantiate the plugin when their dedicated TTS backends are used.
- Added a safe Round fallback screen when initialization fails, preserving the process long enough to retrieve the crash log.

# 0.7.6

- Added persistent crash logging for uncaught Flutter and Dart errors, including timestamp, app version, operating system, error details, and stack trace.

# 0.7.5

- Added a macOS compatibility path and macOS-specific build documentation.
- Added macOS runner Swift sources and sandbox entitlements for user-selected file read/write access used by import/export workflows.
- Added `tools/prepare_macos.sh` to generate the missing Xcode host project on a Mac without replacing LingoGrow Dart source, assets, tests or course content.
- Documented macOS validation requirements for TTS, local storage, file import/export, audio playback, editor dialogs and narrow windows.
- Kept iOS as a separate future Apple-platform preparation task.

# 0.7.4

- Added Linux desktop host files directly to the source package, so Linux builds no longer require `flutter create`.
- Uses Flutter's relocatable bundle install layout under the project build directory instead of `/usr/local`, avoiding normal-user permission failures.
- No course content or Image Bank artwork changes in this release.

# 0.7.3

- Fixed `AlphaLifecycleService.warningStage()` so missed milestone days fall forward to the next stricter warning stage, matching the documented alpha-expiry behavior.
- Expanded alpha-lifecycle regression coverage to include 8, 6, 5, 4 and 2 days before expiry plus the expired state.
- Added `unlock_service_test.dart` covering first-Chapter access, Topic-completion gating, Duel unlocking, unrelated Topic progress and zero-required-Topic behavior.
- Added `image_bank_service_test.dart` security regression coverage for missing/malformed manifests, unsafe filenames, duplicate IDs, existing IDs, missing assets, unsupported formats, ZIP path traversal, duplicate basenames and import safety limits.
- Hardened the Image Bank preview widget test to avoid an environment-sensitive `pumpAndSettle()` timeout while retaining the preview-open/close assertions.
- No course-content or Image Bank artwork replacement is included in this release; incorrectly cropped bundled artwork remains a separate asset-correction task.

# 0.7.2

- Fixed the Course Info runtime rendering failure caused by placing `LayoutBuilder` inside an `AlertDialog`; responsive fields now use a precomputed narrow/wide layout without intrinsic-dimension callbacks.
- Fixed the remaining analyzer warnings in Course Editor and Weekly XP target settings.
- Added Image Bank enlarged preview with metadata, zoom/pan and an explicit Use image action.
- Increased Image Bank bottom grid padding so the floating Import bank action no longer obscures the last assets on small windows.
- Stabilized Image Bank tile sizing for narrow windows and retained contained, non-cropping image rendering.
- Updated Credits wording to “Project and code design: Quisquisnaut (Quisquis on Discord)” and “Code generation and software development assistance: ChatGPT”.
- Synchronized current documentation and third-party notices for 0.7.2, including the direct `archive` MIT dependency.
- Added regression tests/checks for Course Info layout structure and Image Bank preview behavior.

# 0.7.1

- Added a transparent 30-day alpha lifecycle: this alpha expires on 2026-09-12, warns near expiry, blocks learner exercises/Review after expiry, never deletes local data, and leaves Course Editor available.
- Course Info now shows Source language and Target language as read-only fields.
- Course authors can have multiple roles plus custom roles; role definitions are shown in the editor and documented in Editor Help.
- Added per-Chapter Editor notes for internal technical/editorial information; these notes are never shown to learners, who see the Guidebook instead.
- Removed the unintended visible `Learner (0)` Status. `Apprentice` is now the first Status at zero progress while later rank thresholds remain unchanged.
- Added/updated tests, audit checks and documentation for alpha lifecycle, multi-role authors, Chapter editor notes and the corrected ten-rank Status sequence.
- Re-ran static security, consistency, narrow-screen and platform-boundary review for the changed paths.

# 0.7.0

- Set project and code authorship consistently to Quisquisnaut (Quisquis on Discord), with ChatGPT credited for software development assistance.
- Performed a security/edge-case hardening pass: bounded Image Bank ZIP imports, rejected unsafe/archive-traversal filenames and duplicate basenames, and tightened learner-backup import limits.
- Added Course Info metadata edge-case audit checks for author lists, unusually long fields, course descriptions and invalid last-updated dates.
- Improved narrow-screen behavior in Course Info, Chapter editor cards, Duel status and missing-image notices to reduce RenderFlex overflow risk.
- Reviewed and synchronized current documentation for 15-exercise rounds, 0-2 Word Blocks distractors, current 25-exercise/four-life Duel rules, MPL-2.0 scope and platform limitations.
- Clarified platform support: Android, Windows and Linux are primary targets; iOS/macOS require macOS/Xcode validation; Web remains experimental while native file-import authoring features are present.

# 0.6.9

- Changed LingoGrow software source licensing from GPL-3.0 to MPL-2.0; course content, Image Bank and other assets remain separately licensed.
- Added structured multi-author Course Info with per-author roles and custom roles, plus language variant, levels, course version, last-updated date and description.
- Added stable Course Audit codes and documented audit severity/codes in Course Editor Help.
- Language Duel audit now requires 25 unique candidates, matching the 25-exercise / 4-life learner Duel.
- Added authoring guidance/audit for accidental Round duplicates, isolated-word capitalization and Opposite exercises used too early.
- Expanded Course Editor Help with Round, distractor, source-language, progression, Listening Spelling, metadata and audit rules.
- Weekly XP now celebrates the first crossing of the learner's weekly target once per week.
- Bundled sample courses were normalized for isolated-word lowercase and reviewed for early Opposite/duplicate content.

# 0.6.8

- Added Learner Status and slowed Status progression by at least an order of magnitude.
- Home now labels weekly XP explicitly as “Week XP · All courses”.
- Added Gap Choice: a target-language sentence with a missing element and one semantically and grammatically correct answer block.
- Image Word letter/syllable composition now forbids distractor blocks; bundled samples were updated accordingly.
- Typed-answer checking tolerates a missing diacritic but rejects a wrong diacritic; meaningful spaces and apostrophes remain significant.
- Bundled Italian isolated common-word options keep creator-entered lowercase instead of automatic capitalization.
- Opposite exercises now use explicit source-language instructions such as “Choose the opposite” and “Match each word with its opposite”.
- Topic images are guaranteed in bundled sample Topics.
- Image Credits no longer use A-Z pages and instead list images/decorative assets actually in use.
- Added editable per-course author/license metadata with common-license menu plus Custom license.
- Info now distinguishes per-language progress from all-course weekly XP and points editor users to Course Editor Help.
- Course Editor Help was updated for Import/Export, licensing, Image Word, Gap Choice, Audio Library and exercise transfer behavior.
- Fixed Android/iOS learner Export/Import by using picker bytes when mobile storage is not exposed as a normal filesystem path.
- Hardened Android/iOS MP3 import, fixed bundled MP3 playback by using Flutter AssetSource for asset recordings, and improved Android TTS locale fallback/completion behavior.
- Fixed Learners bottom-sheet overflow and reduced the Android Add profile lifecycle race.
- Copy and Move are separate exercise actions. They use an explicit transfer buffer and a Paste action in the destination Round rather than duplicating immediately below the source.

# 0.6.7

- Fixed Course Audit tests for current Audio Match duplicate diagnostics.
- Course Audit and Course Editor now enforce the documented Word Block rule of 0, 1 or at most 2 distractors.
- Removed unused legacy public-domain bicycle, coffee-cup and train exercise images and their credits; the olive-tree artwork and credit remain.

# 0.6.6

- Exercise type and standardized instructions are shown in the course source language.
- Corrected target-language instruction leakage in bundled courses, including German; Spanish-source course instructions are now Spanish.
- Audio Match answer options are shuffled for every exercise presentation.
- Home metrics refresh when the learner returns from the course flow after completing exercises.
- Audio Library and Image Bank are authoring tools inside Course Editor, not top-level Settings items.
- Built-in Image Bank manifest now exposes all 113 bundled images.

# v0.6.5+65

- Fixed Week XP and weekly target values in the Home status card.
- Fixed nullable ZIP byte handling in Image Bank import.
- No feature removals from v0.6.4.

# 0.6.4+64

- Standard round length 15.
- Duel 25 exercises, 4 lives.
- Weekly XP groundwork and per-user weekly target default 1000.
- Status number shown from Apprentice (0) to Guru (9).
- Listening Spelling exercise.
- Per-course editor lock persistence API, default locked.
- External Course Pack architecture and per-course author/license metadata specification.
- Block distractor rule documented: 0-2, progressive by Topic round.
- Sample courses regenerated to 15 exercises per round.

# Changelog

## 0.6.1+61

- Added separate Image Bank ZIP import so vocabulary assets and manifests can be updated without recompiling LingoGrow.
- Image Bank import validates IDs, referenced files, supported formats and the 50 KB image maximum.
- Missing external image assets now produce a visible warning.
- Added Course Editor Help and moved editor-specific guidance out of general Info.
- Added Image Word: build the target-language word from letter/syllable blocks while viewing an image.
- Added Topic images to all bundled sample courses and an Image Word sample exercise to each course.
- Raised maximum imported image size from 30 KB to 50 KB.


## 0.6.0+60
- Added Missing Word listening exercise with one or more blanks, TTS/recorded/hybrid audio, editor fields and audit checks.
- Settings now exposes Audio Library and Image Bank together for unlocked creators; removed the separate Welcome switch.
- Welcome now reads the actual package version and uses the shared one-time-notice reset.
- Info now documents local course edit overwrite behavior, learner-backup exclusions, and image import specifications.
- Image import now enforces a 30 KB maximum and reports oversized resolution guidance.

## 0.5.9+59
- Settings reads the displayed version from package metadata.
- Removed the legacy Six Fairy Tales credits and automatic translation-character fallback.
- Replaced the misleading generated image bank with a smaller verified flat set; no numbered fake variants remain.
- Added Image Bank to the Course Editor menu with alphabetical browsing, A-Z quick access, import and deletion of imported images.
- Topics can now use an image from Image Bank or an imported image.
- Audio Library retains MP3 preview, alphabetical sorting and A-Z quick access.
- Build Sentences Check is enabled whenever at least one block is selected.

# LingoGrow 0.5.5

- Enlarged Translation exercise illustrations while preserving their aspect ratio.
- Added a detailed Audio Library explanation to Info.
- Removed the 10-tap unlock instructions from Info.
- Course Editor now shows the sample-content warning every time it opens while any Chapter still carries the TEMPORARY SAMPLE badge; the warning stops only after all such badges are removed.
- Replaced editor action labels `Done` with `Save` where the action commits edited content.
- Version bumped to 0.5.5+55.

# 0.5.3

- Fixed Course Editor 10-tap unlock: no five-second timeout.
- Audio Library is now directly visible in Course Editor.
- Added learner Export my data / Import my data controls.
- Bundled sample course revisions replace stale local sample overrides from older bundled versions.
- Added per-learner, per-course update notice keyed by content revision.
- All bundled courses are capped at three Chapters and explicitly marked TEMPORARY SAMPLE.
- Retained MP3 import, longest-match concatenation, Hybrid fallback and orphan-file review/delete flow.

# 0.5.2

- Added creator-recorded MP3 Audio Library with TTS/recorded/hybrid modes and longest-match concatenation.
- Added periodic orphan MP3 detection and confirmed cleanup.
- Round header now includes course language and Chapter number.
- Reconfirmed 10-tap Course Editor unlock and release checks.
- Bundled sample courses remain capped at three TEMPORARY SAMPLE Chapters.

# 0.5.1

- Regenerated all eight bundled courses as three-Chapter TEMPORARY SAMPLE courses.
- Added removable TEMPORARY SAMPLE Chapter badges.
- Added Course Audit category filters.
- Added Round and single-exercise Preview mode with no learner progress writes.
- Added first-open Course Editor sample-content notice and reset-one-time-notices action.
- Renamed Startup animation setting to Animations and broadened it to course-entry animation.
- Added Duel suspense sound.
- Compacted Jump freely panel.
- Preserved optional multi-exercise generation from Reading comprehension.
- Addressed analyzer lint reports carried over from 0.5.0.

# Changelog

## 0.5.0
- Consolidated the latest 0.4.x work into the 0.5 line.
- Added a richer olive-and-flags startup animation with IT, DE, ES, PT, NL, CY, UK English and FI.
- Added a short target-language flag transition after Go to course.
- Added Finnish plus editable empty Welsh, Dutch and Portuguese course shells.
- Reworked the Union Jack artwork and shared flag rendering across selectors and backgrounds.
- Made Chapter and Topic flag backgrounds more recognizable and saturated while retaining readable overlays.
- Made Home cards more transparent and their important text bolder.
- Made Language Duel panels semitransparent and topic titles bold.
- Automatically shows each Chapter Guidebook on first open per learner/language/Chapter.
- Added per-language learner reset without touching other languages, avatar settings or course edits.
- Added Windows System.Speech TTS backend to avoid the flutter_tts Windows platform-thread error.
- Added voice preference and Test voice support, including female/male preference.
- Added Skip all TTS exercises; zero-error attempts with skipped audio receive a separate leaf mark and cannot earn a new laurel.
- Added victory sound when a new laurel crown is first earned and when Course Editor is unlocked.
- Fixed Word Blocks so the Check button becomes available after the correct number of sentence blocks is selected, leaving the distractor unused.
- Retained Review priority by latest error count across up to 50 distinct rounds.
- Added more Topic-page decorative scene variations and flag-inspired Topic backgrounds.
- Reorganized Image Credits into Olive + Status Avatar notes plus A-Z subpages.
- Added project/AI attribution and clarified that course content is created by human authors.
- Added GPL-3.0 LICENSE, third-party notices, licensing documentation and recorded-audio-pack architecture notes.
- Kept Course Editor as an unlockable mode in one app; supports empty courses, Guidebook editing and create/delete/reorder across all course hierarchy levels.

# 0.4.25

- Revised all bundled Word Blocks in Italian, German, Spanish and Spanish→English courses.
- Every Word Blocks exercise has exactly one distractor, and the distractor is now selected from the same language as the visible blocks.
- Re-shuffled Word Blocks deterministically so the distractor is not systematically the last block.
- Added an offline validator check for high-confidence source/target-language distractor mismatches.
- Reviewed capitalization in explicitly paired course material. Sentence/expression pairs in Italian, Spanish and Spanish→English now use consistent initial capitalization; German greeting pairs were aligned without altering normal German noun capitalization.
- Revalidated all four bundled courses: 10 exercises per round, at least one Reading comprehension and one Listening comprehension per round, valid IDs, Audio Match uniqueness and Word Blocks invariants.
- Bundled course data version updated to 0.4.25.
- Application version 0.4.25+41.

# 0.4.24

- Migrated all Course Editor reorder lists from deprecated `onReorder` to Flutter's `onReorderItem`.
- Removed the legacy manual `newIndex` decrement, preventing double index adjustment when moving chapters, topics, rounds or exercises downward.
- Fixed the asynchronous `BuildContext` analyzer issue in the Course Editor copy/reset actions by checking context validity after awaits.
- Added braces to the compact flow-control blocks flagged by current Dart/Flutter lints.
- Expanded defensive formatting in the exercise editor save/audit path and preserved context-safety after dialogs.
- Retains the v0.4.23 structural Course Editor: create/delete/reorder chapters, topics, rounds and exercises; exercise type locked after creation; Guidebook editing.
- Bundled course JSON validation passes for Italian, German, Spanish and Spanish → English.
- Version 0.4.24+40.

## 0.4.22
- Audio Match now requires three different spoken words/phrases and five different visible choices.
- Course Audit reports repeated Audio Match sounds, repeated correct matches, and duplicate visible choices as Errors.
- Fixed duplicate Audio Match content in the bundled Italian and German sample courses.
- Added an automated audit test covering duplicate sounds and choices.
- Retains the v0.4.21 analyzer/Settings fixes.
- Version 0.4.22+38.

# 0.4.20

- Reorganized Home into a compact dashboard with source → target course selector, language-specific Status, streak, total study days, completed rounds and XP.
- Added 10 medieval Status ranks from Apprentice to Guru, calculated per learner + language from XP, streak, distinct study days and completed rounds.
- Added per-profile Status appearance settings: 3 skin tones × 2 hair tones.
- Added Info page explaining metrics, multilingual streak freeze, Status, source/target languages, Review and Duel rules.
- Added reserved Course authors entries to Credits, including the Spanish → English course.
- Added English (UK) target course with Spanish as source language.
- Implemented multilingual streak freeze: studying another language freezes, rather than resets, the untouched language streak; a full no-study day breaks it.
- Added defensive course parsing, safer profile/XP handling, corrupt local editor-patch recovery and shell-free Linux TTS executable discovery.
- Added Course Audit with Error / Warning / Suggestion levels, clickable round locations, per-exercise pre-save audit and outdated-audit state after edits.
- Course Audit checks IDs, round lengths, choice indexes/options, hints that reveal answers, TTS requirements, word blocks, matching, Audio Match, icons, Duel candidate counts and other authoring edge cases.
- Learner-facing rounds now skip structurally invalid locally edited exercises rather than crashing; a fully invalid round displays an authoring-audit message.
- Replaced the fixed Home Info/Credits row with a wrapping layout to reduce overflow risk on narrow windows and large text scales.
- Added extensive inline documentation comments around progress, Status, editing, validation, TTS and layout decisions.
- Version 0.4.20+36.

# 0.4.19

- Added English with UK flag.
- Added a full Spanish → English sample course with explicit sourceLanguage and targetLanguage metadata.
- English target TTS uses en-GB while Spanish remains the source language for instructions and translations.

# 0.4.18

- Added a Home link to a dedicated recent-round Review page.
- Stores recent completed rounds separately for every local learner profile.
- Review shows up to the 20 most recently completed rounds for the selected course, ordered from the least recent of those 20 to the most recent.
- Repeating a round moves it to the most-recent position instead of creating duplicate entries.

# 0.4.17

- Course Editor can now keep more than 10 exercises in a round. Ten remains the standard round length, but exceeding it only shows a warning; no exercise is removed automatically and saving is allowed.
- Exercise insertion positions now extend through the full current round, including rounds already longer than 10 exercises.

# 0.4.16

- Added an in-app local Course Editor under Settings.
- Authors can browse chapter > topic > round, edit any exercise, and insert a new exercise at a chosen position.
- The editor preserves the 10-exercise round rule: inserting into a full round shifts later exercises and removes the final exercise only after confirmation.
- Supports all current exercise types and their fields, including flashcards, Audio Match, listening/reading comprehension, matching, word blocks, icons, TTS, hints, and accepted answers.
- Course edits are stored locally and overlaid on bundled course JSON at load time. Bundled course assets are never modified.
- Added Copy edits as JSON and Reset local edits commands.

# 0.4.15

- Fixed Spanish course selection and removed implicit Italian fallback.
- Course codes are normalized and unsupported languages now fail explicitly.
- Language switching loads the selected course before replacing the current course, avoiding stale Italian content.
- Spanish remains a full bundled sample course with es-ES TTS.
- Version 0.4.15+31.

# 0.4.13

- Added a Home-accessible Credits screen documenting bundled images and sounds.
- Added original local Duel win/loss sound effects and an independent Sound effects setting.
- Made the LingoGrow title area transparent so the olive background remains visible.
- Increased the visibility of Italian and German flag backgrounds on Chapter pages.
- Updated the three-lives loss message to “Duel lost. You’ve lost all three lives.”
- Added media credit documentation in `docs/MEDIA_CREDITS.md`.
- Version 0.4.13+29.

# 0.4.12

- Windows and desktop UI constrained to a portrait learning column; Windows window defaults to 430×800.
- Windows TTS explicitly selects an installed voice matching the active course locale and refuses a wrong-language fallback.
- Language Duel keeps the 7/10 threshold, removes duplicate questions within one duel, and adds three person life icons; each error removes one life and the third ends the duel.
- Added flashcard exercises with pronunciation, meaning, usage sentence, usage pronunciation, Got it and Review again.
- Regenerated reading-comprehension items into contextual mini-passages that test meaning rather than literal phrase spotting.
- Added verified public-domain coffee, train and bicycle images to visual exercises, with source notes.
- Existing flag chapter backgrounds, duel background, translucent Home cards and course-specific Duel logic retained.
- Version 0.4.12+28.

# 0.4.11

- Language Duels now draw questions from the active course and chapter; German duels no longer use Italian fallback content.
- Added a light illustrated duel backdrop with two plant fighters.
- Individual Chapter pages now use the active course flag as a full-page translucent background.
- Home streak and Go to course cards are translucent so the olive artwork remains visible.
- Reading-comprehension samples were regenerated to require interpreting the target-language text instead of merely spotting an identical answer.
- Version 0.4.11+27.

# 0.4.10

- Fixed the remaining 1–3 px bottom RenderFlex overflow in the Home language selector on phone-sized Linux windows.
- Reduced vertical padding and label line height inside language chips without changing the selector behavior.
- Version 0.4.10+26.

# 0.4.9
- Regenerated Italian and German A1 sample courses with 8 chapters each.
- Every normal round now contains exactly 10 exercises; mistake review remains additional.
- Added reading comprehension and expanded listening comprehension.
- Added word-block translation in both directions and English-prompt picture/icon exercises with target-language options.
- Home now says “Go to course”, has a stronger visible olive background, and keeps the language strip horizontally draggable with mouse/touch.
- Removed English/UK from the course selector; Finnish is not included.
- Added a selectable German sample course.
- Added six playful plant illustrations to topic screens.
- Replaced giveaway fill-in hints with semantic English clues.
- Preserved scrollable round/review layout to prevent bottom overflow on short phone-sized windows.
- Version 0.4.9+25.

# 0.4.8
- Home no longer lists chapters or uses the “My Path” heading; it links to a dedicated Chapters page.
- Added a bright Chapters-page background and chapter progress cards.
- Expanded the sample Italian course from 3 to 8 chapters with Food & Cafés, Around Town, Daily Life, Shopping, and Travel.
- New sample chapters include Guidebooks, rounds, mixed exercises, and listening comprehension.

# 0.4.7

- Restored the supplied olive illustration as a true Home-page background with a readability veil.
- Made Home vertically scrollable and SafeArea-aware to prevent bottom overflow.
- Made the language selector explicitly horizontally scrollable on touch and mouse, with a visible scrollbar.
- Added `listening_comprehension` exercises with replayable audio and randomized comprehension choices.
- Added sample listening-comprehension items to all three sample chapters.

# 0.4.6

- Added a project-owned Flutter widget smoke test so `flutter create --platforms=... .` does not leave the default template test referencing a nonexistent `MyApp` class.
- Prevents `flutter test` from failing with `Couldn't find constructor 'MyApp'`.
- No UI or course-logic changes.

# 0.4.5

- Fixed bottom RenderFlex overflow on exercise and review screens by making the full body vertically scrollable and SafeArea-aware.
- Kept feedback and round navigation inside the scrollable content so short Linux phone-size windows and larger text scales remain usable.

# Changelog

## 0.4.4

- Linux TTS now renders eSpeak/eSpeak NG to a temporary WAV and plays it through ALSA `plughw:0,0`, with default-device fallback.
- Fill-in answers now accept either the requested missing fragment or the complete phrase when supplied by the exercise, while still ignoring capitalization, punctuation, accents, and redundant spaces.
- Fixed narrow-phone overflow in Match the expressions by stacking prompt and selector when needed.
- Random order is now genuinely unconstrained for exercise queues, duel questions, choices, matching items, and sentence tokens, so the original order is allowed as a random result.
- Learner deletion now requires confirmation.
- Retains guidebooks, multi-language selector, compact olive-background home, profiles, streaks, review pass, correct-answer feedback, autumn round backgrounds, bilingual duels, icon exercises, and cross-platform optional TTS.

## 0.4.3
- Option shuffles are now purely random and may legitimately reproduce the original source order.
- This applies to multiple-choice options, listening options, matching choices, sentence-building tokens, and Language Duel choices.

## 0.4.2

- Compact home hero with the supplied olive illustration used as a background layer.
- Horizontally scrollable language selector expanded to English, German, Italian, Spanish, Welsh, Dutch, and Portuguese.
- Added a Guidebook to every chapter with goals, vocabulary, grammar, useful expressions, and examples.
- Guidebooks are reference-only and do not affect progress, XP, streaks, or unlocking.

# 0.4.1

- Added documented TTS support for Android, iOS/iPadOS, macOS, Windows, Linux and Web.
- TTS remains optional and can be disabled in Settings at any time.
- Linux keeps the lightweight eSpeak NG/eSpeak backend.
- Android/iOS/macOS/Windows/Web use `flutter_tts` and the system/browser voice engine.
- Made TTS/platform diagnostics web-safe and updated platform-neutral audio error messages.
- Added `docs/TTS_ALL_PLATFORMS.md` with setup and troubleshooting instructions.

# 0.4.0

- Compact multi-learner home with local profiles and streak.
- Round-specific autumn pastel backgrounds.
- Botanical chapter background.
- Responsive matching layout.
- Answer normalization ignores case, punctuation, accents and extra spaces.
- One-time mistake-review notice.
- Bilingual randomized Language Duel.
- New icon-choice exercises.

## 0.3.9
- Force answer options to appear in a different order from the course source whenever there are at least two options.
- Randomize the exercise order within each round.
- Randomize both sides of matching exercises.
- Randomize Language Duel exercise order and answer options.
- Keep the existing rule that Build the sentence never starts in the correct order.

## 0.3.8

- Word-order exercises now always start in a randomized order different from the correct answer.

# Changelog

## 0.3.7

- Moved all language flags out of the olive artwork so the supplied botanical illustration is never covered.
- Added a visible language selector below the hero image: English, German, Italian, Spanish and Welsh.
- Italian is selected by default because it is the sample course currently bundled with the app; unavailable languages show a short explanatory message.
- Updated the antiX/Linux preview note to reflect that Linux TTS is now supported.

## 0.3.5

- Linux preview now opens in a centered phone-sized window (390 x 700) instead of filling the desktop.

# 0.3.4

- Fixed Linux compilation with current Flutter SDKs by explicitly importing `FlutterError` from `package:flutter/foundation.dart` in the course loader.
- No functional or UI changes.


## 0.3.3
- Added Welsh flag to the olive-tree language badges.
- Added "Courses made by humans." to the home artwork.
- Changed "Jump freely in the tree" to the more natural "Jump freely around the tree".
- Preserved the original small olive-tree image asset unchanged.


## 0.3.2
- Report confirmation now says: "Copied to clipboard. You can paste it into your report."

## 0.3.1
- Added a one-tap report button to normal exercise screens and Language Duel exercises.
- Added separate Course error and App bug report choices.
- Reports copy diagnostic context to the clipboard instead of sending data anywhere.
- Copied reports include app and course versions, platform, chapter, topic, round, exercise ID and position, exercise type, visible content, and current answer state.
- Added self-explanatory instructions and a confirmation message after copying.
- No account, network service, or new dependency is required.

## 0.3.0
- Renamed the app UI to LingoGrow.
- Added olive-tree home artwork using the supplied small source image unchanged.
- Added runtime UK, German, Italian and Spanish flag overlays.
- Added prominent streak and local/no-account messaging.
- Added a chapter-level branching tree screen.
- Made free movement among all topics and rounds inside unlocked chapters explicit.
- Added an in-tree Language Duel gate that unlocks the next chapter when won.
- Kept the existing offline progress, TTS setting, diagnostics, course data and antiX/Linux preview behavior.


## 0.2.0
- Added realistic Italian sample course.
- Added 3 chapters, 11 topics, 33 rounds, and 165 exercises.
- Added multiple exercise types: choice, listening choice, fill blank, word order, and matching.
- Updated round renderer for multiple exercise types.
- Updated duel engine to draw from suitable chapter exercises.
- Preserved offline-first architecture and local progress.
- Version bumped to 0.2.0.

## 0.1.3
- Added centralized application error codes.
- Added local diagnostic logging.
- Added user-facing error dialogs with codes.
- Added duel validation error handling.
- Added TTS error logging.
- Added diagnostic log path and clear-log control in Settings.
- Logs remain entirely on-device.
- Version bumped to 0.1.3.

## 0.1.2
- Added persistent user TTS enable/disable setting.
- Added Settings screen.
- TTS generation now respects the user setting.
- Default TTS state is enabled.
- No learner data leaves the device.

## 0.1.1
- Added Linux desktop preview compatibility.
- Disabled TTS on Linux preview instead of failing.
- Added Linux preview banner.
- Preserved mobile TTS caching logic for iOS and Android.
- No changes to chapter, topic, round, exercise, duel, quest, streak, XP, or local-storage logic.

## 0.3.6
- Enabled Linux text-to-speech through eSpeak NG/eSpeak, with automatic playback for listening exercises and a replay button.
- Added visible hints to Complete the phrase / fill-in exercises.
- Incorrect answers now show the correct answer before continuing.
- Randomized multiple-choice options, matching options, and word-order tokens when exercises are presented.
- Added one immediate review pass at the end of each round containing only exercises missed on the first pass.
- Added soft autumn pastel exercise backgrounds while keeping dark, high-contrast text.

## 0.5.6+56
- Build Sentences Check remains available whenever the required number of blocks is selected, including wrong orders and distractor choices.
- Flashcards no longer use correct/incorrect semantics; Review again explicitly says the card will return later in the round and requeues it.
- Added a versioned Home welcome notice with a random approved phrase on first launch of each app version.
- Added Settings control to show the current welcome notice again.
- Removed the rejected first Translation illustration from the asset set and rotation.

## 0.5.8+58
- Audio Library now previews imported MP3 files with Play/Stop controls.
- Recorded clips are sorted alphabetically by associated word or expression.
- Added an alphabet jump bar; unassigned MP3 files are grouped separately.
- Retains the 1,000-asset lightweight flat image library and editor image picker introduced in 0.5.7.
- Build Sentences Check remains available whenever at least one word block is selected.


## v0.6.3
- Language Duel: 20 exercises, 4 lives, no score threshold.
- Audio Match: no distractors; target audio may match target-language text or translated text.
- Added Word Match: exactly three source-to-target translation pairs.
- Added Super Match: exactly three target-language relationship pairs such as synonyms or opposites.
- Sample rounds regenerated at 13 exercises with examples of the new match types.
