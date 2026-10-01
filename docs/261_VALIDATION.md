# Build 261 validation

## Revision 0 (2.0.61+261000, 2 October 2026): learner polish

**Generators and validator**
- No Course file changes: the five generators' `--check` reproduce their
  Courses; `tools/validate_courses.py`: the four bundled Courses pass.

**Tests**
- New in `learner_round_path_test`: "Round, Story and sequence names":
  "Round 1: " / "Story: " / "Sequence: " in normal weight and the title in
  w800 in one `Text.rich`, the tooltips "Round 1: Pratica 1", "Story: Al
  bar", "Sequence: Numbers", none for an untitled "Round 2" (alone, w800),
  15 points with line height 1.4.
- New in `round_xp_completion_regression_test`: no confetti with
  Animations off, none with reduced motion (the dialog still shows); the
  weekly-goal test now finds `weekly-goal-confetti` (under an
  `IgnorePointer`) and none on the repeat.
- Updated: `learner_round_path_test` (the long title is one `Text.rich`
  "Round 1: …" of at most three lines; the Laurel overlap and opacity checks
  find the title by key), `leaderboard_navigation_test` (the Lesson title's
  tooltip is the whole "Lesson 1: …"; a Round is opened by its title key),
  the version pins (`app_metadata_225_04`, `qql_229_revision3`,
  `qql_233_revision_platform_contract`, `course_audit_report_225`, three
  pins there) and `beta_lifecycle_test` (every date one day later).
- While authoring: a three-line title at line height 1.5 overflowed the
  card by one pixel with the test font (69 + 20 > 88), so the line height
  is 1.4 (63 + 20).
- Focused runs: the learner path, the two XP regression files and the
  fifteen files that build the Home screen (one failure, the Round opened
  by its old title text, fixed and re-run), the version, Beta and Help
  tests.
- `flutter analyze --no-pub`: no issues.
- **Complete suite** (`--concurrency=1`, keep-awake, 26 min 52 s):
  **3521 passed, 1 skipped, 0 failed**.

## Revision 1 (2.0.61+261001, 2 October 2026): Study and Review from Courses, the Course Editor opening mode

**Generators and validator**
- No Course file changes (the four bundled Courses unchanged).

**Tests**
- New: `test/courses_study_review_261_test.dart` (9 tests): the Study and
  Review reasons (a published bundled Course can be studied, none without a
  learner, "Publish this Course before you can study it." for a Draft
  Course, Review needs a completed Round); completed Rounds read from the
  Review records; Course Studio's `studyEntriesFor` apart from
  `entriesFor`; the opening mode (View only until chosen, a first opening
  remembers it, a later default leaves opened Courses alone, a mode chosen
  in the editor wins, Edit opens as View only without rights, a legacy lock
  keeps its meaning, the key under the learner prefix); Do Not Disturb sets
  it; from the empty library, All Courses → Study adds the Laboratory, makes
  it current (`IT`) and returns to the learner page, with Review greyed
  ("Complete a Round of this Course first."); Review on QQL Demo: English
  from Italian (a recorded Round) makes `EN_IT` current and opens Review on
  it; Course Studio closes Courses with the request.
- Updated: `app_reset_service_239_test` (the learner-progress reset keeps
  `course_editor_opening_mode`); the version pins.
- Focused run: the new file, then the 52 files that build Courses, Course
  Studio, the Course Editor modes, Do Not Disturb or the resets: 532
  passed.
- `flutter analyze --no-pub`: no issues.
- **Complete suite** (`--concurrency=1`, keep-awake, 27 min 13 s):
  **3530 passed, 1 skipped, 0 failed**.
