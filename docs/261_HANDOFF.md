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

## Revision 6 follow-up (same version, 2 October 2026)

The canonical editor fits a phone: every menu takes the width it is given
with one-line entries; a Match item's Side and a gap's Reveal sit under
the row's title. Test `test/primitive_editor_narrow_261_test.dart` (every
primitive, blank and with its example, and every Laboratory exercise at
360 pixels).

## Next

Build 262 (owner decisions of 2 October 2026, discussion to finish; plan
`docs/262_BUNDLED_AUTHORING_PLAN.md`, not committed yet): the
app author edits and produces the bundled Courses inside the app. A
secret, undocumented author mode (20 taps on a hidden spot, then a code
the author chooses, stored only as a hash); "Edit as author" on a bundled
Course makes a copy that keeps every ID; "Export as bundled" writes a
bundled-format file to Export/Courses; the developer puts it in the assets
at the next build, after which that Course's generator is retired.

Stage with `git add -A -- . ':!devtools_options.yaml' ':!tools/cloud_setup.sh' ':!assets/lesson_plants/QQL_IT_EN_qql_demo_english_from_italian.zip' ':!docs/262_BUNDLED_AUTHORING_PLAN.md'`
(the zip is the owner's; the Build 262 plan is committed with Build 262)
after checking `git status` for files another session wrote.
