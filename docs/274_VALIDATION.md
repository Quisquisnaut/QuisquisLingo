# Build 274 validation

## Revision 0 (2.0.74+274000), the Course Editor's top bar and breadcrumbs

The owner's points 1 and 3 of 13 October 2026; one owner decision of
15 October 2026 (a Rounds crumb).

- New tests: `test/editor_breadcrumbs_274_test.dart`, **22 passed**, the
  file run six times clean after its last change:
  - `EditorTrail` (5): a page opened outside the chain can jump only to
    itself; a jump passes the pages above its level and ends at it; a page
    that stays ends it; a way back that fails ends it (and the error is
    rethrown); a level not open above is no jump.
  - The Lesson named once (5): Lesson, Unit, a custom label, Number only
    and Off.
  - The Rounds page title, and with numbering Off.
  - The exercise crumb is its place in the Round (outside the chain only
    the Round is a link); Previous and Next change it.
  - Through the real chain from the Course Editor's main page: every crumb
    above is a link; unsaved changes ask first; Keep editing ends the jump
    (an ordinary Back afterwards stops at the Round); Rounds and Lesson
    crumbs; Discard on the way to the Course leaves the Course unchanged;
    Apply keeps the change (the main page shows unsaved changes); the
    Lesson crumb goes back three pages, then the Lesson page's Course crumb
    one more; a jump in View only.
  - The canonical editor: its crumbs and its jump (pushed with a trail); the
    canonical editor opened from a new exercise's preset form, through the
    real chain; Keep editing in the form under it ends the jump (this test
    fails with the form's earlier `_leave()` call).
- Changed tests: `lesson_metadata_and_icon_test` expects "Rounds · Lesson 1";
  `official_course_ui_226_01_test` pumps after `ensureVisible` before it
  taps Preview (the longer breadcrumb moved the button below its window).
- The 125 test files that use the changed editor files: 1,387 passed, 2
  failed (that Preview tap, fixed and rerun). The 15 Help and localization
  test files: 192 passed. The five version tests pass at 274000.
- Independent reviews:
  - first (the code): nothing blocking; acted on: a test that could not
    fail, the canonical editor's `_leave` without a `_routeMayPop` guard,
    `jumpTo` ending the jump in `finally`, the Help's words (EN/IT/ES), four
    more tests; left as it is: the Lessons list's one crumb (not in the
    plan);
  - second (the corrections and the documents): the canonical editor the
    preset form opens had no links (it now gets the form's trail and the
    form goes on upward after it); `ensureVisible` without a pump in three
    test helpers; a test of a way back that fails; the README's wording;
  - third (that last correction): a jump continued from the canonical
    editor called the form's `_leave()` directly, so Keep editing there
    left the jump set; the form now continues with `_jumpTo(target)`.
- `flutter analyze`: no issues.
- Complete suite: **4,821 passed, 1 skipped, 0 failed**.
