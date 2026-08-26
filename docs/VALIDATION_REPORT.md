# QuisquisLingo 2.0.9+209 release validation report

Date: 26 August 2026

## Baseline and scope

- Build 209 starts from the verified `2.0.8+208` technical rebrand baseline.
- The package version is `2.0.9+209`.
- The established 30-day Alpha policy is unchanged. Build 209 expires at the end of 25 September 2026.
- Phase 2A modularization is complete: Round completion orchestration has been extracted from `RoundScreen` into `LearningCompletionService`.
- UI presentation, user input handling, mistake-review flow, preview-mode dialog, victory sound playback, mounted-lifecycle checks, weekly goal celebration dialog, and route navigation remain in `RoundScreen`.
- Learner behavior, course behavior, XP/scoring rules, Topic completion rules, Duel rules, wallpaper/settings behavior, and Course Editor structure are unchanged.
- Phase 2B modularization (`LearningActivityService` in build 210) and Phase 2C (`XpCalculator` in build 211) remain separate future roadmap steps.

## Validation summary

- Dart formatting was verified on all touched files.
- `flutter pub get` completed cleanly.
- `flutter analyze` reported 0 issues.
- `flutter test` passed all 161 tests across the complete test suite.
- Bundled course validation (`tools/validate_courses.py`) passed with 0 issues across all 8 bundled courses.
- Image Bank validation (`tools/validate_images.py`) passed with 0 issues across all 113 assets.
- `git diff --check` reported 0 whitespace or formatting errors.

## Platform notes

- Windows builds `quisquislingo_app.exe`.
- Linux builds `quisquislingo_app` with application ID `com.example.quisquislingo_app`.
- macOS, Android, and iOS platform support and runners remain unchanged.
