# QuisquisLingo 2.0.21+221 release validation report

Date: 1 September 2026

## Release boundary

- The target package version is `2.0.21+221`.
- The mandatory 30-day Alpha lifecycle expires at the end of 1 October 2026. Builds 220 and 221 were prepared on the same date, so the established policy keeps the same expiry date.
- Scope is limited to learner-panel flag presentation and its per-learner three-state utility, theme veils, Guidebook-owned Lesson identity, Round-card width, surface opacity hierarchy, connector contrast support, fixed bottom layering/inset, Duel-to-next-Guidebook spacing, Laurel artwork, the learner-bottom theme utility, locked-Lesson previews, learner-scoped active-course restoration, focused regression coverage and normal release metadata.
- XP, scoring, Round completion, Duel and Review rules, course formats, learner identity, TTS, mascot selection/artwork, connector geometry and unrelated navigation remain unchanged.

## Learner-panel refinements

- Built-in flags render inside their official or established aspect ratios and are centered in the available backdrop rather than stretched to fill it. Custom flag images use `BoxFit.contain`; neutral surrounding space is retained instead of aggressively cropping the flag.
- One continuous `colorScheme.surface` veil remains between the flag and learner content. Its opacity is `0.25` in dark mode and `0.10` in light mode; foreground content is not faded.
- Standalone in-flow Lesson headings are absent. Every Guidebook owns the correct `Lesson <number>: <title>` identity: the prefix is regular, the title uses weight 900, and the combined identity is limited to two lines with ellipsis. The fixed Lesson selector remains unchanged and no path heading is duplicated.
- The redundant `Your roadmap to <Lesson title>` line remains absent. The centered Guidebook uses 78% of the available width within its existing 400 logical-pixel cap (312 logical px maximum). Its existing avatar is retained; the larger purple `Guidebook` and smaller blue `Start Here` keep distinct styles in one scale-down-only horizontal row, and navigation is unchanged.
- Round-card width is capped at 244 logical pixels. Default card height remains 108 pixels, with the same internal padding, icon, two-line/ellipsis title, completed/perfect states, Laurel, deterministic side placement, connector routing, 28 px vertical gap and tap behavior.
- Round surfaces remain at `0.75` opacity. Guidebook and Duel surfaces use `0.70`; the round-ended behind-content connector keeps its 2 px, `0.55` theme-aware main stroke above a 4 px, `0.32` `colorScheme.surface` support stroke drawn on the identical path; and mascot-container surfaces use `0.10`. Text, icons, Round accents, Laurel artwork and mascot PNGs remain fully opaque.
- The external spacer before each subsequent Lesson divider is 32 logical pixels instead of 20, adding a modest 12-pixel pause after the preceding Duel before the next Guidebook without changing Duel internals, ordinary Round spacing, ordering or navigation.
- The unchanged 68 px bottom controls now occupy structurally reserved space after the learner `ListView` in the shared outer `SafeArea` column. The scroll viewport therefore ends above the controls instead of painting behind them; its retained 112 px bottom padding lets the final Duel scroll completely above the full bottom area and platform safe area without adding a second bar.
- The learner `ListView` keeps its established `AlwaysScrollableScrollPhysics`. The audited coarse Windows touchpad steps come from Flutter's legacy pointer-wheel handling, so no local interpolation, event interception or global scrolling change was introduced.
- Perfect Round artwork now uses two small, subtly arched lateral custom-painted Laurel branches. The existing green perfect icon, icon/frame dimensions and position, `PERFECT` text and perfect-state logic remain unchanged.

## Learner theme mode

- A compact 40 × 40 logical-pixel utility follows the unchanged Profile, Review and Course Info primary actions within the existing 68 px learner bottom area. It remains visibly secondary and fits the 320, 375 and 430 logical-pixel widths in both light and dark appearances.
- The control cycles exactly `Default → Light → Dark → Default`, applies the selected mode immediately to the app and learner panel, and exposes matching current-state icon, tooltip and accessibility text (`Theme: Default`, `Theme: Light` or `Theme: Dark`).
- Default retains Flutter's system-following behavior. Light and Dark are stored only in the existing authoritative active-profile preference namespace; switching profiles restores each learner's choice, local logout retains it, and restart reconstructs it. With no active learner the app uses Default and does not create a synthetic default-profile setting.

## Learner flag background mode

- A separate compact 40 × 40 logical-pixel Flag utility is the far-right learner-bottom control and fits alongside the existing theme control at 320, 375 and 430 logical pixels in both appearances.
- It cycles exactly `Small → Off → Extended → Small` one state per tap. Tooltip and accessibility text report the current state exactly as `Flag background: Small`, `Flag background: Off` or `Flag background: Extended`.
- Small remains the default contained/aspect-ratio-preserving 221 presentation with the current light/dark veil. Off renders neither course flag nor flag-specific veil and exposes the normal neutral learner background. Extended uses `BoxFit.cover` for both built-in and custom flags, preserving aspect ratio while allowing the intentional immersive crop, with the same current theme veil.
- The value uses the active learner's existing preference namespace. Switching learners and reconstructing the service restore each learner's independent choice; no active learner falls back to Small without writing a synthetic default-profile value.

## Locked Lesson preview

- Three taps on the same genuinely locked Lesson heading lock reveal that Lesson in `Preview only / Lesson still locked` mode. Two taps, stale taps and taps split across Lessons do not activate it; the five-second stale-sequence protection remains.
- Preview state is held only in an in-memory app-session set keyed by `courseId` and `topicId`. Multiple specifically activated Lessons remain previewable through learner reload, Lesson changes, scrolling, Guidebook, Round, Duel, Review, App Info, Settings, Profile, Course Info and reconstruction of the learner page. Only application restart/relaunch clears the set.
- The genuine lock remains visible. Guidebook, Round cards and Duel are non-interactive in preview, and Round-path interaction is disabled.
- Tests confirm no Round or Topic completion, XP, Weekly XP, persistence or subsequent-Lesson unlock changes. IDDQD behavior and normal progression remain authoritative and unchanged.

## Learner-scoped active course

- The last active bundled course code or custom `custom:<courseId>` reference is stored in the existing encoded learner namespace rather than the former device-global selection key. Selecting a course updates only the active learner's value.
- Direct A → B and B → A profile switches restore each learner's own course before learner Home is shown. Logout removes only `active_learner`; choosing a learner restores that learner's saved course, and reconstructing the app does the same for the selected learner.
- No compatibility migration or fallback reads the former global active-course preference. Recent-course history remains the established device-wide selector history, while course data, progress, XP, streak, Review and unlock state remain unchanged.

## Responsive and visual validation

- Widget-level render checks cover 320, 375 and 430 logical px in both light and dark themes. They verify contained and extended flag geometry, Off-mode veil omission and neutral background, centered narrower Guidebook bounds, two-line Lesson headings, selector behavior and both secondary appearance controls without horizontal overflow or uncaught layout exceptions. A focused structural check also verifies that the scroll viewport ends above all five bottom controls, their frame remains fixed while scrolling, and the final Duel can clear the controls at every required width.
- The 320 logical-pixel production-widget image capture requested for manual review deadlocked before producing an image, despite the test process exceeding its 60-second timeout. The stuck process was stopped after a bounded wait. In accordance with the user's instruction, no replacement screenshot batch was started.
- No screenshot, render harness, preview entry point or PNG output was created for the post-validation corrections; final visual inspection is reserved for the user on the actual release build.
- The temporary screenshot harness and its output path were removed before packaging. No preview route, screenshot suite or temporary visual source file remains in the release diff.

## Automated validation

- Focused checks passed for the exact flag-state cycle and semantics, per-learner appearance persistence/restart behavior, Small/Off/Extended learner composition, built-in/custom aspect-ratio handling, structurally isolated 320/375/430 scroll/control layouts in both themes, final-content clearance, isolated active-course persistence, direct A → B → A switching and logout/reselect restoration in both directions.
- `flutter test --no-pub --reporter compact --timeout 60s` passed **342 tests** in **2 minutes 23 seconds**.
- `flutter analyze --no-pub` reported no errors or warnings. It retained the same **7 pre-existing info-only** `curly_braces_in_flow_control_structures` diagnostics in `course_editor_service.dart`, `profile_service.dart` and `settings_service.dart`; they remain deliberately unchanged.
- `python tools\validate_courses.py` passed all eight bundled Course Model v4 JSON files.
- `python tools\validate_images.py` reports only the pre-existing missing `assets/exercise_images/hello.webp` among 113 Image Bank assets. Earlier releases document the same unrelated baseline condition, so the asset and its metadata remain unchanged.
- `git diff --check` passed; LF/CRLF working-copy notices are non-functional.

## Release artifact

- The corrected Windows release was rebuilt from the validated 221 working tree after learner-scoped active-course restoration and structural bottom-control isolation were added.
- `tools\package_windows_release.ps1` completed the release build, added the required VC runtime DLLs, validated package contents, extracted the ZIP and matched extracted files against staging.
- The packaged Flutter assets contain the ten established QQL 219 mascots and do not contain `monkey_selfie.png`.
- Staged Windows directory: `build/packages/quisquislingo_alpha_221_dev_windows_x64/`
- Windows ZIP: `build/packages/quisquislingo_alpha_221_dev_windows_x64.zip` (24,766,590 bytes; SHA-256 `2E765ADACBB58470205CED926603F25CC3101C5A298A4C27A416F66E69631FA0`)
