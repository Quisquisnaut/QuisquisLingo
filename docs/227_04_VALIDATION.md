# QQL 227.04 closure and validation

## Release boundary

Target metadata is Version `2.0.27`, Phase `227.04`, revision `0`, technical build `227040`, and pubspec `2.0.27+227040`. The QQL 227 Alpha expiry remains exactly `2026-10-07 23:59:59` local time. Course Model remains v6 (`formatVersion: 6`) and the Audit Registry remains at 102 rules.

Implementation starts from committed `8badf79dda864cc40098f4df262628029bf68df1`, `Complete QQL 227.03 IDDQD communication`. Inspection confirmed the completed `2.0.27+227030` baseline and a clean checkout before Phase 227.04 edits. Phase 227.04 does not modify or reinterpret completed Flag Background rendering, derivation or persistence.

## Final learner control matrix

| Control | Final options | Scope | Default |
| --- | --- | --- | --- |
| Flag Background | Small / Off / Extended / Tinted / Inspired | learner × Course | Off |
| IDDQD | Off / On / View Only | learner × Course | Off |
| Theme | Light / Dark / System / Day/Night | learner | System |

Flag Background retains `softInspired` internally and `soft_inspired` in storage. Tinted and Inspired, their adaptive color pipeline, static immediate replacement and safe fallback behavior are unchanged.

## IDDQD behavior and communication

Off and On retain their established behavior. Off applies genuine progression locks. On passes through the existing Lesson gate and records actual study, completion, XP, Weekly XP, activity, streaks, Laurels, Review, Duel results and genuine unlocks normally.

View Only passes through the same gate and permits published GuideBook access, Round exercise interaction with immediate correctness feedback, and eligible Duel interaction. It does not create an alternate profile, copy learner state, mutate then roll back, or make the real lock appear unlocked. Round completion uses the established non-persisting completion branch before `LearningCompletionService`; Review forwards the same View Only execution mode into its Round; Duel suppresses the authoritative `winDuel` write. The result dialogs identify a preview result and do not claim XP, Laurels, completion or unlocks.

The selected mode itself persists under the existing opaque learner namespace and Course-specific suffix:

```text
iddqd_<Uri.encodeComponent(courseId.trim())>
```

Existing boolean `false` and `true` values remain Off and On. View Only stores `view_only` on that same key. No alternate key or Course field is introduced. Missing or invalid data resolves safely to Off.

The compact bottom control has no permanent explanatory text beneath its buttons. Its tooltip and accessibility label use:

- Off: `Normal progression locks apply.`
- On: `Locked content can be opened. Study progress is recorded normally.`
- View Only: `Locked content can be previewed. No learning progress is recorded.`

A genuinely locked Lesson retains its lock badge and adds one subordinate message at the shared Lesson gate: On shows `Accessible with IDDQD`; View Only shows `Preview with IDDQD`. The message is not repeated on each descendant. Unpublished or disabled GuideBooks and ineligible Duels remain unavailable through their own rules.

## Theme behavior and compatibility

Theme remains an opaque-learner preference shared across Courses. The visible order is Light, Dark, System, Day/Night. The internal `defaultMode` case and stored `default` value now display as System, so existing Default selections keep the same live operating-system Light/Dark behavior without migration.

Day/Night stores `day_night`, not the currently resolved brightness. It uses local device wall-clock time:

- Light from `07:00:00` inclusive to `19:00:00` exclusive;
- Dark from `19:00:00` inclusive to `07:00:00` exclusive.

The app schedules one timer for the next 07:00 or 19:00 boundary. It cancels that timer when another Theme mode becomes active and re-evaluates local time immediately on resume, including after an inactive timezone or wall-clock change. System continues to use Flutter's live platform brightness. Material theme animation duration is zero.

## Focused test coverage

Focused behavior tests cover:

- exact Flag Background, IDDQD and Theme option matrices and cycle order;
- legacy boolean IDDQD compatibility plus View Only learner × Course persistence, restart and isolation;
- Off lock blocking, On access, View Only access, retained real lock semantics and mode-specific contextual wording;
- View Only Round interaction followed by a fresh-service assertion of no completed Round/Lesson, perfect/TTS-perfect state, recent Review record, XP, Weekly XP, streak or study day, then normal completion to prove the ordinary write path remains active;
- View Only Duel interaction with no Duel result, XP, Weekly XP, activity or Lesson state, followed by a normal persisted victory;
- old `default` Theme storage restoring as visible System and reacting live to Light/Dark platform brightness;
- deterministic Day/Night values at `06:59:59`, `07:00:00`, `18:59:59` and `19:00:00`, plus daytime/nighttime samples, live timer switching and resume re-evaluation;
- learner Theme isolation, Course independence and Day/Night restart persistence;
- compact bottom controls at 320, 375, 430 and 1100 logical pixels in Light and Dark for every IDDQD mode, plus the established enlarged-text learner-page checks;
- unchanged version, Alpha expiry, Course Model, bundled Courses, checksums and assets through final release validation.

## Validation results

The final corrected tree produced the following release evidence:

| Check | Result |
| --- | --- |
| Focused 227.04 behavior tests | 67 passed, 0 failed |
| Complete Flutter suite | 1,209 passed, 0 failed in 12:10 |
| Flutter analyzer delta | 71 inherited findings, 0 new, 0 resolved (70 info, 1 warning, 0 errors) |
| Dart formatting verification | 21 touched Dart files checked, 0 changes required |
| Bundled Course validation | 9 Course Model v6 Courses valid |
| Bundled Course checksums | All 9 exact |
| Image asset validation | 112 assets, 0 issues |
| Lesson icon validation | 14 assets, 0 issues |
| `git diff --check` | Passed |

The focused total covers the final IDDQD, Theme, Home access, persistence, completion-boundary, responsive-control, metadata, Alpha-lifecycle and Audit-registry cases. The complete suite was run once on the stable source tree. No production or test source changed after it started; this document records the resulting evidence.

## Remaining limitations

View Only guards the current learner study write paths: Round completion, Review Round completion and Duel victory. GuideBook reading already has no learner-progress write. The contextual message remains Lesson-level because the current learner architecture has one genuine Lesson lock gate rather than independent descendant lock states. Automated rendering cannot represent every assistive technology or platform text-scale combination.

Phase 227.04 closes QQL 227. It adds no configurable schedule, geolocation, fourth IDDQD mode, Theme animation, Flag Background mode, Course Editor change, Course Model change, Settings reorganization, Stats, Study Days or logging work. No 227.05 or QQL 228 work is included.
