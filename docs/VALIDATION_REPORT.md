# QuisquisLingo 2.0.12+212 release validation report

Date: 28 August 2026

## Baseline and scope

- Build 212 starts from the clean `2.0.11+211` learner-status-bar release.
- The package version is `2.0.12+212`.
- The established 30-day Alpha expiry remains at the end of 27 September 2026 because builds 211 and 212 are prepared on the same date.
- Current Round, Topic, Duel and perfect-potential XP formulas have been extracted into a pure `XpCalculator`.
- `LearningCompletionService` still resolves attempt and Laurel state, preserves completion ordering, and passes the calculated Round award to the existing progress/accounting boundary.
- `ProgressService` still decides when Topic and Duel completion operations occur and delegates their calculated fixed awards to its existing `XpService` facade.
- `XpService` remains the sole XP persistence/accounting boundary and is unchanged.
- XP values, persistence keys and formats, Weekly XP rollover and aggregation, language XP, profile isolation, leaderboard data, progress state, UI wording and navigation behavior are unchanged.
- The existing 15 XP perfect-repeat potential display versus 25 XP imperfect six-exercise repeat award, followed by a repeated 25 XP Topic award, is characterized and intentionally deferred for XP stabilization.

## Validation summary

- Targeted post-refactor tests passed all 49 selected tests across calculator, completion, XP persistence/rollover, Topic, progress/profile and Alpha lifecycle coverage.
- The focused widget characterization confirmed that the 15 XP perfect-repeat potential text remains visible while the imperfect Round persists 25 XP.
- Repository-wide `flutter analyze` reported 7 pre-existing `curly_braces_in_flow_control_structures` infos in untouched files and no findings in changed files.
- `git diff --check` reported 0 whitespace errors.
- The complete Flutter test suite was not run, as required by the scoped build-212 validation plan.

## Platform notes

- Windows builds `quisquislingo_app.exe`.
- Linux builds `quisquislingo_app` with application ID `com.example.quisquislingo_app`.
- macOS, Android, and iOS platform support and runners remain unchanged.
