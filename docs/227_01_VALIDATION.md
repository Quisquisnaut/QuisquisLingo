# QQL 227.01 Learner Panel controls baseline and validation

## Contract and immutable parent

Date: 7 September 2026. Existing checkout: `C:\Users\ansa\Downloads\QQL\QuisquisLingo_source`, branch `main`. Inspection began with a clean working tree at `259160354b2d3d20da664551969697358127d93e` (`2.0.26+226042`). No worktree, staging, commit, push or packaging is included.

The supplied `qql_227_prompt.txt` defines an implementation audit, documentation and focused characterization phase. Subsequent direct user instructions explicitly add one correction: **Flag Background must be per user × Course, initialized Off, with a clean cut**. The user also confirms **Theme per user, initialized Default**, and **IDDQD per user × Course, initialized Off**; those latter two already match the parent. These direct instructions control the delivered scope.

Target metadata follows the existing phase/revision convention: Version `2.0.27`, Phase `227.01`, revision `0`, numeric platform build `227010`, pubspec `2.0.27+227010`. Course Model stays v6 and the Audit registry stays at 102 rules.

The prompt allows an Alpha change when the established release process requires it. `AGENTS.md` explicitly requires refreshing expiry for every app-version change and preserving the existing lifetime policy. Accordingly this new release retains the **30-day lifetime**, from September 7 to **2026-10-07 23:59:59 local time**, instead of inheriting the parent's October 6 date. Only the date and matching metadata/test/documentation expectations change; lifecycle gates and warning semantics do not.

## Discrepancies established before changes

| Prompt assumption or question | Immediate-parent implementation | 227.01 disposition |
| --- | --- | --- |
| Flag Background may have Default/per-Course semantics | Three modes Small / Off / Extended; missing/unknown string means Small; one preference per learner shared across Courses | Explicit user correction: same three modes, per learner × Course, Off initialization, clean cut |
| Theme offers Auto / Light / Dark | Exact labels are **Default / Light / Dark**; `defaultMode` stores `default` and maps to `ThemeMode.system` | Preserve labels, storage, per-learner scope and live system behavior; do not introduce Auto or System labels |
| IDDQD might have Default or dormant View Only values | Boolean false/true, displayed Off/On; no IDDQD enum or View Only value | Preserve; document the separate existing three-tap preview |
| Flag-derived palette/contrast behavior may exist | Literal flag artwork plus theme-dependent veils/surfaces; no palette extraction or image-dependent contrast classifier | Characterize existing behavior; no Tinted or Inspired implementation |

These are repository findings, not permission to pre-build later roadmap features. The repository roadmap had no detailed 227 controls contract before this phase; its new 227.01 entry points to this baseline rather than inventing 227.02–227.04 designs.

## Exact options and defaults

| Family | Displayed tooltip / semantics label | Internal representation | Effect |
| --- | --- | --- | --- |
| Flag | `Flag background: Small` | `LearnerFlagBackgroundMode.small`, string `small` | Selected Course flag with `BoxFit.contain` |
| Flag | `Flag background: Off` | `LearnerFlagBackgroundMode.off`, string `off` | No flag backdrop and no flag veil; theme page background remains |
| Flag | `Flag background: Extended` | `LearnerFlagBackgroundMode.extended`, string `extended` | Selected Course flag with `BoxFit.cover` |
| IDDQD | `IDDQD: Off` | Boolean `false` | Genuine Lesson access rules apply |
| IDDQD | `IDDQD: On` | Boolean `true` | Walk through Lesson locks while preserving genuine lock/progression state |
| Theme | `Theme: Default` | `LearnerThemeMode.defaultMode`, string `default` | Follow current system/platform brightness |
| Theme | `Theme: Light` | `LearnerThemeMode.light`, string `light` | Force light Material theme and light learner appearance |
| Theme | `Theme: Dark` | `LearnerThemeMode.dark`, string `dark` | Force dark Material theme and dark learner appearance |

Flag cycle remains `Small → Off → Extended → Small`; initialization is now **Off**, so the first tap selects Extended. There is no fourth Default flag option. The former implicit default was Small; the corrected implicit default is Off. IDDQD toggles Off/On and has no separate Default option. Theme cycles `Default → Light → Dark → Default`; the user's Light/Dark clarification does not request reordering.

Theme missing/unknown strings resolve to Default by exact storage-value matching. `auto`, `system`, capitalization changes and padded values are not supported aliases. Flag missing/unknown strings resolve to Off in the new namespace. IDDQD missing values resolve to false. Wrong SharedPreferences value types can throw at typed getters; these are distinct from missing/unknown string values and are not silently migrated.

## Persistence matrix

All three use device-local `SharedPreferences`. `ProfileService` supplies the authoritative opaque UUIDv4 learner prefix `learner_<learnerProfileId>_`; display names, language names and Course titles are not identities.

| Setting | Immediate-parent key and scope | Delivered key and scope | Initialization / existing data |
| --- | --- | --- | --- |
| Flag Background | `learner_<UUID>_flag_background_mode`; per learner, shared across all Courses | `learner_<UUID>_flag_background_mode_course_<courseToken>`; per learner × immutable Course ID | Off for each missing pair; old shared key is untouched, unread, unconverted and never used as fallback |
| IDDQD | `learner_<UUID>_iddqd_<encodedCourseId>`; per learner × Course | Unchanged | False/Off when missing; existing pair choices remain authoritative |
| Theme | `learner_<UUID>_theme_mode`; per learner | Unchanged; shared across that learner's Courses | Default when missing; existing learner choices remain authoritative |

For Flag Background, `courseToken` is the 64-character lowercase SHA-256 hexadecimal digest of the UTF-8 bytes of `courseId.trim()`. This uses the existing crypto dependency. The 92-character suffix stays inside backup-v2's existing 160-character, `[A-Za-z0-9_.:-]` allowance, including Courses whose IDs contain slashes, Unicode or long text. For IDDQD, `encodedCourseId` remains `Uri.encodeComponent(courseId.trim())`; that existing storage is unchanged. Case is preserved in both: distinct case-sensitive IDs remain distinct. Neither a language code nor a `custom:` selector reference substitutes for the resolved Course object's `courseId`. Two Courses with the same language/title and two learners with the same display name must still have separate identities.

The Flag Background API now requires Course context. Without an active learner, appearance reads return their defaults and appearance writes are no-ops. A bottom control without Course context remains Off and cannot create an unscoped flag preference. The IDDQD service continues to require an active learner through `ProfileService.key`; Home displays Off without an active learner. IDDQD's existing service errors are not replaced with a global/default learner namespace.

Preference reads do not eagerly write defaults. Re-instantiating services reloads the same stored values. Logout removes the active learner reference; it does not delete these settings. Existing backup-v2 export/restore copies allowed learner-namespace suffixes generically, so the new scoped flag keys retain their suffixes without a backup-format change. Old shared flag remnants may remain in a backup but are still ignored by the corrected flag reader. The inherited IDDQD encoder can generate `%` characters for unusual Course IDs, which the existing backup decoder omits; that adjacent limitation is recorded without changing IDDQD or backup semantics. Course selection/recent-course storage remains separate and unchanged.

## Flag rendering and contrast baseline

Ownership: `HomeScreen.build`, `CourseFlagBackdrop` / `FlagBackdrop` / `FlagPainter` in `lib/widgets/flag_art.dart`, `WorldFlagRepository`, `WorldFlagArt`, and the import-only validation in `CourseFlagService`.

Home uses opacity **1** for the flag itself; the lower-level backdrop widgets' default `.82` is not the Home value. For Small and Extended, Home overlays the learner theme's `surface` at **.10 in Light** or **.25 in Dark**. Off omits both layers and leaves page background `#F7F3E8` in Light or `#080B09` in Dark.

Source precedence is exact:

1. A nonempty trimmed `course.worldFlagId` takes precedence. `_WorldFlagResolver` asynchronously resolves the local manifest entity; `WorldFlagArt` renders its SVG asset using the requested fit, without a frame. Resolution loading uses an empty expanded placeholder. An unavailable ID gives an empty expanded backdrop with `World Flag unavailable: <id>` semantics. It does **not** fall through to a different flag source.
2. Otherwise a nonempty trimmed `flagImageBase64` is decoded and rendered by `Image.memory`, with the requested fit and `gaplessPlayback: true`. A synchronous Base64 decoding failure falls through to the built-in flag path. Successfully decoded bytes that are not a valid image fail later in the image codec; this widget has no explicit `errorBuilder`, so the surrounding synchronous catch does not provide an image-codec fallback.
3. Otherwise a nonempty `flagCode` is used, or Home's selected-language fallback code when it is blank. `FlagPainter` normalizes trim/case and paints fixed literals for IT, DE, ES, PT, NL, FI, CY, EN/UK and KO/KR. An unsupported or blank final code paints neutral `#E9E2CF`. This painter is not the authoritative World Flags library.

For the built-in painter, Small centers an `AspectRatio`; Extended uses a clipped `FittedBox` with the same ratio. EN/UK is 2:1, DE/CY 5:3, FI 18:11 and other painter codes 3:2. Custom raster images use their intrinsic image proportions; World Flag SVGs retain their asset proportions. Cover may crop; contain may leave surrounding page background visible. There is no tiling or flag stretching policy added here.

| Flag condition | Existing rendering outcome | Contrast treatment |
| --- | --- | --- |
| No explicit flag source | Built-in selected-language flag, or neutral fallback for unsupported code | Ordinary theme veil and foreground surfaces |
| Invalid World Flag ID | Empty/unavailable backdrop; explicit ID is not replaced | Ordinary page/veil; unavailable semantics |
| Malformed Base64 text | Falls back to explicit built-in flag code or selected-language code | Ordinary theme treatment |
| Valid Base64, invalid image bytes | Asynchronous image-codec error; no custom fallback handler | Known existing robustness limit, not fixed in 227.01 |
| Extremely light / extremely dark | Same literal source pixels and .10/.25 veil | No luminance-based adjustment of veil or utility-icon colors |
| Highly saturated / near-monochrome / multicolor / neutral-dominant | Same source selection, fit and fixed veil | No dominant-color, saturation, clustering or neutral-weight classifier |

Foreground protection is theme-based: Round surfaces use .75 opacity, GuideBook and Duel surfaces .70; primary bottom-action surfaces use white .34 in Light / `surfaceContainerHighest` .72 in Dark; compact Theme/Flag/Off-IDDQD surfaces use white .16 / `surfaceContainerHighest` .36. On-IDDQD uses `secondaryContainer`. Utility icon foreground is fixed `#3D704F` in Light and `#9AD5B3` in Dark. `_FlagBackdropText` outlines certain free-standing text with a 2px opposite-luminance stroke based on the **foreground**, not sampled flag pixels. The main Round-path connector has a subtle contrast-support stroke. These mechanisms reduce interference but do not establish a measured contrast guarantee over every arbitrary image.

`CourseFlagService.prepareFlag` validates imported PNG/JPEG content, size and dimensions and normalizes it to a maximum 256px PNG. It does not calculate a learner palette. Bundled flag assets, Course JSON, checksums and import validation are unchanged in this phase.

## IDDQD access and mutation baseline

`SettingsService` stores the Boolean. `HomeScreen._reload` restores it for the resolved Course and learner. The bottom callback changes local UI state immediately, writes the existing pair key, and reverts the local value on an exception. There is no IDDQD-specific progression write or completion shortcut.

`LessonUnlockService.isLessonUnlocked` remains the source of genuine access: the first existing Lesson is unlocked; each later Lesson needs completion of its immediately preceding Lesson or victory in that preceding Lesson's Duel. IDDQD is not an input to that service. Home passes genuine `unlocked` separately from `hasAccess = unlocked || iddqd || previewOnly`. The GuideBook/Lesson lock badge uses genuine `unlocked`, so access granted by IDDQD does not erase the lock indication.

| Learner element | IDDQD On behavior | Independent gates preserved |
| --- | --- | --- |
| Later locked Lesson | Its normal content path becomes accessible | Genuine unlock state and previous-Lesson rule remain unchanged |
| Rounds and their exercises | Existing published Rounds can be opened and studied | Publication projection, active-learner/Alpha gates, exercise rules and scoring |
| GuideBook | Can open an otherwise Lesson-locked GuideBook | `useGuidebook`, Published GuideBook and existing learner-content gates |
| Duel | Can reach the Lesson's available Duel | `createDuels`, actual eligible pool (minimum 25), existing rules and Alpha gate |
| Review | No IDDQD-specific path or filtering override | Existing Review history/selection, evaluation and Alpha gate |
| Draft content / Course Editor locks | No bypass added | Existing publication and authoring boundaries |

The separate pre-existing three-tap Lesson-lock preview is session-memory state keyed by Course ID and Lesson ID. It exposes a specifically activated locked Lesson's layout while disabling Round, GuideBook and Duel interaction. `previewOnly` applies only while genuinely locked **and IDDQD is Off**. It is not a persisted IDDQD mode and no View Only enum exists. Its key does not contain learner ID; that inherited preview scope is documented without changing it in this phase.

## Progression / XP mutation matrix

| Action | Settings writes | Course progression / unlocks | XP / Weekly XP | Streak / study days / Laurels / Review |
| --- | --- | --- | --- | --- |
| Change Flag Background | Only current learner × Course appearance key | None | None | None |
| Change Theme / live system-brightness update | Theme choice writes learner theme key; OS notification itself writes no preference | None | None | None |
| Toggle IDDQD | Only current learner × Course IDDQD key | None; access changes, genuine state stays intact | None | None |
| Open/navigate content using IDDQD | Ordinary navigation state may change | Opening alone does not award completion | None from access alone | Existing GuideBook/visited-Lesson state may change through their normal actions |
| Finish actual study while IDDQD is On | Existing learning persistence | Real Round/Lesson/Duel results persist normally; later genuine unlocks remain after IDDQD is turned Off | Normal calculator/accounting rules apply | Normal activity, streak, Laurel and Review-history rules apply |

`LearningCompletionService`, `ProgressService`, `LearningActivityService` and `XpService` do not special-case IDDQD. The unchanged scoring baseline is 5 XP per first-attempt-correct evaluable exercise on first completion, 2 on repeats/Review, repeatable 5 perfect bonus, one-time 25 first Laurel, one-time 25 first Lesson completion; Duel victories award 50 first / 10 later. An incomplete Round gets no completion award. Visual controls do not call these services to alter progress.

## Theme propagation and responsive assumptions

Theme ownership remains `ProfileService` → `LearnerStatusEvents` → `QuisquisLingoApp` → `MaterialApp` and `LearnerThemeModeScope`. Bottom controls optimistically update their label, persist through the service, and reload presentation on an exception. The app and bottom controls reload on relevant profile/appearance invalidations and reject stale asynchronous presentation loads using generation counters. Appearance changes do not require an app restart.

Default resolves live through `ThemeMode.system`; the current Flutter SDK selects via `MediaQuery.platformBrightnessOf(context)`. Home independently uses the same live platform brightness for Default, and forces the explicit Light/Dark value when selected. Auto is a conceptual description in the supplied prompt, not a UI option or serialized token. There is no clock/sunrise/Day-Night schedule.

`MaterialApp` does not override theme animation settings: the installed SDK (`Flutter 3.47.2`, Dart `3.13.2`) supplies `AnimatedTheme`, 200ms duration and `Curves.linear`. Home also applies its own concrete dark `Theme` and platform-brightness-dependent veil/page constants, so not every local layer is guaranteed to interpolate identically. No transition/animation change is introduced.

The bottom row stays fixed below the expanding lazy Lesson flow, inside SafeArea. It is 68 logical px high, maximum 360 wide, with 12px internal padding, 4px gaps, an expanded Profile action, 40×40 Review/Course Info/IDDQD/Theme/Flag controls and 20px utility icons. Home adds 14px side and 12px bottom padding. Desktop app content is constrained to 430 logical px. Theme and flag changes rebuild appearance without resetting the scroll flow or remounting the learner routes. Existing tests cover 320/375/430px widths and both brightness modes; tiny widths beyond those bounds and native accessibility sizing are not newly certified.

For the scoped Flag Background correction, the resolved Course-aware Home owns the loaded flag choice instead of the app-global appearance loader. The bottom action receives Course context. Dedicated appearance refresh must not use the full progression reload merely to repaint a flag. Course/learner switching restores the appropriate pair, with Off before any choice exists. Theme remains owned at the app level.

Course selection retains the existing asynchronous sequence: `_switchCourse` / `_switchCustomCourse` first set the selected Course, then persist selection and await `_reload`. A new top-bar Course identity can therefore appear before its scoped flag preference finishes restoring. Characterization waits for both the resolved Course and its appearance; it does not treat picker dismissal or a fixed number of pumped frames as completion of that reload. No navigation/loading redesign is included.

## Evidence and validation

Working traceability distinguishes preserved parent behavior from the one user-authorized correction:

| Requirement / risk | Observable evidence | Coverage source | Result |
| --- | --- | --- | --- |
| Exact options, labels, cycles, defaults | Enum/storage and real bottom-widget behavior | Existing `profile_navigation_test.dart` plus new 227.01 characterization | Passed focused and final suite |
| User/Course isolation and clean cut | Pair writes, switch/read/reload, ignored old shared key | New 227.01 tests; existing UUID/settings regressions | Passed focused and final suite |
| Theme Default follows live OS brightness | Change platform brightness in a mounted app; explicit themes ignore it | New 227.01 characterization and existing profile/theme tests | Passed focused and final suite |
| Flag render/fallback behavior | All existing fits/veils, source priority, malformed/absent source paths | Existing learner/flag tests plus new characterization | Passed focused and final suite |
| IDDQD access leaves genuine state intact | Toggle access in Home and inspect actual progress; complete real service study while enabled | Existing `leaderboard_navigation_test.dart`, unlock/completion tests plus new characterization | Passed focused and final suite |
| Visual controls do not mutate learner data | Snapshot persistent data and inspect allowed-key changes | New characterization and existing profile tests | Passed focused and final suite |
| Metadata/30-day policy | Exact pubspec/metadata labels, inclusive expiry day and warning boundaries | Updated metadata, Alpha and welcome-dialog tests | Passed focused and final suite |

Existing baseline coverage includes `profile_navigation_test.dart` (profile isolation/logout, theme/flag cycling, immediate appearance, layout), `settings_service_v5_test.dart` (IDDQD user × Course isolation), `leaderboard_navigation_test.dart` (IDDQD access, true locks, three-tap preview, background fits/veils and selected Course), `unlock_service_test.dart`, `progress_service_test.dart`, `learning_completion_service_test.dart`, and existing World Flag/authoring validation. These tests are evidence only after the fresh runs recorded below; parent totals are not reused as a 227.01 pass.

The immediate parent's committed validation record reports **1,181 passed** and **71 inherited analyzer findings**. Fresh results and the analyzer delta are recorded separately below. Full-suite execution is serialized after affected tests and analyzer review; it is not run repeatedly for documentation wording.

### Added and adapted coverage

`test/learner_panel_controls_227_01_test.dart` adds nine tests:

1. Exact Theme/Flag enum names, labels, stored values, cycles and absent/unknown fallbacks.
2. Theme defaults, independent learners, Course-independent choices and service reload.
3. Flag Background clean cut, ignored-but-preserved shared key, pair isolation, trim/case semantics and reload.
4. New Flag Background keys surviving actual backup export, decoder validation and separate-copy restore with a long Course ID containing unsafe suffix characters.
5. IDDQD Off initialization, pair isolation, trim/case semantics and reload.
6. Real `LearningCompletionService` study with IDDQD On, followed by Off: Round/Lesson completion, Laurel, 60 actual XP, Weekly XP, study day, streak and genuine unlock remain recorded.
7. Mounted application Default Theme follows live light/dark/light platform changes while retaining `ThemeMode.system`.
8. Real Theme/Flag button taps preserve all non-appearance preferences plus explicit progress/XP/activity snapshots.
9. Malformed Base64 uses the built-in fallback; an unavailable explicit World Flag ID remains unavailable instead of substituting a different source.

Existing `profile_navigation_test.dart` and `leaderboard_navigation_test.dart` retain and adapt actual widget coverage for the new Course-aware flag API, Off initialization, course/profile restoration, flag rendering, Theme propagation and responsive controls. Tests concerned with course discovery, publication or selection now use the existing `UnifiedLearnerTopBar.course` as their readiness/identity observation: an Off background is not evidence that Home failed to load. Dedicated appearance tests explicitly choose a visible flag mode when that is what they test. Metadata, Alpha and welcome-notice fixtures follow the new release values.

### Changed-file inventory

| Files | Necessary change |
| --- | --- |
| `lib/services/profile_service.dart` | Course-aware Flag Background API, Off fallback and backup-safe pair key; existing Theme behavior retained |
| `lib/main.dart` | Remove Course-independent flag loading; retain application-level Theme ownership |
| `lib/screens/home_screen.dart` | Load flag choice for the resolved learner/Course pair; dedicated appearance refresh and Course context for bottom controls |
| `lib/widgets/learner_bottom_actions.dart` | Course context, Off initialization, Course-change reload and scoped writes |
| `pubspec.yaml`, `lib/services/app_metadata.dart`, `lib/services/alpha_lifecycle_service.dart` | Phase/revision/version and mandatory 30-day Alpha date refresh |
| `test/learner_panel_controls_227_01_test.dart` (new) | Nine focused behavioral characterizations listed above |
| `test/profile_navigation_test.dart`, `test/leaderboard_navigation_test.dart` | Retained widget behavior with scoped flag/default assertions and valid readiness observations |
| `test/korean_production_discovery_225_03_test.dart`, `test/persisted_learner_delivery_226_04_r1_test.dart`, `test/provisional_mytest_workflow_test.dart` | Preserve course discovery/publication/restart assertions independently of the optional backdrop |
| `test/alpha_lifecycle_test.dart`, `test/app_metadata_225_04_test.dart`, `test/course_audit_report_225_test.dart`, `test/learner_round_path_test.dart` | Release/date expectations and welcome fixture |
| `docs/227_01_VALIDATION.md` (new), `AGENTS.md`, `CHANGELOG.md`, `README.md`, `docs/ROADMAP.md`, `docs/LOGIC.md`, `docs/COURSE_EDITOR.md` | Baseline, authoritative current contract, release references and current expiry |

There is no change to Course assets/model, dependency versions, Settings/IDDQD persistence, backup format, completion orchestration, progress, XP, activity, scoring or genuine unlock implementations. The now-unused public `LearnerFlagBackgroundModeScope` is left intact; removing unrelated public symbols is not required for this correction.

### Fresh execution

Commands use the existing SDK at `C:\Users\ansa\flutter\bin\flutter.bat` and Python at `C:\Python314\python.exe`. Flutter checks use `--no-pub`; there is no dependency/SDK installation, package resolution or global configuration change. Installed package configuration is inherited from the validated parent environment. Flutter/Dart operations are serialized.

| Check | Fresh result and retained log |
| --- | --- |
| New characterization file on final source | **9 passed / 0 failed**, 00:02, exit 0, `test --no-pub --reporter expanded --timeout 60s test/learner_panel_controls_227_01_test.dart`; `build/227010-controls-analyzer-correction.log`. The earlier functional pass is retained as `build/227010-controls-new-test-final.log`. |
| Broader affected set | **178 passed / 3 failed** before the selector test corrections; `build/227010-broader-regression.log`. The failures and their subsequent passing evidence are explained below; this initial run is not claimed as wholly passing. |
| Corrected selector restoration and Editor actions | **2 passed / 0 failed**, 00:09, exit 0, named selection of `selected course restores its learner-scoped flag background\|course selector ends with stable Editor actions without changing selection`; `build/227010-leaderboard-selected-and-actions-final.log` |
| Direct switching/logout restoration | Passed in the affected three-case diagnosis (that run was **2 passed / 1 failed**, with only the Italian-return appearance assertion still failing); `build/227010-leaderboard-affected-final.log`. Its test body was not changed afterward. |
| Bundled Course validator | `python -X utf8 tools/validate_courses.py`: **9 Course Model v6 files valid**, exit 0 |
| Bundled checksum check | `python -X utf8 tools/regenerate_bundled_courses_225_02.py --check`: **all 9 matched**, exit 0 |
| Images | `python -X utf8 tools/validate_images.py`: **112 assets, 0 issues**, exit 0 |
| Lesson icons | `python -X utf8 tools/validate_lesson_icons.py`: **14 assets, 0 issues**, exit 0 |
| Initial analyzer | **72 findings: 71 inherited / 1 new / 0 resolved**, exit 1, 107.6s; `build/227010-analyze-final.log`, `build/227010-analyzer-initial-delta.json`. Removed only the new redundant `dart:typed_data` test import, without suppression, then reran its nine tests as recorded above. |
| Final analyzer after that correction | **71 inherited / 0 new / 0 resolved**, exit 1 solely for the inherited findings (70 Info, 1 Warning, 0 errors), 12.2s; `analyze --no-pub`, `build/227010-analyze-verified.log`, `build/227010-analyzer-final-delta.json` |
| One complete final-tree Flutter suite | **1,190 passed / 0 failed**, exit 0, **13:20**; `test --no-pub --concurrency=1 --reporter expanded --timeout 60s`; `build/227010-full-suite.log`. This is the single complete run and includes all nine added tests. |
| Final diff / unchanged-source verification | `git diff --check`: exit 0. All **252 source/test/config SHA-256 values match** the final pre-suite snapshot in `build/227010-final-source-hashes.json`; no source/test changes followed. `git diff --cached --exit-code`: exit 0; nothing staged. |

The broader set is:

```text
test/leaderboard_navigation_test.dart
test/profile_navigation_test.dart
test/learner_round_path_test.dart
test/settings_service_v5_test.dart
test/progress_service_test.dart
test/progress_time_test.dart
test/unlock_service_test.dart
test/learning_completion_service_test.dart
test/learner_profile_identity_test.dart
test/korean_production_discovery_225_03_test.dart
test/persisted_learner_delivery_226_04_r1_test.dart
test/provisional_mytest_workflow_test.dart
test/alpha_lifecycle_test.dart
test/app_metadata_225_04_test.dart
test/course_audit_report_225_test.dart
test/unified_learner_layout_regression_test.dart
test/unified_learner_top_bar_test.dart
```

It was run with `test --no-pub --reporter expanded --timeout 60s` followed by those paths. Passing groups were not rerun just for reporting; final suite coverage includes them.

Failure classification: the first focused compile attempt lacked the Home appearance-event import; it was fixed before test execution. A subsequent two-file run passed 21 cases and failed only the new live-theme test, which inspected a single frame before the existing 200ms theme transition settled; bounded settling corrected the test. The broader run exposed two old tests using a visible backdrop as course-readiness evidence despite Off being valid. They now observe the real top-bar Course. The course-switch appearance test also needed to await the existing asynchronous preference reload after top-bar selection; it retains assertions for both rendered appearance and unchanged stored IT Small / DE Off choices. No production behavior was changed to satisfy those timing/readiness assertions, and no failed assertion was waived. A mistyped isolated name filter matched no tests and is not counted as a pass (`build/227010-leaderboard-flag-isolation-no-match.log`).

Tooling: the WinGet `rg` executable failed, including the one permitted fresh-shell retry, so inspection used Git searches and .NET text readers without `Get-Content`. An unprivileged Dart-format invocation formatted its target files but could not clean up SDK telemetry outside the workspace; the subsequent scoped-permission format command succeeded. All 16 changed Dart files were formatted, and the final selector edits were formatted again before their final focused run. These environment failures are not test passes or application defects.

Analyzer provenance: the immediate parent's committed `docs/226_04_VALIDATION.md` records 71 inherited findings. Diagnostic comparison uses the retained `build/provisional-analyze-final.log` as a multiset of severity, message, normalized path and diagnostic code, ignoring line/column shifts. Its four diagnostic-containing files (`flat_image_library_screen.dart`, `course_audit_service.dart`, `settings_service.dart`, `guidebook_sentence_generator_test.dart`) are unchanged between `782bc26ed52b0afe5a66f42e194abb64e1092320` and the immediate parent, and are unchanged in this patch. This supports the exact 71/0/0 comparison without creating a worktree or claiming a fresh parent analysis. The one remaining Warning is the inherited unused `_tapAndSettle` helper; the 70 Info findings concern brace style. No inherited cleanup or analyzer suppression is included.

Closure: **227.01 is verified within the stated automated-test and platform limits**. The complete total is the parent's 1,181 tests plus nine new characterizations. The final 24-file change comprises 22 modified tracked files and two new files, all listed above. The existing `main` checkout and HEAD remain unchanged; no staging, commit, push, worktree, packaging or user-data conversion occurred. Documentation closure followed the suite without changing its source/test/config snapshot. Later 227 implementation requires a separate task and must use this corrected scope/default matrix as its baseline.

## Limits to carry into 227.02–227.04

- Preserve the delivered isolation/default matrix: Flag user × Course Off; IDDQD user × Course Off; Theme user Default. No fallback to shared legacy Flag Background data.
- Preserve real progress while IDDQD is On and the separation between true lock state, access and session-only preview. A later View Only design requires an explicit new contract.
- Resolve future naming against actual **Default**, not an assumed existing Auto label. Preserve live system brightness and learner-scoped stored Theme choices unless explicitly changed later.
- Current flags have no color classifier or image-adaptive contrast guarantee; corrupt decoded images and unavailable SVG assets have different failure paths from malformed Base64 and unavailable World Flag IDs. No speculative repair is part of this phase.
- Backup-v2 accepts only a bounded safe suffix alphabet. New Flag Background keys respect it; existing IDDQD keys containing percent-encoded unusual Course IDs can be omitted during backup decode. That inherited behavior needs a separately authorized compatibility decision.
- SharedPreferences mocks and mounted-widget reloads are deterministic automated evidence, not a physical device process-restart certification. Native Windows/Android appearance events, arbitrary-image visual QA, and release packaging remain unclaimed unless separately executed.
- Do not activate Tinted, Inspired, new IDDQD communication, Day/Night, Settings reorganization, Study Day/Stats, Crash Log relocation, Audio Settings or 228+ work from this document.
