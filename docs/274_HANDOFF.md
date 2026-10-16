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
- **16 October 2026, Revision 3: the format of sound answers** (asked
  before any code). An answer of the new Listening preset is a Select item
  whose sound is an audio element with either `text` (spoken by the device
  voice or by the recording given that text, as today) or `recording` (the
  ID of an Audio Library recording, played whatever its text; may have
  none); its own text, shown only once the learner has answered, is a text
  element with the new role `after_answer`. After answering an answer shows
  its `after_answer` text, else its sound's `text`, else the recording's
  Audio Library text, else nothing (an Audit Info). The owner chose:
  - the Audio Library ID, not the file (`media:<sha>.mp3`): the Audio
    Library stays the one list of recordings; Fork and Copy as New Course
    remap the ID; a deleted recording leaves an Audit Error;
  - **Delete asks first** in the Audio Library when answers use the
    recording, naming the exercises;
  - **On-Device TTS plays no recordings, chosen ones included** (the
    owner: "If you want it to keep playing, why switch to On-Device TTS
    only?"): such an answer has no sound, an Audit Error, the exercise is
    skipped until the mode or the answer changes;
  - **Course Info warns first** when the mode is switched to On-Device TTS
    while answers use recordings (how many; go on or keep the mode).
  Choosing on Check is the existing `evaluationTiming: explicit`, newly
  runnable for a single-answer Select. `minimumAppBuild` 274003 for a
  Course that uses it.

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

## Revision 3 (2.0.74+274003): Listen and pick the missing word

In progress (16 October 2026; version already 274003, because a Course
stamped `minimumAppBuild` 274003 must be readable by the app under test):

- Done: `PromptElement.recording` (parse: audio only, never with a text,
  never in the prompt; serialized; kept by `copyWith`, `withPlural`, the
  canonical editor's row; remapped by Fork/Copy in
  `AuthoringDuplicationService._copyPrompt`), role `after_answer`
  (`ElementRoles`; `ExerciseItem.text` leaves it out), the Select
  configuration single + `evaluationTiming: explicit` in the runtime-support
  table, `ExerciseFeatures.hasSoundItems` / `soundOf` / `afterAnswerTextOf`
  / `checkedOnCheck`, kind `selectSounds` (difficulty recognizeTarget,
  Audit kind name), copy `type.selectSounds`, `instruction.selectSounds`,
  `instruction.selectSoundsGap`, `title.listen_and_pick_the_missing_word`
  and learner panel `soundNumber` in seven languages; `SoundAnswers`
  (`lib/services/sound_answers.dart`: `recordingOf`, `shownText`,
  `recordingIds`, `answersWithRecordings`, `needsThisBuild`,
  `withMinimumAppBuild` in `CourseMinimumBuild.stamp`);
  `RecordedAudioService.playClips` (the body of `playConcatenated`); Round
  screen `_soundChoiceExercise` / `_soundAnswer` (`sound-answer-<i>`,
  `sound-answer-text-<i>`, `sound-answer-mark-<i>`, `sound-answers-check`),
  `_playAnswerSound`, `_singleCheckChoiceExercise` (`single-check-option-<i>`,
  `single-check-submit`), the hint, `CorrectAnswerText.of(audioLibrary:)`;
  availability (`_soundsAvailable`); Duel exclusion; `CourseAudioUsage`
  (uses by id, `answersNaming`); the Audio Library's Delete asks
  (`audio-delete-named-dialog`) and the audio source menu warns before On-
  Device TTS (`audio-tts-named-dialog`: the only place the mode is set is
  the Audio Library, not Course Info).
- Done since (16 October 2026): the Audit rules (135: 69 Errors, 44
  Warnings, 22 Infos); the preset (registry, recipe, builder, decompose,
  form `SoundAnswersEditor`, field Help, Search, Fill with an example);
  Python tools and `docs/capabilities_v12.json`; the Laboratory example
  (125 examples) and its presentation record; Help EN/IT/ES (the preset,
  its three fields, the Audio Library's audio modes and recordings);
  `docs/LOCALIZATION_CURRENT_STATE.md`; the tables of the existing tests;
  `test/listen_pick_missing_word_274_test.dart` (28, six clean runs);
  CHANGELOG, README, AGENTS, change summary, validation.
- The independent review (16 October 2026) found thirteen faults, all
  confirmed and corrected: the preset did not fit a Listen Round (and one
  copy would empty that Round); a Test Round showed the marks; a blank row
  could make another answer the correct one; picture answers graded on
  Check fell into the list of words; the sound kind ignored selection mode,
  inline gaps and timing; the Audit did not check the sentence and gap the
  form asks for; recordings were accepted where nothing plays them (now a
  format error outside a Select, the Error SOUND_ANSWERS_NOT_PLAYABLE inside
  one, and the Python validator mirrors the refusals); the dialogs'
  grammar and consequences; the recording's failure message; the Story
  log's answer text; a false unsaved-changes prompt; a doubled Error.
  Tests added for each (38 in the new file). 136 rules, 70 Errors.
- The re-review closed all thirteen; six residuals corrected; the new file
  38 passed, six clean runs; `flutter analyze` clean. Kept as designed: the
  preset's sentence and gap Warnings follow the stored preset (sound
  answers without a gap are legitimate).
- The complete suite: 4,885 passed, 1 skipped (after a first run whose
  two failures were test tables: the mascots' anchors, the importable
  Laboratory's version 2). Committed as "Build 274 Revision 3: Listen and
  pick the missing word" and pushed to build-274.
- Next: Revision 4 (Image Library search order, Strict search), then
  Revision 5 (category groups). Merge into main only on the owner's go.
- To tell the owner: the warning before On-Device TTS is in the Audio
  Library's audio source menu (the only place the mode is set), not in
  Course Info.

## Revision 4 (2.0.74+274004): Image Library search order and Strict search

In progress (16 October 2026, the owner's "Go on with the plan").

- Done: `imageSearchMatch` / `ImageSearchMatch` (name, nameWord, tagWord,
  inside) and `matchesImageSearch(strict:)` in
  `lib/services/image_library_rules.dart` (words split at anything not a
  letter, mark or digit, singular as `imageTagKey`; the order never adds or
  hides a picture); the library sorts by part, then the chosen sort;
  Strict search (`exercise-image-strict-search`, above Search all, off);
  Help EN/IT/ES `findPicture`; version 274004; CHANGELOG, README, AGENTS,
  change summary, validation; `test/image_search_order_274_test.dart` (7).
- Review: no blocking fault; corrected the symbols (whole texts first),
  the category (only named whole), scripts without spaces, the layout;
  re-review closed them. Tests 10, six clean runs; analyze clean.
- The complete suite: 4,895 passed, 1 skipped. Committed as "Build 274
  Revision 4: Image Library search order and Strict search" and pushed to
  build-274.
- Owner report of 16 October 2026 (Italian Demo 2): leaving the Course
  Editor asked about unsaved changes after switching the audio source to
  MP3 and back and searching pictures with Strict on and off; not
  reproduced. Traced: the Audio Library's round trip is exact (tested on a
  copy of the stored Course, both MP3 modes, with the reconciliation), the
  Image Library hands back a Course only on add or remove, the stored
  Course has nothing to reconcile, nothing was saved, the logs say nothing.
  Cause not found; proposed: the dialog names what changed.
