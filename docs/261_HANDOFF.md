# Build 261 handoff

Branch `claude/261-learner-polish` from `main` (`8b98c6a`, Builds 259 and
260 merged through PR #30); Revisions 0–6 merged into `main` through
PR #31 (`c6516eb`); the Revision 6 follow-up is on branch
`claude/261-revision6-followup`. Changes:
`docs/261_CHANGE_SUMMARY.md`; evidence: `docs/261_VALIDATION.md`.

Plan (owner answers of 1 October 2026):

- Revision 0, learner polish: Round names on one line, tooltips on the
  Round name and the Lesson title, confetti for the weekly goal.
- Revision 1: Study and Review in the ⋮ menus of All Courses and Course
  Studio (Study adds the Course to the personal library when missing,
  makes it current and opens the learner screen; unavailable entries
  greyed with a reason); in Do Not Disturb a per-learner "Course Editor
  opening mode" (Locked / View only / Inspection / Edit) for Courses never
  opened in the editor (the remembered per-Course mode wins; Edit falls
  back to View only without rights); the new key goes to AppResetService,
  InventoryService and docs/239_RESET_STORAGE_INVENTORY.md.
- Revision 2, the Course preview from the Course Editor: a flag left of
  the title on every Course Editor screen opens the learner screen on the
  working copy (Drafts included, nothing completed, every Lesson open;
  Rounds, Stories, Duel and GuideBook usable; Selector, Profile, Review and
  Settings disabled; nothing written; the stored current Course
  unchanged); a "Preview · Exit" chip returns to the same editor spot with
  the changes still pending. From the Exercise editor the preview leaves
  out that form's unsaved edits.

## Revision 0 (committed `18ab7a5`, 2 October 2026)

Learner polish. Tests in `learner_round_path_test`,
`leaderboard_navigation_test` and `round_xp_completion_regression_test`.
Complete suite: 3521 passed, 1 skipped.

## Revision 1 (committed `2e82cd8`, 2 October 2026)

Study and Review in the Course menus of All Courses and Course Studio; the
Course Editor opening mode in Do Not Disturb. Test
`test/courses_study_review_261_test.dart`. Complete suite: 3530 passed, 1 skipped.

## Revision 2 (committed `c6a03b1`, 2 October 2026)

The Course preview from the Course Editor: the flag on every editor
screen, `CoursePreviewScreen`, the Duel's preview mode. Test
`test/course_preview_261_test.dart`. Complete suite: 3536 passed, 1 skipped.

## Revision 3 (committed `f0e1391`, 2 October 2026)

Exercise titles: the recognized preset's name in seven languages, none in
a Story; the Pick the translation line translated. Test
`test/exercise_titles_261_test.dart`; the Laboratory presentation
baseline re-recorded (70 records, titles only). Complete suite: 3541 passed, 1 skipped.

## Revision 4 (committed `2e4dd84`, 2 October 2026)

The preview made evident (owner go of 2 October 2026): the amber PREVIEW
bar with Exit; Course Info, Theme and Flag background only, changing the
preview alone. Tests in `test/course_preview_261_test.dart`. Complete suite: 3542 passed, 1 skipped.

## Revision 5 (committed `9190715`, 2 October 2026)

Owner review points 1, 2, 4 and 5: reading answers that do not copy the
text and the Audit's READING_ANSWER_IN_TEXT; English from Italian's
untitled practice Rounds; New Canonical folded into New Exercise; Fill
with an example. Test `test/owner_review_261_revision5_test.dart`. Complete suite: 3550 passed, 1 skipped.

## Revision 6 (committed `f62c4b0`, 2 October 2026)

The canonical editor explains its primitives: a popup per primitive,
learner and Course; Clear all; the message when the primitive changes over
filled fields; nine Help sections with the owner's screenshots
(`assets/primitives_screenshots/`); Help opens at the primitive; Role is a
menu of the roles QQL reads (`ElementRoles`). Plan
`docs/261_REVISION6_PLAN.md`; test `test/owner_review_261_revision6_test.dart`. Complete suite: 3572 passed, 1 skipped.
At 360 pixels the canonical editor's menus overflowed to the right:
fixed by the Revision 6 follow-up (below).

## Revision 6 follow-up (committed `c48c875`, same version, 2 October 2026)

The canonical editor fits a phone: every menu takes the width it is given
with one-line entries; a Match item's Side and a gap's Reveal sit under
the row's title. Test `test/primitive_editor_narrow_261_test.dart` (every
primitive, blank and with its example, and every Laboratory exercise at
360 pixels). Complete suite: 3582 passed, 1 skipped.

## Revision 7 (committed `fb38c7b`, 2.0.61+261007, 3 October 2026)

Round Types redesign: ten explicit Round types replace the generic learner
path label; New Round selects a type, and Lesson Options controls optional
Round numbering. Story creation and Sequence playback follow their types.
Listen and Read require structurally verifiable content; FlashCard and Test
have their own publication rules, and Test defers feedback until its results.
The GuideBook Round Wizard can replan compatible types. Existing official
Courses retain valid checksums when the new fields are synthesized during
migration. The learner path says Completed rather than repeating Practice as
both a type and a completion action. Editor Help now owns a Round Types
section; Story guidance is removed from Exercise Primitives Help. The
Course Editor now offers Lesson label and numbering and Round label and
numbering together in Lesson Options. Lesson choices are Off, Lesson +
number, Number only and Custom + number; older label choices remain valid
for existing Courses. Lesson titles remain required and Round titles optional;
authored titles stay visible with every label choice. A dedicated Editor Help
FAQ explains both selectors in English, Italian and Spanish. The
Timed type uses `Icons.timer_outlined`, accepts required non-audio evaluatable
exercises, and has ordered distinct limits from 30 seconds to 10 minutes.
Course-level default limits in Lesson Options are copied into new Timed Rounds;
editing the defaults leaves existing Rounds alone. Timely completion unlocks
the next limit and grants a separate 10 XP On Time bonus once per learner,
Course, Round and limit. Timeout locks the attempt, leaves the Round incomplete
and retains first-pass correct-answer XP for that attempt. The Audit blocks
invalid limits and incompatible or indeterminate Timed content. The bonus is
calculated by `XpCalculator` and displayed in the completion breakdown.
The implementation plan is
`docs/superpowers/plans/2026-10-03-round-types-redesign.md`; verification
is in `docs/261_VALIDATION.md`.

Codex stopped before the commit; Claude Code resumed at 11:35 on
3 October. Added then: the Beta expiry moves to `2026-11-02 23:59:59`
(30 days from the 3 October release; `beta_lifecycle_test.dart` shifted a
day), README, CHANGELOG, `docs/261_CHANGE_SUMMARY.md` Revision 7, the
AGENTS expiry line and `v4_completed_timed_limits` in
`docs/239_RESET_STORAGE_INVENTORY.md` (reset already covers it through the
`v4_` prefix; Inventory counts every learner key). Analyzer clean; final
complete suite with temporary files on D: (C: has under 3 GB free, too
little for the 300 MB Image Library fixture; AGENTS.md now names
`D:\QQL_test_temp` for test runs): 3605 passed, 1 skipped, 0 failed.

Owner decision (3 October 2026): in a Timed Round the clock keeps running
through the mistake review (and the Review your mistakes message, which
closes itself at zero); the Round finishes in time only when the last
review answer comes before zero. Kept as it is, nothing added.

## Revision 8 (2.0.61+261008, 3 October 2026)

The learner path in Lesson colours (owner decisions of 3 October, refined
over six renders sent to the owner): `LessonColorPalette` (eight non-green
colours by position, light and dark); the Lesson number circle and the
52-pixel Round circles in the Lesson colour (tint with a ring, solid when
completed, green with the laurel when perfect; Completed written in the
deeper shade); the Duel as a centred circle; rows on 20% backgrounds without
border; a 12-point grey label above lighter titles (the same with or without
a Round title); a 16-step placement pattern (left edge, centre with texts
right or left, right edge; repeats, never edge to edge); the path at most
560 pixels wide; rounded curves from circle to circle, varied per curve from
the Rounds' IDs, tapering and fading toward the circles; a page-colour halo
over Flag Background Small/Extended. Release notes, AGENTS.md, README and
the change summary describe the final design.

Later owner requests in the same revision: mascots in seven slots of ten,
never two Rounds in a row on the same side (`learnerRoundPathMascotRows`);
App Info's "Colour code of the path" with the owner's picture
`assets/rounds_screenshots/colors.png` (first placed in Course Info by
mistake and moved; the chat's "..." button painted out of the picture).

Visual check: a throwaway test rendered the preview, a Duel, App Info and
the circle states with the real Roboto font into `D:/QQL_test_temp/rev8*.png`
(deleted, never committed). Owner said go at the eleventh render; the
complete suite passed: 3612 passed, 1 skipped, 0 failed.

## Next

Build 262 (owner decisions of 2 October 2026, discussion to finish; plan
`docs/262_BUNDLED_AUTHORING_PLAN.md`, not committed yet): the
app author edits and produces the bundled Courses inside the app. A
secret, undocumented author mode (20 taps on a hidden spot, then a code
the author chooses, stored only as a hash); "Edit as author" on a bundled
Course makes a copy that keeps every ID; "Export as bundled" writes a
bundled-format file to Export/Courses; the developer puts it in the assets
at the next build, after which that Course's generator is retired.

Stage with `git add -A -- . ':!devtools_options.yaml' ':!tools/cloud_setup.sh' ':!assets/lesson_plants/QQL_IT_EN_qql_demo_english_from_italian.zip' ':!docs/262_BUNDLED_AUTHORING_PLAN.md' ':!docs/PUBLISHER_COURSES_PLAN.md'`
(the zip is the owner's; the Build 262 plan is committed with Build 262)
after checking `git status` for files another session wrote.
