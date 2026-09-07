# QQL 227.03 IDDQD state clarity and validation

## Release boundary

Target metadata is Version `2.0.27`, Phase `227.03`, revision `0`, technical build `227030`, and pubspec `2.0.27+227030`. The QQL 227 Alpha expiry remains exactly `2026-10-07 23:59:59` local time. Course Model remains v6 (`formatVersion: 6`) and the Audit Registry remains at 102 rules.

Implementation starts from committed `8343d7f3ba88af9fe5a5081fdfb98e4c49ce1e90`, `Complete QQL 227.02 inspired flag backgrounds`. Inspection confirmed a clean checkout and the completed `2.0.27+227021` revision-1 baseline before editing. Phase 227.03 does not modify or reinterpret Small / Off / Extended / Tinted / Inspired, their ordering or rendering, the learner × Course Flag Background preference, or the compatible `softInspired` / `soft_inspired` identity.

## Final learner wording

The fixed learner-bottom control retains the label `IDDQD`. Its selected state now has persistent visible guidance:

- Off: `Normal progression locks apply.`
- On: `Locked content can be opened. Normal progression status is preserved.`

The control tooltip and accessibility label contain the same authoritative wording. The explanation changes in the same rebuild as the existing IDDQD control state, without fades, transitions or other animation.

## Existing access boundary and contextual communication

The genuine unlock calculation remains solely in `LessonUnlockService`: the first Lesson is unlocked, and a later Lesson unlocks only after the immediately preceding Lesson is completed or its Duel is won. IDDQD does not enter that service and does not rewrite its result.

The existing Home flow uses that genuine result as one Lesson-level gate. When IDDQD is On, a genuinely locked Lesson's existing `hasAccess` path exposes:

- its published GuideBook;
- all of its Rounds;
- its Duel only when the existing Duel eligibility calculation says it is available.

Phase 227.03 adds one compact `Accessible with IDDQD` indicator to that genuinely locked Lesson section. The existing Lesson lock badge remains visible and its accessibility label also states that IDDQD allows access. The contextual indicator is intentionally at the shared Lesson gate rather than repeated on every descendant, because the current implementation has no independent Round lock state. Unpublished or disabled GuideBooks and ineligible Duels remain unavailable through their own existing rules and receive no false availability claim. No new access path is added.

With IDDQD Off, the established locked-Lesson guidance and hidden descendant path remain unchanged. The separate three-tap session preview remains preview-only and does not receive the IDDQD indicator.

## Persistence and progression

IDDQD persistence is unchanged. The current value is stored beneath the active opaque learner namespace using the existing Course-specific key suffix:

```text
iddqd_<Uri.encodeComponent(courseId.trim())>
```

Missing values still resolve to Off. The same learner and Course restore their value, another Course remains independent, and another learner remains independent. No migration, alternate key, Course Model field or Course JSON field was added.

Toggling IDDQD alone calls only the existing setting write and changes no completed Rounds, completed Lessons, XP, Weekly XP, streaks, Laurels, Review state or genuine unlock state. Actual study performed while IDDQD is On continues through the normal completion service and records the same real completion, XP, activity, Laurel and progression effects as any other study.

## Responsive and accessibility coverage

The visible selected-mode explanation uses at most two centered lines below the existing controls. Automated rendering covers 320, 375, 430 and 1100 logical pixels in Light and Dark themes for both Off and On, with fixed 40 × 40 action targets and no overflow. The bottom inset continues to derive from the exported control height, so learner content remains clear of the enlarged fixed control area.

The IDDQD control exposes button and toggled semantics plus the full selected-state explanation. The contextual Lesson indicator states both the genuine lock and the active access override. Existing actionable GuideBook, Round and Duel surfaces retain their normal actionable semantics when IDDQD supplies the Lesson access gate.

## Test coverage

Focused tests cover:

- exact visible Off and On wording, tooltip wording and accessibility labels;
- immediate selected-state replacement through the real control callback;
- the same genuinely locked Lesson with IDDQD Off and On;
- the `Accessible with IDDQD` indicator and retained genuine lock marker;
- actionability of the published GuideBook, Round and eligible Duel through the existing gate;
- no completed Round, completed Lesson, XP, Weekly XP or unlock mutation from enabling IDDQD alone;
- normal completion, XP, activity, Laurel and unlock behavior after actual study while IDDQD is enabled;
- existing learner × Course persistence, default and isolation coverage;
- 320 / 375 / 430 / 1100 logical-pixel rendering in Light and Dark for both modes;
- unchanged metadata, Alpha expiry, Course Model, bundled checksums and assets through release validation.

## Validation results

| Check | Result |
| --- | --- |
| Focused IDDQD communication, access, persistence and progression | **6 passed / 0 failed**, exit 0; the final indicator change's direct Home test also passed after correction |
| Responsive control and learner-layout rendering | **6 passed / 0 failed**, exit 0; Off/On control matrix plus five focused Home regressions at the required phone widths |
| Metadata, audit-report and Alpha lifecycle | **13 passed / 0 failed**, exit 0, including Welcome/Alpha display metadata |
| Final analyzer delta | **71 inherited / 0 new / 0 resolved** against the committed revision-1 log: 70 Infos, 1 Warning, 0 errors; exit 1 solely for inherited findings |
| Complete Flutter suite | **1,200 passed / 0 failed**, exit 0, **15:51**; one serialized run of the corrected final source tree |
| Bundled Course validator | **9 Course Model v6 files valid**, exit 0 |
| Bundled checksum check | **all 9 generated Courses and SHA-256 values matched**, exit 0 |
| Image validator | **112 assets / 0 issues**, exit 0 |
| Lesson-icon validator | **14 assets / 0 issues**, exit 0 |
| Final source snapshot | All **253 source/test/pubspec SHA-256 values** matched the pre-suite snapshot; 0 changed and 0 added |
| `git diff --check` | **Passed**, exit 0; no staged diff; no Course Model or asset diff |

The first complete-suite candidate run classified five 227.03 regressions: the new contextual label could overflow under narrow enlarged text, and one layout test hard-coded the old 112-pixel inset after the bottom-control height grew. The label now flexes and wraps to at most two lines, and the test asserts the established `learnerBottomActionsHeight + 44` relationship. All five cases passed together before the corrected final-tree suite ran. The failed candidate log remains ignored validation evidence and is not reported as a passing complete run.

## Remaining limitations

The contextual message follows the current shared Lesson access gate. It does not invent independent lock states for Rounds, GuideBooks or Duels, so descendants do not each repeat the same indicator. Automated responsive checks cover the required widths, both themes and the repository's enlarged-text regression, but they do not exercise every assistive technology or platform text-scale combination.

Phase 227.03 stops at explaining the existing Off / On state and access override. It does not add IDDQD modes, view-only behavior, Theme modes or scheduling, Flag Background changes, animations, Settings reorganization, Stats, Study Days, logging changes, Course Editor work or Course Model changes. Phase 227.04 has not begun.
