# QuisquisLingo 2.0.20+220 release validation report

Date: 1 September 2026

## Release boundary

- The target package version is `2.0.20+220`.
- The mandatory 30-day Alpha lifecycle expires at the end of 1 October 2026.
- Scope is limited to central Profile navigation, the three-action learner bottom area, local logout, Buy a coffee relocation, focused regression coverage and normal release metadata.
- Round cards, the left/right learner path, mascots, mascot discovery and ordering, Laurel, connector, GuideBook/Duel presentation, XP, Review rules, course data and persistence formats remain unchanged.
- The pending Lesson-heading maximum-line roadmap item remains unimplemented.

## Profile navigation

- Home's former Leaderboard action now opens Profile. The learner bottom area contains exactly Profile, Review and Course Info.
- Profile reuses the extracted authoritative learner avatar painter. The bottom representation is 32 x 32 px within the unchanged 68 px control area; the Profile page uses a 112 x 128 px presentation.
- When a renderable appearance is unavailable, the bottom action shows the full active learner name in centered text with two lines and ellipsis, then falls back to the standard person icon when no valid name exists.
- The full learner name remains available through the tooltip, and semantics identify the destination as `Profile, <learner name>` when a learner is active.
- Active-profile and avatar invalidations refresh the bottom action and Profile page without persisting duplicate presentation state.
- Profile links to the existing Avatar, learner-profile management and Gamification destinations. Back navigation from each destination returns to Profile.
- Settings exposes one Profile entry and no longer links directly to Avatar or Learner profiles.

## Local logout and support

- Profile explains that the learner is local, no remote server is contacted and stored profile/progress data remains on the device.
- A concise confirmation offers Cancel and Log out. Cancel leaves the learner active.
- Confirmed logout removes only `active_learner`. It does not delete the learner list, avatar keys, progress, XP, streak, Review state, completion state, Gamification state, courses or other learners.
- Status refresh short-circuits while no learner is active, preventing writes to the fallback `learner_default_*` namespace.
- Home returns to its existing learner flow: stored profiles open the existing selection/create sheet, while an empty profile list opens the existing create dialog. Reselecting the same learner restores the original profile-owned state.
- Buy a coffee moved from the learner bottom area to the lower support area of Course Info. The existing HTTPS validation, external application launch mode and failure messages remain intact.

## Responsive and visual validation

- Focused widget checks cover 320, 375 and 430 logical px in light and dark themes. All three bottom controls stay within the viewport and the control area remains 68 px high at every width.
- Temporary production-widget renders were inspected at all three widths in both themes, then removed. The three controls remain balanced, the 32 px avatar is recognizable without competing with learner content, and the two-line name and person-icon fallbacks remain contained.
- Profile-page renders at all three widths in both themes confirmed avatar/name contrast, readable destination rows and local-logout copy. The narrow page scrolls normally to the logout action.
- Navigation tests cover Home and Settings entry, all three Profile subpages and their back paths, logout confirmation/cancel, the existing learner chooser, unchanged Review and Course Info destinations, and Course Info support launching.
- No preview route, screenshot suite or temporary visual source file remains in the release diff.

## Automated validation

- Final focused coverage passed **73 tests** across Profile/navigation, learner status, Home bottom actions, Alpha lifecycle and QQL 219 learner-path preservation.
- `flutter test --no-pub --reporter compact --timeout 60s` passed **325 tests** in **1 minute 23 seconds**.
- The repository aggregate validator repeated all **325 tests** serially in **2 minutes 7 seconds** and passed all eight bundled course files.
- `flutter analyze --no-pub` reported no errors or warnings. It retained the same **7 pre-existing info-only** `curly_braces_in_flow_control_structures` diagnostics in `course_editor_service.dart`, `profile_service.dart` and `settings_service.dart`; they remain deliberately unchanged.
- `python tools\validate_courses.py` passed all eight bundled Course Model v4 JSON files.
- `python tools\validate_images.py` and the aggregate validator report only the pre-existing missing `assets/exercise_images/hello.webp` among 113 Image Bank assets. Build 219 documented the same unrelated baseline condition, so the asset and its metadata were not changed for 220.
- `git diff --check` passed; LF/CRLF working-copy notices are non-functional.

## Release artifact

- The Windows release was built from an isolated clean snapshot containing `HEAD` plus only the intended 220 source changes. This prevents the unrelated untracked `assets/mascots/monkey_selfie.png` from entering the wholesale mascot asset directory without deleting or modifying that user file.
- `tools\package_windows_release.ps1` completed the release build, added the required VC runtime DLLs, validated package contents, extracted the ZIP and matched extracted files against staging.
- The packaged Flutter assets contain the ten established QQL 219 mascot PNGs and do not contain `monkey_selfie.png`.
- Staged Windows directory: `build/packages/quisquislingo_alpha_220_dev_windows_x64/`
- Windows ZIP: `build/packages/quisquislingo_alpha_220_dev_windows_x64.zip` (24,635,517 bytes)
