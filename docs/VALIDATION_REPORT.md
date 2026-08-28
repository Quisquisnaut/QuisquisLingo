# QuisquisLingo 2.0.13+213 release validation report

Date: 28 August 2026

## Baseline and scope

- Build 213 starts from the clean post-212 `main` branch.
- The package version is `2.0.13+213`.
- The established 30-day Alpha expiry remains at the end of 27 September 2026 because build 213 is prepared on the same date as builds 211 and 212.
- `XpCalculator` is the pure authority for completed-Round breakdowns and first/repeat Topic and Duel awards.
- `LearningCompletionService` persists the exact immutable Round result displayed by `RoundScreen`.
- Existing completed-Round, perfect-Round, completed-Topic and won-Duel course-scoped state determines first versus repeat awards without new persistence keys.
- `XpService` remains the sole XP persistence/accounting boundary and is unchanged.
- Weekly rollover, profile isolation, per-course Weekly XP, language XP, leaderboard aggregation and the learner status-bar layout are unchanged.

## Authoritative XP behavior

- First Round completion: 5 XP per first-attempt-correct evaluable exercise.
- Repeat and Review: 2 XP per first-attempt-correct evaluable exercise.
- Every zero-error completed Round: 5 XP perfect bonus.
- First Laurel for a Round: 25 XP once.
- First Topic completion: 25 XP once.
- Duel victory: 50 XP first, 10 XP on later victories.
- Incomplete Rounds: 0 XP.
- Flashcard and informational/guide content: no base XP and no error, without blocking perfect or Laurel eligibility.

## Validation summary

- The combined targeted Flutter command passed all **70 tests** across `xp_calculator_test.dart`, `learning_completion_service_test.dart`, `round_xp_completion_regression_test.dart`, `topic_completion_regression_test.dart`, `duel_xp_regression_test.dart`, `xp_service_test.dart`, `progress_service_test.dart` and `alpha_lifecycle_test.dart`.
- `flutter analyze` reported the same **7 pre-existing** `curly_braces_in_flow_control_structures` infos in untouched files and no findings in changed files.
- `git diff --check` reported no whitespace errors.
- The complete Flutter test suite was not run, as required by the build-213 scope.
