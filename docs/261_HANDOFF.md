# Build 261 handoff

Branch `claude/261-learner-polish` from `main` (`8b98c6a`, Builds 259 and
260 merged through PR #30); local commits only, not pushed. Changes:
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

## Revision 4 (implemented, 2 October 2026)

The preview made evident (owner go of 2 October 2026): the amber PREVIEW
bar with Exit; Course Info, Theme and Flag background only, changing the
preview alone. Tests in `test/course_preview_261_test.dart`.

## Next

The owner's review of Build 261 (push and PR only when asked).

Stage with `git add -A -- . ':!devtools_options.yaml' ':!tools/cloud_setup.sh'`
after checking `git status` for files another session wrote.
