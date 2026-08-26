# QuisquisLingo 2.0.10+210 release validation report

Date: 27 August 2026

## Baseline and scope

- Build 210 starts from the verified `2.0.9+209` Phase 2A modularization baseline.
- The package version is `2.0.10+210`.
- The established Alpha expiry is unchanged. Build 210 expires at the end of 25 September 2026.
- Modularization Phase 2B is complete: learning-activity, streak, and study-day logic has been extracted from `ProgressService` into `LearningActivityService`.
- `ProgressService` retains the existing public learning-activity facade and continues to own course progress, completion orchestration, Review state, reset behavior, Guidebook state, leaderboard participation, and other non-activity progress responsibilities.
- `XpService` remains the XP persistence/accounting boundary.
- Existing activity persistence keys and formats, injected-clock behavior, streak/study-day rules, cross-language freeze behavior, duplicate activity registrations, and completion ordering are unchanged.
- Learner-facing behavior, XP/scoring rules, Topic completion rules, Duel rules, reset behavior, UI, navigation, and Course Editor behavior are unchanged.
- Build 210 added characterization coverage before extraction for persistence compatibility, temporal edge cases, cross-language behavior, reset/profile lifecycle, completion side effects, and cross-midnight duplicate registration behavior.
- Build 211 Status Bar, build 212 Streak Celebration, build 213 `XpCalculator`, and build 214 XP formula changes remain separate future roadmap steps.

## Validation summary

- `flutter analyze` reported 0 issues.
- `flutter test` passed all 179 tests across the complete test suite.
- Bundled course validation (`tools/validate_courses.py`) passed with 0 issues across all 8 bundled courses.
- Image Bank validation (`tools/validate_images.py`) passed with 0 issues across all 113 assets.
- `git diff --check` reported 0 whitespace errors.
- Final release-closure review confirmed that no production behavior, persistence format, Alpha expiry, or build-211+ functionality changed during 210E.

## Platform notes

- Windows builds `quisquislingo_app.exe`.
- Linux builds `quisquislingo_app` with application ID `com.example.quisquislingo_app`.
- macOS, Android, and iOS platform support and runners remain unchanged.