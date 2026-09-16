# QQL 236 validation

Validation target: `2.0.36+236000`, **Build 236, Revision 0**.
The 30-day Beta expiry is `2026-10-16 23:59:59` local time.

## Scope

- Startup logo: 1,000 ms fade from transparent to opaque and scale from
  60% to 100%, then 800 ms static hold; no exit fade. Disabled Animations
  and reduced motion retain the static 1,800 ms startup gate.
- Course entry: the shared resolver supplies automatic or explicitly
  selected FlagPainter/World Flags to the unchanged two-second overlay.
  Explicit raster flags remain supported. Invalid explicit sources do not
  gain an automatic fallback. Same-Course selection, startup, disabled
  Animations and reduced motion remain suppressed.
- Course Manager: only its internal-ID toggle is omitted. Help, other
  actions, subordinate ID controls and the persisted preference remain.
- Course Model v9, authored Course JSON, learner persistence, progression,
  XP, Review and Duel behavior are unchanged.

## Regression coverage

- Startup tests check the 60% initial scale, an intermediate entrance frame,
  full opacity/scale at 1,000 ms, static hold and replacement at 1,800 ms.
  Existing disabled-animation and reduced-motion tests retain full-gate checks.
- Course-entry tests cover automatic FlagPainter resolution, automatic
  World Flag resolution, real SVG overlays for both explicit and automatic
  World Flags, neutral/invalid sources and unchanged suppression rules.
- Editor tests check that Course Manager retains Help/Import/Create but no
  ID toggle, preserves an enabled preference and leaves subordinate ID
  visibility and controls intact.
- Metadata and Beta lifecycle expectations track Build 236 and its new expiry.

## Execution

Validated on 2026-09-16 using the installed Flutter tool snapshot directly,
with Flutter commands serialized.

| Check | Result |
| --- | --- |
| `flutter pub get` | PASS |
| `dart format` on touched Dart files | PASS |
| Focused startup, course-entry, Editor ID and Beta lifecycle tests | PASS: 36 tests |
| `flutter analyze --no-pub` | PASS: no issues |
| `flutter test --no-pub --concurrency=1` | PASS: 1,559 tests |
| `python tools/validate_courses.py` | PASS: 10 bundled v9 courses |
| `python tools/validate_images.py` | PASS: 111 assets, 0 issues |
| `python tools/validate_media_assets.py` | PASS: 443 files, 19 locked audio, 281 World Flags, 0 issues |
| `git diff --check` | PASS |

The complete suite ran once after all production/test modifications and
formatting were finished; no production or test files changed afterward.
Flutter's four generated macOS/Windows registrant files are byte-identical
to HEAD and contain no meaningful changes.

## Release packages

- `tools\package_android_debug.ps1` — PASS. Built the Android Debug APK and
  verified the copied APK plus all 11 approved `matXpack` materials before
  archive creation. The release asset is
  `quisquislingo_android_debug_beta_236000.zip` (12 files, 96,167,737 bytes,
  SHA-256 `155C5C54134521F68F2132010F483DE6D7C00D2F9F06EF08A9BB5A547830A4EE`).
  Its APK is `quisquislingo_android_debug_beta_236000.apk`.
- `tools\package_windows_release.ps1 -RebuildFlutterApplication` — PASS.
  Built the frozen `2.0.36+236000` application, verified 477 application
  files / 54,537,516 bytes, passed all 24 launcher unit tests and all four
  packaged-launcher integration tests, and verified launcher dependencies
  in the staged tree and ZIP. The release asset is
  `quisquislingo_windows_beta_236000.zip` (492 files, 27,816,256 bytes,
  SHA-256 `70E0E1DECC2D47730E3100D61B0D99E292D7AAD3529E75070E3F02C20CA99725`).
  The package entry point is `QuisquisLingo.exe`.

The Android Gradle build emitted upstream Java restricted-method and
Flutter-plugin Kotlin compatibility warnings, but completed successfully.
No full Flutter suite was rerun after packaging because the scripts made no
source changes.
