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

## Revision 2 (2.0.74+274002), playback on request

The owner's points 6 and 4 of 13 October 2026; one owner decision of
15 October 2026 (a word that states no language counts as the target
language).

- New tests: `test/playback_on_request_274_test.dart`, **21 passed**, the
  file run six times clean after its last change. On the Laboratory's own
  examples (built by the real forms), with the texts written out:
  - `PlaybackOnRequest` (15): Type the translation into the target
    ("grazie", after answering only); an answer expression heard as its
    first answer, without braces; Type the translation into the source
    ("Grazie.", no answer); an Instruction or context with a target clue is
    not heard; Build the translation ("Bevo acqua" into the target, nothing
    into the source); Pick the translation ("Buongiorno." once answered into
    the target, "Grazie." into the source, as `TranslationChoice` gave);
    Select the image's named icons (sole, luna, albero) and no word for
    picture options or Listen and pick the image; a listening exercise with
    named icons says none; several answers, or answers that fill gaps,
    say none; a word marked as the
    source language; Match pictures to words' words, none for Match the
    words, and the sides worked out for a Match without them; the Audio
    Library counts every text (`CourseAudioUsage.spokenTexts`); the mascot
    keeps room for the speaker (81 letters take four lines beside it) and
    the whole room for a sentence in the source language, which has none.
  - The Round screen (6): the speaker beside the sentence to translate,
    nothing spoken until it is tapped; Build the translation's Listen to the
    answer after Check; a named icon's speaker plays its word and does not
    answer; Match pictures to words' speakers in the menu only, a tap that
    plays and does not choose, the chosen word in the closed field without
    a speaker; outside the Preview, with the learner's
    audio off no option or menu speakers and the sentence's speaker greyed
    with its note, with the audio on both are there; the three exercises at
    360 pixels.
  - Each guard the review asked for fails without its fix (the mascot's
    room, the sides of a Match, several answers, an Instruction or
    context): checked by undoing the four fixes and running the file.
- The Laboratory presentation baseline: 19 records re-recorded (the counts
  of audio buttons and of Listen to the answer; what is spoken by itself is
  unchanged in every record); the 124 records recorded afresh after the
  corrections, and every other record reproduced byte for byte.
- `translation_choice_239`, `audio_usage_270`, `audio_library_271` and
  `exercise_laboratory_254`: 342 passed. The 97 test files that use the
  Round screen, the audio usage, the correct answer text, the Help or the
  version (before the review's corrections): 1,445 passed. After the
  corrections, `exercise_mascot_256`, `exercise_laboratory_254`,
  `match_repeated_values_265`, `translation_choice_239`, `audio_usage_270`
  and `plural_pictures_265`: 344 passed.
- Independent review: nothing blocking. Acted on: the mascot's room for the
  speaker; the Match's closed field (its speaker had no room: the menu keeps
  it); the sides of a Match as the screen pairs them; no word for several
  answers or inline gaps; no Instruction or context as the sentence; the
  comment and CHANGELOG wording on the answer heard; the baseline note's
  place and an AGENTS double negative; tests with the texts written out and
  the missing cases. Left as the plan says, reported to the owner: a speaker
  in a Course with its own recordings may say it cannot play, as Pick the
  translation's does.
- Second review (of the corrections): nothing blocking; acted on: three
  tests made stronger (the Match field once a word is chosen, which fails
  without `selectedItemBuilder`; the mascot keeping the whole room where no
  speaker is drawn; answers that fill gaps, a Select the image whose guard
  is reachable). Release moved to 16 October 2026 (past midnight): Beta
  expiry 2026-11-15 23:59:59.
- `flutter analyze`: no issues.
- Complete suite: **4,842 passed, 1 skipped, 0 failed**.
