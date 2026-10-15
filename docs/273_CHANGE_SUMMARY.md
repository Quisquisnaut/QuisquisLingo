# Build 273 change summary

Build 273 is the second half of the modularization plan
(`docs/272_MODULARIZATION_PLAN.md`): the owners the plan rated medium risk,
which the owner moved out of Build 272 on 12 October 2026. The rule is
Build 272's: no file is split unless the responsibility first gets an owner
of its own that can be tested without the screen; one owner per revision;
**nothing an author or a learner sees changes** unless the owner decides a
change, which is then a revision of its own.

## Revision 0 (2.0.73+273000): the Story cast owner

### Before

Who speaks in a Course's Stories (the narrator and the reusable characters)
is edited in two places: the Course Editor's **Story characters** section
and the **New Story** wizard. The rules about the cast lived inside the
Course Editor file:

- the line under a speaker's name ("Target language · voice female"),
  written once in each screen;
- how the narrator, the characters and an avatar's picture credit are
  written into the Course, a helper at the end of the file that both
  screens called;
- how many Dialogue lines still name a character, and the message that
  refuses to remove it (Course Editor only);
- the list of characters with one replaced or one removed, written inline
  (Course Editor only).

### Now

- `StoryCast` (`lib/services/story_cast.dart`, pure Dart, no screen and no
  storage) is the one owner:
  - `describe(speaker)`: the line under a speaker's name;
  - `summaryOf(course)`: the Story characters tile ("Narrator: Teller · 1
    character", "Unnamed narrator · 2 characters");
  - `linesSpokenBy(course, speakerId)`: the exercises of every Lesson and
    Round whose prompt names the speaker;
  - `stillSpeaksMessage(lines)`: why a character still speaking cannot be
    removed (no line is ever handed to the narrator silently);
  - `replacing(characters, speaker)` and `without(characters, speakerId)`;
  - `withSpeakers(course, narrator:, characters:, credits:)`: the narrator
    is stored only when the Course already has one or the new one differs
    from the Course's narrator, so saving the default narrator unchanged
    changes nothing (the rule the owner chose in Build 270); characters in
    their order, none leaves no entry; each credit once, after the
    Course's own; everything else of the Course kept.
- The Course Editor's Story characters, the Story Wizard and the Rounds
  page (which receives the Wizard's new Story) call it. The Course Editor
  file is at 7,848 lines (7,927).
- Left as they are, on purpose: `Course.narrator` and `Course.speakerOf`
  stay in the Course model (the Round screen and the Audit read them); the
  Story Wizard shows "Unknown character" for a line whose speaker it does
  not know while the Round screen lets the narrator say it. They are two
  presentations, not one rule, and nothing changes for learners.

### What does not change

The screens, their keys and their texts; Course files; scoring,
progression and learner data. No new key or folder.

## Revision 1 (2.0.73+273001): one publish gate

### Before

Applying an item as normal content (Published) is refused while the Course
Audit finds an error learners would meet. That check was written eight
times:

- the Course's **Publish** on the Course Editor's main page;
- a Lesson's **Apply** in the Lessons page's menu, and the Lesson editor's
  **Apply**;
- a Round's **Apply** in the Rounds page's menu, and the Round editor's
  **Apply**;
- an exercise's **Apply** in the Round editor's list;
- **Apply** in the preset form and in the canonical editor.

The copies for a Lesson and a Round each built their own view of the
Course with the parents taken as Published and projected what learners
would get; the Course's copy projected the Course as it was; the three
exercise copies audited the exercise alone. Each ran the Audit, counted the
errors and wrote its own refusal. The two exercise forms also each drew the
same two dialogs (the errors with Keep editing, the warnings with Use
anyway).

### Now

- `PublishGate` (`lib/services/publish_gate.dart`, no screen and no
  storage) is the one owner of the check: `courseErrors`, `lessonErrors` (the Course taken as
  Published), `roundErrors` (the Course and the Lesson taken as Published),
  `exerciseIssues` with `errorsIn` and `warningCount`, and the three
  refusals. The screens only gather the Course they are editing and show
  the answer.
- `showEditorList` and `confirmUseAnyway` (`lib/widgets/editor_dialogs.dart`)
  are the exercise forms' two dialogs, shared.
- Line counts: the Course Editor file 7,792 (7,848), the preset form
  3,218 (3,276), the canonical editor 1,761 (1,818).

### Differences kept, for the owner to decide

1. **"Move to Draft" has two wordings.** The Lessons page's menu, the
   Rounds page's menu and the Round editor's exercise list ask "Move Lesson
   (Round, Exercise) to Draft?" ("…will disappear from the learner course
   (path, Round)…"); the Lesson editor, the Round editor and the two
   exercise forms ask "Apply Lesson as draft?" ("…will disappear from
   learner-facing content…"). Recommendation: one wording, the second
   (Build 270 renamed Save to Apply; the three menus were left behind).
2. **The Round type check.** Only the canonical editor refuses to apply an
   exercise that does not fit its Round's type (for example a Listen
   Round's exercise whose audio is not required). The preset form offers
   only the presets that fit the Round type, but a fitting preset may
   still give an exercise that does not fit (audio left optional), and the
   Round editor's exercise list applies without the check. The Audit marks
   the Round red (an Error), which stops a Draft Round from being applied;
   a Round already Published is not stopped, and at runtime one exercise
   that does not fit makes the whole Round unplayable for learners
   (`RoundPlayabilityService`). Recommendation: the preset form and the
   exercise list check the Round type before Apply, as the canonical
   editor does (found by the independent review).
3. **Why Preview is refused.** The preset form lists the errors' messages
   separated by blank lines; the canonical editor lists "CODE: message"
   lines. Recommendation: the canonical editor's list in both.
4. **The exercise list's Apply** refuses with one line ("…until its Errors
   are fixed.") and never asks about warnings, while the forms list the
   errors and ask about warnings. Recommendation: leave it (a quick switch
   from the list; the form is where findings are read).

### What does not change

The screens, their keys and their texts; when an item is refused or
applied; Course files; scoring, progression and learner data. No new key
or folder.

## Revision 2 (2.0.73+273002): answer grading out of the Round screen

### Before

The Round screen decided inside its widget whether a learner's answer was
right: one method per kind of answer (a typed answer, blocks in order,
missing words, gaps filled by choosing or with blocks, several answers,
groups and slots, Match pairs), each reading the screen's own fields, and
the text of the right answer the screen shows after a wrong one was built
by eight more methods of the same widget. None of it could be tested
without opening a Round.

### Now

- `AnswerGrader` (`lib/services/answer_grader.dart`) grades: an exercise,
  its features and what the learner did in; right or wrong out (for a
  typed answer also the accepted answer it matched, the small differences
  forgiven and the other accepted answers to show).
- `CorrectAnswerText` (`lib/services/correct_answer_text.dart`) writes the
  right answer; its few words of its own ("See the course answer.",
  "Review the flashcard.", "Slot 2") come from the learner panel in the
  Course's language, as before.
- The Round screen keeps when it grades, what the learner's taps hold and
  what it shows. Its file is at 5,496 lines (5,794).

### Differences kept, for the owner to decide

1. **Gaps are graded more strictly than one typed answer.** Missing words
   (also Listen for missing words, Complete the text, Missing letters)
   types one word per gap; its gaps forgive no typo, take no literal
   answer, and ignore the exercise's options for capitals, punctuation,
   spaces and accents. One typed answer (Type the translation, Type what
   you hear, Type the missing word with its first letter shown) follows
   those options: it forgives a doubled letter in a long word when the
   exercise allows typos (Type the missing word with its first letter
   shown does; with the first letter hidden it does not), and accepts
   literal answers (only Type what you hear has them). With the default options the two give the same results; the
   difference shows only for an exercise whose options were changed in the
   canonical editor, or with a doubled letter where typos are allowed.
   Recommendation: leave it unless the owner wants gaps to follow the
   exercise's options (a change of grading, a revision of its own; found
   partly by the independent review).
2. **Two kinds of gap compare differently.** A gap filled with a block is
   right when the block reads like the expected one (two identical blocks
   are interchangeable, Build 256's rule); a gap filled by choosing an
   option is right only with the very option expected. With two identical
   options (an author's slip) a learner could choose the "wrong" twin.
   Recommendation: leave it (options are distinct in practice; the Audit
   could warn about identical options).
3. **An exercise with no pairs.** Match by meaning grades it wrong, Listen
   and match grades it right. No learner meets it: such an exercise has an
   Audit error and is never played. Recommendation: leave it.

### What does not change

Which answers are right, the feedback, the right answer shown, the XP,
the keys and the texts. No new key or folder.

## Revision 3 (2.0.73+273003): the owner's decisions on Revisions 1 and 2

Decided by the owner on 15 October 2026 on the differences above. A change
of behaviour.

### What changes

1. **The Round type is checked on every Apply of an exercise** (Revision
   1, point 2). The preset form refuses Apply with "Round type
   compatibility" and the reason, and the Round editor's exercise list
   refuses in one line ("Exercise cannot be applied as normal content:
   This required exercise does not structurally require audio."), as the
   canonical editor already did. Apply as draft is not checked. The rule
   is the Course Audit's own: a Before you start card is exempt except in
   a FlashCard or a Test Round. The canonical editor's check and the
   notice above its form follow that rule too, so it no longer refuses a
   Before you start card in a Listen, Read, Timed or Speak Round (the Audit
   accepts it there). The Exercise Wizard opens the same preset form, so
   its Apply is refused too for an exercise that does not fit the Round
   (the Wizard keeps its results as Draft anyway: Apply as draft works).
   Copy to…, Move to… and Duplicate keep an exercise's state and are not
   checked; the Audit still marks the Round red.
2. **A refused Preview lists "CODE: message"** in the preset form as in
   the canonical editor (Revision 1, point 3).
3. **Gaps follow the exercise's options for capitals, punctuation, spaces
   and accents, never typos** (Revision 2, point 1, the middle way): in
   Listen and fill the gaps, Complete the text and Missing letters. A
   gap's text is trimmed first, as one typed answer is. With the options
   the forms leave, nothing changes; an exercise whose options were
   changed in the canonical editor, or that came from a file with other
   options, now grades its gaps by them ("Capitals: exact" makes "Legge"
   wrong for "legge"; "Accents: ignore" accepts "lègge").

### Left as they are (owner)

The two wordings of "move to Draft"; the exercise list's one-line Audit
refusal; gaps chosen compared by option, gap blocks by text; an exercise
without pairs in Listen and match.

### Found along the way, for the owner

"Accents: exact" has no effect: the answer engine is given the same rules
for "exact" as for "missing accents accepted", and a missing accent is
accepted in both (in gaps and in typed answers alike). No form sets it; the
canonical editor offers it.

A Before you start card in a FlashCard or a Test Round breaks the Audit's
Round type rule (and is now refused on Apply), although the learner is
shown it in every Round type (`RoundPlayabilityService`). Found by the
independent review; the rule is older than this Build.

## Revision 4 (2.0.73+273004): the held Story line has an owner

### Before

A Dialogue line that reads itself aloud keeps Continue greyed until it has
been read (Build 269), with two safety releases (Build 270). The Round
screen held this in ten fields of its own (whether the line holds, its
voice started and ended, its time passed, a tap on Play playing, the
estimate, three timers and the ceiling's flag), two constants, a getter
and five methods, all checked against the screen's exercise counter (one
of them, `_prepareLineHold`, stays as a one-line call of the owner).

### Now

- `SpokenLineHold` (`lib/services/spoken_line_hold.dart`, no Flutter) owns
  them: `prepare`, `armWatchdog`, `voiceStarted`, `voiceDone`, `read`,
  `tapStarted` / `tapEnded`, `dispose`, and what the page reads (`held`,
  `speaking`, `voiceEnded`, `finished`, `playing`, `estimate`, `waits`).
  It counts the lines itself, so a voice, a timer or a reading that
  belongs to an earlier line is ignored, as before.
- The Round screen tells it when a line is prepared, when its voice starts
  and ends, and redraws when it says so; the stopwatch that times the
  voice, the text revealed after listening and the Crash Log lines stay
  with the screen. Its file is at 5,380 lines (5,496).

### What does not change

When Continue is greyed and released, the words brightening, the pace
learnt, Play, and the Crash Log lines. One harmless difference: no ceiling
timer is armed for a voice that starts after the page is gone.

## Revision 5 (2.0.73+273005): one attempt at a Round has an owner

### Before

The Round screen kept one attempt at a Round in eight fields of its own
(the queue of exercises, the place in it, the review phase, the mistakes
of the first pass, the right answers at the first try and their
difficulty, the errors, a Test's results) and changed them in its answer,
its Flashcard and its "next" methods; a Test's score was worked out inside
the results dialog.

### Now

- `RoundAttempt` (`lib/services/round_attempt.dart`, no Flutter) owns
  them: what comes next, each answer, a Flashcard seen again, the review of
  mistakes (never in a Round played in order or a Test), whether the answer
  just given is the last (for a Timed Round in time), and the Test's score.
  It shuffles with the Round screen's own random source, so the order is
  drawn exactly as before.
- The Round screen keeps the dialogs, the Timed clock, the guards against
  a double tap and a second finish, and the completion (it reads the
  attempt's counts for the XP). Its file is at 5,342 lines (5,380).

### What does not change

The order of the exercises, the review of mistakes, the Test's results and
score, the XP, the Timed Round's on-time bonus, the keys and the texts.
