# QuisquisLingo 2.0.14+214 release validation report

Date: 28 August 2026

## Baseline and scope

- Build 214 starts from the clean post-213 `main` branch.
- The package version is `2.0.14+214`.
- The established 30-day Alpha expiry remains at the end of 27 September 2026 because build 214 is prepared on the same date as builds 211–213.
- `XpCalculator` remains the pure authority for the unchanged build-213 Round, Topic and Duel formulas.
- `LearningCompletionService` now includes an applicable first Topic award in the same completion result shown by `RoundScreen`.
- Language XP and learner-global Weekly XP increase by the displayed total before the popup is shown; `TopicScreen` does not grant or communicate the award again.
- Text-entry, status-bar, Home/Gamification navigation and desktop resize changes are scoped to the confirmed build-214 refinements.

## Authoritative XP behavior

- First Round completion: 5 XP per first-attempt-correct evaluable exercise.
- Repeat and Review: 2 XP per first-attempt-correct evaluable exercise.
- Every zero-error completed Round: 5 XP perfect bonus.
- First Laurel for a Round: 25 XP once.
- First Topic completion: 25 XP once.
- Duel victory: 50 XP first, 10 XP on later victories.
- Incomplete Rounds: 0 XP.
- Flashcard and informational/guide content: no base XP and no error, without blocking perfect or Laurel eligibility.
- The Round popup reports first-attempt-correct evaluable answers as X/Y and excludes Flashcard/Info/Guide items from Y.

## Validation summary

- The combined targeted Flutter command passed all **66 tests** across `xp_calculator_test.dart`, `learning_completion_service_test.dart`, `round_xp_completion_regression_test.dart`, `topic_completion_regression_test.dart`, `text_entry_submission_test.dart`, `leaderboard_navigation_test.dart`, `learner_status_bar_test.dart`, `desktop_window_resize_test.dart` and `alpha_lifecycle_test.dart`.
- `flutter analyze` reported the same **7 pre-existing** `curly_braces_in_flow_control_structures` infos in untouched files and no findings in changed files.
- `git diff --check` reported no whitespace errors.
- The complete Flutter test suite was not run, as required by the build-214 scope.
