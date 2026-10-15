# Build 274 handoff

Branch `build-274` from `main` `ae98a881` (Build 273 fast-forwarded into
`main` and pushed on 15 October 2026 at the owner's go; `build-273` deleted
locally and on origin). Plan: `docs/274_PLAN.md`, the owner's nine points of
13 October 2026. Every revision: version `2.0.74+274RRR`, Beta expiry 30 days
from its release day, `CHANGELOG.md`, `README.md`, the `AGENTS.md` release
entry, `docs/274_CHANGE_SUMMARY.md`, `docs/274_VALIDATION.md`, this file;
focused tests while working (a new widget test file is run six times or more
before the suite), an independent read-only review, `flutter analyze` and
the complete suite once on the final tree; one commit, the branch pushed.
Help EN/IT/ES wherever a screen or a rule an author reads changes.

## Revision order

| Rev | What | State |
|---|---|---|
| 0 | The Course Editor's top bar and breadcrumbs (points 1 and 3) | done |
| 1 | Two recommendations stop being Warnings (points 2 and 5) | delivered early, as Build 272 Revision 16 |
| 2 | Playback on request (points 6 and 4) | done |
| 3 | A new Listening preset, Listen and pick the missing word (point 7) | planned |
| 4 | Image Library search: the order and Strict search (point 8) | planned |
| 5 | Two small categories join a group (point 9) | planned |

## Owner decisions

- **15 October 2026, Revision 0: a Rounds crumb.** The plan said the
  Lesson crumb opens the Lesson's page; today the Round editor's Lesson crumb
  goes back to the Rounds list, so following the plan would have changed
  where it leads. Asked, the owner chose to add a Rounds crumb: "Course >
  Lesson 2 > Rounds > Round 3 > Exercise 4", every page you came through has
  its crumb, Lesson opens the Lesson's page and Rounds opens the Rounds list.
- **15 October 2026, Revision 2: Select the image's words.** The plan offers
  a speaker on each option whose text is in the target language, and the
  Laboratory's named icons (sole, luna, albero) state no language. Asked,
  the owner chose to count a word that states no language as the target
  language; a word marked as the source language gets no speaker.

## Revision 0 (2.0.74+274000): the Course Editor's top bar and breadcrumbs

In the working tree (15 October 2026, about 21:30):

- `EditorTrail` and `EditorLevel` in `lib/widgets/editor_breadcrumbs.dart`:
  what a page gives the page it opens (the levels above it it can go back
  to, and the jump in progress). `EditorTrail.below(above, level)`,
  `jumpTo(level, leave:, stayed:)`, `passesThrough(level)`, `target`.
- `EditorBreadcrumbs`: `rounds`, `exerciseNumber`, `newExercise`, `trail`,
  `onJump` (`onParent` is gone); keys `editor-crumb-<level>`.
- The pages: the Course Editor's main page starts the trail when it opens
  the Lessons list; `LessonManagementScreen`, `LessonEditorScreen`,
  `LessonRoundsScreen`, `RoundEditorScreen`, `ExerciseEditorScreen`,
  `PrimitiveEditorScreen` and `exerciseEditorFor` take `trail` (the
  `linkParent` flags are gone); each page, when the page it opened closes,
  goes on upward through its own way back when the jump names a level above
  it (`_receiveLesson`, `_receiveRound`, `_receiveNewExercise` hold what the
  page did with the result before).
- `LessonPresentationService.shortName(course, index)`: the Rounds page's
  top bar.
- Help EN/IT/ES `editorHelp.qa.navigate.a`.
- Tests: `test/editor_breadcrumbs_274_test.dart` (22, six runs clean);
  `lesson_metadata_and_icon_test` expects the new title;
  `official_course_ui_226_01_test` pumps after `ensureVisible` before it
  taps Preview (the longer breadcrumb moved the button below its window).
- The 125 test files that use the changed editor files: 1,387 passed, 2
  failed (that Preview tap, fixed and rerun).
- Independent review: nothing blocking. Acted on: the Keep editing test
  could not fail (it now leaves with the ordinary Back, which must stop at
  the Round); `PrimitiveEditorScreen._leave` gets the `_routeMayPop` guard
  the preset form has; `jumpTo` ends the jump in `finally`; the Help says
  "the pages you came through", Italian "la pagina Rounds"; four more tests
  (Previous and Next, the canonical editor, three pages back then the
  Course, View only). Left as it is: the Lessons list's one crumb stays
  plain text (not in the plan).
- Second review (of the corrections and the documents): nothing blocking;
  acted on: the canonical editor the preset form opens had no links (it now
  gets the form's trail and the form goes on upward after it), three
  `ensureVisible` without a pump in the test's helpers, a test of a way back
  that fails, README "every crumb whose page you came through".
- Third review (of that last correction only): a jump continued from the
  canonical editor called the form's `_leave()` directly, so Keep editing
  there left the target set and a later ordinary Back climbed on; the form
  now continues with `_jumpTo(target)`. A test covers it, and fails without
  the fix.
- Version 274000, documents written. `flutter analyze` clean; complete
  suite 4,821 passed, 1 skipped; committed and pushed.

## Revision 2 (2.0.74+274002): playback on request

In the working tree (15 October 2026):

- `PlaybackOnRequest` (`lib/services/playback_on_request.dart`, pure Dart):
  `promptText`, `answerText`, `optionWord`, `texts`. The Round screen and
  `CourseAudioUsage.spokenTexts` read it (the Pick the translation block of
  `spokenTexts` is replaced by `PlaybackOnRequest.texts`).
- `CorrectAnswerText.variantOf` (static; `firstVariant` calls it).
- Round screen (`scratchpad/r274_2/apply_r2.py` of the session applied the
  edits): `_translationFeedbackAudio` and `_translationChoiceExercise` read
  the owner; `_withPromptSpeaker` around `exercise-prompt-text` and the
  audio note; `_wordSpeaker`, `_withOptionSpeaker` (both returns of
  `_pictureAnswer`), `_matchWord` (`_matchingExercise`'s menu entries).
- Laboratory presentation baseline: 19 records re-recorded with
  `QQL_RECORD_PRESENTATION` and put in place by
  `scratchpad/r274_2/rerecord.py` (only the named records replaced; after
  the corrections all 124 recorded afresh and compared: only Match pictures
  to words moved, back to its committed record).
- Help EN/IT/ES: the six presets' Help and `editorHelp.qa.textsToRecord.a`.
- Version 274002, documents written. The 97 test files that use the
  changed code: 1,445 passed.
- Independent review: nothing blocking. Acted on: `ExerciseMascotRoom.of`
  keeps 48 pixels for the prompt's speaker; the Match's closed field keeps
  its plain word (`selectedItemBuilder`), the speakers are in the menu;
  `optionWord` reads `f.leftItems`/`f.rightItems`, says nothing for several
  answers or inline gaps; `promptText` is null for an Instruction or
  context; wording (the answer heard is the first accepted, the plan's
  choice), the baseline note's place, an AGENTS double negative; tests with
  literal texts and the missing cases (21 after the second review, six
  runs clean; the four guards fail without their fixes). Left as the plan says (Pick the translation's
  behaviour), reported to the owner: in a `recorded` or `hybrid` Course a
  speaker whose text has no recording may say it cannot play.
- Second review (of the corrections): nothing blocking; three tests made
  stronger (the Match field once a word is chosen, the mascot keeping the
  whole room for a sentence with no speaker, answers that fill gaps): 21
  tests.
- Released 16 October 2026: the work ran past midnight, so the Beta expiry
  is 2026-11-15 23:59:59 and every date of `test/beta_lifecycle_test.dart`
  moved by one day.
- `flutter analyze` clean; complete suite 4,842 passed, 1 skipped;
  committed and pushed.

Next: Revision 3, a new Listening preset (point 7).
