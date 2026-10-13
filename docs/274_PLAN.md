# QQL Build 274 plan

Owner's nine points and decisions of 13 October 2026, planned while Build 272
was running (read only: this document is the only thing written). Build 273
is the second half of the modularization plan
(`docs/272_MODULARIZATION_PLAN.md`, its medium-risk items). Build 274 is small
improvements to the Course Editor, the Audit, playback on request, one new
Listening preset and the Image Library.

Every revision: version `2.0.74+274RRR`, Beta expiry 30 days from its release
day, `CHANGELOG.md`, `README.md`, the `AGENTS.md` release entry,
`docs/274_CHANGE_SUMMARY.md`, `docs/274_VALIDATION.md`,
`docs/274_HANDOFF.md`; focused tests while working (a new widget test file is
run six times or more before the suite), `flutter analyze` and the complete
suite once on the final tree; one commit, the branch pushed. Help EN/IT/ES
wherever a screen or a rule an author reads changes.

Line numbers below are those of Build 272 Revision 7.

## Revision 0: the Course Editor's top bar and breadcrumbs

### The Rounds page says the Lesson once (point 1)

- **Today**: the Rounds page (the list of a Lesson's Rounds) has the top bar
  "Rounds · Lesson 2: Greetings", with "Lesson 2" in the small grey label
  type, and right under it the breadcrumb "Course > Lesson 2: Greetings".
- **Change**: the top bar says "Rounds · Lesson 2", all in the normal title
  type. The breadcrumb stays as it is, small label included.
- When the Course's Lesson numbering has no word to show (Off, or Number
  only), the top bar shows the Lesson's title instead: "Rounds · Greetings".
  A custom label is shown as written ("Rounds · Unit 2").
- Where: `course_editor_screen.dart`, the Rounds page's `AppBar`
  (`LabelledText('Rounds · $lessonLabel', label: lessonIdentity?.prefix)`).

### Breadcrumbs: the exercise's number, and every ancestor a link (point 3)

- **Today**: the Exercise editor's breadcrumb ends with "Exercise", and only
  the crumb before the last (the Round) is a link.
- **Change**:
  - the last crumb is "Exercise 4": the exercise's place in its Round, the
    number the Round editor's list shows; "New Exercise" before it is added;
  - the Course and the Lesson crumbs are links too, drawn like the Round's;
  - this holds on every editor page that has breadcrumbs (Lesson, Rounds,
    Round, Exercise editor, canonical editor), not only the Exercise editor.
- **Where a link leads**: Course → the Course Editor's main page; Lesson →
  the Lesson's page; Round → the Round editor.
- **A jump is several Backs**: it goes through each level's own way back
  (`_leave` in the two exercise editors, `_returnToRounds`,
  `_returnToLesson`, `_returnToLessons`), in order, so unsaved changes still
  ask first at the level that has them, and a level that refuses stops the
  jump there. Nothing is saved or discarded differently from pressing Back
  that many times.
- Where: `lib/widgets/editor_breadcrumbs.dart` (one callback per ancestor
  instead of `onParent`), and a small request object that travels down the
  pages with the level asked for; each page, when its child returns, goes on
  upward if the request names a level above it.
- Tests: from the Exercise editor with unsaved changes, the Course link asks
  first; Discard lands on the Course Editor's main page with the working
  copy as it was; Cancel stays. The number shown equals the Round editor's.

## Revision 1: two recommendations stop being Warnings

**Delivered early, as Build 272 Revision 16 (2.0.72+272016, 13 October
2026), by the owner's decision.** Build 274 starts from its Revision 0 and
goes on to Revision 2; nothing of this section is left to do. One detail
decided while building it: the read-aloud note reads "Flashcard has no
read-aloud."

A Warning turns the exercise, its Round and its Lesson red. These four are
advice, so they become Info (shown, never red).

### Flashcards (point 2)

- **Today**: a Flashcard without a usage sentence gets the Warning
  `FLASHCARD_EXAMPLE_EMPTY`; a Picture flashcard gets no message. The form
  already saves a card without one.
- **Change**: Info for both kinds of card; the form's field reads "Usage
  sentence and optional translation (recommended)".
- `FLASHCARD_AUDIO_EMPTY` (a Flashcard with no read-aloud) becomes Info too.

### Listen and match, Match by meaning (point 5)

- **Today**: `AUDIO_MATCH_PAIR_COUNT` and `MATCH_PAIR_COUNT` warn for any
  number of pairs other than 3, and the Listen and match form says "Three
  sound matches". The learner's page already lays out any number of pairs.
- **Change**: Info, and only outside 2 to 5 pairs (1 pair, or 6 and more).
  The form's label becomes "Sound matches (2 to 5)"; the same wording for
  Match by meaning.
- Where: `course_audit_service.dart` (the `super_match` and `audio_match`
  cases, the Flashcard checks), `audit_code_registry.dart` (severity and
  texts), the two forms' labels, Help EN/IT/ES, the registry counts the
  tests pin.

## Revision 2: playback on request

A small speaker button the learner may tap. Nothing plays by itself, nothing
is asked of the author, and Course files do not change: what is spoken is
worked out from the exercise as it is. It is offered only while the
learner's audio is on, as for Pick the translation today.

### Translations (point 6)

- **Today**: only Pick the translation offers it (a speaker beside a
  target-language sentence; "Listen to the answer" after answering when the
  answers are in the target language).
- **Change**: the same for Build the translation and Type the translation,
  both directions:
  - to source: the speaker stands beside the target sentence to translate;
  - to target: "Listen to the answer" after answering, speaking the first
    accepted answer.

### Options that show a picture and a word (point 4)

- Select the image when its options show their word, and the words of Match
  pictures to words: a speaker on each option whose text is in the target
  language.
- The Duel stays as it is.

### For both

- Where: `round_screen.dart` (`_translationFeedbackAudio` and its button
  generalized; `_iconChoiceExercise`, `_matchingExercise`),
  `TranslationChoice.spokenTextFor` as the model.
- Every text that can now be spoken is added to
  `CourseAudioUsage.spokenTexts`, so the Audio Library's Texts to record and
  "Used in N exercises" know it.
- Tests: the button appears only for target-language text and only with
  audio on; the right text is spoken; nothing plays without a tap; the
  Laboratory presentation baseline is re-recorded for the exercises that
  gain a button.

## Revision 3: a new Listening preset (point 7)

Working name **Listen and pick the missing word**.

- **What the learner gets**: the whole sentence is spoken, and shown with a
  gap; the answers are sounds. A tap on an answer plays it; the learner
  picks one and presses Check. Before answering an answer shows no text.
- **After answering, each answer shows its word** (owner, 13 October
  2026): the text the author wrote for that answer, else the word the sound
  says. A sound that has no word shows nothing.
- **An answer may be an MP3 with no text** (owner, 13 October 2026): a
  recording can be an answer as it is. Giving it a text is recommended (an
  Info of the Audit when it has none), never required: the exercise plays
  and can be published without it.
- **Author's form** (proposed): Instruction or context (optional); the
  sentence with `___` for the gap; the answers, each one either a word (the
  device voice reads it, or its recording plays) or a recording picked from
  the Audio Library, with an optional text shown after answering; which
  answer is correct; Hint (optional).
- **In a Course file**: a Select whose items are sounds, under a spoken
  sentence with a gap. Today an exercise names a sound by its text: the
  device voice reads that text, or the Audio Library's recording given that
  text is played. An answer that is a recording with no text cannot be found
  that way, so the exercise must name the recording itself: the one
  addition to the Course format this preset needs, to design when building
  it (with the text kept back until the answer). A Course that uses the
  preset takes `minimumAppBuild` of this revision; an earlier build would
  print the words of the sounds.
- It is an audio exercise: left out while the learner's Audio Exercises is
  off, like the other Listening exercises. Left out of the Duel.
- **Work**: a new answer layout on the learner's page; the preset's recipe
  and form; its title and instruction line in the seven learner languages;
  Help EN/IT/ES (preset and fields); a Laboratory example and the
  presentation baseline; the Audit rules (answers, one correct, the gap);
  the sounds in `CourseAudioUsage.spokenTexts`; exercise difficulty.

## Revision 4: Image Library search (point 8)

- **Today**: a search finds every picture whose name, tag, Local word, ID or
  category contains the letters typed, in the order of the chosen sort. A
  search for "man" finds 282 pictures: 98 where "man" is a word of its own
  and 184 where it is inside a longer word (Woman, …), mixed together.
- **Change, the order**: first the pictures whose name is the term, then
  those with the term as a whole word of the name, then as a whole word of a
  tag or Local word, then those where it is only inside a longer word. The
  chosen sort (Name, Newest, …) orders the pictures inside each part. A
  plural counts as its word, as the library already compares words
  ("cats" for "cat").
- **Strict search**: a checkbox above Search all, off by default: only the
  first three parts (whole words). With it, "man" does not find Woman.
- Where: `lib/services/image_library_rules.dart` (a rank beside
  `matchesImageSearch`, on the keys `ImageSearchKeys` already keeps for each
  picture, so the search stays as fast as Build 271 made it),
  `flat_image_library_screen.dart` (the order, the checkbox
  `exercise-image-strict-search`). Help EN/IT/ES (`findPicture`).
- A search that names a whole category or group keeps finding its pictures.

## Revision 5: two small categories join a group (point 9)

- **Today**: Movement (6 pictures: Fast, Spin, Bounce, Fall, Grow, Shrink)
  and Symbols (5: Prohibition sign, Power, Play, Pause, Stop) each have a
  chip of their own beside Actions (104) and Concepts (22).
- **Change**: two groups, as the other eleven work (one chip, its categories
  on a second row):
  - **actions & movement**: Actions, Movement;
  - **concepts & symbols**: Concepts, Symbols.
- No picture changes its stored category: groups are only how the library
  shows categories. Courses, Image Banks and the validator's category list
  are untouched.
- Where: `imageCategoryGroups` and `imageCategoryGroupLabels` in
  `lib/models/image_categories.dart` (group keys are never category IDs:
  `actions_movement`, `concepts_symbols`); the tests that count the groups;
  Help EN/IT/ES where the groups are listed.

## What does not change

Scoring, progression, learner data, the Course format (except what the new
preset adds: a sound answer that names its recording, and the
`minimumAppBuild` of a Course that uses the preset), the stored
categories of pictures, and what an Audit Error is.

## Order and branch

Branch `build-274` from `main` once Build 272 is merged. Whether Build 273
or Build 274 comes first is the owner's choice: they touch different code,
except that Revision 0 here changes how the editor pages go back, which
Build 273 also reads.
